import SwiftUI

struct PlaybackBarView: View {
    @Environment(\.palette) private var palette

    var body: some View {
        HStack {
            Text("Playback Bar")
                .font(.rowSubtitle)
                .foregroundStyle(palette.textSecondary)
            Spacer()
            Text("stub — replaced in Step 8")
                .font(.rowSubtitle)
                .foregroundStyle(palette.textSecondary.opacity(0.6))
        }
        .padding(.horizontal, 20)
        .frame(height: Metrics.playbackBarHeight)
        .frame(maxWidth: .infinity)
        .background(palette.playbackBarBg)
        .overlay(alignment: .top) {
            Rectangle().fill(palette.borderDefault).frame(height: 1)
        }
    }
}
