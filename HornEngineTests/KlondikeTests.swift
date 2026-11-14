import XCTest
@testable import HornEngine

/// To the Klondike's own rules, and the bands its balance has to stay in
/// (docs/journeys/klondike.md).
final class KlondikeTests: XCTestCase {
    let klondike = Journeys.journey(Klondike.id) as! Klondike

    /// Five in the party, out on the way at `mile` (tenths). March 1898 unless told otherwise.
    func party(mile: Int = 11250, month: Int = 2, role: Role = .merchant, pass: Double? = nil) -> GameState {
        var s = GameState(journey: Klondike.id, role: role, ship: "Klondike Belle", captain: "Will",
                          crew: ["Martha", "Gus", "Clara", "Ed"], startYear: 1898, startMonth: month)
        s.mile = mile
        s.stopIndex = klondike.stops.lastIndex { $0.mile <= mile } ?? 0
        if let pass = pass { s.vars[KlondikeData.routeKey] = pass }
        s.food = 6000
        s.water = 1000
        s.limes = 5
        s.meds = 2
        s.clothes = 5
        s.sailcloth = 3
        s.timber = 4
        s.tackle = 60
        s.atPort = false
        return s
    }

    func region(_ s: GameState) -> Region { klondike.region(s, at: s.mile) }

    func speed(_ e: GameEngine) -> Double {
        var sp = 1.0
        klondike.adjustSpeed(e, e.state.region, &sp)
        return sp
    }

    func messages(_ q: [Interrupt]) -> [String] {
        q.compactMap { if case .message(let t) = $0 { return t } else { return nil } }
    }

    func choice(_ q: [Interrupt]) -> ChoiceEvent? {
        for i in q { if case .choice(let c) = i { return c } }
        return nil
    }

    func key(_ c: ChoiceEvent?) -> String? {
        if case .custom(let k, _)? = c?.kind { return k }
        return nil
    }

    // MARK: - Three legs

    func testTheSteamerIsAPassengerLeg() {
        var s = party(mile: 5000)
        s.pace = .full
        s.sails = 10
        s.hull = 20
        let e = engine(s)
        XCTAssertEqual(Klondike.legName(s), "steamer")
        XCTAssertEqual(speed(e), 2200)
        XCTAssertEqual(klondike.paceHP(s), 0)
        XCTAssertEqual(klondike.waterNeed(s, .freezing), 0)
        XCTAssertEqual(klondike.propulsionWear(e), 0)
        XCTAssertEqual(klondike.structureDamage(e, s.region), 0)
    }

    func testTheTrailMovesUnderAMileADay() {
        XCTAssertEqual(speed(engine(party(mile: 11250))), 9, accuracy: 1e-9)
        XCTAssertEqual(speed(engine(party(mile: 11250, role: .whaler))), 9 * 1.15, accuracy: 1e-9)
        var s = party(mile: 11250)
        s.vars[KlondikeData.packersKey] = 1
        XCTAssertEqual(speed(engine(s)), 9 * 1.4, accuracy: 1e-9)
        // The packers carry only as far as the summit.
        s.mile = 11400
        XCTAssertEqual(speed(engine(s)), 9, accuracy: 1e-9)
        // The White Pass is slower: the same miles at nine tenths the speed.
        XCTAssertEqual(speed(engine(party(mile: 11250, pass: KlondikeData.whitePass))), 9 * 0.9, accuracy: 1e-9)
        XCTAssertEqual(speed(engine(party(mile: 13500))), 300, accuracy: 1e-9)
        XCTAssertEqual(Klondike.legName(party(mile: 11250)), "foot")
        XCTAssertEqual(Klondike.legName(party(mile: KlondikeData.bennettMile)), "boat")
    }

    func testHaulingIsHarderWorkThanRowing() {
        var s = party(mile: 11250)
        XCTAssertEqual(klondike.paceHP(s), -1.7)
        s.pace = .full
        XCTAssertEqual(klondike.paceHP(s), -3.4)
        s.pace = .easy
        XCTAssertEqual(klondike.paceHP(s), -0.5)
        var white = party(mile: 11250, pass: KlondikeData.whitePass)
        XCTAssertEqual(klondike.paceHP(white), -1.7 * 0.75, accuracy: 1e-9)
        white.mile = 13500
        white.pace = .easy
        XCTAssertEqual(klondike.paceHP(white), 0.5)
        white.pace = .full
        XCTAssertEqual(klondike.paceHP(white), -1)
    }

    // MARK: - Firewood

    func testFirewoodBurnsByTheCold() {
        let s = party(mile: 11400)
        XCTAssertEqual(klondike.waterNeed(s, .freezing), 8)
        XCTAssertEqual(klondike.waterNeed(s, .cold), 6)
        XCTAssertEqual(klondike.waterNeed(s, .cool), 4)
        XCTAssertEqual(klondike.waterNeed(s, .warm), 2)
        // The Chilkoot summit in February is freezing: five people burn 40 lbs a day.
        var feb = party(mile: 11400, month: 1)
        feb.water = 100
        let e = engine(feb)
        XCTAssertEqual(e.state.temperature(in: e.state.region), .freezing)
        var q: [Interrupt] = []
        e.consume(&q, .sail)
        XCTAssertEqual(e.state.water, 60)
        XCTAssertFalse(e.state.thirst)
        // Out of wood is out of fire: the engine's thirst, with its own cause of death.
        e.state.water = 10
        e.consume(&q, .sail)
        XCTAssertTrue(e.state.thirst)
        XCTAssertEqual(klondike.text.causeThirst, "exposure")
    }

