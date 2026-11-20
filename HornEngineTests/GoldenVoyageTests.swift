import XCTest
@testable import HornEngine

/// Three hundred seeded 1849 voyages, each folded into one hash: the state before every
/// sailing day (every Double bit for bit), every message, choice, burial and score line the
/// engine produced, and how many random numbers it had drawn by then.
///
/// `PrototypeParityTests` proves sixteen voyages match the web prototype. This proves the
/// engine still does today what it did when the fixture was recorded, over far more ground:
/// a third of the bots play carefully, a third carelessly and a third at random — changing
/// pace and rations, resting, fishing, trading, talking, using the yard, filling a cart with
/// whatever fits. A change to any rule, number, draw order or sentence of 1849 fails it.
///
/// The fixture was recorded before the engine learned other journeys (docs/decisions.md D9).
/// Re-record it only when 1849 itself is meant to change, which needs the owner's say-so:
///   HORN_RECORD_GOLDEN=1 swift test --disable-sandbox --filter GoldenVoyageTests
/// To see where a voyage diverges, write its full trace from the old and the new code and
/// diff them:
///   HORN_GOLDEN_DUMP=whaler-17 swift test --disable-sandbox --filter GoldenVoyageTests
final class GoldenVoyageTests: XCTestCase {
    struct Golden: Equatable {
        let name: String
        let ending: String
        let ticks: Int
        let draws: Int
        let hash: String

        var line: String { "\(name) \(ending) \(ticks) \(draws) \(hash)" }

        init(name: String, ending: String, ticks: Int, draws: Int, hash: String) {
            self.name = name
            self.ending = ending
            self.ticks = ticks
            self.draws = draws
            self.hash = hash
        }

        init?(line: Substring) {
            let p = line.split(separator: " ")
            guard p.count == 5, let t = Int(p[2]), let d = Int(p[3]) else { return nil }
            self.init(name: String(p[0]), ending: String(p[1]), ticks: t, draws: d, hash: String(p[4]))
        }
    }

    static let fixtureURL = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        .appendingPathComponent("Fixtures/golden-voyages.txt")

    static let voyagesPerRole = 100

    static func playAll() -> [Golden] {
        let env = ProcessInfo.processInfo.environment
        var out: [Golden] = []
        for (r, role) in [Role.merchant, .shipwright, .whaler].enumerated() {
            for i in 0..<voyagesPerRole {
                let name = "\(role.rawValue)-\(i)"
                let bot = GoldenBot(name: name, role: role, seed: UInt64(50_000 + r * 1000 + i),
                                    wild: [0, 0.35, 1][i % 3])
                if env["HORN_GOLDEN_DUMP"] == name { bot.dump = [] }
                out.append(bot.play())
                if let d = bot.dump {
                    let url = FileManager.default.temporaryDirectory.appendingPathComponent("golden-\(name).txt")
                    try? d.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
                    print("GOLDEN DUMP \(url.path)")
                }
            }
        }
        return out
    }

    func testEveryGoldenVoyageIsUnchanged() throws {
        let now = Self.playAll()
        if ProcessInfo.processInfo.environment["HORN_RECORD_GOLDEN"] == "1" {
            try (now.map(\.line).joined(separator: "\n") + "\n")
                .write(to: Self.fixtureURL, atomically: true, encoding: .utf8)
            print("GOLDEN recorded \(now.count) voyages")
            return
        }
        let want = try String(contentsOf: Self.fixtureURL, encoding: .utf8)
            .split(separator: "\n").compactMap(Golden.init(line:))
        XCTAssertEqual(want.count, 3 * Self.voyagesPerRole, "the fixture is short")
        XCTAssertEqual(now.count, want.count)
        let changed = zip(now, want).filter { $0 != $1 }
        XCTAssertTrue(changed.isEmpty,
                      "\(changed.count) of \(want.count) golden voyages changed. First:\n  now      "
                          + (changed.first?.0.line ?? "") + "\n  recorded " + (changed.first?.1.line ?? ""))
        // The sample has to keep covering both endings and long voyages, or it guards little.
        XCTAssertGreaterThan(want.filter { $0.ending == "finale" }.count, 60)
        XCTAssertGreaterThan(want.filter { $0.ending == "gameover" }.count, 60)
    }

    func testAVoyageReplaysIdentically() {
        let a = GoldenBot(name: "x", role: .shipwright, seed: 4242, wild: 1).play()
        let b = GoldenBot(name: "x", role: .shipwright, seed: 4242, wild: 1).play()
        XCTAssertEqual(a, b)
        XCTAssertGreaterThan(a.draws, 0)
    }
}

/// Counts the draws the engine makes, so a draw that moves, appears or vanishes shows up
/// even when the state it produced happens to match.
struct CountingRNG: RandomSource {
    var base: SeededRNG
    private(set) var draws = 0

    init(seed: UInt64) { base = SeededRNG(seed: seed) }

    mutating func nextUnit() -> Double {
        draws += 1
        return base.nextUnit()
    }
}

