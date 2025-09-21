//
//  PresetPositionsView.swift
//  VoiceChess
//
//  Created by Chris Marquez on 9/21/25.
//

import SwiftUI
import ChessboardKit
import ChessKit
import AVFoundation

struct PresetPositionsView: View {
    @Binding var chessboardModel: ChessboardModel
    let speak: (String) -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button("Start Position") {
                setBoard(fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1", description: "Starting position")
            }

            Button("Castling") {
                // Example FEN where castling is possible
                setBoard(fen: "r3k1nr/ppp1qppp/2np4/2b1p3/2B1P1b1/2NPBN2/PPP2PPP/R2QK2R w KQkq - 0 1", description: "Castling position")
            }

            Button("Stalemate") {
                // Example stalemate position (black to move)
                setBoard(fen: "7k/5K2/8/6Q1/8/8/8/8 w - - 0 1", description: "Stalemate position")
            }

            Button("Checkmate") {
                // Example checkmate position (white delivered mate)
                setBoard(fen: "3k4/6R/3K4/8/8/8/8/8 w - - 0 1", description: "Checkmate position")
            }
        }
        .padding(.horizontal)
        .buttonStyle(.borderedProminent)
    }

    private func setBoard(fen: String, description: String) {
        chessboardModel.setFen(fen)
        speak(description)
    }
}
