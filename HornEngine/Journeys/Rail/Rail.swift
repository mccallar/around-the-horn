#if os(WASI)
import FoundationEssentials
#else
import Foundation
#endif

// The Iron Road: 1869. Omaha to Sacramento on the new Pacific Railroad, 1,776 miles with a
// chartered freight, a wood-burning engine and five people, a few weeks after the last
// spike.
//
// A turn is four hours. What it is about: firewood (dear on the plains, free in a river if
// you can snag it), water for the boiler across three deserts, two long grades where a
// helper engine earns its fee, the engine and the running gear wearing out under you, the
// season, and a contract date. Tables are in RailData.swift; events and set pieces in
// Rail+Events.swift. Spec and the bot's numbers: docs/journeys/rail.md.
//
// Stock roles: `sails` is the engine, `hull` the cars and running gear; `sailcloth` is
// boiler fittings, `timber` car spares, `clothes` blankets, `tackle` grapnel line (casts),
// `fuel` firewood in TENTHS of a cord, `water` the tank car's reserve.

public final class Rail: Journey {
    public static let id = "rail"

    init() {
        super.init(id: Self.id, text: Self.strings)
        title = "The Iron Road"
        subtitle = "1869 · Omaha to Sacramento on the new Pacific Railroad"
        blurb = "Seventeen hundred miles of brand-new track, a wood-burning engine with opinions, three deserts, two mountain ranges and a freight contract with a date on it."
        items = RailData.items
        stops = RailData.stops
        regions = RailData.regions
        ports = Self.depots
        weathers = RailData.weathers
        fairWeather = RailData.fair
        ailments = [RailData.mountainFever, RailData.exhaustion, RailData.crushedHand, RailData.scald]

        roles[.merchant] = RoleInfo(label: "A Chicago freight contractor", title: "freight contractor",
                                    money: 1000, mend: 25, patch: 20, catchLimit: 40, aim: 1.5)
        roles[.shipwright] = RoleInfo(label: "A Pittsburgh boilermaker", title: "boilermaker",
                                      money: 520, mend: 40, patch: 35, catchLimit: 40, aim: 1.5)
        roles[.whaler] = RoleInfo(label: "A St. Louis river hand", title: "river hand",
                                  money: 350, mend: 25, patch: 20, catchLimit: 60, aim: 4)

        paces[.easy] = PaceInfo(name: "Easy", speed: 32, hp: 0.5, wear: 1.3, fuel: 7,
                                desc: "About 32 miles in four hours. Kind to the engine and the woodpile.")
        paces[.steady] = PaceInfo(name: "Timetable", speed: 42, hp: 0, wear: 2.6, fuel: 10,
                                  desc: "About 42 miles in four hours and a cord of wood to do it.")
        paces[.full] = PaceInfo(name: "Wide open", speed: 54, hp: -1, wear: 4.4, fuel: 15,
                                desc: "About 54 miles in four hours. Half again the wood, most of twice the wear, and nobody sleeps.")

        rationings[.filling] = RationsInfo(name: "Hearty", amount: 0.5, hp: 1, desc: "Three square meals a day.")
        rationings[.meager] = RationsInfo(name: "Lean", amount: 0.35, hp: -0.3, desc: "Two meals and a lot of coffee.")
        rationings[.bare] = RationsInfo(name: "Scraps", amount: 0.2, hp: -2.2, desc: "Hard bread and the memory of bacon.")

        departures = RailData.departures
        firstNames = RailData.firstNames
        vesselNames = RailData.vesselNames
        defaultTopTen = RailData.defaultTopTen
        quarry = RailData.drift
        forageSeconds = 25
        forageReward = .fuel

        rules.tickHours = 4
        rules.startHour = 6
        rules.water = 0.5
        rules.hotWater = 1
        rules.rainCatch = 20...60
        rules.lowFoodTicks = 6
        rules.lowWaterTicks = 6
        rules.lowFuelTicks = 3
        rules.rearmTicks = 8
        rules.restChoices = [1, 2, 3, 6]
        rules.starve = 4
        rules.parch = 6
        rules.freezeWarm = 0.8
        rules.freezeBare = 3
        rules.freezeSeason = 0.4
        rules.coldBare = 1.2
        rules.heat = 0.5
        rules.sickBase = 0.011
        rules.hullCreep = 0.3
        rules.spoilBelow = -1
        rules.eventChance = 0.2
        rules.yardHull = 1.5
        rules.yardSails = 1.5
        rules.wearWrecks = false
        rules.noFuelSpeed = RailData.noWoodSpeed
        rules.burnsPartLoad = true
    }

