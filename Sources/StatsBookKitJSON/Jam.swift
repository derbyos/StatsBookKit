//
//  File.swift
//  
//
//  Created by gandreas on 8/31/23.
//

import Foundation


/// What kind of Jam Row is this - a jam (with a number) or a star pass?
public enum JamRowKind {
    /// is this a regular jam row, if so ``jam`` will have the number of the jam
    case jam(Int)
    /// Is this a star pass by this team?
    case starPass
    /// Is this a star pass by the other team?
    case starPassOther
    /// something else?
    case other(String)
    /// blank?
    case blank
    
    
    /// We are definitely some sort of star pass
    var isStarPass : Bool {
        switch self {
        case .starPass, .starPassOther: return true
        default: return false
        }
    }
    
    /// Figure out, from an Int or String, what we are
    /// - Parameters:
    ///   - jam: The jam number, if provided
    ///   - sp: The star pass text otherwise
    public init(jam: Int?, sp: String?) {
        if let num = jam {
            self = .jam(num)
        } else if let sp, sp.isEmpty == false {
            switch sp {
            case "SP": self = .starPass
            case "SP*","*": self = .starPassOther
            default: self = .other(sp)
            }
        } else {
            self = .blank
        }
    }
    
    /// Reverse the intializer, and save SP and Jam
    /// - Parameters:
    ///   - jam: The jam to set if we are a jam
    ///   - sp: The star pass to set if we are some sort of star pass
    public func extract(jam: inout Int?, sp: inout String?) {
        switch self {
        case .jam(let i):
            sp = nil
            jam = i
        case .starPass:
            jam = nil
            sp = "SP"
        case .starPassOther:
            jam = nil
            sp = "SP*"
        case .other(let s):
            jam = nil
            sp = s
        case .blank:
            jam = nil
            sp = nil
        }
    }
}
/// Since both lineups and score use either one or two row in the spread sheet
/// to represent themselves, we call those a JamRow
public protocol JamRowable : FlexArrayItem {
    /// What kind of row is this - a regular one or a SP?
    var jamRowKind: JamRowKind { get set }
    
}

/// A jam for this team/period, synthesized from jam rows
public struct SynthesizedJam<Row:JamRowable> {
    public init(number: Int, jam: Row, starPass: Row? = nil) {
        self.number = number
        self.jam = jam
        self.starPass = starPass
    }
    
    /// The jam number
    public let number: Int
    /// The jam row from the underlying period
    public var jam: Row
    /// If this row has a star pass, the jam row for that star pass (this
    /// includes the star pass for the other team only)
    public var starPass: Row?
}

extension FlexArray where Element : JamRowable {
    
    /// Get the index (in jamRows) for the starting row of the jam
    /// - Parameter number: The jam number
    /// - Returns: The row found
    public func index(forJam number: Int) -> Int? {
        return firstIndex {
            if case let .jam(i) = $0.jamRowKind, i == number { return true }
            return false
        }
    }

    /// Get a specific jam by number (including star pass)
    /// - Parameter number: The jam number
    /// - Returns: The jam/star pass jam row pair structure
    public func jam(number: Int) -> SynthesizedJam<Element>? {
        guard let idx = index(forJam: number) else {
            return nil
        }
        if self[idx+1].jamRowKind.isStarPass {
            return .init(number: number, jam: self[idx], starPass: self[idx+1])
        }
        return .init(number: number, jam: self[idx])
    }

    public subscript(jam number: Int) -> SynthesizedJam<Element>? {
        get {
            jam(number: number)
        }
    }

}
