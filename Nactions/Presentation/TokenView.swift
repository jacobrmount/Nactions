// Nactions/Presentation/TokenView.swift
import SwiftUI
import LocalAuthentication

#if os(macOS)
import AppKit
#endif

struct TokenView: View {
    @ObservedObject var tokenManager = TokenService.shared
    @State private var showingAddToken = false
    @State private var tokenToEdit: NotionToken?
    @State private var tokenToDelete: NotionToken?
    @State private var showingDeleteConfirmation = false

    var body: some View {
        #if os(iOS)
        // iOS maintains NavigationView and floating button design
        NavigationView {
            tokenListContent
                .navigationTitle("Tokens")
                .sheet(isPresented: $showingAddToken) {
                    AddTokenView(tokenToEdit: $tokenToEdit, isPresented: $showingAddToken)
                        .presentationDetents([.medium, .large])
                        .presentationDragIndicator(.visible)
                }
        }
        #else
        // macOS version (fits into tab-based UI)
        tokenListContent
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
            .sheet(isPresented: $showingAddToken) {
                AddTokenView(tokenToEdit: $tokenToEdit, isPresented: $showingAddToken)
                    .frame(width: 400, height: 300)
            }
        #endif
    }
    
    private var tokenListContent: some View {
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
                                    #if os(iOS)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(8)
                                    #else
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    #endif
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
                #if os(iOS)
                .listStyle(PlainListStyle())
                #else
                .listStyle(InsetListStyle())
                #endif
            }
            
            // Add Token Button (different style per platform)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        tokenToEdit = nil
                        showingAddToken = true
                    }) {
                        #if os(iOS)
                        // iOS floating button style
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                            .shadow(radius: 5)
                            .padding(.trailing, 25)
                            .padding(.bottom, 25)
                        #else
                        // macOS button style
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Color.blue)
                            .clipShape(Circle())
                            .padding(.trailing, 16)
                            .padding(.bottom, 16)
                        #endif
                    }
                }
            }
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
    }
}
