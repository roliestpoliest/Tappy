import Foundation
import SwiftUI
import Observation

@Observable
class RecordingStore {
    var recordings: [InputRecording] = []

    private var saveURL: URL {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        let dir = appSupport.appendingPathComponent("Tappy", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("recordings.json")
    }

    init() {
        load()
    }

    func add(_ recording: InputRecording) {
        recordings.append(recording)
        save()
    }

    func delete(at offsets: IndexSet) {
        recordings.remove(atOffsets: offsets)
        save()
    }

    func delete(id: UUID) {
        recordings.removeAll { $0.id == id }
        save()
    }

    func rename(id: UUID, to newName: String) {
        guard let index = recordings.firstIndex(where: { $0.id == id }) else { return }
        recordings[index].name = newName
        save()
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(recordings)
            try data.write(to: saveURL, options: .atomic)
        } catch {
            print("Failed to save recordings: \(error)")
        }
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: saveURL.path) else { return }
        do {
            let data = try Data(contentsOf: saveURL)
            recordings = try JSONDecoder().decode([InputRecording].self, from: data)
        } catch {
            print("Failed to load recordings: \(error)")
        }
    }
}
