import SwiftUI

struct RecordButtonView: View {
    @Environment(AppStateService.self) private var appState
    @Environment(\.palette) private var palette

    var size: CGFloat = 26

    private var innerSize: CGFloat { max(10, size * 0.54) }
    private var cornerRadius: CGFloat { size / 2 }

    var body: some View {
        Button(action: { appState.toggleRecording() }) {
            Group {
                if appState.recorder.isRecording {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(palette.recordRed)
                        .frame(width: innerSize, height: innerSize)
                } else {
                    Circle()
                        .fill(palette.recordRed)
                        .frame(width: innerSize, height: innerSize)
                }
            }
            .frame(width: size, height: size)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(palette.buttonSubtle)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(palette.borderSubtle, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(!appState.accessibility.isGranted)
        .animation(.easeInOut(duration: 0.15), value: appState.recorder.isRecording)
    }
}
