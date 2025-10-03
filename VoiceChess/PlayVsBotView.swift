//
//  PlayVsBotView.swift
//  VoiceChess
//
//  Created by Chris Marquez on 10/2/25.
//

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
    let speechSynthesizer = AVSpeechSynthesizer()
    
    @State var engine: Engine? = nil
    @State var bestMoveText: String = ""
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
                .onMove { move, isLegal, from, to, _, promotionPiece in
                    guard isLegal, !gameOverManager.gameOver else { return }
                    
                    let moveText = "\(from)\(to)" + (promotionPiece?.rawValue ?? "")
                    MoveHandler.handleMove(
                        move: move,
                        moveText: moveText,
                        chessboardModel: &chessboardModel,
                        moveHistory: &moveHistory,
                        gameOverManager: gameOverManager,
                        speechSynthesizer: speechSynthesizer
                    )
                    
                    Task { await botRespondIfNeeded() }
                }
                .frame(width: 400, height: 400)
                .padding()
            
            if !bestMoveText.isEmpty {
                Text("Bot played: \(bestMoveText)")
                    .font(.headline)
            }
        }
        .onAppear {
            Task.detached { await startEngine() }
        }
        .onChange(of: selectedTheme) { _, newValue in
            chessboardModel.pieceStyle = newValue
        }
        .alert(isPresented: $gameOverManager.gameOver) {
            Alert(
                title: Text("Game Over"),
                message: Text(gameOverManager.gameResult),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    // MARK: - Engine Setup
    func startEngine() async {
        let newEngine = Engine(type: .stockfish)
        await newEngine.start()
        
        if let nnueURL = Bundle.main.url(forResource: "nn-1111cefa1111", withExtension: "nnue") {
            await newEngine.send(command: .setoption(id: "EvalFile", value: nnueURL.path))
        }
        
        await newEngine.send(command: .uci)
        await newEngine.send(command: .isready)
        engine = newEngine
        
        // If bot plays White, make it move first
        if botPlays == .white {
            Task { await botRespondIfNeeded() }
        }
    }
    
    // MARK: - Bot Respond
    func botRespondIfNeeded() async {
        guard let engine = engine else { return }
        guard !gameOverManager.gameOver else { return }
        if chessboardModel.turn != botPlays { return }
        
        let currentFEN = FenSerialization.default.serialize(position: chessboardModel.game.position)
        
        // Determine bot parameters based on skill level
        let (depth, skill, thinkTime): (Int, Int, UInt64) = {
            switch skillLevel {
            case 5: return (5, 5, 1_000_000_000)       // Easy
            case 11: return (10, 10, 2_000_000_000)    // Medium
            case 16: return (18, 15, 3_000_000_000)    // Hard
            default: return (10, 10, 2_000_000_000)    // Default to Medium
            } }()
        
        await engine.send(command: .stop)
        await engine.send(command: .setoption(id: "Skill Level", value: "\(skill)"))
        await engine.send(command: .position(.fen(currentFEN)))
        
        // Wait for bot to "think"
        try? await Task.sleep(nanoseconds: thinkTime)
        
        // Request move using depth
        await engine.send(command: .go(depth: depth))
        
        guard let responseStream = await engine.responseStream else { return }
        
        for await response in responseStream {
            if case let .info(info) = response, let pv = info.pv, !pv.isEmpty {
                let move = Move(string: pv[0])
                if chessboardModel.game.legalMoves.contains(move) {
                    DispatchQueue.main.async {
                        MoveHandler.handleMove(
                            move: move,
                            moveText: pv[0],
                            chessboardModel: &chessboardModel,
                            moveHistory: &moveHistory,
                            gameOverManager: gameOverManager,
                            speechSynthesizer: speechSynthesizer
                        )
                        bestMoveText = pv[0]
                    }
                    break
                }
            }
        }
    }
    
    // MARK: - Difficulty Name
    func difficultyName(for level: Int) -> String {
        switch level {
        case 5: return "Easy"
        case 11: return "Medium"
        case 16: return "Hard"
        default: return "Custom"
        }
    }
}
