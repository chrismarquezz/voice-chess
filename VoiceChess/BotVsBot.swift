//
//  StockfishDebugView.swift
//  VoiceChess
//
//  Created by Chris Marquez on 9/28/25.
//

import SwiftUI
import ChessboardKit
import ChessKit
import ChessKitEngine
import AVFoundation

struct BotVsBotView: View {
    
    @State var chessboardModel = ChessboardModel(
        fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
        perspective: .white,
        allowOpponentMove: true
    )
    
    @State private var moveHistory: [String] = []
    @StateObject var gameOverManager = GameOverManager()
    let speechSynthesizer = AVSpeechSynthesizer()
    
    @State var engine: Engine? = nil
    @State var bestMoveText: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            
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
                    
                    Task {
                        await evaluateCurrentPosition()
                    }
                }
                .frame(width: 350, height: 350)
                .padding()
            
            Text("Current FEN: \(FenSerialization.default.serialize(position: chessboardModel.game.position))")
                .font(.caption)
                .multilineTextAlignment(.center)
                .padding()
            
            Text("Engine Suggestion: \(bestMoveText)")
                .font(.headline)
            
            Spacer()
            
            Button("Start Engine vs Engine") {
                Task {
                    await startEngineVsEngine()
                }
            }
        }
        .onAppear {
            Task {
                Task.detached {
                    await startEngine()
                }
            }
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
        await newEngine.set(loggingEnabled: true)
        await newEngine.start()
        
        guard let nnueURL = Bundle.main.url(forResource: "nn-1111cefa1111", withExtension: "nnue") else {
            print("[DEBUG] Could not find NNUE file")
            return
        }
        let nnuePath = nnueURL.path
        
        await newEngine.send(command: .uci)
        await newEngine.send(command: .isready)
        await newEngine.send(command: .setoption(id: "EvalFile", value: nnuePath))
        await newEngine.send(command: .isready)
        await newEngine.send(command: .position(.startpos))
        
        engine = newEngine
        print("[DEBUG] Engine ready")
        
        // Initial evaluation of starting position
        await evaluateCurrentPosition()
    }
    
    // MARK: - Evaluate Current Position
    func evaluateCurrentPosition() async {
        guard let engine = engine else { return }
        
        let currentFEN = FenSerialization.default.serialize(position: chessboardModel.game.position)
        print("[DEBUG] Evaluating FEN: \(currentFEN)")
        
        await engine.send(command: .stop)
        await engine.send(command: .position(.fen(currentFEN)))
        await engine.send(command: .go(depth: 10))
        
        guard let responseStream = await engine.responseStream else { return }
        
        for await response in responseStream {
            if case let .info(info) = response, let pv = info.pv, !pv.isEmpty {
                let move = Move(string: pv[0])
                if chessboardModel.game.legalMoves.contains(move) {
                    DispatchQueue.main.async {
                        self.bestMoveText = pv[0]
                    }
                    print("[DEBUG] Engine best legal move: \(pv[0])")
                    break
                } else {
                    print("[DEBUG] Engine suggested illegal move: \(pv[0])")
                }
            }
        }
    }
    
    // MARK: - Engine vs Engine Loop
    func startEngineVsEngine() async {
        guard let engine = engine else { return }
        
        while !gameOverManager.gameOver {
            let currentFEN = FenSerialization.default.serialize(position: chessboardModel.game.position)
            await engine.send(command: .stop)
            await engine.send(command: .position(.fen(currentFEN)))
            await engine.send(command: .go(depth: 10))
            
            guard let responseStream = await engine.responseStream else { break }
            
            var moveMade = false
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
                        }
                        print("[DEBUG] Engine played: \(pv[0])")
                        moveMade = true
                        break
                    }
                }
            }
            
            if !moveMade {
                print("[DEBUG] No legal move found, stopping engine vs engine")
                break
            }
            
            // Small delay to visualize moves
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1s
        }
    }
}

#Preview {
    BotVsBotView()
}
