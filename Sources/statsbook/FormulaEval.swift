//
//  File.swift
//  
//
//  Created by gandreas on 8/23/23.
//

import Foundation

extension Formula {
    /// Evaluate a formula, creating a value
    /// - Returns: The value of evaluating the formula
    public func eval() throws -> Value {
        try eval(op: root)
    }
    
    func iterateRange(sheetName: String?, tl: Address, br: Address, action: (Address, Value, inout Bool) throws -> Void) throws {
        for row in min(tl.row, br.row) ..< max(tl.row, br.row) + 1 {
            for colNum in min(tl.columnNumber, br.columnNumber) ..< max(tl.columnNumber, br.columnNumber) + 1 {
                let address = Address(row: row, column: Address.columnName(colNum))
                let value: Value = try fetch(sheetName: sheetName, address: address)
                var stop = false
                try action(address, value, &stop)
                if stop {
                    return // done prematurely
                }
            }
        }
    }
    
    func flatten(param: [Op]) throws -> [Value] {
        return try param.flatMap({ op in
            var retval = [Value]()
            switch op {
            case let .range(tl, br):
                try iterateRange(sheetName: nil, tl: tl, br: br) { _, value, _ in
                    retval.append(value)
                }
            case let .rangeNonLocal(sheetName, tl, br):
                try iterateRange(sheetName: sheetName, tl: tl, br: br) { _, value, _ in
                    retval.append(value)
                }
            default:
                let value = try eval(op: op)
                retval.append(value)
            }
            return retval
        })
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
            return .bool(v.isEmpty)
        case "SUM":
            var total = 0.0
            for value in try flatten(param: param) {
                if case let .number(i) = value {
                    total += i
                }
            }
            return .number(total)
        case "COUNT": // where only number cells matter
            var total = 0.0
            for value in try flatten(param: param) {
                if case .number = value {
                    total += 1
                }
            }
            return .number(total)
        case "COUNTIF":
            guard param.count > 1 else {
                throw Errors.typeMismatch("COUNTIF(value,value)")
            }
            let test = try eval(op:param.last!)
            var total = 0.0
            for value in try flatten(param: param.dropLast()) {
                if value == test {
                    total += 1
                }
            }
            return .number(total)
        case "COUNTA": // count number of non-empty cells
            var total = 0.0
            for value in try flatten(param: param) {
                if !value.isEmpty {
                    total += 1.0
                }
            }
            return .number(total)
        case "MAX":
            var total = -Double.infinity
            for value in try flatten(param: param) {
                if case .number(let i) = value {
                    total = max(total, i)
                }
            }
            if total == -Double.infinity {
                return .undefined
            }
            return .number(total)
        case "MIN":
            var total = Double.infinity
            for value in try flatten(param: param) {
                if case .number(let i) = value {
                    total = min(total, i)
                }
            }
            if total == Double.infinity {
                return .undefined
            }
            return .number(total)
        default:
            throw Errors.unimplementedFunction(fn)
        }
    }
    
    func eval(lhs: Op, binOp: Operator, rhs: Op) throws -> Value {
        let l = try eval(op: lhs)
        switch binOp {
        case .eq:
            let r = try eval(op: rhs)
            switch (l,r) {
                // empty cells are empty strings
            case (.string(""), .undefined), (.undefined, .string("")):
                return true
            default:
                return .bool(l == r)
            }
        case .ne:
            let r = try eval(op: rhs)
            switch (l,r) {
            case (.string(""), .undefined), (.undefined, .string("")):
                return false
            default:
                return .bool(l != r)
            }
        case .lt:
            let r = try eval(op: rhs)
            switch (l,r) {
            case (.number(let ln), .number(let rn)): return .bool(ln < rn)
            case (.string(let ln), .string(let rn)): return .bool(ln < rn)
            default:
                throw Errors.typeMismatch("<")
            }
        case .gt:
            let r = try eval(op: rhs)
            switch (l,r) {
            case (.number(let ln), .number(let rn)): return .bool(ln > rn)
            case (.string(let ln), .string(let rn)): return .bool(ln > rn)
            default:
                throw Errors.typeMismatch(">")
            }
        case .le:
            let r = try eval(op: rhs)
            switch (l,r) {
            case (.number(let ln), .number(let rn)): return .bool(ln <= rn)
            case (.string(let ln), .string(let rn)): return .bool(ln <= rn)
            default:
                throw Errors.typeMismatch("<=")
            }
        case .ge:
            let r = try eval(op: rhs)
            switch (l,r) {
            case (.number(let ln), .number(let rn)): return .bool(ln >= rn)
            case (.string(let ln), .string(let rn)): return .bool(ln >= rn)
            default:
                throw Errors.typeMismatch(">=")
            }
        case .add:
            guard let ln = l.asNumber, let rn = try eval(op: rhs).asNumber  else {
                throw Errors.typeMismatch("+")
            }
            return .number(ln + rn)
        case .sub:
            guard let ln = l.asNumber, let rn = try eval(op: rhs).asNumber  else {
                throw Errors.typeMismatch("-")
            }
            return .number(ln - rn)
        case .mul:
            guard let ln = l.asNumber, let rn = try eval(op: rhs).asNumber  else {
                throw Errors.typeMismatch("*")
            }
            return .number(ln * rn)
        case .div:
            guard let ln = l.asNumber, let rn = try eval(op: rhs).asNumber  else {
                throw Errors.typeMismatch("/")
            }
            return .number(ln / rn)
        case .concat:
            guard case let .string(lstring) = l, case let .string(rstring) = try eval(op: rhs) else {
                throw Errors.typeMismatch("Concat operator requires two strings")
            }
            return .string(lstring + rstring)
        }
    }
    
    func fetch(sheetName: String?, address: Address) throws -> Value {
        let sheetToUse: Sheet
        if let sheetName {
            sheetToUse = try sheet.file.sheet(named: sheetName)
        } else {
            sheetToUse = sheet
        }
        guard let cell = sheetToUse[address] else {
            return .undefined
        }
        // do we want to eval this formula?
        guard let value = try cell.eval() else {
            return .undefined
        }
        return value
    }
    func eval(op: Op) throws -> Value {
        switch op {
        case .constantNumber(let i): return .number(i)
        case .constantString(let s): return .string(s)
        case .function(let fn, let ops):
            return try eval(fn: fn, param: ops)
        case .referenceCell(let addr):
            return try fetch(sheetName: nil, address: addr)
        case .referenceNonLocalCell(let sheetName, let addr):
            return try fetch(sheetName: sheetName, address: addr)
        case .binary(let lhs, let binop, let rhs):
            return try eval(lhs: lhs, binOp: binop, rhs: rhs)
        default:
            throw Errors.unimplementedFunction("")
        }
    }
}

