import SwiftUI

struct PlaybackPanel: View {
    let recording: MacroRecording?
    @Binding var config: PlaybackConfig
    @Environment(EventPlayer.self) var player

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                playbackCard
                settingsCard
            }
            .padding(14)
        }
        .background(.background)
    }

    // MARK: - Playback Card

    private var playbackCard: some View {
        VStack(spacing: 14) {
            Button(action: togglePlayback) {
                ZStack {
                    Circle()
                        .fill(playButtonColor.opacity(0.15))
                        .frame(width: 60, height: 60)
                    Image(systemName: player.isPlaying ? "stop.fill" : "play.fill")
                        .font(.title2)
                        .foregroundStyle(playButtonColor)
                }
            }
            .buttonStyle(.plain)
            .disabled(recording?.events.isEmpty ?? true)

            ProgressView(value: player.isPlaying ? player.progress : 0)
                .progressViewStyle(.linear)
                .tint(.accentColor)

            HStack {
                Group {
                    if player.isPlaying {
                        Text("Iter \(player.currentIteration)" +
                             (config.repeatCount == 0 ? " / ∞" : " / \(config.repeatCount)"))
                    } else {
                        Text(recording == nil ? "No recording" : "Ready")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                Spacer()

                Text(speedLabel)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Settings Card

    private var settingsCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Playback Settings")
                .font(.callout.bold())
                .fontDesign(.rounded)
                .foregroundStyle(.secondary)
                .padding(.bottom, 12)

            Group {
                sliderRow(
                    label: "Speed",
                    valueLabel: String(format: "%.1f×", config.speed),
                    value: $config.speed,
                    range: 0.1...10.0
                )

                stepperRow(
                    label: "Repeat",
                    valueLabel: config.repeatCount == 0 ? "Loop ∞" : "\(config.repeatCount)×",
                    value: $config.repeatCount,
                    range: 0...999
                )

                Divider().padding(.vertical, 8)

                stepperRow(
                    label: "Click ×",
                    valueLabel: "\(config.clickMultiplier)×",
                    value: $config.clickMultiplier,
                    range: 1...20
                )

                sliderRow(
                    label: "Jitter",
                    valueLabel: String(format: "%.0f pt", config.jitterAmount),
                    value: $config.jitterAmount,
                    range: 0...50
                )

                toggleRow(
                    label: "Bezier Curves",
                    isOn: $config.useBezierCurves
                )

                if config.useBezierCurves {
                    sliderRow(
                        label: "Deviation",
                        valueLabel: String(format: "%.0f pt", config.bezierDeviation),
                        value: $config.bezierDeviation,
                        range: 0...100
                    )
                }
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Setting Row Builders

    private func sliderRow(
        label: String,
        valueLabel: String,
        value: Binding<Double>,
        range: ClosedRange<Double>
    ) -> some View {
        VStack(spacing: 4) {
            HStack {
                Text(label)
                    .font(.callout)
                Spacer()
                Text(valueLabel)
                    .font(.callout.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            Slider(value: value, in: range)
                .tint(.accentColor)
        }
        .padding(.vertical, 5)
    }

    private func stepperRow(
        label: String,
        valueLabel: String,
        value: Binding<Int>,
        range: ClosedRange<Int>
    ) -> some View {
        HStack {
            Text(label)
                .font(.callout)
            Spacer()
            Text(valueLabel)
                .font(.callout.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(minWidth: 56, alignment: .trailing)
            Stepper("", value: value, in: range)
                .labelsHidden()
        }
        .padding(.vertical, 5)
    }

    private func toggleRow(label: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(label)
                .font(.callout)
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
        }
        .padding(.vertical, 5)
    }

    // MARK: - Helpers

    private var playButtonColor: Color {
        player.isPlaying ? .red : .accentColor
    }

    private var speedLabel: String {
        guard let rec = recording else { return "" }
        let base = rec.duration / config.speed
        return "\(String(format: "%.1f", config.speed))× · ~\(base.mmss)"
    }

    private func togglePlayback() {
        guard let recording else { return }
        if player.isPlaying {
            player.stop()
        } else {
            player.play(recording: recording, config: config)
        }
    }
}
