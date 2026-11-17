import XCTest
import HornEngine
@testable import AroundTheHorn

/// What every skin owes the shell, checked for every journey the engine has. A new
/// journey's skin is added to `Skins.all` and this file tells it what it left out.
///
/// The compiler already insists a skin supplies every member; this checks that what it
/// supplied is not blank and that its three drawings run for every weather and every stop.
@MainActor
final class SkinContractTests: XCTestCase {
    /// Every journey that has a skin, in `Journeys.all`'s order. A journey without one fails
    /// `testEveryJourneyHasASkinAndEverySkinAJourney` alone, so the contract below still
    /// runs over every skin there is, before and after it in the list.
    let journeys = Journeys.all.filter { Skins.skin($0.id) != nil }

    /// Every blank string reachable in `value`, by path. Closures are not strings: the
    /// tests call those themselves.
    func blanks(_ value: Any, _ path: String = "") -> [String] {
        if let s = value as? String {
            return s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? [path] : []
        }
        let m = Mirror(reflecting: value)
        if m.displayStyle == .optional { return m.children.first.map { blanks($0.value, path) } ?? [] }
        return m.children.enumerated().flatMap { i, ch in blanks(ch.value, path + "." + (ch.label ?? "\(i)")) }
    }

    func said(_ s: String, _ what: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertFalse(s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "\(what) is blank", file: file, line: line)
    }

    func fresh(_ j: Journey, role: Role = .merchant) -> GameState {
        let d = j.departures[0]
        return GameState(journey: j.id, role: role, ship: "Wren", captain: "Ada", crew: ["Bo", "Cy", "Di", "Ed"],
                         startYear: d.year, startMonth: d.month)
    }

    /// A voyage standing at each stop in turn (in port where there is one), and one under
    /// way just short of each: every place the words and the drawings can be asked for.
    func states(_ j: Journey) throws -> [(name: String, state: GameState)] {
        let skin = try XCTUnwrap(Skins.skin(j.id))
        var out = [("fresh", fresh(j))]
        for (i, stop) in j.stops.enumerated() {
            var at = fresh(j)
            at.stopIndex = i
            at.mile = stop.mile
            at.day = 3 * i
            at.atPort = j.port(stop.id) != nil
            out.append(("at \(stop.id)", at))
            if i > 0 { out.append(("nearing \(stop.id)", skin.debug.start(i, j.departures[0].month))) }
        }
        return out
    }

    // MARK: A skin for every journey

    func testEveryJourneyHasASkinAndEverySkinAJourney() {
        XCTAssertFalse(journeys.isEmpty)
        for j in Journeys.all { XCTAssertNotNil(Skins.skin(j.id), "no skin for \(j.id)") }
        for s in Skins.all { XCTAssertTrue(Journeys.has(s.id), "a skin for \(s.id), which is no journey") }
        XCTAssertEqual(Set(Skins.all.map(\.id)).count, Skins.all.count, "one skin each")
    }

    // MARK: Copy

    func testTheTitleCardLeavesNothingBlank() throws {
        for j in journeys {
            let card = try XCTUnwrap(Skins.skin(j.id)).card
            XCTAssertEqual(blanks(card), [], j.id)
            said(card.resume("Wren"), "\(j.id) resume")
            XCTAssertTrue(card.resume("Wren").contains("Wren"), "\(j.id): the saved voyage is named")
            said(card.outfitIntro(fresh(j)), "\(j.id) outfitIntro")
            XCTAssertFalse(card.learnPages.isEmpty, j.id)
            for page in card.learnPages { XCTAssertFalse(page.paragraphs.isEmpty, "\(j.id) \(page.heading)") }
            XCTAssertFalse(card.differences.isEmpty, j.id)
            XCTAssertFalse(card.outfitBullets.isEmpty, j.id)
            said(j.title, "\(j.id) title")
            said(j.subtitle, "\(j.id) subtitle")
        }
    }

