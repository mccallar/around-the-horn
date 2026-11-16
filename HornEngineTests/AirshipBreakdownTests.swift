import XCTest
@testable import HornEngine

/// Over the Pole's two meters at nought, and the tanks dry (docs/journeys/airship.md, "As
/// built", D14): no meter below 0, engines that have given out drift and burn nothing, lift
/// that has gone sends her down unless something goes over the side, and a ship adrift says
/// so and pays for it in gas.
final class AirshipBreakdownTests: XCTestCase {
    let airship = Journeys.journey(Airship.id)
    var air: Airship { airship as! Airship }

    /// A meter as the status panel writes it (`StatusPanel`: `Int(jsRounded(x))`), keeping
    /// the sign a negative zero would carry.
    static func shown(_ x: Double) -> String {
        let r = jsRound(x)
        return (r.sign == .minus ? "-" : "") + "\(Int(abs(r)))%"
    }

    /// The most a watch adrift can make: 60 km in a following wind, full lift, the top of
    /// the jitter.
    static let driftMost = Int(jsRound(AirshipData.driftSpeed * AirshipData.tail.speed * 1.15))

    struct Trace {
        var log: [String] = []
        /// Every value the two meters and the crew's health were stored at after a watch.
        var stored: [Double] = []
        var shown: [String] = []
        /// Damage reports that said more was lost than the meter held.
        var overReported: [String] = []
        /// Kilometres flown on a watch begun with the lift showing 0%.
        var movedWithNoLift: [Int] = []
        /// Kilometres flown on a watch begun with the engines showing 0%, or the tanks dry.
        var movedAdrift: [Int] = []
        var endings: [String] = []
    }

    /// A seeded flight from Vadsø in May with no spares, no ballast and no money, meters worn
    /// as given and `fuel` kg of petrol, answering every question with its first offer.
    func run(seed: UInt64, fuel: Double, sails: Double = 20, hull: Double = 12, turns: Int = 150) -> Trace {
        var s = GameState(journey: Airship.id, role: .merchant, ship: "Kestrel", captain: "Arne",
                          crew: ["Ingrid", "Sigurd", "Solveig", "Olav"], startYear: 1926, startMonth: 4)
        s.mile = 4300
        s.stopIndex = airship.stops.lastIndex { $0.mile <= 4300 }!
        s.food = 2000
        s.water = 1200
        s.limes = 20
        s.clothes = 5
        s.fuel = fuel
        s.sails = sails
        s.hull = hull
        s.money = 0
        s.atPort = false
        let e = GameEngine(state: s, rng: SeededRNG(seed: seed))
        var t = Trace()
        func play(_ q: [Interrupt]) {
            var q = q
            while !q.isEmpty {
                switch q.removeFirst() {
                case .message(let m): t.log.append(m)
                case .choice(let c):
                    t.log.append(c.prompt)
                    q = e.resolve(c, option: c.options.firstIndex(where: \.enabled) ?? 0) + q
                case .burial(let id, let cause): e.commitBurial(crewID: id, cause: cause, epitaph: "")
                case .arrival(let id): q = e.beginArrival(id) + q
                case .enterPort: return
                case .gameOver(let title, _): t.endings.append(title); return
                case .finale: t.endings.append("arrived"); return
                }
            }
        }
        for _ in 0..<turns where !e.state.over {
            let km = e.state.mile, before = (lift: e.state.hull, engines: e.state.sails)
            let noLift = Airship.goingDown(e.state)
            let adrift = Airship.enginesOut(e.state) || e.state.fuel <= 0
            let n = t.log.count
            play(e.sailDay())
            if e.state.atPort { e.setSail() }
            for m in t.log[n...] {
                for (label, had) in [("Lift", before.lift), ("Engines", before.engines)] {
                    guard let r = m.range(of: "\(label) −") else { continue }
                    let lost = Double(m[r.upperBound...].prefix { $0.isNumber }) ?? 0
                    if lost > jsRound(had) { t.overReported.append("\(label) at \(Self.shown(had)): \(m)") }
                }
            }
            if noLift { t.movedWithNoLift.append(e.state.mile - km) } else if adrift { t.movedAdrift.append(e.state.mile - km) }
            t.stored += [e.state.sails, e.state.hull] + e.state.crew.filter(\.alive).map(\.hp)
            t.shown += [Self.shown(e.state.hull), Self.shown(e.state.sails)]
        }
        return t
    }

