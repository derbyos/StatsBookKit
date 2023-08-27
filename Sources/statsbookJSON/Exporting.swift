//
//  File.swift
//  
//
//  Created by gandreas on 8/26/23.
//

import Foundation
import statsbook
extension StatsBookJSON {
    // Take the data in our json and export it into a statsbook xlsx file
    public func export(to statsbook: StatsBookFile) throws {
        // does nothing yet
        try igrf.export(to: statsbook.igrf)
        try score.export(to: statsbook.score)
        try penalties.export(to: statsbook.penalties)
        try lineups.export(to: statsbook.lineups)
    }
}

extension IGRF {
    public func export(to igrf: statsbook.IGRF) throws {
        // TODO: Save comments
        igrf.venueName = venueName
        igrf.city = city
        igrf.state = state
        igrf.gameNumber = gameNumber
        igrf.tournament = tournament
        igrf.hostLeague = hostLeague
        igrf.date = date
        igrf.time = time
        // TODO: Save everything else
        try home.export(to: igrf.home)
        try away.export(to: igrf.away)
    }
}

extension IGRF.Team {
    public func export(to team: statsbook.IGRF.Team) throws {
        team.league = league
        team.team = self.team
        team.color = color
        for i in 1...20 {
            if i <= skaters.count {
                try self.skaters[i - 1].export(to: team.skater(index: i))
            } else { // clear it
                try Skater(number: nil, name: nil).export(to: team.skater(index: i))
            }
        }
    }
}
extension IGRF.Team.Skater {
    public func export(to skater: statsbook.IGRF.Team.Skater) throws {
        skater.name = name
        skater.number = number
    }
}

extension Score {
    public func export(to score: statsbook.Score) throws {
        // TODO: Save everything else
    }
}

extension Lineups {
    public func export(to lineups: statsbook.Lineups) throws {
        // TODO: Save everything else
    }
}

extension Penalties {
    public func export(to penalties: statsbook.Penalties) throws {
        // TODO: Save everything else
    }
}
