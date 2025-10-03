//
//  PlayView.swift
//  VoiceChess
//
//  Created by Chris Marquez on 10/1/25.
//

import SwiftUI

struct PlayView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 50) {
                Spacer()
                
                Text("VoiceChess")
                    .font(.system(size: 50, weight: .bold))
                
                // Chess-themed buttons
                VStack(spacing: 20) {
                    NavigationLink {
                        DifficultySelectionView()
                    } label: {
                        HStack {
                            Text("♞")
                                .font(.largeTitle)
                            Text("Play vs Bot")
                                .font(.title2.bold())
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(radius: 4)
                    }
                    
                    NavigationLink {
                        PlayLocalView()
                    } label: {
                        HStack {
                            Text("♔")
                                .font(.largeTitle)
                            Text("Play Local")
                                .font(.title2.bold())
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .foregroundColor(.black)
                        .cornerRadius(12)
                        .shadow(radius: 4)
                    }
                }
                .padding(.horizontal, 30)
                
                Spacer()
            }
            .padding()
            .background(
                Color.gray.opacity(0.1)
                    .ignoresSafeArea()
            )
        }
    }
}

#Preview {
    PlayView()
}
