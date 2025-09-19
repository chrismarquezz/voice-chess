//
//  RootView.swift
//  VoiceChess
//
//  Created by Chris Marquez on 9/17/25.
//


import SwiftUI

struct RootView: View {
    @State private var showGame = false
    
    var body: some View {
        if showGame {
            ContentView()
        } else {
            MenuView(onPlay: {
                showGame = true
            })
        }
    }
}

#Preview {
    RootView()
}
