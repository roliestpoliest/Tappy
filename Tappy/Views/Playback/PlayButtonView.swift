import SwiftUI

struct PlayButtonView: View {
    @Environment(AppStateService.self) private var appState
    @Environment(\.palette) private var palette

    var body: some View {
        Button(action: togglePlay) {
            Image(systemName: appState.player.isPlaying ? "pause.fill" : "play.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(Circle().fill(palette.accent))
                .shadow(color: palette.accent.opacity(0.35), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
        .disabled(!appState.canPlay && !appState.player.isPlaying)
    }

    private func togglePlay() {
        if appState.player.isPlaying {
            appState.player.stop()
        } else {
            guard appState.canPlay, let rec = appState.selectedRecording else { return }
            appState.player.play(recording: rec, config: appState.playbackConfig)
        }
    }
}
