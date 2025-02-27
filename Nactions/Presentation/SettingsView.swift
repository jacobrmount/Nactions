// Nactions/Presentation/SettingsView.swift
import SwiftUI
import UIKit

struct SettingsView: View {
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Backup / Restore")) {
                    Button("Export Tokens") {
                        exportTokens()
                    }
                    Button("Import Tokens") {
                        importTokens()
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
    
    // MARK: - Export
    
    private func exportTokens() {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = scene.windows.first?.rootViewController else {
            return
        }
        TokenBackupManager.exportTokens(presentingViewController: rootVC)
    }
    
    // MARK: - Import
    
    private func importTokens() {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = scene.windows.first?.rootViewController else {
            return
        }
        TokenBackupManager.importTokens(presentingViewController: rootVC) { success in
            if success {
                print("✅ Import succeeded.")
            } else {
                print("❌ Import failed.")
            }
        }
    }
}
