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
            public init(totalPenalties: Int? = nil, notSkaterExplusionCount: Int? = nil, skaters: [Penalties.Period.Team.Skater]) {
                _totalPenalties = .init(value:totalPenalties)
                _notSkaterExplusionCount = .init(value:notSkaterExplusionCount)
                self.skaters = skaters
            }
            
            // derived but handy
            @Commented public var totalPenalties : Int?
            @Commented public var notSkaterExplusionCount : Int?
            
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
