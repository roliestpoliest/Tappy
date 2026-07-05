import SwiftUI

struct ActionListView: View {
    let recording: MacroRecording

    @Environment(\.palette) private var palette

    var body: some View {
        VStack(spacing: 6) {
            Text("Action List")
                .font(.paneTitle)
                .foregroundStyle(palette.textPrimary)
            Text("\(recording.eventCount) events — stub, replaced in Step 7")
                .font(.rowSubtitle)
                .foregroundStyle(palette.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
