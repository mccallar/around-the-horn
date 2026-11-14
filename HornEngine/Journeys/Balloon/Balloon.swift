import Foundation

// The Jet Stream: 1999. Round the world by balloon, east from Marrakech on the winter jet
// stream, 18,300 nautical miles until you cross the meridian of Marrakech again from the
// west, with five landing fields along the way and two oceans between them.
//
// A turn is a four-hour watch. What it is about: propane, burned every watch whether you
// are going anywhere or not (more in the cold, a little less loitering, nothing on the
// ground, 25 gallons to climb away from a field); lift, which leaks, ices and is torn by
// storms, and which ballast wins back; the cold of the jet against the speed of it; stale
// air in a sealed capsule; and the Pacific, five thousand miles with nowhere to land.
// Tables are in BalloonData.swift; events in Balloon+Events.swift; the fields in
// Balloon+Fields.swift; set pieces and answers in Balloon+Choices.swift. Spec and the bot's
// numbers: docs/journeys/balloon.md.
//
// Stock roles: `hull` is lift, `sails` the burners; `timber` is ballast (a sack wins back
// lift), `sailcloth` burner spares, `limes` CO2 scrubbers (against stale air), `clothes`
// down suits, `tackle` fishing line (casts, twenty to a spool), `fuel` propane in gallons.
// The pace is the altitude: `easy` low and slow, `steady` the middle air, `full` the jet.

public final class Balloon: Journey {
    public static let id = "balloon"

    init() {
        super.init(id: Self.id, text: Self.strings)
        title = "The Jet Stream"
        subtitle = "1999 · Round the world by balloon, riding the winter jet stream"
        blurb = "Eighteen thousand miles round the world in a balloon with a sealed capsule for five: five landing fields, two oceans, the Himalaya, and a propane burner that has to be fed every watch, going anywhere or not."
        items = BalloonData.items
        stops = BalloonData.stops
        regions = BalloonData.regions
        ports = Self.fields
        weathers = BalloonData.weathers
        fairWeather = BalloonData.steady
        deficiency = BalloonData.staleAir
        ailments = BalloonData.mildPool

        roles[.merchant] = RoleInfo(label: "Be a chocolate maker from Zurich", title: "chocolate maker",
                                    money: 15000, mend: 25, patch: 20, catchLimit: 40, aim: 1.5)
        roles[.shipwright] = RoleInfo(label: "Be a balloon builder from Bristol", title: "balloon builder",
                                      money: 7250, mend: 35, patch: 30, catchLimit: 40, aim: 1.5)
        roles[.whaler] = RoleInfo(label: "Be a bush pilot from Alaska", title: "bush pilot",
                                  money: 6500, mend: 25, patch: 20, catchLimit: 60, aim: 4)

        paces[.easy] = PaceInfo(name: "Low & slow", speed: 110, hp: 0.5, wear: 0.6, fuel: 12,
                                desc: "Around 10,000 feet. Slow winds, gentle on burners and crew.")
        paces[.steady] = PaceInfo(name: "Middle air", speed: 150, hp: 0, wear: 1, fuel: 14,
                                  desc: "Around 20,000 feet. A sensible height.")
        paces[.full] = PaceInfo(name: "The jet", speed: 185, hp: -1, wear: 2, fuel: 16,
                                desc: "Around 33,000 feet, in the jet stream. Fast and frugal, but bitter cold and hard on everything.")

        rationings[.filling] = RationsInfo(name: "Hot meals", amount: 0.5, hp: 1,
                                           desc: "8 oz a watch, heated on the burner ring.")
        rationings[.meager] = RationsInfo(name: "Half portions", amount: 0.3, hp: -0.3,
                                          desc: "About 5 oz a watch. Nobody is ever quite full.")
        rationings[.bare] = RationsInfo(name: "Crackers & cocoa", amount: 0.2, hp: -2.2,
                                        desc: "About 3 oz a watch, and a mug of something warm.")

        departures = BalloonData.departures
        firstNames = BalloonData.firstNames
        vesselNames = BalloonData.vesselNames
        defaultTopTen = BalloonData.defaultTopTen
        quarry = BalloonData.fish
        forageSeconds = 25
        forageReward = .food

        rules.tickHours = 4
        rules.startHour = 8
        // A watch that starts with any propane is flown under power; one that starts dry
        // drifts (`adjustSpeed`).
        rules.noFuelSpeed = 1
        rules.water = 0.2
        rules.hotWater = 0.3
        rules.rainCatch = 2...6
        rules.lowFoodTicks = 12
        rules.lowWaterTicks = 6
        rules.lowFuelTicks = 6
        rules.rearmTicks = 18
        rules.freezeWarm = 1.6
        rules.freezeSeason = 0
        rules.deficiencyAfter = 18
        rules.deficiencyRate = 0.006
        rules.spoilBelow = 35
        rules.spoilFoodOver = 20
        rules.spoil = 5...15
        rules.hullCreep = BalloonData.seep
        rules.yardHull = 20
        rules.yardSails = 15
        rules.tradeWorth = 250
        rules.tradeCash = 300
        rules.tradeSize = 250...700
    }

