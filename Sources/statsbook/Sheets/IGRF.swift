//
//  File.swift
//  
//
//  Created by gandreas on 8/22/23.
//

import Foundation


/// A wrapper around the IGRF
public struct IGRF : TypedSheetCover {
    
    var sheet: Sheet
    
    init(sheet: Sheet) {
        self.sheet = sheet
//        _venueName = .init(sheet: sheet, row: 3, col: "B")
    }

    struct CellDefinitions {
        var venueName = CellDef<String?>("B3")
        var city = CellDef<String?>("I3")
        var state = CellDef<String?>("K3")
        var gameNumber = CellDef<String?>("L3")
        var tournament = CellDef<String?>("B5")
        var hostLeague = CellDef<String?>("I5")
        var date = CellDef<String?>("B7")
        var time = CellDef<String?>("I7")
    }
    
    static var cellDefinitions: CellDefinitions = .init()


    struct Team : TypedSheetCover {
        var cellOffset: Address.Offset
        var sheet: Sheet
        init(sheet: Sheet, offset: Address.Offset) {
            self.sheet = sheet
            self.cellOffset = offset
        }
        
        
        struct CellDefinitions {
            var league = CellDef<String?>("B10")
            var team = CellDef<String?>("B11")
            var state = CellDef<String?>("B12")
            var period1Points = CellDef<Double?>("C36")
            var period2Points = CellDef<Double?>("C37")
            var totalPoints = CellDef<Double?>("C38")
            var period1Penalties = CellDef<Double?>("F36")
            var period2Penalties = CellDef<Double?>("F37")
            var totalPenalties = CellDef<Double?>("F38")
        }
        
        static var cellDefinitions: CellDefinitions = .init()

        struct Skater : TypedSheetCover {
            var cellOffset: Address.Offset
            var sheet: Sheet
            init(sheet: Sheet, offset: Address.Offset) {
                self.sheet = sheet
                self.cellOffset = offset
            }
            
            struct CellDefinitions {
                var number = CellDef<String?>("B14") 
                var name = CellDef<String?>("C14") 
            }
            static var cellDefinitions: CellDefinitions = .init()

        }
        func skater(index: Int) -> Skater {
            // form a skater based on offset adding the index
            .init(sheet: sheet, offset: .init(dr: self.cellOffset.dr + index - 1, dc: self.cellOffset.dc))
        }
    }
    var home: Team {
        .init(sheet: sheet, offset: .zero)
    }
    var away: Team {
        // move 6 columns to the right
        .init(sheet: sheet, offset: .init(dc: 6))
    }
}


public extension StatsBookFile {
    var igrf: IGRF {
        IGRF(sheet: try! sheet(named: "IGRF"))
    }
}
