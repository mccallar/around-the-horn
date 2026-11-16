import XCTest
@testable import HornEngine

/// The Jet Stream's two meters at nought, and the tanks dry (docs/journeys/balloon.md, "As
/// built", D14): no meter below 0, burners that have given out drift, sink and burn nothing,
/// the last of the propane heats only its share of a watch, and lift that has gone sends her
/// down unless something goes over the side.
final class BalloonBreakdownTests: XCTestCase {
    let balloon = Journeys.journey(Balloon.id) as! Balloon

    /// A meter as the status panel writes it (`StatusPanel`: `Int(jsRounded(x))`), keeping
    /// the sign a negative zero would carry.
    static func shown(_ x: Double) -> String {
        let r = jsRound(x)
        return (r.sign == .minus ? "-" : "") + "\(Int(abs(r)))%"
    }

    /// The most a watch without heat can make: 40 nm in a jet streak, burners and lift
    /// whole, five aboard, the top of the jitter.
    static let driftMost = Int(jsRound(BalloonData.driftSpeed * BalloonData.jet.speed * 1.15))

    struct Trace {
        var log: [String] = []
        /// Every value the two meters and the crew's health were stored at after a watch.
        var stored: [Double] = []
        var shown: [String] = []
        /// Damage reports that said more was lost than the meter held.
        var overReported: [String] = []
        /// Miles flown on a watch begun with the lift showing 0%.
        var movedWithNoLift: [Int] = []
        /// Miles flown on a watch begun with the burners showing 0%, or the tanks dry.
        var movedAdrift: [Int] = []
        var endings: [String] = []
    }

