import XCTest

/// Walks Over the Pole from the picker to both endings, saving a PNG of each screen to
/// `$HORN_SHOTS` (see `ScreenshotWalk`).
final class AirshipScreenshotUITests: ScreenshotWalk {
    static let airship = ["-journey", "airship"]
    override class var journeyArgs: [String] { airship }

    /// What the flight may ask on the way to somewhere else, and the answer that costs
    /// least: fly on, decline, climb out of the murk. Not the masts or the Circle, which
    /// a walk may be rolling toward.
    static let patience = [
        "Continue", "Continue the flight", "Fly on", "Put them off at Pulham",
        "Climb out of it and wait for a clear patch", "Decline", "Say a few words",
        "Fly by your own eyes", "Accept the trade",
    ]
    /// And on the way past them.
    static let passing = patience + ["Fly on without stopping", "No time for speeches"]

    var next: XCUIElement { app.buttons.matching(NSPredicate(format: "label IN %@", Self.patience)).firstMatch }
    var onward: XCUIElement { app.buttons.matching(NSPredicate(format: "label IN %@", Self.passing)).firstMatch }

    /// Answers whatever comes up until a button called `label` (or starting with it) is on screen.
    func roll(until label: String, tries: Int = 60) {
        let target = button(startingWith: label)
        for _ in 0..<tries where !target.exists {
            // Both can arrive on one screen ("Fly on" beside what is wanted): look again first.
            if next.waitForExistence(timeout: 2) && !target.exists { next.tap() }
        }
        XCTAssertTrue(target.waitForExistence(timeout: 10), "never reached \(label)")
    }

    /// Answers until the flight is under way with nothing on screen but the status.
    func settleAloft(_ tries: Int = 12) {
        let halt = app.buttons["Stop the engines & take stock"]
        // Screens are swapped whole, so the button is there exactly when nothing is asked.
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
        button(startingWith: "Over the Pole").tap()
        tap("Learn about the flight")
        shot("02-learn")
        tap("Next")
        shot("02-learn-2")
        tap("Next")
        shot("02-learn-3")
        tap("Back to the start")
        tap("Fly for the Pole")
        shot("03-role")
        tap("What does each one bring?")
        shot("04-differences")
        tap("Back")
        tap("A New York financier")
        shot("05-names")
        tap("Use these names")
        shot("06-month")
        tap("Ask for advice")
        shot("07-advice")
        tap("Continue")
        tap("May 1926")
        shot("08-outfit")
    }

    func testTheStoresAndTheFlight() {
        relaunch(["-HornTickSeconds", "6"])
        tap("Fly for the Pole")
        tap("A meteorologist trained at Bergen")
        tap("Use these names")
        tap("May 1926")
        tap("Enter the stores")
        shot("10-shop-empty")
        for _ in 0..<8 { app.buttons["More Provisions"].tap() }
        for _ in 0..<6 { app.buttons["More Drinking water"].tap() }
        for _ in 0..<4 { app.buttons["More Coffee & cocoa"].tap() }
        for _ in 0..<5 { app.buttons["More Fur flying suits"].tap() }
        shot("11-shop")
        app.swipeUp()
        app.swipeUp()
        for _ in 0..<2 { app.buttons["More Engine spares"].tap() }
        for _ in 0..<3 { app.buttons["More Water ballast"].tap() }
        for _ in 0..<6 { app.buttons["More Pilot balloons"].tap() }
        // No petrol yet: Rome won't let her go.
        button(startingWith: "Pay $").tap()
        shot("12-no-petrol")
        tap("Continue")
        app.swipeUp()
        app.swipeUp()
        for _ in 0..<30 { app.buttons["More Petrol"].tap() }
        shot("13-shop-petrol")
        let pay = button(startingWith: "Pay $")
        XCTAssertTrue(pay.waitForExistence(timeout: 5))
        pay.tap()
        shot("14-depart")
        tap("Head north")
        let halt = app.buttons["Stop the engines & take stock"]
        XCTAssertTrue(halt.waitForExistence(timeout: 5))
        shot("15-aloft")
        settleAloft()
        halt.tap()
        shot("16-menu")
        tap("Check supplies & crew")
        shot("17-supplies")
        app.swipeUp()
        shot("17-supplies-bottom")
        tap("Back")
        button(startingWith: "Change speed").tap()
        shot("18-speed")
        button(startingWith: "Cruising").tap()
        button(startingWith: "Change rations").tap()
        shot("19-rations")
        button(startingWith: "Short rations").tap()
        tap("Stop the engines and rest")
        shot("20-rest")
        tap("Never mind")
        tap("Make repairs aloft")
        shot("21-repairs")
    }

