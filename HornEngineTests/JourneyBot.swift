@testable import HornEngine

/// A sensible player for any journey, driven by the journey's own tables. Each journey's
/// balance test sets the knobs in `Policy` and answers its own choices in `decide`; the
/// contract test runs every journey with the defaults.
///
/// The 1849 balance gate keeps its own `SensibleBot`, which follows the spec's wording.
final class JourneyBot {
    struct Policy {
        var departure = 0
        var pace = Pace.steady
        /// Chooses the pace before each turn under way (nil: keep `pace`).
        var choosePace: ((GameEngine) -> Pace)?
        var rations: [Role: Rations] = [:]
        /// Stock up for the run to the next port at this share of the pace's speed, plus
        /// `marginTurns` in hand.
        var speedShare = 0.85
        var marginTurns = 10.0
        /// Multiplies the run's food, water, fuel or preventive by item (1 if absent): heat
        /// drinks more than the tables' daily ration, cold burns more.
        var stockFactor: [ItemKey: Double] = [:]
        /// What to hold after shopping, in stored units, bought in this order after the
        /// consumables and the warm clothes.
        var spares: [(ItemKey, Double)] = [(.meds, 2), (.sailcloth, 2), (.timber, 2)]
        /// Throws of forage gear to hold, by role.
        var tackle: [Role: Double] = [:]
        var mendBelow = 40.0
        var yardBelow = 70.0
        var restBelowHP = 70.0
        var restTurns = 3
        /// Shop before using the yard, so the money goes on supplies first.
        var yardAfterShop = false
        /// Forage when this few turns of the reward are left (0: never).
        var forageBelowTurns: [Role: Double] = [:]
        var throwsPerOuting = 15
        var hitChance: [Role: Double] = [:]
        var maxTurns = 2000
        /// Answers a choice: the option index. Nil takes the first enabled option.
        var decide: (GameEngine, ChoiceEvent) -> Int? = { _, _ in nil }
    }

    struct Result: Equatable {
        let won: Bool
        let turns: Int
        let ending: String
        let score: Int
    }

    let e: GameEngine
    let policy: Policy
    var j: Journey { e.journey }
    /// Every message, prompt and option the run produced, for determinism checks.
    private(set) var transcript: [String] = []

    init(journey: Journey, role: Role, seed: UInt64, policy: Policy = Policy()) {
        self.policy = policy
        let d = journey.departures[policy.departure % journey.departures.count]
        var s = GameState(journey: journey.id, role: role, ship: journey.vesselNames[0],
                          captain: journey.firstNames[0], crew: Array(journey.firstNames[1...4]),
                          startYear: d.year, startMonth: d.month)
        s.pace = policy.pace
        s.rations = policy.rations[role] ?? .filling
        e = GameEngine(state: s, rng: SeededRNG(seed: seed))
    }

    var crew: Double { Double(e.state.living.count) }

    func play() -> Result {
        shop()
        guard e.depart() != nil else { return Result(won: false, turns: 0, ending: "never left", score: 0) }
        while e.state.day < policy.maxTurns {
            if let end = underWay() { return end }
            switch process(e.sailDay()) {
            case .resume: continue
            case .port:
                if let end = portVisit() { return end }
            case .ended(let r): return r
            }
        }
        return Result(won: false, turns: e.state.day, ending: "still travelling", score: 0)
    }

    enum Route { case resume, port, ended(Result) }

    // MARK: Between ports

    func underWay() -> Result? {
        while (e.state.sails < policy.mendBelow && e.canMendSails) || (e.state.hull < policy.mendBelow && e.canPatchHull) {
            let q = e.state.sails < policy.mendBelow && e.canMendSails ? e.mendSails() : e.patchHull()
            if case .ended(let r) = process(q) { return r }
        }
        let below = policy.forageBelowTurns[e.state.role] ?? 0
        if below > 0, rewardTurns < below, e.fishingRefusal == nil {
            if case .ended(let r) = process(e.landCatch(simulatedCatch())) { return r }
        }
        if let choose = policy.choosePace { e.state.pace = choose(e) }
        e.setSail()
        return nil
    }

    /// Turns the stock the foraging game adds to will last.
    var rewardTurns: Double {
        switch j.forageReward {
        case .fuel:
            let burn = j.pace(e.state.pace).fuel
            return burn > 0 ? e.state.fuel / burn : .infinity
        case .water:
            return j.rules.water > 0 ? e.state.water / (crew * j.rules.water) : .infinity
        default:
            return e.state[j.forageReward] / (crew * j.rations(e.state.rations).amount)
        }
    }

    func simulatedCatch() -> Int {
        var caught = 0
        let hit = policy.hitChance[e.state.role] ?? 0.35
        for _ in 0..<policy.throwsPerOuting where e.state.tackle > 0 {
            e.throwHarpoon()
            if e.chance(hit) { caught += e.weightedPick(j.quarry.map { ($0, $0.weight) }).lb }
        }
        return caught
    }

    // MARK: Ports

