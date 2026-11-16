import XCTest
@testable import HornEngine
@testable import AroundTheHorn

/// The Jet Stream's skin, held to its own journey's tables: every number its sentences
/// state, the words a balloon needs and the ones it must not borrow from a ship, a train
/// or an airship, every sky, stretch of country, field and stop in the picture, the polar
/// chart, the fishing, and the way out of a field. `SkinContractTests` asks what every
/// skin owes the shell; this asks what this one says. It ends with whole flights from the
/// title card to an ending.
@MainActor
final class BalloonSkinTests: XCTestCase {
    let air = BalloonSkin.journey
    let skin = BalloonSkin.skin
    let card = BalloonSkin.card
    let fm = FileManager.default
    var p: Persistence!

    override func setUp() async throws {
        p = Persistence(directory: fm.temporaryDirectory.appendingPathComponent(UUID().uuidString),
                        defaults: UserDefaults(suiteName: UUID().uuidString)!)
    }

    func stopIndex(_ id: String) -> Int { air.stops.firstIndex { $0.id == id }! }

    /// Ten miles short of `stop`, in January, as the debug start leaves it.
    func nearing(_ stop: String) -> GameState { skin.debug.start(stopIndex(stop), 0) }

    /// Standing at `stop`, its arrival told; on the ground if `port`.
    func at(_ stop: String, port: Bool = false) -> GameState {
        var g = nearing(stop)
        BalloonSkin.at(&g, stop, port: port)
        return g
    }

    /// Flying at `mile`, on the southern track if `south`.
    func over(_ mile: Int, south: Bool = false) -> GameState {
        var g = nearing("finish")
        g.mile = mile
        g.stopIndex = air.stops.lastIndex { $0.mile <= mile }!
        if south { g.vars[BalloonData.southKey] = 1 }
        return g
    }

    func has(_ text: String, _ part: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(text.contains(part), "“\(part)” is not in “\(text)”", file: file, line: line)
    }

    func state(month: Int = 0) -> GameState {
        let d = air.departures.first { $0.month == month }!
        return GameState(journey: Balloon.id, role: .merchant, ship: "Wren", captain: "Ada", crew: ["Bo", "Cy", "Di", "Ed"],
                         startYear: d.year, startMonth: d.month)
    }

    // MARK: Watches

    func testTurnsAreWatchesOfFourHours() {
        XCTAssertEqual(air.rules.tickHours, 4)
        XCTAssertEqual(BalloonSkin.perDay, 6)
        has(card.learnPages[0].paragraphs[2], "watches[/amber] of four hours, six to a day")
        XCTAssertEqual(BalloonSkin.span(1), "1 watch")
        XCTAssertEqual(BalloonSkin.span(5), "5 watches")
        XCTAssertEqual(BalloonSkin.span(6), "6 watches (1 day)")
        let w = skin.words(nearing("lux"))
        XCTAssertEqual(air.rules.restChoices.map(w.restChoice),
                       ["Loiter 1 watch", "Loiter 2 watches", "Loiter 3 watches", "Loiter 5 watches"])
        let ground = skin.words(at("lux", port: true))
        XCTAssertEqual(air.rules.restChoices.map(ground.restChoice),
                       ["Rest 1 watch", "Rest 2 watches", "Rest 3 watches", "Rest 5 watches"])
        has(w.repairsNote, "Each repair takes a watch.")
        has(w.yardIntro, "Each job takes a watch on the ground.")
        // Loitering burns its own share, about ten gallons a watch.
        XCTAssertEqual(BalloonData.loiterBurn, 10)
        has(w.restPrompt, "about 10 gallons a watch")
        XCTAssertEqual(BalloonSkin.tenth(2.5), "2.5")
        XCTAssertEqual(BalloonSkin.tenth(1.0), "1")
    }

    // MARK: Numbers the card states

    func testTheCardsNumbersAreTheTables() {
        let all = card.learnPages.flatMap(\.paragraphs) + card.differences + card.outfitBullets
            + [card.tagline, card.monthIntro, card.monthAdvice]
        let text = all.joined(separator: "\n")

        // The flight.
        XCTAssertEqual(air.totalMiles, 18300)
        XCTAssertEqual(air.totalMiles / 1000, 18)
        has(card.tagline, "Eighteen thousand nautical miles round the world")
        has(text, "18,300 nautical miles later")
        XCTAssertEqual(air.stops.first?.name, "Marrakech")
        XCTAssertEqual(air.ports.count - 1, 5)
        has(text, "Five fields along the way")
        XCTAssertEqual(state().crew.count, 5)
        has(text, "a crew of five, counting yourself")

        // Who you are.
        for (role, money) in [(Role.merchant, "$15,000"), (.shipwright, "$7,250"), (.whaler, "$6,500")] {
            let info = air.role(role)
            XCTAssertEqual("$" + formatNumber(info.money), money)
            let line = card.differences.first { $0.lowercased().contains(info.title) }
            XCTAssertNotNil(line, "\(role)")
            has(line ?? "", "starts with \(money).")
        }
        XCTAssertGreaterThan(air.role(.shipwright).mend, air.role(.merchant).mend)
        XCTAssertGreaterThan(air.role(.shipwright).patch, air.role(.merchant).patch)
        XCTAssertGreaterThan(air.role(.whaler).aim, air.role(.merchant).aim)
        XCTAssertEqual(Double(air.role(.whaler).catchLimit), 1.5 * Double(air.role(.merchant).catchLimit))
        has(text, "can stow half as much again of what it catches")
        XCTAssertEqual(Role.shipwright.scoreMultiplier, 2)
        XCTAssertEqual(Role.whaler.scoreMultiplier, 3)
        has(text, "the builder's counts double, the bush pilot's triple")

        // Propane.
        let propane = air.item(.fuel)
        XCTAssertEqual(Pace.allCases.map { air.pace($0).fuel }, [12, 14, 16])
        XCTAssertGreaterThan(BalloonData.burnFactor(.cold), 1)
        XCTAssertGreaterThan(BalloonData.burnFactor(.freezing), BalloonData.burnFactor(.cold))
        has(text, "12 to 16 gallons a watch, more in the cold")
        XCTAssertEqual(BalloonData.launchBurn, 25)
        has(text, "25 to climb away from any field")
        has(text, "climbing away from a field takes 25 gallons")
        has(skin.words(at("lux", port: true)).leavePort, "25 gallons")
        XCTAssertEqual(propane.max, 1200)
        has(text, "You can lift 1,200 gallons")
        let saga = air.stop("saga")!.mile, abq = air.stop("abq")!.mile
        XCTAssertFalse(air.stops.contains { $0.mile > saga && $0.mile < abq && air.port($0.id) != nil }, "no field over the Pacific")
        XCTAssertEqual(abq - saga, 5850)
        has(text, "From Saga to Albuquerque is 5,850 nautical miles with nowhere to land")
        has(text, "There is nowhere to land between Saga and Albuquerque")

        // The crossing at the usual winds of January, the balloon worn to 85%: some 600
        // gallons, in the middle air or the jet; in light winds all the way, far more.
        func crossing(_ pace: Pace, speed: ((Region) -> Double)? = nil) -> Double {
            let g = state(month: 0)
            let worn = (0.75 + 0.25 * 0.85) * (0.45 + 0.55 * 0.85)
            var gallons = 0.0
            for m in stride(from: saga, to: abq, by: 50) {
                let r = air.region(g, at: m)
                let total = r.weights.reduce(0) { $0 + $1.1 }
                let weather = speed?(r) ?? r.weights.reduce(0) { $0 + $1.0.speed * $1.1 } / total
                let watches = 50 / (air.pace(pace).speed * weather * worn)
                gallons += watches * air.pace(pace).fuel * BalloonData.burnFactor(air.temperature(g, in: r))
            }
            return gallons
        }
        for pace in [Pace.steady, .full] { XCTAssertTrue((500...700).contains(crossing(pace)), "\(pace): \(crossing(pace))") }
        XCTAssertGreaterThan(crossing(.steady) { _ in BalloonData.light.speed }, 1000)
        has(text, "In good winds the crossing burns some 600 gallons of propane; in poor ones, far more.")
        // The jet burns less a mile.
        XCTAssertLessThan(air.pace(.full).fuel / air.pace(.full).speed, air.pace(.steady).fuel / air.pace(.steady).speed)
        has(text, "burn less propane for every mile")

        // Food, water, air.
        XCTAssertEqual(5 * air.rations(.filling).amount, 2.5, accuracy: 1e-9)
        XCTAssertEqual(air.rations(.filling).name, "Hot meals")
        has(text, "five of you on hot meals eat 2.5 lbs a watch")
        // At about 130 miles a watch flown, the whole way is three or four weeks.
        let weeks = Double(air.totalMiles) / 130 / Double(BalloonSkin.perDay) / 7
        XCTAssertTrue((3...4.5).contains(weeks), "\(weeks)")
        has(text, "the flight takes three or four weeks")
        XCTAssertEqual(air.rules.water, 0.2)
        XCTAssertGreaterThan(air.rules.hotWater, air.rules.water)
        has(text, "a fifth of a gallon each a watch, more in the heat")
        XCTAssertEqual(air.rules.rainCatch, 2...6)
        XCTAssertTrue(BalloonData.snow.wet)
        has(text, "In snow you can melt rime off the hatch rim.")
        XCTAssertEqual(1 / (5 * air.rules.preventiveUse), 10, accuracy: 1e-9)
        has(text, "a canister lasts five of you ten watches")
        XCTAssertEqual(air.rules.deficiencyAfter, 3 * BalloonSkin.perDay)
        has(text, "within three days")
        has(text, "Three days without them")
        XCTAssertEqual(air.item(.tackle).per, 20)
        has(text, "a spool is 20 casts")

        // Everything the hangar sells is on the outfitting list.
        let bullets = card.outfitBullets.joined(separator: "\n").lowercased()
        for it in air.items {
            let name = it.key == .food ? "food" : it.key == .water ? "water" : it.name.lowercased()
            has(bullets, name.replacingOccurrences(of: "burner spares", with: "burner spares"))
        }
    }

