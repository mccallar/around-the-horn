import Foundation

/// The game's rules (spec §5). Mutates `state` and returns `[Interrupt]`; never touches
/// UI. Every random number comes from `rng`.
///
/// FIDELITY RULE: each function here is a line-for-line port of the prototype function of
/// the same name, and draws its random numbers in the same order — including draws whose
/// result is thrown away (a pick from an empty list, a `ri` inside a `Math.min`). Change
/// that order and a seeded voyage stops matching the prototype; `Tools/prototype-diff`
/// checks it.
public final class GameEngine {
    public var state: GameState
    public var rng: RandomSource

    public init(state: GameState, rng: RandomSource = SeededRNG(seed: UInt64.random(in: 0...UInt64.max))) {
        self.state = state
        self.rng = rng
    }

    public enum DayMode {
        /// Under way.
        case sail
        /// Hove to at sea: resting, repairing, fishing.
        case sea
        /// Ashore.
        case port
    }

    // MARK: - Random helpers (the prototype's rnd, ri, pick, chance, wpick)

    func rnd(_ a: Double, _ b: Double) -> Double { rng.uniform(a, b) }
    func ri(_ a: Int, _ b: Int) -> Int { rng.int(a, b) }
    func chance(_ p: Double) -> Bool { rng.chance(p) }

    /// Spends a draw even when `a` is empty, as the prototype does.
    func pick<T>(_ a: [T]) -> T? {
        let i = Int((rng.nextUnit() * Double(a.count)).rounded(.down))
        return a.isEmpty ? nil : a[i]
    }

    func weightedPick<K>(_ w: [(K, Double)]) -> K {
        var total = 0.0
        for (_, x) in w { total += x }
        var r = rng.nextUnit() * total
        for (k, x) in w {
            r -= x
            if r <= 0 { return k }
        }
        return w[0].0
    }

    // MARK: - Weather (spec §5 "Weather roll")

    func rollWeather(_ reg: Region) -> Weather {
        if state.forceFair > 0 {
            state.forceFair -= 1
            return .fair
        }
        let w = weatherWeights(reg, cursed: state.badLuck > 0)
        if state.badLuck > 0 { state.badLuck -= 1 }
        return weightedPick(w)
    }

    /// The day's weather odds in `reg`, in the prototype's key order: a key the
    /// adjustments add that the region lacks goes on the end, as it does in `{...reg.w}`.
    func weatherWeights(_ reg: Region, cursed: Bool) -> [(Weather, Double)] {
        var w = reg.weights
        func bump(_ k: Weather, _ f: (Double) -> Double) {
            if let i = w.firstIndex(where: { $0.0 == k }) { w[i].1 = f(w[i].1) } else { w.append((k, f(0))) }
        }
        if reg.south && state.southernWinter {
            bump(.gale) { $0 + 20 }
            bump(.storm) { $0 + (reg.horn ? 30 : 18) }
            bump(.cold) { $0 + 15 }
            bump(.fair) { $0 * 0.5 }
            bump(.fresh) { $0 * 0.6 }
        }
        if reg.id == .northAtlantic && [11, 0, 1].contains(state.month) {
            bump(.gale) { $0 + 8 }
            bump(.storm) { $0 + 5 }
        }
        if cursed {
            bump(.gale) { $0 + 20 }
            bump(.storm) { $0 + 15 }
            bump(.calm) { $0 + 10 }
        }
        return w
    }

    // MARK: - One day under sail (spec §5.1)

    public func sailDay() -> [Interrupt] {
        var q: [Interrupt] = []
        state.note = ""
        guard let ns = state.nextStop, !state.over else { return q }
        state.day += 1
        let reg = state.region
        state.weather = rollWeather(reg)
        let w = state.weather
        let n = state.living.count
        var sp = state.pace.speed * w.speed
        sp *= 0.45 + 0.55 * (state.sails / 100)
        sp *= 0.75 + 0.25 * (state.hull / 100)
        sp *= n >= 4 ? 1 : n == 3 ? 0.85 : n == 2 ? 0.65 : 0.45
        if state.inStrait { sp *= 0.5 }
        if (reg.horn || reg.strait) && state.southernWinter { sp *= 0.6 }
        sp *= rnd(0.85, 1.15)
        var d = Int(max(0, jsRound(sp)))
        var arrived = false
        if state.mile + d >= ns.mile {
            d = ns.mile - state.mile
            arrived = true
        }
        state.mile += d
        if w == .calm { state.note = "Not a breath of wind. The sails hang slack." }
        consume(&q, .sail)
        health(&q, .sail)
        if state.over { return q }
        wear(&q, reg)
        if state.over { return q }
        if !arrived {
            if state.inStrait && chance(state.pilot ? 0.012 : 0.055) {
                let h = ri(12, 28)
                state.hull -= Double(h)
                state.day += 1
                q.append(.message("You have run aground on an uncharted shoal! It takes a full day to kedge her off. [red](Hull −\(h)%)[/red]"))
                checkSink(&q)
            } else if reg.horn && chance(0.012) {
                overboard(&q)
            } else if chance(0.11) {
                seaEvent(&q, reg)
            }
        }
        if state.over { return q }
        if arrived {
            state.stopIndex += 1
            q.append(.arrival(stopID: ns.id))
        }
        return q
    }

