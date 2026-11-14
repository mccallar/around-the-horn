import Foundation

// The Jet Stream's tables: what the capsule carries, where the fields are, the air it flies
// through and the weather there. Everything is in this namespace; nothing extends a shared
// type.

enum BalloonData {
    // MARK: - Numbers of its own

    /// Gallons the climb from a field to cruising height burns, the first launch included.
    static let launchBurn = 25.0
    /// Gallons a watch spent loitering low, before the temperature.
    static let loiterBurn = 10.0
    /// Nautical miles a watch on the helium alone, with the tanks dry.
    static let driftSpeed = 40.0
    /// Lift lost every watch the tanks are dry, flying or loitering.
    static let emptyLift = 5.0
    /// Helium seeping through the cell, every watch flown.
    static let seep = 0.08
    static let strikeChance = 0.035
    static let strikeChanceForecast = 0.008
    static let roofChance = 0.02
    static let forecastFee = 250.0
    static let himalayaBurn = 35.0
    static let himalayaGain = 200
    static let iceBurn = 40.0
    static let partyBurn = 15.0

    /// Where the two Pacific tracks part and meet again.
    static let forkFrom = 7800
    static let forkTo = 12600

    // Keys in `GameState.vars`.
    static let southKey = "balloon.south"
    static let forecastKey = "balloon.forecasters"
    /// Propane aboard at the start of the watch being flown.
    static let startFuelKey = "balloon.startFuel"
    /// 1 after an ordinary relaunch, 2 after the ground team paid for it; said on the first watch.
    static let relaunchKey = "balloon.relaunch"
    static let toppedUpKey = "balloon.toppedUp"

    /// Gas burned a watch, as a share of the altitude's, by how cold the air is.
    static func burnFactor(_ t: Temp) -> Double {
        switch t {
        case .hot: return 0.85
        case .warm: return 0.95
        case .cool: return 1
        case .cold: return 1.1
        case .freezing: return 1.2
        }
    }

    /// "January 5, 1999", without the hour.
    static func dateOnly(_ s: GameState) -> String {
        let d = s.date
        return "\(monthNames[d.month]) \(d.day), \(d.year)"
    }

    /// "0.7 gallons", "14.5 gallons", "1 gallon": propane to a tenth, never shown as none.
    static func gallons(_ g: Double) -> String {
        let tenths = max(1, jsRound(g * 10))
        let n = tenths.truncatingRemainder(dividingBy: 10) == 0 ? String(Int(tenths / 10)) : String(format: "%.1f", tenths / 10)
        return "\(n) \(tenths == 10 ? "gallon" : "gallons")"
    }

    /// "1600", the watch's GMT time.
    static func clock(_ s: GameState) -> String {
        String(format: "%02d00", s.hour)
    }

    // MARK: - Stock

    static let items: [Item] = [
        Item(key: .food, name: "Rations", unit: "lbs", one: "lb", step: 10, per: 1, price: 3, max: 500,
             desc: "Freeze-dried meals, cocoa and chocolate. Each of you eats 3–8 oz a watch."),
        Item(key: .water, name: "Drinking water", unit: "gal", one: "gal", step: 10, per: 1, price: 0.5, max: 250,
             desc: "About a fifth of a gallon each per watch — more in the heat."),
        Item(key: .limes, name: "CO2 scrubbers", unit: "canisters", one: "canister", step: 1, per: 1, price: 25, max: 30,
             desc: "Lithium canisters that keep the capsule air sweet. One lasts five of you ten watches."),
        Item(key: .meds, name: "Medical kits", unit: "kits", one: "kit", step: 1, per: 1, price: 100, max: 12,
             desc: "Drugs, splints and oxygen masks. One kit per illness halves its harm."),
        Item(key: .clothes, name: "Down suits", unit: "suits", one: "suit", step: 1, per: 1, price: 80, max: 10,
             desc: "One per person. The capsule heater can't hold off the cold of the jet."),
        Item(key: .timber, name: "Ballast", unit: "sacks", one: "sack", step: 1, per: 1, price: 60, max: 20,
             desc: "Sealed sacks of dry sand. Drop one to win back lift you've lost."),
        Item(key: .sailcloth, name: "Burner spares", unit: "kits", one: "kit", step: 1, per: 1, price: 140, max: 20,
             desc: "Jets, valves and igniters for servicing the burners aloft."),
        Item(key: .tackle, name: "Fishing line", unit: "spools", one: "spool", step: 1, per: 20, price: 30, max: 30,
             desc: "Line and lures for trailing from the hatch. Each spool is 20 casts."),
        Item(key: .fuel, name: "Propane", unit: "gal", one: "gal", step: 50, per: 1, price: 0.45, max: 1200,
             desc: "Burns 12–16 gallons a watch, more in the cold. Run out and you sink."),
    ]

