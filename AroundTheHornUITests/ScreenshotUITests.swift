import XCTest

/// Walks the game and saves a PNG of each screen to `$HORN_SHOTS` (passed to the runner
/// as SIMCTL_CHILD_HORN_SHOTS). Inert without it, so the normal UI suite skips it.
///
/// This is how screens get looked at here: `simctl io screenshot` returns a blank image
/// in the sandbox, while XCUIScreen captures what is really drawn.
final class ScreenshotUITests: XCTestCase {
    var dir: URL!
    var app: XCUIApplication!

    override func setUpWithError() throws {
        guard let d = ProcessInfo.processInfo.environment["HORN_SHOTS"] else { throw XCTSkip("HORN_SHOTS not set") }
        dir = URL(fileURLWithPath: d)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        continueAfterFailure = false
        app = XCUIApplication(bundleIdentifier: LaunchUITests.appBundleID)
        app.launchArguments = ProcessInfo.processInfo.environment["HORN_ARGS"]?.split(separator: " ").map(String.init) ?? []
        app.launch()
    }

    func shot(_ name: String) {
        sleep(1)
        let png = XCUIScreen.main.screenshot().pngRepresentation
        try? png.write(to: dir.appendingPathComponent("\(name).png"))
    }

    func tap(_ label: String) {
        let b = app.buttons[label]
        XCTAssertTrue(b.waitForExistence(timeout: 10), "no button \(label)")
        b.tap()
    }

    func testSetupScreens() {
        shot("01-title")
        tap("Learn about the passage")
        shot("02-learn")
        tap("Next"); tap("Next"); tap("Back to the start")
        tap("Sail for California")
        shot("03-role")
        tap("Find out the differences")
        shot("04-differences")
        tap("Back")
        tap("Be a merchant from Boston")
        shot("05-names")
        tap("Use these names")
        shot("06-month")
        tap("Ask for advice")
        shot("07-advice")
        tap("Continue")
        tap("January 1849")
        shot("08-outfit")
    }
}

extension ScreenshotUITests {
    func testVoyageScreens() {
        app.terminate()
        app.launchArguments = ["-HornTickSeconds", "6"]
        app.launch()
        tap("Sail for California")
        tap("Be a whaler from Nantucket")
        tap("Use these names")
        tap("January 1849")
        tap("Enter the shop")
        for _ in 0..<12 { app.buttons["More Provisions"].tap() }
        for _ in 0..<5 { app.buttons["More Fresh water"].tap() }
        for _ in 0..<5 { app.buttons["More Oilskins & woolens"].tap() }
        for _ in 0..<4 { app.buttons["More Citrus"].tap() }
        shot("10-shop")
        app.swipeUp()
        app.swipeUp()
        shot("11-shop-bottom")
        let pay = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Pay $'")).firstMatch
        XCTAssertTrue(pay.waitForExistence(timeout: 5))
        pay.tap()
        shot("12-depart")
        tap("Set sail")
        let heave = app.buttons["Heave to & take stock"]
        XCTAssertTrue(heave.waitForExistence(timeout: 5))
        shot("13-travel")
        // Keep sailing through whatever the voyage raises until we can heave to.
        for _ in 0..<20 where !heave.isHittable {
            let next = app.buttons.matching(NSPredicate(format: "label == 'Continue' OR label BEGINSWITH 'Drop anchor'")).firstMatch
            if next.exists { next.tap() }
        }
        if heave.waitForExistence(timeout: 5) {
            heave.tap()
            shot("14-sea-menu")
            tap("Check supplies & crew")
            shot("15-supplies")
            app.swipeUp()
            shot("16-supplies-bottom")
            tap("Back")
            app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Change pace'")).firstMatch.tap()
            shot("17-pace")
            tap("Easy sail. Reefed sails. Gentle on ship and crew.")
            tap("Make repairs")
            shot("18-repairs")
        } else {
            shot("14-interrupted")
        }
    }
}

extension ScreenshotUITests {
    func testSceneGallery() {
        app.terminate()
        app.launchArguments = ["-HornSceneGallery", "YES"]
        app.launch()
        shot("20-gallery")
        sleep(1)
        shot("21-gallery-later")
    }
}

extension ScreenshotUITests {
    func relaunch(_ args: [String]) {
        app.terminate()
        app.launchArguments = args
        app.launch()
    }

    /// Taps Continue through messages until `label` appears.
    func sail(until label: String) {
        tap("Continue on your voyage")
        let target = app.buttons[label]
        for _ in 0..<30 where !target.exists {
            let next = app.buttons["Continue"]
            if next.waitForExistence(timeout: 2) { next.tap() }
        }
        XCTAssertTrue(target.waitForExistence(timeout: 10), "never reached \(label)")
    }

    func testPortScreens() {
        relaunch(["-HornDebugStart", "rio", "-HornTickSeconds", "1"])
        sail(until: "Drop anchor and go ashore")
        shot("30-arrival")
        tap("Drop anchor and go ashore")
        shot("31-port-menu")
        tap("Talk to people")
        shot("32-talk")
        tap("Continue")
        tap("Visit the shipyard")
        shot("33-shipyard")
        tap("Leave the shipyard")
        tap("Buy supplies")
        shot("34-port-shop")
    }

    func testForkScreens() {
        relaunch(["-HornDebugStart", "tdf", "-HornDebugMonth", "5", "-HornTickSeconds", "1"])
        sail(until: "Round Cape Horn")
        shot("35-fork")
        tap("Take the Strait of Magellan")
        shot("36-pilot")
    }
}

extension ScreenshotUITests {
    func testChartAndFishing() {
        relaunch(["-HornDebugStart", "callao", "-HornTickSeconds", "30"])
        tap("Look at the chart")
        shot("40-chart")
        tap("Back")
        tap("Go fishing")
        let water = app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH 'The sea below'")).firstMatch
        XCTAssertTrue(water.waitForExistence(timeout: 5))
        for dy in [0.4, 0.6, 0.8] {
            water.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: dy)).tap()
            usleep(300_000)
        }
        shot("41-fishing")
        tap("Back to the ship")
        XCTAssertTrue(app.buttons["Continue"].waitForExistence(timeout: 5), "Back to the ship didn't land")
        shot("42-catch")
    }
}

extension ScreenshotUITests {
    func testFinale() {
        relaunch(["-HornDebugStart", "sf", "-HornTickSeconds", "1"])
        tap("Continue on your voyage")
        let again = app.buttons["Sail again"]
        for _ in 0..<20 where !again.exists {
            let next = app.buttons["Continue"]
            if next.waitForExistence(timeout: 2) { next.tap() }
        }
        XCTAssertTrue(again.waitForExistence(timeout: 10))
        shot("50-finale")
        app.swipeUp()
        shot("51-finale-bottom")
        tap("See the top ten")
        shot("52-top-ten")
        tap("Back")
        shot("53-thanks")
        tap("Sail again")
        XCTAssertTrue(app.buttons["Sail for California"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Continue the voyage'")).firstMatch.exists,
                       "no save survives the finale")
    }
}
