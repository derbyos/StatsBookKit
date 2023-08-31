//
//  File.swift
//  
//
//  Created by gandreas on 8/26/23.
//

import Foundation
import StatsBookKit

public struct IGRF: Codable {
    public init(venueName: String? = nil, city: String? = nil, state: String? = nil, gameNumber: String? = nil, tournament: String? = nil, hostLeague: String? = nil, date: String? = nil, time: String? = nil, suspension: Bool? = false, home: IGRF.Team = .init(), away: IGRF.Team = .init(), officials: [IGRF.Official] = [], requiredOS: Bool? = nil, reasonForOS: String? = nil, signatures: Signatures = .init(), suspensionServedBy: String? = nil, expulsions: FlexArray<IGRF.Explusion> = []) {
        _venueName = .init(value: venueName)
        _city = .init(value: city)
        _state = .init(value: state)
        _gameNumber = .init(value: gameNumber)
        _tournament = .init(value: tournament)
        _hostLeague = .init(value: hostLeague)
        _date = .init(value: date)
        _time = .init(value: time)
        _suspension = .init(value: suspension)
        _suspensionServedBy = .init(value: suspensionServedBy)
        _requiredOS = .init(value: requiredOS)
        _reasonForOS = .init(value: reasonForOS)
        self.home = home
        self.away = away
        self.officials = officials
        self.signatures = signatures
        self.expulsions = expulsions
    }
    
    
    @Commented public var venueName: String?
    @Commented public var city: String?
    @Commented public var state: String?
    @Commented public var gameNumber: String?
    @Commented public var tournament: String?
    @Commented public var hostLeague: String?
    @Commented public var date: String?
    @Commented public var time: String?
    
    @Commented public var suspension: Bool?
    
    public struct Team: Codable {
        public init(league: String? = nil, team: String? = nil, color: String? = nil, period1Points: Int? = nil, period2Points: Int? = nil, totalPoints: Int? = nil, period1Penalties: Int? = nil, period2Penalties: Int? = nil, totalPenalties: Int? = nil, skaters: [IGRF.Team.Skater] = []) {
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
        
        // These are derived values for convenience only
        @Commented public var period1Points : Int?
        @Commented public var period2Points : Int?
        @Commented public var totalPoints : Int?
        @Commented public var period1Penalties : Int?
        @Commented public var period2Penalties : Int?
        @Commented public var totalPenalties : Int?
        
        public struct Skater: Codable {
            public init(number: String? = nil, name: String? = nil) {
                _number = .init(value:number)
                _name = .init(value:name)
            }
            
            @Commented public var number: String?
            @Commented public var name: String?
        }
        public var skaters: [Skater]
    }
    public struct Official: Codable {
        public init(role: String? = nil, name: String? = nil, league: String? = nil, cert: String? = nil) {
            _role = .init(value:role)
            _name = .init(value:name)
            _league = .init(value:league)
            _cert = .init(value:cert)
        }
        
        @Commented public var role: String?
        @Commented public var name: String?
        @Commented public var league: String?
        @Commented public var cert: String?
    }
    
    public struct Signature: Codable {
        public init(skateName: String? = nil, legalName: String? = nil, signature: Data? = nil) {
            _skateName = .init(value:skateName)
            _legalName = .init(value:legalName)
            _signature = .init(value:signature)
        }
        
        @Commented public var skateName: String?
        @Commented public var legalName: String?
        @Commented public var signature: Data? // as a PNG or other image format
    }
    public struct Signatures: Codable {
        public init(homeTeamCaptain: IGRF.Signature = .init(), awayTeamCaptain: IGRF.Signature = .init(), headReferee: IGRF.Signature = .init(), headNSO: IGRF.Signature = .init()) {
            self.homeTeamCaptain = homeTeamCaptain
            self.awayTeamCaptain = awayTeamCaptain
            self.headReferee = headReferee
            self.headNSO = headNSO
        }
        
        public var homeTeamCaptain: Signature
        public var awayTeamCaptain: Signature
        public var headReferee: Signature
        public var headNSO: Signature
    }
    public var home: Team
    public var away: Team
    public var officials: [Official] = []
    public var signatures: Signatures
    @Commented public var requiredOS: Bool?
    @Commented public var reasonForOS: String?
    public struct Explusion: Codable, FlexArrayItem {
        public init() {
            self.init(expulsion: nil, suspension: nil)
        }
        
        public init(expulsion: String? = nil, suspension: Bool? = nil) {
            _expulsion = .init(value:expulsion)
            _suspension = .init(value:suspension)
        }
        public var isEmpty: Bool { _expulsion.isEmpty && _suspension.isEmpty }
        // IGRF has space for 3 expulsion lines
        static public var maxItemCount: Int? { 3 }
        @Commented public var expulsion: String?
        @Commented public var suspension: Bool?
    }
    @Commented public var suspensionServedBy: String?
    
    public var expulsions : FlexArray<Explusion>
}

/// Sad that this extension has to be here (and not in importer) but `_foo` is private
/// and can only be accessed by extensions in this file
extension IGRF {
    init(igrf sb: StatsBookKit.IGRF) {
        let igrf = Importer(tsc: sb)
        _venueName = igrf.venueName
        _city = igrf.city
        _state = igrf.state
        _gameNumber = igrf.gameNumber
        _tournament = igrf.tournament
        _hostLeague = igrf.hostLeague
        _date = igrf.date
        _time = igrf.time
        _suspension = igrf.suspension
        _requiredOS = igrf.requiredOS
        _reasonForOS = igrf.reasonForOS
        _suspensionServedBy = igrf.suspensionServedBy
        home = .init(team: sb.home, penalties: sb.homePenalties, points: sb.homePoints)
        away = .init(team: sb.away, penalties: sb.awayPenalties, points: sb.awayPoints)
        // generate all officials, including blank rows
        officials = (1...sb.maxOfficials).map({.init(official: sb.official(index: $0))})
        expulsions = .init((1...sb.maxOfficials).map({.init(expulsion: sb.expulsion(index: $0))}))
        signatures = .init(signatures: sb.signatures)
    }
}

extension IGRF.Official {
    init(official sb: StatsBookKit.IGRF.Official) {
        let official = Importer(tsc: sb)
        _role = official.role
        _name = official.name
        _league = official.league
        _cert = official.cert
    }
}
extension IGRF.Explusion {
    init(expulsion sb: StatsBookKit.IGRF.Expulsion) {
        let explusion = Importer(tsc: sb)
        _expulsion = explusion.expulsion
        _suspension = explusion.suspension
    }
}

extension IGRF.Signature {
    init(signature sb: StatsBookKit.IGRF.Signatures.Signature) {
        let signature = Importer(tsc: sb)
        _signature = .init(value: nil) // we don't have images yet
        _legalName = signature.legalName
        _skateName = signature.skateName
    }
}

extension IGRF.Signatures {
    init(signatures: StatsBookKit.IGRF.Signatures) {
        homeTeamCaptain = .init(signature: signatures.homeTeamCaptain)
        awayTeamCaptain = .init(signature: signatures.awayTeamCaptain)
        headReferee = .init(signature: signatures.headReferee)
        headNSO = .init(signature: signatures.headNSO)
    }
}

extension IGRF.Team {
    init(team sb: StatsBookKit.IGRF.Team, penalties: StatsBookKit.IGRF.PenaltyTotals, points:StatsBookKit.IGRF.PointTotals) {
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
    init(skater sb: StatsBookKit.IGRF.Team.Skater) {
        let skater = Importer(tsc: sb)
        _number = skater.number
        _name = skater.name
    }
}
