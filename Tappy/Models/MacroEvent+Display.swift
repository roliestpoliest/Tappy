import SwiftUI

extension MacroEvent {
    var typeIcon: String {
        switch type {
        case .mouseMove:                        return "cursorarrow.motionlines"
        case .mouseLeftDown, .mouseLeftUp:      return "cursorarrow.click"
        case .mouseRightDown, .mouseRightUp:    return "contextualmenu.and.cursorarrow"
        case .mouseOtherDown, .mouseOtherUp:    return "cursorarrow.click.2"
        case .scrollWheel:                      return "scroll"
        case .keyDown, .keyUp:                  return "keyboard"
        case .flagsChanged:                     return "command"
        }
    }

    var typeColor: Color {
        switch type {
        case .mouseMove:
            return .blue
        case .mouseLeftDown, .mouseLeftUp, .mouseRightDown, .mouseRightUp,
             .mouseOtherDown, .mouseOtherUp:
            return .purple
        case .scrollWheel:
            return .teal
        case .keyDown, .keyUp, .flagsChanged:
            return .orange
        }
    }

    var displayTitle: String {
        switch type {
        case .mouseMove:
            if let p = position { return "Move  (\(Int(p.x)), \(Int(p.y)))" }
            return "Move"
        case .mouseLeftDown:
            if let p = position { return "Left ↓  (\(Int(p.x)), \(Int(p.y)))" }
            return "Left ↓"
        case .mouseLeftUp:
            if let p = position { return "Left ↑  (\(Int(p.x)), \(Int(p.y)))" }
            return "Left ↑"
        case .mouseRightDown:
            if let p = position { return "Right ↓  (\(Int(p.x)), \(Int(p.y)))" }
            return "Right ↓"
        case .mouseRightUp:
            if let p = position { return "Right ↑  (\(Int(p.x)), \(Int(p.y)))" }
            return "Right ↑"
        case .mouseOtherDown:
            return "Button \(mouseButton) ↓"
        case .mouseOtherUp:
            return "Button \(mouseButton) ↑"
        case .scrollWheel:
            return "Scroll  Δx:\(scrollDeltaX) Δy:\(scrollDeltaY)"
        case .keyDown:
            return "\(keyName) ↓"
        case .keyUp:
            return "\(keyName) ↑"
        case .flagsChanged:
            return "Modifier"
        }
    }

    var isMouseMove: Bool { type == .mouseMove }

    private var keyName: String {
        guard let code = keyCode else { return "Key" }
        return Self.keyCodeNames[code] ?? "Key \(code)"
    }

    static let keyCodeNames: [UInt16: String] = [
        0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
        8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
        16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6",
        23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0",
        30: "]", 31: "O", 32: "U", 33: "[", 34: "I", 35: "P", 36: "Return",
        37: "L", 38: "J", 39: "'", 40: "K", 41: ";", 42: "\\", 43: ",",
        44: "/", 45: "N", 46: "M", 47: ".", 48: "Tab", 49: "Space",
        51: "Delete", 53: "Esc", 55: "⌘", 56: "⇧", 57: "Caps",
        58: "⌥", 59: "⌃", 60: "⇧R", 61: "⌥R", 62: "⌃R", 63: "fn",
        96: "F5", 97: "F6", 98: "F7", 99: "F3", 100: "F8", 101: "F9",
        103: "F11", 109: "F10", 111: "F12", 114: "Help", 115: "Home",
        116: "PgUp", 117: "Del→", 118: "F4", 119: "End",
        120: "F2", 121: "PgDn", 122: "F1",
        123: "←", 124: "→", 125: "↓", 126: "↑",
    ]
}
