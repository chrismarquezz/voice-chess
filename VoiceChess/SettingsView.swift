//
//  SettingsView.swift
//  VoiceChess
//
//  Created by Chris Marquez on 9/30/25.
//

import SwiftUI

struct SettingsView: View {
    
    var body: some View {
        NavigationView {
            Form {
                NavigationLink(destination: ChangeThemeView()) {
                    Text("Change Theme")
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}