    func testDeadwoodIsGatheredBelowTheTreeLineOutOfTown() {
        var s = party(mile: 11250)
        s.water = 500
        let valley = engine(s, [0])
        var q: [Interrupt] = []
        klondike.tick(valley, &q, .sea, valley.state.region)
        XCTAssertEqual(valley.state.water, 520)
        XCTAssertTrue(valley.state.note.contains("deadwood"))

        let summit = engine(party(mile: 11400), [0])
        klondike.tick(summit, &q, .sea, summit.state.region)
        XCTAssertEqual(summit.state.water, 1000)

        s.weather = KlondikeData.blizzard
        let blizzard = engine(s, [0])
        klondike.tick(blizzard, &q, .sea, blizzard.state.region)
        XCTAssertEqual(blizzard.state.water, 500)

        s.weather = KlondikeData.fair
        let town = engine(s, [0])
        klondike.tick(town, &q, .port, town.state.region)
        XCTAssertEqual(town.state.water, 500)
    }

    // MARK: - The fork

    func testTheForkChoosesThePassAndItsTowns() {
        let e = engine(party(mile: 11100))
        let fork = choice(e.beginArrival("lynn"))
        XCTAssertEqual(key(fork), "fork")
        XCTAssertEqual(fork?.options.count, 3)
        // Advice, then the same question again.
        let advice = e.resolve(fork!, option: 2)
        XCTAssertEqual(messages(advice).count, 1)
        XCTAssertEqual(key(choice(advice)), "fork")

        _ = e.resolve(fork!, option: 1)
        let s = e.state
        XCTAssertEqual(s.vars[KlondikeData.routeKey], KlondikeData.whitePass)
        XCTAssertEqual(klondike.region(s, at: 11250).id, "skagwayValley")
        XCTAssertEqual(klondike.region(s, at: 11400).id, "whitePassSummit")
        XCTAssertEqual(klondike.region(s, at: 11500).id, "logCabin")
        XCTAssertEqual(klondike.region(s, at: 11600).id, "upperLakes")
        XCTAssertEqual(klondike.port(s, at: "landing")?.name, "Skagway")
        XCTAssertEqual(klondike.port(s, at: "camp")?.name, "White Pass City")
        XCTAssertEqual(Klondike.name(klondike.stop("summit")!, s), "the summit of the White Pass")
        XCTAssertEqual(Klondike.shortName(klondike.stop("lakes")!, s), "Log Cabin")

        // Before the fork the legend shows both; after the Chilkoot, its own.
        let before = party(mile: 5000)
        XCTAssertEqual(Klondike.shortName(klondike.stop("landing")!, before), "Dyea · Skagway")
        let chilkoot = party(mile: 11250, pass: KlondikeData.chilkoot)
        XCTAssertEqual(klondike.port(chilkoot, at: "landing")?.name, "Dyea")
        XCTAssertEqual(region(chilkoot).id, "taiya")
    }

    func testDyeaOffersPackersForThoseWhoCanPay() {
        let e = engine(party(mile: 11100))
        let fork = choice(e.beginArrival("lynn"))!
        let packers = choice(e.resolve(fork, option: 0))
        XCTAssertEqual(key(packers), "packers")
        XCTAssertTrue(packers!.options[0].enabled)
        _ = e.resolve(packers!, option: 0)
        XCTAssertEqual(e.state.money, 1700 - 90)
        XCTAssertEqual(e.state.vars[KlondikeData.packersKey], 1)

        var poor = party(mile: 11100)
        poor.money = 50
        let p = engine(poor)
        let ask = choice(p.resolve(choice(p.beginArrival("lynn"))!, option: 0))!
        XCTAssertFalse(ask.options[0].enabled)
        XCTAssertEqual(p.resolve(ask, option: 0), [.choice(ask)])
    }

    func testTownsPriceByThePass() {
        let dyea = party(mile: 11200, pass: KlondikeData.chilkoot)
        let skagway = party(mile: 11200, pass: KlondikeData.whitePass)
        XCTAssertEqual(klondike.port(dyea, at: "landing")!.price(.food), 0.14, accuracy: 1e-9)
        XCTAssertEqual(klondike.port(skagway, at: "landing")!.price(.food), 0.135, accuracy: 1e-9)
        XCTAssertTrue(klondike.port(skagway, at: "landing")!.fever)
        XCTAssertEqual(klondike.port(dyea, at: "camp")!.price(.water), 0.095, accuracy: 1e-9)
        XCTAssertEqual(klondike.port(skagway, at: "camp")!.price(.water), 0.072, accuracy: 1e-9)
        XCTAssertEqual(klondike.port(dyea, at: "bennett")!.price(.timber), 17.6, accuracy: 1e-9)
        XCTAssertEqual(engine(skagway).currentPort?.name, "Skagway")
        XCTAssertEqual(klondike.sickPool(engine(skagway), .cool, klondike.port(skagway, at: "landing")),
                       KlondikeData.feverPortPool)
    }

