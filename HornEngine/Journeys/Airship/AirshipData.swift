#if os(WASI)
import FoundationEssentials
#else
import Foundation
#endif

// Over the Pole's tables: what the airship carries, where she moors, the country and the
// ice she crosses and the weather there. Everything is in this namespace; nothing extends a
// shared type.

enum AirshipData {
    // MARK: - Numbers of its own

    /// Kilometres a watch she drifts with the tanks dry, before weather and lift.
    static let driftSpeed = 60.0
    /// Lift a whole watch adrift costs: with no engines to fly her nose-up, she is held at
    /// her height by valving gas when the sun warms her (docs/journeys/airship.md, D14).
    static let driftGas = 0.5
    /// Lift at 0%, with no ballast to drop: the petrol the dump valves let go, and the lift
    /// it buys back. Dearer by the point than a bag of ballast, and it is range besides.
    static let dumpPetrol = 300.0
    static let dumpLift = 10.0
    /// What seeps through the gas cells every flying watch.
    static let seep = 0.15
    /// The two ends of the unmapped ice, where the Pole's choice of height applies.
    static let forkFrom = 6550
    static let forkTo = 8600
    /// The wireless forecasts of the fog's height, under it.
    static let forecastFee = 60.0
    static let ridgeChance = 0.04
    static let ridgeChanceForecast = 0.01
    /// Heavy ship: below this much lift, with this much petrol aboard, she may have to dump.
    static let heavyBelow = 35.0
    static let heavyPetrol = 300.0
    static let heavyChance = 0.06
    static let heavyDump = 100...250
    /// A stowaway put off at a mast leaves at this one.
    static let stowawayLeaves = "pulham"
    static let stowawayBefore = 9
    /// The sack of coffee the trading post at Point Barrow hands up, in tins.
    static let barrowCoffee = 2.0

    // `GameState.vars` keys.
    static let routeKey = "airship.route"
    static let forecastKey = "airship.forecasts"
    static let flaresKey = "airship.flares"
    static let newsKey = "airship.news"
    static let driftingKey = "airship.drifting"
    /// Set once the crew has been told the engines have given out; cleared once they run.
    static let enginesOutKey = "airship.enginesOut"
    static let routeHigh = 1.0
    static let routeLow = 2.0

    // MARK: - Stock

    static let items: [Item] = [
        Item(key: .food, name: "Provisions", unit: "kg", one: "kg", step: 10, per: 1, price: 0.5, max: 300,
             desc: "Pemmican, biscuit, chocolate, tinned soup. Each hand eats 0.1–0.3 kg a watch."),
        Item(key: .water, name: "Drinking water", unit: "litres", one: "litre", step: 20, per: 1, price: 0.05, max: 300,
             desc: "About 0.6 litre per person per watch, in cans along the keel."),
        Item(key: .limes, name: "Coffee & cocoa", unit: "tins", one: "tin", step: 1, per: 1, price: 4, max: 20,
             desc: "Kept hot in vacuum flasks, it keeps the watch awake. A tin lasts five people about ten watches."),
        Item(key: .meds, name: "Medicine", unit: "kits", one: "kit", step: 1, per: 1, price: 15, max: 10,
             desc: "Aspirin, iodine, bandages, burn ointment. One kit per illness halves its harm."),
        Item(key: .clothes, name: "Fur flying suits", unit: "suits", one: "suit", step: 1, per: 1, price: 18, max: 8,
             desc: "Reindeer-skin suits and fur boots. One per soul aboard, or the polar cold will kill them."),
        Item(key: .sailcloth, name: "Engine spares", unit: "boxes", one: "box", step: 1, per: 1, price: 22, max: 10,
             desc: "Plugs, valves, magneto parts and a spare propeller blade, for repairs aloft."),
        Item(key: .timber, name: "Water ballast", unit: "bags", one: "bag", step: 1, per: 1, price: 8, max: 16,
             desc: "A hundred kilos of water and alcohol, so it won't freeze. Drop a bag and she rises."),
        Item(key: .tackle, name: "Pilot balloons", unit: "boxes", one: "box", step: 1, per: 10, price: 4, max: 30,
             desc: "Small red balloons for reading the winds aloft. Each box is 10 balloons."),
        Item(key: .fuel, name: "Petrol", unit: "kg", one: "kg", step: 100, per: 1, price: 0.015, max: 8000,
             desc: "Airships reckon petrol by weight. Cruising, she burns 250 kg a watch."),
    ]

    /// What a trader thinks one stored unit is worth.
    static let values: [ItemKey: Double] = [
        .food: 0.7, .water: 0.06, .limes: 4, .meds: 15, .clothes: 18, .sailcloth: 22, .timber: 8, .tackle: 0.4,
        .fuel: 0.025,
    ]

    // MARK: - Stops

