import XCTest
@testable import HornEngine

/// The Long Transfer's two meters at nought, and the tanks dry (docs/journeys/mars.md, "As
/// built", D14): no meter or health below 0, a dark array coasts, burns nothing and is asked
/// about before every day, a set piece that needs the drive waits for power, a hull that
/// shows 0% lets go, and dry tanks burn their last share and cost power.
final class MarsBreakdownTests: XCTestCase {
    let mars = Journeys.journey(Mars.id)
    var m: Mars { mars as! Mars }

    /// A meter as the status panel writes it (`StatusPanel`: `Int(jsRounded(x))`), keeping
    /// the sign a negative zero would carry.
    static func shown(_ x: Double) -> String {
        let r = jsRound(x)
        return (r.sign == .minus ? "-" : "") + "\(Int(abs(r)))%"
    }

    /// The most a day's coast can make: a cruise in the best tracking, power at 0%, the top
    /// of the jitter, and the aerobrake's quick days.
    static let coastMost = Int(jsRound(370 * MarsData.tracking.speed * 0.7015 * 0.4 * 1.15 * MarsData.aerobrakeSpeed))

    /// Five aboard in the inner arc in October 2087, in fair weather for six days.
    func arc(mile: Int = 16_000, sails: Double = 100, hull: Double = 100, fuel: Double = 500,
             panels: Int = 0, patches: Int = 0, money: Double = 0) -> GameState {
        var s = GameState(journey: Mars.id, role: .merchant, ship: "Fair Copy", captain: "Adaeze",
                          crew: ["Tomasz", "Priya", "Mateo", "Ingrid"], startYear: 2087, startMonth: 9)
        s.mile = mile
        s.stopIndex = mars.stops.lastIndex { $0.mile <= mile } ?? 0
        s.food = 400
        s.water = 700
        s.limes = 10
        s.clothes = 5
        s.fuel = fuel
        s.sails = sails
        s.hull = hull
        s.sailcloth = panels
        s.timber = patches
        s.money = money
        s.forceFair = 6
        s.atPort = false
        return s
    }

    func choice(_ q: [Interrupt]) -> ChoiceEvent? {
        for i in q { if case .choice(let c) = i { return c } }
        return nil
    }

    func key(_ c: ChoiceEvent?) -> String? {
        if case .custom(let k, _)? = c?.kind { return k }
        return nil
    }

    func messages(_ q: [Interrupt]) -> [String] {
        q.compactMap { if case .message(let t) = $0 { return t } else { return nil } }
    }

    func gameOver(_ q: [Interrupt]) -> (title: String, body: String)? {
        for i in q { if case .gameOver(let t, let b) = i { return (t, b) } }
        return nil
    }

    /// The jitter's top, as `ScriptedRNG`'s fallback draws it.
    static let jitter = 0.85 + 0.3 * 0.999

    static let dark = "[red]The array has gone dark.[/red]"
    static let lost = "The hull of the [i]Fair Copy[/i] lets go."

    // MARK: - A seeded run

    struct Trace {
        var stored: [Double] = []
        var shown: [String] = []
        var overReported: [String] = []
        /// Distance made on a turn begun with the array dark, and propellant burnt on one.
        var movedDark: [Int] = []
        var burntDark: [Double] = []
        /// Distance made on a turn begun with the hull showing 0%.
        var movedWithNoHull: [Int] = []
        var rewires = 0
        var endings: [String] = []
    }

