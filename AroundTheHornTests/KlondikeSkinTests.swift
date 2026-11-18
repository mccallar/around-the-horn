import XCTest
@testable import HornEngine
@testable import AroundTheHorn

/// To the Klondike's skin, held to its own journey: the shell does what the engine asks of
/// it. Lake Bennett holds the party ashore for a boat and for the ice
/// (`Journey.holdInPort`); given-out sleds or oars stop it until they are mended, and the
/// status box says so in red (D14, `Journey.stalled`); the departure from Seattle warns of
/// short grub and refuses none; a voyage left with a question on screen comes back to it
/// (D10), and one saved in the Seattle stores comes back to them (D16). `SkinContractTests`
/// asks what every skin owes the shell; this asks what this one says.
@MainActor
final class KlondikeSkinTests: XCTestCase {
    let klondike = KlondikeSkin.journey
    let skin = KlondikeSkin.skin
    let fm = FileManager.default
    var p: Persistence!

    override func setUp() async throws {
        p = Persistence(directory: fm.temporaryDirectory.appendingPathComponent(UUID().uuidString),
                        defaults: UserDefaults(suiteName: UUID().uuidString)!)
    }

    func has(_ text: String, _ part: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(text.contains(part), "“\(part)” is not in “\(text)”", file: file, line: line)
    }

    func blank() -> GameState { KlondikeSkin.fresh(month: 2) }

    /// Standing at `stop`, its arrival told; in town if `port`.
    func at(_ stop: String, port: Bool = false, white: Bool = false) -> GameState {
        var g = blank()
        KlondikeSkin.at(&g, stop, port: port, white: white)
        return g
    }

    /// Under way at `mile` (tenths of a mile).
    func going(_ mile: Int) -> GameState {
        var g = blank()
        KlondikeSkin.go(&g, mile)
        return g
    }

    func controller() -> GameController {
        let c = GameController(persistence: p, journeys: Journeys.all, skins: Skins.all)
        c.tickInterval = .seconds(3600)
        return c
    }

    func newTrek(_ c: GameController, role: Role = .merchant, month: Int = 2) {
        c.chooseJourney(klondike.id)
        c.startNewGame()
        c.chooseRole(role)
        c.setNames(ship: "", captain: "Gus", crew: ["", "", "", ""])
        c.chooseDeparture(year: 1898, month: month)
    }

    /// Clicks through the messages and burials on screen, and says what the messages said.
    @discardableResult
    func dismiss(_ c: GameController) -> [String] {
        var said: [String] = []
        while true {
            switch c.screen {
            case .message(let text, _, let then):
                said.append(text)
                then()
            case .burial(let id, let cause):
                c.bury(crewID: id, cause: cause, epitaph: "")
            default:
                return said
            }
        }
    }

    func question(_ c: GameController, _ key: String, file: StaticString = #filePath, line: UInt = #line) -> ChoiceEvent? {
        guard case .choice(let ask) = c.screen, case .custom(key, _) = ask.kind else {
            XCTFail("not the “\(key)” question: \(c.screen)", file: file, line: line)
            return nil
        }
        return ask
    }

    func onPortMenu(_ c: GameController) -> Bool { if case .portMenu = c.screen { return true } else { return false } }
    func onSeaMenu(_ c: GameController) -> Bool { if case .seaMenu = c.screen { return true } else { return false } }
    func underWay(_ c: GameController) -> Bool { if case .travel = c.screen { return c.traveling } else { return false } }

    // MARK: The engine's own numbers

    /// What the skin reads out of `vars` and works out from the date is the engine's.
    func testTheSkinReadsTheEnginesOwnKeysAndDates() {
        XCTAssertEqual(KlondikeSkin.routeKey, KlondikeData.routeKey)
        XCTAssertEqual(KlondikeSkin.boatKey, KlondikeData.boatKey)
        XCTAssertEqual(KlondikeSkin.breakupKey, KlondikeData.breakupKey)
        XCTAssertEqual(KlondikeSkin.chilkoot, KlondikeData.chilkoot)
        XCTAssertEqual(KlondikeSkin.whitePass, KlondikeData.whitePass)
        XCTAssertEqual(KlondikeSkin.usualBreakup, KlondikeData.breakupUsual)
        var g = at("bennett", port: true)
        g.day = 0
        for day in stride(from: 0, through: 200, by: 7) {
            g.day = day
            XCTAssertEqual(KlondikeSkin.dayOfYear(g), KlondikeData.dayOfYear(g), "day \(day)")
            XCTAssertEqual(KlondikeSkin.iceOut(g), Klondike.iceOut(g), "day \(day)")
        }
    }

