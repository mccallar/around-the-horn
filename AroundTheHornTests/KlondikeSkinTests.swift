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

// MARK: - Numbers the card states, and the stores

extension KlondikeSkinTests {
    /// Distances are tenths of a mile, written as the engine writes them.
    func testDistancesAreTenthsOfAMile() {
        XCTAssertEqual(KlondikeData.unitsPerMile, 10)
        XCTAssertEqual(klondike.totalMiles, 17_000)
        let w = skin.words(going(11280))
        XCTAssertEqual(w.distanceUnit, "mi")
        XCTAssertEqual(w.distance(11_365), "1,136.5")
        XCTAssertEqual(w.distance(17_000), "1,700.0")
        XCTAssertEqual(w.distance(7), "0.7")
        XCTAssertEqual(w.distance(0), "0.0")
        for stop in klondike.stops { XCTAssertEqual(w.distance(stop.mile), Klondike.mileNumber(stop.mile), stop.id) }
        XCTAssertEqual(klondike.rules.restChoices.map(w.restChoice), ["1 day", "2 days", "3 days", "5 days"])
        has(w.repairsNote, "Each repair takes a day.")
        has(w.yardIntro, "Each job takes a day.")
        XCTAssertEqual(skin.words(at("dawson")).gameOverLine.hasSuffix("1,700.0 miles from Seattle."), true)
    }

    func testTheCardsNumbersAreTheTables() {
        let card = KlondikeSkin.card
        let all = card.learnPages.flatMap(\.paragraphs) + card.differences + card.outfitBullets
            + [card.tagline, card.monthIntro, card.monthAdvice]
        let text = all.joined(separator: "\n")

        // The way north.
        XCTAssertEqual(klondike.totalMiles / KlondikeData.unitsPerMile, 1700)
        has(card.tagline, "Seventeen hundred miles from Seattle")
        has(text, "seventeen hundred miles north")
        XCTAssertEqual((KlondikeData.bennettMile - KlondikeData.landingMile) / KlondikeData.unitsPerMile, 33)
        has(text, "the thirty-three miles of trail")
        let river = (klondike.totalMiles - KlondikeData.bennettMile) / KlondikeData.unitsPerMile
        XCTAssertTrue((540..<550).contains(river), "\(river) miles")
        has(text, "nearly five hundred and fifty miles of lakes, canyon and rapids")
        XCTAssertEqual(GameState(journey: Klondike.id, role: .merchant, ship: "", captain: "", crew: ["", "", "", ""],
                                 startYear: 1898, startMonth: 2).crew.count, 5)
        has(text, "You lead a party of five.")
        XCTAssertEqual(klondike.stop("lynn")!.type, .fork)
        has(text, "At the head of Lynn Canal choose your pass")

        // The police, the fire and the grub.
        XCTAssertEqual(KlondikeData.yearOfGrub, 1095)
        has(text, "a year's grub — 1,095 lbs a head")
        has(text, "a year's grub: 1,095 lbs a head")
        XCTAssertEqual(klondike.rules.parch, 12)
        has(text, "A day without a fire costs every one of you 12 health.")
        XCTAssertEqual(KlondikeData.temps["chilkootSummit"]![0], .freezing)
        XCTAssertEqual(5 * KlondikeData.firewoodPerHead * KlondikeData.burn(.freezing), 40)
        has(text, "five of you burn 40 lbs of it a day")
        XCTAssertEqual(klondike.item(.food).desc.contains("1–3 lbs a day"), true)
        XCTAssertEqual(klondike.rations(.bare).amount, 1)
        XCTAssertEqual(klondike.rations(.filling).amount, 3)

        // Given out, and mended.
        XCTAssertEqual(KlondikeData.coilPrice, 24)
        XCTAssertEqual(KlondikeData.coilPrice, 3 * klondike.item(.sailcloth).price)
        has(text, "with a coil bought off the next party along for $24")
        XCTAssertEqual(KlondikeData.makeDoDays, 2)
        has(text, "or with two days' work making do")

        // The ice and the crowd.
        XCTAssertEqual(KlondikeData.breakupEarliest, KlondikeData.dayOfYear(month: 4, day: 24))
        XCTAssertEqual(KlondikeData.breakupUsual, KlondikeData.dayOfYear(month: 4, day: 28))
        has(text, "wait for the ice to go out, at the end of May")
        XCTAssertEqual(KlondikeData.crowdBonusPerDay, 20)
        XCTAssertEqual(KlondikeData.august1, KlondikeData.dayOfYear(month: 7, day: 1))
        has(text, "Every day you get there before August 1 is worth 20 points.")

        // Who you are.
        for (role, money) in [(Role.merchant, "$1,700"), (.shipwright, "$1,000"), (.whaler, "$720")] {
            let info = klondike.role(role)
            XCTAssertEqual("$" + formatNumber(info.money), money)
            let line = card.differences.first { $0.lowercased().contains(info.title) }
            XCTAssertNotNil(line, "\(role)")
            has(line ?? "", "starts with \(money).")
        }
        XCTAssertGreaterThan(klondike.role(.shipwright).mend, klondike.role(.merchant).mend)
        XCTAssertGreaterThan(klondike.role(.shipwright).patch, klondike.role(.merchant).patch)
        has(text, "Gets far more out of every bundle of canvas and coil of rope")
        XCTAssertLessThan(Klondike.buildDays(.shipwright).proper, Klondike.buildDays(.merchant).proper)
        XCTAssertLessThan(Klondike.buildDays(.shipwright).scow, Klondike.buildDays(.merchant).scow)
        has(text, "builds a better boat in less time")
        XCTAssertGreaterThan(KlondikeData.minerTrail, 1)
        has(text, "moves an outfit over the pass faster than anyone")
        XCTAssertEqual(Role.shipwright.scoreMultiplier, 2)
        XCTAssertEqual(Role.whaler.scoreMultiplier, 3)
        has(text, "the boatbuilder scores double, the miner triple")

        // When to go: January to May of 1898.
        XCTAssertEqual(klondike.departures.map(\.month), [0, 1, 2, 3, 4])
        XCTAssertTrue(klondike.departures.allSatisfy { $0.year == 1898 })
        XCTAssertEqual(KlondikeData.season(0), .winter)
        XCTAssertEqual(KlondikeData.season(4), .spring)
        has(card.monthAdvice, "Go in January and the pass will freeze you solid. Go in May")
        XCTAssertEqual(klondike.item(.tackle).per, 20)
        XCTAssertEqual(klondike.item(.tackle).desc.contains("Each box is 20 casts."), true)
    }