    func testTheWordsLeaveNothingBlankAtAnyStop() throws {
        for j in journeys {
            let skin = try XCTUnwrap(Skins.skin(j.id))
            for (name, base) in try states(j) {
                for role in Role.allCases {
                    var g = base
                    g.role = role
                    let w = skin.words(g), at = "\(j.id) \(name) \(role)"
                    XCTAssertEqual(blanks(w), [], at)
                    said(w.distance(0), "\(at) distance")
                    said(w.distance(j.totalMiles), "\(at) distance")
                    for n in j.rules.restChoices { said(w.restChoice(n), "\(at) restChoice \(n)") }
                    XCTAssertEqual(Set(j.rules.restChoices.map(w.restChoice)).count, j.rules.restChoices.count,
                                   "\(at): rest choices read differently")
                    for cost in [0, 1, 250] {
                        said(w.yardHull(cost), "\(at) yardHull")
                        said(w.yardSails(cost), "\(at) yardSails")
                    }
                    said(w.priceNote(30), "\(at) priceNote")
                    said(w.burial("Bo"), "\(at) burial")
                }
            }
        }
    }

    /// A journey short of clothes or long without citrus still says something sensible.
    func testTheWordsSurviveAVoyageGoingBadly() throws {
        for j in journeys {
            let skin = try XCTUnwrap(Skins.skin(j.id))
            var g = fresh(j)
            g.clothes = 0
            g.noCitrus = 99
            g.hull = 0
            g.sails = 0
            g.money = 0
            for i in g.crew.indices.dropFirst() { g.crew[i].hp = 0 }
            XCTAssertEqual(blanks(skin.words(g)), [], j.id)
        }
    }

    /// The rows the shell builds from the journey's items: named, and named apart, since
    /// the lists tell them apart by label.
    func testStoresAreNamedAndToldApart() throws {
        for j in journeys {
            let skin = try XCTUnwrap(Skins.skin(j.id))
            for (name, g) in try states(j) {
                let w = skin.words(g)
                let status = StatusPanel.stores(j, g, w)
                XCTAssertFalse(status.isEmpty, j.id)
                XCTAssertEqual(Set(status.map(\.label)).count, status.count, "\(j.id) \(name)")
                XCTAssertEqual(status.contains { $0.label == (w.statusNames[.fuel] ?? j.item(.fuel).name) }, j.burnsFuel,
                               "\(j.id): a fuel row exactly when the journey burns fuel")
                for r in status {
                    said(r.label, "\(j.id) status label")
                    said(r.value, "\(j.id) status value")
                }
                let rows = SuppliesView.rows(j, g, w)
                XCTAssertEqual(rows.first?.0, w.cash, "\(j.id) \(name): the money comes first")
                XCTAssertEqual(rows.first?.1.hasPrefix(w.currency), true, "\(j.id) \(name): in the journey's currency")
                XCTAssertEqual(Array(rows.dropFirst().map(\.0)), j.items.map { w.storeNames[$0.key] ?? $0.name },
                               "\(j.id) \(name): then everything the journey stocks, in the shop's order")
                XCTAssertEqual(Set(rows.map(\.0)).count, rows.count, "\(j.id) \(name)")
                for r in rows {
                    said(r.0, "\(j.id) supplies label")
                    said(r.1, "\(j.id) supplies value")
                }
                for it in j.items {
                    said(Stores.have(it, g, w), "\(j.id) have \(it.key)")
                    for n in ["0", "1", "2"] { said(Stores.unit(it, count: n, w), "\(j.id) unit of \(n) \(it.key)") }
                    if w.singular { said(it.one, "\(j.id): one \(it.key) is written with its singular") }
                }
            }
            try amountsAreNeverStoredCounts(j)
            for key in [ItemKey.food] + (j.burnsFuel ? [.fuel] : []) {
                said(j.item(key).name, "\(j.id): the journey stocks \(key)")
            }
        }
    }