    /// A turn is a day: the date has no hour and the status box no clock.
    func testTurnsAreWholeDaysWithNoClock() {
        XCTAssertEqual(klondike.rules.tickHours, 24)
        for g in [blank(), going(150), going(11280), going(14000), at("bennett", port: true)] {
            XCTAssertNil(skin.words(g).clock)
            XCTAssertTrue(g.dateText.hasSuffix(", 1898"), g.dateText)
        }
    }

    // MARK: Lake Bennett holds the party ashore (`Journey.holdInPort`)

    /// Pushing off with no boat says so and offers one; the yard row offers one too. Neither
    /// lets the party go, takes a day, or starts the clock. "Not yet" is the port menu.
    func testBennettWantsABoatBeforeThePartyCanPushOff() throws {
        let c = controller()
        c.loadForDebug(at("bennett", port: true))
        XCTAssertTrue(onPortMenu(c), "\(c.screen)")
        let w = skin.words(c.game!)
        XCTAssertEqual(w.leavePort, "Push off and float on")
        XCTAssertEqual(w.yard, "See about a boat")
        XCTAssertNotNil(w.yardQuestion)
        let day = c.game!.day

        c.leavePort()
        guard case .message(let why, _, let next) = c.screen else { return XCTFail("\(c.screen)") }
        has(why, "See about a boat first.")
        XCTAssertFalse(c.traveling)
        XCTAssertTrue(c.game!.atPort)
        next()
        let boat = try XCTUnwrap(question(c, "boat"))
        XCTAssertEqual(boat.options.count, 5)
        c.choose(boat, option: 4)
        XCTAssertTrue(onPortMenu(c), "Not yet: \(c.screen)")
        XCTAssertTrue(c.game!.atPort)
        XCTAssertEqual(c.game!.day, day)
        XCTAssertFalse(Klondike.hasBoat(c.game!))

        // The yard row asks the same question, and a raft is a boat.
        c.openYard()
        let again = try XCTUnwrap(question(c, "boat"))
        XCTAssertEqual(again.options.map(\.label), boat.options.map(\.label))
        c.choose(again, option: 3)
        dismiss(c)
        XCTAssertTrue(onPortMenu(c), "\(c.screen)")
        XCTAssertTrue(c.game!.atPort)
        XCTAssertEqual(c.game!.vars[KlondikeSkin.boatKey], KlondikeSkin.raft)
        let built = skin.words(c.game!)
        XCTAssertEqual(built.yard, "Visit the boatwrights")
        XCTAssertNil(built.yardQuestion)
        XCTAssertEqual(built.meters.0, "Boat")
        XCTAssertEqual(built.meters.1, "Oars & sail")
        c.openYard()
        guard case .shipyard = c.screen else { return XCTFail("the boatwrights, not \(c.screen)") }
    }

