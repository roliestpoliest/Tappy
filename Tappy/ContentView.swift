import AppKit
import SwiftUI

struct ContentView: View {
    @Environment(AccessibilityManager.self) var accessibility
    @Environment(EventRecorder.self) var recorder
    @Environment(EventPlayer.self) var player

    @State private var recordings: [MacroRecording] = []
    @State private var selectedRecording: MacroRecording?
    @State private var showSidebar = true
    @State private var showNamePrompt = false
    @State private var pendingRecording: MacroRecording?
    @State private var config = PlaybackConfig()
    @State private var escapeMonitor: NSObjectProtocol?

    private var selectedIndex: Int? {
        recordings.firstIndex(where: { $0.id == selectedRecording?.id })
    }

    var body: some View {
        Group {
            if !accessibility.isGranted {
                AccessibilityPromptView()
                    .frame(minWidth: 500, minHeight: 420)
            } else {
                mainLayout
            }
        }
        .onAppear { loadRecordings() }
    }

    private var mainLayout: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                if showSidebar {
                    RecordingListView(
                        recordings: $recordings,
                        selectedRecording: $selectedRecording
                    )
                    .frame(width: 189)
                    .transition(.move(edge: .leading).combined(with: .opacity))

                    Divider()
                }

                Group {
                    if let index = selectedIndex {
                        ActionsPanel(recording: $recordings[index])
                    } else {
                        EmptyActionsView()
                    }
                }
                .frame(minWidth: 260, maxWidth: .infinity)
            }

            PlaybackBar(
                recording: selectedIndex.map { recordings[$0] },
                config: $config
            )
        }
        .animation(.spring(duration: 0.25), value: showSidebar)
        .frame(minWidth: 580, minHeight: 480)
        .navigationTitle("Tappy")
        .onAppear {
            escapeMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                guard event.keyCode == 53 else { return event }
                var consumed = false
                MainActor.assumeIsolated {
                    if player.isPlaying { player.stop(); consumed = true }
                }
                return consumed ? nil : event
            } as? NSObjectProtocol
        }
        .onDisappear {
            if let m = escapeMonitor { NSEvent.removeMonitor(m); escapeMonitor = nil }
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: { withAnimation(.spring(duration: 0.25)) { showSidebar.toggle() } }) {
                    Image(systemName: "sidebar.left")
                }
                .help(showSidebar ? "Hide Sidebar" : "Show Sidebar")
            }
            ToolbarItem(placement: .primaryAction) {
                RecordButton(
                    isRecording: recorder.isRecording,
                    elapsedTime: recorder.elapsedTime,
                    action: toggleRecording
                )
                .disabled(player.isPlaying)
            }
        }
        .sheet(isPresented: $showNamePrompt) {
            if let recording = pendingRecording {
                NameRecordingSheet(recording: recording) { named in
                    recordings.insert(named, at: 0)
                    selectedRecording = named
                    try? named.save()
                    showNamePrompt = false
                    pendingRecording = nil
                }
            }
        }
    }

    private func toggleRecording() {
        if recorder.isRecording {
            let recording = recorder.stopRecording()
            pendingRecording = recording
            showNamePrompt = true
        } else {
            recorder.startRecording()
        }
    }

    private func loadRecordings() {
        recordings = (try? MacroRecording.loadAll()) ?? []
    }
}
