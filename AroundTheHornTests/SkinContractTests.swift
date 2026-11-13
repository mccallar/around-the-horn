import XCTest
import HornEngine
@testable import AroundTheHorn

/// What every skin owes the shell, checked for every journey the engine has. A new
/// journey's skin is added to `Skins.all` and this file tells it what it left out.
///
/// The compiler already insists a skin supplies every member; this checks that what it
/// supplied is not blank and that its three drawings run for every weather and every stop.
@MainActor
final class SkinContractTests: XCTestCase {
    let journeys = Journeys.all

    /// Every blank string reachable in `value`, by path. Closures are not strings: the
    /// tests call those themselves.
    func blanks(_ value: Any, _ path: String = "") -> [String] {
        if let s = value as? String {
            return s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? [path] : []
        }
        let m = Mirror(reflecting: value)
        if m.displayStyle == .optional { return m.children.first.map { blanks($0.value, path) } ?? [] }
        return m.children.enumerated().flatMap { i, ch in blanks(ch.value, path + "." + (ch.label ?? "\(i)")) }
    }

    func said(_ s: String, _ what: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertFalse(s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "\(what) is blank", file: file, line: line)
    }

    func fresh(_ j: Journey, role: Role = .merchant) -> GameState {
        let d = j.departures[0]
        return GameState(journey: j.id, role: role, ship: "Wren", captain: "Ada", crew: ["Bo", "Cy", "Di", "Ed"],
                         startYear: d.year, startMonth: d.month)
    }

    /// A voyage standing at each stop in turn (in port where there is one), and one under
    /// way just short of each: every place the words and the drawings can be asked for.
    func states(_ j: Journey) throws -> [(name: String, state: GameState)] {
        let skin = try XCTUnwrap(Skins.skin(j.id))
        var out = [("fresh", fresh(j))]
        for (i, stop) in j.stops.enumerated() {
            var at = fresh(j)
            at.stopIndex = i
            at.mile = stop.mile
            at.day = 3 * i
            at.atPort = j.port(stop.id) != nil
            out.append(("at \(stop.id)", at))
            if i > 0 { out.append(("nearing \(stop.id)", skin.debug.start(i, j.departures[0].month))) }
        }
        return out
    }

    // MARK: A skin for every journey

    func testEveryJourneyHasASkinAndEverySkinAJourney() {
        XCTAssertFalse(journeys.isEmpty)
        for j in journeys { XCTAssertNotNil(Skins.skin(j.id), "no skin for \(j.id)") }
        for s in Skins.all { XCTAssertTrue(Journeys.has(s.id), "a skin for \(s.id), which is no journey") }
        XCTAssertEqual(Set(Skins.all.map(\.id)).count, Skins.all.count, "one skin each")
    }

    // MARK: Copy

    func testTheTitleCardLeavesNothingBlank() throws {
        for j in journeys {
            let card = try XCTUnwrap(Skins.skin(j.id)).card
            XCTAssertEqual(blanks(card), [], j.id)
            said(card.resume("Wren"), "\(j.id) resume")
            XCTAssertTrue(card.resume("Wren").contains("Wren"), "\(j.id): the saved voyage is named")
            said(card.outfitIntro(fresh(j)), "\(j.id) outfitIntro")
            XCTAssertFalse(card.learnPages.isEmpty, j.id)
            for page in card.learnPages { XCTAssertFalse(page.paragraphs.isEmpty, "\(j.id) \(page.heading)") }
            XCTAssertFalse(card.differences.isEmpty, j.id)
            XCTAssertFalse(card.outfitBullets.isEmpty, j.id)
            said(j.title, "\(j.id) title")
            said(j.subtitle, "\(j.id) subtitle")
        }
    }

