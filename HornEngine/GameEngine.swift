#if os(WASI)
import FoundationEssentials
#else
import Foundation
#endif

/// The game's rules (spec §5). Mutates `state` and returns `[Interrupt]`; never touches
/// UI. Every random number comes from `rng`.
///
/// These are the rules every journey shares. The numbers come from `journey.rules`, the
/// sentences from `journey.text`, and what a journey does differently from its hooks
/// (Journey.swift).
///
/// FIDELITY RULE: with 1849's journey, each function here is a line-for-line port of the
/// prototype function of the same name, and draws its random numbers in the same order —
/// including draws whose result is thrown away (a pick from an empty list, a `ri` inside
/// a `Math.min`). Change that order, or regroup a floating-point expression, and a seeded
/// voyage stops matching the prototype; `PrototypeParityTests` and `GoldenVoyageTests`
/// check it.
public final class GameEngine {
    public var state: GameState
    public var rng: RandomSource
    public let journey: Journey

    public init(state: GameState, rng: RandomSource = SeededRNG(seed: UInt64.random(in: 0...UInt64.max))) {
        self.state = state
        self.rng = rng
        journey = Journeys.journey(state.journey)
    }

    public enum DayMode {
        /// Under way.
        case sail
        /// Stopped between ports: resting, repairing, foraging.
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
            return journey.fairWeather
        }
        let w = weatherWeights(reg, cursed: state.badLuck > 0)
        if state.badLuck > 0 { state.badLuck -= 1 }
        return weightedPick(w)
    }

    /// The turn's weather odds in `reg`, after the journey's seasons and curses.
    func weatherWeights(_ reg: Region, cursed: Bool) -> WeatherOdds {
        journey.weatherWeights(self, reg, cursed: cursed)
    }

    // MARK: - One day under sail (spec §5.1)

    public func sailDay() -> [Interrupt] {
        var q: [Interrupt] = []
        state.note = ""
        guard let ns = state.nextStop, !state.over else { return q }
        if let stopped = journey.stalled(self) { return stopped }
        state.day += 1
        let reg = state.region
        state.weather = rollWeather(reg)
        let w = state.weather
        let r = journey.rules
        let pace = journey.pace(state.pace)
        let n = state.living.count
        var sp = pace.speed * w.speed
        sp *= r.propFloor + r.propSpan * (state.sails / 100)
        sp *= r.hullFloor + r.hullSpan * (state.hull / 100)
        sp *= journey.crewFactor(n)
        journey.adjustSpeed(self, reg, &sp)
        if pace.fuel > 0 {
            if state.fuel >= pace.fuel {
                state.fuel -= pace.fuel
            } else {
                let share = r.burnsPartLoad ? max(0, state.fuel) / pace.fuel : 0
                state.fuel = 0
                sp *= r.burnsPartLoad ? share + (1 - share) * r.noFuelSpeed : r.noFuelSpeed
            }
        }
        sp *= rnd(r.speedJitter.lowerBound, r.speedJitter.upperBound)
        var d = Int(max(0, jsRound(sp)))
        var arrived = false
        if state.mile + d >= ns.mile {
            d = ns.mile - state.mile
            arrived = true
        }
        state.mile += d
        if !w.note.isEmpty { state.note = w.note }
        consume(&q, .sail)
        if pace.fuel > 0 { fuelWarnings(&q, pace) }
        health(&q, .sail)
        if state.over { return q }
        wear(&q, reg)
        if state.over { return q }
        journey.tick(self, &q, .sail, reg)
        if state.over { return q }
        if !arrived { journey.dayEvents(self, &q, reg) }
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
        let r = journey.rules
        let text = journey.text
        let temp = state.temperature(in: state.region)
        let fneed = n * journey.rations(state.rations).amount
        if state.food >= fneed {
            state.food -= fneed
            state.starving = false
        } else {
            state.food = 0
            state.starving = true
        }
        let wneed = n * (temp == .hot ? r.hotWater : r.water)
        if state.water >= wneed {
            state.water -= wneed
            state.thirst = false
        } else {
            state.water = 0
            state.thirst = true
        }
        let hasDeficiency = journey.deficiency != nil
        if !hasDeficiency || mode == .port {
            state.noCitrus = 0
        } else if state.limes > 0 {
            state.limes = max(0, state.limes - n * r.preventiveUse)
            state.noCitrus = 0
        } else {
            state.noCitrus += 1
        }
        if mode != .port && state.weather.wet && state.water < journey.item(.water).cap {
            let caught = ri(r.rainCatch.lowerBound, r.rainCatch.upperBound)
            state.add(.water, Double(caught))
            state.note = text.rainCaught(caught)
        }
        if state.starving && !state.flags.food {
            state.flags.food = true
            q.append(.message(text.outOfFood))
        } else if !state.starving && state.food < fneed * r.lowFoodTicks && !state.flags.lowFood {
            state.flags.lowFood = true
            q.append(.message(text.lowFood))
        }
        if state.food > fneed * r.rearmTicks {
            state.flags.food = false
            state.flags.lowFood = false
        }
        if state.thirst && !state.flags.water {
            state.flags.water = true
            q.append(.message(text.outOfWater))
        } else if !state.thirst && state.water < wneed * r.lowWaterTicks && !state.flags.lowWater {
            state.flags.lowWater = true
            q.append(.message(text.lowWater))
        }
        if state.water > wneed * r.rearmTicks {
            state.flags.water = false
            state.flags.lowWater = false
        }
        if hasDeficiency {
            if mode != .port && state.limes <= 0 && !state.flags.limes {
                state.flags.limes = true
                q.append(.message(text.preventiveGone))
            }
            if state.limes > 1 { state.flags.limes = false }
        }
    }

    /// For a journey with an engine: the tank is dry, or nearly.
    func fuelWarnings(_ q: inout [Interrupt], _ pace: PaceInfo) {
        let r = journey.rules
        if state.fuel <= 0 && !state.flags.fuel {
            state.flags.fuel = true
            q.append(.message(journey.text.outOfFuel))
        } else if state.fuel > 0 && state.fuel < pace.fuel * r.lowFuelTicks && !state.flags.lowFuel {
            state.flags.lowFuel = true
            q.append(.message(journey.text.lowFuel))
        }
        if state.fuel > pace.fuel * r.rearmTicks {
            state.flags.fuel = false
            state.flags.lowFuel = false
        }
    }

    // MARK: - Health (spec §5.3)

    func health(_ q: inout [Interrupt], _ mode: DayMode) {
        let r = journey.rules
        let text = journey.text
        let temp = state.temperature(in: state.region)
        let w = state.weather
        let pace = journey.pace(state.pace)
        let rations = journey.rations(state.rations)
        let harshSeason = journey.harshSeason(state)
        let deficiency = journey.deficiency
        let port: Port? = mode == .port ? journey.port(state.currentStop.id) : nil
        let livingNow = state.crew.indices.filter { state.crew[$0].alive }
        for (i, idx) in livingNow.enumerated() {
            var p = state.crew[idx]
            var d = rations.hp
            if mode == .sail {
                d += pace.hp
                if w.harsh != 0 { d -= w.harsh }
            }
            if mode == .sea { d += r.restAway }
            if mode == .port { d += r.restInPort }
            if state.starving { d -= r.starve }
            if state.thirst { d -= r.parch }
            let warm = i < state.clothes
            if mode != .port {
                if temp == .freezing {
                    d -= (warm ? r.freezeWarm : r.freezeBare) + (harshSeason ? r.freezeSeason : 0)
                } else if temp == .cold {
                    d -= warm ? 0 : r.coldBare
                } else if temp == .hot {
                    d -= r.heat
                }
            }
            if let a = p.ailment {
                d -= a.damage * (p.treated ? r.treated : 1)
                if a == deficiency {
                    if (state.limes > 0 || mode == .port) && chance(mode == .port ? r.cureInPort : r.cureAway) {
                        p.ailment = nil
                        q.append(.message(text.deficiencyCured(TextMarkup.escape(p.name))))
                    }
                } else {
                    p.ailDays -= mode == .port ? r.mendInPort : mode == .sea ? r.mendAtRest : 1
                    if p.ailDays <= 0 {
                        p.ailment = nil
                        p.treated = false
                        q.append(.message(text.wellAgain(TextMarkup.escape(p.name))))
                    }
                }
            } else {
                d += r.well
            }
            p.hp = min(100, max(0, p.hp + d))
            state.crew[idx] = p
            if p.ailment == nil && p.hp > 0 {
                var pr = r.sickBase + (100 - p.hp) * r.sickPerHP
                if state.rations == .bare { pr += r.sickBare }
                if state.starving { pr += r.sickStarving }
                if state.thirst { pr += r.sickThirst }
                if temp == .hot { pr += r.sickHeat }
                if (temp == .freezing || temp == .cold) && !warm && mode != .port { pr += r.sickCold }
                if port?.fever == true { pr += r.sickFeverPort }
                if mode == .port { pr *= r.sickPortFactor }
                if chance(pr) {
                    sicken(idx, &q, temp, port, nil)
                } else if let deficiency = deficiency, mode != .port, state.noCitrus > r.deficiencyAfter,
                          chance(min(r.deficiencyMax, Double(state.noCitrus - r.deficiencyAfter) * r.deficiencyRate))
                {
                    sicken(idx, &q, temp, nil, deficiency)
                }
            }
        }
        deaths(&q)
    }

    func sicken(_ idx: Int, _ q: inout [Interrupt], _ temp: Temp, _ port: Port?, _ force: Ailment?) {
        let pool: [Ailment]
        if let force = force {
            pool = [force]
        } else {
            pool = journey.sickPool(self, temp, port)
        }
        // The pick spends its draw even from a pool of one.
        let a = pick(pool)!
        state.crew[idx].ailment = a
        state.crew[idx].ailDays = Double(ri(a.duration.lowerBound, a.duration.upperBound))
        state.crew[idx].treated = false
        var t = journey.text.hasAilment(TextMarkup.escape(state.crew[idx].name), a)
        if a == journey.deficiency {
            t += journey.text.deficiencyHint
        } else if state.meds > 0 {
            state.meds -= 1
            state.crew[idx].treated = true
            t += journey.text.medsUsed(state.meds)
        }
        q.append(.message(t))
    }

    func deaths(_ q: inout [Interrupt]) {
        for idx in state.crew.indices where state.crew[idx].alive && state.crew[idx].hp <= 0 {
            state.crew[idx].alive = false
            let p = state.crew[idx]
            let text = journey.text
            let cause = p.ailment?.deathName
                ?? (state.thirst ? text.causeThirst : state.starving ? text.causeStarvation : text.causeExhaustion)
            if p.isCaptain {
                state.over = true
                q.append(.gameOver(title: text.leaderDied(TextMarkup.escape(p.name), cause), body: text.leaderDiedBody))
                return
            }
            q.append(.burial(crewID: p.id, cause: cause))
        }
    }

    // MARK: - Ship wear (spec §5.4)

    func wear(_ q: inout [Interrupt], _ reg: Region) {
        let r = journey.rules
        let text = journey.text
        let w = state.weather
        state.sails = max(0, state.sails - journey.pace(state.pace).wear * w.wear
            * rnd(r.wearJitter.lowerBound, r.wearJitter.upperBound))
        let hd = journey.structureDamage(self, reg)
        state.hull = max(0, state.hull - hd)
        if state.hull < r.spoilBelow && state.food > r.spoilFoodOver && chance(r.spoilChance) {
            let l = ri(r.spoil.lowerBound, r.spoil.upperBound)
            state.food -= Double(l)
            q.append(.message(text.spoiled(l)))
        }
        if state.hull < r.hullWarn && !state.flags.hull {
            state.flags.hull = true
            q.append(.message(text.hullWarning))
        }
        if state.hull > r.warnRearm { state.flags.hull = false }
        if state.sails < r.sailsWarn && !state.flags.sails {
            state.flags.sails = true
            q.append(.message(text.sailsWarning))
        }
        if state.sails > r.warnRearm { state.flags.sails = false }
        if r.wearWrecks { checkSink(&q) }
    }

    func checkSink(_ q: inout [Interrupt]) {
        if state.hull <= 0 && !state.over {
            state.hull = 0
            state.over = true
            q.append(.gameOver(title: journey.text.wrecked(TextMarkup.escape(state.ship)),
                               body: journey.text.wreckedBody))
        }
    }

    // MARK: - Days without sailing (spec §5.5)

    /// Rest, repairs, foraging: time passes, the crew eats and heals or sickens; the vessel
    /// doesn't move or wear. In port the weather is fair.
    public func passDays(_ n: Int, _ mode: DayMode) -> [Interrupt] {
        var q: [Interrupt] = []
        var i = 0
        while i < n && !state.over {
            state.day += 1
            state.weather = mode != .port ? rollWeather(state.region) : journey.fairWeather
            consume(&q, mode)
            health(&q, mode)
            if !state.over { journey.tick(self, &q, mode, state.region) }
            i += 1
        }
        return q
    }
}
