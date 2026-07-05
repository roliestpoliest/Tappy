import SwiftUI

struct FloatingToolbarView: View {
    @Environment(AppStateService.self) private var appState
    @Environment(\.palette) private var palette

    @State private var isPulsing: Bool = false

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

            Button(action: toggleRecord) {
                Circle()
                    .fill(palette.recordRed)
                    .opacity(isPulsing ? 0.6 : 1.0)
                    .frame(width: 14, height: 14)
                    .padding(6)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(palette.buttonSubtle)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(palette.borderSubtle, lineWidth: 1)
                            )
                    )
            }
            .buttonStyle(.plain)
            .disabled(!appState.accessibility.isGranted)

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
        .onChange(of: appState.recorder.isRecording) { _, recording in
            if recording {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            } else {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isPulsing = false
                }
            }
        }
    }

    private func toggleRecord() {
        if appState.recorder.isRecording {
            let name = "Recording \(Date().formatted(date: .abbreviated, time: .shortened))"
            try? appState.stopRecordingAndSave(name: name)
        } else {
            guard appState.accessibility.isGranted else {
                appState.accessibility.requestAccess()
                return
            }
            appState.recorder.startRecording()
        }
    }
}
