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
    
    // MARK: Recursive descent parser
    func parseFunctionName(_ scanner: Scanner) -> String? {
        let pos = scanner.scanLocation
        if let name = scanner.scanCharacters(from: .uppercaseLetters),
           scanner.scanString("(") != nil {
            return name
        }
        scanner.scanLocation = pos
        return nil
    }
    func parseFunction(_ scanner: Scanner) throws -> Op? {
        if let name = parseFunctionName(scanner) {
            var param = [Op]()
            if scanner.scanString(")") != nil {
                // done
                return .function(name, param)
            }
            while scanner.isAtEnd == false {
                let p = try parseOp(scanner)
                param.append(p)
                if scanner.scanString(")") != nil {
                    // done
                    return .function(name, param)
                }
                if scanner.scanString(",") == nil {
                    throw Errors.expectedCommaBetweenParameters
                }
            }
        }
        return nil
    }
    func parseAddress(_ scanner: Scanner) throws -> Op? {
        let pos = scanner.scanLocation
        var sheetName: String?
        if scanner.scanString("'") != nil {
            sheetName = scanner.scanUpToString("'")
            guard sheetName != nil else {
                throw Errors.malformedCellAddress
            }
            _ = scanner.scanString("'")
            if scanner.scanString("!") == nil {
                throw Errors.malformedCellAddress
            }
        } else if let name = scanner.scanCharacters(from: .uppercaseLetters) {
            // this could be a cell column
            if scanner.scanString("!") != nil {
                sheetName = name
            } else {
                // not a sheet name, keep going
                scanner.scanLocation = pos
            }
        }
        var hasDollar = scanner.scanString("$") != nil
        if let name = scanner.scanCharacters(from: .uppercaseLetters) {
            hasDollar = scanner.scanString("$") != nil || hasDollar
            var i = 0
            if scanner.scanInt(&i) {
                if let sheetName {
                    return .referenceNonLocalCell(sheetName, Address(row: i, column: name))
                } else {
                    return .referenceCell(Address(row: i, column: name))
                }
            } else {
                if hasDollar {
                    throw Errors.malformedCellAddress
                }
                // otherwise it may just be a name for some reason
            }
        }
        if sheetName != nil { // we got Name!
            throw Errors.malformedCellAddress
        }
        scanner.scanLocation = pos
        return nil
    }
    func parseTerminal(_ scanner: Scanner) throws -> Op {
        if let fn = try parseFunction(scanner) {
            return fn
        }
        if scanner.scanString("(") != nil {
            let retval = try parseOp(scanner)
            if scanner.scanString(")") == nil {
                throw Errors.missingClosingParen
            }
            return retval
        }
        if let addr = try parseAddress(scanner) {
            return addr
        }
        var i = 0
        if scanner.scanInt(&i) {
            return .constantInt(i)
        }
        // shortcut optimization
        if scanner.scanString("\"\"") != nil {
            return .constantString("")
        }
        // Note: doesn't support backslash quote yet
        if scanner.scanString("\"") != nil {
            let savedSkip = scanner.charactersToBeSkipped
            scanner.charactersToBeSkipped = nil
            guard let str = scanner.scanUpToString("\"") else {
                throw Errors.invalidString
            }
            _ = scanner.scanString("\"")
            scanner.charactersToBeSkipped = savedSkip
            return .constantString(str)
        }
        throw Errors.unableToParseFormula
    }
    func parsePrefix(_ scanner: Scanner) throws -> Op {
        if scanner.scanString("-") != nil {
            return .prefix(.negate, try parsePrefix(scanner))
        } else {
            return try parseTerminal(scanner)
        }
    }
    func parseFactor(_ scanner: Scanner) throws -> Op {
        var retval = try parsePrefix(scanner)
        while scanner.isAtEnd == false {
            if scanner.scanString("*") != nil {
                retval = .binary(retval, .mul, try parsePrefix(scanner))
            } else if scanner.scanString("/") != nil {
                retval = .binary(retval, .div, try parsePrefix(scanner))
            } else {
                break
            }
        }
        return retval
    }
    func parseTerm(_ scanner: Scanner) throws -> Op {
        var retval = try parseFactor(scanner)
        while scanner.isAtEnd == false {
            if scanner.scanString("+") != nil {
                retval = .binary(retval, .add, try parseFactor(scanner))
            } else if scanner.scanString("-") != nil {
                retval = .binary(retval, .sub, try parseFactor(scanner))
            } else if scanner.scanString("&") != nil {
                retval = .binary(retval, .concat, try parseFactor(scanner))
            } else {
                break
            }
        }
        return retval
    }
    func parseCompare(_ scanner: Scanner) throws -> Op {
        var retval = try parseTerm(scanner)
        while scanner.isAtEnd == false {
            if scanner.scanString("=") != nil {
                retval = .binary(retval, .eq, try parseTerm(scanner))
            } else if scanner.scanString("!=") != nil {
                retval = .binary(retval, .ne, try parseTerm(scanner))
            } else if scanner.scanString(">=") != nil {
                retval = .binary(retval, .ge, try parseTerm(scanner))
            } else if scanner.scanString("<=") != nil {
                retval = .binary(retval, .le, try parseTerm(scanner))
            } else if scanner.scanString(">") != nil {
                retval = .binary(retval, .gt, try parseTerm(scanner))
            } else if scanner.scanString("<") != nil {
                retval = .binary(retval, .lt, try parseTerm(scanner))
            } else {
                break
            }
        }
        return retval
    }

    func parseOp(_ scanner: Scanner) throws -> Op {
        return try parseCompare(scanner)
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
        case constantInt(Int)
        case constantString(String)
        /// A cell reference (we don't care about $A$4 vs A4)
        case referenceCell(Address)
        /// A cell reference in another sheet
        case referenceNonLocalCell(String, Address)
        case function(String, [Op])
        case binary(Op, Operator, Op)
        case prefix(Prefix, Op)
    }
    public enum Value: Equatable {
        case string(String)
        case int(Int)
        case bool(Bool)
        case undefined
        
        var isTrue: Bool {
            switch self {
            case .bool(let b): return b
            case .int(let i): return i != 0
            case .string(let s): return !s.isEmpty
            case .undefined: return false
            }
        }
    }
    public func eval() throws -> Value {
        try eval(op: root)
    }
    
    func eval(fn: String, param: [Op]) throws -> Value {
        switch fn {
        case "IF":
            if param.count == 2 {
                if try eval(op:param[0]).isTrue {
                    return try eval(op:param[1])
                } else {
                    return .undefined
                }
            } else if param.count == 3 {
                if try eval(op:param[0]).isTrue {
                    return try eval(op:param[1])
                } else {
                    return try eval(op:param[2])
                }
            } else {
                throw Errors.malformedFunction("IF() expects 2 or 3 parameters")
            }
        case "OR":
            return .bool(try param.contains(where: { op in
                try eval(op: op).isTrue
            }))
        case "AND":
            return .bool(try param.allSatisfy({ op in
                try eval(op: op).isTrue
            }))
        case "ISBLANK":
            guard param.count == 1 else {
                throw Errors.malformedFunction("ISBLANK() expects 1 parameter")
            }
            let v = try eval(op:param[0])
            switch v {
            case .string(let s): return .bool(s.isEmpty)
            case .undefined: return true
            default: return false
            }
        default:
            throw Errors.unimplementedFunction(fn)
        }
    }
    
    func eval(lhs: Op, binOp: Operator, rhs: Op) throws -> Value {
        let l = try eval(op: lhs)
        switch binOp {
        case .eq:
            return try .bool(l == eval(op: rhs))
        case .ne:
            return try .bool(l != eval(op: rhs))
        case .concat:
            guard case let .string(lstring) = l, case let .string(rstring) = try eval(op: rhs) else {
                throw Errors.typeMismatch("Concat operator requires two strings")
            }
            return .string(lstring + rstring)
        default:
            throw Errors.unimplementedFunction(binOp.rawValue)
        }
    }
    func eval(op: Op) throws -> Value {
        switch op {
        case .constantInt(let i): return .int(i)
        case .constantString(let s): return .string(s)
        case .referenceCell(let addr):
            guard let cell = sheet[addr] else {
                return .undefined
            }
            guard let value = cell.value else {
                return .undefined
            }
            return value
        case .function(let fn, let ops):
            return try eval(fn: fn, param: ops)
        case .referenceNonLocalCell(let sheetName, let addr):
            let newSheet = try sheet.file.sheet(named: sheetName)
            guard let cell = newSheet[addr] else {
                return .undefined
            }
            guard let value = cell.value else {
                return .undefined
            }
            return value
        case .binary(let lhs, let binop, let rhs):
            return try eval(lhs: lhs, binOp: binop, rhs: rhs)
        default:
            throw Errors.unimplementedFunction("")
        }
    }
}


extension Cell {
    var value: Formula.Value? {
        switch xml["t"] {
        case "s":
            guard let sharedID = xml.firstChild(named: "v")?.asInt else {
                return nil
            }
            return sheet.file[sharedString: sharedID].map{.string($0)}
        case "str":
            return xml.firstChild(named: "v").map{.string($0.asString)}
        default:
            return nil
        }
    }
}


extension Formula.Value : ExpressibleByNilLiteral, ExpressibleByStringLiteral, ExpressibleByIntegerLiteral, ExpressibleByBooleanLiteral {
    public init(nilLiteral: ()) {
        self = .undefined
    }
    public init(stringLiteral value: String) {
        self = .string(value)
    }
    public init(booleanLiteral value: Bool) {
        self = .bool(value)
    }
    public init(integerLiteral value: Int) {
        self = .int(value)
    }
}