    /// What a trader thinks one stored unit is worth. Water is not traded (`tradeKeys`).
    static let values: [ItemKey: Double] = [
        .food: 4.2, .limes: 25, .meds: 100, .clothes: 80, .timber: 60, .sailcloth: 140, .tackle: 1.5,
        .fuel: 0.55,
    ]

    // MARK: - Stops

    static let stops: [Stop] = [
        Stop(id: "mar", name: "Marrakech", short: "Marrakech", type: .port, mile: 0),
        Stop(id: "atlas", name: "the High Atlas", short: "High Atlas", type: .mark, mile: 100,
             note: "You are crossing the High Atlas. Snowfields slide by below, close enough to see the tracks of mule trains, then fall away to the stony desert. Mission Control comes on the radio: you're on your way."),
        Stop(id: "lux", name: "Luxor", short: "Luxor", type: .port, mile: 2200),
        Stop(id: "jod", name: "Jodhpur", short: "Jodhpur", type: .port, mile: 4400),
        Stop(id: "him", name: "the Himalaya", short: "Himalaya", type: .line, mile: 5050),
        Stop(id: "saga", name: "Saga, on the island of Kyushu", short: "Saga", type: .port, mile: 7650),
        Stop(id: "pacific", name: "the edge of the Pacific", short: "Off Japan", type: .fork, mile: 7800),
        Stop(id: "dateline", name: "the date line", short: "Date line", type: .line, mile: 10050),
        Stop(id: "landfall", name: "the American coast", short: "Landfall", type: .mark, mile: 12600),
        Stop(id: "abq", name: "Albuquerque", short: "Albuquerque", type: .port, mile: 13500),
        Stop(id: "kh", name: "Kitty Hawk", short: "Kitty Hawk", type: .port, mile: 15000),
        Stop(id: "azores", name: "the Azores", short: "Azores", type: .island, mile: 17350),
        Stop(id: "finish", name: "the finish line", short: "Finish line", type: .end, mile: 18300),
    ]

    static let landfallNorth = "Landfall! The coast of California slides in under you north of San Francisco — a white line of surf, then the dark of the redwoods. The Pacific is behind you. Everyone talks at once."
    static let landfallSouth = "Landfall! San Diego slides in under you, and then the brown hills and the desert. The Pacific is behind you. Everyone talks at once."

    /// On the ground a field is its own place, whatever leg starts there.
    static let fieldTemp: [String: Temp] = ["mar": .warm, "lux": .warm, "jod": .warm, "saga": .cool, "abq": .cool,
                                            "kh": .cool]

    // MARK: - Weather

    static let steady = Weather("steady", name: "Steady wind", speed: 1, wear: 0.2, sky: .clear)
    static let jet = Weather("jet", name: "Jet streak", speed: 1.45, wear: 0.35, sky: .breeze)
    static let light = Weather("light", name: "Light wind", speed: 0.55, wear: 0.1, sky: .clear)
    static let stalled = Weather("stalled", name: "Stalled", speed: 0.1, wear: 0.03, sky: .still,
                                 note: "Not a breath of wind. The balloon hangs over the same patch of earth.")
    static let sun = Weather("sun", name: "Hot sun", speed: 0.7, wear: 0.05, sky: .heat)
    static let cloud = Weather("cloud", name: "In cloud", speed: 0.85, wear: 0.15, sky: .fog)
    /// `wet`: the shared catch melts rime off the hatch (`Rules.rainCatch`).
    static let snow = Weather("snow", name: "Snow & rime", speed: 0.8, wear: 0.6, wet: true, sky: .snow)
    static let shear = Weather("shear", name: "Rough air", speed: 1.15, wear: 1.2, harsh: 0.6, rough: true, sky: .gale)
    static let storm = Weather("storm", name: "THUNDERSTORM", speed: 0.4, wear: 2.5, harsh: 1.5, rough: true, sky: .storm)
    static let dust = Weather("dust", name: "Dust haze", speed: 0.85, wear: 0.3, sky: .dust)

