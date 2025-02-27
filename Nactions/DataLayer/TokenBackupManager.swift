// NactionsKit/DataLayer/TokenBackupManager.swift
import UIKit
import UniformTypeIdentifiers

final class TokenBackupManager {
    
    /// Exports tokens by encoding them as JSON and presenting a UIDocumentPicker to let the user choose a destination.
    static func exportTokens(presentingViewController: UIViewController) {
        // Fetch tokens from Core Data as an array of NotionToken (Codable)
        let tokens = TokenDataController.shared.fetchTokens()
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        do {
            let jsonData = try encoder.encode(tokens)
            // Write JSON data to a temporary file
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("NotionTokens.json")
            try jsonData.write(to: tempURL)
            
            // Create and present a document picker for exporting the file.
            let documentPicker = UIDocumentPickerViewController(forExporting: [tempURL])
            presentingViewController.present(documentPicker, animated: true, completion: nil)
        } catch {
            print("Error exporting tokens: \(error.localizedDescription)")
        }
    }
    
    /// Presents a document picker to import tokens from a JSON file.
    /// When a file is chosen, it decodes the tokens and adds/updates them in Core Data.
    static func importTokens(presentingViewController: UIViewController, completion: @escaping (Bool) -> Void) {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.json])
        documentPicker.delegate = DocumentPickerDelegate.shared
        DocumentPickerDelegate.shared.completionHandler = { url in
            guard let url = url else {
                print("❌ No file selected.")
                completion(false)
                return
            }
            
            // Start security-scoped access
            guard url.startAccessingSecurityScopedResource() else {
                print("❌ Could not access security scoped resource.")
                completion(false)
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }
            
            do {
                let jsonData = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                let importedTokens = try decoder.decode([NotionToken].self, from: jsonData)
                
                print("ℹ️ Decoded tokens: \(importedTokens)")
                
                for token in importedTokens {
                    print("ℹ️ Importing token named: \(token.name)")
                    TokenDataController.shared.saveToken(name: token.name, apiToken: token.apiToken)
                }
                completion(true)
            } catch {
                print("❌ Error importing tokens: \(error.localizedDescription)")
                completion(false)
            }
        }
        presentingViewController.present(documentPicker, animated: true, completion: nil)
    }
}

// MARK: - Document Picker Delegate

final class DocumentPickerDelegate: NSObject, UIDocumentPickerDelegate {
    static let shared = DocumentPickerDelegate()
    var completionHandler: ((URL?) -> Void)?
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        completionHandler?(urls.first)
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        completionHandler?(nil)
    }
}
