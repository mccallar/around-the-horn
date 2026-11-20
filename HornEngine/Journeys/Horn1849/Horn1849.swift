#if os(WASI)
import FoundationEssentials
#else
import Foundation
#endif

// The 1849 voyage: New York to San Francisco around Cape Horn.
//
// The reference journey, and a line-for-line port of the prototype
// (docs/reference/horn1849.html). Its tables are in GameData.swift and its sea events
// and landmarks in Horn1849+Events.swift. This file holds its sentences for the shared
// rules, and the rules that are its own: the southern winter, the Strait of Magellan,
// what a storm does to a wooden hull.
//
// Nothing here may change a number, a sentence or the order random numbers are drawn in:
// `PrototypeParityTests` and `GoldenVoyageTests` compare every voyage against the
// prototype's.

public final class Horn1849: Journey {
    public static let id = "horn1849"

    init() {
        super.init(id: Self.id, text: Self.strings)
        title = "Around the Horn"
        subtitle = "1849 · New York to San Francisco under sail"
        blurb = "Fourteen thousand miles by way of Cape Horn, with gold at the far end and the worst water in the world in between."
        items = GameData.items
        stops = GameData.stops
        regions = GameData.regions
        ports = PortID.allCases.map(GameData.port)
        weathers = Weather.allCases
        fairWeather = .fair
        deficiency = .scurvy
        ailments = [.shipFever, .dysentery, .fever, .brokenArm, .exhaustion]
        for r in Role.allCases {
            roles[r] = RoleInfo(label: r.label, title: r.title, money: r.startingMoney, mend: r.sailMend,
                                patch: r.hullPatch, catchLimit: r.catchLimit, aim: r.harpoonPadding)
        }
        for p in Pace.allCases {
            paces[p] = PaceInfo(name: p.name, speed: p.speed, hp: p.hp, wear: p.wear, desc: p.desc)
        }
        for r in Rations.allCases {
            rationings[r] = RationsInfo(name: r.name, amount: r.lb, hp: r.hp, desc: r.desc)
        }
        departures = GameData.departures
        firstNames = GameData.firstNames
        vesselNames = GameData.shipNames
        defaultTopTen = GameData.defaultTopTen
        quarry = GameData.fish
        forageSeconds = GameData.fishingSeconds
        // `rules` stays as it is: the defaults are this journey's numbers.
    }

    // MARK: - Sentences

    static let strings = JourneyText(
        rainCaught: { "Caught \($0) gallons of rainwater in the sails." },
        outOfFood: "[red]You have run out of provisions![/red] The crew is starving.",
        lowFood: "The cook warns you: provisions will last about a week.",
        outOfWater: "[red]The water casks are dry![/red] Without water, the crew will die within days.",
        lowWater: "The water casks are nearly empty — a few days left.",
        preventiveGone: "The last of the citrus is gone. Scurvy will follow within a few weeks unless you find fresh food.",
        // A sailing ship burns nothing; no pace here uses fuel, so neither line is ever said.
        outOfFuel: "",
        lowFuel: "",
        deficiencyCured: { "\($0) is recovering from scurvy." },
        wellAgain: { "\($0) is well again." },
        hasAilment: { name, a in "\(name) has \(a.name)." },
        deficiencyHint: " [dim]Bleeding gums, aching joints. Citrus or a run ashore will cure it.[/dim]",
        medsUsed: { " [dim]You open a medicine kit (\($0) left).[/dim]" },
        causeThirst: "thirst",
        causeStarvation: "starvation",
        causeExhaustion: "exhaustion",
        leaderDied: { name, cause in "You, Captain \(name), have died of \(cause)." },
        leaderDiedBody: "The crew sails the ship into the nearest port and scatters. The voyage is over.",
        spoiled: { "Seawater has been leaking into the hold. \($0) lbs of provisions are spoiled." },
        hullWarning: "[red]The pumps are working day and night.[/red] The hull needs patching — soon.",
        sailsWarning: "[red]Your sails are in rags.[/red] She barely answers the helm. Mend them if you can.",
        wrecked: { "The [i]\($0)[/i] has foundered." },
        wreckedBody: "Her seams opened faster than the pumps could keep up. She went down by the head, taking everything with her.",
        depart: { s in
            "The [i]\(TextMarkup.escape(s.ship))[/i] casts off from South Street on \(s.dateText). Behind you, New York shrinks to a smudge of chimney smoke. Ahead lie fourteen thousand miles of ocean."
                + (s.food <= 0 ? " " + Horn1849.goingHungry : "")
        },
        noProvisions: "You can't put to sea with no provisions! The chandler shakes his head and points you back inside.",
        rested: { days, h in
            "After \(days) day\(days > 1 ? "s" : "") of rest, your crew's health is [\(h.color)]\(h.text)[/\(h.color)]."
        },
        mended: { "The sailmaker's palm and needle are busy all day. [green](Sails now \($0)%)[/green]" },
        patched: { "The carpenter caulks and planks over the worst of it. [green](Hull now \($0)%)[/green]" },
        yardHull: "Shipwrights swarm over her. She is tight as a drum again.",
        yardSails: "A sail loft fits you out with fresh canvas.",
        noTradersLeft: "Nobody else on the waterfront wants to trade with you today.",
        nobodyWants: "You walk the quays, but nobody wants what you have.",
        traderIntro: "A trader on the quay looks over your stores.",
        noTackle: "You have no fishing tackle left.",
        tooRough: "The seas are far too rough to fish.",
        catchReport: { caught, limit, got in
            var t = caught > 0 ? "You caught [amber]\(caught) lbs[/amber] of fish." : "You caught nothing."
            if caught > limit { t += " The cook can only salt and stow \(limit) lbs before the rest spoils." }
            if got != 0 { t += " [green]+\(got) lbs of provisions.[/green]" }
            t += " [dim]A day has passed.[/dim]"
            return t
        },
        defaultEpitaph: "Fair winds, shipmate.",
        tradeOffer: { intro, give, want in
            "\(intro)\n\nThey will give you [amber]\(give)[/amber] for [amber]\(want)[/amber]."
        },
        tradeHave: { "[dim]You have \($0).[/dim]" },
        tradeAccept: "Accept the trade",
        tradeDecline: "Decline",
        tradeDone: "Done. Goods change hands.",
        reached: { stop, s in "You have reached \(stop.name).\n[dim]\(s.dateText) · day \(s.day)[/dim]" },
        goAshore: "Drop anchor and go ashore",
        passBy: "Sail on without stopping",
        wavesGoodbye: { "\($0) waves goodbye from the quay." },
        scoreSurvivors: { alive, health in "\(alive) aboard, health \(health.text)" },
        scoreCondition: "Hull & sails",
        scoreProvisions: "Provisions & water",
        scoreStores: "Stores & spares",
        scoreCash: "Cash",
        ranks: [Rank.masterMariner.rawValue, Rank.ableSeaman.rawValue, Rank.ordinarySeaman.rawValue,
                Rank.greenhand.rawValue])

