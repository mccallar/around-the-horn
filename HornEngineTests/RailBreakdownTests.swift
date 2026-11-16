import XCTest
@testable import HornEngine

/// The train's two meters at nought, and the woodpile empty (docs/journeys/rail.md,
/// "Breakdowns"): no meter below 0, a train that has given out stops, and one with no
/// wood crawls.
final class RailBreakdownTests: XCTestCase {
    let rail = Journeys.journey(Rail.id)

    /// A meter as the status panel writes it (`StatusPanel`: `Int(jsRounded(x))`; the web:
    /// `${jsRounded(x)}%`), keeping the sign a negative zero would carry.
    static func shown(_ x: Double) -> String {
        let r = jsRound(x)
        return (r.sign == .minus ? "-" : "") + "\(Int(abs(r)))%"
    }

    /// What one seeded run with nothing to mend with did, turn by turn.
    struct Trace {
        var log: [String] = []
        /// Every value the two meters and the crew's health were stored at after a turn.
        var stored: [Double] = []
        var shown: [String] = []
        /// Damage reports that said more was lost than the meter held.
        var overReported: [String] = []
        /// Miles covered on a turn begun with a meter showing 0%.
        var movedAtZero: [Int] = []
        /// Miles covered on a turn begun with no wood at all.
        var movedWithoutWood: [Int] = []
        var ending: String?
    }

