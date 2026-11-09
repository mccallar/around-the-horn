import XCTest
@testable import HornEngine

/// Spec §12 M1 acceptance checks, one group per item, plus the paths the parity voyages
/// don't happen to reach.
final class EngineTests: XCTestCase {
    // MARK: - Consumption math

    func testDailyConsumptionInTheTropics() {
        var s = GameState.fixture()
        s.mile = 4000  // the Doldrums: hot
        let e = engine(s)
        var q: [Interrupt] = []
        e.consume(&q, .sail)
        XCTAssertEqual(e.state.food, 2000 - 5 * 3)
        XCTAssertEqual(e.state.water, 800 - 5 * 1.5)
        XCTAssertEqual(e.state.limes, 10 - 5 * 0.02, accuracy: 1e-12)
        XCTAssertEqual(e.state.noCitrus, 0)
        XCTAssertTrue(q.isEmpty)
    }

    func testRationsAndCrewSizeSetTheFoodBill() {
        var s = GameState.fixture()
        s.rations = .bare
        s.crew[4].alive = false
        let e = engine(s)
        var q: [Interrupt] = []
        e.consume(&q, .sail)
        XCTAssertEqual(e.state.food, 2000 - 4 * 1)
        XCTAssertEqual(e.state.water, 800 - 4)
    }

    func testInPortCitrusIsNotEatenAndTheClockResets() {
        var s = GameState.fixture()
        s.noCitrus = 20
        s.limes = 0
        let e = engine(s)
        var q: [Interrupt] = []
        e.consume(&q, .port)
        XCTAssertEqual(e.state.noCitrus, 0)
        XCTAssertFalse(q.contains(.message("The last of the citrus is gone. Scurvy will follow within a few weeks unless you find fresh food.")))
    }

    func testRainFillsTheCasks() {
        var s = GameState.fixture()
        s.weather = .rain
        let e = engine(s, [0])  // ri(15, 45) → 15
        var q: [Interrupt] = []
        e.consume(&q, .sail)
        XCTAssertEqual(e.state.water, 800 - 5 + 15)
        XCTAssertEqual(e.state.note, "Caught 15 gallons of rainwater in the sails.")
    }

    func testRunningOutOfFoodStarvesTheCrewAndWarnsOnce() {
        var s = GameState.fixture()
        s.food = 10
        let e = engine(s)
        var q: [Interrupt] = []
        e.consume(&q, .sail)
        XCTAssertEqual(e.state.food, 0)
        XCTAssertTrue(e.state.starving)
        XCTAssertEqual(q.first, .message("[red]You have run out of provisions![/red] The crew is starving."))
        var again: [Interrupt] = []
        e.consume(&again, .sail)
        XCTAssertTrue(again.isEmpty, "the warning is one-time until food recovers")
    }

    // MARK: - Scurvy after 35 citrus-free days

    func testNoScurvyRollUntilDay36WithoutCitrus() {
        var s = GameState.fixture()
        s.limes = 0
        s.noCitrus = 35
        let e = engine(s)
        var q: [Interrupt] = []
        e.health(&q, .sail)
        XCTAssertEqual((e.rng as! ScriptedRNG).draws, 5, "one illness roll per sailor, no scurvy roll")
        XCTAssertTrue(e.state.crew.allSatisfy { $0.ailment == nil })
    }

    func testScurvyCanStrikeOnDay36() {
        var s = GameState.fixture()
        s.limes = 0
        s.noCitrus = 36
        // Captain: ordinary illness roll fails, scurvy roll (0.004) succeeds, then pick + ri.
        let e = engine(s, [0.999, 0.001, 0, 0])
        var q: [Interrupt] = []
        e.health(&q, .sail)
        XCTAssertEqual(e.state.crew[0].ailment, .scurvy)
        XCTAssertFalse(e.state.crew[0].treated, "medicine doesn't treat scurvy")
        XCTAssertEqual(e.state.meds, 4)
        XCTAssertEqual(q.first, .message("Ezra has scurvy. [dim]Bleeding gums, aching joints. Citrus or a run ashore will cure it.[/dim]"))
    }

