//
//  File.swift
//  
//
//  Created by gandreas on 8/26/23.
//

import Foundation
import statsbook

public struct Score: Codable {
    public var homeP1: TeamPeriod
    public var homeP2: TeamPeriod
    public var awayP1: TeamPeriod
    public var awayP2: TeamPeriod

    /// All the data for a given team's period
    public struct TeamPeriod : Codable {
        public init(scorekeeper: String? = nil, jammerRef: String? = nil, jams: [Score.TeamPeriod.Jam], totals: Score.TeamPeriod.Totals) {
            _scorekeeper = .init(value: scorekeeper)
            _jammerRef = .init(value: jammerRef)
            self.jams = jams
            self.totals = totals
        }
        
        // derived from IGRF
//        var team : String?
//        var color : String?
        @Commented public var scorekeeper : String?
        @Commented public var jammerRef : String?
        // derived from IGRF
//        var date : Double?
        
        /// all the data for a single row in the team period (which can be before
        /// or after a star pass).  Note that this isn't actually jam, rather a part of
        /// a jam, because of course, star passes
        public struct Jam : Codable {
            public init(jammer: String? = nil, lost: String? = nil, lead: String? = nil, call: String? = nil, inj: String? = nil, ni: String? = nil, sp: String? = nil, jam: Int? = nil, trip2: Int? = nil, trip3: Int? = nil, trip4: Int? = nil, trip5: Int? = nil, trip6: Int? = nil, trip7: Int? = nil, trip8: Int? = nil, trip9: Int? = nil, trip10: Int? = nil, jamTotal: Int? = nil, gameTotal: Int? = nil, trips: [Int]) {
                _jammer = .init(value:jammer)
                _lost = .init(value:lost)
                _lead = .init(value:lead)
                _call = .init(value:call)
                _inj = .init(value:inj)
                _ni = .init(value:ni)
                _sp = .init(value:sp)
                _jam = .init(value:jam)
                _trip2 = .init(value:trip2)
                _trip3 = .init(value:trip3)
                _trip4 = .init(value:trip4)
                _trip5 = .init(value:trip5)
                _trip6 = .init(value:trip6)
                _trip7 = .init(value:trip7)
                _trip8 = .init(value:trip8)
                _trip9 = .init(value:trip9)
                _trip10 = .init(value:trip10)
                _jamTotal = .init(value:jamTotal)
                _gameTotal = .init(value:gameTotal)
                self.trips = trips
            }
            
            @Commented public var jammer : String?
            @Commented public var lost : String?
            @Commented public var lead : String?
            @Commented public var call : String?
            @Commented public var inj : String?
            @Commented public var ni : String?
            // if this is a star pass, this cell will have a string
            @Commented public var sp : String?
            // if it is not a star pass this cell will have number
            @Commented  public var jam : Int?
            @Commented  public var trip2 : Int?
            @Commented  public var trip3 : Int?
            @Commented  public var trip4 : Int?
            @Commented  public var trip5 : Int?
            @Commented  public var trip6 : Int?
            @Commented  public var trip7 : Int?
            @Commented  public var trip8 : Int?
            @Commented  public var trip9 : Int?
            @Commented  public var trip10 : Int?
            @Commented  public var jamTotal : Int?
            @Commented  public var gameTotal : Int?
            
            public var trips: [Int]
        }
        
        public var jams: [Jam]
        
        public struct Totals : Codable {
            public init(jams: Int? = nil, lost: Int? = nil, lead: Int? = nil, call: Int? = nil, inj: Int? = nil, ni: Int? = nil, trip2: Int? = nil, trip3: Int? = nil, trip4: Int? = nil, trip5: Int? = nil, trip6: Int? = nil, trip7: Int? = nil, trip8: Int? = nil, trip9: Int? = nil, trip10: Int? = nil, period: Int? = nil, game: Int? = nil) {
                _jams = .init(value: jams)
                _lost = .init(value: lost)
                _lead = .init(value: lead)
                _call = .init(value: call)
                _inj = .init(value: inj)
                _ni = .init(value: ni)
                _trip2 = .init(value: trip2)
                _trip3 = .init(value: trip3)
                _trip4 = .init(value: trip4)
                _trip5 = .init(value: trip5)
                _trip6 = .init(value: trip6)
                _trip7 = .init(value: trip7)
                _trip8 = .init(value: trip8)
                _trip9 = .init(value: trip9)
                _trip10 = .init(value: trip10)
                _period = .init(value: period)
                _game = .init(value: game)
            }
            
            @Commented public var jams : Int?
            @Commented public var lost : Int?
            @Commented public var lead : Int?
            @Commented public var call : Int?
            @Commented public var inj : Int?
            @Commented public var ni : Int?
            @Commented public var trip2 : Int?
            @Commented public var trip3 : Int?
            @Commented public var trip4 : Int?
            @Commented public var trip5 : Int?
            @Commented public var trip6 : Int?
            @Commented public var trip7 : Int?
            @Commented public var trip8 : Int?
            @Commented public var trip9 : Int?
            @Commented public var trip10 : Int?
            // derived but useful
            @Commented public var period : Int? // totals for this period
            // derived but useful
            @Commented public var game : Int? // totals for the game so far
            var trips: [Int] {
                [trip2, trip3, trip4, trip5, trip6, trip7, trip8, trip9, trip10].compactMap({$0})
            }
        }
        
        public var totals: Totals
    }
}

extension Score {
    init(score sb: statsbook.Score) {
        homeP1 = .init(score: sb.homeP1)
        homeP2 = .init(score: sb.homeP2)
        awayP1 = .init(score: sb.awayP1)
        awayP2 = .init(score: sb.awayP2)
    }
}
extension Score.TeamPeriod {
    init(score sb: statsbook.Score.TeamPeriod) {
        let score = Importer(tsc: sb)
//        _team = score.team
//        _color = score.color
        _scorekeeper = score.scorekeeper
        _jammerRef = score.jammerRef
//        _date = score.date
        jams = sb.allJams.map {
            .init(jam: $0)
        }
        totals = .init(totals: sb.totals)
    }
}

extension Score.TeamPeriod.Jam {
    init(jam sb: statsbook.Score.TeamPeriod.Jam) {
        let jam = Importer(tsc: sb)
        _jammer = jam.jammer
        _lost = jam.lost
        _lead = jam.lead
        _call = jam.call
        _inj = jam.inj
        _ni = jam.ni
        _sp = jam.sp
        _jam = jam.jam
        _trip2 = jam.trip2
        _trip3 = jam.trip3
        _trip4 = jam.trip4
        _trip5 = jam.trip5
        _trip6 = jam.trip6
        _trip7 = jam.trip7
        _trip8 = jam.trip8
        _trip9 = jam.trip9
        _trip10 = jam.trip10
        _jamTotal = jam.jamTotal
        _gameTotal = jam.gameTotal
        trips = sb.trips
    }

}
extension Score.TeamPeriod.Totals {
    init(totals sb: statsbook.Score.TeamPeriod.Totals) {
        let totals = Importer(tsc: sb)
        _jams = totals.jams
        _lost = totals.lost
        _lead = totals.lead
        _call = totals.call
        _inj = totals.inj
        _ni = totals.ni
        _trip2 = totals.trip2
        _trip3 = totals.trip3
        _trip4 = totals.trip4
        _trip5 = totals.trip5
        _trip6 = totals.trip6
        _trip7 = totals.trip7
        _trip8 = totals.trip8
        _trip9 = totals.trip9
        _trip10 = totals.trip10
        _period = totals.period
        _game = totals.game
    }
}