    /// The report from play on the Iron Road, checked here: a meter below 0, and no fuel
    /// moving just fine. Before the fix nothing was stored below 0, but the airship reported
    /// damage at a meter already at 0% ("Engines −18%" at 0%), engines at 0% drove her at
    /// 45% and burnt petrol, lift at 0% forced her down with ballast aboard, and the last
    /// few kilos of petrol powered a whole watch.
    func testNoMeterGoesBelowNoughtAndNothingFliesOnAsNormalAtNought() {
        var t = Trace()
        for seed: UInt64 in 1...90 {
            let r = run(seed: seed, fuel: [0, 2000, 120][Int(seed % 3)])
            t.stored += r.stored
            t.shown += r.shown
            t.overReported += r.overReported
            t.movedWithNoLift += r.movedWithNoLift
            t.movedAdrift += r.movedAdrift
            t.endings += r.endings
        }
        XCTAssertFalse(t.stored.contains { $0 < 0 || $0.sign == .minus }, "a value stored below 0")
        XCTAssertFalse(t.shown.contains { $0.hasPrefix("-") }, "a meter shown below 0")
        XCTAssertEqual(t.overReported.count, 0, "damage reported past nought: \(t.overReported.prefix(2))")
        XCTAssertGreaterThan(t.movedWithNoLift.count, 0, "some flight lost its lift")
        XCTAssertEqual(t.movedWithNoLift.filter { $0 > 0 }.count, 0, "flew on with no lift: \(t.movedWithNoLift.filter { $0 > 0 }.prefix(10))")
        XCTAssertGreaterThan(t.movedAdrift.count, 0, "some flight drifted")
        XCTAssertLessThanOrEqual(t.movedAdrift.max() ?? 0, Self.driftMost, "a watch adrift flew \(t.movedAdrift.max() ?? 0) km")
        XCTAssertTrue(t.endings.contains("The [i]Kestrel[/i] has been forced down."), "\(Set(t.endings))")
    }

    // MARK: - Engines at nought

    func flying(km: Int = 1000, sails: Double = 100, hull: Double = 100, fuel: Double = 4000,
                spares: Int = 0, ballast: Int = 0, money: Double = 0) -> GameState {
        var s = GameState(journey: Airship.id, role: .merchant, ship: "Kestrel", captain: "Arne",
                          crew: ["Ingrid", "Sigurd", "Solveig", "Olav"], startYear: 1926, startMonth: 4)
        s.mile = km
        s.stopIndex = airship.stops.lastIndex { $0.mile <= km } ?? 0
        s.food = 200
        s.water = 200
        s.limes = 10
        s.clothes = 5
        s.fuel = fuel
        s.sails = sails
        s.hull = hull
        s.sailcloth = spares
        s.timber = ballast
        s.money = money
        s.forceFair = 6
        s.atPort = false
        return s
    }

    func choice(_ q: [Interrupt]) -> ChoiceEvent? {
        for i in q { if case .choice(let c) = i { return c } }
        return nil
    }

    func messages(_ q: [Interrupt]) -> [String] {
        q.compactMap { if case .message(let t) = $0 { return t } else { return nil } }
    }

    func gameOver(_ q: [Interrupt]) -> (title: String, body: String)? {
        for i in q { if case .gameOver(let t, let b) = i { return (t, b) } }
        return nil
    }

    static let givenOut = "[red]The engines have given out.[/red]"

    func testEnginesAtNoughtDriftAndBurnNothing() {
        let e = engine(flying(sails: 0.4, spares: 1))
        XCTAssertTrue(Airship.enginesOut(e.state), "0.4 shows as 0%")
        let q = e.sailDay()
        XCTAssertTrue(Airship.drifting(e.state))
        XCTAssertEqual(e.state.fuel, 4000, "no petrol through engines that will not run")
        XCTAssertEqual(e.state.mile - 1000, 69, "60 km × fair × full lift × the top of the jitter")
        XCTAssertEqual(e.state.sails, 0.4, "and no wear")
        XCTAssertEqual(messages(q).filter { $0.hasPrefix(Self.givenOut) }.count, 1, "\(messages(q))")
        XCTAssertEqual(e.state.note, "Engines dead. You are going where the wind goes.")
        // Said once.
        XCTAssertFalse(messages(e.sailDay()).contains { $0.hasPrefix(Self.givenOut) })

        // A box of spares aloft, and the engines run again on the next watch.
        _ = e.mendSails()
        XCTAssertEqual(e.state.sails, 25.4, accuracy: 1e-9)
        let km = e.state.mile
        _ = e.sailDay()
        XCTAssertEqual(e.state.fuel, 3750)
        XCTAssertGreaterThan(e.state.mile - km, 150)
        XCTAssertFalse(Airship.drifting(e.state))
        XCTAssertNil(e.state.vars[AirshipData.enginesOutKey], "the warning is ready for next time")
    }

