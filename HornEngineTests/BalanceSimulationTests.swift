import XCTest
@testable import HornEngine

/// Spec §12 M2: a headless "sensible player" plays 30 seeded voyages per role, and the
/// win rates and voyage length must land in the bands the web version was tuned to.
///
/// The prototype's own bot (`test/bot.js`) was not supplied; `SensibleBot` follows the
/// spec's description of it, and where that description is silent it takes the cautious
/// choice — each one is commented where it is made.
final class BalanceSimulationTests: XCTestCase {
    static let voyagesPerRole = 30

    struct Result {
        let won: Bool
        let days: Int
        let ending: String
    }

    func testWinRatesAndVoyageLengthAreInBand() {
        var lines: [String] = []
        var allWinDays: [Int] = []
        var rates: [Role: Double] = [:]
        for role in Role.allCases {
            let results = (0..<Self.voyagesPerRole).map { i in
                SensibleBot(role: role, seed: UInt64(1849 + 1000 * role.scoreMultiplier + i)).play()
            }
            let wins = results.filter(\.won)
            rates[role] = Double(wins.count) / Double(results.count)
            allWinDays += wins.map(\.days)
            let endings = Dictionary(grouping: results.filter { !$0.won }, by: \.ending).mapValues(\.count)
            lines.append("\(role.rawValue): \(wins.count)/\(results.count) won, median \(Self.median(wins.map(\.days))) days; lost to \(endings)")
        }
        let medianDays = Self.median(allWinDays)
        let report = lines.joined(separator: "\n") + "\nmedian voyage (all winners): \(medianDays) days"
        print("BALANCE\n" + report)
        add(XCTAttachment(string: report))

        // The spec's bands, each with its ±15 percentage-point tolerance.
        XCTAssertGreaterThanOrEqual(rates[.merchant]!, 0.85 - 0.15, report)
        XCTAssertTrue((0.45 - 0.15...0.85 + 0.15).contains(rates[.shipwright]!), report)
        XCTAssertTrue((0.15 - 0.15...0.50 + 0.15).contains(rates[.whaler]!), report)
        XCTAssertTrue((150...200).contains(medianDays), report)
    }

    static func median(_ xs: [Int]) -> Int {
        guard !xs.isEmpty else { return 0 }
        let s = xs.sorted()
        return s.count % 2 == 1 ? s[s.count / 2] : (s[s.count / 2 - 1] + s[s.count / 2]) / 2
    }
}

/// The spec's sensible player (§12 M2).
final class SensibleBot {
    let e: GameEngine
    var restedHere = false

    init(role: Role, seed: UInt64) {
        let rng = SeededRNG(seed: seed)
        // Departure: the advice the game gives is "December or January, if you can".
        // Not in the spec's bot description; alternating keeps both in the sample.
        let departure = GameData.departures[seed % 2 == 0 ? 0 : 1]
        let s = GameState(role: role, ship: "Resolute", captain: "Ezra",
                          crew: ["Hannah", "Silas", "Mercy", "Tobias"],
                          startYear: departure.year, startMonth: departure.month)
        e = GameEngine(state: s, rng: rng)
    }

    var crew: Double { Double(e.state.living.count) }
    var foodDays: Double { e.state.food / (crew * e.state.rations.lb) }

    func play() -> BalanceSimulationTests.Result {
        // "Non-merchants use meager rations."
        if e.state.role != .merchant { e.state.rations = .meager }
        shop()
        guard e.departNewYork() != nil else { return .init(won: false, days: 0, ending: "never sailed") }
        while e.state.day < 500 {
            if let end = atSea() { return end }
            switch process(e.sailDay()) {
            case .resume: continue
            case .port:
                if let end = portVisit() { return end }
            case .ended(let r): return r
            }
        }
        return .init(won: false, days: e.state.day, ending: "still at sea")
    }

    enum Route { case resume, port, ended(BalanceSimulationTests.Result) }

    // MARK: At sea

    /// Before each day's sailing: mend, and fish when food runs short.
    func atSea() -> BalanceSimulationTests.Result? {
        // "Mends at sea if sails or hull < 40."
        while (e.state.sails < 40 && e.canMendSails) || (e.state.hull < 40 && e.canPatchHull) {
            let q = e.state.sails < 40 && e.canMendSails ? e.mendSails() : e.patchHull()
            if case .ended(let r) = process(q) { return r }
        }
        // "Non-merchants … fish (simulated catch) when food is under 12 days."
        if e.state.role != .merchant && foodDays < 12 && e.fishingRefusal == nil {
            if case .ended(let r) = process(e.landCatch(simulatedCatch())) { return r }
        }
        e.setSail()
        return nil
    }

