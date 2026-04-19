import Foundation

enum InputEventType: String, Codable {
    case leftMouseDown
    case leftMouseUp
    case mouseMoved
    case keyDown
    case keyUp
    case scrollWheel
}

struct InputEvent: Codable, Identifiable {
    let id: UUID
    let type: InputEventType
    let x: Double
    let y: Double
    let timestamp: TimeInterval // seconds since recording started

    // Keyboard fields (only set for key events)
    let keyCode: UInt16?
    let modifierFlags: UInt?

    // Scroll fields (only set for scroll events)
    let scrollDeltaX: Double?
    let scrollDeltaY: Double?

    var position: CGPoint {
        CGPoint(x: x, y: y)
    }

    init(
        type: InputEventType,
        position: CGPoint,
        timestamp: TimeInterval,
        keyCode: UInt16? = nil,
        modifierFlags: UInt? = nil,
        scrollDeltaX: Double? = nil,
        scrollDeltaY: Double? = nil
    ) {
        self.id = UUID()
        self.type = type
        self.x = position.x
        self.y = position.y
        self.timestamp = timestamp
        self.keyCode = keyCode
        self.modifierFlags = modifierFlags
        self.scrollDeltaX = scrollDeltaX
        self.scrollDeltaY = scrollDeltaY
    }
}
