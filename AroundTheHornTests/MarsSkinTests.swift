import XCTest
@testable import HornEngine
@testable import AroundTheHorn

/// The Long Transfer's skin, held to its own journey's tables: every number its sentences
/// state, the words a freighter needs and the ones it must not borrow from a ship under
/// sail, a train, an airship or a balloon, the sky over every stretch of the arc, every
/// stop and station in the picture, the plot, and the grapple. `SkinContractTests` asks
/// what every skin owes the shell; this asks what this one says. It ends with whole
/// transfers from the title card to an ending.
@MainActor
final class MarsSkinTests: XCTestCase {
    let mars = MarsSkin.journey
    let skin = MarsSkin.skin
    let card = MarsSkin.card
    let fm = FileManager.default
    var p: Persistence!

    override func setUp() async throws {
        p = Persistence(directory: fm.temporaryDirectory.appendingPathComponent(UUID().uuidString),
                        defaults: UserDefaults(suiteName: UUID().uuidString)!)
    }

    func stopIndex(_ id: String) -> Int { mars.stops.firstIndex { $0.id == id }! }

    /// 100,000 km short of `stop`, in October, as the debug start leaves it.
    func nearing(_ stop: String) -> GameState { skin.debug.start(stopIndex(stop), 9) }

    /// Standing at `stop`, its arrival told; docked if `port`.
    func at(_ stop: String, port: Bool = false) -> GameState {
        var g = nearing(stop)
        MarsSkin.at(&g, stop, port: port)
        return g
    }

    func flying(_ mile: Int) -> GameState {
        var g = nearing("cycler")
        MarsSkin.fly(&g, mile)
        g.weather = mars.fairWeather
        return g
    }

    func has(_ text: String, _ part: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(text.contains(part), "“\(part)” is not in “\(text)”", file: file, line: line)
    }

    func state(month: Int = 9) -> GameState {
        GameState(journey: Mars.id, role: .merchant, ship: "Wren", captain: "Ada", crew: ["Bo", "Cy", "Di", "Ed"],
                  startYear: 2087, startMonth: month)
    }

    // MARK: Days and millions of kilometres

    func testTurnsAreDaysAndDistancesAreMillionsOfKilometres() {
        XCTAssertEqual(mars.rules.tickHours, 24)
        XCTAssertEqual(mars.totalMiles, 48_000)
        let w = skin.words(nearing("midway"))
        XCTAssertEqual(mars.rules.restChoices.map(w.restChoice), ["1 day", "2 days", "3 days", "5 days"])
        has(w.repairsNote, "Each repair takes a day.")
        has(w.yardIntro, "Each job takes a day.")
        XCTAssertEqual(w.distanceUnit, "million km")
        XCTAssertEqual(w.distance(31_245), "312.45")
        XCTAssertEqual(w.distance(48_000), "480.00")
        XCTAssertEqual(w.distance(38), "0.38")
        XCTAssertEqual(w.distance(5), "0.05")
        XCTAssertEqual(w.distance(0), "0.00")
        // Written as the engine writes them, at every stop.
        for stop in mars.stops { XCTAssertEqual(MarsSkin.km(stop.mile), MarsData.km(stop.mile), stop.id) }
        XCTAssertEqual(MarsSkin.tenth(5 * 0.55), "2.8")
        XCTAssertEqual(MarsSkin.tenth(4), "4")
        // The status box: "312.45 of 480.00 million km".
        var g = nearing("midway")
        g.mile = 31_245
        XCTAssertEqual("\(w.distance(g.mile)) of \(w.distance(mars.totalMiles)) \(w.distanceUnit)", "312.45 of 480.00 million km")
    }

    // MARK: Numbers the card states