    func testTheWordsLeaveNothingBlankAtAnyStop() throws {
        for j in journeys {
            let skin = try XCTUnwrap(Skins.skin(j.id))
            for (name, base) in try states(j) {
                for role in Role.allCases {
                    var g = base
                    g.role = role
                    let w = skin.words(g), at = "\(j.id) \(name) \(role)"
                    XCTAssertEqual(blanks(w), [], at)
                    said(w.distance(0), "\(at) distance")
                    said(w.distance(j.totalMiles), "\(at) distance")
                    for n in j.rules.restChoices { said(w.restChoice(n), "\(at) restChoice \(n)") }
                    XCTAssertEqual(Set(j.rules.restChoices.map(w.restChoice)).count, j.rules.restChoices.count,
                                   "\(at): rest choices read differently")
                    for cost in [0, 1, 250] {
                        said(w.yardHull(cost), "\(at) yardHull")
                        said(w.yardSails(cost), "\(at) yardSails")
                    }
                    said(w.priceNote(30), "\(at) priceNote")
                    said(w.burial("Bo"), "\(at) burial")
                }
            }
        }
    }

    /// A journey short of clothes or long without citrus still says something sensible.
    func testTheWordsSurviveAVoyageGoingBadly() throws {
        for j in journeys {
            let skin = try XCTUnwrap(Skins.skin(j.id))
            var g = fresh(j)
            g.clothes = 0
            g.noCitrus = 99
            g.hull = 0
            g.sails = 0
            g.money = 0
            for i in g.crew.indices.dropFirst() { g.crew[i].hp = 0 }
            XCTAssertEqual(blanks(skin.words(g)), [], j.id)
        }
    }

    /// The rows the shell builds from the journey's items: named, and named apart, since
    /// the lists tell them apart by label.
    func testStoresAreNamedAndToldApart() throws {
        for j in journeys {
            let skin = try XCTUnwrap(Skins.skin(j.id))
            for (name, g) in try states(j) {
                let w = skin.words(g)
                let status = StatusPanel.stores(j, g, w)
                XCTAssertFalse(status.isEmpty, j.id)
                XCTAssertEqual(Set(status.map(\.label)).count, status.count, "\(j.id) \(name)")
                XCTAssertEqual(status.contains { $0.label == (w.statusNames[.fuel] ?? j.item(.fuel).name) }, j.burnsFuel,
                               "\(j.id): a fuel row exactly when the journey burns fuel")
                for r in status {
                    said(r.label, "\(j.id) status label")
                    said(r.value, "\(j.id) status value")
                }
                let rows = SuppliesView.rows(j, g, w)
                XCTAssertEqual(rows.count, j.items.count + 1)
                XCTAssertEqual(Set(rows.map(\.0)).count, rows.count, "\(j.id) \(name)")
                for r in rows {
                    said(r.0, "\(j.id) supplies label")
                    said(r.1, "\(j.id) supplies value")
                }
                for it in j.items { said(Stores.have(it, g, w), "\(j.id) have \(it.key)") }
            }
            for key in [ItemKey.food] + (j.burnsFuel ? [.fuel] : []) {
                said(j.item(key).name, "\(j.id): the journey stocks \(key)")
            }
        }
    }

    // MARK: Drawings

    func testTheSceneDrawsInEveryWeatherAtEveryStop() throws {
        for j in journeys {
            let scene = try XCTUnwrap(Skins.skin(j.id)).scene
            var frames = [ScenePicture.frame(j, nil, moving: false, t: 0)]  // the title card
            for (_, base) in try states(j) {
                for weather in j.weathers {
                    for moving in [false, true] {
                        var g = base
                        g.weather = weather
                        frames.append(ScenePicture.frame(j, g, moving: moving, t: 0))
                        g.hull = 3
                        g.sails = 3
                        let worn = ScenePicture.frame(j, g, moving: moving, t: 0)
                        // Round the clock, for a journey whose turns are shorter than a day.
                        for hour in [0, 5, 12, 19, 23] {
                            frames.append(SceneFrame(t: 0, weather: worn.weather, moving: moving, atPort: worn.atPort,
                                                     hull: worn.hull, sails: worn.sails, region: worn.region,
                                                     hour: hour, state: g))
                        }
                    }
                }
            }
            for f in frames {
                for t in [0, 0.37, 5.3, 4321.9] {
                    let px = PixelCanvas(w: SceneSkin.w, h: SceneSkin.h)
                    scene.draw(px, f.at(t))
                    XCTAssertGreaterThan(px.tally.marks, 0, "\(j.id) \(f.weather.name): nothing drawn")
                }
                said(scene.label(f), "\(j.id) scene label in \(f.weather.name)")
            }
        }
    }

