//
//  ToolbarView.swift
//  VoiceChess
//
//  Created by Chris Marquez on 9/21/25.
//

import SwiftUI

struct ToolbarView: View {
    let startListening: () -> Void
    let stopListening: () -> Void
    let resetBoard: () -> Void
    let flipBoard: () -> Void
    
    var body: some View {
        HStack(spacing: 40) {
            Button(action: startListening) {
                Image(systemName: "mic.fill")
                    .resizable()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.green)
            }
            
            Button(action: stopListening) {
                Image(systemName: "stop.fill")
                    .resizable()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.red)
            }
            
            Button(action: resetBoard) {
                Image(systemName: "arrow.clockwise")
                    .resizable()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.blue)
            }
            
            Button(action: flipBoard) {
                Image(systemName: "arrow.2.circlepath")
                    .resizable()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .padding(.bottom, 30)
    }
}
