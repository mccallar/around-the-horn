#if os(WASI)
import FoundationEssentials
#else
import Foundation
#endif

// The Iron Road's tables: what the train carries, where it stops, the country it crosses
// and the weather there. Everything is in this namespace; nothing extends a shared type.

enum RailData {
    // MARK: - Numbers of its own

    /// The freight is due in twelve days (a turn is four hours)…
    static let contractTurns = 72
    /// …and the consignee walks away after sixteen.
    static let forfeitTurns = 96
    static let bonusPerTurn = 40
    /// Gallons the boiler never gets: the crew's own kegs.
    static let kegs = 60.0
    static let helperFee: [String: Double] = ["sherman": 30, "eastslope": 40]

    enum Season { case spring, summer, autumn, winter }

    /// `month` is 0-based.
    static func season(_ month: Int) -> Season {
        switch month {
        case 2, 3, 4: return .spring
        case 5, 6, 7: return .summer
        case 8, 9, 10: return .autumn
        default: return .winter
        }
    }

    // MARK: - Stock

    static let items: [Item] = [
        Item(key: .fuel, name: "Firewood", unit: "cords", one: "cord", step: 1, per: 10, price: 4, max: 16,
             desc: "The engine eats about a cord every four hours at timetable speed, more with the throttle wide. Dear on the plains, cheap in the mountains."),
        Item(key: .water, name: "Tank water", unit: "gallons", one: "gallon", step: 100, per: 1, price: 0.02, max: 1200,
             desc: "Your reserve, in a tank car. The trackside tanks keep the boiler full for nothing, except in the deserts, where it drinks 80 gallons or more every four hours from this."),
        Item(key: .food, name: "Provisions", unit: "lbs", one: "lb", step: 25, per: 1, price: 0.12, max: 400,
             desc: "Bacon, beans, hard bread, coffee. Five people eat about 15 lbs a day."),
        Item(key: .clothes, name: "Wool blankets", unit: "blankets", one: "blanket", step: 1, per: 1, price: 4, max: 10,
             desc: "One apiece. A caboose stove warms the half of you that faces it."),
        Item(key: .meds, name: "Medicine kits", unit: "kits", one: "kit", step: 1, per: 1, price: 9, max: 8,
             desc: "Quinine, calomel, liniment, clean bandages. Opened the moment someone falls sick."),
        Item(key: .sailcloth, name: "Boiler fittings", unit: "sets", one: "set", step: 1, per: 1, price: 14, max: 8,
             desc: "Flue plugs, packing, a gauge glass, a spare valve. One set and four hours puts the engine a good way right."),
        Item(key: .timber, name: "Car spares", unit: "crates", one: "crate", step: 1, per: 1, price: 11, max: 8,
             desc: "Journal brasses, brake shoes, links and pins. One crate and four hours mends the running gear."),
        Item(key: .tackle, name: "Grapnel line", unit: "coils", one: "coil", step: 1, per: 20, price: 2, max: 10,
             desc: "A coil is good for 20 casts. Where the line follows a river, driftwood is firewood for the price of getting wet."),
    ]

    // MARK: - Stops

    static let stops: [Stop] = [
        Stop(id: "omaha", name: "Omaha", short: "Omaha", type: .port, mile: 0),
        Stop(id: "grandisland", name: "Grand Island", short: "Grand Island", type: .mark, mile: 154,
             note: "Grand Island: a depot, a water tank and a sky. The Platte runs alongside, a mile wide and an inch deep, and will for two more days."),
        Stop(id: "northplatte", name: "North Platte", short: "North Platte", type: .port, mile: 291),
        Stop(id: "julesburg", name: "Julesburg", short: "Julesburg", type: .mark, mile: 377,
             note: "Julesburg. Two years ago it was the end of the track and the loudest town in the territory. The track moved on and took the noise with it. The line leaves the river here and starts, almost politely, to climb."),
        Stop(id: "cheyenne", name: "Cheyenne", short: "Cheyenne", type: .port, mile: 516),
        Stop(id: "dalecreek", name: "the Dale Creek trestle", short: "Dale Creek", type: .line, mile: 553),
        Stop(id: "rawlins", name: "Rawlins Springs", short: "Rawlins", type: .mark, mile: 709,
             note: "Rawlins Springs, and the last sweet water for a long way. [amber]West of here is the Red Desert: the boiler will drink from your tank car for the next 136 miles.[/amber]"),
        Stop(id: "greenriver", name: "Green River", short: "Green River", type: .port, mile: 845),
        Stop(id: "ogden", name: "Ogden", short: "Ogden", type: .port, mile: 1032),
        Stop(id: "promontory", name: "Promontory Summit", short: "Promontory", type: .mark, mile: 1084,
             note: "Promontory Summit, where the two roads met. The gold spike and the laurel tie spent one afternoon in the ground and were taken up again before dark; what holds the rails now is pine and iron, like everywhere else. [amber]The salt desert began back at Ogden, and the boiler drinks from your tank car for 166 miles yet.[/amber]"),
        Stop(id: "elko", name: "Elko", short: "Elko", type: .port, mile: 1305),
        Stop(id: "sink", name: "the Humboldt Sink", short: "Humboldt Sink", type: .mark, mile: 1530,
             note: "The Humboldt gives up here and soaks into the ground. The wagon people called what comes next the Forty-Mile Desert and counted the miles in dead oxen. [amber]It is sixty miles by rail, and the boiler drinks from your tank car for all of them.[/amber]"),
        Stop(id: "reno", name: "Reno", short: "Reno", type: .port, mile: 1620),
        Stop(id: "donner", name: "Donner Summit", short: "Donner Summit", type: .line, mile: 1669),
        Stop(id: "capehorn", name: "Cape Horn", short: "Cape Horn", type: .mark, mile: 1721,
             note: "The track rounds a ledge blasted out of the bluff, with the American River a very long way down on the left. The men who built it named it Cape Horn. You are told the other one is worse."),
        Stop(id: "sacramento", name: "Sacramento", short: "Sacramento", type: .end, mile: 1776),
    ]

