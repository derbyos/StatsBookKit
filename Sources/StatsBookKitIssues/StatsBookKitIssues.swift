//
//  File.swift
//  
//
//  Created by gandreas on 9/3/23.
//

import Foundation

/// What team is this issue related to
public enum Team {
    /// Home team (left team on IGRF)
    case home
    /// Away team (right team on IGRF)
    case away
}

/// What sheet is this issue related to
public enum Sheet {
    /// The IGRF
    case igrf
    /// The score sheet
    case score
    /// The penalties sheet
    case penalties
    /// The lineups sheet
    case lineups
}

/// Where does this issue come from (or a reference to where contradictory information is found)
public struct Source {
    /// What sheet does this come from
    public var sheet: Sheet
    /// For errors that come from a specific team (most of them)
    public var team: Team?
    /// What period (if applicable)
    public var period: Int?
    /// What jam (if applicable)
    public var jam: Int?
    /// What row in table, one based index (where 1 should correspond to jam 1, but beyond that it can vary)
    public var row: Int?
    /// Trip, if applicable (can be either score trip or box trip, depending on sheet)
    public var trip: Int?
}


/// The severity of the issue
public enum Severity {
    /// These are definite issues that need to be addressed.   For example, a penalty without a box trip recorded in the lineups.
    case error
    /// These are things that are problems that probably impact the statsbook validity.
    case problem
    /// These are warnings that should be addressed, but could definitely be acceptable
    case warning
    /// These are unusual cases detected.  Not specifically a problem, but might be indicative of one
    case minor
}

public protocol Issue : CustomStringConvertible {
    /// How bad is the problem
    var severity: Severity { get }
    /// Where is the issue statsbook (i.e., what needs to be fixed)
    var source: Source { get }
    /// A summary descrition of the problem
    var description: String { get }
    /// Details of the problem, including specific values
    var detailedDescription: String { get }
    /// Suggestion on how to fix the problem (if there is one)
    var suggestedFix: String? { get }
}
