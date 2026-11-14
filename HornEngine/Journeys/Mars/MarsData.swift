import Foundation

// The Long Transfer's tables: what the freighter carries, where it stops, the stretches of
// the transfer arc and the space weather in them. Everything is in this namespace; nothing
// extends a shared type.
//
// Distance is stored in units of 10,000 km (48,000 to Jezero) and spoken in millions of km
// (`km`). Propellant is stored in tenths of a tonne.

enum MarsData {
    // MARK: - Numbers of its own

    /// The contract's day: a bonus for every day under it, and nothing forfeit after it.
    static let contractDays = 170
    static let bonusPerDay = 25
    /// Tenths of a tonne to match orbits with the cycler.
    static let dockBurn = 60.0
    /// Turnover: running on four more days.
    static let turnoverBurn = 80.0
    static let turnoverGain = 1200
    /// Tenths of a tonne for a full propulsive capture.
    static let captureBurn = 100.0
    /// Where the capture's rough days end: the Phobos yard.
    static let captureEnds = 47_300
    /// The launch window: how good the geometry is, by the 0-based launch month.
    static let window: [Int: Double] = [7: 0.86, 8: 0.94, 9: 1.0, 10: 0.94, 11: 0.86]
    /// Speed in the capture region before Phobos, by how you were captured.
    static let aerobrakeSpeed = 1.5
    static let propulsiveSpeed = 0.75
    /// What the hull loses a day in the upper air while aerobraking.
    static let aerobrakeWear = 4.0...10.0

    // vars keys
    static let captureKey = "mars.capture"   // 1 aerobrake, 2 full burn, 3 partial burn
    static let owedKey = "mars.owed"         // money wired by a grateful ship, paid at the next port
    static let lateKey = "mars.late"

    /// "312.45 million km", from units of 10,000 km.
    static func km(_ units: Int) -> String {
        let whole = units / 100
        let part = units % 100
        return "\(formatNumber(Double(whole))).\(part < 10 ? "0" : "")\(part) million km"
    }

    /// "12 tonnes", "0.5 tonnes", "1 tonne", from tenths.
    static func tonnes(_ tenths: Double) -> String {
        let t = tenths.rounded() / 10
        return "\(jsNumber(t)) \(t == 1 ? "tonne" : "tonnes")"
    }

    // MARK: - Stock

    static let items: [Item] = [
        Item(key: .food, name: "Rations", unit: "kg", one: "kg", step: 25, per: 1, price: 0.18, max: 450,
             desc: "Freeze-dried, tinned and vacuum-packed. Five people on full rations eat 4 kg a day."),
        Item(key: .water, name: "Water", unit: "litres", one: "litre", step: 50, per: 1, price: 0.23, max: 800,
             desc: "The recycler gives back most of what you use. The rest, 2 litres a head a day, is gone for good. Ice caught on the tether tops it up."),
        Item(key: .fuel, name: "Propellant", unit: "tonnes", one: "tonne", step: 5, per: 10, price: 0.74, max: 100,
             desc: "The drive burns a tonne a day at cruise, 0.7 at economy and 1.6 at a hard burn. The tanks hold 100 tonnes, which is not enough to reach Mars."),
        Item(key: .limes, name: "Supplement packs", unit: "packs", one: "pack", step: 1, per: 1, price: 2.3, max: 20,
             desc: "Calcium, vitamin D and a pill nobody can pronounce. A pack lasts one person 50 days. A month without and bones start to thin."),
        Item(key: .meds, name: "Medical kits", unit: "kits", one: "kit", step: 1, per: 1, price: 9, max: 8,
             desc: "Dressings, antibiotics, splints, burn gel. Opened the moment someone falls ill."),
        Item(key: .clothes, name: "Thermal suits", unit: "suits", one: "suit", step: 1, per: 1, price: 5.5, max: 10,
             desc: "One each. The cabin is heated by the same power that drives the ship; when the power fails, so does the heat."),
        Item(key: .sailcloth, name: "Array panels", unit: "panels", one: "panel", step: 1, per: 1, price: 13, max: 8,
             desc: "Spare solar panels and drive parts. One panel and a day on the truss puts power & drive a good way right."),
        Item(key: .timber, name: "Hull patches", unit: "patches", one: "patch", step: 1, per: 1, price: 11, max: 8,
             desc: "Sealant, a plate and a lot of patience. One patch and a day mends the pressure hull."),
        Item(key: .tackle, name: "Tether cartridges", unit: "cartridges", one: "cartridge", step: 1, per: 20, price: 2.75, max: 10,
             desc: "A cartridge fires the grapple 20 times. In a comet's old debris stream, ice is water for the price of a shot."),
    ]

    // MARK: - Stops