    func testTheRankLegendIsTheEnginesRanks() {
        let cuts = klondike.rules.rankCuts
        XCTAssertEqual(cuts, [7000, 4000, 2000])
        let legend = cuts.map { "\(klondike.rank($0)) \(formatNumber(Double($0)))+" } + [klondike.rank(0)]
        XCTAssertEqual(KlondikeSkin.card.rankLegend, legend.joined(separator: " · "))
    }

    /// The Seattle prices as the shop shows them, and amounts as the engine stores them.
    func testTheStoresAndThePriceNote() {
        let g0 = at("seattle", port: true)
        let w = skin.words(g0)
        func label(_ key: ItemKey, at port: String = "seattle") -> String {
            ShopView.priceLabel(klondike.item(key), klondike.port(port)!.price(key), w.currency, lot: w.lots.contains(key))
        }
        XCTAssertEqual(label(.food), "$0.10/lb")
        XCTAssertEqual(label(.water), "$2/100 lbs")
        XCTAssertEqual(label(.limes), "$4/jug")
        XCTAssertEqual(label(.sailcloth), "$8/coil")
        XCTAssertEqual(label(.timber), "$10/bundle")
        XCTAssertEqual(label(.tackle), "$3/box")
        XCTAssertEqual(w.priceNote(40), "Prices here are 40% above Seattle, more or less.")
        XCTAssertEqual(w.priceNote(-10), "Prices here are 10% below Seattle, more or less.")
        // Bennett is dearer than Dyea, and Dyea than Seattle.
        let mults = ["seattle", "juneau", "landing", "camp", "bennett", "selkirk"].map { klondike.port($0)!.mult }
        XCTAssertEqual(mults, mults.sorted())

        var g = going(11280)
        g.tackle = 60
        g.limes = 2.5
        g.food = 6000
        g.water = 1
        XCTAssertEqual(Stores.have(klondike.item(.tackle), g, w), "3")
        XCTAssertEqual(Stores.amount(klondike.item(.tackle), g, w), "60 casts")
        g.tackle = 1
        XCTAssertEqual(Stores.amount(klondike.item(.tackle), g, w), "1 cast")
        XCTAssertEqual(Stores.amount(klondike.item(.limes), g, w), "2.5 jugs")
        XCTAssertEqual(Stores.amount(klondike.item(.food), g, w), "6,000 lbs")
        XCTAssertEqual(Stores.amount(klondike.item(.water), g, w), "1 lb")
        XCTAssertEqual(StatusPanel.stores(klondike, g, w).map(\.label), ["Provisions", "Firewood"])
    }

