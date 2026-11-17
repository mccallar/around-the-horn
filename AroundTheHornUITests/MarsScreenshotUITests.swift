import XCTest

/// Walks The Long Transfer from the picker to both endings, saving a PNG of each screen to
/// `$HORN_SHOTS` (see `ScreenshotWalk`).
final class MarsScreenshotUITests: ScreenshotWalk {
    static let mars = ["-journey", "mars"]
    override class var journeyArgs: [String] { mars }

    /// What the transfer may ask on the way to somewhere else, and the answer that costs
    /// least: keep going, shelter, leave it, say sorry, wave it away, note it. Not the
    /// stations or the set pieces, which a walk may be rolling toward.
    static let patience = [
        "Continue", "Continue the transfer", "Shelter in the core for a day", "Leave it", "Say you're sorry, and mean it",
        "Wave it away", "Note it in the log", "Say a few words", "Decline", "Accept the trade",
    ]
    /// And on the way past them.
    static let passing = patience + ["Keep going", "Wave as she goes by", "Turn on schedule", "Propulsive capture (10 tonnes)"]

    static func answers(_ list: [String]) -> NSPredicate {
        NSPredicate(format: "label IN %@ OR label ENDSWITH 'back with the shuttle'", list)
    }

    var next: XCUIElement { app.buttons.matching(Self.answers(Self.patience)).firstMatch }
    var onward: XCUIElement { app.buttons.matching(Self.answers(Self.passing)).firstMatch }

    /// Answers whatever comes up until a button called `label` (or starting with it) is on screen.
    func roll(until label: String, tries: Int = 80) {
        let target = button(startingWith: label)
        for _ in 0..<tries where !target.exists {
            if next.waitForExistence(timeout: 2) && !target.exists { next.tap() }
        }
        XCTAssertTrue(target.waitForExistence(timeout: 10), "never reached \(label)")
    }

    /// Answers until she is under way with nothing on screen but the status.
    func settle(_ tries: Int = 12) {
        let halt = app.buttons["Cut the drive & take stock"]
        for _ in 0..<tries {
            if halt.exists && !onward.exists { return }
            if onward.waitForExistence(timeout: 6) { onward.tap() }
        }
        XCTFail("never settled under way")
    }

    func testAPickerAndSetup() {
        shot("01-title")
        tap("Choose another journey")
        XCTAssertTrue(app.staticTexts["Choose a journey"].waitForExistence(timeout: 5))
        shot("00-picker")
        button(startingWith: "The Long Transfer").tap()
        tap("Learn about the transfer")
        shot("02-learn")
        tap("Next")
        shot("02-learn-2")
        app.swipeUp()
        shot("02-learn-2-bottom")
        tap("Next")
        shot("02-learn-3")
        tap("Back to the start")
        tap("Take the charter")
        shot("03-role")
        tap("Weigh them up")
        shot("04-differences")
        tap("Back")
        tap("A charter captain backed by a freight consortium")
        shot("05-names")
        tap("Use these names")
        shot("06-month")
        tap("Ask for advice")
        shot("07-advice")
        tap("Continue")
        tap("October 2087")
        shot("08-outfit")
    }