    // MARK: - Sentences

    static let strings = JourneyText(
        rainCaught: { "The car roofs run \($0) gallons of rainwater into the tank." },
        outOfFood: "[red]The grub box is empty![/red] Nobody fires an engine for long on coffee.",
        lowFood: "The fireman, who also cooks, reports about a day of provisions left.",
        outOfWater: "[red]The kegs are dry and so is the tank car.[/red] The crew cannot go long like this.",
        lowWater: "There is barely a day of drinking water left aboard.",
        preventiveGone: "",
        outOfFuel: "[red]The woodpile is gone.[/red] From here the firebox gets sagebrush, fence posts and bad language, which will barely move her and are hard on the engine.",
        lowFuel: "The fireman can see the floor of the tender: about twelve hours of wood left.",
        deficiencyCured: { _ in "" },
        wellAgain: { "\($0) is fit for duty again." },
        hasAilment: { name, a in "\(name) has \(a.name)." },
        deficiencyHint: "",
        medsUsed: { " [dim]You open a medicine kit (\($0) left).[/dim]" },
        causeThirst: "thirst",
        causeStarvation: "hunger",
        causeExhaustion: "exhaustion",
        leaderDied: { name, cause in "You, Conductor \(name), have died of \(cause)." },
        leaderDiedBody: "The crew brings the train in to the next siding and wires the news east. The freight goes on, eventually, under somebody else's name.",
        spoiled: { "\($0) lbs of provisions have spoiled." },
        hullWarning: "[red]Every car is running rough.[/red] Hot bearings, worn brake shoes, a wheel with a flat on it. Mend the running gear soon.",
        sailsWarning: "[red]The engine is leaking steam at every joint.[/red] She can barely drag the train. Work on her if you can.",
        wrecked: { "The [i]\($0)[/i] is off the rails." },
        wreckedBody: "Something under the train finally let go. The engine is on her side in the ditch, the cars are stacked behind her like dropped cards, and everybody is alive to stand and look at it. The freight will go west on another train.",
        depart: { s in
            "The [i]\(TextMarkup.escape(s.ship))[/i] whistles off from the Omaha yard, \(s.dateText), with the freight due in Sacramento in twelve days and a consignee who will not wait past sixteen. Ahead: 1,776 miles of track so new the ties still smell of sap."
                + (s.food <= 0 ? " " + Rail.goingHungry : "")
        },
        noProvisions: "You can't pull out with nothing to eat aboard! The outfitter points you back at the provisions.",
        rested: { turns, h in
            "After \(turns * 4) hours laid over, your crew's health is [\(h.color)]\(h.text)[/\(h.color)]."
        },
        mended: { "Four hours with wrenches, flue plugs and a great deal of packing. [green](Engine now \($0)%)[/green]" },
        patched: { "New brasses, new brake shoes, and every pin checked twice. [green](Running gear now \($0)%)[/green]" },
        yardHull: "The car shop goes over the train from pilot to caboose. She rolls like new.",
        yardSails: "The roundhouse men pull the flues, pack the glands and send the engine out blowing a clean stack.",
        noTradersLeft: "Nobody else around the depot wants to trade today.",
        nobodyWants: "You ask up and down the platform, but nobody wants what you have.",
        traderIntro: "A freighter on the depot platform looks over your stores.",
        noTackle: "You have no grapnel line left.",
        tooRough: "Nobody is going down to a river bank in this weather.",
        catchReport: { caught, limit, got in
            var t = caught > 0 ? "You hauled out [amber]\(RailData.cords(caught))[/amber] of driftwood." : "You hauled out nothing but weed."
            if caught > limit { t += " The crew can only buck and stack \(RailData.cords(limit)) before the light goes." }
            if got != 0 { t += " [green]+\(RailData.cords(got)) of firewood.[/green]" }
            t += " [dim]Four hours have passed.[/dim]"
            return t
        },
        defaultEpitaph: "Clear track ahead, friend.",
        tradeOffer: { intro, give, want in
            "\(intro)\n\nThey will give you [amber]\(give)[/amber] for [amber]\(want)[/amber]."
        },
        tradeHave: { "[dim]You have \($0).[/dim]" },
        tradeAccept: "Accept the trade",
        tradeDecline: "Decline",
        tradeDone: "Done. Goods change hands.",
        reached: { stop, s in "You have reached \(stop.name).\n[dim]\(s.dateText) · mile \(stop.mile)[/dim]" },
        goAshore: "Pull into the yard and lay over",
        passBy: "Take the main line straight through",
        wavesGoodbye: { "\($0) swings down, lifts a hat and walks off toward town." },
        scoreSurvivors: { alive, health in "\(alive) aboard, health \(health.text)" },
        scoreCondition: "Engine & running gear",
        scoreProvisions: "Provisions & water",
        scoreStores: "Wood, stores & spares",
        scoreCash: "Cash",
        ranks: ["Superintendent of the Line", "Master Conductor", "Brakeman", "Section Hand"])

