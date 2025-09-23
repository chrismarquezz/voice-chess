//
//  ContentView.swift
//  VoiceChess
//
//  Created by Chris Marquez on 9/21/25.
//

import SwiftUI
import ChessboardKit
import ChessKit
import AVFoundation

struct ContentView: View {
    
    @State var chessboardModel = ChessboardModel(
        fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
        perspective: .white,
        allowOpponentMove: false
    )
    
    @StateObject var speechManager = SpeechManager()
    @StateObject var gameOverManager = GameOverManager()
    
    @State private var pendingMove: Move? = nil
    @State private var pendingMoveText: String? = nil
    @State private var moveHistory: [String] = []
    
    let speechSynthesizer = AVSpeechSynthesizer()
    
    var body: some View {
        VStack(spacing: 20) {
            
            Chessboard(chessboardModel: chessboardModel)
                .onMove { move, isLegal, from, to, _, promotionPiece in
                    guard isLegal else { return }
                    guard !gameOverManager.gameOver else { return }
                    
                    let moveText = "\(from) to \(to)"
                    MoveHandler.handleMove(
                        move: move,
                        moveText: moveText,
                        chessboardModel: &chessboardModel,
                        moveHistory: &moveHistory,
                        gameOverManager: gameOverManager,
                        speechSynthesizer: speechSynthesizer
                    )
                }
                .frame(width: 350, height: 350)
                .padding()
            
            MoveDisplayView(moveText: pendingMoveText)
            
            Spacer()
            
            PresetPositionsView(chessboardModel: $chessboardModel, speak: speak)
            
            ToolbarView(
                startListening: { speechManager.startListening() },
                stopListening: handleStopListening,
                resetBoard: resetBoard,
                flipBoard: flipBoard
            )
        }
        .alert(isPresented: $gameOverManager.gameOver) {
            Alert(
                title: Text("Game Over"),
                message: Text(gameOverManager.gameResult),
                dismissButton: .default(Text("OK")) {
                }
            )
        }
    }
    
    // MARK: - Voice stop handling
    func handleStopListening() {
        guard !gameOverManager.gameOver else { return }
        speechManager.stopListening()
        let recognized = speechManager.recognizedText.lowercased()
        
        if recognized.contains("show last") {
            let count = recognized.extractNumber() ?? 5
            for move in moveHistory.suffix(count) {
                speak(move)
            }
            return
        }
        
        if let moveToConfirm = pendingMove, let moveText = pendingMoveText {
            if recognized.contains("yes") {
                MoveHandler.handleMove(
                    move: moveToConfirm,
                    moveText: moveText,
                    chessboardModel: &chessboardModel,
                    moveHistory: &moveHistory,
                    gameOverManager: gameOverManager,
                    speechSynthesizer: speechSynthesizer
                )
                pendingMove = nil
                pendingMoveText = nil
            } else if recognized.contains("no") {
                pendingMove = nil
                pendingMoveText = nil
                speak("Move canceled")
            }
        } else {
            pendingMoveText = recognized
            if let move = MoveParser(game: chessboardModel.game).parse(recognized) {
                pendingMove = move
                
                if let promo = move.promotion {
                    // Speak promotion confirmation
                    let pieceName: String
                    switch promo {
                    case .queen: pieceName = "queen"
                    case .rook: pieceName = "rook"
                    case .bishop: pieceName = "bishop"
                    case .knight: pieceName = "knight"
                        
                    default: pieceName = "unknown piece"
                    }
                    speak("\(pendingMoveText!). Promoting to \(pieceName). Yes or no.")
                } else {
                    speak("\(pendingMoveText!). Yes or no.")
                }
                
            } else {
                speak("Could not recognize a valid move.")
            }
        }
    }
    
    func resetBoard() {
        let startFen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
        chessboardModel.setFen(startFen)
        moveHistory.removeAll()
    }
    
    func flipBoard() {
        chessboardModel.perspective = chessboardModel.perspective == .white ? .black : .white
        speak("Board flip")
    }
    
    func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        speechSynthesizer.speak(utterance)
    }
}

extension String {
    func extractNumber() -> Int? {
        let words = self.components(separatedBy: " ")
        for word in words {
            if let num = Int(word) { return num }
        }
        return nil
    }
}

#Preview {
    ContentView()
}
