import Foundation

// Over the Pole: 1926. Rome to Nome in a small semi-rigid airship, 9,600 km from mooring
// mast to mooring mast as far as Spitsbergen, then over the North Pole and 4,300 km of ice
// with no mast at all.
//
// A turn is a four-hour watch. What it is about: petrol (dry tanks and she drifts at the
// wind's pace), lift (leaks, ice and the sun take it; ballast and fresh gas give it back,
// and at nothing she is forced down), coffee against watch fatigue, furs against the polar
// cold, and one choice at the Pole: above the fog or under it. Tables are in
// AirshipData.swift; masts in Airship+Masts.swift; events in Airship+Events.swift; set
// pieces and answers in Airship+Choices.swift. Spec and the bot's numbers:
// docs/journeys/airship.md.
//
// Stock roles: `hull` is lift, `sails` the engines; `timber` is water ballast (a bag mends
// lift), `sailcloth` engine spares, `limes` coffee & cocoa (against watch fatigue),
// `clothes` fur suits, `tackle` pilot balloons (one a throw, ten to a box), `fuel` petrol in
// kilograms. The foraging game is reading the winds, and what it finds is petrol saved.

public final class Airship: Journey {
    public static let id = "airship"

    init() {
        super.init(id: Self.id, text: Self.strings)
        title = "Over the Pole"
        subtitle = "1926 · Rome to Nome by airship, over the top of the world"
        blurb = "Nine thousand six hundred kilometres in a hydrogen airship: five mooring masts, then the North Pole and four thousand kilometres of ice nobody has seen. Every kilo has to be lifted, and petrol is life."
        items = AirshipData.items
        stops = AirshipData.stops
        regions = AirshipData.regions
        ports = Self.masts
        weathers = AirshipData.weathers
        fairWeather = AirshipData.fair
        deficiency = AirshipData.watchFatigue
        ailments = AirshipData.mildPool

        roles[.merchant] = RoleInfo(label: "Be a financier from New York", title: "financier",
                                    money: 1200, mend: 25, patch: 20, catchLimit: 450, aim: 1.5)
        roles[.shipwright] = RoleInfo(label: "Be an airship engineer from Rome", title: "engineer",
                                      money: 650, mend: 40, patch: 35, catchLimit: 450, aim: 1.5)
        roles[.whaler] = RoleInfo(label: "Be a meteorologist from Bergen", title: "meteorologist",
                                  money: 425, mend: 25, patch: 20, catchLimit: 900, aim: 4)

        paces[.easy] = PaceInfo(name: "Economical", speed: 190, hp: 0.5, wear: 0.6, fuel: 150,
                                desc: "One engine turning. Easy on everything, and on the petrol.")
        paces[.steady] = PaceInfo(name: "Cruising", speed: 250, hp: 0, wear: 1, fuel: 250,
                                  desc: "Both engines at cruising revolutions.")
        paces[.full] = PaceInfo(name: "Full speed", speed: 310, hp: -1, wear: 2, fuel: 420,
                                desc: "Both engines flat out. Fast, loud, thirsty and hard on the crew.")

        rationings[.filling] = RationsInfo(name: "Full rations", amount: 0.3, hp: 1,
                                           desc: "0.3 kg a watch. Soup, biscuit and chocolate.")
        rationings[.meager] = RationsInfo(name: "Short rations", amount: 0.2, hp: -0.3,
                                          desc: "0.2 kg a watch. Nobody is full.")
        rationings[.bare] = RationsInfo(name: "Pemmican only", amount: 0.1, hp: -2.2,
                                        desc: "0.1 kg a watch. Chew slowly.")

        departures = AirshipData.departures
        firstNames = AirshipData.firstNames
        vesselNames = AirshipData.vesselNames
        defaultTopTen = AirshipData.defaultTopTen
        quarry = AirshipData.winds
        forageSeconds = 25
        forageReward = .fuel

        rules.tickHours = 4
        rules.startHour = 8
        rules.noFuelSpeed = 1  // a dry watch drifts: `adjustSpeed` sets the pace
        rules.water = 0.6
        rules.hotWater = 0.9
        rules.rainCatch = 6...18
        rules.restChoices = [1, 3, 6, 12]
        rules.starve = 4
        rules.parch = 6
        rules.freezeSeason = 0
        rules.sickBase = 0.006
        rules.sickPerHP = 0.0005
        rules.deficiencyAfter = 12
        rules.deficiencyRate = 0.01
        rules.spoilBelow = -1  // she dumps petrol instead (`tick`)
        rules.eventChance = 0.15
        rules.yardHull = 3
        rules.yardSails = 2
    }

