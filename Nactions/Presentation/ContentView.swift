// Nactions/Presentation/ContentView.swift

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            TokenView()
                .tabItem {
                    Label("Tokens", systemImage: "person.badge.key.fill")
                }
            
            WidgetConfigView()
                .tabItem {
                    Label("Widgets", systemImage: "rectangle.grid.2x2")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .onAppear {
            // Verify app group access on launch
            let groupAccessSuccessful = AppGroupConfig.verifyAppGroupAccess()
            if !groupAccessSuccessful {
                print("Failed to access app group - widgets may not work correctly")
            }
        }
    }
}
