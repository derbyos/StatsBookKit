//
//  File.swift
//  
//
//  Created by gandreas on 8/26/23.
//

import Foundation

public struct Lineups {
    var sheet: Sheet
    init(sheet: Sheet) {
        self.sheet = sheet
    }
    
    var homeP1: TeamPeriod { .init(sheet: sheet, offset: .init(dr: 0, dc: 0))}
    var homeP2: TeamPeriod { .init(sheet: sheet, offset: .init(dr: 43, dc: 0))}
    var awayP1: TeamPeriod { .init(sheet: sheet, offset: .init(dr: 0, dc: 26))}
    var awayP2: TeamPeriod { .init(sheet: sheet, offset: .init(dr: 43, dc: 26))}

    /// All the data for a given team's period
    public struct TeamPeriod : TypedSheetCover {
        var sheet: Sheet
        var cellOffset: Address.Offset
        init(sheet: Sheet, offset: Address.Offset) {
            self.sheet = sheet
            self.cellOffset = offset
        }
        struct CellDefinitions {
            var team = CellDef<String?>("A1")
            var color = CellDef<String?>("H1")
            var lineupTracker = CellDef<String?>("P1")
            var date = CellDef<Double?>("L1")
        }
        static var cellDefinitions: CellDefinitions = .init()

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
                // if this is a star pass, this cell will have a string
                var sp = CellDef<String?>("A4")
                // if it is not a star pass this cell will have number
                var jam = CellDef<Int?>("A4")
                
                var noPivot = CellDef<String?>("B4")
            }
            static var cellDefinitions: CellDefinitions = .init()
            /// If this team had a star pass, return the "jam" after the star pass
            var afterStarPass: Jam? {
                if self[self.addressFor.sp.nextRow] == "SP" {
                    // return the next row
                    return .init(sheet: sheet, offset: cellOffset + .init(dr:1))
                }
                return nil
            }

            struct Skater : TypedSheetCover {
                var sheet: Sheet
                var cellOffset: Address.Offset
                init(sheet: Sheet, offset: Address.Offset) {
                    self.sheet = sheet
                    self.cellOffset = offset
                }
                struct CellDefinitions {
                    var number = CellDef<String?>("C4")
                    var box1 = CellDef<String?>("D4")
                    var box2 = CellDef<String?>("E4")
                    var box3 = CellDef<String?>("F4")
                }
                static var cellDefinitions: CellDefinitions = .init()

                var boxTrips : [String] {
                    [self.box1,self.box2,self.box3].compactMap({$0})
                }
            }
            /// The position in the lineup
            enum Position : Address, Hashable, CaseIterable {
                case jammer = "C4"
                case pivot = "G4"
                case blocker1 = "K4"
                case blocker2 = "O4"
                case blocker3 = "S4"
                var offset: Address.Offset {
                    self.rawValue - Position.jammer.rawValue
                }
            }
            var jammer: Skater {
                .init(sheet: sheet, offset: cellOffset + Position.jammer.offset)
            }
            var pivot: Skater {
                .init(sheet: sheet, offset: cellOffset + Position.pivot.offset)
            }
            var blocker1: Skater {
                .init(sheet: sheet, offset: cellOffset + Position.blocker1.offset)
            }
            var blocker2: Skater {
                .init(sheet: sheet, offset: cellOffset + Position.blocker2.offset)
            }
            var blocker3: Skater {
                .init(sheet: sheet, offset: cellOffset + Position.blocker3.offset)
            }
            /// A map of the skaters by position
            var skaters:[Position: Skater] {
                .init(uniqueKeysWithValues: Position.allCases.map {
                    ($0, .init(sheet: sheet, offset: cellOffset + ($0.offset)))
                })
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

    }
}

public extension StatsBookFile {
    var lineups: Lineups {
        Lineups(sheet: try! sheet(named: "Lineups"))
    }
}


