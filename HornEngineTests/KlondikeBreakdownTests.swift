import XCTest
@testable import HornEngine

/// To the Klondike's two meters at nought, and no firewood (docs/journeys/klondike.md, "As
/// built", D14): no meter or health below 0, sleds or oars that show 0% stop the party until
/// they are mended, Miles Canyon and Five Fingers wait for a sweep, an outfit or a boat that
/// shows 0% is the end, and a day without a fire is costed and shown.
final class KlondikeBreakdownTests: XCTestCase {
    let klondike = Journeys.journey(Klondike.id)
    var k: Klondike { klondike as! Klondike }

    /// A meter as the status panel writes it (`Int(jsRound(x))`), keeping the sign a negative
    /// zero would carry.
    static func shown(_ x: Double) -> String {
        let r = jsRound(x)
        return (r.sign == .minus ? "-" : "") + "\(Int(abs(r)))%"
    }

    /// Five in the party at `mile` (tenths), in fair weather for six days. On the trail in
    /// March unless told otherwise; `boat` puts them afloat with a boat built at Bennett.
    func party(mile: Int = 11_250, month: Int = 2, role: Role = .merchant, boat: Bool = false,
               sails: Double = 100, hull: Double = 100, rope: Int = 0, money: Double = 0) -> GameState {
        var s = GameState(journey: Klondike.id, role: role, ship: "Klondike Belle", captain: "Will",
                          crew: ["Martha", "Gus", "Clara", "Ed"], startYear: 1898, startMonth: month)
        s.mile = mile
        s.stopIndex = klondike.stops.lastIndex { $0.mile <= mile } ?? 0
        s.vars[KlondikeData.routeKey] = KlondikeData.chilkoot
        if boat { s.vars[KlondikeData.boatKey] = 1 }
        s.food = 6000
        s.water = 1000
        s.limes = 5
        s.meds = 2
        s.clothes = 5
        s.sailcloth = rope
        s.timber = 0
        s.tackle = 60
        s.sails = sails
        s.hull = hull
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

    static let sleds = "[red]Your sleds have given out.[/red] Split runners, knotted straps, harness in pieces: there is no moving a ton of outfit along the trail until they are mended."
    static let oars = "[red]The oars and sail have given out.[/red] With no sweep to steer by, the [i]Klondike Belle[/i] goes wherever the water likes, so you work her into the bank and tie up. She stays there until she is re-rigged."
    static let ruined = "Your outfit is ruined."
    static let brokenUp = "The [i]Klondike Belle[/i] has broken up."

    // MARK: - A seeded run

    struct Trace {
        var stored: [Double] = []
        var shown: [String] = []
        var overReported: [String] = []
        /// Distance made on a turn begun with the sleds or the oars given out, or the outfit or
        /// the boat showing 0%.
        var movedGivenOut: [Int] = []
        var movedWithNoHull: [Int] = []
        var madeDo = 0
        var afloat = 0
        var endings: [String] = []
    }

    /// A seeded run from the Taiya valley in March with the meters worn as given, nothing to
    /// mend with and `money` in hand, through Bennett (a raft, then the ice) and down the
    /// river. Every question takes its first offer.
    func run(seed: UInt64, sails: Double, hull: Double, money: Double, turns: Int = 160) -> Trace {
        var s = party(sails: sails, hull: hull, money: money)
        s.forceFair = 0
        s.food = 9000
        s.water = 2000
        let e = GameEngine(state: s, rng: SeededRNG(seed: seed))
        var t = Trace()
        var log: [String] = []
        func play(_ q: [Interrupt]) {
            var q = q
            while !q.isEmpty {
                switch q.removeFirst() {
                case .message(let s): log.append(s)
                case .choice(let c):
                    log.append(c.prompt)
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
            if e.state.atPort { play(e.setSail()) }
            if e.state.over || e.state.atPort { continue }
            let mile = e.state.mile
            let before = (hull: e.state.hull, drive: e.state.sails)
            let givenOut = Klondike.givenOut(e.state), noHull = jsRound(e.state.hull) <= 0
            if Klondike.hasBoat(e.state) { t.afloat += 1 }
            let n = log.count
            play(e.sailDay())
            for line in log[n...] {
                for (label, had) in [("Outfit", before.hull), ("Boat", before.hull), ("Sleds", before.drive), ("Oars & sail", before.drive)] {
                    guard let r = line.range(of: "(\(label) −") ?? line.range(of: ", \(label) −") else { continue }
                    let lost = Double(line[r.upperBound...].prefix { $0.isNumber }) ?? 0
                    if lost > jsRound(had) { t.overReported.append("\(label) at \(Self.shown(had)): \(line)") }
                }
                if line.hasPrefix("Two days of knocking crates apart") || line.hasPrefix("Two days with an axe") { t.madeDo += 1 }
            }
            if givenOut { t.movedGivenOut.append(e.state.mile - mile) }
            if noHull { t.movedWithNoHull.append(e.state.mile - mile) }
            t.stored += [e.state.sails, e.state.hull, e.state.water, e.state.food, e.state.money]
                + e.state.crew.filter(\.alive).map(\.hp)
            t.shown += [Self.shown(e.state.hull), Self.shown(e.state.sails)]
        }
        return t
    }

    /// The report from play on the Iron Road, checked here: a meter below 0, and the train
    /// moving just fine with nothing to burn. Before the fix nothing was stored below 0, but
    /// sleds or oars at 0% carried the party on at 45% of its pace (the March miner's bot did
    /// so for 21 days in two runs of 30), an outfit under half a point showed 0% and went on,
    /// and damage was reported past what the meter had.
    func testNoMeterGoesBelowNoughtAndNothingCarriesOnAsNormalAtNought() {
        var t = Trace()
        for seed: UInt64 in 1...60 {
            let r = run(seed: seed, sails: [6, 12, 30][Int(seed % 3)], hull: [9, 40, 70][Int(seed / 3 % 3)],
                        money: seed % 2 == 0 ? 0 : 60)
            t.stored += r.stored
            t.shown += r.shown
            t.overReported += r.overReported
            t.movedGivenOut += r.movedGivenOut
            t.movedWithNoHull += r.movedWithNoHull
            t.madeDo += r.madeDo
            t.afloat += r.afloat
            t.endings += r.endings
        }
        XCTAssertFalse(t.stored.contains { $0 < 0 || $0.sign == .minus }, "a value stored below 0")
        XCTAssertFalse(t.shown.contains { $0.hasPrefix("-") }, "a meter shown below 0")
        XCTAssertEqual(t.overReported.count, 0, "damage reported past nought: \(t.overReported.prefix(2))")
        XCTAssertGreaterThan(t.movedGivenOut.count, 0, "some party's sleds or oars gave out")
        XCTAssertEqual(t.movedGivenOut.filter { $0 != 0 }.count, 0, "moved on with the sleds or oars at 0%")
        XCTAssertEqual(t.movedWithNoHull.filter { $0 != 0 }.count, 0, "moved on with the outfit or boat at 0%")
        XCTAssertGreaterThan(t.madeDo, 0, "some party made do")
        XCTAssertGreaterThan(t.afloat, 0, "some party reached the river")
        XCTAssertTrue(t.endings.contains(Self.ruined), "\(Set(t.endings))")
    }

    // MARK: - Sleds and oars given out

    /// Worn to 0.25 by a day's travel, which shows 0%: nothing else happens that day, and the
    /// next is a question that takes no time and draws nothing.
    func testSledsWornToNoughtStopTheParty() {
        let e = engine(party(sails: 0.6, money: 30))
        let q = e.sailDay()
        XCTAssertNil(choice(q))
        XCTAssertEqual(e.state.sails, 0.6 - 0.25 * (0.6 + 0.8 * 0.999), accuracy: 1e-9)
        XCTAssertTrue(Klondike.givenOut(e.state))
        let mile = e.state.mile, day = e.state.day
        let draws = (e.rng as! ScriptedRNG).draws

        guard let ask = choice(e.sailDay()) else { return XCTFail("moved on with the sleds at 0%") }
        XCTAssertEqual(key(ask), "givenout")
        XCTAssertEqual(ask.prompt, Self.sleds)
        XCTAssertEqual(ask.detail, "A coil of rope & rawhide mends them in a day. The trail is never empty, and somebody on it will sell you a coil for $24, three times the Seattle price. Or you can lash up pack boards from the crates you have already emptied: two days' work, for gear that will barely hold (Sleds 10%).\n[dim]You have $30.[/dim]")
        XCTAssertEqual(ask.options.map(\.label), ["Mend the sleds: 1 coil of rope & rawhide [dim](have 0)[/dim]",
                                                 "Buy a coil off the next party along ($24)",
                                                 "Lash up pack boards from empty crates and sacking (2 days)",
                                                 "Take stock first"])
        XCTAssertEqual(ask.options.map(\.enabled), [false, true, true, true])
        XCTAssertEqual(e.state.mile, mile)
        XCTAssertEqual(e.state.day, day)
        XCTAssertEqual((e.rng as! ScriptedRNG).draws, draws, "asking draws nothing")
        XCTAssertEqual(choice(e.sailDay()), ask, "asked again, every time")
        XCTAssertEqual(KlondikeData.coilPrice, 3 * klondike.item(.sailcloth).price, "three times the Seattle price")
    }

    func testRopeAboardMendsThemInADay() {
        let e = engine(party(role: .shipwright, sails: 0, rope: 3, money: 500))
        guard let ask = choice(e.sailDay()) else { return XCTFail("not asked") }
        XCTAssertEqual(ask.options.map(\.label), ["Mend the sleds: 1 coil of rope & rawhide [dim](have 3)[/dim]",
                                                 "Lash up pack boards from empty crates and sacking (2 days)",
                                                 "Take stock first"], "nothing to buy with rope aboard")
        XCTAssertEqual(ask.detail, "A coil of rope & rawhide mends them in a day. Or you can lash up pack boards from the crates you have already emptied: two days' work, for gear that will barely hold (Sleds 10%).")
        let q = e.resolve(ask, option: 0)
        XCTAssertEqual(e.state.sailcloth, 2)
        XCTAssertEqual(e.state.sails, 40, "the boatbuilder's mend")
        XCTAssertEqual(e.state.day, 1)
        XCTAssertEqual(messages(q).last, "A day of splicing, lacing and shaving new runners. [green](Sleds now 40%)[/green]")
        XCTAssertNil(choice(e.sailDay()))
        XCTAssertGreaterThan(e.state.mile, 11_250)
    }

    func testACoilOffThePartyAlongCosts24AndADay() {
        let e = engine(party(sails: 0, money: 30))
        let q = e.resolve(choice(e.sailDay())!, option: 1)
        XCTAssertEqual(e.state.money, 6)
        XCTAssertEqual(e.state.sailcloth, 0)
        XCTAssertEqual(e.state.sails, 25)
        XCTAssertEqual(e.state.day, 1)
        XCTAssertEqual(messages(q).first, "A packer coming down the trail with an empty sled sells you a coil of his rope, at his price.")
        XCTAssertEqual(messages(q).last, "A day of splicing, lacing and shaving new runners. [green](Sleds now 25%)[/green]")

        let broke = engine(party(sails: 0, money: 23))
        XCTAssertEqual(choice(broke.sailDay())?.options.map(\.enabled), [false, false, true, true])
    }

    /// Always there, so nobody is stuck: two days' hard work as the trail counts it (no
    /// miles, no rest) for 10 points.
    func testMakingDoIsTwoDaysHardWorkForTenPoints() {
        var s = party(sails: 0.3)
        for i in s.crew.indices { s.crew[i].hp = 60 }
        let e = engine(s)
        let resting = engine(s)
        let q = e.resolve(choice(e.sailDay())!, option: 2)
        _ = resting.rest(days: 2)
        XCTAssertEqual(e.state.day, 2)
        XCTAssertEqual(e.state.mile, 11_250)
        XCTAssertEqual(e.state.sails, 10.3, accuracy: 1e-9)
        XCTAssertEqual(messages(q).last, "Two days of knocking crates apart and lacing sacking into straps. The pack boards are ugly and they creak, but they carry. [green](Sleds now 10%)[/green]")
        XCTAssertLessThan(e.state.averageHP, resting.state.averageHP, "work, not rest")
        XCTAssertEqual(e.state.food, resting.state.food, "and eaten all the same")
        XCTAssertNil(choice(e.sailDay()))
        XCTAssertGreaterThan(e.state.mile, 11_250)
    }

    func testTakingStockIsTheMenu() {
        let e = engine(party(sails: 0))
        let ask = choice(e.sailDay())!
        XCTAssertEqual(e.resolve(ask, option: 3), [.enterPort])
        XCTAssertEqual(e.state.day, 0)
        XCTAssertFalse(e.state.atPort)
        XCTAssertEqual(choice(e.sailDay()), ask)
    }

    /// Afloat it is the oars & sail, in the river's words, and the work is a spruce.
    func testOarsGivenOutTieTheBoatToTheBank() {
        let e = engine(party(mile: 12_100, month: 5, boat: true, sails: 0))
        guard let ask = choice(e.sailDay()) else { return XCTFail("floated on with the oars at 0%") }
        XCTAssertEqual(ask.prompt, Self.oars)
        XCTAssertEqual(ask.detail, "A coil of rope & rawhide re-rigs her in a day. Boats go by all day, and somebody in one will part with a coil for $24, three times the Seattle price. Or you can cut a new sweep and a pair of oars from a spruce on the bank: two days' work, and they will barely do (Oars & sail 10%).\n[dim]You have $0.[/dim]")
        XCTAssertEqual(ask.options.map(\.label), ["Re-rig the oars & sail: 1 coil of rope & rawhide [dim](have 0)[/dim]",
                                                 "Buy a coil off the next boat along ($24)",
                                                 "Cut a sweep and oars from a spruce on the bank (2 days)",
                                                 "Take stock first"])
        let q = e.resolve(ask, option: 2)
        XCTAssertEqual(messages(q).last, "Two days with an axe and a drawknife turn a spruce on the bank into a sweep and a pair of oars, green and heavy. She answers again, more or less. [green](Oars & sail now 10%)[/green]")
        XCTAssertEqual(e.state.mile, 12_100)

        let f = engine(party(mile: 12_100, month: 5, boat: true, sails: 0, rope: 1))
        let r = f.resolve(choice(f.sailDay())!, option: 0)
        XCTAssertEqual(messages(r).last, "You shave a new oar from a spruce and lace up the sail. [green](Oars & sail now 25%)[/green]")

        let g = engine(party(mile: 12_100, month: 5, boat: true, sails: 0, money: 24))
        let b = g.resolve(choice(g.sailDay())!, option: 1)
        XCTAssertEqual(messages(b).first, "A boat drifting by pulls in long enough to sell you a coil of rope, at their price.")
        XCTAssertEqual(g.state.money, 0)
    }

    /// The steamer goes north whatever the sleds in her hold are like.
    func testTheSteamerCarriesSledsAtNought() {
        let e = engine(party(mile: 5_000, sails: 0))
        XCTAssertFalse(Klondike.givenOut(e.state))
        XCTAssertNil(choice(e.sailDay()))
        XCTAssertGreaterThan(e.state.mile, 5_000)
    }

    // MARK: - Set pieces that need a sweep

    /// Miles Canyon reached on the day the oars give out waits for a sweep, and so does the
    /// question, across a save; mended, the canyon comes first and takes no time.
    func testMilesCanyonWaitsForASweep() throws {
        let e = engine(party(mile: 12_480, month: 5, boat: true, sails: 0.6, rope: 1))
        XCTAssertEqual(e.sailDay().last, .arrival(stopID: "canyon"))
        XCTAssertTrue(Klondike.givenOut(e.state))
        let q = e.beginArrival("canyon")
        XCTAssertEqual(q, [.message("The [i]Klondike Belle[/i] comes down to Miles Canyon with no sweep to steer by, and you tie her up to the bank above the fast water. Nobody takes a boat into Miles Canyon without a sweep.")])
        let day = e.state.day

        let f = engine(try JSONDecoder().decode(GameState.self, from: JSONEncoder().encode(e.state)))
        guard let ask = choice(f.sailDay()) else { return XCTFail("not asked") }
        XCTAssertEqual(ask.prompt, Self.oars + " Nobody takes a boat into Miles Canyon without a sweep.")
        _ = f.resolve(ask, option: 0)
        XCTAssertEqual(f.state.day, day + 1)
        let canyon = choice(f.sailDay())
        XCTAssertEqual(key(canyon), "canyon")
        XCTAssertEqual(f.state.day, day + 1, "the canyon takes no time to reach")
        XCTAssertEqual(f.state.mile, 12_530)
        XCTAssertNil(f.state.vars[KlondikeData.heldKey])
        _ = f.resolve(canyon!, option: 0)
        _ = f.sailDay()
        XCTAssertGreaterThan(f.state.mile, 12_530)
    }

    func testFiveFingersWaitsToo() {
        let e = engine(party(mile: 14_620, month: 5, boat: true, sails: 0.6))
        XCTAssertEqual(e.sailDay().last, .arrival(stopID: "fivefinger"))
        XCTAssertEqual(messages(e.beginArrival("fivefinger")), ["The [i]Klondike Belle[/i] comes down to Five Finger Rapids with no sweep to steer by, and you tie her up to the bank above the fast water. Nobody takes a boat through Five Fingers without a sweep."])
        XCTAssertEqual(choice(e.sailDay())?.prompt, Self.oars + " Nobody takes a boat through Five Fingers without a sweep.")
    }

    /// The police weigh grub, not sleds: the summit is met as usual.
    func testThePoliceDoNotWaitForSleds() {
        let e = engine(party(mile: 11_360, sails: 0.6))
        XCTAssertEqual(e.sailDay().last, .arrival(stopID: "summit"))
        XCTAssertTrue(Klondike.givenOut(e.state))
        XCTAssertEqual(key(choice(e.beginArrival("summit"))), "police")
    }

    // MARK: - The outfit and the boat at nothing

    func testAnOutfitThatShowsNoughtIsRuined() {
        // Worn to 0.49 by a day's creep, which shows 0%: all of it goes.
        let e = engine(party(hull: 0.52))
        guard let end = gameOver(e.sailDay()) else { return XCTFail("went on with the outfit at 0%") }
        XCTAssertEqual(end.title, Self.ruined)
        XCTAssertTrue(end.body.hasSuffix("nothing to show the police. You sell the scraps for a ticket home."))
        XCTAssertTrue(e.state.over)
        XCTAssertEqual(e.state.hull, 0)

        // Already showing 0% (an older save): it goes before another day.
        let f = engine(party(hull: 0.3))
        XCTAssertEqual(gameOver(f.sailDay())?.title, Self.ruined)
        XCTAssertEqual(f.state.day, 0)
        XCTAssertEqual(f.state.hull, 0)

        // 0.6 shows 1%: a day's creep leaves 0.57, which still shows 1%, and the party goes on.
        let g = engine(party(hull: 0.6))
        XCTAssertNil(gameOver(g.sailDay()))
        XCTAssertEqual(g.state.hull, 0.57, accuracy: 1e-9)

        // Even aboard the steamer, where nothing wears it.
        let h = engine(party(mile: 5_000, hull: 0.4))
        XCTAssertEqual(gameOver(h.sailDay())?.title, Self.ruined)
    }

    func testABoatThatShowsNoughtBreaksUp() {
        let e = engine(party(mile: 12_100, month: 5, boat: true, hull: 0.52))
        guard let end = gameOver(e.sailDay()) else { return XCTFail("floated on with the boat at 0%") }
        XCTAssertEqual(end.title, Self.brokenUp)
        XCTAssertEqual(end.body, klondike.text.wreckedBody)
        XCTAssertEqual(e.state.hull, 0)
    }

    func testDamageIsNeverReportedPastNought() {
        let e = engine(party(sails: 3.4, hull: 50))
        XCTAssertEqual(k.knock(e, .drive, 13), "Sleds −3%")
        XCTAssertEqual(e.state.sails, 0)
        XCTAssertEqual(e.state.sails.sign, .plus)
        XCTAssertNil(k.knock(e, .drive, 5), "a meter already showing 0% loses nothing it can show")
        XCTAssertEqual(k.knock(e, .structure, 4), "Outfit −4%")
        XCTAssertEqual(e.state.hull, 46)
        e.state.hull = 2.6
        XCTAssertEqual(k.knock(e, .structure, 2), "Outfit −2%")
        XCTAssertEqual(e.state.hull, 0.6, accuracy: 1e-9, "1% still holds")
        e.state.hull = 2.4
        XCTAssertEqual(k.knock(e, .structure, 2), "Outfit −2%")
        XCTAssertEqual(e.state.hull, 0, "0.4 shows 0%: it is gone")
        XCTAssertEqual(Klondike.red([nil, "Sleds −3%", nil, "Outfit −2%"]), " [red](Sleds −3%, Outfit −2%)[/red]")
        XCTAssertEqual(Klondike.red([nil]), "")

        // A gravel bar under a boat at 5%: "Boat −5%", not the bar's 14, and she breaks up.
        let f = engine(party(mile: 12_600, month: 5, boat: true, hull: 5), [0, 0.5])
        var q: [Interrupt] = []
        k.trailDay(f, &q, f.state.region)
        XCTAssertEqual(messages(q).first, "She runs hard onto a gravel bar hidden under the brown water. It takes a full day of wading and prying to get her off. [red](Boat −5%)[/red]")
        XCTAssertEqual(gameOver(q)?.title, Self.brokenUp)

        // The runaway sled with the sleds at 2% and the outfit at 50%.
        let g = engine(party(mile: 11_400, sails: 2, hull: 50), [], fallback: 0.9)
        g.state.weather = KlondikeData.wind
        let runaway = klondike.events(g, g.state.region)[5]
        q = []
        runaway.run(g, &q)
        XCTAssertEqual(messages(q).first, "A loaded sled gets away on the steep pitch and runs wild down the slope, spilling sacks the length of the hill. [red](Sleds −2%, Outfit −6%)[/red]")
    }

    /// Accidents already left a crew member at 1 health at least; they still do.
    func testAccidentsLeaveACrewMemberAtOneHealthAtLeast() {
        func hurt(_ s: GameState, _ values: [Double], _ hp: Double, _ run: (GameEngine, inout [Interrupt]) -> Void) -> [Double] {
            var s = s
            for i in s.crew.indices { s.crew[i].hp = hp }
            let e = engine(s, values)
            var q: [Interrupt] = []
            run(e, &q)
            return e.state.crew.map(\.hp)
        }
        XCTAssertEqual(hurt(party(mile: 5_000), [], 3) { e, q in klondike.events(e, e.state.region)[9].run(e, &q) },
                       [1, 1, 1, 1, 1], "seasick")
        XCTAssertEqual(hurt(party(mile: 11_400), [0.6, 0, 0], 3) { e, q in k.snowslide(e, &q) }, [1, 3, 3, 3, 3], "dug out")
        XCTAssertEqual(hurt(party(mile: 11_400), [0, 0], 3) { e, q in k.overboard(e, &q, onFoot: true, epitaph: nil) },
                       [3, 1, 3, 3, 3], "hauled out of a creek")
        var wind = party(mile: 11_400)
        wind.weather = KlondikeData.wind
        XCTAssertEqual(hurt(wind, [0, 0], 5) { e, q in
            e.state.weather = KlondikeData.wind
            klondike.events(e, e.state.region)[5].run(e, &q)
        }, [1, 5, 5, 5, 5], "a broken leg")
    }

    // MARK: - No firewood

    /// Firewood is for the people, not the sleds: a party with none still walks, but every
    /// day without a fire costs each of them 12 health, and the status panel says so.
    func testNoFireIsACrisisNotAStop() {
        func day(water: Double) -> (GameEngine, [Interrupt]) {
            var s = party(mile: 11_400, water: water)
            for i in s.crew.indices { s.crew[i].hp = 50 }
            let e = engine(s)
            return (e, e.sailDay())
        }
        let (dry, q) = day(water: 0)
        let (wet, _) = day(water: 1000)
        XCTAssertEqual(klondike.rules.parch, 12)
        for i in dry.state.crew.indices {
            XCTAssertEqual(wet.state.crew[i].hp - dry.state.crew[i].hp, 12, accuracy: 1e-9)
        }
        XCTAssertEqual(dry.state.mile, wet.state.mile, "the sleds pull as well cold")
        XCTAssertTrue(messages(q).contains(klondike.text.outOfWater))
        XCTAssertTrue(Klondike.noFire(dry.state))
        XCTAssertFalse(Klondike.noFire(wet.state))
        XCTAssertFalse(Klondike.noFire(party(mile: 5_000, water: 0)), "the steamer keeps its own stove")
        XCTAssertEqual(dry.state.water, 0)
        XCTAssertEqual(dry.state.water.sign, .plus)
    }

    // MARK: - Saves

    func testGivenOutSurvivesASave() throws {
        let e = engine(party(sails: 0, money: 30))
        guard let ask = choice(e.sailDay()) else { return XCTFail("not asked") }
        let back = try JSONDecoder().decode(GameState.self, from: JSONEncoder().encode(e.state))
        XCTAssertEqual(choice(engine(back).sailDay()), ask, "loaded given out, the same question")
        let pending = try JSONDecoder().decode([Interrupt].self, from: JSONEncoder().encode([Interrupt.choice(ask)]))
        XCTAssertEqual(pending, [.choice(ask)])
        let f = engine(back)
        _ = f.resolve(ask, option: 1)
        XCTAssertEqual(f.state.money, 6, "and answered from the save")
        XCTAssertEqual(f.state.sails, 25)
    }
}

private extension KlondikeBreakdownTests {
    func party(mile: Int, water: Double) -> GameState {
        var s = party(mile: mile)
        s.water = water
        return s
    }
}