    /// November's jet hasn't filled and March's is breaking up; December to February are
    /// one season. The launches are November 1998 to March 1999.
    func testTheSeasonsAreTheEnginesCalendar() {
        XCTAssertEqual(air.departures.map(\.month), [10, 11, 0, 1, 2])
        XCTAssertEqual(air.departures.map(\.year), [1998, 1998, 1999, 1999, 1999])
        has(card.monthIntro, "Your balloon is ready in November 1998.")
        func jetOdds(_ month: Int) -> Double {
            let e = GameEngine(state: state(month: month))
            let odds = air.weatherWeights(e, air.regions.first { $0.id == "npacific" }!, cursed: false)
            let total = odds.reduce(0) { $0 + $1.1 }
            return odds.filter { $0.0 == BalloonData.jet }.reduce(0) { $0 + $1.1 } / total
        }
        XCTAssertEqual(jetOdds(11), jetOdds(0))
        XCTAssertEqual(jetOdds(1), jetOdds(0))
        XCTAssertLessThan(jetOdds(10), jetOdds(0) - 0.05)
        XCTAssertLessThan(jetOdds(2), jetOdds(0) - 0.05)
        has(card.monthAdvice, "The jet is weak in November and starts breaking up in March.")
        has(card.monthAdvice, "Launch in December, January or February")
        has(card.learnPages[3].paragraphs[1], "The jet is strongest from December to February.")
        XCTAssertTrue(skin.debug.start(3, 9).dateText.hasPrefix("January"), "a debug start out of season is in January")
    }

    func testTheRankLegendIsTheEnginesRanks() {
        let cuts = air.rules.rankCuts
        XCTAssertEqual(cuts, [7000, 4000, 2000])
        let legend = cuts.map { "\(air.rank($0)) \(formatNumber(Double($0)))+" } + [air.rank(0)]
        XCTAssertEqual(card.rankLegend, legend.joined(separator: " · "))
    }

    // MARK: A balloon's words

    func testTheStatusBoxIsABalloons() {
        var g = nearing("lux")
        let w = skin.words(g)
        let rows = StatusPanel.stores(air, g, w)
        XCTAssertEqual(rows.map(\.label), ["Rations", "Water", "Propane"])
        XCTAssertEqual(rows.map(\.value), ["200 lbs", "150 gal", "900 gal"])
        XCTAssertEqual(w.meters.0, "Lift")
        XCTAssertEqual(w.meters.1, "Burners")
        XCTAssertEqual(w.travelled, "Flown")
        XCTAssertEqual(w.distanceUnit, "nm")
        XCTAssertEqual(w.distance(18300), "18,300")
        XCTAssertEqual(w.leaderTag, "pilot")
        XCTAssertNil(w.clock)
        XCTAssertNil(w.place, "aloft, the status box names the country below")

        g.water = 1
        XCTAssertEqual(StatusPanel.stores(air, g, skin.words(g))[1].value, "1 gal")

        let list = SuppliesView.rows(air, g, w)
        XCTAssertEqual(list.map(\.0), ["Cash", "Rations", "Drinking water", "CO2 scrubbers", "Medical kits", "Down suits",
                                       "Ballast", "Burner spares", "Fishing line", "Propane"])
        XCTAssertEqual(list.last?.1, "900 gal")
        XCTAssertEqual(list[8].1, "60 casts")
        XCTAssertEqual(list[3].1, "8 canisters")
        g.limes = 0.37
        XCTAssertEqual(SuppliesView.rows(air, g, w)[3].1, "0.3 canisters", "scrubbers are used by the tenth of a canister")
        g.limes = 1
        XCTAssertEqual(SuppliesView.rows(air, g, w)[3].1, "1 canister")
        g.tackle = 1
        XCTAssertEqual(SuppliesView.rows(air, g, w)[8].1, "1 cast")

        // Who is on it, and what the menus offer.
        XCTAssertEqual(w.bonus, "Bonus for being a chocolate maker")
        g.role = .shipwright
        XCTAssertEqual(skin.words(g).bonus, "Bonus for being a balloon builder")
        has(skin.words(g).repairsNote, "As a balloon builder")
        g.role = .whaler
        XCTAssertEqual(skin.words(g).bonus, "Bonus for being a bush pilot")
        XCTAssertEqual(w.trade, "See who'll trade")
        XCTAssertEqual(w.talk, "Ask around the field")
        XCTAssertEqual(w.forage, "Trail a fishing line")
        XCTAssertEqual(w.halt, "Hold & take stock")
        has(w.rationsNow, "With 5 aboard, that's 2.5 lbs a watch.")

        // On the ground the box names the field, not the next leg's country.
        let luxor = at("lux", port: true)
        XCTAssertEqual(luxor.region.name, "Arabia")
        XCTAssertEqual(skin.words(luxor).place, "Luxor")
        XCTAssertNil(skin.words(at("lux")).place, "over the field, not on it")
        XCTAssertEqual(skin.words(at("abq", port: true)).place, "Albuquerque")
        XCTAssertEqual(skin.words(at("saga", port: true)).place, "Saga")
        // The other journeys write the region, as they always have.
        for other in [Horn1849Skin.skin, RailSkin.skin, AirshipSkin.skin] {
            var g = other.debug.start(2, 4)
            g.atPort = true
            XCTAssertNil(other.words(g).place, other.id)
            XCTAssertNil(other.words(g).leaveRefusal, other.id)
        }
    }