    // MARK: - Consumption (spec §5.2)

    func consume(_ q: inout [Interrupt], _ mode: DayMode) {
        let n = Double(state.living.count)
        if n == 0 { return }
        let temp = state.temperature(in: state.region)
        let fneed = n * state.rations.lb
        if state.food >= fneed {
            state.food -= fneed
            state.starving = false
        } else {
            state.food = 0
            state.starving = true
        }
        let wneed = n * (temp == .hot ? 1.5 : 1)
        if state.water >= wneed {
            state.water -= wneed
            state.thirst = false
        } else {
            state.water = 0
            state.thirst = true
        }
        if mode == .port {
            state.noCitrus = 0
        } else if state.limes > 0 {
            state.limes = max(0, state.limes - n * 0.02)
            state.noCitrus = 0
        } else {
            state.noCitrus += 1
        }
        if mode != .port && (state.weather == .rain || state.weather == .storm)
            && state.water < GameData.item(.water).cap
        {
            let r = ri(15, 45)
            state.add(.water, Double(r))
            state.note = "Caught \(r) gallons of rainwater in the sails."
        }
        if state.starving && !state.flags.food {
            state.flags.food = true
            q.append(.message("[red]You have run out of provisions![/red] The crew is starving."))
        } else if !state.starving && state.food < fneed * 7 && !state.flags.lowFood {
            state.flags.lowFood = true
            q.append(.message("The cook warns you: provisions will last about a week."))
        }
        if state.food > fneed * 10 {
            state.flags.food = false
            state.flags.lowFood = false
        }
        if state.thirst && !state.flags.water {
            state.flags.water = true
            q.append(.message("[red]The water casks are dry![/red] Without water, the crew will die within days."))
        } else if !state.thirst && state.water < wneed * 5 && !state.flags.lowWater {
            state.flags.lowWater = true
            q.append(.message("The water casks are nearly empty — a few days left."))
        }
        if state.water > wneed * 10 {
            state.flags.water = false
            state.flags.lowWater = false
        }
        if mode != .port && state.limes <= 0 && !state.flags.limes {
            state.flags.limes = true
            q.append(.message("The last of the citrus is gone. Scurvy will follow within a few weeks unless you find fresh food."))
        }
        if state.limes > 1 { state.flags.limes = false }
    }

    // MARK: - Health (spec §5.3)

    func health(_ q: inout [Interrupt], _ mode: DayMode) {
        let temp = state.temperature(in: state.region)
        let w = state.weather
        let port: Port? = mode == .port ? state.currentStop.portID.map(GameData.port) : nil
        let livingNow = state.crew.indices.filter { state.crew[$0].alive }
        for (i, idx) in livingNow.enumerated() {
            var p = state.crew[idx]
            var d = state.rations.hp
            if mode == .sail {
                d += state.pace.hp
                if w.harsh != 0 { d -= w.harsh }
            }
            if mode == .sea { d += 3 }
            if mode == .port { d += 6 }
            if state.starving { d -= 7 }
            if state.thirst { d -= 12 }
            let warm = i < state.clothes
            if mode != .port {
                if temp == .freezing {
                    d -= (warm ? 1.4 : 4.5) + (state.southernWinter ? 1 : 0)
                } else if temp == .cold {
                    d -= warm ? 0 : 2.2
                } else if temp == .hot {
                    d -= 0.4
                }
            }
            if let a = p.ailment {
                d -= a.damage * (p.treated ? 0.5 : 1)
                if a == .scurvy {
                    if (state.limes > 0 || mode == .port) && chance(mode == .port ? 0.6 : 0.35) {
                        p.ailment = nil
                        q.append(.message("\(TextMarkup.escape(p.name)) is recovering from scurvy."))
                    }
                } else {
                    p.ailDays -= mode == .port ? 2 : mode == .sea ? 1.5 : 1
                    if p.ailDays <= 0 {
                        p.ailment = nil
                        p.treated = false
                        q.append(.message("\(TextMarkup.escape(p.name)) is well again."))
                    }
                }
            } else {
                d += 1
            }
            p.hp = min(100, max(0, p.hp + d))
            state.crew[idx] = p
            if p.ailment == nil && p.hp > 0 {
                var pr = 0.0035 + (100 - p.hp) * 0.00035
                if state.rations == .bare { pr += 0.005 }
                if state.starving { pr += 0.03 }
                if state.thirst { pr += 0.04 }
                if temp == .hot { pr += 0.003 }
                if (temp == .freezing || temp == .cold) && !warm && mode != .port { pr += 0.01 }
                if port?.fever == true { pr += 0.012 }
                if mode == .port { pr *= 0.7 }
                if chance(pr) {
                    sicken(idx, &q, temp, port, nil)
                } else if mode != .port && state.noCitrus > 35
                    && chance(min(0.12, Double(state.noCitrus - 35) * 0.004))
                {
                    sicken(idx, &q, temp, nil, .scurvy)
                }
            }
        }
        deaths(&q)
    }

