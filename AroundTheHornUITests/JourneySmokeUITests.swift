import XCTest

/// Every journey in a normal UI run. The screenshot walks need HORN_SHOTS and are skipped
/// without it, so this is what launches the journeys other than 1849 there: each opens on
/// its own title card by `-journey <id>`, its first button leads into its setup, and its
/// picker lists all six.
final class JourneySmokeUITests: XCTestCase {
    static let journeys: [(id: String, title: String, start: String)] = [
        ("horn1849", "Around the Horn", "Sail for California"),
        ("rail", "The Iron Road", "Take the contract"),
        ("airship", "Over the Pole", "Fly for the Pole"),
        ("balloon", "The Jet Stream", "Fly round the world"),
        ("mars", "The Long Transfer", "Take the charter"),
        ("klondike", "To the Klondike", "Head for the Klondike"),
    ]

    func button(_ app: XCUIApplication, startingWith prefix: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", prefix)).firstMatch
    }

    func testEveryJourneyOpensOnItsOwnTitleCardAndThePickerListsAllSix() {
        for j in Self.journeys {
            let app = XCUIApplication(bundleIdentifier: LaunchUITests.appBundleID)
            app.launchArguments = ["-journey", j.id]
            app.launch()
            let title = app.descendants(matching: .any)["title"]
            XCTAssertTrue(title.waitForExistence(timeout: 10), "\(j.id): no title card")
            XCTAssertEqual(title.label, j.title, j.id)

            let picker = app.buttons["Choose another journey"]
            XCTAssertTrue(picker.waitForExistence(timeout: 5), "\(j.id): no way to the picker")
            picker.tap()
            XCTAssertTrue(app.staticTexts["Choose a journey"].waitForExistence(timeout: 5), "\(j.id): no picker")
            for other in Self.journeys {
                XCTAssertTrue(button(app, startingWith: other.title).exists, "\(j.id)'s picker lacks \(other.title)")
            }
            button(app, startingWith: j.title).tap()

            let start = app.buttons[j.start]
            XCTAssertTrue(start.waitForExistence(timeout: 5), "\(j.id): no \"\(j.start)\"")
            start.tap()
            XCTAssertTrue(app.staticTexts["Who are you?"].waitForExistence(timeout: 5), "\(j.id): the setup did not open")
            app.terminate()
        }
    }
}