    // MARK: - Sentences

    static let strings = JourneyText(
        rainCaught: { "Rain runs off the envelope into the water cans: \($0) litres." },
        outOfFood: "[red]The provisions are gone![/red] The crew is starving.",
        lowFood: "The steward warns you: provisions will last about a day.",
        outOfWater: "[red]The water cans are dry![/red] Without water, the crew will not last long.",
        lowWater: "The water cans are nearly empty — a few watches left.",
        preventiveGone: "The last of the coffee is gone. Within a couple of days the crew will be asleep on their feet.",
        outOfFuel: "[red]The tanks are dry![/red] The engines cough and stop. She is a free balloon now, going where the wind goes.",
        lowFuel: "[amber]The engineer chalks a number on the tank: petrol for about five more watches.[/amber]",
        deficiencyCured: { "\($0) is wide awake again." },
        wellAgain: { "\($0) is well again." },
        hasAilment: { name, a in "\(name) has \(a.name)." },
        deficiencyHint: " [dim]Red eyes, slow hands, asleep on their feet. Hot coffee or a night at a mast will cure it.[/dim]",
        medsUsed: { " [dim]You open a medicine kit (\($0) left).[/dim]" },
        causeThirst: "thirst",
        causeStarvation: "starvation",
        causeExhaustion: "exhaustion",
        leaderDied: { name, cause in "You, Captain \(name), have died of \(cause)." },
        leaderDiedBody: "The crew brings the ship down at the first place they can and sends word home by wireless. The expedition is over.",
        spoiled: { "\($0) kg of provisions have gone bad in the damp." },
        hullWarning: "[red]She is heavy and sinking by the stern.[/red] Drop ballast or find gas — soon.",
        sailsWarning: "[red]The engines are failing.[/red] They miss, smoke and overheat. Fit spares if you have any.",
        wrecked: { "The [i]\($0)[/i] has been forced down." },
        wreckedBody: forcedDownOnIce,
        depart: { s in
            "The [i]\(TextMarkup.escape(s.ship))[/i] slips the mast at Ciampino on \(s.dateText). The ground crew lets go the lines, the engines take up their roar, and Rome shrinks to a smudge of domes and umbrella pines. Ahead lie nine thousand six hundred kilometres, most of them cold."
        },
        noProvisions: "You can't cast off with no provisions! The storekeeper shakes his head and points you back inside.",
        rested: { turns, h in
            "After \(turns) \(turns == 1 ? "watch" : "watches") of rest, your crew's health is [\(h.color)]\(h.text)[/\(h.color)]."
        },
        mended: { "The mechanics work all watch, half out in the slipstream, with frozen fingers and a box of spares. [green](Engines now \($0)%)[/green]" },
        patched: { "The rigger slits a ballast bag and a hundred kilos of water rain down on the world below. She rises at once. [green](Lift now \($0)%)[/green]" },
        yardHull: "Hydrogen hisses in from the cylinders all watch. She rides high and light again.",
        yardSails: "The station mechanics strip both engines to the last nut and put them back better than new.",
        noTradersLeft: "Nobody else at the mast wants to trade with you today.",
        nobodyWants: "You walk the field, but nobody wants what you have.",
        traderIntro: "A ground-crew foreman looks over your stores.",
        noTackle: "You have no pilot balloons left.",
        tooRough: "The air is far too wild to read.",
        catchReport: { caught, limit, got in
            var t = caught > 0 ? "You found winds worth [amber]\(formatNumber(Double(caught))) kg[/amber] of petrol."
                : "The balloons found nothing you could use."
            if caught > limit { t += " The navigator can only plan so far ahead: \(formatNumber(Double(limit))) kg is all you can use." }
            if got > 0 { t += " [green]+\(formatNumber(Double(got))) kg of petrol.[/green]" }
            t += " [dim]A watch has passed.[/dim]"
            return t
        },
        defaultEpitaph: "Clear skies, shipmate.",
        tradeOffer: { intro, give, want in
            "\(intro)\n\nThey offer [amber]\(give)[/amber] for [amber]\(want)[/amber]."
        },
        tradeHave: { "[dim]You have \($0).[/dim]" },
        tradeAccept: "Accept the trade",
        tradeDecline: "Decline",
        tradeDone: "Done. Goods change hands.",
        reached: { stop, s in "You have reached \(stop.name).\n[dim]\(s.dateText) · watch \(s.day)[/dim]" },
        goAshore: "Moor at the mast and go ashore",
        passBy: "Fly on without stopping",
        wavesGoodbye: { "\($0) waves goodbye from the foot of the mast." },
        scoreSurvivors: { alive, health in "\(alive) aboard, health \(health.text)" },
        scoreCondition: "Lift & engines",
        scoreProvisions: "Provisions, water & petrol",
        scoreStores: "Stores & spares",
        scoreCash: "Cash",
        ranks: ["Commander", "Navigator", "Rigger", "Ballast"])