extension Cell {
    /// The current embedded value in the XML, potentially including shared strings, etc...
    /// but not calculated or cached in the sheet
    var value: Formula.Value? {
        switch xml["t"] {
        case "s":
            guard let sharedID = xml.firstChild(named: "v")?.asInt else {
                return nil
            }
            return sheet.file[sharedString: sharedID].map{.string($0)}
        case "str": // more accurately, cell containing formula
            return xml.firstChild(named: "v").map{.string($0.asString)}
        case "inlinestr":
            return xml.firstChild(named: "v").map{.string($0.asString)}
//        case "b": // boolean
//            return xml.firstChild(named: "v").map{.string($0.asString)}
//        case "d": // date
//            return xml.firstChild(named: "v").map{.string($0.asString)}
        case "n":
            return xml.firstChild(named: "v").flatMap{Double($0.asString)}.map{.number($0)}
        default:
            // for untyped results from formulas
            if let v = xml.firstChild(named: "v") {
                if let d = Double(v.asString) {
                    return .number(d)
                }
                return .string(v.asString)
            }
            return nil
        }
    }
    
    func eval(force: Bool = true) throws -> Formula.Value? {
        if let value =  sheet.cachedValues[address] {
            return value
        }
        if force { // ignore value, re-calcuate formula
            if let f = formula {
                let retval = try f.eval()
                sheet.cachedValues[address] = retval
                return retval
            }
        }
        // check value first
        if let value = self.value {
            return value
        } else {
            if let f = formula {
                let retval = try f.eval()
                sheet.cachedValues[address] = retval
                return retval
            } else {// no value, no formula
                return nil
            }
        }
    }
}


