//
//  DifficultySelectionView.swift
//  VoiceChess
//
//  Created by Chris Marquez on 10/2/25.
//

import SwiftUI

struct DifficultySelectionView: View {
    var body: some View {
        VStack(spacing: 40) {
            Text("Choose Difficulty")
                .font(.largeTitle)
                .bold()
            
            // Easy
            NavigationLink {
                PlayVsBotView(skillLevel: 5)
            } label: {
                DifficultyButton(label: "Easy", color: .green)
            }
            
            // Medium
            NavigationLink {
                PlayVsBotView(skillLevel: 11)
            } label: {
                DifficultyButton(label: "Medium", color: .yellow)
            }
            
            // Hard
            NavigationLink {
                PlayVsBotView(skillLevel: 16)
            } label: {
                DifficultyButton(label: "Hard", color: .red)
            }
        }
        .padding()
    }
}

struct DifficultyButton: View {
    let label: String
    let color: Color
    
    var body: some View {
        Text(label)
            .font(.title)
            .bold()
            .frame(width: 200, height: 80)
            .background(color.opacity(0.8))
            .foregroundColor(.white)
            .cornerRadius(15)
            .shadow(radius: 5)
    }
}
