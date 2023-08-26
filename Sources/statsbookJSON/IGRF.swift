//
//  File.swift
//  
//
//  Created by gandreas on 8/26/23.
//

import Foundation
import statsbook

public struct IGRF: Codable {
    public init(venueName: String? = nil, city: String? = nil, state: String? = nil, gameNumber: String? = nil, tournament: String? = nil, hostLeague: String? = nil, date: String? = nil, time: String? = nil, home: IGRF.Team, away: IGRF.Team) {
        _venueName = .init(value: venueName)
        _city = .init(value: city)
        _state = .init(value: state)
        _gameNumber = .init(value: gameNumber)
        _tournament = .init(value: tournament)
        _hostLeague = .init(value: hostLeague)
        _date = .init(value: date)
        _time = .init(value: time)
        self.home = home
        self.away = away
    }
    
    
    @Commented public var venueName: String?
    @Commented public var city: String?
    @Commented public var state: String?
    @Commented public var gameNumber: String?
    @Commented public var tournament: String?
    @Commented public var hostLeague: String?
    @Commented public var date: String?
    @Commented public var time: String?
    
    
    public struct Team: Codable {
        internal init(league: String? = nil, team: String? = nil, color: String? = nil, period1Points: Int? = nil, period2Points: Int? = nil, totalPoints: Int? = nil, period1Penalties: Int? = nil, period2Penalties: Int? = nil, totalPenalties: Int? = nil, skaters: [IGRF.Team.Skater]) {
            _league = .init(value:league)
            _team = .init(value:team)
            _color = .init(value:color)
            _period1Points = .init(value:period1Points)
            _period2Points = .init(value:period2Points)
            _totalPoints = .init(value:totalPoints)
            _period1Penalties = .init(value:period1Penalties)
            _period2Penalties = .init(value:period2Penalties)
            _totalPenalties = .init(value:totalPenalties)
            self.skaters = skaters
        }
        
        @Commented public var league: String?
        @Commented public var team: String?
        @Commented public var color: String?
        
        @Commented public var period1Points : Int?
        @Commented public var period2Points : Int?
        @Commented public var totalPoints : Int?
        @Commented public var period1Penalties : Int?
        @Commented public var period2Penalties : Int?
        @Commented public var totalPenalties : Int?
        
        public struct Skater: Codable {
            internal init(number: String? = nil, name: String? = nil) {
                _number = .init(value:number)
                _name = .init(value:name)
            }
            
            @Commented public var number: String?
            @Commented public var name: String?
        }
        public var skaters: [Skater]
    }
    public var home: Team
    public var away: Team
}

/// Sad that this extension has to be here (and not in importer) but `_foo` is private
/// and can only be accessed by extensions in this file
extension IGRF {
    init(igrf sb: statsbook.IGRF) {
        let igrf = Importer(tsc: sb)
        _venueName = igrf.venueName
        _city = igrf.city
        _state = igrf.state
        _gameNumber = igrf.gameNumber
        _tournament = igrf.tournament
        _hostLeague = igrf.hostLeague
        _date = igrf.date
        _time = igrf.time
        home = .init(team: sb.home, penalties: sb.homePenalties, points: sb.homePoints)
        away = .init(team: sb.away, penalties: sb.awayPenalties, points: sb.awayPoints)
    }
}

extension IGRF.Team {
    init(team sb: statsbook.IGRF.Team, penalties: statsbook.IGRF.PenaltyTotals, points:statsbook.IGRF.PointTotals) {
        let team = Importer(tsc: sb)
        _league = team.league
        _team = team.team
        _color = team.color
        _period1Points = Importer(tsc:points).period1
        _period2Points = Importer(tsc:points).period2
        _totalPoints = Importer(tsc:points).total
        _period1Penalties = Importer(tsc:penalties).period1
        _period2Penalties = Importer(tsc:penalties).period2
        _totalPenalties = Importer(tsc:penalties).total
        skaters = (1...20).compactMap({ i in
            let skater = Skater(skater: sb.skater(index: i))
            if skater.name != nil || skater.number != nil {
                return skater
            }
            return nil
        })
    }
}

extension IGRF.Team.Skater {
    init(skater sb: statsbook.IGRF.Team.Skater) {
        let skater = Importer(tsc: sb)
        _number = skater.number
        _name = skater.name
    }
}