    /// Something aboard never reads as nothing, and a stored count is never written
    /// beside the name of a unit it isn't in: the smallest amount the lists can show (a
    /// whole unit, or a tenth of one for a thing stored in parts) reads differently from
    /// none, in the supplies list, the status box and the shop.
    func amountsAreNeverStoredCounts(_ j: Journey) throws {
        let skin = try XCTUnwrap(Skins.skin(j.id))
        var none = fresh(j)
        for it in j.items { none[it.key] = 0 }
        let w = skin.words(none)
        let bare = SuppliesView.rows(j, none, w), bareStatus = StatusPanel.stores(j, none, w)
        for (i, it) in j.items.enumerated() {
            let how = Stores.counting(it, w), per = Double(max(1, it.per))
            // One of whatever the item is counted in.
            let least = how.loose != nil ? 1 : how.tenths ? max(1, (per / 10).rounded(.up)) : per
            var some = none
            some[it.key] = least
            XCTAssertEqual(some[it.key], least, "\(j.id) \(it.key): the hold takes \(least)")
            let rows = SuppliesView.rows(j, some, w)
            XCTAssertNotEqual(rows[i + 1].1, bare[i + 1].1, "\(j.id): \(least) of \(it.key) reads as none")
            for (k, r) in rows.enumerated() where k != i + 1 {
                XCTAssertEqual(r.1, bare[k].1, "\(j.id): \(it.key) changed another row")
            }
            let status = StatusPanel.stores(j, some, w)
            let label = w.statusNames[it.key] ?? it.name
            if let k = bareStatus.firstIndex(where: { $0.label == label }) {
                XCTAssertNotEqual(status[k].value, bareStatus[k].value, "\(j.id): \(least) of \(it.key) reads as none")
            }
            // The shop counts what it sells: one bought is one had.
            var bought = none
            bought[it.key] = per
            XCTAssertEqual(Stores.have(it, bought, w), "1", "\(j.id): one \(it.one) bought")
            XCTAssertEqual(Stores.have(it, none, w), "0", j.id)
            // What isn't loose is written in the item's own unit, so a full unit reads "1".
            if how.loose == nil {
                XCTAssertEqual(Stores.count(per, it, how), "1", "\(j.id) \(it.key)")
                XCTAssertTrue(Stores.measure(per, it, how).hasSuffix(" " + Stores.unit(it, count: "1", how)), j.id)
            } else {
                XCTAssertEqual(Stores.count(per, it, how), String(it.per), "\(j.id) \(it.key): counted singly")
            }
        }
    }

    // MARK: Drawings

    func testTheSceneDrawsInEveryWeatherAtEveryStop() throws {
        for j in journeys {
            let scene = try XCTUnwrap(Skins.skin(j.id)).scene
            var frames = [ScenePicture.frame(j, nil, moving: false, t: 0)]  // the title card
            for (_, base) in try states(j) {
                for weather in j.weathers {
                    for moving in [false, true] {
                        var g = base
                        g.weather = weather
                        frames.append(ScenePicture.frame(j, g, moving: moving, t: 0))
                        g.hull = 3
                        g.sails = 3
                        let worn = ScenePicture.frame(j, g, moving: moving, t: 0)
                        // Round the clock, for a journey whose turns are shorter than a day.
                        for hour in [0, 5, 12, 19, 23] {
                            frames.append(SceneFrame(t: 0, weather: worn.weather, moving: moving, atPort: worn.atPort,
                                                     hull: worn.hull, sails: worn.sails, region: worn.region,
                                                     hour: hour, state: g))
                        }
                    }
                }
            }
            let whole = CGRect(x: 0, y: 0, width: SceneSkin.w, height: SceneSkin.h)
            for f in frames {
                for t in [0, 0.37, 5.3, 4321.9] {
                    let px = PixelCanvas(w: SceneSkin.w, h: SceneSkin.h)
                    scene.draw(px, f.at(t))
                    XCTAssertGreaterThan(px.tally.marks, 0, "\(j.id) \(f.weather.name): nothing drawn")
                    XCTAssertTrue(px.tally.bounds?.contains(whole) ?? false,
                                  "\(j.id) \(f.weather.name): the picture leaves part of the canvas bare")
                }
                said(scene.label(f), "\(j.id) scene label in \(f.weather.name)")
            }
        }
    }

    func picture(_ scene: SceneSkin, _ f: SceneFrame, t: Double = 0.37) -> Int {
        let px = PixelCanvas(w: SceneSkin.w, h: SceneSkin.h)
        scene.draw(px, f.at(t))
        return px.tally.picture
    }

