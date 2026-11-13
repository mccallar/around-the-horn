import XCTest
@testable import AroundTheHorn

final class MarkupTests: XCTestCase {
    func testRunsAndNesting() {
        let r = Markup.runs("A [red]storm[/red] and [dim]a [i]ship[/i][/dim].")
        XCTAssertEqual(r.map(\.text), ["A ", "storm", " and ", "a ", "ship", "."])
        XCTAssertEqual(r[1].styles, [.red])
        XCTAssertEqual(r[4].styles, [.dim, .i])
        XCTAssertEqual(r[5].styles, [])
    }

    func testEscapedNamesStayPlainText() {
        let name = Markup.escape("[red]Bob")
        XCTAssertEqual(Markup.plain("\(name) is well again."), "[red]Bob is well again.")
        XCTAssertEqual(Markup.runs(name).first?.styles, [])
    }

    func testUnknownTagsAndStrayBracketsArePlain() {
        XCTAssertEqual(Markup.plain("a [blue]b[/blue] [c"), "a [blue]b[/blue] [c")
        XCTAssertEqual(Markup.plain("[/red]x"), "[/red]x", "a close with no open is text")
    }

    func testColorsInnermostWins() {
        let a = Markup.attributed("[green]x [red]y[/red][/green]", size: 22)
        let colors = a.runs.map(\.foregroundColor)
        XCTAssertEqual(colors.first!, Theme.green)
        XCTAssertEqual(colors.last!, Theme.red)
    }
}

final class PersistenceTests: XCTestCase {
    var p: Persistence!

    override func setUp() {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        p = Persistence(directory: dir, defaults: UserDefaults(suiteName: UUID().uuidString)!)
    }

    func testSaveLoadDelete() {
        var s = GameState(role: .whaler, ship: "Sea Lark", captain: "Ira", crew: ["A", "B", "C", "D"],
                          startYear: 1849, startMonth: 0)
        s.day = 40
        p.save(s)
        XCTAssertEqual(p.loadSave(Horn1849.id), s)
        p.deleteSave(Horn1849.id)
        XCTAssertNil(p.loadSave(Horn1849.id))
    }

    func testAFinishedVoyageIsNeverSaved() {
        var s = GameState(role: .merchant, ship: "X", captain: "A", crew: ["B", "C", "D", "E"],
                          startYear: 1849, startMonth: 0)
        s.over = true
        p.save(s)
        XCTAssertNil(p.loadSave(Horn1849.id))
    }

    func testAnIncompatibleSaveIsDiscarded() throws {
        var s = GameState(role: .merchant, ship: "X", captain: "A", crew: ["B", "C", "D", "E"],
                          startYear: 1849, startMonth: 0)
        s.saveVersion = 999
        try FileManager.default.createDirectory(at: p.directory, withIntermediateDirectories: true)
        try JSONEncoder().encode(s).write(to: p.saveURL(Horn1849.id))
        XCTAssertNil(p.loadSave(Horn1849.id))
        try Data("not json".utf8).write(to: p.saveURL(Horn1849.id))
        XCTAssertNil(p.loadSave(Horn1849.id))
    }

    func testTopTenDefaultsThenPersists() {
        let journey = Journeys.journey(Horn1849.id)
        XCTAssertEqual(p.topTen(journey), GameData.defaultTopTen)
        let t = TopTen.inserting(name: "Ira", score: 9000, into: p.topTen(journey)).table
        p.saveTopTen(t, for: journey.id)
        XCTAssertEqual(p.topTen(journey).first, TopTenEntry(name: "Ira", score: 9000))
    }

    func testMute() {
        XCTAssertFalse(p.muted)
        p.muted = true
        XCTAssertTrue(p.muted)
    }
}

import HornEngine