    static let forcedDownOnIce = "With no gas left to hold her and no ballast left to drop, she sank slowly onto the ice and would not rise again. The crew made camp beside the wreck of the gondola, and it was weeks before a ship found them. The expedition is over."
    static let forcedDownInAField = "With no gas left to hold her and no ballast left to drop, she sank slowly into a field and would not rise again. The crew climbed out of the wreck of the gondola to find a farmer and his dog staring at them. The expedition is over."

    /// The finale's opening lines, for the skin: the arrival, the town, and who climbs down.
    public static func finale(_ s: GameState) -> String {
        let days = Int(jsRound(Double(s.day * 4) / 24))
        let crowd = s.living.count > 1 ? " Your crew is already asking for the telegraph office."
            : " You climb down alone into the crowd, looking for the telegraph office."
        return "Land ho! The [i]\(TextMarkup.escape(s.ship))[/i] comes down over the roofs of Nome on \(s.dateText), after \(s.day) \(s.day == 1 ? "watch" : "watches") (\(days) \(days == 1 ? "day" : "days")) in the air.\n\nThe whole town turns out — miners, dog drivers, the schoolteacher and every child in Nome — to grab the handling lines and walk her down onto the beach. There is no mast here and no shed. Whatever happens to her next, she has crossed the top of the world." + crowd
    }

    // MARK: - Where and when

    /// Beyond the Pole the country is the height you chose.
    public override func region(_ s: GameState, at m: Int) -> Region {
        if m >= AirshipData.forkFrom && m < AirshipData.forkTo && s.vars[AirshipData.routeKey] == AirshipData.routeLow {
            return AirshipData.underFog
        }
        return super.region(s, at: m)
    }

    /// April's late-winter cold and July's polar summer, in the north.
    public override func temperature(_ s: GameState, in reg: Region) -> Temp {
        guard reg.has("north") else { return reg.temp }
        if s.month == 3 && reg.temp == .cold { return .freezing }
        if s.month == 6 && reg.temp == .freezing { return .cold }
        return reg.temp
    }

