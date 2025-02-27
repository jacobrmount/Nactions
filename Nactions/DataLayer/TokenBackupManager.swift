// DataLayer/TokenBackupManager.swift
import SwiftUI
import UniformTypeIdentifiers

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

final class TokenBackupManager {
    
    // MARK: - Export Tokens
    
    static func exportTokens(completion: @escaping (Bool) -> Void) {
        // Fetch tokens from Core Data
        let tokens = TokenDataController.shared.fetchTokens()
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        do {
            let jsonData = try encoder.encode(tokens)
            // Write JSON data to a temporary file
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("NotionTokens.json")
            try jsonData.write(to: tempURL)
            
            #if os(iOS)
            // iOS implementation using UIKit
            exportTokensIOS(from: tempURL, completion: completion)
            #elseif os(macOS)
            // macOS implementation using AppKit
            exportTokensMacOS(from: tempURL, completion: completion)
            #endif
        } catch {
            print("Error exporting tokens: \(error.localizedDescription)")
            completion(false)
        }
    }
    
    // MARK: - Import Tokens
    
    static func importTokens(completion: @escaping (Bool) -> Void) {
        #if os(iOS)
        importTokensIOS(completion: completion)
        #elseif os(macOS)
        importTokensMacOS(completion: completion)
        #endif
    }
    
    // MARK: - iOS Implementations
    
    #if os(iOS)
    private static func exportTokensIOS(from fileURL: URL, completion: @escaping (Bool) -> Void) {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = scene.windows.first?.rootViewController else {
            completion(false)
            return
        }
        
        let documentPicker = UIDocumentPickerViewController(forExporting: [fileURL])
        
        // Use a delegate to handle completion
        let delegate = DocumentPickerDelegate()
        delegate.completionHandler = { _ in
            // Since export doesn't return the URL, we'll assume success if the delegate is called
            completion(true)
        }
        documentPicker.delegate = delegate
        
        // Keep a reference to the delegate
        objc_setAssociatedObject(documentPicker, &AssociatedObjectHandle, delegate, .OBJC_ASSOCIATION_RETAIN)
        
        rootVC.present(documentPicker, animated: true)
    }
    
    private static func importTokensIOS(completion: @escaping (Bool) -> Void) {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = scene.windows.first?.rootViewController else {
            completion(false)
            return
        }
        
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.json])
        
        let delegate = DocumentPickerDelegate()
        delegate.completionHandler = { url in
            guard let url = url else {
                print("No file selected.")
                completion(false)
                return
            }
            
            processImportedFile(at: url, completion: completion)
        }
        documentPicker.delegate = delegate
        
        // Keep a reference to the delegate
        objc_setAssociatedObject(documentPicker, &AssociatedObjectHandle, delegate, .OBJC_ASSOCIATION_RETAIN)
        
        rootVC.present(documentPicker, animated: true)
    }
    
    // Document picker delegate for iOS
    private class DocumentPickerDelegate: NSObject, UIDocumentPickerDelegate {
        var completionHandler: ((URL?) -> Void)?
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            completionHandler?(urls.first)
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            completionHandler?(nil)
        }
    }
    #endif
    
    // MARK: - macOS Implementations
    
    #if os(macOS)
    private static func exportTokensMacOS(from fileURL: URL, completion: @escaping (Bool) -> Void) {
        let savePanel = NSSavePanel()
        savePanel.canCreateDirectories = true
        savePanel.showsTagField = false
        savePanel.nameFieldStringValue = "NotionTokens.json"
        savePanel.allowedContentTypes = [UTType.json]
        
        savePanel.beginSheetModal(for: NSApp.keyWindow!) { response in
            if response == .OK, let targetURL = savePanel.url {
                do {
                    let data = try Data(contentsOf: fileURL)
                    try data.write(to: targetURL)
                    completion(true)
                } catch {
                    print("Error saving file: \(error.localizedDescription)")
                    completion(false)
                }
            } else {
                completion(false)
            }
        }
    }
    
    private static func importTokensMacOS(completion: @escaping (Bool) -> Void) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.allowedContentTypes = [UTType.json]
        
        openPanel.beginSheetModal(for: NSApp.keyWindow!) { response in
            if response == .OK, let url = openPanel.url {
                processImportedFile(at: url, completion: completion)
            } else {
                completion(false)
            }
        }
    }
    #endif
    
    // MARK: - Shared Implementation
    
    private static func processImportedFile(at url: URL, completion: @escaping (Bool) -> Void) {
        // Start security-scoped access (needed on both platforms)
        guard url.startAccessingSecurityScopedResource() else {
            print("Could not access security scoped resource.")
            completion(false)
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        do {
            let jsonData = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let importedTokens = try decoder.decode([NotionToken].self, from: jsonData)
            
            print("Decoded tokens: \(importedTokens)")
            
            for token in importedTokens {
                print("Importing token named: \(token.name)")
                TokenDataController.shared.saveToken(name: token.name, apiToken: token.apiToken)
            }
            completion(true)
        } catch {
            print("Error importing tokens: \(error.localizedDescription)")
            completion(false)
        }
    }
}

// Required to maintain a reference to delegates in iOS
private var AssociatedObjectHandle: UInt8 = 0
