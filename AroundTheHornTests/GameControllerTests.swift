import XCTest
import HornEngine
@testable import AroundTheHorn

/// Drives whole voyages through the controller's screen routing, the way a player's
/// taps would, without the 0.7 s clock.
@MainActor
final class GameControllerTests: XCTestCase {
    var c: GameController!
    var p: Persistence!

    override func setUp() async throws {
        p = Persistence(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString),
                        defaults: UserDefaults(suiteName: UUID().uuidString)!)
        c = GameController(persistence: p)
        c.tickInterval = .seconds(3600)
    }

    /// Title → role → names → month → shop → departure.
    func setUpVoyage(role: Role = .merchant) {
        c.startNewGame()
        c.chooseRole(role)
        c.setNames(ship: "", captain: "Ira", crew: ["", "", "", ""])
        c.chooseDeparture(year: 1849, month: 0)
        guard case .outfit = c.screen else { return XCTFail("\(c.screen)") }
        c.enterFirstShop()
        guard case .shop(let done) = c.screen else { return XCTFail("\(c.screen)") }
        c.run { $0.buy([.food: 2000, .water: 800, .limes: 20, .clothes: 5, .meds: 6, .sailcloth: 5, .timber: 5, .tackle: 2]) }
        done()
        guard case .depart = c.screen else { return XCTFail("\(c.screen)") }
        c.startTravel()
    }

    func testBlankNamesTakeTheirSuggestions() {
        c.startNewGame()
        c.chooseRole(.whaler)
        let s = c.suggestions
        c.setNames(ship: "  ", captain: "Ira", crew: ["", "Bo", "", ""])
        c.chooseDeparture(year: 1848, month: 11)
        let g = c.game!
        XCTAssertEqual(g.ship, s.ship)
        XCTAssertEqual(g.crew.map(\.name), ["Ira", s.crew[1], "Bo", s.crew[3], s.crew[4]])
        XCTAssertEqual(g.money, 500)
        XCTAssertEqual(g.dateText, "December 1, 1848")
    }

    func testNoDepartureWithoutProvisions() {
        c.startNewGame()
        c.chooseRole(.merchant)
        c.setNames(ship: "", captain: "", crew: ["", "", "", ""])
        c.chooseDeparture(year: 1849, month: 0)
        c.enterFirstShop()
        guard case .shop(let done) = c.screen else { return XCTFail() }
        done()
        guard case .message(let t, _, let then) = c.screen else { return XCTFail("\(c.screen)") }
        XCTAssertEqual(t, GameEngine.noProvisionsRefusal)
        then()
        guard case .shop = c.screen else { return XCTFail("back to the shop") }
    }

    /// Plays to an ending, taking the first enabled option everywhere.
    func playOut(maxSteps: Int = 20_000) -> String {
        for _ in 0..<maxSteps {
            switch c.screen {
            case .travel:
                XCTAssertTrue(c.traveling)
                c.tick()
            case .message(_, _, let then): then()
            case .choice(let e): c.choose(e, option: e.options.firstIndex(where: \.enabled)!)
            case .burial(let id, let cause): c.bury(crewID: id, cause: cause, epitaph: "")
            case .portMenu, .seaMenu:
                XCTAssertNotNil(p.loadSave(Horn1849.id), "a menu always has a save behind it")
                c.startTravel()
            case .finale: return "finale"
            case .gameOver: return "gameover"
            default:
                XCTFail("stuck on \(c.screen)")
                return "stuck"
            }
        }
        return "too long"
    }

    func testAWholeVoyageReachesAnEndingAndClearsTheSave() {
        var endings: [String] = []
        for _ in 0..<6 {
            setUpVoyage()
            endings.append(playOut())
            XCTAssertNil(p.loadSave(Horn1849.id), "no save after the voyage ends")
            XCTAssertFalse(c.traveling)
            c.goToTitle()
        }
        XCTAssertFalse(endings.contains("stuck"))
        XCTAssertFalse(endings.contains("too long"))
    }

    func testAFinaleEntersTheTopTen() {
        setUpVoyage()
        c.run { $0.state.mile = 13_990; $0.state.stopIndex = 10 }
        var finale: GameController.Finale?
        for _ in 0..<50 {
            switch c.screen {
            case .travel: c.tick()
            case .message(_, _, let then): then()
            case .choice(let e): c.choose(e, option: 0)
            case .burial(let id, let cause): c.bury(crewID: id, cause: cause, epitaph: "")
            case .finale(let f): finale = f
            default: break
            }
            if finale != nil { break }
        }
        let f = try! XCTUnwrap(finale)
        XCTAssertNotNil(f.place, "a fresh merchant's arrival beats the tenth score")
        XCTAssertEqual(p.topTen(c.journey)[f.place!].name, "Ira")
        XCTAssertNil(p.loadSave(Horn1849.id))
    }

    func testHeavingToAndBackgroundingStopTheClock() {
        setUpVoyage()
        c.heaveTo()
        guard case .seaMenu = c.screen else { return XCTFail("\(c.screen)") }
        XCTAssertFalse(c.traveling)
        c.startTravel()
        c.scenePhaseChanged(.background)
        XCTAssertFalse(c.traveling)
        guard case .seaMenu = c.screen else { return XCTFail("a menu, not the loop, on return") }
        XCTAssertNotNil(p.loadSave(Horn1849.id))
    }

    func testContinuingASavedVoyage() {
        setUpVoyage()
        for _ in 0..<5 { if case .travel = c.screen { c.tick() } }
        c.heaveTo()
        let saved = c.game!
        c.goToTitle()
        XCTAssertEqual(c.savedVoyage, saved)
        c.continueSavedVoyage()
        XCTAssertEqual(c.game, saved)
        guard case .seaMenu = c.screen else { return XCTFail("\(c.screen)") }
    }

    func testRestAndRepairsReturnWhereTheyStarted() {
        setUpVoyage()
        c.heaveTo()
        c.run { $0.state.sails = 50 }
        c.mendSails()
        while case .message(_, _, let then) = c.screen { then() }
        guard case .repairs = c.screen else { return XCTFail("\(c.screen)") }
        XCTAssertEqual(c.game!.sails, 75)
        c.rest(days: 2)
        while case .message(_, _, let then) = c.screen { then() }
        guard case .seaMenu = c.screen else { return XCTFail("\(c.screen)") }
    }

    func testFishingIsRefusedInAGale() {
        setUpVoyage()
        c.heaveTo()
        c.run { $0.state.weather = .gale }
        c.goFishing()
        guard case .message(let t, _, _) = c.screen else { return XCTFail("\(c.screen)") }
        XCTAssertEqual(t, "The seas are far too rough to fish.")
    }
}
