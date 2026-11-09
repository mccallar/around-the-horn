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
