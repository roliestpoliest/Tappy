import SwiftUI

struct TitleBarView: View {
    @Environment(\.palette) private var palette

    var body: some View {
        ZStack {
            Text("Tappy")
                .font(.appTitle)
                .tracking(-0.14)
                .foregroundStyle(palette.textTitle)
        }
        .frame(height: Metrics.titleBarHeight)
        .frame(maxWidth: .infinity)
        .background(palette.windowBg.opacity(0.96))
        .overlay(alignment: .bottom) {
            Rectangle().fill(palette.borderDefault).frame(height: 1)
        }
    }
}
