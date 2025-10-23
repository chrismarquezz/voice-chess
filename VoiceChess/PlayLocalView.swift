//
//  PlayLocalView.swift
//  VoiceChess
//
//  Created by Chris Marquez on 9/21/25.
//

import SwiftUI
import ChessboardKit
import ChessKit
import AVFoundation

struct PlayLocalView: View {
    
    // Persisted theme
    @AppStorage("pieceStyle") private var selectedTheme: String = "pixel"
    
    // Chessboard model
    @State private var chessboardModel: ChessboardModel? = nil
    
    @StateObject var speechManager = SpeechManager()
    @StateObject var gameOverManager = GameOverManager()
    
    @State private var pendingMove: Move? = nil
    @State private var pendingMoveText: String? = nil
    @State private var isConfirmingMove: Bool = false
    @State private var moveHistory: [String] = []
    
    @State private var debounceWorkItem: DispatchWorkItem?
    
    let speechSynthesizer = AVSpeechSynthesizer()
    
    var body: some View {
        VStack(spacing: 20) {
            
            Spacer()
            
            if let chessboardModel = chessboardModel {
                Chessboard(chessboardModel: chessboardModel)
                    .onMove { move, isLegal, from, to, _, _ in
                        guard isLegal else { return }
                        guard !gameOverManager.gameOver else { return }
                        
                        let moveText = "\(from) to \(to)"
                        MoveHandler.handleMove(
                            move: move,
                            moveText: moveText,
                            chessboardModel: &self.chessboardModel!,
                            moveHistory: &moveHistory,
                            gameOverManager: gameOverManager,
                            speechSynthesizer: speechSynthesizer
                        )
                    }
                    .frame(width: 400, height: 400)
                    .padding()
            } else {
                ProgressView("Loading Board...")
            }
            
            MoveDisplayView(moveText: pendingMoveText)
            
            Spacer()
                                    
        }
        .alert(isPresented: $gameOverManager.gameOver) {
            Alert(
                title: Text("Game Over"),
                message: Text(gameOverManager.gameResult),
                dismissButton: .default(Text("OK"))
            )
        }
        // MARK: - Initialize
        .onAppear {
            chessboardModel = ChessboardModel(
                fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
                perspective: .white,
                allowOpponentMove: false,
                pieceStyle: selectedTheme
            )
            speechManager.startListening()
        }
        .onDisappear {
            speechManager.stopListening()
        }
        .onChange(of: selectedTheme) { _, newValue in
            chessboardModel?.pieceStyle = newValue
        }
        // MARK: - Handle Speech
        .onChange(of: speechManager.recognizedText) { _, newText in
            debounceSpeechProcessing(newText)
        }
    }
    
    // MARK: - Handle Recognized Speech
    func handleSpeech(_ recognized: String) {
        guard !recognized.isEmpty, !gameOverManager.gameOver else { return }

        let lower = recognized.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if lower.isEmpty { return }
        
        // PHASE 1: Confirm existing pending move
        if isConfirmingMove, let move = pendingMove, let moveText = pendingMoveText {
            if lower.contains("yes") {
                MoveHandler.handleMove(
                    move: move,
                    moveText: moveText,
                    chessboardModel: &chessboardModel!,
                    moveHistory: &moveHistory,
                    gameOverManager: gameOverManager,
                    speechSynthesizer: speechSynthesizer
                )
                pendingMove = nil
                pendingMoveText = nil
                isConfirmingMove = false
                speak("Move confirmed.")
                return
            } else if lower.contains("no") {
                pendingMove = nil
                pendingMoveText = nil
                isConfirmingMove = false
                speak("Move canceled.")
                return
            }
        }
        
        // PHASE 2: Interpret as a possible move
        if let move = MoveParser(game: chessboardModel!.game).parse(lower) {
            pendingMove = move
            pendingMoveText = lower
            isConfirmingMove = true
            
            if let promo = move.promotion {
                let promoPiece: String
                switch promo {
                case .queen: promoPiece = "queen"
                case .rook: promoPiece = "rook"
                case .bishop: promoPiece = "bishop"
                case .knight: promoPiece = "knight"
                default: promoPiece = "piece"
                }
                speak("\(lower). Promoting to \(promoPiece). Is that correct?")
            } else {
                speak("\(lower). Is that your move?")
            }
        }
    }
    
    // MARK: - Debounce to prevent mid-sentence triggers
    func debounceSpeechProcessing(_ text: String) {
        debounceWorkItem?.cancel()
        let workItem = DispatchWorkItem {
            handleSpeech(text)
        }
        debounceWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: workItem)
    }

    // MARK: - Speak helper
    func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.45
        speechSynthesizer.speak(utterance)
    }
    
    // MARK: - Reset / Flip
    func resetBoard() {
        let startFen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
        chessboardModel?.setFen(startFen)
        moveHistory.removeAll()
    }
    
    func flipBoard() {
        chessboardModel?.perspective = chessboardModel!.perspective == .white ? .black : .white
        speak("Board flipped.")
    }
}

#Preview {
    PlayLocalView()
}
