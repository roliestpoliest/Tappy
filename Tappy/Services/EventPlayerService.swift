import CoreGraphics
import Foundation
import Observation

// File-level constant so the abort tap callback (a C function pointer that cannot
// capture context) can compare against it without accessing actor-isolated state.
private let syntheticEventMarker: Int64 = 0x54415050  // "TAPP" in ASCII

@Observable
final class EventPlayerService {
    var isPlaying: Bool = false
    var isPaused: Bool = false
    var currentEventIndex: Int = 0
    var currentIteration: Int = 1

    @ObservationIgnored private let playbackSource = CGEventSource(stateID: .privateState)
    @ObservationIgnored private var playbackTask: Task<Void, any Error>?
    @ObservationIgnored private var abortTap: CFMachPort?
    @ObservationIgnored private var pauseContinuation: CheckedContinuation<Void, Never>?

    // MARK: - Public Interface

    func play(recording: MacroRecording, config: PlaybackConfig) {
        stop()
        isPlaying = true
        setupAbortTap()

        playbackTask = Task { @MainActor in
            let maxIterations = config.isLooping ? Int.max : config.repeatCount

            for iteration in 1...maxIterations {
                currentIteration = iteration
                var previousPosition: CGPoint? = nil

                for (index, event) in recording.events.enumerated() {
                    try Task.checkCancellation()
                    await waitIfPaused()

                    if index > 0 {
                        let prev = recording.events[index - 1]
                        let scaledDelay = max(0, (event.timestamp - prev.timestamp) / config.speed)
                        try await Task.sleep(for: .seconds(scaledDelay))
                    }

                    if event.type.isDragEvent {
                        postDragEvent(event)
                        previousPosition = event.position
                    } else if let targetPos = event.position, event.type.isMouseEvent {
                        let budget = interEventBudget(index: index, events: recording.events, speed: config.speed)
                        await moveMouse(from: previousPosition ?? targetPos, to: targetPos, budget: budget)
                        previousPosition = targetPos
                        postMouseEvent(event)
                    } else if event.type == .scrollWheel {
                        postScrollEvent(event)
                    } else {
                        postKeyEvent(event)
                    }

                    currentEventIndex = index
                }
            }

            isPlaying = false
            currentEventIndex = 0
            teardownAbortTap()
        }
    }

    func pause() {
        isPaused = true
    }

    func resume() {
        isPaused = false
        pauseContinuation?.resume()
        pauseContinuation = nil
    }

    func stop() {
        playbackTask?.cancel()
        playbackTask = nil
        isPlaying = false
        isPaused = false
        currentEventIndex = 0
        currentIteration = 1
        pauseContinuation?.resume()
        pauseContinuation = nil
        teardownAbortTap()
    }

    // MARK: - Abort Tap

    private func setupAbortTap() {
        let mask: CGEventMask = (1 << CGEventType.rightMouseDown.rawValue)
        abortTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .tailAppendEventTap,
            options: .listenOnly,
            eventsOfInterest: mask,
            callback: { _, _, event, userInfo -> Unmanaged<CGEvent>? in
                guard let userInfo else { return nil }
                let player = Unmanaged<EventPlayerService>.fromOpaque(userInfo).takeUnretainedValue()
                if event.getIntegerValueField(.eventSourceUserData) == syntheticEventMarker {
                    return Unmanaged.passRetained(event)
                }
                DispatchQueue.main.async {
                    MainActor.assumeIsolated { player.stop() }
                }
                return Unmanaged.passRetained(event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )
        if let tap = abortTap {
            let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
            CGEvent.tapEnable(tap: tap, enable: true)
        }
    }

    private func teardownAbortTap() {
        if let tap = abortTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            abortTap = nil
        }
    }

    // MARK: - Pause / Resume

    private func waitIfPaused() async {
        guard isPaused else { return }
        await withCheckedContinuation { continuation in
            pauseContinuation = continuation
        }
    }

    // MARK: - Timing

    private func interEventBudget(index: Int, events: [MacroEvent], speed: Double) -> TimeInterval {
        guard index + 1 < events.count else { return 0 }
        let gap = events[index + 1].timestamp - events[index].timestamp
        return max(0, gap / speed)
    }

    // MARK: - Mouse Movement

    private func moveMouse(from start: CGPoint, to end: CGPoint, budget: TimeInterval) async {
        guard hypot(end.x - start.x, end.y - start.y) > 2.0, budget > 0.01 else { return }

        let path = BezierInterpolationService.interpolate(from: start, to: end)
        let stepDelay = budget / Double(path.count)

        for point in path {
            try? Task.checkCancellation()
            let moveEvent = CGEvent(mouseEventSource: playbackSource,
                                    mouseType: .mouseMoved,
                                    mouseCursorPosition: point,
                                    mouseButton: .left)
            moveEvent?.setIntegerValueField(.eventSourceUserData, value: syntheticEventMarker)
            moveEvent?.post(tap: .cgSessionEventTap)
            try? await Task.sleep(for: .seconds(stepDelay))
        }
    }

    // MARK: - Event Posting

    private func postMouseEvent(_ event: MacroEvent) {
        guard let pos = event.position else { return }
        let cgEvent = CGEvent(mouseEventSource: playbackSource,
                              mouseType: event.type.toCGEventType(),
                              mouseCursorPosition: pos,
                              mouseButton: event.type.toCGMouseButton())
        cgEvent?.setIntegerValueField(.eventSourceUserData, value: syntheticEventMarker)
        cgEvent?.post(tap: .cgSessionEventTap)
    }

    private func postDragEvent(_ event: MacroEvent) {
        guard let pos = event.position else { return }
        let cgEvent = CGEvent(mouseEventSource: playbackSource,
                              mouseType: event.type.toCGEventType(),
                              mouseCursorPosition: pos,
                              mouseButton: event.type == .leftMouseDragged ? .left : .right)
        cgEvent?.setIntegerValueField(.eventSourceUserData, value: syntheticEventMarker)
        cgEvent?.post(tap: .cgSessionEventTap)
    }

    private func postScrollEvent(_ event: MacroEvent) {
        let scrollEvent = CGEvent(scrollWheelEvent2Source: playbackSource,
                                  units: .pixel,
                                  wheelCount: 2,
                                  wheel1: Int32(event.scrollDeltaY ?? 0),
                                  wheel2: Int32(event.scrollDeltaX ?? 0),
                                  wheel3: 0)
        scrollEvent?.setIntegerValueField(.eventSourceUserData, value: syntheticEventMarker)
        scrollEvent?.post(tap: .cgSessionEventTap)
    }

    private func postKeyEvent(_ event: MacroEvent) {
        guard let keyCode = event.keyCode else { return }
        let cgEvent = CGEvent(keyboardEventSource: playbackSource,
                              virtualKey: keyCode,
                              keyDown: event.type == .keyDown)
        if let rawFlags = event.modifierFlags {
            cgEvent?.flags = CGEventFlags(rawValue: rawFlags)
        }
        cgEvent?.setIntegerValueField(.eventSourceUserData, value: syntheticEventMarker)
        cgEvent?.post(tap: .cgSessionEventTap)
    }
}
