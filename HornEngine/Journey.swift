#if os(WASI)
import FoundationEssentials
#else
import Foundation
#endif

// One journey: its tables, its sentences, and the handful of rules that are its own.
//
// The shared engine (GameEngine.swift, +Actions, +Choices, Trade) runs every journey the
// same way: weather, distance, eating and drinking, health, wear, arrivals. A journey
// fills the tables in its `init` and overrides only the hooks where it differs. 1849
// (Journeys/Horn1849) is the reference: its overrides hold exactly what the prototype
// does that a train or an airship would not.
//
// Rules for authors, each enforced by a test (docs/design/journeys-architecture.md):
//  - Every random number comes from the engine (`e.rnd`, `e.ri`, `e.chance`, `e.pick`,
//    `e.weightedPick`). A journey never makes its own generator.
//  - Only arrays carry order. Look things up in a dictionary or a set; never loop over one.
//  - Every sentence the player reads comes from the journey. `JourneyText` has no
//    defaults, so a new journey cannot ship with a sailor's line in a balloon.

// MARK: - Numbers

/// The numbers the shared rules run on. The defaults are 1849's, so 1849 sets none of
/// them; a new journey changes what it needs to in its `init`.
public struct Rules {
    // Time
    /// Hours one turn takes. `GameState.day` counts turns.
    public var tickHours = 24
    /// Hour of the day the journey starts at, for journeys whose turns are shorter than a day.
    public var startHour = 0
    /// Day of the start month the journey starts on.
    public var startDay = 1

    // Speed: pace × weather × (propFloor + propSpan × sails) × (hullFloor + hullSpan × hull)
    // × crew × the journey's own factors × jitter.
    public var propFloor = 0.45
    public var propSpan = 0.55
    public var hullFloor = 0.75
    public var hullSpan = 0.25
    public var speedJitter = 0.85...1.15
    /// Multiplies speed on a turn the engine has no fuel for.
    public var noFuelSpeed = 0.25
    /// Whether a part load, less than the pace burns in a turn, is burnt for its share of the
    /// turn (only the rest runs on `noFuelSpeed`). False: it is thrown on with no effect and
    /// the whole turn runs on `noFuelSpeed`.
    public var burnsPartLoad = false

    // Eating and drinking, per person per turn
    public var water = 1.0
    public var hotWater = 1.5
    /// How much of the preventive (1849: citrus) each person uses up a turn.
    public var preventiveUse = 0.02
    /// What wet weather adds to the water, away from port.
    public var rainCatch = 15...45
    public var lowFoodTicks = 7.0
    public var lowWaterTicks = 5.0
    public var lowFuelTicks = 5.0
    /// A warning can fire again once the stock is back above this many turns' worth.
    public var rearmTicks = 10.0

    // Health per turn
    public var restAway = 3.0
    public var restInPort = 6.0
    /// How many turns the rest menu offers.
    public var restChoices = [1, 2, 3, 5]
    public var starve = 7.0
    public var parch = 12.0
    public var freezeWarm = 1.4
    public var freezeBare = 4.5
    /// Added to either freezing number in the journey's harsh season.
    public var freezeSeason = 1.0
    public var coldBare = 2.2
    public var heat = 0.4
    /// Multiplies an ailment's damage once a medicine kit is opened.
    public var treated = 0.5
    public var cureInPort = 0.6
    public var cureAway = 0.35
    /// Turns of an ailment worked off per turn in port, resting, and under way.
    public var mendInPort = 2.0
    public var mendAtRest = 1.5
    public var well = 1.0

    // Falling sick, per person per turn
    public var sickBase = 0.0035
    public var sickPerHP = 0.00035
    public var sickBare = 0.005
    public var sickStarving = 0.03
    public var sickThirst = 0.04
    public var sickHeat = 0.003
    public var sickCold = 0.01
    public var sickFeverPort = 0.012
    public var sickPortFactor = 0.7
    /// Turns without the preventive before the deficiency can start, then its odds.
    public var deficiencyAfter = 35
    public var deficiencyRate = 0.004
    public var deficiencyMax = 0.12

