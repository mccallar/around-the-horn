import XCTest
@testable import HornEngine

/// The Iron Road's own rules, and the bands its balance has to stay in
/// (docs/journeys/rail.md).
final class RailTests: XCTestCase {
    let rail = Journeys.journey(Rail.id)

    /// Five aboard a well-found train, out on the line. October unless told otherwise.
    func train(mile: Int = 100, month: Int = 9, role: Role = .merchant) -> GameState {
        var s = GameState(journey: Rail.id, role: role, ship: "Juniper", captain: "Amos",
                          crew: ["Clara", "Ned", "Ruth", "Gideon"], startYear: 1869, startMonth: month)
        s.mile = mile
        s.stopIndex = rail.stops.lastIndex { $0.mile <= mile } ?? 0
        s.food = 400
        s.water = 600
        s.fuel = 120
        s.meds = 2
        s.clothes = 5
        s.sailcloth = 2
        s.timber = 2
        s.tackle = 40
        s.atPort = false
        return s
    }

    func region(_ id: RegionID) -> Region { rail.regions.first { $0.id == id }! }

    func speed(_ e: GameEngine, _ id: RegionID) -> Double {
        var sp = 100.0
        rail.adjustSpeed(e, region(id), &sp)
        return sp
    }

    func messages(_ q: [Interrupt]) -> [String] {
        q.compactMap { if case .message(let t) = $0 { return t } else { return nil } }
    }

    func choice(_ q: [Interrupt]) -> ChoiceEvent? {
        for i in q { if case .choice(let c) = i { return c } }
        return nil
    }

    /// D22: Omaha holds a train with no provisions only while the purse runs to a step of
    /// them (25 lbs, $3). A river hand can spend below it with none aboard; the train then
    /// leaves, and the departure says the crew goes hungry.
    func testOmahaLetsATrainGoHungryOnlyWhenThePurseCannotBuyAStep() throws {
        XCTAssertEqual(rail.firstPortStep(.food), 3, accuracy: 1e-9)
        var s = GameState(journey: Rail.id, role: .whaler, ship: "Juniper", captain: "Amos",
                          crew: ["Clara", "Ned", "Ruth", "Gideon"], startYear: 1869, startMonth: 9)
        XCTAssertEqual(s.money, 350, accuracy: 1e-9)
        let e = GameEngine(state: s)
        XCTAssertTrue(e.buy([.clothes: 10, .meds: 8, .sailcloth: 8, .timber: 8, .fuel: 9]))
        XCTAssertLessThan(e.state.money, rail.firstPortStep(.food))
        XCTAssertFalse(e.buy([.food: 25]))
        let said = try XCTUnwrap(e.depart(), "the river hand is not held at Omaha for good")
        XCTAssertTrue(said.hasSuffix(" " + Rail.goingHungry), said)
        XCTAssertFalse(e.state.atPort)

        s.money = 3
        XCTAssertFalse(rail.departsUnfed(s))
        XCTAssertNil(GameEngine(state: s).depart(), "the purse runs to 25 lbs")
        s.money = 2.99
        XCTAssertTrue(rail.departsUnfed(s))
        s.food = 25
        let fed = GameEngine(state: s).depart() ?? ""
        XCTAssertTrue(fed.hasSuffix("smell of sap."), fed)
    }

    // MARK: - Boiler water

    func testTheBoilerDrinksFromTheTankCarInADesert() {
        let e = engine(train(mile: 750))
        var q: [Interrupt] = []
        rail.tick(e, &q, .sail, e.state.region)
        XCTAssertEqual(e.state.water, 520)
        XCTAssertEqual(e.state.sails, 100)
        XCTAssertTrue(q.isEmpty)
        XCTAssertEqual(speed(e, "reddesert"), 100)
    }

    func testTheBoilerTakesNothingOutsideADesertOrWhileStopped() {
        let river = engine(train(mile: 100))
        var q: [Interrupt] = []
        rail.tick(river, &q, .sail, river.state.region)
        XCTAssertEqual(river.state.water, 600)

        let stopped = engine(train(mile: 750))
        rail.tick(stopped, &q, .sea, stopped.state.region)
        XCTAssertEqual(stopped.state.water, 600)
    }

    func testTheKegsAreNeverTheBoilers() {
        var s = train(mile: 750)
        s.water = 100
        XCTAssertEqual(Rail.boilerWater(s), 40)
        // Forty gallons will not make a turn of steam: the engine crawls and is hurt by it.
        let e = engine(s, [0])
        XCTAssertEqual(speed(e, "reddesert"), 50)
        var q: [Interrupt] = []
        rail.tick(e, &q, .sail, e.state.region)
        XCTAssertEqual(e.state.water, RailData.kegs)
        XCTAssertEqual(e.state.sails, 98)
        XCTAssertFalse(e.state.note.isEmpty)
    }

