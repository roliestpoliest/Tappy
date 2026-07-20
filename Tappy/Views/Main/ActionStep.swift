import Foundation

struct TypedTextStep: Identifiable, Equatable {
    let id: UUID
    let text: String
    let startTimestamp: TimeInterval
    let endTimestamp: TimeInterval
    let underlyingEventIDs: [UUID]
}

struct KeyPressStep: Identifiable, Equatable {
    let id: UUID
    let label: String
    let keyCode: UInt16
    let startTimestamp: TimeInterval
    let endTimestamp: TimeInterval
    let underlyingEventIDs: [UUID]
}

enum ActionStep: Identifiable, Equatable {
    case single(MacroEvent)
    case typing(TypedTextStep)
    case keyPress(KeyPressStep)

    var id: UUID {
        switch self {
        case .single(let e):   return e.id
        case .typing(let g):   return g.id
        case .keyPress(let p): return p.id
        }
    }

    var startTimestamp: TimeInterval {
        switch self {
        case .single(let e):   return e.timestamp
        case .typing(let g):   return g.startTimestamp
        case .keyPress(let p): return p.startTimestamp
        }
    }

    var endTimestamp: TimeInterval {
        switch self {
        case .single(let e):   return e.timestamp
        case .typing(let g):   return g.endTimestamp
        case .keyPress(let p): return p.endTimestamp
        }
    }

    var underlyingEventIDs: [UUID] {
        switch self {
        case .single(let e):   return [e.id]
        case .typing(let g):   return g.underlyingEventIDs
        case .keyPress(let p): return p.underlyingEventIDs
        }
    }
}

extension ActionStep {
    // Max seconds between two consecutive characters before we split a typing run.
    static let typingGapThreshold: TimeInterval = 2.0

    // CGEventFlags bits that disqualify a keyDown from being treated as "typing".
    // Command, Option, Control → these produce shortcuts, not text.
    // Shift and Caps Lock are allowed (they drive capitalization).
    private static let disqualifyingModifiersMask: UInt64 =
        0x100000 | 0x080000 | 0x040000  // cmd | opt | ctrl

    static func buildSteps(from events: [MacroEvent]) -> [ActionStep] {
        // Pass 1: pair each typeable keyDown with the next keyUp of the same keyCode.
        var typingKeyUpPartner: [UUID: UUID] = [:]
        for (i, event) in events.enumerated() where isTypeableKeyDown(event) {
            for j in (i + 1) ..< events.count
                where events[j].type == .keyUp && events[j].keyCode == event.keyCode {
                typingKeyUpPartner[event.id] = events[j].id
                break
            }
        }
        let absorbedTypingKeyUpIDs = Set(typingKeyUpPartner.values)

        // Pass 2: walk events; produce .typing, .keyPress, and .single steps.
        var steps: [ActionStep] = []
        var groupChars: String = ""
        var groupEventIDs: [UUID] = []
        var groupStart: TimeInterval = 0
        var groupLastCharTs: TimeInterval = 0
        var groupEndTs: TimeInterval = 0

        func flushGroup() {
            guard !groupChars.isEmpty else { return }
            steps.append(.typing(TypedTextStep(
                id: UUID(),
                text: groupChars,
                startTimestamp: groupStart,
                endTimestamp: groupEndTs,
                underlyingEventIDs: groupEventIDs
            )))
            groupChars = ""
            groupEventIDs = []
        }

        var i = 0
        while i < events.count {
            let event = events[i]

            if absorbedTypingKeyUpIDs.contains(event.id) {
                groupEndTs = max(groupEndTs, event.timestamp)
                i += 1
                continue
            }

            if isTypeableKeyDown(event), let char = event.characters, !char.isEmpty {
                let gapExceeded = !groupChars.isEmpty
                    && (event.timestamp - groupLastCharTs) > typingGapThreshold
                if gapExceeded { flushGroup() }
                if groupChars.isEmpty { groupStart = event.timestamp }
                groupChars.append(char)
                groupEventIDs.append(event.id)
                if let partnerID = typingKeyUpPartner[event.id] {
                    groupEventIDs.append(partnerID)
                }
                groupLastCharTs = event.timestamp
                groupEndTs = max(groupEndTs, event.timestamp)
                i += 1
                continue
            }

            // Not a typing candidate — flush any open typing group first.
            flushGroup()

            // Try to consolidate an isolated keyDown + adjacent matching keyUp
            // into a single .keyPress step (e.g. Return, Escape, arrows).
            if event.type == .keyDown,
               i + 1 < events.count,
               events[i + 1].type == .keyUp,
               events[i + 1].keyCode == event.keyCode {
                let keyUp = events[i + 1]
                let label = keyDisplayLabel(
                    keyCode: event.keyCode ?? 0,
                    characters: event.characters
                )
                steps.append(.keyPress(KeyPressStep(
                    id: UUID(),
                    label: label,
                    keyCode: event.keyCode ?? 0,
                    startTimestamp: event.timestamp,
                    endTimestamp: keyUp.timestamp,
                    underlyingEventIDs: [event.id, keyUp.id]
                )))
                i += 2
                continue
            }

            steps.append(.single(event))
            i += 1
        }
        flushGroup()
        return steps
    }