    func testTheNotesWarnOfScrubbersAndDryTanks() {
        var g = nearing("lux")
        XCTAssertFalse(skin.words(g).suppliesNote.contains("[red]"))
        has(skin.words(g).suppliesNote, "Altitude: Middle air · Rations: Hot meals")
        g.noCitrus = 13
        has(skin.words(g).suppliesNote, "[red]13 watches without scrubbers[/red]")
        g.noCitrus = 12
        XCTAssertFalse(skin.words(g).suppliesNote.contains("scrubbers"))
        g.fuel = 0
        has(skin.words(g).suppliesNote, "[red]the tanks are dry[/red]")
        has(skin.words(g).paceNow, "the height makes no difference to how far she drifts")
        g.clothes = 3
        XCTAssertEqual(skin.words(g).clothesWarning, "[red]Only 3 of 5 aboard have a down suit.[/red]")
        g.clothes = 5
        XCTAssertNil(skin.words(g).clothesWarning)
        // With no heat the drift is the same at every height: the engine's own figure.
        XCTAssertEqual(BalloonData.driftSpeed, 40)
    }

    /// D14, for the balloon: the box says when she is going down, has no heat, or is on
    /// the last of her propane.
    func testTheStatusBoxSaysWhenTheBalloonIsInTrouble() {
        var g = nearing("lux")
        g.pace = .steady
        func trouble() -> String? {
            let t = skin.words(g).trouble
            if let t { XCTAssertEqual(t.label, "Balloon") }
            return t?.value
        }
        XCTAssertNil(trouble())
        let watch = Balloon.watchBurn(g)
        XCTAssertEqual(watch, 14 * BalloonData.burnFactor(.warm), accuracy: 1e-9)
        g.fuel = watch - 0.5
        XCTAssertEqual(trouble(), "Last of the propane", "less than a watch here burns")
        g.fuel = watch
        XCTAssertNil(trouble())
        g.fuel = 0
        XCTAssertEqual(trouble(), "Tanks dry, sinking")
        g.sails = 0.4
        XCTAssertTrue(Balloon.burnersOut(g), "shows 0%: given out")
        XCTAssertEqual(trouble(), "Burners dead, tanks dry")
        g.fuel = 900
        XCTAssertEqual(trouble(), "Burners dead, sinking")
        has(skin.words(g).suppliesNote, "[red]the burners are dead[/red]")
        has(skin.words(g).paceNow, "[red]With no heat for the cone")
        g.sails = 0.5
        XCTAssertNil(trouble(), "shows 1%")
        g.hull = 0.3
        XCTAssertTrue(Balloon.goingDown(g))
        XCTAssertEqual(trouble(), "Going down")
        // On the ground she is not sinking; and before the launch there is nothing to say.
        g = at("lux", port: true)
        g.fuel = 0
        XCTAssertEqual(trouble(), "Tanks dry")
        g.fuel = 900
        g.sails = 0
        XCTAssertEqual(trouble(), "Burners dead")
        g.sails = 80
        g.hull = 0
        XCTAssertEqual(trouble(), "No lift")
        g = state()
        g.fuel = 0
        XCTAssertNil(trouble())

        // Dead burners are drawn as dry tanks are: no flame, drifting.
        var dead = nearing("jod")
        dead.weather = air.fairWeather
        dead.sails = 0
        XCTAssertTrue(BalloonScene.cold(frame(dead)))
        XCTAssertFalse(BalloonScene.flame(frame(dead)))
        has(skin.scene.label(frame(dead)), "drifting")
        has(skin.scene.label(frame(dead)), "burners dead")
    }

    func testTheStoresSellPropaneByTheFifty() {
        let w = skin.words(nearing("lux"))
        func label(_ key: ItemKey, at port: String) -> String {
            ShopView.priceLabel(air.item(key), air.port(port)!.price(key), w.currency, lot: w.lots.contains(key))
        }
        XCTAssertEqual(label(.fuel, at: "mar"), "$22.50/50 gal")
        XCTAssertEqual(label(.water, at: "mar"), "$5/10 gal")
        XCTAssertEqual(label(.food, at: "mar"), "$3/lb")
        XCTAssertEqual(label(.tackle, at: "mar"), "$30/spool")
        XCTAssertEqual(label(.fuel, at: "lux"), "$23.40/50 gal")
        has(w.priceNote(30), "Prices here are 30% above Marrakech, more or less.")
        var g = nearing("lux")
        g.tackle = 60
        XCTAssertEqual(Stores.have(air.item(.tackle), g, w), "3")
        XCTAssertEqual(Stores.unit(air.item(.tackle), count: "3", w), "spools")
        // Propane is cheapest at Luxor of the fields after Marrakech, as its driver says.
        let after = air.ports.dropFirst().map { ($0.id, $0.price(.fuel)) }
        XCTAssertEqual(after.min { $0.1 < $1.1 }?.0, "lux")
    }

    /// Every string reachable in `value`: the words as data, without the closures.
    func strings(_ value: Any) -> [String] {
        if let s = value as? String { return [s] }
        return Mirror(reflecting: value).children.flatMap { strings($0.value) }
    }

    /// Everything the skin can say, at every stop, for every role.
    func everythingSaid() -> [String] {
        var out = strings(card) + [card.resume("Wren"), card.outfitIntro(nearing("atlas"))]
        let forage = skin.forage
        out += [forage.heading, forage.throwsLabel, forage.caughtLabel, forage.timeLabel, forage.hint("40 lbs"),
                forage.label(3), forage.actionHint, forage.leave, skin.chart.title]
        out += air.quarry.flatMap { [forage.pop("1", $0), forage.pop("24", $0)] }
        for i in air.stops.indices.dropFirst() {
            for role in Role.allCases {
                for (port, day, fuel, hull, sails) in [(false, 10, 900.0, 72.0, 64.0), (true, 80, 0, 0, 0), (false, 90, 3, 0.2, 0.2)] {
                    var g = skin.debug.start(i, 0)
                    g.role = role
                    g.day = day
                    g.fuel = fuel
                    g.hull = hull
                    g.sails = sails
                    g.noCitrus = day
                    g.atPort = port && air.port(air.stops[i - 1].id) != nil
                    g.clothes = port ? 2 : 5
                    let w = skin.words(g)
                    out += strings(w) + air.rules.restChoices.map(w.restChoice)
                    out += [w.distance(g.mile), w.yardHull(56), w.yardSails(72), w.priceNote(30), w.burial("Bo"),
                            skin.chart.label(g), skin.chart.footer(g)]
                    for weather in air.weathers {
                        g.weather = weather
                        for moving in [false, true] {
                            out.append(skin.scene.label(ScenePicture.frame(air, g, moving: moving, t: 0)))
                        }
                    }
                }
            }
        }
        for cell in skin.debug.gallery {
            let g = SceneGallery.state(air, cell.set)
            out.append(skin.scene.label(ScenePicture.frame(air, g, moving: cell.moving, t: 0)))
        }
        out.append(skin.scene.label(ScenePicture.frame(air, nil, moving: false, t: 0)))
        return out
    }

