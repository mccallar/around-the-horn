import XCTest
@testable import HornEngine
@testable import AroundTheHorn

/// A voyage left with something on screen comes back to it. The engine moves the voyage
/// on before the player sees what the turn raised (a stop is behind you before its
/// arrival is offered), so the save keeps what is still waiting, and a quit at any point
/// in the queue resumes at that point: the warning, then the stop's question, then the
/// end. Every journey with a skin, because the queue is the shell's.
@MainActor
final class ResumeTests: XCTestCase {
    var p: Persistence!

    override func setUp() async throws {
        p = Persistence(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString),
                        defaults: UserDefaults(suiteName: UUID().uuidString)!)
    }

    func controller(_ id: String) -> GameController {
        let c = GameController(persistence: p, journey: id)
        c.tickInterval = .seconds(3600)
        return c
    }

    /// The app quit and opened again on the same files: a new controller, and "continue".
    func quitAndResume(_ id: String) -> GameController {
        let c = controller(id)
        XCTAssertTrue(p.hasSave(id), "a voyage to go back to")
        c.continueSavedVoyage()
        return c
    }

    /// Rolls the last mile into `stop` with the food just running short, so that the turn
    /// which arrives says so first, and returns with that warning on screen, unanswered.
    func arriveWarned(_ c: GameController, _ id: String, at stop: String) -> String {
        let journey = Journeys.journey(id)
        let i = journey.stops.firstIndex { $0.id == stop }!
        c.loadForDebug(Skins.skin(id)!.debug.start(i, 9))
        c.startTravel()
        for _ in 0..<60 {
            c.run { e in
                let need = Double(e.state.living.count) * e.journey.rations(e.state.rations).amount
                e.state.mile = journey.stops[i].mile - 1
                e.state.food = need * 1.01
                e.state.flags.lowFood = false
            }
            c.tick()
            if c.game!.stopIndex == i {
                guard case .message(let t, _, _) = c.screen else {
                    XCTFail("the low-food warning first, not \(c.screen)")
                    return ""
                }
                XCTAssertEqual(t, journey.text.lowFood)
                return t
            }
            // Not there yet (a calm): answer what the day raised and roll on.
            _ = answerMessages(c)
            if case .choice(let e) = c.screen { c.choose(e, option: e.options.firstIndex(where: \.enabled)!) }
            _ = answerMessages(c)
            if case .travel = c.screen {} else { c.startTravel() }
        }
        XCTFail("never reached \(stop)")
        return ""
    }

    /// Continues past every message on screen, and returns what they said.
    @discardableResult
    func answerMessages(_ c: GameController) -> [String] {
        var said: [String] = []
        while case .message(let t, _, let then) = c.screen {
            said.append(t)
            then()
        }
        return said
    }

    func onMessage(_ c: GameController, _ text: String, file: StaticString = #filePath, line: UInt = #line) {
        guard case .message(let t, _, _) = c.screen else { return XCTFail("\(c.screen)", file: file, line: line) }
        XCTAssertEqual(t, text, file: file, line: line)
    }

    // MARK: The end of the line

    /// Quit on the warning that came with the last stop: back on the warning, then the end.
    func endsAfterAResume(_ id: String) {
        let c = controller(id)
        let last = Journeys.journey(id).stops.last!.id
        let warning = arriveWarned(c, id, at: last)
        XCTAssertNil(c.game!.nextStop, "the engine has already put the voyage at its end")

        let again = quitAndResume(id)
        XCTAssertFalse(again.traveling)
        onMessage(again, warning)
        answerMessages(again)
        guard case .finale = again.screen else { return XCTFail("\(again.screen)") }
        XCTAssertNil(p.loadSave(id), "the voyage is over")
    }

    func testTheRailroadEndsAfterAResumeAtSacramento() { endsAfterAResume(Rail.id) }

    func testTheVoyageEndsAfterAResumeAtSanFrancisco() { endsAfterAResume(Horn1849.id) }

    /// A save written before the queue was kept, standing on the last stop with nothing
    /// waiting, would never end: the arrival it was never told of is told now.
    func arrivesFromAnOldSaveAtTheEnd(_ id: String) {
        let j = Journeys.journey(id)
        var s = Skins.skin(id)!.debug.start(j.stops.count - 1, 9)
        s.stopIndex = j.stops.count - 1
        s.mile = j.stops.last!.mile
        p.save(s)
        let c = quitAndResume(id)
        answerMessages(c)
        guard case .finale = c.screen else { return XCTFail("\(c.screen)") }
    }

    func testAnOldRailSaveAtSacramentoStillArrives() { arrivesFromAnOldSaveAtTheEnd(Rail.id) }

    func testAnOldVoyageSaveAtSanFranciscoStillArrives() { arrivesFromAnOldSaveAtTheEnd(Horn1849.id) }

    // MARK: A stop's question

    /// Quit on the warning ahead of a stop's question, and again on the question: the
    /// question is still asked, and asked once, and its answer still counts.
    func asksAfterAResume(_ id: String, at stop: String, _ isTheQuestion: (ChoiceEvent) -> Bool) -> GameController {
        let c = controller(id)
        let warning = arriveWarned(c, id, at: stop)
        let passed = c.game!

        let again = quitAndResume(id)
        XCTAssertEqual(again.game, passed)
        onMessage(again, warning)
        answerMessages(again)
        guard case .choice(let asked) = again.screen else {
            XCTFail("the question at \(stop), not \(again.screen)")
            return again
        }
        XCTAssertTrue(isTheQuestion(asked), "\(asked.kind)")

        let third = quitAndResume(id)
        guard case .choice(let still) = third.screen else {
            XCTFail("still the question, not \(third.screen)")
            return third
        }
        XCTAssertEqual(still, asked)
        return third
    }

    func custom(_ key: String) -> (ChoiceEvent) -> Bool {
        { if case .custom(let k, _) = $0.kind { return k == key } else { return false } }
    }

    func testCheyennesHelperIsStillOfferedAfterAResume() {
        let c = asksAfterAResume(Rail.id, at: "cheyenne", custom("helper"))
        guard case .choice(let e) = c.screen else { return }
        let money = c.game!.money
        c.choose(e, option: 0)
        XCTAssertLessThan(c.game!.money, money, "the helper is paid for")
        answerMessages(c)
        guard case .choice(let yard) = c.screen, case .portArrival("cheyenne") = yard.kind else {
            return XCTFail("then the yard: \(c.screen)")
        }
        c.choose(yard, option: 0)
        answerMessages(c)
        guard case .portMenu = c.screen else { return XCTFail("\(c.screen)") }
        XCTAssertTrue(c.game!.atPort)
        XCTAssertNotNil(p.loadSave(Rail.id))
    }

    func testDonnersQuestionIsStillAskedAfterAResume() {
        let c = asksAfterAResume(Rail.id, at: "donner", custom("donner"))
        guard case .choice(let e) = c.screen else { return }
        c.choose(e, option: 0)
        XCTAssertNotNil(c.game!.vars["rail.retainers"], "the answer is kept")
    }

    func testTheLineIsStillCrossedAfterAResume() {
        let c = asksAfterAResume(Horn1849.id, at: "line") { if case .equator = $0.kind { true } else { false } }
        guard case .choice(let e) = c.screen else { return }
        c.choose(e, option: 0)
        answerMessages(c)
        guard case .seaMenu = c.screen else { return XCTFail("a menu, not the loop, after a resume: \(c.screen)") }
        XCTAssertNotNil(p.loadSave(Horn1849.id))
    }

    func testRiosHarbourIsStillOfferedAfterAResume() {
        _ = asksAfterAResume(Horn1849.id, at: "rio") {
            if case .portArrival("rio") = $0.kind { true } else { false }
        }
    }

    // MARK: Over the Pole

    func testTheFlightEndsAfterAResumeAtNome() { endsAfterAResume(Airship.id) }

    func testAnOldFlightSaveAtNomeStillArrives() { arrivesFromAnOldSaveAtTheEnd(Airship.id) }

    /// The Pole's question, then the wireless forecasts it leads to: both still asked, and
    /// the height chosen is the country she flies over.
    func testThePolesQuestionIsStillAskedAfterAResume() {
        let c = asksAfterAResume(Airship.id, at: "pole", custom("pole"))
        guard case .choice(let e) = c.screen else { return }
        c.choose(e, option: 1)
        guard case .choice(let offer) = c.screen, case .custom("forecast", _) = offer.kind else {
            return XCTFail("then the forecasts: \(c.screen)")
        }
        c.choose(offer, option: 0)
        answerMessages(c)
        guard case .seaMenu = c.screen else { return XCTFail("a menu, not the loop, after a resume: \(c.screen)") }
        XCTAssertEqual(c.game!.region.id, "underFog")
        XCTAssertEqual(c.game!.vars["airship.forecasts"], 1)
        XCTAssertNotNil(p.loadSave(Airship.id))
    }

    func testKingsBaysMastIsStillOfferedAfterAResume() {
        let c = asksAfterAResume(Airship.id, at: "kingsbay") {
            if case .portArrival("kingsbay") = $0.kind { true } else { false }
        }
        guard case .choice(let e) = c.screen else { return }
        c.choose(e, option: 0)
        answerMessages(c)
        guard case .portMenu = c.screen else { return XCTFail("\(c.screen)") }
        XCTAssertTrue(c.game!.atPort)
    }

    func testPointBarrowIsStillOfferedAfterAResume() {
        let c = asksAfterAResume(Airship.id, at: "barrow", custom("barrow"))
        guard case .choice(let e) = c.screen else { return }
        let petrol = c.game!.fuel
        c.choose(e, option: 0)
        XCTAssertGreaterThan(c.game!.fuel, petrol, "the camp's petrol is taken on")
    }

    // MARK: The file

    /// A voyage with nothing waiting is written exactly as it always was, so any build
    /// that could read it still can; one with something waiting reads back the same.
    func testTheSaveKeepsWhatIsWaitingBesideTheVoyage() throws {
        let s = Skins.skin(Rail.id)!.debug.start(4, 9)
        p.save(s)
        let url = p.directory.appendingPathComponent("save-\(Rail.id).json")
        let plain = try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as! NSDictionary
        let state = try JSONSerialization.jsonObject(with: JSONEncoder().encode(s)) as! NSDictionary
        XCTAssertEqual(plain, state)
        XCTAssertTrue(p.loadVoyage(Rail.id)!.pending.isEmpty)

        let waiting: [Interrupt] = [.message("Low on wood."), .arrival(stopID: "cheyenne")]
        p.save(s, pending: waiting)
        XCTAssertEqual(try JSONDecoder().decode(GameState.self, from: Data(contentsOf: url)), s,
                       "the voyage alone still reads from it")
        XCTAssertEqual(p.loadVoyage(Rail.id)!.pending, waiting)
        XCTAssertEqual(p.loadSave(Rail.id), s)
    }

    /// A train whose engine has given out, on the Platte, under way.
    func brokenDown(_ c: GameController, fittings: Int, money: Double) {
        var s = Skins.skin(Rail.id)!.debug.start(2, 9)
        s.sails = 0
        s.sailcloth = fittings
        s.money = money
        c.loadForDebug(s)
        c.startTravel()
        c.tick()
    }

    func testABreakdownIsStillThereAfterAResumeAndMendingRollsOn() {
        let c = controller(Rail.id)
        brokenDown(c, fittings: 1, money: 100)
        guard case .choice(let ask) = c.screen, case .custom("breakdown", _) = ask.kind else { return XCTFail("\(c.screen)") }
        let mile = c.game!.mile
        let d = quitAndResume(Rail.id)
        guard case .choice(let again) = d.screen else { return XCTFail("the breakdown again: \(d.screen)") }
        XCTAssertEqual(again, ask)
        d.choose(again, option: 2)
        guard case .seaMenu = d.screen else { return XCTFail("taking stock: \(d.screen)") }
        XCTAssertEqual(d.game!.mile, mile)
        d.startTravel()
        d.tick()
        guard case .choice(let third) = d.screen else { return XCTFail("still broken down: \(d.screen)") }
        d.choose(third, option: 0)
        XCTAssertEqual(answerMessages(d).last?.hasSuffix("[green](Engine now 25%)[/green]"), true)
        guard case .travel = d.screen else { return XCTFail("rolling again: \(d.screen)") }
        d.tick()
        XCTAssertGreaterThan(d.game!.mile, mile)
    }

    /// Found by review: a train that gave out in a yard went back to the yard every time she
    /// was sent on, and the yard's menu has no repairs row. Now she is asked; the yard's
    /// store sells the part, and the question, resumed, fits it.
    func testABreakdownInAYardIsMendedFromTheStore() {
        let c = controller(Rail.id)
        var s = Skins.skin(Rail.id)!.debug.start(2, 9)
        s.mile = 291
        s.stopIndex = Journeys.journey(Rail.id).stops.firstIndex { $0.id == "northplatte" }!
        s.atPort = true
        s.sails = 0
        s.sailcloth = 0
        s.money = 20
        c.loadForDebug(s)
        guard case .portMenu = c.screen else { return XCTFail("\(c.screen)") }
        c.startTravel()
        c.tick()
        guard case .choice(let ask) = c.screen, case .custom("breakdown", _) = ask.kind else { return XCTFail("\(c.screen)") }
        XCTAssertEqual(ask.options.map(\.enabled), [false, true])
        c.choose(ask, option: 1)
        guard case .portMenu = c.screen else { return XCTFail("down into the yard: \(c.screen)") }
        XCTAssertTrue(c.run { $0.buy([.sailcloth: 1]) })
        c.startTravel()
        c.tick()
        guard case .choice(let again) = c.screen else { return XCTFail("asked again: \(c.screen)") }
        let d = quitAndResume(Rail.id)
        guard case .choice(let resumed) = d.screen else { return XCTFail("resumed: \(d.screen)") }
        XCTAssertEqual(resumed, again)
        XCTAssertTrue(resumed.options[0].enabled)
        d.choose(resumed, option: 0)
        XCTAssertEqual(answerMessages(d).last?.hasSuffix("[green](Engine now 25%)[/green]"), true)
        // A resumed voyage lands on a menu after what was waiting: the one under way, where
        // she stands, at the yard's mile.
        guard case .seaMenu = d.screen else { return XCTFail("a menu after resuming: \(d.screen)") }
        XCTAssertEqual(d.game!.mile, 291)
        d.startTravel()
        d.tick()
        XCTAssertGreaterThan(d.game!.mile, 291)
    }

    /// D14 on the airship: her lift gone over the Ekeberg mast, the question survives a quit;
    /// the ground crew walks her in, the stores sell a bag of ballast, and the question,
    /// asked again as she casts off, drops it.
    func testAnAirshipGoingDownIsStillAskedAfterAResume() {
        let j = Journeys.journey(Airship.id)
        let c = controller(Airship.id)
        var s = Skins.skin(Airship.id)!.debug.start(j.stops.firstIndex { $0.id == "oslo" }!, 4)
        AirshipSkin.at(&s, "oslo")
        s.hull = 0
        s.timber = 0
        s.fuel = 0
        s.money = 50
        c.loadForDebug(s)
        c.startTravel()
        c.tick()
        guard case .choice(let ask) = c.screen, case .custom("sinking", _) = ask.kind else { return XCTFail("\(c.screen)") }
        XCTAssertEqual(ask.options.map(\.enabled), [false, false, true])
        let d = quitAndResume(Airship.id)
        guard case .choice(let resumed) = d.screen else { return XCTFail("resumed: \(d.screen)") }
        XCTAssertEqual(resumed, ask)
        d.choose(resumed, option: 2)
        guard case .portMenu = d.screen else { return XCTFail("walked in to the mast: \(d.screen)") }
        XCTAssertTrue(d.run { $0.buy([.timber: 1]) })
        d.startTravel()
        d.tick()
        guard case .choice(let again) = d.screen else { return XCTFail("asked again: \(d.screen)") }
        XCTAssertEqual(again.options.map(\.enabled), [true, false, true])
        d.choose(again, option: 0)
        XCTAssertEqual(answerMessages(d).last, j.text.patched(20))
        XCTAssertEqual(d.game!.hull, 20)
        XCTAssertEqual(d.game!.mile, 2750)
        if case .travel = d.screen {} else { d.startTravel() }
        d.tick()
        XCTAssertGreaterThan(d.game!.mile, 2750, "and she drifts on")
    }

    func testNothingToMendWithAndNoMoneyEndsTheRun() {
        let c = controller(Rail.id)
        brokenDown(c, fittings: 0, money: 0)
        guard case .gameOver(let title, _) = c.screen else { return XCTFail("\(c.screen)") }
        XCTAssertTrue(title.hasPrefix("Stranded at mile"))
        XCTAssertFalse(p.hasSave(Rail.id))
    }
}
