// DataManagement/Entities/SearchFilter+Extensions.swift
import Foundation
import CoreData

extension SearchFilterEntity {
    /// Converts to NotionSearchFilter for API operations
    func toNotionSearchFilter() -> NotionSearchFilter {
        return NotionSearchFilter(
            property: self.property ?? "",
            value: self.value ?? "",
            type: self.type
        )
    }
    
    /// Creates a SearchFilterEntity from a NotionSearchFilter
    static func create(from filter: NotionSearchFilter, in context: NSManagedObjectContext) -> SearchFilterEntity {
        let entity = SearchFilterEntity(context: context)
        entity.id = UUID().uuidString
        entity.property = filter.property
        entity.value = filter.value
        entity.type = filter.type
        return entity
    }
}

/// Add dictionary conversion support for NotionSearchFilter
extension NotionSearchFilter {
    // Add convenience initializer
    public init(property: String, value: String, type: String? = nil) {
        self.init(from: try! JSONDecoder().decode(Decoder.self, from: JSONEncoder().encode([
            "property": property,
            "value": value,
            "type": type
        ])))
    }
}
