//
//  File.swift
//  
//
//  Created by gandreas on 8/22/23.
//

import Foundation


/// A wrapper around the IGRF
public struct IGRF : TypedSheetCover {
    
    public var sheet: Sheet
    
    public init(sheet: Sheet) {
        self.sheet = sheet
//        _venueName = .init(sheet: sheet, row: 3, col: "B")
    }

    public struct CellDefinitions {
        public var venueName = CellDef<String?>("B3")
        public var city = CellDef<String?>("I3")
        public var state = CellDef<String?>("K3")
        public var gameNumber = CellDef<String?>("L3")
        public var tournament = CellDef<String?>("B5")
        public var hostLeague = CellDef<String?>("I5")
        public var date = CellDef<String?>("B7")
        public var time = CellDef<String?>("I7")
        public var suspension = CellDef<Bool?>("L7")
        public var suspensionServedBy = CellDef<String?>("F40")
        public var requiredOS = CellDef<Bool?>("D39")
        public var reasonForOS = CellDef<String?>("I39")
    }
    
    public static var cellDefinitions: CellDefinitions = .init()


    public struct Team : TypedSheetCover {
        public var cellOffset: Address.Offset
        public var sheet: Sheet
        init(sheet: Sheet, offset: Address.Offset) {
            self.sheet = sheet
            self.cellOffset = offset
        }
        
        
        public struct CellDefinitions {
            public var league = CellDef<String?>("B10")
            public var team = CellDef<String?>("B11")
            public var color = CellDef<String?>("B12")
        }
        
        public static var cellDefinitions: CellDefinitions = .init()

        public struct Skater : TypedSheetCover {
            public var cellOffset: Address.Offset
            public var sheet: Sheet
            init(sheet: Sheet, offset: Address.Offset) {
                self.sheet = sheet
                self.cellOffset = offset
            }
            
            public struct CellDefinitions {
                public var number = CellDef<String?>("B14")
                public var name = CellDef<String?>("C14")
            }
            public static var cellDefinitions: CellDefinitions = .init()

        }
        // The maximum number of skaters
        public let maxSkaters: Int = 20
        /// Get the skater by index
        /// - Parameter index: The one base index of the skater
        /// - Returns: The skater record
        public func skater(index: Int) -> Skater {
            // form a skater based on offset adding the index
            .init(sheet: sheet, offset: .init(dr: self.cellOffset.dr + index - 1, dc: self.cellOffset.dc))
        }
    }
    public var home: Team {
        .init(sheet: sheet, offset: .zero)
    }
    public var away: Team {
        // move 7 columns to the right
        .init(sheet: sheet, offset: .init(dc: 7))
    }
    
    // unforutnately, the offset for totals isn't uniform - the difference
    // between penalties is 7 but the difference between points is 6
    public struct PenaltyTotals : TypedSheetCover {
        public var cellOffset: Address.Offset
        public var sheet: Sheet
        init(sheet: Sheet, offset: Address.Offset) {
            self.sheet = sheet
            self.cellOffset = offset
        }
        
        
        public struct CellDefinitions {
            public var period1 = CellDef<Int?>("F36")
            public var period2 = CellDef<Int?>("F37")
            public var total = CellDef<Int?>("F38")        }
        public static var cellDefinitions: CellDefinitions = .init()
    }

    public struct PointTotals : TypedSheetCover {
        public var cellOffset: Address.Offset
        public var sheet: Sheet
        init(sheet: Sheet, offset: Address.Offset) {
            self.sheet = sheet
            self.cellOffset = offset
        }
        
        
        public struct CellDefinitions {
            public var period1 = CellDef<Int?>("C36")
            public var period2 = CellDef<Int?>("C37")
            public var total = CellDef<Int?>("C38")
        }
        public static var cellDefinitions: CellDefinitions = .init()
    }
    public var homePenalties: PenaltyTotals {
        .init(sheet: sheet, offset: .zero)
    }
    public var awayPenalties: PenaltyTotals {
        // move 6 columns to the right
        .init(sheet: sheet, offset: .init(dc: 6))
    }
    public var homePoints: PointTotals {
        .init(sheet: sheet, offset: .zero)
    }
    public var awayPoints: PointTotals {
        // move 7 columns to the right
        .init(sheet: sheet, offset: .init(dc: 7))
    }
    
    public struct Official : TypedSheetCover {
        public var cellOffset: Address.Offset
        public var sheet: Sheet
        init(sheet: Sheet, offset: Address.Offset) {
            self.sheet = sheet
            self.cellOffset = offset
        }
        public struct CellDefinitions {
            public var role = CellDef<String?>("A60")
            public var name = CellDef<String?>("C60")
            public var league = CellDef<String?>("H60")
            public var cert = CellDef<String?>("K60")
        }
        public static var cellDefinitions: CellDefinitions = .init()
    }
    
    // The maximum number of officials
    public let maxOfficials: Int = 28
    /// Get the official by index
    /// - Parameter index: The one base index of the skater
    /// - Returns: The official record
    public func official(index: Int) -> Official {
        // form a skater based on offset adding the index
        .init(sheet: sheet, offset: .init(dr: index - 1))
    }

    public struct Expulsion : TypedSheetCover {
        public var cellOffset: Address.Offset
        public var sheet: Sheet
        init(sheet: Sheet, offset: Address.Offset) {
            self.sheet = sheet
            self.cellOffset = offset
        }
        public struct CellDefinitions {
            public var expulsion = CellDef<String?>("A41")
            public var suspension = CellDef<Bool?>("L41")
        }
        public static var cellDefinitions: CellDefinitions = .init()
    }
    // The maximum number of officials
    public let maxExpulsions: Int = 3
    /// Get the expulsion by index
    /// - Parameter index: The one base index of the explusion
    /// - Returns: The expulsion record
    public func expulsion(index: Int) -> Expulsion {
        // form a skater based on offset adding the index
        .init(sheet: sheet, offset: .init(dr: index - 1))
    }

    public struct Signatures : TypedSheetCover {
        public struct Signature : TypedSheetCover {
            public var cellOffset: Address.Offset
            public var sheet: Sheet
            init(sheet: Sheet, offset: Address.Offset) {
                self.sheet = sheet
                self.cellOffset = offset
            }
            public struct CellDefinitions {
                public var skateName = CellDef<String?>("B49")
                public var legalName = CellDef<String?>("B50")
                public var signature = CellDef<String?>("B51")
            }
            public static var cellDefinitions: CellDefinitions = .init()
        }
        public var cellOffset: Address.Offset
        public var sheet: Sheet
        init(sheet: Sheet, offset: Address.Offset) {
            self.sheet = sheet
            self.cellOffset = offset
        }
        public struct CellDefinitions {
        }
        public static var cellDefinitions: CellDefinitions = .init()
        
        public var homeTeamCaptain: Signature { .init(sheet: sheet, offset: .zero)}
        public var awayTeamCaptain: Signature { .init(sheet: sheet, offset: .init(dc:6))}
        public var headReferee: Signature { .init(sheet: sheet, offset: .init(dr:4))}
        public var headNSO: Signature { .init(sheet: sheet, offset: .init(dr:4, dc:6))}
    }
    public var signatures: Signatures {
        .init(sheet: sheet, offset: .zero)
    }
}


public extension StatsBookFile {
    var igrf: IGRF {
        IGRF(sheet: try! sheet(named: "IGRF"))
    }
}
