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
    
    // Track position repetition (FEN → count)
    @State private var positionHistory: [String: Int] = [:]
    
    let speechSynthesizer = AVSpeechSynthesizer()
    
    var body: some View {
        VStack(spacing: 20) {
            
            // MARK: - Chessboard
            Chessboard(chessboardModel: chessboardModel)
                .onMove { move, isLegal, from, to, _, promotionPiece in
                    guard !gameOver else { return }   // prevent play if over
                    guard isLegal else { return }
                    
                    // Normal move
                    let moveText = "\(from) to \(to)"
                    moveHistory.append(moveText)
                    
                    chessboardModel.game.make(move: move)
                    let newFen = FenSerialization.default.serialize(position: chessboardModel.game.position)
                    chessboardModel.setFen(newFen)
                    
                    // --- TRACK REPETITION ---
                    trackPosition(newFen)
                    
                    let utterance = AVSpeechUtterance(string: "\(moveText) played")
                    utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
                    speechSynthesizer.speak(utterance)
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
                
                // --- GAME END CONDITIONS ---
                if chessboardModel.game.isMate {
                    speak("Checkmate!")
                    gameOver = true
                } else if chessboardModel.game.isCheck {
                    speak("Check!")
                } else if chessboardModel.game.legalMoves.isEmpty {
                    speak("Stalemate!")
                    gameOver = true
                } else if chessboardModel.game.position.counter.halfMoves >= 100 {
                    speak("Draw by fifty-move rule!")
                    gameOver = true
                }
                
                // --- TRACK REPETITION ---
                trackPosition(newFen)
                
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
        gameOver = false   // <--- reset
        positionHistory.removeAll() // reset repetition tracking
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
    
    // MARK: - Draw helpers
    func trackPosition(_ fen: String) {
        // Normalize FEN (ignore halfmove + fullmove counters for repetition tracking)
        let components = fen.split(separator: " ")
        if components.count >= 4 {
            let normalizedFen = components[0...3].joined(separator: " ")
            positionHistory[normalizedFen, default: 0] += 1
            
            if positionHistory[normalizedFen] == 3 {
                speak("Draw by threefold repetition!")
                gameOver = true
            }
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
