import AppKit
import SwiftUI

struct MenuBarView: View {
    @Environment(AccessibilityManager.self) var accessibility
    @Environment(EventRecorder.self) var recorder
    @Environment(EventPlayer.self) var player

    @State private var recentRecordings: [MacroRecording] = []

    var body: some View {
        VStack(spacing: 0) {
            recordButton
                .padding(12)

            if !recentRecordings.isEmpty {
                Divider()

                VStack(spacing: 0) {
                    ForEach(recentRecordings.prefix(3)) { recording in
                        quickPlayRow(recording)
                    }
                }
                .padding(.vertical, 6)

                Divider()
            }

            openAppButton
                .padding(12)
        }
        .frame(width: 240)
        .onAppear { recentRecordings = (try? MacroRecording.loadAll()) ?? [] }
    }

    private var recordButton: some View {
        Button(action: toggleRecording) {
            HStack {
                Image(systemName: recorder.isRecording ? "stop.fill" : "record.circle.fill")
                    .foregroundStyle(recorder.isRecording ? .red : .blue)
                Text(recorder.isRecording
                     ? "Stop  \(recorder.elapsedTime.mmss)"
                     : "Start Recording")
                    .fontDesign(.rounded)
                    .monospacedDigit()
                Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .background(
            recorder.isRecording
                ? Color.red.opacity(0.12)
                : Color.accentColor.opacity(0.10),
            in: RoundedRectangle(cornerRadius: 10)
        )
        .disabled(!accessibility.isGranted)
    }

    private func quickPlayRow(_ recording: MacroRecording) -> some View {
        Button(action: { quickPlay(recording) }) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(recording.name)
                        .font(.callout)
                        .lineLimit(1)
                    Text("\(recording.events.count) events · \(recording.duration.mmss)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: player.isPlaying ? "stop.circle" : "play.circle")
                    .foregroundStyle(.tint)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }

    private var openAppButton: some View {
        Button(action: openMainWindow) {
            HStack {
                Image(systemName: "macwindow")
                Text("Open Tappy")
                Spacer()
            }
            .foregroundStyle(.secondary)
            .font(.callout)
        }
        .buttonStyle(.plain)
    }

    private func toggleRecording() {
        if recorder.isRecording {
            let recording = recorder.stopRecording()
            try? recording.save()
            recentRecordings = (try? MacroRecording.loadAll()) ?? []
        } else {
            recorder.startRecording()
        }
    }

    private func quickPlay(_ recording: MacroRecording) {
        if player.isPlaying {
            player.stop()
        } else {
            player.play(recording: recording, config: PlaybackConfig())
        }
    }

    private func openMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
    }
}