    /// A seeded run from 160 million km with nothing to mend with and no money, the meters
    /// worn as given and `fuel` tenths of propellant aboard. A dark array coasts on odd seeds
    /// and is rewired on even ones; every other question takes its first offer.
    func run(seed: UInt64, fuel: Double, sails: Double = 15, hull: Double = 14, turns: Int = 150) -> Trace {
        let e = GameEngine(state: arc(sails: sails, hull: hull, fuel: fuel), rng: SeededRNG(seed: seed))
        e.state.forceFair = 0
        var t = Trace()
        var log: [String] = []
        func play(_ q: [Interrupt]) {
            var q = q
            while !q.isEmpty {
                switch q.removeFirst() {
                case .message(let s): log.append(s)
                case .choice(let c):
                    log.append(c.prompt)
                    var pick = c.options.firstIndex(where: \.enabled) ?? 0
                    if key(c) == "dark", seed % 2 == 1, let coast = c.options.firstIndex(where: { $0.label.hasPrefix("Coast on") }) {
                        pick = coast
                    }
                    q = e.resolve(c, option: pick) + q
                case .burial(let id, let cause): e.commitBurial(crewID: id, cause: cause, epitaph: "")
                case .arrival(let id): q = e.beginArrival(id) + q
                case .enterPort: return
                case .gameOver(let title, _): t.endings.append(title); return
                case .finale: t.endings.append("arrived"); return
                }
            }
        }
        for _ in 0..<turns where !e.state.over {
            let mile = e.state.mile, fuel = e.state.fuel
            let before = (hull: e.state.hull, power: e.state.sails)
            let dark = Mars.dark(e.state), noHull = jsRound(e.state.hull) <= 0
            let n = log.count
            play(e.sailDay())
            if e.state.atPort { e.setSail() }
            for line in log[n...] {
                for (label, had) in [("Pressure hull", before.hull), ("Power & drive", before.power)] {
                    guard let r = line.range(of: "\(label) −") else { continue }
                    let lost = Double(line[r.upperBound...].prefix { $0.isNumber }) ?? 0
                    if lost > jsRound(had) { t.overReported.append("\(label) at \(Self.shown(had)): \(line)") }
                }
                if line.hasPrefix("Two days later the wings") { t.rewires += 1 }
            }
            if noHull { t.movedWithNoHull.append(e.state.mile - mile) }
            if dark {
                t.movedDark.append(e.state.mile - mile)
                t.burntDark.append(fuel - e.state.fuel)
            }
            t.stored += [e.state.sails, e.state.hull] + e.state.crew.filter(\.alive).map(\.hp)
            t.shown += [Self.shown(e.state.hull), Self.shown(e.state.sails)]
        }
        return t
    }

    /// The report from play on the Iron Road, checked here: a meter below 0, and no fuel
    /// moving just fine. Before the fix nothing was stored below 0 for long, but an accident
    /// could leave a crew member's health at −5 until the next day, damage was reported past
    /// what the meter had ("Power & drive −9%" with 3% left), power at 0% drove her at 70%
    /// of her speed on a full burn of propellant, a hull showing 0% flew on, and the last of
    /// the propellant was thrown away for nothing.
    func testNoMeterGoesBelowNoughtAndNothingCarriesOnAsNormalAtNought() {
        var t = Trace()
        for seed: UInt64 in 1...60 {
            let r = run(seed: seed, fuel: [0, 30, 500][Int(seed % 3)])
            t.stored += r.stored
            t.shown += r.shown
            t.overReported += r.overReported
            t.movedDark += r.movedDark
            t.burntDark += r.burntDark
            t.movedWithNoHull += r.movedWithNoHull
            t.rewires += r.rewires
            t.endings += r.endings
        }
        XCTAssertFalse(t.stored.contains { $0 < 0 || $0.sign == .minus }, "a value stored below 0")
        XCTAssertFalse(t.shown.contains { $0.hasPrefix("-") }, "a meter shown below 0")
        XCTAssertEqual(t.overReported.count, 0, "damage reported past nought: \(t.overReported.prefix(2))")
        XCTAssertGreaterThan(t.movedDark.filter { $0 > 0 }.count, 0, "some ship coasted in the dark")
        XCTAssertLessThanOrEqual(t.movedDark.max() ?? 0, Self.coastMost, "a dark day made \(t.movedDark.max() ?? 0)")
        XCTAssertEqual(t.burntDark.filter { $0 != 0 }.count, 0, "propellant burnt in the dark")
        XCTAssertGreaterThan(t.rewires, 0, "some ship rewired her wings")
        XCTAssertEqual(t.movedWithNoHull.filter { $0 != 0 }.count, 0, "flew on with the hull at 0%")
        XCTAssertTrue(t.endings.contains(Self.lost), "\(Set(t.endings))")
    }

    // MARK: - The array dark

