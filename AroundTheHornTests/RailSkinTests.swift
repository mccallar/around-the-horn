import XCTest
@testable import HornEngine
@testable import AroundTheHorn

/// The Iron Road's skin, held to its own journey's tables: every number its sentences
/// state, the words a train needs and the ones it must not borrow from a ship, the
/// country in the picture, and the map. `SkinContractTests` asks what every skin owes
/// the shell; this asks what this one says. It ends with two voyages under way at once,
/// one on each journey, each keeping its own save and its own top ten.
@MainActor
final class RailSkinTests: XCTestCase {
    let rail = RailSkin.journey
    let skin = RailSkin.skin
    let card = RailSkin.card
    let horn = Journeys.journey(Horn1849.id)
    let fm = FileManager.default
    var p: Persistence!

    override func setUp() async throws {
        p = Persistence(directory: fm.temporaryDirectory.appendingPathComponent(UUID().uuidString),
                        defaults: UserDefaults(suiteName: UUID().uuidString)!)
    }

    func stopIndex(_ id: String) -> Int { rail.stops.firstIndex { $0.id == id }! }

    /// Ten miles short of `stop`, in October, as the debug start leaves it.
    func nearing(_ stop: String) -> GameState { skin.debug.start(stopIndex(stop), 9) }

    func has(_ text: String, _ part: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(text.contains(part), "“\(part)” is not in “\(text)”", file: file, line: line)
    }

    // MARK: The contract and the clock

    func testTheContractIsTheEnginesOwn() {
        XCTAssertEqual(RailSkin.contractTurns, RailData.contractTurns)
        XCTAssertEqual(rail.rules.tickHours, 4)
        XCTAssertEqual(RailSkin.perDay, 6)
        // The card says twelve days and sixteen.
        XCTAssertEqual(RailData.contractTurns / RailSkin.perDay, 12)
        XCTAssertEqual(RailData.contractTurns % RailSkin.perDay, 0)
        XCTAssertEqual(RailData.forfeitTurns / RailSkin.perDay, 16)
        XCTAssertEqual(RailData.forfeitTurns % RailSkin.perDay, 0)
        has(card.tagline, "due in twelve days")
        has(card.learnPages[0].paragraphs[1], "in twelve days. After sixteen the contract is torn up.")
        has(card.outfitBullets[2], "The run should take about twelve.")
    }

    func testTurnsAreReadAsDaysAndHours() {
        XCTAssertEqual(RailSkin.span(1), "4 hours")
        XCTAssertEqual(RailSkin.span(2), "8 hours")
        XCTAssertEqual(RailSkin.span(6), "1 day")
        XCTAssertEqual(RailSkin.span(7), "1 day and 4 hours")
        XCTAssertEqual(RailSkin.span(12), "2 days")
        XCTAssertEqual(RailSkin.span(67), "11 days and 4 hours")
        let w = skin.words(nearing("elko"))
        XCTAssertEqual(rail.rules.restChoices.map(w.restChoice), ["4 hours", "8 hours", "12 hours", "1 day"])
        // Every job the words put a time on takes one turn.
        has(w.repairsNote, "four hours")
        has(w.yardIntro, "four hours")
        has(card.learnPages[1].paragraphs[1], "It costs four hours")
    }

    func testTheClockCountsTheContractDown() {
        var g = nearing("elko")
        func clock(_ day: Int) -> String {
            g.day = day
            return skin.words(g).clock?.value ?? ""
        }
        XCTAssertEqual(skin.words(g).clock?.label, "Contract")
        XCTAssertEqual(clock(0), "12 days left")
        XCTAssertEqual(clock(30), "7 days left")
        XCTAssertEqual(clock(71), "4 hours left")
        XCTAssertEqual(clock(72), "late")
        XCTAssertEqual(clock(73), "4 hours late")
        XCTAssertEqual(clock(90), "3 days late")

        // On time is what the engine pays for: a turn in hand.
        for (day, late) in [(40, false), (71, false), (72, true), (80, true)] {
            g.day = day
            let w = skin.words(g)
            XCTAssertEqual(w.clock?.value.hasSuffix("late"), late, "day \(day): the status row and the note agree")
            XCTAssertEqual(w.suppliesNote.contains("the freight is late"), late, "day \(day)")
            XCTAssertEqual(w.suppliesNote.contains("left on the contract"), !late, "day \(day)")
            XCTAssertEqual(w.arrivalBody.contains("The freight is on time."), !late, "day \(day)")
            XCTAssertEqual(w.arrivalBody.contains("He signs for the freight anyway."), late, "day \(day)")
            let bonus = rail.score(g).lines.first { $0.label == Rail.onTimeLabel }
            XCTAssertEqual((bonus?.points ?? 0) > 0, !late, "day \(day): the bonus and the words agree")
        }
        g.day = 44
        has(skin.words(g).arrival, "7 days and 8 hours out of Omaha")
    }

