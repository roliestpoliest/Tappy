import SwiftUI

struct MainPaneView: View {
    @Environment(AppStateService.self) private var appState
    @Environment(\.palette) private var palette

    var body: some View {
        VStack(spacing: 0) {
            MainPaneHeaderView()
            if let recording = appState.selectedRecording {
                ActionListView(recording: recording)
            } else {
                EmptyStateView(message: "Select a recording to view its actions.")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(palette.mainPaneBg)
    }
}
