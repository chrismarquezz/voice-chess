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
    /// Example inputs: "Knight f3", "Bishop c4", "e4", "castle kingside"
    func parse(_ command: String) -> Move? {
        // Normalize command
        var lowercased = command.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Replace common homophones (don't map castling here — handled separately)
        let homophones: [String: String] = [
            "night": "knight",
            "nite": "knight",
        ]
        for (wrong, correct) in homophones {
            lowercased = lowercased.replacingOccurrences(of: wrong, with: correct)
        }
        
        let words = lowercased.components(separatedBy: " ")
        
        // --- Handle castling (find whichever castle move is currently legal) ---
        if lowercased == ("castle kingside") || lowercased == ("castle short") || lowercased == ("castle shortside"){
            // Kingside castling for both colors
                let kingsideCastleMove = game.legalMoves.first { move in
                    let from = move.from
                    let to = move.to
                    guard let piece = game.position.board[from] else { return false }
                    return piece.kind == .king &&
                           ((from.coordinate == "e1" && to.coordinate == "g1") ||
                            (from.coordinate == "e8" && to.coordinate == "g8"))
                }
                return kingsideCastleMove
            
        }
        if lowercased == ("castle queenside") || lowercased == ("castle longside") || lowercased == ("castle long") {
            let queensideCastleMove = game.legalMoves.first { move in
                    let from = move.from
                    let to = move.to
                    guard let piece = game.position.board[from] else { return false }
                    return piece.kind == .king &&
                           ((from.coordinate == "e1" && to.coordinate == "c1") ||
                            (from.coordinate == "e8" && to.coordinate == "c8"))
                }
                return queensideCastleMove
            }
        
        // --- Handle piece move (like "Knight f3") ---
        if words.count == 2, let pieceKind = pieceKind(from: words[0]) {
            let toSquare = Square(coordinate: words[1])
            
            // Filter legal moves going to the target square and matching piece kind
            let candidates = game.legalMoves.filter { move in
                move.to == toSquare && game.position.board[move.from]?.kind == pieceKind
            }
            
            return candidates.first
        }
        
        // --- Handle pawn move (like "e4") ---
        if words.count == 1 {
            let toSquare = Square(coordinate: words[0])
            
            // Pawns moving to the square
            let candidates = game.legalMoves.filter { move in
                move.to == toSquare && game.position.board[move.from]?.kind == .pawn
            }
            
            return candidates.first
        }
        
        return nil
    }
    
    /// Convert string to ChessKit.PieceKind
    private func pieceKind(from string: String) -> PieceKind? {
        switch string.lowercased() {
        case "knight": return .knight
        case "bishop": return .bishop
        case "rook":   return .rook
        case "queen":  return .queen
        case "king":   return .king
        default:       return nil
        }
    }
}