    func testTheCardsNumbersAreTheTables() {
        let all = card.learnPages.flatMap(\.paragraphs) + card.differences + card.outfitBullets
            + [card.tagline, card.monthIntro, card.monthAdvice]
        let text = all.joined(separator: "\n")

        // The arc and its stations.
        has(card.tagline, "Four hundred and eighty million kilometres")
        has(text, "480 million km along the transfer arc")
        XCTAssertEqual(mars.stop("cycler")!.mile, 15_500)
        has(text, "the cycler [i]Perpetua[/i], passing through at 155 million km")
        XCTAssertEqual(mars.stop("midway")!.mile, 30_000)
        has(text, "Midway Depot at 300")
        XCTAssertEqual(mars.totalMiles - mars.stop("phobos")!.mile, 700)
        has(text, "Phobos Yard, 7 million short of the landing")
        XCTAssertEqual(mars.ports.count, 4)
        has(text, "four places to tie up")
        XCTAssertEqual(mars.stop("midway")!.mile - mars.stop("cycler")!.mile, 14_500)
        has(text, "the next station is 145 million km on")
        XCTAssertEqual(state().crew.count, 5)
        has(text, "a crew of five counting yourself")

        // The contract.
        XCTAssertEqual(MarsSkin.contractDays, MarsData.contractDays)
        XCTAssertEqual(MarsSkin.bonusPerDay, MarsData.bonusPerDay)
        has(text, "a bonus for every day under 170")
        XCTAssertEqual(mars.item(.meds).price, 9)
        has(text, "a $9 medical kit")

        // Who you are.
        for (role, money) in [(Role.merchant, "$1,500"), (.shipwright, "$850"), (.whaler, "$625")] {
            let info = mars.role(role)
            XCTAssertEqual("$" + formatNumber(info.money), money)
            let line = card.differences.first { $0.lowercased().contains(info.title) }
            XCTAssertNotNil(line, "\(role)")
            has(line ?? "", "starts with \(money).")
        }
        XCTAssertGreaterThan(mars.role(.shipwright).mend, mars.role(.merchant).mend)
        XCTAssertGreaterThan(mars.role(.shipwright).patch, mars.role(.merchant).patch)
        XCTAssertGreaterThan(mars.role(.whaler).aim, mars.role(.merchant).aim)
        XCTAssertEqual(mars.role(.whaler).catchLimit, 100)
        XCTAssertEqual(mars.role(.merchant).catchLimit, 60)
        XCTAssertEqual(mars.role(.shipwright).catchLimit, 60)
        has(text, "takes 100 litres from an outing where the others manage 60")
        XCTAssertEqual(Role.shipwright.scoreMultiplier, 2)
        XCTAssertEqual(Role.whaler.scoreMultiplier, 3)
        has(text, "the rigger's counts double, the hauler's triple")

        // Propellant.
        let fuel = mars.item(.fuel)
        XCTAssertEqual(fuel.per, 10)
        XCTAssertEqual(mars.pace(.steady).fuel, 10)
        XCTAssertEqual(mars.pace(.easy).fuel, 7)
        XCTAssertEqual(mars.pace(.full).fuel, 16)
        has(text, "a tonne a day at cruise, 0.7 at an economy burn, 1.6 at a hard burn")
        XCTAssertEqual(fuel.max, 100)
        has(text, "The tanks hold 100 tonnes")
        XCTAssertEqual(mars.rules.noFuelSpeed, 0.4)
        has(text, "she coasts at four tenths of her speed")
        XCTAssertEqual(MarsData.tumbleWear, 1)
        has(text, "power & drive loses a point a day")
        // Gateway to the Perpetua at cruise, with full power and October's geometry.
        XCTAssertEqual(MarsData.window[9], 1)
        XCTAssertEqual((Double(mars.stop("cycler")!.mile) / mars.pace(.steady).speed).rounded(), 42)
        has(text, "about 42 days at cruise")
        // Cheapest at Midway.
        let prices = ["gateway", "cycler", "midway", "phobos"].map { mars.port($0)!.price(.fuel) }
        XCTAssertEqual(prices.min(), mars.port("midway")!.price(.fuel))
        has(text, "at Midway, where it is cheapest")

        // Water, power and the hull.
        XCTAssertEqual(mars.rules.water, 2)
        XCTAssertEqual(mars.rules.hotWater, 2)
        has(text, "2 litres a head a day are gone for good")
        has(text, "the recycler loses 2 litres a head a day, 10 a day for five of you")
        XCTAssertEqual(mars.item(.water).max, 800)
        has(text, "The tanks hold 800 litres")
        XCTAssertEqual(MarsData.darkWater, 2 * mars.rules.water)
        has(text, "twice the water lost")
        var cabin = state()
        let region = mars.regions[1]
        cabin.sails = 39.9
        XCTAssertEqual(mars.temperature(cabin, in: region), .cold)
        cabin.sails = 40
        XCTAssertEqual(mars.temperature(cabin, in: region), region.temp)
        cabin.sails = 19.9
        XCTAssertEqual(mars.temperature(cabin, in: region), .freezing)
        has(text, "under 40% the crew is cold, under 20% freezing")
        XCTAssertEqual(MarsData.rigDays, 2)
        XCTAssertEqual(MarsData.rigPower, 10)
        has(text, "two days, for 10 points of power")
        XCTAssertEqual(mars.rules.deficiencyAfter, 30)
        has(text, "a month without, and they start to")
        has(text, "A month without, and bones start to thin")
        XCTAssertEqual(1 / mars.rules.preventiveUse, 50, accuracy: 1e-9)
        has(text, "a pack lasts one person 50 days")
        XCTAssertEqual(5 * mars.rations(.filling).amount, 4, accuracy: 1e-9)
        has(text, "five people on full rations eat 4 kg a day")
        XCTAssertEqual(mars.item(.tackle).per, 20)
        has(text, "fires the grapple 20 times")

        // The set pieces.
        XCTAssertEqual(MarsData.turnoverBurn, 80)
        has(text, "for 8 tonnes of propellant")
        XCTAssertEqual((Double(MarsData.turnoverGain) / mars.pace(.steady).speed).rounded(), 4)
        has(text, "about four days sooner")
        XCTAssertEqual(MarsData.captureBurn, 100)
        has(text, "costs 10 tonnes")
        XCTAssertEqual(MarsData.dockBurn, 60)
        has(text, "matching orbits to dock costs 6 tonnes")
        XCTAssertEqual(Mars.needsTheDrive, ["cycler", "turnover", "approach"])

        // The window: the 7th of August to December, October the shortest.
        XCTAssertEqual(mars.rules.startDay, 7)
        XCTAssertEqual(mars.departures.map(\.month), [7, 8, 9, 10, 11])
        XCTAssertTrue(mars.departures.allSatisfy { $0.year == 2087 })
        has(text, "on the 7th, August to December 2087")
        has(card.monthIntro, "a launch slot on the 7th of every month in it")
        let best = MarsData.window.max { $0.value < $1.value }!
        XCTAssertEqual(best.key, 9)
        has(text, "October has the shortest arc")
        has(card.monthAdvice, "October is the window")
    }

    func testTheRankLegendIsTheEnginesRanks() {
        let cuts = mars.rules.rankCuts
        XCTAssertEqual(cuts, [8000, 5000, 2500])
        let legend = cuts.map { "\(mars.rank($0)) \(formatNumber(Double($0)))+" } + [mars.rank(0)]
        XCTAssertEqual(card.rankLegend, legend.joined(separator: " · "))
    }

    // MARK: A freighter's words

    func testTheStatusBoxIsAFreighters() {
        var g = nearing("midway")
        let w = skin.words(g)
        let rows = StatusPanel.stores(mars, g, w)
        XCTAssertEqual(rows.map(\.label), ["Rations", "Water", "Propellant"])
        XCTAssertEqual(rows.map(\.value), ["300 kg", "400 litres", "60 tonnes"])
        XCTAssertEqual(w.meters.0, "Pressure hull")
        XCTAssertEqual(w.meters.1, "Power & drive")
        XCTAssertEqual(w.travelled, "Along the arc")
        XCTAssertEqual(w.leaderTag, "captain")
        XCTAssertNil(w.place, "under way, the stretch of the arc")
        for (tenths, reads) in [(5.0, "0.5 tonnes"), (10, "1 tonne"), (15, "1.5 tonnes"), (0, "0 tonnes")] {
            g.fuel = tenths
            XCTAssertEqual(StatusPanel.stores(mars, g, skin.words(g))[2].value, reads)
        }
        g.water = 1
        XCTAssertEqual(StatusPanel.stores(mars, g, skin.words(g))[1].value, "1 litre")

        let list = SuppliesView.rows(mars, g, w)
        XCTAssertEqual(list.map(\.0), ["Cash", "Rations", "Water", "Propellant", "Supplement packs", "Medical kits",
                                       "Thermal suits", "Array panels", "Hull patches", "Tether cartridges"])
        XCTAssertEqual(list[9].1, "60 shots")
        g.tackle = 1
        XCTAssertEqual(SuppliesView.rows(mars, g, w)[9].1, "1 shot")
        g.limes = 0.37
        XCTAssertEqual(SuppliesView.rows(mars, g, w)[4].1, "0.3 packs", "packs are used by the tenth")
        g.limes = 1
        XCTAssertEqual(SuppliesView.rows(mars, g, w)[4].1, "1 pack")

        // Docked, the box says where.
        let docked = at("midway", port: true)
        XCTAssertEqual(skin.words(docked).place, "Docked at Midway")
        XCTAssertNil(skin.words(at("turnover")).place)

        // Who is on it, and what the menu offers.
        XCTAssertEqual(w.bonus, "Bonus for being a charter captain")
        g.role = .shipwright
        XCTAssertEqual(skin.words(g).bonus, "Bonus for being a yard rigger")
        has(skin.words(g).repairsNote, "As a yard rigger")
        g.role = .whaler
        XCTAssertEqual(skin.words(g).bonus, "Bonus for being an ice hauler")
        XCTAssertEqual(w.forage, "Work the grapple")
        has(w.rationsNow, "With 5 aboard, that's 4 kg a day.")
        // D15: the hull's repair above power's, in the box's order.
        has(w.patch, "pressure hull")
        has(w.mend, "array panel")
    }

