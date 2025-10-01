//
//  ChangeThemeView.swift
//  VoiceChess
//
//  Created by Chris Marquez on 10/1/25.
//

import SwiftUI
import ChessboardKit
import ChessKit

struct ChangeThemeView: View {
    @AppStorage("pieceStyle") private var selectedTheme: String = "uscf"
    
    @State private var chessboardModel: ChessboardModel? = nil
    
    // Available themes
    let themes = ["uscf", "pixel", "big-pixel"]
    
    var body: some View {
        VStack {
            if let chessboardModel = chessboardModel {
                Chessboard(chessboardModel: chessboardModel)
                    .frame(width: 300, height: 300)
                    .padding()
            } else {
                ProgressView("Loading Board...")
            }
            
            Text("Select a Theme")
                .font(.headline)
            
            HStack(spacing: 16) {
                ForEach(themes, id: \.self) { theme in
                    Button(action: {
                        selectedTheme = theme
                        chessboardModel?.pieceStyle = theme
                    }) {
                        Text(theme.capitalized)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 16)
                            .background(selectedTheme == theme ? Color.blue : Color.gray.opacity(0.3))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
            .padding()
            
            Spacer()
        }
        .navigationTitle("Change Theme")
        .onAppear {
            chessboardModel = ChessboardModel(
                fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
                perspective: .white,
                allowOpponentMove: true,
                pieceStyle: selectedTheme
            )
        }
    }
}

#Preview {
    ChangeThemeView()
}
