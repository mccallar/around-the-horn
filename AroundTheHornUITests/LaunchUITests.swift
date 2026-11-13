import XCTest

final class LaunchUITests: XCTestCase {
    /// By bundle identifier, not `XCUIApplication()`: the no-argument form reads its
    /// target from a test configuration that `xcodebuild test` writes and
    /// `Tools/run_tests.sh` (which spawns the runner directly) does not.
    static let appBundleID = "com.mccallatech.AroundTheHorn"

    func testLaunchShowsTitle() {
        let app = XCUIApplication(bundleIdentifier: Self.appBundleID)
        app.launch()
        XCTAssertTrue(app.descendants(matching: .any)["title"].waitForExistence(timeout: 10))
    }

    /// `-journey <id>` goes straight to that journey's title card; an id nobody knows is
    /// ignored, and the app opens as it would without it.
    func testTheJourneyArgumentOpensThatTitleCard() {
        for id in ["horn1849", "no-such-journey"] {
            let app = XCUIApplication(bundleIdentifier: Self.appBundleID)
            app.launchArguments = ["-journey", id]
            app.launch()
            XCTAssertTrue(app.descendants(matching: .any)["title"].waitForExistence(timeout: 10), id)
            app.terminate()
        }
    }
}
