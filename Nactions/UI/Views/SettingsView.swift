import SwiftUI

struct SettingsView: View {
    @State private var tokenName: String = ""
    @State private var notionToken: String = ""
    @State private var tokens: [NotionToken] = UserDefaultsManager.shared.getTokens()
    @State private var selectedTokenID: UUID? = nil
    @State private var showEditAlert = false
    @State private var editedApiKey: String = ""
    @State private var verificationResults: [UUID: Bool] = [:] // Stores verification results

    var body: some View {
        VStack {
            Text("Notion Integration").font(.title2)

            // Input Fields
            TextField("Token Name", text: $tokenName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            TextField("Enter Notion API Token", text: $notionToken)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button("Save & Verify Token") {
                UserDefaultsManager.shared.saveToken(name: tokenName, apiKey: notionToken)
                tokens = UserDefaultsManager.shared.getTokens() // Refresh list
                Task {
                    if let newToken = tokens.last {
                        let isValid = await NotionAPI.shared.verifyToken(newToken.apiKey)
                        verificationResults[newToken.id] = isValid
                    }
                }
                tokenName = ""
                notionToken = ""
            }
            .buttonStyle(.borderedProminent)
            .padding()

            Divider().padding()

            // List of Saved Tokens
            List {
                ForEach(tokens) { token in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(token.name)
                                .font(.headline)
                            Text(token.apiKey)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }

                        Spacer()

                        // Show verification result ✅ or ❌
                        if let isValid = verificationResults[token.id] {
                            Image(systemName: isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(isValid ? .green : .red)
                        }

                        // Manual Token Verification Button
                        Button("Verify Token") {
                            Task {
                                let isValid = await NotionAPI.shared.verifyToken(token.apiKey)
                                verificationResults[token.id] = isValid
                            }
                        }
                        .buttonStyle(.bordered)

                        // Delete Button
                        Button(action: {
                            UserDefaultsManager.shared.deleteToken(id: token.id)
                            tokens = UserDefaultsManager.shared.getTokens() // Refresh after delete
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                    .contextMenu { // Right-click menu (macOS) or long-press (iOS)
                        Button("Edit API Token") {
                            selectedTokenID = token.id
                            editedApiKey = token.apiKey
                            showEditAlert = true
                        }
                    }
                }
            }
            .padding()
        }
        .onAppear {
            tokens = UserDefaultsManager.shared.getTokens() // Load stored tokens
        }
        .alert("Edit API Token", isPresented: $showEditAlert) {
            TextField("New API Token", text: $editedApiKey)
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                if let id = selectedTokenID {
                    UserDefaultsManager.shared.updateToken(id: id, newApiKey: editedApiKey)
                    tokens = UserDefaultsManager.shared.getTokens() // Refresh list
                }
            }
        }
        .padding()
    }
}
