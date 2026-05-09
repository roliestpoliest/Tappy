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

    init() {
        accessibility = AccessibilityService()
        storage = StorageService()
        recorder = EventRecorderService()
        player = EventPlayerService()
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
}
