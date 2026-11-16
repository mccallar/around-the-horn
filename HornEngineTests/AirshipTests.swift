import XCTest
@testable import HornEngine

/// Over the Pole's own rules, and the bands its balance has to stay in
/// (docs/journeys/airship.md).
final class AirshipTests: XCTestCase {
    let airship = Journeys.journey(Airship.id)

    /// Five aboard a well-found airship, in the air. May unless told otherwise.
    func flying(km: Int = 1000, month: Int = 4, role: Role = .merchant) -> GameState {
        var s = GameState(journey: Airship.id, role: role, ship: "Kestrel", captain: "Arne",
                          crew: ["Ingrid", "Sigurd", "Solveig", "Olav"], startYear: 1926, startMonth: month)
        s.mile = km
        s.stopIndex = airship.stops.lastIndex { $0.mile <= km } ?? 0
        s.food = 200
        s.water = 200
        s.limes = 10
        s.fuel = 4000
        s.meds = 2
        s.clothes = 5
        s.sailcloth = 2
        s.timber = 3
        s.tackle = 60
        s.atPort = false
        return s
    }

    func region(_ id: RegionID) -> Region {
        if id == AirshipData.underFog.id { return AirshipData.underFog }
        return airship.regions.first { $0.id == id }!
    }

    func messages(_ q: [Interrupt]) -> [String] {
        q.compactMap { if case .message(let t) = $0 { return t } else { return nil } }
    }

    func choice(_ q: [Interrupt]) -> ChoiceEvent? {
        for i in q { if case .choice(let c) = i { return c } }
        return nil
    }

    func ask(_ key: String, _ args: [String] = []) -> ChoiceEvent {
        ChoiceEvent(kind: .custom(key: key, args: args), prompt: "", detail: nil,
                    options: [.init("a"), .init("b"), .init("c")])
    }

    // MARK: - Petrol

    func testEachPaceBurnsItsPetrolAWatch() {
        for (pace, burn) in [(Pace.easy, 150.0), (.steady, 250), (.full, 420)] {
            var s = flying()
            s.pace = pace
            s.forceFair = 1
            let e = engine(s)
            _ = e.sailDay()
            XCTAssertEqual(e.state.fuel, 4000 - burn, "\(pace)")
            XCTAssertLessThan(e.state.sails, 100)
        }
    }

    func testTheLastOfThePetrolStillPowersAWatch() {
        var s = flying()
        s.fuel = 100
        s.forceFair = 1
        let e = engine(s)
        _ = e.sailDay()
        XCTAssertEqual(e.state.fuel, 0)
        XCTAssertGreaterThan(e.state.mile - 1000, 200)
        XCTAssertFalse(Airship.drifting(e.state))
    }

    func testDryTanksDriftWithTheWindAndSpareTheEngines() {
        var s = flying()
        s.fuel = 0
        s.forceFair = 1
        let e = engine(s)
        let q = e.sailDay()
        XCTAssertTrue(Airship.drifting(e.state))
        // 60 km × fair × full lift × the top of the jitter.
        XCTAssertEqual(e.state.mile - 1000, 69)
        XCTAssertEqual(e.state.sails, 100)
        XCTAssertEqual(e.state.note, "Engines silent. You are going where the wind goes.")
        XCTAssertTrue(messages(q).contains(airship.text.outOfFuel))

        // The drift ignores pace, engines and crew; it rides the weather and what lift is left.
        var t = flying()
        t.fuel = 0
        t.hull = 60
        t.sails = 10
        t.pace = .full
        t.weather = AirshipData.head
        let d = engine(t)
        var sp = 999.0
        airship.adjustSpeed(d, d.state.region, &sp)
        XCTAssertEqual(sp, 60 * 0.6 * 0.9, accuracy: 1e-9)
    }

    // MARK: - Lift

