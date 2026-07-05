import SwiftUI

struct PlaybackBarView: View {
    @Environment(\.palette) private var palette

    var body: some View {
        HStack(spacing: 10) {
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
