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
    
    public var homeP1: TeamPeriod { .init(sheet: sheet, offset: .init(dr: 0, dc: 0))}
    public var homeP2: TeamPeriod { .init(sheet: sheet, offset: .init(dr: 43, dc: 0))}
    public var awayP1: TeamPeriod { .init(sheet: sheet, offset: .init(dr: 0, dc: 26))}
    public var awayP2: TeamPeriod { .init(sheet: sheet, offset: .init(dr: 43, dc: 26))}

    /// All the data for a given team's period
    public struct TeamPeriod : TypedSheetCover {
        public var sheet: Sheet
        public var cellOffset: Address.Offset
        public init(sheet: Sheet, offset: Address.Offset) {
            self.sheet = sheet
            self.cellOffset = offset
        }
        public struct CellDefinitions {
            public var team = CellDef<String?>("A1")
            public var color = CellDef<String?>("H1")
            public var lineupTracker = CellDef<String?>("P1")
            public var date = CellDef<Double?>("L1")
        }
        public static var cellDefinitions: CellDefinitions = .init()

        /// all the data for a single row in the team period (which can be before
        /// or after a star pass)
        public struct Jam : TypedSheetCover {
            public var sheet: Sheet
            public var cellOffset: Address.Offset
            public init(sheet: Sheet, offset: Address.Offset) {
                self.sheet = sheet
                self.cellOffset = offset
            }
            public struct CellDefinitions {
                // if this is a star pass, this cell will have a string
                public var sp = CellDef<String?>("A4")
                // if it is not a star pass this cell will have number
                public var jam = CellDef<Int?>("A4")
                
                public var noPivot = CellDef<String?>("B4")
            }
            public static var cellDefinitions: CellDefinitions = .init()
            /// If this team had a star pass, return the "jam" after the star pass
            public var afterStarPass: Jam? {
                if self[self.addressFor.sp.nextRow] == "SP" {
                    // return the next row
                    return .init(sheet: sheet, offset: cellOffset + .init(dr:1))
                }
                return nil
            }

            public struct Skater : TypedSheetCover {
                public var sheet: Sheet
                public var cellOffset: Address.Offset
                public init(sheet: Sheet, offset: Address.Offset) {
                    self.sheet = sheet
                    self.cellOffset = offset
                }
                public struct CellDefinitions {
                    public var number = CellDef<String?>("C4")
                    public var box1 = CellDef<String?>("D4")
                    public var box2 = CellDef<String?>("E4")
                    public var box3 = CellDef<String?>("F4")
                }
                public static var cellDefinitions: CellDefinitions = .init()

                public var boxTrips : [String] {
                    [self.box1,self.box2,self.box3].compactMap({$0})
                }
            }
            /// The position in the lineup
            public enum Position : Address, Hashable, CaseIterable {
                case jammer = "C4"
                case pivot = "G4"
                case blocker1 = "K4"
                case blocker2 = "O4"
                case blocker3 = "S4"
                var offset: Address.Offset {
                    self.rawValue - Position.jammer.rawValue
                }
            }
            public var jammer: Skater {
                .init(sheet: sheet, offset: cellOffset + Position.jammer.offset)
            }
            public var pivot: Skater {
                .init(sheet: sheet, offset: cellOffset + Position.pivot.offset)
            }
            public var blocker1: Skater {
                .init(sheet: sheet, offset: cellOffset + Position.blocker1.offset)
            }
            public var blocker2: Skater {
                .init(sheet: sheet, offset: cellOffset + Position.blocker2.offset)
            }
            public var blocker3: Skater {
                .init(sheet: sheet, offset: cellOffset + Position.blocker3.offset)
            }
            /// A map of the skaters by position
            public var skaters:[Position: Skater] {
                .init(uniqueKeysWithValues: Position.allCases.map {
                    ($0, .init(sheet: sheet, offset: cellOffset + ($0.offset)))
                })
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

        /// All (valid) jam lines
        public var jams : [Jam] {
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

    }
}

public extension StatsBookFile {
    var lineups: Lineups {
        Lineups(sheet: try! sheet(named: "Lineups"))
    }
}