    func testADarkArrayCoastsBurnsNothingAndIsAskedEveryDay() {
        let e = engine(arc(sails: 0.4, panels: 1))
        XCTAssertTrue(Mars.dark(e.state), "0.4 shows as 0%")
        XCTAssertTrue(Mars.coasting(e.state))
        guard let ask = choice(e.sailDay()) else { return XCTFail("not asked") }
        XCTAssertEqual(e.state.day, 0, "no time passes for asking")
        XCTAssertEqual(e.state.mile, 16_000)
        XCTAssertEqual(key(ask), "dark")
        XCTAssertEqual(ask.prompt, Self.dark + " The drive is dead, the recycler has stopped and the cabin is getting colder by the hour. The [i]Fair Copy[/i] coasts on along the arc at the speed she had, which is not much.")
        XCTAssertEqual(ask.detail, "A spare panel goes in from the truss in a day. Without one, two of you can go out and rewire what is left of the wings: two days in suits for a tenth of the power, which is enough to run the drive and the recycler. Until then the water lost each day is twice the usual, 4 litres a head.")
        XCTAssertEqual(ask.options.map(\.label), ["Fit a spare array panel [dim](have 1)[/dim]",
                                                 "Rewire what is left of the wings: two days in suits",
                                                 "Coast on in the dark for a day", "Take stock first"])
        XCTAssertTrue(ask.options.allSatisfy(\.enabled))
        XCTAssertEqual(choice(e.sailDay()), ask, "asked again, the same question")

        // A day's coast: the shared dry-tank speed at 0% power, no propellant, twice the water.
        XCTAssertEqual(e.resolve(ask, option: 2), [])
        let q = e.sailDay()
        XCTAssertNil(choice(q), "the day chosen is not asked about")
        XCTAssertEqual(e.state.day, 1)
        XCTAssertEqual(e.state.mile - 16_000, Int(jsRound(370 * (0.7 + 0.3 * 0.004) * 0.4 * Self.jitter)))
        XCTAssertEqual(e.state.fuel, 500, "no propellant through a drive with no power")
        XCTAssertEqual(e.state.water, 700 - 5 * MarsData.darkWater)
        XCTAssertEqual(mars.temperature(e.state, in: e.state.region), .freezing)
        XCTAssertEqual(e.state.note, "The array is dark. She is coasting.")
        XCTAssertNil(e.state.vars[MarsData.coastKey])

        // The next day is asked about again.
        guard let again = choice(e.sailDay()) else { return XCTFail("not asked the next day") }
        XCTAssertEqual(e.state.day, 1)
        let mended = e.resolve(again, option: 0)
        XCTAssertEqual(e.state.sailcloth, 0)
        XCTAssertEqual(e.state.sails, 25, accuracy: 1e-9)
        XCTAssertEqual(e.state.day, 2)
        XCTAssertEqual(messages(mended).last, mars.text.mended(25))
        let mile = e.state.mile
        XCTAssertNil(choice(e.sailDay()))
        XCTAssertEqual(e.state.fuel, 490)
        XCTAssertGreaterThan(e.state.mile - mile, 300)
        XCTAssertFalse(Mars.dark(e.state))
    }

    /// Worn to nothing on a day under way, she is asked before the next.
    func testPowerWornToNoughtUnderWayIsAskedTheNextDay() {
        // 0.6 shows 1%: a fair day's wear (0.84 at the jitter's top) takes it to nothing.
        let e = engine(arc(sails: 0.6))
        XCTAssertNil(choice(e.sailDay()), "she makes this day on what was left")
        XCTAssertGreaterThan(e.state.mile - 16_000, 250)
        XCTAssertEqual(e.state.sails, 0)
        XCTAssertEqual(e.state.fuel, 490)
        XCTAssertEqual(key(choice(e.sailDay())), "dark")
    }

    func testTheWaterLostDoublesOnlyInTheDarkAndNotDocked() {
        var s = arc(sails: 0)
        XCTAssertEqual(mars.waterNeed(s, .freezing), 4)
        s.sails = 1
        XCTAssertEqual(mars.waterNeed(s, .freezing), 2)
        s.sails = 0
        s.atPort = true
        XCTAssertEqual(mars.waterNeed(s, .freezing), 2, "a station's recycler does the work")
        XCTAssertNil(mars.stalled(engine(s)), "nobody is asked aboard a station")
        XCTAssertFalse(Mars.coasting(s))
    }

