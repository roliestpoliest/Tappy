import SwiftUI

struct ActionListView: View {
    let recording: MacroRecording

    @Environment(AppStateService.self) private var appState
    @Environment(\.palette) private var palette

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical) {
                LazyVStack(spacing: 3) {
                    ForEach(Array(recording.events.enumerated()), id: \.element.id) { index, event in
                        ActionRowView(
                            event: event,
                            index: index,
                            nextTimestamp: index + 1 < recording.events.count
                                ? recording.events[index + 1].timestamp
                                : nil,
                            isRunning: appState.player.isPlaying
                                && appState.player.currentEventIndex == index
                                && appState.selectedRecording?.id == recording.id
                        )
                        .id(event.id)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .onChange(of: appState.player.currentEventIndex) { _, newIndex in
                guard appState.player.isPlaying,
                      newIndex < recording.events.count else { return }
                withAnimation(.easeInOut(duration: 0.2)) {
                    proxy.scrollTo(recording.events[newIndex].id, anchor: .center)
                }
            }
        }
    }
}
