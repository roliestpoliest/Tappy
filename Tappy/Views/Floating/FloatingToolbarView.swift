import SwiftUI

struct FloatingToolbarView: View {
    @Environment(AppStateService.self) private var appState
    @Environment(\.palette) private var palette

    var body: some View {
        HStack(spacing: 4) {
            Menu {
                Text("More actions coming soon").disabled(true)
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(palette.textSecondary)
                    .frame(width: 28, height: 28)
                    .background(
                        RoundedRectangle(cornerRadius: 8).fill(palette.buttonSubtle)
                    )
            }
            .menuStyle(.borderlessButton)
            .fixedSize()

            Spacer(minLength: 0)

            RecordButtonView(size: 26)

            Spacer(minLength: 0)

            Button(action: { appState.toggleCollapsed() }) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(palette.textSecondary)
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: Metrics.windowCornerRadius)
                .fill(palette.floatingBg)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Metrics.windowCornerRadius)
                .stroke(palette.borderSubtle, lineWidth: 1)
        )
    }
}
