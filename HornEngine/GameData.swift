// Static tables, copied from the prototype's `ROLES`, `ITEMS`, `VAL`, `PORTS`, `STOPS`,
// `REGIONS`, `MAGELLAN`, `WEATHER`, `PACE`, `RATIONS`, `AIL`, `DEATH_NAME`, `FIRST`,
// `SHIPS` and `DEFAULT_TOP` (docs/reference/horn1849.html). The prototype is the
// reference: change a number here only with Ryan's say-so (spec §0.5).
//
// ORDER IS DATA. Weather weights are ordered lists, not dictionaries, because the
// prototype's `wpick` walks an object in key order and a different order lands the same
// random number in a different bucket. Keep every list in the prototype's order.

// MARK: - Roles

public enum Role: String, Codable, CaseIterable {
    case merchant, shipwright, whaler

    public var label: String {
        switch self {
        case .merchant: return "Be a merchant from Boston"
        case .shipwright: return "Be a shipwright from Mystic"
        case .whaler: return "Be a whaler from Nantucket"
        }
    }

    /// As in "Bonus for being a merchant".
    public var title: String { rawValue }

    public var startingMoney: Double {
        switch self {
        case .merchant: return 1500
        case .shipwright: return 850
        case .whaler: return 500
        }
    }

    public var scoreMultiplier: Int {
        switch self {
        case .merchant: return 1
        case .shipwright: return 2
        case .whaler: return 3
        }
    }

    /// Percentage points one bolt of sailcloth restores at sea.
    public var sailMend: Double { self == .shipwright ? 40 : 25 }
    /// Percentage points one bundle of timber restores at sea.
    public var hullPatch: Double { self == .shipwright ? 35 : 20 }
    /// Pounds of fish the cook can salt from one outing.
    public var catchLimit: Int { self == .whaler ? 300 : 200 }
    /// Extra hit radius, in fishing-canvas pixels, around each fish.
    public var harpoonPadding: Double { self == .whaler ? 4 : 1.5 }
}

// MARK: - Items

public enum ItemKey: String, Codable, CaseIterable {
    case food, water, limes, meds, clothes, sailcloth, timber, tackle
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
    /// New York price per bought unit.
    public let price: Double
    /// Most bought units the ship can hold.
    public let max: Int
    public let desc: String

    /// Most STORED units the ship can hold (the prototype's `cap`).
    public var cap: Double { Double(max * per) }
}

public enum GameData {
    public static let items: [Item] = [
        Item(key: .food, name: "Provisions", unit: "lbs", one: "lb", step: 100, per: 1, price: 0.10, max: 3000,
             desc: "Salt beef, hardtack, beans. Each sailor eats 1–3 lbs a day."),
        Item(key: .water, name: "Fresh water", unit: "gal", one: "gal", step: 100, per: 1, price: 0.04, max: 1000,
             desc: "A gallon per person per day — more in the tropics."),
        Item(key: .limes, name: "Citrus", unit: "crates", one: "crate", step: 1, per: 1, price: 4, max: 40,
             desc: "Limes & lemons against scurvy. A crate lasts 5 sailors ~10 days."),
        Item(key: .meds, name: "Medicine", unit: "kits", one: "kit", step: 1, per: 1, price: 12, max: 12,
             desc: "Quinine, laudanum, bandages. One kit per illness halves its harm."),
        Item(key: .clothes, name: "Oilskins & woolens", unit: "sets", one: "set", step: 1, per: 1, price: 9, max: 12,
             desc: "One set per soul aboard, or the far south will kill them."),
        Item(key: .sailcloth, name: "Spare sailcloth", unit: "bolts", one: "bolt", step: 1, per: 1, price: 14, max: 20,
             desc: "For mending torn sails at sea."),
        Item(key: .timber, name: "Spare timber", unit: "bundles", one: "bundle", step: 1, per: 1, price: 11, max: 20,
             desc: "Planks, oakum & pitch to patch the hull."),
        Item(key: .tackle, name: "Fishing tackle", unit: "boxes", one: "box", step: 1, per: 20, price: 3, max: 600,
             desc: "Harpoons, hooks & line. Each box is 20 throws."),
    ]

    public static func item(_ key: ItemKey) -> Item {
        items.first { $0.key == key }!
    }

    /// The prototype's `VAL`: what a trader thinks one stored unit is worth.
    public static func tradeValue(_ good: TradeGood) -> Double {
        switch good {
        case .money: return 1
        case .item(let k):
            switch k {
            case .food: return 0.14
            case .water: return 0.05
            case .limes: return 4
            case .meds: return 12
            case .clothes: return 9
            case .sailcloth: return 14
            case .timber: return 11
            case .tackle: return 0.15
            }
        }
    }