    func testScurvyOddsGrowWithTheDaysAndCapAt12Percent() {
        // (noCitrus − 35) × 0.004, capped at 0.12: a draw of 0.119 strikes at day 65.
        var s = GameState.fixture()
        s.limes = 0
        s.noCitrus = 65
        let e = engine(s, [0.999, 0.119, 0, 0])
        var q: [Interrupt] = []
        e.health(&q, .sail)
        XCTAssertEqual(e.state.crew[0].ailment, .scurvy)
        s.noCitrus = 100
        let capped = engine(s, [0.999, 0.1201, 0, 0])
        capped.health(&q, .sail)
        XCTAssertNil(capped.state.crew[0].ailment)
    }

    // MARK: - Medicine halves the damage

    func testMedicineHalvesAnAilmentsDamage() {
        func hpAfterADay(treated: Bool) -> Double {
            var s = GameState.fixture()
            s.crew[0].hp = 50
            s.crew[0].ailment = .shipFever
            s.crew[0].ailDays = 10
            s.crew[0].treated = treated
            let e = engine(s)
            var q: [Interrupt] = []
            e.health(&q, .sea)
            return e.state.crew[0].hp
        }
        // Filling rations +1, hove to +3, ship fever 4.5 (halved: 2.25), no natural recovery.
        XCTAssertEqual(hpAfterADay(treated: false), 50 + 1 + 3 - 4.5)
        XCTAssertEqual(hpAfterADay(treated: true), 50 + 1 + 3 - 2.25)
    }

    func testFallingIllOpensAMedicineKit() {
        let e = engine(.fixture(), [0, 0, 0])  // illness roll succeeds, pick, ri
        var q: [Interrupt] = []
        e.health(&q, .sail)
        XCTAssertNotNil(e.state.crew[0].ailment)
        XCTAssertTrue(e.state.crew[0].treated)
        XCTAssertEqual(e.state.meds, 3)
        guard case .message(let t) = q.first else { return XCTFail("no message") }
        XCTAssertTrue(t.hasSuffix("[dim]You open a medicine kit (3 left).[/dim]"), t)
    }

    // MARK: - Death and disaster

    func testTheCaptainsDeathEndsTheVoyage() {
        var s = GameState.fixture()
        s.crew[0].hp = 1
        s.food = 0
        s.water = 0
        let e = engine(s)
        var q: [Interrupt] = []
        e.consume(&q, .sail)
        e.health(&q, .sail)
        XCTAssertTrue(e.state.over)
        XCTAssertEqual(q.last, .gameOver(title: "You, Captain Ezra, have died of thirst.",
                                         body: "The crew sails the ship into the nearest port and scatters. The voyage is over."))
        XCTAssertFalse(q.contains { if case .burial = $0 { return true } else { return false } })
    }

    func testACrewMembersDeathMeansABurial() {
        var s = GameState.fixture()
        s.crew[2].hp = 1
        s.crew[2].ailment = .yellowFever
        s.crew[2].ailDays = 5
        let e = engine(s)
        var q: [Interrupt] = []
        e.health(&q, .sail)
        XCTAssertFalse(e.state.over)
        XCTAssertEqual(q.last, .burial(crewID: s.crew[2].id, cause: "yellow fever"))
        e.commitBurial(crewID: s.crew[2].id, cause: "yellow fever", epitaph: "  ")
        XCTAssertEqual(e.state.graves, [Grave(name: "Silas", cause: "yellow fever", date: "January 1, 1849",
                                              epitaph: "Fair winds, shipmate.")])
    }

    func testABrokenArmKillsAsAnInfectedWound() {
        XCTAssertEqual(Ailment.brokenArm.deathName, "an infected wound")
        XCTAssertEqual(Ailment.pneumonia.deathName, "pneumonia")
    }

