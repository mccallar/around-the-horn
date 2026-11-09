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
}