/// Plays one voyage and hashes everything it sees. Its own decisions come from `d`, a
/// second generator, so they never move the engine's draws.
final class GoldenBot {
    let name: String
    let e: GameEngine
    var d: SeededRNG
    /// 0 plays carefully, 1 does anything the menus allow.
    let wild: Double
    var hash: UInt64 = 0xcbf2_9ce4_8422_2325
    var ticks = 0
    var rested = Set<Int>()
    var dump: [String]?

    /// What the careful bots buy at every port, up to these stored amounts.
    static let shopping: [(ItemKey, Double)] = [(.food, 1500), (.water, 600), (.limes, 10), (.clothes, 5),
                                                (.meds, 3), (.sailcloth, 3), (.timber, 3), (.tackle, 40)]

    enum Route { case resume, port, over(String) }

    init(name: String, role: Role, seed: UInt64, wild: Double) {
        self.name = name
        self.wild = wild
        d = SeededRNG(seed: seed &* 0x9E37_79B9_7F4A_7C15 &+ 7)
        let dep = GameData.departures[Int(seed % UInt64(GameData.departures.count))]
        let s = GameState(role: role, ship: "Resolute", captain: "Ezra",
                          crew: ["Hannah", "Silas", "Mercy", "Tobias"], startYear: dep.year, startMonth: dep.month)
        e = GameEngine(state: s, rng: CountingRNG(seed: seed))
    }

    var draws: Int { (e.rng as! CountingRNG).draws }

    // MARK: Hashing

    func mix(_ s: String) {
        for b in s.utf8 { hash = (hash ^ UInt64(b)) &* 0x0000_0100_0000_01b3 }
        hash = (hash ^ 0x0a) &* 0x0000_0100_0000_01b3
        dump?.append(s)
    }

    func bits(_ x: Double) -> String { String(x.bitPattern, radix: 16) }

    func mixState() {
        let s = e.state
        mix("S|\(s.day)|\(s.mile)|\(bits(s.money))|\(bits(s.food))|\(bits(s.water))|\(bits(s.limes))|\(s.meds)|\(s.clothes)"
            + "|\(s.sailcloth)|\(s.timber)|\(s.tackle)|\(bits(s.hull))|\(bits(s.sails))|\(s.weather.rawValue)|\(s.stopIndex)"
            + "|\(s.passage?.rawValue ?? "-")|\(s.pilot)|\(s.noCitrus)|\(s.badLuck)|\(s.forceFair)|\(s.tradesLeft)"
            + "|\(s.talkIndex)|\(s.atPort)|\(s.over)|\(s.note)|\(s.albatrossSeen)|\(s.stowawaySeen)|\(s.starving)"
            + "|\(s.thirst)|\(s.pace.rawValue)|\(s.rations.rawValue)|\(s.dateText)|draws \(draws)")
        mix("W|\(s.flags.food)|\(s.flags.lowFood)|\(s.flags.water)|\(s.flags.lowWater)|\(s.flags.limes)|\(s.flags.hull)|\(s.flags.sails)")
        for c in s.crew {
            mix("C|\(c.name)|\(bits(c.hp))|\(c.ailment?.rawValue ?? "-")|\(bits(c.ailDays))|\(c.treated)|\(c.alive)"
                + "|\(c.isCaptain)|\(c.leaveAt ?? "-")")
        }
        for g in s.graves { mix("G|\(g.name)|\(g.cause)|\(g.date)|\(g.epitaph)") }
    }

    // MARK: The voyage

    func play() -> GoldenVoyageTests.Golden {
        var ending = "limit"
        shop()
        if e.state.food <= 0 {
            // A random cart can leave with no food; the chandler turns that away.
            XCTAssertNil(e.departNewYork())
            mix("N|" + GameEngine.noProvisionsRefusal)
            e.buy([.food: min(e.room(for: .food), 4)])
        }
        mix("D|" + (e.departNewYork() ?? "refused"))
        if !e.state.atPort {
            loop: for _ in 0..<3000 {
                mixState()
                if case .over(let o) = seaTurn() { ending = o; break loop }
                ticks += 1
                switch process(e.sailDay()) {
                case .resume: continue
                case .port:
                    if case .over(let o) = portVisit() { ending = o; break loop }
                case .over(let o):
                    ending = o
                    break loop
                }
            }
        } else {
            ending = "never-sailed"
        }
        mixState()
        return .init(name: name, ending: ending, ticks: ticks, draws: draws, hash: String(hash, radix: 16))
    }

