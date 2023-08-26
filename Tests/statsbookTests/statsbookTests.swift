import XCTest
@testable import statsbook
@testable import statsbookJSON

final class statsbookTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        //        XCTAssertEqual(statsbook().text, "Hello, World!")
    }
    
    func loadBlankFile() throws -> StatsBookFile {
        try .init(URL(fileURLWithPath: "/Users/gandreas/Downloads/wftda-statsbook-full-us-letter.xlsx"))
    }
    func loadSampleFile() throws -> StatsBookFile {
        try .init(URL(fileURLWithPath: "/Users/gandreas/Downloads/STATS-2023-04-30_NSRDSupernovas_vs_DRDAllstars_1.xlsx"))
    }
    
    func testLoading() throws {
        let file = try loadBlankFile()
        print(file.zipFile.entries)
        XCTAssertEqual(try file.sheet(named: "Read Me")[row: 1, col: "A"]?.stringValue, "Women\'s Flat Track Derby Association")
        XCTAssertEqual(file.igrf.sheet[row: 3, col: "L"]?.comment?.commentText, """
Hint:
Use this for doubleheaders or multi-game events. It will print on other sheets. 

Does not have to be entered as "A" or "B"; alphanumeric and multiple characters are honored.
""")
    }
    
    func testAddresses() {
        let a1 = Address(row: 5, column: "B")
        XCTAssertEqual(a1.adding(row: 3).row, a1.row + 3)
        XCTAssertEqual(a1.adding(column: 1).column, "C")
        XCTAssertEqual(Address(row: 5, column: "Z").adding(column: 1).column, "AA")
        XCTAssertEqual(Address(row: 5, column: "AA").adding(column: -1).column, "Z")
    }
    
    func testRead() throws {
        let file = try loadSampleFile()
        let igrf = file.igrf
        XCTAssertEqual(igrf.city, "Saint Paul")
        XCTAssertEqual(igrf.home.league, "North Star Roller Derby")
        //        print("\(igrf.home.league ?? "")")
    }
    
    func testFormula() throws {
        let file = try loadSampleFile()
        let sheet = try file.sheet(named: "Score")
        // home color
        let cell = sheet[row: 1, col: "A"]!
        let formula = cell.formula!
        //        print(try formula.eval())
        XCTAssertEqual(try formula.eval(), "North Star Roller Derby / NSRD Supernovas")
        
        let formula2 = sheet[row: 42, col: "A"]!.formula!
        XCTAssertEqual(try formula2.eval(), 20.0)
        let formula4 = sheet[row: 42, col: "T"]!.formula!
        XCTAssertEqual(try formula4.eval(), 20.0)
        // this is a shared formula
        let formula5 = sheet[row: 5, col: "Q"]!.formula!
        XCTAssertEqual(try formula5.eval(), 3.0)
        let formula3 = sheet[row: 42, col: "V"]!.formula!
        XCTAssertEqual(try formula3.eval(), 3.0)
    }
    
    func testFormula2() throws {
        let file = try loadSampleFile()
        let sheet = try file.sheet(named: "IGRF")
        // home score period 1
        let formula2 = sheet[row: 36, col: "C"]!.formula!
        XCTAssertEqual(try formula2.eval(), 43.0)
        let formula3 = sheet[row: 36, col: "F"]!.formula!
        XCTAssertEqual(try formula3.eval(), 10.0)
    }
    
    func testStyles() throws {
        let file = try loadSampleFile()
        let sheet = try file.sheet(named: "IGRF")
        // Start Time
        let startTime = sheet[row: 7, col: "I"]!
        XCTAssertEqual(startTime.styleFormat?.numberFormat, "h:mm\\ AM/PM;@")
    }
    func printSheet(_ sheetName: String, bottomRight: Address) throws {
        let file = try loadSampleFile()
        let sheet = try file.sheet(named: sheetName)
        try sheet.recalc(reset: true)
        for row in 1...bottomRight.row {
            var cols = [String]()
            for col in 0 ... bottomRight.columnNumber {
                guard let f = sheet[row: row, col: Address.columnName(col)], let value = try f.eval(force: true) else {
                    cols.append("")
                    continue
                }
                switch value {
                case .bool(let b):
                    cols.append(String(describing: b))
                case .number(let d):
                    cols.append(String(describing: d))
                case .string(let s):
                    cols.append(s)
                case .undefined:
                    cols.append("*")
                }
            }
            print(row, cols.joined(separator: "|"))
        }
    }
    
    
    func testIGRFSheet() throws {
        try printSheet("IGRF", bottomRight: Address(row: 90, column: "M"))
    }
    func testScoresSheet() throws {
        try printSheet("Score", bottomRight: Address(row: 84, column: "AK"))
    }
    func testPenaltiesSheet() throws {
        try printSheet("Penalties", bottomRight: Address(row: 45, column: "BD"))
    }
    func testLineupsSheet() throws {
        try printSheet("Lineups", bottomRight: Address(row: 84, column: "AZ"))
    }
    
    func roundTripBlankFileXML(_ file: StatsBookFile, _ sheetName: String) throws {
        let sheet = try file.sheet(named: sheetName)
        try sheet.recalc(reset: true)
        let saved = sheet.save()
        XCTAssertEqual(sheet.xml, saved)
    }
    
    func testSaveBlankXML() throws {
        let file = try loadBlankFile()
        try roundTripBlankFileXML(file, "IGRF")
        try roundTripBlankFileXML(file, "Score")
    }
    
    func testSaveUnchanged() throws {
        let file = try loadBlankFile()
        let baseData : Data = file.zipFile.originalData
        let newData = file.zipFile.save()
        XCTAssertEqual(baseData, newData)
        if newData != baseData {
            if newData.count == baseData.count {
                for i in 0..<newData.count {
                    if newData[i] != baseData[i] {
                        XCTFail("Offset \(i) newData = \(newData[i]) oldData = \(baseData[i])")
                    }
                }
            }
        }
    }
    
    func testIGRF() throws {
        let file = try loadSampleFile()
        let sheet = try file.sheet(named: "IGRF")
        let igrf = IGRF(sheet: sheet)
        XCTAssertEqual(igrf.city, "Saint Paul")
        XCTAssertEqual(igrf.homePoints.period1, 43)
        XCTAssertEqual(igrf.homePenalties.period1, 10)
    }
    func testScoreSheet() throws {
        let file = try loadSampleFile()
        let score = file.score
        XCTAssertEqual(score.homeP1.color, "White")
        XCTAssertEqual(score.awayP2.color, "Red")
        let jam = score.homeP1.jam(number: 6)
        XCTAssertNotNil(jam)
        XCTAssertEqual(jam?.jammer,"1313")
        XCTAssertEqual(jam?.jamTotal, 0)
        XCTAssertEqual(jam?.gameTotal, 13)
        XCTAssertNotNil(jam?.afterStarPass)
        XCTAssertEqual(jam?.afterStarPass?.jammer, "622")
        XCTAssertEqual(score.homeP1.jam(number: 6)?.afterStarPass?.trips, [4, 0])
    }
    func testPenaltySheet() throws {
        let file = try loadSampleFile()
        let penalties = file.penalties
        let home1 = penalties.period1.home
        XCTAssertEqual(home1.totalPenalties, 10)
        let skater = home1.skater(number: "24")
        XCTAssertNotNil(skater)
        let skaterPenalties = skater!.penalties
        XCTAssertEqual(skaterPenalties.count, 2)
        XCTAssertEqual(skaterPenalties[0].jam, 16)
        XCTAssertEqual(skaterPenalties[0].code, "M")
        XCTAssertEqual(skaterPenalties[1].jam, 20)
        XCTAssertEqual(skaterPenalties[1].code, "M")
        
        let away2 = penalties.period2.away
        XCTAssertEqual(away2.totalPenalties, 5)
        let skater2 = away2.skater(number: "28")
        XCTAssertNotNil(skater2)
        let skaterPenalties2 = skater2!.penalties
        XCTAssertEqual(skaterPenalties2.count, 1)
        XCTAssertEqual(skaterPenalties2[0].jam, 13)
        XCTAssertEqual(skaterPenalties2[0].code, "P")
    }
    
    func testLineups() throws {
        let file = try loadSampleFile()
        let lineups = file.lineups
        let home1 = lineups.homeP1
        let h1Jam8 = home1.jam(number: 8)
        XCTAssertNotNil(h1Jam8)
        let skaters = h1Jam8!.skaters
        XCTAssertEqual(skaters[.jammer]?.number, "1300")
        XCTAssertEqual(skaters[.jammer]?.boxTrips, ["+"])
        let afterSP = h1Jam8?.afterStarPass
        XCTAssertNotNil(afterSP)
        XCTAssertEqual(afterSP?.noPivot, "X")
        XCTAssertEqual(afterSP?.jammer.number, "622")
        
        let away2 = lineups.awayP2
        let a2Jam19 = away2.jam(number: 19)
        XCTAssertNotNil(a2Jam19)
        XCTAssertEqual(a2Jam19?.pivot.number, "28")
    }
    
    func testMinJSONComments() throws {
        var sbj = StatsBookJSON.blank
        sbj.igrf.city = "Toasterville"
        sbj.igrf.$city.comment = "Not a real city"
        sbj.igrf.venueName = "Arena"
        let data = try JSONEncoder().encode(sbj)
        print(String(data: data, encoding: .utf8)!)
        
        let sbj2 = try JSONDecoder().decode(StatsBookJSON.self, from: data)
        // make sure both commented and uncommented values are there
        // and the comment as well
        XCTAssertEqual(sbj.igrf.city, sbj2.igrf.city)
        XCTAssertEqual(sbj.igrf.$city.comment, sbj2.igrf.$city.comment)
        XCTAssertEqual(sbj.igrf.venueName, sbj2.igrf.venueName)
        
        let encoderNoComment = JSONEncoder()
        encoderNoComment.userInfo[RemoveCommentsKey] = true
        let dataNoComment = try encoderNoComment.encode(sbj)
        print(String(data: dataNoComment, encoding: .utf8)!)
        let sbjNoComment = try JSONDecoder().decode(StatsBookJSON.self, from: dataNoComment)
        // make sure both commented and uncommented values are there
        // but the comment is removed
        XCTAssertEqual(sbj.igrf.city, sbjNoComment.igrf.city)
        XCTAssertEqual(sbj.igrf.venueName, sbjNoComment.igrf.venueName)
        XCTAssertNil(sbjNoComment.igrf.$city.comment)
    }
    
    func testImportingJSONComments() throws {
        let file = try loadSampleFile()
        let sbj = StatsBookJSON(statsbook: file)
        XCTAssertNotNil(sbj.igrf.$gameNumber.comment)
    }
    
    
    func testImportingJSONIGRF() throws {
        let file = try loadSampleFile()
        let sbj = StatsBookJSON(statsbook: file)
        XCTAssertEqual(sbj.igrf.home.skaters[0].number, "120")
        XCTAssertEqual(sbj.igrf.away.skaters[16].name, "Stough")
        XCTAssertEqual(sbj.igrf.home.totalPoints, 72)
        XCTAssertEqual(sbj.igrf.away.totalPenalties, 17)
    }
    
    func testImportingJSONScore() throws {
        let file = try loadSampleFile()
        let sbj = StatsBookJSON(statsbook: file)
        XCTAssertEqual(file.score.homeP1.totals.lead, 7)
        XCTAssertEqual(file.score.awayP2.totals.lead, 14)

        XCTAssertEqual(sbj.score.homeP1.totals.lead, 7)
        XCTAssertEqual(sbj.score.awayP2.totals.lead, 14)
    }
}