    func testTheContractRowCountsDaysInHandAsTheEnginePaysThem() {
        var g = nearing("midway")
        func row() -> String {
            let c = skin.words(g).clock
            XCTAssertEqual(c?.label, "Contract")
            return c?.value ?? ""
        }
        g.day = 0
        XCTAssertEqual(row(), "170 days in hand")
        g.day = 169
        XCTAssertEqual(row(), "1 day in hand")
        XCTAssertEqual(mars.score(g).lines.last?.points, MarsData.bonusPerDay, "one day in hand pays")
        g.day = 170
        XCTAssertEqual(row(), "late")
        XCTAssertEqual(mars.score(g).lines.last?.points, 0)
        XCTAssertEqual(mars.score(g).lines.last?.label, Mars.onTimeLabel)
        g.day = 172
        XCTAssertEqual(row(), "2 days late")
        // The engine's own message comes on day 170.
        let e = GameEngine(state: nearing("midway"))
        e.state.day = 169
        e.state.atPort = false
        var said: [String] = []
        for _ in 0..<3 where !e.state.over {
            said += e.sailDay().compactMap { if case .message(let t) = $0 { return t } else { return nil } }
        }
        XCTAssertTrue(said.contains { $0.contains("Day 170. The contract date has passed.") }, "\(said)")
    }

    func testTheNotesWarnOfBonesTheArrayAndDryTanks() {
        var g = nearing("midway")
        XCTAssertFalse(skin.words(g).suppliesNote.contains("[red]"))
        g.noCitrus = 16
        has(skin.words(g).suppliesNote, "[red]16 days without supplements[/red]")
        g.noCitrus = 15
        XCTAssertFalse(skin.words(g).suppliesNote.contains("supplements"))
        g.fuel = 0
        has(skin.words(g).suppliesNote, "[red]the tanks are dry[/red]")
        has(skin.words(g).paceNow, "[red]The tanks are dry: she is only coasting.[/red]")
        g.fuel = 300
        g.sails = 0.4
        has(skin.words(g).suppliesNote, "[red]the array is dark[/red]")
        has(skin.words(g).paceNow, "[red]The array is dark: she is only coasting.[/red]")
        g.clothes = 3
        XCTAssertEqual(skin.words(g).clothesWarning, "[red]Only 3 of 5 aboard have a thermal suit.[/red]")
        g.clothes = 5
        XCTAssertNil(skin.words(g).clothesWarning)
        // Before she has left, nothing is dry and nothing dark.
        var fresh = state()
        fresh.sails = 0
        XCTAssertFalse(skin.words(fresh).suppliesNote.contains("[red]"))
    }

    /// D14, as docs/journeys/mars.md specifies the row: "Ship" and what is wrong.
    func testTheStatusBoxSaysWhenTheShipIsInTrouble() {
        var g = nearing("midway")
        g.pace = .steady
        func trouble() -> String? {
            let t = skin.words(g).trouble
            if let t { XCTAssertEqual(t.label, "Ship") }
            return t?.value
        }
        XCTAssertNil(trouble())
        g.fuel = 9
        XCTAssertTrue(Mars.lastOfThePropellant(g))
        XCTAssertEqual(trouble(), "Last of the propellant", "less than a day at cruise")
        g.pace = .easy
        XCTAssertNil(trouble(), "a day at an economy burn is 0.7 tonnes")
        g.pace = .steady
        g.fuel = 10
        XCTAssertNil(trouble())
        g.fuel = 0
        XCTAssertEqual(trouble(), "Tanks dry, coasting")
        g.sails = 0.4
        XCTAssertTrue(Mars.dark(g), "shows 0%: dark")
        XCTAssertEqual(trouble(), "Array dark, tanks dry")
        g.fuel = 300
        XCTAssertEqual(trouble(), "Array dark, coasting")
        g.sails = 0.5
        XCTAssertNil(trouble(), "shows 1%")
        // Docked she is not coasting; before Gateway is left behind there is nothing to say.
        var docked = at("midway", port: true)
        docked.fuel = 0
        g = docked
        XCTAssertEqual(trouble(), "Tanks dry")
        g.sails = 0
        XCTAssertEqual(trouble(), "Array dark, tanks dry")
        g.fuel = 300
        XCTAssertEqual(trouble(), "Array dark")
        g = state()
        g.fuel = 0
        XCTAssertNil(trouble())
    }

    func testTheStoresAndThePriceNote() {
        let w = skin.words(nearing("midway"))
        func label(_ key: ItemKey, at port: String) -> String {
            ShopView.priceLabel(mars.item(key), mars.port(port)!.price(key), w.currency, lot: w.lots.contains(key))
        }
        XCTAssertEqual(label(.food, at: "gateway"), "$0.18/kg")
        XCTAssertEqual(label(.water, at: "gateway"), "$0.23/litre")
        XCTAssertEqual(label(.fuel, at: "gateway"), "$0.74/tonne")
        XCTAssertEqual(label(.tackle, at: "gateway"), "$2.75/cartridge")
        // Phobos is cheaper than Gateway, Midway dearer.
        XCTAssertEqual(Int(jsRounded((mars.port("phobos")!.mult - 1) * 100)), -20)
        XCTAssertEqual(w.priceNote(-20), "Prices here run about 20% below Gateway Yard's, give or take what is scarce.")
        XCTAssertEqual(w.priceNote(40), "Prices here run about 40% above Gateway Yard's, give or take what is scarce.")
        // A cartridge is twenty shots aboard, and the shop counts cartridges.
        var g = nearing("midway")
        g.tackle = 60
        XCTAssertEqual(Stores.have(mars.item(.tackle), g, w), "3")
        XCTAssertEqual(Stores.unit(mars.item(.tackle), count: "3", w), "cartridges")
        g.fuel = 605
        XCTAssertEqual(Stores.have(mars.item(.fuel), g, w), "60.5")
    }

    /// Every string reachable in `value`: the words as data, without the closures.
    func strings(_ value: Any) -> [String] {
        if let s = value as? String { return [s] }
        return Mirror(reflecting: value).children.flatMap { strings($0.value) }
    }

