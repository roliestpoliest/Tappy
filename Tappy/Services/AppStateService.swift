import Foundation
import Observation

@Observable
final class AppStateService {
    let accessibility: AccessibilityService
    let storage: StorageService
    let recorder: EventRecorderService
    let player: EventPlayerService

    var recordings: [MacroRecording] = []
    var selectedRecording: MacroRecording? = nil
    var playbackConfig: PlaybackConfig = .default

    var isCollapsed: Bool = false
    var colorScheme: AppColorScheme = .system

    init() {
        accessibility = AccessibilityService()
        storage = StorageService()
        recorder = EventRecorderService()
        player = EventPlayerService()

        if let raw = UserDefaults.standard.string(forKey: "colorScheme"),
           let stored = AppColorScheme(rawValue: raw) {
            colorScheme = stored
        }
    }

    func loadRecordings() {
        recordings = (try? storage.loadAllRecordings()) ?? []
        playbackConfig = (try? storage.loadPlaybackConfig()) ?? .default
    }

    func stopRecordingAndSave(name: String) throws {
        guard var recording = recorder.stopRecording() else { return }
        recording.name = name
        try storage.saveRecording(recording)
        recordings = try storage.loadAllRecordings()
        selectedRecording = recording
    }

    func deleteRecording(_ recording: MacroRecording) throws {
        try storage.deleteRecording(id: recording.id)
        recordings = try storage.loadAllRecordings()
        if selectedRecording?.id == recording.id { selectedRecording = nil }
    }

    func deleteEvents(_ eventIDs: [UUID], from recording: MacroRecording) throws {
        let removalSet = Set(eventIDs)
        guard !removalSet.isEmpty else { return }
        var updated = recording
        updated.events.removeAll { removalSet.contains($0.id) }
        updated.duration = updated.events.last?.timestamp ?? 0
        try storage.updateRecording(updated)
        recordings = try storage.loadAllRecordings()
        if selectedRecording?.id == updated.id { selectedRecording = updated }
    }

    func renameRecording(_ recording: MacroRecording, to newName: String) throws {
        var updated = recording
        updated.name = newName
        try storage.updateRecording(updated)
        recordings = try storage.loadAllRecordings()
        if selectedRecording?.id == updated.id { selectedRecording = updated }
    }

    func updatePlaybackConfig(_ config: PlaybackConfig) {
        playbackConfig = config
        try? storage.savePlaybackConfig(config)
    }

    var canPlay: Bool {
        accessibility.isGranted && selectedRecording != nil && !recorder.isRecording
    }

    func toggleCollapsed() {
        isCollapsed.toggle()
    }

    func toggleRecording() {
        if recorder.isRecording {
            let name = "Recording \(Date().formatted(date: .abbreviated, time: .shortened))"
            try? stopRecordingAndSave(name: name)
        } else {
            guard accessibility.isGranted else {
                accessibility.requestAccess()
                return
            }
            recorder.startRecording()
        }
    }

    func toggleColorScheme() {
        colorScheme = (colorScheme == .dark) ? .light : .dark
        persistColorScheme()
    }

    private func persistColorScheme() {
        UserDefaults.standard.set(colorScheme.rawValue, forKey: "colorScheme")
    }
}
