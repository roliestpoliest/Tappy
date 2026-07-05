import SwiftUI

struct RecordingRowView: View {
    let recording: MacroRecording

    @Environment(AppStateService.self) private var appState
    @Environment(\.palette) private var palette

    private var isSelected: Bool { appState.selectedRecording?.id == recording.id }

    var body: some View {
        Button(action: { appState.selectedRecording = recording }) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? palette.accent : palette.buttonSubtle)
                        .frame(width: 30, height: 30)
                    Image(systemName: "waveform")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(isSelected ? .white : palette.textSecondary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(recording.name)
                        .font(.rowTitle)
                        .tracking(-0.13)
                        .foregroundStyle(palette.textPrimary)
                        .lineLimit(1)
                    Text("\(recording.eventCount) actions")
                        .font(.rowSubtitle)
                        .foregroundStyle(palette.textSecondary)
                }

                Spacer(minLength: 0)
            }
            .padding(10)
            .background {
                RoundedRectangle(cornerRadius: Metrics.rowRadius)
                    .fill(isSelected ? Color(hex: 0x7895B2, alpha: 0.31) : Color.clear)
            }
            .overlay {
                RoundedRectangle(cornerRadius: Metrics.rowRadius)
                    .stroke(isSelected ? Color(hex: 0x7895B2, alpha: 0.60) : .clear, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Rename…") { }
            Button("Delete", role: .destructive) {
                try? appState.deleteRecording(recording)
            }
        }
    }
}