    func testRewiringGivesATenthOfThePowerForTwoDaysAndSomeSkin() {
        var s = arc(sails: 0)
        for (i, hp) in [100.0, 60, 90, 80, 70].enumerated() { s.crew[i].hp = hp }
        let e = engine(s)
        guard let ask = choice(e.sailDay()) else { return XCTFail("not asked") }
        XCTAssertEqual(ask.options.map(\.enabled), [false, true, true, true])
        let q = e.resolve(ask, option: 1)
        XCTAssertEqual(messages(q).first, "Priya and Mateo suit up and go out along the truss with a reel of cable, a meter and a flask of something hot.")
        XCTAssertEqual(messages(q).last, "Two days later the wings are not mended so much as talked round: one string of cells on each, wired past everything that has burnt out. The drive lights, and so does the recycler. [green](Power & drive now 10%)[/green]")
        XCTAssertEqual(e.state.day, MarsData.rigDays)
        XCTAssertEqual(e.state.sails, MarsData.rigPower)
        XCTAssertEqual(e.state.water, 700 - 2 * 5 * MarsData.darkWater, "two days in the dark")
        // Two days at rest in a freezing cabin, suited (+3.6 a day), then 3 to 8 each for the
        // two who went out (8 at the jitter's top). Nobody else pays for it.
        for (hp, want) in zip(e.state.crew.map(\.hp), [100, 67.2, 89.2, 79.2, 77.2]) { XCTAssertEqual(hp, want, accuracy: 1e-9) }
        XCTAssertNil(choice(e.sailDay()))
        XCTAssertEqual(e.state.fuel, 490, "the drive runs on a tenth")

        // One hand left: you go with them. Nobody left: you go alone.
        var two = arc(sails: 0)
        for i in 2...4 { two.crew[i].alive = false }
        let f = engine(two)
        XCTAssertTrue(choice(f.sailDay())!.detail!.contains("two of you can go out"))
        XCTAssertTrue(messages(f.resolve(choice(f.sailDay())!, option: 1)).first?.hasPrefix("You and Tomasz suit up") ?? false)
        var one = arc(sails: 0)
        for i in 1...4 { one.crew[i].alive = false }
        let g = engine(one)
        XCTAssertTrue(choice(g.sailDay())!.detail!.contains("Without one, you can go out"))
        XCTAssertEqual(messages(g.resolve(choice(g.sailDay())!, option: 1)).first,
                       "You suit up and go out along the truss alone with a reel of cable, a meter and a flask of something hot.")
        XCTAssertEqual(g.state.sails, 10)
    }

    /// Taking stock is the menu under way; nothing happens and no time passes.
    func testTakingStockIsTheMenu() {
        let e = engine(arc(sails: 0))
        let before = e.state
        XCTAssertEqual(e.resolve(choice(e.sailDay())!, option: 3), [.enterPort])
        XCTAssertEqual(e.state, before)
    }

    /// Trouble with the wings needs power to have trouble with; the thruster grid and a course
    /// trimmed on a good fix need the drive running; the pod needs the drive to match its
    /// course. (Found by the seeded run: a dark ship trimmed 2.5 million km off the arc.)
    func testWingTroubleAndThePodNeedTheDrive() {
        func eligible(sails: Double, pace: Pace, fuel: Double) -> [Bool] {
            var s = arc(sails: sails, fuel: fuel)
            s.pace = pace
            let ev = mars.events(engine(s), s.region)
            return [ev[1].ok, ev[2].ok, ev[7].ok, ev[15].ok]
        }
        XCTAssertEqual(eligible(sails: 50, pace: .full, fuel: 500), [true, true, true, true])
        XCTAssertEqual(eligible(sails: 0, pace: .full, fuel: 500), [false, false, false, false])
        XCTAssertEqual(eligible(sails: 50, pace: .full, fuel: 0), [true, true, false, false])
        XCTAssertEqual(eligible(sails: 50, pace: .steady, fuel: 500), [true, true, false, true])

        for (sails, can) in [(50.0, true), (0.3, false)] {
            let e = engine(arc(sails: sails))
            var q: [Interrupt] = []
            mars.events(e, e.state.region)[9].run(e, &q)
            XCTAssertEqual(key(choice(q)), "pod")
            XCTAssertEqual(choice(q)?.options.map(\.enabled), [can, true])
        }
    }

