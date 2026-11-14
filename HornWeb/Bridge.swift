#if os(WASI)
import FoundationEssentials
#else
import Foundation
#endif
import HornEngine

// The web version's way into the engine: one JSON request in, one JSON reply out.
//
// The browser runs this file compiled to WebAssembly (Exports.swift); on the Mac the same
// file answers the same requests on stdin (main.swift), which is how the Node tests prove
// the two give identical answers. Nothing here is a rule of the game: every call is one
// the app's GameController makes on `GameEngine`, under the same name, and every number
// and sentence in a reply is the engine's own.
//
// A request is an object with an `op` and that op's fields. A reply is an object with
// `ok: true` and the op's fields, or `ok: false` and an `error`. Ops that touch the voyage
// in hand reply with its `view`: the saved state (exactly as the app saves it) and what
// the screens derive from it.
public final class Bridge {
    /// The voyage in hand. One at a time, as in the app.
    var engine: GameEngine?

    public init() {}

    // MARK: - Requests

    struct Request: Decodable {
        let op: String
        // Starting a voyage
        var journey: String?
        var role: Role?
        var ship: String?
        var captain: String?
        var crew: [String]?
        var year: Int?
        var month: Int?
        /// The generator's seed, as a decimal string (a UInt64 doesn't fit a JS number).
        var seed: String?
        // Loading
        var save: SaveIn?
        // Actions
        var cart: [String: Int]?
        var days: Int?
        var caught: Int?
        var stopID: String?
        var choice: ChoiceEvent?
        var option: Int?
        var crewID: UUID?
        var cause: String?
        var epitaph: String?
        var pace: Pace?
        var rations: Rations?
        var pending: [Interrupt]?
        // Helpers
        var score: Int?
        var name: String?
        var table: [TopTenEntry]?
        var port: String?
        var n: Double?
        var text: String?
        var typed: String?
        var suggested: String?
        var max: Int?
    }

    /// A save as the app writes it: the voyage's own keys and, beside them, `pending`.
    struct SaveIn: Decodable {
        let state: GameState
        let pending: [Interrupt]

        enum Keys: String, CodingKey { case pending }

        init(from decoder: Decoder) throws {
            state = try GameState(from: decoder)
            let c = try decoder.container(keyedBy: Keys.self)
            pending = (try? c.decodeIfPresent([Interrupt].self, forKey: .pending)) ?? []
        }
    }

    /// What `save` writes: the same shape as the app's save file (Persistence.SaveFile).
    struct SaveOut: Encodable {
        let state: GameState
        let pending: [Interrupt]

        enum Keys: String, CodingKey { case pending }

        func encode(to encoder: Encoder) throws {
            try state.encode(to: encoder)
            guard !pending.isEmpty else { return }
            var c = encoder.container(keyedBy: Keys.self)
            try c.encode(pending, forKey: .pending)
        }
    }

    struct Failure: Error { let message: String }

    // MARK: - Entry

    /// Answers one request. Never throws: a bad request gets `ok: false`.
    public func handle(_ json: String) -> String {
        let reply: Reply
        do {
            let req = try JSONDecoder().decode(Request.self, from: Data(json.utf8))
            reply = try dispatch(req)
        } catch let f as Failure {
            reply = Reply.failure(f.message)
        } catch {
            reply = Reply.failure("bad request: \(error)")
        }
        return reply.json
    }