    static let stops: [Stop] = [
        Stop(id: "gateway", name: "Gateway Yard", short: "Gateway", type: .port, mile: 0),
        Stop(id: "lunar", name: "lunar distance", short: "The Moon", type: .mark, mile: 38,
             note: "Lunar distance. The Moon slides past the window close enough to show its seams and scars, and then it is behind you with everything else you know."),
        Stop(id: "hill", name: "the edge of Earth's reach", short: "Earth's reach", type: .mark, mile: 150,
             note: "1.50 million km out, the Earth lets go. From here the Sun has more say over your course than home does. Somebody marks the moment by finishing the coffee."),
        Stop(id: "cycler", name: "the cycler Perpetua", short: "Perpetua", type: .port, mile: 15_500),
        Stop(id: "turnover", name: "Turnover", short: "Turnover", type: .line, mile: 24_000),
        Stop(id: "midway", name: "Midway Depot", short: "Midway", type: .port, mile: 30_000),
        Stop(id: "shadow", name: "the conjunction shadow", short: "Shadow", type: .mark, mile: 38_000,
             note: "The Sun now stands between you and Earth and talks over every message. [amber]No forecasts until 410 million km: if a storm comes, nobody will have warned you.[/amber]"),
        Stop(id: "approach", name: "Mars approach", short: "Approach", type: .fork, mile: 46_000),
        Stop(id: "phobos", name: "Phobos Yard", short: "Phobos", type: .port, mile: 47_300),
        Stop(id: "jezero", name: "Jezero Landing", short: "Jezero", type: .end, mile: 48_000),
    ]

    // MARK: - Space weather

    static let quiet = Weather("quiet", name: "Quiet", speed: 1, wear: 0.3, sky: .clear)
    static let tracking = Weather("tracking", name: "Good tracking", speed: 1.08, wear: 0.25, sky: .still,
                                  note: "A clean fix from Earth. The navigator trims the burn and looks pleased with herself.")
    static let gusts = Weather("gusts", name: "Solar wind gusts", speed: 1, wear: 0.7, sky: .breeze,
                               note: "The wings flex and chatter in the gusts.")
    static let pebbles = Weather("pebbles", name: "Pebble stream", speed: 0.95, wear: 0.4, rough: true, sky: .dust,
                                 note: "Grit ticks on the hull like rain on a shed roof.")
    static let noise = Weather("noise", name: "Radio noise", speed: 0.9, wear: 0.3, sky: .fog,
                               note: "Nothing from Earth but hiss. The navigator flies on dead reckoning and caution.")
    static let proton = Weather("proton", name: "Proton storm", speed: 0.8, wear: 1.4, harsh: 1.5, rough: true, sky: .storm,
                                note: "The counters are chattering. Everyone who can is in the core.")
    static let ejection = Weather("ejection", name: "Mass ejection", speed: 0.6, wear: 1.8, harsh: 2, rough: true, sky: .gale,
                                  note: "A wall of the Sun's weather goes through the ship. Every alarm aboard has an opinion.")

    static let weathers = [quiet, tracking, gusts, pebbles, noise, proton, ejection]
    /// The ones the calendar scales.
    static let storms = [proton, ejection]

    /// What each weather does to the pressure hull, at most, before the pace's factor.
    static let hullHit: [String: Double] = ["pebbles": 5, "proton": 1, "ejection": 4]

    // MARK: - The arc

    private static let near: WeatherOdds = [(quiet, 50), (tracking, 20), (gusts, 10), (pebbles, 8), (noise, 6),
                                            (proton, 4), (ejection, 1)]
    private static let open: WeatherOdds = [(quiet, 52), (tracking, 16), (gusts, 12), (pebbles, 4), (noise, 8),
                                            (proton, 5), (ejection, 1.5)]
    private static let stream: WeatherOdds = [(quiet, 44), (tracking, 12), (gusts, 10), (pebbles, 18), (noise, 7),
                                              (proton, 5), (ejection, 1.5)]
    private static let far: WeatherOdds = [(quiet, 50), (tracking, 8), (gusts, 12), (pebbles, 5), (noise, 13),
                                           (proton, 6), (ejection, 2)]
    private static let farStream: WeatherOdds = [(quiet, 44), (tracking, 6), (gusts, 10), (pebbles, 18), (noise, 12),
                                                 (proton, 6), (ejection, 2)]
    private static let hidden: WeatherOdds = [(quiet, 54), (gusts, 12), (pebbles, 5), (noise, 18), (proton, 6),
                                              (ejection, 2)]
    private static let mars: WeatherOdds = [(quiet, 50), (tracking, 16), (gusts, 10), (pebbles, 8), (noise, 6),
                                            (proton, 6), (ejection, 2)]

