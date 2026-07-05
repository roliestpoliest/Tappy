import SwiftUI

struct AccessibilityPromptView: View {
    @Environment(AppStateService.self) private var appState
    @Environment(\.palette) private var palette

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.shield")
                .font(.system(size: 42, weight: .light))
                .foregroundStyle(palette.accent)
            Text("Accessibility permission needed")
                .font(.paneTitle)
                .foregroundStyle(palette.textPrimary)
            Text("Tappy needs Accessibility access to record and play back your input.")
                .font(.rowSubtitle)
                .foregroundStyle(palette.textSecondary)
                .multilineTextAlignment(.center)
            Button("Open System Settings") {
                appState.accessibility.requestAccess()
            }
            .buttonStyle(.borderedProminent)
            .tint(palette.accent)
        }
        .padding(32)
        .frame(width: 360)
    }
}
