import XCTest
@testable import HornEngine

/// What every journey in `Journeys.all` must hold to for the shared rules, the saves and
/// the app's screens to work with it (docs/design/journeys-architecture.md).
final class JourneyContractTests: XCTestCase {
    func testIDsAreUniqueAndTheCardIsFilledIn() {
        XCTAssertEqual(Set(Journeys.all.map(\.id)).count, Journeys.all.count)
        XCTAssertEqual(Journeys.all[0].id, Horn1849.id, "saves with an unknown id fall back to the first")
        for j in Journeys.all {
            XCTAssertFalse(j.title.isEmpty, j.id)
            XCTAssertFalse(j.subtitle.isEmpty, j.id)
            XCTAssertFalse(j.blurb.isEmpty, j.id)
            XCTAssertTrue(Journeys.has(j.id))
            XCTAssertTrue(Journeys.journey(j.id) === j)
        }
    }

    func testStopsRunFromAPortToTheEnd() {
        for j in Journeys.all {
            let stops = j.stops
            XCTAssertGreaterThanOrEqual(stops.count, 3, j.id)
            XCTAssertEqual(stops[0].mile, 0, j.id)
            XCTAssertEqual(stops[0].type, .port, "\(j.id): the journey starts in its first port's shop")
            XCTAssertEqual(stops.last?.type, .end, j.id)
            XCTAssertEqual(stops.filter { $0.type == .end }.count, 1, j.id)
            XCTAssertEqual(Set(stops.map(\.id)).count, stops.count, "\(j.id): stop ids are unique")
            for (a, b) in zip(stops, stops.dropFirst()) {
                XCTAssertLessThan(a.mile, b.mile, "\(j.id): \(a.id) before \(b.id)")
            }
            for s in stops {
                XCTAssertFalse(s.name.isEmpty, "\(j.id) \(s.id)")
                XCTAssertFalse(s.short.isEmpty, "\(j.id) \(s.id)")
            }
        }
    }

    func testEveryPortStopHasAPortAndEveryPortAStop() {
        for j in Journeys.all {
            for s in j.stops where s.type == .port {
                XCTAssertNotNil(j.port(s.id), "\(j.id): no port for stop \(s.id)")
            }
            for p in j.ports {
                XCTAssertEqual(j.stop(p.id)?.type, .port, "\(j.id): port \(p.id) has no port stop")
                XCTAssertEqual(p.journey, j.id, "\(p.id) prices itself from another journey")
                XCTAssertFalse(p.name.isEmpty, p.id)
                XCTAssertFalse(p.shop.isEmpty, p.id)
                XCTAssertFalse(p.talk.isEmpty, "\(j.id) \(p.id): someone to talk to")
                XCTAssertGreaterThan(p.mult, 0, p.id)
                if p.id != j.stops[0].id { XCTAssertFalse(p.arrive.isEmpty, "\(j.id) \(p.id): an arrival paragraph") }
            }
            XCTAssertEqual(Set(j.ports.map(\.id)).count, j.ports.count, j.id)
        }
    }

    func testRegionsCoverTheWholeDistanceWithWeatherTheJourneyKnows() {
        for j in Journeys.all {
            XCTAssertFalse(j.regions.isEmpty, j.id)
            for (a, b) in zip(j.regions, j.regions.dropFirst()) { XCTAssertLessThan(a.to, b.to, "\(j.id) \(a.id.rawValue)") }
            XCTAssertGreaterThanOrEqual(j.regions.last!.to, j.totalMiles, j.id)
            XCTAssertTrue(j.weathers.contains(j.fairWeather), j.id)
            XCTAssertEqual(Set(j.weathers.map(\.rawValue)).count, j.weathers.count, j.id)
            XCTAssertLessThanOrEqual(j.weathers.count, 10, j.id)
            for w in j.weathers { XCTAssertFalse(w.name.isEmpty, "\(j.id) \(w.rawValue)") }
            for r in j.regions {
                XCTAssertFalse(r.name.isEmpty, "\(j.id) \(r.id.rawValue)")
                XCTAssertGreaterThan(r.weights.reduce(0) { $0 + $1.1 }, 0, "\(j.id) \(r.id.rawValue)")
                for (w, weight) in r.weights {
                    XCTAssertTrue(j.weathers.contains(w), "\(j.id) \(r.id.rawValue): \(w.rawValue) is not this journey's weather")
                    XCTAssertGreaterThanOrEqual(weight, 0)
                }
            }
        }
    }

