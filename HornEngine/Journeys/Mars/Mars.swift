import Foundation

// The Long Transfer: 2087. Gateway Yard in high Earth orbit to Jezero Landing on Mars,
// 480 million km along the transfer arc in a chartered second-hand freighter with five
// aboard.
//
// A turn is a day. What it is about: propellant, which the tanks cannot hold enough of for
// the whole trip; water, which the recycler returns most of and the ice streams can top
// up; power, which drives the ship and heats the cabin, so a neglected array makes a cold
// crew; the Sun, building to a maximum, so a late launch meets more storms; and two
// decisions, at turnover and at Mars. Tables are in MarsData.swift; ports in Mars+Ports;
// events in Mars+Events; set pieces and answers in Mars+Choices. Spec and the bot's
// numbers: docs/journeys/mars.md.
//
// Stock roles: `sails` is power & drive, `hull` the pressure hull; `sailcloth` is array
// panels, `timber` hull patches, `clothes` thermal suits, `limes` supplement packs (bone
// loss), `tackle` tether cartridges (shots), `fuel` propellant in TENTHS of a tonne,
// `water` the tanks.

public final class Mars: Journey {
    public static let id = "mars"

    init() {
        super.init(id: Self.id, text: Self.strings)
        title = "The Long Transfer"
        subtitle = "2087 · Earth orbit to Mars in a chartered freighter"
        blurb = "Four hundred and eighty million kilometres in a second-hand freighter with five aboard, two depots, a station passing through, and a contract to deliver to Jezero. Nothing out there wants to kill you. Nothing out there will help."
        items = MarsData.items
        stops = MarsData.stops
        regions = MarsData.regions
        ports = Self.stations
        weathers = MarsData.weathers
        fairWeather = MarsData.quiet
        deficiency = MarsData.boneLoss
        ailments = [MarsData.badAir, MarsData.lowSpirits, MarsData.infection, MarsData.fracture]

        roles[.merchant] = RoleInfo(label: "Be a charter captain backed by a freight consortium", title: "charter captain",
                                    money: 1500, mend: 25, patch: 20, catchLimit: 60, aim: 1.5)
        roles[.shipwright] = RoleInfo(label: "Be a yard rigger who bought the ship she used to fix", title: "yard rigger",
                                      money: 850, mend: 40, patch: 32, catchLimit: 60, aim: 1.5)
        roles[.whaler] = RoleInfo(label: "Be an ice hauler from the lunar tugs", title: "ice hauler",
                                  money: 625, mend: 25, patch: 20, catchLimit: 100, aim: 4)

        paces[.easy] = PaceInfo(name: "Economy burn", speed: 310, hp: 0.5, wear: 1.2, fuel: 7,
                                desc: "About 3.1 million km a day on 0.7 tonnes of propellant. Easy on the drive and on everyone.")
        paces[.steady] = PaceInfo(name: "Cruise", speed: 370, hp: 0, wear: 2, fuel: 10,
                                  desc: "About 3.7 million km a day on a tonne of propellant.")
        paces[.full] = PaceInfo(name: "Hard burn", speed: 430, hp: -1, wear: 3.4, fuel: 16,
                                desc: "About 4.3 million km a day on 1.6 tonnes. Noise, heat, wear, and nobody sleeps.")

        rationings[.filling] = RationsInfo(name: "Full", amount: 0.8, hp: 1, desc: "0.8 kg a head a day. Three meals and something hot.")
        rationings[.meager] = RationsInfo(name: "Lean", amount: 0.55, hp: -0.3, desc: "0.55 kg a head a day. Nobody starves; nobody is pleased.")
        rationings[.bare] = RationsInfo(name: "Short", amount: 0.35, hp: -2.2, desc: "0.35 kg a head a day. Paste, mostly.")

        departures = MarsData.departures
        firstNames = MarsData.firstNames
        vesselNames = MarsData.vesselNames
        defaultTopTen = MarsData.defaultTopTen
        quarry = MarsData.ice
        forageSeconds = 25
        forageReward = .water

        rules.startDay = 7
        rules.propFloor = 0.7
        rules.propSpan = 0.3
        rules.hullFloor = 1
        rules.hullSpan = 0
        rules.noFuelSpeed = 0.4
        rules.water = 2
        rules.hotWater = 2
        rules.deficiencyAfter = 30
        rules.hullCreep = 0.05
        rules.spoil = 10...30
        rules.eventChance = 0.17
        rules.yardHull = 1.2
        rules.yardSails = 1
        rules.tradeWorth = 20
        rules.tradeCash = 40
        rules.tradeSize = 15...45
        rules.rankCuts = [8000, 5000, 2500]
    }

