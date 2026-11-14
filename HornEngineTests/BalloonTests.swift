import XCTest
@testable import HornEngine

/// The Jet Stream's own rules, and the bands its balance has to stay in
/// (docs/journeys/balloon.md).
final class BalloonTests: XCTestCase {
    let balloon = Journeys.journey(Balloon.id) as! Balloon

    /// Five aboard, well found, aloft over the Sahara in January 1999 unless told otherwise.
    func flying(mile: Int = 1000, month: Int = 0, role: Role = .merchant) -> GameState {
        var s = GameState(journey: Balloon.id, role: role, ship: "Skylark", captain: "Anna",
                          crew: ["Bruno", "Claire", "Dieter", "Elena"], startYear: 1999, startMonth: month)
        s.mile = mile
        s.stopIndex = balloon.stops.lastIndex { $0.mile <= mile } ?? 0
        s.food = 200
        s.water = 100
        s.limes = 10
        s.meds = 2
        s.clothes = 5
        s.sailcloth = 2
        s.timber = 2
        s.tackle = 40
        s.fuel = 500
        s.atPort = false
        return s
    }

    /// On the ground at a field.
    func landed(_ id: String, month: Int = 0) -> GameState {
        var s = flying(mile: balloon.stop(id)!.mile, month: month)
        s.stopIndex = balloon.stops.firstIndex { $0.id == id }!
        s.atPort = true
        return s
    }

    func region(_ id: RegionID) -> Region {
        (balloon.regions + [BalloonData.southTrack, BalloonData.subtropic]).first { $0.id == id }!
    }

    func messages(_ q: [Interrupt]) -> [String] {
        q.compactMap { if case .message(let t) = $0 { return t } else { return nil } }
    }

    func choice(_ q: [Interrupt]) -> ChoiceEvent? {
        for i in q { if case .choice(let c) = i { return c } }
        return nil
    }

    func ask(_ key: String) -> ChoiceEvent {
        ChoiceEvent(kind: .custom(key: key, args: []), prompt: "", detail: nil,
                    options: [.init("a"), .init("b"), .init("c")])
    }

    // MARK: - Propane

    func testEachAltitudeBurnsItsPropaneAndTheColdBurnsMore() {
        // The Sahara is warm: 0.95 of the altitude's gallons.
        for (pace, gal) in [(Pace.easy, 12.0), (.steady, 14), (.full, 16)] {
            var s = flying()
            s.pace = pace
            s.forceFair = 1
            let e = engine(s)
            _ = e.sailDay()
            XCTAssertEqual(e.state.fuel, 500 - gal * 0.95, accuracy: 1e-9, "\(pace)")
        }
        // The Himalaya in January is freezing: 1.2.
        var s = flying(mile: 6000)
        s.forceFair = 1
        let e = engine(s)
        XCTAssertEqual(e.state.temperature(in: e.state.region), .freezing)
        _ = e.sailDay()
        XCTAssertEqual(e.state.fuel, 500 - 14 * 1.2, accuracy: 1e-9)
    }

    func testTheLastOfThePropaneStillFliesAWatch() {
        var s = flying()
        s.fuel = 5
        s.forceFair = 1
        let e = engine(s)
        let q = e.sailDay()
        XCTAssertEqual(e.state.fuel, 0)
        XCTAssertGreaterThan(e.state.mile - 1000, 150)
        XCTAssertEqual(e.state.hull, 100 - BalloonData.seep, accuracy: 1e-9)
        XCTAssertTrue(messages(q).contains(balloon.text.outOfFuel))
    }

    func testDryTanksDriftOnTheHeliumAndSink() {
        var s = flying()
        s.fuel = 0
        s.forceFair = 1
        let e = engine(s)
        _ = e.sailDay()
        // 40 nm × steady × the top of the jitter, whatever the altitude.
        XCTAssertEqual(e.state.mile - 1000, 46)
        XCTAssertEqual(e.state.hull, 100 - BalloonData.seep - 5, accuracy: 1e-9)
        XCTAssertFalse(e.state.note.isEmpty)

        // Loitering dry sinks too, and at the bottom you come down.
        s.hull = 4
        let low = engine(s)
        let q = low.passDays(1, .sea)
        XCTAssertTrue(low.state.over)
        guard case .gameOver(let title, _)? = q.last else { return XCTFail("no ending") }
        XCTAssertEqual(title, "The [i]Skylark[/i] has come down.")
    }

    func testLoiteringBurnsTenAWatchAndTheGroundNothing() {
        let e = engine(flying())
        _ = e.passDays(1, .sea)
        XCTAssertEqual(e.state.fuel, 500 - 10 * 0.95, accuracy: 1e-9)

        let ground = engine(landed("lux"))
        _ = ground.passDays(2, .port)
        XCTAssertEqual(ground.state.fuel, 500)
        XCTAssertEqual(ground.state.hull, 100)
    }

