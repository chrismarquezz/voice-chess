//
//  DifficultySelectionView.swift
//  VoiceChess
//

import SwiftUI

struct DifficultySelectionView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink("Easy", destination: PlayVsBotView(skillLevel: 5))
                NavigationLink("Medium", destination: PlayVsBotView(skillLevel: 11))
                NavigationLink("Hard", destination: PlayVsBotView(skillLevel: 16))
            }
            .navigationTitle("Play vs Bot")
        }
    }
}

#Preview {
    DifficultySelectionView()
}
