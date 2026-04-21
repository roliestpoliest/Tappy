//
//  TappyApp.swift
//  Tappy
//
//  Created by Carolyn Heron on 4/11/26.
//

import SwiftUI

@main 
struct TappyApp: App {
    @State private var accessibilityService = AccessibilityService()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(accessibilityService)
                .onAppear {
                    accessibilityService.requestAccess()
                }
        }
    }
}
