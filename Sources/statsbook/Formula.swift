//
//  File.swift
//  
//
//  Created by gandreas on 8/23/23.
//

import Foundation


/// Support for simple formulas
public struct Formula {
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
