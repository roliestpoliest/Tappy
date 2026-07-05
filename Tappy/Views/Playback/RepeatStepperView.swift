import SwiftUI

struct RepeatStepperView: View {
    @Environment(AppStateService.self) private var appState
    @Environment(\.palette) private var palette

    var body: some View {
        let looping = appState.playbackConfig.isLooping
        HStack(spacing: 6) {
            step("minus") { bump(-1) }
                .disabled(looping || appState.playbackConfig.repeatCount <= 1)
            Text("\(appState.playbackConfig.repeatCount)×")
                .font(.speedLabel)
                .foregroundStyle(palette.textPrimary)
                .frame(minWidth: 24)
            step("plus") { bump(+1) }
                .disabled(looping)
        }
        .opacity(looping ? 0.4 : 1.0)
    }

    @ViewBuilder
    private func step(_ system: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(palette.textSecondary)
                .frame(width: 24, height: 24)
                .background(
                    RoundedRectangle(cornerRadius: 6).fill(palette.buttonSubtle)
                )
        }
        .buttonStyle(.plain)
    }

    private func bump(_ delta: Int) {
        var cfg = appState.playbackConfig
        cfg.repeatCount = max(1, cfg.repeatCount + delta)
        appState.updatePlaybackConfig(cfg)
    }
}
