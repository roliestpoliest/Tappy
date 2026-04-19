import CoreGraphics
import Foundation
import Observation

@Observable
final class EventPlayer {
    var isPlaying = false
    var progress: Double = 0
    var currentIteration: Int = 0
    var currentEventID: UUID? = nil

    @ObservationIgnored nonisolated(unsafe) private var playbackThread: Thread?
    @ObservationIgnored nonisolated(unsafe) private var shouldStop = false

    func play(recording: MacroRecording, config: PlaybackConfig) {
        guard !isPlaying else { return }
        shouldStop = false
        isPlaying = true
        progress = 0
        currentIteration = 0

        let events = config.useBezierCurves
            ? expandForBezier(recording.events, config: config)
            : recording.events
        let totalDuration = recording.duration
        let maxIterations = config.repeatCount

        let thread = Thread { [weak self] in
            guard let self else { return }
            var iteration = 0

            repeat {
                let baseTime = CFAbsoluteTimeGetCurrent()

                for event in events {
                    if self.shouldStop { break }

                    let scaledDelay = event.timestamp / config.speed
                    let targetTime = baseTime + scaledDelay
                    let now = CFAbsoluteTimeGetCurrent()
                    let sleepMicros = (targetTime - now) * 1_000_000
                    if sleepMicros > 0 {
                        usleep(UInt32(min(sleepMicros, Double(UInt32.max))))
                    }

                    if self.shouldStop { break }
                    self.postEvent(event, config: config)

                    let pct = totalDuration > 0 ? event.timestamp / totalDuration : 0
                    let iterSnapshot = iteration + 1
                    let eventID = event.id
                    Task { @MainActor [weak self] in
                        self?.progress = pct
                        self?.currentIteration = iterSnapshot
                        self?.currentEventID = eventID
                    }
                }

                iteration += 1
            } while !self.shouldStop && (maxIterations == 0 || iteration < maxIterations)

            Task { @MainActor [weak self] in
                self?.isPlaying = false
                self?.progress = maxIterations > 0 ? 1.0 : 0.0
                self?.currentEventID = nil
            }
        }
        thread.qualityOfService = .userInteractive
        thread.start()
        playbackThread = thread
    }

    func stop() {
        shouldStop = true
    }

    nonisolated private func postEvent(_ event: MacroEvent, config: PlaybackConfig) {
        let pos = jittered(event.position, amount: config.jitterAmount)

        switch event.type {
        case .mouseMove:
            postMouse(type: .mouseMoved, pos: pos, button: .left, flags: event.eventFlags)

        case .mouseLeftDown:
            for _ in 0..<config.clickMultiplier {
                postMouse(type: .leftMouseDown, pos: pos, button: .left, flags: event.eventFlags)
                usleep(10_000)
                postMouse(type: .leftMouseUp, pos: pos, button: .left, flags: event.eventFlags)
                usleep(10_000)
            }

        case .mouseLeftUp:
            break // handled by mouseLeftDown multiplier

        case .mouseRightDown:
            for _ in 0..<config.clickMultiplier {
                postMouse(type: .rightMouseDown, pos: pos, button: .right, flags: event.eventFlags)
                usleep(10_000)
                postMouse(type: .rightMouseUp, pos: pos, button: .right, flags: event.eventFlags)
                usleep(10_000)
            }

        case .mouseRightUp:
            break

        case .mouseOtherDown:
            let btn = CGMouseButton(rawValue: UInt32(event.mouseButton)) ?? .center
            postMouse(type: .otherMouseDown, pos: pos, button: btn, flags: event.eventFlags)

        case .mouseOtherUp:
            let btn = CGMouseButton(rawValue: UInt32(event.mouseButton)) ?? .center
            postMouse(type: .otherMouseUp, pos: pos, button: btn, flags: event.eventFlags)

        case .scrollWheel:
            if let e = CGEvent(scrollWheelEvent2Source: nil,
                               units: .pixel,
                               wheelCount: 2,
                               wheel1: event.scrollDeltaY,
                               wheel2: event.scrollDeltaX,
                               wheel3: 0) {
                e.post(tap: .cghidEventTap)
            }

        case .keyDown:
            if let code = event.keyCode,
               let e = CGEvent(keyboardEventSource: nil, virtualKey: code, keyDown: true) {
                e.flags = CGEventFlags(rawValue: event.eventFlags)
                e.post(tap: .cghidEventTap)
            }

        case .keyUp:
            if let code = event.keyCode,
               let e = CGEvent(keyboardEventSource: nil, virtualKey: code, keyDown: false) {
                e.flags = CGEventFlags(rawValue: event.eventFlags)
                e.post(tap: .cghidEventTap)
            }

        case .flagsChanged:
            if let code = event.keyCode,
               let e = CGEvent(keyboardEventSource: nil, virtualKey: code, keyDown: false) {
                e.flags = CGEventFlags(rawValue: event.eventFlags)
                e.type = .flagsChanged
                e.post(tap: .cghidEventTap)
            }
        }
    }

    nonisolated private func postMouse(type: CGEventType, pos: CGPoint?, button: CGMouseButton, flags: UInt64) {
        guard let pos,
              let e = CGEvent(mouseEventSource: nil,
                              mouseType: type,
                              mouseCursorPosition: pos,
                              mouseButton: button) else { return }
        e.flags = CGEventFlags(rawValue: flags)
        e.post(tap: .cghidEventTap)
    }

    nonisolated private func jittered(_ point: CGPoint?, amount: Double) -> CGPoint? {
        guard let point, amount > 0 else { return point }
        let angle = Double.random(in: 0..<(2 * .pi))
        let radius = Double.random(in: 0..<amount)
        return CGPoint(
            x: point.x + cos(angle) * radius,
            y: point.y + sin(angle) * radius)
    }

    nonisolated private func expandForBezier(_ events: [MacroEvent], config: PlaybackConfig) -> [MacroEvent] {
        var expanded: [MacroEvent] = []
        expanded.reserveCapacity(events.count * config.bezierSteps)

        for i in 0..<events.count {
            let event = events[i]
            guard event.type == .mouseMove,
                  i + 1 < events.count,
                  events[i + 1].type == .mouseMove,
                  let start = event.position,
                  let end = events[i + 1].position else {
                expanded.append(event)
                continue
            }

            let pts = BezierInterpolator.points(
                from: start, to: end,
                deviation: config.bezierDeviation,
                steps: config.bezierSteps)

            let dt = events[i + 1].timestamp - event.timestamp

            for (j, pt) in pts.dropLast().enumerated() {
                let t = event.timestamp + dt * Double(j) / Double(pts.count - 1)
                expanded.append(MacroEvent(
                    type: .mouseMove,
                    timestamp: t,
                    position: pt,
                    eventFlags: event.eventFlags))
            }
        }

        if let last = events.last { expanded.append(last) }
        return expanded
    }
}
