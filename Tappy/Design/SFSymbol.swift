import Foundation

extension MacroEventType {
    var sfSymbolName: String {
        switch self {
        case .leftMouseDown, .leftMouseUp:          return "cursorarrow.click"
        case .rightMouseDown, .rightMouseUp:        return "cursorarrow.click.2"
        case .middleMouseDown, .middleMouseUp:      return "cursorarrow"
        case .leftMouseDragged, .rightMouseDragged: return "hand.draw"
        case .scrollWheel:                          return "arrow.up.and.down"
        case .keyDown, .keyUp:                      return "keyboard"
        case .flagsChanged:                         return "command"
        }
    }

    var displayName: String {
        switch self {
        case .leftMouseDown:     return "Left Mouse Down"
        case .leftMouseUp:       return "Left Mouse Up"
        case .rightMouseDown:    return "Right Mouse Down"
        case .rightMouseUp:      return "Right Mouse Up"
        case .middleMouseDown:   return "Middle Mouse Down"
        case .middleMouseUp:     return "Middle Mouse Up"
        case .leftMouseDragged:  return "Drag"
        case .rightMouseDragged: return "Right Drag"
        case .scrollWheel:       return "Scroll"
        case .keyDown:           return "Key Down"
        case .keyUp:             return "Key Up"
        case .flagsChanged:      return "Modifier"
        }
    }
}
