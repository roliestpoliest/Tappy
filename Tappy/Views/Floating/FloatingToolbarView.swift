import SwiftUI

struct FloatingToolbarView: View {
    @Environment(AppStateService.self) private var appState
    @Environment(\.palette) private var palette

    var body: some View {
        HStack {
            Text("Floating")
                .font(.rowSubtitle)
                .foregroundStyle(palette.textSecondary)
            Spacer()
            Button(action: { appState.toggleCollapsed() }) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(palette.textSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(palette.floatingBg)
    }
}
