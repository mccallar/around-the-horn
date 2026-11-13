import XCTest

/// Spec "definition of done": save/resume works after force-quitting mid-voyage.
final class ResumeUITests: XCTestCase {
    func testForceQuitMidVoyageThenContinue() {
        let app = XCUIApplication(bundleIdentifier: LaunchUITests.appBundleID)
        app.launchArguments = LaunchUITests.horn + ["-HornDebugStart", "valp", "-HornTickSeconds", "30"]
        app.launch()
        XCTAssertTrue(app.buttons["Continue on your voyage"].waitForExistence(timeout: 10))
        app.terminate()  // what a force quit does: no chance to save on the way out

        app.launchArguments = LaunchUITests.horn
        app.launch()
        let resume = app.buttons["Continue the voyage of the Resolute"]
        XCTAssertTrue(resume.waitForExistence(timeout: 10), "the title offers the saved voyage")
        resume.tap()
        XCTAssertTrue(app.buttons["Continue on your voyage"].waitForExistence(timeout: 5), "back on the sea menu")
        XCTAssertTrue(app.staticTexts["8,890 of 14,000 nm"].exists, "at the same place")
    }
}
