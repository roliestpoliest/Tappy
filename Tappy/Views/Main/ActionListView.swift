import SwiftUI

struct ActionListView: View {
    let recording: MacroRecording

    @Environment(AppStateService.self) private var appState
    @Environment(\.palette) private var palette

    private var steps: [ActionStep] {
        ActionStep.buildSteps(from: recording.events)
    }

    private func dimOpacity(for step: ActionStep) -> Double {
        guard appState.isCropping, let range = appState.cropRange else { return 1.0 }
        // Dim only steps entirely outside the selected range.
        let entirelyOutside = step.endTimestamp < range.lowerBound
            || step.startTimestamp > range.upperBound
        return entirelyOutside ? 0.35 : 1.0
    }

    private var runningStepID: UUID? {
        guard appState.player.isPlaying,
              appState.selectedRecording?.id == recording.id,
              appState.player.currentEventIndex < recording.events.count else { return nil }
        let currentEventID = recording.events[appState.player.currentEventIndex].id
        return steps.first(where: { $0.underlyingEventIDs.contains(currentEventID) })?.id
    }

    var body: some View {
        let allSteps = steps
        let currentStepID = runningStepID
        ScrollViewReader { proxy in
            ScrollView(.vertical) {
                LazyVStack(spacing: 3) {
                    ForEach(Array(allSteps.enumerated()), id: \.element.id) { index, step in
                        ActionRowView(
                            step: step,
                            index: index,
                            nextStepStart: index + 1 < allSteps.count
                                ? allSteps[index + 1].startTimestamp
                                : nil,
                            isRunning: step.id == currentStepID,
                            isDeleteEnabled: !appState.player.isPlaying && !appState.isCropping,
                            onDelete: {
                                try? appState.deleteEvents(
                                    step.underlyingEventIDs,
                                    from: recording
                                )
                            }
                        )
                        .id(step.id)
                        .opacity(dimOpacity(for: step))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .onChange(of: appState.player.currentEventIndex) { _, newIndex in
                guard appState.player.isPlaying,
                      newIndex < recording.events.count else { return }
                let currentEventID = recording.events[newIndex].id
                let stepsNow = steps
                guard let target = stepsNow.first(where: {
                    $0.underlyingEventIDs.contains(currentEventID)
                }) else { return }
                withAnimation(.easeInOut(duration: 0.2)) {
                    proxy.scrollTo(target.id, anchor: .center)
                }
            }
        }
    }
}