    func testEnginesWornToNoughtUnderWaySaySo() {
        // 0.6 shows 1%: a fair watch's wear takes it to nothing.
        let e = engine(flying(sails: 0.6))
        let q = e.sailDay()
        XCTAssertGreaterThan(e.state.mile - 1000, 100, "she flew this watch on what was left")
        XCTAssertEqual(e.state.sails, 0)
        XCTAssertTrue(messages(q).contains { $0.hasPrefix(Self.givenOut) }, "\(messages(q))")
        let km = e.state.mile, fuel = e.state.fuel
        _ = e.sailDay()
        XCTAssertLessThanOrEqual(e.state.mile - km, Self.driftMost)
        XCTAssertEqual(e.state.fuel, fuel)
    }

    /// Engine trouble needs engines that are running: a drifting ship has no backfire, no
    /// stalling engine and no ice flying off her propellers.
    func testEngineEventsNeedTheEnginesRunning() {
        func eligible(fuel: Double, sails: Double) -> [Bool] {
            var s = flying(km: 6000, sails: sails, fuel: fuel)
            s.weather = AirshipData.storm
            let e = engine(s)
            var sp = 0.0
            airship.adjustSpeed(e, e.state.region, &sp)
            let ev = airship.events(e, e.state.region)
            return [ev[4].ok, ev[5].ok, ev[8].ok]
        }
        XCTAssertEqual(eligible(fuel: 4000, sails: 50), [true, true, true])
        XCTAssertEqual(eligible(fuel: 0, sails: 50), [false, false, false])
        XCTAssertEqual(eligible(fuel: 4000, sails: 0), [false, false, false])
    }

    // MARK: - The tanks dry

    /// Adrift she makes a fraction of a powered watch, burns nothing, wears no engine and
    /// spends gas holding her height; the status panel says so (the skin's `trouble`).
    func testAWatchAdriftCostsGas() {
        let powered = engine(flying())
        let adrift = engine(flying(fuel: 0))
        _ = powered.sailDay()
        let q = adrift.sailDay()
        XCTAssertEqual(powered.state.hull, 100 - AirshipData.seep, accuracy: 1e-9)
        XCTAssertEqual(adrift.state.hull, 100 - AirshipData.seep - AirshipData.driftGas, accuracy: 1e-9)
        XCTAssertEqual(adrift.state.mile - 1000, 69)
        XCTAssertGreaterThan(powered.state.mile - 1000, 250)
        XCTAssertTrue(messages(q).contains(airship.text.outOfFuel))
        XCTAssertTrue(airship.text.outOfFuel.contains("spending gas to hold her height"))
        XCTAssertEqual(adrift.state.note, "Engines silent. You are going where the wind goes.")
    }

    // MARK: - Lift at nought

    static let goingDown = "[red]She is going down.[/red]"

