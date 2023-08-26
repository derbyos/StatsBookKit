//
//  File.swift
//  
//
//  Created by gandreas on 8/26/23.
//

import Foundation

public struct Penalties {
    var sheet: Sheet
    init(sheet: Sheet) {
        self.sheet = sheet
    }
    /// Penalty data for a given period
    public struct Period : TypedSheetCover {
        public var sheet: Sheet
        public var cellOffset: Address.Offset
        init(sheet: Sheet, offset: Address.Offset) {
            self.sheet = sheet
            self.cellOffset = offset
        }
        public struct CellDefinitions {
            var homeName = CellDef<String?>("A1")
            var homeColor = CellDef<String?>("I1")
            var awayName = CellDef<String?>("Q1")
            var awayColor = CellDef<String?>("Z1")
            var date = CellDef<String?>("L1")
            var penaltyTracker = CellDef<String?>("N1")
        }
        public static var cellDefinitions = CellDefinitions()
        
        public struct Team : TypedSheetCover {
            public var sheet: Sheet
            public var cellOffset: Address.Offset
            init(sheet: Sheet, offset: Address.Offset) {
                self.sheet = sheet
                self.cellOffset = offset
            }
            public struct CellDefinitions {
                /// total penalties for this team in this peariod
                var totalPenalties = CellDef<Int?>("L44")
                var notSkaterExplusionCount = CellDef<Int?>("E44")
            }
            public static var cellDefinitions = CellDefinitions()
            
            public struct Skater : TypedSheetCover {
                public var sheet: Sheet
                public var cellOffset: Address.Offset
                init(sheet: Sheet, offset: Address.Offset) {
                    self.sheet = sheet
                    self.cellOffset = offset
                }
                public struct CellDefinitions {
                    /// total penalties for this team in this peariod
                    var number = CellDef<String?>("A4")
                    var total = CellDef<Int?>("L4")
                }
                public static var cellDefinitions = CellDefinitions()
                
                public struct Penalty : TypedSheetCover {
                    public var sheet: Sheet
                    public var cellOffset: Address.Offset
                    init(sheet: Sheet, offset: Address.Offset) {
                        self.sheet = sheet
                        self.cellOffset = offset
                    }
                    public struct CellDefinitions {
                        /// total penalties for this team in this peariod
                        var code = CellDef<String?>("B4")
                        var jam = CellDef<Int?>("B5")
                    }
                    public static var cellDefinitions = CellDefinitions()
                }
                
                /// Find all penalties
                /// - Returns: Array of all penalty entries
                public var penalties : [Penalty] {
                    (0..<9).compactMap { i in
                        let penalty = Penalty(sheet: sheet, offset: cellOffset + .init(dc: i))
                        if penalty.code != nil && penalty.jam != nil {
                            return penalty
                        }
                        return nil
                    }
                }
                
                /// Get the foExp (note that code and jam will be empty if nothing here
                public var foExp: Penalty {
                    Penalty(sheet: sheet, offset: cellOffset + .init(dc: 9))
                }
            }
            
            /// All skaters, in order.  Note that we assume that skater numbers are entered as
            /// string (which we do in other places as well)
            func skaters() -> [Skater] {
                (0..<20).compactMap { i in
                    let skater = Skater(sheet: sheet, offset: cellOffset + .init(dr: 2 * i))
                    if skater.number == nil {
                        return nil
                    }
                    return skater
                }
            }
            /// Find the first skater on this team in this period that matches the given skater number
            /// - Parameter number: The skater number
            /// - Returns: The skater entry
            func skater(number: String) -> Skater? {
                skaters().first(where: {$0.number == number})
            }
        }
        
        public var home : Team { Team(sheet: sheet, offset: cellOffset) }
        public var away : Team { Team(sheet: sheet, offset: cellOffset + .init(dc: 15)) }
    }
    
    public var period1 : Period { Period(sheet: sheet, offset: .zero) }
    public var period2 : Period { Period(sheet: sheet, offset: .init(dc:28)) }
}

public extension StatsBookFile {
    var penalties: Penalties {
        Penalties(sheet: try! sheet(named: "Penalties"))
    }
}
