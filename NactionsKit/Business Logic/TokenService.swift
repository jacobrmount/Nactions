// BusinessLogic/TokenService.swift
import Foundation
import Combine
import CoreData
import WidgetKit

@MainActor
public final class TokenService: ObservableObject {
    static let shared = TokenService()
    
    // Published tokens array for SwiftUI live updates
    @Published var tokens: [NotionToken] = []
    // Track tokens that failed refresh for UI alerts or retry logic
    @Published var invalidTokens: [NotionToken] = []
    // Published activated tokens for database view
    @Published var activatedTokens: [NotionToken] = []
    
    var cancellables = Set<AnyCancellable>()
    
    init() {
        // Load initial tokens from Core Data
        tokens = TokenDataController.shared.fetchTokens()
        activatedTokens = TokenDataController.shared.fetchActivatedTokens()
        
        // Subscribe to Core Data changes in the main context.
        NotificationCenter.default.publisher(for: .NSManagedObjectContextObjectsDidChange, object: CoreDataStack.shared.viewContext)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.tokens = TokenDataController.shared.fetchTokens()
                self.activatedTokens = TokenDataController.shared.fetchActivatedTokens()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - CRUD Operations
    func saveToken(name: String, apiToken: String) {
        TokenDataController.shared.saveToken(name: name, apiToken: apiToken)
    }
    
    func updateTokenCredentials(for token: NotionToken, newApiToken: String) {
        var updatedToken = token
        updatedToken.apiToken = newApiToken
        updatedToken.isConnected = true
        TokenDataController.shared.updateToken(updatedToken: updatedToken)
    }
    
    // MARK: - Token Activation
    func toggleTokenActivation(token: NotionToken) {
        // Only allow activating connected tokens
        guard token.isConnected else { return }
        
        var updatedToken = token
        updatedToken.isActivated = !token.isActivated
        TokenDataController.shared.updateToken(updatedToken: updatedToken)
        
        // Force UI refresh and update activatedTokens
        self.objectWillChange.send()
        
        print("Token activation toggled for \(token.name): \(updatedToken.isActivated)")
        
        // Update the activatedTokens collection
        if updatedToken.isActivated {
            if !activatedTokens.contains(where: { $0.id == token.id }) {
                activatedTokens.append(updatedToken)
            }
        } else {
            activatedTokens.removeAll(where: { $0.id == token.id })
        }
        
        // Log the current state
        print("Current activated tokens: \(activatedTokens.map { $0.name })")
    }
    
    func deleteToken(_ token: NotionToken) {
        TokenDataController.shared.deleteToken(tokenToDelete: token)
    }
    
    // MARK: - Token Validation and Refresh
    
    /// Refresh all tokens - called by background refresh scheduler
    func refreshAllTokens() async {
        let currentTokens = tokens
        for token in currentTokens {
            await validateToken(token)
        }
    }
    
    func validateStoredTokens() async {
        for token in tokens {
            if !token.isConnected {
                await validateToken(token)
            }
        }
    }
    
    func validateToken(_ token: NotionToken) async {
        let notionClient = NotionAPIClient(token: token.apiToken)
        do {
            let botUser = try await notionClient.retrieveBotUser()
            print("✅ Token valid for \(token.name): \(botUser.name ?? "Unknown")")
            DispatchQueue.main.async {
                self.updateTokenStatus(for: token, isConnected: true)
            }
        } catch {
            print("❌ Token invalid for \(token.name): \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.updateTokenStatus(for: token, isConnected: false)
                
                // If token is invalid, ensure it's not activated
                if token.isActivated {
                    var updatedToken = token
                    updatedToken.isActivated = false
                    updatedToken.isConnected = false
                    TokenDataController.shared.updateToken(updatedToken: updatedToken)
                }
            }
        }
    }
    
    func updateTokenStatus(for token: NotionToken, isConnected: Bool) {
        if let index = tokens.firstIndex(where: { $0.id == token.id }) {
            var updatedToken = tokens[index]
            updatedToken.isConnected = isConnected
            
            // If token is no longer connected, deactivate it
            if !isConnected && updatedToken.isActivated {
                updatedToken.isActivated = false
            }
            
            tokens[index] = updatedToken
            
            // Trigger an immediate UI update.
            self.objectWillChange.send()
            // Also update in Core Data.
            TokenDataController.shared.updateToken(updatedToken: updatedToken)
            
            // Update activatedTokens if needed
            self.activatedTokens = TokenDataController.shared.fetchActivatedTokens()
        }
    }
    
    // MARK: - Widget Support
    
    // Update the widget data whenever tokens change
    func updateWidgetData() {
        WidgetDataManager.shared.shareTokensWithWidgets()
        WidgetCenter.shared.reloadAllTimelines()
    }
}

#if DEBUG
extension TokenService {
    func makePreviewManager() -> TokenService {
        let previewManager = TokenService()
        previewManager.tokens = [
            NotionToken(id: UUID(), name: "Nactions", apiToken: "fake_token_1", isConnected: true, isActivated: true),
            NotionToken(id: UUID(), name: "Gmail", apiToken: "fake_token_2", isConnected: false, isActivated: false)
        ]
        previewManager.activatedTokens = [
            NotionToken(id: UUID(), name: "Nactions", apiToken: "fake_token_1", isConnected: true, isActivated: true)
        ]
        return previewManager
    }
}
#endif