    /// The scene is a picture of the voyage, not a fixed card: it shows the weather, and
    /// whether the party is in port or under way. A draw that ignored its frame would
    /// pass every "something was drawn" check there is.
    func testTheSceneShowsTheWeatherAndThePort() throws {
        for j in journeys {
            let scene = try XCTUnwrap(Skins.skin(j.id)).scene
            let all = try states(j)
            let sea = try XCTUnwrap(all.first { $0.name.hasPrefix("nearing") }).state

            // The same frame twice is the same picture, or nothing below means anything.
            XCTAssertEqual(picture(scene, ScenePicture.frame(j, sea, moving: true, t: 0)),
                           picture(scene, ScenePicture.frame(j, sea, moving: true, t: 0)), j.id)

            // Under way, each kind of sky is its own picture.
            var bySky: [Sky: Int] = [:]
            for weather in j.weathers + [j.fairWeather] where bySky[weather.sky] == nil {
                var g = sea
                g.weather = weather
                bySky[weather.sky] = picture(scene, ScenePicture.frame(j, g, moving: true, t: 0))
            }
            XCTAssertGreaterThan(bySky.count, 1, "\(j.id): more than one kind of sky")
            XCTAssertEqual(Set(bySky.values).count, bySky.count, "\(j.id): two kinds of sky draw the same picture")

            // The weather the status box writes in red looks nothing like fair weather.
            let worst = try XCTUnwrap(j.weathers.first { StatusPanel.isWorst($0, of: j) }, "\(j.id): a worst weather")
            var foul = sea, fine = sea
            foul.weather = worst
            fine.weather = j.fairWeather
            XCTAssertNotEqual(picture(scene, ScenePicture.frame(j, foul, moving: true, t: 0)),
                              picture(scene, ScenePicture.frame(j, fine, moving: true, t: 0)), j.id)

            // In port is not the open way.
            var ports = 0
            for (name, g) in all where g.atPort {
                ports += 1
                var away = g
                away.atPort = false
                XCTAssertNotEqual(picture(scene, ScenePicture.frame(j, g, moving: false, t: 0)),
                                  picture(scene, ScenePicture.frame(j, away, moving: false, t: 0)),
                                  "\(j.id) \(name): in port looks the same as under way")
            }
            XCTAssertGreaterThan(ports, 0, "\(j.id): somewhere to put in")
        }
    }

