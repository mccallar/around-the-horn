import XCTest
@testable import HornEngine

/// The Long Transfer's own rules, and the bands its balance has to stay in
/// (docs/journeys/mars.md).
final class MarsTests: XCTestCase {
    let mars = Journeys.journey(Mars.id)

    /// Five aboard a well-found freighter out on the arc. October 2087 unless told otherwise.
    func ship(mile: Int = 1000, month: Int = 9, role: Role = .merchant) -> GameState {
        var s = GameState(journey: Mars.id, role: role, ship: "Fair Copy", captain: "Adaeze",
                          crew: ["Tomasz", "Priya", "Mateo", "Ingrid"], startYear: 2087, startMonth: month)
        s.mile = mile
        s.stopIndex = mars.stops.lastIndex { $0.mile <= mile } ?? 0
        s.food = 300
        s.water = 500
        s.fuel = 500
        s.limes = 5
        s.meds = 2
        s.clothes = 5
        s.sailcloth = 2
        s.timber = 2
        s.tackle = 40
        s.atPort = false
        return s
    }

    func region(_ id: RegionID) -> Region { mars.regions.first { $0.id == id }! }

    func speed(_ e: GameEngine, _ id: RegionID) -> Double {
        var sp = 100.0
        mars.adjustSpeed(e, region(id), &sp)
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

    /// A choice of the journey's own, as `GameEngine.ask` would raise it.
    func ask(_ e: GameEngine, _ key: String, _ args: [String] = []) -> ChoiceEvent {
        guard case .choice(let c) = e.ask(key, args, prompt: "?", options: [.init("0"), .init("1")]) else {
            fatalError("ask raises a choice")
        }
        return c
    }

    // MARK: - Power, warmth and wear

    func testTheCabinIsAsWarmAsThePowerAllows() {
        var s = ship()
        let reg = region("departure")
        s.sails = 19
        XCTAssertEqual(mars.temperature(s, in: reg), .freezing)
        s.sails = 20
        XCTAssertEqual(mars.temperature(s, in: reg), .cold)
        s.sails = 39.9
        XCTAssertEqual(mars.temperature(s, in: reg), .cold)
        s.sails = 40
        XCTAssertEqual(mars.temperature(s, in: reg), .cool)
    }

    func testThermalSuitsKeepACrewWarmWhenThePowerFails() {
        var s = ship()
        s.sails = 30
        for i in s.crew.indices { s.crew[i].hp = 50 }
        let bare = engine(s)
        bare.state.clothes = 0
        var q: [Interrupt] = []
        bare.health(&q, .sail)
        let suited = engine(s)
        suited.health(&q, .sail)
        // Full rations +1, well +1, and the cold costs the unsuited 2.2.
        XCTAssertEqual(bare.state.crew[0].hp, 49.8, accuracy: 0.001)
        XCTAssertEqual(suited.state.crew[0].hp, 52, accuracy: 0.001)
    }

    func testFarFromTheSunTheWingsWearFaster() {
        // Cruise 2 × quiet 0.3 × a middling jitter of 1.
        XCTAssertEqual(mars.propulsionWear(engine(ship(mile: 1000), [0.5])), 0.6, accuracy: 0.001)
        XCTAssertEqual(mars.propulsionWear(engine(ship(mile: 25_000), [0.5])), 0.78, accuracy: 0.001)
        XCTAssertEqual(mars.propulsionWear(engine(ship(mile: 39_000), [0.5])), 0.78, accuracy: 0.001)
        // The Sun only gets thinner from there to Mars.
        XCTAssertEqual(mars.propulsionWear(engine(ship(mile: 43_000), [0.5])), 0.78, accuracy: 0.001)
        XCTAssertEqual(mars.propulsionWear(engine(ship(mile: 47_500), [0.5])), 0.78, accuracy: 0.001)
    }

    func testPebblesAndTheSunsWeatherHitTheHull() {
        var s = ship()
        XCTAssertEqual(mars.structureDamage(engine(s, [0.5]), region("departure")), 0.05, accuracy: 0.001)
        s.weather = MarsData.pebbles
        XCTAssertEqual(mars.structureDamage(engine(s, [0.5]), region("departure")), 2.55, accuracy: 0.001)
        s.pace = .full
        XCTAssertEqual(mars.structureDamage(engine(s, [0.5]), region("departure")), 3.8, accuracy: 0.001)
        s.weather = MarsData.ejection
        s.pace = .easy
        XCTAssertEqual(mars.structureDamage(engine(s, [0.5]), region("departure")), 0.05 + 2 * 0.7, accuracy: 0.001)
    }

    // MARK: - The calendar

    func testTheLaunchWindowSetsThePace() {
        let speeds = (7...11).map { speed(engine(ship(month: $0)), "inner") }
        XCTAssertEqual(speeds, [86, 94, 100, 94, 86])
        XCTAssertEqual(MarsData.departures.map(\.month), [7, 8, 9, 10, 11])
        XCTAssertEqual(mars.rules.startDay, 7)
        XCTAssertEqual(ship().dateText, "October 7, 2087")
    }

    func testTheSunBuildsToAMaximum() {
        XCTAssertEqual(Mars.stormFactor(ship(month: 7)), 0.6 + 0.2 / 9, accuracy: 0.0001)
        XCTAssertEqual(Mars.stormFactor(ship(month: 9)), 0.6 + 2.2 / 9, accuracy: 0.0001)
        var may = ship(month: 11)
        may.day = 150
        XCTAssertEqual(may.date.month, 4)
        XCTAssertEqual(Mars.stormFactor(may), 1.6)

        func odds(_ s: GameState, _ k: Weather) -> Double {
            mars.weatherWeights(engine(s), region("departure"), cursed: false).first { $0.0 == k }?.1 ?? 0
        }
        XCTAssertEqual(odds(may, MarsData.proton), 5 * 1.6, accuracy: 0.0001)
        XCTAssertEqual(odds(may, MarsData.ejection), 1.5 * 1.6, accuracy: 0.0001)
        XCTAssertEqual(odds(may, MarsData.quiet), 52)
        XCTAssertGreaterThan(odds(may, MarsData.proton), odds(ship(month: 7), MarsData.proton) * 2.5)
    }

    func testTheShadowHasNoClearFix() {
        XCTAssertNil(region("shadow").weights.first { $0.0 == MarsData.tracking })
        XCTAssertTrue(region("shadow").has("quiet"))
        XCTAssertTrue(region("shadow").has("far"))
    }

    // MARK: - Water and the grapple

    func testWaterIsTwoLitresAHeadAndNothingFallsFromTheSky() {
        XCTAssertEqual(mars.rules.water, 2)
        XCTAssertEqual(mars.rules.hotWater, 2)
        XCTAssertTrue(mars.weathers.allSatisfy { !$0.wet })
        let e = engine(ship())
        var q: [Interrupt] = []
        e.consume(&q, .sail)
        XCTAssertEqual(e.state.water, 490)
        XCTAssertEqual(e.state.food, 296)
    }

    func testTheGrappleWantsAnIceStreamAndACalmDay() {
        XCTAssertNil(engine(ship(mile: 9000)).fishingRefusal)
        XCTAssertNil(engine(ship(mile: 35_000)).fishingRefusal)
        XCTAssertEqual(engine(ship(mile: 1000)).fishingRefusal?.contains("nothing out there to catch"), true)
        XCTAssertEqual(engine(ship(mile: 25_000)).fishingRefusal?.contains("nothing out there to catch"), true)

        var s = ship(mile: 9000)
        s.tackle = 0
        XCTAssertEqual(engine(s).fishingRefusal, mars.text.noTackle)
        s = ship(mile: 9000)
        s.weather = MarsData.pebbles
        XCTAssertEqual(engine(s).fishingRefusal, mars.text.tooRough)
    }

    func testIceGoesInTheWaterTanksUpToWhatOneOutingCanMelt() {
        let e = engine(ship(mile: 9000))
        _ = e.landCatch(50)
        // Fifty litres in, and a day passes: ten drunk.
        XCTAssertEqual(e.state.water, 540, accuracy: 0.001)

        let hauler = engine(ship(mile: 9000, role: .whaler))
        _ = hauler.landCatch(150)
        XCTAssertEqual(hauler.state.water, 590, accuracy: 0.001)

        let full = engine(ship(mile: 9000))
        full.state.water = 790
        _ = full.landCatch(50)
        XCTAssertEqual(full.state.water, 790, accuracy: 0.001)
    }

    // MARK: - The cycler and the stations

    func testDockingWithTheCyclerCostsSixTonnesAndOpensHerStores() {
        let e = engine(ship(mile: 15_500))
        let c = choice(e.beginArrival("cycler"))
        XCTAssertEqual(key(c), "cycler")
        XCTAssertTrue(c!.options[0].enabled)
        let after = e.resolve(c!, option: 0)
        XCTAssertEqual(e.state.fuel, 440)
        // Docking is going aboard: no second offer to dock, and her stores open.
        XCTAssertNil(choice(after))
        XCTAssertEqual(after.last, .enterPort)
        XCTAssertTrue(e.state.atPort)
        XCTAssertTrue(messages(after).first?.contains("comes up out of the dark") ?? false)
    }

    func testWavingTheCyclerBySkipsHerAndAnEmptyTankCannotDock() {
        let e = engine(ship(mile: 15_500))
        e.state.fuel = 50
        let c = choice(e.beginArrival("cycler"))!
        XCTAssertFalse(c.options[0].enabled)
        XCTAssertTrue(c.options[1].enabled)
        XCTAssertEqual(e.resolve(c, option: 0), [.choice(c)])
        let after = e.resolve(c, option: 1)
        XCTAssertNil(choice(after))
        XCTAssertEqual(messages(after).count, 1)
        XCTAssertEqual(e.state.fuel, 50)
    }

    func testAGratefulShipPaysAtTheNextPort() {
        let e = engine(ship())
        e.state.money = 100
        _ = e.resolve(ask(e, "distress", ["water", "80"]), option: 0)
        XCTAssertEqual(e.state.water, 420)
        let owed = e.state.vars[MarsData.owedKey] ?? 0
        XCTAssertTrue((15...30).contains(owed))

        // Paid on reaching the station, before the offer to dock: keeping going keeps it.
        let q = e.beginArrival("midway")
        XCTAssertEqual(e.state.money, 100 + owed)
        XCTAssertEqual(e.state.vars[MarsData.owedKey], 0)
        XCTAssertTrue(messages(q).first?.contains("+$\(Int(owed))") ?? false)
        XCTAssertEqual(e.resolve(choice(q)!, option: 1), [])
        XCTAssertEqual(e.state.money, 100 + owed)

        // The cycler pays too, even to a ship that waves her by.
        let c = engine(ship(mile: 15_500))
        c.state.money = 100
        c.state.vars[MarsData.owedKey] = 20
        let wave = c.beginArrival("cycler")
        XCTAssertEqual(c.state.money, 120)
        _ = c.resolve(choice(wave)!, option: 1)
        XCTAssertEqual(c.state.money, 120)

        // A patch, and a refusal costs nothing.
        let p = engine(ship())
        _ = p.resolve(ask(p, "distress", ["patch", "60"]), option: 0)
        XCTAssertEqual(p.state.timber, 1)
        let no = engine(ship())
        _ = no.resolve(ask(no, "distress", ["water", "60"]), option: 1)
        XCTAssertEqual(no.state.water, 500)
        XCTAssertNil(no.state.vars[MarsData.owedKey])
    }

    func testTheHitchhikerIsBoundForADepotNeverTheCycler() {
        func docked(_ mile: Int) -> GameState {
            var s = ship(mile: mile)
            s.vars[MarsData.dockedKey] = Double(mars.stops.firstIndex { $0.id == (mile < 30_000 ? "gateway" : "midway") }!)
            return s
        }
        for mile in [600, 30_900] {
            var found: [String] = []
            let s = docked(mile)
            for ev in mars.events(engine(s), s.region) where ev.ok {
                let e = engine(s, [], fallback: 0)
                var q: [Interrupt] = []
                ev.run(e, &q)
                if let c = choice(q), case .custom("hitch", let args) = c.kind { found = args }
            }
            XCTAssertEqual(found.last, mile < 30_000 ? "midway" : "phobos", "at \(mile)")
        }
        // Past the cycler, which nobody is ever bound for, there is no shuttle to catch you;
        // nor from a depot you kept going past, though you docked at the yard before it.
        var passed = docked(600)
        passed.mile = 30_900
        passed.stopIndex = mars.stops.firstIndex { $0.id == "midway" }!
        for past in [docked(16_000), passed] {
            for ev in mars.events(engine(past), past.region) where ev.ok {
                let e = engine(past, [], fallback: 0)
                var q: [Interrupt] = []
                ev.run(e, &q)
                XCTAssertNotEqual(key(choice(q)), "hitch", "at \(past.mile)")
            }
        }

        // Going aboard is what counts: leaving Midway's dock marks it.
        let leave = engine(ship(mile: 30_000))
        leave.state.atPort = true
        leave.setSail()
        XCTAssertEqual(leave.state.vars[MarsData.dockedKey], Double(mars.stops.firstIndex { $0.id == "midway" }!))

        let e = engine(ship())
        _ = e.resolve(ask(e, "hitch", ["Noor", "midway"]), option: 0)
        XCTAssertEqual(e.state.living.count, 6)
        let q = e.beginArrival("midway")
        XCTAssertEqual(e.state.living.count, 5)
        XCTAssertTrue(choice(q)?.detail?.contains("Noor") ?? false)
    }

    /// A pod or a cache says what actually went into the hold, not what it held.
    func testFindsReportWhatFitsAboard() {
        // Water bladders: 150 litres, room for 20.
        let e = engine(ship(), [0.5, 0.2, 0.87])
        e.state.water = 780
        let q = e.resolve(ask(e, "pod"), option: 0)
        XCTAssertEqual(e.state.water, 800)
        XCTAssertTrue(messages(q)[0].contains("+20 litres of water"), messages(q)[0])
        XCTAssertTrue(messages(q)[0].contains("The rest stays in the pod"), messages(q)[0])
        XCTAssertFalse(messages(q)[0].contains("150"), messages(q)[0])

        // Medical kits, with the locker full: nothing goes in and it says so.
        let full = engine(ship(), [0.5, 0.4, 0.9])
        full.state.meds = 8
        let m = messages(full.resolve(ask(full, "pod"), option: 0))[0]
        XCTAssertEqual(full.state.meds, 8)
        XCTAssertTrue(m.contains("no room aboard"), m)
        XCTAssertFalse(m.contains("+"), m)

        // The cache: 30 kg of rations, room for 10; one pack.
        let s = ship()
        var said: [String] = []
        for ev in mars.events(engine(s), s.region) where ev.ok {
            let c = engine(s, [], fallback: 0)
            c.state.food = 440
            var q: [Interrupt] = []
            ev.run(c, &q)
            said += messages(q).filter { $0.contains("supply cache") }
            if !messages(q).filter({ $0.contains("supply cache") }).isEmpty { XCTAssertEqual(c.state.food, 450) }
        }
        XCTAssertEqual(said.count, 1)
        XCTAssertTrue(said[0].contains("+10 kg of rations, +1 supplement pack."), said[0])
    }

    /// The captain's death says who is left to bring the ship in, and someone dying the
    /// same day is not anyone.
    func testTheCaptainsDeathSaysWhetherAnyoneIsLeft() {
        func body(_ setUp: (GameEngine) -> Void) -> String {
            let e = engine(ship())
            setUp(e)
            e.state.crew[0].hp = 0
            var q: [Interrupt] = []
            e.deaths(&q)
            for i in q { if case .gameOver(_, let b) = i { return b } }
            XCTFail("no game over")
            return ""
        }
        XCTAssertEqual(body { _ in }, mars.text.leaderDiedBody)
        XCTAssertEqual(body { e in for i in 1..<5 { e.state.crew[i].alive = false } }, Mars.nobodyLeftAboard)
        XCTAssertEqual(body { e in for i in 1..<5 { e.state.crew[i].hp = 0 } }, Mars.nobodyLeftAboard)
        XCTAssertEqual(body { e in
            e.state.atPort = true
            for i in 1..<5 { e.state.crew[i].alive = false }
        }, Mars.nobodyLeftDocked)
        // Nor does running out of food count heads.
        XCTAssertFalse(mars.text.outOfFood.lowercased().contains("five"))
    }

    func testStationPricesFollowWhatEachHasPlentyOf() {
        func price(_ id: String, _ k: ItemKey) -> Double { mars.port(id)!.price(k) }
        XCTAssertLessThan(price("cycler", .water), price("gateway", .water))
        XCTAssertGreaterThan(price("cycler", .food), price("gateway", .food))
        XCTAssertLessThan(price("midway", .fuel), price("gateway", .fuel))
        XCTAssertGreaterThan(price("midway", .meds), price("gateway", .meds))
        XCTAssertLessThan(price("phobos", .food), price("gateway", .food))
        XCTAssertGreaterThan(price("phobos", .fuel), price("gateway", .fuel))
        XCTAssertEqual(mars.ports.map(\.mult).min(), mars.port("phobos")!.mult, "Phobos is the cheapest yard")
    }

    // MARK: - Turnover

    func testTurningOnScheduleChangesNothing() {
        let e = engine(ship(mile: 24_000))
        let c = choice(e.beginArrival("turnover"))!
        XCTAssertEqual(key(c), "turnover")
        let before = e.state
        XCTAssertEqual(messages(e.resolve(c, option: 0)).count, 1)
        XCTAssertEqual(e.state, before)
    }

    func testRunningOnGainsFourDaysForEightTonnesAndMayHurtTheDrive() {
        let c = choice(engine(ship(mile: 24_000)).beginArrival("turnover"))!
        let hurt = engine(ship(mile: 24_000), [0, 0.5])
        _ = hurt.resolve(c, option: 1)
        XCTAssertEqual(hurt.state.fuel, 420)
        XCTAssertEqual(hurt.state.mile, 25_400)
        XCTAssertEqual(hurt.state.sails, 85)

        let fine = engine(ship(mile: 24_000))
        _ = fine.resolve(c, option: 1)
        XCTAssertEqual(fine.state.mile, 25_400)
        XCTAssertEqual(fine.state.sails, 100)

        // A tired drive: 30% becomes 50%.
        var s = ship(mile: 24_000)
        s.sails = 45
        let tired = engine(s, [0.45, 0])
        _ = tired.resolve(c, option: 1)
        XCTAssertEqual(tired.state.sails, 35)
        let fresh = engine(ship(mile: 24_000), [0.45])
        _ = fresh.resolve(c, option: 1)
        XCTAssertEqual(fresh.state.sails, 100)

        var dry = ship(mile: 24_000)
        dry.fuel = 79
        let c2 = choice(engine(dry).beginArrival("turnover"))!
        XCTAssertFalse(c2.options[1].enabled)
        XCTAssertTrue(c2.options[0].enabled)
    }

    // MARK: - Capture

    func testAerobrakingIsQuickAndHardOnTheHullUntilPhobos() {
        let e = engine(ship(mile: 46_000), [0.5])
        let c = choice(e.beginArrival("approach"))!
        XCTAssertEqual(key(c), "capture")
        XCTAssertTrue(c.options.allSatisfy(\.enabled))
        _ = e.resolve(c, option: 0)
        XCTAssertEqual(e.state.vars[MarsData.captureKey], 1)
        XCTAssertEqual(e.state.fuel, 500)
        XCTAssertEqual(speed(e, "capture"), 150, accuracy: 0.001)
        XCTAssertEqual(mars.structureDamage(e, region("capture")), 7.05, accuracy: 0.001)
        XCTAssertNotEqual(mars.wreckedBody(e.state), mars.text.wreckedBody)

        e.state.mile = 47_400
        XCTAssertEqual(speed(e, "capture"), 100)
        XCTAssertEqual(mars.structureDamage(e, region("capture")), 0.05, accuracy: 0.001)
        XCTAssertEqual(mars.wreckedBody(e.state), mars.text.wreckedBody)
    }

    func testABurnIntoOrbitCostsTenTonnesAndTakesLonger() {
        let e = engine(ship(mile: 46_000))
        let c = choice(e.beginArrival("approach"))!
        _ = e.resolve(c, option: 1)
        XCTAssertEqual(e.state.vars[MarsData.captureKey], 2)
        XCTAssertEqual(e.state.fuel, 400)
        XCTAssertEqual(speed(e, "capture"), 75, accuracy: 0.001)
        XCTAssertEqual(mars.structureDamage(e, region("capture")), 0.05, accuracy: 0.001)

        // Short of propellant the burn is partial and the rest of the approach coasts.
        let short = engine(ship(mile: 46_000))
        short.state.fuel = 40
        let q = short.resolve(c, option: 1)
        XCTAssertEqual(short.state.vars[MarsData.captureKey], 3)
        XCTAssertEqual(short.state.fuel, 0)
        XCTAssertEqual(speed(short, "capture"), 100)
        XCTAssertTrue(messages(q).first?.contains("run dry") ?? false)
    }

    // MARK: - Sickness

    func testWhatAilsYouDependsOnTheDay() {
        var s = ship()
        let calm = mars.sickPool(engine(s), .cool, nil)
        XCTAssertEqual(calm, mars.ailments)
        s.weather = MarsData.proton
        XCTAssertTrue(mars.sickPool(engine(s), .cool, nil).contains(MarsData.radiation))
        XCTAssertEqual(mars.sickPool(engine(s), .cool, mars.port("midway")), mars.ailments)
        s = ship()
        XCTAssertTrue(mars.sickPool(engine(s), .cold, nil).contains(MarsData.hypothermia))
        XCTAssertFalse(calm.contains(MarsData.hypothermia))
        s.noCitrus = 16
        XCTAssertEqual(mars.sickPool(engine(s), .cool, nil).filter { $0 == MarsData.fracture }.count, 2)
        XCTAssertEqual(mars.deficiency, MarsData.boneLoss)
        XCTAssertEqual(mars.rules.deficiencyAfter, 30)
    }

    func testShelteringFromAFlareCostsADayAndWorkingOnCanCostAHand() {
        let shelter = engine(ship())
        _ = shelter.resolve(ask(shelter, "flare"), option: 0)
        XCTAssertEqual(shelter.state.day, 1)
        XCTAssertEqual(shelter.state.mile, 1000)

        // One person, the first, and the 75% comes up.
        let work = engine(ship(), [0, 0, 0])
        let q = work.resolve(ask(work, "flare"), option: 1)
        XCTAssertEqual(work.state.crew[0].ailment, MarsData.radiation)
        XCTAssertEqual(work.state.day, 0)
        XCTAssertGreaterThanOrEqual(messages(q).count, 2)

        let lucky = engine(ship())
        _ = lucky.resolve(ask(lucky, "flare"), option: 1)
        XCTAssertTrue(lucky.state.crew.allSatisfy { $0.ailment == nil })
    }

    func testAShadowedShipGetsNoFlareWarningOrTrackingFix() {
        func keys(_ mile: Int) -> [String] {
            let s = ship(mile: mile)
            var out: [String] = []
            for ev in mars.events(engine(s), s.region) where ev.ok {
                let e = engine(s, [], fallback: 0)
                var q: [Interrupt] = []
                ev.run(e, &q)
                if let k = key(choice(q)) { out.append(k) }
                if e.state.mile != mile { out.append("fix") }
            }
            return out
        }
        XCTAssertTrue(keys(5000).contains("flare"))
        XCTAssertTrue(keys(5000).contains("fix"))
        XCTAssertFalse(keys(39_000).contains("flare"))
        XCTAssertFalse(keys(39_000).contains("fix"))

        // Nor anything else from Earth: no navigation update, no mail.
        func said(_ mile: Int) -> [String] {
            let s = ship(mile: mile)
            var out: [String] = []
            for ev in mars.events(engine(s), s.region) where ev.ok {
                let e = engine(s, [], fallback: 0)
                var q: [Interrupt] = []
                ev.run(e, &q)
                out += messages(q)
            }
            return out
        }
        for line in ["navigation update from Earth", "Messages from home"] {
            XCTAssertTrue(said(5000).contains { $0.contains(line) }, line)
            XCTAssertFalse(said(39_000).contains { $0.contains(line) }, line)
        }
        // The landmark that says so comes where the shadow begins.
        XCTAssertEqual(mars.stop("shadow")?.mile, mars.regions.first { $0.id == "stream2" }?.to)
    }

    /// Earth and the Moon make a double star only once they are far enough off to be stars.
    func testEarthIsADoubleStarOnlyFromAfar() {
        func seen(_ mile: Int) -> Bool {
            let s = ship(mile: mile)
            return mars.events(engine(s), s.region).contains { ev in
                guard ev.ok else { return false }
                let e = engine(s, [], fallback: 0)
                var q: [Interrupt] = []
                ev.run(e, &q)
                return messages(q).contains { $0.contains("Earth is a bright star") }
            }
        }
        XCTAssertFalse(seen(450))
        XCTAssertTrue(seen(5000))
        XCTAssertFalse(seen(30_000))
    }

    /// A ship you helped promises money at the next station, so she only calls while there
    /// is one ahead.
    func testNobodyAsksForHelpPastTheLastStation() {
        func asked(_ mile: Int) -> Bool {
            let s = ship(mile: mile)
            return mars.events(engine(s), s.region).contains { ev in
                guard ev.ok else { return false }
                let e = engine(s, [], fallback: 0)
                var q: [Interrupt] = []
                ev.run(e, &q)
                return key(choice(q)) == "distress"
            }
        }
        XCTAssertTrue(asked(5000))
        XCTAssertTrue(asked(47_000))
        XCTAssertFalse(asked(47_500))
    }

    // MARK: - The contract and the score

    func testTheContractRunsLateButIsNeverForfeit() {
        let e = engine(ship(mile: 40_000))
        var q: [Interrupt] = []
        e.state.day = MarsData.contractDays - 1
        mars.tick(e, &q, .sail, e.state.region)
        XCTAssertTrue(q.isEmpty)
        e.state.day = MarsData.contractDays
        mars.tick(e, &q, .sail, e.state.region)
        XCTAssertEqual(messages(q).count, 1)
        e.state.day = 400
        mars.tick(e, &q, .port, e.state.region)
        XCTAssertEqual(messages(q).count, 1)
        XCTAssertFalse(e.state.over)
    }

    func testDaysInHandAreWorthPoints() {
        var s = ship(mile: 48_000)
        s.day = 150
        XCTAssertEqual(mars.score(s).lines.first { $0.label == Mars.onTimeLabel }?.points, 20 * MarsData.bonusPerDay)
        s.day = 180
        XCTAssertEqual(mars.score(s).lines.first { $0.label == Mars.onTimeLabel }?.points, 0)
        XCTAssertEqual(mars.score(ship(role: .whaler)).multiplier, 3)
        XCTAssertEqual(mars.rank(Int.max), "Master of Transfer")
        XCTAssertEqual(mars.rank(0), "Groundling")
    }

    // MARK: - Words

    func testDistancesReadInMillionsOfKilometres() {
        XCTAssertEqual(MarsData.km(31_245), "312.45 million km")
        XCTAssertEqual(MarsData.km(38), "0.38 million km")
        XCTAssertEqual(MarsData.km(15_500), "155.00 million km")
        XCTAssertEqual(MarsData.km(48_000), "480.00 million km")
        XCTAssertEqual(MarsData.km(100_005), "1,000.05 million km")
        XCTAssertEqual(MarsData.tonnes(120), "12 tonnes")
        XCTAssertEqual(MarsData.tonnes(10), "1 tonne")
        XCTAssertEqual(MarsData.tonnes(5), "0.5 tonnes")
        XCTAssertEqual(mars.totalMiles, 48_000)
    }

    func testTradeTalksInKilosLitresAndTonnes() {
        XCTAssertEqual(mars.describe(.item(.food), 120), "120 kg of rations")
        XCTAssertEqual(mars.describe(.item(.water), 1), "1 litre of water")
        XCTAssertEqual(mars.describe(.item(.water), 60), "60 litres of water")
        XCTAssertEqual(mars.describe(.item(.limes), 3), "3 supplement packs")
        XCTAssertEqual(mars.describe(.item(.meds), 1), "1 medical kit")
        XCTAssertEqual(mars.describe(.item(.clothes), 2), "2 thermal suits")
        XCTAssertEqual(mars.describe(.item(.sailcloth), 1), "1 array panel")
        XCTAssertEqual(mars.describe(.item(.timber), 2), "2 hull patches")
        XCTAssertEqual(mars.describe(.item(.tackle), 40), "2 tether cartridges")
        XCTAssertEqual(mars.describe(.item(.tackle), 7), "7 tether shots")
        XCTAssertEqual(mars.describe(.item(.fuel), 120), "12 tonnes of propellant")
        XCTAssertEqual(mars.describe(.money, 45), "$45")
        XCTAssertEqual(mars.roundTrade(.item(.food), 34), 30)
        XCTAssertEqual(mars.roundTrade(.item(.fuel), 34), 30)
        XCTAssertEqual(mars.roundTrade(.item(.tackle), 3), 20)
    }

    // MARK: - Balance

    /// How the balance test plays: October; for each leg, food, water and propellant (a
    /// fifth extra, for docking and capture) for the run at three quarters of the pace's
    /// speed (less in a poor window), plus ten days; two each of medical kits, panels and
    /// patches; supplies before the yard, which is used below 70%. The ice hauler eats lean,
    /// carries four tether cartridges, buys water only to the next ice stream when one lies
    /// ahead, and grapples whenever the tanks have room; the others carry two and grapple
    /// only when water runs low. Docks with the cycler; shelters from flares; runs on at
    /// turnover only with propellant to spare; aerobrakes on a hull of 60% or better and
    /// burns into orbit otherwise.
    static func policy(departure: Int = 2) -> JourneyBot.Policy {
        var p = JourneyBot.Policy()
        p.departure = departure
        p.marginTurns = 10
        p.rations = [.whaler: .meager]
        p.speedShare = 0.75 * (MarsData.window[MarsData.departures[departure].month] ?? 1)
        p.stockFactor = [.fuel: 1.2]
        p.stockFactorHere = { e, k in
            guard k == .water, e.state.role == .whaler else { return nil }
            return ["gateway", "midway"].contains(e.state.currentStop.id) ? 0.5 : nil
        }
        p.spares = [(.meds, 2), (.sailcloth, 2), (.timber, 2)]
        p.tackle = [.merchant: 40, .shipwright: 40, .whaler: 80]
        p.forageBelowTurns = [.merchant: 25, .shipwright: 25, .whaler: 80]
        p.hitChance = [.merchant: 0.35, .shipwright: 0.35, .whaler: 0.55]
        p.mendBelow = 45
        p.yardBelow = 70
        p.yardAfterShop = true
        p.decide = { e, c in
            guard case .custom(let key, _) = c.kind else { return nil }
            switch key {
            case "turnover":
                let midway = MarsData.stops.first { $0.id == "midway" }!.mile
                let need = Double(midway - e.state.mile) / 370 * 10 * 1.2
                return e.state.fuel >= MarsData.turnoverBurn + need ? 1 : 0
            case "capture":
                return e.state.hull >= 60 ? 0 : 1
            default:
                return nil
            }
        }
        return p
    }

    /// October is the launch the forecasters recommend. The charter captain should nearly
    /// always arrive, the yard rigger usually, the ice hauler about half the time, and a
    /// winning run should take a little under the contract's 170 days.
    func testOctoberBalanceStaysInItsBands() {
        XCTAssertEqual(MarsData.departures[2].month, 9)
        let r = JourneyBot.survey(mars, count: 30, seed: 500, policy: Self.policy())
        print(r.report)
        XCTAssertGreaterThanOrEqual(r.rates[.merchant] ?? 0, 0.85, r.report)
        XCTAssertGreaterThanOrEqual(r.rates[.shipwright] ?? 0, 0.6, r.report)
        XCTAssertLessThanOrEqual(r.rates[.shipwright] ?? 1, 0.9 + 1e-9, r.report)
        XCTAssertGreaterThanOrEqual(r.rates[.whaler] ?? 0, 0.35, r.report)
        XCTAssertLessThanOrEqual(r.rates[.whaler] ?? 1, 0.7, r.report)
        XCTAssertTrue((140...180).contains(r.medianTurns), r.report)
    }

    /// Early the planets are badly placed; late they are badly placed and the Sun is
    /// stormy. Either way the trip is longer, and the two poorer roles pay for it.
    func testAugustAndDecemberAreHarder() {
        let october = JourneyBot.survey(mars, count: 30, seed: 500, policy: Self.policy())
        let august = JourneyBot.survey(mars, count: 30, seed: 500, policy: Self.policy(departure: 0))
        let december = JourneyBot.survey(mars, count: 30, seed: 500, policy: Self.policy(departure: 4))
        print(august.report + "\n" + december.report)
        for role in [Role.shipwright, .whaler] {
            XCTAssertLessThan(august.rates[role] ?? 1, (october.rates[role] ?? 0) - 0.2, august.report)
            XCTAssertLessThan(december.rates[role] ?? 1, (october.rates[role] ?? 0) - 0.2, december.report)
        }
        XCTAssertGreaterThan(august.medianTurns, october.medianTurns + 10, august.report)
        XCTAssertGreaterThan(december.medianTurns, october.medianTurns + 10, december.report)
    }

    /// The ice hauler's living is the grapple; leave it at home, or burn hard all the way,
    /// and the money runs out first.
    func testTheIceHaulerNeedsTheGrappleAndAnEasyHand() {
        let bot = JourneyBot.survey(mars, count: 30, seed: 500, policy: Self.policy())
        var p = Self.policy()
        p.tackle = [:]
        p.forageBelowTurns = [:]
        p.stockFactorHere = nil
        let dry = JourneyBot.survey(mars, count: 30, seed: 500, policy: p)
        print(dry.report)
        XCTAssertLessThan(dry.rates[.whaler] ?? 1, (bot.rates[.whaler] ?? 0) - 0.3, dry.report)

        p = Self.policy()
        p.pace = .full
        let hard = JourneyBot.survey(mars, count: 30, seed: 500, policy: p)
        print(hard.report)
        XCTAssertLessThan(hard.rates[.whaler] ?? 1, (bot.rates[.whaler] ?? 0) - 0.2, hard.report)
        XCTAssertLessThan(hard.medianTurns, bot.medianTurns, hard.report)
    }

    func testLosingRunsEndMoreThanOneWay() {
        var endings = Set<String>()
        for role in [Role.shipwright, .whaler] {
            for i in 0..<30 {
                let r = JourneyBot(journey: mars, role: role, seed: 500 + UInt64(1000 * role.scoreMultiplier + i),
                                   policy: Self.policy()).play()
                if !r.won { endings.insert(r.ending) }
            }
        }
        XCTAssertGreaterThanOrEqual(endings.count, 3, "\(endings)")
    }
}
