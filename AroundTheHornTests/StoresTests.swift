import XCTest
@testable import HornEngine
@testable import AroundTheHorn

/// How an amount is written: in the shop, the supplies list, the status box and the
/// mini-game. The engine counts in stored units (a box of tackle is 20 throws, a cord of
/// firewood is 10 of whatever a saw log is worth), and the shell must never print a
/// stored count beside the unit's name.
@MainActor
final class StoresTests: XCTestCase {
    let horn = TestJourneys.horn

    var fresh: GameState {
        GameState(journey: Horn1849.id, role: .merchant, ship: "Wren", captain: "Ada", crew: ["Bo", "Cy", "Di", "Ed"],
                  startYear: 1849, startMonth: 0)
    }

    var words: Words { Horn1849Skin.skin.words(fresh) }

    // MARK: 1849 reads as it always did

    func test1849CountsOnlyCitrusInTenthsAndOnlyTackleLoose() {
        for it in horn.items {
            let how = Stores.counting(it, words)
            XCTAssertEqual(how.tenths, it.key == .limes, "\(it.key)")
            XCTAssertEqual(how.loose, it.key == .tackle ? "throws" : nil, "\(it.key)")
            XCTAssertFalse(how.singular, "1849 writes \"1 crates\", as its prototype did")
        }
    }

    func test1849sAmountsAreWrittenAsBefore() {
        var g = fresh
        g.food = 1500
        g.water = 800.9
        g.limes = 9.57
        g.meds = 1
        g.clothes = 5
        g.sailcloth = 4
        g.timber = 0
        g.tackle = 60
        let w = Horn1849Skin.skin.words(g)
        func amount(_ k: ItemKey) -> String { Stores.amount(horn.item(k), g, w) }
        XCTAssertEqual(amount(.food), "1,500 lbs")
        XCTAssertEqual(amount(.water), "800 gal")
        XCTAssertEqual(amount(.limes), "9.5 crates")
        XCTAssertEqual(amount(.meds), "1 kits")
        XCTAssertEqual(amount(.clothes), "5 sets")
        XCTAssertEqual(amount(.sailcloth), "4 bolts")
        XCTAssertEqual(amount(.timber), "0 bundles")
        XCTAssertEqual(amount(.tackle), "60 throws")

        func have(_ k: ItemKey) -> String { Stores.have(horn.item(k), g, w) }
        XCTAssertEqual(have(.food), "1500", "the shop writes no commas")
        XCTAssertEqual(have(.water), "800")
        XCTAssertEqual(have(.limes), "9.5")
        XCTAssertEqual(have(.meds), "1")
        XCTAssertEqual(have(.tackle), "3", "boxes")
        g.tackle = 50
        XCTAssertEqual(have(.tackle), "2")
        g.tackle = 19
        XCTAssertEqual(have(.tackle), "0")
        g.limes = 1
        XCTAssertEqual(amount(.limes), "1 crates")
        XCTAssertEqual(have(.limes), "1")
        g.limes = 0.04
        XCTAssertEqual(amount(.limes), "0 crates")
        g.food = 1_234_567.8
        XCTAssertEqual(amount(.food), "1,234,567 lbs")

        for it in horn.items {
            for n in ["0", "1", "2", "9.5"] { XCTAssertEqual(Stores.unit(it, count: n, w), it.unit, "\(it.key) \(n)") }
        }
    }

    /// The same sums as the build before the skins made, digit for digit.
    func test1849sAmountsMatchTheOldSums() {
        func oldTenths(_ v: Double) -> String {
            let x = (v * 10).rounded(.down) / 10
            return x == x.rounded() ? String(Int(x)) : String(x)
        }
        var g = fresh
        let w = words
        for stock in [0, 0.04, 0.1, 0.95, 1, 1.05, 7.77, 19, 20, 59.999, 60, 999, 1000, 2999.5] {
            for it in horn.items {
                g[it.key] = stock
                let v = g[it.key]
                let amount: String, have: String
                switch it.key {
                case .tackle:
                    amount = "\(Int(v)) throws"
                    have = String(Int((v / 20).rounded(.down)))
                case .limes:
                    amount = "\(oldTenths(v)) crates"
                    have = oldTenths(v)
                default:
                    amount = "\(formatNumber(v)) \(it.unit)"
                    have = String(Int(v.rounded(.down)))
                }
                XCTAssertEqual(Stores.amount(it, g, w), amount, "\(it.key) \(stock)")
                XCTAssertEqual(Stores.have(it, g, w), have, "\(it.key) \(stock)")
            }
        }
    }

