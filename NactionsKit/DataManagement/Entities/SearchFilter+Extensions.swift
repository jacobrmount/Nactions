// DataManagement/Entities/SearchFilter+Extensions.swift
import Foundation
import CoreData

extension SearchFilterEntity {
    /// Converts to NotionSearchFilter for API operations
    func toNotionSearchFilter() -> NotionSearchFilter {
        let filter = NotionSearchFilter()
        filter.property = self.property ?? ""
        filter.value = self.value ?? ""
        filter.type = self.type
        return filter
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

/// Add convenience helper for NotionSearchFilter
extension NotionSearchFilter {
    // This creates a static factory method instead of a designated initializer
    public static func create(property: String, value: String, type: String? = nil) -> NotionSearchFilter {
        let filter = NotionSearchFilter()
        filter.property = property
        filter.value = value
        filter.type = type
        return filter
    }
}