    func dispatch(_ r: Request) throws -> Reply {
        switch r.op {
        case "journeys":
            return Reply(["journeys": AnyEncodable(Journeys.all.map(JourneyInfo.init))])

        // MARK: Starting, saving, loading

        case "start":
            // GameController.chooseDeparture: the voyage at its first stop, before the shop.
            let id = try need(r.journey, "journey")
            guard Journeys.has(id) else { throw Failure(message: "no journey \(id)") }
            let s = GameState(journey: id, role: try need(r.role, "role"), ship: try need(r.ship, "ship"),
                              captain: try need(r.captain, "captain"), crew: try need(r.crew, "crew"),
                              startYear: try need(r.year, "year"), startMonth: try need(r.month, "month"))
            engine = GameEngine(state: s, rng: CountedRNG(seed: try seed(r)))
            return view()
        case "load":
            // GameController.continueSavedVoyage: a save the app would offer, and what was
            // waiting on screen when it was made.
            let save = try need(r.save, "save")
            let s = save.state
            guard s.saveVersion == GameState.currentSaveVersion, Journeys.has(s.journey), !s.over else {
                throw Failure(message: "this save can't be continued")
            }
            if let j = r.journey, j != s.journey { throw Failure(message: "the save is another journey's") }
            engine = GameEngine(state: s, rng: CountedRNG(seed: try seed(r)))
            return view(["pending": AnyEncodable(save.pending)])
        case "save":
            let e = try voyage()
            return Reply(["save": AnyEncodable(SaveOut(state: e.state, pending: r.pending ?? []))])
        case "view":
            return view()
        case "close":
            engine = nil
            return Reply([:])

        // MARK: The voyage (GameController and GameController+Menus, call for call)

        case "buy":
            let e = try voyage()
            var cart: [ItemKey: Int] = [:]
            for (k, n) in try need(r.cart, "cart") {
                guard let key = ItemKey(rawValue: k) else { throw Failure(message: "no item \(k)") }
                cart[key] = n
            }
            return view(["result": AnyEncodable(e.buy(cart))])
        case "depart":
            return view(["result": AnyEncodable(try voyage().depart())])
        case "setSail":
            try voyage().setSail()
            return view()
        case "sailDay":
            return interrupts(try voyage().sailDay())
        case "rest":
            return interrupts(try voyage().rest(days: try need(r.days, "days")))
        case "mendSails":
            return interrupts(try voyage().mendSails())
        case "patchHull":
            return interrupts(try voyage().patchHull())
        case "repairHullAtYard":
            return interrupts(try voyage().repairHullAtYard())
        case "recutSailsAtYard":
            return interrupts(try voyage().recutSailsAtYard())
        case "tradeAtPort":
            return interrupts(try voyage().tradeAtPort())
        case "talk":
            return view(["result": AnyEncodable(try voyage().talk())])
        case "throwHarpoon":
            return view(["result": AnyEncodable(try voyage().throwHarpoon())])
        case "landCatch":
            return interrupts(try voyage().landCatch(try need(r.caught, "caught")))
        case "beginArrival":
            return interrupts(try voyage().beginArrival(try need(r.stopID, "stopID")))
        case "resolve":
            return interrupts(try voyage().resolve(try need(r.choice, "choice"), option: try need(r.option, "option")))
        case "commitBurial":
            try voyage().commitBurial(crewID: try need(r.crewID, "crewID"), cause: try need(r.cause, "cause"),
                                      epitaph: r.epitaph ?? "")
            return view()
        case "finish":
            let e = try voyage()
            let score = e.finish()
            return view(["score": AnyEncodable(ScoreInfo(score)), "rank": AnyEncodable(e.journey.rank(score.total))])
        case "setPace":
            try voyage().state.pace = try need(r.pace, "pace")
            return view()
        case "setRations":
            try voyage().state.rations = try need(r.rations, "rations")
            return view()

        // MARK: Helpers the screens use, so the browser never re-implements a rule

        case "rank":
            return Reply(["result": AnyEncodable(try journey(r).rank(try need(r.score, "score")))])
        case "topTen":
            // TopTen.inserting into the table given, or the journey's default one.
            let table = try r.table ?? journey(r).defaultTopTen
            let (t, place) = TopTen.inserting(name: try need(r.name, "name"), score: try need(r.score, "score"),
                                              into: table)
            return Reply(["table": AnyEncodable(t), "place": AnyEncodable(place)])
        case "bill":
            let j = try journey(r)
            guard let port = j.port(try need(r.port, "port")) else { throw Failure(message: "no such port") }
            var cart: [ItemKey: Int] = [:]
            for (k, n) in try need(r.cart, "cart") { if let key = ItemKey(rawValue: k) { cart[key] = n } }
            return Reply(["result": AnyEncodable(GameEngine.bill(cart, at: port))])
        case "formatNumber":
            // An Int is 32 bits in WebAssembly: past that, `formatNumber` would trap. No
            // amount in the game comes near it.
            let n = try need(r.n, "n")
            guard n.isFinite, abs(n) < 2_147_483_647 else { throw Failure(message: "n is out of range") }
            return Reply(["result": AnyEncodable(formatNumber(n))])
        case "escape":
            return Reply(["result": AnyEncodable(TextMarkup.escape(try need(r.text, "text")))])
        case "name":
            // GameController.setNames for one field: trimmed, the suggestion if blank, cut
            // to `max` characters as Swift counts them.
            let t = trimmed(try need(r.typed, "typed"))
            let s = r.suggested ?? ""
            return Reply(["result": AnyEncodable(String((t.isEmpty ? s : t).prefix(try need(r.max, "max"))))])
        default:
            throw Failure(message: "no op \(r.op)")
        }
    }

