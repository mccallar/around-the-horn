import XCTest
@testable import HornEngine

/// The train's two meters at nought, and the woodpile empty (docs/journeys/rail.md,
/// "Breakdowns"): no meter below 0, a train that has given out stops, and one with no
/// wood crawls.
final class RailBreakdownTests: XCTestCase {
    let rail = Journeys.journey(Rail.id)

    /// A meter as the status panel writes it (`StatusPanel`: `Int(jsRounded(x))`; the web:
    /// `${jsRounded(x)}%`), keeping the sign a negative zero would carry.
    static func shown(_ x: Double) -> String {
        let r = jsRound(x)
        return (r.sign == .minus ? "-" : "") + "\(Int(abs(r)))%"
    }

    /// What one seeded run with nothing to mend with did, turn by turn.
    struct Trace {
        var log: [String] = []
        /// Every value the two meters and the crew's health were stored at after a turn.
        var stored: [Double] = []
        var shown: [String] = []
        /// Damage reports that said more was lost than the meter held.
        var overReported: [String] = []
        /// Miles covered on a turn begun with a meter showing 0%.
        var movedAtZero: [Int] = []
        /// Miles covered on a turn begun with less wood than the pace burns.
        var movedWithoutWood: [Int] = []
        var ending: String?
    }

    /// A seeded run out of Omaha in October with no fittings, no car spares, no money and
    /// `fuel` tenths of a cord, answering every question with its first offer.
    func run(seed: UInt64, fuel: Double = 0, turns: Int = 200) -> Trace {
        var s = GameState(journey: Rail.id, role: .merchant, ship: "Juniper", captain: "Amos",
                          crew: ["Clara", "Ned", "Ruth", "Gideon"], startYear: 1869, startMonth: 9)
        s.food = 2000
        s.water = 1200
        s.fuel = fuel
        s.clothes = 5
        s.money = 0
        s.atPort = false
        let e = GameEngine(state: s, rng: SeededRNG(seed: seed))
        var t = Trace()
        func play(_ q: [Interrupt]) {
            var q = q
            while !q.isEmpty {
                switch q.removeFirst() {
                case .message(let m): t.log.append(m)
                case .choice(let c):
                    t.log.append(c.prompt)
                    q = e.resolve(c, option: c.options.firstIndex(where: \.enabled) ?? 0) + q
                case .burial(let id, let cause): e.commitBurial(crewID: id, cause: cause, epitaph: "")
                case .arrival(let id): q = e.beginArrival(id) + q
                case .enterPort: return
                case .gameOver(let title, _): t.ending = title; return
                case .finale: t.ending = "arrived"; return
                }
            }
        }
        for _ in 0..<turns where !e.state.over {
            let mile = e.state.mile, before = (e.state.sails, e.state.hull)
            let atZero = jsRound(before.0) <= 0 || jsRound(before.1) <= 0
            let noWood = e.state.fuel < rail.pace(e.state.pace).fuel
            let n = t.log.count
            play(e.sailDay())
            if e.state.atPort { e.setSail() }
            for m in t.log[n...] {
                for (label, had) in [("Engine", before.0), ("Running gear", before.1)] {
                    guard let r = m.range(of: "(\(label) −") else { continue }
                    let lost = Double(m[r.upperBound...].prefix { $0.isNumber }) ?? 0
                    if lost > jsRound(had) { t.overReported.append("\(label) at \(Self.shown(had)): \(m)") }
                }
            }
            if atZero { t.movedAtZero.append(e.state.mile - mile) }
            if noWood && !atZero { t.movedWithoutWood.append(e.state.mile - mile) }
            t.stored += [e.state.sails, e.state.hull] + e.state.crew.filter(\.alive).map(\.hp)
            t.shown += [Self.shown(e.state.hull), Self.shown(e.state.sails)]
            t.log.append("turn \(e.state.day) mile \(e.state.mile) engine \(Self.shown(e.state.sails)) gear \(Self.shown(e.state.hull)) wood \(e.state.fuel)")
        }
        t.ending = t.ending ?? (e.state.over ? "over" : nil)
        return t
    }

    /// Ryan's report: the train's health went below 0, and with no wood she ran on just
    /// fine. Before the fix: no meter was ever stored below 0 or as -0, but the damage
    /// reports kept coming at a meter already at 0% ("Engine −13%" with the engine at 0%),
    /// a train whose engine showed 0% ran on at 45% speed with wood and at a quarter of that
    /// without, and a crew member's health could be stored below 0 by a road accident.
    func testNoMeterGoesBelowNoughtAndAGivenOutTrainStops() {
        var t = Trace()
        for seed: UInt64 in 1...120 {
            let r = run(seed: seed, fuel: seed % 2 == 0 ? 160 : 0)
            t.stored += r.stored
            t.shown += r.shown
            t.overReported += r.overReported
            t.movedAtZero += r.movedAtZero
            t.movedWithoutWood += r.movedWithoutWood
        }
        XCTAssertFalse(t.stored.contains { $0 < 0 || $0.sign == .minus }, "a value stored below 0")
        XCTAssertFalse(t.shown.contains { $0.hasPrefix("-") }, "a meter shown below 0")
        XCTAssertEqual(t.overReported.count, 0, "damage reported past nought: \(t.overReported.prefix(2))")
        XCTAssertGreaterThan(t.movedAtZero.count, 0, "some run gave out")
        XCTAssertEqual(t.movedAtZero.filter { $0 > 0 }.count, 0, "a train at 0% moved: \(t.movedAtZero.filter { $0 > 0 }.prefix(10))")
        XCTAssertGreaterThan(t.movedWithoutWood.count, 0, "some run had no wood")
        XCTAssertLessThanOrEqual(t.movedWithoutWood.max() ?? 0, 7, "a turn on no wood ran \(t.movedWithoutWood.max() ?? 0) miles")
    }
}
