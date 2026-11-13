import XCTest
@testable import HornEngine
@testable import AroundTheHorn

/// Choosing a journey, getting back to choose another, and what belongs to which.
///
/// The engine has one journey, so the second on the list is a stand-in with its own id,
/// title and top ten (`TestJourneys`): two rows that can be told apart, which the same
/// journey listed twice could never be. A stand-in can't be sailed (the engine only
/// sails its own), so the voyages here are all 1849's.
@MainActor
final class JourneyPickerTests: XCTestCase {
    var p: Persistence!
    let fm = FileManager.default
    let horn = TestJourneys.horn
    let other = TestJourneys.copy(id: "test-other", title: "The Other Way")

    var both: [Journey] { [horn, other] }
    var bothSkins: [JourneySkin] { [Horn1849Skin.skin, TestJourneys.skin(other.id)] }

    override func setUp() async throws {
        p = Persistence(directory: fm.temporaryDirectory.appendingPathComponent(UUID().uuidString),
                        defaults: UserDefaults(suiteName: UUID().uuidString)!)
    }

    func two(journey: String? = nil) -> GameController {
        let c = GameController(persistence: p, journeys: both, skins: bothSkins, journey: journey)
        c.tickInterval = .seconds(3600)
        return c
    }

    func isPicker(_ c: GameController) -> Bool { if case .picker = c.screen { return true } else { return false } }
    func isTitle(_ c: GameController) -> Bool { if case .title = c.screen { return true } else { return false } }
    func isMenu(_ c: GameController) -> Bool {
        switch c.screen {
        case .seaMenu, .portMenu: return true
        default: return false
        }
    }

    /// 1849 well under way, ten miles short of its fourth stop.
    var underWay: GameState { Horn1849Skin.skin.debug.start(3, 0) }

    // MARK: One journey: as it was before there were others

    func testOneJourneyOpensOnItsTitleCardWithNoWayToAPicker() {
        let one = [Journeys.all[0]]
        let c = GameController(persistence: p, journeys: one)
        XCTAssertTrue(isTitle(c))
        XCTAssertFalse(c.hasPicker)
        c.goToPicker()
        XCTAssertTrue(isTitle(c), "there is nothing to pick between")
        XCTAssertTrue(isTitle(GameController(persistence: p, journeys: one, journey: "no-such-journey")))
    }

    /// The rows that lead back to a title card exist only where there is a picker beyond
    /// it: 1849 alone has the menus it always had.
    func testALoneJourneyHasNoExtraRows() {
        let c = GameController(persistence: p)
        XCTAssertEqual(c.journeys.map(\.id), Journeys.all.map(\.id))
        if Journeys.all.count == 1 {
            XCTAssertTrue(c.wayBack.isEmpty)
            XCTAssertTrue(c.wayOut.isEmpty)
            c.loadForDebug(underWay)
            XCTAssertTrue(c.wayOut.isEmpty)
        }
        let one = GameController(persistence: p, journeys: [horn])
        XCTAssertTrue(one.wayBack.isEmpty && one.wayOut.isEmpty)
    }

    func testALoneJourneyTakesNoNoticeOfARememberedOne() {
        p.lastJourney = other.id
        let c = GameController(persistence: p, journeys: [horn])
        XCTAssertTrue(isTitle(c))
        XCTAssertEqual(c.journey.id, horn.id)
        XCTAssertEqual(c.skin.id, horn.id)
    }

    // MARK: Several

    func testSeveralJourneysOpenOnThePickerAndEachRowLeadsToItsOwnTitleCard() {
        let c = two()
        XCTAssertTrue(isPicker(c))
        XCTAssertTrue(c.hasPicker)
        XCTAssertEqual(c.journeys.map(\.id), [horn.id, other.id], "in the order given")
        XCTAssertEqual(c.journeys.map { PickerView.label($0, inProgress: false) }, [horn.title, "The Other Way"])
        XCTAssertNotEqual(horn.title, other.title)

        c.chooseJourney(other.id)
        XCTAssertTrue(isTitle(c))
        XCTAssertEqual(c.journey.id, other.id)
        XCTAssertEqual(c.journeyID, other.id)
        XCTAssertEqual(c.journey.title, "The Other Way")
        XCTAssertEqual(c.skin.id, other.id, "and its own skin, not the first on the list")

        c.goToPicker()
        XCTAssertTrue(isPicker(c))
        c.chooseJourney(horn.id)
        XCTAssertTrue(isTitle(c))
        XCTAssertEqual(c.journey.id, horn.id)
        XCTAssertEqual(c.skin.id, horn.id)
    }