    func testGasSeepsAndTheWeatherAndTheSunTakeMore() {
        let e = engine(flying())
        XCTAssertEqual(airship.structureDamage(e, region("france")), AirshipData.seep, accuracy: 1e-9)
        XCTAssertEqual(airship.structureDamage(e, region("aboveFog")), AirshipData.seep + 0.6, accuracy: 1e-9)

        var s = flying()
        s.weather = AirshipData.ice
        s.pace = .full
        let iced = engine(s, [0.5])
        // rnd(1, 3) = 2, × full speed 1.6, × the low route's 1.5.
        XCTAssertEqual(airship.structureDamage(iced, region("underFog")), 0.15 + 2 * 1.6 * 1.5, accuracy: 1e-9)

        s.weather = AirshipData.storm
        s.pace = .easy
        let storm = engine(s, [0.5])
        XCTAssertEqual(airship.structureDamage(storm, region("france")), 0.15 + 1.8 * 0.7, accuracy: 1e-9)
    }

    func testAHeavyShipDumpsPetrol() {
        var s = flying()
        s.hull = 30
        s.fuel = 1000
        let e = engine(s, [0.01, 0])
        var q: [Interrupt] = []
        airship.tick(e, &q, .sail, e.state.region)
        XCTAssertEqual(e.state.fuel, 900)
        XCTAssertEqual(messages(q).count, 1)

        s.hull = 40
        let light = engine(s, [0.01, 0])
        q = []
        airship.tick(light, &q, .sail, light.state.region)
        XCTAssertEqual(light.state.fuel, 1000)
        XCTAssertTrue(q.isEmpty)
    }

    func testForcedDownOnTheIceOrInAField() {
        var s = flying(km: 1000)
        s.hull = 0
        let field = engine(s)
        var q: [Interrupt] = []
        field.checkSink(&q)
        guard case .gameOver(let title, let body)? = q.last else { return XCTFail("no ending") }
        XCTAssertEqual(title, "The [i]Kestrel[/i] has been forced down.")
        XCTAssertTrue(body.contains("farmer"))

        s = flying(km: 6000)
        s.hull = 0
        let ice = engine(s)
        q = []
        ice.checkSink(&q)
        guard case .gameOver(_, let polar)? = q.last else { return XCTFail("no ending") }
        XCTAssertTrue(polar.contains("onto the ice"))

        // Over open water she comes down on the sea, not in a field.
        for km in [300, 2000] {
            s = flying(km: km)
            s.hull = 0
            let wet = engine(s)
            q = []
            wet.checkSink(&q)
            guard case .gameOver(_, let sea)? = q.last else { return XCTFail("no ending") }
            XCTAssertTrue(sea.contains("onto the sea"), "\(km)")
            XCTAssertFalse(sea.contains("farmer"), "\(km)")
        }

        // Scandinavia is north, but land: a field, not the ice. Everywhere with sea ice
        // below, and only there, is the ice.
        for region in airship.regions + [AirshipData.underFog] {
            s = flying(km: region.to - 5)
            if region.id == AirshipData.underFog.id { s.vars[AirshipData.routeKey] = AirshipData.routeLow }
            XCTAssertEqual(s.region.id, region.id)
            let body = airship.wreckedBody(s)
            XCTAssertEqual(body.contains("onto the ice"), region.has("pack"), region.name)
            if region.id.rawValue == "scandinavia" { XCTAssertTrue(body.contains("farmer"), body) }
        }
    }

    /// The sights below match the country: mock suns in the north, a fishing fleet at sea,
    /// a village over land.
    func testWhatYouSeeBelowMatchesTheCountry() {
        func sight(_ km: Int) -> String {
            let e = engine(flying(km: km))
            var q: [Interrupt] = []
            airship.events(e, e.state.region)[14].run(e, &q)
            return messages(q).first ?? ""
        }
        XCTAssertTrue(sight(300).contains("fishing fleet"))
        XCTAssertTrue(sight(2000).contains("fishing fleet"))
        XCTAssertTrue(sight(1000).contains("village"))
        XCTAssertTrue(sight(6000).contains("mock suns"))
    }