    func testTradesAndTheDepartureReadRight() {
        XCTAssertEqual(klondike.describe(.item(.meds), 3), "3 medicine kits")
        has(klondike.describe(.item(.clothes), 1), "1 set")
        has(klondike.describe(.item(.tackle), 40), "2 boxes")
        has(klondike.describe(.item(.food), 250), "250 lbs")
        var g = blank()
        for day in 0..<4 {
            g.day = day
            let depart = klondike.text.depart(g)
            XCTAssertFalse(depart.contains(".."), depart)
            has(depart, g.dateText)
        }
        has(blank().dateText, "March 1, 1898")
    }
}

// MARK: - The vocabulary sieve

extension KlondikeSkinTests {
    /// Every string reachable in `value`: the words as data, without the closures.
    func strings(_ value: Any) -> [String] {
        if let s = value as? String { return [s] }
        return Mirror(reflecting: value).children.flatMap { strings($0.value) }
    }

    /// The states the walk below says everything in: under way, in town, given out with no
    /// fire, short of lime juice and furs; on each pass; with and without a boat.
    func states(_ i: Int) -> [GameState] {
        var out: [GameState] = []
        for white in [false, true] {
            for (port, sails, water, citrus) in [(false, 64.0, 600.0, 0), (true, 50, 600, 30), (false, 0, 0, 40)] {
                var g = skin.debug.start(i, 2)
                KlondikeSkin.settle(&g, toward: i, white: white)
                g.sails = sails
                g.water = water
                g.noCitrus = citrus
                g.clothes = port ? 2 : 5
                g.atPort = port && klondike.port(g, at: g.currentStop.id) != nil
                out.append(g)
            }
        }
        return out
    }

    /// Everything the skin can say, at every stop, for every role.
    func everythingSaid() -> [String] {
        let card = KlondikeSkin.card
        var out = strings(card) + [card.resume("Belle"), card.outfitIntro(blank())]
        let forage = skin.forage
        out += [forage.heading, forage.throwsLabel, forage.caughtLabel, forage.timeLabel, forage.hint("150 lbs"),
                forage.label(1), forage.label(3), forage.actionHint, forage.leave, skin.chart.title]
        out += klondike.quarry.flatMap { [forage.pop("1", $0), forage.pop("35", $0)] }
        for i in klondike.stops.indices.dropFirst() {
            for role in Role.allCases {
                for var g in states(i) {
                    g.role = role
                    let w = skin.words(g)
                    out += strings(w) + klondike.rules.restChoices.map(w.restChoice)
                    out += [w.distance(g.mile), w.yardHull(56), w.yardSails(72), w.priceNote(30), w.priceNote(-20),
                            w.burial("Ida"), w.stopName(g.currentStop), skin.chart.label(g), skin.chart.footer(g)]
                    if let ask = w.yardQuestion {
                        let c = controller()
                        c.loadForDebug(g)
                        if case .choice(let e) = c.run({ ask($0) }) {
                            out += [e.prompt, e.detail ?? ""] + e.options.map(\.label)
                        }
                    }
                    for weather in klondike.weathers where role == .merchant {
                        g.weather = weather
                        for moving in [false, true] {
                            out.append(skin.scene.label(ScenePicture.frame(klondike, g, moving: moving, t: 0)))
                        }
                    }
                }
            }
        }
        for cell in skin.debug.gallery {
            let g = SceneGallery.state(klondike, cell.set)
            out.append(skin.scene.label(ScenePicture.frame(klondike, g, moving: cell.moving, t: 0)))
            out.append(cell.name)
        }
        out.append(skin.scene.label(ScenePicture.frame(klondike, nil, moving: false, t: 0)))
        return out
    }

