//
//  GameOverManager.swift
//  VoiceChess
//
//  Created by Chris Marquez on 9/21/25.
//

import SwiftUI

class GameOverManager: ObservableObject {
    @Published var gameOver: Bool = false
    @Published var gameResult: String = ""
    
    func endGame(with result: String) {
        gameResult = result
        gameOver = true
    }
}