    // MARK: - Set pieces in the dark

    /// Turnover reached on the day the array went dark waits for power, and so does the
    /// question, across a save; there is no coasting past it.
    func testASetPieceReachedInTheDarkWaitsForPower() throws {
        let e = engine(arc(mile: 23_800, sails: 0.6, panels: 1))
        var q = e.sailDay()
        XCTAssertTrue(Mars.dark(e.state))
        XCTAssertEqual(q.last, .arrival(stopID: "turnover"))
        q = e.beginArrival("turnover")
        XCTAssertEqual(q, [.message("The [i]Fair Copy[/i] reaches Turnover with her array dark. Turnover is due, and nobody turns a ship end for end without a drive.")])
        let day = e.state.day

        let f = engine(try JSONDecoder().decode(GameState.self, from: JSONEncoder().encode(e.state)))
        guard let ask = choice(f.sailDay()) else { return XCTFail("not asked") }
        XCTAssertEqual(ask.prompt, Self.dark + " The drive is dead, the recycler has stopped and the cabin is getting colder by the hour. Turnover is due, and nobody turns a ship end for end without a drive.")
        XCTAssertEqual(ask.options.map(\.label), ["Fit a spare array panel [dim](have 1)[/dim]",
                                                 "Rewire what is left of the wings: two days in suits", "Take stock first"])
        _ = f.resolve(ask, option: 0)
        XCTAssertEqual(f.state.day, day + 1)
        let turnover = choice(f.sailDay())
        XCTAssertEqual(key(turnover), "turnover")
        XCTAssertEqual(f.state.day, day + 1, "the question takes no time")
        XCTAssertEqual(f.state.mile, 24_000)
        XCTAssertNil(f.state.vars[MarsData.heldKey])
        _ = f.resolve(turnover!, option: 0)
        _ = f.sailDay()
        XCTAssertGreaterThan(f.state.mile, 24_000)
    }

    /// The cycler pays what a grateful ship wired on arrival, as always, then holds her
    /// window open until there is power to match orbits with.
    func testTheCyclerWaitsForADarkShip() {
        var s = arc(mile: 15_300, sails: 0.6)
        s.vars[MarsData.owedKey] = 20
        let e = engine(s)
        XCTAssertEqual(e.sailDay().last, .arrival(stopID: "cycler"))
        let q = e.beginArrival("cycler")
        XCTAssertEqual(messages(q).count, 2)
        XCTAssertTrue(messages(q)[0].contains("+$20"))
        XCTAssertEqual(messages(q)[1], "The [i]Fair Copy[/i] reaches the cycler Perpetua with her array dark. The Perpetua is holding her docking window open, and there is no meeting her without a drive.")
        XCTAssertNil(choice(q))
        XCTAssertEqual(e.state.money, 20)

        let ask = choice(e.sailDay())!
        XCTAssertEqual(ask.options.count, 3, "no coasting past her")
        _ = e.resolve(ask, option: 1)  // rewire
        guard let dock = choice(e.sailDay()) else { return XCTFail("no cycler") }
        XCTAssertEqual(key(dock), "cycler")
        XCTAssertEqual(dock.options.map(\.enabled), [true, true])
        XCTAssertEqual(e.state.money, 20, "paid once")
    }

    /// A station's tugs bring a dark ship in: reaching Midway dark is the usual arrival.
    func testAStationTakesADarkShipIn() {
        let e = engine(arc(mile: 29_800, sails: 0.6))
        XCTAssertEqual(e.sailDay().last, .arrival(stopID: "midway"))
        XCTAssertTrue(Mars.dark(e.state))
        guard let c = choice(e.beginArrival("midway")), case .portArrival = c.kind else { return XCTFail("no arrival") }
        XCTAssertNil(e.state.vars[MarsData.heldKey])
    }

    // MARK: - The pressure hull

