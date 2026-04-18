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
    let mouseMover = BezierMouseMover()
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
            
            Text("Has accesibility pernmission: \(AXIsProcessTrusted() ? "YES" : "NO")")
            Text("Hit the escape key to stop the auto clicker")
            
            // Example: center of screen
            let screen = NSScreen.main!.frame
            let point = CGPoint(x: screen.midX, y: screen.midY)
            VStack(spacing: 20) {
                Button("Start Clicking") {
                    clicker.startClicking(at: point, interval: 0.2)
                }

                Button("Move mouse to middle of screen ith animation") {
                    mouseMover.move(to: point, duration: 0.6)
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