    // Wear
    public var wearJitter = 0.6...1.4
    /// What the structure loses every turn under way, before weather.
    public var hullCreep = 0.03
    /// Below this much structure, food can spoil. Set to -1 for a journey where it can't:
    /// the test must fail before the draw, never ask `chance(0)`.
    public var spoilBelow = 35.0
    public var spoilFoodOver = 50.0
    public var spoilChance = 0.06
    public var spoil = 20...60
    public var hullWarn = 30.0
    public var sailsWarn = 25.0
    public var warnRearm = 50.0
    /// Whether wear that brings `hull` to nothing ends the journey (1849: she founders).
    /// A journey that sets it false lets the vehicle break down instead, with its own
    /// `Journey.stalled`; its violent events can still end it with `GameEngine.checkSink`.
    public var wearWrecks = true

    // Yard prices, per percentage point restored, before the port's multiplier
    public var yardHull = 2.5
    public var yardSails = 1.8

    /// The default chance of one event on a turn under way (`Journey.dayEvents`).
    public var eventChance = 0.11

    // Trading
    public var portTrades = 3
    /// A trader wants a good you hold at least this much value of, or this much cash.
    public var tradeWorth = 25.0
    public var tradeCash = 30.0
    /// What one trade is worth, before each side's haggling.
    public var tradeSize = 25.0...70.0

    /// Scores at or above each cut earn the matching name in `JourneyText.ranks`.
    public var rankCuts = [7000, 4000, 2000]

    public init() {}
}

// MARK: - Sentences

/// Every sentence the shared rules say. All of it is required.
public struct JourneyText {
    // Eating and drinking
    public var rainCaught: (Int) -> String
    public var outOfFood: String
    public var lowFood: String
    public var outOfWater: String
    public var lowWater: String
    public var preventiveGone: String
    public var outOfFuel: String
    public var lowFuel: String

    // Health
    public var deficiencyCured: (_ name: String) -> String
    public var wellAgain: (_ name: String) -> String
    public var hasAilment: (_ name: String, _ ailment: Ailment) -> String
    /// Follows `hasAilment` for the deficiency. Starts with a space.
    public var deficiencyHint: String
    /// Follows `hasAilment` when a kit is opened. Starts with a space.
    public var medsUsed: (_ left: Int) -> String
    public var causeThirst: String
    public var causeStarvation: String
    public var causeExhaustion: String
    public var leaderDied: (_ name: String, _ cause: String) -> String
    public var leaderDiedBody: String

    // Wear
    public var spoiled: (Int) -> String
    public var hullWarning: String
    public var sailsWarning: String
    public var wrecked: (_ vessel: String) -> String
    public var wreckedBody: String

    // From the menus
    public var depart: (GameState) -> String
    public var noProvisions: String
    public var rested: (_ turns: Int, HealthLabel) -> String
    public var mended: (_ percent: Int) -> String
    public var patched: (_ percent: Int) -> String
    public var yardHull: String
    public var yardSails: String
    public var noTradersLeft: String
    public var nobodyWants: String
    public var traderIntro: String
    public var noTackle: String
    public var tooRough: String
    public var catchReport: (_ caught: Int, _ limit: Int, _ got: Int) -> String
    public var defaultEpitaph: String

    // Choices
    public var tradeOffer: (_ intro: String, _ give: String, _ want: String) -> String
    public var tradeHave: (_ have: String) -> String
    public var tradeAccept: String
    public var tradeDecline: String
    public var tradeDone: String
    public var reached: (Stop, GameState) -> String
    public var goAshore: String
    public var passBy: String
    public var wavesGoodbye: (_ name: String) -> String

    // Score
    public var scoreSurvivors: (Int, HealthLabel) -> String
    public var scoreCondition: String
    public var scoreProvisions: String
    public var scoreStores: String
    public var scoreCash: String
    /// Four names, best first.
    public var ranks: [String]
}

