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

        // Fire immediately when the user returns from System Settings
        activeObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.refresh() }
        }

        // Timer as fallback in case the notification doesn't fire
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