    public static let months = ["January", "February", "March", "April", "May", "June", "July",
                                "August", "September", "October", "November", "December"]

    public static let firstNames = ["Ezra", "Hannah", "Silas", "Mercy", "Tobias", "Lydia", "Amos", "Prudence",
                                    "Caleb", "Martha", "Jonas", "Eliza", "Gideon", "Sarah", "Ira", "Abigail",
                                    "Moses", "Patience", "Levi", "Clara", "Obed", "Ruth", "Josiah", "Temperance",
                                    "Asa", "Phebe", "Reuben", "Charity"]

    public static let shipNames = ["Resolute", "Mary Ellen", "Golden Hope", "Sea Lark", "Persistence", "Wanderer",
                                   "Nantucket Belle", "Prosperity", "Endeavour", "Good Intent", "Morning Star",
                                   "Jenny Lind"]

    public static let defaultTopTen: [TopTenEntry] = [
        TopTenEntry(name: "Josiah Whitcombe", score: 7650), TopTenEntry(name: "Abigail Thorne", score: 6430),
        TopTenEntry(name: "Elias Mayhew", score: 5920), TopTenEntry(name: "Ruth Starbridge", score: 5110),
        TopTenEntry(name: "Obed Coffin", score: 4380), TopTenEntry(name: "Lydia Penhallow", score: 3800),
        TopTenEntry(name: "Amos Greenleaf", score: 3150), TopTenEntry(name: "Hannah Brewster", score: 2640),
        TopTenEntry(name: "Silas Weatherby", score: 1990), TopTenEntry(name: "Tobias Fenn", score: 1250),
    ]

    /// Departure months offered (spec §6): (year, 0-based month).
    public static let departures: [(year: Int, month: Int)] = [(1848, 11), (1849, 0), (1849, 1), (1849, 2), (1849, 3)]

    public static let totalMiles = 14_000
}

// MARK: - Ports

public enum PortID: String, Codable, CaseIterable {
    case ny, cv, rio, falk, valp, callao
}

public struct Port {
    public let id: PortID
    public let name: String
    public let shop: String
    public let mult: Double
    public let mods: [ItemKey: Double]
    public let fever: Bool
    /// Arrival paragraph. New York has none: nobody arrives there.
    public let arrive: String
    public let talk: [String]

    /// The prototype's `itemPrice`: `base × mult × mod`.
    public func price(_ key: ItemKey) -> Double {
        GameData.item(key).price * mult * (mods[key] ?? 1)
    }
}

