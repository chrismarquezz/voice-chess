//
//  DrawHelper.swift
//  VoiceChess
//
//  Created by Chris Marquez on 9/21/25.
//

import ChessKit

struct DrawHelper {
    
    static func isInsufficientMaterial(board: Board) -> Bool {
        let pieces = board.enumeratedPieces().map { $0.1 }
        
        let nonKingPieces = pieces.filter { $0.kind != .king }
        if nonKingPieces.count > 1 { return false }
        if nonKingPieces.isEmpty { return true } // only kings
        
        if nonKingPieces.count == 1 {
            let kind = nonKingPieces[0].kind
            return kind == .bishop || kind == .knight
        }
        
        // Two bishops scenario
        if nonKingPieces.count == 2 {
            if nonKingPieces.allSatisfy({ $0.kind == .bishop }) {
                let bishopSquares = board.enumeratedPieces()
                    .filter { $0.1.kind == .bishop }
                    .map { $0.0 }
                let colors = bishopSquares.map { ($0.file + $0.rank) % 2 }
                if colors[0] != colors[1] { return true }
            }
        }
        
        return false
    }
}