    func testTheChartDrawsAtEveryStop() throws {
        for j in journeys {
            let chart = try XCTUnwrap(Skins.skin(j.id)).chart
            said(chart.title, "\(j.id) chart title")
            XCTAssertGreaterThan(chart.w, 0)
            XCTAssertGreaterThan(chart.h, 0)
            XCTAssertGreaterThan(chart.routeStep, 0)
            XCTAssertGreaterThan(chart.travelledStep, 0)
            for (name, g) in try states(j) {
                let at = "\(j.id) \(name)"
                said(chart.label(g), "\(at) chart label")
                said(chart.footer(g), "\(at) chart footer")
                for route in [chart.route(g)] + chart.others(g) {
                    XCTAssertGreaterThanOrEqual(route.count, 2, at)
                    XCTAssertEqual(route.map(\.mile), route.map(\.mile).sorted(), "\(at): miles only go up")
                }
                let route = chart.route(g)
                XCTAssertEqual(route.first?.mile, 0, at)
                XCTAssertGreaterThanOrEqual(route.last?.mile ?? 0, Double(j.totalMiles), "\(at): the route reaches the end")
                for s in j.stops {
                    let q = ChartView.position(route, atMile: Double(s.mile), chart)
                    XCTAssertTrue((0...chart.w).contains(q.x) && (0...chart.h).contains(q.y), "\(at): \(s.id) is off the chart")
                }
                // The shell's own marks, on a chart with no map under them.
                let bare = ChartSkin(w: chart.w, h: chart.h, title: chart.title, label: chart.label, footer: chart.footer,
                                     background: { _, _, _ in }, route: chart.route, others: chart.others,
                                     project: chart.project, routeStep: chart.routeStep,
                                     travelledStep: chart.travelledStep, routeColor: chart.routeColor,
                                     overlay: { _, _, _ in })
                let whole = CGRect(x: 0, y: 0, width: chart.w, height: chart.h)
                for t in [0, 0.6] {
                    let px = PixelCanvas(w: chart.w, h: chart.h)
                    ChartView.draw(px, chart, j, g, t: t)
                    XCTAssertGreaterThan(px.tally.marks, j.stops.count, at)

                    // The skin's map, on its own: there is one, and it covers the chart.
                    let map = PixelCanvas(w: chart.w, h: chart.h)
                    chart.background(map, g, t)
                    XCTAssertGreaterThan(map.tally.marks, 0, "\(at): no map under the route")
                    XCTAssertTrue(map.tally.bounds?.contains(whole) ?? false, "\(at): the map leaves part of the chart bare")

                    let over = PixelCanvas(w: chart.w, h: chart.h)
                    chart.overlay(over, g, t)
                    let shell = PixelCanvas(w: chart.w, h: chart.h)
                    ChartView.draw(shell, bare, j, g, t: t)
                    XCTAssertGreaterThanOrEqual(shell.tally.marks, j.stops.count + 2, "\(at): a route and every stop")
                    XCTAssertEqual(px.tally.marks, map.tally.marks + shell.tally.marks + over.tally.marks,
                                   "\(at): the chart is the map, the shell's route and stops, and the overlay")
                    XCTAssertNotEqual(px.tally.picture, shell.tally.picture, "\(at): the map shows")
                }
            }
            // The marker moves with the party.
            let all = try states(j)
            let first = try XCTUnwrap(all.first).state, last = try XCTUnwrap(all.last).state
            XCTAssertNotEqual(first.mile, last.mile)
            let a = PixelCanvas(w: chart.w, h: chart.h), b = PixelCanvas(w: chart.w, h: chart.h)
            ChartView.draw(a, chart, j, first, t: 0)
            ChartView.draw(b, chart, j, last, t: 0)
            XCTAssertNotEqual(a.tally.picture, b.tally.picture, "\(j.id): the chart is the same at the start and the end")
        }
    }

