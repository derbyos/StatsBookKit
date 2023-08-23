//
//  File.swift
//  
//
//  Created by gandreas on 8/22/23.
//

import Foundation


/// An address in a cell (row/column)
struct Address : Equatable, Hashable {
    /// The row number
    var row: Int
    /// the column letter
    var column: String

    /// Convert column letters to indices (only support single and double letter column names).  Zero based, so column "A" is 0
    var columnNumber: Int {
        var retval = 0
        var first = true
        for letter in column {
            if first {
                first = false
            } else { // convert "A" (0) to 26
                retval = (retval + 1) * 26
            }
            guard let v = letter.asciiValue, v >= Character("A").asciiValue! && v <= Character("Z").asciiValue! else {
                continue
            }
            retval += Int(v) - Int(Character("A").asciiValue!)
        }
        return retval
    }
    /// Convert column indices to letters (only support single and double letter column names)
    static func columnName(_ number: Int) -> String {
        if number < 26 {
            return String(Character(Unicode.Scalar(UInt8(number) + Character("A").asciiValue!)))
        } else {
            return columnName(number / 26 - 1) + columnName(number % 26)
        }
    }
    func adding(row delta: Int) -> Address {
        .init(row: row + delta, column: column)
    }
    func adding(column delta: Int) -> Address {
        .init(row: row, column: Address.columnName(columnNumber + delta))
    }
}