    // MARK: - The fork

    func testThePoleChoosesTheCountryBeyondIt() {
        var s = flying(km: 7000)
        XCTAssertEqual(s.region.id, "aboveFog")
        s.vars[AirshipData.routeKey] = AirshipData.routeLow
        XCTAssertEqual(s.region.id, "underFog")
        XCTAssertEqual(s.temperature(in: s.region), .cold)
        s.mile = 8700
        XCTAssertEqual(s.region.id, "alaska")
        s.mile = 6000
        XCTAssertEqual(s.region.id, "polarSea")
    }

    func testThePoleAsksAndTheNavigatorAdvises() {
        let e = engine(flying(km: 6550, month: 3))
        guard let pole = choice(e.beginArrival("pole")) else { return XCTFail("no choice") }
        XCTAssertEqual(pole.options.count, 3)
        XCTAssertTrue(pole.prompt.contains("iron-hard"))

        let advice = e.resolve(pole, option: 2)
        XCTAssertEqual(messages(advice).count, 1)
        XCTAssertNotNil(choice(advice))
        XCTAssertNil(e.state.vars[AirshipData.routeKey])

        _ = e.resolve(pole, option: 0)
        XCTAssertEqual(e.state.vars[AirshipData.routeKey], AirshipData.routeHigh)
    }

    func testUnderTheFogTheForecastsCostSixtyDollars() {
        let e = engine(flying(km: 6550))
        e.state.money = 100
        guard let pole = choice(e.beginArrival("pole")),
              let offer = choice(e.resolve(pole, option: 1)) else { return XCTFail("no offer") }
        XCTAssertEqual(e.state.vars[AirshipData.routeKey], AirshipData.routeLow)
        XCTAssertTrue(offer.options[0].enabled)
        _ = e.resolve(offer, option: 0)
        XCTAssertEqual(e.state.money, 40)
        XCTAssertEqual(e.state.vars[AirshipData.forecastKey], 1)

        let poor = engine(flying(km: 6550))
        poor.state.money = 59
        guard let p2 = choice(poor.beginArrival("pole")),
              let o2 = choice(poor.resolve(p2, option: 1)) else { return XCTFail("no offer") }
        XCTAssertFalse(o2.options[0].enabled)
        XCTAssertTrue(o2.options[1].enabled)
        XCTAssertEqual(poor.resolve(o2, option: 0), [.choice(o2)])
    }

    func testRidgesHideUnderTheFogAndTheForecastsFindMostOfThem() {
        var s = flying(km: 7000)
        s.vars[AirshipData.routeKey] = AirshipData.routeLow
        s.day = 50
        let blind = engine(s, [0.03])
        var q: [Interrupt] = []
        airship.dayEvents(blind, &q, blind.state.region)
        XCTAssertEqual(blind.state.hull, 78)
        XCTAssertEqual(blind.state.day, 51)
        XCTAssertEqual(messages(q).count, 1)

        s.vars[AirshipData.forecastKey] = 1
        let warned = engine(s, [0.03])
        q = []
        airship.dayEvents(warned, &q, warned.state.region)
        XCTAssertEqual(warned.state.hull, 100)
        XCTAssertTrue(q.isEmpty)
    }

    /// At the Pole, the low route is only called warmer in the months it is: in April both
    /// heights freeze, and in July both are merely cold.
    func testThePoleOnlyPromisesWarmthUnderTheFogWhenThereIsSome() {
        for (month, warmer) in [(3, false), (4, true), (5, true), (6, false)] {
            let e = engine(flying(km: 6550, month: month))
            XCTAssertEqual(airship.temperature(e.state, in: AirshipData.underFog) != airship.temperature(e.state, in: AirshipData.aboveFog),
                           warmer, "month \(month)")
            guard let pole = choice(e.beginArrival("pole")) else { return XCTFail("no choice") }
            XCTAssertEqual(pole.detail?.contains("where it is warmer") ?? false, warmer, "month \(month)")
            XCTAssertEqual(pole.detail?.contains("no warmer at this time of year") ?? false, !warmer, "month \(month)")
            let advice = messages(e.resolve(pole, option: 2)).first ?? ""
            XCTAssertEqual(advice.contains("Under it, it's warmer"), warmer, "month \(month)")
            XCTAssertEqual(advice.contains("no warmer this time of year"), !warmer, "month \(month)")
        }
    }

