//
//  File.swift
//  
//
//  Created by gandreas on 8/22/23.
//

import Foundation

/// Cell is a lightweight wrapper around the xml for a cell in a sheet
struct Cell {
    var sheet: Sheet
    var xml: XML
    init(sheet: Sheet, xml: XML) {
        self.sheet = sheet
        self.xml = xml
    }
    
    /// The current string value of a cell (either a constant, or the curent value of a calculated cell)
    var stringValue: String? {
        switch xml["t"] {
        case "s": // shared string
            guard let sharedID = xml.firstChild(named: "v")?.asInt else {
                return nil
            }
            return sheet.file[sharedString: sharedID]
        case "str": // a calculated cell which is formatted as a string
            // just get the current value
            return xml.firstChild(named: "v")?.asString
        default:
            return nil
        }
    }

    var intValue: Int? {
        switch xml["t"] {
        case "s": // shared string
            guard let sharedID = xml.firstChild(named: "v")?.asInt else {
                return nil
            }
            return sheet.file[sharedString: sharedID].flatMap({Int($0)})
        case "str": // a calculated cell which is formatted as a string
            // just get the current value
            return xml.firstChild(named: "v").flatMap({Int($0.asString)})
        default:
            return nil
        }
    }

    var formula: Formula? {
        guard let f = xml.firstChild(named: "f") else {
            return nil
        }
        if f["t"] == "shared", let si = f["si"] {
            // shared
            if let sharedFormula = sheet.shared(formula: si) {
                // TODO: Convert to relative formula
                guard let f = try? Formula(source:sharedFormula.1, sheet: sheet) else {
                    return nil
                }
                if let here = Address(xml["r"]) {
                    let delta = sharedFormula.0.delta(to: here)
                    return f.offset(by: delta)
                }
            }
        }
        return try? Formula(source: f.asString, sheet: sheet)
    }
    
    var comment: String? {
        sheet.comments?.firstChild(named: "comments")?.firstChild(named: "commentList")?.firstChild(where: {$0["ref"] == xml["r"]})?.asString
    }
}

@propertyWrapper
public struct StringCell {
    public var wrappedValue: String? {
        get {
            sheet[row: row, col: col]?.stringValue
        }
    }
    public var comment: String? {
        sheet[row: row, col: col]?.comment
    }
    var sheet: Sheet!
    var row: Int
    var col: String
    public init(sheet: Sheet!, row: Int, col: String) {
        self.sheet = sheet
        self.row = row
        self.col = col
    }
}

@propertyWrapper
public struct IntCell {
    public var wrappedValue: Int? {
        get {
            sheet[row: row, col: col]?.intValue
        }
    }
    public var comment: String? {
        sheet[row: row, col: col]?.comment
    }
    var sheet: Sheet!
    var row: Int
    var col: String
    public init(sheet: Sheet! = nil, row: Int, col: String) {
        self.sheet = sheet
        self.row = row
        self.col = col
    }
}