    func testTheMiniGameIsPlayableAndDraws() throws {
        for j in journeys {
            let forage = try XCTUnwrap(Skins.skin(j.id)).forage
            let f = forage.field
            XCTAssertEqual(blanks([forage.heading, forage.throwsLabel, forage.caughtLabel, forage.timeLabel,
                                   forage.actionHint, forage.leave]), [], j.id)
            said(forage.label(0), "\(j.id) forage label")
            said(forage.label(4), "\(j.id) forage label")

            XCTAssertFalse(j.quarry.isEmpty, "\(j.id): something to catch")
            XCTAssertGreaterThan(j.forageSeconds, 0)

            // Amounts are the shell's to write, in the unit the catch is stowed in; the
            // skin's sentences only carry them.
            XCTAssertTrue(j.items.contains { $0.key == j.forageReward }, "\(j.id): the catch is something the journey stocks")
            let reward = FishingView.reward(j, try XCTUnwrap(Skins.skin(j.id)).words(fresh(j)))
            XCTAssertEqual(reward.item.key, j.forageReward)
            XCTAssertTrue(forage.hint("#LIMIT#").contains("#LIMIT#"), "\(j.id): the hint says how much can be kept")
            for role in Role.allCases {
                let limit = j.role(role).catchLimit
                XCTAssertGreaterThan(limit, 0, "\(j.id) \(role)")
                XCTAssertNotEqual(reward.measure(limit), reward.measure(0), "\(j.id) \(role): the limit reads as nothing")
                XCTAssertTrue(forage.hint(reward.measure(limit)).contains(reward.measure(limit)), j.id)
            }
            for q in j.quarry {
                XCTAssertTrue(forage.pop("#N#", q).contains("#N#"), "\(j.id): a hit on \(q.name) says what it was worth")
                XCTAssertNotEqual(reward.count(q.lb), reward.count(0), "\(j.id): \(q.name) is worth something and reads as nothing")
                XCTAssertNotEqual(reward.measure(q.lb), reward.measure(0), "\(j.id) \(q.name)")
                said(FishingView.pop(forage, reward)(q), "\(j.id) pop for \(q.name)")
            }

            // The field hangs together: the quarry runs on the far side of the line from
            // the thrower, all of it on the canvas and in reach.
            XCTAssertTrue((0...f.w).contains(f.origin.x) && (0...f.h).contains(f.origin.y), j.id)
            XCTAssertTrue(f.lanes.lowerBound >= 0 && f.lanes.upperBound <= f.h, j.id)
            XCTAssertTrue(f.inReach(f.lanes.lowerBound) && f.inReach(f.lanes.upperBound), "\(j.id): the lanes are in reach")
            XCTAssertEqual(f.upward, f.origin.y > f.lanes.upperBound, "\(j.id): thrown toward the quarry")
            XCTAssertGreaterThan(f.speed, 0)

            for role in Role.allCases {
                var throwsLeft = 8
                let m = FishingModel(field: f, quarry: j.quarry, seconds: j.forageSeconds, padding: j.role(role).aim,
                                     pop: FishingView.pop(forage, reward), random: { 0.5 },
                                     useTackle: {
                                         guard throwsLeft > 0 else { return false }
                                         throwsLeft -= 1
                                         return true
                                     },
                                     tackleLeft: { throwsLeft })
                XCTAssertFalse(m.fish.isEmpty, "\(j.id): quarry on the field at the start")
                for s in m.fish { XCTAssertTrue(f.lanes.contains(s.y0), j.id) }
                // A throw that leads its quarry lands, and the catch is what the quarry
                // is worth: the field, the speeds and the role's aim make a game.
                let target = m.fish[0]
                var aim = (x: target.x, y: target.y)
                for _ in 0..<3 {
                    let flight = hypot(aim.x - f.origin.x, aim.y - f.origin.y) / f.speed
                    aim = (target.x + target.vx * flight, target.y)
                }
                m.throwAt(x: aim.x, y: aim.y)
                let thrown = try XCTUnwrap(m.harpoon, "\(j.id): a tap in the lanes throws")
                XCTAssertEqual(thrown.vy < 0, f.upward, "\(j.id): thrown toward the lanes")
                XCTAssertEqual(throwsLeft, 7)
                for _ in 0..<2000 where m.harpoon != nil { m.step(0.01) }
                XCTAssertEqual(m.caught, target.kind.lb, "\(j.id) \(role): a well-led throw catches what it was thrown at")
                XCTAssertEqual(m.pops.first?.text, FishingView.pop(forage, reward)(target.kind), j.id)
                XCTAssertFalse(m.fish.contains { $0.id == target.id }, "\(j.id): what is caught leaves the field")

                let mid = (f.lanes.lowerBound + f.lanes.upperBound) / 2
                var steps = 0
                while !m.ended && steps < 100_000 {
                    m.step(0.05)
                    if m.harpoon == nil { m.throwAt(x: f.w / 2, y: mid) }
                    if steps % 7 == 0 {
                        let px = PixelCanvas(w: f.w, h: f.h)
                        FishingView.draw(px, forage, m, now: Double(steps) * 0.05)
                        XCTAssertGreaterThan(px.tally.marks, 0, j.id)
                    }
                    steps += 1
                }
                XCTAssertTrue(m.ended, "\(j.id): the outing ends")
                XCTAssertGreaterThanOrEqual(m.caught, target.kind.lb, "\(j.id): a catch is kept to the end")
            }

            // Every kind of quarry and a throw in flight, drawn on their own.
            let px = PixelCanvas(w: f.w, h: f.h)
            forage.backdrop(px, 12.5)
            let afterBackdrop = px.tally.marks
            XCTAssertGreaterThan(afterBackdrop, 0, "\(j.id): a backdrop")
            for q in j.quarry {
                for vx in [-20.0, 20.0] {
                    let before = px.tally.marks
                    forage.quarry(px, FishingModel.Swimmer(kind: q, x: f.w / 2, y0: f.lanes.lowerBound,
                                                           y: f.lanes.lowerBound, vx: vx, t: 0, wf: 1, wa: 1))
                    XCTAssertGreaterThan(px.tally.marks, before, "\(j.id): \(q.name) is drawn")
                }
            }
            let before = px.tally.marks
            forage.thrown(px, FishingModel.Harpoon(x: f.w / 2, y: f.lanes.lowerBound, vx: 10, vy: f.upward ? -f.speed : f.speed))
            XCTAssertGreaterThan(px.tally.marks, before, "\(j.id): the throw is drawn")
        }
    }

