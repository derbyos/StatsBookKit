//
//  File.swift
//  
//
//  Created by gandreas on 8/22/23.
//

import Foundation


/// An address in a cell (row/column)
public struct Address : Equatable, Hashable, CustomStringConvertible {
    internal init(row: Int, anchorRow: Bool = false, column: String, anchorColumn: Bool = false) {
        self.row = row
        self.anchorRow = anchorRow
        self.column = column
        self.anchorColumn = anchorColumn
    }
    
    /// The row number
    var row: Int
    var anchorRow: Bool = false
    /// the column letter
    var column: String
    var anchorColumn: Bool = false
    
    /// Convert a string such as "A7" into an address.  Note that we also support
    /// specifying the anchor (so "$A7" and "A$7")
    /// - Parameter string: The string with row and column and optional anchor flags
    public init?(_ string: String?) {
        guard let string else { return nil }
        let scanner = Scanner(string: string)
        anchorColumn = scanner.scanString("$") != nil
        guard let col = scanner.scanCharacters(from: .uppercaseLetters) else {
            return nil
        }
        anchorRow = scanner.scanString("$") != nil
        guard let rowNumber = scanner.scanInt() else {
            return nil
        }
        row = rowNumber
        column = col
    }
    
    /// Convert back to $A$1 format
    public var description: String {
        "\(anchorColumn ? "$":"")\(column)\(anchorRow ? "$":"")\(row)"
    }
    /// Convert column letters to indices (only support single and double letter column names).  Zero based, so column "A" is 0
    var columnNumber: Int {
        get {
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
        set {
            column = Address.columnName(newValue)
        }
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
        .init(row: row + delta, anchorRow: anchorRow, column: column, anchorColumn: anchorColumn)
    }
    func adding(column delta: Int) -> Address {
        .init(row: row, anchorRow: anchorRow, column: Address.columnName(columnNumber + delta), anchorColumn: anchorColumn)
    }
    
    /// What is the offset from here to the other cell
    /// - Parameter other: The other cell
    /// - Returns: Different in rows and columns
    func delta(to other: Address) -> (dr: Int, dc: Int) {
        (dr: other.row - row, dc: other.columnNumber - columnNumber)
    }
    /// Offset the address by rows and columns
    /// - Parameter by: The offset
    /// - Returns: The offset address
    /// If the row or column is anchored, it is not offset
    func offset(by: (dr: Int, dc: Int)) -> Address {
        .init(row: anchorRow ? row : row + by.dr, anchorRow: anchorRow,
              column: anchorColumn ? column : Address.columnName(columnNumber + by.dc), anchorColumn:  anchorColumn)
    }
}