    /// Everything the skin can say, at every stop, for every role.
    func everythingSaid() -> [String] {
        var out = strings(card) + [card.resume("Wren"), card.outfitIntro(nearing("lunar"))]
        let forage = skin.forage
        out += [forage.heading, forage.throwsLabel, forage.caughtLabel, forage.timeLabel, forage.hint("100 litres"),
                forage.label(1), forage.label(3), forage.actionHint, forage.leave, skin.chart.title]
        out += mars.quarry.flatMap { [forage.pop("1", $0), forage.pop("35", $0)] }
        for i in mars.stops.indices.dropFirst() {
            for role in Role.allCases {
                for (port, day, fuel, sails) in [(false, 10, 900.0, 64.0), (true, 180, 0, 0), (false, 120, 0, 0.2)] {
                    var g = skin.debug.start(i, 9)
                    g.role = role
                    g.day = day
                    g.fuel = fuel
                    g.sails = sails
                    g.noCitrus = day
                    g.atPort = port && mars.port(g.currentStop.id) != nil
                    g.clothes = port ? 2 : 5
                    let w = skin.words(g)
                    out += strings(w) + mars.rules.restChoices.map(w.restChoice)
                    out += [w.distance(g.mile), w.yardHull(56), w.yardSails(72), w.priceNote(30), w.priceNote(-20),
                            w.burial("Bo"), skin.chart.label(g), skin.chart.footer(g)]
                    for weather in mars.weathers {
                        g.weather = weather
                        for moving in [false, true] {
                            out.append(skin.scene.label(ScenePicture.frame(mars, g, moving: moving, t: 0)))
                        }
                    }
                }
            }
        }
        for cell in skin.debug.gallery {
            let g = SceneGallery.state(mars, cell.set)
            out.append(skin.scene.label(ScenePicture.frame(mars, g, moving: cell.moving, t: 0)))
            out.append(cell.name)
        }
        out.append(skin.scene.label(ScenePicture.frame(mars, nil, moving: false, t: 0)))
        return out
    }

