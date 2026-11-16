import XCTest

/// Walks The Jet Stream from the picker to both endings, saving a PNG of each screen to
/// `$HORN_SHOTS` (see `ScreenshotWalk`).
final class BalloonScreenshotUITests: ScreenshotWalk {
    static let balloon = ["-journey", "balloon"]
    override class var journeyArgs: [String] { balloon }

    /// What the flight may ask on the way to somewhere else, and the answer that costs
    /// least: wave, keep the bear, go round, climb out of the ice, fly on. Not the fields
    /// or the set pieces, which a walk may be rolling toward.
    static let patience = [
        "Continue", "Continue the flight", "Wave and fly on", "Keep the bear", "Descend and go around (lose a watch)",
        "Climb above the cloud to melt it (40 gal)", "Ride it out", "Wave them off", "Decline", "Carry them home",
        "Say goodbye", "Accept the trade",
    ]
    /// And on the way past them.
    static let passing = patience + ["Fly on without landing", "Stay south of the range", "Ride the northern track",
                                     "Keep to the watch schedule", "Fly on", "Trust your own eyes"]

    var next: XCUIElement { app.buttons.matching(NSPredicate(format: "label IN %@", Self.patience)).firstMatch }
    var onward: XCUIElement { app.buttons.matching(NSPredicate(format: "label IN %@", Self.passing)).firstMatch }

    /// Answers whatever comes up until a button called `label` (or starting with it) is on screen.
    func roll(until label: String, tries: Int = 80) {
        let target = button(startingWith: label)
        for _ in 0..<tries where !target.exists {
            if next.waitForExistence(timeout: 2) && !target.exists { next.tap() }
        }
        XCTAssertTrue(target.waitForExistence(timeout: 10), "never reached \(label)")
    }

    /// Answers until the flight is under way with nothing on screen but the status.
    func settleAloft(_ tries: Int = 12) {
        let halt = app.buttons["Hold & take stock"]
        for _ in 0..<tries {
            if halt.exists && !onward.exists { return }
            if onward.waitForExistence(timeout: 6) { onward.tap() }
        }
        XCTFail("never settled aloft")
    }

    func testAPickerAndSetup() {
        shot("01-title")
        tap("Choose another journey")
        XCTAssertTrue(app.staticTexts["Choose a journey"].waitForExistence(timeout: 5))
        shot("00-picker")
        button(startingWith: "The Jet Stream").tap()
        tap("Learn about the flight")
        shot("02-learn")
        for i in 2...4 {
            tap("Next")
            shot("02-learn-\(i)")
        }
        tap("Back to the start")
        tap("Fly round the world")
        shot("03-role")
        tap("Compare the three")
        shot("04-compare")
        tap("Back")
        tap("A Zurich chocolate maker")
        shot("05-names")
        tap("Use these names")
        shot("06-month")
        tap("Ask for advice")
        shot("07-advice")
        tap("Continue")
        tap("January 1999")
        shot("08-outfit")
    }

    func testTheHangarAndTheFlight() {
        relaunch(["-HornTickSeconds", "6"])
        tap("Fly round the world")
        tap("An Alaska bush pilot")
        tap("Use these names")
        tap("January 1999")
        tap("Enter the supply hangar")
        shot("10-shop-empty")
        for _ in 0..<10 { app.buttons["More Rations"].tap() }
        for _ in 0..<8 { app.buttons["More Drinking water"].tap() }
        for _ in 0..<6 { app.buttons["More CO2 scrubbers"].tap() }
        for _ in 0..<5 { app.buttons["More Down suits"].tap() }
        shot("11-shop")
        app.swipeUp()
        app.swipeUp()
        for _ in 0..<3 { app.buttons["More Ballast"].tap() }
        for _ in 0..<2 { app.buttons["More Burner spares"].tap() }
        for _ in 0..<2 { app.buttons["More Fishing line"].tap() }
        // No propane yet: the launch director won't let her go.
        button(startingWith: "Pay $").tap()
        shot("12-no-propane")
        tap("Continue")
        XCTAssertTrue(app.buttons["More Propane"].waitForExistence(timeout: 10), "not back in the hangar")
        app.swipeUp()
        app.swipeUp()
        for _ in 0..<16 { app.buttons["More Propane"].tap() }
        shot("13-shop-propane")
        let pay = button(startingWith: "Pay $")
        XCTAssertTrue(pay.waitForExistence(timeout: 5))
        pay.tap()
        shot("14-launch")
        tap("Climb away")
        let halt = app.buttons["Hold & take stock"]
        XCTAssertTrue(halt.waitForExistence(timeout: 5))
        shot("15-aloft", settle: false)
        settleAloft()
        halt.tap()
        shot("16-menu")
        tap("Check supplies & crew")
        shot("17-supplies")
        app.swipeUp()
        shot("17-supplies-bottom")
        tap("Back")
        button(startingWith: "Change altitude").tap()
        shot("18-altitude")
        button(startingWith: "Middle air").tap()
        tap("Loiter low and rest")
        shot("19-rest")
        tap("Never mind")
        tap("Make repairs")
        shot("20-repairs")
    }