    // MARK: - Sentences

    static let strings = JourneyText(
        rainCaught: { "The condensers wring \($0) litres out of the cabin air." },
        outOfFood: "[red]The galley is empty.[/red] There is a lot of arithmetic going on aboard, and none of it comes out well.",
        lowFood: "The quartermaster, who is also the cook, reports about a week of rations left.",
        outOfWater: "[red]The water tanks are dry.[/red] The recycler can only give back what it is given.",
        lowWater: "About five days of water left in the tanks, by the recycler's count.",
        preventiveGone: "[amber]The last supplement pack is gone.[/amber] Bones will not notice for a month. Then they will.",
        outOfFuel: "[red]The propellant tanks are dry.[/red] The drive coughs once and goes quiet. The ship coasts on the speed she has, which is not much.",
        lowFuel: "About five days of propellant left at this burn.",
        deficiencyCured: { "\($0)'s bones have stopped aching. The supplements are doing their work." },
        wellAgain: { "\($0) is back on the duty roster." },
        hasAilment: { name, a in "\(name) has \(a.name)." },
        deficiencyHint: " Supplement packs will put it right, and so will a few days docked at a station, whose doctor has a cupboard full of them.",
        medsUsed: { " [dim]You open a medical kit (\($0) left).[/dim]" },
        causeThirst: "thirst",
        causeStarvation: "hunger",
        causeExhaustion: "exhaustion",
        leaderDied: { name, cause in "You, Captain \(name), have died of \(cause)." },
        leaderDiedBody: "Your crew bring the ship the rest of the way on the autopilot and their own nerve. The cargo is delivered under the first officer's name, which you would have wanted, more or less.",
        spoiled: { "With the hull leaking, the galley freezer cannot hold its cold. \($0) kg of rations have spoiled." },
        hullWarning: "[red]The pressure hull is losing air faster than the tanks can make it up.[/red] Patch it soon.",
        sailsWarning: "[red]Power is failing.[/red] Half the array is dark, the drive is starved and the cabin is getting cold.",
        wrecked: { "The hull of the [i]\($0)[/i] lets go." },
        wreckedBody: "It goes quietly, the way these things do: a seam that had been patched once too often. The ship's last message reaches Gateway a few minutes later. It gives a position, a time and the names of everyone aboard, and it is very calm.",
        depart: { s in
            "The [i]\(TextMarkup.escape(s.ship))[/i] backs away from Gateway Yard on \(s.dateText). Jezero is 480 million km along the arc, and the contract pays a bonus for every day under 170. Somebody has already started a betting pool."
        },
        noProvisions: "Nobody leaves Gateway without rations aboard. The yard's quartermaster points you back at the shop.",
        rested: { days, h in
            "After \(days) \(days == 1 ? "day" : "days") with the drive idling, your crew's health is [\(h.color)]\(h.text)[/\(h.color)]."
        },
        mended: { "A day in suits on the truss, swapping a panel and coaxing the drive. [green](Power & drive now \($0)%)[/green]" },
        patched: { "A day of sealant, a plate and a pressure test. [green](Pressure hull now \($0)%)[/green]" },
        yardHull: "The yard crew go over the pressure hull seam by seam. She holds air like a new one.",
        yardSails: "The yard fits new panels and rebuilds the thruster grid. The cabin lights come up a shade brighter.",
        noTradersLeft: "Nobody else aboard wants to trade today.",
        nobodyWants: "You ask round the docking ring, but nobody wants what you have.",
        traderIntro: "A purser from another freighter drifts over with a tablet and a proposition.",
        noTackle: "You have no tether cartridges left.",
        tooRough: "Nobody goes out on the truss in this.",
        catchReport: { caught, limit, got in
            var t = caught > 0 ? "You reeled in [amber]\(caught) litres[/amber] of ice." : "The grapple came back empty every time."
            if caught > limit { t += " The melt tank only takes \(limit) litres from one outing." }
            if got != 0 { t += " [green]+\(got) litres of water.[/green]" }
            t += " [dim]A day has passed.[/dim]"
            return t
        },
        defaultEpitaph: "Clear skies and a straight course.",
        tradeOffer: { intro, give, want in
            "\(intro)\n\nThey will give you [amber]\(give)[/amber] for [amber]\(want)[/amber]."
        },
        tradeHave: { "[dim]You have \($0).[/dim]" },
        tradeAccept: "Accept the trade",
        tradeDecline: "Decline",
        tradeDone: "Done. Goods change hands through the lock.",
        reached: { stop, s in "You have reached \(stop.name).\n[dim]\(s.dateText) · \(MarsData.km(stop.mile))[/dim]" },
        goAshore: "Dock and go aboard",
        passBy: "Keep going",
        wavesGoodbye: { "\($0) shakes every hand, collects a bag and floats off through the lock." },
        scoreSurvivors: { alive, health in "\(alive) aboard, health \(health.text)" },
        scoreCondition: "Hull, power & drive",
        scoreProvisions: "Rations & water",
        scoreStores: "Propellant, stores & spares",
        scoreCash: "Cash",
        ranks: ["Master of Transfer", "Deep-space Hand", "Orbit Hand", "Groundling"])

