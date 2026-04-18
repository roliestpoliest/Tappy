//
//  MouseClickMonitor.swift
//  Tappy
//
//  Created by ujwal joshi on 4/17/26.
//

import Cocoa

class MouseClickMonitor {

    private var monitor: Any?

    func start() {
        monitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { event in

            let location = NSEvent.mouseLocation

            switch event.type {
            case .leftMouseDown:
                print("Left click at \(location)")
            case .rightMouseDown:
                print("Right click at \(location)")
            default:
                break
            }
        }
    }

    func stop() {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }
}