    // MARK: - Sentences

    static let strings = JourneyText(
        rainCaught: { "Melted \($0) gallons of rime off the hatch rim." },
        outOfFood: "[red]The food lockers are empty![/red] The crew is going hungry.",
        lowFood: "The flight engineer reckons there's food for about two days.",
        outOfWater: "[red]The water jugs are empty![/red] Without water, the crew won't last long.",
        lowWater: "The water is nearly gone — about a day's worth.",
        preventiveGone: "The last scrubber canister is spent. The air will turn stale in a few days unless you land.",
        outOfFuel: "[red]The last propane tank sputters dry![/red] Without the burners you sink, and keep sinking. Drop ballast and make for a field.",
        lowFuel: "The flight engineer taps the gauge: propane for about a day.",
        deficiencyCured: { "\($0) is breathing easier." },
        wellAgain: { "\($0) is well again." },
        hasAilment: { name, a in "\(name) has \(a.name)." },
        deficiencyHint: " [dim]Pounding headache, short of breath. Fresh scrubbers or a landing will clear it.[/dim]",
        medsUsed: { " [dim]You open a medical kit (\($0) left).[/dim]" },
        causeThirst: "thirst",
        causeStarvation: "starvation",
        causeExhaustion: "exhaustion",
        leaderDied: { name, cause in "You, \(name), have died of \(cause)." },
        leaderDiedBody: aloftWithCrew,
        spoiled: { "You're sinking. Over the side go \($0) lbs of rations to keep you up." },
        hullWarning: "[red]The balloon won't hold its height.[/red] You need lift — drop ballast, and soon.",
        sailsWarning: "[red]The burners cough and spit.[/red] She can barely climb. Service them if you can.",
        wrecked: { "The [i]\($0)[/i] has come down." },
        wreckedBody: downOnLand,
        depart: { s in
            "The [i]\(TextMarkup.escape(s.ship))[/i] lifts off from the launch field outside Marrakech at 0800 GMT on \(BalloonData.dateOnly(s)). The crowd shrinks to a scatter of dots, and the Atlas rises white to the south. Ahead lie eighteen thousand miles of sky."
        },
        noProvisions: "The launch director won't let you go: you need food aboard and at least 25 gallons of propane to climb out.",
        rested: { turns, h in
            "After \(turns) \(turns == 1 ? "watch" : "watches") of rest, your crew's health is [\(h.color)]\(h.text)[/\(h.color)]."
        },
        mended: { "The flight engineer strips and cleans the burners one at a time, wearing gloves. [green](Burners now \($0)%)[/green]" },
        patched: { "You cut away a sack of ballast and let the balloon settle at its new height. [green](Lift now \($0)%)[/green]" },
        yardHull: "The riggers run a hose from the helium trucks for a whole watch. She stands up tall and tight again.",
        yardSails: "A burner man from the ground team fits new jets and valves all round. They roar like new.",
        noTradersLeft: "Nobody else at the field wants to trade with you today.",
        nobodyWants: "You walk the field, but nobody wants what you have.",
        traderIntro: "Someone at the edge of the field looks over your stores.",
        noTackle: "You have no fishing line left.",
        tooRough: "The air is far too rough to come down that low.",
        catchReport: { caught, limit, got in
            var t = caught > 0 ? "You caught [amber]\(caught) lbs[/amber] of fish." : "You caught nothing."
            if caught > limit { t += " The cool box holds \(limit) lbs before the rest goes bad." }
            if got > 0 { t += " [green]+\(got) lbs of rations.[/green]" }
            t += " [dim]The capsule is aired out. A watch has passed.[/dim]"
            return t
        },
        defaultEpitaph: "Blue skies, friend.",
        tradeOffer: { intro, give, want in
            "\(intro)\n\nThey'll give you [amber]\(give)[/amber] for [amber]\(want)[/amber]."
        },
        tradeHave: { "[dim]You have \($0).[/dim]" },
        tradeAccept: "Accept the trade",
        tradeDecline: "Decline",
        tradeDone: "Done. Goods change hands.",
        reached: { stop, s in
            "You have reached \(stop.name).\n[dim]\(s.dateText) · day \(s.day / 6 + 1) of the flight[/dim]"
        },
        goAshore: "Land at the field",
        passBy: "Fly on without landing",
        wavesGoodbye: { "\($0) climbs down and waves you off from the edge of the field." },
        scoreSurvivors: { alive, health in "\(alive) aboard, health \(health.text)" },
        scoreCondition: "Lift & burners",
        scoreProvisions: "Propane, food & water",
        scoreStores: "Stores & spares",
        scoreCash: "Cash",
        ranks: ["Master Aeronaut", "Balloon Captain", "Co-pilot", "Ballast"])