// MARK: - Events

/// One thing that can happen on a turn under way. `Journey.events` lists them; the engine
/// picks one of those whose `ok` holds, by weight.
public struct JourneyEvent {
    public let weight: Double
    public let ok: Bool
    public let run: (GameEngine, inout [Interrupt]) -> Void

    public init(_ weight: Double, when ok: Bool = true, _ run: @escaping (GameEngine, inout [Interrupt]) -> Void) {
        self.weight = weight
        self.ok = ok
        self.run = run
    }
}

// MARK: - The journey

public class Journey {
    public let id: String
    public let text: JourneyText

    // What the journey picker shows.
    public internal(set) var title = ""
    public internal(set) var subtitle = ""
    public internal(set) var blurb = ""

    // Tables. Order is data in every one of them.
    public internal(set) var items: [Item] = []
    public internal(set) var stops: [Stop] = []
    public internal(set) var regions: [Region] = []
    public internal(set) var ports: [Port] = []
    public internal(set) var weathers: [Weather] = []
    /// The weather in port, at the finish, and on a forced fair turn.
    public internal(set) var fairWeather = Weather("fair", name: "Fair", speed: 1, wear: 0.25, sky: .clear)
    /// What the journey's slow sickness is, if it has one (1849: scurvy). It comes on
    /// after `Rules.deficiencyAfter` turns without `limes` and lasts until cured.
    public internal(set) var deficiency: Ailment?
    /// What anyone can come down with when `sickPool` isn't overridden.
    public internal(set) var ailments: [Ailment] = []
    public internal(set) var roles: [Role: RoleInfo] = [:]
    public internal(set) var paces: [Pace: PaceInfo] = [:]
    public internal(set) var rationings: [Rations: RationsInfo] = [:]
    /// Departure months offered: (year, 0-based month).
    public internal(set) var departures: [(year: Int, month: Int)] = []
    public internal(set) var firstNames: [String] = []
    public internal(set) var vesselNames: [String] = []
    public internal(set) var defaultTopTen: [TopTenEntry] = []
    /// What the foraging game lets you catch.
    public internal(set) var quarry: [Fish] = []
    public internal(set) var forageSeconds = 25.0
    /// What a catch is stowed as. A role's `catchLimit` and the item's room cap it.
    public internal(set) var forageReward = ItemKey.food
    public internal(set) var rules = Rules()

    init(id: String, text: JourneyText) {
        self.id = id
        self.text = text
    }

    // MARK: Lookups

    /// A journey that doesn't stock `key` gets an item with no room for it.
    public func item(_ key: ItemKey) -> Item {
        items.first { $0.key == key }
            ?? Item(key: key, name: "", unit: "", one: "", step: 1, per: 1, price: 0, max: 0, desc: "")
    }

    public func stop(_ id: String) -> Stop? { stops.first { $0.id == id } }
    public func port(_ stopID: String) -> Port? { ports.first { $0.id == stopID } }

    /// The port at `stopID` in this game: who keeps the store, what it charges, what is said
    /// there. Override when a fork changes it (the Klondike's two passes each have their own
    /// landing). The engine asks this one; `port(_:)` is the table's.
    public func port(_ s: GameState, at stopID: String) -> Port? { port(stopID) }
    public func role(_ r: Role) -> RoleInfo { roles[r]! }
    public func pace(_ p: Pace) -> PaceInfo { paces[p]! }
    public func rations(_ r: Rations) -> RationsInfo { rationings[r]! }
    public var totalMiles: Int { stops.last?.mile ?? 0 }
    /// Whether any pace burns fuel: the status panel shows the tank only if so.
    public var burnsFuel: Bool { Pace.allCases.contains { (paces[$0]?.fuel ?? 0) > 0 } }

    /// What a trader will take and give, in the order offers are drawn from.
    public var tradeKeys: [ItemKey] { items.map(\.key) }

    // MARK: Hooks: where and when