    func testEachLegGoesAshoreInItsOwnWords() {
        let juneau = choice(engine(party(mile: 10200)).beginArrival("juneau"))
        XCTAssertEqual(juneau?.options.map(\.label), ["Go ashore while the steamer takes on coal", "Stay aboard"])
        let dyea = choice(engine(party(mile: 11200, pass: KlondikeData.chilkoot)).beginArrival("landing"))
        XCTAssertEqual(dyea?.options.map(\.label), ["Stop and make camp here", "Keep moving"])
        XCTAssertTrue(dyea?.prompt.hasPrefix("You have reached Dyea.") ?? false)
        let selkirk = choice(engine(party(mile: 15250)).beginArrival("selkirk"))
        XCTAssertEqual(selkirk?.options.map(\.label), ["Tie up and go ashore", "Float on past"])
    }

    // MARK: - The police

    func testAYearsGrubPassesThePolice() {
        let e = engine(party(mile: KlondikeData.summitMile, pass: KlondikeData.chilkoot))
        let ask = choice(e.beginArrival("summit"))!
        XCTAssertEqual(ask.options.map(\.label), ["Carry on to the lakes"])
        XCTAssertTrue(ask.prompt.contains("Chilkoot"))
        XCTAssertEqual(e.resolve(ask, option: 0), [])
        XCTAssertFalse(e.state.over)
    }

    func testShortOfGrubYouBuyItFetchItOrGoHome() {
        var s = party(mile: KlondikeData.summitMile, pass: KlondikeData.chilkoot)
        s.food = 5000
        let ask = choice(engine(s).beginArrival("summit"))!
        guard case .custom(_, let args) = ask.kind else { return XCTFail() }
        // 475 short; the traders want 30¢ a lb; six days down to Sheep Camp and back.
        XCTAssertEqual(args, ["475", "143", "108", "565"])
        XCTAssertEqual(ask.options.count, 3)
        XCTAssertTrue(ask.options.allSatisfy(\.enabled))

        let buy = engine(s)
        _ = buy.resolve(ask, option: 0)
        XCTAssertEqual(buy.state.money, 1700 - 143)
        XCTAssertEqual(buy.state.food, 5475)

        let fetch = engine(s)
        _ = fetch.resolve(ask, option: 1)
        XCTAssertEqual(fetch.state.money, 1700 - 108)
        XCTAssertEqual(fetch.state.day, 6)
        XCTAssertEqual(fetch.state.food, 5475)

        let home = engine(s)
        let q = home.resolve(ask, option: 2)
        XCTAssertTrue(home.state.over)
        guard case .gameOver(let title, _)? = q.last else { return XCTFail("no ending") }
        XCTAssertEqual(title, "The police have turned you back.")

        s.money = 0
        let broke = choice(engine(s).beginArrival("summit"))!
        XCTAssertEqual(broke.options.map(\.enabled), [false, false, true])
    }

    func testAPartnerKeptCountsAtTheSummitAndOneSentOnLeavesBefore() {
        var s = party(mile: 11250, pass: KlondikeData.chilkoot)
        s.stowawaySeen = false
        let e = engine(s)
        let ask = e.ask("partner", ["Ida", "camp", "Sheep Camp"], prompt: "x", options: [.init("a"), .init("b")])
        guard case .choice(let c) = ask else { return XCTFail() }
        _ = e.resolve(c, option: 1)
        XCTAssertEqual(e.state.crew.last?.leaveAt, "camp")
        e.state.mile = KlondikeData.campMile
        e.state.stopIndex = 4
        _ = e.beginArrival("camp")
        XCTAssertEqual(e.state.living.count, 5)
        XCTAssertEqual(Klondike.requirement(e.state), 5 * 1095)

        let kept = engine(s)
        _ = kept.resolve(c, option: 0)
        XCTAssertNil(kept.state.crew.last?.leaveAt)
        XCTAssertEqual(Klondike.requirement(kept.state), 6 * 1095)
        XCTAssertNotNil(Klondike.shortOfGrubWarning(kept.state))
    }

    // MARK: - Lake Bennett

    func atBennett(month: Int = 3, role: Role = .merchant, _ values: [Double] = []) -> GameEngine {
        var s = party(mile: KlondikeData.bennettMile, month: month, role: role, pass: KlondikeData.chilkoot)
        s.atPort = true
        return engine(s, values)
    }

    func testBennettRollsTheIceAndHasOnlyOneWayIn() {
        let e = atBennett([0])
        e.state.atPort = false
        let ask = choice(e.beginArrival("bennett"))!
        XCTAssertEqual(e.state.vars[KlondikeData.breakupKey], Double(KlondikeData.breakupEarliest))
        XCTAssertEqual(ask.options.map(\.label), ["Make camp at the lakes"])
        XCTAssertTrue(ask.detail?.contains("still frozen") ?? false)
        XCTAssertEqual(e.resolve(ask, option: 0), [.enterPort])
        XCTAssertTrue(e.state.atPort)

        let late = atBennett([0.999])
        _ = late.beginArrival("bennett")
        XCTAssertEqual(late.state.vars[KlondikeData.breakupKey], Double(KlondikeData.dayOfYear(month: 5, day: 1)))
    }

    func testNoBoatNoLeaving() {
        let e = atBennett()
        let q = e.setSail()
        XCTAssertTrue(e.state.atPort)
        XCTAssertEqual(messages(q).count, 1)
        let boat = choice(q)!
        XCTAssertEqual(key(boat), "boat")
        XCTAssertEqual(boat.options.map(\.enabled), [true, true, true, true, true])
        // Not yet: still ashore, still no boat.
        XCTAssertEqual(e.resolve(boat, option: 4), [])
        XCTAssertFalse(Klondike.hasBoat(e.state))
        XCTAssertTrue(e.state.atPort)
    }