    func testAnUnknownRowChangesNothingAtAll() {
        let c = two()
        c.chooseJourney(other.id)
        c.goToPicker()
        let shown = c.screenID
        c.chooseJourney("no-such-journey")
        XCTAssertEqual(c.journey.id, other.id)
        XCTAssertEqual(c.skin.id, other.id)
        XCTAssertTrue(isPicker(c), "still on the picker")
        XCTAssertEqual(c.screenID, shown, "nothing was shown")
        XCTAssertEqual(p.lastJourney, other.id, "nor remembered")
    }

    func testTheLaunchArgumentGoesStraightToThatTitleCard() {
        for j in both {
            let c = two(journey: j.id)
            XCTAssertTrue(isTitle(c))
            XCTAssertEqual(c.journey.id, j.id)
            XCTAssertEqual(c.skin.id, j.id)
        }
        let c = two(journey: "no-such-journey")
        XCTAssertTrue(isPicker(c), "an id nobody knows is no choice at all")
        XCTAssertNil(p.lastJourney, "a launch argument is not a choice to remember")
    }

    // MARK: The last journey chosen is where the app opens

    func testTheChosenJourneyIsRememberedForTheNextLaunch() {
        let first = two()
        XCTAssertTrue(isPicker(first))
        XCTAssertNil(p.lastJourney, "nothing is chosen until a row is tapped")
        first.chooseJourney(other.id)
        XCTAssertEqual(p.lastJourney, other.id)

        let next = two()
        XCTAssertTrue(isTitle(next), "straight back to where the player was")
        XCTAssertEqual(next.journey.id, other.id)
        XCTAssertEqual(next.skin.id, other.id)
        XCTAssertTrue(next.hasPicker)
        next.goToPicker()
        XCTAssertTrue(isPicker(next), "and the picker is still one tap away")
        next.chooseJourney(horn.id)
        XCTAssertEqual(two().journey.id, horn.id)
    }

    func testTheLaunchArgumentWinsOverTheRememberedJourney() {
        p.lastJourney = other.id
        let c = two(journey: horn.id)
        XCTAssertTrue(isTitle(c))
        XCTAssertEqual(c.journey.id, horn.id)
        XCTAssertEqual(p.lastJourney, other.id)
    }

    func testARememberedJourneyThatIsNoLongerOfferedLeadsToThePicker() {
        p.lastJourney = "a-journey-since-removed"
        let c = two()
        XCTAssertTrue(isPicker(c))
        XCTAssertEqual(c.journey.id, horn.id)
        XCTAssertEqual(c.skin.id, horn.id)
    }

    // MARK: A journey without a skin is not offered

    func testAJourneyNobodyHasDrawnIsNotOnTheList() {
        let c = GameController(persistence: p, journeys: both, skins: [Horn1849Skin.skin])
        XCTAssertEqual(c.journeys.map(\.id), [horn.id], "never shown wearing another journey's skin")
        XCTAssertFalse(c.hasPicker)
        XCTAssertTrue(isTitle(c))
        XCTAssertEqual(c.journey.id, horn.id)
        c.chooseJourney(other.id)
        XCTAssertEqual(c.journey.id, horn.id)
        XCTAssertEqual(c.skin.id, horn.id)
        XCTAssertNil(p.lastJourney)

        // Nor reached by the launch argument or a remembered choice.
        p.lastJourney = other.id
        let named = GameController(persistence: p, journeys: both, skins: [Horn1849Skin.skin], journey: other.id)
        XCTAssertTrue(isTitle(named))
        XCTAssertEqual(named.journey.id, horn.id)
        XCTAssertEqual(named.skin.id, horn.id)

        // And a skin with no journey offers nothing.
        let spare = GameController(persistence: p, journeys: [horn], skins: bothSkins)
        XCTAssertEqual(spare.journeys.map(\.id), [horn.id])
    }

