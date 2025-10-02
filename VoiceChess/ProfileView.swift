//
//  ProfileView.swift
//  VoiceChess
//
//  Created by Chris Marquez on 10/1/25.
//

import SwiftUI

struct ProfileView: View {
    @AppStorage("pieceStyle") private var selectedTheme: String = "pixel"
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Placeholder avatar / profile info
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 120, height: 120)
                    .overlay(Text("person.crop.circle").font(.system(size: 60)))
                
                Text("Username")
                    .font(.title)
                    .bold()
                
                Text("Level 1")
                Text("XP: 0")
                
                Divider()
                
                Text("Selected Theme: \(selectedTheme.capitalized)")
                
                Spacer()
            }
            .padding()
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                    }
                }
            }
        }
    }
}

#Preview {
    ProfileView()
}