    func testTablesAreComplete() {
        for j in Journeys.all {
            for r in Role.allCases {
                let info = j.roles[r]
                XCTAssertNotNil(info, "\(j.id) \(r)")
                XCTAssertFalse(info?.label.isEmpty ?? true, "\(j.id) \(r)")
                XCTAssertFalse(info?.title.isEmpty ?? true, "\(j.id) \(r)")
                XCTAssertGreaterThan(info?.money ?? 0, 0, "\(j.id) \(r)")
            }
            for p in Pace.allCases {
                XCTAssertFalse(j.paces[p]?.name.isEmpty ?? true, "\(j.id) \(p)")
                XCTAssertGreaterThan(j.paces[p]?.speed ?? 0, 0, "\(j.id) \(p)")
            }
            for r in Rations.allCases {
                XCTAssertFalse(j.rationings[r]?.name.isEmpty ?? true, "\(j.id) \(r)")
                XCTAssertGreaterThan(j.rationings[r]?.amount ?? 0, 0, "\(j.id) \(r)")
            }
            XCTAssertEqual(Set(j.items.map(\.key)).count, j.items.count, "\(j.id): one item per key")
            XCTAssertGreaterThan(j.item(.food).max, 0, "\(j.id): a journey must stock food; leaving needs some")
            for it in j.items {
                XCTAssertFalse(it.name.isEmpty, "\(j.id) \(it.key)")
                XCTAssertFalse(it.unit.isEmpty, "\(j.id) \(it.key)")
                XCTAssertFalse(it.one.isEmpty, "\(j.id) \(it.key)")
                XCTAssertFalse(it.desc.isEmpty, "\(j.id) \(it.key)")
                XCTAssertGreaterThan(it.price, 0, "\(j.id) \(it.key)")
                XCTAssertGreaterThan(it.step, 0, "\(j.id) \(it.key)")
                XCTAssertGreaterThan(it.per, 0, "\(j.id) \(it.key)")
                XCTAssertGreaterThan(it.max, 0, "\(j.id) \(it.key)")
            }
            XCTAssertFalse(j.departures.isEmpty, j.id)
            for d in j.departures { XCTAssertTrue((0...11).contains(d.month), j.id) }
            XCTAssertGreaterThanOrEqual(Set(j.firstNames).count, 12, "\(j.id): five aboard and spares for the name picker")
            XCTAssertEqual(Set(j.firstNames).count, j.firstNames.count, j.id)
            XCTAssertGreaterThanOrEqual(j.vesselNames.count, 6, j.id)
            XCTAssertEqual(j.defaultTopTen.count, 10, j.id)
            XCTAssertEqual(j.defaultTopTen.map(\.score), j.defaultTopTen.map(\.score).sorted(by: >), j.id)
            XCTAssertFalse(j.rules.restChoices.isEmpty, j.id)
            XCTAssertGreaterThan(j.rules.tickHours, 0, j.id)
            XCTAssertEqual(24 % j.rules.tickHours, 0, "\(j.id): turns divide the day evenly")
        }
    }

    func testStocksMatchTheRulesThatUseThem() {
        for j in Journeys.all {
            if j.burnsFuel {
                XCTAssertGreaterThan(j.item(.fuel).max, 0, "\(j.id) burns fuel it can't carry")
                XCTAssertFalse(j.text.outOfFuel.isEmpty, j.id)
                XCTAssertFalse(j.text.lowFuel.isEmpty, j.id)
            }
            if j.deficiency != nil {
                XCTAssertGreaterThan(j.item(.limes).max, 0, "\(j.id) has a deficiency and no preventive")
                XCTAssertFalse(j.text.preventiveGone.isEmpty, j.id)
                XCTAssertFalse(j.text.deficiencyHint.isEmpty, j.id)
            }
            if j.item(.water).max == 0 {
                XCTAssertEqual(j.rules.water, 0, "\(j.id) drinks water it can't carry")
                XCTAssertEqual(j.rules.hotWater, 0, j.id)
            } else {
                XCTAssertFalse(j.text.outOfWater.isEmpty, j.id)
                XCTAssertFalse(j.text.lowWater.isEmpty, j.id)
            }
            if j.item(.tackle).max > 0 {
                XCTAssertFalse(j.quarry.isEmpty, "\(j.id) sells forage gear with nothing to catch")
                XCTAssertGreaterThan(j.item(j.forageReward).max, 0, "\(j.id): the catch has nowhere to go")
                XCTAssertGreaterThan(j.forageSeconds, 0, j.id)
                for r in Role.allCases { XCTAssertGreaterThan(j.role(r).catchLimit, 0, "\(j.id) \(r)") }
            }
            XCTAssertFalse(j.ailments.isEmpty, j.id)
        }
    }

