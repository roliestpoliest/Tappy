import SwiftUI

struct LoopButtonView: View {
    @Environment(AppStateService.self) private var appState
    @Environment(\.palette) private var palette

    var body: some View {
        Button(action: toggle) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(appState.playbackConfig.isLooping ? .white : palette.textSecondary)
                .frame(width: 24, height: 24)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(appState.playbackConfig.isLooping ? palette.accent : palette.buttonSubtle)
                )
        }
        .buttonStyle(.plain)
    }

    private func toggle() {
        var cfg = appState.playbackConfig
        cfg.isLooping.toggle()
        appState.updatePlaybackConfig(cfg)
    }
}
