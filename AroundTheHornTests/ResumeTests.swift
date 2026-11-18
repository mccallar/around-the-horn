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

    // MARK: The Jet Stream

    func testTheBalloonEndsAfterAResumeAtTheFinishLine() { endsAfterAResume(Balloon.id) }

    func testAnOldBalloonSaveAtTheFinishLineStillArrives() { arrivesFromAnOldSaveAtTheEnd(Balloon.id) }

    func testTheHimalayasQuestionIsStillAskedAfterAResume() {
        let c = asksAfterAResume(Balloon.id, at: "him", custom("him"))
        guard case .choice(let e) = c.screen else { return }
        let propane = c.game!.fuel, mile = c.game!.mile
        c.choose(e, option: 0)
        XCTAssertEqual(c.game!.fuel, propane - 35, accuracy: 1e-9, "the climb over the range burns 35 gallons")
        XCTAssertEqual(c.game!.mile, mile + 200, "and gains two hundred miles")
    }

    /// The edge of the Pacific, then the forecasters it leads to: both still asked, and
    /// the track chosen is the ocean she flies over.
    func testTheForkAndTheForecastersAreStillAskedAfterAResume() {
        let c = asksAfterAResume(Balloon.id, at: "pacific", custom("fork"))
        guard case .choice(let e) = c.screen else { return }
        c.choose(e, option: 1)
        guard case .choice(let offer) = c.screen, case .custom("forecast", _) = offer.kind else {
            return XCTFail("then the forecasters: \(c.screen)")
        }
        let d = quitAndResume(Balloon.id)
        guard case .choice(let still) = d.screen else { return XCTFail("still the forecasters, not \(d.screen)") }
        XCTAssertEqual(still, offer)
        let money = d.game!.money
        d.choose(still, option: 0)
        answerMessages(d)
        guard case .seaMenu = d.screen else { return XCTFail("a menu, not the loop, after a resume: \(d.screen)") }
        XCTAssertEqual(d.game!.money, money - 250)
        XCTAssertEqual(Journeys.journey(Balloon.id).region(d.game!, at: 9000).id, "southtrack")
        XCTAssertTrue(BalloonChart.onSouthTrack(d.game!))
        XCTAssertNotNil(p.loadSave(Balloon.id))
    }

    func testTheDateLinesPartyIsStillOfferedAfterAResume() {
        let c = asksAfterAResume(Balloon.id, at: "dateline", custom("dateline"))
        guard case .choice(let e) = c.screen else { return }
        let day = c.game!.day
        c.choose(e, option: 0)
        XCTAssertEqual(c.game!.day, day + 1, "the party takes a watch")
    }

    func testTheAzoresBoatIsStillOfferedAfterAResume() {
        let c = asksAfterAResume(Balloon.id, at: "azores", custom("azores"))
        guard case .choice(let e) = c.screen else { return }
        XCTAssertEqual(e.options.count, 2)
    }

    func testSagasFieldIsStillOfferedAfterAResume() {
        let c = asksAfterAResume(Balloon.id, at: "saga") {
            if case .portArrival("saga") = $0.kind { true } else { false }
        }
        guard case .choice(let e) = c.screen else { return }
        c.choose(e, option: 0)
        answerMessages(c)
        guard case .portMenu = c.screen else { return XCTFail("\(c.screen)") }
        XCTAssertTrue(c.game!.atPort)
        XCTAssertEqual(BalloonSkin.skin.words(c.game!).place, "Saga")
    }

    /// D14 on the balloon: her lift gone over the Luxor field with no ballast and no
    /// propane to cut away, the question survives a quit; the ground team brings her in,
    /// the store sells a sack, the ground team pays for the climb, and the question, asked
    /// again as she climbs away, drops the sack.
    func testABalloonGoingDownOverAFieldIsStillAskedAfterAResume() {
        let j = Journeys.journey(Balloon.id)
        let c = controller(Balloon.id)
        var s = Skins.skin(Balloon.id)!.debug.start(j.stops.firstIndex { $0.id == "lux" }!, 0)
        BalloonSkin.at(&s, "lux")
        s.hull = 0
        s.timber = 0
        s.fuel = 0
        s.money = 100
        c.loadForDebug(s)
        c.startTravel()
        c.tick()
        guard case .choice(let ask) = c.screen, case .custom("sinking", _) = ask.kind else { return XCTFail("\(c.screen)") }
        XCTAssertEqual(ask.options.map(\.enabled), [false, false, true])
        let d = quitAndResume(Balloon.id)
        guard case .choice(let resumed) = d.screen else { return XCTFail("resumed: \(d.screen)") }
        XCTAssertEqual(resumed, ask)
        d.choose(resumed, option: 2)
        guard case .portMenu = d.screen else { return XCTFail("down on the field: \(d.screen)") }
        XCTAssertEqual(BalloonSkin.skin.words(d.game!).trouble?.value, "No lift")
        XCTAssertNotNil(BalloonSkin.skin.words(d.game!).leaveRefusal, "no lift and a sack for sale: ballast first")
        XCTAssertTrue(d.run { $0.buy([.timber: 1]) })
        XCTAssertNil(BalloonSkin.skin.words(d.game!).leaveRefusal, "the ground team will pay for the climb")
        d.leavePort()
        guard case .travel = d.screen else { return XCTFail("\(d.screen)") }
        d.tick()
        var said = answerMessages(d)
        guard case .choice(let again) = d.screen, case .custom("sinking", _) = again.kind else {
            return XCTFail("asked again: \(d.screen) after \(said)")
        }
        XCTAssertTrue(again.options[0].enabled)
        d.choose(again, option: 0)
        said = answerMessages(d)
        XCTAssertTrue(said.contains { $0.contains("You cut away a sack of ballast") }, "\(said)")
        XCTAssertGreaterThan(d.game!.hull, 0)
        XCTAssertEqual(d.game!.timber, 0)
        XCTAssertFalse(d.game!.over)
    }

    // MARK: The Long Transfer

    func testTheTransferEndsAfterAResumeAtJezero() { endsAfterAResume(Mars.id) }

    func testAnOldTransferSaveAtJezeroStillArrives() { arrivesFromAnOldSaveAtTheEnd(Mars.id) }

    /// The cycler's offer survives a quit; docking is paid for and goes aboard.
    func testTheCyclersOfferIsStillMadeAfterAResume() {
        let c = asksAfterAResume(Mars.id, at: "cycler", custom("cycler"))
        guard case .choice(let e) = c.screen else { return }
        let fuel = c.game!.fuel
        c.choose(e, option: 0)
        answerMessages(c)
        guard case .portMenu = c.screen else { return XCTFail("aboard the Perpetua: \(c.screen)") }
        XCTAssertTrue(c.game!.atPort)
        XCTAssertEqual(c.game!.fuel, fuel - MarsData.dockBurn, accuracy: 1e-9)
        XCTAssertEqual(MarsSkin.skin.words(c.game!).place, "Aboard the Perpetua")
    }

    func testTurnoverIsStillAskedAfterAResume() {
        let c = asksAfterAResume(Mars.id, at: "turnover", custom("turnover"))
        guard case .choice(let e) = c.screen else { return }
        let mile = c.game!.mile
        c.choose(e, option: 1)
        XCTAssertEqual(c.game!.mile, mile + MarsData.turnoverGain, "four days run on")
        XCTAssertEqual(MarsScene.facing(ScenePicture.frame(c.journey, c.game!, moving: true, t: 0)), .astern)
    }

    func testMarsCaptureIsStillAskedAfterAResume() {
        let c = asksAfterAResume(Mars.id, at: "approach", custom("capture"))
        guard case .choice(let e) = c.screen else { return }
        let fuel = c.game!.fuel
        c.choose(e, option: 1)
        XCTAssertEqual(c.game!.fuel, fuel - MarsData.captureBurn, accuracy: 1e-9)
        XCTAssertEqual(c.game!.vars[MarsData.captureKey], 2)
    }

    func testMidwayIsStillOfferedAfterAResume() {
        let c = asksAfterAResume(Mars.id, at: "midway") {
            if case .portArrival("midway") = $0.kind { true } else { false }
        }
        guard case .choice(let e) = c.screen else { return }
        c.choose(e, option: 0)
        answerMessages(c)
        guard case .portMenu = c.screen else { return XCTFail("\(c.screen)") }
        XCTAssertEqual(MarsSkin.skin.words(c.game!).place, "Docked at Midway")
    }

    /// D14 on the transfer: the array gone dark as she reaches Turnover. Turnover waits;
    /// the dark question, without its coast, survives a quit; a panel puts the power back,
    /// and Turnover is met on the next day.
    func testTurnoverReachedDarkWaitsForPowerAcrossAResume() {
        let j = Journeys.journey(Mars.id)
        let c = controller(Mars.id)
        var s = Skins.skin(Mars.id)!.debug.start(j.stops.firstIndex { $0.id == "turnover" }!, 9)
        s.mile = j.stop("turnover")!.mile - 1
        s.sails = 0
        s.sailcloth = 1
        c.loadForDebug(s)
        c.startTravel()
        c.tick()
        guard case .choice(let first) = c.screen, case .custom("dark", _) = first.kind else {
            return XCTFail("the dark question: \(c.screen)")
        }
        // A day's coast, which reaches Turnover in the dark.
        c.choose(first, option: first.options.firstIndex { $0.label.hasPrefix("Coast") }!)
        var said: [String] = []
        var asked: ChoiceEvent?
        for _ in 0..<12 {
            said += answerMessages(c)
            if case .choice(let e) = c.screen {
                if case .custom("dark", _) = e.kind { asked = e; break }
                c.choose(e, option: e.options.firstIndex(where: \.enabled)!)
                continue
            }
            if case .travel = c.screen {} else { c.startTravel() }
            c.tick()
        }
        guard let ask = asked else { return XCTFail("asked again in the dark: \(c.screen) after \(said)") }
        XCTAssertGreaterThanOrEqual(c.game!.mile, j.stop("turnover")!.mile)
        XCTAssertNotNil(c.game!.vars[MarsData.heldKey], "Turnover is waiting")
        XCTAssertTrue(said.contains { $0.contains("nobody turns a ship end for end without a drive") }, "\(said)")
        XCTAssertFalse(ask.options.contains { $0.label.contains("Coast") }, "no coasting past a set piece")
        XCTAssertEqual(MarsSkin.skin.words(c.game!).trouble?.value, "Array dark, coasting")
        XCTAssertEqual(MarsScene.facing(ScenePicture.frame(j, c.game!, moving: true, t: 0)), .ahead, "not yet turned")

        let d = quitAndResume(Mars.id)
        guard case .choice(let resumed) = d.screen else { return XCTFail("resumed: \(d.screen)") }
        XCTAssertEqual(resumed, ask)
        d.choose(resumed, option: 0)
        answerMessages(d)
        XCTAssertGreaterThan(d.game!.sails, 0.5)
        if case .travel = d.screen {} else { d.startTravel() }
        d.tick()
        answerMessages(d)
        guard case .choice(let turn) = d.screen, case .custom("turnover", _) = turn.kind else {
            return XCTFail("then Turnover: \(d.screen)")
        }
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

// MARK: - To the Klondike

extension ResumeTests {
    func testTheTrekEndsAfterAResumeAtDawson() { endsAfterAResume(Klondike.id) }

    func testAnOldTrekSaveAtDawsonStillArrives() { arrivesFromAnOldSaveAtTheEnd(Klondike.id) }

    /// Every stop between Seattle and Dawson: quit on the warning that came with it, and
    /// again on what the stop says or asks. Each comes back once, and is the stop's own: the
    /// pass at Lynn Canal, the police at the summit, the canyon and the rapids, a town's
    /// welcome, a landmark's note.
    func testEveryStopOfTheTrekIsStillMetAfterAResume() {
        let j = Journeys.journey(Klondike.id)
        let asks = ["lynn": "fork", "summit": "police", "canyon": "canyon", "fivefinger": "fivefinger"]
        for stop in j.stops.dropFirst().dropLast() {
            let c = controller(Klondike.id)
            let warning = arriveWarned(c, Klondike.id, at: stop.id)
            let passed = c.game!
            XCTAssertEqual(passed.currentStop.id, stop.id)

            let again = quitAndResume(Klondike.id)
            XCTAssertEqual(again.game, passed, stop.id)
            onMessage(again, warning)
            if case .message(_, _, let then) = again.screen { then() }
            let isMark = asks[stop.id] == nil && j.port(stop.id) == nil
            if !isMark { answerMessages(again) }
            switch again.screen {
            case .choice(let asked):
                if let key = asks[stop.id] {
                    XCTAssertTrue(custom(key)(asked), "\(stop.id): \(asked.kind)")
                } else {
                    guard case .portArrival(let id) = asked.kind else { XCTFail("\(stop.id): \(asked.kind)"); continue }
                    XCTAssertEqual(id, stop.id)
                }
                let third = quitAndResume(Klondike.id)
                guard case .choice(let still) = third.screen else { XCTFail("\(stop.id): \(third.screen)"); continue }
                XCTAssertEqual(still, asked, stop.id)
                third.choose(still, option: still.options.firstIndex(where: \.enabled)!)
                answerMessages(third)
                if case .choice(let next) = third.screen { XCTAssertNotEqual(next, still, "\(stop.id): asked once") }
            case .message(let said, _, _):
                XCTAssertTrue(isMark, "\(stop.id) asks, and said “\(said)”")
                let third = quitAndResume(Klondike.id)
                onMessage(third, said)
                answerMessages(third)
                if case .message(let next, _, _) = third.screen { XCTAssertNotEqual(next, said, "\(stop.id): said once") }
            default:
                XCTFail("\(stop.id): \(again.screen)")
            }
        }
    }

    /// D14 on the river: Miles Canyon reached with the oars given out waits. The question,
    /// saying so, survives a quit; re-rigged, the canyon is met on the next day.
    func testMilesCanyonReachedWithNoSweepWaitsAcrossAResume() {
        let j = Journeys.journey(Klondike.id)
        let i = j.stops.firstIndex { $0.id == "canyon" }!
        var s = Skins.skin(Klondike.id)!.debug.start(i, 5)
        s.stopIndex = i
        s.mile = j.stops[i].mile
        s.vars[KlondikeData.heldKey] = Double(i)
        s.sails = 0
        s.sailcloth = 1
        let c = controller(Klondike.id)
        c.loadForDebug(s)
        c.startTravel()
        c.tick()
        guard case .choice(let ask) = c.screen, custom("givenout")(ask) else { return XCTFail("given out: \(c.screen)") }
        XCTAssertTrue(ask.prompt.contains("Nobody takes a boat into Miles Canyon without a sweep."), ask.prompt)
        XCTAssertEqual(KlondikeSkin.skin.words(c.game!).trouble?.value, "Oars & sail given out")

        let again = quitAndResume(Klondike.id)
        guard case .choice(let still) = again.screen else { return XCTFail("still the question, not \(again.screen)") }
        XCTAssertEqual(still, ask)
        again.choose(still, option: 0)
        answerMessages(again)
        XCTAssertGreaterThan(again.game!.sails, 0.5)
        XCTAssertNil(KlondikeSkin.skin.words(again.game!).trouble)
        if case .travel = again.screen {} else { again.startTravel() }
        again.tick()
        answerMessages(again)
        guard case .choice(let canyon) = again.screen, custom("canyon")(canyon) else {
            return XCTFail("the canyon, waiting: \(again.screen)")
        }
        XCTAssertNil(again.game!.vars[KlondikeData.heldKey])
    }

    /// Sleds given out with no rope, saved on the question: back on it, a coil bought off the
    /// next party along at three times Seattle's price, and the party moves again.
    func testGivenOutSledsAreStillAskedAfterAResume() {
        var s = Skins.skin(Klondike.id)!.debug.start(4, 2)
        s.sails = 0
        s.sailcloth = 0
        s.money = 100
        let c = controller(Klondike.id)
        c.loadForDebug(s)
        c.startTravel()
        c.tick()
        guard case .choice(let ask) = c.screen, custom("givenout")(ask) else { return XCTFail("given out: \(c.screen)") }
        XCTAssertEqual(ask.options.map(\.enabled), [false, true, true, true])
        let mile = c.game!.mile

        let again = quitAndResume(Klondike.id)
        guard case .choice(let still) = again.screen else { return XCTFail("still the question, not \(again.screen)") }
        XCTAssertEqual(still, ask)
        XCTAssertEqual(again.game!.mile, mile, "nobody moved")
        again.choose(still, option: 1)
        answerMessages(again)
        XCTAssertEqual(again.game!.money, 100 - KlondikeData.coilPrice, accuracy: 1e-9)
        XCTAssertGreaterThan(again.game!.sails, 0.5)
        XCTAssertNil(KlondikeSkin.skin.words(again.game!).trouble)
    }
}