    func testTheDryTankWarningComesOnceAndReArmsAfterAFill() {
        var s = train(mile: 750)
        s.water = 290
        let e = engine(s)
        var q: [Interrupt] = []
        rail.tick(e, &q, .sail, e.state.region)
        XCTAssertEqual(messages(q).count, 1)
        q = []
        rail.tick(e, &q, .sail, e.state.region)
        XCTAssertTrue(messages(q).isEmpty)

        e.state.water = 600
        rail.tick(e, &q, .sea, e.state.region)
        XCTAssertEqual(e.state.vars["rail.dryWarned"], 0)
    }

    func testTheCrewFillsTheKegsAtARiverOrFromSnowButNotInADryDesert() {
        var s = train(mile: 100)
        s.water = 20
        let river = engine(s)
        var q: [Interrupt] = []
        rail.tick(river, &q, .sail, river.state.region)
        XCTAssertEqual(river.state.water, RailData.kegs)
        XCTAssertTrue(river.state.note.contains("river"))

        s = train(mile: 750)
        s.water = 20
        let desert = engine(s)
        rail.tick(desert, &q, .sea, desert.state.region)
        XCTAssertEqual(desert.state.water, 20)

        s.weather = RailData.snow
        let snowed = engine(s)
        rail.tick(snowed, &q, .sea, snowed.state.region)
        XCTAssertEqual(snowed.state.water, RailData.kegs)
        XCTAssertTrue(snowed.state.note.contains("snow"))

        // In a yard the tank is there to be paid for.
        s = train(mile: 100)
        s.water = 20
        let yard = engine(s)
        rail.tick(yard, &q, .port, yard.state.region)
        XCTAssertEqual(yard.state.water, 20)
    }

    // MARK: - Grades

    func testAHelperTakesTheGradeAway() {
        let e = engine(train(mile: 530))
        XCTAssertEqual(speed(e, "sherman"), 45, accuracy: 0.001)
        e.state.vars["rail.helper.sherman"] = 1
        XCTAssertEqual(speed(e, "sherman"), 100)
        // One hill's helper is no use on the next.
        XCTAssertEqual(speed(e, "eastslope"), 45, accuracy: 0.001)
        XCTAssertEqual(speed(e, "wasatch"), 80, accuracy: 0.001)
    }

    func testTheHelperAsksBeforeTheYardAndIsPaidOnce() {
        let e = engine(train(mile: 516))
        e.state.money = 100
        let q = e.beginArrival("cheyenne")
        guard let offer = choice(q), case .custom(let key, let args) = offer.kind else { return XCTFail("no offer") }
        XCTAssertEqual(key, "helper")
        XCTAssertEqual(args, ["cheyenne", "sherman"])
        XCTAssertTrue(offer.options[0].enabled)

        let after = e.resolve(offer, option: 0)
        XCTAssertEqual(e.state.money, 70)
        XCTAssertEqual(e.state.vars["rail.helper.sherman"], 1)
        XCTAssertEqual(messages(after).count, 1)
        guard let yard = choice(after), case .portArrival(let stop) = yard.kind else { return XCTFail("no yard") }
        XCTAssertEqual(stop, "cheyenne")
    }

    func testAnEmptyPurseCanStillClimbAlone() {
        let e = engine(train(mile: 1620))
        e.state.money = 10
        guard let offer = choice(e.beginArrival("reno")) else { return XCTFail("no offer") }
        XCTAssertFalse(offer.options[0].enabled)
        XCTAssertTrue(offer.options[1].enabled)
        XCTAssertEqual(e.resolve(offer, option: 0), [.choice(offer)])

        let after = e.resolve(offer, option: 1)
        XCTAssertEqual(e.state.money, 10)
        XCTAssertNil(e.state.vars["rail.helper.eastslope"])
        XCTAssertNotNil(choice(after))
    }

    // MARK: - Set pieces

    func testDaleCreekOnlyAsksWhenTheWindIsUp() {
        let calm = engine(train(mile: 553))
        XCTAssertEqual(messages(calm.beginArrival("dalecreek")).count, 1)

        var s = train(mile: 553)
        s.weather = RailData.headwind
        s.day = 20
        let waits = engine(s)
        guard let ask = choice(waits.beginArrival("dalecreek")) else { return XCTFail("no choice") }
        _ = waits.resolve(ask, option: 0)
        XCTAssertEqual(waits.state.day, 21)
        XCTAssertEqual(waits.state.hull, 100, accuracy: 1)

        let crosses = engine(s, [0, 0])
        _ = crosses.resolve(ask, option: 1)
        XCTAssertEqual(crosses.state.day, 20)
        XCTAssertEqual(crosses.state.hull, 92)

        let lucky = engine(s)
        _ = lucky.resolve(ask, option: 1)
        XCTAssertEqual(lucky.state.hull, 100)
    }