    func portVisit() -> Result? {
        if e.state.averageHP < policy.restBelowHP, case .ended(let r) = process(e.rest(days: policy.restTurns)) { return r }
        if policy.yardAfterShop { shop() }
        if e.state.hull < policy.yardBelow && e.canRepairHullAtYard, case .ended(let r) = process(e.repairHullAtYard()) { return r }
        if e.state.sails < policy.yardBelow && e.canRecutSailsAtYard, case .ended(let r) = process(e.recutSailsAtYard()) { return r }
        if !policy.yardAfterShop { shop() }
        e.setSail()
        return nil
    }

    func shop() {
        guard let port = e.currentPort else { return }
        let ahead = j.stops[(e.state.stopIndex + 1)...]
        guard let next = ahead.first(where: { $0.type == .port || $0.type == .end }) else { return }
        let pace = j.pace(e.state.pace)
        let turns = Double(next.mile - e.state.mile) / (pace.speed * policy.speedShare) + policy.marginTurns
        let n = crew
        func f(_ k: ItemKey) -> Double { policy.stockFactor[k] ?? 1 }
        var wants: [(ItemKey, Double)] = [
            (.food, n * j.rations(e.state.rations).amount * turns * f(.food)),
            (.water, n * j.rules.water * turns * f(.water)),
            (.fuel, pace.fuel * turns * f(.fuel)),
            (.limes, j.deficiency == nil ? 0 : n * j.rules.preventiveUse * turns * f(.limes)),
            (.clothes, n),
        ]
        wants += policy.spares
        wants.append((.tackle, policy.tackle[e.state.role] ?? 0))
        var cart: [ItemKey: Int] = [:]
        var total = 0.0
        for (k, target) in wants {
            let it = j.item(k)
            if it.max == 0 { continue }
            var units = Int(((target - e.state[k]) / Double(it.per) / Double(it.step)).rounded(.up)) * it.step
            units = min(max(0, units), e.room(for: k))
            let price = port.price(k)
            while units > 0 && total + Double(units) * price > e.state.money { units -= it.step }
            units = max(0, units)
            cart[k, default: 0] += units
            total += Double(units) * price
        }
        e.buy(cart)
    }

    // MARK: Interrupts

    func process(_ initial: [Interrupt]) -> Route {
        var q = initial
        while !q.isEmpty {
            switch q.removeFirst() {
            case .message(let t): transcript.append(t)
            case .choice(let c):
                transcript.append(c.prompt)
                transcript += c.options.map(\.label)
                let pick = policy.decide(e, c) ?? c.options.firstIndex(where: \.enabled) ?? 0
                q = e.resolve(c, option: pick) + q
            case .burial(let id, let cause):
                transcript.append("burial: \(cause)")
                e.commitBurial(crewID: id, cause: cause, epitaph: "")
            case .arrival(let id): q = e.beginArrival(id) + q
            case .enterPort: return .port
            case .gameOver(let title, let body):
                transcript += [title, body]
                return .ended(Result(won: false, turns: e.state.day, ending: title, score: 0))
            case .finale:
                let score = e.finish()
                return .ended(Result(won: true, turns: e.state.day, ending: "arrived", score: score.total))
            }
        }
        return .resume
    }

    static func median(_ xs: [Int]) -> Int {
        guard !xs.isEmpty else { return 0 }
        let s = xs.sorted()
        return s.count % 2 == 1 ? s[s.count / 2] : (s[s.count / 2 - 1] + s[s.count / 2]) / 2
    }

    /// Plays `count` seeded journeys per role and reports wins and the median length of a
    /// winning run, in turns.
    static func survey(_ journey: Journey, count: Int = 30, seed: UInt64, policy: Policy = Policy())
        -> (rates: [Role: Double], medianTurns: Int, report: String)
    {
        var lines: [String] = []
        var winTurns: [Int] = []
        var rates: [Role: Double] = [:]
        for role in Role.allCases {
            let results = (0..<count).map { i in
                JourneyBot(journey: journey, role: role, seed: seed + UInt64(1000 * role.scoreMultiplier + i),
                           policy: policy).play()
            }
            let wins = results.filter(\.won)
            rates[role] = Double(wins.count) / Double(results.count)
            winTurns += wins.map(\.turns)
            var endings: [(String, Int)] = []
            for r in results where !r.won {
                if let i = endings.firstIndex(where: { $0.0 == r.ending }) { endings[i].1 += 1 } else { endings.append((r.ending, 1)) }
            }
            let lost = endings.map { "\($0.1)× \($0.0)" }.joined(separator: "; ")
            lines.append("\(role.rawValue): \(wins.count)/\(results.count) won, median \(median(wins.map(\.turns))) turns, median score \(median(wins.map(\.score)))\(lost.isEmpty ? "" : " — lost: \(lost)")")
        }
        let m = median(winTurns)
        return (rates, m, "\(journey.id)\n" + lines.joined(separator: "\n") + "\nmedian winning run: \(m) turns")
    }
}
