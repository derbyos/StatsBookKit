//
//  File.swift
//  
//
//  Created by gandreas on 8/23/23.
//

import Foundation


struct Styles {
    var xml: XML
    
    /// The format code for the number format by ID
    let numberFormats:[String: String]
    let fonts:[XML]
    let fills:[XML]
    let borders:[XML]
    let cellStyleXfs:[XML]
    let cellXfs: [XML]
    let cellStyles: [XML]
    let dxfs: [XML]
    let indexColors: [XML]
    let mruColors: [XML]
    
    struct XF {
        init(xml: XML, styles: Styles) {
            if let parent = xml["xfId"], let parentId = Int(parent), let style = styles.cellStyleFormat(parentId) {
                self = style
            }
            if let numberFormatID = xml["numFmtId"] {
                numberFormat = styles.numberFormats[numberFormatID]
            }
            if let idString = xml["fontID"], let idValue = Int(idString), idValue >= 0 && idValue < styles.fonts.count {
                font = styles.fonts[idValue]
            }
            if let idString = xml["fillID"], let idValue = Int(idString), idValue >= 0 && idValue < styles.fills.count {
                font = styles.fills[idValue]
            }
            if let idString = xml["borderID"], let idValue = Int(idString), idValue >= 0 && idValue < styles.borders.count {
                font = styles.borders[idValue]
            }

            if xml["applyNumberFormat"] == "0" {
                applyNumberFormat = false
            }
            if xml["applyFill"] == "0" {
                applyFill = false
            }
            if xml["applyBorder"] == "0" {
                applyBorder = false
            }
            if xml["applyProtection"] == "0" {
                applyProtection = false
            }
            if xml["applyAlignment"] == "0" {
                applyAlignment = false
            }
        }
        var numberFormat: String?
        var font: XML?
        var fill: XML?
        var border: XML?
        var applyNumberFormat: Bool = true
        var applyFill: Bool = true
        var applyBorder: Bool = true
        var applyProtection: Bool = true
        var applyAlignment: Bool = true
    }
    func cellStyleFormat(_ index: Int) -> XF? {
        guard index >= 0 && index < cellStyleXfs.count else {
            return nil
        }
        return XF(xml: cellStyleXfs[index], styles: self)
    }
    func cellFormat(_ index: Int) -> XF? {
        guard index >= 0 && index < cellXfs.count else {
            return nil
        }
        return XF(xml: cellXfs[index], styles: self)
        
    }
    init(xml: XML) {
        self.xml = xml
        // Excel defines built-in format ID 14: "m/d/yyyy"; 22: "m/d/yyyy h:mm"; 37: "#,##0_);(#,##0)"; 38: "#,##0_);[Red](#,##0)"; 39: "#,##0.00_);(#,##0.00)"; 40: "#,##0.00_);[Red](#,##0.00)"; 47: "mm:ss.0"; KOR fmt 55: "yyyy/mm/dd".
        var numberFormats = [
            "14": "m/d/yyyy", "22": "m/d/yyyy h:mm", "37": "#,##0_);(#,##0)", "38": "#,##0_);[Red](#,##0)", "39": "#,##0.00_);(#,##0.00)", "40": "#,##0.00_);[Red](#,##0.00)", "47": "mm:ss.0", "55": "yyyy/mm/dd"
        ]
        for format in xml.firstChild(named: "numFmts")?.allChildren(named: "numFmt") ?? [] {
            if let id = format["numFmtId"] {
                numberFormats[id] = format["formatCode"]
            }
        }
        self.numberFormats = numberFormats
        fonts = xml.firstChild(named: "fonts")?.allChildren(named: "font") ?? []
        fills = xml.firstChild(named: "fills")?.allChildren(named: "fill") ?? []
        borders = xml.firstChild(named: "borders")?.allChildren(named: "border") ?? []
        cellStyleXfs = xml.firstChild(named: "cellStyleXfs")?.allChildren(named: "xf") ?? []
        cellXfs = xml.firstChild(named: "cellXfs")?.allChildren(named: "xf") ?? []
        cellStyles = xml.firstChild(named: "cellStyles")?.allChildren(named: "cellStyle") ?? []
        dxfs = xml.firstChild(named: "dxfs")?.allChildren(named: "dxf") ?? []
        indexColors = xml.firstChild(named: "colors")?.firstChild(named: "indexedColors")?.allChildren(named: "rgbColor") ?? []
        mruColors = xml.firstChild(named: "colors")?.firstChild(named: "mruColors")?.allChildren(named: "color") ?? []
    }
}


extension Cell {
    var styleFormat: Styles.XF? {
        if let sid = xml["s"].flatMap({Int($0)}) {
            return sheet.file.styles.cellFormat(sid)
        }
        return nil
    }
}