    func testAHullAtZeroSinksTheShip() {
        var s = GameState.fixture()
        s.hull = 0.02  // a fair day's 0.03 finishes her
        let e = engine(s)
        var q: [Interrupt] = []
        e.wear(&q, s.region)
        XCTAssertEqual(e.state.hull, 0)
        XCTAssertTrue(e.state.over)
        XCTAssertEqual(q.last, .gameOver(title: "The [i]Resolute[/i] has foundered.",
                                         body: "Her seams opened faster than the pumps could keep up. She went down by the head, taking everything with her."))
    }

    func testNothingFollowsASinking() {
        var s = GameState.fixture()
        s.hull = 0.02
        s.mile = 250  // would otherwise arrive at the Gulf Stream
        let e = engine(s)
        let q = e.sailDay()
        guard case .gameOver = q.last else { return XCTFail("\(q)") }
        XCTAssertFalse(q.contains(.arrival(stopID: "gulf")))
    }

    // MARK: - Arrival exactly at the stop

    func testArrivalClampsToTheStopsMile() {
        var s = GameState.fixture()
        s.mile = 2890
        s.stopIndex = 1
        let e = engine(s)
        let q = e.sailDay()
        XCTAssertEqual(e.state.mile, 2900)
        XCTAssertEqual(e.state.stopIndex, 2)
        XCTAssertEqual(q.last, .arrival(stopID: "cv"))
    }

    func testNoArrivalShortOfTheStop() {
        var s = GameState.fixture()
        s.mile = 10
        let e = engine(s)
        let q = e.sailDay()
        XCTAssertLessThan(e.state.mile, 300)
        XCTAssertEqual(e.state.stopIndex, 0)
        XCTAssertFalse(q.contains(.arrival(stopID: "gulf")))
    }

    func testArrivingAtAPortSendsTheStowawayAshore() {
        var s = GameState.fixture()
        s.crew.append(CrewMember(name: "Asa", hp: 85, leaveAt: "cv"))
        s.stopIndex = 2
        s.tradesLeft = 0
        let e = engine(s)
        let q = e.beginArrival("cv")
        XCTAssertFalse(e.state.crew.contains { $0.name == "Asa" })
        XCTAssertEqual(e.state.tradesLeft, 3)
        guard case .choice(let c) = q.first else { return XCTFail("\(q)") }
        XCTAssertEqual(c.kind, .portArrival(stopID: "cv"))
        XCTAssertTrue(c.detail!.hasSuffix("[dim]Asa waves goodbye from the quay.[/dim]"))
        XCTAssertEqual(e.resolve(c, option: 0), [.enterPort])
        XCTAssertTrue(e.state.atPort)
    }

    // MARK: - Strait region selection

    func testTheStraitReplacesTheRegionOnlyBetween7350And7799() {
        var s = GameState.fixture()
        s.passage = .magellan
        XCTAssertEqual(s.region(at: 7349).id, .roaringForties)
        XCTAssertEqual(s.region(at: 7350).id, .magellan)
        XCTAssertEqual(s.region(at: 7799).id, .magellan)
        XCTAssertEqual(s.region(at: 7800).id, .humboldt)
        s.passage = .horn
        XCTAssertEqual(s.region(at: 7350).id, .capeHorn)
        s.passage = nil
        XCTAssertEqual(s.region(at: 7799).id, .capeHorn)
    }

    func testInStraitFollowsTheMile() {
        var s = GameState.fixture()
        s.passage = .magellan
        s.mile = 7500
        XCTAssertTrue(s.inStrait)
        s.passage = .horn
        XCTAssertFalse(s.inStrait)
    }

    // MARK: - Southern-winter weather

    static func weights(_ w: [(Weather, Double)]) -> [String] { w.map { "\($0.0.rawValue) \($0.1)" } }

    func testSouthernWinterAtTheHorn() {
        let june = GameState.fixture(year: 1849, month: 5)
        XCTAssertTrue(june.southernWinter)
        let w = engine(june).weatherWeights(GameData.regions[5], cursed: false)
        XCTAssertEqual(Self.weights(w), ["gale 55.0", "storm 58.0", "cold 37.0", "fog 8.0",
                                         "fresh \(7 * 0.6)", "fair 0.0"])
    }

