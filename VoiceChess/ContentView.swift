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
    
    let speechSynthesizer = AVSpeechSynthesizer()
    
    var body: some View {
        VStack(spacing: 20) {
            
            // MARK: - Chessboard
            Chessboard(chessboardModel: chessboardModel)
                .onMove { move, isLegal, from, to, _, promotionPiece in
                    guard isLegal else { return }
                    
                    // Normal move
                    let moveText = "\(from) to \(to)"
                    moveHistory.append(moveText)
                    
                    chessboardModel.game.make(move: move)
                    let newFen = FenSerialization.default.serialize(position: chessboardModel.game.position)
                    chessboardModel.setFen(newFen)
                    
                    let utterance = AVSpeechUtterance(string: "\(moveText) played")
                    utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
                    speechSynthesizer.speak(utterance)
                }
                .frame(width: 400, height: 400)
                .padding()
            
            // MARK: - Move display
            MoveDisplayView(moveText: pendingMoveText)
            
            Spacer()
            
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
        speechManager.stopListening()
        let recognized = speechManager.recognizedText.lowercased()
        print("Recognized text: \(recognized)")
        
        // Show last moves
        if recognized.contains("show last") {
            if let number = recognized.extractNumber() {
                speakLastMoves(number)
            } else {
                speakLastMoves(5)
            }
            return
        }
        
        // Handle confirmation of normal move
        if let moveToConfirm = pendingMove, let moveText = pendingMoveText {
            if recognized.contains("yes") {
                moveHistory.append(moveText)
                
                chessboardModel.game.make(move: moveToConfirm)
                let newFen = FenSerialization.default.serialize(position: chessboardModel.game.position)
                chessboardModel.setFen(newFen)
                
                speak("\(moveText) played")
                
                if chessboardModel.game.isMate {
                    speak("Checkmate!")
                } else if chessboardModel.game.isCheck {
                    speak("Check!")
                }
                
                pendingMove = nil
                pendingMoveText = nil
            } else if recognized.contains("no") {
                pendingMove = nil
                pendingMoveText = nil
                speak("Move canceled.")
            }
        } else {
            // Parse new move
            pendingMoveText = recognized
            if let move = MoveParser(game: chessboardModel.game).parse(recognized) {
                pendingMove = move
                speak("\(pendingMoveText!). Say yes to confirm move, or no to cancel.")
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
