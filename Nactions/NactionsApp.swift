// Nactions/NactionsApp.swift
import SwiftUI
import NactionsKit

@main
struct NactionsApp: App {
    // Initialize Core Data stack
    let coreDataStack = CoreDataStack.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, coreDataStack.viewContext)
        }
    }
}
