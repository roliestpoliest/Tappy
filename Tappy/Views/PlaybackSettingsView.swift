import SwiftUI

// MARK: - Playback Bar (bottom of main window)

struct PlaybackBar: View {
    let recording: MacroRecording?
    @Binding var config: PlaybackConfig
    @Environment(EventPlayer.self) var player

    @State private var showSettings = false

    private var currentTime: TimeInterval {
        guard let rec = recording else { return 0 }
        return player.progress * rec.duration
    }

    var body: some View {
        HStack(spacing: 10) {
            // Play/Pause
            Button(action: togglePlayback) {
                ZStack {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 36, height: 36)
                        .shadow(color: Color.accentColor.opacity(0.35), radius: 4, y: 2)
                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .offset(x: player.isPlaying ? 0 : 1)
                }
            }
            .buttonStyle(.plain)
            .disabled(recording?.events.isEmpty ?? true)
            .padding(.trailing, 10)

            // Scrubber
            HStack(spacing: 8) {
                Text(currentTime.mmss)
                    .font(.system(size: 10).monospacedDigit())
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 28, alignment: .leading)

                ProgressView(value: player.isPlaying ? player.progress : 0)
                    .progressViewStyle(.linear)
                    .tint(Color.accentColor)

                Text((recording?.duration ?? 0).mmss)
                    .font(.system(size: 10).monospacedDigit())
                    .foregroundStyle(Color(red: 0.682, green: 0.741, blue: 0.792))
                    .frame(width: 24, alignment: .trailing)
            }

            barDivider

            // Speed control
            HStack(spacing: 5) {
                Button {
                    config.speed = max(0.25, (config.speed * 4 - 1) / 4)
                } label: {
                    Image(systemName: "tortoise.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.accentColor.opacity(0.7))
                }
                .buttonStyle(.plain)

                Text(speedLabel)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color(red: 0.239, green: 0.310, blue: 0.369))
                    .frame(minWidth: 26, alignment: .center)
                    .monospacedDigit()

                Button {
                    config.speed = min(10.0, (config.speed * 4 + 1) / 4)
                } label: {
                    Image(systemName: "hare.fill")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.accentColor.opacity(0.7))
                }
                .buttonStyle(.plain)
            }

            barDivider

            // Loop toggle + repeat count
            HStack(spacing: 8) {
                Button {
                    config.repeatCount = config.repeatCount == 0 ? 1 : 0
                } label: {
                    Image(systemName: "repeat")
                        .font(.system(size: 13))
                        .foregroundStyle(config.repeatCount == 0
                            ? Color.accentColor
                            : Color.accentColor.opacity(0.35))
                }
                .buttonStyle(.plain)
                .help(config.repeatCount == 0 ? "Loop: On" : "Loop: Off")

                HStack(spacing: 4) {
                    Button {
                        if config.repeatCount > 1 { config.repeatCount -= 1 }
                    } label: {
                        Image(systemName: "minus")
                            .font(.system(size: 9, weight: .semibold))
                            .frame(width: 22, height: 22)
                    }
                    .buttonStyle(.plain)
                    .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 5))
                    .disabled(config.repeatCount <= 1 && config.repeatCount != 0)

                    Text(config.repeatCount == 0 ? "∞" : "\(config.repeatCount)×")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color(red: 0.239, green: 0.310, blue: 0.369))
                        .frame(minWidth: 24, alignment: .center)
                        .monospacedDigit()

                    Button {
                        if config.repeatCount != 0 { config.repeatCount += 1 }
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 9, weight: .semibold))
                            .frame(width: 22, height: 22)
                    }
                    .buttonStyle(.plain)
                    .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 5))
                    .disabled(config.repeatCount == 0)
                }
            }

            Spacer()

            // Advanced settings
            Button { showSettings.toggle() } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.accentColor.opacity(0.6))
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showSettings, arrowEdge: .top) {
                PlaybackPanel(recording: recording, config: $config)
                    .frame(width: 268)
                    .environment(player)
            }
        }
        .padding(.horizontal, 20)
        .frame(height: 60)
        .background(Color(red: 0.929, green: 0.906, blue: 0.859))
        .overlay(alignment: .top) {
            Color.accentColor.opacity(0.5)
                .frame(height: 0.5)
        }
    }

    private var barDivider: some View {
        Rectangle()
            .fill(Color(red: 0.682, green: 0.741, blue: 0.792).opacity(0.5))
            .frame(width: 1, height: 28)
    }

    private var speedLabel: String {
        let s = config.speed
        if s == Double(Int(s)) { return "\(Int(s))×" }
        return String(format: "%.2g×", s)
    }

    private func togglePlayback() {
        guard let recording else { return }
        if player.isPlaying { player.stop() }
        else { player.play(recording: recording, config: config) }
    }
}

// MARK: - Playback Panel (settings popover)

struct PlaybackPanel: View {
    let recording: MacroRecording?
    @Binding var config: PlaybackConfig
    @Environment(EventPlayer.self) var player

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                settingsCard
            }
            .padding(14)
        }
        .background(.background)
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
}
