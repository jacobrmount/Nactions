// DataManagement/Entities/Property+Extensions.swift
import Foundation
import CoreData

// Declare the class under our namespace to avoid conflicts
extension CoreData {
    // Typealias to the generated class for cleaner code
    public typealias PropertyEntity = NactionsKit.PropertyEntity
}

// Extend the class using the namespace
extension CoreData.PropertyEntity {
    // Helper methods for property type operations
    
    // Get property value as a string (for title, rich_text, etc.)
    public var stringValue: String? {
        guard let data = propertyData else { return nil }
        
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            
            switch type {
            case "title", "rich_text":
                guard let richTextArray = jsonObject as? [[String: Any]] else { return nil }
                
                // Extract and concatenate text content from rich_text array
                let textContents = richTextArray.compactMap { textObj -> String? in
                    guard let text = textObj["text"] as? [String: Any],
                          let content = text["content"] as? String else { return nil }
                    return content
                }
                
                return textContents.joined()
                
            case "checkbox":
                return (jsonObject as? Bool)?.description
                
            case "number":
                return (jsonObject as? NSNumber)?.stringValue
                
            case "select":
                guard let selectObj = jsonObject as? [String: Any],
                      let name = selectObj["name"] as? String else { return nil }
                return name
                
            case "date":
                guard let dateObj = jsonObject as? [String: Any],
                      let start = dateObj["start"] as? String else { return nil }
                return start
                
            default:
                return nil
            }
        } catch {
            print("Error parsing property data: \(error)")
            return nil
        }
    }
    
    // Get property value as a boolean (for checkbox)
    public var boolValue: Bool? {
        guard type == "checkbox", let data = propertyData else { return nil }
        
        do {
            return try JSONSerialization.jsonObject(with: data) as? Bool
        } catch {
            print("Error parsing checkbox property: \(error)")
            return nil
        }
    }
    
    // Get property value as a number
    public var numberValue: Double? {
        guard type == "number", let data = propertyData else { return nil }
        
        do {
            return try JSONSerialization.jsonObject(with: data) as? Double
        } catch {
            print("Error parsing number property: \(error)")
            return nil
        }
    }
    
    // Get property value as a date
    public var dateValue: Date? {
        guard type == "date", let data = propertyData else { return nil }
        
        do {
            guard let dateObj = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let dateString = dateObj["start"] as? String else { return nil }
            
            // Parse ISO 8601 date string
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            return formatter.date(from: dateString)
        } catch {
            print("Error parsing date property: \(error)")
            return nil
        }
    }
    
    // Set property data from string value (for title, rich_text)
    public func setStringValue(_ value: String) {
        switch type {
        case "title", "rich_text":
            // Create a rich_text array with one text object
            let richText: [[String: Any]] = [
                [
                    "type": "text",
                    "text": [
                        "content": value,
                        "link": nil
                    ],
                    "annotations": [
                        "bold": false,
                        "italic": false,
                        "strikethrough": false,
                        "underline": false,
                        "code": false,
                        "color": "default"
                    ],
                    "plain_text": value
                ]
            ]
            
            do {
                self.propertyData = try JSONSerialization.data(withJSONObject: richText)
            } catch {
                print("Error serializing rich text: \(error)")
            }
            
        case "select":
            // Create a select object
            let select: [String: String] = ["name": value]
            
            do {
                self.propertyData = try JSONSerialization.data(withJSONObject: select)
            } catch {
                print("Error serializing select: \(error)")
            }
            
        case "date":
            // Create a date object
            let date: [String: String] = ["start": value]
            
            do {
                self.propertyData = try JSONSerialization.data(withJSONObject: date)
            } catch {
                print("Error serializing date: \(error)")
            }
            
        default:
            print("Cannot set string value for property type: \(type)")
        }
    }
    
    // Set property data from boolean value (for checkbox)
    public func setBoolValue(_ value: Bool) {
        guard type == "checkbox" else {
            print("Cannot set bool value for property type: \(type)")
            return
        }
        
        do {
            self.propertyData = try JSONSerialization.data(withJSONObject: value)
        } catch {
            print("Error serializing checkbox: \(error)")
        }
    }
    
    // Set property data from number value
    public func setNumberValue(_ value: Double) {
        guard type == "number" else {
            print("Cannot set number value for property type: \(type)")
            return
        }
        
        do {
            self.propertyData = try JSONSerialization.data(withJSONObject: value)
        } catch {
            print("Error serializing number: \(error)")
        }
    }
    
    // Set property data from date value
    public func setDateValue(_ date: Date) {
        guard type == "date" else {
            print("Cannot set date value for property type: \(type)")
            return
        }
        
        // Format date as ISO 8601 string
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let dateString = formatter.string(from: date)
        
        // Create date object
        let dateObject: [String: String] = ["start": dateString]
        
        do {
            self.propertyData = try JSONSerialization.data(withJSONObject: dateObject)
        } catch {
            print("Error serializing date: \(error)")
        }
    }
    
    // Creates a new Property managed object
    public static func create(name: String, type: String, for page: CoreData.PageEntity, in context: NSManagedObjectContext) -> CoreData.PropertyEntity {
        let property = PropertyEntity(context: context)
        property.id = UUID().uuidString // Generate a unique local ID
        property.name = name
        property.type = type
        property.page = page
        return property
    }
}