    // MARK: - Season

    func testTheSeasonMovesTheColdAndTheFog() {
        XCTAssertEqual(airship.temperature(flying(month: 3), in: region("scandinavia")), .freezing)
        XCTAssertEqual(airship.temperature(flying(month: 4), in: region("scandinavia")), .cold)
        XCTAssertEqual(airship.temperature(flying(month: 6), in: region("polarSea")), .cold)
        XCTAssertEqual(airship.temperature(flying(month: 3), in: region("france")), .cool)

        func odds(_ month: Int, _ id: RegionID, _ w: Weather) -> Double {
            airship.weatherWeights(engine(flying(month: month)), region(id), cursed: false).first { $0.0 == w }?.1 ?? 0
        }
        XCTAssertEqual(odds(3, "polarSea", AirshipData.snow), 24)
        XCTAssertEqual(odds(3, "polarSea", AirshipData.fog), 10)
        XCTAssertEqual(odds(4, "polarSea", AirshipData.fog), 20)
        XCTAssertEqual(odds(5, "polarSea", AirshipData.ice), 18)
        XCTAssertEqual(odds(6, "polarSea", AirshipData.fog), 38)
        XCTAssertEqual(odds(6, "polarSea", AirshipData.fair), 24 * 0.6, accuracy: 1e-9)
        XCTAssertEqual(odds(5, "med", AirshipData.storm), 8)
        XCTAssertEqual(odds(4, "med", AirshipData.storm), 4)
    }

    /// The fog comes down to the ice only where there is ice below: over the pack when it
    /// freezes, and always on the polar leap. Never over the forests of Norway.
    func testFogToTheIceNeedsIceBelow() {
        func murk(_ km: Int, month: Int) -> Bool {
            let e = engine(flying(km: km, month: month))
            return airship.events(e, e.state.region)[13].ok
        }
        XCTAssertEqual(airship.temperature(flying(km: 3000, month: 3), in: region("scandinavia")), .freezing)
        XCTAssertFalse(murk(3000, month: 3), "April over Scandinavia")
        XCTAssertTrue(murk(4500, month: 3), "April over the Barents pack")
        XCTAssertFalse(murk(4500, month: 4), "May over the open Barents Sea")
        XCTAssertTrue(murk(6000, month: 4))
        XCTAssertTrue(murk(7000, month: 6))
        XCTAssertFalse(murk(1000, month: 3))
    }

    /// With the tanks dry she cannot circle: neither the newspaper nor the murk asks.
    func testADriftingShipIsNotAskedToCircle() {
        func asked(_ fuel: Double) -> (news: Bool, murk: Bool) {
            var s = flying(km: 6000)
            s.fuel = fuel
            s.forceFair = 1
            let e = engine(s)
            var sp = 0.0
            airship.adjustSpeed(e, e.state.region, &sp)
            let ev = airship.events(e, e.state.region)
            return (ev[17].ok, ev[13].ok)
        }
        XCTAssertTrue(asked(4000).news)
        XCTAssertTrue(asked(4000).murk)
        XCTAssertFalse(asked(0).news)
        XCTAssertFalse(asked(0).murk)
    }

    /// The Rhône mark is where the coast is crossed: the Mediterranean ends there.
    func testTheCoastIsCrossedAtTheRhone() {
        let rhone = airship.stops.first { $0.id == "rhone" }!
        XCTAssertEqual(region("med").to, rhone.mile)
        XCTAssertEqual(flying(km: rhone.mile - 1).region.id, "med")
        XCTAssertEqual(flying(km: rhone.mile).region.id, "france")
    }