    /// A seeded run out of Omaha in October with no fittings, no car spares, no money and
    /// `fuel` tenths of a cord, answering every question with its first offer.
    func run(seed: UInt64, fuel: Double = 0, turns: Int = 200) -> Trace {
        var s = GameState(journey: Rail.id, role: .merchant, ship: "Juniper", captain: "Amos",
                          crew: ["Clara", "Ned", "Ruth", "Gideon"], startYear: 1869, startMonth: 9)
        s.food = 2000
        s.water = 1200
        s.fuel = fuel
        s.clothes = 5
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
                case .gameOver(let title, _): t.ending = title; return
                case .finale: t.ending = "arrived"; return
                }
            }
        }
        for _ in 0..<turns where !e.state.over {
            let mile = e.state.mile, before = (e.state.sails, e.state.hull)
            let atZero = jsRound(before.0) <= 0 || jsRound(before.1) <= 0
            let noWood = e.state.fuel <= 0
            let n = t.log.count
            play(e.sailDay())
            if e.state.atPort { e.setSail() }
            for m in t.log[n...] {
                for (label, had) in [("Engine", before.0), ("Running gear", before.1)] {
                    guard let r = m.range(of: "(\(label) −") else { continue }
                    let lost = Double(m[r.upperBound...].prefix { $0.isNumber }) ?? 0
                    if lost > jsRound(had) { t.overReported.append("\(label) at \(Self.shown(had)): \(m)") }
                }
            }
            if atZero { t.movedAtZero.append(e.state.mile - mile) }
            if noWood && !atZero { t.movedWithoutWood.append(e.state.mile - mile) }
            t.stored += [e.state.sails, e.state.hull] + e.state.crew.filter(\.alive).map(\.hp)
            t.shown += [Self.shown(e.state.hull), Self.shown(e.state.sails)]
            t.log.append("turn \(e.state.day) mile \(e.state.mile) engine \(Self.shown(e.state.sails)) gear \(Self.shown(e.state.hull)) wood \(e.state.fuel)")
        }
        t.ending = t.ending ?? (e.state.over ? "over" : nil)
        return t
    }

    /// The report from play: the train's health went below 0, and with no wood she ran on just
    /// fine. Before the fix: no meter was ever stored below 0 or as -0, but the damage
    /// reports kept coming at a meter already at 0% ("Engine −13%" with the engine at 0%),
    /// a train whose engine showed 0% ran on at 45% speed with wood and at a quarter of that
    /// without, and a crew member's health could be stored below 0 by a road accident.
    func testNoMeterGoesBelowNoughtAndAGivenOutTrainStops() {
        var t = Trace()
        for seed: UInt64 in 1...120 {
            let r = run(seed: seed, fuel: seed % 2 == 0 ? 160 : 0)
            t.stored += r.stored
            t.shown += r.shown
            t.overReported += r.overReported
            t.movedAtZero += r.movedAtZero
            t.movedWithoutWood += r.movedWithoutWood
        }
        XCTAssertFalse(t.stored.contains { $0 < 0 || $0.sign == .minus }, "a value stored below 0")
        XCTAssertFalse(t.shown.contains { $0.hasPrefix("-") }, "a meter shown below 0")
        XCTAssertEqual(t.overReported.count, 0, "damage reported past nought: \(t.overReported.prefix(2))")
        XCTAssertGreaterThan(t.movedAtZero.count, 0, "some run gave out")
        XCTAssertEqual(t.movedAtZero.filter { $0 > 0 }.count, 0, "a train at 0% moved: \(t.movedAtZero.filter { $0 > 0 }.prefix(10))")
        XCTAssertGreaterThan(t.movedWithoutWood.count, 0, "some run had no wood")
        // A fifth of timetable speed at best: 42 × 0.2 × the jitter's 1.15.
        XCTAssertLessThanOrEqual(t.movedWithoutWood.max() ?? 0, 10, "a turn on no wood ran \(t.movedWithoutWood.max() ?? 0) miles")
    }

    // MARK: - Breaking down

    /// Five aboard on the Platte in October, with `sails`, `hull`, spares and money as given.
    func train(mile: Int = 100, sails: Double = 100, hull: Double = 100, fittings: Int = 0, spares: Int = 0,
               money: Double = 0, fuel: Double = 120) -> GameState {
        var s = GameState(journey: Rail.id, role: .merchant, ship: "Juniper", captain: "Amos",
                          crew: ["Clara", "Ned", "Ruth", "Gideon"], startYear: 1869, startMonth: 9)
        s.mile = mile
        s.stopIndex = rail.stops.lastIndex { $0.mile <= mile } ?? 0
        s.food = 400
        s.water = 600
        s.fuel = fuel
        s.clothes = 5
        s.sails = sails
        s.hull = hull
        s.sailcloth = fittings
        s.timber = spares
        s.money = money
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

    func gameOver(_ q: [Interrupt]) -> String? {
        for i in q { if case .gameOver(let t, _) = i { return t } }
        return nil
    }

    func testAnEngineAtNoughtStopsTheTrainUntilSheIsMended() {
        let e = engine(train(sails: 0.4, fittings: 1, money: 100))
        XCTAssertTrue(Rail.brokenDown(e.state), "0.4 shows as 0%: given out")
        guard let ask = choice(e.sailDay()) else { return XCTFail("no breakdown") }
        XCTAssertEqual(e.state.day, 0, "no time passes for asking")
        XCTAssertEqual(e.state.mile, 100)
        XCTAssertTrue(ask.prompt.hasPrefix("[red]The engine has given out.[/red] The [i]Juniper[/i] stands dead on the line at mile 100"), ask.prompt)
        XCTAssertEqual(ask.options.map(\.label), ["Work on the engine: 1 set of boiler fittings [dim](have 1)[/dim]",
                                                 "Send Clara walking for a mechanic ($45)",
                                                 "Climb down and take stock first"])
        XCTAssertTrue(ask.options.allSatisfy(\.enabled))
        // Asked again, the same question: nothing has changed.
        XCTAssertEqual(choice(e.sailDay()), ask)

        // Taking stock first goes to the menu and changes nothing.
        XCTAssertEqual(e.resolve(ask, option: 2), [.enterPort])
        XCTAssertEqual(e.state.day, 0)

        let q = e.resolve(ask, option: 0)
        XCTAssertEqual(e.state.sailcloth, 0)
        XCTAssertEqual(e.state.sails, 25.4, accuracy: 1e-9)
        XCTAssertEqual(e.state.day, 1, "four hours with wrenches")
        XCTAssertTrue(messages(q).last?.hasSuffix("[green](Engine now 25%)[/green]") == true, "\(messages(q))")
        XCTAssertFalse(Rail.brokenDown(e.state))
        _ = e.sailDay()
        XCTAssertGreaterThan(e.state.mile, 100, "and she rolls again")
    }

    func testRunningGearAtNoughtIsABreakdownNotAWreck() {
        // Worn to nothing under way: no wreck, and the next turn she stands.
        let e = engine(train(hull: 0.6, spares: 1))
        XCTAssertFalse(Rail.brokenDown(e.state), "0.6 shows as 1%")
        let q = e.sailDay()
        XCTAssertNil(gameOver(q))
        XCTAssertFalse(e.state.over)
        XCTAssertTrue(Rail.brokenDown(e.state))
        let worn = e.state.hull
        let mile = e.state.mile
        guard let ask = choice(e.sailDay()) else { return XCTFail("no breakdown") }
        XCTAssertEqual(e.state.mile, mile)
        XCTAssertTrue(ask.prompt.hasPrefix("[red]The running gear has given out.[/red]"), ask.prompt)
        XCTAssertEqual(ask.options[0].label, "Mend the running gear: 1 crate of car spares [dim](have 1)[/dim]")
        XCTAssertFalse(ask.options[1].enabled, "no money for a mechanic")
        _ = e.resolve(ask, option: 0)
        XCTAssertEqual(e.state.hull, worn + 20, accuracy: 1e-9)
        XCTAssertNil(choice(e.sailDay()))
        XCTAssertGreaterThan(e.state.mile, mile)
    }

    func testBothGivenOutAsksForBoth() {
        let e = engine(train(sails: 0, hull: 0, fittings: 1, spares: 1))
        guard let ask = choice(e.sailDay()) else { return XCTFail("no breakdown") }
        XCTAssertTrue(ask.prompt.hasPrefix("[red]The engine and the running gear have both given out.[/red]"), ask.prompt)
        XCTAssertEqual(ask.options.count, 4)
        // The running gear first, as the condition box lists it, then the engine.
        XCTAssertTrue(ask.options[0].label.hasPrefix("Mend the running gear"), ask.options[0].label)
        XCTAssertTrue(ask.options[1].label.hasPrefix("Work on the engine"), ask.options[1].label)
        _ = e.resolve(ask, option: 1)
        XCTAssertEqual(e.state.sails, 25)
        // Still standing on the running gear: asked again, for that alone.
        guard let again = choice(e.sailDay()) else { return XCTFail("still broken down") }
        XCTAssertEqual(again.options.count, 3)
        _ = e.resolve(again, option: 0)
        XCTAssertFalse(Rail.brokenDown(e.state))
    }

    func testAMechanicWalkedForCostsTimeMoneyAndShoeLeather() {
        let e = engine(train(sails: 0, hull: 0, money: 100), [], fallback: 0)
        for i in 2..<e.state.crew.count { e.state.crew[i].hp = 90 }
        guard let ask = choice(e.sailDay()) else { return XCTFail("no breakdown") }
        XCTAssertEqual(ask.options[2].label, "Send Clara walking for a mechanic ($45)", "the fittest goes")
        XCTAssertFalse(ask.options[0].enabled || ask.options[1].enabled)
        let q = e.resolve(ask, option: 2)
        XCTAssertEqual(e.state.money, 55)
        XCTAssertEqual(e.state.day, 3, "twelve hours at the least")
        XCTAssertEqual(e.state.sails, 40)
        XCTAssertEqual(e.state.hull, 40)
        let said = messages(q)
        XCTAssertTrue(said.first?.hasPrefix("Clara sets off down the ties") == true, "\(said)")
        XCTAssertTrue(said.contains { $0.hasPrefix("A handcar comes clacking up the line") && $0.hasSuffix("[green](Engine 40%, Running gear 40%)[/green]") }, "\(said)")
        XCTAssertLessThan(e.state.crew[1].hp, 100, "Clara walked it")
        XCTAssertNotNil(e.state.crew[1].ailment, "and, this time, came back with something")
        _ = e.sailDay()
        XCTAssertGreaterThan(e.state.mile, 100)
    }

    func testAConductorAloneWalksAlone() {
        let e = engine(train(sails: 0, money: 100))
        for i in 1..<e.state.crew.count { e.state.crew[i].alive = false }
        guard let ask = choice(e.sailDay()) else { return XCTFail("no breakdown") }
        XCTAssertEqual(ask.options[1].label, "Walk down the line for a mechanic yourself ($45)")
        let q = e.resolve(ask, option: 1)
        XCTAssertTrue(messages(q).first?.hasPrefix("You leave the train") == true)
        XCTAssertFalse(Rail.brokenDown(e.state))
    }

    func testNothingToMendWithAndNoMoneyIsStranded() {
        let e = engine(train(mile: 760, sails: 0, fittings: 0, spares: 3, money: 44))
        let q = e.sailDay()
        XCTAssertEqual(gameOver(q), "Stranded at mile 760.")
        XCTAssertTrue(e.state.over)
        // Fittings for the engine are no help when the running gear is what has gone.
        let gear = engine(train(hull: 0, fittings: 3, spares: 0))
        XCTAssertEqual(gameOver(gear.sailDay()), "Stranded at mile 100.")
    }

    /// Standing at North Platte, where she gave out on the turn she pulled in.
    func inTheYard(sails: Double = 0, hull: Double = 100, fittings: Int = 0, spares: Int = 0, money: Double) -> GameState {
        var s = train(mile: 291, sails: sails, hull: hull, fittings: fittings, spares: spares, money: money)
        s.stopIndex = rail.stops.firstIndex { $0.id == "northplatte" }!
        return s
    }

    func testGivenOutInAYardGoesToTheRoundhouse() {
        let e = engine(inTheYard(money: 200))
        guard let ask = choice(e.sailDay()) else { return XCTFail("no breakdown") }
        XCTAssertTrue(ask.prompt.contains("will not leave North Platte like this"), ask.prompt)
        XCTAssertEqual(ask.options.map(\.label), ["Work on the engine: 1 set of boiler fittings [dim](have 0)[/dim]",
                                                 "Climb down into the yard: the store and the roundhouse"])
        XCTAssertFalse(ask.options[0].enabled)
        XCTAssertEqual(e.state.day, 0)
        XCTAssertEqual(e.resolve(ask, option: 1), [.enterPort])
        XCTAssertTrue(e.state.atPort)
        XCTAssertTrue(e.canRecutSailsAtYard)
        _ = e.recutSailsAtYard()
        XCTAssertFalse(Rail.brokenDown(e.state))
        e.setSail()
        _ = e.sailDay()
        XCTAssertGreaterThan(e.state.mile, 291)

        XCTAssertEqual(gameOver(engine(inTheYard(money: 0)).sailDay()), "Stranded at North Platte.", "no spares, no money, not even for a set of fittings")
        XCTAssertEqual(gameOver(engine(inTheYard(sails: 100, hull: 0, fittings: 2, money: 12)).sailDay()), "Stranded at North Platte.",
                       "fittings are no use to the running gear, and a crate of car spares is $12.65 here")
    }

    /// Found by review: a train that gave out in a yard with a spare aboard, or the money for
    /// one but not for the roundhouse, went back to the yard every time she was sent on, and
    /// nothing in the yard could mend her.
    func testGivenOutInAYardWithASpareOrTheMoneyForOneGetsGoing() {
        // A set of fittings aboard: fitted from the question, with or without money.
        for money in [0.0, 30] {
            let e = engine(inTheYard(fittings: 1, money: money))
            guard let ask = choice(e.sailDay()) else { return XCTFail("no breakdown") }
            XCTAssertTrue(ask.options[0].enabled)
            _ = e.resolve(ask, option: 0)
            XCTAssertEqual(e.state.sails, 25)
            XCTAssertEqual(e.state.day, 1)
            _ = e.sailDay()
            XCTAssertGreaterThan(e.state.mile, 291, "with $\(money)")
        }
        // $20 and no fittings: the store sells a set for $16.10, and it goes in.
        let e = engine(inTheYard(money: 20))
        guard let ask = choice(e.sailDay()) else { return XCTFail("no breakdown") }
        XCTAssertEqual(e.resolve(ask, option: 1), [.enterPort])
        XCTAssertTrue(e.state.atPort)
        XCTAssertFalse(e.canRecutSailsAtYard, "the roundhouse is beyond $20")
        XCTAssertTrue(e.buy([.sailcloth: 1]))
        e.setSail()
        guard let again = choice(e.sailDay()) else { return XCTFail("still broken down") }
        XCTAssertTrue(again.options[0].enabled)
        _ = e.resolve(again, option: 0)
        XCTAssertFalse(Rail.brokenDown(e.state))
        _ = e.sailDay()
        XCTAssertGreaterThan(e.state.mile, 291)

        // Both out: a crate of car spares bought for the running gear, the fittings aboard.
        let both = engine(inTheYard(hull: 0, fittings: 1, money: 13))
        guard let two = choice(both.sailDay()) else { return XCTFail("no breakdown") }
        XCTAssertEqual(two.options.count, 3)
        XCTAssertFalse(two.options[0].enabled, "no car spares aboard")
        _ = both.resolve(two, option: 2)
        XCTAssertTrue(both.buy([.timber: 1]))
        both.setSail()
        for _ in 0..<2 {
            guard let q = choice(both.sailDay()) else { return XCTFail("still broken down") }
            _ = both.resolve(q, option: q.options.firstIndex(where: \.enabled)!)
        }
        XCTAssertFalse(Rail.brokenDown(both.state))
    }

    func testTheTrestleAndTheRunawayCanStillWreckHer() {
        let e = engine(train(mile: 1669, hull: 10), [0, 0])
        guard let ask = choice(e.beginArrival("donner")) else { return XCTFail("no choice") }
        let q = e.resolve(ask, option: 1)
        XCTAssertEqual(gameOver(q), "The [i]Juniper[/i] is off the rails.")
        XCTAssertTrue(messages(q).first?.hasSuffix("[red](Running gear −10%)[/red]") == true, "the loss as the box shows it: \(messages(q))")
    }

    func testDamageIsNeverReportedPastNought() {
        let r = rail as! Rail
        let e = engine(train(sails: 3.4, hull: 0.3))
        XCTAssertEqual(r.knock(e, engine: true, 13), " [red](Engine −3%)[/red]")
        XCTAssertEqual(e.state.sails, 0)
        XCTAssertEqual(e.state.sails.sign, .plus)
        XCTAssertEqual(r.knock(e, engine: false, 5), "", "a meter already showing 0% loses nothing it can show")
        XCTAssertEqual(e.state.hull, 0)
        XCTAssertEqual(r.knock(e, engine: true, 6), "")
        XCTAssertEqual(e.state.sails.sign, .plus)
    }

    func testABreakdownSurvivesASave() throws {
        let e = engine(train(sails: 0, fittings: 2, money: 60))
        guard let ask = choice(e.sailDay()) else { return XCTFail("no breakdown") }
        let back = try JSONDecoder().decode(GameState.self, from: JSONEncoder().encode(e.state))
        let f = engine(back)
        XCTAssertEqual(choice(f.sailDay()), ask, "loaded mid-breakdown, the same question")
        _ = f.resolve(ask, option: 0)
        XCTAssertEqual(f.state.sails, 25)
        let pending = try JSONDecoder().decode([Interrupt].self, from: JSONEncoder().encode([Interrupt.choice(ask)]))
        XCTAssertEqual(pending, [.choice(ask)])
    }

    // MARK: - Out of wood

    func testWithNoWoodSheCrawlsAndItWearsTheEngine() {
        let wood = engine(train(fuel: 120), [], fallback: 0.5)
        let none = engine(train(fuel: 0), [], fallback: 0.5)
        _ = wood.sailDay()
        let q = none.sailDay()
        let full = wood.state.mile - 100, crawl = none.state.mile - 100
        XCTAssertGreaterThan(full, 30)
        XCTAssertEqual(Double(crawl), Double(full) * RailData.noWoodSpeed, accuracy: 1, "\(crawl) of \(full) miles")
        XCTAssertEqual(wood.state.sails - none.state.sails, 1, accuracy: 1e-9, "fence posts take a point off the engine")
        XCTAssertEqual(messages(q).first, rail.text.outOfFuel)
        XCTAssertTrue(rail.text.outOfFuel.contains("will barely move her"))
        XCTAssertEqual(none.state.note, "No wood. The firebox is getting fence posts, sagebrush and anything else that will burn.")
        XCTAssertNil(none.state.vars[Rail.noWoodKey], "nothing left over in the save")

        // Wood again: full speed and no extra wear.
        none.state.fuel = 50
        let mile = none.state.mile, sails = none.state.sails
        _ = none.sailDay()
        XCTAssertGreaterThan(none.state.mile - mile, 30)
        XCTAssertLessThan(sails - none.state.sails, 3)
        XCTAssertNotEqual(none.state.note, "No wood. The firebox is getting fence posts, sagebrush and anything else that will burn.")
    }

    /// The last cord burnt is a turn at full steam: only a turn begun short of wood crawls.
    /// Found by review: the warning that came with it said she was barely moving.
    func testTheLastCordIsBurntAtFullSpeed() {
        let e = engine(train(fuel: 10), [], fallback: 0.5)
        let sails = e.state.sails
        let q = e.sailDay()
        XCTAssertEqual(e.state.fuel, 0)
        XCTAssertGreaterThan(e.state.mile - 100, 30)
        XCTAssertNil(e.state.vars[Rail.noWoodKey])
        XCTAssertLessThan(sails - e.state.sails, 1, "no fence posts yet")
        XCTAssertTrue(messages(q).contains(rail.text.outOfFuel))
        XCTAssertTrue(rail.text.outOfFuel.contains("From here"), "the warning looks ahead: \(rail.text.outOfFuel)")
        XCTAssertFalse(rail.text.outOfFuel.contains("You are barely moving"))
    }

    /// Found by review: part of a cord, less than the pace burns, was thrown away and the turn
    /// crawled as if there were none. It burns for its share of the turn.
    func testAPartCordIsBurntForItsShare() {
        let full = engine(train(fuel: 120), [], fallback: 0.5)
        let part = engine(train(fuel: 6), [], fallback: 0.5)
        _ = full.sailDay()
        _ = part.sailDay()
        let ran = Double(full.state.mile - 100)
        // Six tenths at full speed and four at a fifth: 0.68 of the turn.
        XCTAssertEqual(Double(part.state.mile - 100), ran * (0.6 + 0.4 * RailData.noWoodSpeed), accuracy: 1)
        XCTAssertEqual(part.state.fuel, 0)
        XCTAssertEqual(full.state.sails - part.state.sails, 0.4, accuracy: 1e-9, "fence posts for four tenths of the turn")
        XCTAssertEqual(part.state.note, "The wood gives out partway, and the fireman finishes the run on fence posts.")
        XCTAssertNil(part.state.vars[Rail.noWoodKey])
    }

    /// Found by review: with an empty tender the road still took wood from her ("sand,
    /// patience and 1.2 cords"), and offered the dash ahead of the express and bucking a
    /// drift, which burn it by the cord.
    func testNoWoodIsNeverBurntThatIsNotThere() {
        var s = GameState(journey: Rail.id, role: .merchant, ship: "Juniper", captain: "Amos",
                          crew: ["Clara", "Ned", "Ruth", "Gideon"], startYear: 1869, startMonth: 11)
        s.mile = 545
        s.stopIndex = rail.stops.lastIndex { $0.mile <= 545 }!
        s.food = 400
        s.water = 900
        s.atPort = false
        let r = rail as! Rail
        for fuel in [0.0, 5, 15, 30] {
            s.fuel = fuel
            let e = engine(s, [], fallback: 0.5)
            let reg = e.state.region
            XCTAssertEqual(reg.id, "sherman")
            var said: [String] = [], options: [ChoiceEvent.Option] = []
            for ev in r.roadEvents(e, reg) where ev.ok {
                let f = engine(s, [], fallback: 0.5)
                var q: [Interrupt] = []
                ev.run(f, &q)
                said += messages(q)
                options += q.compactMap { if case .choice(let c) = $0 { return c } else { return nil } }.flatMap(\.options)
                XCTAssertGreaterThanOrEqual(f.state.fuel, 0)
            }
            let spin = said.first { $0.hasPrefix("The drivers lose their feet") }
            XCTAssertEqual(spin == nil, fuel < 1, "\(fuel): \(spin ?? "no spin")")
            if let spin, fuel < 8 { XCTAssertTrue(spin.contains("and \(RailData.cords(Int(fuel))) of wood"), "all there was: \(spin)") }
            let dash = options.first { $0.label.hasPrefix("Run for the next station, wide open") }
            let buck = options.first { $0.label.hasPrefix("Back up, open the throttle and buck it") }
            XCTAssertEqual(dash?.enabled, fuel >= 22, "\(fuel)")
            XCTAssertEqual(buck?.enabled, fuel >= 16, "\(fuel)")
            if fuel < 16 { XCTAssertEqual(buck?.label, "Back up, open the throttle and buck it [dim](not on the wood aboard)[/dim]") }
        }
    }

    // MARK: - Set pieces

    /// Found by review: a train that gave out on the turn she reached Donner Summit was
    /// still asked how to come down it, and "She comes off the mountain singing" with the
    /// running gear at 0%. The question waits until she is mended, and survives a save.
    func testASetPieceWaitsUntilSheIsMended() throws {
        let e = engine(train(mile: 1665, hull: 0.6, spares: 1), [], fallback: 0.5)
        XCTAssertEqual(e.state.currentStop.id, "reno")
        var q = e.sailDay()
        XCTAssertTrue(Rail.brokenDown(e.state))
        XCTAssertEqual(q.last, .arrival(stopID: "donner"))
        q = e.beginArrival("donner")
        XCTAssertEqual(q, [.message("The [i]Juniper[/i] gets as far as Donner Summit, and not a foot further.")])
        XCTAssertNil(choice(q))
        let day = e.state.day

        let f = engine(try JSONDecoder().decode(GameState.self, from: JSONEncoder().encode(e.state)), [], fallback: 0.5)
        guard let ask = choice(f.sailDay()) else { return XCTFail("no breakdown") }
        XCTAssertTrue(ask.prompt.hasPrefix("[red]The running gear has given out.[/red]"), ask.prompt)
        _ = f.resolve(ask, option: 0)
        XCTAssertFalse(Rail.brokenDown(f.state))
        let mended = f.state.day
        XCTAssertEqual(mended, day + 1)
        guard let donner = choice(f.sailDay()), case .custom("donner", _) = donner.kind else { return XCTFail("no Donner") }
        XCTAssertEqual(f.state.day, mended, "the question takes no time")
        XCTAssertEqual(f.state.mile, 1669)
        XCTAssertNil(f.state.vars[Rail.heldKey])
        _ = f.resolve(donner, option: 0)
        XCTAssertEqual(f.state.vars["rail.retainers"], 1)
        _ = f.sailDay()
        XCTAssertGreaterThan(f.state.mile, 1669)
    }
}