    func testSouthernWinterElsewhereInTheSouthAddsLessStorm() {
        let july = GameState.fixture(year: 1849, month: 6)
        let w = engine(july).weatherWeights(GameData.regions[4], cursed: false)
        XCTAssertEqual(Self.weights(w), ["fresh \(22 * 0.6)", "gale 50.0", "storm 30.0", "rain 14.0", "fog 10.0",
                                         "cold 27.0", "fair 0.0"])
    }

    func testSouthernSummerLeavesTheWeightsAlone() {
        let jan = GameState.fixture(year: 1849, month: 0)
        let w = engine(jan).weatherWeights(GameData.regions[5], cursed: false)
        XCTAssertEqual(Self.weights(w), Self.weights(GameData.regions[5].weights))
    }

    func testNorthAtlanticWinterAndTheAlbatrossCurse() {
        let dec = GameState.fixture(year: 1848, month: 11)
        let w = engine(dec).weatherWeights(GameData.regions[0], cursed: true)
        XCTAssertEqual(Self.weights(w), ["fair 30.0", "fresh 22.0", "rain 14.0", "gale 42.0", "fog 8.0",
                                         "storm 25.0", "light 7.0", "calm 10.0"])
    }

    func testStElmosFireForcesFairWeatherWithoutADraw() {
        var s = GameState.fixture()
        s.forceFair = 2
        let e = engine(s, [0])
        XCTAssertEqual(e.rollWeather(GameData.regions[5]), .fair)
        XCTAssertEqual(e.state.forceFair, 1)
        XCTAssertEqual((e.rng as! ScriptedRNG).draws, 0)
    }

    func testTemperatureByMonth() {
        let dec = GameState.fixture(year: 1848, month: 11)
        XCTAssertEqual(dec.temperature(in: GameData.regions[0]), .cold)
        let jun = GameState.fixture(year: 1849, month: 5)
        XCTAssertEqual(jun.temperature(in: GameData.regions[0]), .cool)
        XCTAssertEqual(jun.temperature(in: GameData.regions[4]), .freezing)
        XCTAssertEqual(GameState.fixture().temperature(in: GameData.regions[4]), .cold)
    }

    // MARK: - Offer rounding

    func testTradeRounding() {
        XCTAssertEqual(GameEngine.roundTrade(.item(.food), 34.9), 30)
        XCTAssertEqual(GameEngine.roundTrade(.item(.food), 35), 40, "halves round up, as in JavaScript")
        XCTAssertEqual(GameEngine.roundTrade(.item(.water), 3), 10, "minimum 10")
        XCTAssertEqual(GameEngine.roundTrade(.item(.tackle), 29.9), 20)
        XCTAssertEqual(GameEngine.roundTrade(.item(.tackle), 30), 40)
        XCTAssertEqual(GameEngine.roundTrade(.money, 2), 5, "minimum $5")
        XCTAssertEqual(GameEngine.roundTrade(.money, 12.5), 15)
        XCTAssertEqual(GameEngine.roundTrade(.item(.meds), 0.4), 1, "minimum 1")
        XCTAssertEqual(GameEngine.roundTrade(.item(.limes), 2.5), 3)
    }

    func testOffersAreAlwaysSaneAcrossManySeeds() {
        var offers = 0
        for seed in 0..<500 as Range<UInt64> {
            let e = GameEngine(state: .fixture(), rng: SeededRNG(seed: seed))
            guard let o = e.makeOffer() else { continue }
            offers += 1
            XCTAssertNotEqual(o.give, o.want)
            XCTAssertGreaterThan(o.giveAmount, 0)
            XCTAssertLessThanOrEqual(Double(o.wantAmount), e.state[o.want])
            for (good, n) in [(o.give, o.giveAmount), (o.want, o.wantAmount)] {
                switch good {
                case .item(.food), .item(.water): XCTAssertEqual(n % 10, 0)
                case .item(.tackle): XCTAssertEqual(n % 20, 0)
                case .money: XCTAssertEqual(n % 5, 0)
                default: break
                }
            }
        }
        XCTAssertGreaterThan(offers, 400)
    }