    static let aloftWithCrew = "Your co-pilot brings the balloon down at the first safe place, and the ground team flies everyone home. The attempt is over."
    static let aloftAlone = "With nobody at the burners, the balloon drifts on alone until it settles, far from anywhere. A search plane finds it two days later. The attempt is over."
    static let onTheGround = "The ground team packs up the balloon and flies everyone home. The attempt is over."
    static let downOnLand = "With no lift left, you pick the emptiest ground in sight and come down hard in a cloud of dust and torn fabric. Everyone climbs out. The attempt is over."
    static let downAtSea = "With no lift left, the capsule settles onto the swell and the envelope folds over it like a tent. A freighter answers your mayday and takes everyone aboard. The balloon is lost, and so is the attempt."

    /// The finale's opening lines, for the skin: the crossing, the landing, who climbs out.
    public static func finale(_ s: GameState) -> String {
        let days = s.day / 6
        let hours = (s.day % 6) * 4
        let took = "\(days) \(days == 1 ? "day" : "days")" + (hours == 0 ? "" : " and \(hours) hours")
        let out = s.living.count > 1
            ? " Your crew climbs out, stiff and blinking, and stands on the ground as if it might move."
            : " You climb out alone and stand on the ground as if it might move."
        return "Finish line! The [i]\(TextMarkup.escape(s.ship))[/i] crosses eight degrees west, the meridian of Marrakech, at \(BalloonData.clock(s)) GMT on \(BalloonData.dateOnly(s)) — \(took) after you lifted off.\n\nAt the next sunrise you come down on a stony plain outside the city, bounce twice, and stop. Children run out from a village to see what has fallen out of the sky." + out
    }

    /// The game-over footer: how far you got, and how far there was still to go.
    public static func shortfall(_ s: GameState) -> String {
        let total = BalloonData.stops[BalloonData.stops.count - 1].mile
        return "\(s.dateText) · \(formatNumber(Double(s.mile))) nautical miles flown, \(formatNumber(Double(total - s.mile))) short of the finish line."
    }

    // MARK: - Where and when

    static func south(_ s: GameState) -> Bool { s.vars[BalloonData.southKey] == 1 }

    /// The southern track replaces the two northern Pacific regions.
    public override func region(_ s: GameState, at m: Int) -> Region {
        if Self.south(s) && m >= BalloonData.forkFrom && m < BalloonData.forkTo {
            return m < BalloonData.southTrack.to ? BalloonData.southTrack : BalloonData.subtropic
        }
        return super.region(s, at: m)
    }

    /// On the ground, the field's own air; aloft, midwinter freezes the high regions and
    /// the North Atlantic is cold from November to March.
    public override func temperature(_ s: GameState, in reg: Region) -> Temp {
        if s.atPort, let t = BalloonData.fieldTemp[s.currentStop.id] { return t }
        let m = s.month
        if reg.has("high") && reg.temp == .cold && (m == 11 || m == 0 || m == 1) { return .freezing }
        if reg.has("atlantic") && (m >= 10 || m <= 2) { return .cold }
        return reg.temp
    }

