//
//  RootView.swift
//  VoiceChess
//
//  Created by Chris Marquez on 9/21/25.
//

import SwiftUI

struct RootView: View {
    @State private var showMainTabs = false
    @State private var animateFade = false
    
    private let splashDuration: Double = 3.0
    
    var body: some View {
        ZStack {
            if showMainTabs {
                // Main Tabs
                TabView {
                    // Local voice-controlled play
                    PlayLocalView()
                        .tabItem {
                            Label("Local", systemImage: "person.2.fill")
                        }
                    
                    // Bot play tab
                    DifficultySelectionView()
                        .tabItem {
                            Label("Bot", systemImage: "cpu.fill")
                        }
                    
                    // Optional: Settings tab
                    SettingsView()
                        .tabItem {
                            Label("Settings", systemImage: "gearshape.fill")
                        }
                }
                .transition(.opacity)
                .ignoresSafeArea()
                
            } else {
                // Splash / Loading screen
                LoadingView()
                    .transition(.opacity)
                    .opacity(animateFade ? 0 : 1)
                    .ignoresSafeArea()
            }
        }
        .onAppear {
            // Start fade transition
            DispatchQueue.main.asyncAfter(deadline: .now() + splashDuration) {
                withAnimation(.easeOut(duration: 1.0)) {
                    animateFade = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    showMainTabs = true
                }
            }
        }
    }
}

#Preview {
    RootView()
}
