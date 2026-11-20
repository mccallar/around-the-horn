#if os(WASI)
import FoundationEssentials
#else
import Foundation
#endif

// To the Klondike's tables: the outfit, the stops, the three legs of country, the weather by
// season, and the names. Everything is in this namespace; nothing extends a shared type.
//
// Distances are in TENTHS of a mile: the trail moves under a mile a day. `Klondike.miles(_:)`
// turns them back into words for the skin.

enum KlondikeData {
    // MARK: - Numbers of its own

    /// The police rule at the summit: a year at three pounds a day, for every head.
    static let yearOfGrub = 1095.0
    static let packersFee = 90.0
    /// Hired packers speed the relay up to the summit.
    static let packersFactor = 1.4
    /// The miner's strong back, on foot legs.
    static let minerTrail = 1.15
    /// Exertion on foot is three quarters as bad on the White Pass's gentler grade.
    static let gentleFactor = 0.75
    static let pilotFee = 25.0
    static let boatPrice = 220.0
    /// Points for every day the party reaches Dawson before August 1, 1898.
    static let crowdBonusPerDay = 20
    /// Pounds of firewood a head a day before the temperature counts.
    static let firewoodPerHead = 4.0
    static let deadwood = 20...50

    /// Distance a day at pace factor 1, before weather, by leg (tenths of a mile).
    enum Leg: String { case steamer, foot, boat }

    static func base(_ leg: Leg) -> Double {
        switch leg {
        case .steamer: return 2200
        case .foot: return 9
        case .boat: return 300
        }
    }

    /// Health a day under way, by leg and pace (before the White Pass's gentler grade).
    static func paceHP(_ leg: Leg, _ pace: Pace) -> Double {
        switch (leg, pace) {
        case (.steamer, _): return 0
        case (.foot, .easy): return -0.5
        case (.foot, .steady): return -1.7
        case (.foot, .full): return -3.4
        case (.boat, .easy): return 0.5
        case (.boat, .steady): return 0
        case (.boat, .full): return -1
        }
    }

    /// Firewood burned, as a share of `firewoodPerHead`, by how cold it is.
    static func burn(_ t: Temp) -> Double {
        switch t {
        case .freezing: return 2
        case .cold: return 1.5
        case .cool: return 1
        case .warm, .hot: return 0.5
        }
    }

    // Stop miles, in tenths.
    static let landingMile = 11200
    static let campMile = 11330
    static let summitMile = 11365
    static let bennettMile = 11530

    // Keys into `GameState.vars`.
    static let routeKey = "klondike.route"
    static let packersKey = "klondike.packers"
    static let boatKey = "klondike.boat"
    static let breakupKey = "klondike.breakup"
    static let clearKey = "klondike.clear"
    static let rumourKey = "klondike.rumour"
    /// Set only while `haulDays` runs: the pace's health is the trail's.
    static let haulingKey = "klondike.hauling"
    /// Miles Canyon or Five Fingers, reached as the oars gave out: its index in `stops`.
    static let heldKey = "klondike.held"

    // Sleds or oars given out (Klondike+Trouble).
    /// What the next party along wants for a coil of rope & rawhide: three times Seattle's.
    static let coilPrice = 24.0
    /// Making do without one: two days' hard work for 10 points.
    static let makeDoDays = 2
    static let makeDoPoints = 10.0
    static let chilkoot = 1.0
    static let whitePass = 2.0

    // MARK: - Calendar

    enum Season: Int { case winter = 0, spring, summer }

    /// `month` is 0-based. Winter is November to March, spring April and May.
    static func season(_ month: Int) -> Season {
        switch month {
        case 3, 4: return .spring
        case 5...9: return .summer
        default: return .winter
        }
    }

    /// December, January and February: the freezing hurts more.
    static func deepWinter(_ month: Int) -> Bool { month == 11 || month == 0 || month == 1 }

