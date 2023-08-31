//
//  File.swift
//  
//
//  Created by gandreas on 8/26/23.
//

import Foundation

public struct Score {
    var sheet: Sheet
    init(sheet: Sheet) {
        self.sheet = sheet
    }
    
    public var homeP1: TeamPeriod { .init(sheet: sheet, offset: .init(dr: 0, dc: 0))}
    public var homeP2: TeamPeriod { .init(sheet: sheet, offset: .init(dr: 42, dc: 0))}
    public var awayP1: TeamPeriod { .init(sheet: sheet, offset: .init(dr: 0, dc: 19))}
    public var awayP2: TeamPeriod { .init(sheet: sheet, offset: .init(dr: 42, dc: 19))}

    /// All the data for a given team's period
    public struct TeamPeriod : TypedSheetCover {
        public var sheet: Sheet
        public var cellOffset: Address.Offset
        init(sheet: Sheet, offset: Address.Offset) {
            self.sheet = sheet
            self.cellOffset = offset
        }
        public struct CellDefinitions {
            public var team = CellDef<String?>("A1")
            public var color = CellDef<String?>("I1")
            public var scorekeeper = CellDef<String?>("L1")
            public var jammerRef = CellDef<String?>("O1")
            public var date = CellDef<Double?>("K1")
        }
        public static var cellDefinitions: CellDefinitions = .init()
        
        /// all the data for a single row in the team period (which can be before
        /// or after a star pass)
        public struct Jam : TypedSheetCover {
            public var sheet: Sheet
            public var cellOffset: Address.Offset
            init(sheet: Sheet, offset: Address.Offset) {
                self.sheet = sheet
                self.cellOffset = offset
            }
            public struct CellDefinitions {
                public var jammer = CellDef<String?>("B4")
                public var lost = CellDef<String?>("C4")
                public var lead = CellDef<String?>("D4")
                public var call = CellDef<String?>("E4")
                public var inj = CellDef<String?>("F4")
                public var ni = CellDef<String?>("G4")
                // if this is a star pass, this cell will have a string
                public var sp = CellDef<String?>("A4")
                // if it is not a star pass this cell will have number
                public var jam = CellDef<Int?>("A4")
                public var trip2 = CellDef<Int?>("H4")
                public var trip3 = CellDef<Int?>("I4")
                public var trip4 = CellDef<Int?>("J4")
                public var trip5 = CellDef<Int?>("K4")
                public var trip6 = CellDef<Int?>("L4")
                public var trip7 = CellDef<Int?>("M4")
                public var trip8 = CellDef<Int?>("N4")
                public var trip9 = CellDef<Int?>("O4")
                public var trip10 = CellDef<Int?>("P4")
                public var jamTotal = CellDef<Int?>("Q4")
                public var gameTotal = CellDef<Int?>("R4")
            }
            public static var cellDefinitions: CellDefinitions = .init()
            // an easier way to get the the trips (starting with trip 2)
            // TODO: Figure out how to extra initial trip points
            public var trips: [Int] {
                get {
                    // just grab all the non-nil numbers from these cells
                    (addressFor.trip2 ... addressFor.trip10)
                        .compactMap{
                            let d: Double? = self[$0]
                            return d.flatMap({Int($0)})
                        }
                }
                set {
                    // TODO: Replace extra trips with formula
                    assert(newValue.count < 10, "Too many trips to fit in the cells")
                    for i in zip(addressFor.trip2 ... addressFor.trip10, newValue) {
                        self[i.0] = Double(i.1)
                    }
                }
            }
            
            /// If this team had a star pass, return the "jam" after the star pass
            public var afterStarPass: Jam? {
                if self[self.addressFor.sp.nextRow] == "SP" {
                    // return the next row
                    return .init(sheet: sheet, offset: cellOffset + .init(dr:1))
                }
                return nil
            }
        }
        
        public var maxJamRows : Int { 38 }
        public subscript(jamRow index: Int) -> Jam {
            return Jam(sheet: sheet, offset: cellOffset + .init(dr: index))
        }
        
        /// Get the line that contains that jam
        public func jam(number: Int) -> Jam? {
            var offset = 0
            for addr in (Address("A4") ... "A41") {
                if self[addr] == Double(number) {
                    return Jam(sheet: sheet, offset: cellOffset + .init(dr: offset))
                }
                offset += 1
            }
            return nil
        }
        
        public var allJams : [Jam] {
            var retval = [Jam]()
            var offset = 0
            for addr in (Address("A4") ... "A41") {
                // if something is in either of the first to columns, use it
                if self[addr] != Optional<Double>.none || self[addr] != Optional<String>.none || self[addr + .init(dc: 1)] != Optional<Double>.none || self[addr + .init(dc: 1)] != Optional<String>.none {
                    retval.append(Jam(sheet: sheet, offset: cellOffset + .init(dr: offset)))
                }
                offset += 1
            }
            return retval

        }
        
        /// Nearly identical to the Jam struct but shows totals
        public struct Totals : TypedSheetCover {
            public var sheet: Sheet
            public var cellOffset: Address.Offset
            init(sheet: Sheet, offset: Address.Offset) {
                self.sheet = sheet
                self.cellOffset = offset
            }
            public struct CellDefinitions {
                public var jams = CellDef<Int?>("A42")
                public var lost = CellDef<Int?>("C42")
                public var lead = CellDef<Int?>("D42")
                public var call = CellDef<Int?>("E42")
                public var inj = CellDef<Int?>("F42")
                public var ni = CellDef<Int?>("G42")
                public var trip2 = CellDef<Int?>("H42")
                public var trip3 = CellDef<Int?>("I42")
                public var trip4 = CellDef<Int?>("J42")
                public var trip5 = CellDef<Int?>("K42")
                public var trip6 = CellDef<Int?>("L42")
                public var trip7 = CellDef<Int?>("M42")
                public var trip8 = CellDef<Int?>("N42")
                public var trip9 = CellDef<Int?>("O42")
                public var trip10 = CellDef<Int?>("P42")
                public var period = CellDef<Int?>("Q42") // totals for this period
                public var game = CellDef<Int?>("Q42") // totals for the game so far
            }
            public static var cellDefinitions = CellDefinitions()
            /// The trip totals
            public var trips: [Int] {
                // these are just the totals, so no editing, etc...
                // just grab all the non-nil numbers from these cells
                (addressFor.trip2 ... addressFor.trip10)
                    .compactMap{
                        let d: Double? = self[$0]
                        return d.flatMap({Int($0)})
                    }
            }

        }
        public var totals : Totals { .init(sheet: sheet, offset: cellOffset) }
    }
}
 
 public extension StatsBookFile {
     var score: Score {
         Score(sheet: try! sheet(named: "Score"))
     }
 }


