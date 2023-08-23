//
//  File.swift
//  
//
//  Created by gandreas on 8/23/23.
//

import Foundation


/// Support for simple formulas
public struct Formula {
    internal init(root: Formula.Op, sheet: Sheet) {
        self.root = root
        self.sheet = sheet
    }
    
    /// Errors found while parsing or executing the formula
    enum Errors : Error {
        case expectedCommaBetweenParameters
        case missingClosingParen
        case unableToParseFormula
        case malformedCellAddress
        case malformedRange
        case invalidString
        case unimplementedFunction(String)
        case malformedFunction(String)
        case typeMismatch(String)
    }
    var root: Op
    var sheet: Sheet
    public init(source: String, sheet: Sheet) throws {
        self.sheet = sheet
        let scanner = Scanner(string: source)
        root = .undefined
        // now we can call ourselves
        root = try parseOp(scanner)
    }
    
    enum Operator : String {
        case add = "+"
        case sub = "-"
        case mul = "*"
        case div = "/"
        case concat = "&"
        case eq = "="
        case ne = "!="
        case lt = "<"
        case gt = ">"
        case le = "<="
        case ge = ">="
    }
    enum Prefix: String {
        case negate = "-"
    }
    // support for some of the functions
    indirect enum Op {
        case undefined
        case constantNumber(Double)
        case constantString(String)
        /// A cell reference (we don't care about $A$4 vs A4)
        /// Turns out for shared formulas we do care about $
        case referenceCell(Address)
        /// A cell reference in another sheet
        case referenceNonLocalCell(String, Address)
        case range(Address, Address)
        case rangeNonLocal(String, Address, Address)
        case function(String, [Op])
        case binary(Op, Operator, Op)
        case prefix(Prefix, Op)
    }
    public enum Value: Equatable {
        case string(String)
        case number(Double)
        case bool(Bool)
        case undefined
        
        var isTrue: Bool {
            switch self {
            case .bool(let b): return b
            case .number(let i): return i != 0
            case .string(let s): return !s.isEmpty
            case .undefined: return false
            }
        }
        var isEmpty: Bool {
            switch self {
            case .undefined: return true
            case .string(let s): return s.isEmpty
            default: return false
            }
        }
    }
}

extension Formula.Value : ExpressibleByNilLiteral, ExpressibleByStringLiteral, ExpressibleByFloatLiteral, ExpressibleByBooleanLiteral {
    public init(nilLiteral: ()) {
        self = .undefined
    }
    public init(stringLiteral value: String) {
        self = .string(value)
    }
    public init(booleanLiteral value: Bool) {
        self = .bool(value)
    }
    public init(floatLiteral value: Double) {
        self = .number(value)
    }
}

extension Formula {
    /// Offset the formula by a given number of rows and columns
    /// Note that anchored parts do not offset
    /// - Parameter by: The offset in rows and columns
    /// - Returns: The offset formula
    func offset(by: (dr: Int, dc: Int)) -> Formula {
        .init(root: root.offset(by: by), sheet: sheet)
    }
}

extension Formula.Op {
    /// Offset the formula by a given number of rows and columns
    /// Note that anchored parts do not offset
    /// - Parameter by: The offset in rows and columns
    /// - Returns: The offset formula
    func offset(by: (dr: Int, dc: Int)) -> Formula.Op {
        switch self {
        case .binary(let l, let oper, let r):
            return .binary(l.offset(by: by), oper, r.offset(by: by))
        case .function(let fn, let ops):
            return .function(fn, ops.map{$0.offset(by: by)})
        case .prefix(let pre, let op):
            return .prefix(pre, op.offset(by: by))
        case .range(let a1, let a2):
            // only local ranges are offset, non-sheet ones never are
            return .range(a1.offset(by: by), a2.offset(by: by))
        case .referenceCell(let a):
            return .referenceCell(a.offset(by: by))
        default:
            return self
        }
    }

}