    func testLiftAtNoughtWithBallastAboardIsAskedNotForcedDown() {
        let e = engine(flying(hull: 0.3, ballast: 1))
        XCTAssertTrue(Airship.goingDown(e.state), "0.3 shows as 0%")
        guard let ask = choice(e.sailDay()) else { return XCTFail("not asked") }
        XCTAssertFalse(e.state.over)
        XCTAssertEqual(e.state.day, 0, "no time passes for asking")
        XCTAssertEqual(e.state.mile, 1000)
        XCTAssertTrue(ask.prompt.hasPrefix(Self.goingDown), ask.prompt)
        XCTAssertTrue(ask.prompt.contains("sinking toward the ground"), "France is land: \(ask.prompt)")
        XCTAssertEqual(ask.options.map(\.label), ["Drop a bag of ballast [dim](have 1)[/dim]",
                                                 "Open the dump valves: 300 kg of petrol [dim](have 4,000 kg)[/dim]"])
        XCTAssertTrue(ask.options.allSatisfy(\.enabled))
        XCTAssertEqual(choice(e.sailDay()), ask, "asked again, the same question")

        let q = e.resolve(ask, option: 0)
        XCTAssertEqual(e.state.timber, 0)
        XCTAssertEqual(e.state.hull, 20.3, accuracy: 1e-9)
        XCTAssertEqual(e.state.day, 1, "a watch to trim her")
        XCTAssertEqual(messages(q).last, airship.text.patched(20))
        XCTAssertFalse(Airship.goingDown(e.state))
        _ = e.sailDay()
        XCTAssertGreaterThan(e.state.mile, 1000, "and she flies on")
    }

    /// Worn to nothing in a watch, she is asked in that watch, and nothing else happens to
    /// her first.
    func testLiftWornToNoughtInAWatchAsksThere() {
        // 0.6 shows 1%: the watch's seep takes it to 0.45, which shows 0%.
        let e = engine(flying(km: 6000, hull: 0.6, ballast: 2), [], fallback: 0)
        let q = e.sailDay()
        XCTAssertNil(gameOver(q), "not forced down with ballast aboard")
        XCTAssertFalse(e.state.over)
        guard let ask = choice(q) else { return XCTFail("not asked: \(q)") }
        XCTAssertTrue(ask.prompt.contains("sinking toward the ice"), ask.prompt)
        XCTAssertEqual(q.filter { if case .choice = $0 { return true } else { return false } }.count, 1, "no event as well")
    }

    func testThePetrolDumpBuysTenPointsForThreeHundredKilos() {
        let e = engine(flying(km: 2000, hull: 0, fuel: 1000))
        guard let ask = choice(e.sailDay()) else { return XCTFail("not asked") }
        XCTAssertTrue(ask.prompt.contains("sinking toward the sea"), ask.prompt)
        XCTAssertEqual(ask.options.map(\.enabled), [false, true])
        let q = e.resolve(ask, option: 1)
        XCTAssertEqual(e.state.fuel, 700)
        XCTAssertEqual(e.state.hull, 10)
        XCTAssertEqual(e.state.day, 1)
        XCTAssertEqual(messages(q).last, "The engineer opens the dump valves, and 300 kg of petrol go over the side in a long glittering spray. Lighter by that much, she checks her fall and climbs. [green](Lift now 10%)[/green]")
        _ = e.sailDay()
        XCTAssertGreaterThan(e.state.mile, 2000)
    }

    func testNothingToThrowOverTheSideIsForcedDown() {
        for (km, below) in [(1000, "farmer"), (2000, "onto the sea"), (6000, "onto the ice")] {
            let e = engine(flying(km: km, hull: 0.4, fuel: 299))
            guard let end = gameOver(e.sailDay()) else { return XCTFail("\(km): not forced down") }
            XCTAssertEqual(end.title, "The [i]Kestrel[/i] has been forced down.")
            XCTAssertTrue(end.body.contains(below), "\(km): \(end.body)")
            XCTAssertTrue(e.state.over)
            XCTAssertEqual(e.state.hull, 0, "the picture puts her down")
        }
    }

    /// Over the Ekeberg mast, where she flew on with no lift: the ground crew can walk her in,
    /// and the stores sell the ballast she needs. Without the price of a bag, she is grounded.
    func testOverAMastTheGroundCrewWalksHerIn() {
        let e = engine(flying(km: 2750, hull: 0, fuel: 0, money: 20))
        XCTAssertEqual(e.state.currentStop.id, "oslo")
        guard let ask = choice(e.sailDay()) else { return XCTFail("not asked") }
        XCTAssertTrue(ask.prompt.contains("the field below the mast at Oslo"), ask.prompt)
        XCTAssertEqual(ask.options.map(\.label).last, "Let the ground crew walk her in to the mast")
        XCTAssertEqual(ask.options.map(\.enabled), [false, false, true])
        XCTAssertEqual(e.resolve(ask, option: 2), [.enterPort])
        XCTAssertTrue(e.state.atPort)
        XCTAssertTrue(e.buy([.timber: 1]))
        e.setSail()
        guard let again = choice(e.sailDay()) else { return XCTFail("asked again") }
        XCTAssertEqual(again.options.map(\.enabled), [true, false, true])
        _ = e.resolve(again, option: 0)
        XCTAssertEqual(e.state.hull, 20)

        let broke = engine(flying(km: 2750, hull: 0, fuel: 0, money: 10))
        guard let end = gameOver(broke.sailDay()) else { return XCTFail("not grounded") }
        XCTAssertEqual(end.title, "Grounded at Oslo.", "a bag is $10.40 at Oslo")
        XCTAssertTrue(broke.state.over)
    }