    // MARK: - Weather

    static let fair = Weather("fair", name: "Fair", speed: 1, wear: 0.25, sky: .clear)
    static let headwind = Weather("headwind", name: "Head wind", speed: 0.9, wear: 0.35, sky: .breeze,
                                  note: "The wind is square on the smokebox and the smoke lies flat along the cars.")
    static let heat = Weather("heat", name: "Blazing heat", speed: 0.95, wear: 0.5, harsh: 0.4, sky: .heat,
                              note: "The rails ahead swim in the heat.")
    static let rain = Weather("rain", name: "Rain", speed: 0.9, wear: 0.3, wet: true, sky: .rain,
                              note: "Wet rail. The drivers slip on every start.")
    static let thunder = Weather("thunder", name: "Thunderstorm", speed: 0.7, wear: 0.6, harsh: 0.6, rough: true, wet: true,
                                 sky: .storm, note: "Lightning walks along the telegraph wire.")
    static let fog = Weather("fog", name: "Fog", speed: 0.75, wear: 0.25, sky: .fog,
                             note: "You run on the whistle and on faith.")
    static let dust = Weather("dust", name: "Dust storm", speed: 0.7, wear: 0.9, harsh: 0.5, rough: true, sky: .dust,
                              note: "Grit in the oil cups, grit in the coffee.")
    static let snow = Weather("snow", name: "Snow", speed: 0.75, wear: 0.5, harsh: 0.5, sky: .snow,
                              note: "Snow is settling between the rails.")
    static let blizzard = Weather("blizzard", name: "Blizzard", speed: 0.35, wear: 1.2, harsh: 1.5, rough: true, sky: .snow,
                                  note: "You cannot see the stack from the cab.")

    static let weathers = [fair, headwind, heat, rain, thunder, fog, dust, snow, blizzard]

    // MARK: - Country

    private static let plains: WeatherOdds = [(fair, 50), (headwind, 18), (rain, 10), (thunder, 6), (fog, 4), (dust, 4),
                                               (heat, 4), (snow, 3), (blizzard, 1)]
    private static let mountain: WeatherOdds = [(fair, 46), (headwind, 14), (rain, 10), (thunder, 5), (fog, 8), (snow, 12),
                                                 (blizzard, 5)]
    private static let desert: WeatherOdds = [(fair, 50), (headwind, 14), (heat, 14), (dust, 14), (rain, 3), (thunder, 3),
                                               (snow, 2)]
    private static let riverDesert: WeatherOdds = [(fair, 54), (headwind, 14), (heat, 10), (dust, 10), (rain, 5),
                                                    (thunder, 4), (snow, 3)]
    private static let valley: WeatherOdds = [(fair, 60), (rain, 14), (fog, 16), (headwind, 6), (heat, 4)]