public extension GameData {
    static func port(_ id: PortID) -> Port {
        switch id {
        case .ny:
            return Port(id: .ny, name: "New York", shop: "Hollis & Sons, Ship Chandlers", mult: 1, mods: [:], fever: false,
                        arrive: "", talk: [
                "A dockhand coiling rope: “Half the ships in this harbor are bound for California, and most of their captains have never seen the Horn. Buy woolens. Whatever you think you need — buy more.”",
                "A retired captain on a bollard: “Leave in December or January. You want to reach the Horn in February or March, when it's summer down there. Get there in June and you'll be beating against the wind for a month.”",
                "A ship's surgeon: “Lime juice, captain. A little every day and scurvy never comes aboard. The Navy learned that fifty years ago, and half the merchant fleet still ignores it.”",
            ])
        case .cv:
            return Port(id: .cv, name: "Porto Praia, Cape Verde", shop: "The market at Porto Praia", mult: 1.3,
                        mods: [.limes: 0.55, .water: 0.6, .clothes: 1.4, .timber: 1.4], fever: false,
                        arrive: "Porto Praia sits under bare brown hills. Boys row out to meet you with baskets of oranges.", talk: [
                "A harbor official: “South of here you run into the calms near the line. Some ships sit there two weeks with their sails hanging like laundry. Fill every cask you have.”",
                "A fruit seller: “Oranges! Limes! Very cheap, very good for sailors' teeth!”",
                "A whaleman's mate from New Bedford: “In the doldrums, rig a sail to catch the squalls. Rainwater is the sweetest water you'll drink all voyage.”",
            ])
        case .rio:
            return Port(id: .rio, name: "Rio de Janeiro", shop: "A chandler on the Rua Direita", mult: 1.45,
                        mods: [.limes: 0.5], fever: true,
                        arrive: "You glide past the great granite Sugar Loaf into one of the finest harbors in the world. The bay is crowded with California-bound ships.", talk: [
                "A British merchant: “Yellow fever comes and goes in this city. Don't linger longer than you must.”",
                "A gold-seeker from Ohio: “Two months at sea and I'd trade my share of the gold for a dry bunk. They tell me the worst is still ahead.”",
                "A harbor pilot: “South of the Plata, the weather turns. Bend on your heaviest canvas and break out the woolens.”",
            ])
        case .falk:
            return Port(id: .falk, name: "Port Stanley, Falklands", shop: "The Stanley company store", mult: 2,
                        mods: [.clothes: 0.9, .timber: 1.2], fever: false,
                        arrive: "A bleak, treeless settlement of stone cottages and peat smoke. Dismasted ships lie at anchor in the harbor.", talk: [
                "A sheep farmer: “Ships limp in here every week with their masts gone. The shipyard does good business. So does the graveyard.”",
                "A sealer: “Hug the Horn too close and the current will throw you on the rocks. Stand well south — fifty-seven degrees, if you can stand the ice.”",
                "The storekeeper: “Everything costs double here. Everything has to come from England.”",
            ])
        case .valp:
            return Port(id: .valp, name: "Valparaíso", shop: "Almacén del Puerto", mult: 1.6, mods: [:], fever: false,
                        arrive: "Valparaíso climbs steep hills above a crescent bay. After the far south, it looks like paradise.", talk: [
                "A Chilean merchant: “Welcome to the Pacific! From here the current flows north with you. Cold, but kind.”",
                "A homesick sailor: “Some crews jump ship here for the copper mines. Others hear the news from California and run there instead.”",
                "The harbor master: “You came round the bottom? Then the worst is behind you. Mind your water — the coast north of here is desert.”",
            ])
        case .callao:
            return Port(id: .callao, name: "Callao, Peru", shop: "A ship chandler near the mole", mult: 1.75,
                        mods: [.limes: 0.7], fever: true,
                        arrive: "The port of Lima. Pelicans wheel over the anchorage and the air smells of woodsmoke and salt.", talk: [
                "A Peruvian trader: “Lima is close, and beautiful. But the fevers on the waterfront are no joke.”",
                "A clipper captain: “Don't hug the coast from here. Stand out past the Galápagos, then swing north and east. The winds will thank you.”",
                "A woman returning from San Francisco: “Gold everywhere, and a dozen eggs costs a week's wages. Bring anything you can sell.”",
            ])
        }
    }
}

// MARK: - Stops

public enum StopType: String, Codable {
    case port, mark, line, fork, island, end
}

public struct Stop: Equatable {
    public let id: String
    /// As in "You have reached ___."
    public let name: String
    /// For the status panel and the chart legend.
    public let short: String
    public let type: StopType
    public let mile: Int

    public var portID: PortID? { type == .port ? PortID(rawValue: id) : nil }
}

public extension GameData {
    static let stops: [Stop] = [
        Stop(id: "ny", name: "New York", short: "New York", type: .port, mile: 0),
        Stop(id: "gulf", name: "the Gulf Stream", short: "Gulf Stream", type: .mark, mile: 300),
        Stop(id: "cv", name: "the Cape Verde Islands", short: "Cape Verde", type: .port, mile: 2900),
        Stop(id: "line", name: "the Equator", short: "Equator", type: .line, mile: 3850),
        Stop(id: "rio", name: "Rio de Janeiro", short: "Rio de Janeiro", type: .port, mile: 5200),
        Stop(id: "falk", name: "Port Stanley in the Falkland Islands", short: "Falklands", type: .port, mile: 7000),
        Stop(id: "tdf", name: "Tierra del Fuego", short: "Tierra del Fuego", type: .fork, mile: 7350),
        Stop(id: "pacific", name: "the Pacific", short: "The Pacific", type: .mark, mile: 7800),
        Stop(id: "valp", name: "Valparaíso", short: "Valparaíso", type: .port, mile: 8900),
        Stop(id: "callao", name: "Callao", short: "Callao", type: .port, mile: 10200),
        Stop(id: "gal", name: "the Galápagos Islands", short: "Galápagos", type: .island, mile: 11300),
        Stop(id: "sf", name: "San Francisco", short: "San Francisco", type: .end, mile: 14000),
    ]

    static func stop(_ id: String) -> Stop? {
        stops.first { $0.id == id }
    }
}

// MARK: - Weather

public enum Weather: String, Codable, CaseIterable {
    case fair, fresh, light, calm, hot, rain, fog, cold, gale, storm