    func testDescribingGoods() {
        XCTAssertEqual(describe(.item(.limes), 1), "1 crate of citrus")
        XCTAssertEqual(describe(.item(.limes), 3), "3 crates of citrus")
        XCTAssertEqual(describe(.item(.tackle), 40), "2 boxes of fishing tackle")
        XCTAssertEqual(describe(.item(.tackle), 30), "1.5 boxes of fishing tackle")
        XCTAssertEqual(describe(.item(.tackle), 20), "1 box of fishing tackle")
        XCTAssertEqual(describe(.money, 45), "$45")
    }

    // MARK: - Score arithmetic

    func testScoreArithmetic() {
        var s = GameState.fixture(role: .shipwright)
        for i in s.crew.indices { s.crew[i].hp = 80 }
        s.hull = 90
        s.sails = 70
        s.food = 1000
        s.water = 260
        s.limes = 3.7
        s.meds = 2
        s.clothes = 5
        s.sailcloth = 1
        s.timber = 2
        s.tackle = 45
        s.money = 503
        let score = Score(s)
        XCTAssertEqual(score.lines.map(\.points), [5 * 500, 250, 40 + 5, 6 + 10 + 10 + 4 + 8 + 2, 100])
        XCTAssertEqual(score.lines[0].label, "5 aboard, health good")
        XCTAssertEqual(score.subtotal, 2935)
        XCTAssertEqual(score.total, 5870)
        XCTAssertEqual(Rank(score: score.total), .ableSeaman)
    }

    func testScoreForAThinnedPoorCrew() {
        var s = GameState.fixture(role: .whaler)
        s.crew[3].alive = false
        for i in 0..<3 { s.crew[i].hp = 40 }
        s.crew[4].hp = 40
        let score = Score(s)
        XCTAssertEqual(score.lines[0].label, "4 aboard, health poor")
        XCTAssertEqual(score.lines[0].points, 4 * 300)
        XCTAssertEqual(score.multiplier, 3)
    }

    func testRanks() {
        XCTAssertEqual(Rank(score: 7000), .masterMariner)
        XCTAssertEqual(Rank(score: 6999), .ableSeaman)
        XCTAssertEqual(Rank(score: 2000), .ordinarySeaman)
        XCTAssertEqual(Rank(score: 1999), .greenhand)
    }

    func testTopTen() {
        let base = GameData.defaultTopTen
        let (t, i) = TopTen.inserting(name: "Ezra", score: 5000, into: base)
        XCTAssertEqual(i, 4)
        XCTAssertEqual(t.count, 10)
        XCTAssertEqual(t[4], TopTenEntry(name: "Ezra", score: 5000))
        XCTAssertEqual(t.last?.name, "Silas Weatherby")
        XCTAssertNil(TopTen.inserting(name: "Ezra", score: 1250, into: base).index, "must BEAT the tenth")
        XCTAssertEqual(TopTen.inserting(name: "Ezra", score: 7650, into: base).index, 1, "ties rank below")
    }

    // MARK: - Choices the parity voyages don't take

    func testShootingTheAlbatrossCursesTheWeather() {
        let e = engine()
        let q = e.resolve(e.choice(.albatross), option: 1)
        XCTAssertEqual(e.state.food, 2012)
        XCTAssertEqual(e.state.badLuck, 25)
        XCTAssertEqual(q, [.message("One shot, and it falls into the sea. The crew hauls it aboard for 12 lbs of tough meat. The old hands go quiet. Nobody will look you in the eye.")])
        _ = e.rollWeather(e.state.region)
        XCTAssertEqual(e.state.badLuck, 24)
    }

    func testSailingPastTheGalapagosChangesNothing() {
        let e = engine()
        let before = e.state
        XCTAssertEqual(e.resolve(e.choice(.galapagos), option: 1), [])
        XCTAssertEqual(e.state, before)
    }

