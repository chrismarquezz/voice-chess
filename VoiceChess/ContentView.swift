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
    
    // Speech synthesizer
    let speechSynthesizer = AVSpeechSynthesizer()
    
    // Pending move awaiting confirmation
    @State private var pendingMove: Move? = nil
    @State private var pendingMoveText: String? = nil
    
    // Track move history as algebraic strings
    @State private var moveHistory: [String] = []
    
    var body: some View {
        VStack(spacing: 20) {
            
            // Chessboard
            Chessboard(chessboardModel: chessboardModel)
                .onMove { move, isLegal, from, to, _, promotionPiece in
                    guard isLegal else { return }
                    
                    // This block executes direct board moves (manual drags, if any)
                    let moveText = "\(from) to \(to)"
                    moveHistory.append(moveText)
                    
                    // Execute move
                    chessboardModel.game.make(move: move)
                    let newFen = FenSerialization.default.serialize(position: chessboardModel.game.position)
                    chessboardModel.setFen(newFen)
                    
                    // Speak move
                    let utterance = AVSpeechUtterance(string: "\(moveText) played")
                    utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
                    speechSynthesizer.speak(utterance)
                }
                .frame(width: 400, height: 400)
                .padding()
            
            Spacer()
            
            // Bottom toolbar
            HStack(spacing: 40) {
                
                // Start Listening
                Button(action: {
                    speechManager.startListening()
                }) {
                    Image(systemName: "mic.fill")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.green)
                }
                
                // Stop Listening / process voice
                Button(action: {
                    speechManager.stopListening()
                    
                    let recognized = speechManager.recognizedText.lowercased()
                    print("Recognized text: \(recognized)") // debug console output
                    
                    // Check if user asked to hear recent moves
                    if recognized.contains("show last") {
                        if let number = recognized.extractNumber() {
                            speakLastMoves(number)
                        } else {
                            speakLastMoves(5) // default last 5 moves
                        }
                        return
                    }
                    
                    // Voice confirmation flow
                    if let moveToConfirm = pendingMove, let moveText = pendingMoveText {
                        if recognized.contains("yes") {
                            moveHistory.append(moveText)
                            
                            // Execute move
                            chessboardModel.game.make(move: moveToConfirm)
                            let newFen = FenSerialization.default.serialize(position: chessboardModel.game.position)
                            chessboardModel.setFen(newFen)
                            
                            // Speak move using the same friendly text
                            let moveUtterance = AVSpeechUtterance(string: "\(moveText) played")
                            moveUtterance.voice = AVSpeechSynthesisVoice(language: "en-US")
                            speechSynthesizer.speak(moveUtterance)
                            
                            // Speak check/checkmate
                            if chessboardModel.game.isMate {
                                let checkmateUtterance = AVSpeechUtterance(string: "Checkmate!")
                                checkmateUtterance.voice = AVSpeechSynthesisVoice(language: "en-US")
                                checkmateUtterance.postUtteranceDelay = 0.4
                                speechSynthesizer.speak(checkmateUtterance)
                            } else if chessboardModel.game.isCheck {
                                let checkUtterance = AVSpeechUtterance(string: "Check!")
                                checkUtterance.voice = AVSpeechSynthesisVoice(language: "en-US")
                                checkUtterance.postUtteranceDelay = 0.4
                                speechSynthesizer.speak(checkUtterance)
                            }
                            
                            pendingMove = nil
                            pendingMoveText = nil
                            
                        } else if recognized.contains("no") {
                            pendingMove = nil
                            pendingMoveText = nil
                            let utterance = AVSpeechUtterance(string: "Move canceled.")
                            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
                            speechSynthesizer.speak(utterance)
                        }
                    } else {
                        // Parse new move
                        if let move = MoveParser(game: chessboardModel.game).parse(recognized) {
                            pendingMove = move
                            pendingMoveText = recognized // keep friendly string
                            
                            let utterance = AVSpeechUtterance(string: "\(pendingMoveText!). Say yes to confirm move, or no to cancel.")
                            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
                            speechSynthesizer.speak(utterance)
                        } else {
                            let utterance = AVSpeechUtterance(string: "Could not recognize a valid move.")
                            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
                            speechSynthesizer.speak(utterance)
                        }
                    }
                    
                }) {
                    Image(systemName: "stop.fill")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.red)
                }
                
                // Reset Board
                Button(action: {
                    let startFen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
                    chessboardModel.setFen(startFen)
                    moveHistory.removeAll()
                    
                    let utterance = AVSpeechUtterance(string: "Board reset")
                    utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
                    speechSynthesizer.speak(utterance)
                }) {
                    Image(systemName: "arrow.clockwise")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.blue)
                }
                
                // Flip Board
                Button(action: {
                    chessboardModel.perspective = chessboardModel.perspective == .white ? .black : .white
                }) {
                    Image(systemName: "arrow.2.circlepath")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.orange)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            .padding(.bottom, 30)
        }
    }
    
    // MARK: - Speak last moves
    private func speakLastMoves(_ count: Int) {
        let recentMoves = moveHistory.suffix(count)
        for move in recentMoves {
            let utterance = AVSpeechUtterance(string: move)
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            speechSynthesizer.speak(utterance)
        }
    }
}

// Helper to extract numbers from spoken text like "show last 3 moves"
extension String {
    func extractNumber() -> Int? {
        let words = self.components(separatedBy: " ")
        for word in words {
            if let num = Int(word) {
                return num
            }
        }
        return nil
    }
}

#Preview {
    ContentView()
}