    static let stops: [Stop] = [
        Stop(id: "rome", name: "Rome", short: "Rome", type: .port, mile: 0),
        Stop(id: "rhone", name: "the Rhône valley", short: "Rhône Valley", type: .mark, mile: 650,
             note: "You cross the coast at the mouth of the Rhône and turn north up its valley. The mistral comes funnelling down between the hills to meet you, and the mechanics frown at their gauges."),
        Stop(id: "pulham", name: "the air station at Pulham, England", short: "Pulham", type: .port, mile: 1700),
        Stop(id: "oslo", name: "the Ekeberg mast at Oslo", short: "Oslo", type: .port, mile: 2750),
        Stop(id: "circle", name: "the Arctic Circle", short: "Arctic Circle", type: .line, mile: 3650),
        Stop(id: "vadso", name: "the mast at Vadsø", short: "Vadsø", type: .port, mile: 4200),
        Stop(id: "bear", name: "Bear Island", short: "Bear Island", type: .mark, mile: 4800,
             note: "Bear Island slides past to the west: a black wedge of cliffs streaked with snow, with a cloud of seabirds around it. After this there is nothing below but the Barents Sea, all the way to Spitsbergen."),
        Stop(id: "kingsbay", name: "Kings Bay, Spitsbergen", short: "Kings Bay", type: .port, mile: 5300),
        Stop(id: "pole", name: "the North Pole", short: "North Pole", type: .fork, mile: 6550),
        Stop(id: "barrow", name: "Point Barrow", short: "Point Barrow", type: .island, mile: 8600),
        Stop(id: "wales", name: "Cape Prince of Wales", short: "Cape Prince of Wales", type: .mark, mile: 9430,
             note: "Through a gap in the cloud you see two coasts at once: Cape Prince of Wales below you, the westernmost point of America, and far across the strait, blue in the distance, the hills of Asia. The wind is doing its best to push you over there."),
        Stop(id: "nome", name: "Nome", short: "Nome", type: .end, mile: 9600),
    ]

    // MARK: - Weather

    static let fair = Weather("fair", name: "Fair & clear", speed: 1, wear: 0.5, sky: .clear)
    static let tail = Weather("tail", name: "Following wind", speed: 1.3, wear: 0.5, sky: .breeze)
    static let head = Weather("head", name: "Headwind", speed: 0.6, wear: 1, sky: .breeze,
                              note: "The engines roar and the ground below barely moves.")
    static let rain = Weather("rain", name: "Rain", speed: 0.85, wear: 0.6, wet: true, sky: .rain)
    static let fog = Weather("fog", name: "Fog", speed: 0.7, wear: 0.3, sky: .fog)
    static let snow = Weather("snow", name: "Snow", speed: 0.75, wear: 1, sky: .snow)
    static let ice = Weather("ice", name: "Icing fog", speed: 0.55, wear: 1.8, harsh: 0.6, sky: .fog,
                             note: "Ice is forming on the struts and the propellers.")
    static let gale = Weather("gale", name: "Gale", speed: 0.45, wear: 2, harsh: 0.8, rough: true, sky: .gale)
    static let storm = Weather("storm", name: "THUNDERSTORM", speed: 0.35, wear: 3, harsh: 1.5, rough: true, wet: true,
                               sky: .storm)

    static let weathers = [fair, tail, head, rain, fog, snow, ice, gale, storm]

    // MARK: - Country

    /// Tags: "sea" (open water below: steamers and fishing boats), "north" (the seasons
    /// move the weather and the cold), "pack" (sea ice below, at least when it freezes),
    /// "ridges" (pressure ridges hidden in the fog). Numbers:
    /// "superheat" (lift lost to the sun every flying watch), "iceMult" (multiplies icing).
    static let regions: [Region] = [
        Region(id: "med", to: 650, name: "Mediterranean", temp: .warm, tags: ["sea"],
               weights: [(fair, 35), (tail, 15), (head, 18), (rain, 12), (fog, 6), (gale, 6), (storm, 4)]),
        Region(id: "france", to: 1700, name: "France", temp: .cool,
               weights: [(fair, 28), (head, 22), (tail, 14), (rain, 18), (fog, 10), (gale, 5), (storm, 3)]),
        Region(id: "northSea", to: 2750, name: "North Sea", temp: .cool, tags: ["sea"],
               weights: [(fair, 20), (head, 20), (tail, 14), (rain, 14), (fog, 18), (gale, 14)]),
        Region(id: "scandinavia", to: 4200, name: "Scandinavia", temp: .cold, tags: ["north"],
               weights: [(fair, 26), (head, 16), (tail, 14), (snow, 18), (fog, 10), (gale, 10), (ice, 6)]),
        Region(id: "barents", to: 5300, name: "Barents Sea", temp: .cold, tags: ["north", "sea", "pack"],
               weights: [(fog, 24), (fair, 16), (head, 14), (tail, 10), (snow, 14), (gale, 12), (ice, 10)]),
        Region(id: "polarSea", to: forkFrom, name: "The Polar Sea", temp: .freezing, tags: ["north", "pack"],
               weights: [(fair, 24), (fog, 20), (tail, 12), (head, 12), (snow, 12), (ice, 12), (gale, 8)]),
        aboveFog,
        Region(id: "alaska", to: 9601, name: "Alaskan Coast", temp: .cold, tags: ["north", "pack"],
               weights: [(fog, 20), (gale, 18), (head, 16), (ice, 10), (snow, 10), (fair, 16), (tail, 10)]),
    ]