    /// The report from play: the box gave no sign that the train had given out or run out of wood.
    func testTheStatusBoxSaysWhenTheTrainIsInTrouble() {
        var g = nearing("elko")
        func trouble() -> String? {
            let t = skin.words(g).trouble
            if let t { XCTAssertEqual(t.label, "Train") }
            return t?.value
        }
        XCTAssertNil(trouble())
        g.sails = 0.4
        XCTAssertTrue(Rail.brokenDown(g), "shows 0%: given out")
        XCTAssertEqual(trouble(), "Broken down")
        g.sails = 0.5
        XCTAssertNil(trouble(), "shows 1%")
        g.hull = 0
        XCTAssertEqual(trouble(), "Broken down")
        g.fuel = 0
        XCTAssertEqual(trouble(), "Broken down, no wood")
        g.hull = 30
        XCTAssertEqual(trouble(), "Out of wood")
        // Found by review: with less than a turn's wood the box said nothing, though the
        // turn runs partly on fence posts. The pace decides how much a turn burns.
        g.pace = .steady
        g.fuel = 9
        XCTAssertEqual(trouble(), "Last of the wood")
        g.fuel = 10
        XCTAssertNil(trouble())
        g.pace = .easy
        g.fuel = 6
        XCTAssertEqual(trouble(), "Last of the wood")
        g.fuel = 7
        XCTAssertNil(trouble(), "the easy pace burns 0.7 cords a turn")
        // The meters themselves never read below nought, a negative zero included.
        g.sails = -0.0
        XCTAssertEqual("\(Int(jsRounded(g.sails)))%", "0%")
        // 1849 has no such row.
        var s = Horn1849Skin.skin.debug.start(1, 0)
        s.sails = 0
        s.hull = 0
        XCTAssertNil(Horn1849Skin.skin.words(s).trouble)
    }

    // MARK: Numbers the card states

    func testTheCardsNumbersAreTheTables() {
        let all = card.learnPages.flatMap(\.paragraphs) + card.differences + card.outfitBullets
        let text = all.joined(separator: "\n")

        // The road.
        XCTAssertEqual(rail.totalMiles, 1776)
        has(text, "\(formatNumber(Double(rail.totalMiles))) miles off")
        XCTAssertEqual(rail.stops.first?.name, "Omaha")
        XCTAssertEqual(rail.stops.last?.name, "Sacramento")

        // Who you are.
        for (role, money) in [(Role.merchant, "$1,000"), (.shipwright, "$520"), (.whaler, "$350")] {
            let info = rail.role(role)
            XCTAssertEqual("$" + formatNumber(info.money), money)
            let line = try? XCTUnwrap(card.differences.first { $0.lowercased().contains(info.title) }, "\(role)")
            has(line ?? "", "starts with \(money).")
        }
        XCTAssertGreaterThan(rail.role(.shipwright).mend, rail.role(.merchant).mend)
        XCTAssertGreaterThan(rail.role(.shipwright).patch, rail.role(.merchant).patch)
        XCTAssertGreaterThan(rail.role(.whaler).aim, rail.role(.merchant).aim)
        XCTAssertEqual(Role.shipwright.scoreMultiplier, 2)
        XCTAssertEqual(Role.whaler.scoreMultiplier, 3)
        has(text, "the boilermaker scores double, the river hand triple")

        // Wood.
        let wood = rail.item(.fuel)
        XCTAssertEqual(rail.forageReward, .fuel)
        XCTAssertEqual(rail.role(.whaler).catchLimit / wood.per, 6)
        XCTAssertEqual(rail.role(.merchant).catchLimit / wood.per, 4)
        XCTAssertEqual(rail.role(.shipwright).catchLimit / wood.per, 4)
        has(text, "six cords of driftwood at a time where the others manage four")
        XCTAssertEqual(rail.pace(.steady).fuel, Double(wood.per), "a cord a turn at timetable speed")
        XCTAssertEqual(rail.pace(.steady).name, "Timetable")
        has(text, "about a cord every four hours at timetable speed")
        XCTAssertEqual(wood.max, 16)
        has(text, "The tender holds sixteen cords")
        has(text, "The tender holds 16 cords")

        // Cheap in Omaha, cheaper under the Sierra, dearer at every yard between.
        let home = rail.port("omaha")!.price(.fuel)
        for port in rail.ports where port.id != "omaha" {
            if port.id == "reno" {
                XCTAssertLessThan(port.price(.fuel), home)
            } else {
                XCTAssertGreaterThan(port.price(.fuel), home, port.id)
            }
        }
        XCTAssertEqual(rail.stops.last { $0.type == .port }?.id, "reno", "the last yard is the one under the Sierra")

        // Water.
        let dry = rail.regions.filter { $0.tags.contains("dry") }
        XCTAssertEqual(dry.count, 3)
        XCTAssertEqual(dry.compactMap { $0.nums["dry"] }.min(), 80)
        has(text, "except in the three deserts")
        has(text, "80 gallons or more every four hours")
        XCTAssertEqual(rail.item(.water).max, 1200)
        has(text, "The car holds 1,200 gallons")

        // The hills.
        let steep = rail.regions.filter { ($0.nums["grade"] ?? 1) < 0.5 }
        XCTAssertEqual(steep.map(\.id.rawValue), ["sherman", "eastslope"])
        XCTAssertEqual(Set(RailData.helperFee.keys), Set(steep.map(\.id.rawValue)), "a helper at the foot of each")
        XCTAssertEqual(steep.compactMap { $0.nums["grade"] }, [0.45, 0.45], "about half speed")
        has(text, "Two long grades")
        // Sherman Hill is past Cheyenne and the east slope past Reno.
        XCTAssertEqual(rail.region(nearing("cheyenne"), at: rail.stop("cheyenne")!.mile).id, "sherman")
        XCTAssertEqual(rail.region(nearing("reno"), at: rail.stop("reno")!.mile).id, "eastslope")

        // The table.
        let filling = rail.rations(.filling).amount
        XCTAssertEqual(5 * filling * Double(RailSkin.perDay), 15)
        has(text, "five people eating well use 15 lbs a day")
        XCTAssertEqual(rail.item(.tackle).per, 20)
        has(text, "a coil is good for 20 casts")

        // Everything the store sells is on the outfitting list.
        let bullets = card.outfitBullets.joined(separator: "\n").lowercased()
        for it in rail.items { has(bullets, it.name.lowercased()) }
        XCTAssertFalse(rail.items.contains { $0.key == .limes }, "nothing on a train to keep scurvy off")
    }