    /// Tags: "traffic" (debris likelier), "ice" (the grapple works; pebble hits likelier),
    /// "far" (furthest from help; power wears 1.3× faster), "quiet" (the Sun is between you
    /// and Earth: no flare warnings), "dust" (Mars's neighbourhood).
    static let regions: [Region] = [
        Region(id: "cislunar", to: 150, name: "Cislunar space", temp: .cool, tags: ["traffic"], weights: near),
        Region(id: "departure", to: 8_000, name: "The departure leg", temp: .cool, weights: open),
        Region(id: "stream1", to: 11_000, name: "The first ice stream", temp: .cool, tags: ["ice"], weights: stream),
        Region(id: "inner", to: 24_000, name: "The inner arc", temp: .cool, weights: open),
        Region(id: "deep", to: 34_000, name: "Deep space", temp: .cool, tags: ["far"], weights: far),
        Region(id: "stream2", to: 37_000, name: "The second ice stream", temp: .cool, tags: ["ice", "far"],
               weights: farStream),
        Region(id: "shadow", to: 41_000, name: "The conjunction shadow", temp: .cool, tags: ["far", "quiet"],
               weights: hidden),
        Region(id: "approach", to: 46_000, name: "The approach", temp: .cool, weights: open),
        Region(id: "capture", to: 48_001, name: "Mars capture", temp: .cool, tags: ["dust"], weights: mars),
    ]

    // MARK: - Ailments

    static let radiation = Ailment("radiation sickness", damage: 4, days: 6...12)
    static let decompression = Ailment("a decompression injury", damage: 2.5, days: 4...8, death: "a decompression injury")
    static let badAir = Ailment("bad air", damage: 2, days: 3...6)
    static let fracture = Ailment("a fracture", damage: 1.2, days: 12...20, death: "complications of a fracture")
    static let lowSpirits = Ailment("low spirits", damage: 1, days: 5...10, death: "a long decline")
    static let infection = Ailment("an infection", damage: 3, days: 6...12, death: "infection")
    static let burn = Ailment("a burn", damage: 1.5, days: 10...18, death: "an infected burn")
    static let hypothermia = Ailment("hypothermia", damage: 3, days: 4...8)
    static let boneLoss = Ailment("bone loss", damage: 2, days: 999...999)

    // MARK: - People, ships, the board

    /// The 2087 launch window, all on the 7th (`Rules.startDay`): August to December.
    static let departures: [(year: Int, month: Int)] = [(2087, 7), (2087, 8), (2087, 9), (2087, 10), (2087, 11)]

    static let firstNames = ["Adaeze", "Tomasz", "Priya", "Mateo", "Ingrid", "Kenji", "Amara", "Lucía", "Farid",
                             "Siosaia", "Noor", "Dmitri", "Thandiwe", "Rafael", "Mei", "Oskar", "Leilani", "Yusuf",
                             "Bríd", "Anan"]

    static let vesselNames = ["Patient Margin", "Second Opinion", "Late Arrival", "Ample Notice", "Fair Copy",
                              "Slow Return", "Tidy Sum", "Odd Hours", "Small Mercies", "Fine Print", "Long Haul",
                              "Standing Order"]

    static let defaultTopTen: [TopTenEntry] = [
        TopTenEntry(name: "Wanjiru Abernethy", score: 8600),
        TopTenEntry(name: "Haruto Delacroix", score: 7700),
        TopTenEntry(name: "Ilse Mbeki-Sorensen", score: 6800),
        TopTenEntry(name: "Paulo Faleolo", score: 6000),
        TopTenEntry(name: "Zainab Kowalczyk", score: 5200),
        TopTenEntry(name: "Rowan Achterberg", score: 4400),
        TopTenEntry(name: "Esi Lindqvist", score: 3600),
        TopTenEntry(name: "Arjun Castellano", score: 2800),
        TopTenEntry(name: "Marisol Nakagawa", score: 2000),
        TopTenEntry(name: "Teodor Osei", score: 1200),
    ]

    /// What drifts past in an ice stream, in litres.
    static let ice: [Fish] = [
        Fish(name: "grit", lb: 4, width: 6, height: 3, speed: 26...42, weight: 35, color: "#C9D6DF"),
        Fish(name: "cobble", lb: 9, width: 9, height: 5, speed: 30...48, weight: 26, color: "#A9C1D1"),
        Fish(name: "boulder", lb: 18, width: 13, height: 8, speed: 24...40, weight: 18, color: "#8FAEC2"),
        Fish(name: "berg", lb: 35, width: 20, height: 11, speed: 20...34, weight: 12, color: "#E3EEF5"),
        Fish(name: "lost water bladder", lb: 60, width: 14, height: 9, speed: 36...56, weight: 4, color: "#E8A33D"),
    ]
}