    override func weatherWeights(_ e: GameEngine, _ reg: Region, cursed: Bool) -> WeatherOdds {
        var w = reg.weights
        let month = e.state.month
        if reg.has("north") {
            switch month {
            case 3:
                bump(&w, AirshipData.snow) { $0 + 12 }
                bump(&w, AirshipData.gale) { $0 + 8 }
                bump(&w, AirshipData.fog) { $0 * 0.5 }
                bump(&w, AirshipData.ice) { $0 * 0.6 }
            case 5:
                bump(&w, AirshipData.fog) { $0 + 10 }
                bump(&w, AirshipData.ice) { $0 + 6 }
            case 6:
                bump(&w, AirshipData.fog) { $0 + 18 }
                bump(&w, AirshipData.ice) { $0 + 12 }
                bump(&w, AirshipData.fair) { $0 * 0.6 }
            default:
                break
            }
        }
        if (month == 5 || month == 6) && (reg.id == "med" || reg.id == "france") {
            bump(&w, AirshipData.storm) { $0 + 4 }
        }
        return w
    }

    // MARK: - A watch in the air

    static func drifting(_ s: GameState) -> Bool { s.vars[AirshipData.driftingKey] == 1 }

    /// With the tanks dry at the start of a watch she drifts: no pace, no engines, no crew,
    /// only the wind and what lift she has left.
    override func adjustSpeed(_ e: GameEngine, _ reg: Region, _ sp: inout Double) {
        if e.state.fuel <= 0 {
            e.state.vars[AirshipData.driftingKey] = 1
            let r = rules
            sp = AirshipData.driftSpeed * e.state.weather.speed * (r.hullFloor + r.hullSpan * (e.state.hull / 100))
        } else {
            e.state.vars[AirshipData.driftingKey] = nil
        }
    }

    /// Engines that are not turning do not wear. The jitter is drawn either way.
    override func propulsionWear(_ e: GameEngine) -> Double {
        let wear = super.propulsionWear(e)
        return Self.drifting(e.state) ? 0 : wear
    }

    static func paceFactor(_ p: Pace) -> Double { p == .full ? 1.6 : p == .easy ? 0.7 : 1 }

    /// Gas seeps every watch; snow, ice, gales, storms and the sun above the fog take more.
    override func structureDamage(_ e: GameEngine, _ reg: Region) -> Double {
        let w = e.state.weather
        let pace = e.state.pace
        var d = AirshipData.seep
        if w == AirshipData.snow { d += e.rnd(0, 0.5) }
        if w == AirshipData.ice { d += e.rnd(1, 3) * Self.paceFactor(pace) * reg.num("iceMult") }
        if w == AirshipData.gale { d += e.rnd(0, 0.8) * (pace == .full ? 1.5 : 1) }
        if w == AirshipData.storm { d += e.rnd(1, 2.6) * Self.paceFactor(pace) }
        d += reg.num("superheat", or: 0)
        return d
    }

    public override func wreckedBody(_ s: GameState) -> String {
        s.region.has("north") ? Self.forcedDownOnIce : Self.forcedDownInAField
    }

    override func tick(_ e: GameEngine, _ q: inout [Interrupt], _ mode: GameEngine.DayMode, _ reg: Region) {
        guard mode == .sail else { return }
        // Drifting says so, unless the rain had something to say.
        if Self.drifting(e.state) && (e.state.note.isEmpty || e.state.note == e.state.weather.note) {
            e.state.note = "Engines silent. You are going where the wind goes."
        }
        // Too heavy to hold her height: petrol goes over the side.
        if e.state.hull < AirshipData.heavyBelow && e.state.fuel > AirshipData.heavyPetrol
            && e.chance(AirshipData.heavyChance) {
            let n = e.ri(AirshipData.heavyDump.lowerBound, AirshipData.heavyDump.upperBound)
            e.state.fuel = max(0, e.state.fuel - Double(n))
            q.append(.message("She is too heavy to hold her height. The engineer opens the dump valve and \(n) kg of petrol goes over the side to keep her up."))
        }
    }

    /// Under the fog, the ridges come first; otherwise one event on about one watch in seven.
    override func dayEvents(_ e: GameEngine, _ q: inout [Interrupt], _ reg: Region) {
        let forecasts = e.state.vars[AirshipData.forecastKey] == 1
        if reg.has("ridges") && e.chance(forecasts ? AirshipData.ridgeChanceForecast : AirshipData.ridgeChance) {
            ridgeStrike(e, &q)
        } else if e.chance(rules.eventChance) {
            e.runEvent(events(e, reg), &q)
        }
    }

