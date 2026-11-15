#if os(WASI)
import FoundationEssentials
#else
import Foundation
#endif

// The shapes every journey fills in. The tables themselves live in each journey's folder
// (Journeys/<Name>/); nothing in this file knows which voyage is being played.
//
// The stock names on `ItemKey` and `GameState` are 1849's, kept because saves and the
// parity fixtures use them. Read them as roles: `limes` is whatever wards off the
// journey's slow sickness, `clothes` is warmth, `sailcloth` mends what drives the vessel
// (`sails`), `timber` mends what holds it together (`hull`), `tackle` is what the
// foraging game spends.

public let monthNames = ["January", "February", "March", "April", "May", "June", "July",
                         "August", "September", "October", "November", "December"]

// MARK: - Backgrounds

/// Three starting backgrounds: the most money, the handiest with repairs, or neither and
/// three times the score. Each journey names and prices them (`Journey.role`).
public enum Role: String, Codable, CaseIterable {
    case merchant, shipwright, whaler

    public var scoreMultiplier: Int {
        switch self {
        case .merchant: return 1
        case .shipwright: return 2
        case .whaler: return 3
        }
    }
}

public struct RoleInfo {
    /// The menu line: "A Boston merchant".
    public let label: String
    /// As in "Bonus for being a merchant".
    public let title: String
    public let money: Double
    /// Percentage points one spare restores to what drives the vessel, away from a yard.
    public let mend: Double
    /// Percentage points one spare restores to what holds it together.
    public let patch: Double
    /// Most the foraging game can add from one outing, in stored units of food.
    public let catchLimit: Int
    /// Extra hit radius, in foraging-canvas pixels.
    public let aim: Double

    public init(label: String, title: String, money: Double, mend: Double, patch: Double, catchLimit: Int,
                aim: Double) {
        self.label = label
        self.title = title
        self.money = money
        self.mend = mend
        self.patch = patch
        self.catchLimit = catchLimit
        self.aim = aim
    }
}

// MARK: - Items

public enum ItemKey: String, Codable, CaseIterable {
    case food, water, limes, meds, clothes, sailcloth, timber, tackle
    /// Burned under way by journeys that have an engine. 1849 has none.
    case fuel
}

public struct Item {
    public let key: ItemKey
    public let name: String
    public let unit: String
    public let one: String
    /// Units added per tap of + in the shop.
    public let step: Int
    /// Stored units per bought unit: a box of tackle is 20 throws.
    public let per: Int
    /// Price per bought unit where the journey starts.
    public let price: Double
    /// Most bought units the vessel can hold.
    public let max: Int
    public let desc: String

    public init(key: ItemKey, name: String, unit: String, one: String, step: Int, per: Int, price: Double,
                max: Int, desc: String) {
        self.key = key
        self.name = name
        self.unit = unit
        self.one = one
        self.step = step
        self.per = per
        self.price = price
        self.max = max
        self.desc = desc
    }

    /// Most STORED units the vessel can hold (the prototype's `cap`).
    public var cap: Double { Double(max * per) }
}

// MARK: - Ports

public struct Port {
    /// The id of the stop it stands at.
    public let id: String
    /// The id of the journey it belongs to, for its base prices.
    public let journey: String
    public let name: String
    public let shop: String
    public let mult: Double
    public let mods: [ItemKey: Double]
    public let fever: Bool
    /// Arrival paragraph. The starting port has none: nobody arrives there.
    public let arrive: String
    public let talk: [String]

    public init(id: String, journey: String, name: String, shop: String, mult: Double, mods: [ItemKey: Double] = [:],
                fever: Bool = false, arrive: String, talk: [String]) {
        self.id = id
        self.journey = journey
        self.name = name
        self.shop = shop
        self.mult = mult
        self.mods = mods
        self.fever = fever
        self.arrive = arrive
        self.talk = talk
    }

    /// The prototype's `itemPrice`: `base × mult × mod`.
    public func price(_ key: ItemKey) -> Double {
        Journeys.journey(journey).item(key).price * mult * (mods[key] ?? 1)
    }
}

// MARK: - Stops

public enum StopType: String, Codable {
    /// Somewhere to go ashore: shop, yard, trade, talk.
    case port
    /// A landmark passed with a sentence (`Stop.note`).
    case mark
    /// The three below are the journey's own set pieces (`Journey.special`): 1849 uses
    /// them for the Equator, the Tierra del Fuego fork and the Galápagos.
    case line, fork, island
    case end
}

public struct Stop: Equatable {
    public let id: String
    /// As in "You have reached ___."
    public let name: String
    /// For the status panel and the chart legend.
    public let short: String
    public let type: StopType
    /// Distance from the start, in the journey's units.
    public let mile: Int
    /// What a `.mark` says as you pass it.
    public let note: String

    public init(id: String, name: String, short: String, type: StopType, mile: Int, note: String = "") {
        self.id = id
        self.name = name
        self.short = short
        self.type = type
        self.mile = mile
        self.note = note
    }
}

// MARK: - Weather

/// What a day looks like, so a scene can pick a palette for weather it has never heard of.
public enum Sky: String, Codable {
    case clear, breeze, still, heat, rain, fog, snow, gale, storm, dust
}