    /// Tags: "river" (driftwood to be had), "plains", "mountain", "dry" (no boiler water
    /// by the track), "descent" (the brakes do the work), "valley". Numbers: "grade"
    /// multiplies speed unless a helper engine is on; "dry" is the gallons the boiler
    /// draws from the tank car each turn under way.
    static let regions: [Region] = [
        Region(id: "platte", to: 377, name: "The Platte Valley", temp: .cool, tags: ["river", "plains"], weights: plains),
        Region(id: "highplains", to: 516, name: "The High Plains", temp: .cool, tags: ["plains"], weights: plains),
        Region(id: "sherman", to: 573, name: "Sherman Hill", temp: .cool, tags: ["mountain"], nums: ["grade": 0.45],
               weights: mountain),
        Region(id: "laramie", to: 709, name: "The Laramie Plains", temp: .cool, tags: ["plains"], weights: plains),
        Region(id: "reddesert", to: 845, name: "The Red Desert", temp: .warm, tags: ["dry"], nums: ["dry": 80],
               weights: desert),
        Region(id: "wasatch", to: 1032, name: "The Wasatch", temp: .cool, tags: ["mountain", "river"], nums: ["grade": 0.8],
               weights: mountain),
        Region(id: "saltdesert", to: 1250, name: "The Salt Desert", temp: .warm, tags: ["dry"], nums: ["dry": 80],
               weights: desert),
        Region(id: "humboldt", to: 1530, name: "The Humboldt", temp: .warm, tags: ["river"], weights: riverDesert),
        Region(id: "fortymile", to: 1590, name: "The Forty-Mile Desert", temp: .warm, tags: ["dry"], nums: ["dry": 100],
               weights: desert),
        Region(id: "truckee", to: 1620, name: "The Truckee Meadows", temp: .cool, tags: ["river"], weights: riverDesert),
        Region(id: "eastslope", to: 1669, name: "The East Slope", temp: .cool, tags: ["mountain", "river"],
               nums: ["grade": 0.45], weights: mountain),
        Region(id: "sierra", to: 1745, name: "The Sierra Nevada", temp: .cool, tags: ["mountain", "descent"],
               weights: mountain),
        Region(id: "valley", to: 1777, name: "The Sacramento Valley", temp: .warm, tags: ["valley"], weights: valley),
    ]

    // MARK: - Ailments

    static let mountainFever = Ailment("mountain fever", damage: 3.5, days: 8...14)
    static let lungChill = Ailment("a chill on the lungs", damage: 3, days: 8...14)
    static let sunstroke = Ailment("sunstroke", damage: 3, days: 3...6)
    static let alkali = Ailment("alkali sickness", damage: 3, days: 4...8)
    static let scald = Ailment("a scalded arm", damage: 1.5, days: 10...18, death: "an infected scald")
    static let crushedHand = Ailment("a crushed hand", damage: 1.2, days: 12...20, death: "an infected wound")
    static let exhaustion = Ailment("exhaustion", damage: 1.5, days: 3...6)

    // MARK: - People, engines, the board

    static let departures: [(year: Int, month: Int)] = [(1869, 5), (1869, 7), (1869, 9), (1869, 11), (1870, 1)]

    static let firstNames = ["Amos", "Patrick", "Silas", "Josiah", "Hattie", "Michael", "Ezra", "Clara", "Otto", "Lars",
                             "Tobias", "Nell", "Cornelius", "Dennis", "Ada", "Henry", "Mae", "Walter", "Ruth", "Gideon"]

    static let vesselNames = ["Prairie Queen", "Morning Star", "Old Reliable", "Pathfinder", "Sagebrush", "Thunderhead",
                              "Iron Duchess", "Meadowlark", "Westward", "Tall Timber", "Plover", "Wanderer"]

    static let defaultTopTen: [TopTenEntry] = [
        TopTenEntry(name: "Hattie Corrigan", score: 8350),
        TopTenEntry(name: "Lars Engebretsen", score: 7400),
        TopTenEntry(name: "Josiah Tuttle", score: 6600),
        TopTenEntry(name: "Mae Okafor", score: 5850),
        TopTenEntry(name: "Dennis Rafferty", score: 5100),
        TopTenEntry(name: "Clara Whitlock", score: 4300),
        TopTenEntry(name: "Otto Brandt", score: 3550),
        TopTenEntry(name: "Silas Pettibone", score: 2800),
        TopTenEntry(name: "Nell Havercamp", score: 1950),
        TopTenEntry(name: "Gideon Marsh", score: 1150),
    ]

    /// What the river carries past. `lb` is tenths of a cord.
    static let drift: [Fish] = [
        Fish(name: "branch", lb: 2, width: 9, height: 3, speed: 26...42, weight: 35, color: "#B08A5A"),
        Fish(name: "fence rail", lb: 4, width: 12, height: 3, speed: 30...48, weight: 26, color: "#C9A66B"),
        Fish(name: "cottonwood limb", lb: 8, width: 15, height: 4, speed: 36...56, weight: 18, color: "#8C6B42"),
        Fish(name: "saw log", lb: 14, width: 20, height: 6, speed: 24...38, weight: 13, color: "#6E5233"),
        Fish(name: "raft of ties", lb: 25, width: 28, height: 7, speed: 38...58, weight: 8, color: "#A3815A"),
    ]

    /// "1.4 cords", "1 cord", from tenths of a cord.
    static func cords(_ tenths: Int) -> String {
        let whole = tenths / 10
        let part = tenths % 10
        let n = part == 0 ? "\(whole)" : "\(whole).\(part)"
        return "\(n) \(tenths == 10 ? "cord" : "cords")"
    }
}
