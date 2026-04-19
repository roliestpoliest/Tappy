import Foundation

struct MacroRecording: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    let createdAt: Date
    var events: [MacroEvent]
    var duration: TimeInterval

    init(name: String, events: [MacroEvent] = []) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        self.events = events
        self.duration = events.last?.timestamp ?? 0
    }

    static var storageDirectory: URL {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return appSupport.appendingPathComponent("Tappy", isDirectory: true)
    }

    var fileURL: URL {
        MacroRecording.storageDirectory
            .appendingPathComponent("\(id.uuidString).json")
    }

    func save() throws {
        let dir = MacroRecording.storageDirectory
        try FileManager.default.createDirectory(
            at: dir, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(self)
        try data.write(to: fileURL, options: .atomic)
    }

    func delete() throws {
        try FileManager.default.removeItem(at: fileURL)
    }

    static func loadAll() throws -> [MacroRecording] {
        let dir = storageDirectory
        guard FileManager.default.fileExists(atPath: dir.path) else { return [] }
        let urls = try FileManager.default.contentsOfDirectory(
            at: dir, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "json" }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return urls.compactMap { url in
            guard let data = try? Data(contentsOf: url) else { return nil }
            return try? decoder.decode(MacroRecording.self, from: data)
        }.sorted { $0.createdAt > $1.createdAt }
    }

    static func == (lhs: MacroRecording, rhs: MacroRecording) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension DateFormatter {
    static let recordingName: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return f
    }()
}

extension TimeInterval {
    var mmss: String {
        let total = Int(self)
        let m = total / 60
        let s = total % 60
        return String(format: "%d:%02d", m, s)
    }
}
