//
//  SettingsView.swift
//  VoiceChess
//
//  Created by Chris Marquez on 9/30/25.
//

import SwiftUI

struct SettingsView: View {
    @State private var soundEnabled = true
    @State private var darkMode = false
    
    var body: some View {
        NavigationView {
            Form {
                Toggle("Enable Sound", isOn: $soundEnabled)
                Toggle("Dark Mode", isOn: $darkMode)
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}
