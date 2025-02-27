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
    
    var cancellables = Set<AnyCancellable>()
    
    init() {
        // Load initial tokens from Core Data
        tokens = TokenDataController.shared.fetchTokens()
        
        // Subscribe to Core Data changes in the main context.
        NotificationCenter.default.publisher(for: .NSManagedObjectContextObjectsDidChange, object: CoreDataStack.shared.viewContext)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.tokens = TokenDataController.shared.fetchTokens()
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
    
    func deleteToken(_ token: NotionToken) {
        TokenDataController.shared.deleteToken(tokenToDelete: token)
    }
    
    // MARK: - Background Token Refresh Example
    /// Refresh tokens in the background. This method is called from your background task scheduler.
    func refreshAllTokens() async {
        let currentTokens = tokens
        for token in currentTokens {
            if !token.isConnected {
                if let newTokenValue = await refreshToken(for: token) {
                    let refreshedToken = NotionToken(id: token.id, name: token.name, apiToken: newTokenValue, isConnected: true)
                    TokenDataController.shared.updateToken(updatedToken: refreshedToken)
                } else {
                    // Mark as invalid if refresh fails
                    if !invalidTokens.contains(where: { $0.id == token.id }) {
                        invalidTokens.append(token)
                    }
                }
            }
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
            }
        }
    }
    
    func updateTokenStatus(for token: NotionToken, isConnected: Bool) {
        if let index = tokens.firstIndex(where: { $0.id == token.id }) {
            tokens[index].isConnected = isConnected
            // Trigger an immediate UI update.
            self.objectWillChange.send()
            // Also update in Core Data.
            TokenDataController.shared.updateToken(updatedToken: tokens[index])
        }
    }
    
    /// Simulated token refresh function.
    func refreshToken(for token: NotionToken) async -> String? {
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        return token.apiToken + "_refreshed"
    }
    
    // MARK: - Widget Support
    
    // Update the widget data whenever tokens change
    func updateWidgetData() {
        WidgetDataManager.shared.shareTokensWithWidgets()
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    // Widget-aware CRUD operations
    
    // Override the original saveToken to update widgets after saving
    func saveTokenAndUpdateWidgets(name: String, apiToken: String) {
        saveToken(name: name, apiToken: apiToken)
        
        // Allow time for Core Data to save
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.updateWidgetData()
        }
    }
    
    // Override the original updateTokenCredentials to update widgets
    func updateTokenCredentialsAndWidgets(for token: NotionToken, newApiToken: String) {
        updateTokenCredentials(for: token, newApiToken: newApiToken)
        
        // Allow time for Core Data to save
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.updateWidgetData()
        }
    }
    
    // Override the original deleteToken to update widgets
    func deleteTokenAndUpdateWidgets(_ token: NotionToken) {
        deleteToken(token)
        
        // Allow time for Core Data to save
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.updateWidgetData()
        }
    }
    
    // Call this when tokens are validated
    func validateTokensAndUpdateWidgets() async {
        await validateStoredTokens()
        
        // Update widget data after validation
        DispatchQueue.main.async {
            self.updateWidgetData()
        }
    }
}

#if DEBUG
extension TokenService {
    func makePreviewManager() -> TokenService {
        let previewManager = TokenService()
        previewManager.tokens = [
            NotionToken(id: UUID(), name: "Nactions", apiToken: "fake_token_1", isConnected: true),
            NotionToken(id: UUID(), name: "Gmail", apiToken: "fake_token_2", isConnected: false)
        ]
        return previewManager
    }
}
#endif