    // MARK: - Launching

    func testTheLaunchNeedsFoodAndTwentyFiveGallonsAndBurnsThem() {
        var s = GameState(journey: Balloon.id, role: .merchant, ship: "Skylark", captain: "Anna",
                          crew: ["Bruno", "Claire", "Dieter", "Elena"], startYear: 1999, startMonth: 0)
        s.food = 100
        s.fuel = 20
        XCTAssertNil(engine(s).depart())
        s.fuel = 100
        let e = engine(s)
        XCTAssertEqual(e.depart()?.contains("at 0800 GMT on January 1, 1999."), true)
        XCTAssertEqual(e.state.fuel, 75)
        // Resuming the flight between fields costs nothing.
        e.setSail()
        XCTAssertEqual(e.state.fuel, 75)
        XCTAssertNil(e.state.vars[BalloonData.relaunchKey])
    }

    func testARelaunchBurnsTwentyFiveGallonsAndSaysSo() {
        var s = landed("lux")
        s.fuel = 100
        s.forceFair = 1
        let e = engine(s)
        e.setSail()
        XCTAssertEqual(e.state.fuel, 75)
        _ = e.sailDay()
        XCTAssertEqual(e.state.note, "Relaunched. The climb back to cruising height burned 25 gallons.")
        XCTAssertNil(e.state.vars[BalloonData.relaunchKey])
    }

    func testTheGroundTeamPaysForTheClimbOnlyWhenYouCannot() {
        var s = landed("lux")
        s.fuel = 10
        s.money = 1000
        XCTAssertNotNil(Balloon.relaunchRefusal(engine(s)))

        s.money = 20
        let broke = engine(s)
        XCTAssertNil(Balloon.relaunchRefusal(broke))
        broke.setSail()
        XCTAssertEqual(broke.state.fuel, 0)
        broke.state.forceFair = 1
        let said = messages(broke.sailDay())
        XCTAssertEqual(said.count, 3, "\(said)")
        XCTAssertTrue(said[0].contains("+15 gallons."))
        XCTAssertEqual(said[2], balloon.text.outOfFuel)

        s.fuel = 30
        XCTAssertNil(Balloon.relaunchRefusal(engine(s)))

        // Aloft past a field there is nothing to refuse: resuming the flight costs nothing.
        var aloft = flying(mile: 2600)
        aloft.fuel = 10
        aloft.money = 1000
        let a = engine(aloft)
        XCTAssertEqual(a.currentPort?.id, "lux")
        XCTAssertNil(Balloon.relaunchRefusal(a))
    }

    func testTheGroundTeamsTopUpIsCountedToATenth() {
        for (fuel, said) in [(24.3, "(+0.7 gallons.)"), (10.5, "(+14.5 gallons.)"), (24.0, "(+1 gallon.)")] {
            var s = landed("kh")
            s.fuel = fuel
            s.money = 0
            s.forceFair = 1
            let e = engine(s)
            e.setSail()
            let first = messages(e.sailDay())[0]
            XCTAssertTrue(first.contains(said), first)
        }
    }

    // MARK: - Where and when

    func testTheGroundIsTheFieldsOwnPlace() {
        // Luxor sits on the edge of hot Arabia; on the field it is warm.
        let s = landed("lux")
        XCTAssertEqual(s.region.id, "arabia")
        XCTAssertEqual(s.temperature(in: s.region), .warm)
        var aloft = s
        aloft.atPort = false
        XCTAssertEqual(aloft.temperature(in: aloft.region), .hot)

        let e = engine(landed("abq"))
        XCTAssertEqual(balloon.sickPool(e, .cold, balloon.port("abq")), BalloonData.groundPool)
        XCTAssertEqual(balloon.sickPool(e, .cool, balloon.port("saga")), BalloonData.fluFieldPool)
        XCTAssertEqual(balloon.sickPool(e, .hot, nil), BalloonData.hotPool)
        XCTAssertEqual(balloon.sickPool(e, .freezing, nil), BalloonData.coldPool)
        XCTAssertEqual(balloon.sickPool(e, .warm, nil), BalloonData.mildPool)
    }

