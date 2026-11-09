import XCTest
@testable import HornEngine

/// The prototype is the reference implementation (spec §0). `Tools/prototype-diff`
/// runs it headless with the engine's SplitMix64 in place of Math.random and records the
/// state before every sailing day of sixteen voyages; this replays each one through
/// HornEngine with the same seed and the same decisions, and requires the SAME state —
/// exactly, not approximately — every day, the same choices offered in the same order,
/// and the same ending.
///
/// The decision policy below must stay identical to the driver in `trace.mjs`. If the
/// prototype changes, regenerate the fixture:
///   node Tools/prototype-diff/trace.mjs > HornEngineTests/Fixtures/prototype-traces.json
final class PrototypeParityTests: XCTestCase {
    struct Voyage: Decodable {
        let name: String
        let seed: UInt64
        let role: String
        let year: Int
        let month: Int
        let policy: String
        let fork: String
        let ship: String
        let names: [String]
        let supplies: [String: Double]
        let outcome: String
        let picks: [String]
        let snaps: [Snap]
    }

    struct Snap: Decodable, Equatable {
        struct Crew: Decodable, Equatable {
            let name: String
            let hp: Double
            let ail: String?
            let ailDays: Double
            let treated: Bool
            let alive: Bool
            let leave: String?
        }

        let day: Int, mile: Int
        let money: Double, food: Double, water: Double, limes: Double
        let meds: Int, clothes: Int, sailcloth: Int, timber: Int, tackle: Int
        let hull: Double, sails: Double
        let weather: String
        let stopIdx: Int
        let passage: String?
        let pilot: Bool
        let noCitrus: Int, badLuck: Int, forceFair: Int, tradesLeft: Int, talkIdx: Int
        let atPort: Bool, albatross: Bool, stowaway: Bool, starving: Bool, thirst: Bool
        let flags: [Bool]
        let crew: [Crew]
        let graves: [String]
    }

    /// What the driver buys at every port, in order, up to these stored amounts.
    /// Must match `SHOPPING` in trace.mjs.
    static let shopping: [(ItemKey, Double)] = [(.food, 1500), (.water, 600), (.limes, 10), (.clothes, 5),
                                                (.meds, 3), (.sailcloth, 3), (.timber, 3)]

    static func loadVoyages() throws -> [Voyage] {
        let url = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .appendingPathComponent("Fixtures/prototype-traces.json")
        return try JSONDecoder().decode([Voyage].self, from: Data(contentsOf: url))
    }

    func testEveryVoyageMatchesThePrototypeDayByDay() throws {
        let voyages = try Self.loadVoyages()
        XCTAssertEqual(voyages.count, 16)
        XCTAssertTrue(voyages.contains { $0.outcome == "finale" }, "no trace reaches San Francisco")
        XCTAssertTrue(voyages.contains { $0.outcome == "gameover" }, "no trace ends in disaster")
        for v in voyages {
            let r = Replay(v).run()
            XCTAssertEqual(r.outcome, v.outcome, "\(v.name): ending")
            XCTAssertEqual(r.picks, v.picks, "\(v.name): choices offered and taken")
            XCTAssertEqual(r.snaps.count, v.snaps.count, "\(v.name): number of sailing days")
            if let i = r.snaps.indices.first(where: { $0 < v.snaps.count && r.snaps[$0] != v.snaps[$0] }) {
                XCTFail("\(v.name): first divergence at snapshot \(i) (day \(v.snaps[i].day)):\n"
                        + Self.diff(r.snaps[i], v.snaps[i]))
            }
        }
    }

    static func diff(_ a: Snap, _ b: Snap) -> String {
        let ma = Mirror(reflecting: a).children, mb = Mirror(reflecting: b).children
        return zip(ma, mb).compactMap { x, y in
            "\(x.value)" == "\(y.value)" ? nil : "  \(x.label!): swift \(x.value)  prototype \(y.value)"
        }.joined(separator: "\n")
    }

    /// The trace driver, in Swift: the same decisions, made through the engine's API.
    final class Replay {
        let v: Voyage
        let e: GameEngine
        var picks: [String] = []
        var snaps: [Snap] = []
        var restedAtSea = Set<Int>()
        var askedMate = false

        enum Route { case resume, port, over(String) }

        init(_ v: Voyage) {
            self.v = v
            var s = GameState(role: Role(rawValue: v.role)!, ship: v.ship, captain: v.names[0],
                              crew: Array(v.names.dropFirst()), startYear: v.year, startMonth: v.month)
            for (k, n) in v.supplies {
                if k == "money" { s.money = n } else { s[ItemKey(rawValue: k)!] = n }
            }
            e = GameEngine(state: s, rng: SeededRNG(seed: v.seed))
        }

        var needRepair: Bool {
            let s = e.state
            return (s.sails < 45 && s.sailcloth > 0) || (s.hull < 45 && s.timber > 0)
        }

        var wantSeaRest: Bool { e.state.averageHP < 50 && !restedAtSea.contains(e.state.stopIndex) }