    static let onTimeLabel = "Days in hand on the contract"

    // MARK: - Where and when

    /// The cabin is heated by the same power that drives the ship.
    public override func temperature(_ s: GameState, in reg: Region) -> Temp {
        s.sails < 20 ? .freezing : s.sails < 40 ? .cold : reg.temp
    }

    /// The Sun is building to a maximum: storms about 0.6× in August 2087, 1.6× by May 2088.
    static func stormFactor(_ s: GameState) -> Double {
        let d = s.date
        let months = Double((d.year - 2087) * 12 + d.month - 7) + Double(d.day - 1) / 30
        return min(1.6, max(0.6, 0.6 + months / 9))
    }

    override func weatherWeights(_ e: GameEngine, _ reg: Region, cursed: Bool) -> WeatherOdds {
        var w = reg.weights
        let f = Self.stormFactor(e.state)
        for storm in MarsData.storms { bump(&w, storm) { $0 * f } }
        return w
    }

    // MARK: - A turn under way

    /// The launch window's geometry, and the capture before Phobos.
    override func adjustSpeed(_ e: GameEngine, _ reg: Region, _ sp: inout Double) {
        sp *= MarsData.window[e.state.startMonth] ?? 1
        if reg.id == "capture" && e.state.mile < MarsData.captureEnds {
            switch e.state.vars[MarsData.captureKey] {
            case 1: sp *= MarsData.aerobrakeSpeed
            case 2: sp *= MarsData.propulsiveSpeed
            default: break
            }
        }
    }

    /// Far from the Sun the wings work harder for the same power.
    override func propulsionWear(_ e: GameEngine) -> Double {
        let w = super.propulsionWear(e)
        return e.state.region.has("far") ? w * 1.3 : w
    }

    /// Pebbles and the Sun's weather hit the hull, harder at a hard burn; aerobraking
    /// beats on it every day until Phobos.
    override func structureDamage(_ e: GameEngine, _ reg: Region) -> Double {
        var hd = rules.hullCreep
        let w = e.state.weather
        if let hit = MarsData.hullHit[w.rawValue] {
            hd += e.rnd(0, hit) * (e.state.pace == .full ? 1.5 : e.state.pace == .easy ? 0.7 : 1)
        }
        if Self.aerobraking(e.state, reg) {
            hd += e.rnd(MarsData.aerobrakeWear.lowerBound, MarsData.aerobrakeWear.upperBound)
        }
        return hd
    }

    static func aerobraking(_ s: GameState, _ reg: Region) -> Bool {
        reg.id == "capture" && s.mile < MarsData.captureEnds && s.vars[MarsData.captureKey] == 1
    }

    /// The shared rule stops at the captain's death, so anyone it would have taken the same
    /// day is still marked alive: only someone with health left can bring the ship in.
    public override func leaderDiedBody(_ s: GameState) -> String {
        if s.living.contains(where: { $0.hp > 0 }) { return text.leaderDiedBody }
        return s.atPort ? Self.nobodyLeftDocked : Self.nobodyLeftAboard
    }

    static let nobodyLeftAboard = "There is nobody left aboard to take the helm. The autopilot holds her to the arc exactly as it was told, and in time a tug goes out to bring her in. Jezero gets its cargo, very late, and flies its flag at half height for a day."
    static let nobodyLeftDocked = "There is nobody left aboard to take her on. The station crew move her to a quiet berth, and the cargo goes the rest of the way to Jezero in somebody else's hold."