    func testTheRankLegendIsTheEnginesRanks() {
        let cuts = rail.rules.rankCuts
        XCTAssertEqual(cuts, [7000, 4000, 2000])
        let legend = cuts.map { "\(rail.rank($0)) \(formatNumber(Double($0)))+" } + [rail.rank(0)]
        XCTAssertEqual(card.rankLegend, legend.joined(separator: " · "))
    }

    func testTheSeasonsAdviceIsTheEnginesCalendar() {
        // "December and January are the worst of it."
        var harsh: [Int] = []
        for month in 0..<12 {
            let g = GameState(journey: Rail.id, role: .merchant, ship: "Wren", captain: "Ada", crew: ["Bo", "Cy", "Di", "Ed"],
                              startYear: 1869, startMonth: month)
            if rail.harshSeason(g) { harsh.append(month) }
        }
        XCTAssertEqual(harsh, [0, 11])
        has(card.monthAdvice, "December and January are the worst of it")
        // October is on offer, and is where a debug start begins.
        XCTAssertTrue(rail.departures.contains { $0.year == 1869 && $0.month == 9 })
        XCTAssertEqual(nearing("elko").dateText.hasPrefix("October"), true)
        has(card.monthAdvice, "October.")
        has(card.monthIntro, "May 1869")
        XCTAssertTrue(rail.departures.allSatisfy { ($0.year, $0.month) >= (1869, 5) }, "nobody leaves before the last spike")
    }

    // MARK: A train's words

    func testTheStatusBoxIsATrains() {
        var g = nearing("elko")
        let w = skin.words(g)
        let rows = StatusPanel.stores(rail, g, w)
        XCTAssertEqual(rows.map(\.label), ["Provisions", "Tank car", "Firewood"])
        XCTAssertEqual(rows.map(\.value), ["250 lbs", "900 gallons", "12 cords"])
        XCTAssertEqual(w.meters.0, "Running gear")
        XCTAssertEqual(w.meters.1, "Engine")
        XCTAssertEqual(w.travelled, "Covered")
        XCTAssertEqual(w.distanceUnit, "miles")
        XCTAssertEqual(w.distance(1776), "1,776")
        XCTAssertEqual(w.leaderTag, "conductor")

        // One cord is a cord, and part of one is written as part of one.
        g.fuel = 10
        XCTAssertEqual(StatusPanel.stores(rail, g, skin.words(g)).last?.value, "1 cord")
        g.fuel = 39
        XCTAssertEqual(StatusPanel.stores(rail, g, skin.words(g)).last?.value, "3.9 cords")

        // The supplies list: no row for a thing a train does not carry.
        let list = SuppliesView.rows(rail, g, w).map(\.0)
        XCTAssertEqual(list, ["Cash", "Firewood", "Tank water", "Provisions", "Blankets", "Medicine kits",
                              "Boiler fittings", "Car spares", "Grapnel line"])
        let casts = SuppliesView.rows(rail, g, w).last?.1
        XCTAssertEqual(casts, "60 casts")
    }

    func testTheStoreSellsByTheCordAndTheHundredGallons() {
        let w = skin.words(nearing("elko"))
        func label(_ key: ItemKey, at port: String) -> String {
            let it = rail.item(key)
            return ShopView.priceLabel(it, rail.port(port)!.price(key), w.currency, lot: w.lots.contains(key))
        }
        XCTAssertEqual(label(.fuel, at: "omaha"), "$4/cord")
        XCTAssertEqual(label(.water, at: "omaha"), "$2/100 gallons")
        XCTAssertEqual(label(.food, at: "omaha"), "$0.12/lb")
        XCTAssertEqual(label(.fuel, at: "cheyenne"), "$7.28/cord")
        XCTAssertEqual(label(.water, at: "cheyenne"), "$2.60/100 gallons")
        XCTAssertEqual(label(.fuel, at: "reno"), "$2.60/cord")
        has(w.priceNote(30), "30% above Omaha")
    }

    /// Every string reachable in `value`: the words as data, without the closures.
    func strings(_ value: Any) -> [String] {
        if let s = value as? String { return [s] }
        return Mirror(reflecting: value).children.flatMap { strings($0.value) }
    }

    /// Everything the skin can say, at every stop, for every role.
    func everythingSaid() -> [String] {
        var out = strings(card) + [card.resume("Wren")]
        let forage = skin.forage
        out += [forage.heading, forage.throwsLabel, forage.caughtLabel, forage.timeLabel, forage.hint("4 cords"),
                forage.label(3), forage.actionHint, forage.leave, skin.chart.title]
        out += rail.quarry.flatMap { [forage.pop("1", $0), forage.pop("1.4", $0)] }
        for i in rail.stops.indices.dropFirst() {
            for role in Role.allCases {
                for (port, day) in [(false, 10), (true, 80)] {
                    var g = skin.debug.start(i, 9)
                    g.role = role
                    g.day = day
                    g.atPort = port
                    g.clothes = port ? 2 : 5
                    let w = skin.words(g)
                    out += strings(w) + rail.rules.restChoices.map(w.restChoice)
                    out += [w.distance(g.mile), w.yardHull(56), w.yardSails(72), w.priceNote(30), w.burial("Bo"),
                            card.outfitIntro(g), skin.chart.label(g), skin.chart.footer(g)]
                    for weather in rail.weathers {
                        g.weather = weather
                        for moving in [false, true] {
                            out.append(skin.scene.label(ScenePicture.frame(rail, g, moving: moving, t: 0)))
                        }
                    }
                }
            }
        }
        return out
    }