    /// One outing of the mini-game, played by an average thumb: up to 15 throws in 25
    /// seconds, each hitting a fish drawn by the game's own weights. The whaler's wider
    /// hit padding (4 px against 1.5) makes a hit likelier.
    func simulatedCatch() -> Int {
        var caught = 0
        let hit = e.state.role == .whaler ? 0.55 : 0.35
        for _ in 0..<15 where e.state.tackle > 0 {
            e.throwHarpoon()
            if e.chance(hit) {
                let fish = e.weightedPick(GameData.fish.map { ($0, $0.weight) })
                caught += fish.lb
            }
        }
        return caught
    }

    // MARK: Ports

    func portVisit() -> BalanceSimulationTests.Result? {
        // "Rests 3 days in port if average hp < 70."
        if e.state.averageHP < 70, case .ended(let r) = process(e.rest(days: 3)) { return r }
        // "Uses the shipyard if hull < 70." Sails too, by the same rule.
        if e.state.hull < 70 && e.canRepairHullAtYard, case .ended(let r) = process(e.repairHullAtYard()) { return r }
        if e.state.sails < 70 && e.canRecutSailsAtYard, case .ended(let r) = process(e.recutSailsAtYard()) { return r }
        shop()
        e.setSail()
        return nil
    }

    /// "Buys sensibly … for (distance to the next port)/85 + 10 days of food, water and
    /// citrus", keeps woolens ≥ crew, then a few spares, in that order while money lasts.
    func shop() {
        guard let port = e.currentPort else { return }
        let next = GameData.stops[(e.state.stopIndex + 1)...].first { $0.type == .port || $0.type == .end }!
        let days = Double(next.mile - e.state.mile) / 85 + 10
        let n = crew
        let wants: [(ItemKey, Double)] = [
            (.food, n * e.state.rations.lb * days),
            (.water, n * days),
            (.limes, n * 0.02 * days),
            (.clothes, n),
            (.meds, 2),
            (.sailcloth, 2),
            (.timber, 2),
            (.tackle, e.state.role == .merchant ? 0 : 60),
        ]
        var cart: [ItemKey: Int] = [:]
        var total = 0.0
        for (k, target) in wants {
            let it = GameData.item(k)
            var units = Int(((target - e.state[k]) / Double(it.per) / Double(it.step)).rounded(.up)) * it.step
            units = min(max(0, units), e.room(for: k))
            let price = port.price(k)
            while units > 0 && total + Double(units) * price > e.state.money { units -= it.step }
            units = max(0, units)
            cart[k] = units
            total += Double(units) * price
        }
        e.buy(cart)
    }

    // MARK: Interrupts

    func process(_ initial: [Interrupt]) -> Route {
        var q = initial
        while !q.isEmpty {
            switch q.removeFirst() {
            case .message: break
            case .choice(let c): q = e.resolve(c, option: decide(c)) + q
            case .burial(let id, let cause): e.commitBurial(crewID: id, cause: cause, epitaph: "")
            case .arrival(let id): q = e.beginArrival(id) + q
            case .enterPort: return .port
            case .gameOver(let title, _): return .ended(.init(won: false, days: e.state.day, ending: Self.ending(title)))
            case .finale:
                _ = e.finish()
                return .ended(.init(won: true, days: e.state.day, ending: "San Francisco"))
            }
        }
        return .resume
    }

    func decide(_ c: ChoiceEvent) -> Int {
        switch c.kind {
        case .stranger: return 1           // cautious: run rather than risk privateers
        case .albatross: return 0          // let it be
        case .stowaway: return 1           // one less mouth: put ashore at Cape Verde
        case .icebergs: return 0           // shorten sail
        case .equator: return 0            // "always holds the Equator ceremony"
        case .galapagos: return 0          // "always lands at the Galápagos"
        case .fork: return e.chance(0.5) ? 0 : 1  // "takes the Horn or the Strait at random"
        case .pilot: return c.options[0].enabled ? 0 : 1
        case .portArrival: return 0        // go ashore to buy
        case .tradeOffer: return 1         // decline
        }
    }

    static func ending(_ title: String) -> String {
        if title.contains("foundered") { return "foundered" }
        if let r = title.range(of: "died of ") { return String(title[r.upperBound...].dropLast()) }
        return title
    }
}