    /// Before each day's sailing.
    func seaTurn() -> Route {
        if wild > 0 {
            if d.chance(0.05 * wild) { e.state.pace = [.easy, .steady, .full][d.int(0, 2)] }
            if d.chance(0.05 * wild) { e.state.rations = [.filling, .meager, .bare][d.int(0, 2)] }
            if d.chance(0.04 * wild), case .over(let o) = process(e.rest(days: d.int(1, 3))) { return .over(o) }
            if d.chance(0.06 * wild) {
                if let no = e.fishingRefusal {
                    mix("N|" + no)
                } else {
                    for _ in 0..<d.int(1, 12) { mix("H|\(e.throwHarpoon())") }
                    if case .over(let o) = process(e.landCatch(d.int(0, 420))) { return .over(o) }
                }
            }
        }
        for _ in 0..<6 {
            let s = e.state
            let q: [Interrupt]
            if e.canMendSails && (s.sails < 45 || d.chance(0.03 * wild)) { q = e.mendSails() }
            else if e.canPatchHull && (s.hull < 45 || d.chance(0.03 * wild)) { q = e.patchHull() }
            else { break }
            if case .over(let o) = process(q) { return .over(o) }
        }
        if wild == 0 && e.state.averageHP < 50 && !rested.contains(e.state.stopIndex) {
            rested.insert(e.state.stopIndex)
            if case .over(let o) = process(e.rest(days: 3)) { return .over(o) }
        }
        e.setSail()
        return .resume
    }

    func portVisit() -> Route {
        if d.chance(0.6), case .over(let o) = process(e.rest(days: d.int(1, 3))) { return .over(o) }
        // Up to five asks, so the fourth and fifth meet "nobody else wants to trade".
        for _ in 0..<d.int(0, 5) {
            if case .over(let o) = process(e.tradeAtPort()) { return .over(o) }
        }
        for _ in 0..<d.int(0, 4) { mix("T|" + e.talk()) }
        mix("Y|\(e.shipyardHullCost)|\(e.shipyardSailsCost)|\(e.canRepairHullAtYard)|\(e.canRecutSailsAtYard)")
        if e.canRepairHullAtYard && d.chance(0.7), case .over(let o) = process(e.repairHullAtYard()) { return .over(o) }
        if e.canRecutSailsAtYard && d.chance(0.7), case .over(let o) = process(e.recutSailsAtYard()) { return .over(o) }
        shop()
        e.setSail()
        return .resume
    }

    func shop() {
        guard let port = e.currentPort else { return }
        var cart: [ItemKey: Int] = [:]
        var total = 0.0
        if wild >= 1 {
            for it in GameData.items {
                let price = port.price(it.key)
                let afford = Int(((e.state.money - total) / price).rounded(.down))
                let most = max(0, min(e.room(for: it.key), afford)) / it.step
                let n = most > 0 ? d.int(0, most) * it.step : 0
                cart[it.key] = n
                total += Double(n) * price
            }
        } else {
            for (k, target) in Self.shopping {
                let it = GameData.item(k)
                var n = min(e.room(for: k),
                            max(0, Int(((target - e.state[k]) / Double(it.per) / Double(it.step)).rounded(.up)) * it.step))
                let price = port.price(k)
                while n > 0 && total + Double(n) * price > e.state.money { n -= it.step }
                n = max(0, n)
                cart[k] = n
                total += Double(n) * price
            }
        }
        mix("K|" + GameData.items.map { "\($0.key.rawValue)=\(cart[$0.key] ?? 0)@\(bits(port.price($0.key)))" }
            .joined(separator: ","))
        mix("K|\(bits(GameEngine.bill(cart, at: port)))|\(e.buy(cart))")
    }

    // MARK: Interrupts

    func process(_ initial: [Interrupt]) -> Route {
        var q = initial
        var asked = 0
        while !q.isEmpty {
            switch q.removeFirst() {
            case .message(let t):
                mix("M|" + t)
            case .choice(let c):
                mix("Q|\(c.prompt)|\(c.detail ?? "-")|" + c.options.map { "\($0.label):\($0.enabled)" }.joined(separator: "/"))
                let open = c.options.indices.filter { c.options[$0].enabled }
                asked += 1
                // Careful bots take the first option; a fork is a coin toss for every bot.
                // After forty questions in one queue, stop asking the mate for advice.
                var i = open[d.int(0, open.count - 1)]
                if case .fork = c.kind { i = d.int(0, asked > 40 ? 1 : 2) } else if wild == 0 || asked > 40 { i = open[0] }
                mix("A|\(i)")
                q = e.resolve(c, option: i) + q
            case .burial(let id, let cause):
                let who = e.state.crew.first { $0.id == id }?.name ?? "?"
                mix("B|\(who)|\(cause)")
                e.commitBurial(crewID: id, cause: cause, epitaph: d.chance(0.5) ? "" : "Rest easy, \(who).")
            case .arrival(let id):
                mix("R|" + id)
                q = e.beginArrival(id) + q
            case .enterPort:
                mix("P")
                return .port
            case .gameOver(let title, let body):
                mix("X|\(title)|\(body)")
                return .over("gameover")
            case .finale:
                let sc = e.finish()
                mix("F|" + sc.lines.map { "\($0.label)=\($0.points)" }.joined(separator: "/")
                    + "|\(sc.subtotal)|\(sc.multiplier)|\(sc.total)")
                return .over("finale")
            }
        }
        return .resume
    }
}