    // MARK: - Where and when

    public override func region(_ s: GameState, at m: Int) -> Region {
        if s.passage == .magellan && m >= 7350 && m < 7800 { return GameData.magellan }
        return GameData.regions.first { m < $0.to }!
    }

    /// The prototype's `tempAt`.
    public override func temperature(_ s: GameState, in reg: Region) -> Temp {
        var t = reg.temp
        let mo = s.month
        if reg.id == .northAtlantic && [10, 11, 0, 1, 2].contains(mo) { t = .cold }
        if reg.south && (4...8).contains(mo) && t == .cold { t = .freezing }
        return t
    }

    public override func harshSeason(_ s: GameState) -> Bool { s.southernWinter }

    /// The day's weather odds in `reg`, in the prototype's key order: a key the
    /// adjustments add that the region lacks goes on the end, as it does in `{...reg.w}`.
    override func weatherWeights(_ e: GameEngine, _ reg: Region, cursed: Bool) -> WeatherOdds {
        var w = reg.weights
        if reg.south && e.state.southernWinter {
            bump(&w, .gale) { $0 + 20 }
            bump(&w, .storm) { $0 + (reg.horn ? 30 : 18) }
            bump(&w, .cold) { $0 + 15 }
            bump(&w, .fair) { $0 * 0.5 }
            bump(&w, .fresh) { $0 * 0.6 }
        }
        if reg.id == .northAtlantic && [11, 0, 1].contains(e.state.month) {
            bump(&w, .gale) { $0 + 8 }
            bump(&w, .storm) { $0 + 5 }
        }
        if cursed {
            bump(&w, .gale) { $0 + 20 }
            bump(&w, .storm) { $0 + 15 }
            bump(&w, .calm) { $0 + 10 }
        }
        return w
    }

    // MARK: - A day under sail

    override func adjustSpeed(_ e: GameEngine, _ reg: Region, _ sp: inout Double) {
        if e.state.inStrait { sp *= 0.5 }
        if (reg.horn || reg.strait) && e.state.southernWinter { sp *= 0.6 }
    }

    override func structureDamage(_ e: GameEngine, _ reg: Region) -> Double {
        let w = e.state.weather
        let pace = e.state.pace
        var hd = 0.03
        if w == .storm {
            hd += e.rnd(1, 2.6) * (pace == .full ? 1.6 : pace == .easy ? 0.7 : 1)
                * (reg.horn ? 1.5 : 1) * (reg.strait ? 0.5 : 1)
        }
        if w == .gale { hd += e.rnd(0, 0.8) * (pace == .full ? 1.5 : 1) }
        return hd
    }