    static let onTimeLabel = "Days in hand on the contract"

    // MARK: - Where and when

    /// The tables give the mild months; the season moves everything.
    public override func temperature(_ s: GameState, in reg: Region) -> Temp {
        let mountain = reg.has("mountain")
        let dry = reg.has("dry")
        switch RailData.season(s.month) {
        case .summer:
            if dry { return .hot }
            if mountain { return .cool }
            return s.month == 7 && !reg.has("river") ? .hot : .warm
        case .autumn:
            if mountain { return s.month == 10 ? .cold : .cool }
            return reg.temp
        case .winter:
            if mountain { return .freezing }
            return reg.has("valley") ? .cool : .cold
        case .spring:
            return mountain ? .cold : .cool
        }
    }

    /// December and January.
    public override func harshSeason(_ s: GameState) -> Bool { s.month == 11 || s.month == 0 }

    override func weatherWeights(_ e: GameEngine, _ reg: Region, cursed: Bool) -> WeatherOdds {
        var w = reg.weights
        func scale(_ k: Weather, _ f: Double) {
            if let i = w.firstIndex(where: { $0.0 == k }) { w[i].1 *= f }
        }
        let month = e.state.month
        switch RailData.season(month) {
        case .summer:
            scale(RailData.heat, month == 7 ? 3 : 2)
            scale(RailData.thunder, month == 7 ? 1.2 : 2)
            scale(RailData.dust, 1.5)
            scale(RailData.fog, 0.5)
            scale(RailData.snow, 0)
            scale(RailData.blizzard, 0)
        case .autumn:
            scale(RailData.heat, 0.5)
            if month == 10 { scale(RailData.snow, 2) } else { scale(RailData.blizzard, 0.4) }
        case .winter:
            let deep = harshSeason(e.state)
            scale(RailData.snow, deep ? 4 : 3)
            scale(RailData.blizzard, deep ? 5 : 3)
            scale(RailData.heat, 0)
            scale(RailData.thunder, 0)
            scale(RailData.dust, 0.3)
            scale(RailData.rain, reg.has("valley") ? 2 : 0.4)
        case .spring:
            scale(RailData.rain, 1.8)
            scale(RailData.thunder, 1.5)
            scale(RailData.snow, 1.5)
            scale(RailData.heat, 0.3)
        }
        return w
    }

    // MARK: - A turn under way

    static func helperKey(_ reg: Region) -> String { "rail.helper.\(reg.id.rawValue)" }

    /// What the boiler can still take from the tank car.
    static func boilerWater(_ s: GameState) -> Double { max(0, s.water - RailData.kegs) }

