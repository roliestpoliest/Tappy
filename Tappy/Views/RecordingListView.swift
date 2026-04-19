import SwiftUI

struct RecordingListView: View {
    @Binding var recordings: [MacroRecording]
    @Binding var selectedRecording: MacroRecording?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Recordings")
                    .font(.callout.bold())
                    .fontDesign(.rounded)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 6)

            List(selection: $selectedRecording) {
                if recordings.isEmpty {
                    Text("No recordings yet")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(recordings) { recording in
                        RecordingRowView(recording: recording)
                            .tag(recording)
                            .listRowBackground(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedRecording == recording
                                          ? Color.accentColor.opacity(0.12)
                                          : Color.clear)
                                    .padding(.horizontal, 4)
                            )
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let r = recordings[index]
                            try? r.delete()
                            if selectedRecording == r { selectedRecording = nil }
                        }
                        recordings.remove(atOffsets: indexSet)
                    }
                }
            }
            .listStyle(.sidebar)
        }
    }
}

struct RecordingRowView: View {
    let recording: MacroRecording

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(recording.name)
                .font(.callout.bold())
                .fontDesign(.rounded)
                .lineLimit(1)
            HStack(spacing: 6) {
                Text(recording.duration.mmss)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                Text("·")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Text("\(recording.events.count) events")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 3)
    }
}

struct RecordButton: View {
    let isRecording: Bool
    let elapsedTime: TimeInterval
    let action: () -> Void

    @State private var pulse = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Circle()
                    .fill(isRecording ? Color.red : Color.secondary.opacity(0.5))
                    .frame(width: 10, height: 10)
                    .scaleEffect(pulse ? 1.3 : 1.0)
                    .animation(
                        isRecording
                            ? .easeInOut(duration: 0.6).repeatForever(autoreverses: true)
                            : .default,
                        value: pulse)

                // Invisible "Record" placeholder keeps width stable during timer
                ZStack {
                    Text("Record")
                        .hidden()
                    Text(isRecording ? elapsedTime.mmss : "Record")
                        .animation(.none, value: elapsedTime)
                }
                .font(.system(.callout, design: .rounded, weight: .medium))
                .monospacedDigit()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .background(
            isRecording
                ? Color.red.opacity(0.15)
                : Color.primary.opacity(0.08),
            in: Capsule()
        )
        .onChange(of: isRecording) { _, recording in
            pulse = recording
        }
        .onAppear {
            pulse = isRecording
        }
    }
}

struct NameRecordingSheet: View {
    @State var recording: MacroRecording
    let onSave: (MacroRecording) -> Void

    @State private var name: String

    init(recording: MacroRecording, onSave: @escaping (MacroRecording) -> Void) {
        self.recording = recording
        self.onSave = onSave
        _name = State(initialValue: recording.name)
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Name Your Recording")
                .font(.headline)
                .fontDesign(.rounded)

            TextField("Recording name", text: $name)
                .textFieldStyle(.roundedBorder)
                .onSubmit { save() }

            HStack {
                Text("\(recording.events.count) events · \(recording.duration.mmss)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            HStack {
                Button("Discard") { onSave(recording) }
                    .foregroundStyle(.red)
                Spacer()
                Button("Save", action: save)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 340)
    }

    private func save() {
        var saved = recording
        saved.name = name.isEmpty ? recording.name : name
        onSave(saved)
    }
}
