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
        try homeP1.export(to: score.homeP1)
        try homeP2.export(to: score.homeP2)
        try awayP1.export(to: score.awayP1)
        try awayP2.export(to: score.awayP2)
    }
}

extension Score.TeamPeriod {
    public func export(to score: statsbook.Score.TeamPeriod) throws {
        score.jammerRef = jammerRef
        score.scorekeeper = scorekeeper
        for i in 0..<score.maxJamRows {
            let row = score[jamRow: i]
            if i < self.jams.count {
                try self.jams[i].export(to: row)
            } else {
                // save an empty one
                try Jam(trips: []).export(to: row)
            }
        }
        // nothing really in the totals, but in case there are comments
        try totals.export(to: score.totals)
    }
}
extension Score.TeamPeriod.Jam {
    public func export(to jam: statsbook.Score.TeamPeriod.Jam) throws {
        if let sp = self.sp {
            jam.sp = sp
        } else {
            jam.jam = self.jam
        }
        jam.jammer = jammer
        jam.lost = lost
        jam.lead = lead
        jam.call = call
        jam.inj = inj
        jam.ni = ni
        // TODO: Add formula support for Trip1 in overtime and trips > 10
        jam.trip2 = trip2
        jam.trip3 = trip3
        jam.trip4 = trip4
        jam.trip5 = trip5
        jam.trip6 = trip6
        jam.trip7 = trip7
        jam.trip8 = trip8
        jam.trip9 = trip9
        jam.trip10 = trip10
    }
}
extension Score.TeamPeriod.Totals {
    public func export(to score: statsbook.Score.TeamPeriod.Totals) throws {
        // totals are all derived (save for potential comments, which are still TBD)
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
