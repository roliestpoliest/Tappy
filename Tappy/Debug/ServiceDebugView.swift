import SwiftUI

struct ServiceDebugView: View {
    @Environment(AppStateService.self) private var appState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // MARK: Accessibility
                GroupBox("AccessibilityService") {
                    LabeledRow("isGranted", value: appState.accessibility.isGranted ? "✅ granted" : "❌ denied")
                    HStack {
                        Button("Request Access") { appState.accessibility.requestAccess() }
                        Button("Refresh") { appState.accessibility.refresh() }
                    }
                }

                // MARK: Storage
                GroupBox("StorageService") {
                    LabeledRow("Recordings on disk", value: "\(appState.recordings.count)")
                    HStack {
                        Button("Reload") { appState.loadRecordings() }
                        Button("Save test recording") { saveTestRecording() }
                        Button("Delete all") { deleteAllRecordings() }
                    }
                    ForEach(appState.recordings) { rec in
                        Text("• \(rec.name) — \(rec.eventCount) events, \(String(format: "%.2fs", rec.duration))")
                            .font(.caption)
                    }
                }

                // MARK: Recorder
                GroupBox("EventRecorderService") {
                    LabeledRow("isRecording", value: appState.recorder.isRecording ? "🔴 recording" : "⚫ idle")
                    HStack {
                        Button("Start") {
                            guard appState.accessibility.isGranted else { return }
                            appState.recorder.startRecording()
                        }
                        Button("Stop & Save") {
                            try? appState.stopRecordingAndSave(name: "Debug Recording")
                        }
                    }
                }

                // MARK: Player
                GroupBox("EventPlayerService") {
                    LabeledRow("isPlaying", value: appState.player.isPlaying ? "▶️ playing" : "⏹ idle")
                    LabeledRow("isPaused", value: appState.player.isPaused ? "⏸ paused" : "—")
                    LabeledRow("currentEventIndex", value: "\(appState.player.currentEventIndex)")
                    LabeledRow("currentIteration", value: "\(appState.player.currentIteration)")
                    LabeledRow("canPlay", value: appState.canPlay ? "✅ yes" : "❌ no")
                    HStack {
                        Button("Play") {
                            guard appState.canPlay, let rec = appState.selectedRecording else { return }
                            appState.player.play(recording: rec, config: appState.playbackConfig)
                        }
                        Button("Pause") { appState.player.pause() }
                        Button("Resume") { appState.player.resume() }
                        Button("Stop") { appState.player.stop() }
                    }
                }

                // MARK: Playback Config
                GroupBox("PlaybackConfig") {
                    LabeledRow("speed", value: "\(appState.playbackConfig.speed)x")

                    HStack {
                        Text("repeatCount").foregroundStyle(.secondary).font(.caption)
                        Spacer()
                        Button("−") { updateRepeat(by: -1) }
                            .disabled(appState.playbackConfig.repeatCount <= 1 || appState.playbackConfig.isLooping)
                        Text("\(appState.playbackConfig.repeatCount)")
                            .fontWeight(.medium)
                            .font(.caption)
                            .frame(minWidth: 24, alignment: .center)
                        Button("+") { updateRepeat(by: 1) }
                            .disabled(appState.playbackConfig.isLooping)
                    }

                    HStack {
                        Text("isLooping").foregroundStyle(.secondary).font(.caption)
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { appState.playbackConfig.isLooping },
                            set: { newValue in
                                var config = appState.playbackConfig
                                config.isLooping = newValue
                                appState.updatePlaybackConfig(config)
                            }
                        ))
                        .labelsHidden()
                        .toggleStyle(.switch)
                    }

                    HStack {
                        Button("Speed 0.5x") { updateSpeed(0.5) }
                        Button("Speed 1x")   { updateSpeed(1.0) }
                        Button("Speed 2x")   { updateSpeed(2.0) }
                    }
                }

                // MARK: Recordings list — select for playback
                if !appState.recordings.isEmpty {
                    GroupBox("Select Recording for Playback") {
                        ForEach(appState.recordings) { rec in
                            Button(action: { appState.selectedRecording = rec }) {
                                HStack {
                                    Text(appState.selectedRecording?.id == rec.id ? "▶ " : "   ")
                                    Text(rec.name)
                                }
                            }
                        }
                    }
                }

                // MARK: BezierInterpolationService
                GroupBox("BezierInterpolationService") {
                    let start = CGPoint(x: 0, y: 0)
                    let end   = CGPoint(x: 300, y: 200)
                    let path  = BezierInterpolationService.interpolate(from: start, to: end)
                    LabeledRow("Points for (0,0)→(300,200)", value: "\(path.count) steps")
                    LabeledRow("First point", value: "(\(Int(path.first?.x ?? 0)), \(Int(path.first?.y ?? 0)))")
                    LabeledRow("Last point",  value: "(\(Int(path.last?.x ?? 0)), \(Int(path.last?.y ?? 0)))")
                }
            }
            .padding()
        }
        .frame(minWidth: 560, minHeight: 600)
    }

    // MARK: - Helpers

    private func updateRepeat(by delta: Int) {
        var config = appState.playbackConfig
        config.repeatCount = max(1, config.repeatCount + delta)
        appState.updatePlaybackConfig(config)
    }

    private func updateSpeed(_ speed: Double) {
        var config = appState.playbackConfig
        config.speed = speed
        appState.updatePlaybackConfig(config)
    }

    private func saveTestRecording() {
        let event = MacroEvent(
            id: UUID(),
            type: .leftMouseDown,
            timestamp: 0.0,
            position: CGPoint(x: 100, y: 200),
            scrollDeltaX: nil,
            scrollDeltaY: nil,
            keyCode: nil,
            modifierFlags: nil,
            characters: nil
        )
        let recording = MacroRecording(
            id: UUID(),
            name: "Test Recording \(Int.random(in: 1...99))",
            createdAt: Date(),
            duration: 0.0,
            events: [event]
        )
        try? appState.storage.saveRecording(recording)
        appState.loadRecordings()
    }

    private func deleteAllRecordings() {
        for rec in appState.recordings {
            try? appState.storage.deleteRecording(id: rec.id)
        }
        appState.loadRecordings()
    }
}

private struct LabeledRow: View {
    let label: String
    let value: String
    init(_ label: String, value: String) {
        self.label = label
        self.value = value
    }
    var body: some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).fontWeight(.medium)
        }
        .font(.caption)
    }
}