    func testTheChandleryAndTheArc() {
        relaunch(["-HornTickSeconds", "6"])
        tap("Take the charter")
        tap("An ice hauler off the lunar tugs")
        tap("Use these names")
        tap("October 2087")
        tap("Enter the chandlery")
        shot("10-shop-empty")
        for _ in 0..<12 { app.buttons["More Rations"].tap() }
        for _ in 0..<8 { app.buttons["More Water"].tap() }
        app.swipeUp()
        for _ in 0..<3 { app.buttons["More Supplement packs"].tap() }
        for _ in 0..<5 { app.buttons["More Thermal suits"].tap() }
        for _ in 0..<2 { app.buttons["More Array panels"].tap() }
        for _ in 0..<2 { app.buttons["More Hull patches"].tap() }
        for _ in 0..<4 { app.buttons["More Tether cartridges"].tap() }
        shot("11-shop")
        // No propellant yet: Gateway won't clear her.
        button(startingWith: "Pay $").tap()
        shot("12-no-propellant")
        // Paying saved the transfer: quit now and it comes back to the chandlery.
        relaunch(["-HornTickSeconds", "6"])
        let resume = button(startingWith: "Rejoin the")
        XCTAssertTrue(resume.waitForExistence(timeout: 10))
        shot("12-title-resume")
        resume.tap()
        XCTAssertTrue(app.buttons["More Propellant"].waitForExistence(timeout: 10), "not back in the chandlery")
        for _ in 0..<14 { app.buttons["More Propellant"].tap() }
        shot("13-shop-propellant")
        let pay = button(startingWith: "Pay $")
        XCTAssertTrue(pay.waitForExistence(timeout: 5))
        pay.tap()
        shot("14-depart")
        tap("Burn for Mars")
        let halt = app.buttons["Cut the drive & take stock"]
        XCTAssertTrue(halt.waitForExistence(timeout: 5))
        shot("15-under-way")
        settle()
        halt.tap()
        shot("16-menu")
        tap("Check supplies & crew")
        shot("17-supplies")
        app.swipeUp()
        shot("17-supplies-bottom")
        tap("Back")
        button(startingWith: "Change thrust").tap()
        shot("18-thrust")
        button(startingWith: "Hard burn").tap()
        button(startingWith: "Change rations").tap()
        shot("19-rations")
        button(startingWith: "Lean").tap()
        tap("Idle the drive and rest")
        shot("20-rest")
        tap("Never mind")
        tap("Make repairs")
        shot("21-repairs")
    }

    /// The arc and its weather: six places in four months, and the gallery.
    func testTheArc() {
        for (stop, month, name) in [("hill", "9", "25-departure-october"), ("cycler", "7", "26-inner-arc-august"),
                                    ("midway", "11", "27-deep-space-december"), ("shadow", "10", "28-shadow-november"),
                                    ("approach", "11", "29-approach-december"), ("phobos", "8", "30-capture-september")] {
            relaunch(["-HornDebugStart", stop, "-HornDebugMonth", month, "-HornTickSeconds", "4"])
            tap("Continue the transfer")
            // The first day reaches the stop and says so; the shot is of the arc after it,
            // with the weather that day rolled.
            sleep(5)
            settle()
            sleep(5)
            settle()
            shot(name)
        }
        relaunch(["-HornSceneGallery", "YES"])
        shot("31-gallery")
        for i in 2...9 {
            app.swipeUp()
            shot("31-gallery-\(i)")
        }
    }

    func testAStation() {
        relaunch(["-HornDebugStart", "midway", "-HornTickSeconds", "1"])
        tap("Continue the transfer")
        roll(until: "Dock and go aboard")
        shot("32-arrival")
        tap("Dock and go aboard")
        shot("33-station-menu")
        tap("Talk to people")
        shot("34-talk")
        tap("Continue")
        tap("Visit the yard crew")
        shot("35-yard")
        tap("Back to the station")
        tap("Buy supplies")
        shot("36-station-stores")
    }

    func testTheSetPieces() {
        relaunch(["-HornDebugStart", "cycler", "-HornTickSeconds", "1"])
        tap("Continue the transfer")
        roll(until: "Match and dock")
        shot("37-cycler")
        button(startingWith: "Match and dock").tap()
        shot("38-cycler-docked")
        tap("Continue")
        shot("38-cycler-menu")

        relaunch(["-HornDebugStart", "turnover", "-HornTickSeconds", "4"])
        tap("Continue the transfer")
        roll(until: "Turn on schedule")
        shot("39-turnover")
        button(startingWith: "Run on four more days").tap()
        shot("40-ran-on")

        relaunch(["-HornDebugStart", "approach", "-HornTickSeconds", "4"])
        tap("Continue the transfer")
        roll(until: "Aerobrake")
        shot("41-approach")
        tap("Aerobrake")
        shot("42-aerobrake")
        tap("Continue")
        sleep(5)
        settle()
        shot("43-aerobraking")
    }

