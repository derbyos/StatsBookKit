//
//  File.swift
//  
//
//  Created by gandreas on 8/25/23.
//

import Foundation

/// For any wrapper around a sheet, we provide a way to do a dynamic lookup
/// of various things
@dynamicMemberLookup
protocol DynamicSheetPage {
    var sheet: Sheet { get }
    subscript(dynamicMember member: String) -> String? { get set }
    /// A map of member names to cell addresses for textual cells
    static var stringFields: [String: Address] { get }

    subscript(dynamicMember member: String) -> Double? { get set }
    /// A map of member names to cell address for numeric cells
    static var numberFields: [String: Address] { get }

    /// If this is a subsection that is actually offset within the page (allowing for
    /// home vs away, for example)
    var cellOffset: (dr: Int, dc: Int) { get }
}

// default implementations of the various parts of the field
extension DynamicSheetPage {
    var cellOffset: (dr: Int, dc: Int) { (dr:0, dc: 0) }
    subscript(dynamicMember member: String) -> String? {
        get {
            if let address = Self.stringFields[member] {
                let cell = sheet[address.offset(by: cellOffset)]
                return try? cell?.eval()?.asString
            } else {
                return nil
            }
        }
        set {
            if let address = Self.stringFields[member] {
                if let newValue {
                    sheet.cachedValues[address.offset(by: cellOffset)] = .string(newValue)
                } else {
                    sheet.cachedValues[address.offset(by: cellOffset)] = .undefined
                }
            }
        }
    }
    
    subscript(dynamicMember member: String) -> Double? {
        get {
            if let address = Self.numberFields[member] {
                let cell = sheet[address]
                return try? cell?.eval()?.asNumber
            } else {
                return nil
            }
        }
        set {
            if let address = Self.numberFields[member] {
                if let newValue {
                    sheet.cachedValues[address] = .number(newValue)
                } else {
                    sheet.cachedValues[address] = .undefined
                }
            }
        }
    }
}
