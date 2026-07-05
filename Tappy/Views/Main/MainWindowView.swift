import SwiftUI

struct MainWindowView: View {
    @Environment(AppStateService.self) private var appState
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
        .sheet(isPresented: .constant(!appState.accessibility.isGranted)) {
            AccessibilityPromptView()
        }
    }
}