    static let weathers = [steady, jet, light, stalled, sun, cloud, snow, shear, storm, dust]

    // MARK: - The air

    private static let arabia: WeatherOdds = [(steady, 30), (sun, 22), (light, 16), (dust, 14), (jet, 10), (stalled, 6),
                                              (shear, 2)]

    /// Tags: "sea" (over water: fishing, the freighter, coming down in the sea), "jet" (the
    /// season moves the jet), "high" (cold turns freezing in midwinter), "ice" (rime costs
    /// lift, storms cost half again, the roof roll), "storms" (the thunderstorm roll),
    /// "atlantic" (the North Atlantic winter).
    static let regions: [Region] = [
        Region(id: "sahara", to: 2200, name: "The Sahara", temp: .warm,
               weights: [(steady, 32), (jet, 18), (light, 14), (sun, 14), (dust, 12), (shear, 6), (stalled, 4)]),
        Region(id: "arabia", to: 3500, name: "Arabia", temp: .hot, weights: arabia),
        Region(id: "oman", to: 3800, name: "The Gulf of Oman", temp: .warm, tags: ["sea"],
               weights: [(steady, 34), (light, 18), (jet, 14), (cloud, 12), (sun, 10), (stalled, 8), (storm, 4)]),
        Region(id: "thar", to: 4400, name: "The Indus & the Thar", temp: .warm, weights: arabia),
        Region(id: "india", to: 5050, name: "Northern India", temp: .cool, tags: ["jet"],
               weights: [(steady, 34), (jet, 24), (light, 14), (cloud, 12), (shear, 8), (stalled, 6), (dust, 2)]),
        Region(id: "himalaya", to: 7350, name: "The Himalaya & China", temp: .cold, tags: ["jet", "high"],
               weights: [(jet, 30), (steady, 20), (shear, 18), (snow, 12), (cloud, 10), (storm, 5), (light, 5)]),
        Region(id: "eastchina", to: 7800, name: "The East China Sea", temp: .cool, tags: ["sea", "jet"],
               weights: [(jet, 26), (steady, 24), (cloud, 16), (shear, 12), (snow, 8), (light, 8), (storm, 6)]),
        Region(id: "npacific", to: 10050, name: "The North Pacific", temp: .cold, tags: ["sea", "jet", "high", "ice"],
               weights: [(jet, 32), (shear, 22), (snow, 14), (storm, 14), (steady, 10), (cloud, 8)]),
        Region(id: "nepacific", to: 12600, name: "The Northeast Pacific", temp: .cold, tags: ["sea", "jet"],
               weights: [(jet, 26), (steady, 20), (shear, 16), (cloud, 16), (snow, 12), (storm, 6), (light, 4)]),
        Region(id: "southwest", to: 13500, name: "The American Southwest", temp: .cool, tags: ["jet"],
               weights: [(steady, 30), (jet, 22), (light, 14), (shear, 12), (dust, 10), (cloud, 8), (stalled, 4)]),
        Region(id: "plains", to: 15000, name: "The Great Plains", temp: .cold, tags: ["jet"],
               weights: [(jet, 26), (steady, 24), (shear, 16), (cloud, 12), (snow, 10), (storm, 6), (light, 6)]),
        Region(id: "atlantic", to: 17350, name: "The North Atlantic", temp: .cool, tags: ["sea", "atlantic"],
               weights: [(steady, 26), (jet, 22), (cloud, 16), (shear, 16), (storm, 8), (snow, 6), (light, 6)]),
        Region(id: "azores", to: 18225, name: "Past the Azores", temp: .warm, tags: ["sea"],
               weights: [(steady, 34), (light, 18), (jet, 14), (cloud, 14), (sun, 8), (stalled, 8), (shear, 4)]),
        // The coast of Morocco between Safi and Essaouira; the finish line is inland.
        Region(id: "morocco", to: 18301, name: "Morocco & home", temp: .warm,
               weights: [(steady, 34), (light, 18), (jet, 14), (sun, 12), (dust, 8), (stalled, 8), (shear, 6)]),
    ]