    func testTheChartDrawsAtEveryStop() throws {
        for j in journeys {
            let chart = try XCTUnwrap(Skins.skin(j.id)).chart
            said(chart.title, "\(j.id) chart title")
            XCTAssertGreaterThan(chart.w, 0)
            XCTAssertGreaterThan(chart.h, 0)
            XCTAssertGreaterThan(chart.routeStep, 0)
            XCTAssertGreaterThan(chart.travelledStep, 0)
            for (name, g) in try states(j) {
                let at = "\(j.id) \(name)"
                said(chart.label(g), "\(at) chart label")
                said(chart.footer(g), "\(at) chart footer")
                for route in [chart.route(g)] + chart.others(g) {
                    XCTAssertGreaterThanOrEqual(route.count, 2, at)
                    XCTAssertEqual(route.map(\.mile), route.map(\.mile).sorted(), "\(at): miles only go up")
                }
                let route = chart.route(g)
                XCTAssertEqual(route.first?.mile, 0, at)
                XCTAssertGreaterThanOrEqual(route.last?.mile ?? 0, Double(j.totalMiles), "\(at): the route reaches the end")
                for s in j.stops {
                    let q = ChartView.position(route, atMile: Double(s.mile), chart)
                    XCTAssertTrue((0...chart.w).contains(q.x) && (0...chart.h).contains(q.y), "\(at): \(s.id) is off the chart")
                }
                for t in [0, 0.6] {
                    let px = PixelCanvas(w: chart.w, h: chart.h)
                    ChartView.draw(px, chart, j, g, t: t)
                    XCTAssertGreaterThan(px.tally.marks, j.stops.count, at)
                }
            }
        }
    }

