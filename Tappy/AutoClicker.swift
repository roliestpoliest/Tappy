//
//  AutoClicker.swift
//  Tappy
//
//  Created by ujwal joshi on 4/17/26.
//

import Foundation
import Cocoa

class AutoClicker {
    private var isClicking = false
    private var globalMonitor: Any?
    private var localMonitor: Any?
    
    init() {
        setupEscapeMonitor()
    }
    
    func startClicking(at point: CGPoint, interval: TimeInterval = 0.1) {
        isClicking = true

        DispatchQueue.global(qos: .userInitiated).async {
            self.moveMouse(to: point)

            while self.isClicking {
                self.click(at: point)
                Thread.sleep(forTimeInterval: interval)
            }
        }
    }
    
    func stopClicking() {
        isClicking = false
    }
    
    private func setupEscapeMonitor() {
            // ✅ Global (when app NOT focused)
            globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
                if event.keyCode == 53 {
                    print("esc key hit")
                    self?.stopClicking()
                }
            }

            // ✅ Local (when app IS focused)
            localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                if event.keyCode == 53 {
                    print("esc key hit (local)")
                    self?.stopClicking()
                    return nil // swallow event (optional)
                }
                return event
            }
        }

    private func moveMouse(to point: CGPoint) {
        CGWarpMouseCursorPosition(point)
    }
    
    private func click(at point: CGPoint) {
        let mouseDown = CGEvent(
            mouseEventSource: nil,
            mouseType: .leftMouseUp,
            mouseCursorPosition: point,
            mouseButton: .left
        )

        let mouseUp = CGEvent(
            mouseEventSource: nil,
            mouseType: .leftMouseDown,
            mouseCursorPosition: point,
            mouseButton: .left
        )

        mouseDown?.post(tap: .cghidEventTap)
        mouseUp?.post(tap: .cghidEventTap)
    }

}
