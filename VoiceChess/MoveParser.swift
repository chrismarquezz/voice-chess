//
//  MoveParser.swift
//  VoiceChess
//
//  Created by Chris Marquez on 9/17/25.
//

import Foundation
import ChessKit

/// Parses human-readable chess moves into `Move` objects for ChessKit
struct MoveParser {
    
    let game: Game
    
    /// Convert a string command into a `Move` object
    /// Example inputs: "Knight to f3", "e2 to e4"
    func parse(_ command: String) -> Move? {
        let lowercased = command.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Simple regex to detect moves like "e2 to e4"
        let pattern = #"([a-h][1-8])\s*(to|-)\s*([a-h][1-8])"#
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: lowercased, range: NSRange(lowercased.startIndex..., in: lowercased)) {
            
            let fromRange = Range(match.range(at: 1), in: lowercased)!
            let toRange = Range(match.range(at: 3), in: lowercased)!
            
            let fromSquare = String(lowercased[fromRange])
            let toSquare   = String(lowercased[toRange])
            
            let from = Square(coordinate: fromSquare)
            let to   = Square(coordinate: toSquare)

            // Get all legal moves from the current position
            let legalMoves = game.legalMoves
            
            // Find the matching move
            return legalMoves.first { $0.from == from && $0.to == to }
        }
        
        // TODO: Extend for piece names like "Knight to f3"
        
        return nil
    }
}
