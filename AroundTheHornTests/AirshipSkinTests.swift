import XCTest
@testable import HornEngine
@testable import AroundTheHorn

/// Over the Pole's skin, held to its own journey's tables: every number its sentences
/// state, the words an airship needs and the ones it must not borrow from a ship or a
/// train, the country, the masts and the stops in the picture, the polar chart, and the
/// winds. `SkinContractTests` asks what every skin owes the shell; this asks what this
/// one says. It ends with whole flights from the title card to an ending.
@MainActor
final class AirshipSkinTests: XCTestCase {
    let air = AirshipSkin.journey
    let skin = AirshipSkin.skin
    let card = AirshipSkin.card
    let fm = FileManager.default
    var p: Persistence!

    override func setUp() async throws {
        p = Persistence(directory: fm.temporaryDirectory.appendingPathComponent(UUID().uuidString),
                        defaults: UserDefaults(suiteName: UUID().uuidString)!)
    }

    func stopIndex(_ id: String) -> Int { air.stops.firstIndex { $0.id == id }! }

    /// Ten kilometres short of `stop`, in May, as the debug start leaves it.
    func nearing(_ stop: String) -> GameState { skin.debug.start(stopIndex(stop), 4) }

    /// Standing at `stop`, its arrival told; moored if `port`.
    func at(_ stop: String, port: Bool = false) -> GameState {
        var g = nearing(stop)
        AirshipSkin.at(&g, stop, port: port)
        return g
    }

    func has(_ text: String, _ part: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(text.contains(part), "“\(part)” is not in “\(text)”", file: file, line: line)
    }

    func state(month: Int) -> GameState {
        GameState(journey: Airship.id, role: .merchant, ship: "Wren", captain: "Ada", crew: ["Bo", "Cy", "Di", "Ed"],
                  startYear: 1926, startMonth: month)
    }

    // MARK: Watches

    func testTurnsAreWatchesOfFourHours() {
        XCTAssertEqual(air.rules.tickHours, 4)
        XCTAssertEqual(AirshipSkin.perDay, 6)
        has(card.learnPages[0].paragraphs[2], "watches[/amber] of four hours, six to a day")
        XCTAssertEqual(AirshipSkin.span(1), "1 watch")
        XCTAssertEqual(AirshipSkin.span(3), "3 watches")
        XCTAssertEqual(AirshipSkin.span(6), "6 watches (1 day)")
        XCTAssertEqual(AirshipSkin.span(12), "12 watches (2 days)")
        XCTAssertEqual(AirshipSkin.span(7), "7 watches")
        let w = skin.words(nearing("oslo"))
        XCTAssertEqual(air.rules.restChoices.map(w.restChoice),
                       ["1 watch", "3 watches", "6 watches (1 day)", "12 watches (2 days)"])
        // Every job the words put a time on takes one watch.
        has(w.repairsNote, "Each repair takes a watch.")
        has(w.yardIntro, "Each job takes a watch.")
        XCTAssertEqual(AirshipSkin.tenth(1.5), "1.5")
        XCTAssertEqual(AirshipSkin.tenth(1.0), "1")
        XCTAssertEqual(AirshipSkin.tenth(0.3 * 4), "1.2")
    }

    // MARK: Numbers the card states

    func testTheCardsNumbersAreTheTables() {
        let all = card.learnPages.flatMap(\.paragraphs) + card.differences + card.outfitBullets
            + [card.tagline, card.monthIntro, card.monthAdvice]
        let text = all.joined(separator: "\n")

        // The flight.
        XCTAssertEqual(air.totalMiles, 9600)
        has(card.tagline, "Nine thousand six hundred kilometres from Rome to Nome")
        XCTAssertEqual(air.stops.first?.name, "Rome")
        XCTAssertEqual(air.stops.last?.name, "Nome")
        let kingsBay = air.stop("kingsbay")!
        XCTAssertEqual(air.totalMiles - kingsBay.mile, 4300)
        has(text, "4,300 kilometres of ice with no mast at all")
        XCTAssertFalse(air.stops.contains { $0.mile > kingsBay.mile && air.port($0.id) != nil }, "no mast after Kings Bay")
        XCTAssertEqual(air.ports.count, 5)
        has(card.monthIntro, "Five mooring masts")
        XCTAssertEqual(state(month: 4).crew.count, 5)
        has(text, "a crew of five, counting yourself")

        // Who you are.
        for (role, money) in [(Role.merchant, "$1,200"), (.shipwright, "$580"), (.whaler, "$470")] {
            let info = air.role(role)
            XCTAssertEqual("$" + formatNumber(info.money), money)
            let line = card.differences.first { $0.lowercased().contains(info.title) }
            XCTAssertNotNil(line, "\(role)")
            has(line ?? "", "starts with \(money).")
        }
        XCTAssertGreaterThan(air.role(.shipwright).mend, air.role(.merchant).mend)
        XCTAssertGreaterThan(air.role(.shipwright).patch, air.role(.merchant).patch)
        XCTAssertGreaterThan(air.role(.whaler).aim, air.role(.merchant).aim)
        XCTAssertEqual(air.role(.whaler).catchLimit, 2 * air.role(.merchant).catchLimit)
        has(text, "twice the petrol's worth of winds")
        XCTAssertEqual(Role.shipwright.scoreMultiplier, 2)
        XCTAssertEqual(Role.whaler.scoreMultiplier, 3)
        has(text, "the engineer's counts double, the meteorologist's triple")

        // Petrol.
        let petrol = air.item(.fuel)
        XCTAssertEqual(air.pace(.steady).name, "Cruising")
        XCTAssertEqual(air.pace(.steady).fuel, 250)
        XCTAssertEqual(air.pace(.steady).speed, 250)
        has(text, "cruising, she burns 250 kg a watch and covers up to 250 km on it")
        XCTAssertEqual(air.stop("pulham")!.mile, 1700)
        has(text, "Rome to Pulham is 1,700 km")
        XCTAssertEqual(petrol.max, 8000)
        has(text, "The tanks hold 8,000 kg")
        // Dearer at every mast north of Rome.
        let prices = air.stops.compactMap { air.port($0.id)?.price(.fuel) }
        XCTAssertEqual(prices.count, 5)
        for (a, b) in zip(prices, prices.dropFirst()) { XCTAssertLessThan(a, b) }
        has(text, "petrol costs more at every mast north of here")

        // Full speed over the ice, on one tankful, at the polar regions' usual weather and
        // a ship worn to 85%: it usually doesn't, and cruising does.
        func petrolOverTheIce(_ pace: Pace) -> Double {
            let regions = air.regions.filter { $0.to > kingsBay.mile }
            var weather = 0.0
            for r in regions {
                let total = r.weights.reduce(0) { $0 + $1.1 }
                weather += r.weights.reduce(0) { $0 + $1.0.speed * $1.1 } / total
            }
            weather /= Double(regions.count)
            let worn = (air.rules.hullFloor + air.rules.hullSpan * 0.85) * (0.45 + 0.55 * 0.85)
            let watches = Double(air.totalMiles - kingsBay.mile) / (air.pace(pace).speed * weather * worn)
            return watches * air.pace(pace).fuel
        }
        XCTAssertGreaterThan(petrolOverTheIce(.full), Double(petrol.max))
        XCTAssertLessThan(petrolOverTheIce(.steady), Double(petrol.max))
        has(text, "Over the ice, on one tankful, it usually doesn't.")

        // The table, the cans and the coffee.
        XCTAssertEqual(5 * air.rations(.filling).amount, 1.5, accuracy: 1e-9)
        has(text, "five people eat 1.5 kg and drink 3 litres a watch")
        XCTAssertEqual(5 * air.rules.water, 3, accuracy: 1e-9)
        XCTAssertEqual(1 / (5 * air.rules.preventiveUse), 10, accuracy: 1e-9)
        has(text, "a tin lasts five people ten watches")
        XCTAssertEqual(air.rules.deficiencyAfter, 2 * AirshipSkin.perDay)
        has(text, "Two days without it")
        has(text, "two days without it")
        XCTAssertEqual(air.item(.tackle).per, 10)
        has(text, "a box holds ten balloons")

        // Everything the stores sell is on the fitting-out list.
        let bullets = card.outfitBullets.joined(separator: "\n").lowercased()
        for it in air.items { has(bullets, it.name.lowercased()) }
    }

