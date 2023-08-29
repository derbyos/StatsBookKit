//
//  File.swift
//  
//
//  Created by gandreas on 8/22/23.
//

import Foundation

import gandZip

public class StatsBookFile {
    public struct Options : OptionSet {
        public var rawValue: Int
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        public static let useInlineStr = Options(rawValue: 1 << 0)
        
        public static let `default` : Options = []
    }
    /// The file versions we support
    public enum Version : String {
        case January2019 = "January 2019 Release"
    }
    /// What version this is.  Note that this is only set during init
    public private(set) var version: Version
    
    /// Various options
    public var options: Options = .default
    
    /// The xml of the workbook
    let workbookXML : XML

    /// The xml of the styles document
    let stylesXML : XML
    
    lazy var styles: Styles = {
        Styles(xml: stylesXML)
    }()

    /// The worksheet rels
    var worksheetRels : [String: String] = [:]
    
    /// Shared strings
    var sharedStrings : [XML] = []
    
    /// Have we edited the shared strings?
    var sharedStringsDirty : Bool = false
    
    /// The zip reader that contains this file
    var zipFile: ZipReader
    
    /// The unmodified data in the zip file (mostly for debugging purpose)
    public var originalData: Data { zipFile.originalData }
    
    /// Save all the changes as a new zip file data
    public func save() throws -> Data {
        for sheet in cachedSheets {
            let xml = sheet.value.save()
            // convert back to XML
            let newData = xml.description
            // where to save it?
            let relPath = try relativePath(forSheet: sheet.key)
            // add it
            try zipFile.replace(newData.data(using: .utf8)!, for: "xl/" + relPath)
        }
        if sharedStringsDirty {
            let newData = sharedStringsData()
            // hard code where this goes
            try zipFile.replace(newData, for: "xl/sharedStrings.xml")
        }
        return zipFile.save()
    }
    /// Open an existing (or blank) statsbook
    /// - Parameter url: The URL
    public convenience init(_ url: URL) throws {
        try self.init(Data(contentsOf: url))
    }
    /// Open an existing (or blank) statsbook as data
    /// - Parameter data: The data of the file
    public init(_ data: Data) throws {
        zipFile = ZipReader(data: data)
        let workbookData = try zipFile.data(for: "xl/workbook.xml")
        guard let wbxml = try XML(workbookData).firstChild(named: "workbook") else {
            throw Errors.missingWorkbook
        }
        workbookXML = wbxml

        let stylesData = try zipFile.data(for: "xl/styles.xml")
        guard let styleXML = try XML(stylesData).firstChild(named: "styleSheet") else {
            throw Errors.missingWorkbook
        }
        self.stylesXML = styleXML

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
    
    /// Find if the string is in the shared strings, if so return the index
    /// - Parameter sharedString: The string to search for
    /// - Returns: The index, if found
    /// - Note: if useInlineStr is false, we will automatically add an item for that string to shared strings and mark it as dirty
    public func lookup(sharedString: String) -> Int? {
        let existing = sharedStrings.firstIndex { $0.asString == sharedString }
        if options.contains(.useInlineStr) {
            return existing
        }
        // make a new version
        sharedStringsDirty = true
        // this will be the index
        let retval = sharedStrings.count
        sharedStrings.append(XML.element("si", namespace: nil, qName: nil, attributes: [:], children: [.element("t", namespace: nil, qName: nil, attributes: [:], children: [.characters(sharedString)])]))
        return retval
    }
    
    // Convert the (updated) shared strings to XML to data
    func sharedStringsData() -> Data {
        let xml = XML.document([
            .element("sst", namespace: nil, qName: nil, attributes: [
                "xmlns": "http://schemas.openxmlformats.org/spreadsheetml/2006/main",
                "count": "\(sharedStrings.count)",
                "uniqueCount": "\(Set<String>(sharedStrings.map{$0.asString}).count)" // not exactly correct if formatting within the element is different
            ], children: sharedStrings)
        ])
        return xml.description.data(using: .utf8)!
    }
    
    /// A cache of all the sheets we've loaded
    var cachedSheets: [String : Sheet] = [:]
    /// Load a sheet by name, using the cached version if needed
    func sheet(named: String) throws -> Sheet {
        if let cached = cachedSheets[named] {
            return cached
        }
        let relPath = try relativePath(forSheet: named)
        let data = try zipFile.data(for: "xl/" + relPath)
        let xml = try XML(data)
        let relsData = try zipFile.data(for: "xl/worksheets/_rels/" + relPath.split(separator: "/").last! + ".rels")
        let relXML = try XML(relsData)
        let retval = Sheet(file: self, name: named, xml, rels: relXML)
        cachedSheets[named] = retval
        return retval
    }
    
    /// Get the relative pathname for the sheet (such that it would be found inside "xl/"
    /// - Parameter sheet: The sheet name
    /// - Returns: <#description#>
    func relativePath(forSheet named: String) throws -> String {
        let wb = workbook
        guard let sheet = wb.sheet(name: named), let sheetRID = sheet.rId, let relPath = worksheetRels[sheetRID] else {
            throw Errors.undefinedSheetNamed(named)
        }
        return relPath
    }
}
