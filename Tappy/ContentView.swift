//
//  ContentView.swift
//  Tappy
//
//  Created by Carolyn Heron on 4/11/26.
//

import SwiftUI

struct ContentView: View {
    @Environment(AccessibilityService.self) var accessibility
    
    var body: some View {
        VStack {
            // Temporary view
            Text("Accessiblity granted: \(accessibility.isGranted.description)")
            
        }
        .padding(200)
    }
}
