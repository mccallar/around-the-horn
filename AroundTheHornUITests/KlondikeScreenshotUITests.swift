import XCTest

/// Walks To the Klondike from the picker to Dawson and to the ways it can end short of it,
/// saving a PNG of each screen to `$HORN_SHOTS` (see `ScreenshotWalk`).
final class KlondikeScreenshotUITests: ScreenshotWalk {
    static let klondike = ["-journey", "klondike"]
    override class var journeyArgs: [String] { klondike }
    /// The engine's var for the pass taken at Lynn Canal, and the White Pass's value.
    static let whitePass = ["-HornDebugVar", "klondike.route=2"]

    /// What the trail may ask on the way to somewhere else, and the answer that costs least:
    /// keep going, wait out the slope, go round the ice, stay with the boat, say no. Not the
    /// stops or the set pieces, which a walk may be rolling toward.
    static let patience = [
        "Continue", "Continue on your journey", "Keep going", "Wait in camp until it settles (2 days)",
        "Go round by the shore (lose a day)", "Stay with the boat", "Decline", "Lay them to rest",
    ]
    /// And on the way past them.
    static let passing = patience + ["Stay aboard", "Keep moving", "Float on past", "Carry on to the lakes",
                                     "Pack it all yourselves"]

    static func answers(_ list: [String]) -> NSPredicate {
        NSPredicate(format: "label IN %@ OR label BEGINSWITH 'Feed '", list)
    }

    var next: XCUIElement { app.buttons.matching(Self.answers(Self.patience)).firstMatch }
    var onward: XCUIElement { app.buttons.matching(Self.answers(Self.passing)).firstMatch }
    var halt: XCUIElement { app.buttons["Stop & take stock"] }

    /// Answers whatever comes up until a button called `label` (or starting with it) is on screen.
    func roll(until label: String, tries: Int = 80) {
        let target = button(startingWith: label)
        for _ in 0..<tries where !target.exists {
            if next.waitForExistence(timeout: 2) && !target.exists { next.tap() }
        }
        if !target.waitForExistence(timeout: 10) { shot("stuck-before-\(label)") }
        XCTAssertTrue(target.exists, "never reached \(label)")
    }

    /// Answers whatever comes up, passing what it passes, until words containing `text` are on screen.
    func roll(untilText text: String, tries: Int = 80) {
        let target = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
        for _ in 0..<tries where !target.exists {
            if onward.waitForExistence(timeout: 2) && !target.exists { onward.tap() }
        }
        if !target.waitForExistence(timeout: 10) { shot("stuck-before-\(text)") }
        XCTAssertTrue(target.exists, "never saw \(text)")
    }

    /// Answers until the party is under way with nothing on screen but the status.
    func settle(_ tries: Int = 12) {
        for _ in 0..<tries {
            if halt.exists && !onward.exists { return }
            if onward.waitForExistence(timeout: 6) { onward.tap() }
        }
        XCTFail("never settled under way")
    }

    /// From a debug start on the menu: under way, and the shot a day along, or at once for
    /// a stretch too short to stay in for a day (with the start's weather).
    func underWay(_ name: String, day: Bool = true) {
        tap("Continue on your journey")
        guard day else {
            sleep(1)
            shot(name, settle: false)
            return
        }
        sleep(5)
        settle()
        shot(name)
    }

    func testAPickerAndSetup() {
        shot("01-title")
        tap("Choose another journey")
        XCTAssertTrue(app.staticTexts["Choose a journey"].waitForExistence(timeout: 5))
        shot("00-picker")
        button(startingWith: "To the Klondike").tap()
        tap("Learn about the trail")
        shot("02-learn")
        tap("Next")
        shot("02-learn-2")
        app.swipeUp()
        shot("02-learn-2-bottom")
        tap("Next")
        shot("02-learn-3")
        app.swipeUp()
        shot("02-learn-3-bottom")
        tap("Back to the start")
        tap("Head for the Klondike")
        shot("03-role")
        tap("What does each one bring north?")
        shot("04-differences")
        tap("Back")
        tap("A Seattle storekeeper")
        shot("05-names")
        tap("Use these names")
        shot("06-month")
        tap("Ask for advice")
        shot("07-advice")
        tap("Continue")
        tap("March 1898")
        shot("08-outfit")
        app.swipeUp()
        shot("08-outfit-bottom")
    }