    func testBuildingProperlyTakesThreeWeeksAndTheStores() {
        let e = atBennett()
        let boat = choice(e.setSail())!
        let q = e.resolve(boat, option: 0)
        XCTAssertEqual(e.state.day, 21)
        XCTAssertEqual(e.state.timber, 1)
        XCTAssertEqual(e.state.sailcloth, 1)
        XCTAssertEqual(e.state.hull, 100)
        XCTAssertEqual(e.state.sails, 100)
        XCTAssertTrue(Klondike.hasBoat(e.state))
        XCTAssertEqual(Klondike.meterNames(e.state).structure, "Boat")
        XCTAssertTrue(messages(q).last?.contains("three weeks") ?? false)
        XCTAssertTrue(e.state.atPort)

        let builder = atBennett(role: .shipwright)
        let q2 = builder.resolve(choice(builder.setSail())!, option: 0)
        XCTAssertEqual(builder.state.day, 14)
        XCTAssertTrue(messages(q2).last?.contains("two weeks") ?? false)
    }

    func testTheQuickBoatsAreWorseExceptInABoatbuildersHands() {
        let scow = atBennett()
        _ = scow.resolve(choice(scow.setSail())!, option: 1)
        XCTAssertEqual(scow.state.day, 9)
        XCTAssertTrue((60...75).contains(Int(scow.state.hull)))
        XCTAssertEqual(scow.state.sails, 80)

        let stout = atBennett(role: .shipwright)
        _ = stout.resolve(choice(stout.setSail())!, option: 1)
        XCTAssertEqual(stout.state.day, 6)
        XCTAssertTrue((85...95).contains(Int(stout.state.hull)))
        XCTAssertEqual(stout.state.sails, 95)

        let bought = atBennett()
        _ = bought.resolve(choice(bought.setSail())!, option: 2)
        XCTAssertEqual(bought.state.money, 1700 - 220)
        XCTAssertEqual(bought.state.day, 2)

        let poor = atBennett()
        poor.state.money = 0
        poor.state.timber = 0
        poor.state.sailcloth = 0
        let ask = choice(poor.setSail())!
        XCTAssertEqual(ask.options.map(\.enabled), [false, false, false, true, true])
        _ = poor.resolve(ask, option: 3)
        XCTAssertEqual(poor.state.day, 5)
        XCTAssertTrue((35...45).contains(Int(poor.state.hull)))
        XCTAssertEqual(poor.state.sails, 50)
    }

    func testTheIceHoldsYouUntilItGoesOut() {
        let e = atBennett()
        e.state.vars[KlondikeData.breakupKey] = Double(KlondikeData.breakupEarliest)
        e.state.vars[KlondikeData.boatKey] = 1
        let ice = choice(e.setSail())!
        XCTAssertEqual(key(ice), "ice")
        XCTAssertEqual(e.resolve(ice, option: 1), [])
        XCTAssertTrue(e.state.atPort)

        let q = e.resolve(ice, option: 0)
        XCTAssertFalse(e.state.atPort)
        XCTAssertEqual(e.state.date.month, 4)
        XCTAssertEqual(e.state.date.day, 24)
        XCTAssertTrue(messages(q).last?.contains("May 24, 1898") ?? false)

        // Once the ice is out, a boat leaves at once.
        let june = atBennett(month: 5)
        june.state.vars[KlondikeData.breakupKey] = Double(KlondikeData.breakupEarliest)
        june.state.vars[KlondikeData.boatKey] = 1
        XCTAssertEqual(june.setSail(), [])
        XCTAssertFalse(june.state.atPort)
    }

    func testRepairsAndWrecksSpeakOfWhatYouHave() {
        var s = party(mile: 11250)
        s.hull = 50
        s.sails = 50
        let outfit = engine(s)
        XCTAssertTrue(messages(outfit.patchHull()).last?.contains("Outfit now 70%") ?? false)
        XCTAssertTrue(messages(outfit.mendSails()).last?.contains("Sleds now 75%") ?? false)
        XCTAssertEqual(klondike.wreckedTitle(s), "Your outfit is ruined.")

        s.vars[KlondikeData.boatKey] = 1
        let boat = engine(s)
        XCTAssertTrue(messages(boat.patchHull()).last?.contains("Boat now 70%") ?? false)
        XCTAssertTrue(messages(boat.mendSails()).last?.contains("Oars & sail now 75%") ?? false)
        XCTAssertEqual(klondike.wreckedTitle(s), "The [i]Klondike Belle[/i] has broken up.")
        XCTAssertTrue(klondike.repaired(s, .yardHull).contains("boatwrights"))
        XCTAssertTrue(klondike.repaired(party(), .yardHull).contains("re-sacks"))
    }

