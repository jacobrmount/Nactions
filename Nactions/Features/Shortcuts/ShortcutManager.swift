import Foundation
import AppIntents

class ShortcutManager {
    static let shared = ShortcutManager()

    func registerShortcuts() {
        let provider = ShortcutProvider()
        let shortcuts = ShortcutProvider.appShortcuts

        // Apple does not require explicit "registration" for AppShortcuts.
        // They become available when implemented correctly.
        print("Registered Shortcuts: \(shortcuts)")
    }
}