    /// The two heights beyond the Pole. The table holds the high one, which is also the
    /// region before the choice is made.
    static let aboveFog = Region(id: "aboveFog", to: forkTo, name: "Above the Fog", temp: .freezing, tags: ["north", "pack"],
                                 nums: ["superheat": 0.6],
                                 weights: [(fair, 26), (tail, 10), (head, 26), (snow, 6), (fog, 8), (ice, 4), (gale, 12)])
    static let underFog = Region(id: "underFog", to: forkTo, name: "Under the Fog", temp: .cold,
                                 tags: ["north", "pack", "ridges"], nums: ["iceMult": 1.5],
                                 weights: [(fog, 30), (ice, 20), (fair, 12), (head, 10), (snow, 10), (tail, 8), (gale, 8)])

    // MARK: - Ailments

    static let watchFatigue = Ailment("watch fatigue", damage: 2.2, days: 1...1, death: "exhaustion")
    static let frostbite = Ailment("frostbite", damage: 2.5, days: 5...9)
    static let pneumonia = Ailment("pneumonia", damage: 4.5, days: 6...10)
    static let influenza = Ailment("influenza", damage: 4.5, days: 5...9)
    static let fever = Ailment("a fever", damage: 3, days: 4...7)
    static let fumes = Ailment("fume sickness", damage: 3.5, days: 2...4, death: "fume poisoning")
    static let snowBlindness = Ailment("snow blindness", damage: 1.2, days: 6...12, death: "exposure")
    static let airsickness = Ailment("airsickness", damage: 1.5, days: 3...5, death: "exhaustion")
    static let brokenArm = Ailment("a broken arm", damage: 1.2, days: 14...24, death: "an infected wound")

    static let mastPool = [influenza, fever, pneumonia]
    static let coldPool = [frostbite, pneumonia, snowBlindness, influenza, brokenArm]
    static let mildPool = [airsickness, fumes, fever, influenza, brokenArm]

    // MARK: - People, airships, the board

    static let departures: [(year: Int, month: Int)] = [(1926, 3), (1926, 4), (1926, 5), (1926, 6)]

    static let firstNames = ["Arne", "Ingrid", "Sigurd", "Solveig", "Olav", "Astrid", "Leif", "Margit", "Emilio", "Rosa",
                             "Natale", "Lucia", "Renato", "Elena", "Walter", "Edith", "Harold", "Dorothy", "Clarence",
                             "Mildred", "Ellis", "Hazel", "Ruben", "Greta", "Tor", "Helga", "Vittorio", "Bianca", "Finn",
                             "Karin"]
    static let stowawayFallback = "Finn"

    static let vesselNames = ["Polar Star", "Northern Light", "Aurora", "Snow Goose", "Kittiwake", "Midnight Sun",
                              "Borealis", "Silver Gull", "Ice Petrel", "True North", "Northward", "Fulmar", "Skylark"]

    /// Old hulls seen from the air.
    static let wrecks = ["Good Intent", "Margaret Lowe", "Brave Endeavour", "Sea Lark", "Northern Venture", "Ellen Shaw",
                         "Hope of Tromsø", "Patience", "Two Brothers", "Morning Gull"]

    static let defaultTopTen: [TopTenEntry] = [
        TopTenEntry(name: "Sigrun Aasland", score: 7600),
        TopTenEntry(name: "Edmund Grayle", score: 6450),
        TopTenEntry(name: "Lucia Benvenuti", score: 5900),
        TopTenEntry(name: "Olav Brekke", score: 5150),
        TopTenEntry(name: "Hazel Winthrop", score: 4400),
        TopTenEntry(name: "Renato Ferraris", score: 3750),
        TopTenEntry(name: "Margit Lunde", score: 3150),
        TopTenEntry(name: "Clarence Abbott", score: 2600),
        TopTenEntry(name: "Ellis Tremaine", score: 1950),
        TopTenEntry(name: "Astrid Vollan", score: 1300),
    ]

    /// What a pilot balloon can find. `lb` is kilograms of petrol saved.
    static let winds: [Fish] = [
        Fish(name: "light air", lb: 15, width: 9, height: 3, speed: 26...42, weight: 35, color: "#CFE8F5"),
        Fish(name: "fair breeze", lb: 45, width: 12, height: 4, speed: 30...48, weight: 26, color: "#9FD0EE"),
        Fish(name: "steady westerly", lb: 90, width: 15, height: 5, speed: 36...56, weight: 18, color: "#F2D16B"),
        Fish(name: "strong current", lb: 225, width: 20, height: 7, speed: 24...38, weight: 13, color: "#E8EEF3"),
        Fish(name: "river of air", lb: 450, width: 28, height: 7, speed: 38...58, weight: 8, color: "#F2B632"),
    ]
}