    /// May and June are the months it is warmer under the fog; April is iron-cold up north
    /// and July is foggy; the departures are April to July.
    func testTheSeasonsAreTheEnginesCalendar() {
        XCTAssertEqual(air.departures.map(\.month), [3, 4, 5, 6])
        XCTAssertTrue(air.departures.allSatisfy { $0.year == 1926 })
        let under = air.region(state(month: 4), at: 7000)
        XCTAssertEqual(under.id, "aboveFog", "above the fog until the Pole says otherwise")
        var low = state(month: 4)
        low.vars[AirshipData.routeKey] = AirshipData.routeLow
        let fog = air.region(low, at: 7000)
        XCTAssertEqual(fog.id, "underFog")
        var warmer: [Int] = []
        for month in 3...6 {
            let g = state(month: month)
            if air.temperature(g, in: fog) != air.temperature(g, in: under) { warmer.append(month) }
        }
        XCTAssertEqual(warmer, [4, 5])
        has(card.learnPages[2].paragraphs[0], "in May and June it is warmer")

        let scandinavia = air.regions.first { $0.id == "scandinavia" }!
        XCTAssertEqual(air.temperature(state(month: 3), in: scandinavia), .freezing)
        XCTAssertEqual(air.temperature(state(month: 4), in: scandinavia), .cold)
        has(card.learnPages[2].paragraphs[1], "Leave Rome in April and the Arctic is still iron-cold")
        func fogOdds(_ month: Int) -> Double {
            let e = GameEngine(state: state(month: month))
            let odds = air.weatherWeights(e, air.regions.first { $0.id == "polarSea" }!, cursed: false)
            let total = odds.reduce(0) { $0 + $1.1 }
            return odds.filter { $0.0.sky == .fog }.reduce(0) { $0 + $1.1 } / total
        }
        XCTAssertGreaterThan(fogOdds(6), fogOdds(4) + 0.1, "July's summer fog")
        has(card.monthAdvice, "Go in May")
        has(card.learnPages[2].paragraphs[1], "May is the month.")
        XCTAssertTrue(skin.debug.start(3, 9).dateText.hasPrefix("May"), "a debug start out of season is in May")
    }

    func testTheRankLegendIsTheEnginesRanks() {
        let cuts = air.rules.rankCuts
        XCTAssertEqual(cuts, [7000, 4000, 2000])
        let legend = cuts.map { "\(air.rank($0)) \(formatNumber(Double($0)))+" } + [air.rank(0)]
        XCTAssertEqual(card.rankLegend, legend.joined(separator: " · "))
    }

    // MARK: An airship's words

    func testTheStatusBoxIsAnAirships() {
        var g = nearing("oslo")
        let w = skin.words(g)
        let rows = StatusPanel.stores(air, g, w)
        XCTAssertEqual(rows.map(\.label), ["Provisions", "Water", "Petrol"])
        XCTAssertEqual(rows.map(\.value), ["150 kg", "200 litres", "5,000 kg"])
        XCTAssertEqual(w.meters.0, "Lift")
        XCTAssertEqual(w.meters.1, "Engines")
        XCTAssertEqual(w.travelled, "Flown")
        XCTAssertEqual(w.distanceUnit, "km")
        XCTAssertEqual(w.distance(9600), "9,600")
        XCTAssertEqual(w.leaderTag, "captain")
        XCTAssertNil(w.clock)

        g.water = 1
        XCTAssertEqual(StatusPanel.stores(air, g, skin.words(g))[1].value, "1 litre")

        let list = SuppliesView.rows(air, g, w)
        XCTAssertEqual(list.map(\.0), ["Cash", "Provisions", "Drinking water", "Coffee & cocoa", "Medicine", "Fur suits",
                                       "Engine spares", "Water ballast", "Pilot balloons", "Petrol"])
        XCTAssertEqual(list.last?.1, "5,000 kg")
        XCTAssertEqual(list[8].1, "60 balloons")
        XCTAssertEqual(list[3].1, "6 tins")
        g.limes = 0.37
        XCTAssertEqual(SuppliesView.rows(air, g, w)[3].1, "0.3 tins", "coffee is drunk by the tenth of a tin")
        g.limes = 1
        XCTAssertEqual(SuppliesView.rows(air, g, w)[3].1, "1 tin")

        // Who is on it, and what the menu offers.
        XCTAssertEqual(w.bonus, "Bonus for being a financier")
        g.role = .shipwright
        XCTAssertEqual(skin.words(g).bonus, "Bonus for being an engineer")
        has(skin.words(g).repairsNote, "As an airship engineer")
        g.role = .whaler
        XCTAssertEqual(skin.words(g).bonus, "Bonus for being a meteorologist")
        XCTAssertEqual(w.trade, "Barter with the ground crew")
        XCTAssertEqual(w.forage, "Send up pilot balloons")
        has(w.rationsNow, "With 5 aboard, that's 1.5 kg a watch.")
    }