    // MARK: - Coffee, sickness, the masts

    func testCoffeeKeepsTheWatchAwake() {
        let e = engine(flying())
        var q: [Interrupt] = []
        e.consume(&q, .sail)
        XCTAssertEqual(e.state.limes, 9.9, accuracy: 1e-9)
        XCTAssertEqual(e.state.noCitrus, 0)

        e.state.limes = 0
        e.consume(&q, .sail)
        XCTAssertEqual(e.state.noCitrus, 1)
        e.consume(&q, .port)
        XCTAssertEqual(e.state.noCitrus, 0)

        // Twelve watches without, and the thirteenth can bring watch fatigue on.
        var s = flying()
        s.limes = 0
        s.noCitrus = 13
        let tired = engine(s, [0.5, 0])
        q = []
        tired.health(&q, .sail)
        XCTAssertEqual(tired.state.crew[0].ailment, AirshipData.watchFatigue)
        XCTAssertTrue(messages(q).first?.contains("Hot coffee") ?? false)
        XCTAssertEqual(tired.state.meds, 2)
    }

    func testWhatAilsYouDependsOnTheColdAndTheMast() {
        let e = engine(flying())
        XCTAssertEqual(airship.sickPool(e, .cold, airship.port("kingsbay")), AirshipData.mastPool)
        XCTAssertEqual(airship.sickPool(e, .freezing, nil), AirshipData.coldPool)
        XCTAssertEqual(airship.sickPool(e, .cool, airship.port("oslo")), AirshipData.mildPool)
        XCTAssertTrue(airship.port("kingsbay")!.fever)
    }

    func testAStowawayPutOffLeavesAtPulham() {
        let e = engine(flying(km: 900))
        _ = e.resolve(ask("stowaway", ["Rosa"]), option: 1)
        XCTAssertEqual(e.state.living.count, 6)
        XCTAssertEqual(e.state.hull, 100)
        let q = e.beginArrival("pulham")
        XCTAssertEqual(e.state.living.count, 5)
        XCTAssertTrue(choice(q)?.detail?.contains("Rosa waves goodbye") ?? false)

        let signed = engine(flying(km: 900))
        _ = signed.resolve(ask("stowaway", ["Rosa"]), option: 0)
        XCTAssertEqual(signed.state.living.count, 6)
        XCTAssertEqual(signed.state.hull, 97)
    }

    func testTheStowawayIsOnlyFoundBeforePulham() {
        func offered(_ km: Int, day: Int) -> Bool {
            var s = flying(km: km)
            s.day = day
            let e = engine(s)
            return airship.events(e, e.state.region)[11].ok
        }
        XCTAssertTrue(offered(900, day: 4))
        XCTAssertFalse(offered(900, day: 9))
        XCTAssertFalse(offered(1800, day: 8))
    }

    // MARK: - Set pieces and choices

    func testTheArcticCircleIsWorthAWatch() {
        var s = flying(km: 3650)
        s.crew[1].hp = 80
        s.day = 30
        let e = engine(s)
        guard let c = choice(e.beginArrival("circle")) else { return XCTFail("no choice") }
        _ = e.resolve(c, option: 0)
        XCTAssertEqual(e.state.day, 31)
        XCTAssertEqual(e.state.food, 197)
        XCTAssertEqual(e.state.crew[1].hp, 88)
    }