    override func weatherWeights(_ e: GameEngine, _ reg: Region, cursed: Bool) -> WeatherOdds {
        var w = reg.weights
        let m = e.state.month
        if reg.has("jet") && m == 10 {
            bump(&w, BalloonData.jet) { $0 * 0.6 }
            bump(&w, BalloonData.storm) { $0 + 6 }
        }
        if reg.has("jet") && (m == 2 || m == 3) {
            bump(&w, BalloonData.jet) { $0 * 0.5 }
            bump(&w, BalloonData.light) { $0 + 12 }
            bump(&w, BalloonData.stalled) { $0 + 8 }
            bump(&w, BalloonData.storm) { $0 + 6 }
        }
        if reg.has("atlantic") && (m == 11 || m == 0 || m == 1) {
            bump(&w, BalloonData.shear) { $0 + 8 }
            bump(&w, BalloonData.storm) { $0 + 5 }
        }
        if cursed {
            bump(&w, BalloonData.shear) { $0 + 20 }
            bump(&w, BalloonData.storm) { $0 + 15 }
            bump(&w, BalloonData.stalled) { $0 + 10 }
        }
        return w
    }

    // MARK: - A watch in the air

    /// One person can fly a balloon; fewer hands only mean fewer turns at the burners.
    public override func crewFactor(_ n: Int) -> Double { n >= 3 ? 1 : n == 2 ? 0.9 : 0.75 }

    /// Gallons a watch at this altitude in this air.
    func burn(_ s: GameState, _ reg: Region) -> Double {
        pace(s.pace).fuel * BalloonData.burnFactor(s.temperature(in: reg))
    }

    /// A watch that starts with dry tanks drifts on the helium alone. Otherwise the burn
    /// follows the cold: the shared rule takes the altitude's gallons next, so the tank is
    /// left holding what makes that come out right (and nothing, if the watch empties it).
    override func adjustSpeed(_ e: GameEngine, _ reg: Region, _ sp: inout Double) {
        let start = e.state.fuel
        e.state.vars[BalloonData.startFuelKey] = start
        let base = pace(e.state.pace).fuel
        if start <= 0 {
            sp *= BalloonData.driftSpeed / pace(e.state.pace).speed
            return
        }
        let b = burn(e.state, reg)
        e.state.fuel = start >= b ? start - b + base : 0
    }

    /// Helium seeps every watch flown; the sun, rime, rough air and storms take more.
    override func structureDamage(_ e: GameEngine, _ reg: Region) -> Double {
        let w = e.state.weather
        let pace = e.state.pace
        var d = rules.hullCreep
        if w == BalloonData.sun { d += e.rnd(0, 0.4) }
        if w == BalloonData.snow && reg.has("ice") { d += e.rnd(0.5, 1.5) }
        if w == BalloonData.shear { d += e.rnd(0, 0.8) * (pace == .full ? 1.5 : 1) }
        if w == BalloonData.storm {
            d += e.rnd(1, 2.6) * (pace == .full ? 1.6 : pace == .easy ? 0.7 : 1) * (reg.has("ice") ? 1.5 : 1)
        }
        return d
    }

    public override func wreckedTitle(_ s: GameState) -> String {
        let title = super.wreckedTitle(s)
        guard s.region.has("sea") else { return title }
        return "The [i]\(TextMarkup.escape(s.ship))[/i] has come down in the sea."
    }

    public override func wreckedBody(_ s: GameState) -> String {
        s.region.has("sea") ? Self.downAtSea : Self.downOnLand
    }

    /// The shared rule stops at the pilot's death, so anyone it would have taken in the
    /// same watch is still marked alive: only someone with health left can land her.
    public override func leaderDiedBody(_ s: GameState) -> String {
        if s.atPort { return Self.onTheGround }
        return s.living.contains { $0.hp > 0 } ? Self.aloftWithCrew : Self.aloftAlone
    }