    func testEverySentenceTheRulesSayIsWritten() {
        for j in Journeys.all {
            let t = j.text
            let sample = GameState(journey: j.id, role: .merchant, ship: "Vessel", captain: "Ada",
                                   crew: ["Bo", "Cy", "Di", "Ed"], startYear: j.departures[0].year,
                                   startMonth: j.departures[0].month)
            let lines: [(String, String)] = [
                ("rainCaught", t.rainCaught(20)), ("outOfFood", t.outOfFood), ("lowFood", t.lowFood),
                ("wellAgain", t.wellAgain("Ada")), ("hasAilment", t.hasAilment("Ada", j.ailments[0])),
                ("medsUsed", t.medsUsed(2)), ("causeThirst", t.causeThirst), ("causeStarvation", t.causeStarvation),
                ("causeExhaustion", t.causeExhaustion), ("leaderDied", t.leaderDied("Ada", "thirst")),
                ("leaderDiedBody", t.leaderDiedBody), ("spoiled", t.spoiled(30)), ("hullWarning", t.hullWarning),
                ("sailsWarning", t.sailsWarning), ("wrecked", t.wrecked("Vessel")), ("wreckedBody", t.wreckedBody),
                ("depart", t.depart(sample)), ("noProvisions", t.noProvisions), ("rested", t.rested(2, .fair)),
                ("mended", t.mended(80)), ("patched", t.patched(80)), ("yardHull", t.yardHull),
                ("yardSails", t.yardSails), ("noTradersLeft", t.noTradersLeft), ("nobodyWants", t.nobodyWants),
                ("traderIntro", t.traderIntro), ("noTackle", t.noTackle), ("tooRough", t.tooRough),
                ("catchReport", t.catchReport(50, 40, 40)), ("defaultEpitaph", t.defaultEpitaph),
                ("tradeOffer", t.tradeOffer("x", "y", "z")), ("tradeHave", t.tradeHave("y")),
                ("tradeAccept", t.tradeAccept), ("tradeDecline", t.tradeDecline), ("tradeDone", t.tradeDone),
                ("reached", t.reached(j.stops[1], sample)), ("goAshore", t.goAshore), ("passBy", t.passBy),
                ("wavesGoodbye", t.wavesGoodbye("Bo")), ("scoreSurvivors", t.scoreSurvivors(5, .good)),
                ("scoreCondition", t.scoreCondition), ("scoreProvisions", t.scoreProvisions),
                ("scoreStores", t.scoreStores), ("scoreCash", t.scoreCash),
            ]
            for (name, line) in lines { XCTAssertFalse(line.isEmpty, "\(j.id): text.\(name)") }
            XCTAssertEqual(t.ranks.count, j.rules.rankCuts.count + 1, j.id)
            XCTAssertEqual(j.rules.rankCuts, j.rules.rankCuts.sorted(by: >), j.id)
            XCTAssertEqual(Set(t.ranks).count, t.ranks.count, j.id)
            XCTAssertEqual(j.rank(Int.max), t.ranks.first, j.id)
            XCTAssertEqual(j.rank(0), t.ranks.last, j.id)
            for w in j.weathers where !w.note.isEmpty { XCTAssertFalse(w.note.hasPrefix(" "), "\(j.id) \(w.rawValue)") }
        }
    }

    func testTradeTalkReadsForEveryStockedItem() {
        for j in Journeys.all {
            for it in j.items {
                XCTAssertGreaterThan(j.tradeValue(.item(it.key)), 0, "\(j.id) \(it.key)")
                XCTAssertFalse(j.describe(.item(it.key), Double(it.per)).isEmpty, "\(j.id) \(it.key)")
                XCTAssertGreaterThan(j.roundTrade(.item(it.key), 0.2), 0, "\(j.id) \(it.key): a trade is never for nothing")
            }
            XCTAssertFalse(j.describe(.money, 45).isEmpty, j.id)
        }
    }

