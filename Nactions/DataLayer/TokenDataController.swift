// NactionsKit/DataLayer/TokenDataController.swift
import Foundation
import CoreData

final class TokenDataController {
    static let shared = TokenDataController()
    
    // **MARK: - Fetch Tokens**
    func fetchTokens() -> [NotionToken] {
        let context = CoreDataStack.shared.viewContext
        let request: NSFetchRequest<Token> = Token.fetchRequest()
        do {
            let tokenEntities = try context.fetch(request)
            return tokenEntities.map { $0.toNotionToken() }
        } catch {
            print("Error fetching tokens: \(error)")
            return []
        }
    }
    
    // **MARK: - Save New Token**
    func saveToken(name: String, apiToken: String) {
        CoreDataStack.shared.performBackgroundTask { backgroundContext in
            let newToken = Token(context: backgroundContext)
            newToken.name = name
            newToken.apiToken = apiToken
            newToken.connectionStatus = false
            
            do {
                try backgroundContext.save()
                print("✅ Saved token named: \(name)")
            } catch {
                print("❌ Error saving token: \(error.localizedDescription)")
            }
        }
    }
    
    // **MARK: - Update Existing Token**
    func updateToken(updatedToken: NotionToken) {
        CoreDataStack.shared.performBackgroundTask { backgroundContext in
            let request: NSFetchRequest<Token> = Token.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", updatedToken.id as CVarArg)
            
            do {
                if let tokenEntity = try backgroundContext.fetch(request).first {
                    tokenEntity.name = updatedToken.name
                    tokenEntity.apiToken = updatedToken.apiToken
                    tokenEntity.connectionStatus = updatedToken.isConnected
                    // lastUpdatedDate is automatically updated in willSave()
                    try backgroundContext.save()
                    print("Token updated successfully.")
                } else {
                    print("Token with id \(updatedToken.id) not found for update.")
                }
            } catch {
                print("Error updating token: \(error)")
            }
        }
    }
    
    // **MARK: - Delete Token**
    func deleteToken(tokenToDelete: NotionToken) {
        CoreDataStack.shared.performBackgroundTask { backgroundContext in
            let request: NSFetchRequest<Token> = Token.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", tokenToDelete.id as CVarArg)
            
            do {
                if let tokenEntity = try backgroundContext.fetch(request).first {
                    backgroundContext.delete(tokenEntity)
                    try backgroundContext.save()
                    print("Token deleted successfully.")
                } else {
                    print("Token with id \(tokenToDelete.id) not found for deletion.")
                }
            } catch {
                print("Error deleting token: \(error)")
            }
        }
    }
}
