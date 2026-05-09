import CoreGraphics
import Foundation
import Observation

@Observable
final class EventRecorderService {
    var isRecording: Bool = false

    @ObservationIgnored private var eventBuffer: [MacroEvent] = []
    @ObservationIgnored private var recordingStartTime: CFAbsoluteTime = 0
    @ObservationIgnored private var eventTap: CFMachPort?
    @ObservationIgnored private var runLoopSource: CFRunLoopSource?

    // MARK: - Public Interface

    func startRecording() {
        guard !isRecording else { return }
        eventBuffer.removeAll()
        recordingStartTime = CFAbsoluteTimeGetCurrent()
        isRecording = true
        addInputEventListeners()
    }

    func stopRecording() -> MacroRecording? {
        removeInputEventListeners()
        isRecording = false
        defer { eventBuffer.removeAll() }
        guard !eventBuffer.isEmpty else { return nil }
        let duration = eventBuffer.last!.timestamp
        return MacroRecording(
            id: UUID(),
            name: "Recording \(Date().formatted(date: .abbreviated, time: .shortened))",
            createdAt: Date(),
            duration: duration,
            events: eventBuffer
        )
    }

    // MARK: - Input Listener Lifecycle

    private func addInputEventListeners() {
        let eventMask: CGEventMask =
            (1 << CGEventType.leftMouseDown.rawValue)
            | (1 << CGEventType.leftMouseUp.rawValue)
            | (1 << CGEventType.rightMouseDown.rawValue)
            | (1 << CGEventType.rightMouseUp.rawValue)
            | (1 << CGEventType.otherMouseDown.rawValue)
            | (1 << CGEventType.otherMouseUp.rawValue)
            | (1 << CGEventType.leftMouseDragged.rawValue)
            | (1 << CGEventType.rightMouseDragged.rawValue)
            | (1 << CGEventType.scrollWheel.rawValue)
            | (1 << CGEventType.keyDown.rawValue)
            | (1 << CGEventType.keyUp.rawValue)
            | (1 << CGEventType.flagsChanged.rawValue)

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: eventMask,
            callback: { _, cgType, cgEvent, userInfo -> Unmanaged<CGEvent>? in
                guard let userInfo else { return nil }

                // Extract all data from the CGEvent immediately — it may be freed after this callback returns.
                let rawTimestamp = CFAbsoluteTimeGetCurrent()
                let position      = cgEvent.location
                let scrollDeltaX  = cgEvent.getDoubleValueField(.scrollWheelEventDeltaAxis2)
                let scrollDeltaY  = cgEvent.getDoubleValueField(.scrollWheelEventDeltaAxis1)
                let keyCode       = UInt16(cgEvent.getIntegerValueField(.keyboardEventKeycode))
                let modifierFlags = cgEvent.flags.rawValue

                var charLen = 0
                cgEvent.keyboardGetUnicodeString(
                    maxStringLength: 0, actualStringLength: &charLen, unicodeString: nil)
                var unicodeChars = [UniChar](repeating: 0, count: max(charLen, 0))
                if charLen > 0 {
                    cgEvent.keyboardGetUnicodeString(
                        maxStringLength: charLen, actualStringLength: &charLen, unicodeString: &unicodeChars)
                }

                let recorder = Unmanaged<EventRecorderService>.fromOpaque(userInfo).takeUnretainedValue()
                DispatchQueue.main.async {
                    MainActor.assumeIsolated {
                        recorder.append(
                            cgType: cgType,
                            rawTimestamp: rawTimestamp,
                            position: position,
                            scrollDeltaX: scrollDeltaX,
                            scrollDeltaY: scrollDeltaY,
                            keyCode: keyCode,
                            modifierFlags: modifierFlags,
                            unicodeChars: unicodeChars,
                            charLen: charLen
                        )
                    }
                }
                return Unmanaged.passRetained(cgEvent)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            isRecording = false
            return
        }

        eventTap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    private func removeInputEventListeners() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            eventTap = nil
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
            runLoopSource = nil
        }
    }

    // MARK: - Event Building

    private func append(
        cgType: CGEventType,
        rawTimestamp: CFAbsoluteTime,
        position: CGPoint,
        scrollDeltaX: Double,
        scrollDeltaY: Double,
        keyCode: UInt16,
        modifierFlags: UInt64,
        unicodeChars: [UniChar],
        charLen: Int
    ) {
        guard isRecording else { return }

        let macroType: MacroEventType
        switch cgType {
        case .leftMouseDown:     macroType = .leftMouseDown
        case .leftMouseUp:       macroType = .leftMouseUp
        case .rightMouseDown:    macroType = .rightMouseDown
        case .rightMouseUp:      macroType = .rightMouseUp
        case .otherMouseDown:    macroType = .middleMouseDown
        case .otherMouseUp:      macroType = .middleMouseUp
        case .leftMouseDragged:  macroType = .leftMouseDragged
        case .rightMouseDragged: macroType = .rightMouseDragged
        case .scrollWheel:       macroType = .scrollWheel
        case .keyDown:           macroType = .keyDown
        case .keyUp:             macroType = .keyUp
        case .flagsChanged:      macroType = .flagsChanged
        default: return
        }

        let timestamp = rawTimestamp - recordingStartTime

        let isKeyEvent = cgType == .keyDown || cgType == .keyUp || cgType == .flagsChanged
        let isScrollEvent = cgType == .scrollWheel

        let event = MacroEvent(
            id: UUID(),
            type: macroType,
            timestamp: timestamp,
            position: isKeyEvent ? nil : position,
            scrollDeltaX: isScrollEvent ? scrollDeltaX : nil,
            scrollDeltaY: isScrollEvent ? scrollDeltaY : nil,
            keyCode: isKeyEvent ? keyCode : nil,
            modifierFlags: isKeyEvent ? modifierFlags : nil,
            characters: isKeyEvent ? deriveCharacters(keyCode: keyCode, unicodeChars: unicodeChars, charLen: charLen) : nil
        )

        eventBuffer.append(event)
    }

    private func deriveCharacters(keyCode: UInt16, unicodeChars: [UniChar], charLen: Int) -> String {
        if let label = specialKeyLabels[keyCode] { return label }
        guard charLen > 0 else { return "" }
        return String(utf16CodeUnits: unicodeChars, count: charLen)
    }
}

// MARK: - Key Label Table

private let specialKeyLabels: [UInt16: String] = [
    36: "Return",
    48: "Tab",
    49: "Space",
    51: "Delete",
    53: "Escape",
    96: "F5",   97: "F6",   98: "F7",   99: "F3",
    100: "F8",  101: "F9",  103: "F11", 109: "F10",
    111: "F12", 118: "F4",  120: "F2",  122: "F1",
    115: "Home",  116: "PgUp", 117: "⌦",
    119: "End",   121: "PgDn",
    123: "←",  124: "→",  125: "↓",  126: "↑"
]
