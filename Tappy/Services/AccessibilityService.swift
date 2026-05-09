import AppKit
import ApplicationServices
import Foundation
import Observation

@Observable
final class AccessibilityService {
    var isGranted: Bool = false

    @ObservationIgnored private var pollTimer: Timer?
    @ObservationIgnored private var activeObserver: Any?

    init() {
        isGranted = AXIsProcessTrusted()
    }

    func requestAccess() {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [key: true] as NSDictionary
        isGranted = AXIsProcessTrustedWithOptions(options)
        if !isGranted {
            // Open the Accessibility pane directly — the AXIsProcessTrustedWithOptions
            // prompt is unreliable for sandboxed apps during development.
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
            startPolling()
        }
    }

    func refresh() {
        let trusted = AXIsProcessTrusted()
        if trusted != isGranted {
            isGranted = trusted
        }
        if trusted {
            stopPolling()
        }
    }

    private func startPolling() {
        stopPolling()

        // Fires immediately when the user returns from System Settings
        activeObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.refresh() }
        }

        // 1-second fallback in case the app-activate notification doesn't fire
        let timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.refresh() }
        }
        RunLoop.main.add(timer, forMode: .common)
        pollTimer = timer
    }

    private func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
        if let observer = activeObserver {
            NotificationCenter.default.removeObserver(observer)
            activeObserver = nil
        }
    }
}