    public var name: String {
        switch self {
        case .fair: return "Fair winds"
        case .fresh: return "Fresh breeze"
        case .light: return "Light airs"
        case .calm: return "Becalmed"
        case .hot: return "Hot & still"
        case .rain: return "Rain squalls"
        case .fog: return "Thick fog"
        case .cold: return "Sleet & snow"
        case .gale: return "Gale"
        case .storm: return "STORM"
        }
    }

    public var speed: Double {
        switch self {
        case .fair: return 1
        case .fresh: return 1.18
        case .light: return 0.5
        case .calm: return 0.06
        case .hot: return 0.35
        case .rain: return 0.9
        case .fog: return 0.6
        case .cold: return 0.8
        case .gale: return 0.75
        case .storm: return 0.35
        }
    }

    public var wear: Double {
        switch self {
        case .fair: return 0.25
        case .fresh: return 0.4
        case .light: return 0.1
        case .calm: return 0.03
        case .hot: return 0.05
        case .rain: return 0.3
        case .fog: return 0.15
        case .cold: return 0.6
        case .gale: return 1.2
        case .storm: return 2.5
        }
    }

    /// Health lost per sailing day. Zero for most weather.
    public var harsh: Double {
        switch self {
        case .gale: return 0.6
        case .storm: return 1.5
        default: return 0
        }
    }

    public var isRough: Bool { self == .gale || self == .storm }
}

// MARK: - Regions

public enum Temp: String, Codable {
    case cool, warm, hot, cold, freezing
}

public enum RegionID: String, Codable {
    case northAtlantic, northeastTrades, doldrums, southeastTrades, roaringForties, capeHorn,
         humboldt, tropicalPacific, northPacific, magellan
}

public struct Region: Equatable {
    public let id: RegionID
    /// Exclusive upper mile.
    public let to: Int
    public let name: String
    public let temp: Temp
    public let south: Bool
    public let horn: Bool
    public let strait: Bool
    /// In the prototype's key order.
    public let weights: [(Weather, Double)]

    public static func == (a: Region, b: Region) -> Bool { a.id == b.id }
}

public extension GameData {
    static let regions: [Region] = [
        Region(id: .northAtlantic, to: 2000, name: "North Atlantic", temp: .cool, south: false, horn: false, strait: false,
               weights: [(.fair, 30), (.fresh, 22), (.rain, 14), (.gale, 14), (.fog, 8), (.storm, 5), (.light, 7)]),
        Region(id: .northeastTrades, to: 3450, name: "Northeast Trades", temp: .warm, south: false, horn: false, strait: false,
               weights: [(.fair, 35), (.fresh, 40), (.rain, 10), (.light, 10), (.gale, 5)]),
        Region(id: .doldrums, to: 4300, name: "The Doldrums", temp: .hot, south: false, horn: false, strait: false,
               weights: [(.calm, 32), (.light, 25), (.hot, 18), (.rain, 20), (.fair, 5)]),
        Region(id: .southeastTrades, to: 6000, name: "Southeast Trades", temp: .warm, south: false, horn: false, strait: false,
               weights: [(.fair, 35), (.fresh, 35), (.rain, 12), (.light, 12), (.gale, 6)]),
        Region(id: .roaringForties, to: 7350, name: "Roaring Forties", temp: .cold, south: true, horn: false, strait: false,
               weights: [(.fresh, 22), (.gale, 30), (.storm, 12), (.rain, 14), (.fog, 10), (.cold, 12)]),
        Region(id: .capeHorn, to: 7800, name: "Cape Horn", temp: .freezing, south: true, horn: true, strait: false,
               weights: [(.gale, 35), (.storm, 28), (.cold, 22), (.fog, 8), (.fresh, 7)]),
        Region(id: .humboldt, to: 9600, name: "Humboldt Current", temp: .cold, south: true, horn: false, strait: false,
               weights: [(.fair, 30), (.fresh, 25), (.fog, 22), (.light, 10), (.gale, 13)]),
        Region(id: .tropicalPacific, to: 11800, name: "Tropical Pacific", temp: .hot, south: false, horn: false, strait: false,
               weights: [(.fair, 35), (.fresh, 20), (.light, 20), (.calm, 10), (.rain, 10), (.hot, 5)]),
        Region(id: .northPacific, to: Int.max, name: "North Pacific", temp: .cool, south: false, horn: false, strait: false,
               weights: [(.fair, 22), (.fresh, 22), (.gale, 18), (.fog, 18), (.rain, 15), (.storm, 5)]),
    ]

    /// Replaces the region for miles 7350–7799 once the Strait is chosen.
    static let magellan = Region(id: .magellan, to: 7800, name: "Strait of Magellan", temp: .freezing,
                                 south: true, horn: false, strait: true,
                                 weights: [(.fresh, 12), (.gale, 25), (.storm, 8), (.cold, 25), (.fog, 20), (.rain, 10)])
}

