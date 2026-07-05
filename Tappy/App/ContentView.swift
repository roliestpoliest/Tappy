import AppKit
import SwiftUI

struct ContentView: View {
    @Environment(AppStateService.self) private var appState

    var body: some View {
        Group {
            if appState.isCollapsed {
                FloatingToolbarView()
                    .frame(width: Metrics.floatingSize.width, height: Metrics.floatingSize.height)
            } else {
                MainWindowView()
                    .frame(
                        minWidth: Metrics.mainWindowSize.width,
                        maxWidth: .infinity,
                        minHeight: Metrics.mainWindowSize.height,
                        maxHeight: .infinity
                    )
            }
        }
        .background(WindowConfigurator(isCollapsed: appState.isCollapsed))
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: appState.isCollapsed)
    }
}

struct WindowConfigurator: NSViewRepresentable {
    let isCollapsed: Bool

    func makeNSView(context: Context) -> NSView { NSView() }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            guard let window = nsView.window else { return }

            if isCollapsed {
                if context.coordinator.lastExpandedFrame == nil {
                    context.coordinator.lastExpandedFrame = window.frame
                }
                window.styleMask.remove(.resizable)
                window.contentMinSize = Metrics.floatingSize
                window.contentMaxSize = Metrics.floatingSize
                window.level = .floating
                window.isMovableByWindowBackground = true
                window.setContentSize(Metrics.floatingSize)
            } else {
                window.styleMask.insert(.resizable)
                window.contentMinSize = Metrics.mainWindowSize
                window.contentMaxSize = NSSize(
                    width: CGFloat.greatestFiniteMagnitude,
                    height: CGFloat.greatestFiniteMagnitude
                )
                window.level = .normal
                window.isMovableByWindowBackground = false
                if let restore = context.coordinator.lastExpandedFrame {
                    window.setFrame(restore, display: true, animate: true)
                    context.coordinator.lastExpandedFrame = nil
                }
            }
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        var lastExpandedFrame: NSRect?
    }
}
