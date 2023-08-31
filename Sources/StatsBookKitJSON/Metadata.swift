//
//  File.swift
//  
//
//  Created by gandreas on 8/26/23.
//

import Foundation


public struct Metadata : Codable {
    /// The version from the Read Me sheet
    var version: String
    /// Does this file contain commented values
    var hasComments: Bool
    
    public func encode(to encoder: Encoder) throws {
        // If the option for removing comments is set, make sure written data supports that
        var container = encoder.container(keyedBy: Self.CodingKeys)
        if encoder.userInfo[RemoveCommentsKey] != nil {
            try container.encode(false, forKey: .hasComments)
        } else {
            try container.encode(hasComments, forKey: .hasComments)
        }
        try container.encode(version, forKey: .version)
    }
}