    func testTheSeasonMovesTheJetAndTheCold() {
        let himalaya = region("himalaya")
        XCTAssertEqual(balloon.temperature(flying(month: 0), in: himalaya), .freezing)
        XCTAssertEqual(balloon.temperature(flying(month: 10), in: himalaya), .cold)
        XCTAssertEqual(balloon.temperature(flying(month: 2), in: region("atlantic")), .cold)
        XCTAssertEqual(balloon.temperature(flying(month: 3), in: region("atlantic")), .cool)

        func odds(_ month: Int, _ id: RegionID, _ w: Weather, cursed: Bool = false) -> Double {
            balloon.weatherWeights(engine(flying(month: month)), region(id), cursed: cursed).first { $0.0 == w }?.1 ?? 0
        }
        XCTAssertEqual(odds(0, "plains", BalloonData.jet), 26)
        XCTAssertEqual(odds(10, "plains", BalloonData.jet), 26 * 0.6, accuracy: 1e-9)
        XCTAssertEqual(odds(10, "plains", BalloonData.storm), 12)
        XCTAssertEqual(odds(2, "plains", BalloonData.jet), 13)
        XCTAssertEqual(odds(2, "plains", BalloonData.stalled), 8)
        XCTAssertEqual(odds(0, "atlantic", BalloonData.shear), 24)
        XCTAssertEqual(odds(0, "sahara", BalloonData.jet), 18)
        XCTAssertEqual(odds(10, "sahara", BalloonData.jet), 18, "no jet rules off the jet")
        XCTAssertEqual(odds(0, "sahara", BalloonData.storm, cursed: true), 15)
    }

    func testTheSouthernTrackReplacesTheNorthernPacific() {
        var s = flying(mile: 9000)
        XCTAssertEqual(s.region.id, "npacific")
        s.vars[BalloonData.southKey] = 1
        XCTAssertEqual(s.region.id, "southtrack")
        XCTAssertEqual(s.region(at: 11000).id, "subtropic")
        XCTAssertEqual(s.region(at: 7799).id, "eastchina")
        XCTAssertEqual(s.region(at: 12600).id, "southwest")
    }

    // MARK: - Lift and burners

    func testLiftSeepsAndTheWeatherTearsIt() {
        let e = engine(flying(), [0])
        XCTAssertEqual(balloon.structureDamage(e, region("sahara")), BalloonData.seep, accuracy: 1e-9)

        var s = flying(mile: 9000)
        s.weather = BalloonData.storm
        s.pace = .full
        let storm = engine(s, [0])
        XCTAssertEqual(balloon.structureDamage(storm, region("npacific")), BalloonData.seep + 1 * 1.6 * 1.5, accuracy: 1e-9)

        s.weather = BalloonData.snow
        XCTAssertEqual(balloon.structureDamage(engine(s, [0]), region("npacific")), BalloonData.seep + 0.5, accuracy: 1e-9)
        XCTAssertEqual(balloon.structureDamage(engine(s, [0]), region("himalaya")), BalloonData.seep, accuracy: 1e-9)
    }

    func testRimeMeltsIntoTheWaterJugs() {
        var s = flying()
        s.water = 50
        s.weather = BalloonData.snow
        let e = engine(s, [0])
        var q: [Interrupt] = []
        e.consume(&q, .sea)
        XCTAssertEqual(e.state.water, 50 - 1 + 2, accuracy: 1e-9)
        XCTAssertEqual(e.state.note, "Melted 2 gallons of rime off the hatch rim.")
    }

    func testRepairsAloftFollowTheRole() {
        var s = flying(role: .shipwright)
        s.hull = 50
        s.sails = 50
        let e = engine(s)
        _ = e.patchHull()
        _ = e.mendSails()
        XCTAssertEqual(e.state.hull, 80)
        XCTAssertEqual(e.state.sails, 85)
        XCTAssertEqual(balloon.role(.merchant).patch, 20)
        XCTAssertEqual(balloon.role(.whaler).catchLimit, 60)
    }

    // MARK: - Coming down

    func testComingDownInTheSeaOrOnLand() {
        XCTAssertEqual(balloon.wreckedBody(flying(mile: 9000)), Balloon.downAtSea)
        XCTAssertEqual(balloon.wreckedBody(flying(mile: 1000)), Balloon.downOnLand)

        XCTAssertEqual(balloon.leaderDiedBody(landed("saga")), Balloon.onTheGround)
        var s = flying()
        XCTAssertEqual(balloon.leaderDiedBody(s), Balloon.aloftWithCrew)
        for i in s.crew.indices { s.crew[i].alive = false }
        XCTAssertEqual(balloon.leaderDiedBody(s), Balloon.aloftAlone)
    }

    func testWhenTheWholeCrewDiesInOneWatchNobodyLandsHer() {
        var s = flying(mile: 9000)
        for i in s.crew.indices { s.crew[i].hp = i == 2 ? 3 : 0 }
        let e = engine(s)
        var q: [Interrupt] = []
        e.deaths(&q)
        guard case .gameOver(_, let body)? = q.last else { return XCTFail("no ending") }
        XCTAssertEqual(body, Balloon.aloftWithCrew, "Claire is still on her feet")

        for i in s.crew.indices { s.crew[i].hp = -1 }
        let all = engine(s)
        q = []
        all.deaths(&q)
        guard case .gameOver(_, let none)? = q.last else { return XCTFail("no ending") }
        XCTAssertEqual(none, Balloon.aloftAlone)
    }

