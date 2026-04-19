import SwiftUI

@main
struct TappyApp: App {
    @State private var accessibilityManager = AccessibilityManager()
    @State private var recorder = EventRecorder()
    @State private var player = EventPlayer()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(accessibilityManager)
                .environment(recorder)
                .environment(player)
                .onAppear { accessibilityManager.requestAccess() }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .commands {
            CommandGroup(after: .appInfo) {
                Button(recorder.isRecording ? "Stop Recording" : "Start Recording") {
                    if recorder.isRecording {
                        _ = recorder.stopRecording()
                    } else {
                        recorder.startRecording()
                    }
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])
                .disabled(!accessibilityManager.isGranted)
            }
        }

        MenuBarExtra("Tappy", systemImage: "record.circle") {
            MenuBarView()
                .environment(accessibilityManager)
                .environment(recorder)
                .environment(player)
        }
        .menuBarExtraStyle(.window)
    }
}