        func run() -> (outcome: String, picks: [String], snaps: [Snap]) {
            e.setSail()
            var outcome = "limit"
            loop: for _ in 0..<5000 {
                if v.policy != "second" && (needRepair || wantSeaRest) {
                    if case .over(let o) = seaMenu() { outcome = o; break loop }
                    continue
                }
                snaps.append(snapshot())
                switch process(e.sailDay()) {
                case .resume: continue
                case .port:
                    if case .over(let o) = portVisit() { outcome = o; break loop }
                case .over(let o):
                    outcome = o
                    break loop
                }
            }
            snaps.append(snapshot())
            return (outcome, picks, snaps)
        }

        func process(_ initial: [Interrupt]) -> Route {
            var q = initial
            while !q.isEmpty {
                switch q.removeFirst() {
                case .message: break
                case .choice(let c): q = e.resolve(c, option: pick(c)) + q
                case .burial(let id, let cause): e.commitBurial(crewID: id, cause: cause, epitaph: "")
                case .arrival(let id): q = e.beginArrival(id) + q
                case .enterPort: return .port
                case .gameOver: return .over("gameover")
                case .finale:
                    _ = e.finish()
                    return .over("finale")
                }
            }
            return .resume
        }

        func pick(_ c: ChoiceEvent) -> Int {
            let labels = c.options.map(\.label)
            let firstEnabled = c.options.firstIndex(where: \.enabled)!
            var i: Int
            if case .fork = c.kind {
                var want = v.fork
                if want == "Ask the first mate's advice" {
                    if askedMate { want = "Round Cape Horn" }
                    askedMate = true
                }
                i = labels.firstIndex(of: want)!
            } else if v.policy == "second" && c.options.count > 1 && c.options[1].enabled {
                i = 1
            } else if v.policy == "rotate" && c.options[picks.count % c.options.count].enabled {
                i = picks.count % c.options.count
            } else {
                i = firstEnabled
            }
            picks.append("\(labels[0]) -> \(labels[i])")
            return i
        }

        func seaMenu() -> Route {
            while true {
                if needRepair {
                    while true {
                        let s = e.state
                        let q: [Interrupt]
                        if s.sails < 45 && e.canMendSails { q = e.mendSails() }
                        else if s.hull < 45 && e.canPatchHull { q = e.patchHull() }
                        else { break }
                        if case .over(let o) = process(q) { return .over(o) }
                    }
                } else if wantSeaRest {
                    restedAtSea.insert(e.state.stopIndex)
                    if case .over(let o) = process(e.rest(days: 3)) { return .over(o) }
                } else {
                    e.setSail()
                    return .resume
                }
            }
        }

        func portVisit() -> Route {
            if case .over(let o) = process(e.rest(days: 2)) { return .over(o) }
            if case .over(let o) = process(e.tradeAtPort()) { return .over(o) }
            _ = e.talk()
            while true {
                let q: [Interrupt]
                if e.canRepairHullAtYard { q = e.repairHullAtYard() }
                else if e.canRecutSailsAtYard { q = e.recutSailsAtYard() }
                else { break }
                if case .over(let o) = process(q) { return .over(o) }
            }
            shop()
            e.setSail()
            return .resume
        }

        func shop() {
            let port = e.currentPort!
            var cart: [ItemKey: Int] = [:]
            var total = 0.0
            for (k, target) in PrototypeParityTests.shopping {
                let it = GameData.item(k)
                let room = e.room(for: k)
                var n = min(room, max(0, Int(((target - e.state[k]) / Double(it.per) / Double(it.step)).rounded(.up)) * it.step))
                let pr = port.price(k)
                while n > 0 && total + Double(n) * pr > e.state.money { n -= it.step }
                n = max(0, n)
                cart[k] = n
                total += Double(n) * pr
            }
            XCTAssertTrue(e.buy(cart), "\(v.name): the shop refused a cart the prototype paid for")
        }

        func snapshot() -> Snap {
            let s = e.state
            return Snap(day: s.day, mile: s.mile, money: s.money, food: s.food, water: s.water, limes: s.limes,
                        meds: s.meds, clothes: s.clothes, sailcloth: s.sailcloth, timber: s.timber, tackle: s.tackle,
                        hull: s.hull, sails: s.sails, weather: s.weather.rawValue, stopIdx: s.stopIndex,
                        passage: s.passage?.rawValue, pilot: s.pilot, noCitrus: s.noCitrus, badLuck: s.badLuck,
                        forceFair: s.forceFair, tradesLeft: s.tradesLeft, talkIdx: s.talkIndex, atPort: s.atPort,
                        albatross: s.albatrossSeen, stowaway: s.stowawaySeen, starving: s.starving, thirst: s.thirst,
                        flags: [s.flags.food, s.flags.lowFood, s.flags.water, s.flags.lowWater, s.flags.limes,
                                s.flags.hull, s.flags.sails],
                        crew: s.crew.map { .init(name: $0.name, hp: $0.hp, ail: $0.ailment?.rawValue, ailDays: $0.ailDays,
                                                 treated: $0.treated, alive: $0.alive, leave: $0.leaveAt) },
                        graves: s.graves.map { "\($0.name)|\($0.cause)|\($0.date)|\($0.epitaph)" })
        }
    }
}