    /// The country and the weather: five places in four months, and the gallery.
    func testTheCountry() {
        for (stop, month, name) in [("rhone", "4", "25-france-may"), ("circle", "3", "26-scandinavia-april"),
                                    ("bear", "6", "27-barents-july"), ("kingsbay", "4", "28-polar-sea-may"),
                                    ("barrow", "5", "29-alaska-june")] {
            relaunch(["-HornDebugStart", stop, "-HornDebugMonth", month, "-HornTickSeconds", "4"])
            tap("Continue the flight")
            // The first watch reaches the stop and says so; the shot is of the country
            // after it, with the weather that watch rolled.
            sleep(5)
            settleAloft()
            sleep(5)
            settleAloft()
            shot(name)
        }
        relaunch(["-HornSceneGallery", "YES"])
        shot("30-gallery")
        for i in 2...5 {
            app.swipeUp()
            shot("30-gallery-\(i)")
        }
    }

    func testTheMast() {
        relaunch(["-HornDebugStart", "oslo", "-HornTickSeconds", "1"])
        tap("Continue the flight")
        roll(until: "Moor at the mast and go ashore")
        shot("31-arrival")
        tap("Moor at the mast and go ashore")
        shot("32-mast-menu")
        tap("Talk to people")
        shot("33-talk")
        tap("Continue")
        tap("Visit the gas plant and the mechanics")
        shot("34-gas-plant")
        tap("Back to the mast")
        tap("Rest at the mast")
        shot("35-rest-at-the-mast")
        tap("Never mind")
        tap("Buy supplies")
        shot("36-mast-stores")
    }

    func testTheCircleThePoleAndBarrow() {
        relaunch(["-HornDebugStart", "circle", "-HornTickSeconds", "1"])
        tap("Continue the flight")
        roll(until: "Hold a celebration")
        shot("37-circle")

        relaunch(["-HornDebugStart", "pole", "-HornTickSeconds", "4"])
        tap("Continue the flight")
        roll(until: "Climb above the fog")
        shot("38-pole")
        tap("Ask the navigator's advice")
        shot("39-navigator")
        tap("Continue")
        tap("Stay low, under the fog")
        shot("40-forecasts")
        button(startingWith: "Pay for the forecasts").tap()
        tap("Continue")
        // Answered under way, the flight goes on from the Pole.
        shot("41-at-the-pole")
        sleep(5)
        settleAloft()
        shot("42-under-the-fog")

        relaunch(["-HornDebugStart", "barrow", "-HornTickSeconds", "1"])
        tap("Continue the flight")
        roll(until: "Come down and take on supplies")
        shot("43-barrow")
        button(startingWith: "Come down and take on supplies").tap()
        shot("44-barrow-supplies")
        relaunch(["-HornDebugStart", "barrow", "-HornDebugAtStop", "YES", "-HornTickSeconds", "30"])
        shot("45-barrow-menu")
    }

    func testTheChartAndTheWinds() {
        relaunch(["-HornDebugStart", "kingsbay", "-HornTickSeconds", "30"])
        tap("Look at the chart")
        shot("46-chart")
        tap("Back")
        tap("Send up pilot balloons")
        let sky = app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH 'The sky above the control car'")).firstMatch
        XCTAssertTrue(sky.waitForExistence(timeout: 5))
        shot("47-winds")
        for dy in [0.4, 0.25, 0.55, 0.15, 0.35] {
            sky.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: dy)).tap()
            usleep(350_000)
        }
        sky.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.2)).tap()
        usleep(200_000)
        shot("48-winds-balloon", settle: false)
        tap("Back to the chart table")
        XCTAssertTrue(app.buttons["Continue"].waitForExistence(timeout: 5), "Back to the chart table didn't land")
        shot("49-found")
        relaunch(["-HornDebugStart", "wales", "-HornTickSeconds", "30"])
        tap("Look at the chart")
        shot("46-chart-alaska")
    }

    func testArrival() {
        relaunch(["-HornDebugStart", "nome", "-HornTickSeconds", "1"])
        tap("Continue the flight")
        roll(until: "Fly again")
        shot("50-arrival")
        app.swipeUp()
        shot("51-arrival-bottom")
        tap("See the top ten")
        shot("52-top-ten")
        tap("Back")
        shot("53-thanks")
        tap("Fly again")
        XCTAssertTrue(app.buttons["Fly for the Pole"].waitForExistence(timeout: 5))
        XCTAssertFalse(button(startingWith: "Continue the flight of").exists, "no save survives the arrival")
    }

    /// The other ending: out of gas over the Barents Sea.
    func testForcedDown() {
        relaunch(["-HornDebugStart", "bear", "-HornDebugHull", "0.2", "-HornTickSeconds", "2"])
        shot("54-heavy")
        tap("Continue the flight")
        roll(until: "Try again")
        shot("55-forced-down")
        tap("Try again")
        XCTAssertTrue(app.buttons["Fly for the Pole"].waitForExistence(timeout: 5))
        XCTAssertFalse(button(startingWith: "Continue the flight of").exists, "no save survives a forced landing")
    }

    /// Accessibility text sizes: the longer labels still fit.
    func testLargeText() {
        relaunch(["-HornDebugStart", "oslo", "-HornTickSeconds", "30",
                  "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
        shot("70-large-menu")
        tap("Check supplies & crew")
        shot("71-large-supplies")
    }
}
