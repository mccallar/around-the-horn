import XCTest

/// What a screenshot walk needs: a folder to write to, the app launched on one journey,
/// and a way to tap by label. A walk saves a PNG of each screen to `$HORN_SHOTS` (passed
/// to the runner as SIMCTL_CHILD_HORN_SHOTS) and is skipped without it, so the normal UI
/// suite runs none of them.
///
/// This is how screens get looked at here: `simctl io screenshot` returns a blank image
/// in the sandbox, while XCUIScreen captures what is really drawn.
class ScreenshotWalk: XCTestCase {
    var dir: URL!
    var app: XCUIApplication!

    /// The journey whose screens these are: every launch names it.
    class var journeyArgs: [String] { LaunchUITests.horn }

    override func setUpWithError() throws {
        guard let d = ProcessInfo.processInfo.environment["HORN_SHOTS"] else { throw XCTSkip("HORN_SHOTS not set") }
        dir = URL(fileURLWithPath: d)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        continueAfterFailure = false
        app = XCUIApplication(bundleIdentifier: LaunchUITests.appBundleID)
        let extra = ProcessInfo.processInfo.environment["HORN_ARGS"]?.split(separator: " ").map(String.init) ?? []
        app.launchArguments = journey(extra)
        app.launch()
    }

    /// The arguments with the walk's journey named, unless they already name one.
    func journey(_ args: [String]) -> [String] {
        args.contains("-journey") ? args : Self.journeyArgs + args
    }

    func relaunch(_ args: [String]) {
        app.terminate()
        app.launchArguments = journey(args)
        app.launch()
    }

    /// `settle: false` catches something in flight; otherwise the screen is given a second to stop moving.
    func shot(_ name: String, settle: Bool = true) {
        if settle { sleep(1) }
        let png = XCUIScreen.main.screenshot().pngRepresentation
        try? png.write(to: dir.appendingPathComponent("\(name).png"))
    }

    func tap(_ label: String) {
        let b = app.buttons[label]
        XCTAssertTrue(b.waitForExistence(timeout: 10), "no button \(label)")
        b.tap()
    }

    func button(startingWith prefix: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", prefix)).firstMatch
    }
}
