//
//  File.swift
//  
//
//  Created by gandreas on 8/24/23.
//

import Foundation


/// A wrapper around the comment XML
public struct Comment {
    var xml: XML
    var sheet: Sheet
    init(xml: XML, sheet: Sheet) {
        self.xml = xml
        self.sheet = sheet
    }
    
    /// The name of the author
    public var author: String? {
        sheet.comment(author: xml["authorId"])
    }
    
    /// The shape ID of the comment (we don't actually use this yet)
    public var shapeID: String? {
        sheet.comment(author: xml["shapeId"])
    }
    
    /// The body of the comment, as plain text
    public var commentText: String {
        xml.asString
    }
}
