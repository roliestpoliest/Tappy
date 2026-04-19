import Cocoa
import Observation

@Observable
class HotkeyManager {
    static let recordKeyCode: UInt16 = 15   // R
    static let playKeyCode: UInt16 = 35     // P
    static let hotkeyModifiers: NSEvent.ModifierFlags = [.command, .shift]

    var recordTriggerCount = 0
    var playTriggerCount = 0

    private var globalMonitor: Any?
    private var localMonitor: Any?

    func start() {
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKey(event)
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKey(event)
            return event
        }
    }

    func stop() {
        if let globalMonitor { NSEvent.removeMonitor(globalMonitor); self.globalMonitor = nil }
        if let localMonitor { NSEvent.removeMonitor(localMonitor); self.localMonitor = nil }
    }

    private func handleKey(_ event: NSEvent) {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        guard flags == Self.hotkeyModifiers else { return }
        switch event.keyCode {
        case Self.recordKeyCode:
            recordTriggerCount += 1
        case Self.playKeyCode:
            playTriggerCount += 1
        default:
            break
        }
    }

    /// Returns true if the NSEvent matches a Tappy hotkey combo (used to filter from recorder).
    static func isHotkey(_ event: NSEvent) -> Bool {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        guard flags == hotkeyModifiers else { return false }
        return event.keyCode == recordKeyCode || event.keyCode == playKeyCode
    }
}
