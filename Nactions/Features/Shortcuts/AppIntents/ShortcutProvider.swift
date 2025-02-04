import AppIntents

struct ShortcutProvider: AppShortcutsProvider {
    @AppShortcutsBuilder
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CreatePageIntent(),
            phrases: ["Create Notion Page"],
            shortTitle: "Create Page",
            systemImageName: "doc.badge.plus"
        )
    }
}
