//
//  File.swift
//  
//
//  Created by gandreas on 8/22/23.
//

import Foundation

/// Errors that can be thrown by various routines
public enum Errors : Error {
    /// The version string isn't what we expect
    case unsupportedStatsBookVersion(String)
    /// The XML parsing had a bad day
    case addingChildToNonParentXML
    /// The XML parsing has a very bad day
    case invalidXML
    /// The xls file doesn't have the toplevel workbook.xml
    case missingWorkbook
    /// Unable to load the version from the readme sheet
    case unableToFindVersion
    /// No relative file table
    case missingRels
    /// No relative sheet ID
    case undefinedSheetRelID(String)
    /// No sheet with the given name
    case undefinedSheetNamed(String)
}