    /// Dry tanks cost lift every watch aloft; loitering burns its own, smaller share; the
    /// first watch after a relaunch says what it cost.
    override func tick(_ e: GameEngine, _ q: inout [Interrupt], _ mode: GameEngine.DayMode, _ reg: Region) {
        let dry: Bool
        switch mode {
        case .port:
            return
        case .sail:
            dry = (e.state.vars[BalloonData.startFuelKey] ?? 1) <= 0
            if let r = e.state.vars[BalloonData.relaunchKey] {
                e.state.vars[BalloonData.relaunchKey] = nil
                let relaunched = "Relaunched. The climb back to cruising height burned \(Int(BalloonData.launchBurn)) gallons."
                if r == 2 {
                    let n = BalloonData.gallons(e.state.vars[BalloonData.toppedUpKey] ?? 0)
                    q.append(.message("The ground-team chief looks at your gauges, then at your wallet, and waves the fuel truck over. “On the sponsor's account,” he says. “Just enough to get you off the ground. After that you're drifting.” [dim](+\(n).)[/dim]"))
                    q.append(.message(relaunched))
                    q.append(.message(text.outOfFuel))
                } else if e.state.note.isEmpty || e.state.note == e.state.weather.note {
                    e.state.note = relaunched
                }
            }
        case .sea:
            let start = e.state.fuel
            dry = start <= 0
            if !dry {
                e.state.fuel = max(0, start - BalloonData.loiterBurn * BalloonData.burnFactor(e.state.temperature(in: reg)))
            }
        }
        if dry {
            e.state.hull -= BalloonData.emptyLift
            e.state.note = "The burners are cold. The balloon is sinking."
            e.checkSink(&q)
        }
    }

    /// The climb away from the ground. A field's ground team will not strand you: short of
    /// 25 gallons, they put in what the climb needs and you leave with an empty tank.
    override func leaving(_ e: GameEngine) {
        let burnt = BalloonData.launchBurn
        if e.state.fuel < burnt {
            e.state.vars[BalloonData.toppedUpKey] = burnt - e.state.fuel
            e.state.vars[BalloonData.relaunchKey] = 2
            e.state.fuel = burnt
            e.state.flags.fuel = true  // the warning comes after the ground team's word
        } else if e.state.stopIndex > 0 {
            e.state.vars[BalloonData.relaunchKey] = 1
        }
        e.state.fuel -= burnt
    }

    public override func mayDepart(_ s: GameState) -> Bool { s.fuel >= BalloonData.launchBurn }

    /// What the app should say instead of relaunching, or nil: you are on the ground, short
    /// of the climb's propane, and could buy a step of it here. With no money for it, the
    /// ground team pays. Aloft (resuming between fields) it is always nil.
    public static func relaunchRefusal(_ e: GameEngine) -> String? {
        guard e.state.atPort, let port = e.currentPort, e.state.fuel < BalloonData.launchBurn else { return nil }
        let step = Double(BalloonData.items.first { $0.key == .fuel }!.step)
        guard e.state.money >= step * port.price(.fuel) else { return nil }
        return "You need at least 25 gallons of propane to relaunch. The ground crew points at the fuel truck."
    }

    /// The region's thunderstorms, then the pack ice's roof, then one event on about one
    /// watch in nine.
    override func dayEvents(_ e: GameEngine, _ q: inout [Interrupt], _ reg: Region) {
        let forecast = e.state.vars[BalloonData.forecastKey] == 1
        if reg.has("storms") && e.chance(forecast ? BalloonData.strikeChanceForecast : BalloonData.strikeChance) {
            strike(e, &q, reg)
        } else if reg.has("ice") && e.chance(BalloonData.roofChance) {
            roofAccident(e, &q)
        } else if e.chance(rules.eventChance) {
            e.runEvent(events(e, reg), &q)
        }
    }

    override func sickPool(_ e: GameEngine, _ temp: Temp, _ port: Port?) -> [Ailment] {
        if let port = port { return port.fever ? BalloonData.fluFieldPool : BalloonData.groundPool }
        if temp == .hot { return BalloonData.hotPool }
        if temp == .cold || temp == .freezing { return BalloonData.coldPool }
        return BalloonData.mildPool
    }

    /// A line needs line, the sea below, and air calm enough to come down to the wave tops.
    override func forageRefusal(_ e: GameEngine) -> String? {
        if e.state.tackle <= 0 { return text.noTackle }
        if !e.state.region.has("sea") { return "There's no sea below you to fish in." }
        if e.state.weather.isRough { return text.tooRough }
        return nil
    }

    /// Down at the wave tops with the hatch open, the capsule airs out.
    override func foraged(_ e: GameEngine) { e.state.noCitrus = 0 }