    func testPointBarrowRefuelsAndWakesEveryone() {
        var s = flying(km: 8600)
        s.fuel = 1000
        s.food = 100
        s.water = 100
        s.limes = 0
        s.noCitrus = 20
        s.crew[2].ailment = AirshipData.watchFatigue
        s.day = 70
        let e = engine(s, [0.5, 0.5, 0.5])
        guard let c = choice(e.beginArrival("barrow")) else { return XCTFail("no choice") }
        XCTAssertTrue(c.prompt.contains("fog bank"))
        let q = e.resolve(c, option: 0)
        XCTAssertTrue(messages(q)[0].contains("350 kg of petrol, 18 kg of dried fish"))
        XCTAssertEqual(e.state.fuel, 1350)
        XCTAssertEqual(e.state.food, 118 - 2 * 5 * 0.3, accuracy: 1e-9)
        XCTAssertEqual(e.state.water, 145 - 2 * 5 * 0.6, accuracy: 1e-9)
        XCTAssertEqual(e.state.limes, AirshipData.barrowCoffee - 2 * 5 * 0.02, accuracy: 1e-9)
        XCTAssertEqual(e.state.noCitrus, 0)
        XCTAssertNil(e.state.crew[2].ailment)
        XCTAssertEqual(e.state.day, 72)

        var low = flying(km: 8600)
        low.vars[AirshipData.routeKey] = AirshipData.routeLow
        XCTAssertTrue(choice(engine(low).beginArrival("barrow"))?.prompt.contains("tundra") ?? false)
    }

    func testHelpingTheCastawaysCostsAWatchAndAKit() {
        var s = flying(km: 6000)
        s.day = 40
        let e = engine(s, [0.5])
        let q = e.resolve(ask("flares"), option: 0)
        XCTAssertEqual(e.state.day, 41)
        XCTAssertEqual(e.state.meds, 1)
        XCTAssertEqual(e.state.food, 185 - 5 * 0.3, accuracy: 1e-9)
        XCTAssertTrue(messages(q)[0].contains("and a medicine kit"))
        XCTAssertEqual(e.state.forceFair, 1, "one fair watch spent on the watch passed")
    }

    func testClimbingOutOfTheMurkCostsAWatchAndPetrol() {
        var s = flying(km: 6000)
        s.day = 40
        let climb = engine(s)
        let q = climb.resolve(ask("murk", ["fog"]), option: 0)
        XCTAssertEqual(climb.state.day, 41)
        XCTAssertEqual(climb.state.fuel, 3750)
        XCTAssertTrue(messages(q)[0].contains("clear patch"))

        let hold = engine(s, [0.2])
        _ = hold.resolve(ask("murk", ["fog"]), option: 1)
        XCTAssertEqual(hold.state.hull, 65)
        let clearer = engine(s, [0.2])
        _ = clearer.resolve(ask("murk", ["cloud"]), option: 1)
        XCTAssertEqual(clearer.state.hull, 100)
    }

    func testThePhotographsPayAndCostPetrolAndTwoWatches() {
        var s = flying()
        s.day = 10
        let e = engine(s)
        let before = e.state.money
        let q = e.resolve(ask("news", ["55"]), option: 0)
        XCTAssertEqual(e.state.money, before + 55)
        XCTAssertEqual(e.state.fuel, 3500)
        XCTAssertEqual(e.state.day, 12)
        XCTAssertTrue(messages(q)[0].contains("Petrol −500 kg"))
    }

    // MARK: - Pilot balloons

    func testPilotBalloonsWantBalloonsAndClearAir() {
        XCTAssertNil(engine(flying()).fishingRefusal)
        var s = flying()
        s.weather = AirshipData.fog
        XCTAssertEqual(engine(s).fishingRefusal, "You can't follow a balloon into fog.")
        s.weather = AirshipData.ice
        XCTAssertEqual(engine(s).fishingRefusal, "You can't follow a balloon into fog.")
        s.weather = AirshipData.gale
        XCTAssertEqual(engine(s).fishingRefusal, airship.text.tooRough)
        s = flying()
        s.tackle = 0
        XCTAssertEqual(engine(s).fishingRefusal, airship.text.noTackle)
    }

    func testTheWindsFoundArePetrolSaved() {
        let met = engine(flying(role: .whaler))
        _ = met.landCatch(1000)
        XCTAssertEqual(met.state.fuel, 4900)
        let fin = engine(flying(role: .merchant))
        let q = fin.landCatch(1000)
        XCTAssertEqual(fin.state.fuel, 4450)
        XCTAssertTrue(messages(q)[0].contains("450 kg is all you can use"))
        var full = flying(role: .whaler)
        full.fuel = 7800
        let topped = engine(full)
        _ = topped.landCatch(450)
        XCTAssertEqual(topped.state.fuel, 8000)
    }

