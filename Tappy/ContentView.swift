//
//  ContentView.swift
//  Tappy
//
//  Created by Carolyn Heron on 4/11/26.
//

import SwiftUI
import ApplicationServices

struct ContentView: View {
    let clicker = AutoClicker()
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
            
            Text("Has accesibility pernmission: \(AXIsProcessTrusted() ? "YES" : "NO")")
            
            VStack(spacing: 20) {
                Button("Start Clicking") {
                    // Example: center of screen
                    let screen = NSScreen.main!.frame
                    let point = CGPoint(x: screen.midX, y: screen.midY)

                    clicker.startClicking(at: point, interval: 0.2)
                }

                Button("Stop Clicking") {
                    clicker.stopClicking()
                }
            }
            .frame(width: 300, height: 200)
            
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