    /// Every sentence the trek's engine can write, read from its source: each string
    /// literal, with the code inside its interpolations taken out.
    func engineSaid() throws -> [String] {
        let dir = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("HornEngine/Journeys/Klondike")
        let files = try fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil).filter { $0.pathExtension == "swift" }
        XCTAssertGreaterThanOrEqual(files.count, 6, "the trek's engine is in \(dir.path)")
        let literal = try NSRegularExpression(pattern: #""((?:[^"\\\n]|\\.)*)""#)
        let code = try NSRegularExpression(pattern: #"\\\((?:[^()]|\((?:[^()]|\([^()]*\))*\))*\)"#)
        var out: [String] = []
        for file in files {
            for line in try String(contentsOf: file, encoding: .utf8).split(separator: "\n").map(String.init)
            where !line.trimmingCharacters(in: .whitespaces).hasPrefix("//") {
                for m in literal.matches(in: line, range: NSRange(line.startIndex..., in: line)) {
                    let s = String(line[Range(m.range(at: 1), in: line)!])
                    out.append(code.stringByReplacingMatches(in: s, range: NSRange(s.startIndex..., in: s), withTemplate: ""))
                }
            }
        }
        out += klondike.items.flatMap { it in [1, 2].map { klondike.describe(.item(it.key), Double(it.per * $0)) } }
        return out
    }

    /// Words from the other journeys' worlds: an 1849 ship at sea, a train, an airship, a
    /// balloon, a freighter in space. A stampeder has a steamer, a boat with oars & sail,
    /// firewood, lime juice and miles, so those stay.
    static let elsewhere = try! NSRegularExpression(
        pattern: #"\b(sails|sailing|sailors?|sailcloth|shipwrights?|anchor(s|ed)?|harpoons?|tackle|throws?|voyages?|"#
            + #"nm|nautical|knots?|citrus|limes|whal(e|er|ers|ing)|galley|"#
            + #"trains?|railroad|railway|locomotive|conductor|caboose|boxcars?|cords?|wagons?|oxen|"#
            + #"petrol|gondola|hydrogen|propane|burners?|ballast|gallons?|helium|"#
            + #"propellant|tonnes?|litres?|kilomet(re|er)s?|km|thrusters?|airlock|orbits?)\b"#,
        options: [.caseInsensitive])

    func testNothingOnTheTrailIsSaidInAnotherJourneysWords() throws {
        let said = everythingSaid()
        XCTAssertGreaterThan(Set(said).count, 150, "the walk found the words")
        // The steamer anchors off Dyea, the White Pass has a wagon road at its foot, the lake
        // fills with sails, and rapids throw spray; a count inside an interpolation is code.
        let figures = ["anchor off Dyea", "wagon road", "full of sails", "throw spray", "s.sailcloth"]
        let engine = try engineSaid().map { s in figures.reduce(s) { $0.replacingOccurrences(of: $1, with: "") } }
        XCTAssertGreaterThan(Set(engine).count, 150, "the source was read")
        for s in Set(said + engine) {
            let m = Self.elsewhere.firstMatch(in: s, range: NSRange(s.startIndex..., in: s))
            XCTAssertNil(m, "another journey's word in “\(s)”: \(m.map { (s as NSString).substring(with: $0.range) } ?? "")")
        }
        // The same sieve does catch a ship, a train, an airship, a balloon and a freighter.
        for other in [Horn1849Skin.skin, RailSkin.skin, AirshipSkin.skin, BalloonSkin.skin, MarsSkin.skin] {
            let words = strings(other.words(other.debug.start(3, other.id == Horn1849.id ? 0 : 9))).joined(separator: "\n")
                + strings(other.card).joined(separator: "\n")
            XCTAssertNotNil(Self.elsewhere.firstMatch(in: words, range: NSRange(words.startIndex..., in: words)), other.id)
        }
        // And nothing here is said in the shapes D11 retired.
        let retired = ["You may:", "Find out the differences", "Be a ", "Many kinds of people", "Filling", "Meager",
                       "Bare bones", "Attempt to trade"]
        for s in Set(said + engine + klondike.roles.values.map(\.label) + Rations.allCases.map { klondike.rations($0).name }) {
            for r in retired { XCTAssertFalse(s.contains(r), "“\(r)” in “\(s)”") }
        }
    }
}

// MARK: - The picture

extension KlondikeSkinTests {
    func frame(_ g: GameState, moving: Bool = true) -> SceneFrame {
        SceneFrame(t: 0, weather: g.weather, moving: moving, atPort: g.atPort, hull: g.hull, sails: g.sails,
                   region: g.region, hour: g.hour, state: g)
    }