    /// Every sentence the transfer's engine can write, read from its source: each string
    /// literal, with the code inside its interpolations taken out.
    func engineSaid() throws -> [String] {
        let dir = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("HornEngine/Journeys/Mars")
        let files = try fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil).filter { $0.pathExtension == "swift" }
        XCTAssertGreaterThanOrEqual(files.count, 6, "the transfer's engine is in \(dir.path)")
        let literal = try NSRegularExpression(pattern: #""((?:[^"\\\n]|\\.)*)""#)
        // Interpolations, nested two deep: "\(Int(jsRound(e.state.sails)))".
        let code = try NSRegularExpression(pattern: #"\\\((?:[^()]|\((?:[^()]|\([^()]*\))*\))*\)"#)
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
        out += mars.items.flatMap { it in [1, 2].map { mars.describe(.item(it.key), Double(it.per * $0)) } }
        return out
    }

    /// Words from the other journeys' worlds: a sailing ship's, a train's, an airship's, a
    /// balloon's. A freighter is a ship with a hull and a captain, and docks at stations,
    /// so those stay.
    static let elsewhere = try! NSRegularExpression(
        pattern: #"\b(sail(s|ed|ing|ors?)?|sailcloth|shipwright|anchor(s|ed)?|harpoons?|tackle|throws?|voyages?|"#
            + #"nm|nautical|knots?|miles?|lbs?|pounds?|scurvy|citrus|limes?|whal(e|er|ers|ing)|"#
            + #"trains?|railroad|railway|locomotive|conductor|caboose|boxcars?|tender|cords?|firewood|wagons?|oxen|"#
            + #"petrol|masts?|gondola|hydrogen|propane|burners?|ballast|gallons?|helium)\b"#,
        options: [.caseInsensitive])

    func testNothingOnTheArcIsSaidInAnotherJourneysWords() throws {
        let said = everythingSaid()
        XCTAssertGreaterThan(Set(said).count, 150, "the walk found the words")
        // Phobos is small enough to throw a ball off, and spoiled rations are thrown out.
        let figures = ["throw a ball", "throw out the rest"]
        let engine = try engineSaid().map { s in figures.reduce(s) { $0.replacingOccurrences(of: $1, with: "") } }
        XCTAssertGreaterThan(Set(engine).count, 150, "the source was read")
        for s in Set(said + engine) {
            let m = Self.elsewhere.firstMatch(in: s, range: NSRange(s.startIndex..., in: s))
            XCTAssertNil(m, "another journey's word in “\(s)”: \(m.map { (s as NSString).substring(with: $0.range) } ?? "")")
        }
        // The same sieve does catch a ship, a train, an airship and a balloon.
        for other in [Horn1849Skin.skin, RailSkin.skin, AirshipSkin.skin, BalloonSkin.skin] {
            let words = strings(other.words(other.debug.start(3, other.id == Horn1849.id ? 0 : 9))).joined(separator: "\n")
                + strings(other.card).joined(separator: "\n")
            XCTAssertNotNil(Self.elsewhere.firstMatch(in: words, range: NSRange(words.startIndex..., in: words)), other.id)
        }
        // And nothing here is said in the shapes D11 retired.
        let retired = ["You may:", "Find out the differences", "Be a ", "Many kinds of people", "Filling", "Meager",
                       "Bare bones", "Attempt to trade"]
        for s in Set(said + engine + mars.roles.values.map(\.label) + Rations.allCases.map { mars.rations($0).name }) {
            for r in retired { XCTAssertFalse(s.contains(r), "“\(r)” in “\(s)”") }
        }
    }

    func testTradesAndTheDepartureReadRight() {
        XCTAssertEqual(mars.describe(.item(.meds), 3), "3 medical kits")
        XCTAssertEqual(mars.describe(.item(.clothes), 1), "1 thermal suit")
        XCTAssertEqual(mars.describe(.item(.fuel), 120), "12 tonnes of propellant")
        XCTAssertEqual(mars.describe(.item(.tackle), 40), "2 tether cartridges")
        var g = state()
        for day in 0..<4 {
            g.day = day
            let depart = mars.text.depart(g)
            XCTAssertFalse(depart.contains(".."), depart)
            has(depart, g.dateText)
        }
        has(state().dateText, "October 7, 2087")
    }

    // MARK: Leaving Gateway

    func controller() -> GameController {
        let c = GameController(persistence: p, journeys: Journeys.all, skins: Skins.all)
        c.tickInterval = .seconds(3600)
        return c
    }

    func newTransfer(_ c: GameController, role: Role = .merchant, month: Int = 9) {
        c.chooseJourney(mars.id)
        c.startNewGame()
        c.chooseRole(role)
        c.setNames(ship: "", captain: "Ira", crew: ["", "", "", ""])
        c.chooseDeparture(year: 2087, month: month)
    }

    /// Gateway won't clear her with empty tanks; with propellant and rations she leaves.
    /// Saved in the chandlery before she left, she comes back to it (D16).
    func testGatewayWontClearHerWithEmptyTanksAndASaveComesBackToTheChandlery() {
        var fresh = state()
        XCTAssertNotNil(skin.words(fresh).departRefusal)
        fresh.fuel = 50
        XCTAssertNil(skin.words(fresh).departRefusal)
        XCTAssertTrue(skin.words(fresh).resumesInFirstShop)

        let c = controller()
        newTransfer(c)
        c.enterFirstShop()
        guard case .shop(let done) = c.screen else { return XCTFail("\(c.screen)") }
        c.run { $0.buy([.food: 200]) }
        c.save()
        done()
        guard case .message(let why, _, let back) = c.screen else { return XCTFail("\(c.screen)") }
        has(why, "tanks empty")
        back()
        guard case .shop = c.screen else { return XCTFail("back to the chandlery, not \(c.screen)") }

        let again = controller()
        again.chooseJourney(mars.id)
        again.continueSavedVoyage()
        guard case .shop(let pay) = again.screen else { return XCTFail("back to the chandlery, not \(again.screen)") }
        again.run { $0.buy([.fuel: 40]) }
        again.save()
        pay()
        guard case .depart(let text) = again.screen else { return XCTFail("\(again.screen)") }
        has(text, "backs away from Gateway Yard on October 7, 2087.")
        XCTAssertFalse(again.game!.atPort)
        XCTAssertEqual(skin.words(again.game!).setOut, "Burn for Mars")
    }

    // MARK: The picture

    func frame(_ g: GameState, moving: Bool = true) -> SceneFrame {
        SceneFrame(t: 0, weather: g.weather, moving: moving, atPort: g.atPort, hull: g.hull, sails: g.sails,
                   region: g.region, hour: g.hour, state: g)
    }

    func picture(_ f: SceneFrame, t: Double = 0.37) -> Int {
        let px = PixelCanvas(w: SceneSkin.w, h: SceneSkin.h)
        skin.scene.draw(px, f.at(t))
        return px.tally.picture
    }

    func testTheSpriteIsWhole() {
        XCTAssertEqual(MarsScene.ship.count, 27)
        for row in MarsScene.ship {
            XCTAssertEqual(row.count, 48)
            for ch in row where ch != " " { XCTAssertNotNil(MarsScene.colors[ch], "no colour for \(ch)") }
        }
        // Two wings, as many panels in each.
        let panels = MarsScene.ship.map { $0.filter { $0 == "p" }.count }
        XCTAssertEqual(panels.prefix(10).reduce(0, +), panels.suffix(10).reduce(0, +))
        XCTAssertGreaterThan(panels.reduce(0, +), 30)
        // The drive's bell is on the row the glow comes out of.
        XCTAssertEqual(MarsScene.ship[MarsScene.driveRow][0], "n")
        // Every way she can point stays on the canvas.
        for face in [MarsScene.Facing.ahead, .down, .astern, .up] {
            for c in [MarsScene.flying, MarsScene.docked] {
                for (col, row) in [(0.0, 0.0), (47, 26), (0, 26), (47, 0)] {
                    let q = MarsScene.place(col, row, face, c)
                    XCTAssertTrue((0..<160).contains(q.x) && (0..<80).contains(q.y), "\(face) \(c) \(q)")
                }
            }
        }
        XCTAssertEqual(MarsScene.captureKey, MarsData.captureKey)
        XCTAssertEqual(MarsScene.heldKey, MarsData.heldKey)
    }

    func testEveryWeatherIsItsOwnPicture() {
        var seen: [Int: String] = [:]
        var skies = Set<Sky>()
        for weather in mars.weathers {
            var g = flying(20_000)
            g.weather = weather
            let pic = picture(frame(g))
            XCTAssertNil(seen[pic], "\(weather.name) looks just like \(seen[pic] ?? "")")
            seen[pic] = weather.name
            skies.insert(weather.sky)
            has(skin.scene.label(frame(g)), "Weather: \(weather.name.lowercased())")
        }
        XCTAssertEqual(seen.count, 7)
        XCTAssertEqual(skies.count, 7, "every weather has a sky of its own")
    }

    func testEveryStretchOfTheArcIsItsOwnPicture() {
        var seen: [Int: String] = [:]
        for r in mars.regions {
            let g = flying(min(r.to, mars.totalMiles) - 5)
            XCTAssertEqual(g.region.id, r.id)
            let pic = picture(frame(g))
            XCTAssertNil(seen[pic], "\(r.name) looks just like \(seen[pic] ?? "")")
            seen[pic] = r.name
            XCTAssertEqual(pic, picture(frame(g)), "the same place twice is the same picture")
            has(skin.scene.label(frame(g)), MarsScene.phrase(r))
        }
        XCTAssertEqual(seen.count, mars.regions.count)
        // Earth shrinks behind her and Mars grows ahead.
        XCTAssertGreaterThan(MarsScene.earthRadius(0), MarsScene.earthRadius(150))
        XCTAssertGreaterThan(MarsScene.earthRadius(150), MarsScene.earthRadius(2000))
        XCTAssertEqual(MarsScene.earthRadius(2999), 2, accuracy: 0.2, "a disc until it is a point")
        XCTAssertEqual(MarsScene.marsRadius(29_999), 0)
        XCTAssertLessThan(MarsScene.marsRadius(30_000), MarsScene.marsRadius(46_000))
        XCTAssertLessThan(MarsScene.marsRadius(46_000), MarsScene.marsRadius(47_300))
        XCTAssertLessThan(MarsScene.marsRadius(47_300), MarsScene.marsRadius(48_000))
        // The Sun is smaller further out.
        XCTAssertGreaterThan(MarsScene.sunRadius(0), MarsScene.sunRadius(48_000))
        // The double star of Earth and the Moon only where the engine's sight has it.
        let sight = try! engineSaid().contains { $0.contains("Earth is a bright star now, with a dimmer one beside it") }
        XCTAssertTrue(sight)
    }

    func testEveryStopAndStationIsDrawnAsItself() {
        var seen: [Int: String] = [:]
        for stop in mars.stops {
            let isPort = mars.port(stop.id) != nil
            var g = at(stop.id, port: isPort)
            g.weather = mars.fairWeather
            if stop.id == "gateway" { g.day = 0 }
            if stop.id == "jezero" { g.atPort = true }
            let f = frame(g, moving: false)
            let pic = picture(f)
            XCTAssertNil(seen[pic], "\(stop.id) looks just like \(seen[pic] ?? "")")
            seen[pic] = stop.id
            if isPort { XCTAssertEqual(MarsScene.dockedAt(f), stop.id) }
            // Not the same as the arc 100,000 km on, or short of the end.
            if stop.id != "gateway" {
                var by = g
                by.atPort = false
                by.mile = stop.mile + (stop.id == "jezero" ? -10 : 10)
                XCTAssertNotEqual(pic, picture(frame(by, moving: false)), "\(stop.id) is drawn as a stop")
                XCTAssertNotEqual(skin.scene.label(f), skin.scene.label(frame(by, moving: false)), stop.id)
            }
            // A station she has reached and not docked at is drawn too, and differently.
            if isPort && stop.id != "gateway" {
                var passing = g
                passing.atPort = false
                let pf = frame(passing, moving: false)
                XCTAssertNil(MarsScene.dockedAt(pf))
                XCTAssertEqual(MarsScene.atStop(pf)?.id, stop.id)
                XCTAssertNotEqual(picture(pf), pic, stop.id)
                has(skin.scene.label(pf), "coming up on")
                XCTAssertNotEqual(skin.scene.label(pf), skin.scene.label(f))
            }
        }
        XCTAssertEqual(seen.count, mars.stops.count)
        has(skin.scene.label(frame(at("gateway", port: true), moving: false)), "docked at Gateway Yard")
        has(skin.scene.label(frame(at("cycler", port: true), moving: false)), "docked alongside the cycler Perpetua")
        has(skin.scene.label(frame(at("lunar"), moving: false)), "passing the Moon")
        has(skin.scene.label(frame(at("turnover"), moving: false)), "on end at Turnover")
        has(skin.scene.label(frame(at("jezero"), moving: false)), "Jezero Landing")
        // At the end the cargo is down, whether or not the engine calls her docked.
        var end = at("jezero")
        end.weather = mars.fairWeather
        var landed = end
        landed.atPort = true
        XCTAssertTrue(MarsScene.landed(frame(end)))
        XCTAssertEqual(picture(frame(landed, moving: false)), picture(frame(end, moving: false)))
    }

    /// Past Turnover she flies tail first, braking; reached dark, Turnover waits, and she has
    /// not turned.
    func testSheTurnsAtTurnoverAndFliesTailFirst() {
        let before = flying(23_000), after = flying(25_000)
        XCTAssertEqual(MarsScene.facing(frame(before)), .ahead)
        XCTAssertEqual(MarsScene.facing(frame(after)), .astern)
        XCTAssertEqual(MarsScene.facing(frame(at("turnover"))), .up)
        has(skin.scene.label(frame(after)), "braking tail first")
        has(skin.scene.label(frame(before)), "burning")
        var held = after
        held.vars[MarsData.heldKey] = Double(stopIndex("turnover"))
        XCTAssertEqual(MarsScene.facing(frame(held)), .ahead, "Turnover is still waiting for power")
        // Run on four days: past it, turned.
        var ran = at("turnover")
        ran.mile += MarsData.turnoverGain
        XCTAssertEqual(MarsScene.facing(frame(ran)), .astern)
        // Docked at Midway, she lies alongside nose first.
        XCTAssertEqual(MarsScene.facing(frame(at("midway", port: true))), .ahead)
    }

    func testWearTroubleAndTheDrive() {
        let g = flying(20_000)
        let plain = picture(frame(g))
        // Each meter shows on its own, and worse shows more.
        var power = g, hull = g, both = g, worse = g
        power.sails = 30
        hull.hull = 20
        both.sails = 30
        both.hull = 20
        worse.sails = 5
        let pics = [plain, picture(frame(power)), picture(frame(hull)), picture(frame(both)), picture(frame(worse))]
        XCTAssertEqual(Set(pics).count, 5, "lost panels and a worn hull are each drawn")

        // The glow: none when she isn't moving, longer the harder she burns.
        XCTAssertLessThan(MarsScene.glowLength(.easy), MarsScene.glowLength(.steady))
        XCTAssertLessThan(MarsScene.glowLength(.steady), MarsScene.glowLength(.full))
        var paces = Set<Int>()
        for pace in Pace.allCases {
            var p = g
            p.pace = pace
            paces.insert(picture(frame(p)))
        }
        XCTAssertEqual(paces.count, 3)
        XCTAssertNotEqual(picture(frame(g, moving: false)), plain)
        has(skin.scene.label(frame(g, moving: false)), "her drive idle")

        // The array dark: no glow, every panel dead, and the label says she is coasting.
        var dark = g
        dark.sails = 0.3
        let df = frame(dark)
        XCTAssertTrue(MarsScene.dark(df))
        XCTAssertTrue(MarsScene.coasting(df))
        XCTAssertFalse(MarsScene.tumbling(df))
        XCTAssertNotEqual(picture(df), picture(frame(worse)))
        has(skin.scene.label(df), "coasting with her array dark")
        // Coasting is not standing still: the dust still goes by.
        XCTAssertNotEqual(picture(df), picture(frame(dark, moving: false)))

        // Dry tanks: tumbling, slowly, round all four ways.
        var dry = g
        dry.fuel = 0
        let yf = frame(dry)
        XCTAssertTrue(MarsScene.tumbling(yf))
        let faces = Set(stride(from: 0.0, to: 7, by: 0.4).map { MarsScene.facing(yf.at($0)).rawValue })
        XCTAssertEqual(faces.count, 4)
        has(skin.scene.label(yf), "tumbling slowly, her tanks dry")
        // A voyage not yet begun has bought nothing and is not dry.
        var unbought = g
        unbought.fuel = 0
        unbought.day = 0
        XCTAssertFalse(MarsScene.tumbling(frame(unbought)))
        XCTAssertFalse(MarsScene.dark(frame({ var u = unbought; u.sails = 0; return u }())))

        // Aerobraking glows; a burn into orbit does not.
        var aero = flying(46_800), burn = flying(46_800)
        aero.vars[MarsData.captureKey] = 1
        burn.vars[MarsData.captureKey] = 2
        XCTAssertTrue(MarsScene.aerobraking(aero))
        XCTAssertFalse(MarsScene.aerobraking(burn))
        XCTAssertEqual(Mars.aerobraking(aero, aero.region), MarsScene.aerobraking(aero))
        XCTAssertNotEqual(picture(frame(aero)), picture(frame(burn)))
        has(skin.scene.label(frame(aero)), "skimming the top of the Martian air")
        var phobos = aero
        phobos.mile = mars.stop("phobos")!.mile + 100
        XCTAssertFalse(MarsScene.aerobraking(phobos), "the rough days end at Phobos")
        XCTAssertEqual(Mars.aerobraking(phobos, phobos.region), false)
    }

    /// The hull lets go: two pieces, or, aerobraking, a line across the Martian sky, as the
    /// engine's two endings say.
    func testTheHullLettingGoIsDrawnAsTheEngineTellsIt() {
        var g = flying(20_000)
        g.hull = 0
        let failing = picture(frame(g, moving: false))
        g.over = true
        let f = frame(g, moving: false)
        XCTAssertTrue(MarsScene.lost(f))
        XCTAssertNotEqual(picture(f), failing)
        has(skin.scene.label(f), "two pieces")
        has(mars.wreckedBody(g), "seam")
        var aero = flying(46_800)
        aero.vars[MarsData.captureKey] = 1
        aero.hull = 0
        aero.over = true
        has(skin.scene.label(frame(aero)), "bright line across the top of the Martian sky")
        has(mars.wreckedBody(aero), "short bright line")
        XCTAssertNotEqual(picture(frame(aero)), picture(f))
        // Lost with the crew, the ship goes on whole.
        var crewless = flying(20_000)
        crewless.over = true
        XCTAssertFalse(MarsScene.lost(frame(crewless)))
    }

    // MARK: The plot

    func testThePlotHasEveryStopOnTheArc() {
        let route = MarsChart.route
        XCTAssertEqual(route.first?.mile, 0)
        XCTAssertEqual(route.last?.mile, Double(mars.totalMiles))
        for (a, b) in zip(route, route.dropFirst()) { XCTAssertLessThan(a.mile, b.mile, "the arc only goes on") }
        let chart = skin.chart
        for q in route {
            XCTAssertTrue((4...chart.w - 4).contains(q.x) && (4...chart.h - 4).contains(q.y), "unit \(q.mile) is off the plot")
        }
        // From Earth's orbit on the left, round under the Sun, to Mars's on the right.
        let sun = MarsChart.sun
        XCTAssertEqual(route[0].x, sun.x - MarsChart.scale, accuracy: 1e-9)
        XCTAssertEqual(route[0].y, sun.y, accuracy: 1e-9)
        XCTAssertEqual(route.last!.x, sun.x + MarsChart.scale * MarsChart.marsAU, accuracy: 1e-6)
        XCTAssertEqual(route.last!.y, sun.y, accuracy: 1e-6)
        let mid = ChartView.position(route, atMile: 24_000, chart)
        XCTAssertGreaterThan(mid.y, sun.y + 50, "half way round, below the Sun")
        // Ever further from the Sun, and the marker never jumps.
        XCTAssertEqual(MarsChart.au(atMile: 0), 1, accuracy: 1e-9)
        XCTAssertEqual(MarsChart.au(atMile: 48_000), MarsChart.marsAU, accuracy: 1e-6)
        var last = ChartView.position(route, atMile: 0, chart)
        var r = 0.0
        for m in stride(from: 0.0, through: 48_000, by: 400) {
            let q = ChartView.position(route, atMile: m, chart)
            XCTAssertLessThan(hypot(q.x - last.x, q.y - last.y), 3, "unit \(m)")
            let d = MarsChart.au(atMile: m)
            XCTAssertGreaterThanOrEqual(d, r - 1e-9)
            r = d
            last = q
        }
        // Points an even share of the arc's length apart.
        let steps = zip(route, route.dropFirst()).map { hypot($1.x - $0.x, $1.y - $0.y) / ($1.mile - $0.mile) }
        XCTAssertLessThan((steps.max() ?? 0) / (steps.min() ?? 1), 1.05)
        // The cycler's loop goes through the place she meets it.
        let cycler = ChartView.position(route, atMile: Double(mars.stop("cycler")!.mile), chart)
        let nearest = stride(from: 0.0, to: 2 * .pi, by: 0.001).map { MarsChart.cyclerPoint($0) }
            .map { hypot($0.x - cycler.x, $0.y - cycler.y) }.min()!
        XCTAssertLessThan(nearest, 1)
        // The inset: Gateway, the Moon and Earth's reach, in order outward.
        let xs = ["gateway", "lunar", "hill"].map { MarsChart.insetX(atMile: Double(mars.stop($0)!.mile)) }
        XCTAssertEqual(xs, xs.sorted())
        XCTAssertLessThan(xs.last!, MarsChart.box.x + MarsChart.box.w)

        let g = nearing("midway")
        XCTAssertEqual(chart.footer(g), "299.90 of 480.00 million km along the arc. 180.10 to go. "
                       + "The ringed stops are stations; the inset is the Earth and the Moon, where the trip begins.")
        XCTAssertEqual(chart.label(g), "Plot of the transfer arc round the Sun, from Earth orbit to Mars. You are in deep space.")
        has(chart.label(at("midway", port: true)), "You are docked at Midway Depot.")
        // A ring for each station, four strokes; three names; the inset.
        let over = PixelCanvas(w: chart.w, h: chart.h)
        chart.overlay(over, g, 1)
        XCTAssertGreaterThan(over.tally.marks, mars.ports.count * 4 + 3)
    }

    // MARK: The grapple

    func testTheGrappleIsCountedInLitres() {
        let w = skin.words(nearing("cycler"))
        let reward = FishingView.reward(mars, w)
        XCTAssertEqual(reward.item.key, .water)
        XCTAssertEqual(reward.measure(mars.role(.merchant).catchLimit), "60 litres")
        XCTAssertEqual(reward.measure(mars.role(.whaler).catchLimit), "100 litres")
        let forage = skin.forage
        let berg = mars.quarry.first { $0.name == "berg" }!
        XCTAssertEqual(FishingView.pop(forage, reward)(berg), "+35 litres, berg")
        has(forage.pop("1", mars.quarry[0]), "+1 litre, grit")
        XCTAssertEqual(forage.heading, "The grapple")
        XCTAssertEqual(forage.throwsLabel, "Shots")
        XCTAssertEqual(forage.caughtLabel, "Caught")
        XCTAssertEqual(forage.timeLabel, "Time")
        has(forage.hint("100 litres"), "up to 100 litres")
        has(forage.label(1), "with 1 chunk drifting by")
        has(forage.label(3), "with 3 chunks drifting by")
        // The field: thrown up from the truss, the stream all one way, in three lanes.
        let f = forage.field
        XCTAssertTrue(f.upward)
        XCTAssertTrue(f.oneWay)
        XCTAssertEqual(f.bands, 3)
        XCTAssertGreaterThan(f.origin.y, f.h * 0.75)
        var lanes = Set<Double>()
        for k in 0..<200 { lanes.insert(f.lane(f.lanes.lowerBound + Double(k) / 199 * (f.lanes.upperBound - f.lanes.lowerBound))) }
        XCTAssertEqual(lanes.count, 3)
        for y in lanes { XCTAssertTrue(f.lanes.contains(y)) }
        var draws = 0.0
        let m = FishingModel(field: f, quarry: mars.quarry, seconds: mars.forageSeconds, padding: 1,
                             random: { draws += 0.137; return draws.truncatingRemainder(dividingBy: 1) },
                             useTackle: { true }, tackleLeft: { 10 })
        for _ in 0..<200 { m.step(0.05) }
        XCTAssertTrue(m.fish.allSatisfy { lanes.contains($0.y0) }, "every chunk in a lane")
        XCTAssertTrue(m.fish.allSatisfy { $0.vx > 0 }, "all going the same way")
        // Every other skin's quarry goes anywhere in its lanes, as before.
        for other in [Horn1849Skin.skin, RailSkin.skin, AirshipSkin.skin, BalloonSkin.skin] {
            XCTAssertEqual(other.forage.field.bands, 0, other.id)
            for y in [other.forage.field.lanes.lowerBound, 77.7, other.forage.field.lanes.upperBound] {
                XCTAssertEqual(other.forage.field.lane(y), y, other.id)
            }
        }
        // The tally counts shots, as the supplies list does.
        XCTAssertEqual(w.looseUnits[.tackle], "shots")
        // The engine's catch report.
        var report = nearing("cycler")
        report.water = 100
        let e = GameEngine(state: report)
        let said = e.landCatch(35).compactMap { i -> String? in if case .message(let t) = i { return t }; return nil }
        XCTAssertTrue(said.contains { $0.contains("35 litres") }, "\(said)")

        // The longest a pop can be stays on the field, wherever the hit.
        let px = PixelCanvas(w: f.w, h: f.h)
        for chunk in mars.quarry {
            let pop = forage.pop(reward.count(chunk.lb), chunk)
            let width = px.width(pop, size: 8)
            XCTAssertLessThan(width, f.w, pop)
        }
        // Each kind of chunk is its own drawing.
        var seen = Set<Int>()
        for chunk in mars.quarry {
            let c = PixelCanvas(w: f.w, h: f.h)
            forage.quarry(c, FishingModel.Swimmer(kind: chunk, x: 80, y0: 80, y: 80, vx: 30, t: 0, wf: 1, wa: 1))
            seen.insert(c.tally.picture)
        }
        XCTAssertEqual(seen.count, mars.quarry.count)
        // Out of the streams there is nothing to catch, and the refusal says where they are.
        var empty = nearing("cycler")
        empty.mile = 5000
        let no = mars.forageRefusal(GameEngine(state: empty)) ?? ""
        for (id, text) in [("stream1", "80 to 110"), ("stream2", "340 to 370")] {
            let i = mars.regions.firstIndex { $0.id.rawValue == id }!
            XCTAssertEqual("\(mars.regions[i - 1].to / 100) to \(mars.regions[i].to / 100)", text)
            has(no, text)
        }
    }

    // MARK: The picker, and whole transfers

    func testThePickerOffersTheTransfer() {
        let c = controller()
        guard case .picker = c.screen else { return XCTFail("\(c.screen)") }
        XCTAssertEqual(Array(c.journeys.map(\.id).prefix(5)), [Horn1849.id, Rail.id, Airship.id, Balloon.id, Mars.id])
        c.chooseJourney(mars.id)
        guard case .title = c.screen else { return XCTFail("\(c.screen)") }
        XCTAssertEqual(c.skin.id, mars.id)
        XCTAssertEqual(c.journey.title, "The Long Transfer")
    }

    /// Answers whatever the transfer raises, first open option each time, until it ends,
    /// with a little care: propellant, rations, water and packs at every station it can
    /// afford, the yard when she is worn, repairs under way when she is failing.
    func playOut(_ c: GameController, maxSteps: Int = 30_000) -> String {
        for _ in 0..<maxSteps {
            switch c.screen {
            case .travel:
                let g = c.game!
                if (g.sails < 35 && g.sailcloth >= 1) || (g.hull < 40 && g.timber >= 1) {
                    c.heaveTo()
                    if g.hull < 40 && g.timber >= 1 { c.patchHull() } else { c.mendSails() }
                    continue
                }
                c.tick()
            case .repairs, .shipyard: c.backToMenu()
            case .message(_, _, let then): then()
            case .choice(let e): c.choose(e, option: e.options.firstIndex(where: \.enabled)!)
            case .burial(let id, let cause): c.bury(crewID: id, cause: cause, epitaph: "")
            case .portMenu:
                c.run { e in
                    let n = e.state.living.count
                    _ = e.buy([.fuel: e.room(for: .fuel)]) || e.buy([.fuel: e.room(for: .fuel) / 2])
                    _ = e.buy([.water: max(0, min(e.room(for: .water), 700 - Int(e.state.water)))])
                        || e.buy([.water: max(0, min(e.room(for: .water), 400 - Int(e.state.water)))])
                    _ = e.buy([.food: max(0, min(e.room(for: .food), 400 - Int(e.state.food)))])
                    _ = e.buy([.limes: max(0, min(e.room(for: .limes), 6 - Int(e.state.limes)))])
                    _ = e.buy([.clothes: max(0, n - e.state.clothes)])
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
                c.leavePort()
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

    /// Whole transfers from the title card, the way a player's taps would make them: the
    /// chandlery at Gateway, the stations, Turnover, the capture, and whichever ending the
    /// dice bring. Seeded, so always the same ones, and Jezero is among the endings.
    func testAWholeTransferFromTheTitleCardReachesAnEnding() {
        var endings: [String] = []
        var arrivals: [String] = []
        for round in 0..<4 {
            let c = controller()
            newTransfer(c, role: round == 3 ? .shipwright : .merchant)
            c.run { $0.rng = SeededRNG(seed: UInt64(round + 1)) }
            XCTAssertTrue(mars.vesselNames.contains(c.game!.ship))
            c.enterFirstShop()
            guard case .shop(let done) = c.screen else { return XCTFail("\(c.screen)") }
            c.run { $0.buy([.fuel: 100, .water: 800, .food: 450, .limes: 6, .clothes: 5, .sailcloth: 3, .timber: 3, .tackle: 2]) }
            done()
            guard case .depart = c.screen else { return XCTFail("\(c.screen)") }
            c.startTravel()
            let end = playOut(c)
            endings.append(end)
            if case .finale = c.screen { arrivals.append(c.skin.words(c.game!).arrival) }
            XCTAssertNil(p.loadSave(mars.id), "no save after the transfer ends")
            XCTAssertFalse(c.traveling)
        }
        XCTAssertTrue(Set(endings).isSubset(of: ["finale", "gameover"]), "\(endings)")
        XCTAssertTrue(endings.contains("finale"), "a transfer can reach Jezero: \(endings)")
        for a in arrivals { has(a, "Jezero Landing!") }
    }

    /// A dark array, through the shell: asked before the day, a panel fitted, and the day
    /// goes on; with no panel, the rewire is always there.
    func testADarkArrayIsAskedAndAnswered() {
        let c = controller()
        var s = nearing("midway")
        s.sails = 0
        s.sailcloth = 1
        c.loadForDebug(s)
        c.startTravel()
        c.tick()
        guard case .choice(let ask) = c.screen, case .custom("dark", _) = ask.kind else { return XCTFail("\(c.screen)") }
        XCTAssertEqual(ask.options.map(\.enabled), [true, true, true, true])
        has(ask.options[0].label, "Fit a spare array panel")
        has(ask.options[1].label, "Rewire")
        c.choose(ask, option: 0)
        while case .message(_, _, let then) = c.screen { then() }
        XCTAssertGreaterThan(c.game!.sails, 0.5)
        XCTAssertNil(skin.words(c.game!).trouble)

        let d = controller()
        var t = nearing("midway")
        t.sails = 0
        t.sailcloth = 0
        d.loadForDebug(t)
        d.startTravel()
        d.tick()
        guard case .choice(let again) = d.screen else { return XCTFail("\(d.screen)") }
        XCTAssertEqual(again.options.map(\.enabled), [false, true, true, true])
        let day = d.game!.day
        d.choose(again, option: 1)
        var said: [String] = []
        while case .message(let m, _, let then) = d.screen { said.append(m); then() }
        XCTAssertTrue(said.contains { $0.contains("talked round") }, "\(said)")
        XCTAssertEqual(d.game!.day, day + MarsData.rigDays)
        XCTAssertEqual(Int(jsRounded(d.game!.sails)), Int(MarsData.rigPower))
    }
}