    func testTheLastNinetyMilesAreMoroccoNotTheSea() {
        XCTAssertTrue(flying(mile: 18200).region.has("sea"))
        let land = flying(mile: 18250)
        XCTAssertEqual(land.region.id, "morocco")
        XCTAssertEqual(balloon.wreckedBody(land), Balloon.downOnLand)
        XCTAssertEqual(balloon.wreckedTitle(land), "The [i]Skylark[/i] has come down.")
        XCTAssertEqual(engine(land).fishingRefusal, "There's no sea below you to fish in.")
    }

    // MARK: - The region rolls

    func testTheSouthernTrackThrowsThunderstormsAndTheForecastersDodgeMost() {
        var s = flying(mile: 9000)
        s.vars[BalloonData.southKey] = 1
        s.day = 50
        let e = engine(s, [0.03, 0])
        var q: [Interrupt] = []
        balloon.dayEvents(e, &q, e.state.region)
        XCTAssertEqual(e.state.hull, 85)
        XCTAssertEqual(e.state.day, 51)
        XCTAssertEqual(e.state.weather, BalloonData.storm)
        XCTAssertEqual(e.state.fuel, 500 - 14 * 0.95, accuracy: 1e-9)
        XCTAssertEqual(messages(q).count, 1)

        s.vars[BalloonData.forecastKey] = 1
        let forecast = engine(s, [0.03])
        q = []
        balloon.dayEvents(forecast, &q, forecast.state.region)
        XCTAssertEqual(forecast.state.hull, 100)
        XCTAssertTrue(q.isEmpty)
    }

    func testTheIcedRoofOfTheNorthPacific() {
        let e = engine(flying(mile: 9000), [0.01, 0, 0])
        var q: [Interrupt] = []
        balloon.dayEvents(e, &q, e.state.region)
        XCTAssertEqual(e.state.crew[1].hp, 75)
        XCTAssertTrue(messages(q)[0].hasPrefix("Bruno climbs out"))

        let slip = engine(flying(mile: 9000), [0.01, 0, 0.9, 0])
        q = []
        balloon.dayEvents(slip, &q, slip.state.region)
        XCTAssertEqual(slip.state.crew[1].hp, 80)
        XCTAssertEqual(slip.state.crew[1].ailment, BalloonData.brokenArm)
        XCTAssertEqual(slip.state.crew[1].ailDays, 14)
        XCTAssertEqual(slip.state.meds, 2, "no kit for a fall")

        // Nobody goes out on the roof over the Sahara: the same draw is the event roll.
        let sahara = engine(flying(), [0.015])
        q = []
        balloon.dayEvents(sahara, &q, sahara.state.region)
        XCTAssertTrue(sahara.state.crew.allSatisfy { $0.hp == 100 && $0.ailment == nil })
    }

    // MARK: - Set pieces

    func testClimbingOverTheHimalayaGainsMilesAndCostsTheCold() {
        var s = flying(mile: 5050)
        s.clothes = 3
        let e = engine(s)
        guard let c = choice(e.beginArrival("him")) else { return XCTFail("no choice") }
        XCTAssertTrue(c.options[0].enabled)
        _ = e.resolve(c, option: 0)
        XCTAssertEqual(e.state.mile, 5250)
        XCTAssertEqual(e.state.fuel, 465)
        XCTAssertEqual(e.state.crew.map(\.hp), [97, 97, 97, 87, 87])
        XCTAssertEqual(e.state.sails, 100)

        s.fuel = 30
        guard let no = choice(engine(s).beginArrival("him")) else { return XCTFail("no choice") }
        XCTAssertFalse(no.options[0].enabled)
        XCTAssertTrue(no.options[1].enabled)
        XCTAssertTrue(no.options[0].label.hasPrefix("Climb over the range"))
    }

    func testInTheJetAlreadyYouHoldItOverTheRange() {
        var s = flying(mile: 5050)
        s.pace = .full
        let e = engine(s)
        guard let c = choice(e.beginArrival("him")) else { return XCTFail("no choice") }
        XCTAssertEqual(c.options[0].label, "Hold the jet over the range (35 gal)")
        let said = messages(e.resolve(c, option: 0))[0]
        XCTAssertTrue(said.hasPrefix("You burn hard to hold your height over the summits"), said)
        XCTAssertFalse(said.contains("climb"), said)
    }

