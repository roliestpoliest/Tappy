import SwiftUI

struct MainWindowView: View {
    @Environment(\.palette) private var palette

    var body: some View {
        VStack(spacing: 12) {
            Text("Main Window")
                .font(.paneTitle)
                .foregroundStyle(palette.textPrimary)
            Text("stub — replaced in Steps 4–8")
                .font(.rowSubtitle)
                .foregroundStyle(palette.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(palette.windowBg)
    }
}