    func testTheSkinIsAlwaysTheJourneysOwn() {
        // Listed in another order, each journey still gets the skin with its id.
        let c = GameController(persistence: p, journeys: both, skins: bothSkins.reversed())
        for j in both + both.reversed() {
            c.chooseJourney(j.id)
            XCTAssertEqual(c.journey.id, j.id)
            XCTAssertEqual(c.skin.id, j.id)
        }
    }

    func testAVoyageFromAJourneyNotOfferedIsRefused() {
        let c = two(journey: other.id)
        var stray = underWay
        stray.journey = "no-such-journey"
        c.loadForDebug(stray)
        XCTAssertNil(c.game, "it would be played with another journey's words and pictures")
        XCTAssertTrue(isTitle(c))
        XCTAssertEqual(c.journey.id, other.id)

        // One that is offered brings its journey and its skin with it.
        c.loadForDebug(underWay)
        XCTAssertEqual(c.game?.journey, horn.id)
        XCTAssertEqual(c.journey.id, horn.id)
        XCTAssertEqual(c.skin.id, horn.id)
        XCTAssertTrue(isMenu(c))
    }

    // MARK: Voyages in progress, as the picker marks them

    func testThePickerMarksTheJourneysWithAVoyageUnderWay() {
        XCTAssertEqual(PickerView.label(horn, inProgress: true), horn.title + " [amber]· in progress[/amber]")
        XCTAssertEqual(PickerView.label(horn, inProgress: false), horn.title)

        let c = two()
        XCTAssertEqual(c.inProgress, [], "no voyages yet")
        p.save(underWay)
        XCTAssertEqual(c.inProgress, [], "the picker's rows read what was found when it was shown, not the disk")
        c.chooseJourney(horn.id)
        c.goToPicker()
        XCTAssertEqual(c.inProgress, [horn.id], "found again each time the picker is shown")

        // A launch that opens on the picker finds them too.
        p.lastJourney = nil
        XCTAssertEqual(two().inProgress, [horn.id])

        p.deleteSave(horn.id)
        c.goToPicker()
        XCTAssertEqual(c.inProgress, [])
    }

    // MARK: Out of a voyage and back

    func testEverySetupScreenHasAWayBackToTheTitleCard() {
        let c = two(journey: horn.id)
        XCTAssertEqual(c.wayBack.map(\.label), ["Back to the title"])
        c.startNewGame()
        c.chooseRole(.merchant)
        c.setNames(ship: "", captain: "", crew: ["", "", "", ""])
        c.chooseDeparture(year: 1849, month: 0)
        guard case .outfit = c.screen else { return XCTFail("\(c.screen)") }
        c.wayBack[0].action()
        XCTAssertTrue(isTitle(c))
        XCTAssertNil(c.game, "a voyage never begun is not kept")
        XCTAssertNil(c.savedVoyage)
        c.goToPicker()
        XCTAssertTrue(isPicker(c))
    }

    func testAVoyageCanBeLeftForAnotherJourneyAndComeBackTo() {
        let c = two()
        c.chooseJourney(horn.id)
        c.loadForDebug(underWay)
        XCTAssertTrue(isMenu(c))
        let voyage = c.game!
        XCTAssertEqual(c.wayOut.map(\.label), ["Save and return to the title"])

        // Leaving saves: take the menu's own save away first to see it.
        p.deleteSave(horn.id)
        c.wayOut[0].action()
        XCTAssertTrue(isTitle(c), "out of the voyage, not out of the journey")
        XCTAssertEqual(c.journey.id, horn.id)
        XCTAssertNil(c.game)
        XCTAssertEqual(p.loadSave(horn.id), voyage)
        XCTAssertEqual(c.savedVoyage, voyage, "the title card offers it back")

        // To the picker, to another journey, which has no voyage of its own.
        c.goToPicker()
        XCTAssertTrue(isPicker(c))
        XCTAssertEqual(c.inProgress, [horn.id])
        c.chooseJourney(other.id)
        XCTAssertEqual(c.journey.id, other.id)
        XCTAssertNil(c.savedVoyage, "1849's voyage is not offered on another journey's card")
        c.continueSavedVoyage()
        XCTAssertTrue(isTitle(c))
        XCTAssertNil(c.game)

        // And back.
        c.goToPicker()
        c.chooseJourney(horn.id)
        c.continueSavedVoyage()
        XCTAssertTrue(isMenu(c))
        XCTAssertEqual(c.game, voyage)
        XCTAssertEqual(c.skin.id, horn.id)
    }