    func testTheMiniGameIsPlayableAndDraws() throws {
        for j in journeys {
            let forage = try XCTUnwrap(Skins.skin(j.id)).forage
            let f = forage.field
            XCTAssertEqual(blanks([forage.heading, forage.throwsLabel, forage.caughtLabel, forage.unit, forage.timeLabel,
                                   forage.actionHint, forage.leave]), [], j.id)
            said(forage.hint(300), "\(j.id) forage hint")
            said(forage.label(0), "\(j.id) forage label")
            said(forage.label(4), "\(j.id) forage label")

            XCTAssertFalse(j.quarry.isEmpty, "\(j.id): something to catch")
            XCTAssertGreaterThan(j.forageSeconds, 0)
            for q in j.quarry { said(forage.pop(q), "\(j.id) pop for \(q.name)") }

            // The field hangs together: the quarry runs on the far side of the line from
            // the thrower, all of it on the canvas and in reach.
            XCTAssertTrue((0...f.w).contains(f.origin.x) && (0...f.h).contains(f.origin.y), j.id)
            XCTAssertTrue(f.lanes.lowerBound >= 0 && f.lanes.upperBound <= f.h, j.id)
            XCTAssertTrue(f.inReach(f.lanes.lowerBound) && f.inReach(f.lanes.upperBound), "\(j.id): the lanes are in reach")
            XCTAssertEqual(f.upward, f.origin.y > f.lanes.upperBound, "\(j.id): thrown toward the quarry")
            XCTAssertGreaterThan(f.speed, 0)

            for role in Role.allCases {
                var throwsLeft = 8
                let m = FishingModel(field: f, quarry: j.quarry, seconds: j.forageSeconds, padding: j.role(role).aim,
                                     pop: forage.pop, random: { 0.5 },
                                     useTackle: {
                                         guard throwsLeft > 0 else { return false }
                                         throwsLeft -= 1
                                         return true
                                     },
                                     tackleLeft: { throwsLeft })
                XCTAssertFalse(m.fish.isEmpty, "\(j.id): quarry on the field at the start")
                for s in m.fish { XCTAssertTrue(f.lanes.contains(s.y0), j.id) }
                let mid = (f.lanes.lowerBound + f.lanes.upperBound) / 2
                m.throwAt(x: f.w / 2, y: mid)
                let thrown = try XCTUnwrap(m.harpoon, "\(j.id): a tap in the lanes throws")
                XCTAssertEqual(thrown.vy < 0, f.upward, "\(j.id): thrown toward the lanes")
                XCTAssertEqual(throwsLeft, 7)
                var steps = 0
                while !m.ended && steps < 100_000 {
                    m.step(0.05)
                    if m.harpoon == nil { m.throwAt(x: f.w / 2, y: mid) }
                    if steps % 7 == 0 {
                        let px = PixelCanvas(w: f.w, h: f.h)
                        FishingView.draw(px, forage, m, now: Double(steps) * 0.05)
                        XCTAssertGreaterThan(px.tally.marks, 0, j.id)
                    }
                    steps += 1
                }
                XCTAssertTrue(m.ended, "\(j.id): the outing ends")
            }

            // Every kind of quarry and a throw in flight, drawn on their own.
            let px = PixelCanvas(w: f.w, h: f.h)
            forage.backdrop(px, 12.5)
            let afterBackdrop = px.tally.marks
            XCTAssertGreaterThan(afterBackdrop, 0, "\(j.id): a backdrop")
            for q in j.quarry {
                for vx in [-20.0, 20.0] {
                    let before = px.tally.marks
                    forage.quarry(px, FishingModel.Swimmer(kind: q, x: f.w / 2, y0: f.lanes.lowerBound,
                                                           y: f.lanes.lowerBound, vx: vx, t: 0, wf: 1, wa: 1))
                    XCTAssertGreaterThan(px.tally.marks, before, "\(j.id): \(q.name) is drawn")
                }
            }
            let before = px.tally.marks
            forage.thrown(px, FishingModel.Harpoon(x: f.w / 2, y: f.lanes.lowerBound, vx: 10, vy: f.upward ? -f.speed : f.speed))
            XCTAssertGreaterThan(px.tally.marks, before, "\(j.id): the throw is drawn")
        }
    }

    // MARK: Debug starts

    func testDebugStartsAndTheGallery() throws {
        for j in journeys {
            let skin = try XCTUnwrap(Skins.skin(j.id))
            for i in j.stops.indices.dropFirst() {
                for d in j.departures {
                    let g = skin.debug.start(i, d.month)
                    XCTAssertEqual(g.journey, j.id)
                    XCTAssertEqual(g.stopIndex, i - 1, "\(j.id): short of stop \(i)")
                    XCTAssertLessThan(g.mile, j.stops[i].mile)
                    XCTAssertFalse(g.over)
                    XCTAssertFalse(g.atPort)
                }
            }
            for cell in skin.debug.gallery {
                said(cell.name, "\(j.id) gallery cell")
                let g = SceneGallery.state(j, cell.set)
                let px = PixelCanvas(w: SceneSkin.w, h: SceneSkin.h)
                skin.scene.draw(px, ScenePicture.frame(j, g, moving: cell.moving, t: 1))
                XCTAssertGreaterThan(px.tally.marks, 0)
            }
        }
    }
}

// MARK: - A save and a top ten for each journey

final class JourneyFilesTests: XCTestCase {
    var p: Persistence!
    let fm = FileManager.default

    override func setUpWithError() throws {
        p = Persistence(directory: fm.temporaryDirectory.appendingPathComponent(UUID().uuidString),
                        defaults: UserDefaults(suiteName: UUID().uuidString)!)
        try fm.createDirectory(at: p.directory, withIntermediateDirectories: true)
    }

