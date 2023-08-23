//
//  File.swift
//  
//
//  Created by gandreas on 8/22/23.
//

import Foundation


/// A wrapper around the IGRF
public struct IGRF {
    var sheet: Sheet
    
    init(sheet: Sheet) {
        self.sheet = sheet
    }
}

public extension IGRF {
    var venueName: String? {
        sheet[row: 3, col: "B"]?.stringValue
    }
    var city: String? {
        sheet[row: 3, col: "I"]?.stringValue
    }
    var state: String? {
        sheet[row: 3, col: "K"]?.stringValue
    }
    var gameNumber: String? {
        sheet[row: 3, col: "L"]?.stringValue
    }
    var tournament: String? {
        sheet[row: 5, col: "B"]?.stringValue
    }
    var hostLeague: String? {
        sheet[row: 5, col: "I"]?.stringValue
    }
    var date: String? {
        sheet[row: 7, col: "B"]?.stringValue
    }
    var time: String? {
        sheet[row: 7, col: "I"]?.stringValue
    }

    struct Team {
        var baseAddr: Address
        var sheet: Sheet
        init(sheet: Sheet, baseCol: String) {
            self.sheet = sheet
            self.baseAddr = .init(row: 10, column: baseCol)
        }
        
        var league: String? {
            sheet[baseAddr]?.stringValue
        }
        var team: String? {
            sheet[baseAddr.adding(row: 1)]?.stringValue
        }
        var color: String? {
            sheet[baseAddr.adding(row: 1)]?.stringValue
        }
        
        struct Skater {
            var number: String?
            var name: String?
        }
        func skater(index: Int) -> Skater {
            .init(
                number: sheet[baseAddr.adding(row: 4 + index)]?.stringValue,
                name: sheet[baseAddr.adding(row: 4 + index).adding(column: 1)]?.stringValue
            )
        }
        var period1Points: Int? {
            sheet[baseAddr.adding(row: 16).adding(column: 1)]?.intValue
        }
        var period2Points: Int? {
            sheet[baseAddr.adding(row: 17).adding(column: 1)]?.intValue
        }
        var totalPoints: Int? {
            sheet[baseAddr.adding(row: 18).adding(column: 1)]?.intValue
        }
        var period1Penalties: Int? {
            sheet[baseAddr.adding(row: 16).adding(column: 3)]?.intValue
        }
        var period2Penalties: Int? {
            sheet[baseAddr.adding(row: 17).adding(column: 3)]?.intValue
        }
        var totalPenalties: Int? {
            sheet[baseAddr.adding(row: 18).adding(column: 3)]?.intValue
        }
    }
    var home: Team {
        .init(sheet: sheet, baseCol: "B")
    }
    var away: Team {
        .init(sheet: sheet, baseCol: "I")
    }
}


public extension StatsBookFile {
    var igrf: IGRF {
        IGRF(sheet: try! sheet(named: "IGRF"))
    }
}
