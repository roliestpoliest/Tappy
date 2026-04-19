import AppKit
import CoreGraphics
import Foundation
import Observation

@Observable
final class EventRecorder {
    var isRecording = false
    var capturedEvents: [MacroEvent] = []
    var elapsedTime: TimeInterval = 0

    @ObservationIgnored nonisolated(unsafe) fileprivate var eventTap: CFMachPort?
    @ObservationIgnored private var runLoopSource: CFRunLoopSource?
    @ObservationIgnored private var tapThread: Thread?
    @ObservationIgnored private var tapRunLoop: CFRunLoop?
    @ObservationIgnored nonisolated(unsafe) private var startTime: CFAbsoluteTime = 0
    @ObservationIgnored nonisolated(unsafe) fileprivate var isAppFrontmost: Bool = true
    @ObservationIgnored private var appObservers: [Any] = []
    private var elapsedTimer: Timer?

    func startRecording() {
        guard !isRecording else { return }
        capturedEvents = []
        elapsedTime = 0
        startTime = CFAbsoluteTimeGetCurrent()

        // Tappy is active when the user clicks Record — filter its own UI events
        isAppFrontmost = NSApp.isActive
        appObservers.append(
            NotificationCenter.default.addObserver(
                forName: NSApplication.didBecomeActiveNotification,
                object: nil, queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated { self?.isAppFrontmost = true }
            }
        )
        appObservers.append(
            NotificationCenter.default.addObserver(
                forName: NSApplication.didResignActiveNotification,
                object: nil, queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated { self?.isAppFrontmost = false }
            }
        )

        let eventMask: CGEventMask =
            (1 << CGEventType.mouseMoved.rawValue) |
            (1 << CGEventType.leftMouseDown.rawValue) |
            (1 << CGEventType.leftMouseUp.rawValue) |
            (1 << CGEventType.rightMouseDown.rawValue) |
            (1 << CGEventType.rightMouseUp.rawValue) |
            (1 << CGEventType.otherMouseDown.rawValue) |
            (1 << CGEventType.otherMouseUp.rawValue) |
            (1 << CGEventType.scrollWheel.rawValue) |
            (1 << CGEventType.keyDown.rawValue) |
            (1 << CGEventType.keyUp.rawValue) |
            (1 << CGEventType.flagsChanged.rawValue)

        let selfPtr = Unmanaged.passRetained(self).toOpaque()

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: eventMask,
            callback: eventTapCallback,
            userInfo: selfPtr
        ) else {
            Unmanaged<EventRecorder>.fromOpaque(selfPtr).release()
            return
        }

        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)

        let thread = Thread { [weak self] in
            guard let self else { return }
            self.tapRunLoop = CFRunLoopGetCurrent()
            if let source = self.runLoopSource {
                CFRunLoopAddSource(self.tapRunLoop, source, .commonModes)
            }
            CGEvent.tapEnable(tap: tap, enable: true)
            CFRunLoopRun()
        }
        thread.qualityOfService = .userInteractive
        thread.start()
        tapThread = thread

        isRecording = true

        elapsedTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.elapsedTime = CFAbsoluteTimeGetCurrent() - self.startTime
        }
    }

    func stopRecording() -> MacroRecording {
        elapsedTimer?.invalidate()
        elapsedTimer = nil

        for obs in appObservers { NotificationCenter.default.removeObserver(obs) }
        appObservers.removeAll()

        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let rl = tapRunLoop {
            CFRunLoopStop(rl)
        }

        tapRunLoop = nil
        tapThread = nil
        runLoopSource = nil
        eventTap = nil
        isRecording = false

        let events = capturedEvents
        let name = "Recording \(DateFormatter.recordingName.string(from: Date()))"
        var recording = MacroRecording(name: name, events: events)
        recording.duration = events.last?.timestamp ?? 0
        return recording
    }

    fileprivate func append(event: MacroEvent) {
        capturedEvents.append(event)
    }

    nonisolated fileprivate func buildEvent(cgEvent: CGEvent, type: CGEventType) -> MacroEvent {
        let timestamp = CFAbsoluteTimeGetCurrent() - startTime
        let flags = cgEvent.flags.rawValue

        switch type {
        case .mouseMoved:
            let pos = cgEvent.location
            return MacroEvent(type: .mouseMove, timestamp: timestamp, position: pos, eventFlags: flags)

        case .leftMouseDown:
            let pos = cgEvent.location
            return MacroEvent(type: .mouseLeftDown, timestamp: timestamp, position: pos, eventFlags: flags, mouseButton: 0)

        case .leftMouseUp:
            let pos = cgEvent.location
            return MacroEvent(type: .mouseLeftUp, timestamp: timestamp, position: pos, eventFlags: flags, mouseButton: 0)

        case .rightMouseDown:
            let pos = cgEvent.location
            return MacroEvent(type: .mouseRightDown, timestamp: timestamp, position: pos, eventFlags: flags, mouseButton: 1)

        case .rightMouseUp:
            let pos = cgEvent.location
            return MacroEvent(type: .mouseRightUp, timestamp: timestamp, position: pos, eventFlags: flags, mouseButton: 1)

        case .otherMouseDown:
            let pos = cgEvent.location
            let btn = Int32(cgEvent.getIntegerValueField(.mouseEventButtonNumber))
            return MacroEvent(type: .mouseOtherDown, timestamp: timestamp, position: pos, eventFlags: flags, mouseButton: btn)

        case .otherMouseUp:
            let pos = cgEvent.location
            let btn = Int32(cgEvent.getIntegerValueField(.mouseEventButtonNumber))
            return MacroEvent(type: .mouseOtherUp, timestamp: timestamp, position: pos, eventFlags: flags, mouseButton: btn)

        case .scrollWheel:
            let dx = Int32(cgEvent.getIntegerValueField(.scrollWheelEventDeltaAxis2))
            let dy = Int32(cgEvent.getIntegerValueField(.scrollWheelEventDeltaAxis1))
            return MacroEvent(type: .scrollWheel, timestamp: timestamp, eventFlags: flags, scrollDeltaX: dx, scrollDeltaY: dy)

        case .keyDown:
            let key = UInt16(cgEvent.getIntegerValueField(.keyboardEventKeycode))
            return MacroEvent(type: .keyDown, timestamp: timestamp, keyCode: key, eventFlags: flags)

        case .keyUp:
            let key = UInt16(cgEvent.getIntegerValueField(.keyboardEventKeycode))
            return MacroEvent(type: .keyUp, timestamp: timestamp, keyCode: key, eventFlags: flags)

        case .flagsChanged:
            let key = UInt16(cgEvent.getIntegerValueField(.keyboardEventKeycode))
            return MacroEvent(type: .flagsChanged, timestamp: timestamp, keyCode: key, eventFlags: flags)

        default:
            return MacroEvent(type: .mouseMove, timestamp: timestamp, eventFlags: flags)
        }
    }
}

private let eventTapCallback: CGEventTapCallBack = { proxy, type, event, userInfo in
    guard let userInfo else { return Unmanaged.passRetained(event) }

    let recorder = Unmanaged<EventRecorder>.fromOpaque(userInfo).takeUnretainedValue()

    if type == .tapDisabledByTimeout {
        if let tap = recorder.eventTap {
            CGEvent.tapEnable(tap: tap, enable: true)
        }
        return Unmanaged.passRetained(event)
    }

    guard type != .tapDisabledByUserInput else {
        return Unmanaged.passRetained(event)
    }

    // Skip events when Tappy's own UI is active (avoids recording Record/Stop button interactions)
    if recorder.isAppFrontmost {
        return Unmanaged.passRetained(event)
    }

    let macroEvent = recorder.buildEvent(cgEvent: event, type: type)
    Task { @MainActor [recorder] in
        recorder.append(event: macroEvent)
    }

    return Unmanaged.passRetained(event)
}
