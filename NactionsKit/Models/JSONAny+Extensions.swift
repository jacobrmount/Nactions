// NactionsKit/Models/JSONAny+Extensions.swift
import Foundation

extension JSONAny {
    // Get a safe dictionary from the JSONAny value
    func getValueDictionary() -> [String: Any]? {
        // First check if the value is already a dictionary
        if let dict = value as? [String: Any] {
            return dict
        }
        
        // Try to get a dictionary using alternative methods
        return nil
    }
    
    // Get a safe array from the JSONAny value
    func getArray() -> [Any]? {
        return value as? [Any]
    }
    
    // Helper to safely extract a double value
    func getNumberValue(fromKey key: String) -> Double? {
        guard let dict = getValueDictionary(),
              let number = dict[key] as? Double else {
            return nil
        }
        return number
    }
    
    // Helper to safely extract a dictionary
    func getNestedDictionary(fromKey key: String) -> [String: Any]? {
        guard let dict = getValueDictionary(),
              let nestedDict = dict[key] as? [String: Any] else {
            return nil
        }
        return nestedDict
    }
}