    func testLeavingStopsTheClock() {
        let c = two(journey: horn.id)
        c.loadForDebug(underWay)
        c.startTravel()
        XCTAssertTrue(c.traveling)
        let day = c.game!.day
        c.leaveVoyage()
        XCTAssertFalse(c.traveling)
        XCTAssertTrue(isTitle(c))
        XCTAssertEqual(p.loadSave(horn.id)?.day, day)
    }

    // MARK: What belongs to which

    func testTopTensAreKeptApart() throws {
        XCTAssertEqual(p.topTen(other), [TopTenEntry(name: "Nobody", score: 1)])
        XCTAssertEqual(p.topTen(horn), horn.defaultTopTen)
        XCTAssertNotEqual(p.topTen(horn), p.topTen(other))

        let mine = [TopTenEntry(name: "Driver", score: 77)]
        p.saveTopTen(mine, for: other.id)
        XCTAssertEqual(p.topTen(other), mine)
        XCTAssertEqual(p.topTen(horn), horn.defaultTopTen, "another journey's table is not 1849's")

        let theirs = [TopTenEntry(name: "Gran", score: 4321)]
        p.saveTopTen(theirs, for: horn.id)
        XCTAssertEqual(p.topTen(horn), theirs)
        XCTAssertEqual(p.topTen(other), mine)

        // The table from before there were journeys is 1849's alone.
        try fm.removeItem(at: p.topTenURL(horn.id))
        try fm.removeItem(at: p.topTenURL(other.id))
        try JSONEncoder().encode(theirs).write(to: p.legacyTopTenURL)
        XCTAssertEqual(p.topTen(horn), theirs)
        XCTAssertEqual(p.topTen(other), other.defaultTopTen)
    }

    func testSavesAreKeptApart() throws {
        p.save(underWay)
        XCTAssertTrue(p.hasSave(horn.id))
        XCTAssertFalse(p.hasSave(other.id))
        XCTAssertFalse(fm.fileExists(atPath: p.saveURL(other.id).path))
        // 1849's voyage copied under the other's name is still not the other's.
        try fm.copyItem(at: p.saveURL(horn.id), to: p.saveURL(other.id))
        XCTAssertNil(p.loadSave(other.id))
        p.deleteSave(other.id)
        XCTAssertTrue(p.hasSave(horn.id), "ending one journey's voyage leaves the other's")
    }

    func testAVoyageBelongsToTheJourneyItWasStartedIn() {
        for j in Journeys.all {
            let c = GameController(persistence: p, journeys: Journeys.all, journey: j.id)
            c.startNewGame()
            c.chooseRole(.merchant)
            c.setNames(ship: "", captain: "", crew: ["", "", "", ""])
            let d = j.departures[0]
            c.chooseDeparture(year: d.year, month: d.month)
            XCTAssertEqual(c.game?.journey, j.id)
            XCTAssertEqual(c.skin.id, j.id)
            XCTAssertTrue(j.vesselNames.contains(c.game!.ship), "\(j.id): names come from the journey")
        }
    }

    /// Every journey the engine really has: begun, left, found on the picker's list of
    /// voyages under way, and gone back to, each with its own file.
    func testEveryRealJourneyCanBeLeftAndResumed() throws {
        for j in Journeys.all {
            let skin = try XCTUnwrap(Skins.skin(j.id))
            let c = GameController(persistence: p, journeys: Journeys.all + [other],
                                   skins: Skins.all + [TestJourneys.skin(other.id)], journey: j.id)
            c.tickInterval = .seconds(3600)
            c.loadForDebug(skin.debug.start(1, j.departures[0].month))
            let voyage = try XCTUnwrap(c.game)
            c.leaveVoyage()
            XCTAssertTrue(isTitle(c), j.id)
            XCTAssertTrue(fm.fileExists(atPath: p.saveURL(j.id).path), j.id)
            c.goToPicker()
            XCTAssertTrue(c.inProgress.contains(j.id), j.id)
            XCTAssertFalse(c.inProgress.contains(other.id))
            c.chooseJourney(j.id)
            c.continueSavedVoyage()
            XCTAssertEqual(c.game, voyage, j.id)
        }
    }
}
