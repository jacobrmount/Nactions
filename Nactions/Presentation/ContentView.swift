// Nactions/Presentation/ContentView.swift

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            TokenView()
                .tabItem {
                    Label("Tokens", systemImage: "person.badge.key.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
    }
}
