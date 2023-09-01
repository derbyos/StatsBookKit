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
        return rowXML.allChildren(named: "c").first(where: {$0["r"] == colRow}).map({.init(sheet: self, address: Address(row: row, column: col), xml: $0)})
    }
    
    subscript(address: Address) -> Cell? {
        cell(row: address.row, col: address.column)
    }
    subscript(row row: Int, col col: String) -> Cell? {
        cell(row: row, col: col)
    }
    
    /// The current values for all cells, either from calculation or from
    /// explicit setting.  Note that a cell with a value that hasn't changed
    /// (and isn't a calculation) won't be here
    var cachedValues: [Address: Value] = [:]
    
    /// The current cached values for comments, allowing us to change comments
    var cachedComments: [Address: Comment] = [:]
    
    /// Reset to sheet to its original values
    func reset() {
        cachedValues = [:]
        cachedComments = [:]
    }
    
    
    /// Recalculate the sheet
    /// - Parameter reset: Should the sheet be reset first?
    func recalc(reset: Bool = false) throws {
        if reset {
            self.reset()
        }
        for row in xml.firstChild(named: "worksheet")?.firstChild(named: "sheetData")?.allChildren(named: "row") ?? [] {
            for cellXML in row.allChildren(named: "c") {
                guard let addr = Address(cellXML["r"]) else {
                    continue
                }
                let cell = Cell(sheet: self, address: addr, xml: cellXML)
                if let formula = cell.formula {
                    cachedValues[addr] = try formula.eval()
                } else {
                    assert(cell.formulaSource == nil)
                }
            }
        }
    }
    
    /// Find the bottom right cell with content - note that it may not have content
    /// but a rectangle from A1 to this cell will include all the content
    var bottomRight : Address {
        var retval = Address(row: 1, column: "A")
        for row in xml.firstChild(named: "rows")?.allChildren(named: "row") ?? [] {
            for cellXML in row.allChildren(named: "c") {
                guard let addr = Address(cellXML["r"]) else {
                    continue
                }
                let cell = Cell(sheet: self, address: addr, xml: cellXML)
                if cell.value != nil {
                    if addr.row > retval.row {
                        retval.row = addr.row
                    }
                    if addr.columnNumber > retval.columnNumber {
                        retval.columnNumber = addr.columnNumber
                    }
                }
            }
        }
        return retval
    }
    /// The shared formulas for this sheet
    var sharedFormulas: [String: (Address,String)] = [:]
    /// Lookup the shared formula (unlocalized)
    /// - Parameter formula: The formula index
    /// - Returns: The base address of the formula, and the formula text
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
    
    
    /// Lookup the comments for a given cell by address
    /// - Parameter addr: The cell address
    /// - Returns: The XML of that comment
    func comment(for addr: Address) -> XML? {
        comments?.firstChild(named: "comments")?.firstChild(named: "commentList")?.firstChild(where: {$0["ref"] == addr.description})
    }
    
    /// Fetch the author of a comment based on the author ID
    /// - Parameter author: The ID as a string
    /// - Returns: The author if found
    func comment(author: String?) -> String? {
        guard let author, let index = Int(author) else {
            return nil
        }
        guard let authors = comments?.firstChild(named: "authors")?.allChildren(named: "author") else {
            return nil
        }
        if index >= 0 && index < authors.count {
            return authors[index].asString
        }
        return nil
    }
    
    /// Given the current values saved in this sheet, weave that into the XML for the sheet
    /// - Returns: The new XML with updated values
    func save() -> XML {
        xml.walkAndUpdate { xml in
            switch xml {
            case .element(let name, namespace: let namespace, qName: let qname, attributes: let attributes, children: let children):
                if name == "c" {
                    guard let addr = Address(attributes["r"]) else {
                        return nil // keep going
                    }
                    guard let newValue = cachedValues[addr] else {
                        return nil // unchanged
                    }
                    let cell = Cell(sheet: self, address: addr, xml: xml)
                    let oldValue = cell.value
                    if newValue == oldValue {
                        return nil // unchanged
                    }
                    // we need to update with the new value, but we also need to keep the formula
                    var newAttr = attributes
                    var newV: XML?
                    var newType: String?
                    switch newValue {
                    case .bool(let b):
                        newType = "b"
                        newV = .element("v", namespace: nil, qName: nil, attributes: [:], children: [.characters(b ? "1" : "0")])
                    case .number(let n):
                        newType = "n"
                        newV = .element("v", namespace: nil, qName: nil, attributes: [:], children: [.characters("\(n)")])
                    case .string(let s):
                        if s == "" {
                            // empty string, remove the value
                            newType = nil
                            newV = nil
                        } else if let shared = file.lookup(sharedString: s) {
                            newType = "s"
                            newV = .element("v", namespace: nil, qName: nil, attributes: [:], children: [.characters("\(shared)")])
                        } else {
                            // OpenOffice doesn't like inlineStr, so if
                            // the file options are set lookup will return a
                            // new value and not hit here
                            newType = "inlineStr" // don't mess with shared strings yet
                            newV = .element("v", namespace: nil, qName: nil, attributes: [:], children: [.element("t", namespace: nil, qName: nil, attributes: [:], children: [.characters(s)])])
                        }
                    case .undefined:
                        // remove the contents
                        newType = nil
                        newV = nil
                    }
                    // now replace the V element
                    let vIndex = children.firstIndex { xml in
                        if case .element("v", _, _, _, _) = xml {
                            return false
                        }
                        return true
                    }
                    var newChildren = children
                    if let vIndex {
                        if let newV {
                            newChildren[vIndex] = newV
                        } else {
                            // delete it
                            newChildren.remove(at: vIndex)
                        }
                    } else if let newV { // add a child for the new V
                        newChildren.append(newV)
                    }
                    // and update the type (note that formula don't change)
                    if cell.formulaSource == nil {
                        newAttr["t"] = newType
                    }
                    return .element(name, namespace: namespace, qName: qname, attributes: newAttr, children: newChildren)
                } else {
                    return nil
                }
            default:
                return nil
            }
        }
    }
}

