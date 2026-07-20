import SwiftUI

struct PlaybackBarView: View {
    @Environment(AppStateService.self) private var appState
    @Environment(\.palette) private var palette

    var body: some View {
        HStack(spacing: 10) {
            RecordButtonView(size: 36)
                .padding(.trailing, 6)

            Group {
                PlayButtonView()
                    .padding(.trailing, 10)
                TimelineView()
                    .padding(.trailing, 8)
                divider
                SpeedControlView()
                divider
                LoopButtonView()
                RepeatStepperView()
            }
            .disabled(playbackBarDisabled)
            .opacity(playbackBarDisabled ? 0.4 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: playbackBarDisabled)
        }
        .frame(height: Metrics.playbackBarHeight)
        .padding(.horizontal, 20)
        .background(palette.playbackBarBg)
        .overlay(alignment: .top) {
            Rectangle().fill(palette.borderDefault).frame(height: 1)
        }
    }

    private var playbackBarDisabled: Bool {
        appState.recorder.isRecording || appState.isCropping
    }

    private var divider: some View {
        Rectangle()
            .fill(palette.borderSubtle)
            .frame(width: 1, height: 28)
            .padding(.horizontal, 8)
    }
}