    /// Every sentence the balloon's engine can write, read from its source: each string
    /// literal, with the code inside its interpolations taken out.
    func engineSaid() throws -> [String] {
        let dir = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent("HornEngine/Journeys/Balloon")
        let files = try fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil).filter { $0.pathExtension == "swift" }
        XCTAssertGreaterThanOrEqual(files.count, 6, "the balloon's engine is in \(dir.path)")
        let literal = try NSRegularExpression(pattern: #""((?:[^"\\\n]|\\.)*)""#)
        var out: [String] = []
        for file in files {
            for line in try String(contentsOf: file, encoding: .utf8).split(separator: "\n").map(String.init)
            where !line.trimmingCharacters(in: .whitespaces).hasPrefix("//") {
                for m in literal.matches(in: line, range: NSRange(line.startIndex..., in: line)) {
                    let s = String(line[Range(m.range(at: 1), in: line)!])
                    out.append(Self.withoutCode(s))
                }
            }
        }
        out += air.items.flatMap { it in [1, 2].map { air.describe(.item(it.key), Double(it.per * $0)) } }
        out += [Balloon.finale(nearing("finish")), Balloon.shortfall(nearing("finish"))]
        return out
    }

    /// A literal with the code inside its interpolations taken out, however deep its
    /// parentheses go.
    static func withoutCode(_ s: String) -> String {
        var out = "", depth = 0
        var chars = Array(s)[...]
        while let ch = chars.first {
            chars = chars.dropFirst()
            if depth == 0 && ch == "\\" && chars.first == "(" {
                depth = 1
                chars = chars.dropFirst()
            } else if depth > 0 {
                if ch == "(" { depth += 1 } else if ch == ")" { depth -= 1 }
            } else {
                out.append(ch)
            }
        }
        return out
    }

    /// Words from the other journeys' worlds: a sailing ship's, a train's, an airship's.
    /// A balloon flies over seas and ships, and counts in nautical miles and pounds, so
    /// those stay.
    static let elsewhere = try! NSRegularExpression(
        pattern: #"\b(sail(s|ed|ing|ors?)?|sailcloth|shipyard|anchor(s|ed)?|hull|harpoons?|tackle|throws?|voyages?|"#
            + #"scurvy|citrus|limes?|whal(e|er|ers|ing)|"#
            + #"trains?|railroad|railway|locomotive|conductor|caboose|boxcars?|tender|cords?|firewood|wagons?|oxen|"#
            + #"petrol|airships?|zeppelins?|gondola|masts?|moored|mooring|kilomet(re|res|er|ers)|km|kg)\b"#,
        options: [.caseInsensitive])

    func testNothingInTheAirIsSaidInAnotherJourneysWords() throws {
        let said = everythingSaid()
        XCTAssertGreaterThan(Set(said).count, 200, "the walk found the words")
        // A container ship has a radio mast, ballast is thrown over the side, and mules
        // walk the Atlas in trains.
        let figures = ["her radio mast", "throw over the side", "mule trains"]
        let engine = try engineSaid().map { s in figures.reduce(s) { $0.replacingOccurrences(of: $1, with: "") } }
        XCTAssertGreaterThan(Set(engine).count, 200, "the source was read")
        for s in Set(said + engine) {
            if let m = Self.elsewhere.firstMatch(in: s, range: NSRange(s.startIndex..., in: s)) {
                XCTFail("another journey's word “\((s as NSString).substring(with: m.range))” in “\(s)”")
            }
        }
        // The same sieve does catch a ship, a train and an airship.
        for other in [Horn1849Skin.skin, RailSkin.skin, AirshipSkin.skin] {
            let words = strings(other.words(other.debug.start(3, 4))).joined(separator: "\n")
            XCTAssertNotNil(Self.elsewhere.firstMatch(in: words, range: NSRange(words.startIndex..., in: words)), other.id)
        }
        // And nothing here is said in the shapes D11 retired.
        let retired = ["You may:", "Find out the differences", "Be a ", "Filling", "Meager", "Bare bones", "Attempt to trade"]
        for s in Set(said + engine + air.roles.values.map(\.label) + Rations.allCases.map { air.rations($0).name }) {
            for r in retired { XCTAssertFalse(s.contains(r), "“\(r)” in “\(s)”") }
        }
        XCTAssertEqual(Role.allCases.map { air.role($0).label },
                       ["A Zurich chocolate maker", "A Bristol balloon builder", "An Alaska bush pilot"])
    }

    func testTradesAndTheLaunchReadRight() {
        XCTAssertEqual(air.describe(.item(.meds), 3), "3 medical kits")
        XCTAssertEqual(air.describe(.item(.clothes), 1), "1 down suit")
        XCTAssertEqual(air.describe(.item(.fuel), 400), "400 gallons of propane")
        XCTAssertEqual(air.describe(.item(.tackle), 40), "2 spools of fishing line")
        XCTAssertEqual(air.describe(.item(.tackle), 25), "25 casts of fishing line")
        let g = state()
        let depart = air.text.depart(g)
        has(depart, "at 0800 GMT on January 1, 1999.")
        XCTAssertFalse(depart.contains(".."), depart)
        has(skin.words(nearing("finish")).gameOverLine, "nautical miles flown")
        has(skin.words(nearing("finish")).gameOverLine, "short of the finish line")
    }

    // MARK: Leaving Marrakech, and every field after

    func controller() -> GameController {
        let c = GameController(persistence: p, journeys: Journeys.all, skins: Skins.all)
        c.tickInterval = .seconds(3600)
        return c
    }

    func newFlight(_ c: GameController, role: Role = .merchant, month: Int = 0) {
        c.chooseJourney(air.id)
        c.startNewGame()
        c.chooseRole(role)
        c.setNames(ship: "", captain: "Ira", crew: ["", "", "", ""])
        let d = air.departures.first { $0.month == month }!
        c.chooseDeparture(year: d.year, month: d.month)
    }

    /// The launch director won't let her go without food and the climb's 25 gallons; with
    /// them she lifts off, and a flight saved in the hangar comes back to it (D16).
    func testMarrakechWontLetHerGoWithoutTheClimbsPropane() {
        XCTAssertNil(skin.words(state()).departRefusal, "the engine's own refusal names both")
        has(air.text.noProvisions, "at least 25 gallons of propane")
        let c = controller()
        newFlight(c)
        c.enterFirstShop()
        guard case .shop(let done) = c.screen else { return XCTFail("\(c.screen)") }
        c.run { $0.buy([.food: 100, .fuel: 20]) }
        c.save()
        done()
        guard case .message(let why, _, let back) = c.screen else { return XCTFail("\(c.screen)") }
        XCTAssertEqual(why, air.text.noProvisions)
        back()
        guard case .shop = c.screen else { return XCTFail("back to the hangar, not \(c.screen)") }

        // Quit there and come back: the hangar, not a field menu that would let her go.
        let again = controller()
        again.chooseJourney(air.id)
        again.continueSavedVoyage()
        guard case .shop(let pay) = again.screen else { return XCTFail("back to the hangar, not \(again.screen)") }
        again.run { $0.buy([.fuel: 30]) }
        pay()
        guard case .depart(let text) = again.screen else { return XCTFail("\(again.screen)") }
        has(text, "lifts off from the launch field outside Marrakech at 0800 GMT")
        // The picture is the launch: the field below, the crowd waving, the burners roaring.
        let launch = ScenePicture.frame(air, again.game!, moving: false, t: 0.3)
        XCTAssertTrue(BalloonScene.launching(launch))
        XCTAssertFalse(BalloonScene.loitering(launch))
        XCTAssertTrue(BalloonScene.flame(launch))
        has(skin.scene.label(launch), "climbing away from the launch field at Marrakech")
        XCTAssertFalse(BalloonScene.launching(ScenePicture.frame(air, again.game!, moving: true, t: 0.3)), "flying is flying")
        XCTAssertEqual(again.game!.fuel, 25, accuracy: 1e-9, "the climb burned 25")
        XCTAssertFalse(again.game!.atPort)
        XCTAssertEqual(skin.words(again.game!).setOut, "Climb away")
    }

