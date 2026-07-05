import SwiftUI

struct EmptyStateView: View {
    let message: String

    @Environment(\.palette) private var palette

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "waveform.slash")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(palette.textSecondary.opacity(0.6))
            Text(message)
                .font(.rowSubtitle)
                .foregroundStyle(palette.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