    public override func wreckedBody(_ s: GameState) -> String {
        if Self.aerobraking(s, s.region) {
            return "She was a tired ship for a fire like that. Somewhere in the thin top of the Martian sky a seam opens, and the glow around the hull goes from orange to white. The settlement at Jezero sees a short bright line cross the dawn, and knows what it was."
        }
        return text.wreckedBody
    }

    override func tick(_ e: GameEngine, _ q: inout [Interrupt], _ mode: GameEngine.DayMode, _ reg: Region) {
        if e.state.day >= MarsData.contractDays && e.state.vars[MarsData.lateKey] != 1 {
            e.state.vars[MarsData.lateKey] = 1
            q.append(.message("[amber]Day 170. The contract date has passed.[/amber] Nothing is forfeit; the bonus is gone, and Jezero will be glad of the cargo whenever it comes."))
        }
    }

    /// Storms bring radiation, a cold cabin hypothermia, thin bones fractures.
    override func sickPool(_ e: GameEngine, _ temp: Temp, _ port: Port?) -> [Ailment] {
        var pool = ailments
        if port != nil { return pool }
        if MarsData.storms.contains(e.state.weather) { pool += [MarsData.radiation, MarsData.radiation] }
        if temp == .cold || temp == .freezing { pool += [MarsData.hypothermia, MarsData.hypothermia] }
        if e.state.noCitrus > rules.deficiencyAfter / 2 { pool.append(MarsData.fracture) }
        return pool
    }

    /// The grapple wants an ice stream and a calm day.
    override func forageRefusal(_ e: GameEngine) -> String? {
        if let no = super.forageRefusal(e) { return no }
        if !e.state.region.has("ice") {
            return "There is nothing out there to catch but starlight. The ice streams are at 80 to 110 and 340 to 370 million km."
        }
        return nil
    }

    // MARK: - Events, stops and answers (Mars+Events, Mars+Ports, Mars+Choices)

    override func events(_ e: GameEngine, _ reg: Region) -> [JourneyEvent] { arcEvents(e, reg) }

    override func arrive(_ e: GameEngine, _ stop: Stop) -> [Interrupt] { stationArrival(e, stop) ?? super.arrive(e, stop) }

    override func special(_ e: GameEngine, _ stop: Stop) -> [Interrupt] { setPiece(e, stop) }

    override func resolve(_ e: GameEngine, _ key: String, _ args: [String], _ option: Int) -> [Interrupt] {
        answer(e, key, args, option)
    }

    // MARK: - Trade and score

    /// Money to 5s, rations and water to 10s, propellant to whole tonnes, cartridges whole.
    public override func roundTrade(_ good: TradeGood, _ v: Double) -> Int {
        switch good {
        case .item(.food), .item(.water): return Int(max(10, jsRound(v / 10) * 10))
        default: return super.roundTrade(good, v)
        }
    }

    /// "120 kg of rations", "2 medical kits", "3 tether cartridges", "12 tonnes of propellant".
    public override func describe(_ good: TradeGood, _ amount: Double) -> String {
        let n = jsNumber(amount)
        let one = amount == 1
        switch good {
        case .money: return "$\(formatNumber(amount))"
        case .item(.food): return "\(formatNumber(amount)) kg of rations"
        case .item(.water): return "\(formatNumber(amount)) \(one ? "litre" : "litres") of water"
        case .item(.limes): return "\(n) supplement \(one ? "pack" : "packs")"
        case .item(.meds): return "\(n) medical \(one ? "kit" : "kits")"
        case .item(.clothes): return "\(n) thermal \(one ? "suit" : "suits")"
        case .item(.sailcloth): return "\(n) array \(one ? "panel" : "panels")"
        case .item(.timber): return "\(n) hull \(one ? "patch" : "patches")"
        case .item(.tackle):
            guard amount.truncatingRemainder(dividingBy: 20) == 0 else { return "\(n) tether \(one ? "shot" : "shots")" }
            let c = amount / 20
            return "\(jsNumber(c)) tether \(c == 1 ? "cartridge" : "cartridges")"
        case .item(.fuel): return "\(MarsData.tonnes(amount)) of propellant"
        }
    }

    public override func score(_ s: GameState) -> Score {
        let base = super.score(s)
        let early = max(0, MarsData.contractDays - s.day)
        return Score(lines: base.lines + [.init(label: Self.onTimeLabel, points: early * MarsData.bonusPerDay)],
                     multiplier: base.multiplier)
    }
}