    /// At a field she can buy the climb's propane, she is told to; with no money the ground
    /// team tops her up and she leaves with an empty tank; with no lift and a sack for
    /// sale, ballast or helium first. The way out of the field asks the skin.
    func testAFieldWontLetHerGoWithoutWhatItSells() {
        var g = at("lux", port: true)
        g.fuel = 10
        g.money = 2000
        let c = controller()
        c.loadForDebug(g)
        guard case .portMenu = c.screen else { return XCTFail("\(c.screen)") }
        let why = try? XCTUnwrap(skin.words(c.game!).leaveRefusal)
        has(why ?? "", "You need at least 25 gallons of propane to relaunch.")
        c.leavePort()
        guard case .message(let said, _, let back) = c.screen else { return XCTFail("\(c.screen)") }
        XCTAssertEqual(said, why)
        back()
        guard case .portMenu = c.screen else { return XCTFail("still on the field, not \(c.screen)") }
        XCTAssertTrue(c.game!.atPort)
        XCTAssertTrue(c.run { $0.buy([.fuel: 50]) })
        XCTAssertNil(skin.words(c.game!).leaveRefusal)
        XCTAssertTrue(c.run { $0.buy([.fuel: 450]) })
        c.leavePort()
        guard case .travel = c.screen else { return XCTFail("\(c.screen)") }
        XCTAssertEqual(c.game!.fuel, 485, accuracy: 1e-9, "the climb burned 25")
        c.tick()
        if case .message = c.screen { XCTFail("a plain relaunch says so in the note: \(c.screen)") }
        has(c.game!.note, "Relaunched. The climb back to cruising height burned 25 gallons.")

        // No money for a step of propane: the ground team pays, and says so.
        var poor = at("lux", port: true)
        poor.fuel = 10
        poor.money = 5
        XCTAssertNil(skin.words(poor).leaveRefusal)
        let d = controller()
        d.loadForDebug(poor)
        d.leavePort()
        guard case .travel = d.screen else { return XCTFail("\(d.screen)") }
        d.tick()
        guard case .message(let chief, _, _) = d.screen else { return XCTFail("\(d.screen)") }
        has(chief, "On the sponsor's account")
        has(chief, "(+15 gallons.)")

        // No lift, no ballast, and the price of a sack: ballast or helium first.
        var flat = at("lux", port: true)
        flat.hull = 0
        flat.timber = 0
        flat.day = 30
        has(skin.words(flat).leaveRefusal ?? "", "won't let you go up with no lift in her")
        flat.timber = 1
        XCTAssertNil(skin.words(flat).leaveRefusal)
        // Aloft there is never a refusal: the app also resumes between fields.
        XCTAssertNil(skin.words(nearing("lux")).leaveRefusal)
    }

    // MARK: The picture

    /// The frame by day where she is, unless `hour` (GMT) says otherwise.
    func frame(_ g: GameState, hour: Int? = nil, moving: Bool = true) -> SceneFrame {
        SceneFrame(t: 0, weather: g.weather, moving: moving, atPort: g.atPort, hull: g.hull, sails: g.sails,
                   region: g.region, hour: hour ?? noon(g), state: g)
    }

    /// The GMT hour nearest local noon where she is.
    func noon(_ g: GameState) -> Int {
        let h = Int((12 - BalloonScene.longitude(g) / 15).rounded()) % 24
        return h < 0 ? h + 24 : h
    }

    func picture(_ f: SceneFrame, t: Double = 0.37) -> Int {
        let px = PixelCanvas(w: SceneSkin.w, h: SceneSkin.h)
        skin.scene.draw(px, f.at(t))
        return px.tally.picture
    }

    func testTheSpriteIsWhole() {
        XCTAssertEqual(BalloonScene.balloon.count, 20)
        for row in BalloonScene.balloon {
            XCTAssertEqual(row.count, 18)
            for ch in row where ch != " " { XCTAssertNotNil(BalloonScene.colors[ch], "no colour for \(ch)") }
        }
        // Standing on a field, her capsule's floor is on the ground.
        XCTAssertEqual(BalloonScene.groundY + Double(BalloonScene.balloon.count), BalloonScene.aloftHorizon + 7)
        // Loitering, her lowest row is just above the low horizon.
        XCTAssertEqual(BalloonScene.loiterY + Double(BalloonScene.balloon.count) - 1, BalloonScene.lowHorizon - 3)
    }

    func testEveryWeatherIsItsOwnPicture() {
        var seen: [Int: String] = [:]
        for weather in air.weathers {
            var g = nearing("lux")
            g.weather = weather
            let pic = picture(frame(g))
            XCTAssertNil(seen[pic], "\(weather.name) looks just like \(seen[pic] ?? "")")
            seen[pic] = weather.name
        }
        XCTAssertEqual(seen.count, 10)
        // The two clear skies are told apart by the rules' own figure.
        XCTAssertEqual(BalloonData.steady.sky, BalloonData.light.sky)
        XCTAssertNotEqual(BalloonScene.palette(BalloonData.steady).top, BalloonScene.palette(BalloonData.light).top)
        // Aloft in cloud, snow or a storm, a deck hides the ground; loitering under it, the
        // ground shows.
        var cloud = over(9000)
        cloud.weather = BalloonData.cloud
        var clear = cloud
        clear.weather = BalloonData.steady
        XCTAssertNotNil(BalloonScene.palette(BalloonData.cloud).deck)
        XCTAssertNotEqual(picture(frame(cloud)), picture(frame(clear)))
    }

    func testEveryStretchOfCountryIsItsOwnPicture() {
        var seen: [Int: String] = [:]
        var places = air.regions.map { r -> GameState in over(r.to - 30) }
        places += [over(9000, south: true), over(11500, south: true)]
        for var g in places {
            g.weather = air.fairWeather
            let pic = picture(frame(g))
            XCTAssertNil(seen[pic], "\(g.region.name) looks just like \(seen[pic] ?? "")")
            seen[pic] = g.region.name
            XCTAssertEqual(pic, picture(frame(g)), "the same place twice is the same picture")
            XCTAssertNotEqual(pic, picture(frame(g, moving: false)), "\(g.region.name): loitering is not flying")
        }
        XCTAssertEqual(seen.count, air.regions.count + 2)
        XCTAssertTrue(seen.values.contains("The southern track"))
        // The Great Plains are under snow from December to February.
        var plains = over(14300)
        let january = BalloonScene.ground("plains", month: plains.month)
        plains.startMonth = 10
        plains.startYear = 1998
        XCTAssertNotEqual(january.0, BalloonScene.ground("plains", month: plains.month).0)
    }

