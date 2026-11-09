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
