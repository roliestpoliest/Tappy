import SwiftUI

struct MainWindowView: View {
    @Environment(\.palette) private var palette

    var body: some View {
        VStack(spacing: 0) {
            TitleBarView()
            HStack(spacing: 0) {
                SidebarView()
                MainPaneView()
            }
            PlaybackBarView()
        }
        .background(palette.windowBg)
        .clipShape(RoundedRectangle(cornerRadius: Metrics.windowCornerRadius))
    }
}