    func picture(_ f: SceneFrame, t: Double = 0.37) -> Int {
        let px = PixelCanvas(w: SceneSkin.w, h: SceneSkin.h)
        skin.scene.draw(px, f.at(t))
        return px.tally.picture
    }

    func going(_ mile: Int, white: Bool) -> GameState {
        var g = blank()
        KlondikeSkin.go(&g, mile, white: white)
        g.weather = klondike.fairWeather
        return g
    }

    func testTheSpritesAreWhole() {
        for (name, sprite, colors, width) in [("steamer", KlondikeScene.steamer, KlondikeScene.steamerColors, KlondikeScene.steamer[0].count),
                                              ("party", KlondikeScene.party, KlondikeScene.partyColors, KlondikeScene.party[0].count),
                                              ("boat", KlondikeScene.boat, KlondikeScene.boatColors, KlondikeScene.boat[0].count),
                                              ("raft", KlondikeScene.raftBoat, KlondikeScene.boatColors, KlondikeScene.raftBoat[0].count)] {
            XCTAssertGreaterThan(sprite.count, 4, name)
            for row in sprite {
                XCTAssertEqual(row.count, width, name)
                for ch in row where ch != " " { XCTAssertNotNil(colors[ch], "no colour for \(ch) in the \(name)") }
            }
        }
        XCTAssertNotEqual(KlondikeScene.boat, KlondikeScene.raftBoat, "a raft is not the boat")
    }

    /// On the steamer, on the trail and on the river, every weather is a sky of its own,
    /// and the label says which.
    func testEveryWeatherIsItsOwnPicture() {
        var skies = Set<Sky>()
        for mile in [5200, 11280, 14000] {
            var seen: [Int: String] = [:]
            for weather in klondike.weathers {
                var g = going(mile, white: false)
                g.weather = weather
                let pic = picture(frame(g))
                XCTAssertNil(seen[pic], "at \(mile): \(weather.name) looks just like \(seen[pic] ?? "")")
                seen[pic] = weather.name
                skies.insert(weather.sky)
                has(skin.scene.label(frame(g)), KlondikeScene.phrase(weather.sky))
            }
            XCTAssertEqual(seen.count, klondike.weathers.count)
        }
        XCTAssertEqual(skies.count, klondike.weathers.count, "every weather has a sky of its own")
    }

    /// Every stretch of country, on both passes, is a picture of its own.
    func testEveryStretchIsItsOwnPicture() {
        var seen: [Int: String] = [:]
        for (regions, white) in [(KlondikeData.regions, false), (KlondikeData.whitePassRegions, true)] {
            for r in regions {
                let g = going(min(r.to, klondike.totalMiles) - 5, white: white)
                XCTAssertEqual(g.region.id, r.id)
                let pic = picture(frame(g))
                if let other = seen[pic] { XCTFail("\(r.name) looks just like \(other)") }
                seen[pic] = r.name
                XCTAssertEqual(pic, picture(frame(g)), "the same place twice is the same picture")
            }
        }
        XCTAssertEqual(seen.count, KlondikeData.regions.count + KlondikeData.whitePassRegions.count)
        // What the party travels by follows the leg.
        has(skin.scene.label(frame(going(5200, white: false))), "A crowded steamer heading north")
        has(skin.scene.label(frame(going(11280, white: false))), "Your party hauling sleds")
        has(skin.scene.label(frame(going(14000, white: false))), "Your boat on the river")
    }

