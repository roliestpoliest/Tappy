import SwiftUI

struct SidebarHeaderView: View {
    @Environment(AppStateService.self) private var appState
    @Environment(\.palette) private var palette

    var body: some View {
        HStack(spacing: 8) {
            Button(action: { appState.toggleCollapsed() }) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(palette.textSecondary)
                    .frame(width: 18, height: 18)
            }
            .buttonStyle(.plain)

            Text("RECORDINGS")
                .font(.sectionLabel)
                .tracking(0.88)
                .foregroundStyle(palette.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.top, 18)
        .padding(.bottom, 10)
    }
}