    public func region(_ s: GameState, at m: Int) -> Region {
        regions.first { m < $0.to } ?? regions[regions.count - 1]
    }

    public func temperature(_ s: GameState, in reg: Region) -> Temp { reg.temp }

    /// The season that makes freezing weather worse (1849: the southern winter).
    public func harshSeason(_ s: GameState) -> Bool { false }

    /// The hour as `GameState.dateText` writes it on a journey whose turns are shorter than
    /// a day: "6 p.m.", unless the journey keeps its log by another clock.
    public func hourText(_ hour: Int) -> String {
        "\(hour % 12 == 0 ? 12 : hour % 12) \(hour < 12 ? "a.m." : "p.m.")"
    }

    /// The turn's weather odds in `reg`. `cursed` is `GameState.badLuck` running.
    func weatherWeights(_ e: GameEngine, _ reg: Region, cursed: Bool) -> WeatherOdds { reg.weights }

    // MARK: Hooks: a turn under way

    /// Fewer hands, slower going.
    public func crewFactor(_ n: Int) -> Double { n >= 4 ? 1 : n == 3 ? 0.85 : n == 2 ? 0.65 : 0.45 }

    /// The journey's own speed factors, applied after sails, hull and crew and before the
    /// jitter.
    func adjustSpeed(_ e: GameEngine, _ reg: Region, _ sp: inout Double) {}

    /// What a turn under way burns: the pace's `fuel`. Override when the drive can stand
    /// idle with fuel aboard (the airship's engines, given out, burn none).
    func fuelBurn(_ e: GameEngine, _ pace: PaceInfo) -> Double { pace.fuel }

    /// Health each person gains or loses from the pace on a turn under way. Override when
    /// it depends on where you are (hauling on foot is harder work than rowing).
    public func paceHP(_ s: GameState) -> Double { pace(s.pace).hp }

    /// Water each person needs a turn at `temp`. Override when it scales with the cold
    /// (the Klondike's firewood) or stops on some legs.
    public func waterNeed(_ s: GameState, _ temp: Temp) -> Double { temp == .hot ? rules.hotWater : rules.water }

    /// The vehicle cannot move, or has something to meet before it does: what to show
    /// instead of a turn under way, which then does not happen (no time passes, no number is
    /// drawn). Nil, the default, while it can go on.
    /// What is shown must lead somewhere the vehicle can be put right or the journey ends:
    /// a choice that mends it, `.enterPort` to the menu, or `.gameOver`.
    func stalled(_ e: GameEngine) -> [Interrupt]? { nil }

    /// What the structure loses this turn. Rough weather costs up to its `harsh` in
    /// points, more at full pace and less at an easy one.
    func structureDamage(_ e: GameEngine, _ reg: Region) -> Double {
        var hd = rules.hullCreep
        let w = e.state.weather
        if w.isRough {
            hd += e.rnd(0, w.harsh) * (e.state.pace == .full ? 1.5 : e.state.pace == .easy ? 0.7 : 1)
        }
        return hd
    }

    /// What the drive (`sails`) loses this turn under way: the pace's wear, the weather's,
    /// and a jitter. Override when the drive can rest while moving (an airship adrift).
    func propulsionWear(_ e: GameEngine) -> Double {
        e.journey.pace(e.state.pace).wear * e.state.weather.wear
            * e.rnd(rules.wearJitter.lowerBound, rules.wearJitter.upperBound)
    }

    /// The wreck's title, from `text.wrecked`. Override when where it happens changes it.
    public func wreckedTitle(_ s: GameState) -> String { text.wrecked(TextMarkup.escape(s.ship)) }

    /// The paragraph under `text.wrecked`. Override when where it happens changes it.
    public func wreckedBody(_ s: GameState) -> String { text.wreckedBody }

    /// The paragraph under `text.leaderDied`. Override when where it happens, or who is
    /// left, changes it.
    public func leaderDiedBody(_ s: GameState) -> String { text.leaderDiedBody }