    /// The southern Pacific track, in place of the North Pacific and the Northeast Pacific.
    static let southTrack = Region(id: "southtrack", to: 10050, name: "The southern track", temp: .warm,
                                   tags: ["sea", "jet", "storms"],
                                   weights: [(steady, 32), (jet, 20), (light, 14), (cloud, 12), (storm, 10), (sun, 6),
                                             (stalled, 6)])
    static let subtropic = Region(id: "subtropic", to: 12600, name: "The subtropical Pacific", temp: .hot,
                                  tags: ["sea", "jet", "storms"],
                                  weights: [(steady, 32), (jet, 18), (light, 16), (sun, 10), (cloud, 10), (storm, 8),
                                            (stalled, 6)])

    // MARK: - Ailments

    static let staleAir = Ailment("stale-air sickness", damage: 2.2, days: 1...1, death: "carbon dioxide poisoning")
    static let altitude = Ailment("altitude sickness", damage: 3, days: 4...8)
    static let hypothermia = Ailment("hypothermia", damage: 4.5, days: 5...9)
    static let frostbite = Ailment("frostbite", damage: 2.5, days: 6...12)
    static let influenza = Ailment("influenza", damage: 4.5, days: 6...11)
    static let foodPoisoning = Ailment("food poisoning", damage: 4.5, days: 4...8)
    static let fever = Ailment("a fever", damage: 3, days: 4...7)
    static let brokenArm = Ailment("a broken arm", damage: 1.2, days: 14...24, death: "an infected wound")
    static let exhaustion = Ailment("exhaustion", damage: 1.5, days: 3...5)

    /// At Saga and Kitty Hawk, in the flu season.
    static let fluFieldPool = [influenza, fever, foodPoisoning]
    /// On the ground anywhere else, whatever the next leg's air is like.
    static let groundPool = [influenza, foodPoisoning, fever, brokenArm, exhaustion]
    static let hotPool = [fever, foodPoisoning, exhaustion, influenza, altitude]
    static let coldPool = [hypothermia, frostbite, altitude, influenza, brokenArm]
    static let mildPool = [influenza, foodPoisoning, fever, brokenArm, exhaustion]

    // MARK: - People, balloons, the board

    static let departures: [(year: Int, month: Int)] = [(1998, 10), (1998, 11), (1999, 0), (1999, 1), (1999, 2)]

    static let firstNames = ["Anna", "Bruno", "Claire", "Dieter", "Elena", "Felix", "Greta", "Hugo", "Ingrid", "Jonas",
                             "Katrin", "Luca", "Marta", "Nils", "Olga", "Pascal", "Rosa", "Stefan", "Tessa", "Ulrich",
                             "Vera", "Willem", "Yuki", "Zoe", "Amir", "Bea", "Conor", "Dana", "Erik", "Fiona", "Gus",
                             "Hana"]

    static let vesselNames = ["Westering", "Trade Wind", "Long Shot", "Cirrus Queen", "High Hopes", "Zephyr",
                              "Far Horizon", "Silver Thread", "Second Wind", "Equinox", "Morning Glory", "Skylark",
                              "Wanderlust", "Daydreamer"]

    static let defaultTopTen: [TopTenEntry] = [
        TopTenEntry(name: "Margit Velde", score: 7700),
        TopTenEntry(name: "Anselm Kroll", score: 6450),
        TopTenEntry(name: "Dolores Quiñones", score: 5900),
        TopTenEntry(name: "Tobias Hartnell", score: 5150),
        TopTenEntry(name: "Yuki Morisaki", score: 4400),
        TopTenEntry(name: "Colm Ferriter", score: 3800),
        TopTenEntry(name: "Elodie Marchetti", score: 3200),
        TopTenEntry(name: "Rafael Ostrowski", score: 2650),
        TopTenEntry(name: "Bettina Lund", score: 2000),
        TopTenEntry(name: "Hank Pruett", score: 1300),
    ]

    /// What bites on a lure trailed from the hatch. `lb` is pounds of rations.
    static let fish: [Fish] = [
        Fish(name: "flying fish", lb: 1, width: 9, height: 3, speed: 26...42, weight: 35, color: "#9FC9E8"),
        Fish(name: "mackerel", lb: 2, width: 12, height: 4, speed: 30...48, weight: 26, color: "#7FD6C9"),
        Fish(name: "mahi-mahi", lb: 5, width: 15, height: 5, speed: 36...56, weight: 18, color: "#E8C547"),
        Fish(name: "skipjack", lb: 12, width: 20, height: 7, speed: 24...38, weight: 13, color: "#46689A"),
        Fish(name: "yellowfin", lb: 24, width: 28, height: 7, speed: 38...58, weight: 8, color: "#5B7BB0"),
    ]
}