    // MARK: - Pieces

    func need<T>(_ v: T?, _ name: String) throws -> T {
        guard let v else { throw Failure(message: "missing \(name)") }
        return v
    }

    func voyage() throws -> GameEngine {
        guard let e = engine else { throw Failure(message: "no voyage") }
        return e
    }

    func journey(_ r: Request) throws -> Journey {
        let id = try need(r.journey, "journey")
        guard Journeys.has(id) else { throw Failure(message: "no journey \(id)") }
        return Journeys.journey(id)
    }

    func seed(_ r: Request) throws -> UInt64 {
        guard let s = UInt64(try need(r.seed, "seed")) else { throw Failure(message: "seed must be a decimal UInt64") }
        return s
    }

    func interrupts(_ q: [Interrupt]) -> Reply {
        view(["interrupts": AnyEncodable(q)])
    }

    func view(_ extra: [String: AnyEncodable] = [:]) -> Reply {
        var fields = extra
        if let e = engine { fields["view"] = AnyEncodable(View(e)) }
        return Reply(fields)
    }
}

/// `trimmingCharacters(in: .whitespacesAndNewlines)`, which FoundationEssentials lacks:
/// Unicode's White_Space trimmed from both ends, scalar by scalar.
func trimmed(_ s: String) -> String {
    #if os(WASI)
    let u = s.unicodeScalars
    var lo = u.startIndex, hi = u.endIndex
    while lo < hi && u[lo].properties.isWhitespace { lo = u.index(after: lo) }
    while hi > lo && u[u.index(before: hi)].properties.isWhitespace { hi = u.index(before: hi) }
    return String(String.UnicodeScalarView(u[lo..<hi]))
    #else
    return s.trimmingCharacters(in: .whitespacesAndNewlines)
    #endif
}

// MARK: - Replies

struct AnyEncodable: Encodable {
    let encodeTo: (Encoder) throws -> Void
    init<T: Encodable>(_ v: T) { encodeTo = v.encode }
    func encode(to encoder: Encoder) throws { try encodeTo(encoder) }
}

struct Reply: Encodable {
    var fields: [String: AnyEncodable]
    var error: String?

    init(_ fields: [String: AnyEncodable]) { self.fields = fields }

    static func failure(_ m: String) -> Reply {
        var r = Reply([:])
        r.error = m
        return r
    }

    struct Key: CodingKey {
        var stringValue: String
        var intValue: Int? { nil }
        init(_ s: String) { stringValue = s }
        init?(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { nil }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: Key.self)
        try c.encode(error == nil, forKey: Key("ok"))
        if let error { try c.encode(error, forKey: Key("error")) }
        for (k, v) in fields { try c.encode(v, forKey: Key(k)) }
    }

    var json: String {
        let enc = JSONEncoder()
        enc.outputFormatting = [.sortedKeys]
        do {
            return String(decoding: try enc.encode(self), as: UTF8.self)
        } catch {
            return #"{"ok":false,"error":"could not encode the reply"}"#
        }
    }
}

/// The engine's own `SeededRNG`, counting what it hands out so a test can see a draw that
/// moved. The count and the generator's position are in every view.
struct CountedRNG: RandomSource {
    var base: SeededRNG
    var draws = 0

    init(seed: UInt64) { base = SeededRNG(seed: seed) }

    mutating func nextUnit() -> Double {
        draws += 1
        return base.nextUnit()
    }
}

// MARK: - The voyage, for the screens

/// `state` is the GameState exactly as the app saves it; the rest is what the app's
/// screens read off it and the engine (GameState's computed properties, GameEngine's
/// `can…` and costs), so the browser does no date sums or rules of its own.
struct View: Encodable {
    let state: GameState
    let dateText: String
    let date: [Int]
    let hour: Int
    let region: RegionInfo
    let temperature: Temp
    let averageHP: Double
    let healthLabel: String
    let healthColor: String
    let currentStop: String
    let nextStop: String?
    let inStrait: Bool
    let southernWinter: Bool
    let currentPort: String?
    let prices: [String: Double]
    let room: [String: Int]
    let canMendSails: Bool
    let canPatchHull: Bool
    let shipyardHullCost: Int
    let shipyardSailsCost: Int
    let canRepairHullAtYard: Bool
    let canRecutSailsAtYard: Bool
    let fishingRefusal: String?
    /// How many numbers the generator has handed out, and where it stands (decimal).
    let draws: Int
    let rng: String

