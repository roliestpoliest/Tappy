import SwiftUI

struct SidebarView: View {
    @Environment(AppStateService.self) private var appState
    @Environment(\.palette) private var palette

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SidebarHeaderView()
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 4) {
                    ForEach(appState.recordings) { recording in
                        RecordingRowView(recording: recording)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.top, 4)
            }
        }
        .frame(width: Metrics.sidebarWidth)
        .frame(maxHeight: .infinity)
        .background(palette.sidebarBg)
        .overlay(alignment: .trailing) {
            Rectangle().fill(palette.borderDefault).frame(width: 1)
        }
    }
}
