//
//  File.swift
//  
//
//  Created by gandreas on 8/22/23.
//

import Foundation

import gandZip

public class StatsBookFile {
    /// The file versions we support
    public enum Version {
        case January2019
    }
    /// What version this is.  Note that this is only set during init
    public private(set) var version: Version
    
    /// The xml of the workbook
    let workbookXML : XML
    
    /// The worksheet rels
    var worksheetRels : [String: String] = [:]
    
    /// Shared strings
    var sharedStrings : [XML] = []
    
    /// The zip reader that contains this file
    var zipFile: ZipReader
    
    /// Open an existing (or blank) statsbook
    /// - Parameter url: The URL
    init(_ url: URL) throws {
        zipFile = try ZipReader(data: Data(contentsOf: url))
        let workbookData = try zipFile.data(for: "xl/workbook.xml")
        guard let wbxml = try XML(workbookData).firstChild(named: "workbook") else {
            throw Errors.missingWorkbook
        }
        workbookXML = wbxml
        
        version = .January2019
        try buildWorksheetRL()
        try buildSharedStrings()
        
        let readMe = try sheet(named: "Read Me")
        guard let cell = readMe[row: 3,col: "A"] else {
            throw Errors.unableToFindVersion
        }
        
        if cell.stringValue != "January 2019 Release" {
            throw Errors.unsupportedStatsBookVersion(cell.stringValue ?? "")
        }
    }
    /// Find the XML from a document in the zip file
    func xml(for path: String) throws -> XML {
        let data = try zipFile.data(for: path)
        return try XML(data)
    }
    /// The current workbook XML document
    public var workbook: Workbook {
        .init(workbookXML)
    }
    
    /// Fetch the rels and save all of them
    func buildWorksheetRL() throws {
        let relXMLData = try zipFile.data(for: "xl/_rels/workbook.xml.rels")
        let relXML = try XML(relXMLData)
        for rel in relXML.firstChild(named: "Relationships")?.allChildren(named: "Relationship") ?? [] {
            guard let id = rel["Id"], let target = rel["Target"] else {
                throw Errors.missingRels
            }
            switch rel["Type"] {
            case "http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet":
                worksheetRels[id] = target
            case "http://schemas.openxmlformats.org/officeDocument/2006/relationships/calcChain":
                break
            case "http://schemas.openxmlformats.org/officeDocument/2006/relationships/sharedStrings":
                break
            case "http://schemas.openxmlformats.org/officeDocument/2006/relationships/customXml":
                break
            case "http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles":
                break
            case "http://schemas.openxmlformats.org/officeDocument/2006/relationships/theme":
                break
            default:
                break
            }
        }

    }
    
    /// Fetch the shared strings and save all of them
    func buildSharedStrings() throws {
        let sharedStringXMLData = try zipFile.data(for: "xl/sharedStrings.xml")
        let sharedStringXML = try XML(sharedStringXMLData)
        sharedStrings = sharedStringXML.firstChild(named: "sst")?.allChildren(named: "si") ?? []
    }
    
    public subscript(sharedString sharedID: Int) -> String? {
        guard sharedID >= 0 && sharedID < sharedStrings.count else {
            return nil
        }
        return sharedStrings[sharedID].asString
    }

    /// A cache of all the sheets we've loaded
    var cachedSheets: [String : Sheet] = [:]
    /// Load a sheet by name, using the cached version if needed
    func sheet(named: String) throws -> Sheet {
        if let cached = cachedSheets[named] {
            return cached
        }
        let wb = workbook
        guard let sheet = wb.sheet(name: named), let sheetRID = sheet.rId, let relPath = worksheetRels[sheetRID] else {
            throw Errors.undefinedSheetNamed(named)
        }
        let data = try zipFile.data(for: "xl/" + relPath)
        let xml = try XML(data)
        let relsData = try zipFile.data(for: "xl/worksheets/_rels/" + relPath.split(separator: "/").last! + ".rels")
        let relXML = try XML(relsData)
        let retval = Sheet(file: self, xml, rels: relXML)
        cachedSheets[named] = retval
        return retval
    }
}
