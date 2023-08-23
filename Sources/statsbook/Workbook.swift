//
//  File.swift
//  
//
//  Created by gandreas on 8/22/23.
//

import Foundation

public struct Workbook {
    var xml: XML
    init(_ xml: XML) {
        self.xml = xml
    }
    
    /// Find first sheet with this name
    /// - Parameter name: The name of the sheet
    /// - Returns: The sheet, if found
    public func sheet(name: String) -> SheetReference? {
        xml.firstChild(named: "sheets")?.allChildren(named: "sheet").first(where: {$0["name"] == name}).map{SheetReference($0)}
    }
}

extension Workbook : XMLFile {
    
}
