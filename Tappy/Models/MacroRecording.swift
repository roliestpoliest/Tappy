import Foundation

struct MacroRecording: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    let createdAt: Date
    let duration: TimeInterval  // = events.last?.timestamp ?? 0, stored at recording stop-time
    var events: [MacroEvent]

    var eventCount: Int { events.count }
}
