import Foundation
import Cocoa
import Observation

@Observable
class InputRecorder {
    var isRecording = false
    private(set) var capturedEventCount = 0

    private var events: [InputEvent] = []
    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var startTime: Date?
    private var lastMoveTimestamp: TimeInterval = 0
    private let moveThrottleInterval: TimeInterval = 1.0 / 60.0

    func startRecording() {
        events = []
        capturedEventCount = 0
        startTime = Date()
        isRecording = true

        globalMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .leftMouseUp, .mouseMoved, .leftMouseDragged, .keyDown, .keyUp, .scrollWheel]
        ) { [weak self] event in
            self?.handleEvent(event)
        }

        localMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.leftMouseDown, .leftMouseUp, .mouseMoved, .leftMouseDragged, .keyDown, .keyUp, .scrollWheel]
        ) { [weak self] event in
            self?.handleEvent(event)
            return event
        }
    }

    func stopRecording() -> [InputEvent] {
        isRecording = false

        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
            self.globalMonitor = nil
        }
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
        }

        startTime = nil
        lastMoveTimestamp = 0
        return events
    }

    private func handleEvent(_ event: NSEvent) {
        guard let startTime else { return }

        let timestamp = Date().timeIntervalSince(startTime)

        // Convert NSEvent coordinates (bottom-left origin) to CG coordinates (top-left origin)
        let primaryScreenHeight = NSScreen.screens.first?.frame.height ?? 0
        let nsLocation = NSEvent.mouseLocation
        let cgPoint = CGPoint(x: nsLocation.x, y: primaryScreenHeight - nsLocation.y)

        let inputEvent: InputEvent
        switch event.type {
        case .leftMouseDown:
            inputEvent = InputEvent(type: .leftMouseDown, position: cgPoint, timestamp: timestamp)
        case .leftMouseUp:
            inputEvent = InputEvent(type: .leftMouseUp, position: cgPoint, timestamp: timestamp)
        case .mouseMoved, .leftMouseDragged:
            // Throttle move events to ~60fps
            if timestamp - lastMoveTimestamp < moveThrottleInterval { return }
            lastMoveTimestamp = timestamp
            inputEvent = InputEvent(type: .mouseMoved, position: cgPoint, timestamp: timestamp)
        case .keyDown:
            if HotkeyManager.isHotkey(event) { return }
            inputEvent = InputEvent(
                type: .keyDown,
                position: cgPoint,
                timestamp: timestamp,
                keyCode: event.keyCode,
                modifierFlags: event.modifierFlags.rawValue
            )
        case .keyUp:
            if HotkeyManager.isHotkey(event) { return }
            inputEvent = InputEvent(
                type: .keyUp,
                position: cgPoint,
                timestamp: timestamp,
                keyCode: event.keyCode,
                modifierFlags: event.modifierFlags.rawValue
            )
        case .scrollWheel:
            inputEvent = InputEvent(
                type: .scrollWheel,
                position: cgPoint,
                timestamp: timestamp,
                scrollDeltaX: Double(event.scrollingDeltaX),
                scrollDeltaY: Double(event.scrollingDeltaY)
            )
        default:
            return
        }

        events.append(inputEvent)
        capturedEventCount = events.count
    }
}