    // MARK: Repairs

    /// D15: the repairs screen offers the hull's repair first and the sails' second, in the
    /// order its condition box lists the meters (`Words.meters`, hull then sails). Each row
    /// is told by what it waits for: the hull's by patches, the sails' by sailcloth.
    func testRepairsComeInTheConditionBoxsOrder() throws {
        let p = Persistence(directory: FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString),
                            defaults: UserDefaults(suiteName: UUID().uuidString)!)
        for j in journeys {
            let skin = try XCTUnwrap(Skins.skin(j.id))
            for (timber, sailcloth) in [(0, 2), (2, 0)] {
                var g = skin.debug.start(1, j.departures[0].month)
                g.hull = 50
                g.sails = 50
                g.timber = timber
                g.sailcloth = sailcloth
                let c = GameController(persistence: p, journeys: Journeys.all, skins: Skins.all)
                c.loadForDebug(g)
                let w = skin.words(g)
                let rows = RepairsView.choices(c, w)
                XCTAssertEqual(rows.map(\.label), [w.patch, w.mend, "Done"], j.id)
                XCTAssertEqual(rows.map(\.enabled), [timber > 0, sailcloth > 0, true], "\(j.id): the hull's row first")
            }
        }
    }

    // MARK: Debug starts

    func testDebugStartsAndTheGallery() throws {
        for j in journeys {
            let skin = try XCTUnwrap(Skins.skin(j.id))
            for i in j.stops.indices.dropFirst() {
                for d in j.departures {
                    let g = skin.debug.start(i, d.month)
                    XCTAssertEqual(g.journey, j.id)
                    XCTAssertEqual(g.stopIndex, i - 1, "\(j.id): short of stop \(i)")
                    XCTAssertLessThan(g.mile, j.stops[i].mile)
                    XCTAssertFalse(g.over)
                    XCTAssertFalse(g.atPort)
                }
            }
            for cell in skin.debug.gallery {
                said(cell.name, "\(j.id) gallery cell")
                let g = SceneGallery.state(j, cell.set)
                let px = PixelCanvas(w: SceneSkin.w, h: SceneSkin.h)
                skin.scene.draw(px, ScenePicture.frame(j, g, moving: cell.moving, t: 1))
                XCTAssertGreaterThan(px.tally.marks, 0)
            }
        }
    }
}

// MARK: - A save and a top ten for each journey

final class JourneyFilesTests: XCTestCase {
    var p: Persistence!
    let fm = FileManager.default

    override func setUpWithError() throws {
        p = Persistence(directory: fm.temporaryDirectory.appendingPathComponent(UUID().uuidString),
                        defaults: UserDefaults(suiteName: UUID().uuidString)!)
        try fm.createDirectory(at: p.directory, withIntermediateDirectories: true)
    }

    func voyage(_ journey: String = Horn1849.id, ship: String = "Sea Lark") -> GameState {
        var s = GameState(journey: journey, role: .whaler, ship: ship, captain: "Ira", crew: ["A", "B", "C", "D"],
                          startYear: 1849, startMonth: 0)
        s.day = 40
        return s
    }

    func testFilesAreNamedForTheirJourney() {
        XCTAssertEqual(p.saveURL("rail").lastPathComponent, "save-rail.json")
        XCTAssertEqual(p.topTenURL("rail").lastPathComponent, "topten-rail.json")
        XCTAssertEqual(p.saveURL(Horn1849.id).lastPathComponent, "save-horn1849.json")
        XCTAssertEqual(p.topTenURL(Horn1849.id).lastPathComponent, "topten-horn1849.json")
        XCTAssertEqual(p.legacySaveURL.lastPathComponent, "save.json")
        XCTAssertEqual(p.legacyTopTenURL.lastPathComponent, "topten.json")
    }