    override func sickPool(_ e: GameEngine, _ temp: Temp, _ port: Port?) -> [Ailment] {
        if port?.fever == true { return AirshipData.mastPool }
        if temp == .cold || temp == .freezing { return AirshipData.coldPool }
        return AirshipData.mildPool
    }

    /// Pilot balloons need balloons, calm enough air, and air you can see through.
    override func forageRefusal(_ e: GameEngine) -> String? {
        if let no = super.forageRefusal(e) { return no }
        let w = e.state.weather
        if w == AirshipData.fog || w == AirshipData.ice { return "You can't follow a balloon into fog." }
        return nil
    }

    // MARK: - Events, set pieces and answers (Airship+Events, Airship+Choices)

    override func events(_ e: GameEngine, _ reg: Region) -> [JourneyEvent] { airEvents(e, reg) }

    override func special(_ e: GameEngine, _ stop: Stop) -> [Interrupt] { setPiece(e, stop) }

    override func resolve(_ e: GameEngine, _ key: String, _ args: [String], _ option: Int) -> [Interrupt] {
        answer(e, key, args, option)
    }

    // MARK: - Trade and score

    public override func tradeValue(_ good: TradeGood) -> Double {
        switch good {
        case .money: return 1
        case .item(let k): return AirshipData.values[k] ?? super.tradeValue(good)
        }
    }

    /// Provisions, water and balloons to 10s, petrol to 100s, money to 5s, the rest whole.
    public override func roundTrade(_ good: TradeGood, _ v: Double) -> Int {
        func to(_ n: Double) -> Int { Int(max(n, jsRound(v / n) * n)) }
        switch good {
        case .money: return to(5)
        case .item(.food), .item(.water), .item(.tackle): return to(10)
        case .item(.fuel): return to(100)
        case .item: return Int(max(1, jsRound(v)))
        }
    }

    /// "120 kg of provisions", "1 medicine kit", "2 boxes of pilot balloons", "$45".
    public override func describe(_ good: TradeGood, _ amount: Double) -> String {
        let n = jsNumber(amount)
        let one = amount == 1
        switch good {
        case .money: return "$\(n)"
        case .item(.food): return "\(formatNumber(amount)) kg of provisions"
        case .item(.water): return "\(formatNumber(amount)) \(one ? "litre" : "litres") of water"
        case .item(.limes): return "\(n) \(one ? "tin" : "tins") of coffee"
        case .item(.meds): return "\(n) \(one ? "medicine kit" : "medicine kits")"
        case .item(.clothes): return "\(n) \(one ? "fur suit" : "fur suits")"
        case .item(.sailcloth): return "\(n) \(one ? "box" : "boxes") of engine spares"
        case .item(.timber): return "\(n) \(one ? "bag" : "bags") of ballast"
        case .item(.tackle):
            let boxes = amount / 10
            return "\(jsNumber(boxes)) \(amount <= 10 ? "box" : "boxes") of pilot balloons"
        case .item(.fuel): return "\(formatNumber(amount)) kg of petrol"
        case .item: return super.describe(good, amount)
        }
    }

    public override func score(_ s: GameState) -> Score {
        let alive = s.living.count
        let health = s.healthLabel
        func fl(_ x: Double) -> Int { Int(x.rounded(.down)) }
        let provisions = fl(s.food / 2.5) + fl(s.water / 15) + fl(s.fuel / 50)
        let stores = fl(s.limes) * 2 + s.meds * 5 + s.clothes * 2 + s.sailcloth * 4 + s.timber * 4 + s.tackle / 10
        return Score(lines: [
            .init(label: text.scoreSurvivors(alive, health), points: alive * health.scorePerSurvivor),
            .init(label: text.scoreCondition, points: Int(jsRound(s.hull * 2 + s.sails))),
            .init(label: text.scoreProvisions, points: provisions),
            .init(label: text.scoreStores, points: stores),
            .init(label: text.scoreCash, points: fl(s.money / 5)),
        ], multiplier: s.role.scoreMultiplier)
    }
}
