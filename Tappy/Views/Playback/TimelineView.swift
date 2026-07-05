import SwiftUI

struct TimelineView: View {
    @Environment(AppStateService.self) private var appState
    @Environment(\.palette) private var palette

    var body: some View {
        HStack(spacing: 12) {
            Text(elapsedString)
                .font(.duration)
                .foregroundStyle(palette.textSecondary)
                .frame(width: 30, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(palette.borderSubtle)
                        .frame(height: 4)
                    Capsule()
                        .fill(palette.accent)
                        .frame(width: geo.size.width * progress, height: 4)
                    Circle()
                        .fill(palette.accent)
                        .frame(width: 10, height: 10)
                        .offset(x: geo.size.width * progress - 5)
                        .shadow(color: palette.accent.opacity(0.5), radius: 3, y: 1)
                }
                .frame(maxHeight: .infinity)
            }
            .frame(height: 12)

            Text(totalString)
                .font(.duration)
                .foregroundStyle(palette.textSecondary)
                .frame(width: 30, alignment: .trailing)
        }
    }

    private var progress: Double {
        guard appState.player.isPlaying,
              let rec = appState.selectedRecording,
              rec.duration > 0,
              appState.player.currentEventIndex < rec.events.count else { return 0 }
        return rec.events[appState.player.currentEventIndex].timestamp / rec.duration
    }

    private var elapsedString: String {
        guard appState.player.isPlaying,
              let rec = appState.selectedRecording,
              appState.player.currentEventIndex < rec.events.count else { return "0:00" }
        return format(rec.events[appState.player.currentEventIndex].timestamp)
    }

    private var totalString: String {
        format(appState.selectedRecording?.duration ?? 0)
    }

    private func format(_ seconds: TimeInterval) -> String {
        let m = Int(seconds) / 60
        let s = Int(seconds) % 60
        return String(format: "%d:%02d", m, s)
    }
}