    func testEveryFieldAndEveryStopIsDrawnAsItself() {
        var seen: [Int: String] = [:]
        for stop in air.stops {
            let field = air.port(stop.id) != nil
            var g = at(stop.id, port: field)
            g.weather = air.fairWeather
            if stop.id == "mar" { g.day = 0 }
            if stop.type == .end { g.over = true; g.atPort = true }
            let pic = picture(frame(g, moving: false))
            XCTAssertNil(seen[pic], "\(stop.id) looks just like \(seen[pic] ?? "")")
            seen[pic] = stop.id
            // Not the same as flying on past it.
            var by = g
            by.atPort = false
            by.over = false
            by.mile = stop.mile + (stop.type == .end ? -10 : 10)
            if stop.id != "mar" {
                XCTAssertNotEqual(pic, picture(frame(by, moving: false)), "\(stop.id) is drawn as a stop")
                XCTAssertNotEqual(skin.scene.label(frame(g, moving: false)), skin.scene.label(frame(by, moving: false)), stop.id)
            }
            if field { has(skin.scene.label(frame(g, moving: false)), "standing on the field at \(air.port(stop.id)!.name)") }
        }
        XCTAssertEqual(seen.count, air.stops.count)
        has(skin.scene.label(frame(at("him"), moving: false)), "Everest")
        has(skin.scene.label(frame(at("dateline"), moving: false)), "date line")
        // The landfall is the coast the track comes in on.
        var south = at("landfall")
        south.vars[BalloonData.southKey] = 1
        has(skin.scene.label(frame(south, moving: false)), "San Diego")
        has(skin.scene.label(frame(at("landfall"), moving: false)), "California")
        XCTAssertNotEqual(picture(frame(south, moving: false)), picture(frame(at("landfall"), moving: false)))
        // On the field: no flame and no bob, under whatever sky the status box names.
        var stormy = at("saga", port: true)
        stormy.weather = BalloonData.storm
        var fair = stormy
        fair.weather = air.fairWeather
        XCTAssertFalse(BalloonScene.flame(frame(fair, moving: false)))
        XCTAssertNotEqual(picture(frame(stormy, moving: false)), picture(frame(fair, moving: false)))
        XCTAssertEqual(BalloonScene.position(frame(stormy, moving: false).at(1.1), BalloonScene.palette(BalloonData.storm), hz: 46).y,
                       BalloonScene.groundY)
        // The finish is the next sunrise, whatever the hour she crossed the line.
        var finish = at("finish")
        finish.over = true
        finish.atPort = true
        for hour in [0, 4, 8, 12, 16, 20] { XCTAssertFalse(BalloonScene.isNight(frame(finish, hour: hour, moving: false))) }
    }

    /// Over a field she has not landed at (its question on screen, or flying on past), the
    /// picture is the field and its ground team, not the country around it.
    func testAFieldSheHasNotLandedAtIsStillDrawn() {
        for port in air.ports where port.id != "mar" {
            var g = at(port.id)
            g.weather = air.fairWeather
            let asked = frame(g, moving: false), flying = frame(g)
            XCTAssertEqual(BalloonScene.overField(asked), port.id)
            XCTAssertNil(BalloonScene.field(asked))
            has(skin.scene.label(asked), "low over the field at \(port.name), the ground team waiting below")
            has(skin.scene.label(flying), "flying over the field at \(port.name)")
            var landed = g
            landed.atPort = true
            XCTAssertNotEqual(picture(asked), picture(frame(landed, moving: false)), port.id)
            var on = g
            on.mile += 10
            XCTAssertNil(BalloonScene.overField(frame(on)))
            XCTAssertNotEqual(picture(flying), picture(frame(on)), port.id)
            XCTAssertEqual(BalloonScene.whereabouts(g), "over the field at \(port.name)")
            XCTAssertEqual(BalloonScene.whereabouts(landed), "on the ground at \(port.name)")
        }
        // Marrakech's is behind her as soon as she climbs away.
        var leaving = state()
        leaving.atPort = false
        XCTAssertNil(BalloonScene.overField(frame(leaving, moving: false)))
    }

    /// Down for good: in the sea, on land, or on a field she could not pay at; the picture
    /// and the engine's ending agree.
    func testDownForGoodIsDrawnWhereSheCameDown() {
        for (mile, words) in [(9000, "down in the sea"), (4800, "down on open ground"), (16300, "down in the sea"),
                              (18260, "down on open ground"), (3650, "down in the sea"), (2500, "down on open ground")] {
            var g = over(mile)
            g.weather = air.fairWeather
            g.hull = 0
            let sinking = picture(frame(g, moving: false))
            g.over = true
            let f = frame(g, moving: false)
            XCTAssertTrue(BalloonScene.down(f))
            XCTAssertFalse(BalloonScene.cold(f))
            XCTAssertNotEqual(picture(f), sinking, "\(mile)")
            has(skin.scene.label(f), words)
            XCTAssertEqual(words.contains("sea"), air.wreckedBody(g).contains("swell"), "\(mile)")
        }
        var grounded = at("saga")
        grounded.hull = 0
        grounded.over = true
        let f = frame(grounded, moving: false)
        XCTAssertTrue(BalloonScene.down(f))
        has(skin.scene.label(f), "down for good on the field at Saga")
        XCTAssertNotEqual(picture(f), picture(frame(at("saga"), moving: false)))
        // The pilot's death leaves her in the air: not drawn as down.
        var lost = over(9000)
        lost.over = true
        XCTAssertFalse(BalloonScene.down(frame(lost)))
    }

    /// Night falls by the sun where she is, not by the GMT in the log: 0000 GMT is night
    /// over the Sahara and morning over Japan.
    func testTheNightIsLocalAndTheWearAndTheFlameShow() {
        var sahara = over(1200)
        sahara.weather = air.fairWeather
        XCTAssertTrue(BalloonScene.isNight(frame(sahara, hour: 0)))
        XCTAssertFalse(BalloonScene.isNight(frame(sahara, hour: 12)))
        XCTAssertFalse(BalloonScene.isNight(frame(sahara)))
        has(skin.scene.label(frame(sahara, hour: 0)), "by night")
        XCTAssertFalse(skin.scene.label(frame(sahara)).contains("night"))
        XCTAssertNotEqual(picture(frame(sahara, hour: 0)), picture(frame(sahara)))
        let japan = at("pacific")
        XCTAssertEqual(BalloonScene.longitude(japan), 133.5, accuracy: 1e-9)
        XCTAssertFalse(BalloonScene.isNight(frame(japan, hour: 0)), "0000 GMT is mid-morning off Japan")
        XCTAssertTrue(BalloonScene.isNight(frame(japan, hour: 12)))
        let abq = at("abq")
        XCTAssertTrue(BalloonScene.isNight(frame(abq, hour: 4)))
        XCTAssertFalse(BalloonScene.isNight(frame(abq, hour: 16)))
        // The south track's longitudes are its own.
        XCTAssertNotEqual(BalloonScene.longitude(over(12300, south: true)), BalloonScene.longitude(over(12300)))

        // The flame: blasting 0.6 s in 1.5 flying, blipping 0.4 s in 3 loitering.
        let g = sahara
        XCTAssertTrue(BalloonScene.flame(frame(g).at(0.3)))
        XCTAssertFalse(BalloonScene.flame(frame(g).at(0.9)))
        XCTAssertTrue(BalloonScene.flame(frame(g, moving: false).at(0.3)))
        XCTAssertFalse(BalloonScene.flame(frame(g, moving: false).at(0.5)))
        var worn = g
        worn.sails = 30
        XCTAssertFalse(BalloonScene.flame(frame(worn).at(0.35)), "worn burners blast for less")
        XCTAssertTrue(BalloonScene.flame(frame(worn).at(0.25)))
        var dry = g
        dry.fuel = 0
        XCTAssertFalse(BalloonScene.flame(frame(dry).at(0.3)))
        has(skin.scene.label(frame(dry)), "drifting over the Sahara, burners cold, sinking")
        var unbought = dry
        unbought.day = 0
        XCTAssertFalse(BalloonScene.cold(frame(unbought)))

        // Wear: each meter shows on its own, and the crown sags three pixels below 40%.
        var burners = g, lift = g, both = g
        burners.sails = 30
        lift.hull = 30
        both.sails = 30
        both.hull = 30
        let pics = [picture(frame(g)), picture(frame(burners)), picture(frame(lift)), picture(frame(both))]
        XCTAssertEqual(Set(pics).count, 4, "worn burners and lost lift are each drawn")
        let s = BalloonScene.palette(air.fairWeather)
        XCTAssertEqual(BalloonScene.position(frame(lift).at(0), s, hz: 46).y - BalloonScene.position(frame(g).at(0), s, hz: 46).y, 3)
        // Rough air sways her; a stalled one holds her still.
        var stalled = g
        stalled.weather = BalloonData.stalled
        let calm = BalloonScene.palette(BalloonData.stalled)
        XCTAssertEqual(BalloonScene.position(frame(stalled).at(1.2), calm, hz: 46).y, BalloonScene.aloftY)
    }