    func testThePlotAndTheGrapple() {
        relaunch(["-HornDebugStart", "midway", "-HornTickSeconds", "30"])
        tap("Look at the plot")
        shot("44-plot")
        relaunch(["-HornDebugStart", "hill", "-HornTickSeconds", "30"])
        tap("Look at the plot")
        shot("44-plot-start")
        relaunch(["-HornDebugStart", "shadow", "-HornTickSeconds", "30"])
        tap("Work the grapple")
        let sky = app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH 'The ice stream beyond the truss'")).firstMatch
        XCTAssertTrue(sky.waitForExistence(timeout: 5))
        shot("45-grapple")
        for dy in [0.2, 0.42, 0.64, 0.3, 0.5] {
            sky.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: dy)).tap()
            usleep(350_000)
        }
        sky.coordinate(withNormalizedOffset: CGVector(dx: 0.35, dy: 0.42)).tap()
        usleep(200_000)
        shot("46-grapple-fired", settle: false)
        tap("Back inside")
        XCTAssertTrue(app.buttons["Continue"].waitForExistence(timeout: 5), "Back inside didn't land")
        shot("47-caught")
        // Out of the streams there is nothing to catch.
        relaunch(["-HornDebugStart", "midway", "-HornTickSeconds", "30"])
        tap("Work the grapple")
        shot("48-nothing-to-catch")
    }

    /// The array dark and the tanks dry.
    func testTrouble() {
        relaunch(["-HornDebugStart", "midway", "-HornDebugSails", "0", "-HornTickSeconds", "1"])
        tap("Continue the transfer")
        let rewire = button(startingWith: "Rewire what is left of the wings")
        XCTAssertTrue(rewire.waitForExistence(timeout: 10))
        shot("50-array-dark")
        rewire.tap()
        shot("51-rewire")
        // The two days' messages, then under way on ten points of power. (They last a few
        // days out here, and then the question comes back.)
        let halt = app.buttons["Cut the drive & take stock"], go = app.buttons["Continue"]
        for _ in 0..<8 where !halt.exists {
            if go.waitForExistence(timeout: 2) { go.tap() }
        }
        XCTAssertTrue(halt.waitForExistence(timeout: 5), "not under way after the rewire")
        shot("52-rewired", settle: false)
        relaunch(["-HornDebugStart", "shadow", "-HornDebugFuel", "0", "-HornTickSeconds", "30"])
        shot("53-tanks-dry")
        relaunch(["-HornDebugStart", "shadow", "-HornDebugFuel", "0", "-HornTickSeconds", "3"])
        tap("Continue the transfer")
        sleep(4)
        settle()
        shot("54-tumbling")
    }

    func testJezero() {
        relaunch(["-HornDebugStart", "jezero", "-HornTickSeconds", "1"])
        tap("Continue the transfer")
        roll(until: "Take another charter")
        shot("60-jezero")
        app.swipeUp()
        shot("61-jezero-bottom")
        tap("See the top ten")
        shot("62-top-ten")
        tap("Back")
        tap("Take another charter")
        XCTAssertTrue(app.buttons["Take the charter"].waitForExistence(timeout: 5))
        XCTAssertFalse(button(startingWith: "Rejoin the").exists, "no save survives the delivery")
    }

    /// The other ending: the hull lets go.
    func testTheHullLetsGo() {
        relaunch(["-HornDebugStart", "turnover", "-HornDebugHull", "0.3", "-HornTickSeconds", "2"])
        shot("63-hull-at-nothing")
        tap("Continue the transfer")
        let over = app.buttons["Try again"]
        for _ in 0..<20 where !over.exists {
            if onward.waitForExistence(timeout: 2) && !over.exists { onward.tap() }
        }
        XCTAssertTrue(over.waitForExistence(timeout: 10), "the hull never let go")
        shot("64-hull-lets-go")
        tap("Try again")
        XCTAssertTrue(app.buttons["Take the charter"].waitForExistence(timeout: 5))
        XCTAssertFalse(button(startingWith: "Rejoin the").exists, "no save survives losing the ship")
    }
}