    // MARK: - Trade and score

    func testTradeTalksInKilosBoxesAndBags() {
        let j = airship
        XCTAssertEqual(j.describe(.item(.food), 120), "120 kg of provisions")
        XCTAssertEqual(j.describe(.item(.water), 1), "1 litre of water")
        XCTAssertEqual(j.describe(.item(.limes), 2), "2 tins of coffee")
        XCTAssertEqual(j.describe(.item(.meds), 1), "1 medicine kit")
        XCTAssertEqual(j.describe(.item(.meds), 2), "2 medicine kits")
        XCTAssertEqual(j.describe(.item(.clothes), 2), "2 fur suits")
        XCTAssertEqual(j.describe(.item(.sailcloth), 1), "1 box of engine spares")
        XCTAssertEqual(j.describe(.item(.timber), 3), "3 bags of ballast")
        XCTAssertEqual(j.describe(.item(.tackle), 10), "1 box of pilot balloons")
        XCTAssertEqual(j.describe(.item(.tackle), 20), "2 boxes of pilot balloons")
        // A broken box is counted in balloons, never in fractions of a box.
        XCTAssertEqual(j.describe(.item(.tackle), 85), "85 pilot balloons")
        XCTAssertEqual(j.describe(.item(.tackle), 5), "5 pilot balloons")
        XCTAssertEqual(j.describe(.item(.tackle), 1), "1 pilot balloon")
        XCTAssertEqual(j.describe(.item(.fuel), 1400), "1,400 kg of petrol")
        XCTAssertEqual(j.describe(.money, 45), "$45")

        XCTAssertEqual(j.roundTrade(.item(.fuel), 230), 200)
        XCTAssertEqual(j.roundTrade(.item(.fuel), 20), 100)
        XCTAssertEqual(j.roundTrade(.item(.food), 3), 10)
        XCTAssertEqual(j.roundTrade(.item(.tackle), 34), 30)
        XCTAssertEqual(j.roundTrade(.item(.meds), 0.2), 1)
        XCTAssertEqual(j.roundTrade(.money, 12), 10)
        XCTAssertEqual(j.tradeValue(.item(.fuel)), 0.025)
    }

    func testTheScoreCountsPetrolAndSpares() {
        var s = flying(role: .shipwright)
        s.hull = 80
        s.sails = 70
        s.food = 100
        s.water = 60
        s.fuel = 1000
        s.limes = 3.5
        s.meds = 2
        s.clothes = 5
        s.sailcloth = 1
        s.timber = 2
        s.tackle = 25
        s.money = 300
        let score = airship.score(s)
        XCTAssertEqual(score.lines.map(\.points), [2500, 230, 64, 40, 60])
        XCTAssertEqual(score.total, 2894 * 2)
        XCTAssertEqual(airship.rank(7000), "Commander")
        XCTAssertEqual(airship.rank(1999), "Ballast")

        s.day = 85
        XCTAssertTrue(Airship.finale(s).contains("after 85 watches (14 days) in the air"))
    }

    // MARK: - Balance