    /// Every place reads as a sentence says it: "over the Gulf of Oman", never "over The
    /// Gulf of Oman" or "over Past the Azores".
    func testEveryPlaceIsSaidAsASentenceSaysIt() {
        for region in air.regions + [BalloonData.southTrack, BalloonData.subtropic] {
            let south = region.id == BalloonData.southTrack.id || region.id == BalloonData.subtropic.id
            var g = over(region.to - 30, south: south)
            g.weather = air.fairWeather
            XCTAssertEqual(g.region.id, region.id)
            let phrase = BalloonScene.phrase(region)
            XCTAssertNotNil(BalloonScene.regionPhrase[region.id.rawValue], region.name)
            let labels = [skin.scene.label(frame(g)), skin.scene.label(frame(g, moving: false)), skin.chart.label(g)]
            has(labels[0], "Balloon flying \(phrase). Weather: steady wind")
            has(labels[1], "Balloon loitering low \(phrase), the burners blipping.")
            has(labels[2], "You are \(phrase).")
            for label in labels {
                for heading in ["over The ", "over Past", "over Morocco &", "over Northern"] {
                    XCTAssertFalse(label.contains(heading), label)
                }
            }
        }
        XCTAssertEqual(BalloonScene.regionPhrase.count, air.regions.count + 2)
    }

    // MARK: The chart

    func testTheChartHasEveryStopOnBothTracks() {
        for route in [BalloonChart.northRoute, BalloonChart.southRoute] {
            for stop in air.stops {
                XCTAssertTrue(route.contains { Int($0.mile) == stop.mile }, "\(stop.id) is not a point on the chart's route")
            }
            XCTAssertEqual(route.first?.mile, 0)
            XCTAssertEqual(route.last?.mile, Double(air.totalMiles))
            for (a, b) in zip(route, route.dropFirst()) { XCTAssertLessThan(a.mile, b.mile, "miles only go up") }
            for q in route {
                let r = hypot(q.x - BalloonChart.centre.x, q.y - BalloonChart.centre.y)
                XCTAssertLessThan(r, (90 - BalloonChart.rim) * BalloonChart.scale, "nm \(q.mile) is off the map")
            }
        }
        // Greenwich is down: Marrakech below the Pole, a little left; the date line at the
        // top; Albuquerque on the left; round the page anticlockwise all the way.
        let route = BalloonChart.northRoute
        XCTAssertGreaterThan(route[0].y, BalloonChart.centre.y)
        XCTAssertLessThan(route[0].x, BalloonChart.centre.x)
        let dateline = route.first { Int($0.mile) == air.stop("dateline")!.mile }!
        XCTAssertLessThan(dateline.y, BalloonChart.centre.y)
        XCTAssertEqual(dateline.x, BalloonChart.centre.x, accuracy: 1e-6)
        let abq = route.first { Int($0.mile) == air.stop("abq")!.mile }!
        XCTAssertLessThan(abq.x, BalloonChart.centre.x)
        for (a, b) in zip(BalloonChart.north, BalloonChart.north.dropFirst()) { XCTAssertLessThan(a.0, b.0, "east all the way") }
        XCTAssertEqual(BalloonChart.north.last!.0 - BalloonChart.north.first!.0, 360, "round the world")

        // Before the fork the southern track is still open; after it, the way taken.
        let chart = BalloonChart.skin
        let japan = nearing("pacific")
        XCTAssertEqual(chart.route(japan).map(\.mile), BalloonChart.northRoute.map(\.mile))
        XCTAssertEqual(chart.others(japan).count, 1)
        var south = nearing("dateline")
        south.vars[BalloonData.southKey] = 1
        XCTAssertTrue(BalloonChart.onSouthTrack(south))
        XCTAssertEqual(chart.route(south).map(\.mile), BalloonChart.southRoute.map(\.mile))
        XCTAssertTrue(chart.others(south).isEmpty)
        XCTAssertTrue(chart.others(nearing("dateline")).isEmpty)

        let g = nearing("lux")
        XCTAssertEqual(chart.footer(g), "2,190 of 18,300 nautical miles flown. 16,110 to go. The ringed stops are landing fields.")
        XCTAssertEqual(chart.label(g), "Polar chart of the flight round the world, east from Marrakech and back. You are over the Sahara.")
        has(chart.label(at("lux", port: true)), "You are on the ground at Luxor.")
        // A ring for every field, four strokes each, and a cross at the Pole.
        let rings = PixelCanvas(w: chart.w, h: chart.h)
        BalloonChart.marks(rings, g)
        XCTAssertEqual(rings.tally.marks, air.ports.count * 4 + 2)
    }

    /// Inside a projected outline, by the even-odd rule.
    func inside(_ q: (x: Double, y: Double), _ shape: [BalloonChart.Point]) -> Bool {
        let poly = BalloonChart.outline(shape)
        var inside = false
        for (a, b) in zip(poly, Array(poly.dropFirst()) + [poly[0]]) where (a.y > q.y) != (b.y > q.y) {
            if q.x < a.x + (q.y - a.y) / (b.y - a.y) * (b.x - a.x) { inside.toggle() }
        }
        return inside
    }

    /// Where the engine's regions are sea, the chart's route is over the sea, and over
    /// land where they are land: across the Sahara, India, China, America and Morocco, and
    /// the Gulf of Oman, the Pacific (either track) and the Atlantic. The coasts are a
    /// sketch at this scale, so a few crossings are left out: the Red Sea and the Gulf by
    /// Qatar (the engine's Arabia), the last 300 miles of the Chinese coast (its Himalaya &
    /// China), Kyushu at Saga, and Honshu's south coast, which the route grazes after the
    /// edge of the Pacific.
    func testTheChartsSeaIsTheScenesSea() {
        let chart = BalloonChart.skin
        let land = BalloonChart.shapes.filter { !$0.sea }.map(\.points)
        let water = BalloonChart.shapes.filter(\.sea).map(\.points)
        let stretches = [(200, 2100), (3600, 3750), (3900, 4350), (4450, 5000), (5100, 6900), (8300, 10000),
                         (10100, 12500), (12700, 13450), (13550, 14950), (15200, 17300), (17400, 18150), (18240, 18300)]
        for south in [false, true] {
            var g = over(0, south: south)
            let route = chart.route(g)
            for (from, to) in stretches {
                for m in stride(from: from, through: to, by: 25) {
                    g.mile = m
                    let r = air.region(g, at: m)
                    let q = ChartView.position(route, atMile: Double(m), chart)
                    let onLand = land.contains { inside(q, $0) } && !water.contains { inside(q, $0) }
                    XCTAssertEqual(onLand, !r.has("sea"), "nm \(m) (\(r.name)) on the chart is \(onLand ? "land" : "sea")")
                }
            }
        }
    }

