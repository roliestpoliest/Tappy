import SwiftUI

struct MainPaneHeaderView: View {
    @Environment(AppStateService.self) private var appState
    @Environment(\.palette) private var palette

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(appState.selectedRecording?.name ?? "No recording selected")
                    .font(.paneTitle)
                    .tracking(-0.36)
                    .foregroundStyle(palette.textPrimary)
                Text(appState.selectedRecording.map { "\($0.eventCount) actions" } ?? " ")
                    .font(.rowSubtitle)
                    .foregroundStyle(palette.textSecondary)
            }
            Spacer()
            HStack(spacing: 8) {
                subtleIconButton(system: "crop", disabled: true, action: {})
                subtleIconButton(
                    system: appState.colorScheme == .dark ? "sun.max.fill" : "moon.fill",
                    action: { appState.toggleColorScheme() }
                )
            }
        }
        .padding(.top, 18)
        .padding(.bottom, 10)
        .padding(.horizontal, 24)
        .overlay(alignment: .bottom) {
            Rectangle().fill(palette.borderDefault.opacity(0.5)).frame(height: 1)
        }
    }

    @ViewBuilder
    private func subtleIconButton(
        system: String,
        disabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(palette.textSecondary)
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 9).fill(palette.buttonSubtle)
                )
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.5 : 1.0)
    }
}