    // MARK: - Events, stops and answers (Balloon+Events, Balloon+Choices)

    override func events(_ e: GameEngine, _ reg: Region) -> [JourneyEvent] { airEvents(e, reg) }

    override func arrive(_ e: GameEngine, _ stop: Stop) -> [Interrupt] {
        if stop.id == "landfall" { return [.message(Self.south(e.state) ? BalloonData.landfallSouth : BalloonData.landfallNorth)] }
        return super.arrive(e, stop)
    }

    override func special(_ e: GameEngine, _ stop: Stop) -> [Interrupt] { setPiece(e, stop) }

    override func resolve(_ e: GameEngine, _ key: String, _ args: [String], _ option: Int) -> [Interrupt] {
        answer(e, key, args, option)
    }

    // MARK: - Trade and score

    /// Water is never traded: the jugs hold $150 of it, under any trader's interest, and
    /// the smallest trade is more water than they hold.
    public override var tradeKeys: [ItemKey] { items.map(\.key).filter { $0 != .water } }

    /// Nobody hands over more than you can stow: an offer too big for the room left is cut
    /// to what fits, and what they want for it by the same share (`fitTrade`).
    override func fitOffer(_ e: GameEngine, _ o: Offer) -> Offer? { fitTrade(e, o) }

    public override func tradeValue(_ good: TradeGood) -> Double {
        switch good {
        case .money: return 1
        case .item(let k): return BalloonData.values[k] ?? super.tradeValue(good)
        }
    }

    /// Money to 50s, rations, water and propane to 10s, line to whole spools, the rest whole.
    public override func roundTrade(_ good: TradeGood, _ v: Double) -> Int {
        func to(_ n: Double) -> Int { Int(max(n, jsRound(v / n) * n)) }
        switch good {
        case .money: return to(50)
        case .item(.food), .item(.water), .item(.fuel): return to(10)
        case .item(.tackle): return to(20)
        case .item: return Int(max(1, jsRound(v)))
        }
    }

    /// "120 lbs of rations", "1 medical kit", "2 spools of fishing line", "$450".
    public override func describe(_ good: TradeGood, _ amount: Double) -> String {
        let n = jsNumber(amount)
        let one = amount == 1
        switch good {
        case .money: return "$\(formatNumber(amount))"
        case .item(.food): return "\(formatNumber(amount)) \(one ? "lb" : "lbs") of rations"
        case .item(.water): return "\(formatNumber(amount)) \(one ? "gallon" : "gallons") of water"
        case .item(.limes): return "\(n) scrubber \(one ? "canister" : "canisters")"
        case .item(.meds): return "\(n) medical \(one ? "kit" : "kits")"
        case .item(.clothes): return "\(n) down \(one ? "suit" : "suits")"
        case .item(.timber): return "\(n) \(one ? "sack" : "sacks") of ballast"
        case .item(.sailcloth): return "\(n) burner \(one ? "kit" : "kits")"
        case .item(.tackle):
            // Whole spools when they are; a broken spool is counted in casts.
            guard amount.truncatingRemainder(dividingBy: 20) == 0 else {
                return "\(n) \(one ? "cast" : "casts") of fishing line"
            }
            let spools = amount / 20
            return "\(jsNumber(spools)) \(spools == 1 ? "spool" : "spools") of fishing line"
        case .item(.fuel): return "\(formatNumber(amount)) \(one ? "gallon" : "gallons") of propane"
        }
    }

    public override func score(_ s: GameState) -> Score {
        let alive = s.living.count
        let health = s.healthLabel
        func fl(_ x: Double) -> Int { Int(x.rounded(.down)) }
        let provisions = fl(s.fuel / 50) + fl(s.food / 10) + fl(s.water / 50)
        let stores = fl(s.limes) + s.meds * 5 + s.clothes * 2 + s.sailcloth * 4 + s.timber * 3 + s.tackle / 20
        return Score(lines: [
            .init(label: text.scoreSurvivors(alive, health), points: alive * health.scorePerSurvivor),
            .init(label: text.scoreCondition, points: Int(jsRound(s.hull * 2 + s.sails))),
            .init(label: text.scoreProvisions, points: provisions),
            .init(label: text.scoreStores, points: stores),
            .init(label: text.scoreCash, points: fl(s.money / 50)),
        ], multiplier: s.role.scoreMultiplier)
    }
}
