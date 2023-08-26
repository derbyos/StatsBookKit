//
//  File.swift
//  
//
//  Created by gandreas on 8/22/23.
//

import Foundation


/// A wrapper around the IGRF
public struct IGRF : DynamicSheetPage {
    var sheet: Sheet
    
    init(sheet: Sheet) {
        self.sheet = sheet
//        _venueName = .init(sheet: sheet, row: 3, col: "B")
    }

    static var stringFields: [String : Address] = [
        "venueName":"B3",
        "city":"I3",
        "state":"K3",
        "gameNumber":"L3",
        "tournament":"B5",
        "hostLeague":"I5",
        "date":"B7",
        "time":"I7",
    ]
    
    static var numberFields: [String: Address] = [
        :
    ]
    /*
    @StringCell var venueName: String?
    
//    var venueName: String? {
//        get {
//            try? sheet[row: 3, col: "B"]?.eval()?.asString
//        }
//        set {
//            sheet[row: 3, col: "B"]?.value = newValue.map{.string($0)}
//        }
//    }
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
     */

    struct Team : DynamicSheetPage {
        var cellOffset: (dr: Int, dc: Int)
        var sheet: Sheet
        init(sheet: Sheet, offset: (dr: Int, dc: Int)) {
            self.sheet = sheet
            self.cellOffset = offset
        }
        
        static var stringFields: [String : Address] = [
            "league": "B10",
            "team": "B11",
            "color": "B12",
        ]
        static var numberFields: [String: Address] = [
            "period1Points": "C36",
            "period2Points": "C37",
            "totalPoints": "C38",
            "period1Penalties": "F36",
            "period2Penalties": "F37",
            "totalPenalties": "F38",
        ]
        struct Skater : DynamicSheetPage {
            var cellOffset: (dr: Int, dc: Int)
            var sheet: Sheet
            init(sheet: Sheet, offset: (dr: Int, dc: Int)) {
                self.sheet = sheet
                self.cellOffset = offset
            }
            static var stringFields: [String : Address] = [
                "number": "B14",
                "name": "C14",
                ]
            static var numberFields: [String: Address] = [
                :
            ]
        }
        func skater(index: Int) -> Skater {
            // form a skater based on offset adding the index
            .init(sheet: sheet, offset: (dr: self.cellOffset.dr + index - 1, dc: self.cellOffset.dc))
        }
    }
    var home: Team {
        .init(sheet: sheet, offset: (dr: 0, dc: 0))
    }
    var away: Team {
        // move 6 columns to the right
        .init(sheet: sheet, offset: (dr: 0, dc: 6))
    }
}


public extension StatsBookFile {
    var igrf: IGRF {
        IGRF(sheet: try! sheet(named: "IGRF"))
    }
}