    func testTheShopAndTheSteamer() {
        relaunch(["-HornTickSeconds", "6"])
        tap("Head for the Klondike")
        tap("A Port Townsend boatbuilder")
        tap("Use these names")
        tap("March 1898")
        tap("Enter the shop")
        shot("10-shop-empty")
        for _ in 0..<12 { app.buttons["More Provisions"].tap() }
        for _ in 0..<6 { app.buttons["More Firewood"].tap() }
        for _ in 0..<8 { app.buttons["More Lime juice"].tap() }
        app.swipeUp()
        for _ in 0..<2 { app.buttons["More Medicine chest"].tap() }
        for _ in 0..<5 { app.buttons["More Furs & mackinaws"].tap() }
        for _ in 0..<4 { app.buttons["More Rope & rawhide"].tap() }
        for _ in 0..<5 { app.buttons["More Canvas & pitch"].tap() }
        for _ in 0..<3 { app.buttons["More Hooks & line"].tap() }
        shot("11-shop")
        // Half a year's grub: the outfitters say what the police will say.
        button(startingWith: "Pay $").tap()
        shot("12-short-of-grub")
        tap("Back to the shop")
        // Paying saved the trek: quit now and it comes back to the shop.
        relaunch(["-HornTickSeconds", "6"])
        let resume = button(startingWith: "Continue the journey of")
        XCTAssertTrue(resume.waitForExistence(timeout: 10))
        shot("12-title-resume")
        resume.tap()
        XCTAssertTrue(app.buttons["More Provisions"].waitForExistence(timeout: 10), "not back in the shop")
        for _ in 0..<14 { app.buttons["More Provisions"].tap() }
        shot("13-shop-provisions")
        let pay = button(startingWith: "Pay $")
        XCTAssertTrue(pay.waitForExistence(timeout: 5))
        pay.tap()
        shot("14-depart")
        tap("Steam north")
        XCTAssertTrue(halt.waitForExistence(timeout: 5))
        // A day out of Seattle.
        sleep(7)
        settle()
        shot("15-under-way")
        halt.tap()
        shot("16-menu")
        tap("Check supplies & party")
        shot("17-supplies")
        app.swipeUp()
        shot("17-supplies-bottom")
        tap("Back")
        button(startingWith: "Change pace").tap()
        shot("18-pace")
        button(startingWith: "Hard driving").tap()
        button(startingWith: "Change rations").tap()
        shot("19-rations")
        button(startingWith: "Short commons").tap()
        tap("Rest in your bunk")
        shot("20-rest")
        tap("Never mind")
        tap("Make repairs")
        shot("21-repairs")
    }