    /// Bookkeeping of the journey's own, once a turn after health and wear, in every mode.
    func tick(_ e: GameEngine, _ q: inout [Interrupt], _ mode: GameEngine.DayMode, _ reg: Region) {}

    /// What can happen on a turn that didn't end at a stop.
    func dayEvents(_ e: GameEngine, _ q: inout [Interrupt], _ reg: Region) {
        if e.chance(rules.eventChance) { e.runEvent(events(e, reg), &q) }
    }

    func events(_ e: GameEngine, _ reg: Region) -> [JourneyEvent] { [] }

    /// What someone falling sick here can come down with.
    func sickPool(_ e: GameEngine, _ temp: Temp, _ port: Port?) -> [Ailment] { ailments }

    // MARK: Hooks: arrivals and choices

    /// Reaching `stop`. A mark says its note, a port offers to stop, the end finishes; the
    /// journey's own set pieces come from `special`.
    func arrive(_ e: GameEngine, _ stop: Stop) -> [Interrupt] {
        switch stop.type {
        case .mark: return stop.note.isEmpty ? [] : [.message(stop.note)]
        case .port: return e.portArrival(stop)
        case .end: return [.finale]
        case .line, .fork, .island: return special(e, stop)
        }
    }

    func special(_ e: GameEngine, _ stop: Stop) -> [Interrupt] { [] }

    /// The player answered a choice this journey raised with `GameEngine.ask`.
    func resolve(_ e: GameEngine, _ key: String, _ args: [String], _ option: Int) -> [Interrupt] { [] }

    /// The player answered one of the named choice kinds, which are 1849's.
    func resolveNamed(_ e: GameEngine, _ event: ChoiceEvent, _ option: Int) -> [Interrupt] { [] }

    /// Whether the first port lets you go, beyond having food (`depart`). A refusal reads
    /// `text.noProvisions`, so a journey that refuses for more says so there.
    public func mayDepart(_ s: GameState) -> Bool { true }

    /// Whether the first port lets you go with no food aboard. Never, by default: the
    /// engine's own refusal. A journey whose first stores have nothing left in the purse's
    /// reach may let a hungry ship go rather than hold it there for good (decision D19).
    public func departsUnfed(_ s: GameState) -> Bool { false }

    /// What one step of `key` costs in the first port's stores, as their bill adds it up.
    public func firstPortStep(_ key: ItemKey) -> Double {
        guard let first = stops.first, let port = port(first.id) else { return .infinity }
        return GameEngine.bill([key: items.first { $0.key == key }?.step ?? 0], at: port)
    }

    /// Whether the purse still runs to one step of `key` in the first port's stores. A
    /// first port that holds you for something only while this is true can never hold you
    /// there for good (decisions D19, D21, D22).
    public func firstPortSells(_ key: ItemKey, _ s: GameState) -> Bool { firstPortStep(key) <= s.money }

    /// Leaving the ground: the first departure, or setting off from a port you went ashore
    /// at. Not called when travel resumes between ports.
    func leaving(_ e: GameEngine) {}

    /// Setting off from a port along the way: nil lets you go; otherwise you stay ashore and
    /// this is what happens instead (a choice whose answer may let you go by clearing
    /// `state.atPort`). The Klondike holds you at Lake Bennett for a boat and the ice.
    func holdInPort(_ e: GameEngine) -> [Interrupt]? { nil }

    /// The line after a repair, from `text` unless what is being mended changes on the way.
    public func repaired(_ s: GameState, _ job: RepairJob) -> String {
        switch job {
        case .mend: return text.mended(Int(jsRound(s.sails)))
        case .patch: return text.patched(Int(jsRound(s.hull)))
        case .yardHull: return text.yardHull
        case .yardSails: return text.yardSails
        }
    }

    /// A foraging outing is over and its catch stowed; the turn it takes has not passed yet.
    func foraged(_ e: GameEngine) {}