    func testAHullThatShowsNoughtLetsGo() {
        // Worn to 0.47 by a day's creep, which shows 0%: all of it goes.
        let e = engine(arc(hull: 0.52))
        guard let end = gameOver(e.sailDay()) else { return XCTFail("flew on with the hull at 0%") }
        XCTAssertEqual(end.title, Self.lost)
        XCTAssertEqual(end.body, mars.text.wreckedBody)
        XCTAssertTrue(e.state.over)
        XCTAssertEqual(e.state.hull, 0)

        // Already showing 0% (an older save): it lets go before another day goes by.
        let f = engine(arc(hull: 0.3))
        XCTAssertEqual(gameOver(f.sailDay())?.title, Self.lost)
        XCTAssertEqual(f.state.day, 0)
        XCTAssertEqual(f.state.hull, 0)

        // 0.6 shows 1%: a day's creep leaves 0.55, which still shows 1%, and she goes on.
        let g = engine(arc(hull: 0.6))
        XCTAssertNil(gameOver(g.sailDay()))
        XCTAssertEqual(g.state.hull, 0.55, accuracy: 1e-9)
    }

    func testAPebbleThroughAHullAtThreePercentReportsThreeAndSinksHer() {
        let e = engine(arc(hull: 3), [0.5])
        var q: [Interrupt] = []
        mars.events(e, e.state.region)[0].run(e, &q)
        XCTAssertEqual(messages(q).first, "A pebble the size of a lentil goes in one side of the cargo bay and out the other. It does not stop to apologise. [red](Pressure hull −3%)[/red]")
        XCTAssertEqual(gameOver(q)?.title, Self.lost)
        XCTAssertEqual(e.state.hull, 0)
    }

    func testDamageIsNeverReportedPastNought() {
        let e = engine(arc(sails: 3.4, hull: 50))
        XCTAssertEqual(m.knock(e, .power, 13), " [red](Power & drive −3%)[/red]")
        XCTAssertEqual(e.state.sails, 0)
        XCTAssertEqual(e.state.sails.sign, .plus)
        XCTAssertEqual(m.knock(e, .power, 5), "", "a meter already showing 0% loses nothing it can show")
        XCTAssertEqual(m.knock(e, .hull, 4), " [red](Pressure hull −4%)[/red]")
        XCTAssertEqual(e.state.hull, 46)
        e.state.hull = 2.6
        XCTAssertEqual(m.knock(e, .hull, 2), " [red](Pressure hull −2%)[/red]")
        XCTAssertEqual(e.state.hull, 0.6, accuracy: 1e-9, "1% still holds")
        e.state.hull = 2.4
        XCTAssertEqual(m.knock(e, .hull, 2), " [red](Pressure hull −2%)[/red]")
        XCTAssertEqual(e.state.hull, 0, "0.4 shows 0%: it has let go")
    }

    /// Accidents leave a crew member at 1 health at least; the day that follows is what kills.
    func testAccidentsLeaveACrewMemberAtOneHealthAtLeast() {
        func hit(_ event: Int, hp: Double) -> [Double] {
            var s = arc()
            for i in s.crew.indices { s.crew[i].hp = hp }
            let e = engine(s, [], fallback: 0)
            var q: [Interrupt] = []
            mars.events(e, e.state.region)[event].run(e, &q)
            return e.state.crew.map(\.hp)
        }
        XCTAssertEqual(hit(0, hp: 3), [1, 3, 3, 3, 3], "the pebble's decompression")
        XCTAssertEqual(hit(2, hp: 4), [1, 4, 4, 4, 4], "the coolant line's burn")

        var s = arc()
        for i in s.crew.indices { s.crew[i].hp = 5 }
        let e = engine(s, [], fallback: 0)
        let flare = e.ask("flare", prompt: "?", options: [.init("0"), .init("1")])
        guard case .choice(let c) = flare else { return XCTFail() }
        _ = e.resolve(c, option: 1)
        XCTAssertEqual(e.state.crew.map(\.hp), [1, 5, 5, 5, 5], "working through a flare")
        XCTAssertEqual(e.state.crew[0].ailment, MarsData.radiation)
    }

    // MARK: - The tanks dry