    /// A seeded January flight with no spares, no ballast and no money, meters worn as given
    /// and `fuel` gallons of propane, answering every question with its first offer.
    func run(seed: UInt64, mile: Int, fuel: Double, sails: Double = 20, hull: Double = 12, turns: Int = 150) -> Trace {
        var s = flying(mile: mile, sails: sails, hull: hull, fuel: fuel)
        s.food = 400
        s.water = 200
        s.limes = 25
        s.forceFair = 0
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
            let at = e.state.mile, before = (lift: e.state.hull, burners: e.state.sails)
            let noLift = Balloon.goingDown(e.state)
            let adrift = Balloon.burnersOut(e.state) || e.state.fuel <= 0
            let n = t.log.count
            play(e.sailDay())
            if e.state.atPort { e.setSail() }
            for m in t.log[n...] {
                for (label, had) in [("Lift", before.lift), ("Burners", before.burners)] {
                    guard let r = m.range(of: "\(label) −") else { continue }
                    let lost = Double(m[r.upperBound...].prefix { $0.isNumber }) ?? 0
                    if lost > jsRound(had) { t.overReported.append("\(label) at \(Self.shown(had)): \(m)") }
                }
            }
            if noLift { t.movedWithNoLift.append(e.state.mile - at) } else if adrift { t.movedAdrift.append(e.state.mile - at) }
            t.stored += [e.state.sails, e.state.hull] + e.state.crew.filter(\.alive).map(\.hp)
            t.shown += [Self.shown(e.state.hull), Self.shown(e.state.sails)]
        }
        return t
    }

    /// The report from play on the Iron Road, checked here: a meter below 0, and no fuel
    /// moving just fine. Before the fix nothing was stored below 0, but the balloon reported
    /// damage past what a meter had ("Lift −35%" at 12%), flew on as normal with the lift
    /// showing 0% and with burners at 0% (at 45% of her speed, burning propane), came down
    /// with ballast aboard, and the last gallon of propane flew a whole watch.
    func testNoMeterGoesBelowNoughtAndNothingFliesOnAsNormalAtNought() {
        var t = Trace()
        for seed: UInt64 in 1...90 {
            // Some set out with the lift already showing 0% (0.3), as a flight resumed or
            // relaunched with none would.
            let r = run(seed: seed, mile: [1000, 9000, 15500][Int(seed % 3)], fuel: [0, 800, 30][Int(seed / 3 % 3)],
                        hull: [12, 0.3][Int(seed / 9 % 2)])
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
        XCTAssertLessThanOrEqual(t.movedAdrift.max() ?? 0, Self.driftMost, "a watch adrift flew \(t.movedAdrift.max() ?? 0) nm")
        XCTAssertTrue(t.endings.contains("The [i]Skylark[/i] has come down."), "\(Set(t.endings))")
        XCTAssertTrue(t.endings.contains("The [i]Skylark[/i] has come down in the sea."), "\(Set(t.endings))")
    }

    // MARK: - States

    /// Five aboard over the Sahara in January 1999 unless told otherwise, the weather fair.
    func flying(mile: Int = 1000, sails: Double = 100, hull: Double = 100, fuel: Double = 500,
                spares: Int = 0, ballast: Int = 0, money: Double = 0) -> GameState {
        var s = GameState(journey: Balloon.id, role: .merchant, ship: "Skylark", captain: "Anna",
                          crew: ["Bruno", "Claire", "Dieter", "Elena"], startYear: 1999, startMonth: 0)
        s.mile = mile
        s.stopIndex = balloon.stops.lastIndex { $0.mile <= mile } ?? 0
        s.food = 200
        s.water = 100
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

    func choices(_ q: [Interrupt]) -> Int { q.filter { if case .choice = $0 { return true } else { return false } }.count }

    func messages(_ q: [Interrupt]) -> [String] {
        q.compactMap { if case .message(let t) = $0 { return t } else { return nil } }
    }

    func gameOver(_ q: [Interrupt]) -> (title: String, body: String)? {
        for i in q { if case .gameOver(let t, let b) = i { return (t, b) } }
        return nil
    }

    /// The top of the jitter, as `engine`'s fallback draws it.
    static let top = 0.85 + 0.3 * 0.999

    // MARK: - Burners at nought

    static let givenOut = "[red]The burners have given out.[/red]"

    func testBurnersAtNoughtDriftSinkAndBurnNothing() {
        let e = engine(flying(sails: 0.4, spares: 1))
        XCTAssertTrue(Balloon.burnersOut(e.state), "0.4 shows as 0%")
        let q = e.sailDay()
        XCTAssertEqual(e.state.fuel, 500, "no propane through burners that will not light")
        XCTAssertEqual(e.state.mile - 1000, Int(jsRound(40 * (0.45 + 0.55 * 0.004) * Self.top)), "drifting, as with the tanks dry")
        XCTAssertEqual(e.state.hull, 100 - BalloonData.seep - BalloonData.emptyLift, accuracy: 1e-9, "and sinking")
        XCTAssertEqual(messages(q).filter { $0.hasPrefix(Self.givenOut) }.count, 1, "\(messages(q))")
        XCTAssertEqual(e.state.note, "The burners are dead. The balloon is sinking.")
        XCTAssertFalse(messages(q).contains(balloon.text.outOfFuel), "the tanks are not dry")
        // Said once.
        XCTAssertFalse(messages(e.sailDay()).contains { $0.hasPrefix(Self.givenOut) })

        // Loitering with them dead burns nothing either, and sinks.
        let hull = e.state.hull
        _ = e.passDays(1, .sea)
        XCTAssertEqual(e.state.fuel, 500)
        XCTAssertEqual(e.state.hull, hull - BalloonData.emptyLift, accuracy: 1e-9)

        // A burner kit aloft, and they burn again on the next watch.
        // (Dead burners wear on to nothing, as they did: 0% either way.)
        _ = e.mendSails()
        XCTAssertEqual(e.state.sails, 25, accuracy: 1e-9)
        let at = e.state.mile, fuel = e.state.fuel, lift = e.state.hull
        _ = e.sailDay()
        XCTAssertEqual(e.state.fuel, fuel - 14 * 0.95, accuracy: 1e-9)
        XCTAssertGreaterThan(e.state.mile - at, Self.driftMost)
        XCTAssertEqual(e.state.hull, lift - BalloonData.seep, accuracy: 1e-9)
        XCTAssertNil(e.state.vars[BalloonData.coldKey])
        XCTAssertNil(e.state.vars[BalloonData.burnersOutKey], "the warning is ready for next time")
    }

    func testBurnersWornToNoughtUnderWaySaySo() {
        // 0.6 shows 1%: a fair watch's wear takes it to nothing.
        let e = engine(flying(sails: 0.6))
        let q = e.sailDay()
        XCTAssertGreaterThan(e.state.mile - 1000, Self.driftMost, "she flew this watch on what was left")
        XCTAssertEqual(e.state.fuel, 500 - 14 * 0.95, accuracy: 1e-9)
        XCTAssertTrue(Balloon.burnersOut(e.state))
        XCTAssertTrue(messages(q).contains { $0.hasPrefix(Self.givenOut) }, "\(messages(q))")
        let at = e.state.mile, fuel = e.state.fuel
        _ = e.sailDay()
        XCTAssertLessThanOrEqual(e.state.mile - at, Self.driftMost)
        XCTAssertEqual(e.state.fuel, fuel)
    }

    /// Burner trouble needs burners: no coughing flame with the tanks dry or the burners dead,
    /// no valve welded shut in a set already dead, and no climbing on them.
    func testBurnerTroubleAndClimbsNeedTheBurners() {
        func eligible(fuel: Double, sails: Double) -> [Bool] {
            var s = flying(mile: 9000, sails: sails, fuel: fuel)
            s.weather = BalloonData.storm
            let e = engine(s)
            let ev = balloon.events(e, e.state.region)
            return [ev[4].ok, ev[9].ok]
        }
        XCTAssertEqual(eligible(fuel: 500, sails: 50), [true, true])
        XCTAssertEqual(eligible(fuel: 0, sails: 50), [false, true])
        XCTAssertEqual(eligible(fuel: 500, sails: 0), [false, false])

        let dead = engine(flying(mile: 5050, sails: 0))
        guard let him = choice(dead.beginArrival("him")) else { return XCTFail("no Himalaya") }
        XCTAssertEqual(him.options.map(\.enabled), [false, true])
        var s = flying(mile: 9000, sails: 0)
        s.weather = BalloonData.snow
        let iced = engine(s)
        let ice = balloon.events(iced, iced.state.region).compactMap { ev -> ChoiceEvent? in
            guard ev.ok else { return nil }
            var q: [Interrupt] = []
            ev.run(engine(s), &q)
            if case .custom("ice", _)? = choice(q)?.kind { return choice(q) }
            return nil
        }.first
        XCTAssertEqual(ice?.options.map(\.enabled), [false, true])
    }

    // MARK: - The propane

    func testTheLastOfThePropaneIsSaidAndHeatsOnlyItsShare() {
        var s = flying(fuel: 13)
        XCTAssertEqual(Balloon.watchBurn(s), 14 * 0.95, accuracy: 1e-9)
        XCTAssertTrue(Balloon.lastOfThePropane(s))
        s.fuel = 14
        XCTAssertFalse(Balloon.lastOfThePropane(s))
        s.fuel = 0
        XCTAssertFalse(Balloon.lastOfThePropane(s), "dry is not the last of it")

        // Loitering: 10 × 0.95 a watch, and 4 gallons heat 4/9.5 of it.
        let e = engine(flying(fuel: 4))
        _ = e.passDays(1, .sea)
        XCTAssertEqual(e.state.fuel, 0)
        XCTAssertEqual(e.state.hull, 100 - BalloonData.emptyLift * (1 - 4 / 9.5), accuracy: 1e-9)

        // A whole dry watch drifts the spec's 40 nm and sinks 5, and says so.
        let dry = engine(flying(fuel: 0))
        _ = dry.sailDay()
        XCTAssertEqual(dry.state.mile - 1000, Int(jsRound(40 * Self.top)))
        XCTAssertEqual(dry.state.hull, 100 - BalloonData.seep - BalloonData.emptyLift, accuracy: 1e-9)
        XCTAssertEqual(dry.state.note, "The burners are cold. The balloon is sinking.")
        XCTAssertTrue(balloon.text.outOfFuel.contains("you sink, and keep sinking"))
    }

    /// The watches a set piece passes cost what any watch without heat does.
    func testAWatchLostWithoutHeatSinksToo() {
        let party = engine(flying(mile: 10050, fuel: 0))
        _ = party.resolve(ChoiceEvent(kind: .custom(key: "dateline", args: []), prompt: "", detail: nil,
                                      options: [.init("a"), .init("b")]), option: 0)
        XCTAssertEqual(party.state.day, 1)
        XCTAssertEqual(party.state.hull, 100 - BalloonData.emptyLift, accuracy: 1e-9)
        let full = engine(flying(mile: 10050))
        _ = full.resolve(ChoiceEvent(kind: .custom(key: "dateline", args: []), prompt: "", detail: nil,
                                     options: [.init("a"), .init("b")]), option: 0)
        XCTAssertEqual(full.state.fuel, 485)
        XCTAssertEqual(full.state.hull, 100)
    }

    // MARK: - Lift at nought

    static let goingDown = "[red]She is going down.[/red]"

    func testLiftAtNoughtWithBallastAboardIsAskedNotBroughtDown() {
        let e = engine(flying(hull: 0.3, ballast: 1))
        XCTAssertTrue(Balloon.goingDown(e.state), "0.3 shows as 0%")
        guard let ask = choice(e.sailDay()) else { return XCTFail("not asked") }
        XCTAssertFalse(e.state.over)
        XCTAssertEqual(e.state.day, 0, "no time passes for asking")
        XCTAssertEqual(e.state.mile, 1000)
        XCTAssertTrue(ask.prompt.hasPrefix(Self.goingDown), ask.prompt)
        XCTAssertTrue(ask.prompt.contains("sinking toward the ground"), "the Sahara is land: \(ask.prompt)")
        XCTAssertEqual(ask.options.map(\.label), ["Cut away a sack of ballast [dim](have 1)[/dim]",
                                                 "Cut away a propane cylinder: 50 gallons [dim](have 500 gallons)[/dim]"])
        XCTAssertTrue(ask.options.allSatisfy(\.enabled))
        XCTAssertEqual(choice(e.sailDay()), ask, "asked again, the same question")

        let q = e.resolve(ask, option: 0)
        XCTAssertEqual(e.state.timber, 0)
        XCTAssertEqual(e.state.hull, 20.3, accuracy: 1e-9)
        XCTAssertEqual(e.state.day, 1, "a watch to trim her")
        XCTAssertEqual(messages(q).last, balloon.text.patched(20))
        XCTAssertFalse(Balloon.goingDown(e.state))
        _ = e.sailDay()
        XCTAssertGreaterThan(e.state.mile, 1000, "and she flies on")
    }

    /// Worn to nothing in a watch, she is asked in that watch, and nothing else happens to
    /// her first (every chance drawn here would pass).
    func testLiftWornToNoughtInAWatchAsksThere() {
        // 0.55 shows 1%: the watch's seep takes it to 0.47, which shows 0%.
        let e = engine(flying(mile: 9000, hull: 0.55, ballast: 2), [], fallback: 0)
        let q = e.sailDay()
        XCTAssertNil(gameOver(q), "not brought down with ballast aboard")
        XCTAssertFalse(e.state.over)
        guard let ask = choice(q) else { return XCTFail("not asked: \(q)") }
        XCTAssertTrue(ask.prompt.contains("sinking toward the sea"), ask.prompt)
        XCTAssertEqual(choices(q), 1, "no event as well")
    }

    func testAPropaneCylinderBuysTenPointsForFiftyGallons() {
        let e = engine(flying(mile: 9000, hull: 0, fuel: 100))
        guard let ask = choice(e.sailDay()) else { return XCTFail("not asked") }
        XCTAssertTrue(ask.prompt.contains("sinking toward the sea"), ask.prompt)
        XCTAssertEqual(ask.options.map(\.enabled), [false, true])
        let q = e.resolve(ask, option: 1)
        // The cylinder, then a watch loitering in the freezing North Pacific: 10 × 1.2.
        XCTAssertEqual(e.state.fuel, 100 - 50 - 12, accuracy: 1e-9)
        XCTAssertEqual(e.state.hull, 10)
        XCTAssertEqual(e.state.day, 1)
        XCTAssertEqual(messages(q).last, "The flight engineer waits for empty sea below, then cuts a propane cylinder loose, fifty gallons and all. Lighter by that much, the balloon checks its fall and climbs. [green](Lift now 10%)[/green]")
        _ = e.sailDay()
        XCTAssertGreaterThan(e.state.mile, 9000)
    }

    func testNothingToCutAwayComesDown() {
        for (mile, title) in [(1000, "The [i]Skylark[/i] has come down."), (9000, "The [i]Skylark[/i] has come down in the sea.")] {
            let e = engine(flying(mile: mile, hull: 0.4, fuel: 49))
            guard let end = gameOver(e.sailDay()) else { return XCTFail("\(mile): not brought down") }
            XCTAssertEqual(end.title, title)
            XCTAssertTrue(end.body.hasPrefix("With no lift left and nothing more to throw over the side"), end.body)
            XCTAssertTrue(e.state.over)
            XCTAssertEqual(e.state.hull, 0)
        }
    }

    /// Over Saga's field, where she flew on with no lift: she can come down to the ground
    /// team, whose store sells the ballast she needs. Without the price of a sack, she is
    /// grounded there.
    func testOverAFieldTheGroundTeamTakesHer() {
        let sack = balloon.port("saga")!.price(.timber)
        let e = engine(flying(mile: 7650, hull: 0, fuel: 0, money: sack + 1))
        XCTAssertEqual(e.state.currentStop.id, "saga")
        guard let ask = choice(e.sailDay()) else { return XCTFail("not asked") }
        XCTAssertTrue(ask.prompt.contains("settling toward the field at Saga"), ask.prompt)
        XCTAssertEqual(ask.options.map(\.label).last, "Come down on the field at Saga")
        XCTAssertEqual(ask.options.map(\.enabled), [false, false, true])
        XCTAssertEqual(e.resolve(ask, option: 2), [.enterPort])
        XCTAssertTrue(e.state.atPort)

        // On the ground with no lift, the launch director wants the sack bought first.
        XCTAssertEqual(Balloon.relaunchRefusal(e), "The launch director won't let you go up with no lift in her. A sack of ballast from the store, or the riggers' helium, first.")
        XCTAssertTrue(e.buy([.timber: 1]))
        XCTAssertNil(Balloon.relaunchRefusal(e), "the ground team pays for the climb")
        e.setSail()
        guard let again = choice(e.sailDay()) else { return XCTFail("asked again") }
        XCTAssertEqual(again.options.map(\.enabled), [true, false, true], "a sack aboard: drop it, or come down again")
        _ = e.resolve(again, option: 0)
        XCTAssertEqual(e.state.hull, 20 - BalloonData.emptyLift, accuracy: 1e-9, "the watch to trim her is a dry one")

        let broke = engine(flying(mile: 7650, hull: 0, fuel: 0, money: sack - 1))
        guard let end = gameOver(broke.sailDay()) else { return XCTFail("not grounded") }
        XCTAssertEqual(end.title, "Grounded at Saga.")
        XCTAssertTrue(end.body.contains("the [i]Skylark[/i] comes down on the field at Saga for the last time"), end.body)
        XCTAssertTrue(broke.state.over)
    }

    /// Reaching a field or the finish on the watch the lift gives out, the arrival comes
    /// first. Flying on from the field, she is asked.
    func testArrivingAtAFieldTheArrivalComesFirst() {
        let e = engine(flying(mile: 7645, hull: 0.55, ballast: 1))
        let q = e.sailDay()
        XCTAssertTrue(Balloon.goingDown(e.state))
        XCTAssertEqual(q.last, .arrival(stopID: "saga"))
        XCTAssertNil(choice(q))
        guard let land = choice(e.beginArrival("saga")) else { return XCTFail("no arrival question") }
        _ = e.resolve(land, option: 1)  // fly on
        guard let ask = choice(e.sailDay()) else { return XCTFail("not asked") }
        XCTAssertTrue(ask.prompt.hasPrefix(Self.goingDown))
        XCTAssertEqual(ask.options.count, 3)

        let home = engine(flying(mile: 18295, hull: 0.55))
        XCTAssertEqual(home.sailDay().last, .arrival(stopID: "finish"), "she comes down at the finish anyway")
        XCTAssertFalse(home.state.over)
    }

    /// At a set piece she meets the question first: nobody climbs over the Himalaya in a
    /// balloon going down.
    func testASetPieceWaitsForTheQuestion() {
        let e = engine(flying(mile: 5045, hull: 0.55, ballast: 1))
        let q = e.sailDay()
        guard let ask = choice(q), let i = q.firstIndex(of: .choice(ask)) else { return XCTFail("not asked: \(q)") }
        XCTAssertEqual(q.last, .arrival(stopID: "him"))
        XCTAssertLessThan(i, q.count - 1)
        XCTAssertTrue(ask.prompt.hasPrefix(Self.goingDown))
    }

    /// A rest with the tanks dry sinks her: she is asked once, however many watches are left.
    func testARestThatTakesTheLastOfTheLiftAsksOnce() {
        let e = engine(flying(hull: 7, fuel: 0, ballast: 1))
        let q = e.rest(days: 5)
        XCTAssertFalse(e.state.over)
        XCTAssertEqual(choices(q), 1)
        XCTAssertEqual(e.state.hull, 0)
        XCTAssertEqual(e.state.day, 5)
        guard let ask = choice(q) else { return XCTFail("not asked") }
        _ = e.resolve(ask, option: 0)
        XCTAssertEqual(e.state.hull, 20 - BalloonData.emptyLift, accuracy: 1e-9)
    }

    func testDamageIsNeverReportedPastNought() {
        let e = engine(flying(sails: 3.4, hull: 0.3))
        XCTAssertEqual(balloon.knock(e, [(.burners, 13)]), " [red](Burners −3%)[/red]")
        XCTAssertEqual(e.state.sails, 0)
        XCTAssertEqual(e.state.sails.sign, .plus)
        XCTAssertEqual(balloon.knock(e, [(.lift, 5)]), "", "a meter already showing 0% loses nothing it can show")
        XCTAssertEqual(e.state.hull, 0)
        XCTAssertEqual(balloon.knock(e, [(.burners, 15), (.lift, 6)]), "")
        e.state.hull = 50
        e.state.sails = 10
        XCTAssertEqual(balloon.knock(e, [(.burners, 15), (.lift, 6)]), " [red](Burners −10%, Lift −6%)[/red]")

        // A storm strike at 12% lift reports the 12 there was, and she is asked, not lost.
        var s = flying(mile: 9000, hull: 12, ballast: 1)
        s.vars[BalloonData.southKey] = 1
        let strike = engine(s, [0.03, 0.999])
        var q: [Interrupt] = []
        balloon.dayEvents(strike, &q, strike.state.region)
        XCTAssertTrue(messages(q).first?.hasSuffix("[red](Lift −12%)[/red]") == true, "\(messages(q))")
        XCTAssertTrue(choice(q)?.prompt.hasPrefix(Self.goingDown) == true)
        XCTAssertFalse(strike.state.over)

        // The Himalaya's cold leaves nobody stored below 0.
        var cold = flying(mile: 5050)
        cold.clothes = 0
        for i in cold.crew.indices { cold.crew[i].hp = cold.crew[i].isCaptain ? 50 : 5 }
        let him = engine(cold)
        guard let c = choice(him.beginArrival("him")) else { return XCTFail("no Himalaya") }
        _ = him.resolve(c, option: 0)
        XCTAssertTrue(him.state.crew.allSatisfy { $0.hp >= 0 && $0.hp.sign == .plus }, "\(him.state.crew.map(\.hp))")
        XCTAssertEqual(him.state.living.count, 1)
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

        // Burners given out and said so: a save keeps the drift and does not say it again.
        let d = engine(flying(sails: 0))
        XCTAssertTrue(messages(d.sailDay()).contains { $0.hasPrefix(Self.givenOut) })
        let g = engine(try JSONDecoder().decode(GameState.self, from: JSONEncoder().encode(d.state)))
        let fuel = g.state.fuel, lift = g.state.hull
        XCTAssertFalse(messages(g.sailDay()).contains { $0.hasPrefix(Self.givenOut) })
        XCTAssertEqual(g.state.fuel, fuel)
        XCTAssertEqual(g.state.hull, lift - BalloonData.seep - BalloonData.emptyLift, accuracy: 1e-9)
    }
}
