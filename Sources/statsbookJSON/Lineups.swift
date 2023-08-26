//
//  File.swift
//  
//
//  Created by gandreas on 8/26/23.
//

import Foundation

public struct Lineups : Codable {
    public init(homeP1: Lineups.TeamPeriod, homeP2: Lineups.TeamPeriod, awayP1: Lineups.TeamPeriod, awayP2: Lineups.TeamPeriod) {
        self.homeP1 = homeP1
        self.homeP2 = homeP2
        self.awayP1 = awayP1
        self.awayP2 = awayP2
    }
    
    public var homeP1: TeamPeriod
    public var homeP2: TeamPeriod
    public var awayP1: TeamPeriod
    public var awayP2: TeamPeriod
    
    public struct TeamPeriod : Codable {
        public init(lineupTracker: String? = nil, date: Double? = nil, jams: [Lineups.TeamPeriod.Jam]) {
            _lineupTracker = .init(value:lineupTracker)
            _date = .init(value:date)
            self.jams = jams
        }
        
        // found in the igrf
//        @Commented public var team : String?
//        @Commented public var color : String?
        @Commented public var lineupTracker : String?
        @Commented public var date : Double?

        public struct Jam : Codable {
            public init(sp: String? = nil, jam: Int? = nil, noPivot: String? = nil, jammer: Lineups.TeamPeriod.Jam.Skater? = nil, pivot: Lineups.TeamPeriod.Jam.Skater? = nil, blocker1: Lineups.TeamPeriod.Jam.Skater? = nil, blocker2: Lineups.TeamPeriod.Jam.Skater? = nil, blocker3: Lineups.TeamPeriod.Jam.Skater? = nil) {
                _sp = .init(value:sp)
                _jam = .init(value:jam)
                _noPivot = .init(value:noPivot)
                self.jammer = jammer
                self.pivot = pivot
                self.blocker1 = blocker1
                self.blocker2 = blocker2
                self.blocker3 = blocker3
            }
            
            @Commented public var sp : String?
            @Commented public var jam : Int?
            @Commented public var noPivot : String?
            
            public struct Skater : Codable {
                internal init(number: String? = nil, box: [String]) {
                    _number = .init(value:number)
                    self.box = box
                }
                
                @Commented public var number : String?
                public var box: [String]
            }
            public var jammer: Skater?
            public var pivot: Skater?
            public var blocker1: Skater?
            public var blocker2: Skater?
            public var blocker3: Skater?
        }
        
        public var jams: [Jam]
    }
}
