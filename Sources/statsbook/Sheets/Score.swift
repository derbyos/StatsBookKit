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
    
    var homeP1: TeamPeriod { .init(sheet: sheet, offset: .init(dr: 0, dc: 0))}
    var homeP2: TeamPeriod { .init(sheet: sheet, offset: .init(dr: 42, dc: 0))}
    var awayP1: TeamPeriod { .init(sheet: sheet, offset: .init(dr: 0, dc: 19))}
    var awayP2: TeamPeriod { .init(sheet: sheet, offset: .init(dr: 42, dc: 19))}

    /// All the data for a given team's period
    public struct TeamPeriod : TypedSheetCover {
        public var sheet: Sheet
        public var cellOffset: Address.Offset
        init(sheet: Sheet, offset: Address.Offset) {
            self.sheet = sheet
            self.cellOffset = offset
        }
        public struct CellDefinitions {
            var team = CellDef<String?>("A1")
            var color = CellDef<String?>("I1")
            var scorekeeper = CellDef<String?>("L1")
            var jammerRef = CellDef<String?>("O1")
            var date = CellDef<Double?>("K1")
        }
        public static var cellDefinitions: CellDefinitions = .init()
        
        /// all the data for a single row in the team period (which can be before
        /// or after a star pass)
        struct Jam : TypedSheetCover {
            var sheet: Sheet
            var cellOffset: Address.Offset
            init(sheet: Sheet, offset: Address.Offset) {
                self.sheet = sheet
                self.cellOffset = offset
            }
            struct CellDefinitions {
                var jammer = CellDef<String?>("B4")
                var lost = CellDef<String?>("C4")
                var lead = CellDef<String?>("D4")
                var call = CellDef<String?>("E4")
                var inj = CellDef<String?>("F4")
                var ni = CellDef<String?>("G4")
                // if this is a star pass, this cell will have a string
                var sp = CellDef<String?>("A4")
                // if it is not a star pass this cell will have number
                var jam = CellDef<Int?>("A4")
                var trip2 = CellDef<Int?>("H4")
                var trip3 = CellDef<Int?>("I4")
                var trip4 = CellDef<Int?>("J4")
                var trip5 = CellDef<Int?>("K4")
                var trip6 = CellDef<Int?>("L4")
                var trip7 = CellDef<Int?>("M4")
                var trip8 = CellDef<Int?>("N4")
                var trip9 = CellDef<Int?>("O4")
                var trip10 = CellDef<Int?>("P4")
                var jamTotal = CellDef<Int?>("Q4")
                var gameTotal = CellDef<Int?>("R4")
            }
            static var cellDefinitions: CellDefinitions = .init()
            // an easier way to get the the trips (starting with trip 2)
            // TODO: Figure out how to extra initial trip points
            var trips: [Int] {
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
            var afterStarPass: Jam? {
                if self[self.addressFor.sp.nextRow] == "SP" {
                    // return the next row
                    return .init(sheet: sheet, offset: cellOffset + .init(dr:1))
                }
                return nil
            }
        }
        
        /// Get the line that contains that jam
        func jam(number: Int) -> Jam? {
            var offset = 0
            for addr in (Address("A4") ... "A41") {
                if self[addr] == Double(number) {
                    return Jam(sheet: sheet, offset: cellOffset + .init(dr: offset))
                }
                offset += 1
            }
            return nil
        }
        
        /// Nearly identical to the Jam struct but shows totals
        struct Totals : TypedSheetCover {
            var sheet: Sheet
            var cellOffset: Address.Offset
            init(sheet: Sheet, offset: Address.Offset) {
                self.sheet = sheet
                self.cellOffset = offset
            }
            struct CellDefinitions {
                var jams = CellDef<Int?>("A42")
                var lost = CellDef<Int?>("C42")
                var lead = CellDef<Int?>("D42")
                var call = CellDef<Int?>("E42")
                var inj = CellDef<Int?>("F42")
                var ni = CellDef<Int?>("G42")
                var trip2 = CellDef<Int?>("H42")
                var trip3 = CellDef<Int?>("I42")
                var trip4 = CellDef<Int?>("J42")
                var trip5 = CellDef<Int?>("K42")
                var trip6 = CellDef<Int?>("L42")
                var trip7 = CellDef<Int?>("M42")
                var trip8 = CellDef<Int?>("N42")
                var trip9 = CellDef<Int?>("O42")
                var trip10 = CellDef<Int?>("P42")
                var period = CellDef<Int?>("Q42") // totals for this period
                var game = CellDef<Int?>("Q42") // totals for the game so far
            }
            static var cellDefinitions = CellDefinitions()
            /// The trip totals
            var trips: [Int] {
                // these are just the totals, so no editing, etc...
                // just grab all the non-nil numbers from these cells
                (addressFor.trip2 ... addressFor.trip10)
                    .compactMap{
                        let d: Double? = self[$0]
                        return d.flatMap({Int($0)})
                    }
            }

        }
    }
}
 
 public extension StatsBookFile {
     var score: Score {
         Score(sheet: try! sheet(named: "Score"))
     }
 }