    /// With a boat and the ice still in, pushing off asks whether to wait: "Not yet" stays
    /// in town; waiting passes the days to the breakup and then she is under way.
    func testBennettHoldsABoatUntilTheIceGoesOut() throws {
        var s = at("bennett", port: true)
        s.vars[KlondikeSkin.boatKey] = 3
        s.hull = 95
        s.sails = 100
        s.water = 2000
        s.food = 6000
        s.vars[KlondikeSkin.breakupKey] = Double(KlondikeSkin.dayOfYear(s) + 3)
        XCTAssertFalse(KlondikeSkin.iceOut(s))
        let c = controller()
        c.loadForDebug(s)
        XCTAssertEqual(skin.words(c.game!).yard, "Visit the boatwrights")

        c.leavePort()
        let ice = try XCTUnwrap(question(c, "ice"))
        has(ice.prompt, "still white from shore to shore")
        c.choose(ice, option: 1)
        XCTAssertTrue(onPortMenu(c), "Not yet: \(c.screen)")
        XCTAssertTrue(c.game!.atPort)
        XCTAssertEqual(c.game!.day, s.day)

        c.leavePort()
        let wait = try XCTUnwrap(question(c, "ice"))
        c.choose(wait, option: 0)
        let said = dismiss(c)
        XCTAssertTrue(said.contains { $0.contains("the ice goes out") }, "\(said)")
        XCTAssertTrue(underWay(c), "after the ice, under way: \(c.screen)")
        XCTAssertFalse(c.game!.atPort)
        XCTAssertEqual(c.game!.day, s.day + 3)
        XCTAssertTrue(KlondikeSkin.iceOut(c.game!))
        XCTAssertEqual(skin.words(c.game!).leavePort, "Push off and float on")
        c.stopTravel()

        // Once the ice is out, nothing holds her.
        var open = s
        open.vars[KlondikeSkin.breakupKey] = Double(KlondikeSkin.dayOfYear(s))
        let d = controller()
        d.loadForDebug(open)
        d.leavePort()
        XCTAssertTrue(underWay(d), "\(d.screen)")
        d.stopTravel()
    }

    /// D10: left with the hold on screen, the voyage comes back to it with the rest of the
    /// queue behind it, and after it to a menu, not the loop.
    func testAHoldLeftOnScreenComesBackWithItsQueue() throws {
        var s = at("bennett", port: true)
        // Past the two days buying a boat takes.
        s.vars[KlondikeSkin.breakupKey] = Double(KlondikeSkin.dayOfYear(s) + 5)
        s.water = 2000
        let c = controller()
        c.loadForDebug(s)
        c.leavePort()
        guard case .message = c.screen else { return XCTFail("\(c.screen)") }

        let back = controller()
        back.chooseJourney(klondike.id)
        back.continueSavedVoyage()
        guard case .message(let why, _, let next) = back.screen else { return XCTFail("\(back.screen)") }
        has(why, "See about a boat first.")
        next()
        let boat = try XCTUnwrap(question(back, "boat"), "the question queued behind it")
        back.choose(boat, option: 2)
        dismiss(back)
        XCTAssertTrue(onPortMenu(back), "\(back.screen)")
        XCTAssertTrue(Klondike.hasBoat(back.game!))

        back.leavePort()
        _ = try XCTUnwrap(question(back, "ice"))
        let third = controller()
        third.chooseJourney(klondike.id)
        third.continueSavedVoyage()
        let ice = try XCTUnwrap(question(third, "ice"), "the ice question, saved on screen")
        third.choose(ice, option: 0)
        dismiss(third)
        XCTAssertFalse(third.game!.atPort)
        XCTAssertTrue(onSeaMenu(third), "a menu, not the loop: \(third.screen)")
        XCTAssertFalse(third.traveling)
    }

    // MARK: Given out (D14, `Journey.stalled`)

    /// The red row: what has given out, by leg, and no firewood; nothing aboard the
    /// steamer or before Seattle is left.
    func testTheStatusBoxSaysWhatHasGivenOut() {
        func trouble(_ g: GameState) -> String? {
            let t = skin.words(g).trouble
            if let t { XCTAssertEqual(t.label, "Party") }
            return t?.value
        }
        var foot = going(11280)
        XCTAssertNil(trouble(foot))
        foot.sails = 0.4
        XCTAssertEqual(trouble(foot), "Sleds given out", "shows 0%")
        foot.water = 0
        XCTAssertEqual(trouble(foot), "Sleds given out, no firewood")
        foot.sails = 0.5
        XCTAssertEqual(trouble(foot), "No firewood", "shows 1%")

        var river = going(14000)
        XCTAssertNil(trouble(river))
        river.sails = 0
        XCTAssertEqual(trouble(river), "Oars & sail given out")
        river.water = 0
        XCTAssertEqual(trouble(river), "Oars given out, no firewood")

        var steamer = going(150)
        steamer.sails = 0
        steamer.water = 0
        XCTAssertNil(trouble(steamer), "the steamer carries the party")

        var seattle = blank()
        seattle.sails = 0
        seattle.water = 0
        XCTAssertNil(trouble(seattle), "nothing before it leaves Seattle")

        // The supplies note and the pace screen say it as well.
        foot.sails = 0
        foot.water = 0
        let w = skin.words(foot)
        has(w.suppliesNote, "[red]the sleds have given out[/red]")
        has(w.suppliesNote, "[red]no firewood[/red]")
        has(w.paceNow, "nobody moves until they are mended")
    }

