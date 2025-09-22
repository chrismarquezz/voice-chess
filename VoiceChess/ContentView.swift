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
    
    // MARK: - State
    @State var chessboardModel = ChessboardModel(
        fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
        perspective: .white,
        allowOpponentMove: false
    )
    
    @StateObject var speechManager = SpeechManager()
    
    @State private var pendingMove: Move? = nil
    @State private var pendingMoveText: String? = nil
    @State private var moveHistory: [String] = []
    @State private var gameOver: Bool = false
    
    let speechSynthesizer = AVSpeechSynthesizer()
    
    var body: some View {
        VStack(spacing: 20) {
            
            // MARK: - Chessboard
            Chessboard(chessboardModel: chessboardModel)
                .onMove { move, isLegal, from, to, _, promotionPiece in
                    guard !gameOver else { return }   // prevent play if over
                    guard isLegal else { return }
                    
                    let moveText = "\(from) to \(to)"
                    MoveHandler.handleMove(move: move,
                                           moveText: moveText,
                                           chessboardModel: &chessboardModel,
                                           moveHistory: &moveHistory,
                                           gameOver: &gameOver,
                                           speechSynthesizer: speechSynthesizer)
                }
                .frame(width: 350, height: 350)
                .padding()
            
            // MARK: - Move display
            MoveDisplayView(moveText: pendingMoveText)
            
            Spacer()
            
            // MARK: - Preset Positions Buttons
            PresetPositionsView(chessboardModel: $chessboardModel, speak: speak)
            
            // MARK: - Toolbar
            ToolbarView(
                startListening: { speechManager.startListening() },
                stopListening: handleStopListening,
                resetBoard: resetBoard,
                flipBoard: flipBoard
            )
        }
    }
    
    // MARK: - Voice stop handling
    func handleStopListening() {
        guard !gameOver else { return }   // prevent voice moves if over
        speechManager.stopListening()
        let recognized = speechManager.recognizedText.lowercased()
        
        // Show last moves
        if recognized.contains("show last") {
            let count = recognized.extractNumber() ?? 5
            speakLastMoves(count)
            return
        }
        
        // Handle confirmation of normal move
        if let moveToConfirm = pendingMove, let moveText = pendingMoveText {
            if recognized.contains("yes") {
                MoveHandler.handleMove(move: moveToConfirm,
                                       moveText: moveText,
                                       chessboardModel: &chessboardModel,
                                       moveHistory: &moveHistory,
                                       gameOver: &gameOver,
                                       speechSynthesizer: speechSynthesizer)
                pendingMove = nil
                pendingMoveText = nil
            } else if recognized.contains("no") {
                pendingMove = nil
                pendingMoveText = nil
                speak("Move canceled")
            }
        } else {
            // Parse new move
            pendingMoveText = recognized
            if let move = MoveParser(game: chessboardModel.game).parse(recognized) {
                pendingMove = move
                speak("\(pendingMoveText!). Yes to confirm, no to cancel.")
            } else {
                speak("Could not recognize a valid move.")
            }
        }
    }
    
    // MARK: - Reset / flip
    func resetBoard() {
        let startFen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
        chessboardModel.setFen(startFen)
        moveHistory.removeAll()
        gameOver = false
        speak("Board reset")
    }
    
    func flipBoard() {
        chessboardModel.perspective = chessboardModel.perspective == .white ? .black : .white
        speak("Board flip")
    }
    
    // MARK: - Speech helpers
    func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        speechSynthesizer.speak(utterance)
    }
    
    func speakLastMoves(_ count: Int) {
        let recentMoves = moveHistory.suffix(count)
        for move in recentMoves {
            speak(move)
        }
    }
}

// Helper to extract numbers from spoken text like "show last 3 moves"
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
