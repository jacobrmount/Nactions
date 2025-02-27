// Nactions/Presentation/TokenView.swift
import SwiftUI
import LocalAuthentication

struct TokenView: View {
    @ObservedObject var tokenManager = TokenService.shared
    @State private var showingAddToken = false
    @State private var tokenToEdit: NotionToken?
    @State private var tokenToDelete: NotionToken?
    @State private var showingDeleteConfirmation = false
    @State private var authenticated = false

    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    List {
                        ForEach(tokenManager.tokens, id: \.id) { token in
                            HStack {
                                Circle()
                                    .fill(token.isConnected ? Color.green : Color.red)
                                    .frame(width: 12, height: 12)
                                
                                Button(action: {
                                    tokenToEdit = token
                                    showingAddToken = true
                                }) {
                                    Text(token.name)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(8)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Button(action: {
                                    tokenToDelete = token
                                    showingDeleteConfirmation = true
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                        .padding()
                                }
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
                
                // Floating Add Token Button (Bottom Right)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            tokenToEdit = nil
                            showingAddToken = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.blue)
                                .shadow(radius: 5)
                        }
                        .padding(.trailing, 25)
                        .padding(.bottom, 25)
                    }
                }
            }
            .navigationTitle("Tokens")
            .sheet(isPresented: $showingAddToken) {
                AddTokenView(tokenToEdit: $tokenToEdit, isPresented: $showingAddToken)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .alert(isPresented: $showingDeleteConfirmation) {
                Alert(
                    title: Text("Delete Token"),
                    message: Text("This action cannot be undone. Are you sure?"),
                    primaryButton: .destructive(Text("Delete")) {
                        if let token = tokenToDelete {
                            tokenManager.deleteToken(token)
                        }
                        tokenToDelete = nil
                    },
                    secondaryButton: .cancel {
                        tokenToDelete = nil
                    }
                )
            }
            .onAppear {
                // Attempt biometric authentication on appear.
                if !authenticated {
                    authenticateUser()
                }
            }
        }
    }
    
    private func authenticateUser() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Authenticate to access tokens") { success, authError in
                DispatchQueue.main.async {
                    if success {
                        self.authenticated = true
                    } else {
                        // Handle authentication error
                        print("Authentication failed: \(authError?.localizedDescription ?? "Unknown error")")
                    }
                }
            }
        } else {
            // No biometrics available
            print("Biometric authentication not available: \(error?.localizedDescription ?? "Unknown error")")
            // Fallback to password or PIN authentication if needed
            self.authenticated = true // For now, just authenticate anyway
        }
    }
}
