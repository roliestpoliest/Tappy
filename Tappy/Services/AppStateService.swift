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

    var isCropping: Bool = false
    var cropRange: ClosedRange<TimeInterval>? = nil

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

    func duplicateRecording(_ recording: MacroRecording) throws {
        let copy = MacroRecording(
            id: UUID(),
            name: "Copy of \(recording.name)",
            createdAt: Date(),
            duration: recording.duration,
            events: recording.events
        )
        try storage.saveRecording(copy)
        recordings = try storage.loadAllRecordings()
        selectedRecording = copy
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
        accessibility.isGranted && selectedRecording != nil && !recorder.isRecording && !isCropping
    }

    func beginCropping() {
        guard let rec = selectedRecording else { return }
        if player.isPlaying { player.stop() }
        cropRange = 0...max(rec.duration, 0)
        isCropping = true
    }

    func cancelCropping() {
        isCropping = false
        cropRange = nil
    }

    func applyCrop(startTime: TimeInterval, endTime: TimeInterval) throws {
        guard let rec = selectedRecording, endTime > startTime else { return }
        let kept = rec.events.filter { $0.timestamp >= startTime && $0.timestamp <= endTime }
        guard !kept.isEmpty else { return }
        let shifted = kept.map { $0.withTimestamp($0.timestamp - startTime) }
        var updated = rec
        updated.events = shifted
        updated.duration = shifted.last?.timestamp ?? 0
        try storage.updateRecording(updated)
        recordings = try storage.loadAllRecordings()
        selectedRecording = updated
        cancelCropping()
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
