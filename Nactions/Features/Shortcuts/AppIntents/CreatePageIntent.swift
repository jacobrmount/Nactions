import AppIntents

struct CreatePageIntent: AppIntent {
    static var title: LocalizedStringResource = "Create Notion Page"
    
    @Parameter(title: "Title") var title: String
    @Parameter(title: "Parent Page ID") var parentID: String

    func perform() async throws -> some IntentResult {
        let notionAPI = NotionAPI.shared
        let success = await notionAPI.createPage(title: title, parentID: parentID)
        
        return success ? .result(dialog: "Page Created Successfully") : .result(dialog: "Failed to Create Page")
    }
}
