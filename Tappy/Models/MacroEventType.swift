import CoreGraphics

enum MacroEventType: String, Codable {
    case leftMouseDown
    case leftMouseUp
    case rightMouseDown
    case rightMouseUp
    case middleMouseDown
    case middleMouseUp
    case leftMouseDragged
    case rightMouseDragged
    case scrollWheel
    case keyDown
    case keyUp
    case flagsChanged
}

extension MacroEventType {
    var isDragEvent: Bool {
        self == .leftMouseDragged || self == .rightMouseDragged
    }

    var isMouseEvent: Bool {
        switch self {
        case .leftMouseDown, .leftMouseUp, .rightMouseDown, .rightMouseUp,
             .middleMouseDown, .middleMouseUp, .leftMouseDragged, .rightMouseDragged:
            return true
        default:
            return false
        }
    }

    func toCGEventType() -> CGEventType {
        switch self {
        case .leftMouseDown:    return .leftMouseDown
        case .leftMouseUp:      return .leftMouseUp
        case .rightMouseDown:   return .rightMouseDown
        case .rightMouseUp:     return .rightMouseUp
        case .middleMouseDown:  return .otherMouseDown
        case .middleMouseUp:    return .otherMouseUp
        case .leftMouseDragged: return .leftMouseDragged
        case .rightMouseDragged: return .rightMouseDragged
        case .scrollWheel:      return .scrollWheel
        case .keyDown:          return .keyDown
        case .keyUp:            return .keyUp
        case .flagsChanged:     return .flagsChanged
        }
    }

    func toCGMouseButton() -> CGMouseButton {
        switch self {
        case .rightMouseDown, .rightMouseUp, .rightMouseDragged:
            return .right
        case .middleMouseDown, .middleMouseUp:
            return .center
        default:
            return .left
        }
    }
}
