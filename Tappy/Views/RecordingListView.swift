import SwiftUI

struct RecordingListView: View {
    @Binding var recordings: [MacroRecording]
    @Binding var selectedRecording: MacroRecording?

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Color.accentColor)
                Text("Recordings")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1.0)
                    .textCase(.uppercase)
                    .foregroundStyle(Color.accentColor)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.top, 16)
            .padding(.bottom, 8)

            List(selection: $selectedRecording) {
                if recordings.isEmpty {
                    Text("No recordings yet")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(recordings) { recording in
                        let isSelected = selectedRecording == recording
                        RecordingRowView(recording: recording, isSelected: isSelected)
                            .tag(recording)
                            .listRowInsets(EdgeInsets(top: 3, leading: 8, bottom: 3, trailing: 8))
                            .listRowSeparator(.hidden)
                            .listRowBackground(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(isSelected ? Color.accentColor.opacity(0.31) : Color.clear)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.accentColor.opacity(0.6), lineWidth: 1)
                                            .opacity(isSelected ? 1 : 0)
                                    )
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
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .background(Color(red: 0.961, green: 0.937, blue: 0.902))
    }
}

struct RecordingRowView: View {
    let recording: MacroRecording
    var isSelected: Bool = false

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor : Color.accentColor.opacity(0.15))
                    .frame(width: 30, height: 30)
                Image(systemName: "waveform")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(isSelected ? Color.white : Color.accentColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(recording.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color(red: 0.239, green: 0.310, blue: 0.369))
                    .lineLimit(1)
                Text("\(recording.events.count) actions")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.accentColor)
            }
        }
        .padding(.vertical, 10)
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
