import SwiftUI

struct MainPaneView: View {
    @Environment(\.palette) private var palette

    var body: some View {
        VStack(spacing: 8) {
            Text("Main Pane")
                .font(.paneTitle)
                .foregroundStyle(palette.textPrimary)
            Text("stub — replaced in Step 6")
                .font(.rowSubtitle)
                .foregroundStyle(palette.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(palette.mainPaneBg)
    }
}