    override func dayEvents(_ e: GameEngine, _ q: inout [Interrupt], _ reg: Region) {
        if e.state.inStrait && e.chance(e.state.pilot ? 0.012 : 0.055) {
            let h = e.ri(12, 28)
            e.state.hull -= Double(h)
            e.state.day += 1
            q.append(.message("You have run aground on an uncharted shoal! It takes a full day to kedge her off. [red](Hull −\(h)%)[/red]"))
            e.checkSink(&q)
        } else if reg.horn && e.chance(0.012) {
            e.overboard(&q)
        } else if e.chance(0.11) {
            e.seaEvent(&q, reg)
        }
    }

    override func sickPool(_ e: GameEngine, _ temp: Temp, _ port: Port?) -> [Ailment] {
        if port?.fever == true { return [.yellowFever, .fever, .dysentery] }
        if temp == .hot { return [.fever, .dysentery, .exhaustion, .yellowFever, .shipFever] }
        if temp == .freezing || temp == .cold { return [.pneumonia, .frostbite, .fever, .shipFever, .brokenArm] }
        return [.shipFever, .dysentery, .fever, .brokenArm, .exhaustion]
    }

    // MARK: - Leaving New York with nothing left to buy provisions with (D23)

    /// New York sends a ship with no provisions back to the chandler while the purse runs to
    /// a step of them; with nothing left to buy them with, holding her there would hold her
    /// for good, so she sails hungry (D23). The prototype refuses her whatever the purse.
    public override func departsUnfed(_ s: GameState) -> Bool { !firstPortSells(.food, s) }

    /// The departure's last sentence for a ship that leaves New York with no provisions.
    public static let goingHungry = "There isn't a biscuit in the bread room, and the purse won't stretch to a hundredweight of salt beef, so the crew puts to sea hungry and must live on whatever the sea or the next port gives them."

    // MARK: - Arrivals and choices

    override func arrive(_ e: GameEngine, _ stop: Stop) -> [Interrupt] { e.horn1849Arrive(stop) }

    override func resolveNamed(_ e: GameEngine, _ event: ChoiceEvent, _ option: Int) -> [Interrupt] {
        e.horn1849Resolve(event, option)
    }

    // MARK: - Trade and score

    public override func tradeValue(_ good: TradeGood) -> Double { GameData.tradeValue(good) }
    public override func roundTrade(_ good: TradeGood, _ v: Double) -> Int { GameEngine.roundTrade(good, v) }
    public override func describe(_ good: TradeGood, _ amount: Double) -> String { HornEngine.describe(good, amount) }
    public override func score(_ s: GameState) -> Score { Score(s) }
    public override func rank(_ score: Int) -> String { Rank(score: score).rawValue }
}

// MARK: - Names the app and the tests know this journey's lines by

extension GameEngine {
    /// Leaving New York. Nil and the ship stays if there's no food and the purse still runs
    /// to a step of it (D23); otherwise the casting-off message.
    public func departNewYork() -> String? { depart() }

    public static let noProvisionsRefusal = Horn1849.strings.noProvisions
    public static let defaultEpitaph = Horn1849.strings.defaultEpitaph

    /// Food and water to 10s (min 10), tackle to 20s (min 20), money to 5s (min 5),
    /// everything else to whole units (min 1).
    static func roundTrade(_ good: TradeGood, _ v: Double) -> Int {
        switch good {
        case .item(.food), .item(.water): return Int(max(10, jsRound(v / 10) * 10))
        case .item(.tackle): return Int(max(20, jsRound(v / 20) * 20))
        case .money: return Int(max(5, jsRound(v / 5) * 5))
        default: return Int(max(1, jsRound(v)))
        }
    }
}

/// The prototype's `describe`: "120 lbs of provisions", "2 crates of citrus", "$45".
public func describe(_ good: TradeGood, _ a: Double) -> String {
    let n = jsNumber(a)
    let s = a > 1 ? "s" : ""
    switch good {
    case .money: return "$\(n)"
    case .item(let k):
        switch k {
        case .food: return "\(n) lbs of provisions"
        case .water: return "\(n) gallons of water"
        case .limes: return "\(n) crate\(s) of citrus"
        case .meds: return "\(n) medicine kit\(s)"
        case .clothes: return "\(n) set\(s) of woolens"
        case .sailcloth: return "\(n) bolt\(s) of sailcloth"
        case .timber: return "\(n) bundle\(s) of timber"
        case .tackle: return "\(jsNumber(a / 20)) box\(a > 20 ? "es" : "") of fishing tackle"
        case .fuel: return "\(n) of fuel"  // never stocked on this voyage
        }
    }
}
