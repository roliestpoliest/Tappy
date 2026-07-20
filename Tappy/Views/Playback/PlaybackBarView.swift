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
            .disabled(appState.recorder.isRecording)
            .opacity(appState.recorder.isRecording ? 0.4 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: appState.recorder.isRecording)
        }
        .frame(height: Metrics.playbackBarHeight)
        .padding(.horizontal, 20)
        .background(palette.playbackBarBg)
        .overlay(alignment: .top) {
            Rectangle().fill(palette.borderDefault).frame(height: 1)
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(palette.borderSubtle)
            .frame(width: 1, height: 28)
            .padding(.horizontal, 8)
    }
}