    /// Why foraging is off right now, or nil.
    func forageRefusal(_ e: GameEngine) -> String? {
        if e.state.tackle <= 0 { return text.noTackle }
        if e.state.weather.isRough { return text.tooRough }
        return nil
    }

    // MARK: Hooks: trade and score

    /// What a trader thinks one stored unit is worth.
    public func tradeValue(_ good: TradeGood) -> Double {
        switch good {
        case .money: return 1
        case .item(let k):
            let it = item(k)
            return it.price / Double(it.per)
        }
    }

    /// A drawn offer, last of all and after every draw: as it stands, cut to fit, or nil for
    /// no offer. The default leaves it as drawn, even when it gives more than there is room
    /// for (the excess is lost when it is stowed, as in the prototype).
    func fitOffer(_ e: GameEngine, _ o: Offer) -> Offer? { o }

    /// Bulk goods to 10s, boxed goods to whole boxes, money to 5s, the rest to whole units.
    public func roundTrade(_ good: TradeGood, _ v: Double) -> Int {
        switch good {
        case .money: return Int(max(5, jsRound(v / 5) * 5))
        case .item(let k):
            let it = item(k)
            if it.per > 1 {
                let p = Double(it.per)
                return Int(max(p, jsRound(v / p) * p))
            }
            if it.step >= 100 { return Int(max(10, jsRound(v / 10) * 10)) }
            return Int(max(1, jsRound(v)))
        }
    }

    /// "120 lbs of provisions", "$45". `amount` is in stored units. An item named for the
    /// unit it is counted in is counted by its name: "3 medicine kits", "1 wool blanket".
    public func describe(_ good: TradeGood, _ amount: Double) -> String {
        switch good {
        case .money: return "$\(jsNumber(amount))"
        case .item(let k):
            let it = item(k)
            let n = amount / Double(it.per)
            let unit = n == 1 ? it.one : it.unit
            let name = it.name.lowercased()
            if name == it.unit || name.hasSuffix(" " + it.unit) {
                return "\(jsNumber(n)) \(name.dropLast(it.unit.count))\(unit)"
            }
            return "\(jsNumber(n)) \(unit) of \(name)"
        }
    }

    public func score(_ s: GameState) -> Score {
        let alive = s.living.count
        let health = s.healthLabel
        var provisions = 0.0
        var stores = 0.0
        for it in items {
            let v = s[it.key] * tradeValue(.item(it.key))
            if it.key == .food || it.key == .water { provisions += v } else { stores += v }
        }
        return Score(lines: [
            .init(label: text.scoreSurvivors(alive, health), points: alive * health.scorePerSurvivor),
            .init(label: text.scoreCondition, points: Int(jsRound(s.hull * 2 + s.sails))),
            .init(label: text.scoreProvisions, points: Int((provisions / 3).rounded(.down))),
            .init(label: text.scoreStores, points: Int((stores / 3).rounded(.down))),
            .init(label: text.scoreCash, points: Int((s.money / 5).rounded(.down))),
        ], multiplier: s.role.scoreMultiplier)
    }

    public func rank(_ score: Int) -> String {
        for (i, cut) in rules.rankCuts.enumerated() where score >= cut { return text.ranks[i] }
        return text.ranks[rules.rankCuts.count]
    }
}

/// The four repairs the menus offer: a spare on the drive or the structure, or the yard on
/// either.
public enum RepairJob { case mend, patch, yardHull, yardSails }

// MARK: - The list

public enum Journeys {
    /// Every journey, in the order the picker shows them. Adding one is this line and
    /// its folder.
    public static let all: [Journey] = [Horn1849(), Rail(), Airship(), Balloon(), Klondike(), Mars()]

    private static let byID: [String: Journey] = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })

    /// An id no journey has (a save from a build with more journeys) falls back to 1849.
    /// Check `has` before trusting a save: its stop index is only good for its own journey.
    public static func journey(_ id: String) -> Journey { byID[id] ?? all[0] }

    public static func has(_ id: String) -> Bool { byID[id] != nil }
}
