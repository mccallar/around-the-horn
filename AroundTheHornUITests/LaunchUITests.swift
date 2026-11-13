import XCTest

final class LaunchUITests: XCTestCase {
    /// By bundle identifier, not `XCUIApplication()`: the no-argument form reads its
    /// target from a test configuration that `xcodebuild test` writes and
    /// `Tools/run_tests.sh` (which spawns the runner directly) does not.
    static let appBundleID = "com.mccallatech.AroundTheHorn"

    /// Every UI test names its journey. Without it a launch lands wherever the app
    /// happens to open: the picker once there is more than one journey, or whichever
    /// journey was chosen last on this simulator.
    static let horn = ["-journey", "horn1849"]

    func title(_ app: XCUIApplication) -> XCUIElement { app.descendants(matching: .any)["title"] }

    /// Where a launch that names no journey may land: a title card, or the list of
    /// journeys when there are several and none was chosen last.
    func opensOnATitleCardOrThePicker(_ app: XCUIApplication, _ what: String) {
        let picker = app.staticTexts["Choose a journey"]
        let deadline = Date().addingTimeInterval(10)
        while Date() < deadline {
            if title(app).exists || picker.exists { return }
            usleep(200_000)
        }
        XCTFail("\(what): neither a title card nor the picker")
    }

    func testLaunchShowsTitle() {
        let app = XCUIApplication(bundleIdentifier: Self.appBundleID)
        app.launchArguments = Self.horn
        app.launch()
        XCTAssertTrue(title(app).waitForExistence(timeout: 10))
    }

    func testAPlainLaunchOpensOnATitleCardOrThePicker() {
        let app = XCUIApplication(bundleIdentifier: Self.appBundleID)
        app.launchArguments = []
        app.launch()
        opensOnATitleCardOrThePicker(app, "no arguments")
    }

    /// `-journey <id>` goes straight to that journey's title card. An id nobody knows is
    /// ignored: the app opens as it would without the argument.
    func testTheJourneyArgumentOpensThatTitleCard() {
        let app = XCUIApplication(bundleIdentifier: Self.appBundleID)
        app.launchArguments = Self.horn
        app.launch()
        XCTAssertTrue(title(app).waitForExistence(timeout: 10), "horn1849")
        app.terminate()

        let stray = XCUIApplication(bundleIdentifier: Self.appBundleID)
        stray.launchArguments = ["-journey", "no-such-journey"]
        stray.launch()
        opensOnATitleCardOrThePicker(stray, "an unknown journey")
        stray.terminate()
    }
}
