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
    
    // Track move history as algebraic strings
    @State private var moveHistory: [String] = []
    
    var body: some View {
        VStack(spacing: 20) {
            
            // Chessboard
            Chessboard(chessboardModel: chessboardModel)
                .onMove { move, isLegal, from, to, _, promotionPiece in
                    guard isLegal else { return }
                    
                    let moveText = "\(from) to \(to)"
                    moveHistory.append(moveText)
                    
                    // Execute move
                    chessboardModel.game.make(move: move)
                    let newFen = FenSerialization.default.serialize(position: chessboardModel.game.position)
                    chessboardModel.setFen(newFen)
                    
                    // Check/checkmate
                    var utteranceString = "\(moveText) played"
                    if chessboardModel.game.isMate {
                        utteranceString += ". Checkmate!"
                    } else if chessboardModel.game.isCheck {
                        utteranceString += ". Check!"
                    }
                    
                    // Speak move
                    let utterance = AVSpeechUtterance(string: utteranceString)
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
                    if let moveToConfirm = pendingMove {
                        if recognized.contains("yes") {
                            let moveText = "\(moveToConfirm.from) to \(moveToConfirm.to)"
                            moveHistory.append(moveText)
                            
                            // Execute move
                            chessboardModel.game.make(move: moveToConfirm)
                            let newFen = FenSerialization.default.serialize(position: chessboardModel.game.position)
                            chessboardModel.setFen(newFen)
                            
                            // Speak move and check/checkmate
                            var utteranceString = "\(moveText) played"
                            if chessboardModel.game.isMate {
                                utteranceString += ". Checkmate!"
                            } else if chessboardModel.game.isCheck {
                                utteranceString += ". Check!"
                            }
                            
                            let utterance = AVSpeechUtterance(string: utteranceString)
                            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
                            speechSynthesizer.speak(utterance)
                            
                            pendingMove = nil
                        } else if recognized.contains("no") {
                            pendingMove = nil
                            let utterance = AVSpeechUtterance(string: "Move canceled. Please try again.")
                            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
                            speechSynthesizer.speak(utterance)
                        }
                    } else {
                        // Parse new move
                        if let move = MoveParser(game: chessboardModel.game).parse(speechManager.recognizedText) {
                            pendingMove = move
                            let moveText = "\(move.from) to \(move.to)"
                            let utterance = AVSpeechUtterance(string: "\(moveText). Is that the move you would like to play?")
                            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
                            speechSynthesizer.speak(utterance)
                        } else {
                            let utterance = AVSpeechUtterance(string: "Could not recognize a valid move. Please try again.")
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