    func testTheForkAndTheForecasters() {
        var s = flying(mile: 7800, month: 10)
        s.money = 300
        let e = engine(s)
        guard let fork = choice(e.beginArrival("pacific")) else { return XCTFail("no fork") }
        XCTAssertTrue(fork.prompt.contains("[red]The jet is weak"))
        let advice = e.resolve(fork, option: 2)
        XCTAssertEqual(messages(advice).count, 1)
        XCTAssertNotNil(choice(advice))

        guard let offer = choice(e.resolve(fork, option: 1)) else { return XCTFail("no offer") }
        XCTAssertEqual(e.state.vars[BalloonData.southKey], 1)
        XCTAssertTrue(offer.options[0].enabled)
        _ = e.resolve(offer, option: 0)
        XCTAssertEqual(e.state.money, 50)
        XCTAssertEqual(e.state.vars[BalloonData.forecastKey], 1)
        XCTAssertEqual(choice(e.resolve(fork, option: 1))?.options[0].enabled, false)

        _ = e.resolve(fork, option: 0)
        XCTAssertNil(e.state.vars[BalloonData.southKey])
    }

    func testLandfallSaysWhichCoast() {
        XCTAssertEqual(messages(engine(flying(mile: 12600)).beginArrival("landfall")), [BalloonData.landfallNorth])
        var s = flying(mile: 12600)
        s.vars[BalloonData.southKey] = 1
        XCTAssertEqual(messages(engine(s).beginArrival("landfall")), [BalloonData.landfallSouth])
    }

    func testTheDateLinePartyCostsAWatchPropaneAndCake() {
        var s = flying(mile: 10050)
        for i in s.crew.indices { s.crew[i].hp = 80 }
        let e = engine(s)
        _ = e.resolve(ask("dateline"), option: 0)
        XCTAssertEqual(e.state.day, 1)
        XCTAssertEqual(e.state.fuel, 485)
        XCTAssertEqual(e.state.food, 197)
        XCTAssertTrue(e.state.living.allSatisfy { $0.hp == 88 })
    }

    func testTheAzoresBoatAirsTheCapsuleAndCuresStaleAir() {
        var s = flying(mile: 17350)
        s.noCitrus = 30
        s.crew[2].ailment = BalloonData.staleAir
        let e = engine(s, [0, 0])
        let q = e.resolve(ask("azores"), option: 0)
        XCTAssertEqual(e.state.day, 2)
        XCTAssertNil(e.state.crew[2].ailment)
        XCTAssertEqual(e.state.noCitrus, 0)
        XCTAssertTrue(messages(q)[0].contains("+20 gallons of water, +10 lbs of rations."))
        XCTAssertEqual(e.state.fuel, 500 - 2 * 10 * 0.95, accuracy: 1e-9)
    }

    func testTheAzoresBoatNeedsCalmAir() {
        var s = flying(mile: 17350)
        s.weather = BalloonData.storm
        guard let rough = choice(engine(s).beginArrival("azores")) else { return XCTFail("no choice") }
        XCTAssertFalse(rough.options[0].enabled)
        XCTAssertTrue(rough.options[1].enabled)
        XCTAssertTrue(rough.detail?.contains("far too rough") == true)

        s.weather = BalloonData.steady
        guard let calm = choice(engine(s).beginArrival("azores")) else { return XCTFail("no choice") }
        XCTAssertTrue(calm.options[0].enabled)
    }

    // MARK: - Choices

    func testThunderheadsAroundCostAWatchAndThroughCanCostLift() {
        let around = engine(flying())
        _ = around.resolve(ask("thunderheads"), option: 0)
        XCTAssertEqual(around.state.day, 1)
        XCTAssertEqual(around.state.fuel, 500 - 14 * 0.95, accuracy: 1e-9)
        XCTAssertEqual(around.state.hull, 100)

        var s = flying()
        s.pace = .full
        let through = engine(s, [0.26, 0])
        _ = through.resolve(ask("thunderheads"), option: 1)
        XCTAssertEqual(through.state.hull, 82, "the jet adds 15 points to the 12% risk")
    }

    func testIceOnTheEnvelopeAndTheMascot() {
        let climb = engine(flying())
        _ = climb.resolve(ask("ice"), option: 0)
        XCTAssertEqual(climb.state.fuel, 460)
        let ride = engine(flying(), [0])
        _ = ride.resolve(ask("ice"), option: 1)
        XCTAssertEqual(ride.state.hull, 95)

        var s = flying()
        s.hull = 90
        let drop = engine(s)
        _ = drop.resolve(ask("mascot"), option: 1)
        XCTAssertEqual(drop.state.hull, 91)
        XCTAssertEqual(drop.state.badLuck, 25)
    }

