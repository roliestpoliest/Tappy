import Foundation

struct InputRecording: Codable, Identifiable {
    let id: UUID
    var name: String
    let dateCreated: Date
    let events: [InputEvent]

    var duration: TimeInterval {
        events.last?.timestamp ?? 0
    }

    init(name: String, events: [InputEvent]) {
        self.id = UUID()
        self.name = name
        self.dateCreated = Date()
        self.events = events
    }
}
