import Foundation
import Cocoa
import Observation

// Sendable helper to post CGEvents off the main actor
private struct EventPoster: Sendable {
    nonisolated func post(_ event: InputEvent) {
        let point = CGPoint(x: event.x, y: event.y)
        switch event.type {
        case .mouseMoved:
            CGWarpMouseCursorPosition(point)
        case .leftMouseDown:
            let e = CGEvent(
                mouseEventSource: nil,
                mouseType: .leftMouseDown,
                mouseCursorPosition: point,
                mouseButton: .left
            )
            e?.post(tap: .cghidEventTap)
        case .leftMouseUp:
            let e = CGEvent(
                mouseEventSource: nil,
                mouseType: .leftMouseUp,
                mouseCursorPosition: point,
                mouseButton: .left
            )
            e?.post(tap: .cghidEventTap)
        case .keyDown:
            guard let keyCode = event.keyCode else { return }
            let e = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(keyCode), keyDown: true)
            if let flags = event.modifierFlags {
                e?.flags = CGEventFlags(rawValue: UInt64(flags))
            }
            e?.post(tap: .cghidEventTap)
        case .keyUp:
            guard let keyCode = event.keyCode else { return }
            let e = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(keyCode), keyDown: false)
            if let flags = event.modifierFlags {
                e?.flags = CGEventFlags(rawValue: UInt64(flags))
            }
            e?.post(tap: .cghidEventTap)
        case .scrollWheel:
            let e = CGEvent(scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 2,
                            wheel1: Int32(event.scrollDeltaY ?? 0),
                            wheel2: Int32(event.scrollDeltaX ?? 0),
                            wheel3: 0)
            e?.post(tap: .cghidEventTap)
        }
    }
}

enum RepeatMode: Equatable {
    case once
    case times(Int)  // repeat N times total
    case forever
}

@Observable
class InputPlayer {
    var isPlaying = false
    var playbackSpeed: Double = 1.0
    var repeatMode: RepeatMode = .once
    var currentIteration = 0

    private var rightClickMonitorGlobal: Any?
    private var rightClickMonitorLocal: Any?
    private var playbackTask: Task<Void, Never>?

    func play(recording: InputRecording) {
        guard !recording.events.isEmpty else { return }

        isPlaying = true
        currentIteration = 0
        setupRightClickStop()

        let events = recording.events
        let speed = playbackSpeed
        let mode = repeatMode
        let poster = EventPoster()

        playbackTask = Task.detached { [weak self] in
            var iteration = 0

            while true {
                if Task.isCancelled { break }

                iteration += 1
                let iter = iteration
                let player = self
                await MainActor.run { player?.currentIteration = iter }

                var previousTimestamp: TimeInterval = 0
                for event in events {
                    if Task.isCancelled { break }

                    let delay = (event.timestamp - previousTimestamp) / speed
                    if delay > 0 {
                        try? await Task.sleep(for: .seconds(delay))
                    }

                    if Task.isCancelled { break }
                    previousTimestamp = event.timestamp

                    poster.post(event)
                }

                // Check if we should loop again
                switch mode {
                case .once:
                    break
                case .times(let total):
                    if iteration >= total { break }
                    continue
                case .forever:
                    continue
                }
                break
            }

            let player = self
            await MainActor.run {
                player?.stop()
            }
        }
    }

    func stop() {
        guard isPlaying else { return }
        isPlaying = false
        playbackTask?.cancel()
        playbackTask = nil
        teardownRightClickStop()
    }

    // MARK: - Right-click to stop playback

    private func setupRightClickStop() {
        rightClickMonitorGlobal = NSEvent.addGlobalMonitorForEvents(matching: .rightMouseDown) { [weak self] _ in
            DispatchQueue.main.async {
                self?.stop()
            }
        }

        rightClickMonitorLocal = NSEvent.addLocalMonitorForEvents(matching: .rightMouseDown) { [weak self] event in
            DispatchQueue.main.async {
                self?.stop()
            }
            return nil // swallow the right-click
        }
    }

    private func teardownRightClickStop() {
        if let rightClickMonitorGlobal {
            NSEvent.removeMonitor(rightClickMonitorGlobal)
            self.rightClickMonitorGlobal = nil
        }
        if let rightClickMonitorLocal {
            NSEvent.removeMonitor(rightClickMonitorLocal)
            self.rightClickMonitorLocal = nil
        }
    }
}
