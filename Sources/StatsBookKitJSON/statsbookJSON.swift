//
//  File.swift
//  
//
//  Created by gandreas on 8/26/23.
//

import Foundation

public struct StatsBookJSON : Codable {
    /// File metadata information (including the version from the Read Me sheet
    public var metadata: Metadata
    /// IGRF sheet
    public var igrf: IGRF
    /// Score sheet
    public var score: Score
    /// Penalties sheet
    public var penalties: Penalties
    /// Lineups sheet
    public var lineups: Lineups
    
    public static var blank =  StatsBookJSON(
        metadata: .init(version: "January 2019 Release", hasComments: true),
        igrf: .init(home: .init(skaters: []),
                    away: .init(skaters:[])
                   ),
        score: .init(homeP1: .init(totals: .init()),
                     homeP2: .init(totals: .init()),
                     awayP1: .init(totals: .init()),
                     awayP2: .init(totals: .init())),
        penalties: .init(period1: .init(home: .init(skaters: []),
                                        away: .init(skaters: [])),
                         period2: .init(home: .init(skaters: []),
                                        away: .init(skaters: []))),
        lineups: .init(homeP1: .init(jamRows: []),
                       homeP2: .init(jamRows: []),
                       awayP1: .init(jamRows: []),
                       awayP2: .init(jamRows: []))
    )

    public init(metadata: Metadata, igrf: IGRF, score: Score, penalties: Penalties, lineups: Lineups) {
        self.metadata = metadata
        self.igrf = igrf
        self.score = score
        self.penalties = penalties
        self.lineups = lineups
    }
}