    /// Grades, unless a helper is coupled on; a dry boiler; a descent taken on the retainers.
    /// A turn with too little wood for the pace burns what there is and crawls the rest on
    /// the engine's `noFuelSpeed` (`rules.burnsPartLoad`), which is applied next; the share
    /// run without wood is noted here for `tick`, which charges the engine for it.
    override func adjustSpeed(_ e: GameEngine, _ reg: Region, _ sp: inout Double) {
        let burn = e.journey.pace(e.state.pace).fuel
        e.state.vars[Self.noWoodKey] = e.state.fuel < burn ? 1 - max(0, e.state.fuel) / burn : nil
        let grade = reg.num("grade")
        if grade < 1 && e.state.vars[Self.helperKey(reg)] != 1 { sp *= grade }
        let dry = reg.num("dry", or: 0)
        if dry > 0 && Self.boilerWater(e.state) < dry { sp *= 0.5 }
        if reg.has("descent") && e.state.vars["rail.retainers"] == 1 { sp *= 0.6 }
    }

    /// Rough weather shakes the cars as it would a hull; a long descent eats brake shoes.
    override func structureDamage(_ e: GameEngine, _ reg: Region) -> Double {
        var hd = super.structureDamage(e, reg)
        if reg.has("descent") {
            var brake = e.state.pace == .full ? 1.6 : e.state.pace == .easy ? 0.4 : 0.8
            if e.state.vars["rail.retainers"] == 1 { brake *= 0.4 }
            hd += brake
        }
        return hd
    }

    static let noWoodKey = "rail.noWood"

    override func tick(_ e: GameEngine, _ q: inout [Interrupt], _ mode: GameEngine.DayMode, _ reg: Region) {
        // A turn run, all or partly, on fence posts and sagebrush.
        if mode == .sail, let unfed = e.state.vars.removeValue(forKey: Self.noWoodKey) {
            e.state.sails = max(0, e.state.sails - unfed * e.rnd(RailData.noWoodWear.lowerBound, RailData.noWoodWear.upperBound))
            e.state.note = unfed < 1 ? "The wood gives out partway, and the fireman finishes the run on fence posts."
                : "No wood. The firebox is getting fence posts, sagebrush and anything else that will burn."
        }

        // The boiler's share, in the deserts.
        let dry = reg.num("dry", or: 0)
        if mode == .sail && dry > 0 {
            let have = Self.boilerWater(e.state)
            if have >= dry {
                e.state.water -= dry
            } else {
                e.state.water -= have
                e.state.sails = max(0, e.state.sails - e.rnd(2, 5))
                e.state.note = "The boiler is short of water. You creep from seep to seep with buckets."
            }
            let left = Self.boilerWater(e.state)
            if left < dry * 2 && e.state.vars["rail.dryWarned"] != 1 {
                e.state.vars["rail.dryWarned"] = 1
                q.append(.message("[red]The tank car is nearly dry[/red] and there is no water by the track in this country. When it gives out the engine will crawl, and scorch her flues doing it."))
            }
        }
        if Self.boilerWater(e.state) >= 320 { e.state.vars["rail.dryWarned"] = 0 }

        // Nobody goes thirsty beside a river or in a snowstorm: the crew fills the kegs.
        // The boiler is another matter; it wants a tank, not a bucket.
        let w = e.state.weather
        if mode != .port && e.state.water < RailData.kegs
            && (reg.has("river") || w == RailData.snow || w == RailData.blizzard) {
            if e.state.water < RailData.kegs / 2 {
                e.state.note = reg.has("river") ? "The crew fills the water kegs at the river." : "The crew melts snow for the water kegs."
            }
            e.state.water = RailData.kegs
        }

        // The contract.
        if e.state.day >= RailData.forfeitTurns {
            e.state.over = true
            q.append(.gameOver(title: "The contract is forfeit.",
                               body: "Sixteen days out of Omaha and not yet in Sacramento. The consignee has wired to say the freight may now go wherever it likes, and so may you. The [i]\(TextMarkup.escape(e.state.ship))[/i] is put on a siding to wait for a buyer."))
        } else if e.state.day >= RailData.contractTurns && e.state.vars["rail.lateWarned"] != 1 {
            e.state.vars["rail.lateWarned"] = 1
            q.append(.message("[amber]Twelve days out. The freight is now late.[/amber] The consignee will hold the contract open four more days and not an hour longer."))
        }
    }

