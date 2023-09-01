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
    
    var nextRow : Address {
        self.adding(row: 1)
    }
    var previousRow : Address {
        self.adding(row: -1)
    }
    
    /// The two direction
    public enum Axis : Equatable {
        case row
        case column
    }
    /// Offset between cells
    public struct Offset {
        public init(dr: Int = 0, dc: Int = 0) {
            self.dr = dr
            self.dc = dc
        }
        public static var zero = Offset(dr: 0, dc: 0)
        var dr: Int
        var dc: Int
        
        public static func + (lhs: Offset, rhs: Offset) -> Offset {
            .init(dr: lhs.dr + rhs.dr, dc: lhs.dc + rhs.dc)
        }
    }
    /// What is the offset from here to the other cell
    /// - Parameter other: The other cell
    /// - Returns: Different in rows and columns
    func delta(to other: Address) -> Offset {
        .init(dr: other.row - row, dc: other.columnNumber - columnNumber)
    }
    
    public static func - (lhs: Address, rhs: Address) -> Offset {
        rhs.delta(to: lhs)
    }
    /// Offset the address by rows and columns
    /// - Parameter by: The offset
    /// - Returns: The offset address
    /// If the row or column is anchored, it is not offset
    func offset(by: Offset) -> Address {
        .init(row: anchorRow ? row : row + by.dr, anchorRow: anchorRow,
              column: anchorColumn ? column : Address.columnName(columnNumber + by.dc), anchorColumn:  anchorColumn)
    }
    
    public static func + (lhs: Address, rhs: Offset) -> Address {
        lhs.offset(by: rhs)
    }
    
    // TODO: Make AddressRange struct with an iterator
    /// Support range trivially
    static func ... (tl: Address, br:Address) -> [Address] {
        (min(tl.row, br.row) ..< max(tl.row, br.row) + 1).flatMap { row in
            (min(tl.columnNumber, br.columnNumber) ..< max(tl.columnNumber, br.columnNumber) + 1).map { colNum in
                Address(row: row, column: Address.columnName(colNum))
            }
        }
    }
}

extension Address : ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        if let value = Address(value) {
            self = value
        } else {
            fatalError("Invalid constant address for \(value)")
        }
    }
}

extension Address : RawRepresentable {
    public var rawValue: String {
        self.description
    }
    public init?(rawValue: String) {
        if let value = Address(rawValue) {
            self = value
        } else {
            return nil
        }
    }
}
