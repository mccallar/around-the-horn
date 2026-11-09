import XCTest
import HornEngine
@testable import AroundTheHorn

/// Spec §12 M6 through the controller: ports, the Equator, the fork and pilot, the
/// Galápagos, and the marks.
@MainActor
final class PortAndLandmarkTests: XCTestCase {
    var c: GameController!

    override func setUp() async throws {
        let p = Persistence(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString),
                            defaults: UserDefaults(suiteName: UUID().uuidString)!)
        c = GameController(persistence: p)
        c.tickInterval = .seconds(3600)
    }

    /// Sails from the sea menu, clicking through messages, until a choice appears.
    func sailToChoice(maxDays: Int = 30) -> ChoiceEvent? {
        c.startTravel()
        for _ in 0..<maxDays * 10 {
            switch c.screen {
            case .travel: c.tick()
            case .message(_, _, let then): then()
            case .burial(let id, let cause): c.bury(crewID: id, cause: cause, epitaph: "")
            case .choice(let e):
                if case .stranger = e.kind { c.choose(e, option: 1); continue }
                if case .albatross = e.kind { c.choose(e, option: 0); continue }
                if case .stowaway = e.kind { c.choose(e, option: 0); continue }
                if case .icebergs = e.kind { c.choose(e, option: 0); continue }
                return e
            default: return nil
            }
        }
        return nil
    }

    func testAPortVisit() throws {
        c.debugStart(at: "cv")
        let arrival = try XCTUnwrap(sailToChoice())
        XCTAssertEqual(arrival.kind, .portArrival(stopID: "cv"))
        XCTAssertTrue(arrival.prompt.hasPrefix("You have reached the Cape Verde Islands.\n[dim]"))
        c.choose(arrival, option: 0)
        guard case .portMenu = c.screen else { return XCTFail("\(c.screen)") }
        XCTAssertTrue(c.game!.atPort)

        // Talk: three lines in order, then round again.
        let talk = GameData.port(.cv).talk
        for i in 0..<4 {
            c.talk()
            guard case .message(let t, _, let then) = c.screen else { return XCTFail() }
            XCTAssertEqual(t, talk[i % 3])
            then()
        }

        // Three trade attempts a visit.
        for _ in 0..<3 {
            c.trade()
            while true {
                if case .choice(let e) = c.screen { c.choose(e, option: 1); continue }
                if case .message(_, _, let then) = c.screen { then(); continue }
                break
            }
            guard case .portMenu = c.screen else { return XCTFail("\(c.screen)") }
        }
        c.trade()
        guard case .message(let refused, _, let back) = c.screen else { return XCTFail() }
        XCTAssertEqual(refused, "Nobody else on the waterfront wants to trade with you today.")
        back()

        // The shipyard at Cape Verde prices: ceil((100 − hull) × 2.5 × 1.3).
        let money = c.game!.money
        let cost = ((100 - c.game!.hull) * 2.5 * 1.3).rounded(.up)
        c.show(.shipyard)
        c.repairHullAtYard()
        while case .message(_, _, let then) = c.screen { then() }
        guard case .shipyard = c.screen else { return XCTFail("\(c.screen)") }
        XCTAssertEqual(c.game!.hull, 100)
        XCTAssertEqual(c.game!.money, money - cost, accuracy: 1e-9)

        c.startTravel()
        XCTAssertFalse(c.game!.atPort)
        guard case .travel = c.screen else { return XCTFail() }
    }

    func testSailingPastAPort() throws {
        c.debugStart(at: "rio")
        let arrival = try XCTUnwrap(sailToChoice())
        c.choose(arrival, option: 1)
        guard case .travel = c.screen else { return XCTFail("\(c.screen)") }
        XCTAssertFalse(c.game!.atPort)
    }

    func testTheEquatorCeremony() throws {
        c.debugStart(at: "line")
        let e = try XCTUnwrap(sailToChoice())
        XCTAssertEqual(e.kind, .equator)
        let day = c.game!.day
        c.choose(e, option: 0)
        guard case .message(let t, _, _) = c.screen else { return XCTFail() }
        XCTAssertTrue(t.hasSuffix("[green](Crew health improves.)[/green]"))
        XCTAssertEqual(c.game!.day, day + 1)
    }

    func testTheForkAdviceThenTheStraitAndThePilot() throws {
        c.debugStart(at: "tdf", month: 3)
        let fork = try XCTUnwrap(sailToChoice())
        XCTAssertEqual(fork.kind, .fork)
        c.choose(fork, option: 2)
        guard case .message(let advice, _, let then) = c.screen else { return XCTFail() }
        XCTAssertTrue(advice.hasPrefix("Your first mate spits over the rail"))
        then()
        guard case .choice(let again) = c.screen, again.kind == .fork else { return XCTFail("back to the fork") }
        c.choose(again, option: 1)
        guard case .choice(let pilot) = c.screen, case .pilot(75) = pilot.kind else { return XCTFail("\(c.screen)") }
        XCTAssertEqual(pilot.detail, "[dim]You have $\(formatNumber(c.game!.money)).[/dim]")
        let money = c.game!.money
        c.choose(pilot, option: 0)
        XCTAssertEqual(c.game!.passage, .magellan)
        XCTAssertTrue(c.game!.pilot)
        XCTAssertEqual(c.game!.money, money - 75)
    }

    func testTheForkWarnsOfTheSouthernWinter() throws {
        c.debugStart(at: "tdf", month: 5)
        let fork = try XCTUnwrap(sailToChoice())
        XCTAssertTrue(fork.prompt.contains("[red]It is the dead of the southern winter.[/red]"))
    }

    func testTheGalapagosLanding() throws {
        c.debugStart(at: "gal")
        c.run { $0.state.crew[2].ailment = .scurvy; $0.state.noCitrus = 50 }
        let e = try XCTUnwrap(sailToChoice())
        XCTAssertEqual(e.kind, .galapagos)
        let day = c.game!.day
        c.choose(e, option: 0)
        XCTAssertEqual(c.game!.day, day + 2)
        XCTAssertNotEqual(c.game!.crew[2].ailment, .scurvy)
        XCTAssertEqual(c.game!.noCitrus, 0)
    }

    func testThePacificMarkNamesThePassage() {
        c.debugStart(at: "pacific")
        c.run { $0.state.passage = .magellan }
        c.startTravel()
        var seen: [String] = []
        for _ in 0..<40 {
            switch c.screen {
            case .travel: c.tick()
            case .message(let t, _, let then): seen.append(t); then()
            case .choice(let e): c.choose(e, option: 0)
            case .burial(let id, let cause): c.bury(crewID: id, cause: cause, epitaph: "")
            default: break
            }
            if seen.contains(where: { $0.hasPrefix("You have threaded the Strait of Magellan!") }) { return }
        }
        XCTFail("no Pacific message: \(seen)")
    }
}