    func testRetainersComeDownSlowAndSpareTheBrakes() {
        let e = engine(train(mile: 1669))
        guard let ask = choice(e.beginArrival("donner")) else { return XCTFail("no choice") }
        let rolling = rail.structureDamage(e, region("sierra"))
        XCTAssertEqual(speed(e, "sierra"), 100)

        _ = e.resolve(ask, option: 0)
        XCTAssertEqual(e.state.vars["rail.retainers"], 1)
        XCTAssertEqual(speed(e, "sierra"), 60, accuracy: 0.001)
        XCTAssertEqual(rolling - rail.structureDamage(e, region("sierra")), 0.8 * 0.6, accuracy: 0.001)
        // Retainers are for the mountain; they change nothing on the flat.
        XCTAssertEqual(speed(e, "valley"), 100)
    }

    func testLettingHerRollCanGetAway() {
        let e = engine(train(mile: 1669), [0, 0])
        guard let ask = choice(e.beginArrival("donner")) else { return XCTFail("no choice") }
        _ = e.resolve(ask, option: 1)
        XCTAssertNil(e.state.vars["rail.retainers"])
        XCTAssertEqual(e.state.hull, 85)
        XCTAssertTrue(e.state.living.allSatisfy { $0.hp < 100 })

        let lucky = engine(train(mile: 1669))
        _ = lucky.resolve(ask, option: 1)
        XCTAssertEqual(lucky.state.hull, 100)
    }

    // MARK: - The contract

    func testTheFreightIsLateAtTwelveDaysAndForfeitAtSixteen() {
        let e = engine(train(mile: 1500))
        var q: [Interrupt] = []
        e.state.day = RailData.contractTurns - 1
        rail.tick(e, &q, .sail, e.state.region)
        XCTAssertTrue(q.isEmpty)

        e.state.day = RailData.contractTurns
        rail.tick(e, &q, .sail, e.state.region)
        XCTAssertEqual(messages(q).count, 1)
        rail.tick(e, &q, .sail, e.state.region)
        XCTAssertEqual(messages(q).count, 1)
        XCTAssertFalse(e.state.over)

        e.state.day = RailData.forfeitTurns
        rail.tick(e, &q, .port, e.state.region)
        XCTAssertTrue(e.state.over)
        guard case .gameOver(let title, _)? = q.last else { return XCTFail("no ending") }
        XCTAssertEqual(title, "The contract is forfeit.")
    }

    func testDaysInHandAreWorthPointsAndLateOnesNothing() {
        var s = train(mile: 1776)
        s.day = 60
        let early = rail.score(s).lines.first { $0.label == Rail.onTimeLabel }
        XCTAssertEqual(early?.points, 12 * RailData.bonusPerTurn)
        s.day = 80
        XCTAssertEqual(rail.score(s).lines.first { $0.label == Rail.onTimeLabel }?.points, 0)
        XCTAssertEqual(rail.score(train(role: .whaler)).multiplier, 3)
    }

    // MARK: - Season, sickness and driftwood

    func testTheSeasonMovesTheWeatherAndTheCold() {
        XCTAssertEqual(rail.temperature(train(month: 11), in: region("sierra")), .freezing)
        XCTAssertEqual(rail.temperature(train(month: 6), in: region("saltdesert")), .hot)
        XCTAssertEqual(rail.temperature(train(month: 6), in: region("sierra")), .cool)
        XCTAssertTrue(rail.harshSeason(train(month: 11)))
        XCTAssertFalse(rail.harshSeason(train(month: 9)))

        let july = rail.weatherWeights(engine(train(month: 6)), region("sierra"), cursed: false)
        XCTAssertEqual(july.first { $0.0 == RailData.blizzard }?.1 ?? 0, 0)
        let autumn = rail.weatherWeights(engine(train(month: 9)), region("sierra"), cursed: false)
        let winter = rail.weatherWeights(engine(train(month: 11)), region("sierra"), cursed: false)
        func odds(_ w: WeatherOdds, _ k: Weather) -> Double { w.first { $0.0 == k }?.1 ?? 0 }
        XCTAssertGreaterThan(odds(winter, RailData.blizzard), odds(autumn, RailData.blizzard) * 5)
    }

    func testWhatAilsYouDependsOnWhereYouAre() {
        let desert = engine(train(mile: 750))
        let hot = rail.sickPool(desert, .hot, nil)
        XCTAssertTrue(hot.contains(RailData.sunstroke))
        XCTAssertTrue(hot.contains(RailData.alkali))
        XCTAssertFalse(hot.contains(RailData.lungChill))

        let river = engine(train(mile: 100))
        let cold = rail.sickPool(river, .freezing, nil)
        XCTAssertTrue(cold.contains(RailData.lungChill))
        XCTAssertFalse(cold.contains(RailData.alkali))
        XCTAssertFalse(cold.contains(RailData.sunstroke))
    }