    init(_ e: GameEngine) {
        let s = e.state
        state = s
        dateText = s.dateText
        let d = s.date
        date = [d.year, d.month, d.day]
        hour = s.hour
        let reg = s.region
        region = RegionInfo(reg)
        temperature = s.temperature(in: reg)
        averageHP = s.averageHP
        healthLabel = s.healthLabel.text
        healthColor = s.healthLabel.color
        currentStop = s.currentStop.id
        nextStop = s.nextStop?.id
        inStrait = s.inStrait
        southernWinter = s.southernWinter
        let port = e.currentPort
        currentPort = port?.id
        var prices: [String: Double] = [:]
        var room: [String: Int] = [:]
        for it in e.journey.items {
            if let port { prices[it.key.rawValue] = port.price(it.key) }
            room[it.key.rawValue] = e.room(for: it.key)
        }
        self.prices = prices
        self.room = room
        canMendSails = e.canMendSails
        canPatchHull = e.canPatchHull
        shipyardHullCost = e.shipyardHullCost
        shipyardSailsCost = e.shipyardSailsCost
        canRepairHullAtYard = e.canRepairHullAtYard
        canRecutSailsAtYard = e.canRecutSailsAtYard
        fishingRefusal = e.fishingRefusal
        let rng = e.rng as? CountedRNG
        draws = rng?.draws ?? 0
        self.rng = rng.map { String($0.base.state) } ?? ""
    }
}

struct ScoreInfo: Encodable {
    struct Line: Encodable {
        let label: String
        let points: Int
    }

    let lines: [Line]
    let subtotal: Int
    let multiplier: Int
    let total: Int

    init(_ s: Score) {
        lines = s.lines.map { Line(label: $0.label, points: $0.points) }
        subtotal = s.subtotal
        multiplier = s.multiplier
        total = s.total
    }
}

// MARK: - A journey's tables

struct RegionInfo: Encodable {
    struct Odds: Encodable {
        let weather: String
        let weight: Double
    }

    let id: String
    /// Null for a region that runs to the end (`Int.max`, which is 2^31 - 1 in WebAssembly
    /// and 2^63 - 1 on the Mac, and in neither case a number JavaScript holds exactly).
    let to: Int?
    let name: String
    let temp: Temp
    /// Sorted: a Set has no order of its own.
    let tags: [String]
    let nums: [String: Double]
    let weights: [Odds]

    init(_ r: Region) {
        id = r.id.rawValue
        to = r.to == Int.max ? nil : r.to
        name = r.name
        temp = r.temp
        tags = r.tags.sorted()
        nums = r.nums
        weights = r.weights.map { Odds(weather: $0.0.rawValue, weight: $0.1) }
    }
}

/// Everything the app reads off `Journey`: its tables in their order, the numbers the
/// screens show, and the few sentences the shell takes from the engine.
struct JourneyInfo: Encodable {
    struct ItemInfo: Encodable {
        let key: ItemKey
        let name: String
        let unit: String
        let one: String
        let step: Int
        let per: Int
        let price: Double
        let max: Int
        let desc: String
        let cap: Double
    }

    struct StopInfo: Encodable {
        let id: String
        let name: String
        let short: String
        let type: StopType
        let mile: Int
        let note: String
    }

    struct PortInfo: Encodable {
        let id: String
        let name: String
        let shop: String
        let mult: Double
        let mods: [String: Double]
        let fever: Bool
        let arrive: String
        let talk: [String]
        let prices: [String: Double]
    }

    struct RoleRow: Encodable {
        let role: Role
        let label: String
        let title: String
        let money: Double
        let mend: Double
        let patch: Double
        let catchLimit: Int
        let aim: Double
        let scoreMultiplier: Int
    }

    struct PaceRow: Encodable {
        let pace: Pace
        let name: String
        let speed: Double
        let hp: Double
        let wear: Double
        let fuel: Double
        let desc: String
    }

    struct RationsRow: Encodable {
        let rations: Rations
        let name: String
        let amount: Double
        let hp: Double
        let desc: String
    }

    struct Departure: Encodable {
        let year: Int
        let month: Int
    }

    struct Quarry: Encodable {
        let name: String
        let lb: Int
        let width: Double
        let height: Double
        let speed: [Double]
        let weight: Double
        let color: String
    }

    struct RulesInfo: Encodable {
        let tickHours: Int
        let startHour: Int
        let startDay: Int
        let restChoices: [Int]
        let rankCuts: [Int]
        let portTrades: Int
        let hullWarn: Double
        let sailsWarn: Double
    }

