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

    var formula: String? {
        return xml.firstChild(named: "f")?.asString
    }
    
    var comment: String? {
        sheet.comments?.firstChild(named: "comments")?.firstChild(named: "commentList")?.firstChild(where: {$0["ref"] == xml["r"]})?.asString
    }
}