    func voyage(_ journey: String = Horn1849.id, ship: String = "Sea Lark") -> GameState {
        var s = GameState(journey: journey, role: .whaler, ship: ship, captain: "Ira", crew: ["A", "B", "C", "D"],
                          startYear: 1849, startMonth: 0)
        s.day = 40
        return s
    }

    func testFilesAreNamedForTheirJourney() {
        XCTAssertEqual(p.saveURL("rail").lastPathComponent, "save-rail.json")
        XCTAssertEqual(p.topTenURL("rail").lastPathComponent, "topten-rail.json")
        XCTAssertEqual(p.saveURL(Horn1849.id).lastPathComponent, "save-horn1849.json")
        XCTAssertEqual(p.topTenURL(Horn1849.id).lastPathComponent, "topten-horn1849.json")
        XCTAssertEqual(p.legacySaveURL.lastPathComponent, "save.json")
        XCTAssertEqual(p.legacyTopTenURL.lastPathComponent, "topten.json")
    }

    func testEveryJourneySavesToItsOwnFile() {
        for j in Journeys.all {
            let d = j.departures[0]
            let s = GameState(journey: j.id, role: .merchant, ship: "Wren", captain: "Ada", crew: ["B", "C", "D", "E"],
                              startYear: d.year, startMonth: d.month)
            p.save(s)
            XCTAssertTrue(fm.fileExists(atPath: p.saveURL(j.id).path), j.id)
            XCTAssertEqual(p.loadSave(j.id), s)
            XCTAssertNil(p.loadSave("no-such-journey"))
            p.deleteSave(j.id)
            XCTAssertNil(p.loadSave(j.id))
        }
        XCTAssertFalse(fm.fileExists(atPath: p.legacySaveURL.path), "nothing new is written under the old name")
    }

    func testAnOldSaveIsStill1849sAndMovesOnTheNextSave() throws {
        let old = voyage()
        try JSONEncoder().encode(old).write(to: p.legacySaveURL)
        XCTAssertEqual(p.loadSave(Horn1849.id), old, "save.json is read as 1849's")
        XCTAssertNil(p.loadSave("rail"), "and as nobody else's")
        XCTAssertTrue(fm.fileExists(atPath: p.legacySaveURL.path), "reading it leaves it where it was")

        var later = old
        later.day = 41
        p.save(later)
        XCTAssertEqual(p.loadSave(Horn1849.id), later)
        XCTAssertTrue(fm.fileExists(atPath: p.saveURL(Horn1849.id).path))
        XCTAssertFalse(fm.fileExists(atPath: p.legacySaveURL.path), "the voyage now lives in its own file")
    }

    func testTheNewSaveWinsOverAnOldOne() throws {
        try JSONEncoder().encode(voyage(ship: "Old")).write(to: p.legacySaveURL)
        try JSONEncoder().encode(voyage(ship: "New")).write(to: p.saveURL(Horn1849.id))
        XCTAssertEqual(p.loadSave(Horn1849.id)?.ship, "New")
    }

    func testEndingAVoyageClearsTheOldSaveToo() throws {
        try JSONEncoder().encode(voyage()).write(to: p.legacySaveURL)
        p.deleteSave(Horn1849.id)
        XCTAssertNil(p.loadSave(Horn1849.id), "or the title would offer a voyage that has ended")
        XCTAssertFalse(fm.fileExists(atPath: p.legacySaveURL.path))
    }

    func testASaveInAnotherJourneysFileIsNotHandedOut() throws {
        try JSONEncoder().encode(voyage()).write(to: p.saveURL("rail"))
        XCTAssertNil(p.loadSave("rail"), "1849's voyage under another journey's name")
        var stray = voyage()
        stray.journey = "rail"
        try JSONEncoder().encode(stray).write(to: p.saveURL(Horn1849.id))
        XCTAssertNil(p.loadSave(Horn1849.id), "a save says whose it is")
    }