    func testSpoilageAndWarningsSpeakOfWhatYouHave() {
        var s = party(mile: 11400)
        s.hull = 20
        s.sails = 20
        let outfit = engine(s, [0, 0])
        var q: [Interrupt] = []
        klondike.tick(outfit, &q, .sail, outfit.state.region)
        XCTAssertEqual(outfit.state.food, 5980)
        XCTAssertEqual(messages(q).count, 3)
        XCTAssertTrue(messages(q)[0].contains("Meltwater"))
        XCTAssertTrue(messages(q)[1].contains("outfit is falling apart"))
        XCTAssertTrue(messages(q)[2].contains("sleds are wrecks"))
        // Once said, not said again until mended above half.
        q = []
        klondike.tick(outfit, &q, .sail, outfit.state.region)
        XCTAssertTrue(messages(q).filter { $0.contains("falling apart") }.isEmpty)

        s.mile = 13500
        s.vars[KlondikeData.boatKey] = 1
        s.weather = KlondikeData.blizzard
        let boat = engine(s, [0, 0])
        q = []
        klondike.tick(boat, &q, .sail, boat.state.region)
        XCTAssertTrue(messages(q)[0].contains("bilge"))
        XCTAssertTrue(messages(q)[1].contains("leaking like a basket"))
        XCTAssertTrue(messages(q)[2].contains("down to one good oar"))
    }

    // MARK: - The river

    func testMilesCanyonTakesAPilotOrFourDays() {
        var s = party(mile: 12530)
        s.vars[KlondikeData.boatKey] = 1
        s.money = 100
        let pilot = engine(s)
        let ask = choice(pilot.beginArrival("canyon"))!
        XCTAssertTrue(ask.options[0].enabled)
        _ = pilot.resolve(ask, option: 0)
        XCTAssertEqual(pilot.state.money, 75)
        XCTAssertEqual(pilot.state.hull, 100)

        let portage = engine(s)
        _ = portage.resolve(ask, option: 1)
        XCTAssertEqual(portage.state.day, 4)
        XCTAssertEqual(portage.state.money, 100)

        let advice = engine(s).resolve(ask, option: 2)
        XCTAssertEqual(key(choice(advice)), "canyon")

        s.money = 10
        XCTAssertFalse(choice(engine(s).beginArrival("canyon"))!.options[0].enabled)
    }

    func testFiveFingersCanHoleTheBoatOrCostTwoDays() {
        var s = party(mile: 14670)
        s.vars[KlondikeData.boatKey] = 1
        let ask = choice(engine(s).beginArrival("fivefinger"))!
        let hit = engine(s, [0, 0, 0.999])
        _ = hit.resolve(ask, option: 0)
        XCTAssertEqual(hit.state.hull, 88)
        let line = engine(s)
        _ = line.resolve(ask, option: 1)
        XCTAssertEqual(line.state.day, 2)
        XCTAssertEqual(line.state.hull, 100)
    }

    // MARK: - Hazards and weather

    func testASnowslideCanTakeTheLeader() {
        let e = engine(party(mile: 11400), [0.9, 0, 0.9])
        var q: [Interrupt] = []
        klondike.snowslide(e, &q)
        XCTAssertTrue(e.state.over)
        guard case .gameOver(let title, _)? = q.last else { return XCTFail("no ending") }
        XCTAssertEqual(title, "You, Will, have been lost in a snowslide.")

        let cache = engine(party(mile: 11400), [0, 0, 0])
        q = []
        klondike.snowslide(cache, &q)
        XCTAssertEqual(cache.state.hull, 90)
        XCTAssertEqual(cache.state.food, 5900)
        XCTAssertTrue(messages(q)[0].contains("Outfit −10%"))
    }

    func testSlidesAreAChilkootSpringThing() {
        let chilkoot = region(party(mile: 11400, pass: KlondikeData.chilkoot))
        let white = region(party(mile: 11400, pass: KlondikeData.whitePass))
        XCTAssertEqual(chilkoot.num("slideSpring"), 0.02)
        XCTAssertEqual(white.num("slideSpring"), 0.005)
        XCTAssertGreaterThan(chilkoot.num("slide"), white.num("slide"))
    }

    func testTheSeasonsMoveTheColdAndTheIce() {
        XCTAssertEqual(klondike.temperature(party(month: 1), in: region(party(mile: 11400))), .freezing)
        XCTAssertEqual(klondike.temperature(party(month: 3), in: region(party(mile: 11400))), .cold)
        XCTAssertTrue(klondike.harshSeason(party(month: 0)))
        XCTAssertFalse(klondike.harshSeason(party(month: 2)))
        func has(_ w: WeatherOdds, _ k: Weather) -> Bool { w.contains { $0.0 == k } }
        let june = engine(party(mile: 12800, month: 5))
        XCTAssertTrue(has(klondike.weatherWeights(june, june.state.region, cursed: false), KlondikeData.ice))
        let july = engine(party(mile: 12800, month: 6))
        XCTAssertFalse(has(klondike.weatherWeights(july, july.state.region, cursed: false), KlondikeData.ice))
    }

    func testSundogsBringTwoClearDays() {
        let e = engine(party(mile: 11400))
        e.state.vars[KlondikeData.clearKey] = 2
        let w = klondike.weatherWeights(e, e.state.region, cursed: false)
        XCTAssertEqual(w.map(\.0), [KlondikeData.clear])
        var q: [Interrupt] = []
        klondike.tick(e, &q, .sail, e.state.region)
        klondike.tick(e, &q, .port, e.state.region)
        XCTAssertEqual(e.state.vars[KlondikeData.clearKey], 1)
    }

