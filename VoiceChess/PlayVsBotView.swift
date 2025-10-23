import SwiftUI
import ChessboardKit
import ChessKit
import ChessKitEngine
import AVFoundation

struct PlayVsBotView: View {
    @AppStorage("pieceStyle") private var selectedTheme: String = "uscf"
    @State var chessboardModel: ChessboardModel

    @State private var moveHistory: [String] = []
    @StateObject var gameOverManager = GameOverManager()
    @StateObject var speechManager = SpeechManager()

    @State private var pendingMove: Move? = nil
    @State private var pendingMoveText: String? = nil

    let speechSynthesizer = AVSpeechSynthesizer()
    @State var engine: Engine? = nil
    @State var bestMoveText: String = ""
    @State private var thinkingText: String = ""
    @State private var isThinking: Bool = false
    @State private var botPlays: PieceColor = .black

    let skillLevel: Int   // passed from DifficultySelectionView

    init(skillLevel: Int) {
        self.skillLevel = skillLevel
        let theme = UserDefaults.standard.string(forKey: "pieceStyle") ?? "uscf"
        _chessboardModel = State(initialValue:
            ChessboardModel(
                fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
                perspective: .white,
                allowOpponentMove: true,
                pieceStyle: theme
            )
        )
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Difficulty: \(difficultyName(for: skillLevel))")
                .font(.headline)
                .padding(.top)

            Chessboard(chessboardModel: chessboardModel)
                .frame(width: 400, height: 400)
                .padding()

            if isThinking {
                HStack(spacing: 6) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Bot is thinking...")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            } else {
                Text(thinkingText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            if !bestMoveText.isEmpty {
                Text("Bot played: \(bestMoveText)")
                    .font(.headline)
            }
        }
        .onAppear {
            Task.detached { await startEngine() }
            speechManager.startListening()
        }
        .onDisappear {
            speechManager.stopListening()
        }
        .onChange(of: selectedTheme) { _, newValue in
            chessboardModel.pieceStyle = newValue
        }
        // every time speechManager updates recognized text
        .onChange(of: speechManager.recognizedText) { _, newText in
            handleVoiceCommand(newText.lowercased())
        }
        .alert(isPresented: $gameOverManager.gameOver) {
            Alert(
                title: Text("Game Over"),
                message: Text(gameOverManager.gameResult),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    // MARK: - Handle Voice Commands
    private func handleVoiceCommand(_ command: String) {
        guard !isThinking, !gameOverManager.gameOver else { return }

        let game = chessboardModel.game
        let parser = MoveParser(game: game)

        if let moveToConfirm = pendingMove, let moveText = pendingMoveText {
            if command.contains("yes") {
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
                Task { await botRespondIfNeeded() }
                return
            } else if command.contains("no") {
                speak("Move canceled")
                pendingMove = nil
                pendingMoveText = nil
                return
            }
        }

        // try parsing a new move
        if let move = parser.parse(command) {
            pendingMove = move
            pendingMoveText = command
            speak("\(command). Yes or no?")
        }
    }

    // MARK: - Bot logic (Skill + movetime)
    func botRespondIfNeeded() async {
        guard let engine = engine else { return }
        guard !gameOverManager.gameOver else { return }
        if chessboardModel.turn != botPlays { return }

        let currentFEN = FenSerialization.default.serialize(position: chessboardModel.game.position)
        let (skill, thinkTime): (Int, Int) = {
            switch skillLevel {
            case 5:  return (3, 800)
            case 11: return (10, 1500)
            case 16: return (18, 3000)
            default: return (10, 1500)
            }
        }()

        await engine.send(command: .stop)
        await engine.send(command: .isready)
        await engine.send(command: .setoption(id: "Skill Level", value: "\(skill)"))
        await engine.send(command: .position(.fen(currentFEN)))
        await engine.send(command: .isready)

        DispatchQueue.main.async {
            isThinking = true
            thinkingText = "Thinking..."
        }

        await engine.send(command: .go(movetime: thinkTime))
        guard let stream = await engine.responseStream else { return }

        for await response in stream {
            if case let .bestmove(move, _) = response {
                await engine.send(command: .stop)
                let moveObj = Move(string: move)
                if chessboardModel.game.legalMoves.contains(moveObj) {
                    DispatchQueue.main.async {
                        MoveHandler.handleMove(
                            move: moveObj,
                            moveText: move,
                            chessboardModel: &chessboardModel,
                            moveHistory: &moveHistory,
                            gameOverManager: gameOverManager,
                            speechSynthesizer: speechSynthesizer
                        )
                        bestMoveText = move
                        isThinking = false
                        speak("Bot played \(move)")
                    }
                }
                return
            }
        }
    }

    // MARK: - Engine setup
    func startEngine() async {
        let newEngine = Engine(type: .stockfish)
        await newEngine.start()
        await newEngine.send(command: .uci)
        await newEngine.send(command: .isready)
        engine = newEngine

        if botPlays == .white {
            Task { await botRespondIfNeeded() }
        }
    }

    // MARK: - Utilities
    func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        speechSynthesizer.speak(utterance)
    }

    func difficultyName(for level: Int) -> String {
        switch level {
        case 5: return "Easy"
        case 11: return "Medium"
        case 16: return "Hard"
        default: return "Custom"
        }
    }
}
