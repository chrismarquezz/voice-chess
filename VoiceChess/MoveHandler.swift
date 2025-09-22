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
    
    // Handles moves made via chessboard drag/tap
    static func handleMove(move: Move,
                           moveText: String,
                           chessboardModel: inout ChessboardModel,
                           moveHistory: inout [String],
                           gameOver: inout Bool,
                           speechSynthesizer: AVSpeechSynthesizer) {
        
        moveHistory.append(moveText)
        chessboardModel.game.make(move: move)
        let newFen = FenSerialization.default.serialize(position: chessboardModel.game.position)
        chessboardModel.setFen(newFen)
        
        speak(moveText, synthesizer: speechSynthesizer)
        
        checkGameEnd(chessboardModel: &chessboardModel,
                     gameOver: &gameOver,
                     speechSynthesizer: speechSynthesizer)
    }
    
    // Announces check, checkmate, stalemate, 50-move draw, or insufficient material
    static func checkGameEnd(chessboardModel: inout ChessboardModel,
                             gameOver: inout Bool,
                             speechSynthesizer: AVSpeechSynthesizer) {
        
        let game = chessboardModel.game
        let board = game.position.board
        
        if game.isMate {
            speak("Checkmate!", synthesizer: speechSynthesizer)
            gameOver = true
        } else if game.isCheck {
            speak("Check!", synthesizer: speechSynthesizer)
        } else if game.legalMoves.isEmpty {
            speak("Stalemate!", synthesizer: speechSynthesizer)
            gameOver = true
        } else if game.position.counter.halfMoves >= 100 {
            speak("Draw by fifty-move rule!", synthesizer: speechSynthesizer)
            gameOver = true
        } else if DrawHelper.isInsufficientMaterial(board: board) {
            speak("Draw by insufficient material!", synthesizer: speechSynthesizer)
            gameOver = true
        }
    }
    
    static func speak(_ text: String, synthesizer: AVSpeechSynthesizer) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        synthesizer.speak(utterance)
    }
}