    func testAnOldTopTenIsStill1849sAndIsNeverLost() throws {
        let journey = Journeys.journey(Horn1849.id)
        let old = [TopTenEntry(name: "Gran", score: 4321)]
        try JSONEncoder().encode(old).write(to: p.legacyTopTenURL)
        XCTAssertEqual(p.topTen(journey), old, "topten.json is read as 1849's")

        let next = TopTen.inserting(name: "Ira", score: 9000, into: p.topTen(journey)).table
        p.saveTopTen(next, for: journey.id)
        XCTAssertEqual(p.topTen(journey), next, "the journey's own file is read first")
        XCTAssertTrue(next.contains(TopTenEntry(name: "Gran", score: 4321)), "the old scores carry over")
        let kept = try JSONDecoder().decode([TopTenEntry].self, from: Data(contentsOf: p.legacyTopTenURL))
        XCTAssertEqual(kept, old, "and the old file is left as it was")
    }

    func testTopTensAreKeptApart() {
        let journey = Journeys.journey(Horn1849.id)
        p.saveTopTen([TopTenEntry(name: "Driver", score: 1)], for: "rail")
        XCTAssertEqual(p.topTen(journey), journey.defaultTopTen, "another journey's table is not 1849's")
        XCTAssertTrue(fm.fileExists(atPath: p.topTenURL("rail").path))
    }
}

// MARK: - Choosing a journey

@MainActor
final class JourneyPickerTests: XCTestCase {
    var p: Persistence!

    override func setUp() async throws {
        p = Persistence(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString),
                        defaults: UserDefaults(suiteName: UUID().uuidString)!)
    }

    func isPicker(_ c: GameController) -> Bool { if case .picker = c.screen { return true } else { return false } }
    func isTitle(_ c: GameController) -> Bool { if case .title = c.screen { return true } else { return false } }

    func testOneJourneyOpensOnItsTitleCardWithNoWayToAPicker() {
        let one = [Journeys.all[0]]
        let c = GameController(persistence: p, journeys: one)
        XCTAssertTrue(isTitle(c))
        XCTAssertFalse(c.hasPicker)
        c.goToPicker()
        XCTAssertTrue(isTitle(c), "there is nothing to pick between")
        XCTAssertTrue(isTitle(GameController(persistence: p, journeys: one, journey: "no-such-journey")))
    }

    /// The engine has one journey to give, so the list of two is the same one twice:
    /// enough for the routing, which only counts them.
    func testSeveralJourneysOpenOnThePickerAndTheTitleLeadsBack() {
        let j = Journeys.all[0]
        let c = GameController(persistence: p, journeys: [j, j])
        XCTAssertTrue(isPicker(c))
        XCTAssertTrue(c.hasPicker)
        c.chooseJourney(j.id)
        XCTAssertTrue(isTitle(c))
        XCTAssertEqual(c.journey.id, j.id)
        c.goToPicker()
        XCTAssertTrue(isPicker(c))
        c.chooseJourney("no-such-journey")
        XCTAssertEqual(c.journey.id, j.id, "an unknown id changes nothing")
    }

    func testTheLaunchArgumentGoesStraightToThatTitleCard() {
        let j = Journeys.all[0]
        let c = GameController(persistence: p, journeys: [j, j], journey: j.id)
        XCTAssertTrue(isTitle(c))
        XCTAssertEqual(c.journey.id, j.id)
        XCTAssertTrue(isPicker(GameController(persistence: p, journeys: [j, j], journey: "no-such-journey")),
                      "an id nobody knows is no choice at all")
    }

    func testAVoyageBelongsToTheJourneyItWasStartedIn() {
        for j in Journeys.all {
            let c = GameController(persistence: p, journeys: Journeys.all, journey: j.id)
            c.startNewGame()
            c.chooseRole(.merchant)
            c.setNames(ship: "", captain: "", crew: ["", "", "", ""])
            let d = j.departures[0]
            c.chooseDeparture(year: d.year, month: d.month)
            XCTAssertEqual(c.game?.journey, j.id)
            XCTAssertEqual(c.skin.id, j.id)
            XCTAssertTrue(j.vesselNames.contains(c.game!.ship), "\(j.id): names come from the journey")
        }
    }
}