    struct TextInfo: Encodable {
        let noProvisions: String
        let defaultEpitaph: String
        let goAshore: String
        let passBy: String
        let tradeAccept: String
        let tradeDecline: String
        let ranks: [String]
    }

    let id: String
    let title: String
    let subtitle: String
    let blurb: String
    let items: [ItemInfo]
    let stops: [StopInfo]
    let regions: [RegionInfo]
    let ports: [PortInfo]
    let weathers: [Weather]
    let fairWeather: Weather
    let deficiency: Ailment?
    let ailments: [Ailment]
    let roles: [RoleRow]
    let paces: [PaceRow]
    let rations: [RationsRow]
    let departures: [Departure]
    let firstNames: [String]
    let vesselNames: [String]
    let defaultTopTen: [TopTenEntry]
    let quarry: [Quarry]
    let forageSeconds: Double
    let forageReward: ItemKey
    let totalMiles: Int
    let burnsFuel: Bool
    let tradeKeys: [ItemKey]
    let rules: RulesInfo
    let text: TextInfo

    init(_ j: Journey) {
        id = j.id
        title = j.title
        subtitle = j.subtitle
        blurb = j.blurb
        items = j.items.map {
            ItemInfo(key: $0.key, name: $0.name, unit: $0.unit, one: $0.one, step: $0.step, per: $0.per,
                     price: $0.price, max: $0.max, desc: $0.desc, cap: $0.cap)
        }
        stops = j.stops.map { StopInfo(id: $0.id, name: $0.name, short: $0.short, type: $0.type, mile: $0.mile, note: $0.note) }
        regions = j.regions.map(RegionInfo.init)
        ports = j.ports.map { p in
            var mods: [String: Double] = [:]
            for it in j.items { if let m = p.mods[it.key] { mods[it.key.rawValue] = m } }
            var prices: [String: Double] = [:]
            for it in j.items { prices[it.key.rawValue] = p.price(it.key) }
            return PortInfo(id: p.id, name: p.name, shop: p.shop, mult: p.mult, mods: mods, fever: p.fever,
                            arrive: p.arrive, talk: p.talk, prices: prices)
        }
        weathers = j.weathers
        fairWeather = j.fairWeather
        deficiency = j.deficiency
        ailments = j.ailments
        roles = Role.allCases.filter { j.roles[$0] != nil }.map { r in
            let i = j.role(r)
            return RoleRow(role: r, label: i.label, title: i.title, money: i.money, mend: i.mend, patch: i.patch,
                           catchLimit: i.catchLimit, aim: i.aim, scoreMultiplier: r.scoreMultiplier)
        }
        paces = Pace.allCases.filter { j.paces[$0] != nil }.map { p in
            let i = j.pace(p)
            return PaceRow(pace: p, name: i.name, speed: i.speed, hp: i.hp, wear: i.wear, fuel: i.fuel, desc: i.desc)
        }
        rations = Rations.allCases.filter { j.rationings[$0] != nil }.map { r in
            let i = j.rations(r)
            return RationsRow(rations: r, name: i.name, amount: i.amount, hp: i.hp, desc: i.desc)
        }
        departures = j.departures.map { Departure(year: $0.year, month: $0.month) }
        firstNames = j.firstNames
        vesselNames = j.vesselNames
        defaultTopTen = j.defaultTopTen
        quarry = j.quarry.map {
            Quarry(name: $0.name, lb: $0.lb, width: $0.width, height: $0.height,
                   speed: [$0.speed.lowerBound, $0.speed.upperBound], weight: $0.weight, color: $0.color)
        }
        forageSeconds = j.forageSeconds
        forageReward = j.forageReward
        totalMiles = j.totalMiles
        burnsFuel = j.burnsFuel
        tradeKeys = j.tradeKeys
        let r = j.rules
        rules = RulesInfo(tickHours: r.tickHours, startHour: r.startHour, startDay: r.startDay,
                          restChoices: r.restChoices, rankCuts: r.rankCuts, portTrades: r.portTrades,
                          hullWarn: r.hullWarn, sailsWarn: r.sailsWarn)
        let t = j.text
        text = TextInfo(noProvisions: t.noProvisions, defaultEpitaph: t.defaultEpitaph, goAshore: t.goAshore,
                        passBy: t.passBy, tradeAccept: t.tradeAccept, tradeDecline: t.tradeDecline, ranks: t.ranks)
    }
}