    /// Every sentence the road's engine can write, read from its source: each string
    /// literal, with the code inside its interpolations taken out. The engine is not the
    /// skin, but the player reads both in the same box.
    func engineSaid() throws -> [String] {
        let dir = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("HornEngine/Journeys/Rail")
        let files = try fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil).filter { $0.pathExtension == "swift" }
        XCTAssertGreaterThanOrEqual(files.count, 4, "the road's engine is in \(dir.path)")
        let literal = try NSRegularExpression(pattern: #""((?:[^"\\\n]|\\.)*)""#)
        let code = try NSRegularExpression(pattern: #"\\\((?:[^()]|\([^()]*\))*\)"#)
        var out: [String] = []
        for file in files {
            for line in try String(contentsOf: file, encoding: .utf8).split(separator: "\n").map(String.init)
            where !line.trimmingCharacters(in: .whitespaces).hasPrefix("//") {
                for m in literal.matches(in: line, range: NSRange(line.startIndex..., in: line)) {
                    let s = String(line[Range(m.range(at: 1), in: line)!])
                    out.append(code.stringByReplacingMatches(in: s, range: NSRange(s.startIndex..., in: s), withTemplate: ""))
                }
            }
        }
        // And what it says through the shell's own sentences.
        out += rail.items.flatMap { it in [1, 2].map { rail.describe(.item(it.key), Double(it.per * $0)) } }
        return out
    }

    func testNothingOnTheRoadIsSaidInASailorsWords() throws {
        let said = everythingSaid()
        XCTAssertGreaterThan(Set(said).count, 150, "the walk found the words")
        // A landsman may still reach for a ship to say what a trestle feels like.
        let figures = ["like a ship at a dock", "I'd fish for it"]
        let engine = try engineSaid().map { s in figures.reduce(s) { $0.replacingOccurrences(of: $1, with: "") } }
        XCTAssertGreaterThan(Set(engine).count, 300, "the source was read")
        let sea = try NSRegularExpression(
            pattern: #"\b(ships?|shipyard|sail(s|ed|ing)?|captain|seas?|ocean|nm|nautical|knots?|anchor(s|ed)?|harpoons?|"#
                + #"fish(ing|ed)?|voyages?|hull|masts?|deck|harbou?r|ports?|scurvy|citrus|limes?|leagues?)\b"#,
            options: [.caseInsensitive])
        for s in Set(said + engine) {
            let m = sea.firstMatch(in: s, range: NSRange(s.startIndex..., in: s))
            XCTAssertNil(m, "a sailor's word in “\(s)”")
        }
        // The same sieve does catch a ship: 1849's words are full of them.
        let old = strings(Horn1849Skin.skin.words(Horn1849Skin.skin.debug.start(3, 0))).joined(separator: "\n")
        XCTAssertNotNil(sea.firstMatch(in: old, range: NSRange(old.startIndex..., in: old)))
    }

    /// What a trader offers is said once per unit, and the departure has one full stop.
    func testTradesAndTheDepartureReadRight() {
        XCTAssertEqual(rail.describe(.item(.meds), 3), "3 medicine kits")
        XCTAssertEqual(rail.describe(.item(.clothes), 1), "1 wool blanket")
        XCTAssertEqual(rail.describe(.item(.clothes), 2), "2 wool blankets")
        XCTAssertEqual(rail.describe(.item(.fuel), 30), "3 cords of firewood")
        XCTAssertEqual(rail.describe(.item(.sailcloth), 1), "1 set of boiler fittings")
        for it in rail.items {
            let said = rail.describe(.item(it.key), Double(it.per * 2))
            XCTAssertEqual(said.components(separatedBy: it.unit).count, 2, "“\(it.unit)” once in “\(said)”")
        }
        var g = nearing("northplatte")
        for day in 0..<6 {
            g.day = day
            let depart = rail.text.depart(g)
            XCTAssertFalse(depart.contains(".."), depart)
            has(depart, g.dateText)
        }
    }

    // MARK: The picture

    func frame(_ g: GameState, hour: Int = 12, moving: Bool = true) -> SceneFrame {
        SceneFrame(t: 0, weather: g.weather, moving: moving, atPort: g.atPort, hull: g.hull, sails: g.sails,
                   region: g.region, hour: hour, state: g)
    }

    func picture(_ f: SceneFrame, t: Double = 0.37) -> Int {
        let px = PixelCanvas(w: SceneSkin.w, h: SceneSkin.h)
        skin.scene.draw(px, f.at(t))
        return px.tally.picture
    }

    func testEveryStretchOfCountryIsItsOwnPicture() {
        var seen: [Int: String] = [:]
        for region in rail.regions {
            var g = nearing("elko")
            g.weather = rail.fairWeather
            g.mile = region.to - 5
            XCTAssertEqual(g.region.id, region.id)
            let pic = picture(frame(g))
            XCTAssertNil(seen[pic], "\(region.name) looks just like \(seen[pic] ?? "")")
            seen[pic] = region.name
            XCTAssertEqual(pic, picture(frame(g)), "the same place twice is the same picture")
        }
        XCTAssertEqual(seen.count, 13)
    }

    func testTheTrestleTheYardTheNightAndTheWearAllShow() {
        var g = nearing("elko")
        g.weather = rail.fairWeather
        g.hull = 100
        g.sails = 100
        let plain = picture(frame(g))

        // Dale Creek: the trestle inside Sherman Hill once the train has reached it, and
        // the label says so; not on the way there, with the stop still ahead.
        let dale = rail.stop("dalecreek")!
        var hill = g, bridge = g, approach = g
        hill.mile = 565
        hill.stopIndex = stopIndex("dalecreek")
        bridge.mile = dale.mile
        bridge.stopIndex = stopIndex("dalecreek")
        approach.mile = dale.mile - 3
        approach.stopIndex = stopIndex("cheyenne")
        XCTAssertEqual(hill.region.id, bridge.region.id)
        XCTAssertEqual(approach.region.id, bridge.region.id)
        XCTAssertNotEqual(picture(frame(hill)), picture(frame(bridge)))
        has(skin.scene.label(frame(bridge)), "Dale Creek trestle")
        XCTAssertFalse(skin.scene.label(frame(hill)).contains("trestle"))
        XCTAssertFalse(skin.scene.label(frame(approach)).contains("trestle"), "not before the stop")

        // A yard at a stop.
        var yard = g
        yard.atPort = true
        XCTAssertNotEqual(picture(frame(yard, moving: false)), picture(frame(g, moving: false)))

        // Night.
        XCTAssertNotEqual(picture(frame(g, hour: 23)), plain)
        has(skin.scene.label(frame(g, hour: 23)), "by night")
        XCTAssertFalse(skin.scene.label(frame(g, hour: 12)).contains("by night"))

        // Wear: each meter shows on its own, and worse shows more.
        var engine = g, gear = g, wreck = g
        engine.sails = 10
        gear.hull = 10
        wreck.sails = 10
        wreck.hull = 10
        let pics = [plain, picture(frame(engine)), picture(frame(gear)), picture(frame(wreck))]
        XCTAssertEqual(Set(pics).count, 4, "a tired engine and tired running gear are each drawn")

        // The train is in the picture standing or rolling, and rolling is not standing.
        XCTAssertNotEqual(picture(frame(g, moving: false)), plain)
    }

    // MARK: The map

    func testTheMapHasEveryStopOnTheRoad() {
        let road = RailChart.road
        for stop in rail.stops {
            XCTAssertTrue(road.contains { Int($0.2) == stop.mile }, "\(stop.id) is not a point on the map's road")
        }
        XCTAssertEqual(road.first?.2, 0)
        XCTAssertEqual(road.last?.2, Double(rail.totalMiles))
        for (a, b) in zip(road, road.dropFirst()) {
            XCTAssertLessThan(a.2, b.2, "miles only go up")
            XCTAssertGreaterThan(a.0, b.0, "and the road only goes west")
        }
        let chart = RailChart.skin
        for point in road {
            let q = RailChart.project((point.0, point.1))
            XCTAssertTrue((4...chart.w - 4).contains(q.x) && (4...chart.h - 4).contains(q.y), "mile \(point.2) is off the map")
        }
        let g = nearing("northplatte")
        XCTAssertEqual(chart.footer(g), "281 of 1,776 miles covered. 1,495 to go. The ringed stops have a yard.")
        XCTAssertEqual(chart.label(g), "Map of the railroad from Omaha to Sacramento. You are in \(RailChart.place(g)).")
        XCTAssertFalse(RailChart.place(g).hasPrefix("The "), "mid-sentence")
        // A ring for every yard: four strokes each, and the two ends named.
        let yards = rail.stops.filter { $0.type == .port }
        XCTAssertEqual(yards.count, rail.ports.count)
        let rings = PixelCanvas(w: chart.w, h: chart.h)
        RailChart.names(rings)
        XCTAssertEqual(rings.tally.marks, yards.count * 4 + 2)
        for stop in yards {
            let at = road.first { Int($0.2) == stop.mile }!
            let q = RailChart.project((at.0, at.1))
            XCTAssertTrue(rings.tally.bounds?.contains(CGPoint(x: q.x, y: q.y)) ?? false, "\(stop.id) has no ring")
        }
    }

    /// Where the road is at `mile`, between the map's points.
    func onTheRoad(_ mile: Double) -> RailChart.Point {
        let road = RailChart.road
        let i = road.firstIndex { $0.2 >= mile }!
        guard i > 0 else { return (road[0].0, road[0].1) }
        let a = road[i - 1], b = road[i], t = (mile - a.2) / (b.2 - a.2)
        return (a.0 + (b.0 - a.0) * t, a.1 + (b.1 - a.1) * t)
    }

    /// The stippled deserts are where the boiler drinks from the tank car, and the road
    /// keeps to the shore of the Salt Lake.
    func testTheMapsDesertsAreTheDryCountry() {
        func inADesert(_ p: RailChart.Point) -> Bool {
            RailChart.deserts.contains { (p.lon >= $0.0 && p.lon <= $0.1) && (p.lat >= $0.2 && p.lat <= $0.3) }
        }
        var from = 0
        for reg in rail.regions {
            // A couple of miles' grace at each end, where a stop stands on the line.
            for mile in stride(from: from + 3, through: reg.to - 3, by: 1) {
                XCTAssertEqual(inADesert(onTheRoad(Double(mile))), reg.has("dry"),
                               "mile \(mile), in \(reg.name), on the map")
            }
            from = reg.to
        }
        // Inside the lake by the even-odd rule, a step at a time along the road.
        func inTheLake(_ p: RailChart.Point) -> Bool {
            let lake = RailChart.saltLake
            var inside = false
            for (a, b) in zip(lake, Array(lake.dropFirst()) + [lake[0]]) where (a.lat > p.lat) != (b.lat > p.lat) {
                if p.lon < a.lon + (p.lat - a.lat) / (b.lat - a.lat) * (b.lon - a.lon) { inside.toggle() }
            }
            return inside
        }
        for mile in stride(from: 0.0, through: Double(rail.totalMiles), by: 0.5) {
            XCTAssertFalse(inTheLake(onTheRoad(mile)), "mile \(mile) is in the Salt Lake")
        }
    }

    // MARK: Driftwood

    func testDriftwoodIsCountedInCords() {
        let w = skin.words(nearing("northplatte"))
        let reward = FishingView.reward(rail, w)
        XCTAssertEqual(reward.item.key, .fuel)
        XCTAssertEqual(reward.measure(39), "3.9 cords")
        XCTAssertEqual(reward.measure(10), "1 cord")
        XCTAssertEqual(reward.measure(rail.role(.merchant).catchLimit), "4 cords")
        XCTAssertEqual(reward.measure(rail.role(.whaler).catchLimit), "6 cords")
        let forage = skin.forage
        for wood in rail.quarry {
            has(forage.pop("1", wood), "+1 cord, ")
            has(forage.pop("1.4", wood), "+1.4 cords, ")
            XCTAssertLessThanOrEqual(wood.lb, rail.role(.merchant).catchLimit, "\(wood.name) is in tenths of a cord")
        }
        XCTAssertFalse(rail.quarry.isEmpty)
        // Thrown from the bank at the bottom, at wood going one way on the current.
        XCTAssertTrue(forage.field.upward)
        XCTAssertTrue(forage.field.oneWay)
        XCTAssertGreaterThan(forage.field.origin.y, forage.field.h * 0.75)
        XCTAssertEqual(forage.throwsLabel, "Casts")

        // The longest a pop can be stays on the field, wherever the hit; where it fits it
        // stands where it always did, just left of the hit.
        let px = PixelCanvas(w: forage.field.w, h: forage.field.h)
        for wood in rail.quarry {
            let pop = forage.pop(reward.count(rail.role(.whaler).catchLimit), wood)
            let width = px.width(pop, size: 8)
            for hit in stride(from: 0.0, through: forage.field.w, by: 2) {
                let x = FishingView.popX(hit, width: width, field: forage.field.w)
                XCTAssertTrue(x >= 0 && x + width <= forage.field.w, "“\(pop)” at \(hit) runs off the field")
            }
        }
        XCTAssertEqual(FishingView.popX(100, width: 40, field: 160), 94)
        XCTAssertEqual(forage.caughtLabel, "Hauled")
    }

    // MARK: Two voyages at once

    func controller() -> GameController {
        let c = GameController(persistence: p, journeys: Journeys.all, skins: Skins.all)
        c.tickInterval = .seconds(3600)
        return c
    }

    /// D22: a river hand can spend the purse below a step of provisions ($3) with none
    /// aboard. The outfitter then leads to the departure, never round the engine's refusal
    /// again, and the run ends.
    func testARiverHandWithNothingLeftForProvisionsStillLeavesOmaha() {
        let c = controller()
        c.chooseJourney(rail.id)
        c.startNewGame()
        c.chooseRole(.whaler)
        c.setNames(ship: "", captain: "Ira", crew: ["", "", "", ""])
        c.chooseDeparture(year: 1869, month: 9)
        c.enterFirstShop()
        guard case .shop(let done) = c.screen else { return XCTFail("\(c.screen)") }
        // Everything but provisions, as much of each as the purse runs to.
        c.run { e in
            for it in e.journey.items where it.key != .food {
                var n = e.room(for: it.key)
                while n > 0 && !e.buy([it.key: n]) { n -= 1 }
            }
        }
        XCTAssertLessThan(c.game!.money, rail.firstPortStep(.food))
        XCTAssertEqual(c.game!.food, 0)
        done()
        guard case .depart(let text) = c.screen else { return XCTFail("the departure, not \(c.screen)") }
        has(text, Rail.goingHungry)
        XCTAssertFalse(c.game!.atPort)
        c.run { $0.rng = SeededRNG(seed: 7) }
        c.startTravel()
        let end = playOut(c)
        XCTAssertTrue(["finale", "gameover"].contains(end), end)
    }

    /// Answers whatever the road raises, first open option each time, until it ends.
    /// With `restock`, a little more care: wood, water, food and spares at every yard
    /// it can afford, the roundhouse when the train is worn, and a repair on the road
    /// when the engine is failing.
    func playOut(_ c: GameController, maxSteps: Int = 5_000, restock: Bool = false) -> String {
        for _ in 0..<maxSteps {
            switch c.screen {
            case .travel:
                let g = c.game!
                if restock && (g.sails < 40 || g.hull < 40) && (g.sailcloth >= 1 || g.timber >= 1) {
                    c.heaveTo()
                    if g.sails < 40 && g.sailcloth >= 1 { c.mendSails() } else if g.timber >= 1 { c.patchHull() }
                    continue
                }
                c.tick()
            case .repairs, .shipyard: c.backToMenu()
            case .message(_, _, let then): then()
            case .choice(let e): c.choose(e, option: e.options.firstIndex(where: \.enabled)!)
            case .burial(let id, let cause): c.bury(crewID: id, cause: cause, epitaph: "")
            case .portMenu:
                if restock {
                    c.run { e in
                        let wood = max(0, 16 - Int(e.state.fuel / 10))
                        let water = max(0, (1200 - Int(e.state.water)) / 100)
                        let food = max(0, (300 - Int(e.state.food)) / 25)
                        _ = e.buy([.fuel: wood, .water: water, .food: food]) || e.buy([.fuel: wood]) || e.buy([.fuel: wood / 2])
                        if e.state.sailcloth < 2 { _ = e.buy([.sailcloth: 1]) }
                        if e.state.timber < 2 { _ = e.buy([.timber: 1]) }
                    }
                    let g = c.game!
                    if g.hull < 70 && c.read({ $0.canRepairHullAtYard }) {
                        c.repairHullAtYard()
                        continue
                    }
                    if g.sails < 70 && c.read({ $0.canRecutSailsAtYard }) {
                        c.recutSailsAtYard()
                        continue
                    }
                }
                c.startTravel()
            case .seaMenu: c.startTravel()
            case .finale: return "finale"
            case .gameOver: return "gameover"
            default:
                XCTFail("stuck on \(c.screen)")
                return "stuck"
            }
        }
        return "too long"
    }

    /// Answers what one action raised, until the voyage is back on a menu, moving or over.
    func settle(_ c: GameController) -> [String] {
        var said: [String] = []
        for _ in 0..<200 {
            switch c.screen {
            case .message(let t, _, let then):
                said.append(t)
                then()
            case .choice(let e): c.choose(e, option: e.options.firstIndex(where: \.enabled)!)
            case .burial(let id, let cause): c.bury(crewID: id, cause: cause, epitaph: "")
            default: return said
            }
        }
        return said
    }

    /// Both journeys begun and left: one voyage each on file.
    func bothUnderWay(_ c: GameController) -> (horn: GameState, rail: GameState) {
        let sea = Horn1849Skin.skin.debug.start(3, 0), road = nearing("sacramento")
        c.chooseJourney(horn.id)
        c.loadForDebug(sea)
        c.leaveVoyage()
        c.goToPicker()
        c.chooseJourney(rail.id)
        c.loadForDebug(road)
        c.leaveVoyage()
        c.goToPicker()
        return (sea, road)
    }

    func testTheAppOpensOnThePickerWithBothJourneys() {
        let c = controller()
        guard case .picker = c.screen else { return XCTFail("\(c.screen)") }
        XCTAssertEqual(Array(c.journeys.map(\.id).prefix(2)), [Horn1849.id, Rail.id])
        XCTAssertTrue(c.hasPicker)
        XCTAssertEqual(c.inProgress, [])
        c.chooseJourney(Rail.id)
        guard case .title = c.screen else { return XCTFail("\(c.screen)") }
        XCTAssertEqual(c.skin.id, Rail.id)
        XCTAssertEqual(c.journey.title, "The Iron Road")
        // And next time, straight to the journey last chosen.
        let again = GameController(persistence: p, journeys: Journeys.all, skins: Skins.all)
        guard case .title = again.screen else { return XCTFail("\(again.screen)") }
        XCTAssertEqual(again.journey.id, Rail.id)
    }

    func testTwoVoyagesUnderWayEachKeepTheirOwnSave() {
        let c = controller()
        let (sea, road) = bothUnderWay(c)
        guard case .picker = c.screen else { return XCTFail("\(c.screen)") }
        XCTAssertEqual(c.inProgress, [horn.id, rail.id])
        XCTAssertEqual(p.loadSave(horn.id), sea)
        XCTAssertEqual(p.loadSave(rail.id), road)
        XCTAssertNotEqual(p.saveURL(horn.id), p.saveURL(rail.id))

        // Each title card offers its own voyage back, in its own words.
        c.chooseJourney(rail.id)
        XCTAssertEqual(c.savedVoyage, road)
        c.continueSavedVoyage()
        XCTAssertEqual(c.game, road)
        XCTAssertEqual(c.skin.id, rail.id)
        XCTAssertEqual(c.skin.words(c.game!).halt, "Stop the train & take stock")

        // A day's rest on the road moves the train's clock and not the ship's.
        c.rest(days: 6)
        _ = settle(c)
        guard case .seaMenu = c.screen else { return XCTFail("\(c.screen)") }
        let later = c.game!
        XCTAssertEqual(later.day, road.day + 6)
        c.leaveVoyage()
        XCTAssertEqual(p.loadSave(rail.id), later)
        XCTAssertEqual(p.loadSave(horn.id), sea, "the ship has not moved")

        c.goToPicker()
        c.chooseJourney(horn.id)
        c.continueSavedVoyage()
        XCTAssertEqual(c.game, sea)
        XCTAssertEqual(c.skin.id, horn.id)
        c.startTravel()
        c.tick()
        _ = settle(c)
        c.leaveVoyage()
        XCTAssertNotEqual(p.loadSave(horn.id), sea, "the ship has")
        XCTAssertEqual(p.loadSave(horn.id)?.journey, horn.id)
        XCTAssertEqual(p.loadSave(rail.id), later, "and the train has not")
    }

    func testATrainsArrivalEntersOnlyTheRoadsTopTen() throws {
        let c = controller()
        let (sea, _) = bothUnderWay(c)
        let hornTable = p.topTen(horn), railTable = p.topTen(rail)
        XCTAssertEqual(railTable, rail.defaultTopTen)
        XCTAssertNotEqual(hornTable, railTable)

        c.chooseJourney(rail.id)
        c.continueSavedVoyage()
        XCTAssertEqual(playOut(c), "finale")
        guard case .finale(let f) = c.screen else { return XCTFail("\(c.screen)") }
        let place = try XCTUnwrap(f.place, "ten days in hand beats the tenth score")
        XCTAssertEqual(f.rank, rail.rank(f.score.total))
        XCTAssertTrue(f.score.lines.contains { $0.label == Rail.onTimeLabel && $0.points > 0 })
        XCTAssertEqual(p.topTen(rail)[place], TopTenEntry(name: "Amos", score: f.score.total))
        XCTAssertEqual(p.topTen(rail).count, railTable.count)
        XCTAssertEqual(p.topTen(horn), hornTable, "1849's table is as it was")
        XCTAssertFalse(fm.fileExists(atPath: p.topTenURL(horn.id).path), "and was never written")

        XCTAssertNil(p.loadSave(rail.id), "the run is over")
        XCTAssertEqual(p.loadSave(horn.id), sea, "the ship is still at sea")
        c.goToPicker()
        XCTAssertEqual(c.inProgress, [horn.id])
    }

    func testAForfeitEndsOnlyTheTrainsRun() {
        let c = controller()
        let (sea, _) = bothUnderWay(c)
        let hornTable = p.topTen(horn), railTable = p.topTen(rail)

        c.chooseJourney(rail.id)
        c.continueSavedVoyage()
        c.run { $0.state.day = RailData.forfeitTurns - 7 }
        // Six turns short of sixteen days: a day's rest uses them up.
        c.rest(days: 6)
        let said = settle(c)
        XCTAssertTrue(said.contains { $0.contains("The freight is now late.") }, "\(said)")
        guard case .seaMenu = c.screen else { return XCTFail("\(c.screen) after \(said)") }
        XCTAssertNotNil(p.loadSave(rail.id), "one turn in hand")
        c.rest(days: 1)
        // Whatever else the last turn brought (a fever, a kit opened) comes first.
        _ = settle(c)
        guard case .gameOver(let title, let body) = c.screen else { return XCTFail("\(c.screen)") }
        XCTAssertEqual(title, "The contract is forfeit.")
        has(body, "Sixteen days out of Omaha")

        XCTAssertNil(p.loadSave(rail.id), "no run to go back to")
        XCTAssertEqual(p.topTen(rail), railTable, "and no score for it")
        XCTAssertEqual(p.loadSave(horn.id), sea, "the ship is still at sea")
        XCTAssertEqual(p.topTen(horn), hornTable)
        c.goToPicker()
        XCTAssertEqual(c.inProgress, [horn.id])
    }

    func testAShipsArrivalLeavesTheTrainOnTheRoad() throws {
        let c = controller()
        let (_, road) = bothUnderWay(c)
        let railTable = p.topTen(rail)

        c.chooseJourney(horn.id)
        c.continueSavedVoyage()
        c.run { $0.state.mile = self.horn.totalMiles - 10; $0.state.stopIndex = self.horn.stops.count - 2 }
        XCTAssertEqual(playOut(c), "finale")
        guard case .finale(let f) = c.screen else { return XCTFail("\(c.screen)") }
        XCTAssertNil(p.loadSave(horn.id))
        if let place = f.place { XCTAssertEqual(p.topTen(horn)[place].score, f.score.total) }
        XCTAssertEqual(p.loadSave(rail.id), road, "the train is still on the road")
        XCTAssertEqual(p.topTen(rail), railTable)
        XCTAssertFalse(fm.fileExists(atPath: p.topTenURL(rail.id).path))
        c.goToPicker()
        XCTAssertEqual(c.inProgress, [rail.id])
    }

    /// A whole run from the title card, the way a player's taps would make it: the
    /// store at Omaha, the road, wood and water bought at every yard, and whichever
    /// ending the dice bring. The dice are seeded, so the runs are always the same ones,
    /// and Sacramento is among the endings.
    func testAWholeRunFromTheTitleCardReachesAnEnding() {
        var endings: [String] = []
        for round in 0..<4 {
            let c = controller()
            c.chooseJourney(rail.id)
            c.startNewGame()
            c.chooseRole(Role.allCases[round % Role.allCases.count])
            c.setNames(ship: "", captain: "Ira", crew: ["", "", "", ""])
            c.chooseDeparture(year: 1869, month: 9)
            c.run { $0.rng = SeededRNG(seed: UInt64(round + 1)) }
            XCTAssertTrue(rail.vesselNames.contains(c.game!.ship))
            c.enterFirstShop()
            guard case .shop(let done) = c.screen else { return XCTFail("\(c.screen)") }
            c.run { $0.buy([.fuel: 16, .water: 300, .food: 150, .clothes: 5]) }
            done()
            guard case .depart = c.screen else { return XCTFail("\(c.screen)") }
            c.startTravel()
            let end = playOut(c, maxSteps: 20_000, restock: true)
            endings.append(end)
            XCTAssertNil(p.loadSave(rail.id), "no save after the run ends")
            XCTAssertFalse(c.traveling)
        }
        XCTAssertTrue(Set(endings).isSubset(of: ["finale", "gameover"]), "\(endings)")
        XCTAssertTrue(endings.contains("finale"), "a run can reach Sacramento: \(endings)")
    }
}