    func testFishNeedOpenWaterAndAStop() {
        XCTAssertTrue(engine(party(mile: 5000)).fishingRefusal?.contains("steamer") ?? false)
        XCTAssertTrue(engine(party(mile: 11400)).fishingRefusal?.contains("nothing to fish") ?? false)
        XCTAssertNil(engine(party(mile: 11500)).fishingRefusal)
        var s = party(mile: 13500)
        s.weather = KlondikeData.wind
        XCTAssertEqual(engine(s).fishingRefusal, klondike.text.tooRough)
        s.tackle = 0
        XCTAssertEqual(engine(s).fishingRefusal, klondike.text.noTackle)
        let e = engine(party(mile: 13500))
        e.state.food = 100
        _ = e.landCatch(200)
        XCTAssertGreaterThanOrEqual(e.state.food, 200)
    }

    func testWhatAilsYouDependsOnTheCold() {
        let e = engine(party(mile: 11400))
        XCTAssertTrue(klondike.sickPool(e, .freezing, nil).contains(KlondikeData.frostbite))
        XCTAssertFalse(klondike.sickPool(e, .cool, nil).contains(KlondikeData.frostbite))
        XCTAssertEqual(klondike.deficiency, KlondikeData.scurvy)
    }

    // MARK: - Trade and score

    func testTradeTalkCarriesItsOwnUnits() {
        XCTAssertEqual(klondike.describe(.item(.tackle), 40), "2 boxes of hooks & line")
        XCTAssertEqual(klondike.describe(.item(.tackle), 20), "1 box of hooks & line")
        XCTAssertEqual(klondike.describe(.item(.sailcloth), 1), "1 coil of rope & rawhide")
        XCTAssertEqual(klondike.describe(.item(.meds), 2), "2 medicine kits")
        XCTAssertEqual(klondike.describe(.item(.food), 1250), "1,250 lbs of provisions")
        XCTAssertEqual(klondike.tradeValue(.item(.food)), 0.14)
        XCTAssertEqual(klondike.tradeValue(.item(.tackle)), 0.15, accuracy: 1e-9)
    }

    func testDawsonAheadOfTheCrowdScoresTwentyADay() {
        var s = party(mile: 17000)
        s.day = 111 // March 1 + 111 days = June 20
        XCTAssertEqual(s.date.month, 5)
        XCTAssertEqual(s.date.day, 20)
        let early = klondike.score(s).lines.first { $0.label == Klondike.crowdLabel }
        XCTAssertEqual(early?.points, 42 * 20)
        s.day = 160
        XCTAssertEqual(klondike.score(s).lines.first { $0.label == Klondike.crowdLabel }?.points, 0)
        XCTAssertEqual(klondike.score(party(role: .whaler)).multiplier, 3)
        XCTAssertEqual(klondike.rank(7000), "Sourdough")
        XCTAssertEqual(klondike.rank(1999), "Cheechako")
    }

    // MARK: - What the words say matches the tables

    func testJuneauFursAreCheaperThanSeattlesAsTheStorekeeperSays() {
        let s = party(mile: 10200)
        let seattle = klondike.port(s, at: "seattle")!.price(.clothes)
        let juneau = klondike.port(s, at: "juneau")!
        XCTAssertTrue(juneau.talk.contains { $0.contains("Furs are cheaper here than in Seattle") })
        XCTAssertEqual(seattle, 12)
        XCTAssertEqual(juneau.price(.clothes), 11.25, accuracy: 1e-9)
        XCTAssertLessThan(juneau.price(.clothes), seattle)
    }

    /// Both passes run the same miles in the table; the White Pass is only slower going.
    func testTheWhitePassIsSlowerNotLonger() {
        let e = engine(party(mile: 11100))
        let fork = choice(e.beginArrival("lynn"))!
        let advice = messages(e.resolve(fork, option: 2)).joined()
        for line in [advice, fork.detail ?? ""] {
            XCTAssertFalse(line.contains("longer"), line)
            XCTAssertFalse(line.contains("ten miles"), line)
        }
        XCTAssertTrue(advice.contains("slower"))
        let skagway = party(mile: 11200, pass: KlondikeData.whitePass)
        XCTAssertFalse(klondike.port(skagway, at: "landing")!.talk.contains { $0.contains("long.") })
        XCTAssertEqual(KlondikeData.bennettMile - KlondikeData.landingMile, 330)
    }

    func testTheWhitePassSmithPointsToBennettWhereTheSledMakerIs() {
        let white = party(mile: KlondikeData.campMile, pass: KlondikeData.whitePass)
        let talk = klondike.port(white, at: "camp")!.talk.joined()
        XCTAssertFalse(talk.contains("no smith"))
        XCTAssertTrue(talk.contains("Bennett"))
        // And Bennett's yard does mend sleds before the boat.
        let e = atBennett()
        e.state.sails = 30
        XCTAssertTrue(e.canRecutSailsAtYard)
        XCTAssertEqual(klondike.repaired(e.state, .yardSails), "The sled maker fits new runners and fresh harness.")
    }

    func testTheStowawayIsNotAlwaysTwoDaysOut() {
        var s = party(mile: 8000)
        s.day = 7
        s.stowawaySeen = false
        let e = engine(s)
        let events = klondike.trailEvents(e, e.state.region)
        var q: [Interrupt] = []
        events[11].run(e, &q)
        let ask = choice(q)!
        XCTAssertEqual(key(ask), "partner")
        XCTAssertFalse(ask.prompt.contains("Two days out"))
        XCTAssertTrue(ask.prompt.contains("purser"))
    }

