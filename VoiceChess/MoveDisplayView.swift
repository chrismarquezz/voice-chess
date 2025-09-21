//
//  MoveDisplayView.swift
//  VoiceChess
//
//  Created by Chris Marquez on 9/21/25.
//

import SwiftUI

struct MoveDisplayView: View {
    let moveText: String?
    
    var body: some View {
        Text("Move: \(moveText ?? "")")
            .font(.headline)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(8)
            .padding(.horizontal, 20)
    }
}
