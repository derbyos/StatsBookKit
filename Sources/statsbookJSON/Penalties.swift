//
//  File.swift
//  
//
//  Created by gandreas on 8/26/23.
//

import Foundation

public struct Penalties: Codable {
    public struct Period: Codable {
        public init(penaltyTracker: String? = nil, home: Penalties.Period.Team, away: Penalties.Period.Team) {
            _penaltyTracker = .init(value:penaltyTracker)
            self.home = home
            self.away = away
        }
        
        // these are all derived from IGRF
//        @Commented public var homeName : String?
//        @Commented public var homeColor : String?
//        @Commented public var awayName : String?
//        @Commented public var awayColor : String?
        @Commented public var penaltyTracker : String?
        
        public struct Team : Codable {
            public init(totalPenalties: Int? = nil, nonSkaterExplusionCount: Int? = nil, skaters: [Penalties.Period.Team.Skater]) {
                _totalPenalties = .init(value:totalPenalties)
                _nonSkaterExplusionCount = .init(value:nonSkaterExplusionCount)
                self.skaters = skaters
            }
            
            // derived but handy
            @Commented public var totalPenalties : Int?
            @Commented public var nonSkaterExplusionCount : Int?
            
            public struct Skater : Codable {
                public init(number: String? = nil, total: Int? = nil, penalties: [Penalties.Period.Team.Skater.Penalty], foExp: Penalties.Period.Team.Skater.Penalty? = nil) {
                    _number = .init(value:number)
                    _total = .init(value:total)
                    self.penalties = penalties
                    self.foExp = foExp
                }
                                
                // Technically this is copied from IGRF
                @Commented public var number : String?
                // And this is a derived value
                @Commented public var total : Int?

                public struct Penalty : Codable {
                    public init(code: String? = nil, jam: Int? = nil) {
                        _code = .init(value:code)
                        _jam = .init(value:jam)
                    }
                    
                    @Commented public var code : String?
                    @Commented public var jam : Int?
                }
                public var penalties : [Penalty]
                public var foExp: Penalty?
            }
            
            public var skaters: [Skater]
        }
        public var home : Team
        public var away : Team
    }
    public var period1 : Period
    public var period2 : Period
}

import statsbook

extension Penalties {
    init(penalties sb: statsbook.Penalties) {
        period1 = .init(penalties: sb.period1)
        period2 = .init(penalties: sb.period2)
    }
}

extension Penalties.Period {
    init(penalties sb: statsbook.Penalties.Period) {
        _penaltyTracker = Importer(tsc: sb).penaltyTracker
        home = .init(team: sb.home)
        away = .init(team: sb.away)
    }
}

extension Penalties.Period.Team {
    init(team sb: statsbook.Penalties.Period.Team) {
        let team = Importer(tsc: sb)
        _totalPenalties = team.totalPenalties
        _nonSkaterExplusionCount = team.nonSkaterExplusionCount
        skaters = sb.skaters().map {
            .init(skater: $0)
        }
    }
}

extension Penalties.Period.Team.Skater {
    init(skater sb: statsbook.Penalties.Period.Team.Skater) {
        let skater = Importer(tsc: sb)
        _number = skater.number
        _total = skater.total
        penalties = sb.penalties.map{ .init(penalty: $0) }
    }
}

extension Penalties.Period.Team.Skater.Penalty {
    init(penalty sb: statsbook.Penalties.Period.Team.Skater.Penalty) {
        let penalty = Importer(tsc: sb)
        _jam = penalty.jam
        _code = penalty.code
    }
}
