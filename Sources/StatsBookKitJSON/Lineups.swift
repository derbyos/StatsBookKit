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
        public init(lineupTracker: String? = nil, jams: FlexArray<Lineups.TeamPeriod.Jam>) {
            _lineupTracker = .init(value:lineupTracker)
//            _date = .init(value:date)
            self.jams = jams
        }
        
        // found in the igrf
//        @Commented public var team : String?
//        @Commented public var color : String?
        @Commented public var lineupTracker : String?
//        @Commented public var date : Double?

        public struct Jam : Codable {
            public init(sp: String? = nil, jam: Int? = nil, noPivot: String? = nil, jammer: Lineups.TeamPeriod.Jam.Skater? = nil, pivot: Lineups.TeamPeriod.Jam.Skater? = nil, blocker1: Lineups.TeamPeriod.Jam.Skater? = nil, blocker2: Lineups.TeamPeriod.Jam.Skater? = nil, blocker3: Lineups.TeamPeriod.Jam.Skater? = nil) {
                _sp = .init(value:sp)
                _jam = .init(value:jam)
                _noPivot = .init(value:noPivot)
                self.jammer = jammer ?? .init()
                self.pivot = pivot ?? .init()
                self.blocker1 = blocker1 ?? .init()
                self.blocker2 = blocker2 ?? .init()
                self.blocker3 = blocker3 ?? .init()
            }
            
            @Commented public var sp : String?
            @Commented public var jam : Int?
            @Commented public var noPivot : String?
            
            public struct Skater : Codable {
                internal init(number: String? = nil, boxTrips: FlexArray<Commented<String?>>) {
                    _number = .init(value:number)
                    self.boxTrips = boxTrips
                }
                
                @Commented public var number : String?
                public var boxTrips: FlexArray<Commented<String?>>
            }
            public var jammer: Skater
            public var pivot: Skater
            public var blocker1: Skater
            public var blocker2: Skater
            public var blocker3: Skater
        }
        
        public var jams: FlexArray<Jam>
        
        public var maxJamRows : Int { Jam.maxItemCount! }


        /// Get the line that contains that jam
        public func jam(number: Int, afterSP: Bool = false) -> Jam? {
            for ji in jams.enumerated() {
                if ji.element.jam == number {
                    if afterSP {
                        if ji.offset < jams.count-1 {
                            let next = jams[ji.offset + 1]
                            if next.sp != nil {
                                return next
                            }
                        }
                        return nil
                    } else {
                        return ji.element
                    }
                }
            }
            return nil
        }

    }
}


import StatsBookKit
extension Lineups {
    init(lineups sb: StatsBookKit.Lineups) {
        homeP1 = .init(teamPeriod: sb.homeP1)
        homeP2 = .init(teamPeriod: sb.homeP2)
        awayP1 = .init(teamPeriod: sb.awayP1)
        awayP2 = .init(teamPeriod: sb.awayP2)
    }
}

extension Lineups.TeamPeriod {
    init(teamPeriod sb: StatsBookKit.Lineups.TeamPeriod) {
        _lineupTracker = Importer(tsc: sb).lineupTracker
        jams = .init(sb.jams.map{.init(jam: $0)})
    }
}

extension Lineups.TeamPeriod.Jam : FlexArrayItem {
    public static var maxItemCount: Int? {
        38
    }
    
    init(jam sb: StatsBookKit.Lineups.TeamPeriod.Jam) {
        let importer = Importer(tsc: sb)
        _sp = importer.sp
        _jam = importer.jam
        _noPivot = importer.noPivot
        jammer = .init(skater: sb.jammer)
        pivot = .init(skater: sb.pivot)
        blocker1 = .init(skater: sb.blocker1)
        blocker2 = .init(skater: sb.blocker2)
        blocker3 = .init(skater: sb.blocker3)
    }
    
    public init() {
        self.init(sp: nil, jam: nil, noPivot: nil, jammer: nil, pivot: nil, blocker1: nil, blocker2: nil, blocker3: nil)
    }
    public var isEmpty: Bool {
        _sp.isEmpty && _jam.isEmpty && _noPivot.isEmpty &&
        jammer.isEmpty && pivot.isEmpty && blocker1.isEmpty && blocker2.isEmpty && blocker3.isEmpty
    }
}


extension Lineups.TeamPeriod.Jam.Skater : FlexArrayItem {
    public init() {
        self.init(number: nil, boxTrips: [])
    }
    
    public static var maxItemCount: Int? {
        5
    }
    
    init(skater sb: StatsBookKit.Lineups.TeamPeriod.Jam.Skater) {
        let importer = Importer(tsc: sb)
        _number = importer.number
        boxTrips = .init(maxCount: 3, sb.boxTrips.map{.init(value: $0)})
    }
    
    public var isEmpty: Bool {
        _number.isEmpty && boxTrips.isEmpty
    }
}
