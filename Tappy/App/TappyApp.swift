import AppKit
import SwiftUI

@main
struct TappyApp: App {
    @State private var appState = AppStateService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .environment(\.palette, Palette(scheme: resolvedScheme))
                .preferredColorScheme(appState.colorScheme.swiftUIScheme)
                .task { appState.loadRecordings() }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize)
        .defaultSize(Metrics.mainWindowSize)
    }

    private var resolvedScheme: ColorScheme {
        switch appState.colorScheme {
        case .light:  return .light
        case .dark:   return .dark
        case .system: return NSApplication.shared.effectiveAppearance.name.rawValue.contains("Dark") ? .dark : .light
        }
    }
}
