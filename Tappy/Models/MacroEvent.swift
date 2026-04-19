import CoreGraphics
import Foundation

enum MacroEventType: String, Codable {
    case mouseMove
    case mouseLeftDown, mouseLeftUp
    case mouseRightDown, mouseRightUp
    case mouseOtherDown, mouseOtherUp
    case scrollWheel
    case keyDown, keyUp
    case flagsChanged
}

struct MacroEvent: Codable, Identifiable {
    let id: UUID
    let type: MacroEventType
    let timestamp: TimeInterval
    let position: CGPoint?
    let keyCode: UInt16?
    let eventFlags: UInt64
    let scrollDeltaX: Int32
    let scrollDeltaY: Int32
    let mouseButton: Int32

    nonisolated init(
        type: MacroEventType,
        timestamp: TimeInterval,
        position: CGPoint? = nil,
        keyCode: UInt16? = nil,
        eventFlags: UInt64 = 0,
        scrollDeltaX: Int32 = 0,
        scrollDeltaY: Int32 = 0,
        mouseButton: Int32 = 0
    ) {
        self.id = UUID()
        self.type = type
        self.timestamp = timestamp
        self.position = position
        self.keyCode = keyCode
        self.eventFlags = eventFlags
        self.scrollDeltaX = scrollDeltaX
        self.scrollDeltaY = scrollDeltaY
        self.mouseButton = mouseButton
    }
}