    func testADisabledOptionIsRefused() {
        var s = GameState.fixture()
        s.money = 10
        let e = engine(s)
        let pilot = e.choice(.pilot(cost: 75))
        XCTAssertFalse(pilot.options[0].enabled)
        XCTAssertEqual(e.resolve(pilot, option: 0), [.choice(pilot)])
        XCTAssertEqual(e.state.money, 10)
        XCTAssertFalse(e.state.pilot)
    }

    // MARK: - Shop, fishing, text, saves

    func testShopRoomAndBill() {
        var s = GameState.fixture()
        s.atPort = true
        s.tackle = 11_990  // the cap is 600 BOXES = 12,000 throws (docs/decisions.md D6)
        let e = engine(s)
        XCTAssertEqual(e.room(for: .tackle), 0, "half a box of room is no room")
        XCTAssertEqual(e.room(for: .food), 1000)
        XCTAssertFalse(e.buy([.food: 100_000]), "can't afford it")
        XCTAssertTrue(e.buy([.food: 100, .tackle: 0, .limes: 2]))
        XCTAssertEqual(e.state.money, 1500 - 10 - 8, accuracy: 1e-9)
        XCTAssertEqual(GameData.port(.cv).price(.limes), 4 * 1.3 * 0.55, accuracy: 1e-12)
    }

    func testAWhalerSaltsUpTo300Pounds() {
        var s = GameState.fixture(role: .whaler)
        s.food = 500
        let e = engine(s)
        let q = e.landCatch(420)
        XCTAssertEqual(e.state.food, 500 + 300 - 15)
        XCTAssertEqual(q.first, .message("You caught [amber]420 lbs[/amber] of fish. The cook can only salt and stow 300 lbs before the rest spoils. [green]+300 lbs of provisions.[/green] [dim]A day has passed.[/dim]"))
        XCTAssertEqual(e.state.day, 1)
    }

    func testNoFishingInAGale() {
        var s = GameState.fixture()
        s.weather = .gale
        XCTAssertEqual(engine(s).fishingRefusal, "The seas are far too rough to fish.")
        s.weather = .fair
        s.tackle = 0
        XCTAssertEqual(engine(s).fishingRefusal, "You have no fishing tackle left.")
    }

    func testANameIsNeverMarkup() {
        var s = GameState.fixture()
        s.crew[1].name = "[red]Bob"
        s.crew[1].ailment = .exhaustion
        s.crew[1].ailDays = 0.5
        let e = engine(s)
        var q: [Interrupt] = []
        e.health(&q, .sail)
        XCTAssertTrue(q.contains(.message("[[red]Bob is well again.")))
    }

    func testJavaScriptRounding() {
        XCTAssertEqual(jsRound(2.5), 3)
        XCTAssertEqual(jsRound(-2.5), -2)
        XCTAssertEqual(jsRound(0.49999999999999994), 0)
        XCTAssertEqual(formatNumber(14000), "14,000")
        XCTAssertEqual(formatNumber(1234567.9), "1,234,567")
        XCTAssertEqual(jsNumber(3), "3")
        XCTAssertEqual(jsNumber(1.5), "1.5")
    }

    func testCalendar() {
        var s = GameState.fixture(year: 1848, month: 11)
        XCTAssertEqual(s.dateText, "December 1, 1848")
        s.day = 31
        XCTAssertEqual(s.dateText, "January 1, 1849")
        s.day = 31 + 31 + 28  // 1849 is not a leap year
        XCTAssertEqual(s.dateText, "March 1, 1849")
    }

    func testSaveRoundTrip() throws {
        let e = GameEngine(state: .fixture(), rng: SeededRNG(seed: 9))
        for _ in 0..<40 { _ = e.sailDay() }
        let data = try JSONEncoder().encode(e.state)
        let back = try JSONDecoder().decode(GameState.self, from: data)
        XCTAssertEqual(back, e.state)
        XCTAssertEqual(back.saveVersion, GameState.currentSaveVersion)
    }
}