    /// Two runs from one seed are the same run, and every run ends.
    func testASeededJourneyIsTheSameTwiceAndEnds() throws {
        for j in Journeys.all {
            for role in Role.allCases {
                for seed in [UInt64(11), 12, 13, 14] {
                    let a = JourneyBot(journey: j, role: role, seed: seed)
                    let b = JourneyBot(journey: j, role: role, seed: seed)
                    let ra = a.play()
                    let rb = b.play()
                    XCTAssertEqual(ra, rb, "\(j.id) \(role) \(seed)")
                    XCTAssertTrue(Self.sameButForCrewIDs(a.e.state, b.e.state), "\(j.id) \(role) \(seed)")
                    XCTAssertEqual(a.transcript, b.transcript, "\(j.id) \(role) \(seed)")
                    XCTAssertNotEqual(ra.ending, "still travelling", "\(j.id) \(role) \(seed)")
                    XCTAssertNotEqual(ra.ending, "never left", "\(j.id) \(role) \(seed): the bot's first shop buys food")
                    XCTAssertTrue(a.e.state.over, "\(j.id) \(role) \(seed)")
                    let s = a.e.state
                    XCTAssertTrue((0...100).contains(s.hull) && (0...100).contains(s.sails), "\(j.id)")
                    for it in j.items {
                        XCTAssertGreaterThanOrEqual(s[it.key], 0, "\(j.id) \(it.key)")
                        XCTAssertLessThanOrEqual(s[it.key], it.cap, "\(j.id) \(it.key) over its cap")
                    }
                    XCTAssertGreaterThanOrEqual(s.money, 0, j.id)
                    for line in a.transcript {
                        XCTAssertFalse(line.isEmpty, "\(j.id): an empty line reached the player")
                        XCTAssertNoThrow(try Self.checkMarkup(line), "\(j.id): \(line)")
                    }
                }
            }
        }
    }

    /// Second options too: the first-enabled bot never sees what the other branch says.
    func testEveryChoiceCanBeAnsweredEitherWay() {
        for j in Journeys.all {
            for seed in [UInt64(21), 22, 23] {
                var asked = 0
                var policy = JourneyBot.Policy()
                policy.decide = { _, c in
                    asked += 1
                    let enabled = c.options.indices.filter { c.options[$0].enabled }
                    XCTAssertFalse(enabled.isEmpty, "\(j.id): a choice with no way out: \(c.prompt)")
                    return enabled.isEmpty ? 0 : enabled[asked % enabled.count]
                }
                let bot = JourneyBot(journey: j, role: .shipwright, seed: seed, policy: policy)
                let r = bot.play()
                XCTAssertNotEqual(r.ending, "still travelling", "\(j.id) \(seed)")
                XCTAssertGreaterThan(asked, 0, j.id)
            }
        }
    }

    func testASaveRoundTripsMidJourney() throws {
        for j in Journeys.all {
            let bot = JourneyBot(journey: j, role: .whaler, seed: 31)
            bot.shop()
            XCTAssertNotNil(bot.e.depart(), j.id)
            for _ in 0..<12 where !bot.e.state.over { _ = bot.process(bot.e.sailDay()) }
            let data = try JSONEncoder().encode(bot.e.state)
            let back = try JSONDecoder().decode(GameState.self, from: data)
            XCTAssertEqual(back, bot.e.state, j.id)
            XCTAssertEqual(back.journey, j.id)
            XCTAssertFalse(back.dateText.isEmpty)
        }
    }

    /// Crew ids are fresh UUIDs on every new game, so two runs never share them.
    static func sameButForCrewIDs(_ a: GameState, _ b: GameState) -> Bool {
        var y = b
        guard a.crew.count == y.crew.count else { return false }
        for i in a.crew.indices { y.crew[i].id = a.crew[i].id }
        return a == y
    }

    /// Tags the app's markup knows, opened and closed in order.
    static func checkMarkup(_ line: String) throws {
        struct Bad: Error { let why: String }
        let known: Set<String> = ["red", "green", "amber", "dim", "teal", "i", "b"]
        var open: [String] = []
        var rest = Substring(line)
        while let start = rest.firstIndex(of: "[") {
            guard let end = rest[start...].firstIndex(of: "]") else { break }
            let tag = String(rest[rest.index(after: start)..<end])
            rest = rest[rest.index(after: end)...]
            if tag.hasPrefix("/") {
                let name = String(tag.dropFirst())
                guard known.contains(name) else { continue }
                guard open.last == name else { throw Bad(why: "[/\(name)] closes nothing") }
                open.removeLast()
            } else if known.contains(tag) {
                open.append(tag)
            }
        }
        if !open.isEmpty { throw Bad(why: "unclosed [\(open.last!)]") }
    }
}