    /// How the balance test flies: cruising, the two poorer roles on short rations, two of
    /// each spare and three bags of ballast, pilot balloons for every role (30, 60 or 100) sent
    /// up when the tanks run low, mend below 60%, gas and engines at a mast below 55%, and
    /// every choice the cautious way.
    static func policy(departure: Int = 1, pace: Pace = .steady) -> JourneyBot.Policy {
        var p = JourneyBot.Policy()
        p.departure = departure
        p.pace = pace
        p.rations = [.merchant: .filling, .shipwright: .meager, .whaler: .meager]
        p.speedShare = 0.7
        p.marginTurns = 4
        p.spares = [(.meds, 2), (.sailcloth, 2), (.timber, 3)]
        p.tackle = [.merchant: 30, .shipwright: 60, .whaler: 100]
        p.forageBelowTurns = [.merchant: 4, .shipwright: 6, .whaler: 15]
        p.hitChance = [.merchant: 0.35, .shipwright: 0.35, .whaler: 0.55]
        p.mendBelow = 60
        p.yardBelow = 55
        // Fly on past steamers, put the stowaway off, decline the photographs; help the
        // castaways, celebrate, climb out of the murk, come down at Barrow; above or under
        // the fog by the watch, buying the forecasts when going under.
        p.decide = { e, c in
            guard case .custom(let key, _) = c.kind else { return nil }
            switch key {
            case "steamer", "stowaway", "news": return 1
            case "pole": return e.state.day % 2
            default: return nil
            }
        }
        return p
    }

    /// The balance tests fly 180 flights a role from one seed base. Thirty is too few: the
    /// engineer's rate moves ten points from one block of thirty seeds to the next, so a band
    /// checked on thirty says more about the seeds than the rules. From seed 12345 the rates sit
    /// close to those of 600 flights a role (docs/journeys/airship.md, "Balance").
    static let flights = 180
    static let seed: UInt64 = 12345
    static let may = JourneyBot.survey(Journeys.journey(Airship.id), count: flights, seed: seed, policy: policy())

    /// May is the month the old balloonist recommends. The financier should nearly always
    /// arrive, the engineer usually, the meteorologist about half the time, and a winning
    /// flight should take about thirteen days.
    func testMayBalanceStaysInItsBands() {
        XCTAssertEqual(AirshipData.departures[1].month, 4)
        let r = Self.may
        print(r.report)
        XCTAssertGreaterThanOrEqual(r.rates[.merchant] ?? 0, 0.85, r.report)
        XCTAssertGreaterThanOrEqual(r.rates[.shipwright] ?? 0, 0.6, r.report)
        XCTAssertLessThanOrEqual(r.rates[.shipwright] ?? 1, 0.9 + 1e-9, r.report)
        XCTAssertGreaterThanOrEqual(r.rates[.whaler] ?? 0, 0.35, r.report)
        XCTAssertLessThanOrEqual(r.rates[.whaler] ?? 1, 0.7 + 1e-9, r.report)
        XCTAssertTrue((70...100).contains(r.medianTurns), r.report)
    }

    /// Leave in July and the polar fog and the contrary winds are waiting: the two poorer
    /// roles do clearly worse.
    func testJulyIsHarder() {
        let may = Self.may
        let july = JourneyBot.survey(airship, count: Self.flights, seed: Self.seed, policy: Self.policy(departure: 3))
        print(july.report)
        for role in [Role.shipwright, .whaler] {
            XCTAssertLessThan(july.rates[role] ?? 1, (may.rates[role] ?? 0) - 0.15, july.report)
        }
        XCTAssertGreaterThanOrEqual(july.rates[.merchant] ?? 0, 0.85, july.report)
    }

    /// Full speed all the way burns too much petrol to cross the ice on what a poorer
    /// purse can buy. (It wins so rarely that 60 flights a role show it.)
    func testFullSpeedOverThePoleIsAMistake() {
        let may = Self.may
        let full = JourneyBot.survey(airship, count: 60, seed: Self.seed, policy: Self.policy(pace: .full))
        print(full.report)
        for role in [Role.shipwright, .whaler] {
            XCTAssertLessThan(full.rates[role] ?? 1, (may.rates[role] ?? 0) / 2, full.report)
        }
    }

    func testLosingFlightsEndMoreThanOneWay() {
        var endings = Set<String>()
        for i in 0..<30 {
            let r = JourneyBot(journey: airship, role: .whaler, seed: 500 + UInt64(1000 * Role.whaler.scoreMultiplier + i),
                               policy: Self.policy()).play()
            if !r.won { endings.insert(r.ending) }
        }
        XCTAssertGreaterThanOrEqual(endings.count, 3, "\(endings)")
    }
}