    private static let daysBefore = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334]

    /// Day of 1898, January 1 = 0 (1898 was not a leap year).
    static func dayOfYear(month: Int, day: Int) -> Int { daysBefore[month] + day - 1 }

    static func dayOfYear(_ s: GameState) -> Int {
        let d = s.date
        return (d.year - 1898) * 365 + dayOfYear(month: d.month, day: d.day)
    }

    /// The earliest the ice on Lake Bennett can go out (May 24); it goes out up to eight days later.
    static let breakupEarliest = dayOfYear(month: 4, day: 24)
    /// When the old-timers say to be ready to push off (May 28).
    static let breakupUsual = dayOfYear(month: 4, day: 28)
    static let august1 = dayOfYear(month: 7, day: 1)

    /// Stored distance units in a mile.
    static let unitsPerMile = 10

    /// "1,136.5", from tenths.
    static func mileNumber(_ tenths: Int) -> String {
        let t = max(0, tenths)
        return "\(formatNumber(Double(t / unitsPerMile))).\(t % unitsPerMile)"
    }

    /// "1,136.5 miles", from tenths.
    static func miles(_ tenths: Int) -> String { "\(mileNumber(tenths)) miles" }

    // MARK: - Stock

    static let items: [Item] = [
        Item(key: .food, name: "Provisions", unit: "lbs", one: "lb", step: 250, per: 1, price: 0.10, max: 9000,
             desc: "Flour, bacon, beans, sugar, tea. Each of you eats 1–3 lbs a day, and the police want a year's worth."),
        Item(key: .water, name: "Firewood", unit: "lbs", one: "lb", step: 100, per: 1, price: 0.02, max: 2000,
             desc: "Stove wood. Two to eight lbs a head a day — and nothing grows on top of the pass."),
        Item(key: .limes, name: "Lime juice", unit: "jugs", one: "jug", step: 1, per: 1, price: 4, max: 40,
             desc: "Against scurvy, the winter sickness. A jug lasts five people about ten days."),
        Item(key: .meds, name: "Medicine chest", unit: "kits", one: "kit", step: 1, per: 1, price: 12, max: 12,
             desc: "Liniment, quinine, carbolic salve. One kit per illness halves its harm."),
        Item(key: .clothes, name: "Furs & mackinaws", unit: "sets", one: "set", step: 1, per: 1, price: 12, max: 12,
             desc: "Mackinaw, mitts, moccasins, fur cap. One set a head, or the summit takes fingers and toes."),
        Item(key: .sailcloth, name: "Rope & rawhide", unit: "coils", one: "coil", step: 1, per: 1, price: 8, max: 20,
             desc: "Mends sleds and straps on the trail; re-rigs oars and sail on the river. Boatbuilding takes some."),
        Item(key: .timber, name: "Canvas & pitch", unit: "bundles", one: "bundle", step: 1, per: 1, price: 10, max: 20,
             desc: "Patches a soaked outfit on the trail or a holed boat on the river. Boatbuilding takes some."),
        Item(key: .tackle, name: "Hooks & line", unit: "boxes", one: "box", step: 1, per: 20, price: 3, max: 600,
             desc: "Hooks, line and a spoon lure. Each box is 20 casts."),
    ]

    // MARK: - Stops

    static let stops: [Stop] = [
        Stop(id: "seattle", name: "Seattle", short: "Seattle", type: .port, mile: 0),
        Stop(id: "juneau", name: "Juneau", short: "Juneau", type: .port, mile: 10200),
        Stop(id: "lynn", name: "the head of Lynn Canal", short: "Lynn Canal", type: .fork, mile: 11100),
        Stop(id: "landing", name: "Dyea · Skagway", short: "Dyea · Skagway", type: .port, mile: landingMile),
        Stop(id: "camp", name: "Sheep Camp · White Pass City", short: "Sheep Camp · White Pass City", type: .port,
             mile: campMile),
        Stop(id: "summit", name: "the summit of the Chilkoot Pass · the summit of the White Pass",
             short: "Chilkoot summit · White Pass summit", type: .line, mile: summitMile),
        Stop(id: "lakes", name: "Lake Lindeman · Log Cabin", short: "Lindeman · Log Cabin", type: .mark, mile: 11460),
        Stop(id: "bennett", name: "Lake Bennett", short: "Lake Bennett", type: .port, mile: bennettMile),
        Stop(id: "tagish", name: "the police post at Tagish", short: "Tagish Post", type: .mark, mile: 12030,
             note: "At the police post at Tagish every boat is stopped. A constable paints a number on your bow and writes down everyone aboard — and the name of someone to write to if you never turn up in Dawson. Nobody talks much for the next few miles."),
        Stop(id: "canyon", name: "Miles Canyon", short: "Miles Canyon", type: .line, mile: 12530),
        Stop(id: "fivefinger", name: "Five Finger Rapids", short: "Five Fingers", type: .line, mile: 14670),
        Stop(id: "selkirk", name: "Fort Selkirk", short: "Fort Selkirk", type: .port, mile: 15250),
        Stop(id: "dawson", name: "Dawson City", short: "Dawson", type: .end, mile: 17000),
    ]

    /// The four stops whose name depends on the pass: (Chilkoot, White Pass), as
    /// "You have reached ___" and in the legend.
    static let variants: [String: (chilkoot: (name: String, short: String), whitePass: (name: String, short: String))] = [
        "landing": (("Dyea", "Dyea"), ("Skagway", "Skagway")),
        "camp": (("Sheep Camp", "Sheep Camp"), ("White Pass City", "White Pass City")),
        "summit": (("the summit of the Chilkoot Pass", "Chilkoot summit"), ("the summit of the White Pass", "White Pass summit")),
        "lakes": (("Lake Lindeman", "Lindeman"), ("Log Cabin", "Log Cabin")),
    ]

    // MARK: - Weather

    static let clear = Weather("clear", name: "Clear skies", speed: 1.15, wear: 0.3, sky: .clear)
    static let fair = Weather("fair", name: "Fair", speed: 1, wear: 0.25, sky: .breeze)
    static let rain = Weather("rain", name: "Rain", speed: 0.8, wear: 0.5, sky: .rain)
    static let fog = Weather("fog", name: "Low cloud", speed: 0.6, wear: 0.15, sky: .fog)
    static let snow = Weather("snow", name: "Snowfall", speed: 0.7, wear: 0.5, sky: .snow)
    static let thaw = Weather("thaw", name: "Slush & mud", speed: 0.55, wear: 0.9, sky: .dust)
    static let wind = Weather("wind", name: "High wind", speed: 0.7, wear: 1.1, harsh: 0.6, rough: true, sky: .gale)
    static let blizzard = Weather("blizzard", name: "BLIZZARD", speed: 0.2, wear: 2.2, harsh: 1.5, rough: true, sky: .storm,
                                  note: "Snow so thick you can't see the trail poles.")
    static let ice = Weather("ice", name: "Ice running", speed: 0.35, wear: 1.2, sky: .still,
                             note: "You pole your way between grinding cakes of ice.")
    static let hot = Weather("hot", name: "Hot & buggy", speed: 0.9, wear: 0.15, harsh: 0.5, sky: .heat,
                             note: "The mosquitoes come off the river in clouds.")

    static let weathers = [clear, fair, rain, fog, snow, thaw, wind, blizzard, ice, hot]

    // MARK: - Country

    /// Tags: the leg ("steamer", "foot", "boat"), "timber" (deadwood to gather), "fishable",
    /// "lakeIce" (thin ice), "slides", "snags", "open" (seasickness), "gentle" (the White
    /// Pass's grade). Numbers: "speed" multiplies the day's run; "slide" and "slideSpring"
    /// are the daily snowslide odds out of and in spring.
    static let regions: [Region] = [
        Region(id: "insidePassage", to: 3000, name: "The Inside Passage", temp: .cool, tags: ["steamer"],
               weights: odds["insidePassage"]![1]),
        Region(id: "queenCharlotte", to: 3600, name: "Queen Charlotte Sound", temp: .cool, tags: ["steamer", "open"],
               weights: odds["queenCharlotte"]![1]),
        // Dixon Entrance, where Alaska begins, is about mile 650.
        Region(id: "bcCoast", to: 6500, name: "The British Columbia coast", temp: .cool, tags: ["steamer"],
               weights: odds["bcCoast"]![1]),
        Region(id: "alaskaCoast", to: landingMile, name: "The Alaska coast", temp: .cool, tags: ["steamer"],
               weights: odds["alaskaCoast"]![1]),
        Region(id: "taiya", to: campMile + 1, name: "The Taiya valley", temp: .cool, tags: ["foot", "timber"],
               weights: odds["taiya"]![1]),
        Region(id: "chilkootSummit", to: 11460, name: "The Chilkoot summit", temp: .cold, tags: ["foot", "slides"],
               nums: ["slide": 0.005, "slideSpring": 0.02], weights: odds["chilkootSummit"]![1]),
        Region(id: "lindeman", to: bennettMile, name: "Lindeman & the lakes", temp: .cold,
               tags: ["foot", "timber", "fishable", "lakeIce"], weights: odds["lindeman"]![1]),
        Region(id: "upperLakes", to: 12450, name: "The upper lakes", temp: .cold, tags: ["boat", "timber", "fishable"],
               weights: odds["upperLakes"]![1]),
        Region(id: "fiftyMile", to: 12700, name: "The Fifty Mile River", temp: .cold,
               tags: ["boat", "timber", "fishable", "snags"], weights: odds["fiftyMile"]![1]),
        Region(id: "laberge", to: 13050, name: "Lake Laberge", temp: .cold, tags: ["boat", "timber", "fishable"],
               weights: odds["laberge"]![1]),
        Region(id: "yukon", to: 17001, name: "The Yukon", temp: .cool, tags: ["boat", "timber", "fishable", "snags"],
               weights: odds["yukon"]![1]),
    ]

    /// What the White Pass puts in place of the Chilkoot's three regions.
    static let whitePassRegions: [Region] = [
        Region(id: "skagwayValley", to: campMile + 1, name: "The Skagway valley", temp: .cool,
               tags: ["foot", "timber", "gentle"], nums: ["speed": 0.9], weights: odds["skagwayValley"]![1]),
        Region(id: "whitePassSummit", to: 11460, name: "The White Pass summit", temp: .cold,
               tags: ["foot", "slides", "gentle"], nums: ["speed": 0.9, "slide": 0.002, "slideSpring": 0.005],
               weights: odds["whitePassSummit"]![1]),
        Region(id: "logCabin", to: bennettMile, name: "Log Cabin & the lakes", temp: .cold,
               tags: ["foot", "timber", "fishable", "lakeIce", "gentle"], nums: ["speed": 0.9],
               weights: odds["logCabin"]![1]),
    ]

    static func leg(_ reg: Region) -> Leg { reg.has("steamer") ? .steamer : reg.has("foot") ? .foot : .boat }

    /// Temperature by season: winter, spring, summer.
    static let temps: [RegionID: [Temp]] = [
        "insidePassage": [.cool, .cool, .cool],
        "queenCharlotte": [.cool, .cool, .cool],
        "bcCoast": [.cool, .cool, .cool],
        "alaskaCoast": [.cool, .cool, .cool],
        "taiya": [.cold, .cool, .cool],
        "chilkootSummit": [.freezing, .cold, .cool],
        "lindeman": [.freezing, .cold, .cool],
        "upperLakes": [.freezing, .cold, .cool],
        "fiftyMile": [.freezing, .cold, .cool],
        "laberge": [.freezing, .cold, .cool],
        "yukon": [.freezing, .cool, .warm],
        "skagwayValley": [.cold, .cool, .cool],
        "whitePassSummit": [.freezing, .cold, .cool],
        "logCabin": [.freezing, .cold, .cool],
    ]

    /// Weather odds by season: winter, spring, summer. Order is data.
    static let odds: [RegionID: [WeatherOdds]] = {
        let insideSpring: WeatherOdds = [(fair, 30), (rain, 30), (fog, 15), (wind, 12), (snow, 8), (clear, 5)]
        let charlotteSpring: WeatherOdds = [(wind, 30), (rain, 25), (fair, 15), (fog, 15), (snow, 10), (blizzard, 5)]
        let coastSpring: WeatherOdds = [(rain, 28), (fair, 22), (fog, 14), (snow, 14), (wind, 14), (clear, 8)]
        let coast: [WeatherOdds] = [
            [(rain, 28), (fair, 22), (fog, 14), (snow, 24), (wind, 20), (clear, 8), (blizzard, 4)], coastSpring, coastSpring,
        ]
        let lindeman: [WeatherOdds] = [
            [(clear, 26), (snow, 24), (wind, 18), (fair, 14), (blizzard, 10), (fog, 8)],
            [(thaw, 22), (fair, 22), (snow, 16), (clear, 16), (wind, 14), (fog, 10)],
            [(thaw, 25), (rain, 25), (fair, 25), (wind, 15), (fog, 10)],
        ]
        let riverWinter: WeatherOdds = [(snow, 50), (clear, 50)]
        return [
            "insidePassage": [[(fair, 30), (rain, 21), (fog, 15), (wind, 18), (snow, 16), (clear, 5)], insideSpring, insideSpring],
            "queenCharlotte": [[(wind, 40), (rain, 25), (fair, 15), (fog, 15), (snow, 10), (blizzard, 11)], charlotteSpring,
                               charlotteSpring],
            "bcCoast": coast,
            "alaskaCoast": coast,
            "taiya": [
                [(clear, 28), (snow, 26), (fair, 16), (wind, 12), (fog, 8), (blizzard, 6), (rain, 4)],
                [(thaw, 28), (rain, 20), (fair, 20), (snow, 10), (fog, 10), (clear, 8), (wind, 4)],
                [(thaw, 30), (rain, 30), (fair, 20), (fog, 10), (clear, 10)],
            ],
            "chilkootSummit": [
                [(snow, 24), (wind, 22), (clear, 18), (blizzard, 14), (fog, 14), (fair, 8)],
                [(thaw, 22), (snow, 20), (fog, 16), (wind, 14), (clear, 12), (blizzard, 8), (fair, 8)],
                [(fog, 25), (rain, 25), (thaw, 20), (wind, 15), (fair, 10), (snow, 5)],
            ],
            "lindeman": lindeman,
            "skagwayValley": [
                [(clear, 26), (snow, 24), (fair, 16), (wind, 14), (fog, 8), (rain, 6), (blizzard, 6)],
                [(thaw, 34), (rain, 24), (fair, 16), (snow, 8), (fog, 8), (clear, 6), (wind, 4)],
                [(thaw, 34), (rain, 30), (fair, 16), (fog, 10), (clear, 10)],
            ],
            "whitePassSummit": [
                [(snow, 24), (wind, 24), (clear, 18), (fog, 16), (blizzard, 10), (fair, 8)],
                [(thaw, 26), (snow, 18), (fog, 18), (wind, 14), (clear, 10), (fair, 10), (blizzard, 4)],
                [(rain, 30), (fog, 25), (thaw, 20), (wind, 15), (fair, 10)],
            ],
            "logCabin": lindeman,
            "upperLakes": [
                [(clear, 26), (snow, 24), (wind, 18), (fair, 14), (blizzard, 10), (fog, 8)],
                [(ice, 30), (wind, 22), (fair, 18), (clear, 12), (rain, 10), (fog, 8)],
                [(fair, 30), (wind, 26), (rain, 14), (clear, 14), (fog, 8), (ice, 8)],
            ],
            "fiftyMile": [
                riverWinter,
                [(ice, 25), (fair, 25), (clear, 15), (rain, 15), (wind, 12), (fog, 8)],
                [(fair, 34), (clear, 20), (rain, 16), (wind, 14), (fog, 8), (ice, 8)],
            ],
            "laberge": [
                riverWinter,
                [(ice, 45), (wind, 20), (fair, 15), (fog, 10), (clear, 10)],
                [(fair, 26), (wind, 26), (ice, 18), (rain, 12), (fog, 10), (clear, 8)],
            ],
            "yukon": [
                riverWinter,
                [(fair, 25), (ice, 20), (clear, 15), (rain, 15), (wind, 12), (fog, 13)],
                [(fair, 32), (clear, 20), (hot, 16), (rain, 16), (wind, 8), (fog, 8)],
            ],
        ]
    }()

    // MARK: - Ailments

    static let scurvy = Ailment("scurvy", damage: 2.2, days: 1...1)
    static let pneumonia = Ailment("pneumonia", damage: 4.5, days: 6...10)
    static let typhoid = Ailment("typhoid fever", damage: 5.5, days: 7...12)
    static let fever = Ailment("a fever", damage: 3, days: 4...7)
    /// A camp's sickness of the bowels, by the period's own name (klondike.md, as built 24).
    static let flux = Ailment("the flux", damage: 4.5, days: 5...9)
    static let frostbite = Ailment("frostbite", damage: 2.5, days: 5...9)
    static let snowBlindness = Ailment("snow blindness", damage: 1, days: 2...4, death: "a fall on the ice")
    static let brokenLeg = Ailment("a broken leg", damage: 1.2, days: 14...24, death: "an infected wound")
    static let exhaustion = Ailment("exhaustion", damage: 1.5, days: 3...5)

    static let feverPortPool = [typhoid, fever, flux]
    static let hotPool = [fever, flux, exhaustion, typhoid, brokenLeg]
    static let coldPool = [pneumonia, frostbite, snowBlindness, fever, brokenLeg]
    static let mildPool = [fever, flux, brokenLeg, exhaustion, pneumonia]

    // MARK: - People, boats, the board

    static let departures: [(year: Int, month: Int)] = [(1898, 0), (1898, 1), (1898, 2), (1898, 3), (1898, 4)]

    static let firstNames = ["Will", "Martha", "Gus", "Clara", "Ed", "Nellie", "Frank", "Ida", "Hiram", "Belle", "Oscar",
                             "Mae", "Walter", "Lottie", "Arne", "Signe", "Jack", "Bess", "Charlie", "Effie", "Sam", "Hattie",
                             "Otto", "Pearl", "Lars", "Edna", "Ben", "Josie", "Homer", "Minnie", "Fred", "Ruby"]

    static let boatNames = ["Klondike Belle", "Yukon Lass", "Last Chance", "Never Sweat", "Bonanza Bound", "Hope On",
                            "Puget Belle", "Two Partners", "Sourdough Sal", "North Star", "Polly Ann", "Golden Fleece",
                            "Pay Dirt", "Ton of Grub"]

    static let defaultTopTen: [TopTenEntry] = [
        TopTenEntry(name: "Amos Tolliver", score: 7800),
        TopTenEntry(name: "Nora Halvorsen", score: 6600),
        TopTenEntry(name: "Jasper Quill", score: 5900),
        TopTenEntry(name: "Ada Brightwater", score: 5100),
        TopTenEntry(name: "Elmer Stroud", score: 4450),
        TopTenEntry(name: "Hattie Lindqvist", score: 3800),
        TopTenEntry(name: "Cyrus Pettibone", score: 3150),
        TopTenEntry(name: "Minnie Garvey", score: 2600),
        TopTenEntry(name: "Otto Sundberg", score: 1950),
        TopTenEntry(name: "Floyd Ashcombe", score: 1300),
    ]

    static let fish: [Fish] = [
        Fish(name: "grayling", lb: 3, width: 8, height: 3, speed: 30...46, weight: 35, color: "#9DB7C9"),
        Fish(name: "whitefish", lb: 6, width: 10, height: 4, speed: 24...38, weight: 26, color: "#D9DDE0"),
        Fish(name: "pike", lb: 12, width: 16, height: 4, speed: 36...56, weight: 18, color: "#6E8B3D"),
        Fish(name: "lake trout", lb: 25, width: 20, height: 6, speed: 22...36, weight: 13, color: "#8C7A5B"),
        Fish(name: "king salmon", lb: 45, width: 26, height: 7, speed: 34...52, weight: 8, color: "#C0605A"),
    ]
}
