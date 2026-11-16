#if os(WASI)
import FoundationEssentials
#else
import Foundation
#endif

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
    public var fuel = false
    public var lowFuel = false
}

public enum Passage: String, Codable {
    case horn, magellan
}

/// Everything needed to resume a journey (spec §2). Encoded as JSON for the save.
///
/// Some fields are named for the 1849 voyage and mean their role on every journey:
/// `ship` is the vessel's name, `sails` what drives it and `hull` what holds it together,
/// `limes` whatever wards off the journey's slow sickness (`noCitrus` counts turns
/// without), `sailcloth` and `timber` what mends each. Model.swift lists the stock roles.
public struct GameState: Codable, Equatable {
    /// 2: the save names its journey and stores weather and ailments whole.
    public static let currentSaveVersion = 2

    public var saveVersion = GameState.currentSaveVersion
    /// The id of the journey this is (`Journeys.journey`).
    public var journey: String
    public var role: Role
    public var crew: [CrewMember]
    public var ship: String
    public var startYear: Int
    /// 0-based, matching the prototype.
    public var startMonth: Int
    /// Turns elapsed since the start. A turn is a day unless the journey's
    /// `Rules.tickHours` says otherwise.
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
    /// What an engine burns, on journeys that have one.
    public var fuel: Double = 0

    public var hull: Double = 100
    public var sails: Double = 100
    public var pace: Pace = .steady
    public var rations: Rations = .filling
    public var weather: Weather
    public var stopIndex = 0
    /// 1849: which way round the bottom of the world.
    public var passage: Passage?
    public var pilot = false
    public var noCitrus = 0
    /// Days of foul weather left after shooting the albatross.
    public var badLuck = 0
    /// Days of guaranteed fair weather left after St. Elmo's fire.
    public var forceFair = 0
    public var graves: [Grave] = []
    public var flags = WarningFlags()
    public var tradesLeft: Int
    public var talkIndex = 0
    public var atPort = true
    public var over = false
    /// The teal line under the status panel ("Caught 30 gallons…"). Cleared each day.
    public var note = ""
    public var albatrossSeen = false
    public var stowawaySeen = false
    public var starving = false
    public var thirst = false
    /// A journey's own numbers and switches, by name. Looked up, never looped over.
    public var vars: [String: Double] = [:]

    /// A fresh journey at its first port, before the shop. `crew` is the four hands; the
    /// captain is added as crew[0].
    public init(journey: String = Horn1849.id, role: Role, ship: String, captain: String, crew: [String],
                startYear: Int, startMonth: Int) {
        let j = Journeys.journey(journey)
        self.journey = j.id
        self.role = role
        self.ship = ship
        self.crew = [CrewMember(name: captain, isCaptain: true)] + crew.map { CrewMember(name: $0) }
        self.startYear = startYear
        self.startMonth = startMonth
        money = j.role(role).money
        weather = j.fairWeather
        tradesLeft = j.rules.portTrades
    }

    // MARK: Derived

    public var living: [CrewMember] { crew.filter(\.alive) }

    public var averageHP: Double {
        let l = living
        return l.isEmpty ? 0 : l.reduce(0) { $0 + $1.hp } / Double(l.count)
    }

    public var healthLabel: HealthLabel { HealthLabel(averageHP: averageHP) }

    public var currentStop: Stop { Journeys.journey(journey).stops[stopIndex] }
    public var nextStop: Stop? {
        let stops = Journeys.journey(journey).stops
        return stopIndex + 1 < stops.count ? stops[stopIndex + 1] : nil
    }

    /// 1849: in the Strait of Magellan.
    public var inStrait: Bool { passage == .magellan && mile >= 7350 && mile < 7800 }

    public func region(at m: Int) -> Region { Journeys.journey(journey).region(self, at: m) }

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
            case .fuel: return fuel
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
            case .fuel: fuel = newValue
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
        self[item] = max(0, min(Journeys.journey(journey).item(item).cap, self[item] + amount))
    }

    // MARK: Calendar

    private static let calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }()

    /// Where the calendar stands now, to the hour.
    private var moment: DateComponents {
        let c = Self.calendar
        let r = Journeys.journey(journey).rules
        let start = c.date(from: DateComponents(year: startYear, month: startMonth + 1, day: r.startDay))!
        let d: Date
        if r.tickHours == 24 && r.startHour == 0 {
            d = c.date(byAdding: .day, value: day, to: start)!
        } else {
            d = c.date(byAdding: .hour, value: r.startHour + day * r.tickHours, to: start)!
        }
        return c.dateComponents([.year, .month, .day, .hour], from: d)
    }

    public var date: (year: Int, month: Int, day: Int) {
        let parts = moment
        return (parts.year!, parts.month! - 1, parts.day!)
    }

    /// 0-based month of the current date.
    public var month: Int { date.month }

    /// Hour of the day, 0–23. Always 0 on a journey whose turns are whole days.
    public var hour: Int { moment.hour! }

    /// "March 4, 1849"; with the hour ("March 4, 1849, 6 p.m.", `Journey.hourText`) on a
    /// journey whose turns are shorter than a day.
    public var dateText: String {
        let parts = moment
        let text = "\(monthNames[parts.month! - 1]) \(parts.day!), \(parts.year!)"
        let j = Journeys.journey(journey)
        if j.rules.tickHours >= 24 { return text }
        return "\(text), \(j.hourText(parts.hour!))"
    }

    /// 1849. May–September: winter at the bottom of the world.
    public var southernWinter: Bool { (4...8).contains(month) }

    public func temperature(in reg: Region) -> Temp { Journeys.journey(journey).temperature(self, in: reg) }
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
