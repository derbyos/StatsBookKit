//
//  File.swift
//  
//
//  Created by gandreas on 8/26/23.
//

import Foundation
import statsbook
extension StatsBookJSON {
    public init(statsbook: StatsBookFile) {
        self.metadata = .init(version: statsbook.version.rawValue, hasComments: true)
        self.igrf = .init(igrf: statsbook.igrf)
        self.score = .init(score: statsbook.score)
        self.penalties = .init(penalties: statsbook.penalties)
        self.lineups = .init(lineups: statsbook.lineups)
    }
}


/// A struct wrapping around TypedSheetCover to extract value and comment as
/// CommentedValue wrappers
@dynamicMemberLookup
struct Importer<TSC:TypedSheetCover> {
    var tsc: TSC
    public subscript(dynamicMember path: KeyPath<TSC.CellDefinitions, CellDef<String?>>) -> Commented<String?> {
        var retval = Commented<String?>(value: tsc[dynamicMember: path])
        retval.comment = tsc.commentFor[dynamicMember: path]?.commentText
        return retval
    }
    
    public subscript(dynamicMember path: KeyPath<TSC.CellDefinitions, CellDef<Int?>>) -> Commented<Int?> {
        var retval = Commented<Int?>(value: tsc[dynamicMember: path])
        retval.comment = tsc.commentFor[dynamicMember: path]?.commentText
        return retval
    }
    
    public subscript(dynamicMember path: KeyPath<TSC.CellDefinitions, CellDef<Double?>>) -> Commented<Double?> {
        var retval = Commented<Double?>(value: tsc[dynamicMember: path])
        retval.comment = tsc.commentFor[dynamicMember: path]?.commentText
        return retval
    }
}
