import SwiftUI

struct SpeedControlView: View {
    @Environment(AppStateService.self) private var appState
    @Environment(\.palette) private var palette

    var body: some View {
        HStack(spacing: 6) {
            iconButton("tortoise.fill") { step(-1) }

            Menu {
                ForEach(PlaybackConfig.validSpeeds, id: \.self) { s in
                    Button(String(format: "%.2gx", s)) { setSpeed(s) }
                }
            } label: {
                Text(speedLabel)
                    .font(.speedLabel)
                    .foregroundStyle(palette.textPrimary)
                    .frame(minWidth: 24, minHeight: 22)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()

            iconButton("hare.fill") { step(+1) }
        }
    }

    @ViewBuilder
    private func iconButton(_ system: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(palette.textSecondary)
                .frame(width: 24, height: 24)
                .background(
                    RoundedRectangle(cornerRadius: 6).fill(palette.buttonSubtle)
                )
        }
        .buttonStyle(.plain)
    }

    private var speedLabel: String {
        let s = appState.playbackConfig.speed
        return s == floor(s) ? "\(Int(s))×" : String(format: "%.2g×", s)
    }

    private func step(_ direction: Int) {
        let speeds = PlaybackConfig.validSpeeds
        let idx = speeds.firstIndex(of: appState.playbackConfig.speed) ?? speeds.firstIndex(of: 1.0)!
        let newIdx = max(0, min(speeds.count - 1, idx + direction))
        setSpeed(speeds[newIdx])
    }

    private func setSpeed(_ speed: Double) {
        var cfg = appState.playbackConfig
        cfg.speed = speed
        appState.updatePlaybackConfig(cfg)
    }
}