    func sicken(_ idx: Int, _ q: inout [Interrupt], _ temp: Temp, _ port: Port?, _ force: Ailment?) {
        let pool: [Ailment]
        if let force = force {
            pool = [force]
        } else if port?.fever == true {
            pool = [.yellowFever, .fever, .dysentery]
        } else if temp == .hot {
            pool = [.fever, .dysentery, .exhaustion, .yellowFever, .shipFever]
        } else if temp == .freezing || temp == .cold {
            pool = [.pneumonia, .frostbite, .fever, .shipFever, .brokenArm]
        } else {
            pool = [.shipFever, .dysentery, .fever, .brokenArm, .exhaustion]
        }
        let a = pick(pool)!
        state.crew[idx].ailment = a
        state.crew[idx].ailDays = Double(ri(a.duration.lowerBound, a.duration.upperBound))
        state.crew[idx].treated = false
        var t = "\(TextMarkup.escape(state.crew[idx].name)) has \(a.name)."
        if a == .scurvy {
            t += " [dim]Bleeding gums, aching joints. Citrus or a run ashore will cure it.[/dim]"
        } else if state.meds > 0 {
            state.meds -= 1
            state.crew[idx].treated = true
            t += " [dim]You open a medicine kit (\(state.meds) left).[/dim]"
        }
        q.append(.message(t))
    }

    func deaths(_ q: inout [Interrupt]) {
        for idx in state.crew.indices where state.crew[idx].alive && state.crew[idx].hp <= 0 {
            state.crew[idx].alive = false
            let p = state.crew[idx]
            let cause = p.ailment?.deathName ?? (state.thirst ? "thirst" : state.starving ? "starvation" : "exhaustion")
            if p.isCaptain {
                state.over = true
                q.append(.gameOver(title: "You, Captain \(TextMarkup.escape(p.name)), have died of \(cause).",
                                   body: "The crew sails the ship into the nearest port and scatters. The voyage is over."))
                return
            }
            q.append(.burial(crewID: p.id, cause: cause))
        }
    }

    // MARK: - Ship wear (spec §5.4)

    func wear(_ q: inout [Interrupt], _ reg: Region) {
        let w = state.weather
        state.sails = max(0, state.sails - state.pace.wear * w.wear * rnd(0.6, 1.4))
        var hd = 0.03
        if w == .storm {
            hd += rnd(1, 2.6) * (state.pace == .full ? 1.6 : state.pace == .easy ? 0.7 : 1)
                * (reg.horn ? 1.5 : 1) * (reg.strait ? 0.5 : 1)
        }
        if w == .gale { hd += rnd(0, 0.8) * (state.pace == .full ? 1.5 : 1) }
        state.hull = max(0, state.hull - hd)
        if state.hull < 35 && state.food > 50 && chance(0.06) {
            let l = ri(20, 60)
            state.food -= Double(l)
            q.append(.message("Seawater has been leaking into the hold. \(l) lbs of provisions are spoiled."))
        }
        if state.hull < 30 && !state.flags.hull {
            state.flags.hull = true
            q.append(.message("[red]The pumps are working day and night.[/red] The hull needs patching — soon."))
        }
        if state.hull > 50 { state.flags.hull = false }
        if state.sails < 25 && !state.flags.sails {
            state.flags.sails = true
            q.append(.message("[red]Your sails are in rags.[/red] She barely answers the helm. Mend them if you can."))
        }
        if state.sails > 50 { state.flags.sails = false }
        checkSink(&q)
    }

    func checkSink(_ q: inout [Interrupt]) {
        if state.hull <= 0 && !state.over {
            state.hull = 0
            state.over = true
            q.append(.gameOver(title: "The [i]\(TextMarkup.escape(state.ship))[/i] has foundered.",
                               body: "Her seams opened faster than the pumps could keep up. She went down by the head, taking everything with her."))
        }
    }

    // MARK: - Days without sailing (spec §5.5)

    /// Rest, repairs, fishing: time passes, the crew eats and heals or sickens; the ship
    /// doesn't move or wear. In port the weather is fair.
    public func passDays(_ n: Int, _ mode: DayMode) -> [Interrupt] {
        var q: [Interrupt] = []
        var i = 0
        while i < n && !state.over {
            state.day += 1
            state.weather = mode != .port ? rollWeather(state.region) : .fair
            consume(&q, mode)
            health(&q, mode)
            i += 1
        }
        return q
    }
}
