//
//  File.swift
//  
//
//  Created by gandreas on 8/22/23.
//

import Foundation
public struct SheetReference {
    var xml: XML
    init(_ xml: XML) {
        self.xml = xml
    }
    
    public var sheetId: String? { xml["sheetId"] }
    public var rId: String? { xml["r:id"] }
}


/// Something that reprsent a sheet in the workbook.  It is a class since it
/// is shared by any dynamic creation (such as cells)
public class Sheet {
    weak var file: StatsBookFile!
    var name: String
    var xml: XML
    var rels: XML
    /// Create the sheet
    /// - Parameters:
    ///   - file: The xls file
    ///   - xml: The xml of the sheet
    init(file: StatsBookFile, name: String, _ xml: XML, rels: XML) {
        self.file = file
        self.name = name
        self.xml = xml
        self.rels = rels
    }
    
    lazy var comments: XML? = {
        guard let path = rels.firstChild(named: "Relationships")?.firstChild(where: {
            $0["Type"] == "http://schemas.openxmlformats.org/officeDocument/2006/relationships/comments"
        })?["Target"] else {
            return nil
        }
        // we are assuming that the "current directory" is xl/worksheets
        // so this would be xl/targetname.xml
        let resolvedPath: String
        if path.hasPrefix("../") {
            resolvedPath = "xl/" + path.dropFirst(3)
        } else {
            resolvedPath = path
        }
        return try? file.xml(for: resolvedPath)
    }()
    
    /// Get a given cell XML for a specified row & column
    /// - Parameters:
    ///   - row: The row number (1 = first row)
    ///   - col: The column name ("A", etc...)
    /// - Returns: The cell data for that row/column
    func cell(row: Int, col: String) -> Cell? {
        let rowString = "\(row)"
        guard let rowXML = xml.firstChild(named: "worksheet")?.firstChild(named: "sheetData")?.allChildren(named: "row").first(where: {$0["r"] == rowString}) else {
            return nil
        }
        let colRow = "\(col)\(rowString)"
        return rowXML.allChildren(named: "c").first(where: {$0["r"] == colRow}).map({.init(sheet: self, xml: $0)})
    }
    
    subscript(address: Address) -> Cell? {
        cell(row: address.row, col: address.column)
    }
    subscript(row row: Int, col col: String) -> Cell? {
        cell(row: row, col: col)
    }
    
    var cachedValues: [Address: Formula.Value] = [:]
    
    var sharedFormulas: [String: (Address,String)] = [:]
    func shared(formula: String) -> (Address,String)? {
        if sharedFormulas.isEmpty {
            // build the table
            for row in xml.firstChild(named: "worksheet")?.firstChild(named: "sheetData")?.allChildren(named: "row") ?? [] {
                for cell in row.allChildren(named: "c") {
                    if let f = cell.firstChild(named: "f"), let addr = Address(cell["r"]) {
                        if f["t"] == "shared", let si = f["si"] {
                            let formula = f.asString
                            if formula.isEmpty == false {
                                sharedFormulas[si] = (addr,formula)
                            }
                        }
                    }
                }
            }
        }
        return sharedFormulas[formula]
    }
}