    /// Reaching a mast or Nome on the watch the lift gives out, the ground crew has her lines
    /// first: the arrival, not the question. Flying on from the mast, she is asked.
    func testArrivingAtAMastTheArrivalComesFirst() {
        let e = engine(flying(km: 2745, hull: 0.6, ballast: 1))
        let q = e.sailDay()
        XCTAssertEqual(q.last, .arrival(stopID: "oslo"))
        XCTAssertNil(choice(q))
        guard let moor = choice(e.beginArrival("oslo")) else { return XCTFail("no arrival question") }
        _ = e.resolve(moor, option: 1)  // fly on
        guard let ask = choice(e.sailDay()) else { return XCTFail("not asked") }
        XCTAssertTrue(ask.prompt.hasPrefix(Self.goingDown))
        XCTAssertEqual(ask.options.count, 3)
    }

    /// At a set piece she meets the question first: nobody celebrates the Arctic Circle in a
    /// ship going down.
    func testASetPieceWaitsForTheQuestion() {
        let e = engine(flying(km: 3645, hull: 0.6, ballast: 1))
        let q = e.sailDay()
        guard let ask = choice(q), let i = q.firstIndex(of: .choice(ask)) else { return XCTFail("not asked: \(q)") }
        XCTAssertEqual(q.last, .arrival(stopID: "circle"))
        XCTAssertLessThan(i, q.count - 1)
        XCTAssertTrue(ask.prompt.hasPrefix(Self.goingDown))
    }

    func testDamageIsNeverReportedPastNought() {
        let e = engine(flying(sails: 3.4, hull: 0.3))
        XCTAssertEqual(air.knock(e, [(.engines, 13)]), " [red](Engines −3%)[/red]")
        XCTAssertEqual(e.state.sails, 0)
        XCTAssertEqual(e.state.sails.sign, .plus)
        XCTAssertEqual(air.knock(e, [(.lift, 5)]), "", "a meter already showing 0% loses nothing it can show")
        XCTAssertEqual(e.state.hull, 0)
        XCTAssertEqual(air.knock(e, [(.lift, 4), (.engines, 6)]), "")
        e.state.hull = 50
        e.state.sails = 10
        XCTAssertEqual(air.knock(e, [(.lift, 4), (.engines, 15)]), " [red](Lift −4%, Engines −10%)[/red]")
    }

    func testASinkingSurvivesASave() throws {
        let e = engine(flying(hull: 0, ballast: 2))
        guard let ask = choice(e.sailDay()) else { return XCTFail("not asked") }
        let back = try JSONDecoder().decode(GameState.self, from: JSONEncoder().encode(e.state))
        let f = engine(back)
        XCTAssertEqual(choice(f.sailDay()), ask, "loaded mid-sinking, the same question")
        _ = f.resolve(ask, option: 0)
        XCTAssertEqual(f.state.hull, 20)
        let pending = try JSONDecoder().decode([Interrupt].self, from: JSONEncoder().encode([Interrupt.choice(ask)]))
        XCTAssertEqual(pending, [.choice(ask)])

        // Engines given out and said so: a save keeps the drift and does not say it again.
        let d = engine(flying(sails: 0))
        XCTAssertTrue(messages(d.sailDay()).contains { $0.hasPrefix(Self.givenOut) })
        let g = engine(try JSONDecoder().decode(GameState.self, from: JSONEncoder().encode(d.state)))
        let fuel = g.state.fuel
        XCTAssertFalse(messages(g.sailDay()).contains { $0.hasPrefix(Self.givenOut) })
        XCTAssertEqual(g.state.fuel, fuel)
        XCTAssertTrue(Airship.drifting(g.state))
    }
}
