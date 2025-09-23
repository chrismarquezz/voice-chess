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
    /// Example inputs: "Knight f3", "Bishop c4", "e4", "castle kingside", "Bishop takes c4"
    func parse(_ command: String) -> Move? {
        // Normalize command
        var lowercased = command.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Replace homophones
        let homophones: [String: String] = [
            "night": "knight",
            "nite": "knight",
            "nice": "knight",
            "nine": "knight",
            "brooke": "rook",
            "brook": "rook",
            "book": "rook",
        ]
        for (wrong, correct) in homophones {
            lowercased = lowercased.replacingOccurrences(of: wrong, with: correct)
        }
        
        let words = lowercased.components(separatedBy: " ")
        
        // --- Handle castling ---
        if lowercased == "castle kingside" || lowercased == "castle short" || lowercased == "castle shortside" {
            return game.legalMoves.first { move in
                let from = move.from
                let to = move.to
                guard let piece = game.position.board[from] else { return false }
                return piece.kind == .king &&
                       ((from.coordinate == "e1" && to.coordinate == "g1") ||
                        (from.coordinate == "e8" && to.coordinate == "g8"))
            }
        }
        if lowercased == "castle queenside" || lowercased == "castle longside" || lowercased == "castle long" {
            return game.legalMoves.first { move in
                let from = move.from
                let to = move.to
                guard let piece = game.position.board[from] else { return false }
                return piece.kind == .king &&
                       ((from.coordinate == "e1" && to.coordinate == "c1") ||
                        (from.coordinate == "e8" && to.coordinate == "c8"))
            }
        }
        
        // --- Handle piece moves ---
        if words.count >= 2, let pieceKind = pieceKind(from: words[0]) {
            let wantsCapture = words.contains("takes")
            let toSquare = Square(coordinate: words.last!)
            
            let candidates = game.legalMoves.filter { move in
                guard let fromPiece = game.position.board[move.from] else { return false }
                guard fromPiece.kind == pieceKind else { return false }
                
                let isCapture = game.position.board[move.to] != nil
                
                // Enforce "takes" only for capturing moves
                if isCapture && !wantsCapture {
                    return false
                }
                if !isCapture && wantsCapture {
                    return false
                }
                
                return move.to == toSquare
            }
            
            return candidates.first
        }

        
        // --- Handle pawn moves (with promotion support) ---
        let promotionMap: [String: PieceKind] = [
            "queen": .queen,
            "rook": .rook,
            "bishop": .bishop,
            "knight": .knight
        ]

        // Case 1: simple pawn move like "e4"
        if words.count == 1 {
            let toSquare = Square(coordinate: words[0])
            let candidates = game.legalMoves.filter { move in
                move.to == toSquare && game.position.board[move.from]?.kind == .pawn
            }
            return candidates.first
        }

        // Case 2: promotion like "e8 queen"
        if words.count == 2, let promotionPiece = promotionMap[words[1]] {
            let toSquare = Square(coordinate: words[0])
            let candidates = game.legalMoves.filter { move in
                move.to == toSquare &&
                game.position.board[move.from]?.kind == .pawn &&
                move.promotion == promotionPiece
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