    func testTheNotesWarnOfCoffeeAndDryTanks() {
        var g = nearing("oslo")
        XCTAssertFalse(skin.words(g).suppliesNote.contains("[red]"))
        g.noCitrus = 7
        has(skin.words(g).suppliesNote, "[red]7 watches without coffee[/red]")
        g.noCitrus = 6
        XCTAssertFalse(skin.words(g).suppliesNote.contains("coffee"))
        g.fuel = 0
        has(skin.words(g).suppliesNote, "the tanks are dry")
        has(skin.words(g).paceNow, "it makes no difference")
        g.clothes = 3
        XCTAssertEqual(skin.words(g).clothesWarning, "[red]Only 3 of 5 aboard have a fur suit.[/red]")
        g.clothes = 5
        XCTAssertNil(skin.words(g).clothesWarning)
    }

    func testTheStoresSellPetrolByTheHundredKilos() {
        let w = skin.words(nearing("oslo"))
        func label(_ key: ItemKey, at port: String) -> String {
            ShopView.priceLabel(air.item(key), air.port(port)!.price(key), w.currency, lot: w.lots.contains(key))
        }
        XCTAssertEqual(label(.fuel, at: "rome"), "$1.50/100 kg")
        XCTAssertEqual(label(.water, at: "rome"), "$1/20 litres")
        XCTAssertEqual(label(.food, at: "rome"), "$0.50/kg")
        XCTAssertEqual(label(.tackle, at: "rome"), "$4/box")
        XCTAssertEqual(label(.fuel, at: "pulham"), "$1.62/100 kg")
        XCTAssertEqual(label(.fuel, at: "kingsbay"), "$2.81/100 kg")
        has(w.priceNote(70), "about 70% dearer than in Rome")
        // A box of balloons is ten balloons aboard, and the shop counts boxes.
        var g = nearing("oslo")
        g.tackle = 60
        XCTAssertEqual(Stores.have(air.item(.tackle), g, w), "6")
        XCTAssertEqual(Stores.unit(air.item(.tackle), count: "6", w), "boxes")
    }

    /// Every string reachable in `value`: the words as data, without the closures.
    func strings(_ value: Any) -> [String] {
        if let s = value as? String { return [s] }
        return Mirror(reflecting: value).children.flatMap { strings($0.value) }
    }

    /// Everything the skin can say, at every stop, for every role.
    func everythingSaid() -> [String] {
        var out = strings(card) + [card.resume("Wren"), card.outfitIntro(nearing("rhone"))]
        let forage = skin.forage
        out += [forage.heading, forage.throwsLabel, forage.caughtLabel, forage.timeLabel, forage.hint("450 kg"),
                forage.label(3), forage.actionHint, forage.leave, skin.chart.title]
        out += air.quarry.flatMap { [forage.pop("1", $0), forage.pop("90", $0)] }
        for i in air.stops.indices.dropFirst() {
            for role in Role.allCases {
                for (port, day, fuel) in [(false, 10, 900.0), (true, 80, 0)] {
                    var g = skin.debug.start(i, 4)
                    g.role = role
                    g.day = day
                    g.fuel = fuel
                    g.noCitrus = day
                    g.atPort = port
                    g.clothes = port ? 2 : 5
                    let w = skin.words(g)
                    out += strings(w) + air.rules.restChoices.map(w.restChoice)
                    out += [w.distance(g.mile), w.yardHull(56), w.yardSails(72), w.priceNote(30), w.burial("Bo"),
                            skin.chart.label(g), skin.chart.footer(g)]
                    for weather in air.weathers {
                        g.weather = weather
                        for moving in [false, true] {
                            out.append(skin.scene.label(ScenePicture.frame(air, g, moving: moving, t: 0)))
                        }
                    }
                }
            }
        }
        for cell in skin.debug.gallery {
            let g = SceneGallery.state(air, cell.set)
            out.append(skin.scene.label(ScenePicture.frame(air, g, moving: cell.moving, t: 0)))
        }
        out.append(skin.scene.label(ScenePicture.frame(air, nil, moving: false, t: 0)))
        return out
    }