    /// Every stop, and each pass's own four, is drawn as itself: not like any other, and not
    /// like the country halfway to the next.
    func testEveryStopIsDrawnAsItself() {
        var seen: [Int: String] = [:]
        let stops = klondike.stops
        for (i, stop) in stops.enumerated() {
            for white in KlondikeData.variants[stop.id] == nil ? [false] : [false, true] {
                let town = klondike.port(stop.id) != nil
                var g = blank()
                KlondikeSkin.at(&g, stop.id, port: town, white: white)
                g.weather = klondike.fairWeather
                if stop.id == "seattle" { g.day = 0 }
                let name = "\(stop.id)\(white ? " (White Pass)" : "")"
                let f = frame(g, moving: false)
                let pic = picture(f)
                if let other = seen[pic] { XCTFail("\(name) looks just like \(other)") }
                seen[pic] = name
                if town, let port = klondike.port(g, at: stop.id) {
                    has(skin.scene.label(f), port.name)
                }
                if i + 1 < stops.count {
                    let next = stops[i + 1]
                    var by = g
                    by.atPort = false
                    by.mile = (stop.mile + next.mile) / 2
                    XCTAssertNotEqual(pic, picture(frame(by, moving: false)), "\(name) is drawn as a stop")
                }
            }
        }
        XCTAssertEqual(seen.count, klondike.stops.count + KlondikeData.variants.count)
        // The pass's own names, in the town and on the map.
        XCTAssertEqual(klondike.port(at("landing", port: true), at: "landing")?.name, "Dyea")
        XCTAssertEqual(klondike.port(at("landing", port: true, white: true), at: "landing")?.name, "Skagway")
        has(skin.scene.label(frame(at("camp", port: true, white: true), moving: false)), "White Pass City")
        has(skin.scene.label(frame(at("seattle", port: true), moving: false)), "The steamer tied up at Seattle")
        has(skin.scene.label(frame(at("bennett", port: true), moving: false)), "Your party in camp at Lake Bennett")
    }

    /// Wear, a given-out meter, no fire, and each way the trek can end are drawn as
    /// themselves, and said: every cell of the gallery is a picture of its own.
    func testWearTroubleAndTheEndsAreDrawnAsThemselves() {
        var seen: [Int: String] = [:]
        for cell in skin.debug.gallery {
            var g = SceneGallery.state(klondike, cell.set)
            g.weather = klondike.fairWeather
            let pic = picture(frame(g, moving: cell.moving))
            if let other = seen[pic] { XCTFail("“\(cell.name)” looks just like “\(other)”") }
            seen[pic] = cell.name
        }
        XCTAssertEqual(seen.count, skin.debug.gallery.count)

        func said(_ name: String) -> String {
            let cell = skin.debug.gallery.first { $0.name == name }!
            return skin.scene.label(frame(SceneGallery.state(klondike, cell.set), moving: cell.moving))
        }
        has(said("Sleds given out"), "Your party beside sleds that have given out")
        has(said("Oars given out, tied up"), "Your boat tied to the bank with no oars or sail")
        has(said("The outfit ruined"), "Your outfit lies ruined in the snow")
        has(said("Turned back at the summit"), "Your party turning back from the summit")
        has(said("The boat broken up"), "The wreck of your boat going down the river")
        // Worn is not given out: still hauling, still afloat.
        has(said("Sleds 15%"), "Your party hauling sleds")
        has(said("Sail 15%"), "Your boat on the river")
        // A sled at 15% is drawn worn, at 64% whole.
        var worn = going(11280, white: false)
        let whole = picture(frame(worn))
        worn.sails = 15
        XCTAssertNotEqual(picture(frame(worn)), whole)
        worn.sails = 0
        XCTAssertNotEqual(picture(frame(worn, moving: false)), picture(frame(going(11280, white: false), moving: false)))
        // A raft is not a boat.
        var raft = going(13600, white: false)
        let boat = picture(frame(raft))
        raft.vars[KlondikeSkin.boatKey] = KlondikeSkin.raft
        XCTAssertNotEqual(picture(frame(raft)), boat)
        // The scene with no trek is the pass.
        XCTAssertEqual(skin.scene.label(SceneFrame(t: 0, weather: klondike.fairWeather, moving: false, atPort: false,
                                                   hull: 100, sails: 100, region: nil, hour: 0, state: nil)),
                       "A party hauling a loaded sled up a snowy mountain pass")
    }
}