    func testABreakThroughOnTheLakeIsOnTheLake() {
        let e = engine(party(mile: 11500, pass: KlondikeData.chilkoot), [0, 0, 0, 0.9])
        guard case .choice(let ask) = e.ask("thinice", prompt: "x", options: [.init("a"), .init("b")]) else { return XCTFail() }
        let lines = messages(e.resolve(ask, option: 1)).joined(separator: "\n")
        XCTAssertTrue(lines.contains("the ice gives way under a loaded sled"), lines)
        XCTAssertFalse(lines.contains("creek"), lines)
        XCTAssertTrue(lines.contains("is gone"), lines)
        XCTAssertEqual(e.state.graves.last?.epitaph, "Lost through the lake ice. No grave but the lake.")
        // A break-through on the trail itself (E8) is still at a creek.
        var q: [Interrupt] = []
        klondike.overboard(engine(party(mile: 11400), [0, 0]), &q, onFoot: true, epitaph: nil)
        XCTAssertTrue(messages(q)[0].contains("creek"))
    }

    func testARuinedOutfitPastTheSummitHasNoPoliceToShow() {
        XCTAssertTrue(klondike.wreckedBody(party(mile: 11300)).contains("show the police"))
        XCTAssertTrue(klondike.wreckedBody(party(mile: KlondikeData.summitMile)).contains("show the police"))
        let past = klondike.wreckedBody(party(mile: 11500))
        XCTAssertFalse(past.contains("police"), past)
        var boat = party(mile: 13500)
        boat.vars[KlondikeData.boatKey] = 1
        XCTAssertEqual(klondike.wreckedBody(boat), klondike.text.wreckedBody)
    }

    /// Alaska begins at Dixon Entrance, about mile 650.
    func testTheAlaskaCoastStartsAtDixonEntrance() {
        XCTAssertEqual(region(party(mile: 4500)).name, "The British Columbia coast")
        XCTAssertEqual(region(party(mile: 6499)).name, "The British Columbia coast")
        XCTAssertEqual(region(party(mile: 6500)).name, "The Alaska coast")
        XCTAssertEqual(Klondike.legName(party(mile: 4500)), "steamer")
    }

    // MARK: - Balance

    /// The sensible player of the spec (§18): a year's grub for the police and the run to the
    /// summit, firewood for the bare summit, lime juice for the long camps, spares kept while
    /// $60 stays in hand before the summit.
    static func shop(_ e: GameEngine) {
        guard let port = e.currentPort else { return }
        let s = e.state
        let j = e.journey
        let n = Double(s.living.count)
        let lb = j.rations(s.rations).amount
        let boat = Klondike.hasBoat(s)
        let beforeSummit = s.mile < KlondikeData.summitMile
        let beforeBennett = s.mile < KlondikeData.bennettMile
        let today = KlondikeData.dayOfYear(s)
        let nextTown = j.stops[(s.stopIndex + 1)...].first { $0.type == .port || $0.type == .end }!
        var wait = 0.0
        if !boat {
            let atBennett = Double(today) + days(e, s.mile, KlondikeData.bennettMile)
            wait = max(0, Double(KlondikeData.breakupUsual) - atBennett)
        }
        let toNext = days(e, s.mile, nextTown.mile)
        var wood = n * 4 * 1.5 * 10
        if beforeBennett { wood += n * 4 * 2 * 1.5 * days(e, s.mile, KlondikeData.bennettMile, treelessOnly: true) }
        if s.currentStop.id == "bennett" && !boat { wood += 10 * max(0, Double(KlondikeData.breakupUsual - today)) }
        let reserve = beforeSummit ? 60.0 : 0
        let wants: [(ItemKey, Double, Double)] = [
            (.food, beforeSummit ? KlondikeData.yearOfGrub * n + n * lb * (days(e, s.mile, KlondikeData.summitMile) + 15)
                                 : n * lb * (toNext + 10 + wait), 0),
            (.water, wood, 0),
            (.limes, n * 0.02 * (toNext + 10 + wait), reserve),
            (.clothes, n, 0),
            (.meds, 2, reserve),
            (.sailcloth, boat ? 2 : 3, reserve),
            (.timber, boat ? 2 : 4, reserve),
            (.tackle, s.role == .merchant ? 0 : 60, reserve),
        ]
        var cart: [ItemKey: Int] = [:]
        var total = 0.0
        for (k, target, keep) in wants {
            let it = j.item(k)
            var units = Int(((target - s[k]) / Double(it.per) / Double(it.step)).rounded(.up)) * it.step
            units = min(max(0, units), e.room(for: k))
            let price = port.price(k)
            while units > 0 && total + Double(units) * price > s.money - keep { units -= it.step }
            units = max(0, units)
            cart[k, default: 0] += units
            total += Double(units) * price
        }
        e.buy(cart)
    }

    /// The bot's planning speeds: steamer 170 mi a day, the trail 0.6 (by the region's speed
    /// and the miner's back), the river 24.
    static func days(_ e: GameEngine, _ from: Int, _ to: Int, treelessOnly: Bool = false) -> Double {
        var m = from
        var d = 0.0
        while m < to {
            let reg = e.journey.region(e.state, at: m)
            let end = min(reg.to, to)
            let rate: Double
            switch KlondikeData.leg(reg) {
            case .steamer: rate = 1700
            case .foot: rate = 6 * reg.num("speed") * (e.state.role == .whaler ? KlondikeData.minerTrail : 1)
            case .boat: rate = 240
            }
            if !treelessOnly || (KlondikeData.leg(reg) == .foot && !reg.has("timber")) { d += Double(end - m) / rate }
            m = end
        }
        return d
    }

