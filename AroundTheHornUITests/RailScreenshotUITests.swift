import XCTest

/// Walks The Iron Road from the picker to both endings, saving a PNG of each screen to
/// `$HORN_SHOTS` (see `ScreenshotWalk`). The reference set is `docs/reference/shots-rail/`.
final class RailScreenshotUITests: ScreenshotWalk {
    static let rail = ["-journey", "rail"]
    override class var journeyArgs: [String] { rail }

    /// What the road may ask on the way to somewhere else, and the answer that costs
    /// least: wait, decline, roll on.
    static let patience = [
        "Continue", "Continue down the line", "Take the main line straight through", "Wait for them to cross",
        "Wait for the section gang", "Back into the spur here and let her by", "Back up to the last creek and let it pass",
        "Dig it out by hand", "Set him down at the next section house with a meal", "Decline, politely", "Decline",
        "Lay to rest", "Wait for the wind to drop",
    ]

    /// Answers whatever comes up until a button called `label` (or starting with it) is on screen.
    func roll(until label: String, tries: Int = 60) {
        let target = button(startingWith: label)
        let next = app.buttons.matching(NSPredicate(format: "label IN %@", Self.patience)).firstMatch
        for _ in 0..<tries where !target.exists {
            if next.waitForExistence(timeout: 2) { next.tap() }
        }
        XCTAssertTrue(target.waitForExistence(timeout: 10), "never reached \(label)")
    }

    func testPickerAndSetup() {
        shot("01-title")
        tap("Choose another journey")
        XCTAssertTrue(app.staticTexts["Choose a journey"].waitForExistence(timeout: 5))
        shot("00-picker")
        button(startingWith: "The Iron Road").tap()
        tap("Learn about the road")
        shot("02-learn")
        tap("Next")
        shot("02-learn-2")
        tap("Next")
        shot("02-learn-3")
        tap("Back to the start")
        tap("Take the contract")
        shot("03-role")
        tap("Find out the differences")
        shot("04-differences")
        tap("Back")
        tap("Be a freight contractor from Chicago")
        shot("05-names")
        tap("Use these names")
        shot("06-month")
        tap("Ask for advice")
        shot("07-advice")
        tap("Continue")
        tap("October 1869")
        shot("08-outfit")
    }

    func testShopAndTheRoad() {
        relaunch(["-HornTickSeconds", "6"])
        tap("Take the contract")
        tap("Be a river hand from St. Louis")
        tap("Use these names")
        tap("October 1869")
        tap("Enter the store")
        shot("10-shop-empty")
        for _ in 0..<14 { app.buttons["More Firewood"].tap() }
        for _ in 0..<10 { app.buttons["More Tank water"].tap() }
        for _ in 0..<8 { app.buttons["More Provisions"].tap() }
        for _ in 0..<5 { app.buttons["More Wool blankets"].tap() }
        shot("11-shop")
        app.swipeUp()
        app.swipeUp()
        for _ in 0..<2 { app.buttons["More Boiler fittings"].tap() }
        for _ in 0..<2 { app.buttons["More Car spares"].tap() }
        for _ in 0..<2 { app.buttons["More Grapnel line"].tap() }
        shot("12-shop-bottom")
        let pay = button(startingWith: "Pay $")
        XCTAssertTrue(pay.waitForExistence(timeout: 5))
        pay.tap()
        shot("13-depart")
        tap("Whistle off")
        let halt = app.buttons["Stop the train & take stock"]
        XCTAssertTrue(halt.waitForExistence(timeout: 5))
        shot("14-travel")
        for _ in 0..<20 where !halt.isHittable {
            let next = app.buttons.matching(NSPredicate(format: "label IN %@", Self.patience)).firstMatch
            if next.exists { next.tap() }
        }
        XCTAssertTrue(halt.waitForExistence(timeout: 5))
        halt.tap()
        shot("15-menu")
        tap("Check supplies & crew")
        shot("16-supplies")
        app.swipeUp()
        shot("17-supplies-bottom")
        tap("Back")
        button(startingWith: "Change pace").tap()
        shot("18-pace")
        button(startingWith: "Timetable").tap()
        button(startingWith: "Change rations").tap()
        shot("19-rations")
        button(startingWith: "Filling").tap()
        tap("Stop and rest")
        shot("20-rest")
        tap("Never mind")
        tap("Make repairs")
        shot("21-repairs")
    }

    /// The country and the weather: three places in three seasons, and the gallery.
    func testTheCountry() {
        for (stop, month, name) in [("promontory", "7", "25-salt-desert-august"), ("capehorn", "1", "26-sierra-february"),
                                    ("rawlins", "5", "27-laramie-plains-june"), ("sink", "9", "28-humboldt-october")] {
            relaunch(["-HornDebugStart", stop, "-HornDebugMonth", month, "-HornTickSeconds", "4"])
            tap("Continue down the line")
            // The first turn reaches the stop and says so; the shot is of the country after it,
            // with the weather that turn rolled.
            let halt = app.buttons["Stop the train & take stock"]
            for _ in 0..<12 where !(halt.exists && halt.isHittable) {
                let next = app.buttons.matching(NSPredicate(format: "label IN %@", Self.patience)).firstMatch
                if next.waitForExistence(timeout: 6) { next.tap() }
            }
            XCTAssertTrue(halt.waitForExistence(timeout: 5))
            shot(name)
        }
        relaunch(["-HornSceneGallery", "YES"])
        shot("29-gallery")
        app.swipeUp()
        shot("29-gallery-2")
    }

