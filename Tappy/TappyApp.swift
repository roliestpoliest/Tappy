//
//  TappyApp.swift
//  Tappy
//
//  Created by Carolyn Heron on 4/11/26.
//

import SwiftUI

@main
struct TappyApp: App {
    @State private var appState = AppStateService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .task { appState.loadRecordings() }
        }
    }
}
