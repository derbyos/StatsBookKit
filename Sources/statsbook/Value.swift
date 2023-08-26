//
//  File.swift
//  
//
//  Created by gandreas on 8/24/23.
//

import Foundation


/// Values are the actual values that are stored in the cells (and used in formulas)
public enum Value: Equatable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case undefined
    
    public enum ComparisonResult {
        case ascending
        case same
        case descending
        case invalid
    }
    
    func compare(_ other: Value, caseInsensitive: Bool = false) -> ComparisonResult {
        switch (self, other) {
        case (.string(""), .undefined),
            (.undefined, .string("")):
            return .same
        case let (.string(l), .string(r)):
            switch l.compare(r, options: caseInsensitive ? [.caseInsensitive] : []) {
            case .orderedAscending: return .ascending
            case .orderedSame: return .same
            case .orderedDescending: return .descending
            }
        case let (.number(l), .number(r)):
            if l < r {
                return .ascending
            } else if l > r {
                return .descending
            } else if l == r {
                return .same
            } else {
                // if we have NaN
                return .invalid
            }
        case let (.bool(l), .bool(r)):
            if l == r {
                return .same
            } else if l {
                return .descending
            } else {
                return .ascending
            }
        default:
            return .invalid
        }
    }
    public static func ==(lhs: Value, rhs: Value) -> Bool {
        return lhs.compare(rhs) == .same
    }
    var asNumber: Double? {
        switch self {
        case .number(let d): return d
        case .undefined: return 0.0
        case .bool(let b): return b ? 1.0 : 0.0
        case .string: return nil
        }
    }
    var asString: String? {
        switch self {
        case .number(let d): return "\(d)"
        case .undefined: return ""
        case .bool(let b): return b ? "true" : "false"
        case .string(let s): return s
        }
    }
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


extension Value : ExpressibleByNilLiteral, ExpressibleByStringLiteral, ExpressibleByFloatLiteral, ExpressibleByBooleanLiteral {
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