    func test1849sCatchIsWrittenAsBefore() {
        let skin = Horn1849Forage.skin
        let reward = FishingView.reward(horn, words)
        XCTAssertEqual(reward.item.key, .food)
        XCTAssertEqual("\(skin.caughtLabel): \(reward.measure(0))", "Caught: 0 lbs")
        XCTAssertEqual("\(skin.caughtLabel): \(reward.measure(12))", "Caught: 12 lbs")
        XCTAssertEqual("\(skin.caughtLabel): \(reward.measure(1))", "Caught: 1 lbs")
        XCTAssertEqual("\(skin.caughtLabel): \(reward.measure(1240))", "Caught: 1240 lbs", "the tally writes no commas")
        for r in Role.allCases {
            let limit = horn.role(r).catchLimit
            XCTAssertEqual(skin.hint(reward.measure(limit)),
                           "Tap the water to throw a harpoon. Each throw uses tackle. You can salt and keep up to \(limit) lbs.")
        }
        XCTAssertFalse(horn.quarry.isEmpty)
        for f in horn.quarry { XCTAssertEqual(skin.pop(reward.count(f.lb), f), "+\(f.lb) lb \(f.name)") }
    }

    // MARK: A journey that stores a thing in parts of its unit

    func testAThingStoredInPartsOfItsUnitIsCountedInTenths() {
        let wood = TestJourneys.firewood
        let how = Stores.counting(wood, words)
        XCTAssertEqual(how, Stores.Counting(loose: nil, tenths: true, singular: false),
                       "ten to the cord and not counted loose: nobody had to list it")
        XCTAssertEqual(Stores.measure(14, wood, how), "1.4 cords", "never \"14 cords\"")
        XCTAssertEqual(Stores.measure(9, wood, how), "0.9 cords", "less than a cord is still something aboard")
        XCTAssertEqual(Stores.measure(1, wood, how), "0.1 cords")
        XCTAssertEqual(Stores.measure(0, wood, how), "0 cords")
        XCTAssertEqual(Stores.measure(23, wood, how), "2.3 cords")
        XCTAssertEqual(Stores.measure(23.9, wood, how), "2.3 cords", "rounded down, never up to what isn't there")
        XCTAssertEqual(Stores.measure(400, wood, how), "40 cords")
        XCTAssertEqual(Stores.count(14, wood, how), "1.4")
        XCTAssertEqual(Stores.have(14, wood, how), "1.4", "the shop agrees with the lists")
        XCTAssertEqual(Stores.have(9, wood, how), "0.9")
    }

    func testExactlyOneTakesTheSingularOnlyWhereTheSkinAsks() {
        let wood = TestJourneys.firewood
        let plural = Stores.Counting(tenths: true)
        let singular = Stores.Counting(tenths: true, singular: true)
        XCTAssertEqual(Stores.measure(10, wood, plural), "1 cords")
        XCTAssertEqual(Stores.measure(10, wood, singular), "1 cord")
        XCTAssertEqual(Stores.measure(11, wood, singular), "1.1 cords")
        XCTAssertEqual(Stores.measure(1, wood, singular), "0.1 cords")
        XCTAssertEqual(Stores.measure(100, wood, singular), "10 cords")
        XCTAssertEqual(Stores.measure(0, wood, singular), "0 cords")
        XCTAssertEqual(Stores.unit(wood, count: "1", singular), "cord")
        XCTAssertEqual(Stores.unit(wood, count: "1", plural), "cords")
        XCTAssertEqual(Stores.unit(wood, count: "1,000", singular), "cords")

        let whole = Item(key: .meds, name: "Medicine", unit: "kits", one: "kit", step: 1, per: 1, price: 1, max: 9, desc: "")
        XCTAssertEqual(Stores.measure(1, whole, Stores.Counting(singular: true), grouped: true), "1 kit")
        XCTAssertEqual(Stores.measure(1000, whole, Stores.Counting(singular: true), grouped: true), "1,000 kits")
        XCTAssertEqual(Stores.measure(1, whole, Stores.Counting(loose: "doses", singular: true)), "1 doses",
                       "what is counted loose is written as the skin wrote it")
    }