    /// The country and the weather: five places in three months, and the gallery.
    func testTheCountry() {
        for (stop, month, name) in [("jod", "10", "21-india-november"), ("him", "0", "22-himalaya-january"),
                                    ("dateline", "1", "23-north-pacific-february"), ("abq", "0", "24-plains-january"),
                                    ("azores", "2", "25-past-the-azores-march")] {
            relaunch(["-HornDebugStart", stop, "-HornDebugMonth", month, "-HornTickSeconds", "4"])
            tap("Continue the flight")
            // The first watch reaches the stop and asks; the shot is of the country after
            // it, with the weather that watch rolled.
            sleep(5)
            settleAloft()
            sleep(5)
            settleAloft()
            shot(name)
        }
        relaunch(["-HornSceneGallery", "YES"])
        shot("26-gallery")
        for i in 2...7 {
            app.swipeUp()
            shot("26-gallery-\(i)")
        }
    }

    func testTheField() {
        relaunch(["-HornDebugStart", "lux", "-HornTickSeconds", "1"])
        tap("Continue the flight")
        roll(until: "Land at the field")
        shot("30-arrival")
        tap("Land at the field")
        shot("31-field-menu")
        tap("Ask around the field")
        shot("32-talk")
        tap("Continue")
        tap("Visit the riggers")
        shot("33-riggers")
        tap("Back to the field")
        tap("Buy supplies")
        shot("34-field-shop")

        // Short of the climb's propane, with the money for it: go and buy it.
        relaunch(["-HornDebugStart", "saga", "-HornDebugFuel", "10", "-HornTickSeconds", "1"])
        tap("Continue the flight")
        roll(until: "Land at the field")
        tap("Land at the field")
        button(startingWith: "Relaunch").tap()
        shot("35-relaunch-refused")
    }

    func testTheSetPieces() {
        relaunch(["-HornDebugStart", "him", "-HornTickSeconds", "1"])
        tap("Continue the flight")
        roll(until: "Climb over the range into the jet")
        shot("40-himalaya")

        relaunch(["-HornDebugStart", "pacific", "-HornTickSeconds", "4"])
        tap("Continue the flight")
        roll(until: "Ride the northern track")
        shot("41-fork")
        tap("Ask Mission Control's advice")
        shot("42-advice")
        tap("Continue")
        tap("Take the southern track")
        shot("43-forecasters")
        button(startingWith: "Hire the forecasters").tap()
        tap("Continue")
        sleep(5)
        settleAloft()
        shot("44-southern-track")

        relaunch(["-HornDebugStart", "dateline", "-HornTickSeconds", "1"])
        tap("Continue the flight")
        roll(until: "Hold a party")
        shot("45-dateline")

        relaunch(["-HornDebugStart", "azores", "-HornTickSeconds", "1"])
        tap("Continue the flight")
        roll(until: "Drop down to meet her (2 watches)")
        shot("46-azores")
    }

    func testTheChartAndTheLine() {
        relaunch(["-HornDebugStart", "dateline", "-HornTickSeconds", "30"])
        tap("Look at the chart")
        shot("50-chart")
        tap("Back")
        tap("Trail a fishing line")
        let sea = app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH 'The sea below the capsule'")).firstMatch
        XCTAssertTrue(sea.waitForExistence(timeout: 5))
        shot("51-line")
        for dy in [0.4, 0.55, 0.3, 0.7, 0.45] {
            sea.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: dy)).tap()
            usleep(350_000)
        }
        sea.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.6)).tap()
        usleep(200_000)
        shot("52-line-cast", settle: false)
        tap("Back to the capsule")
        XCTAssertTrue(app.buttons["Continue"].waitForExistence(timeout: 5), "Back to the capsule didn't land")
        shot("53-caught")
        relaunch(["-HornDebugStart", "azores", "-HornTickSeconds", "30"])
        tap("Look at the chart")
        shot("50-chart-atlantic")
    }

    /// No heat, and going down: dry tanks over Arabia, then her lift gone over the North
    /// Pacific, the ballast cut away a sack at a time until there is none, and down in
    /// the sea.
    func testTrouble() {
        relaunch(["-HornDebugStart", "jod", "-HornDebugFuel", "0", "-HornTickSeconds", "30"])
        shot("60-tanks-dry")
        relaunch(["-HornDebugStart", "dateline", "-HornDebugHull", "0.2", "-HornDebugFuel", "0", "-HornTickSeconds", "1"])
        tap("Continue the flight")
        let sack = button(startingWith: "Cut away a sack of ballast")
        XCTAssertTrue(sack.waitForExistence(timeout: 10))
        shot("61-going-down")
        let over = app.buttons["Try again"]
        for _ in 0..<80 where !over.exists {
            if sack.exists && sack.isEnabled { sack.tap(); continue }
            if onward.waitForExistence(timeout: 2) && !over.exists { onward.tap() }
        }
        XCTAssertTrue(over.waitForExistence(timeout: 10), "never came down")
        shot("62-down-in-the-sea")
        tap("Try again")
        XCTAssertTrue(app.buttons["Fly round the world"].waitForExistence(timeout: 5))
        XCTAssertFalse(button(startingWith: "Continue the flight of").exists, "no save survives coming down")
    }

    func testTheFinishLine() {
        relaunch(["-HornDebugStart", "finish", "-HornTickSeconds", "1"])
        tap("Continue the flight")
        roll(until: "Fly again")
        shot("70-finish")
        app.swipeUp()
        shot("71-finish-bottom")
        tap("See the top ten")
        shot("72-top-ten")
        tap("Back")
        shot("73-thanks")
        tap("Fly again")
        XCTAssertTrue(app.buttons["Fly round the world"].waitForExistence(timeout: 5))
        XCTAssertFalse(button(startingWith: "Continue the flight of").exists, "no save survives the finish")
    }
}
