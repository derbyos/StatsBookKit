//
//  File.swift
//  
//
//  Created by gandreas on 8/31/23.
//

import Foundation

/// Since boolean values are stored in different ways in the statsbook, provide a format
/// description of the various options (for example, it may be "X" for true and blank or "" for false, or
/// it may be "YES" or "NO" (or "YES | NO" for undefined).  Note that this is primarily
/// used for setting the field.  For getting, we support a wide variety of things for true
public struct BooleanFormat {
    /// The value to store when setting to `true`
    var trueValue: Value
    /// The value to store when setting to `false`
    var falseValue: Value
    /// The value to store when setting to `nil`
    var undefinedValue: Value
}

extension BooleanFormat {
    /// the "X" is true format
    static let xIsTrue = BooleanFormat(trueValue: "X", falseValue: .undefined, undefinedValue: .undefined)
    
    /// explicit YES | NO
    static let yesBarNo = BooleanFormat(trueValue: "YES", falseValue: "NO", undefinedValue: "YES | NO")
    
    /// NO or YES
    static let defaultToNo = BooleanFormat(trueValue: "YES", falseValue: "NO", undefinedValue: "NO")
    
    /// YES or NO, with blank default
    static let yesOrNo = BooleanFormat(trueValue: "YES", falseValue: "NO", undefinedValue: .undefined)
}