    // MARK: Fishing

    func testTheCatchIsCountedInPoundsOfRations() {
        let w = skin.words(nearing("lux"))
        let reward = FishingView.reward(air, w)
        XCTAssertEqual(reward.item.key, .food)
        XCTAssertEqual(reward.measure(air.role(.merchant).catchLimit), "40 lbs")
        XCTAssertEqual(reward.measure(air.role(.whaler).catchLimit), "60 lbs")
        let forage = skin.forage
        XCTAssertEqual(FishingView.pop(forage, reward)(air.quarry[3]), "+12 lbs skipjack")
        XCTAssertEqual(FishingView.pop(forage, reward)(air.quarry[0]), "+1 lb flying fish")
        XCTAssertFalse(forage.field.upward, "cast down from the hatch")
        XCTAssertEqual(forage.field.origin.x, 80.5)
        XCTAssertEqual(forage.field.origin.y, 27.5)
        XCTAssertEqual(forage.throwsLabel, "Casts")
        XCTAssertEqual(forage.caughtLabel, "Caught")
        XCTAssertEqual(air.forageSeconds, 25)
        has(forage.hint(reward.measure(40)), "You can stow up to 40 lbs.")
        has(forage.label(3), "with 3 fish swimming")
        // The tally counts casts, as the supplies list does.
        let line = air.item(.tackle)
        var g = nearing("lux")
        for (n, reads) in [(0, "0 casts"), (1, "1 cast"), (2, "2 casts"), (60, "60 casts")] {
            g.tackle = n
            XCTAssertEqual(Stores.amount(line, g, w), reads)
        }
        // The engine's report says the same pounds.
        let report = over(3650)
        let e = GameEngine(state: report)
        let said = e.landCatch(30).compactMap { i -> String? in if case .message(let t) = i { return t }; return nil }
        XCTAssertTrue(said.contains { $0.contains("[amber]30 lbs[/amber]") }, "\(said)")

        // The longest a pop can be stays on the field, wherever the hit.
        let px = PixelCanvas(w: forage.field.w, h: forage.field.h)
        for fish in air.quarry {
            let pop = forage.pop(reward.count(fish.lb), fish)
            let width = px.width(pop, size: 8)
            XCTAssertLessThan(width, forage.field.w, pop)
        }
        // Each fish is its own drawing, and so is its direction.
        var seen = Set<Int>()
        for fish in air.quarry {
            for vx in [-30.0, 30] {
                let c = PixelCanvas(w: forage.field.w, h: forage.field.h)
                forage.quarry(c, FishingModel.Swimmer(kind: fish, x: 80, y0: 100, y: 100, vx: vx, t: 0, wf: 1, wa: 1))
                seen.insert(c.tally.picture)
            }
        }
        XCTAssertEqual(seen.count, air.quarry.count * 2)
    }

    // MARK: The picker, and whole flights

    func testThePickerOffersTheBalloon() {
        let c = controller()
        guard case .picker = c.screen else { return XCTFail("\(c.screen)") }
        XCTAssertEqual(Array(c.journeys.map(\.id).prefix(4)), [Horn1849.id, Rail.id, Airship.id, Balloon.id])
        c.chooseJourney(air.id)
        guard case .title = c.screen else { return XCTFail("\(c.screen)") }
        XCTAssertEqual(c.skin.id, air.id)
        XCTAssertEqual(c.journey.title, "The Jet Stream")
    }

    /// Answers whatever the flight raises, first open option each time, until it ends,
    /// with a little care: propane, food, water and scrubbers at every field it can
    /// afford, the riggers when she is worn, and repairs aloft when she is failing.
    func playOut(_ c: GameController, maxSteps: Int = 30_000) -> String {
        var refused = 0
        for _ in 0..<maxSteps {
            switch c.screen {
            case .travel:
                let g = c.game!
                if (g.sails < 40 && g.sailcloth >= 1) || (g.hull < 40 && g.timber >= 1) {
                    c.heaveTo()
                    if g.hull < 40 && g.timber >= 1 { c.patchHull() } else { c.mendSails() }
                    continue
                }
                c.tick()
            case .repairs, .shipyard: c.backToMenu()
            case .message(_, _, let then): then()
            case .choice(let e): c.choose(e, option: e.options.firstIndex(where: \.enabled)!)
            case .burial(let id, let cause): c.bury(crewID: id, cause: cause, epitaph: "")
            case .portMenu:
                c.run { e in
                    let n = e.state.living.count
                    let room = e.room(for: .fuel)
                    _ = e.buy([.fuel: room]) || e.buy([.fuel: room / 2]) || e.buy([.fuel: room / 4])
                    _ = e.buy([.food: max(0, min(e.room(for: .food), 200 - Int(e.state.food)))])
                    _ = e.buy([.water: max(0, min(e.room(for: .water), 120 - Int(e.state.water)))])
                    _ = e.buy([.limes: max(0, min(e.room(for: .limes), 8 - Int(e.state.limes)))])
                    _ = e.buy([.clothes: max(0, n - e.state.clothes)])
                    if e.state.sailcloth < 2 { _ = e.buy([.sailcloth: 1]) }
                    if e.state.timber < 3 { _ = e.buy([.timber: 2]) }
                }
                let g = c.game!
                if g.hull < 70 && c.read({ $0.canRepairHullAtYard }) {
                    c.repairHullAtYard()
                    continue
                }
                if g.sails < 70 && c.read({ $0.canRecutSailsAtYard }) {
                    c.recutSailsAtYard()
                    continue
                }
                if skin.words(g).leaveRefusal != nil { refused += 1 }
                if refused > 3 { c.startTravel() } else { c.leavePort() }
            case .seaMenu: c.startTravel()
            case .finale: return "finale"
            case .gameOver: return "gameover"
            default:
                XCTFail("stuck on \(c.screen)")
                return "stuck"
            }
        }
        return "too long"
    }

    /// Whole flights from the title card, the way a player's taps would make them: the
    /// hangar at Marrakech, the fields, the set pieces, and whichever ending the dice
    /// bring. The dice are seeded, so the flights are always the same ones, and the finish
    /// line is among the endings.
    func testAWholeFlightFromTheTitleCardReachesAnEnding() {
        var endings: [String] = []
        var arrivals: [String] = []
        for round in 0..<4 {
            let c = controller()
            newFlight(c, role: Role.allCases[round % Role.allCases.count])
            c.run { $0.rng = SeededRNG(seed: UInt64(round + 1)) }
            XCTAssertTrue(air.vesselNames.contains(c.game!.ship))
            c.enterFirstShop()
            guard case .shop(let done) = c.screen else { return XCTFail("\(c.screen)") }
            c.run { $0.buy([.fuel: 1000, .water: 120, .food: 200, .limes: 8, .clothes: 5, .sailcloth: 2, .timber: 3, .meds: 2]) }
            done()
            guard case .depart = c.screen else { return XCTFail("\(c.screen)") }
            c.startTravel()
            let end = playOut(c)
            endings.append(end)
            if case .finale = c.screen { arrivals.append(c.skin.words(c.game!).arrival) }
            XCTAssertNil(p.loadSave(air.id), "no save after the flight ends")
            XCTAssertFalse(c.traveling)
        }
        XCTAssertTrue(Set(endings).isSubset(of: ["finale", "gameover"]), "\(endings)")
        XCTAssertTrue(endings.contains("finale"), "a flight can reach the finish line: \(endings)")
        for a in arrivals { has(a, "crosses eight degrees west, the meridian of Marrakech") }
    }
}