    func testTheCameraPlaneCannotClimbToTheJet() {
        func cameraCanCome(_ pace: Pace) -> Bool {
            var s = flying(mile: 14000)
            s.pace = pace
            s.weather = BalloonData.steady
            let e = engine(s)
            return balloon.events(e, e.state.region).contains { ev in
                guard ev.ok else { return false }
                var q: [Interrupt] = []
                ev.run(engine(s), &q)
                if case .custom(let key, _)? = choice(q)?.kind { return key == "camera" }
                return false
            }
        }
        XCTAssertTrue(cameraCanCome(.steady))
        XCTAssertTrue(cameraCanCome(.easy))
        XCTAssertFalse(cameraCanCome(.full))
    }

    func testTheCameraPlanePaysOrShakesYou() {
        let paid = engine(flying(), [0, 0])
        _ = paid.resolve(ask("camera"), option: 0)
        XCTAssertEqual(paid.state.money, 15000 + 300)
        let shaken = engine(flying(), [0.9])
        _ = shaken.resolve(ask("camera"), option: 0)
        XCTAssertEqual(shaken.state.hull, 92)
        XCTAssertEqual(shaken.state.sails, 88)
    }

    /// Through the freighter's own answer: whatever she offers comes up a trail line.
    func testTheFreighterNeverTradesPropaneBallastOrWater() {
        var offers = 0
        var propaneElsewhere = false
        for seed in UInt64(0)..<300 {
            var s = flying(mile: 9000)
            s.fuel = 400
            s.water = 40
            s.timber = 10
            let e = GameEngine(state: s, rng: SeededRNG(seed: seed))
            if let o = GameEngine(state: s, rng: SeededRNG(seed: seed)).makeOffer(), o.give == .item(.fuel) {
                propaneElsewhere = true
            }
            guard case .tradeOffer(let o, _)? = choice(e.resolve(ask("freighter"), option: 0))?.kind else { continue }
            offers += 1
            for g in [o.give, o.want] {
                XCTAssertNotEqual(g, .item(.fuel))
                XCTAssertNotEqual(g, .item(.timber))
                XCTAssertNotEqual(g, .item(.water))
            }
        }
        XCTAssertGreaterThan(offers, 100)
        XCTAssertTrue(propaneElsewhere, "a field's trader can offer propane in the same state")
    }

    /// A trader never hands over more than there is room for, so a trade never pays for
    /// goods that would be thrown away.
    func testNoOfferGivesMoreThanThereIsRoomFor() {
        var offers = 0
        var cut = 0
        for seed in UInt64(0)..<400 {
            for landedAt in [false, true] {
                var s = landedAt ? landed("abq") : flying(mile: 9000)
                s.water = 40
                s.fuel = 900
                s.food = 390
                s.meds = 9
                s.limes = 22
                let e = GameEngine(state: s, rng: SeededRNG(seed: seed))
                guard let o = e.makeOffer() else { continue }
                offers += 1
                XCTAssertNotEqual(o.give, .item(.water))
                XCTAssertNotEqual(o.want, .item(.water))
                XCTAssertGreaterThan(o.wantAmount, 0)
                guard case .item(let k) = o.give else { continue }
                XCTAssertGreaterThan(o.giveAmount, 0)
                XCTAssertLessThanOrEqual(Double(o.giveAmount), balloon.item(k).cap - s[k], "\(o)")
                if Double(o.giveAmount) == balloon.item(k).cap - s[k] { cut += 1 }
            }
        }
        XCTAssertGreaterThan(offers, 300)
        XCTAssertGreaterThan(cut, 20, "big offers are cut, not dropped")
    }

    func testAnOfferTooBigIsCutToFitAndItsPriceWithIt() {
        var s = flying()
        s.fuel = 900
        s.meds = 5
        let e = engine(s)
        let big = Offer(give: .item(.fuel), giveAmount: 1200, want: .item(.meds), wantAmount: 10)
        XCTAssertEqual(balloon.fitOffer(e, big), Offer(give: .item(.fuel), giveAmount: 300, want: .item(.meds), wantAmount: 3))
        let small = Offer(give: .item(.fuel), giveAmount: 300, want: .money, wantAmount: 150)
        XCTAssertEqual(balloon.fitOffer(e, small), small)
        e.applyTrade(balloon.fitOffer(e, big)!)
        XCTAssertEqual(e.state.fuel, 1200)
        XCTAssertEqual(e.state.meds, 2)

        s.food = 495
        XCTAssertNil(balloon.fitOffer(engine(s), Offer(give: .item(.food), giveAmount: 50, want: .money, wantAmount: 300)),
                     "not one 10-lb unit fits")
        XCTAssertEqual(balloon.fitOffer(engine(s), Offer(give: .money, giveAmount: 50, want: .item(.meds), wantAmount: 1))?.giveAmount, 50)
    }

