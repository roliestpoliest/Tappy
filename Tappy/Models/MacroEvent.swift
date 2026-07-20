import CoreGraphics
import Foundation

struct MacroEvent: Identifiable, Codable, Equatable {
    let id: UUID
    let type: MacroEventType

    /// Seconds elapsed since recording start (not wall-clock time).
    let timestamp: TimeInterval

    let position: CGPoint?
    let scrollDeltaX: CGFloat?
    let scrollDeltaY: CGFloat?

    let keyCode: UInt16?
    let modifierFlags: UInt64?  // raw CGEventFlags.rawValue
    let characters: String?     // display only — player uses keyCode + modifierFlags

    func withTimestamp(_ newTimestamp: TimeInterval) -> MacroEvent {
        MacroEvent(
            id: id,
            type: type,
            timestamp: newTimestamp,
            position: position,
            scrollDeltaX: scrollDeltaX,
            scrollDeltaY: scrollDeltaY,
            keyCode: keyCode,
            modifierFlags: modifierFlags,
            characters: characters
        )
    }
}
