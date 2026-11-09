import Foundation

public struct CrewMember: Codable, Equatable, Identifiable {
    public var id: UUID
    public var name: String
    public var hp: Double
    public var ailment: Ailment?
    public var ailDays: Double
    public var treated: Bool
    public var alive: Bool
    public var isCaptain: Bool
    /// A stowaway put ashore leaves at this stop.
    public var leaveAt: String?

    public init(id: UUID = UUID(), name: String, hp: Double = 100, isCaptain: Bool = false, leaveAt: String? = nil) {
        self.id = id
        self.name = name
        self.hp = hp
        ailment = nil
        ailDays = 0
        treated = false
        alive = true
        self.isCaptain = isCaptain
        self.leaveAt = leaveAt
    }
}

public struct Grave: Codable, Equatable {
    public var name: String
    public var cause: String
    public var date: String
    public var epitaph: String
}

/// One-time warnings, each re-armed when its stock recovers (spec §5.2, §5.4).
public struct WarningFlags: Codable, Equatable {
    public var food = false
    public var lowFood = false
    public var water = false
    public var lowWater = false
    public var limes = false
    public var hull = false
    public var sails = false
}

public enum Passage: String, Codable {
    case horn, magellan
}

/// Everything needed to resume a voyage (spec §2). Encoded as JSON for the save.
public struct GameState: Codable, Equatable {
    public static let currentSaveVersion = 1

    public var saveVersion = GameState.currentSaveVersion
    public var role: Role
    public var crew: [CrewMember]
    public var ship: String
    public var startYear: Int
    /// 0-based, matching the prototype.
    public var startMonth: Int
    /// Days elapsed since the 1st of the start month.
    public var day = 0
    public var mile = 0

    public var money: Double
    public var food: Double = 0
    public var water: Double = 0
    /// Fractional: the crew eats 0.02 crate each a day.
    public var limes: Double = 0
    public var meds = 0
    public var clothes = 0
    public var sailcloth = 0
    public var timber = 0
    /// In THROWS, not boxes: one box is 20.
    public var tackle = 0

    public var hull: Double = 100
    public var sails: Double = 100
    public var pace: Pace = .steady
    public var rations: Rations = .filling
    public var weather: Weather = .fair
    public var stopIndex = 0
    public var passage: Passage?
    public var pilot = false
    public var noCitrus = 0
    /// Days of foul weather left after shooting the albatross.
    public var badLuck = 0
    /// Days of guaranteed fair weather left after St. Elmo's fire.
    public var forceFair = 0
    public var graves: [Grave] = []
    public var flags = WarningFlags()
    public var tradesLeft = 3
    public var talkIndex = 0
    public var atPort = true
    public var over = false
    /// The teal line under the status panel ("Caught 30 gallons…"). Cleared each day.
    public var note = ""
    public var albatrossSeen = false
    public var stowawaySeen = false
    public var starving = false
    public var thirst = false

    /// A fresh voyage at New York, before the shop. `crew` is the four hands; the captain
    /// is added as crew[0].
    public init(role: Role, ship: String, captain: String, crew: [String], startYear: Int, startMonth: Int) {
        self.role = role
        self.ship = ship
        self.crew = [CrewMember(name: captain, isCaptain: true)] + crew.map { CrewMember(name: $0) }
        self.startYear = startYear
        self.startMonth = startMonth
        money = role.startingMoney
    }

    // MARK: Derived

    public var living: [CrewMember] { crew.filter(\.alive) }

    public var averageHP: Double {
        let l = living
        return l.isEmpty ? 0 : l.reduce(0) { $0 + $1.hp } / Double(l.count)
    }

    public var healthLabel: HealthLabel { HealthLabel(averageHP: averageHP) }

    public var currentStop: Stop { GameData.stops[stopIndex] }
    public var nextStop: Stop? { stopIndex + 1 < GameData.stops.count ? GameData.stops[stopIndex + 1] : nil }

    public var inStrait: Bool { passage == .magellan && mile >= 7350 && mile < 7800 }

    public func region(at m: Int) -> Region {
        if passage == .magellan && m >= 7350 && m < 7800 { return GameData.magellan }
        return GameData.regions.first { m < $0.to }!
    }

    public var region: Region { region(at: mile) }

    // MARK: Stock by key

    public subscript(item: ItemKey) -> Double {
        get {
            switch item {
            case .food: return food
            case .water: return water
            case .limes: return limes
            case .meds: return Double(meds)
            case .clothes: return Double(clothes)
            case .sailcloth: return Double(sailcloth)
            case .timber: return Double(timber)
            case .tackle: return Double(tackle)
            }
        }
        set {
            switch item {
            case .food: food = newValue
            case .water: water = newValue
            case .limes: limes = newValue
            case .meds: meds = Int(newValue)
            case .clothes: clothes = Int(newValue)
            case .sailcloth: sailcloth = Int(newValue)
            case .timber: timber = Int(newValue)
            case .tackle: tackle = Int(newValue)
            }
        }
    }

    public subscript(good: TradeGood) -> Double {
        get {
            switch good {
            case .money: return money
            case .item(let k): return self[k]
            }
        }
        set {
            switch good {
            case .money: money = newValue
            case .item(let k): self[k] = newValue
            }
        }
    }

    /// The prototype's `add`: change a stock, clamped to 0…capacity.
    public mutating func add(_ item: ItemKey, _ amount: Double) {
        self[item] = max(0, min(GameData.item(item).cap, self[item] + amount))
    }

    // MARK: Calendar

    private static let calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()

    public var date: (year: Int, month: Int, day: Int) {
        let c = Self.calendar
        let start = c.date(from: DateComponents(year: startYear, month: startMonth + 1, day: 1))!
        let d = c.date(byAdding: .day, value: day, to: start)!
        let parts = c.dateComponents([.year, .month, .day], from: d)
        return (parts.year!, parts.month! - 1, parts.day!)
    }

    /// 0-based month of the current date.
    public var month: Int { date.month }

    /// "March 4, 1849"
    public var dateText: String {
        let d = date
        return "\(GameData.months[d.month]) \(d.day), \(d.year)"
    }

    /// May–September: winter at the bottom of the world.
    public var southernWinter: Bool { (4...8).contains(month) }

    /// The prototype's `tempAt`.
    public func temperature(in reg: Region) -> Temp {
        var t = reg.temp
        let mo = month
        if reg.id == .northAtlantic && [10, 11, 0, 1, 2].contains(mo) { t = .cold }
        if reg.south && (4...8).contains(mo) && t == .cold { t = .freezing }
        return t
    }
}

public enum HealthLabel: String, Codable {
    case good, fair, poor
    case veryPoor = "very poor"

    public init(averageHP a: Double) {
        self = a >= 75 ? .good : a >= 50 ? .fair : a >= 28 ? .poor : .veryPoor
    }

    public var text: String { rawValue }

    /// The markup colour the prototype's `hCls` gives it.
    public var color: String {
        switch self {
        case .good: return "green"
        case .fair: return "amber"
        case .poor, .veryPoor: return "red"
        }
    }

    /// Points per survivor at the finale.
    public var scorePerSurvivor: Int {
        switch self {
        case .good: return 500
        case .fair: return 400
        case .poor: return 300
        case .veryPoor: return 200
        }
    }
}
