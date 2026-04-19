import SwiftUI
import ApplicationServices
import UserNotifications

struct ContentView: View {
    @State private var store = RecordingStore()
    @State private var recorder = InputRecorder()
    @State private var player = InputPlayer()
    @State private var hotkeyManager = HotkeyManager()
    @State private var playbackSpeed: Double = 1.0
    @State private var selectedRecordingID: UUID?

    // Save recording alert
    @State private var showingNamePrompt = false
    @State private var newRecordingName = ""
    @State private var pendingEvents: [InputEvent] = []

    // Rename alert
    @State private var showingRenamePrompt = false
    @State private var renameText = ""
    @State private var renamingID: UUID?

    // Repeat settings
    @State private var repeatOption = 0  // 0 = once, 1 = N times, 2 = forever
    @State private var repeatCount = 2

    var body: some View {
        VStack(spacing: 0) {
            headerView
            Divider()
            recordingsList
            Divider()
            controlsView
        }
        .frame(minWidth: 340, minHeight: 420)
        .task {
            hotkeyManager.start()
            _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
        }
        .onChange(of: hotkeyManager.recordTriggerCount) { _, _ in
            toggleRecording()
        }
        .onChange(of: hotkeyManager.playTriggerCount) { _, _ in
            togglePlayback()
        }
        .onChange(of: player.isPlaying) { old, new in
            if old && !new {
                postNotification("Playback finished")
            }
        }
        .alert("Name Your Recording", isPresented: $showingNamePrompt) {
            TextField("Recording name", text: $newRecordingName)
            Button("Save") {
                let name = newRecordingName.trimmingCharacters(in: .whitespaces)
                let recording = InputRecording(
                    name: name.isEmpty ? "Untitled" : name,
                    events: pendingEvents
                )
                store.add(recording)
                newRecordingName = ""
                pendingEvents = []
            }
            Button("Discard", role: .cancel) {
                pendingEvents = []
            }
        } message: {
            Text("\(pendingEvents.count) events captured")
        }
        .alert("Rename Recording", isPresented: $showingRenamePrompt) {
            TextField("New name", text: $renameText)
            Button("Rename") {
                let name = renameText.trimmingCharacters(in: .whitespaces)
                if let id = renamingID, !name.isEmpty {
                    store.rename(id: id, to: name)
                }
                renamingID = nil
                renameText = ""
            }
            Button("Cancel", role: .cancel) {
                renamingID = nil
                renameText = ""
            }
        }
    }

    // MARK: - Actions

    private func toggleRecording() {
        if recorder.isRecording {
            pendingEvents = recorder.stopRecording()
            postNotification("Recording stopped — \(pendingEvents.count) events captured")
            if !pendingEvents.isEmpty {
                NSApp.activate(ignoringOtherApps: true)
                showingNamePrompt = true
            }
        } else if !player.isPlaying {
            recorder.startRecording()
        }
    }

    private func togglePlayback() {
        if player.isPlaying {
            player.stop()
        } else if !recorder.isRecording {
            guard let id = selectedRecordingID,
                  let recording = store.recordings.first(where: { $0.id == id })
            else { return }
            player.playbackSpeed = playbackSpeed
            switch repeatOption {
            case 1:  player.repeatMode = .times(repeatCount)
            case 2:  player.repeatMode = .forever
            default: player.repeatMode = .once
            }
            player.play(recording: recording)
        }
    }

    private func postNotification(_ body: String) {
        let content = UNMutableNotificationContent()
        content.title = "Tappy"
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: 6) {
            Text("Tappy")
                .font(.title2.bold())

            if !AXIsProcessTrusted() {
                Label("Accessibility permission required", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .font(.caption)
            }

            if recorder.isRecording {
                Label(
                    "Recording... \(recorder.capturedEventCount) events",
                    systemImage: "record.circle.fill"
                )
                .foregroundStyle(.red)
                .font(.caption)
            } else if player.isPlaying {
                Label(
                    playbackStatusText,
                    systemImage: "play.circle.fill"
                )
                .foregroundStyle(.green)
                .font(.caption)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal)
    }

    private var playbackStatusText: String {
        let base = "Playing back — right-click to stop"
        switch player.repeatMode {
        case .once:
            return base
        case .times(let total):
            return "\(base) (loop \(player.currentIteration)/\(total))"
        case .forever:
            return "\(base) (loop \(player.currentIteration))"
        }
    }

    // MARK: - Recordings List

    private var recordingsList: some View {
        List(selection: $selectedRecordingID) {
            if store.recordings.isEmpty {
                Text("No recordings yet")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.clear)
            } else {
                ForEach(store.recordings) { recording in
                    RecordingRow(recording: recording)
                        .tag(recording.id)
                        .contextMenu {
                            Button("Rename...") {
                                renamingID = recording.id
                                renameText = recording.name
                                showingRenamePrompt = true
                            }
                            Divider()
                            Button("Delete", role: .destructive) {
                                if selectedRecordingID == recording.id {
                                    selectedRecordingID = nil
                                }
                                store.delete(id: recording.id)
                            }
                        }
                }
                .onDelete { offsets in
                    store.delete(at: offsets)
                    selectedRecordingID = nil
                }
            }
        }
        .listStyle(.inset)
    }

    // MARK: - Controls

    private var controlsView: some View {
        VStack(spacing: 12) {
            // Speed slider
            HStack {
                Text("Speed:")
                    .font(.caption)
                Slider(value: $playbackSpeed, in: 0.25...4.0, step: 0.25)
                Text(String(format: "%.2fx", playbackSpeed))
                    .font(.caption.monospacedDigit())
                    .frame(width: 44, alignment: .trailing)
            }

            // Repeat picker
            HStack {
                Picker("Repeat:", selection: $repeatOption) {
                    Text("Once").tag(0)
                    Text("N Times").tag(1)
                    Text("Forever").tag(2)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: .infinity)

                if repeatOption == 1 {
                    Stepper(value: $repeatCount, in: 2...100) {
                        Text("\(repeatCount)x")
                            .font(.caption.monospacedDigit())
                            .frame(width: 32, alignment: .trailing)
                    }
                }
            }

            // Action buttons
            HStack(spacing: 12) {
                if recorder.isRecording {
                    Button("Stop Recording") {
                        toggleRecording()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                } else {
                    Button("Record") {
                        toggleRecording()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(player.isPlaying)
                }

                if player.isPlaying {
                    Button("Stop Playback") {
                        togglePlayback()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                } else {
                    Button("Play") {
                        togglePlayback()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedRecordingID == nil || recorder.isRecording)
                }
            }

            Text("\u{2318}\u{21E7}R Record  \u{00B7}  \u{2318}\u{21E7}P Play")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding()
    }
}

// MARK: - Recording Row

struct RecordingRow: View {
    let recording: InputRecording

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(recording.name)
                .font(.headline)
            HStack {
                Text("\(recording.events.count) events")
                Text("·")
                Text(formattedDuration)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }

    private var formattedDuration: String {
        let d = recording.duration
        if d < 60 {
            return String(format: "%.1fs", d)
        }
        return "\(Int(d) / 60)m \(Int(d) % 60)s"
    }
}

#Preview {
    ContentView()
}