    // MARK: - Fishing

    func testFishingWantsLineTheSeaAndCalmAir() {
        XCTAssertNil(engine(flying(mile: 9000)).fishingRefusal)
        XCTAssertEqual(engine(flying(mile: 1000)).fishingRefusal, "There's no sea below you to fish in.")
        var s = flying(mile: 9000)
        s.weather = BalloonData.shear
        XCTAssertEqual(engine(s).fishingRefusal, balloon.text.tooRough)
        s.tackle = 0
        XCTAssertEqual(engine(s).fishingRefusal, balloon.text.noTackle)
    }

    func testFishingFillsTheLockerAndAirsTheCapsule() {
        var s = flying(mile: 9000)
        s.limes = 0
        s.noCitrus = 30
        let e = engine(s)
        let q = e.landCatch(70)
        XCTAssertEqual(e.state.food, 200 + 40 - 2.5, accuracy: 1e-9)
        XCTAssertEqual(e.state.noCitrus, 1, "aired, then a watch without scrubbers")
        XCTAssertEqual(messages(q)[0], "You caught [amber]70 lbs[/amber] of fish. The cool box holds 40 lbs before the rest goes bad. [green]+40 lbs of rations.[/green] [dim]The capsule is aired out. A watch has passed.[/dim]")
    }

    // MARK: - Trade and score

    func testTradeTalksInGallonsSacksAndSpools() {
        XCTAssertEqual(balloon.describe(.item(.fuel), 450), "450 gallons of propane")
        XCTAssertEqual(balloon.describe(.item(.timber), 1), "1 sack of ballast")
        XCTAssertEqual(balloon.describe(.item(.tackle), 40), "2 spools of fishing line")
        XCTAssertEqual(balloon.describe(.item(.tackle), 37), "37 casts of fishing line")
        XCTAssertEqual(balloon.describe(.item(.meds), 3), "3 medical kits")
        XCTAssertEqual(balloon.describe(.item(.limes), 2), "2 scrubber canisters")
        XCTAssertEqual(balloon.describe(.money, 1250), "$1,250")
        XCTAssertEqual(balloon.roundTrade(.money, 420), 400)
        XCTAssertEqual(balloon.roundTrade(.item(.fuel), 123), 120)
        XCTAssertEqual(balloon.roundTrade(.item(.tackle), 31), 40)
    }

    func testTheScore() {
        var s = flying()
        s.fuel = 120
        s.food = 55
        s.water = 60
        s.limes = 3.7
        s.meds = 1
        s.clothes = 5
        s.sailcloth = 2
        s.timber = 2
        s.tackle = 45
        s.money = 1000
        s.hull = 70
        s.sails = 60
        let sc = balloon.score(s)
        XCTAssertEqual(sc.lines.map(\.points), [2500, 200, 2 + 5 + 1, 3 + 5 + 10 + 8 + 6 + 2, 20])
        XCTAssertEqual(sc.multiplier, 1)
        XCTAssertEqual(balloon.rank(7000), "Master Aeronaut")
        XCTAssertEqual(balloon.rank(1999), "Ballast")
    }

    func testTheFinaleCountsDaysAndHours() {
        var s = flying(mile: 18300)
        s.day = 160
        let f = Balloon.finale(s)
        XCTAssertTrue(f.contains("at 0000 GMT on January 28, 1999 — 26 days and 16 hours after you lifted off."), f)
        s.day = 162
        let whole = Balloon.finale(s)
        XCTAssertTrue(whole.contains("at 0800 GMT on January 28, 1999 — 27 days after you lifted off."), whole)
        XCTAssertTrue(Balloon.shortfall(flying(mile: 17000)).hasSuffix("17,000 nautical miles flown, 1,300 short of the finish line."))
    }

    // MARK: - Balance

