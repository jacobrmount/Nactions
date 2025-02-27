// DataManagement/Entities/WidgetConfiguration+Extensions.swift
import Foundation
import CoreData

// Declare the class under our namespace to avoid conflicts
extension CoreData {
    // Typealias to the generated class for cleaner code
    public typealias WidgetConfigurationEntity = NactionsKit.WidgetConfigurationEntity
}

// Extend the class using the namespace
extension CoreData.WidgetConfigurationEntity {
    // Lifecycle methods
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        self.id = UUID()
        self.lastUpdated = Date()
    }
    
    // Serialization methods for widget configuration
    
    /// Serializes a configuration dictionary to Data for storage
    public func setConfiguration(_ config: [String: Any]) {
        do {
            let data = try PropertyListSerialization.data(
                fromPropertyList: config,
                format: .binary,
                options: 0
            )
            self.configData = data
        } catch {
            print("Error serializing widget configuration: \(error)")
        }
    }
    
    /// Deserializes stored Data to a configuration dictionary
    public func getConfiguration() -> [String: Any]? {
        guard let data = self.configData else { return nil }
        
        do {
            let config = try PropertyListSerialization.propertyList(
                from: data,
                options: [],
                format: nil
            ) as? [String: Any]
            return config
        } catch {
            print("Error deserializing widget configuration: \(error)")
            return nil
        }
    }
    
    /// Creates a new WidgetConfiguration object
    public static func create(name: String,
                             tokenID: UUID,
                             databaseID: String?,
                             widgetKind: String,
                             widgetFamily: String,
                             config: [String: Any],
                             in context: NSManagedObjectContext) -> CoreData.WidgetConfigurationEntity {
        let widget = WidgetConfigurationEntity(context: context)
        widget.name = name
        widget.tokenID = tokenID
        widget.databaseID = databaseID
        widget.widgetKind = widgetKind
        widget.widgetFamily = widgetFamily
        widget.setConfiguration(config)
        return widget
    }
}