    override func sickPool(_ e: GameEngine, _ temp: Temp, _ port: Port?) -> [Ailment] {
        var pool = ailments
        if temp == .hot { pool.append(RailData.sunstroke) }
        if temp == .cold || temp == .freezing { pool.append(RailData.lungChill) }
        if port == nil && e.state.region.has("dry") { pool.append(RailData.alkali) }
        return pool
    }

    /// Driftwood needs a river that is running.
    override func forageRefusal(_ e: GameEngine) -> String? {
        if let no = super.forageRefusal(e) { return no }
        let reg = e.state.region
        if !reg.has("river") { return "There is no river by the line here, and nothing afloat in the ditches." }
        if e.state.temperature(in: reg) == .freezing { return "The river is iced from bank to bank." }
        return nil
    }

    // MARK: - Leaving Omaha with nothing left to buy provisions with (D22)

    /// Omaha sends a train with no provisions back to the outfitter while the purse runs to
    /// a step of them; with nothing left to buy them with, holding her there would hold her
    /// for good, so the crew goes hungry (D22).
    public override func departsUnfed(_ s: GameState) -> Bool { !firstPortSells(.food, s) }

    /// The departure's last sentence for a train that leaves Omaha with no provisions.
    public static let goingHungry = "There isn't a pound of provisions aboard, and too little in the purse to buy any, so the crew will go hungry until somebody sells you some."

    // MARK: - Events, stops and answers (Rail+Events, Rail+Depots, Rail+Choices)

    override func events(_ e: GameEngine, _ reg: Region) -> [JourneyEvent] { roadEvents(e, reg) }

    /// Nothing happens to a train that has just given out but the breakdown itself.
    override func dayEvents(_ e: GameEngine, _ q: inout [Interrupt], _ reg: Region) {
        if Self.brokenDown(e.state) { return }
        super.dayEvents(e, &q, reg)
    }

    /// Given out, she stands (Rail+Breakdown); mended, she meets the set piece she reached as
    /// she gave out before she turns another wheel.
    override func stalled(_ e: GameEngine) -> [Interrupt]? {
        if let stuck = breakdown(e) { return stuck }
        guard let i = e.state.vars.removeValue(forKey: Self.heldKey).map({ Int($0) }), stops.indices.contains(i) else { return nil }
        let q = setPiece(e, stops[i])
        return q.isEmpty ? nil : q
    }

    /// The set piece a train reached on the turn she gave out, held until she is mended.
    static let heldKey = "rail.heldSetPiece"

    override func arrive(_ e: GameEngine, _ stop: Stop) -> [Interrupt] {
        if stop.type == .line && Self.brokenDown(e.state), let i = stops.firstIndex(where: { $0.id == stop.id }) {
            e.state.vars[Self.heldKey] = Double(i)
            return [.message("The [i]\(TextMarkup.escape(e.state.ship))[/i] gets as far as \(stop.name), and not a foot further.")]
        }
        return helperOffer(e, stop) ?? super.arrive(e, stop)
    }

    override func special(_ e: GameEngine, _ stop: Stop) -> [Interrupt] { setPiece(e, stop) }

    override func resolve(_ e: GameEngine, _ key: String, _ args: [String], _ option: Int) -> [Interrupt] {
        key == "breakdown" ? answerBreakdown(e, args, option) : answer(e, key, args, option)
    }

    // MARK: - Score

    public override func score(_ s: GameState) -> Score {
        let base = super.score(s)
        let early = max(0, RailData.contractTurns - s.day)
        return Score(lines: base.lines + [.init(label: Self.onTimeLabel, points: early * RailData.bonusPerTurn)],
                     multiplier: base.multiplier)
    }
}