    /// Sleds at 0% stop the party before a day under way: no day passes, and the question
    /// offers rope, a bought coil, making do and the menu. Each is honoured.
    func testGivenOutSledsStopThePartyUntilTheyAreMended() throws {
        var s = going(11280)
        s.sails = 0
        s.sailcloth = 1
        let c = controller()
        c.loadForDebug(s)
        c.startTravel()
        c.tick()
        XCTAssertFalse(c.traveling)
        let ask = try XCTUnwrap(question(c, "givenout"))
        has(ask.prompt, "Your sleds have given out.")
        XCTAssertEqual(ask.options.count, 3, "no coil to buy with one aboard")
        has(ask.options[0].label, "Mend the sleds")
        has(ask.options[1].label, "Lash up pack boards")
        XCTAssertEqual(ask.options[2].label, "Take stock first")
        XCTAssertEqual(ask.options.map(\.enabled), [true, true, true])
        XCTAssertEqual(c.game!.day, s.day, "asking takes no time")
        XCTAssertEqual(c.game!.mile, s.mile)
        c.choose(ask, option: 0)
        dismiss(c)
        XCTAssertGreaterThan(c.game!.sails, 0.5)
        XCTAssertEqual(c.game!.sailcloth, 0)
        XCTAssertTrue(underWay(c), "mended, she goes on: \(c.screen)")
        XCTAssertNil(skin.words(c.game!).trouble)
        c.stopTravel()

        // No rope: buy a coil off the next party along.
        var broke = s
        broke.sailcloth = 0
        broke.money = 400
        let d = controller()
        d.loadForDebug(broke)
        d.startTravel()
        d.tick()
        let buy = try XCTUnwrap(question(d, "givenout"))
        XCTAssertEqual(buy.options.map(\.enabled), [false, true, true, true])
        has(buy.options[1].label, "Buy a coil off the next party along ($24)")
        d.choose(buy, option: 1)
        dismiss(d)
        XCTAssertEqual(d.game!.money, 376)
        XCTAssertGreaterThan(d.game!.sails, 0.5)
        d.stopTravel()

        // Take stock first: the menu under way, no time gone; carrying on asks again.
        let e = controller()
        e.loadForDebug(broke)
        e.startTravel()
        e.tick()
        let stock = try XCTUnwrap(question(e, "givenout"))
        e.choose(stock, option: 3)
        XCTAssertTrue(onSeaMenu(e), "\(e.screen)")
        XCTAssertEqual(e.game!.day, broke.day)
        XCTAssertEqual(skin.words(e.game!).trouble?.value, "Sleds given out")
        e.startTravel()
        e.tick()
        let makeDo = try XCTUnwrap(question(e, "givenout"), "asked again")
        e.choose(makeDo, option: 2)
        dismiss(e)
        XCTAssertEqual(e.game!.day, broke.day + KlondikeData.makeDoDays)
        XCTAssertEqual(Int(jsRound(e.game!.sails)), Int(KlondikeData.makeDoPoints))
        XCTAssertEqual(e.game!.mile, broke.mile, "making do goes nowhere")
        e.stopTravel()
    }

    /// Afloat, the oars: the boat's own words, and she is tied to the bank until re-rigged.
    func testGivenOutOarsTieTheBoatToTheBank() throws {
        var s = going(14000)
        s.sails = 0
        s.sailcloth = 0
        let c = controller()
        c.loadForDebug(s)
        c.startTravel()
        c.tick()
        let ask = try XCTUnwrap(question(c, "givenout"))
        has(ask.prompt, "The oars and sail have given out.")
        has(ask.options[0].label, "Re-rig the oars & sail")
        has(ask.options[1].label, "Buy a coil off the next boat along")
        has(ask.options[2].label, "Cut a sweep and oars")
        XCTAssertEqual(c.game!.mile, s.mile)
        c.stopTravel()
    }