    /// March unless told otherwise; the pass at random unless told (0 Chilkoot, 1 White Pass).
    static func policy(departure: Int = 2, pass: Int? = nil, reckless: Bool = false) -> JourneyBot.Policy {
        var p = JourneyBot.Policy()
        p.departure = departure
        p.rations = [.merchant: .filling, .shipwright: .meager, .whaler: .meager]
        p.shopHere = shop
        p.useYard = { e in !(e.state.currentStop.id == "bennett" && !Klondike.hasBoat(e.state)) }
        p.yardBelow = 70
        p.yardAfterShop = true
        p.mendBelow = 40
        p.restBelowHP = 70
        p.restTurns = 3
        p.forageBelowTurns = [.shipwright: 12, .whaler: 12]
        p.hitChance = [.merchant: 0.35, .shipwright: 0.35, .whaler: 0.35]
        p.decide = { e, c in
            switch c.kind {
            case .tradeOffer: return 1
            case .custom(let key, let args):
                switch key {
                case "fork": return pass ?? (e.chance(0.5) ? 0 : 1)
                case "packers": return e.state.money >= 240 ? 0 : 1
                case "quitters", "partner", "rumour": return 1
                case "fivefinger", "slidewarning", "thinice": return reckless ? (key == "fivefinger" ? 0 : 1) : (key == "fivefinger" ? 1 : 0)
                case "ice": return 0
                case "canyon": return c.options[0].enabled ? 0 : 1
                case "police":
                    guard args.count == 4, let a = Int(args[1]), let b = Int(args[2]) else { return 0 }
                    let can = (c.options[0].enabled, c.options[1].enabled)
                    switch can {
                    case (true, true): return a <= b ? 0 : 1
                    case (true, false): return 0
                    case (false, true): return 1
                    default: return 2
                    }
                case "boat":
                    let left = KlondikeData.breakupUsual - KlondikeData.dayOfYear(e.state)
                    if c.options[0].enabled && left >= Klondike.buildDays(e.state.role).proper { return 0 }
                    if e.state.role == .merchant && c.options[2].enabled { return 2 }
                    if c.options[1].enabled { return 1 }
                    if c.options[2].enabled { return 2 }
                    return 3
                default: return nil
                }
            default: return nil
            }
        }
        return p
    }

    /// March is the month the old-timers recommend. The storekeeper should nearly always
    /// reach Dawson, the boatbuilder usually, the miner about half the time; a winning run
    /// takes about four months.
    func testMarchBalanceStaysInItsBands() {
        XCTAssertEqual(KlondikeData.departures[2].month, 2)
        let r = JourneyBot.survey(klondike, count: 30, seed: 1898, policy: Self.policy())
        print(r.report)
        XCTAssertGreaterThanOrEqual(r.rates[.merchant] ?? 0, 0.85, r.report)
        XCTAssertGreaterThanOrEqual(r.rates[.shipwright] ?? 0, 0.6, r.report)
        XCTAssertLessThanOrEqual(r.rates[.shipwright] ?? 1, 0.9 + 1e-9, r.report)
        XCTAssertGreaterThanOrEqual(r.rates[.whaler] ?? 0, 0.35, r.report)
        XCTAssertLessThanOrEqual(r.rates[.whaler] ?? 1, 0.7, r.report)
        XCTAssertTrue((110...140).contains(r.medianTurns), r.report)
    }

    /// January crosses the pass in deep winter: the poorer parties freeze and wear out.
    func testJanuaryIsTheTrap() {
        let march = JourneyBot.survey(klondike, count: 30, seed: 1898, policy: Self.policy())
        let january = JourneyBot.survey(klondike, count: 30, seed: 1898, policy: Self.policy(departure: 0))
        print(january.report)
        for role in [Role.shipwright, .whaler] {
            XCTAssertLessThan(january.rates[role] ?? 1, (march.rates[role] ?? 0) - 0.3, january.report)
        }
        XCTAssertGreaterThan(january.medianTurns, march.medianTurns + 30, january.report)
    }

    /// Hard driving on the trail on short rations wears the party out.
    func testHardDrivingIsHarder() {
        let march = JourneyBot.survey(klondike, count: 30, seed: 1898, policy: Self.policy())
        var p = Self.policy()
        p.pace = .full
        let hard = JourneyBot.survey(klondike, count: 30, seed: 1898, policy: p)
        print(hard.report)
        for role in [Role.shipwright, .whaler] {
            XCTAssertLessThan(hard.rates[role] ?? 1, (march.rates[role] ?? 0) - 0.3, hard.report)
        }
    }

    func testLosingRunsEndMoreThanOneWay() {
        var endings = Set<String>()
        for i in 0..<30 {
            let r = JourneyBot(journey: klondike, role: .whaler, seed: 1898 + UInt64(1000 * Role.whaler.scoreMultiplier + i),
                               policy: Self.policy()).play()
            if !r.won { endings.insert(r.ending) }
        }
        XCTAssertGreaterThanOrEqual(endings.count, 3, "\(endings)")
        XCTAssertTrue(endings.contains("The police have turned you back."), "\(endings)")
    }
}
