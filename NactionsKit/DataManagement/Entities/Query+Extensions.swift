// DataManagement/Entities/Query+Extensions.swift
import Foundation
import CoreData

// Declare the class under our namespace to avoid conflicts
extension CoreData {
    // Typealias to the generated class for cleaner code
    public typealias QueryEntity = NactionsKit.QueryEntity
}

// Extend the class using the namespace
extension CoreData.QueryEntity {
    public func toNotionQueryRequest() -> NotionQueryDatabaseRequest {
        // Convert stored filter data back to a query request
        var filterDict: [String: Any]? = nil
        
        if let filterData = self.filterData {
            filterDict = try? JSONSerialization.jsonObject(with: filterData) as? [String: Any]
        }
        
        // Create sorts array if we have a sort property
        var sorts: [NotionQuerySort]? = nil
        if let sortProperty = self.sortProperty, !sortProperty.isEmpty {
            sorts = [NotionQuerySort(property: sortProperty)]
        }
        
        return NotionQueryDatabaseRequest(
            sorts: sorts,
            filter: filterDict,
            pageSize: Int(self.pageSize),
            startCursor: self.startCursor
        )
    }
    
    public static func create(databaseID: String, request: NotionQueryDatabaseRequest, in context: NSManagedObjectContext) -> QueryEntity {
        let query = QueryEntity(context: context)
        query.id = UUID().uuidString
        query.databaseID = databaseID
        query.pageSize = Int16(request.pageSize ?? 100)
        query.startCursor = request.startCursor
        
        // Store sort property if available
        if let firstSort = request.sorts?.first {
            query.sortProperty = firstSort.property
        }
        
        // Serialize filter data if available
        if let filter = request.filter, !filter.isEmpty {
            do {
                let filterData = try JSONSerialization.data(withJSONObject: filter)
                query.filterData = filterData
            } catch {
                print("Error serializing filter data: \(error)")
            }
        }
        
        return query
    }
}
