import Foundation

struct MacroRecording: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    let createdAt: Date
    var duration: TimeInterval  // = events.last?.timestamp ?? 0; recomputed when events change
    var events: [MacroEvent]

    var eventCount: Int { events.count }
}