    /// The last of the propellant drives its share of the day and she coasts the rest; for
    /// that share the tumble wears the wings.
    func testTheLastOfThePropellantBurnsItsShare() {
        let powered = engine(arc())
        let last = engine(arc(fuel: 4))
        XCTAssertTrue(Mars.lastOfThePropellant(last.state))
        XCTAssertFalse(Mars.lastOfThePropellant(powered.state))
        _ = powered.sailDay()
        let q = last.sailDay()
        XCTAssertEqual(last.state.fuel, 0)
        XCTAssertEqual(powered.state.mile - 16_000, Int(jsRound(370 * Self.jitter)))
        XCTAssertEqual(last.state.mile - 16_000, Int(jsRound(370 * (0.4 + 0.6 * 0.4) * Self.jitter)))
        XCTAssertEqual(powered.state.sails - last.state.sails, 0.6 * MarsData.tumbleWear, accuracy: 1e-9)
        XCTAssertTrue(messages(q).contains(mars.text.outOfFuel))
        XCTAssertEqual(last.state.note, "The drive sputters out partway through the day. She is coasting.")
    }

    /// Dry, she coasts at the shared rule's 0.4 and tumbles for the whole day; the status
    /// panel's row is the skin's (`Mars.coasting`).
    func testDryTanksCoastAndTumble() {
        let powered = engine(arc())
        let dry = engine(arc(fuel: 0))
        XCTAssertTrue(Mars.coasting(dry.state))
        _ = powered.sailDay()
        _ = dry.sailDay()
        XCTAssertEqual(dry.state.mile - 16_000, Int(jsRound(370 * 0.4 * Self.jitter)))
        XCTAssertEqual(powered.state.sails - dry.state.sails, MarsData.tumbleWear, accuracy: 1e-9)
        XCTAssertEqual(dry.state.note, "The tanks are dry. She is coasting.")
        XCTAssertTrue(mars.text.outOfFuel.contains("thrusters that keep her pointed"))
        XCTAssertNil(choice(dry.sailDay()), "dry tanks alone ask nothing")
    }

    /// Dark and dry: coasting is coasting, and the dry tanks add no tumble to a dark array.
    func testDarkAndDryCoastAlike() {
        let darkFull = engine(arc(sails: 0.3))
        let darkDry = engine(arc(sails: 0.3, fuel: 0))
        for e in [darkFull, darkDry] {
            _ = e.resolve(choice(e.sailDay())!, option: 2)
            _ = e.sailDay()
        }
        XCTAssertEqual(darkFull.state.mile, darkDry.state.mile)
        XCTAssertEqual(darkFull.state.sails, 0)
        XCTAssertEqual(darkDry.state.sails, 0)
        XCTAssertEqual(darkFull.state.fuel, 500)
    }

    // MARK: - Saves

    func testTheDarkSurvivesASave() throws {
        let e = engine(arc(sails: 0, panels: 1))
        guard let ask = choice(e.sailDay()) else { return XCTFail("not asked") }
        let back = try JSONDecoder().decode(GameState.self, from: JSONEncoder().encode(e.state))
        XCTAssertEqual(choice(engine(back).sailDay()), ask, "loaded in the dark, the same question")
        let pending = try JSONDecoder().decode([Interrupt].self, from: JSONEncoder().encode([Interrupt.choice(ask)]))
        XCTAssertEqual(pending, [.choice(ask)])

        // A day's coast chosen and saved before it is taken: it is taken, then asked again.
        _ = e.resolve(ask, option: 2)
        let f = engine(try JSONDecoder().decode(GameState.self, from: JSONEncoder().encode(e.state)))
        XCTAssertNil(choice(f.sailDay()))
        XCTAssertEqual(f.state.day, 1)
        XCTAssertGreaterThan(f.state.mile, 16_000)
        XCTAssertEqual(key(choice(f.sailDay())), "dark")

        // A coast chosen and then something else done first (a rest): asked again.
        let g = engine(arc(sails: 0))
        _ = g.resolve(choice(g.sailDay())!, option: 2)
        _ = g.rest(days: 1)
        XCTAssertEqual(key(choice(g.sailDay())), "dark")
        XCTAssertEqual(g.state.mile, 16_000)
    }
}