    /// D15: repairs list the outfit (or the boat) first, the sleds (or the oars) second, as
    /// the status box does, given out or not.
    func testRepairsListTheOutfitFirst() {
        for (g, structure, drive, patch, mend) in [
            (going(11280), "Outfit", "Sleds", "Patch the outfit", "Mend sleds & straps"),
            (going(14000), "Boat", "Oars & sail", "Patch the hull", "Re-rig oars & sail"),
        ] {
            var s = g
            s.sails = 0
            s.hull = 50
            let c = controller()
            c.loadForDebug(s)
            let w = skin.words(s)
            XCTAssertEqual(w.meters.0, structure)
            XCTAssertEqual(w.meters.1, drive)
            let rows = RepairsView.choices(c, w)
            XCTAssertEqual(rows.count, 3)
            has(rows[0].label, patch)
            has(rows[1].label, mend)
        }
    }

    // MARK: Leaving Seattle

    /// No refusal of the skin's own, at Seattle or anywhere: the engine's (no provisions)
    /// sends the party back to the stores, and short grub is a warning that may be waved off.
    func testSeattleWarnsOfShortGrubAndRefusesOnlyAnEmptyLarder() {
        var g = blank()
        for food in [0.0, 100, 5474, 5475, 9000] {
            g.food = food
            XCTAssertNil(skin.words(g).departRefusal)
            XCTAssertNil(skin.words(g).leaveRefusal)
            XCTAssertEqual(skin.words(g).departWarning == nil, food == 0 || food >= 5475, "\(food) lbs")
        }
        for id in klondike.stops.map(\.id) {
            XCTAssertNil(skin.words(at(id, port: true)).leaveRefusal, id)
        }

        let c = controller()
        newTrek(c)
        c.enterFirstShop()
        guard case .shop(let empty) = c.screen else { return XCTFail("\(c.screen)") }
        empty()
        guard case .message(let none, _, let back) = c.screen else { return XCTFail("\(c.screen)") }
        XCTAssertEqual(none, klondike.text.noProvisions)
        back()
        guard case .shop(let some) = c.screen else { return XCTFail("back to the stores, not \(c.screen)") }
        XCTAssertTrue(c.run { $0.buy([.food: 2000]) })
        some()
        guard case .ask(let warning, let answers) = c.screen else { return XCTFail("\(c.screen)") }
        has(warning, "You have [amber]2,000 lbs[/amber] of provisions. The police at the summit will want [amber]5,475[/amber]")
        XCTAssertEqual(answers.map(\.label), ["Back to the shop", "Leave anyway"])
        answers[0].then()
        guard case .shop(let more) = c.screen else { return XCTFail("back to the stores, not \(c.screen)") }
        XCTAssertTrue(c.game!.atPort)
        more()
        guard case .ask(_, let again) = c.screen else { return XCTFail("\(c.screen)") }
        again[1].then()
        guard case .depart(let text) = c.screen else { return XCTFail("\(c.screen)") }
        has(text, "Your steamer backs away from the Seattle waterfront on")
        XCTAssertFalse(c.game!.atPort)
        XCTAssertEqual(skin.words(c.game!).setOut, "Steam north")

        // A year's grub for five: no warning.
        let d = controller()
        newTrek(d)
        d.enterFirstShop()
        guard case .shop(let full) = d.screen else { return XCTFail("\(d.screen)") }
        XCTAssertTrue(d.run { $0.buy([.food: 5500]) })
        full()
        guard case .depart = d.screen else { return XCTFail("\(d.screen)") }
    }

    /// D16: saved in the Seattle stores before it left, a trek comes back to them, and
    /// leaves only through the departure and its warning.
    func testASaveInTheSeattleStoresComesBackToThem() {
        XCTAssertTrue(skin.words(blank()).resumesInFirstShop)
        let c = controller()
        newTrek(c)
        c.enterFirstShop()
        guard case .shop = c.screen else { return XCTFail("\(c.screen)") }
        XCTAssertTrue(c.run { $0.buy([.food: 1000]) })
        c.save()

        let again = controller()
        again.chooseJourney(klondike.id)
        again.continueSavedVoyage()
        guard case .shop(let leave) = again.screen else { return XCTFail("back to the stores, not \(again.screen)") }
        XCTAssertEqual(again.game!.food, 1000)
        leave()
        guard case .ask = again.screen else { return XCTFail("the warning, not \(again.screen)") }
    }
}