    private static func isTypeableKeyDown(_ event: MacroEvent) -> Bool {
        guard event.type == .keyDown,
              let chars = event.characters,
              chars.count == 1,
              let scalar = chars.unicodeScalars.first,
              scalar.value >= 0x20, scalar.value != 0x7F else { return false }
        let flags = event.modifierFlags ?? 0
        return (flags & disqualifyingModifiersMask) == 0
    }

    // Human-friendly label for macOS virtual key codes. Falls back to the
    // event's `characters` string if it's printable, else "Key <code>".
    static func keyDisplayLabel(keyCode: UInt16, characters: String?) -> String {
        switch keyCode {
        case 36:  return "Return"
        case 76:  return "Enter"          // numeric keypad
        case 48:  return "Tab"
        case 49:  return "Space"
        case 51:  return "Delete"
        case 53:  return "Escape"
        case 117: return "Forward Delete"
        case 123: return "\u{2190}"       // ←
        case 124: return "\u{2192}"       // →
        case 125: return "\u{2193}"       // ↓
        case 126: return "\u{2191}"       // ↑
        case 115: return "Home"
        case 119: return "End"
        case 116: return "Page Up"
        case 121: return "Page Down"
        case 122: return "F1"
        case 120: return "F2"
        case 99:  return "F3"
        case 118: return "F4"
        case 96:  return "F5"
        case 97:  return "F6"
        case 98:  return "F7"
        case 100: return "F8"
        case 101: return "F9"
        case 109: return "F10"
        case 103: return "F11"
        case 111: return "F12"
        default:
            if let c = characters, !c.isEmpty,
               let scalar = c.unicodeScalars.first,
               scalar.value >= 0x20, scalar.value != 0x7F {
                return c.uppercased()
            }
            return "Key \(keyCode)"
        }
    }

    static func keyIconName(keyCode: UInt16) -> String {
        switch keyCode {
        case 36, 76: return "return"
        case 48:     return "arrow.right.to.line"
        case 49:     return "space"
        case 51:     return "delete.left"
        case 53:     return "escape"
        case 117:    return "delete.right"
        case 123:    return "arrow.left"
        case 124:    return "arrow.right"
        case 125:    return "arrow.down"
        case 126:    return "arrow.up"
        default:     return "keyboard"
        }
    }
}

extension ActionStep {
    var iconName: String {
        switch self {
        case .single(let e):   return e.type.sfSymbolName
        case .typing:          return "keyboard"
        case .keyPress(let p): return Self.keyIconName(keyCode: p.keyCode)
        }
    }

    var displayName: String {
        switch self {
        case .single(let e):   return e.type.displayName
        case .typing:          return "Type"
        case .keyPress:        return "Press"
        }
    }

    var detailString: String {
        switch self {
        case .single(let e):
            return Self.singleDetailString(for: e)
        case .typing(let g):
            let escaped = g.text
                .replacingOccurrences(of: "\\", with: "\\\\")
                .replacingOccurrences(of: "\"", with: "\\\"")
            return "\"\(escaped)\""
        case .keyPress(let p):
            return "\"\(p.label)\""
        }
    }

    private static func singleDetailString(for event: MacroEvent) -> String {
        switch event.type {
        case .leftMouseDown, .leftMouseUp,
             .rightMouseDown, .rightMouseUp,
             .middleMouseDown, .middleMouseUp,
             .leftMouseDragged, .rightMouseDragged:
            if let p = event.position { return "at (\(Int(p.x)), \(Int(p.y)))" }
            return "\u{2014}"
        case .scrollWheel:
            let dx = event.scrollDeltaX ?? 0
            let dy = event.scrollDeltaY ?? 0
            return String(format: "\u{0394}x %.0f, \u{0394}y %.0f", dx, dy)
        case .keyDown, .keyUp, .flagsChanged:
            if let chars = event.characters, !chars.isEmpty {
                return "\"\(chars)\""
            }
            return "keycode \(event.keyCode ?? 0)"
        }
    }
}