    /// Every sentence the airship's engine can write, read from its source: each string
    /// literal, with the code inside its interpolations taken out.
    func engineSaid() throws -> [String] {
        let dir = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("HornEngine/Journeys/Airship")
        let files = try fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil).filter { $0.pathExtension == "swift" }
        XCTAssertGreaterThanOrEqual(files.count, 5, "the airship's engine is in \(dir.path)")
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
        out += air.items.flatMap { it in [1, 2].map { air.describe(.item(it.key), Double(it.per * $0)) } }
        out += [Airship.finale(nearing("nome"))]
        return out
    }

    /// Words from the other journeys' worlds: a sailing ship's, a train's, a wagon's.
    /// An airship is a ship, her commander a captain, and she flies over seas, so those stay.
    static let elsewhere = try! NSRegularExpression(
        pattern: #"\b(sail(s|ed|ing|ors?)?|sailcloth|shipyard|anchor(s|ed)?|hull|harpoons?|tackle|throws?|voyages?|"#
            + #"nm|nautical|knots?|miles?|lbs?|pounds?|scurvy|citrus|limes?|whal(e|er|ers|ing)|"#
            + #"trains?|railroad|railway|locomotive|conductor|caboose|boxcars?|tender|cords?|firewood|wagons?|oxen)\b"#,
        options: [.caseInsensitive])

    func testNothingInTheAirIsSaidInASailorsOrARailroadersWords() throws {
        let said = everythingSaid()
        XCTAssertGreaterThan(Set(said).count, 150, "the walk found the words")
        // A steamer's funnel may still throw her about, and a supply ship make a voyage.
        let figures = ["throws the ship about", "charge you for the voyage"]
        let engine = try engineSaid().map { s in figures.reduce(s) { $0.replacingOccurrences(of: $1, with: "") } }
        XCTAssertGreaterThan(Set(engine).count, 200, "the source was read")
        for s in Set(said + engine) {
            let m = Self.elsewhere.firstMatch(in: s, range: NSRange(s.startIndex..., in: s))
            XCTAssertNil(m, "another journey's word in “\(s)”")
        }
        // The same sieve does catch a ship and a train.
        for other in [Horn1849Skin.skin, RailSkin.skin] {
            let words = strings(other.words(other.debug.start(3, 9))).joined(separator: "\n")
            XCTAssertNotNil(Self.elsewhere.firstMatch(in: words, range: NSRange(words.startIndex..., in: words)), other.id)
        }
        // And nothing here is said in the shapes D11 retired.
        let retired = ["You may:", "Find out the differences", "Be a ", "Filling", "Meager", "Bare bones", "Attempt to trade"]
        for s in Set(said + engine + air.roles.values.map(\.label) + Rations.allCases.map { air.rations($0).name }) {
            for r in retired { XCTAssertFalse(s.contains(r), "“\(r)” in “\(s)”") }
        }
    }

    func testTradesAndTheDepartureReadRight() {
        XCTAssertEqual(air.describe(.item(.meds), 3), "3 medicine kits")
        XCTAssertEqual(air.describe(.item(.clothes), 1), "1 fur suit")
        XCTAssertEqual(air.describe(.item(.fuel), 400), "400 kg of petrol")
        XCTAssertEqual(air.describe(.item(.tackle), 20), "2 boxes of pilot balloons")
        XCTAssertEqual(air.describe(.item(.tackle), 85), "85 pilot balloons")
        var g = nearing("rhone")
        for day in 0..<6 {
            g.day = day
            let depart = air.text.depart(g)
            XCTAssertFalse(depart.contains(".."), depart)
            has(depart, g.dateText)
        }
    }

    // MARK: Leaving Rome

    func controller() -> GameController {
        let c = GameController(persistence: p, journeys: Journeys.all, skins: Skins.all)
        c.tickInterval = .seconds(3600)
        return c
    }

    func newFlight(_ c: GameController, role: Role = .merchant, month: Int = 4) {
        c.chooseJourney(air.id)
        c.startNewGame()
        c.chooseRole(role)
        c.setNames(ship: "", captain: "Ira", crew: ["", "", "", ""])
        c.chooseDeparture(year: 1926, month: month)
    }

    /// Rome won't let her go with dry tanks; with petrol and provisions she leaves. The
    /// other journeys never refuse for this.
    func testRomeWontLetHerGoWithEmptyTanks() {
        var fresh = state(month: 4)
        XCTAssertNotNil(skin.words(fresh).departRefusal)
        fresh.fuel = 100
        XCTAssertNil(skin.words(fresh).departRefusal)
        for other in [Horn1849Skin.skin, RailSkin.skin] {
            let g = GameState(journey: other.id, role: .merchant, ship: "Wren", captain: "Ada", crew: ["Bo", "Cy", "Di", "Ed"],
                              startYear: 1869, startMonth: 9)
            XCTAssertEqual(g.fuel, 0)
            XCTAssertNil(other.words(g).departRefusal, other.id)
        }

        let c = controller()
        newFlight(c)
        c.enterFirstShop()
        guard case .shop(let done) = c.screen else { return XCTFail("\(c.screen)") }
        c.run { $0.buy([.food: 60]) }
        done()
        guard case .message(let why, _, let back) = c.screen else { return XCTFail("\(c.screen)") }
        has(why, "empty tanks")
        back()
        guard case .shop(let again) = c.screen else { return XCTFail("back to the stores, not \(c.screen)") }
        c.run { $0.buy([.fuel: 30]) }
        again()
        guard case .depart(let text) = c.screen else { return XCTFail("\(c.screen)") }
        has(text, "slips the mast at Ciampino.")
    }

    /// The stores save as you leave them, and the app saves whenever it goes to the
    /// background. A flight saved at Rome before she left comes back to the stores, not
    /// to a mast menu whose "Cast off" would skip the refusals and the departure.
    func testAFlightSavedBeforeSheLeftComesBackToTheStores() {
        let c = controller()
        newFlight(c)
        c.enterFirstShop()
        guard case .shop(let done) = c.screen else { return XCTFail("\(c.screen)") }
        // What the shop's "Pay and leave" does: buy, save, then leave.
        c.run { $0.buy([.food: 60]) }
        c.save()
        done()
        guard case .message(let why, _, _) = c.screen else { return XCTFail("\(c.screen)") }
        has(why, "empty tanks")

        // Force-quit and relaunch.
        let again = controller()
        again.chooseJourney(air.id)
        XCTAssertEqual(again.savedVoyage?.food, 60)
        again.continueSavedVoyage()
        guard case .shop(let leave) = again.screen else { return XCTFail("back to the stores, not \(again.screen)") }
        XCTAssertTrue(again.game!.atPort)
        leave()
        guard case .message(let still, _, let back) = again.screen else { return XCTFail("\(again.screen)") }
        has(still, "empty tanks")
        back()
        guard case .shop(let pay) = again.screen else { return XCTFail("\(again.screen)") }
        again.run { $0.buy([.fuel: 30]) }
        again.save()
        pay()
        guard case .depart(let text) = again.screen else { return XCTFail("\(again.screen)") }
        has(text, "slips the mast at Ciampino.")
        XCTAssertFalse(again.game!.atPort)

        // Sent to the background on the outfitting screen, before the stores: the same.
        let fresh = controller()
        newFlight(fresh)
        guard case .outfit = fresh.screen else { return XCTFail("\(fresh.screen)") }
        fresh.scenePhaseChanged(.background)
        let back2 = controller()
        back2.chooseJourney(air.id)
        back2.continueSavedVoyage()
        guard case .shop = back2.screen else { return XCTFail("back to the stores, not \(back2.screen)") }

        // Once she has left, a save comes back to a menu as before.
        var away = state(month: 4)
        away.food = 60
        away.fuel = 3000
        away.atPort = false
        XCTAssertFalse(GameController.notYetLeft(away))
        p.save(away, pending: [])
        let resumed = controller()
        resumed.chooseJourney(air.id)
        resumed.continueSavedVoyage()
        guard case .seaMenu = resumed.screen else { return XCTFail("\(resumed.screen)") }

        // 1849 and the Iron Road answer false and come back to the port menu, as they
        // always have (decision D15).
        for other in [Horn1849Skin.skin, RailSkin.skin] {
            let g = GameState(journey: other.id, role: .merchant, ship: "Wren", captain: "Ada", crew: ["Bo", "Cy", "Di", "Ed"],
                              startYear: 1869, startMonth: 9)
            XCTAssertFalse(other.words(g).resumesInFirstShop, other.id)
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

    func testTheSpriteIsWhole() {
        XCTAssertEqual(AirshipScene.ship.count, 14)
        for row in AirshipScene.ship {
            XCTAssertEqual(row.count, 32)
            for ch in row where ch != " " { XCTAssertNotNil(AirshipScene.colors[ch], "no colour for \(ch)") }
        }
        // Nose to the mast head when moored.
        let nose = AirshipScene.ship.map { $0.lastIndex { $0 != " " } ?? 0 }.max()!
        XCTAssertEqual(AirshipScene.mooredX + Double(nose), AirshipScene.mastX + 1)
    }

    func testEveryWeatherIsItsOwnPicture() {
        var seen: [Int: String] = [:]
        for weather in air.weathers {
            var g = nearing("oslo")
            g.weather = weather
            let pic = picture(frame(g))
            XCTAssertNil(seen[pic], "\(weather.name) looks just like \(seen[pic] ?? "")")
            seen[pic] = weather.name
        }
        XCTAssertEqual(seen.count, 9)
        // The two winds share a sky, and so do the two fogs: told apart by the rules' figures.
        XCTAssertTrue(AirshipScene.following(AirshipData.tail))
        XCTAssertFalse(AirshipScene.following(AirshipData.head))
        XCTAssertTrue(AirshipScene.icing(AirshipData.ice))
        XCTAssertFalse(AirshipScene.icing(AirshipData.fog))
    }

    func testEveryStretchOfCountryIsItsOwnPicture() {
        var seen: [Int: String] = [:]
        var places = air.regions.map { r -> GameState in
            var g = nearing("bear")
            g.mile = r.to - 5
            return g
        }
        var low = nearing("bear")
        low.mile = 7000
        low.vars[AirshipData.routeKey] = AirshipData.routeLow
        places.append(low)
        for var g in places {
            g.weather = air.fairWeather
            let pic = picture(frame(g))
            XCTAssertNil(seen[pic], "\(g.region.name) looks just like \(seen[pic] ?? "")")
            seen[pic] = g.region.name
            XCTAssertEqual(pic, picture(frame(g)), "the same place twice is the same picture")
        }
        XCTAssertEqual(seen.count, 9)
        XCTAssertTrue(seen.values.contains("Under the Fog"))
    }

    func testEveryMastAndEveryStopIsDrawnAsItself() {
        var seen: [Int: String] = [:]
        for stop in air.stops {
            let moored = air.port(stop.id) != nil
            var g = at(stop.id, port: moored)
            g.weather = air.fairWeather
            if stop.id == "rome" { g.day = 0 }
            let pic = picture(frame(g, moving: false))
            XCTAssertNil(seen[pic], "\(stop.id) looks just like \(seen[pic] ?? "")")
            seen[pic] = stop.id
            // Not the same as passing by.
            var by = g
            by.atPort = false
            by.mile = stop.mile + (stop.id == "nome" ? -10 : 10)
            if stop.id != "rome" {
                XCTAssertNotEqual(pic, picture(frame(by, moving: false)), "\(stop.id) is drawn as a stop")
                XCTAssertNotEqual(skin.scene.label(frame(g, moving: false)), skin.scene.label(frame(by, moving: false)), stop.id)
            }
            if moored { has(skin.scene.label(frame(g, moving: false)), "moored at the mast at \(air.port(stop.id)!.name)") }
        }
        XCTAssertEqual(seen.count, air.stops.count)
        has(skin.scene.label(frame(at("pole"), moving: false)), "North Pole")
        has(skin.scene.label(frame(at("barrow"), moving: false)), "Point Barrow")

        // At the end the engine has her "in port" at Nome, which has no mast: she is
        // still coming down over its roofs, not moored to anything.
        var end = at("nome")
        end.weather = air.fairWeather
        var landed = end
        landed.atPort = true
        XCTAssertNil(AirshipScene.moored(frame(landed, moving: false)))
        XCTAssertEqual(picture(frame(landed, moving: false)), picture(frame(end, moving: false)))
        has(skin.scene.label(frame(landed, moving: false)), "roofs of Nome")
    }

    /// Forced down: on the ice with a camp beside her where there is sea ice, on the sea,
    /// in a field, Scandinavia's included.
    func testForcedDownIsDrawnWhereSheCameDown() {
        for (stop, words) in [("kingsbay", "down on the ice"), ("pulham", "down in a field"), ("rhone", "down on the sea"),
                              ("vadso", "down in a field")] {
            var g = nearing(stop)
            g.weather = air.fairWeather
            g.hull = 0
            let failing = picture(frame(g, moving: false))
            g.over = true
            let f = frame(g, moving: false)
            XCTAssertTrue(AirshipScene.down(f))
            XCTAssertFalse(AirshipScene.drifting(f))
            XCTAssertNotEqual(picture(f), failing, stop)
            has(skin.scene.label(f), words)
            XCTAssertEqual(AirshipScene.position(f, AirshipScene.palette(g.weather)).y, AirshipScene.horizon - 10)
        }
        // The picture and the engine's ending agree, everywhere she can come down.
        for region in air.regions + [AirshipData.underFog] {
            var g = nearing("bear")
            g.mile = region.to - 5
            if region.id == AirshipData.underFog.id { g.vars[AirshipData.routeKey] = AirshipData.routeLow }
            XCTAssertEqual(g.region.id, region.id)
            g.hull = 0
            g.over = true
            let said = skin.scene.label(frame(g, moving: false)), body = air.wreckedBody(g)
            XCTAssertEqual(said.contains("on the ice"), body.contains("onto the ice"), region.name)
            XCTAssertEqual(said.contains("on the sea"), body.contains("onto the sea"), region.name)
            XCTAssertEqual(said.contains("in a field"), body.contains("into a field"), region.name)
        }
    }

    func testTheNightTheMidnightSunTheWearAndTheDrift() {
        var g = nearing("pulham")  // France
        g.weather = air.fairWeather
        g.hull = 100
        g.sails = 100
        let plain = picture(frame(g))
        XCTAssertNotEqual(picture(frame(g, hour: 0)), plain)
        has(skin.scene.label(frame(g, hour: 0)), "by night")
        XCTAssertFalse(skin.scene.label(frame(g)).contains("night"))

        var north = nearing("kingsbay")
        north.weather = air.fairWeather
        XCTAssertTrue(north.region.has("north"))
        XCTAssertNotEqual(picture(frame(north, hour: 0)), picture(frame(north)))
        has(skin.scene.label(frame(north, hour: 0)), "in the midnight sun")
        XCTAssertFalse(skin.scene.label(frame(north, hour: 0)).contains("by night"))

        // Wear: each meter shows on its own, and worse shows more.
        var engines = g, lift = g, both = g
        engines.sails = 10
        lift.hull = 10
        both.sails = 10
        both.hull = 10
        let pics = [plain, picture(frame(engines)), picture(frame(lift)), picture(frame(both))]
        XCTAssertEqual(Set(pics).count, 4, "tired engines and lost lift are each drawn")
        // She rides lower as the lift goes: ten pixels from full to empty.
        let s = AirshipScene.palette(air.fairWeather)
        let full = AirshipScene.position(frame(g).at(0), s), empty = AirshipScene.position(frame({ var e = g; e.hull = 0; return e }()).at(0), s)
        XCTAssertEqual(empty.y - full.y, 10)

        // Dry tanks: no propeller, and the label says she is drifting.
        var dry = g
        dry.fuel = 0
        XCTAssertNotEqual(picture(frame(dry)), plain)
        has(skin.scene.label(frame(dry)), "drifting")
        XCTAssertFalse(skin.scene.label(frame(g)).contains("drifting"))
        // A voyage not yet begun has bought nothing and is not adrift.
        var unbought = g
        unbought.fuel = 0
        unbought.day = 0
        XCTAssertFalse(AirshipScene.drifting(frame(unbought)))

        // Engines stopped is not flying.
        XCTAssertNotEqual(picture(frame(g, moving: false)), plain)
        has(skin.scene.label(frame(g, moving: false)), "engines stopped")
    }

    /// The midnight sun only where and when the sun does not set: north of the Circle, and
    /// later in the spring the nearer the Circle. South of it, and before the season, the
    /// nights are dark.
    func testTheMidnightSunIsWhereAndWhenTheSunDoesNotSet() {
        func night(_ g: GameState) -> SceneFrame {
            var g = g
            g.weather = air.fairWeather
            return frame(g, hour: 0)
        }
        // Ten km short of the Circle in May: Scandinavia, but the sun sets.
        let circle = nearing("circle")
        XCTAssertTrue(circle.region.has("north"))
        XCTAssertFalse(AirshipScene.midnightSun(night(circle)))
        has(skin.scene.label(night(circle)), "by night")
        XCTAssertFalse(skin.scene.label(night(circle)).contains("midnight sun"))
        // The same place at midsummer: the sun stays up, and the picture shows it.
        var midsummer = circle
        midsummer.startMonth = 5
        midsummer.day = 20 * 6
        XCTAssertEqual(midsummer.date.month, 5)
        XCTAssertTrue(AirshipScene.midnightSun(night(midsummer)), "\(midsummer.dateText)")
        has(skin.scene.label(night(midsummer)), "in the midnight sun")
        XCTAssertNotEqual(picture(night(circle)), picture(night(midsummer)))

        // Moored at Oslo, sixty degrees north, never; nor at Pulham, nor at Nome.
        for (stop, port) in [("oslo", true), ("pulham", true), ("nome", false)] {
            for month in air.departures.map(\.month) {
                var g = at(stop, port: port)
                g.startMonth = month
                XCTAssertFalse(AirshipScene.midnightSun(night(g)), "\(stop) \(g.dateText)")
            }
        }
        // Near Vadsø on April 5, 1926: dark. Kings Bay early in April too; in May it is light.
        let april = skin.debug.start(stopIndex("vadso"), 3)
        XCTAssertEqual(april.date.month, 3)
        has(skin.scene.label(night(april)), "by night")
        XCTAssertFalse(AirshipScene.midnightSun(night(skin.debug.start(stopIndex("kingsbay"), 3))))
        XCTAssertTrue(AirshipScene.midnightSun(night(nearing("kingsbay"))))
        XCTAssertTrue(AirshipScene.midnightSun(night(at("pole"))))

        // The dates the comment gives: the first night it stays up at Kings Bay and at Vadsø.
        func firstNight(at stop: String) -> (month: Int, day: Int)? {
            var g = at(stop)
            g.startMonth = 3
            for d in 0..<120 {
                g.day = d * 6
                if AirshipScene.midnightSun(night(g)) { return (g.date.month, g.date.day) }
            }
            return nil
        }
        let kingsBay = firstNight(at: "kingsbay"), vadso = firstNight(at: "vadso")
        XCTAssertEqual(kingsBay?.month, 3)
        XCTAssertEqual(Double(kingsBay?.day ?? 0), 17, accuracy: 1)
        XCTAssertEqual(vadso?.month, 4)
        XCTAssertEqual(Double(vadso?.day ?? 0), 16, accuracy: 1)
    }

    /// Every place reads as a sentence says it: "over the North Sea", "above the fog",
    /// never "over Above the Fog".
    func testEveryPlaceIsSaidAsASentenceSaysIt() throws {
        let said = ["med": "over the Mediterranean", "france": "over France", "northSea": "over the North Sea",
                    "scandinavia": "over Scandinavia", "barents": "over the Barents Sea", "polarSea": "over the Polar Sea",
                    "aboveFog": "above the fog", "underFog": "under the fog", "alaska": "over the Alaskan coast"]
        for region in air.regions + [AirshipData.underFog] {
            var g = nearing("bear")
            g.mile = region.to - 5
            if region.id == AirshipData.underFog.id { g.vars[AirshipData.routeKey] = AirshipData.routeLow }
            g.weather = air.fairWeather
            g.fuel = 3000
            XCTAssertEqual(g.region.id, region.id)
            let phrase = try XCTUnwrap(said[region.id.rawValue], region.name)
            var dry = g
            dry.fuel = 0
            let labels = [skin.scene.label(frame(g)), skin.scene.label(frame(g, moving: false)),
                          skin.scene.label(frame(g, hour: 0)), skin.scene.label(frame(dry)), skin.chart.label(g)]
            has(labels[0], "Airship flying \(phrase). Weather: fair & clear")
            has(labels[1], "Airship \(phrase), engines stopped.")
            has(labels[2], "Airship flying \(phrase) ")
            has(labels[3], "Airship drifting \(phrase), engines stopped.")
            has(labels[4], "You are \(phrase).")
            for label in labels {
                for heading in ["over Above", "over Under", "over Mediterranean", "over North Sea", "over Barents",
                                "over Alaskan", "over The "] {
                    XCTAssertFalse(label.contains(heading), label)
                }
            }
        }
        XCTAssertEqual(Set(said.keys).count, air.regions.count + 1)
    }

    /// At a mast she has reached and not moored to (its arrival's question on screen, or
    /// flying on past it), the picture is the mast and its town, not the country around.
    func testAMastSheHasNotMooredToIsStillDrawn() {
        for port in air.ports where port.id != "rome" {
            var g = at(port.id)
            g.weather = air.fairWeather
            let asked = frame(g, moving: false), flying = frame(g)
            XCTAssertEqual(AirshipScene.passing(asked), port.id)
            XCTAssertNil(AirshipScene.moored(asked))
            has(skin.scene.label(asked), "over the mast at \(port.name), the ground crew waiting below")
            has(skin.scene.label(flying), "flying past the mast at \(port.name)")
            XCTAssertFalse(skin.scene.label(asked).contains(AirshipScene.whereabouts(g.region)), port.id)
            // Not moored: she flies where she always does, and the lines are slack.
            var moored = g
            moored.atPort = true
            XCTAssertNotEqual(picture(asked), picture(frame(moored, moving: false)), port.id)
            XCTAssertEqual(AirshipScene.position(asked.at(0), AirshipScene.palette(g.weather)).x, AirshipScene.flyingX)
            // And not the country she flies on into.
            var on = g
            on.mile += 10
            XCTAssertNil(AirshipScene.passing(frame(on)))
            XCTAssertNotEqual(picture(flying), picture(frame(on)), port.id)
        }
        // Pulham stands where France ends and the North Sea begins: the station, not the sea.
        let pulham = frame(at("pulham"), moving: false)
        XCTAssertEqual(pulham.region?.id.rawValue, "northSea")
        XCTAssertFalse(skin.scene.label(pulham).contains("North Sea"))
        // Rome's is behind her as soon as she leaves.
        var leaving = state(month: 4)
        leaving.fuel = 3000
        leaving.atPort = false
        XCTAssertNil(AirshipScene.passing(frame(leaving, moving: false)))
    }

    // MARK: The chart

    func testTheChartHasEveryStopOnTheFlight() {
        let route = AirshipChart.route
        for stop in air.stops {
            XCTAssertTrue(route.contains { Int($0.mile) == stop.mile }, "\(stop.id) is not a point on the chart's route")
        }
        XCTAssertEqual(route.first?.mile, 0)
        XCTAssertEqual(route.last?.mile, Double(air.totalMiles))
        for (a, b) in zip(route, route.dropFirst()) { XCTAssertLessThanOrEqual(a.mile, b.mile, "kilometres only go up") }
        let chart = AirshipChart.skin
        for q in route {
            XCTAssertTrue((4...chart.w - 4).contains(q.x) && (4...chart.h - 4).contains(q.y), "km \(q.mile) is off the chart")
        }
        // Rome at the bottom, the Pole in the middle, Nome at the top.
        XCTAssertEqual(route[0].x, 110, accuracy: 1)
        XCTAssertEqual(route[0].y, 200, accuracy: 1)
        let pole = route.first { Int($0.mile) == air.stop("pole")!.mile }!
        XCTAssertEqual(pole.x, AirshipChart.pole.x, accuracy: 1e-9)
        XCTAssertEqual(pole.y, AirshipChart.pole.y, accuracy: 1e-9)
        XCTAssertEqual(route.last!.x, 115, accuracy: 1)
        XCTAssertEqual(route.last!.y, 16, accuracy: 1)
        // The marker goes north all the way: up the page.
        for m in stride(from: 0.0, to: Double(air.totalMiles), by: 100) {
            XCTAssertGreaterThan(ChartView.position(route, atMile: m, chart).y,
                                 ChartView.position(route, atMile: m + 100, chart).y - 1e-9, "km \(m)")
        }
        // Either height beyond the Pole flies the same track.
        var low = nearing("barrow")
        low.vars[AirshipData.routeKey] = AirshipData.routeLow
        XCTAssertEqual(chart.route(low).map(\.mile), chart.route(nearing("barrow")).map(\.mile))
        XCTAssertTrue(chart.others(low).isEmpty)

        let g = nearing("pulham")
        XCTAssertEqual(chart.footer(g), "1,690 of 9,600 kilometres flown. 7,910 to go. The ringed stops have a mast.")
        XCTAssertEqual(chart.label(g), "Polar chart of the flight from Rome over the North Pole to Nome. You are over France.")
        has(chart.label(nearing("pole")), "over the Polar Sea")
        // A ring for every mast, four strokes each, a cross at the Pole, three names.
        let rings = PixelCanvas(w: chart.w, h: chart.h)
        AirshipChart.names(rings)
        XCTAssertEqual(rings.tally.marks, air.ports.count * 4 + 2 + 3)
    }

    /// Inside a projected outline, by the even-odd rule.
    func inside(_ q: (x: Double, y: Double), _ shape: [AirshipChart.Point]) -> Bool {
        let poly = shape.map(AirshipChart.project)
        var inside = false
        for (a, b) in zip(poly, Array(poly.dropFirst()) + [poly[0]]) where (a.y > q.y) != (b.y > q.y) {
            if q.x < a.x + (q.y - a.y) / (b.y - a.y) * (b.x - a.x) { inside.toggle() }
        }
        return inside
    }

    /// The route leaves Rome over the Mediterranean, as the scene's sea does, and crosses
    /// France over land. (The chart's coast is crossed a watch short of the Rhône's mouth,
    /// where the region below changes.)
    func testTheChartsSeaIsTheSceneSea() {
        let chart = AirshipChart.skin
        let med = AirshipChart.shapes[1].points, europe = AirshipChart.shapes[0].points
        let seas = AirshipChart.shapes.filter(\.sea).map(\.points)
        let rhone = air.stop("rhone")!.mile
        for km in stride(from: 120, through: 500, by: 10) {
            XCTAssertTrue(inside(ChartView.position(AirshipChart.route, atMile: Double(km), chart), med), "km \(km) is not at sea")
        }
        for km in stride(from: rhone + 10, through: 1490, by: 10) {
            let q = ChartView.position(AirshipChart.route, atMile: Double(km), chart)
            XCTAssertTrue(inside(q, europe) && !seas.contains { inside(q, $0) }, "km \(km) is not over France")
        }
    }

    // MARK: The winds

    func testTheWindsAreCountedInPetrol() {
        let w = skin.words(nearing("oslo"))
        let reward = FishingView.reward(air, w)
        XCTAssertEqual(reward.item.key, .fuel)
        XCTAssertEqual(reward.measure(air.role(.merchant).catchLimit), "450 kg")
        XCTAssertEqual(reward.measure(air.role(.whaler).catchLimit), "900 kg")
        let forage = skin.forage
        has(FishingView.pop(forage, reward)(air.quarry[2]), "+90 kg, steady westerly")
        for wind in air.quarry { has(forage.pop("1", wind), "+1 kg, ") }
        XCTAssertTrue(forage.field.upward)
        XCTAssertFalse(forage.field.oneWay)
        XCTAssertGreaterThan(forage.field.origin.y, forage.field.h * 0.75)
        XCTAssertEqual(forage.throwsLabel, "Balloons")
        XCTAssertEqual(forage.caughtLabel, "Found")
        // The tally counts balloons, as the supplies list does, and one is a balloon.
        XCTAssertEqual(w.looseUnits[.tackle], "balloons")
        let balloons = air.item(.tackle)
        var g = nearing("oslo")
        for (n, reads) in [(0, "0 balloons"), (1, "1 balloon"), (2, "2 balloons"), (11, "11 balloons")] {
            g.tackle = n
            XCTAssertEqual(Stores.amount(balloons, g, w), reads)
        }
        has(forage.label(1), "with 1 wind crossing it")
        has(forage.label(3), "with 3 winds crossing it")
        // The tally writes thousands as the engine's report does: "1,350 kg".
        let found = FishingView.reward(air, w, grouped: forage.grouped)
        XCTAssertEqual(found.measure(1350), "1,350 kg")
        XCTAssertEqual(found.measure(450), "450 kg")
        var report = nearing("oslo")
        report.fuel = 0
        let e = GameEngine(state: report)
        let said = e.landCatch(1350).compactMap { i -> String? in if case .message(let t) = i { return t }; return nil }
        XCTAssertTrue(said.contains { $0.contains("1,350 kg") }, "\(said)")

        // The longest a pop can be stays on the field, wherever the hit.
        let px = PixelCanvas(w: forage.field.w, h: forage.field.h)
        for wind in air.quarry {
            let pop = forage.pop(reward.count(air.role(.whaler).catchLimit), wind)
            let width = px.width(pop, size: 8)
            XCTAssertLessThan(width, forage.field.w, pop)
            for hit in stride(from: 0.0, through: forage.field.w, by: 2) {
                let x = FishingView.popX(hit, width: width, field: forage.field.w)
                XCTAssertTrue(x >= 0 && x + width <= forage.field.w, "“\(pop)” at \(hit) runs off the field")
            }
        }
        // Each wind is its own drawing, and so is its direction.
        var seen = Set<Int>()
        for wind in air.quarry {
            for vx in [-30.0, 30] {
                let c = PixelCanvas(w: forage.field.w, h: forage.field.h)
                forage.quarry(c, FishingModel.Swimmer(kind: wind, x: 80, y0: 80, y: 80, vx: vx, t: 0, wf: 1, wa: 1))
                seen.insert(c.tally.picture)
            }
        }
        XCTAssertEqual(seen.count, air.quarry.count * 2)
    }

    // MARK: The picker, and whole flights

    func testThePickerOffersTheAirship() {
        let c = controller()
        guard case .picker = c.screen else { return XCTFail("\(c.screen)") }
        // The journeys with a skin, in order, and no other.
        XCTAssertEqual(c.journeys.map(\.id), [Horn1849.id, Rail.id, Airship.id])
        c.chooseJourney(air.id)
        guard case .title = c.screen else { return XCTFail("\(c.screen)") }
        XCTAssertEqual(c.skin.id, air.id)
        XCTAssertEqual(c.journey.title, "Over the Pole")
    }

    /// Answers whatever the flight raises, first open option each time, until it ends,
    /// with a little care: petrol, food, water and coffee at every mast it can afford,
    /// the gas plant and the mechanics when she is worn, and repairs aloft when she is
    /// failing.
    func playOut(_ c: GameController, maxSteps: Int = 20_000) -> String {
        for _ in 0..<maxSteps {
            switch c.screen {
            case .travel:
                let g = c.game!
                if (g.sails < 40 && g.sailcloth >= 1) || (g.hull < 40 && g.timber >= 1) {
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
                    let room = e.room(for: .fuel)
                    _ = e.buy([.fuel: room]) || e.buy([.fuel: room / 2]) || e.buy([.fuel: room / 4])
                    _ = e.buy([.food: max(0, min(e.room(for: .food), 120 - Int(e.state.food)))])
                    _ = e.buy([.water: max(0, min(e.room(for: .water), 200 - Int(e.state.water)))])
                    _ = e.buy([.limes: max(0, min(e.room(for: .limes), 6 - Int(e.state.limes)))])
                    _ = e.buy([.clothes: max(0, n - e.state.clothes)])
                    if e.state.sailcloth < 2 { _ = e.buy([.sailcloth: 1]) }
                    if e.state.timber < 3 { _ = e.buy([.timber: 1]) }
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

    /// Whole flights from the title card, the way a player's taps would make them: the
    /// stores at Rome, the masts, the Pole, and whichever ending the dice bring. The dice
    /// are seeded, so the flights are always the same ones, and Nome is among the endings.
    func testAWholeFlightFromTheTitleCardReachesAnEnding() {
        var endings: [String] = []
        var arrivals: [String] = []
        for round in 0..<4 {
            let c = controller()
            newFlight(c, role: Role.allCases[round % Role.allCases.count])
            c.run { $0.rng = SeededRNG(seed: UInt64(round + 1)) }
            XCTAssertTrue(air.vesselNames.contains(c.game!.ship))
            c.enterFirstShop()
            guard case .shop(let done) = c.screen else { return XCTFail("\(c.screen)") }
            c.run { $0.buy([.fuel: 6000, .water: 200, .food: 120, .limes: 6, .clothes: 5, .sailcloth: 2, .timber: 3]) }
            done()
            guard case .depart = c.screen else { return XCTFail("\(c.screen)") }
            c.startTravel()
            let end = playOut(c)
            endings.append(end)
            if case .finale = c.screen { arrivals.append(c.skin.words(c.game!).arrival) }
            XCTAssertNil(p.loadSave(air.id), "no save after the flight ends")
            XCTAssertFalse(c.traveling)
        }
        XCTAssertTrue(Set(endings).isSubset(of: ["finale", "gameover"]), "\(endings)")
        XCTAssertTrue(endings.contains("finale"), "a flight can reach Nome: \(endings)")
        for a in arrivals { has(a, "comes down over the roofs of Nome") }
    }
}