    func testEveryJourneySavesToItsOwnFile() {
        for j in Journeys.all {
            let d = j.departures[0]
            let s = GameState(journey: j.id, role: .merchant, ship: "Wren", captain: "Ada", crew: ["B", "C", "D", "E"],
                              startYear: d.year, startMonth: d.month)
            p.save(s)
            XCTAssertTrue(fm.fileExists(atPath: p.saveURL(j.id).path), j.id)
            XCTAssertEqual(p.loadSave(j.id), s)
            XCTAssertNil(p.loadSave("no-such-journey"))
            p.deleteSave(j.id)
            XCTAssertNil(p.loadSave(j.id))
        }
        XCTAssertFalse(fm.fileExists(atPath: p.legacySaveURL.path), "nothing new is written under the old name")
    }

    func testAnOldSaveIsStill1849sAndMovesOnTheNextSave() throws {
        let old = voyage()
        try JSONEncoder().encode(old).write(to: p.legacySaveURL)
        XCTAssertEqual(p.loadSave(Horn1849.id), old, "save.json is read as 1849's")
        XCTAssertNil(p.loadSave("rail"), "and as nobody else's")
        XCTAssertTrue(fm.fileExists(atPath: p.legacySaveURL.path), "reading it leaves it where it was")

        var later = old
        later.day = 41
        p.save(later)
        XCTAssertEqual(p.loadSave(Horn1849.id), later)
        XCTAssertTrue(fm.fileExists(atPath: p.saveURL(Horn1849.id).path))
        XCTAssertFalse(fm.fileExists(atPath: p.legacySaveURL.path), "the voyage now lives in its own file")
    }

    func testTheNewSaveWinsOverAnOldOne() throws {
        try JSONEncoder().encode(voyage(ship: "Old")).write(to: p.legacySaveURL)
        try JSONEncoder().encode(voyage(ship: "New")).write(to: p.saveURL(Horn1849.id))
        XCTAssertEqual(p.loadSave(Horn1849.id)?.ship, "New")
    }

    func testEndingAVoyageClearsTheOldSaveToo() throws {
        try JSONEncoder().encode(voyage()).write(to: p.legacySaveURL)
        p.deleteSave(Horn1849.id)
        XCTAssertNil(p.loadSave(Horn1849.id), "or the title would offer a voyage that has ended")
        XCTAssertFalse(fm.fileExists(atPath: p.legacySaveURL.path))
    }

    func testASaveInAnotherJourneysFileIsNotHandedOut() throws {
        try JSONEncoder().encode(voyage()).write(to: p.saveURL("rail"))
        XCTAssertNil(p.loadSave("rail"), "1849's voyage under another journey's name")
        var stray = voyage()
        stray.journey = "rail"
        try JSONEncoder().encode(stray).write(to: p.saveURL(Horn1849.id))
        XCTAssertNil(p.loadSave(Horn1849.id), "a save says whose it is")
    }

    func testAnOldTopTenIsStill1849sAndIsNeverLost() throws {
        let journey = Journeys.journey(Horn1849.id)
        let old = [TopTenEntry(name: "Gran", score: 4321)]
        try JSONEncoder().encode(old).write(to: p.legacyTopTenURL)
        XCTAssertEqual(p.topTen(journey), old, "topten.json is read as 1849's")

        let next = TopTen.inserting(name: "Ira", score: 9000, into: p.topTen(journey)).table
        p.saveTopTen(next, for: journey.id)
        XCTAssertEqual(p.topTen(journey), next, "the journey's own file is read first")
        XCTAssertTrue(next.contains(TopTenEntry(name: "Gran", score: 4321)), "the old scores carry over")
        let kept = try JSONDecoder().decode([TopTenEntry].self, from: Data(contentsOf: p.legacyTopTenURL))
        XCTAssertEqual(kept, old, "and the old file is left as it was")
    }

    func testTopTensAreKeptApart() {
        let journey = Journeys.journey(Horn1849.id)
        p.saveTopTen([TopTenEntry(name: "Driver", score: 1)], for: "rail")
        XCTAssertEqual(p.topTen(journey), journey.defaultTopTen, "another journey's table is not 1849's")
        XCTAssertTrue(fm.fileExists(atPath: p.topTenURL("rail").path))
    }
}