    /// The sensible flier of the spec (§18.2), as far as `JourneyBot` can fly it: the
    /// chocolate maker in the middle air throughout, the others in the jet while the crew is
    /// well, the air not freezing and the tanks not dry, and the middle air otherwise; hot meals for the chocolate maker and half portions for the others; for
    /// each leg, food, half again the water, propane and scrubbers for nm ÷ (the speed of
    /// the altitude last flown × 0.6) + 12 watches; two each of medical kits, burner kits and ballast; line for the two poorer
    /// roles; supplies before the riggers, who are hired below 70%. North or south at
    /// random, the forecasters only with $1,500 to spare; stays south of the Himalaya,
    /// holds the party, meets the Azores boat, waves off the freighter and the camera plane.
    static func policy(departure: Int = 2) -> JourneyBot.Policy {
        var p = JourneyBot.Policy()
        p.departure = departure
        p.rations = [.merchant: .filling, .shipwright: .meager, .whaler: .meager]
        p.speedShare = 0.6
        p.marginTurns = 12
        p.stockFactor = [.water: 1.5]
        p.spares = [(.meds, 2), (.sailcloth, 2), (.timber, 2)]
        p.tackle = [.shipwright: 60, .whaler: 60]
        p.forageBelowTurns = [.shipwright: 12, .whaler: 12]
        p.hitChance = [.shipwright: 0.35, .whaler: 0.55]
        p.mendBelow = 40
        p.yardBelow = 70
        p.yardAfterShop = true
        p.choosePace = { e in
            let s = e.state
            if s.role == .merchant { return .steady }
            return s.averageHP >= 75 && s.temperature(in: s.region) != .freezing && s.fuel > 0 ? .full : .steady
        }
        p.decide = { e, c in
            if case .tradeOffer = c.kind { return 1 }
            guard case .custom(let key, _) = c.kind else { return nil }
            switch key {
            case "fork": return e.chance(0.5) ? 0 : 1
            case "forecast": return e.state.money > 1500 ? 0 : 1
            case "him", "freighter", "camera": return 1
            default: return nil
            }
        }
        return p
    }

    /// January is a month the meteorologist recommends (December and February fly the
    /// same). The chocolate maker should nearly always get round, the builder usually, the
    /// bush pilot about half the time, in about four weeks.
    func testJanuaryBalanceStaysInItsBands() {
        XCTAssertEqual(BalloonData.departures[2].month, 0)
        let r = JourneyBot.survey(balloon, count: 30, seed: 500, policy: Self.policy())
        print(r.report)
        XCTAssertGreaterThanOrEqual(r.rates[.merchant] ?? 0, 0.85, r.report)
        XCTAssertGreaterThanOrEqual(r.rates[.shipwright] ?? 0, 0.6, r.report)
        XCTAssertLessThanOrEqual(r.rates[.shipwright] ?? 1, 0.9 + 1e-9, r.report)
        XCTAssertGreaterThanOrEqual(r.rates[.whaler] ?? 0, 0.35, r.report)
        XCTAssertLessThanOrEqual(r.rates[.whaler] ?? 1, 0.7, r.report)
        XCTAssertTrue((145...180).contains(r.medianTurns), r.report)
    }

    /// The jet is weak in November and breaking up in March.
    func testNovemberAndMarchAreHarder() {
        let january = JourneyBot.survey(balloon, count: 30, seed: 500, policy: Self.policy())
        let november = JourneyBot.survey(balloon, count: 30, seed: 500, policy: Self.policy(departure: 0))
        let march = JourneyBot.survey(balloon, count: 30, seed: 500, policy: Self.policy(departure: 4))
        print(november.report + "\n" + march.report)
        for role in [Role.shipwright, .whaler] {
            XCTAssertLessThan(november.rates[role] ?? 1, (january.rates[role] ?? 0) - 0.1, november.report)
            XCTAssertLessThan(march.rates[role] ?? 1, (january.rates[role] ?? 0) - 0.3, march.report)
        }
        XCTAssertGreaterThan(march.medianTurns, january.medianTurns + 10, march.report)
    }

    /// Low and slow is gentle on everything but the clock and the propane.
    func testFlyingLowAllTheWayIsAMistake() {
        let middle = JourneyBot.survey(balloon, count: 30, seed: 500, policy: Self.policy())
        var p = Self.policy()
        p.choosePace = nil
        p.pace = .easy
        let low = JourneyBot.survey(balloon, count: 30, seed: 500, policy: p)
        print(low.report)
        for role in [Role.shipwright, .whaler] {
            XCTAssertLessThan(low.rates[role] ?? 1, (middle.rates[role] ?? 0) - 0.2, low.report)
        }
    }

    /// Some losses come down for want of lift and some are the pilot's death, and neither
    /// kind is a single cause.
    func testLosingFlightsEndMoreThanOneWay() {
        var comeDown = Set<String>()
        var died = Set<String>()
        for role in [Role.shipwright, .whaler] {
            for i in 0..<30 {
                let r = JourneyBot(journey: balloon, role: role, seed: 500 + UInt64(1000 * role.scoreMultiplier + i),
                                   policy: Self.policy()).play()
                if r.won { continue }
                if r.ending.contains("has come down") { comeDown.insert(r.ending) } else if r.ending.contains("have died of") { died.insert(r.ending) }
            }
        }
        XCTAssertFalse(comeDown.isEmpty, "no flight came down: \(died)")
        XCTAssertGreaterThanOrEqual(died.count, 2, "\(died)")
        XCTAssertGreaterThanOrEqual(comeDown.count + died.count, 3, "\(comeDown) \(died)")
    }
}
