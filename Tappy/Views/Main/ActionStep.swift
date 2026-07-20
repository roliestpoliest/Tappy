import Foundation

struct TypedTextStep: Identifiable, Equatable {
    let id: UUID
    let text: String
    let startTimestamp: TimeInterval
    let endTimestamp: TimeInterval
    let underlyingEventIDs: [UUID]
}

enum ActionStep: Identifiable, Equatable {
    case single(MacroEvent)
    case typing(TypedTextStep)

    var id: UUID {
        switch self {
        case .single(let e): return e.id
        case .typing(let g): return g.id
        }
    }

    var startTimestamp: TimeInterval {
        switch self {
        case .single(let e): return e.timestamp
        case .typing(let g): return g.startTimestamp
        }
    }

    var endTimestamp: TimeInterval {
        switch self {
        case .single(let e): return e.timestamp
        case .typing(let g): return g.endTimestamp
        }
    }

    var underlyingEventIDs: [UUID] {
        switch self {
        case .single(let e): return [e.id]
        case .typing(let g): return g.underlyingEventIDs
        }
    }
}

extension ActionStep {
    // Max seconds between two consecutive characters before we split the run.
    static let typingGapThreshold: TimeInterval = 2.0

    // CGEventFlags bits that disqualify a keyDown from being treated as "typing".
    // Command, Option, Control → these produce shortcuts, not text.
    // Shift and Caps Lock are allowed (they drive capitalization).
    private static let disqualifyingModifiersMask: UInt64 =
        0x100000 | 0x080000 | 0x040000  // cmd | opt | ctrl

    static func buildSteps(from events: [MacroEvent]) -> [ActionStep] {
        // Pass 1: pair each qualifying keyDown with the next keyUp of the same keyCode.
        var keyUpPartner: [UUID: UUID] = [:]
        for (i, event) in events.enumerated() where isTypeableKeyDown(event) {
            for j in (i + 1) ..< events.count
                where events[j].type == .keyUp && events[j].keyCode == event.keyCode {
                keyUpPartner[event.id] = events[j].id
                break
            }
        }
        let absorbedKeyUpIDs = Set(keyUpPartner.values)

        // Pass 2: walk events and build steps.
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

        for event in events {
            if absorbedKeyUpIDs.contains(event.id) {
                // This keyUp already belongs to a typing-group entry.
                groupEndTs = max(groupEndTs, event.timestamp)
                continue
            }

            if isTypeableKeyDown(event), let char = event.characters, !char.isEmpty {
                let gapExceeded = !groupChars.isEmpty
                    && (event.timestamp - groupLastCharTs) > typingGapThreshold
                if gapExceeded { flushGroup() }

                if groupChars.isEmpty { groupStart = event.timestamp }
                groupChars.append(char)
                groupEventIDs.append(event.id)
                if let partnerID = keyUpPartner[event.id] {
                    groupEventIDs.append(partnerID)
                }
                groupLastCharTs = event.timestamp
                groupEndTs = max(groupEndTs, event.timestamp)
            } else {
                flushGroup()
                steps.append(.single(event))
            }
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
}

extension ActionStep {
    var iconName: String {
        switch self {
        case .single(let e): return e.type.sfSymbolName
        case .typing:        return "keyboard"
        }
    }

    var displayName: String {
        switch self {
        case .single(let e): return e.type.displayName
        case .typing:        return "Type"
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
        }
    }

    private static func singleDetailString(for event: MacroEvent) -> String {
        switch event.type {
        case .leftMouseDown, .leftMouseUp,
             .rightMouseDown, .rightMouseUp,
             .middleMouseDown, .middleMouseUp,
             .leftMouseDragged, .rightMouseDragged:
            if let p = event.position { return "at (\(Int(p.x)), \(Int(p.y)))" }
            return "—"
        case .scrollWheel:
            let dx = event.scrollDeltaX ?? 0
            let dy = event.scrollDeltaY ?? 0
            return String(format: "Δx %.0f, Δy %.0f", dx, dy)
        case .keyDown, .keyUp, .flagsChanged:
            if let chars = event.characters, !chars.isEmpty {
                return "\"\(chars)\""
            }
            return "keycode \(event.keyCode ?? 0)"
        }
    }
}