    func testDriftwoodWantsLineARiverAndOpenWater() {
        XCTAssertNil(engine(train(mile: 100)).fishingRefusal)
        XCTAssertEqual(engine(train(mile: 750)).fishingRefusal?.contains("no river"), true)
        XCTAssertEqual(engine(train(mile: 1640, month: 11)).fishingRefusal?.contains("iced"), true)

        var s = train(mile: 100)
        s.tackle = 0
        XCTAssertEqual(engine(s).fishingRefusal, rail.text.noTackle)
        s = train(mile: 100)
        s.weather = RailData.blizzard
        XCTAssertEqual(engine(s).fishingRefusal, rail.text.tooRough)
    }

    func testDriftwoodGoesOnTheWoodpile() {
        let e = engine(train(mile: 100))
        e.state.fuel = 30
        _ = e.landCatch(25)
        XCTAssertEqual(e.state.fuel, 55)
        XCTAssertEqual(e.state.food, 400, accuracy: 10)
    }

    func testWoodIsCountedInTenthsAndSpokenInCords() {
        XCTAssertEqual(RailData.cords(10), "1 cord")
        XCTAssertEqual(RailData.cords(160), "16 cords")
        XCTAssertEqual(RailData.cords(25), "2.5 cords")
        XCTAssertEqual(RailData.cords(5), "0.5 cords")
        XCTAssertEqual(RailData.cords(0), "0 cords")
    }

    // MARK: - Balance

    /// How the balance test plays: October, a full tank car at every yard, driftwood when
    /// the tender runs low.
    static func policy(departure: Int = 2) -> JourneyBot.Policy {
        var p = JourneyBot.Policy()
        p.departure = departure
        p.marginTurns = 4
        p.spares = [(.water, 900), (.meds, 2), (.sailcloth, 2), (.timber, 2)]
        p.tackle = [.merchant: 20, .shipwright: 40, .whaler: 60]
        p.forageBelowTurns = [.merchant: 2, .shipwright: 4, .whaler: 10]
        p.hitChance = [.merchant: 0.3, .shipwright: 0.3, .whaler: 0.5]
        p.mendBelow = 60
        p.yardBelow = 40
        // A helper only when there is money to spare for the wood beyond the hill.
        p.decide = { e, c in
            guard case .custom(let key, let args) = c.kind, key == "helper", args.count == 2,
                  let fee = RailData.helperFee[args[1]] else { return nil }
            return e.state.money >= fee + 100 ? 0 : 1
        }
        return p
    }

    /// October is the month the outfitter recommends. The contractor should nearly always
    /// arrive, the boilermaker usually, the river hand about half the time, and a winning
    /// run should take about the twelve days of the contract.
    func testOctoberBalanceStaysInItsBands() {
        XCTAssertEqual(RailData.departures[2].1, 9)
        let r = JourneyBot.survey(rail, count: 30, seed: 500, policy: Self.policy())
        print(r.report)
        XCTAssertGreaterThanOrEqual(r.rates[.merchant] ?? 0, 0.85, r.report)
        XCTAssertGreaterThanOrEqual(r.rates[.shipwright] ?? 0, 0.6, r.report)
        XCTAssertLessThanOrEqual(r.rates[.shipwright] ?? 1, 0.9 + 1e-9, r.report)
        XCTAssertGreaterThanOrEqual(r.rates[.whaler] ?? 0, 0.35, r.report)
        XCTAssertLessThanOrEqual(r.rates[.whaler] ?? 1, 0.7, r.report)
        XCTAssertTrue((66...84).contains(r.medianTurns), r.report)
    }

    /// Leave in December and pay for it: the two poorer roles do much worse than in October.
    func testMidwinterIsHarder() {
        let october = JourneyBot.survey(rail, count: 30, seed: 500, policy: Self.policy())
        let december = JourneyBot.survey(rail, count: 30, seed: 500, policy: Self.policy(departure: 3))
        print(december.report)
        for role in [Role.shipwright, .whaler] {
            XCTAssertLessThan(december.rates[role] ?? 1, (october.rates[role] ?? 0) - 0.2, december.report)
        }
        XCTAssertGreaterThanOrEqual(december.rates[.merchant] ?? 0, 0.85, december.report)
    }

    func testLosingRunsEndMoreThanOneWay() {
        var endings = Set<String>()
        for i in 0..<30 {
            let r = JourneyBot(journey: rail, role: .whaler, seed: 500 + UInt64(1000 * Role.whaler.scoreMultiplier + i),
                               policy: Self.policy()).play()
            if !r.won { endings.insert(r.ending) }
        }
        XCTAssertGreaterThanOrEqual(endings.count, 3, "\(endings)")
    }
}
