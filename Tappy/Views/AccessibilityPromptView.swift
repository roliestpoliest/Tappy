import AppKit
import SwiftUI

struct AccessibilityPromptView: View {
    @Environment(AccessibilityManager.self) var accessibility

    var body: some View {
        ZStack {
            Color.clear

            VStack(spacing: 32) {
                VStack(spacing: 16) {
                    Image(systemName: "hand.tap.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.tint)

                    Text("Accessibility Access Required")
                        .font(.title.bold())
                        .fontDesign(.rounded)

                    Text("Tappy needs Accessibility access to record and replay your inputs.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 360)
                }

                stepsCard

                Button(action: openSystemSettings) {
                    Label("Open System Settings", systemImage: "gearshape.fill")
                        .frame(minWidth: 220)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding(48)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            while !accessibility.isGranted {
                try? await Task.sleep(for: .seconds(0.5))
                accessibility.refresh()
            }
        }
    }

    private var stepsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            stepRow(number: "1", text: "Click \"Open System Settings\" below")
            stepRow(number: "2", text: "Navigate to Privacy & Security → Accessibility")
            stepRow(number: "3", text: "Enable the toggle next to Tappy")
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private func stepRow(number: String, text: String) -> some View {
        HStack(spacing: 12) {
            Text(number)
                .font(.headline)
                .fontDesign(.rounded)
                .frame(width: 28, height: 28)
                .background(Color.accentColor.opacity(0.15), in: Circle())
                .foregroundStyle(.tint)
            Text(text)
                .font(.callout)
        }
    }

    private func openSystemSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
}