    func testTheHelperAndAYard() {
        relaunch(["-HornDebugStart", "cheyenne", "-HornTickSeconds", "1"])
        tap("Continue down the line")
        roll(until: "Hire the helper")
        shot("30-helper")
        button(startingWith: "Hire the helper").tap()
        shot("31-helper-hired")
        roll(until: "Pull into the yard and lay over")
        shot("32-arrival")
        tap("Pull into the yard and lay over")
        shot("33-yard-menu")
        tap("Talk to people")
        shot("34-talk")
        tap("Continue")
        tap("Visit the roundhouse")
        shot("35-roundhouse")
        tap("Leave the roundhouse")
        tap("Lay over in the yard")
        shot("36-layover")
        tap("Never mind")
        tap("Buy supplies")
        shot("37-yard-shop")
    }

    func testTheTrestleAndTheSummit() {
        relaunch(["-HornDebugStart", "dalecreek", "-HornTickSeconds", "30"])
        shot("38-dale-creek-menu")
        tap("Continue down the line")
        XCTAssertTrue(app.buttons["Stop the train & take stock"].waitForExistence(timeout: 5))
        shot("39-dale-creek")

        relaunch(["-HornDebugStart", "donner", "-HornTickSeconds", "1"])
        tap("Continue down the line")
        roll(until: "Let her roll")
        shot("40-donner")
        tap("Set the retainers and come down slow")
        shot("41-retainers")
    }

    func testTheMapAndDriftwood() {
        relaunch(["-HornDebugStart", "northplatte", "-HornTickSeconds", "30"])
        tap("Look at the map")
        shot("45-map")
        tap("Back")
        tap("Haul driftwood")
        let river = app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH 'The river from the bank'")).firstMatch
        XCTAssertTrue(river.waitForExistence(timeout: 5))
        shot("46-driftwood")
        for dy in [0.55, 0.4, 0.25, 0.5, 0.35] {
            river.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: dy)).tap()
            usleep(350_000)
        }
        river.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.15)).tap()
        usleep(200_000)
        shot("47-driftwood-cast", settle: false)
        tap("Back to the train")
        XCTAssertTrue(app.buttons["Continue"].waitForExistence(timeout: 5), "Back to the train didn't land")
        shot("48-haul")
    }

    func testArrival() {
        relaunch(["-HornDebugStart", "sacramento", "-HornTickSeconds", "1"])
        tap("Continue down the line")
        roll(until: "Run it again")
        shot("50-arrival")
        app.swipeUp()
        shot("51-arrival-bottom")
        tap("See the top ten")
        shot("52-top-ten")
        tap("Back")
        shot("53-thanks")
        tap("Run it again")
        XCTAssertTrue(app.buttons["Take the contract"].waitForExistence(timeout: 5))
        XCTAssertFalse(button(startingWith: "Climb back aboard").exists, "no save survives the arrival")
    }

    /// The other ending: sixteen days out and still short of Sacramento.
    func testTheContractForfeit() {
        relaunch(["-HornDebugStart", "sacramento", "-HornTickSeconds", "60"])
        let over = app.buttons["Try again"], rest = app.buttons["Stop and rest"]
        let next = app.buttons["Continue"]
        var late = false
        for _ in 0..<14 where !over.exists {
            XCTAssertTrue(rest.waitForExistence(timeout: 10))
            rest.tap()
            tap("1 day")
            for _ in 0..<8 where !over.exists && !rest.exists {
                if next.waitForExistence(timeout: 2) {
                    if !late && app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'now late'")).firstMatch.exists {
                        late = true
                        shot("54-late")
                    }
                    next.tap()
                }
            }
            if late && rest.exists && !FileManager.default.fileExists(atPath: dir.appendingPathComponent("55-late-menu.png").path) {
                shot("55-late-menu")
            }
        }
        XCTAssertTrue(over.waitForExistence(timeout: 10), "the contract never ran out")
        shot("56-forfeit")
        over.tap()
        XCTAssertTrue(app.buttons["Take the contract"].waitForExistence(timeout: 5))
        XCTAssertFalse(button(startingWith: "Climb back aboard").exists, "no save survives a forfeit")
        tap("See the top ten")
        shot("57-top-ten")
    }

    /// Accessibility text sizes: the longer rail labels still fit.
    func testLargeText() {
        relaunch(["-HornDebugStart", "elko", "-HornTickSeconds", "30",
                  "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
        shot("70-large-menu")
        tap("Check supplies & crew")
        shot("71-large-supplies")
    }
}