    /// D21: a miner who spends the purse below a step of grub ($25) with none aboard is
    /// warned and goes hungry, rather than sent back to the outfitter for good.
    func testLeavingHungry() {
        relaunch(["-HornTickSeconds", "30"])
        tap("Head for the Klondike")
        tap("A hard-rock miner out of Leadville")
        tap("Use these names")
        tap("March 1898")
        tap("Enter the shop")
        for _ in 0..<5 { app.buttons["More Firewood"].tap() }
        for _ in 0..<40 { app.buttons["More Lime juice"].tap() }
        app.swipeUp()
        for (item, n) in [("Medicine chest", 12), ("Furs & mackinaws", 12), ("Rope & rawhide", 20), ("Canvas & pitch", 10)] {
            for _ in 0..<n { app.buttons["More \(item)"].tap() }
        }
        shot("14a-spent")
        tap("Pay $718.00 and leave")
        XCTAssertTrue(app.buttons["Leave anyway"].waitForExistence(timeout: 5))
        shot("14b-no-grub")
        tap("Leave anyway")
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "you will go hungry")).firstMatch
            .waitForExistence(timeout: 5))
        shot("14c-leaving-hungry")
    }

    /// Every stretch of the way, in play: the coast by steamer, both passes on foot, the
    /// lakes and the river by boat.
    func testTheStretches() {
        for (stop, extra, day, name) in [
            ("juneau", ["-HornDebugMile", "500", "-HornDebugMonth", "1"], true, "25-inside-passage"),
            ("juneau", ["-HornDebugMile", "3300", "-HornDebugMonth", "2"], false, "26-queen-charlotte"),
            ("juneau", ["-HornDebugMile", "4500", "-HornDebugMonth", "3"], true, "27-bc-coast"),
            ("juneau", ["-HornDebugMile", "8000", "-HornDebugMonth", "4"], true, "28-alaska-coast"),
            ("camp", ["-HornDebugMonth", "2"], true, "29-taiya"),
            ("camp", ["-HornDebugMonth", "3"] + Self.whitePass, true, "30-skagway-valley"),
            ("lakes", ["-HornDebugMonth", "1"], true, "31-chilkoot-summit"),
            ("lakes", ["-HornDebugMonth", "2"] + Self.whitePass, true, "32-white-pass-summit"),
            ("bennett", ["-HornDebugMonth", "2"], true, "33-lindeman"),
            ("bennett", ["-HornDebugMonth", "3"] + Self.whitePass, true, "34-log-cabin"),
            ("tagish", [], true, "35-upper-lakes"),
            ("fivefinger", ["-HornDebugMile", "12550"], false, "36-fifty-mile"),
            ("fivefinger", ["-HornDebugMile", "12850"], false, "37-laberge"),
            ("selkirk", [], true, "38-yukon"),
        ] {
            relaunch(["-HornDebugStart", stop, "-HornTickSeconds", "4"] + extra)
            underWay(name, day: day)
        }
        relaunch(["-HornSceneGallery", "YES"])
        shot("39-gallery")
        for i in 2...14 {
            app.swipeUp()
            shot("39-gallery-\(i)")
        }
    }

    /// The towns: Juneau from the steamer, Sheep Camp on foot, Fort Selkirk from the boat.
    func testTheTowns() {
        relaunch(["-HornDebugStart", "juneau", "-HornTickSeconds", "1"])
        tap("Continue on your journey")
        roll(until: "Go ashore while the steamer takes on coal")
        shot("40-juneau-arrival")
        tap("Go ashore while the steamer takes on coal")
        shot("41-juneau")
        tap("Talk to people")
        shot("42-talk")
        tap("Continue")
        tap("Buy supplies")
        shot("43-juneau-stores")

        relaunch(["-HornDebugStart", "camp", "-HornTickSeconds", "1"])
        tap("Continue on your journey")
        roll(until: "Stop and make camp here")
        shot("44-sheep-camp-arrival")
        tap("Stop and make camp here")
        shot("45-sheep-camp")
        tap("Visit the outfitters' yard")
        shot("46-outfitters-yard")

        relaunch(["-HornDebugStart", "camp", "-HornTickSeconds", "1"] + Self.whitePass)
        tap("Continue on your journey")
        roll(until: "Stop and make camp here")
        tap("Stop and make camp here")
        shot("47-white-pass-city")

        relaunch(["-HornDebugStart", "selkirk", "-HornTickSeconds", "1"])
        tap("Continue on your journey")
        roll(until: "Tie up and go ashore")
        shot("48-selkirk-arrival")
        tap("Tie up and go ashore")
        shot("49-selkirk")
        tap("Visit the boatwrights")
        shot("50-boatwrights")
    }

    /// The fork, the landing, the summit's police, the lakes, Tagish and the water below it.
    func testTheWayStops() {
        relaunch(["-HornDebugStart", "lynn", "-HornTickSeconds", "1", "-HornDebugMonth", "3"])
        tap("Continue on your journey")
        roll(until: "Land at Dyea for the Chilkoot")
        shot("51-fork")
        tap("Ask the purser's advice")
        shot("52-purser")
        tap("Continue")
        tap("Land at Dyea for the Chilkoot")
        shot("53-packers")
        button(startingWith: "Hire the packers").tap()
        shot("54-packers-hired")

        relaunch(["-HornDebugStart", "landing", "-HornTickSeconds", "1"])
        tap("Continue on your journey")
        roll(until: "Stop and make camp here")
        shot("55-dyea")

        relaunch(["-HornDebugStart", "summit", "-HornTickSeconds", "1"])
        tap("Continue on your journey")
        roll(until: "Carry on to the lakes")
        shot("56-police")
        relaunch(["-HornDebugStart", "summit", "-HornTickSeconds", "1", "-HornDebugFood", "4200"])
        tap("Continue on your journey")
        roll(until: "Turn back for home")
        shot("57-police-short")
        relaunch(["-HornDebugStart", "summit", "-HornTickSeconds", "1"] + Self.whitePass)
        tap("Continue on your journey")
        roll(until: "Carry on to the lakes")
        shot("58-police-white-pass")

        relaunch(["-HornDebugStart", "lakes", "-HornTickSeconds", "1"])
        tap("Continue on your journey")
        roll(untilText: "drops out of the rocks")
        shot("59-lindeman")
        relaunch(["-HornDebugStart", "lakes", "-HornTickSeconds", "1"] + Self.whitePass)
        tap("Continue on your journey")
        roll(untilText: "At Log Cabin")
        shot("59-log-cabin")

        relaunch(["-HornDebugStart", "tagish", "-HornTickSeconds", "1"])
        tap("Continue on your journey")
        roll(untilText: "At the police post at Tagish")
        shot("60-tagish")
    }

    /// Lake Bennett: no boat, the boat question, and the ice.
    func testLakeBennett() {
        relaunch(["-HornDebugStart", "bennett", "-HornTickSeconds", "1"])
        tap("Continue on your journey")
        roll(until: "Make camp at the lakes")
        shot("61-bennett-arrival")
        tap("Make camp at the lakes")
        shot("62-bennett")
        tap("Push off and float on")
        shot("63-no-boat")
        tap("Continue")
        shot("64-boat-question")
        button(startingWith: "Buy a boat from the sawmill crew").tap()
        // The haggling takes a day, and the day may bring news of its own.
        roll(untilText: "The sawmill crew has a boat")
        shot("65-boat-bought")
        tap("Continue")
        // Still pushing off: now the ice.
        let wait = app.buttons["Wait in camp for the ice to go out"]
        if !wait.waitForExistence(timeout: 5) { tap("Push off and float on") }
        XCTAssertTrue(wait.waitForExistence(timeout: 10), "the ice never asked")
        shot("66-ice-in")
        wait.tap()
        roll(untilText: "the ice goes out with a long groan")
        shot("67-ice-out")
        tap("Continue")
        XCTAssertTrue(halt.waitForExistence(timeout: 10), "not under way once the ice went out")
    }

    func testTheRiver() {
        relaunch(["-HornDebugStart", "canyon", "-HornTickSeconds", "1"])
        tap("Continue on your journey")
        roll(until: "Hire a pilot to run her through")
        shot("69-canyon")
        tap("Ask the constable's advice")
        shot("70-constable")
        tap("Continue")
        button(startingWith: "Hire a pilot to run her through").tap()
        shot("71-piloted")

        relaunch(["-HornDebugStart", "fivefinger", "-HornTickSeconds", "1"])
        tap("Continue on your journey")
        roll(until: "Run the right-hand channel")
        shot("72-five-fingers")
        tap("Line her down along the bank (2 days)")
        roll(untilText: "Slow, wet and safe")
        shot("73-lined-down")
    }

    func testTheMapAndFishing() {
        relaunch(["-HornDebugStart", "juneau", "-HornTickSeconds", "30"])
        tap("Look at the map")
        shot("74-map-coast")
        relaunch(["-HornDebugStart", "camp", "-HornTickSeconds", "30"] + Self.whitePass)
        tap("Look at the map")
        shot("75-map-white-pass")
        relaunch(["-HornDebugStart", "summit", "-HornTickSeconds", "30"])
        tap("Look at the map")
        shot("76-map-chilkoot")
        relaunch(["-HornDebugStart", "dawson", "-HornTickSeconds", "30"])
        tap("Look at the map")
        shot("77-map-river")

        relaunch(["-HornDebugStart", "tagish", "-HornTickSeconds", "30"])
        tap("Go fishing")
        let water = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label BEGINSWITH 'The water below the boat'")).firstMatch
        XCTAssertTrue(water.waitForExistence(timeout: 5))
        shot("78-fishing")
        for dy in [0.3, 0.5, 0.7, 0.4, 0.6] {
            water.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: dy)).tap()
            usleep(350_000)
        }
        water.coordinate(withNormalizedOffset: CGVector(dx: 0.35, dy: 0.5)).tap()
        usleep(200_000)
        shot("79-cast", settle: false)
        tap("Back to camp")
        XCTAssertTrue(app.buttons["Continue"].waitForExistence(timeout: 5), "Back to camp didn't land")
        shot("80-caught")
        // On the trail there is no water to fish.
        relaunch(["-HornDebugStart", "camp", "-HornTickSeconds", "30"])
        tap("Go fishing")
        shot("81-nothing-to-catch")
    }

    /// Sleds and oars given out, no firewood, both at once, and an outfit worn low.
    func testTrouble() {
        relaunch(["-HornDebugStart", "camp", "-HornDebugSails", "0", "-HornTickSeconds", "30"])
        shot("82-sleds-given-out-status")
        relaunch(["-HornDebugStart", "camp", "-HornDebugSails", "0", "-HornTickSeconds", "1"])
        tap("Continue on your journey")
        let mend = button(startingWith: "Mend the sleds")
        XCTAssertTrue(mend.waitForExistence(timeout: 10))
        shot("83-sleds-given-out")
        mend.tap()
        shot("84-sleds-mended")

        relaunch(["-HornDebugStart", "lakes", "-HornDebugWater", "0", "-HornTickSeconds", "30"])
        shot("85-no-firewood")
        tap("Check supplies & party")
        shot("86-no-firewood-supplies")
        relaunch(["-HornDebugStart", "lakes", "-HornDebugWater", "0", "-HornDebugSails", "0", "-HornTickSeconds", "30"])
        shot("87-both")
        relaunch(["-HornDebugStart", "camp", "-HornDebugHull", "12", "-HornDebugSails", "15", "-HornTickSeconds", "30"])
        tap("Make repairs")
        shot("88-repairs-worn")

        relaunch(["-HornDebugStart", "fivefinger", "-HornDebugSails", "0", "-HornTickSeconds", "1"])
        tap("Continue on your journey")
        let rerig = button(startingWith: "Re-rig the oars & sail")
        XCTAssertTrue(rerig.waitForExistence(timeout: 10))
        shot("89-oars-given-out")
        tap("Take stock first")
        shot("90-oars-given-out-menu")
    }

    func testDawson() {
        relaunch(["-HornDebugStart", "dawson", "-HornTickSeconds", "1"])
        tap("Continue on your journey")
        roll(until: "Head north again")
        shot("91-dawson")
        app.swipeUp()
        shot("92-dawson-bottom")
        tap("See the top ten")
        shot("93-top-ten")
        tap("Back")
        tap("Head north again")
        XCTAssertTrue(app.buttons["Head for the Klondike"].waitForExistence(timeout: 5))
        XCTAssertFalse(button(startingWith: "Continue the journey of").exists, "no save survives reaching Dawson")
    }

    /// The ways it ends short of Dawson: turned back at the summit, the outfit ruined on
    /// the trail, the boat broken up on the river.
    func testEndings() {
        relaunch(["-HornDebugStart", "summit", "-HornTickSeconds", "1", "-HornDebugFood", "4200"])
        tap("Continue on your journey")
        roll(until: "Turn back for home")
        tap("Turn back for home")
        let over = app.buttons["Try again"]
        XCTAssertTrue(over.waitForExistence(timeout: 10))
        shot("94-turned-back")
        tap("Try again")
        XCTAssertFalse(button(startingWith: "Continue the journey of").exists, "no save survives turning back")

        for (stop, name) in [("camp", "95-outfit-ruined"), ("fivefinger", "96-boat-broken-up")] {
            relaunch(["-HornDebugStart", stop, "-HornDebugHull", "0.3", "-HornTickSeconds", "2"])
            tap("Continue on your journey")
            for _ in 0..<20 where !over.exists {
                if onward.waitForExistence(timeout: 2) && !over.exists { onward.tap() }
            }
            XCTAssertTrue(over.waitForExistence(timeout: 10), "\(name): never over")
            shot(name)
            tap("Try again")
        }
    }
}