    /// The review's case: a saw log worth 14 stored units is 1.4 cords, and a limit of 40
    /// is 4 cords.
    func testACatchOfFirewoodIsWrittenInCords() {
        let rail = TestJourneys.woodBurner()
        let skin = Horn1849Forage.skin  // any skin: the amounts are the shell's
        let reward = FishingView.reward(rail, words)
        XCTAssertEqual(reward.item.key, .fuel)
        XCTAssertEqual("\(skin.caughtLabel): \(reward.measure(14))", "Caught: 1.4 cords")
        XCTAssertEqual(reward.measure(0), "0 cords")
        XCTAssertEqual(reward.measure(2), "0.2 cords")
        XCTAssertEqual(reward.count(14), "1.4")
        XCTAssertEqual(reward.measure(rail.role(.merchant).catchLimit), "4 cords")
        XCTAssertEqual(reward.measure(rail.role(.whaler).catchLimit), "6 cords")
        XCTAssertTrue(skin.hint(reward.measure(40)).hasSuffix("keep up to 4 cords."))
        let log = rail.quarry[3]
        XCTAssertEqual(log.lb, 14)
        XCTAssertTrue(skin.pop(reward.count(log.lb), log).hasPrefix("+1.4 "))
    }

    /// What floats up from a hit goes through the same sum as the tally.
    func testAHitFloatsUpTheSameAmountTheTallyGains() throws {
        let rail = TestJourneys.woodBurner()
        let skin = Horn1849Forage.skin
        let reward = FishingView.reward(rail, words)
        XCTAssertEqual(rail.quarry.map(FishingView.pop(skin, reward)),
                       ["+0.2 lb log 2", "+0.4 lb log 4", "+0.8 lb log 8", "+1.4 lb log 14", "+2.5 lb log 25"])

        let f = skin.field
        let m = FishingModel(field: f, quarry: rail.quarry, seconds: rail.forageSeconds, padding: 4,
                             pop: FishingView.pop(skin, reward), random: { 0.5 }, useTackle: { true }, tackleLeft: { 9 })
        let target = try XCTUnwrap(m.fish.first)
        var aim = (x: target.x, y: target.y)
        for _ in 0..<3 {
            let flight = hypot(aim.x - f.origin.x, aim.y - f.origin.y) / f.speed
            aim = (target.x + target.vx * flight, target.y)
        }
        m.throwAt(x: aim.x, y: aim.y)
        for _ in 0..<400 where m.harpoon != nil { m.step(0.01) }
        XCTAssertEqual(m.caught, target.kind.lb)
        XCTAssertEqual(m.pops.first?.text, "+\(reward.count(m.caught)) lb \(target.kind.name)")
        XCTAssertEqual(reward.measure(m.caught), "0.8 cords", "eight tenths of a cord, never \"8 cords\"")
    }

    // MARK: The weather that reads in red

    func testIn1849OnlyTheStormReadsRedAsBefore() {
        for w in horn.weathers + [horn.fairWeather] {
            XCTAssertEqual(StatusPanel.isWorst(w, of: horn), w.sky == .storm, w.name)
        }
        XCTAssertEqual(horn.weathers.filter { StatusPanel.isWorst($0, of: horn) }.map(\.name), ["STORM"])
    }

    func testTheWorstWeatherReadsRedWhateverItsSky() {
        let rail = TestJourneys.woodBurner()
        XCTAssertTrue(StatusPanel.isWorst(TestJourneys.blizzard, of: rail), "a blizzard has a snowy sky and is the worst there is")
        XCTAssertFalse(StatusPanel.isWorst(TestJourneys.snow, of: rail))
        XCTAssertFalse(StatusPanel.isWorst(TestJourneys.thunderstorm, of: rail), "stormy to look at, but not the worst")
        XCTAssertFalse(StatusPanel.isWorst(rail.fairWeather, of: rail))

        let calm = TestJourneys.copy(id: "test-calm") { $0.weathers = [$0.fairWeather] }
        XCTAssertFalse(StatusPanel.isWorst(calm.fairWeather, of: calm), "nothing to fear, nothing in red")
    }
}
