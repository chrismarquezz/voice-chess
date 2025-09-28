//
//  MoveHandler.swift
//  VoiceChess
//
//  Created by Chris Marquez on 9/21/25.
//

import ChessKit
import ChessboardKit
import AVFoundation

struct MoveHandler {

    // Keep track of repeated positions
    static var positionCounts: [String: Int] = [:]

    static func handleMove(
        move: Move,
        moveText: String,
        chessboardModel: inout ChessboardModel,
        moveHistory: inout [String],
        gameOverManager: GameOverManager,
        speechSynthesizer: AVSpeechSynthesizer
    ) {
        moveHistory.append(moveText)
        chessboardModel.game.make(move: move)
        let newFen = FenSerialization.default.serialize(position: chessboardModel.game.position)
        chessboardModel.setFen(newFen)
        
        // Update threefold repetition counts
        if DrawHelper.isThreefoldRepetition(fen: newFen, positionCounts: &positionCounts) {
            let result = "Draw by threefold repetition!"
            speak(result, synthesizer: speechSynthesizer)
            gameOverManager.endGame(with: result)
            return
        }

        speak(moveText, synthesizer: speechSynthesizer)
        
        checkGameEnd(
            chessboardModel: chessboardModel,
            gameOverManager: gameOverManager,
            synthesizer: speechSynthesizer
        )
    }

    static func checkGameEnd(
        chessboardModel: ChessboardModel,
        gameOverManager: GameOverManager,
        synthesizer: AVSpeechSynthesizer
    ) {
        let game = chessboardModel.game
        let board = game.position.board
        
        if game.isMate {
            let result = "Checkmate!"
            speak(result, synthesizer: synthesizer)
            gameOverManager.endGame(with: result)
        } else if game.isCheck {
            speak("Check!", synthesizer: synthesizer)
        } else if game.legalMoves.isEmpty {
            let result = "Stalemate!"
            speak(result, synthesizer: synthesizer)
            gameOverManager.endGame(with: result)
        } else if game.position.counter.halfMoves >= 100 {
            let result = "Draw by 50-move rule!"
            speak(result, synthesizer: synthesizer)
            gameOverManager.endGame(with: result)
        } else if DrawHelper.isInsufficientMaterial(board: board) {
            let result = "Draw by insufficient material!"
            speak(result, synthesizer: synthesizer)
            gameOverManager.endGame(with: result)
        }
    }

    static func speak(_ text: String, synthesizer: AVSpeechSynthesizer) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        synthesizer.speak(utterance)
    }
}