// MARK: - Pace & rations

public enum Pace: String, Codable, CaseIterable {
    case easy, steady, full

    public var name: String {
        switch self {
        case .easy: return "Easy sail"
        case .steady: return "Steady"
        case .full: return "Full canvas"
        }
    }

    /// Base nautical miles a day.
    public var speed: Double {
        switch self {
        case .easy: return 100
        case .steady: return 135
        case .full: return 170
        }
    }

    public var hp: Double {
        switch self {
        case .easy: return 0.5
        case .steady: return 0
        case .full: return -1
        }
    }

    public var wear: Double {
        switch self {
        case .easy: return 0.6
        case .steady: return 1
        case .full: return 2
        }
    }

    public var desc: String {
        switch self {
        case .easy: return "Reefed sails. Gentle on ship and crew."
        case .steady: return "A sensible spread of canvas."
        case .full: return "Every sail set. Fast, but hard on sails and sailors."
        }
    }
}

public enum Rations: String, Codable, CaseIterable {
    case filling, meager, bare

    public var name: String {
        switch self {
        case .filling: return "Filling"
        case .meager: return "Meager"
        case .bare: return "Bare bones"
        }
    }

    /// Pounds per person per day.
    public var lb: Double {
        switch self {
        case .filling: return 3
        case .meager: return 2
        case .bare: return 1
        }
    }

    public var hp: Double {
        switch self {
        case .filling: return 1
        case .meager: return -0.3
        case .bare: return -2.2
        }
    }

    public var desc: String {
        switch self {
        case .filling: return "3 lbs a day. Full meals."
        case .meager: return "2 lbs a day. Small meals."
        case .bare: return "1 lb a day. Hardtack and little else."
        }
    }
}

// MARK: - Ailments

public enum Ailment: String, Codable, CaseIterable {
    case scurvy = "scurvy"
    case shipFever = "ship fever"
    case dysentery = "dysentery"
    case yellowFever = "yellow fever"
    case fever = "a fever"
    case pneumonia = "pneumonia"
    case frostbite = "frostbite"
    case brokenArm = "a broken arm"
    case exhaustion = "exhaustion"

    /// As in "NAME has ___."
    public var name: String { rawValue }

    /// Health lost per day, halved when treated.
    public var damage: Double {
        switch self {
        case .scurvy: return 2.2
        case .shipFever: return 4.5
        case .dysentery: return 4.5
        case .yellowFever: return 6.5
        case .fever: return 3
        case .pneumonia: return 4.5
        case .frostbite: return 2.5
        case .brokenArm: return 1.2
        case .exhaustion: return 1.5
        }
    }

    /// Days it lasts, both ends included. Scurvy lasts until cured.
    public var duration: ClosedRange<Int> {
        switch self {
        case .scurvy: return 999...999
        case .shipFever: return 6...11
        case .dysentery: return 5...9
        case .yellowFever: return 5...8
        case .fever: return 4...7
        case .pneumonia: return 6...10
        case .frostbite: return 5...9
        case .brokenArm: return 14...24
        case .exhaustion: return 3...5
        }
    }

    /// As in "has died of ___". A broken arm doesn't kill; the wound does.
    public var deathName: String {
        self == .brokenArm ? "an infected wound" : rawValue
    }
}

// MARK: - Fishing (spec §9)

public struct Fish {
    public let name: String
    public let lb: Int
    public let width: Double
    public let height: Double
    /// Pixels per second, both ends included.
    public let speed: ClosedRange<Double>
    public let weight: Double
    public let color: String
}

public extension GameData {
    /// The prototype's `FISH`, in its order.
    static let fish: [Fish] = [
        Fish(name: "mackerel", lb: 4, width: 9, height: 3, speed: 26...42, weight: 35, color: "#7FD6C9"),
        Fish(name: "bonito", lb: 12, width: 12, height: 4, speed: 30...48, weight: 26, color: "#6F9DE0"),
        Fish(name: "dorado", lb: 25, width: 15, height: 5, speed: 36...56, weight: 18, color: "#E8C547"),
        Fish(name: "tuna", lb: 60, width: 20, height: 7, speed: 24...38, weight: 13, color: "#46689A"),
        Fish(name: "shark", lb: 120, width: 28, height: 7, speed: 38...58, weight: 8, color: "#8A949E"),
    ]

    /// Seconds in one fishing outing.
    static let fishingSeconds = 25.0
}
