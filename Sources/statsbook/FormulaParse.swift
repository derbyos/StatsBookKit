//
//  File.swift
//  
//
//  Created by gandreas on 8/23/23.
//

import Foundation

extension Formula {
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
            if scanner.scanString(":") != nil {
                guard let addr2 = try parseAddress(scanner) else {
                    throw Errors.malformedRange
                }
                switch (addr,addr2) {
                case let (.referenceCell(a1), .referenceCell(a2)):
                    return .range(a1, a2)
                case let (.referenceNonLocalCell(s, a1), .referenceCell(a2)):
                    return .rangeNonLocal(s, a1, a2)
                case let (.referenceNonLocalCell(s, a1), .referenceNonLocalCell(s2, a2)):
                    // is Sheet!A1:Sheet!B5 even valid?
                    guard s == s2 else {
                        throw Errors.malformedRange
                    }
                    return .rangeNonLocal(s, a1, a2)
                default:
                    throw Errors.malformedRange
                }
            }
            return addr
        }
        var i = 0.0
        if scanner.scanDouble(&i) {
            return .constantNumber(i)
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
}