/// One kind of weather. Each journey declares its own as static constants; two are the
/// same weather when their `rawValue`s match.
public struct Weather: Codable, Hashable {
    public let rawValue: String
    public let name: String
    /// Multiplies the day's run.
    public let speed: Double
    /// Multiplies the day's wear on what drives the vessel.
    public let wear: Double
    /// Health lost per day under way.
    public let harsh: Double
    /// Too rough to forage in.
    public let isRough: Bool
    /// Rain the crew can catch (`Rules.rainCatch`).
    public let wet: Bool
    public let sky: Sky
    /// The status line on a day of it under way, or "".
    public let note: String

    public init(_ rawValue: String, name: String, speed: Double, wear: Double, harsh: Double = 0,
                rough: Bool = false, wet: Bool = false, sky: Sky, note: String = "") {
        self.rawValue = rawValue
        self.name = name
        self.speed = speed
        self.wear = wear
        self.harsh = harsh
        isRough = rough
        self.wet = wet
        self.sky = sky
        self.note = note
    }

    public static func == (a: Weather, b: Weather) -> Bool { a.rawValue == b.rawValue }
    public func hash(into hasher: inout Hasher) { hasher.combine(rawValue) }
}

/// Weather odds as an ORDERED list: the pick walks it front to back, so order is data.
public typealias WeatherOdds = [(Weather, Double)]

/// Changes one weather's weight, adding it at the end if the list lacks it.
public func bump(_ w: inout WeatherOdds, _ k: Weather, _ f: (Double) -> Double) {
    if let i = w.firstIndex(where: { $0.0 == k }) { w[i].1 = f(w[i].1) } else { w.append((k, f(0))) }
}

// MARK: - Regions

public enum Temp: String, Codable {
    case cool, warm, hot, cold, freezing
}

public struct RegionID: RawRepresentable, Hashable, Codable, ExpressibleByStringLiteral {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(stringLiteral value: String) { rawValue = value }
}

public struct Region: Equatable {
    public let id: RegionID
    /// Exclusive upper bound, in the journey's distance units.
    public let to: Int
    public let name: String
    public let temp: Temp
    /// What the journey's own rules ask about: "south", "mountain", "sea".
    public let tags: Set<String>
    /// Numbers the journey's own rules read: an icing multiplier, a grade.
    public let nums: [String: Double]
    /// Ordered: see `WeatherOdds`.
    public let weights: WeatherOdds

    public init(id: RegionID, to: Int, name: String, temp: Temp, tags: Set<String> = [],
                nums: [String: Double] = [:], weights: WeatherOdds) {
        self.id = id
        self.to = to
        self.name = name
        self.temp = temp
        self.tags = tags
        self.nums = nums
        self.weights = weights
    }

    public func has(_ tag: String) -> Bool { tags.contains(tag) }
    public func num(_ key: String, or fallback: Double = 1) -> Double { nums[key] ?? fallback }

    public static func == (a: Region, b: Region) -> Bool { a.id == b.id }
}

// MARK: - Pace & rations

public enum Pace: String, Codable, CaseIterable {
    case easy, steady, full
}

public struct PaceInfo {
    public let name: String
    /// Distance in one turn before weather and wear.
    public let speed: Double
    /// Health change per turn under way.
    public let hp: Double
    /// Multiplies wear on what drives the vessel.
    public let wear: Double
    /// Fuel burned per turn under way. Zero for a journey without an engine.
    public let fuel: Double
    public let desc: String

    public init(name: String, speed: Double, hp: Double, wear: Double, fuel: Double = 0, desc: String) {
        self.name = name
        self.speed = speed
        self.hp = hp
        self.wear = wear
        self.fuel = fuel
        self.desc = desc
    }
}

public enum Rations: String, Codable, CaseIterable {
    case filling, meager, bare
}

public struct RationsInfo {
    public let name: String
    /// Food per person per turn, in stored units.
    public let amount: Double
    public let hp: Double
    public let desc: String

    public init(name: String, amount: Double, hp: Double, desc: String) {
        self.name = name
        self.amount = amount
        self.hp = hp
        self.desc = desc
    }
}

// MARK: - Ailments

/// One sickness or injury. Each journey declares its own as static constants. The
/// `rawValue` is also how it reads in "NAME has ___."
public struct Ailment: Codable, Hashable {
    public let rawValue: String
    /// Health lost per turn, less when treated.
    public let damage: Double
    /// Turns it lasts, both ends included. The journey's deficiency lasts until cured.
    public let duration: ClosedRange<Int>
    /// As in "has died of ___".
    public let deathName: String

    public var name: String { rawValue }

    public init(_ rawValue: String, damage: Double, days: ClosedRange<Int>, death: String? = nil) {
        self.rawValue = rawValue
        self.damage = damage
        duration = days
        deathName = death ?? rawValue
    }

    public static func == (a: Ailment, b: Ailment) -> Bool { a.rawValue == b.rawValue }
    public func hash(into hasher: inout Hasher) { hasher.combine(rawValue) }
}

// MARK: - Foraging game

/// One thing the foraging game lets you catch. 1849's are fish.
public struct Fish {
    public let name: String
    /// Stored units of food it is worth.
    public let lb: Int
    public let width: Double
    public let height: Double
    /// Pixels per second, both ends included.
    public let speed: ClosedRange<Double>
    public let weight: Double
    public let color: String

    public init(name: String, lb: Int, width: Double, height: Double, speed: ClosedRange<Double>, weight: Double,
                color: String) {
        self.name = name
        self.lb = lb
        self.width = width
        self.height = height
        self.speed = speed
        self.weight = weight
        self.color = color
    }
}
