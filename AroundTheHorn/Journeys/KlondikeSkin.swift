import SwiftUI
import HornEngine

/// To the Klondike, 1898: everything the shell says and draws for it. A turn is a day and
/// distances are stored in tenths of a mile, written "1,136.5". The engine calls its two
/// meters `hull` and `sails`: the outfit and its sleds until a boat is built at Lake
/// Bennett, then the boat and its oars & sail. `water` is firewood, `sailcloth` rope &
/// rawhide, `timber` canvas & pitch, `limes` lime juice and `tackle` hooks, counted in
/// casts. The art is in the files beside this one.
enum KlondikeSkin {
    static let journey = Journeys.journey(Klondike.id)

    static let skin = JourneySkin(
        id: Klondike.id, card: card, words: words,
        scene: SceneSkin(draw: KlondikeScene.draw, label: KlondikeScene.label),
        chart: KlondikeChart.skin, forage: KlondikeForage.skin, debug: debug)

    // MARK: What the engine keeps in `vars`

    /// The engine's own keys (held to `KlondikeData` by `KlondikeSkinTests`).
    static let routeKey = "klondike.route", boatKey = "klondike.boat", breakupKey = "klondike.breakup"
    static let chilkoot = 1.0, whitePass = 2.0
    /// What `boatKey` holds for a raft: the fourth way of getting a boat.
    static let raft = 4.0

    static func onWhitePass(_ g: GameState) -> Bool { g.vars[routeKey] == whitePass }
    static func pass(_ g: GameState) -> Double? { g.vars[routeKey] }

    /// "steamer", "foot" or "boat", as the engine has it.
    static func leg(_ g: GameState) -> String { Klondike.legName(g) }

    /// Day of 1898, January 1 being 0, as the engine counts it for the ice and the crowd.
    static func dayOfYear(_ g: GameState) -> Int {
        let d = g.date
        let before = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334]
        return (d.year - 1898) * 365 + before[d.month] + d.day - 1
    }

    /// May 28, when the ice goes out if nobody has yet seen Bennett to roll for it.
    static let usualBreakup = 147

    /// Whether the ice on Lake Bennett has gone out.
    static func iceOut(_ g: GameState) -> Bool { dayOfYear(g) >= Int(g.vars[breakupKey] ?? Double(usualBreakup)) }

    static func days(_ n: Int) -> String { "\(n) \(n == 1 ? "day" : "days")" }

    // MARK: Title card

    static let card = TitleCard(
        banner: "TO THE KLONDIKE · 1898",
        title: "TO THE\nKLONDIKE",
        year: "~ 1898 ~",
        tagline: "Seventeen hundred miles from Seattle to the gold fields of the Yukon — by steamer, on foot, and by boat.",
        start: "Head for the Klondike",
        resume: { "Continue the journey of the [i]\($0)[/i]" },
        learn: "Learn about the trail",
        learnPages: [
            TitleCard.Page(heading: "The rush", paragraphs: [
                "In July 1897 a steamer tied up in Seattle with a ton of gold aboard, and by winter the whole country had the fever. The gold was on the Klondike River in Canada's Yukon, seventeen hundred miles north — up the coast by steamer, over the mountains on foot, and down the Yukon River by boat.",
                "You lead a party of five. Buy a year's outfit, get it over the pass, build a boat, and bring everyone to Dawson City alive.",
                "Time passes a day at a time. The steamer is quick; the thirty-three miles of trail are not, because everything you own goes up them a load at a time.",
            ]),
            TitleCard.Page(heading: "The outfit", paragraphs: [
                "[amber]Provisions[/amber]: the police at the summit turn back anyone without a year's grub — 1,095 lbs a head. Bring more than that; you'll eat on the way up.",
                "[amber]Firewood[/amber] keeps you alive on top of the pass, where nothing grows. Below the trees you can gather your own. A day without a fire costs every one of you 12 health.",
                "[amber]Lime juice[/amber] holds off scurvy. [amber]Furs[/amber] — one set each — hold off the cold.",
                "[amber]Canvas & pitch[/amber] and [amber]rope & rawhide[/amber] patch your outfit on the trail and your boat on the river, and you'll need some to build the boat. [amber]Hooks & line[/amber] catch fish on the lakes and river.",
                "Sleds worn down to 0% give out, and nobody moves until they are mended: with a coil of rope & rawhide, with a coil bought off the next party along for $24, or with two days' work making do. An outfit that ever shows 0% is ruined, and the trek is over.",
            ]),
            TitleCard.Page(heading: "Pass, lakes, river", paragraphs: [
                "At the head of Lynn Canal choose your pass: the steep [amber]Chilkoot[/amber] or the gentler, slower [amber]White Pass[/amber]. Either way, you carry everything up a load at a time.",
                "At [amber]Lake Bennett[/amber] you build a boat and wait for the ice to go out, at the end of May. Then it's nearly five hundred and fifty miles of lakes, canyon and rapids to Dawson.",
                "Oars & sail at 0% leave the boat tied to the bank until they are re-rigged, and nobody takes a boat into Miles Canyon or through Five Fingers without a sweep. A boat that shows 0% breaks up.",
                "Leave too early and the pass will freeze you; too late and the snow turns to slush and slides, and the crowd beats you to Dawson. Every day you get there before August 1 is worth 20 points. Hard driving gets you there sooner, if it gets you there at all.",
            ]),
        ],
        roleHeading: "Who are you?",
        roleIntro: "In 1898 the fever took clerks and cooks, preachers and prospectors. Choose who you will be:",
        differencesAction: "What does each one bring north?",
        differencesHeading: "What each one brings north",
        differences: [
            "A Klondike outfit cost more than most people earned in a year.",
            "[amber]Storekeeper[/amber] — starts with $1,700.",
            "[amber]Boatbuilder[/amber] — starts with $1,000. Gets far more out of every bundle of canvas and coil of rope, and builds a better boat in less time.",
            "[amber]Miner[/amber] — starts with $720. A strong back: moves an outfit over the pass faster than anyone.",
            "The poorer you start, the more your arrival is worth: the boatbuilder scores double, the miner triple.",
        ],
        namesHeading: "Boat & party",
        vesselPrompt: "Name the boat you'll build at the lakes:",
        vesselLabel: "Boat's name",
        leaderPrompt: "Your name:",
        leaderLabel: "Your name",
        crewPrompt: "Your four partners:",
        crewLabel: "Partner",
        monthHeading: "When will you go?",
        monthIntro: "The news reached Seattle last July. All winter the steamers have gone north crammed to the rails. When will you go?",
        monthAdvice: "An old sourdough taps his pipe on the stove: “Go in January and the pass will freeze you solid. Go in May and you'll wade through slush under the snowslides, and every creek in the Klondike will be staked twice over before you get there. March is the month. February, if your purse can stand a cold trail. Be at the lakes when the ice goes out.”",
        outfitHeading: "Outfitting",
        outfitIntro: { "You have [amber]$\(formatNumber($0.money))[/amber] to outfit your party. The outfitters on First Avenue will sell you anything, and they all tell you the same things:" },
        outfitBullets: [
            "• [b]Provisions[/b] — the police won't let anyone over the summit without a year's grub: 1,095 lbs a head. Then you have to eat on the way.",
            "• [b]Firewood[/b] — nothing grows on top of the pass, and in the cold up there five of you burn 40 lbs of it a day.",
            "• [b]Lime juice[/b] — beans and bacon all winter bring on scurvy.",
            "• [b]Furs & mackinaws[/b] — one set a head, or the summit will take fingers and toes.",
            "• [b]Canvas & pitch, rope & rawhide[/b] — to patch the outfit on the trail, and to build a boat at the lakes.",
            "• [b]A medicine chest and hooks & line[/b].",
        ],
        enterShop: "Enter the shop",
        rankLegend: "Sourdough 7,000+ · Old Hand 4,000+ · Stampeder 2,000+ · Cheechako")

    // MARK: Words

    /// The party's plight, for the status box (docs/journeys/klondike.md, D14): sleds or
    /// oars given out, no firewood, or both. Nothing before it leaves Seattle; the outfit and
    /// the boat need no row, since at 0% the trek is over.
    static func trouble(_ g: GameState) -> String? {
        guard g.day > 0 else { return nil }
        let out = Klondike.givenOut(g), cold = Klondike.noFire(g), boat = Klondike.hasBoat(g)
        switch (out, cold) {
        case (true, true): return boat ? "Oars given out, no firewood" : "Sleds given out, no firewood"
        case (true, false): return boat ? "Oars & sail given out" : "Sleds given out"
        case (false, true): return "No firewood"
        case (false, false): return nil
        }
    }

    /// The burial line by where it happens, in the engine's words, with the name as the
    /// shell hands it over (already escaped).
    static func burial(_ g: GameState, _ name: String) -> String {
        let mark = "\u{1}NAME\u{1}"
        return Klondike.burialText(g, name: mark).replacingOccurrences(of: mark, with: name)
    }

    static func words(_ g: GameState) -> Words {
        let pace = journey.pace(g.pace), rations = journey.rations(g.rations)
        let n = g.living.count
        let leg = leg(g)
        let boat = Klondike.hasBoat(g)
        let gone = g.day > 0
        let givenOut = gone && Klondike.givenOut(g), cold = gone && Klondike.noFire(g)
        let title = journey.role(g.role).title
        let town = g.atPort ? journey.port(g, at: g.currentStop.id) : nil
        let bennett = g.currentStop.id == "bennett" && g.atPort
        let meters = Klondike.meterNames(g)
        let home = journey.stops.first?.name ?? ""
        let finale = Klondike.finale(g)
        return Words(
            setOut: "Steam north",
            halt: "Stop & take stock",
            carryOn: "Continue on your journey",
            supplies: "Check supplies & party",
            chart: "Look at the map",
            changePace: "Change pace",
            changeRations: "Change rations",
            rest: leg == "steamer" ? "Rest in your bunk" : "Make camp and rest",
            repairs: "Make repairs",
            forage: "Go fishing",
            leavePort: leg == "boat" || g.currentStop.id == "bennett" ? "Push off and float on"
                : leg == "steamer" ? "Back aboard and steam on" : "Shoulder your packs and move on",
            restInPort: "Rest in town",
            trade: "Look for a trade",
            talk: "Talk to people",
            buy: "Buy supplies",
            yard: boat ? "Visit the boatwrights" : bennett ? "See about a boat" : "Visit the outfitters' yard",
            yardQuestion: bennett && !boat ? { Klondike.boatChoice($0) } : nil,
            place: town?.name,
            stopName: { Klondike.shortName($0, g) },
            statusNames: [:],
            travelled: "Traveled",
            distanceUnit: "mi",
            distance: { Klondike.mileNumber($0) },
            meters: (meters.structure, meters.drive),
            clock: nil,
            trouble: trouble(g).map { ("Party", $0) },
            cash: "Cash",
            currency: "$",
            storeNames: [.meds: "Medicine", .clothes: "Furs"],
            looseUnits: [.tackle: "casts"],
            looseOne: [.tackle: "cast"],
            fractional: [.limes],
            singular: true,
            lots: [.water],
            departRefusal: nil,
            // Less grub than the police will want: a warning, which may be waved off. With
            // none at all the engine's own refusal comes first.
            departWarning: g.food > 0 && Klondike.shortOfGrubWarning(g) != nil
                ? (Klondike.shortOfGrubWarning(g)!, "Back to the shop", "Leave anyway") : nil,
            resumesInFirstShop: true,
            leaveRefusal: nil,
            vesselHeading: boat ? "The \(g.ship)" : "Your outfit",
            suppliesNote: "Pace: \(pace.name) · Rations: \(rations.name)"
                + (g.noCitrus > 20 ? " · [red]\(g.noCitrus) days without lime juice[/red]" : "")
                + (givenOut ? (boat ? " · [red]the oars & sail have given out[/red]" : " · [red]the sleds have given out[/red]") : "")
                + (cold ? " · [red]no firewood[/red]" : ""),
            crewHeading: "Party · health \(g.healthLabel.text)",
            leaderTag: "you",
            clothesWarning: g.clothes < n ? "[red]Only \(g.clothes) of \(n) have furs.[/red]" : nil,
            lostHeading: "Lost on the trail",
            paceHeading: "Pace",
            paceNow: "The pace is [amber]\(pace.name)[/amber]."
                + (leg == "steamer" ? " [dim]Aboard the steamer, the captain sets the pace. It will matter on the trail.[/dim]" : "")
                + (givenOut ? (boat ? " [red]The oars & sail have given out: she stays tied to the bank until they are re-rigged.[/red]"
                                    : " [red]The sleds have given out: nobody moves until they are mended.[/red]") : ""),
            rationsHeading: "Rations",
            rationsNow: "Rations are currently [amber]\(rations.name)[/amber]. With \(n) in the party, that's \(formatNumber(Double(n) * rations.amount)) lbs a day.",
            restPrompt: g.atPort ? "Your party can sleep under a roof, eat a cooked meal and recover. How many days?"
                : leg == "steamer" ? "You keep to your bunk. How many days?"
                : "You make camp and the party rests. How many days?",
            restChoice: { days($0) },
            repairsHeading: "Repairs",
            repairsNote: "Each repair takes a day." + (g.role == .shipwright ? " As a boatbuilder, your repairs go much further." : ""),
            mend: boat ? "Re-rig oars & sail — 1 coil of rope & rawhide [dim](have \(g.sailcloth))[/dim]"
                : "Mend sleds & straps — 1 coil of rope & rawhide [dim](have \(g.sailcloth))[/dim]",
            patch: boat ? "Patch the hull — 1 bundle of canvas & pitch [dim](have \(g.timber))[/dim]"
                : "Patch the outfit — 1 bundle of canvas & pitch [dim](have \(g.timber))[/dim]",
            yardHeading: boat ? "The boatwrights" : "The outfitters' yard",
            yardIntro: "You have [amber]$\(formatNumber(g.money))[/amber]. Each job takes a day.",
            yardHull: { boat ? "Have her hauled out and recaulked — $\(formatNumber(Double($0)))"
                             : "Have the outfit re-sacked and re-tarped — $\(formatNumber(Double($0)))" },
            yardSails: { boat ? "Have new oars and a sail made — $\(formatNumber(Double($0)))"
                              : "Have the sleds and harness made good — $\(formatNumber(Double($0)))" },
            leaveYard: boat ? "Leave the boatwrights" : "Leave the yard",
            priceNote: { p in
                p >= 0 ? "Prices here are \(p)% above \(home), more or less." : "Prices here are \(-p)% below \(home), more or less."
            },
            burial: { burial(g, $0) },
            commit: "Lay them to rest",
            gameOverLine: "\(g.dateText) · \(Klondike.miles(g.mile)) from \(home).",
            arrival: finale.title,
            arrivalBody: finale.body,
            bonus: "Bonus for being a \(title)",
            again: "Head north again",
            thanks: "Thanks for coming north.")
    }

    // MARK: Debug starts and the gallery

    /// Days from leaving Seattle to just short of each stop on the coast and the trail, as a
    /// March party might take them.
    static let trailDays = [0, 5, 6, 7, 16, 22, 30, 38]
    /// The day of 1898 a party might be just short of each stop on the river, the ice gone.
    static let riverDates = [8: 153, 9: 156, 10: 164, 11: 166, 12: 171]

    static let debug = DebugSkin(
        start: { stop, month in
            // March unless the month asked for is one a party can leave in.
            let m = journey.departures.contains { $0.month == month } ? month : 2
            var s = fresh(month: m)
            let here = journey.stops[stop], before = journey.stops[stop - 1]
            s.stopIndex = stop - 1
            s.mile = here.mile - min(100, (here.mile - before.mile) / 2)
            settle(&s, toward: stop)
            s.atPort = false
            return s
        },
        gallery: [
            ("Seattle, the waterfront", false, { at(&$0, "seattle", port: true) }),
            ("Leaving Seattle", true, { go(&$0, 150) }),
            ("Queen Charlotte Sound", true, { go(&$0, 3300) }),
            ("The British Columbia coast", true, { go(&$0, 5200) }),
            ("Juneau", false, { at(&$0, "juneau", port: true) }),
            ("The Alaska coast", true, { go(&$0, 10600) }),
            ("The head of Lynn Canal", false, { at(&$0, "lynn") }),
            ("Dyea", false, { at(&$0, "landing", port: true) }),
            ("Skagway", false, { at(&$0, "landing", port: true, white: true) }),
            ("The Taiya valley", true, { go(&$0, 11265) }),
            ("The Skagway valley", true, { go(&$0, 11265, white: true) }),
            ("Sheep Camp", false, { at(&$0, "camp", port: true) }),
            ("White Pass City", false, { at(&$0, "camp", port: true, white: true) }),
            ("The Golden Stairs", true, { go(&$0, 11356) }),
            ("The Chilkoot summit", false, { at(&$0, "summit") }),
            ("The White Pass summit", false, { at(&$0, "summit", white: true) }),
            ("Lake Lindeman, frozen", false, { at(&$0, "lakes") }),
            ("Log Cabin", false, { at(&$0, "lakes", white: true) }),
            ("Lake Bennett, the ice in", false, { at(&$0, "bennett", port: true) }),
            ("Lake Bennett, a boat built", false, { s in
                at(&s, "bennett", port: true)
                s.vars[boatKey] = 1
                s.hull = 100
                s.sails = 100
            }),
            ("The upper lakes", true, { go(&$0, 12250) }),
            ("Tagish Post", false, { at(&$0, "tagish") }),
            ("Miles Canyon", false, { at(&$0, "canyon") }),
            ("The Fifty Mile River", true, { go(&$0, 12600) }),
            ("Lake Laberge", true, { go(&$0, 12900) }),
            ("Five Finger Rapids", false, { at(&$0, "fivefinger") }),
            ("Fort Selkirk", false, { at(&$0, "selkirk", port: true) }),
            ("The Yukon in July", true, { s in
                go(&s, 16000)
                s.day += 25
            }),
            ("Dawson City", false, { at(&$0, "dawson") }),
            ("A raft", true, { s in
                go(&s, 13600)
                s.vars[boatKey] = raft
            }),
            ("Camped on the trail", false, { go(&$0, 11280) }),
            ("Sleds 15%", true, { s in
                go(&s, 11280)
                s.sails = 15
            }),
            ("Sleds given out", false, { s in
                go(&s, 11280)
                s.sails = 0
            }),
            ("Outfit 20%", true, { s in
                go(&s, 11280)
                s.hull = 20
            }),
            ("No firewood", false, { s in
                go(&s, 11400)
                s.water = 0
            }),
            ("Boat 20%, bailing", true, { s in
                go(&s, 14000)
                s.hull = 20
            }),
            ("Sail 15%", true, { s in
                go(&s, 14000)
                s.sails = 15
            }),
            ("Oars given out, tied up", false, { s in
                go(&s, 14000)
                s.sails = 0
            }),
            ("The outfit ruined", false, { s in
                go(&s, 11300)
                s.hull = 0
                s.over = true
            }),
            ("Turned back at the summit", false, { s in
                at(&s, "summit")
                s.over = true
            }),
            ("The boat broken up", false, { s in
                go(&s, 14000)
                s.hull = 0
                s.over = true
            }),
        ])

    static func fresh(month: Int) -> GameState {
        var s = GameState(journey: Klondike.id, role: .merchant, ship: "Puget Belle", captain: "Gus",
                          crew: ["Martha", "Lars", "Ida", "Homer"], startYear: 1898, startMonth: month)
        s.food = 6000
        s.water = 600
        s.limes = 8
        s.meds = 3
        s.clothes = 5
        s.sailcloth = 3
        s.timber = 4
        s.tackle = 60
        s.hull = 72
        s.sails = 64
        s.money = 400
        return s
    }

    /// The pass chosen past the fork, a boat past Bennett, and a day that fits: on the coast
    /// and the trail as long as a March party takes, on the river after the ice has gone.
    static func settle(_ s: inout GameState, toward stop: Int, white: Bool = false) {
        if s.mile > journey.stops[2].mile { s.vars[routeKey] = white ? whitePass : chilkoot }
        let bennett = journey.stops[7].mile
        if s.mile > bennett {
            s.vars[boatKey] = 1
            s.vars[breakupKey] = Double(usualBreakup)
            s.food = min(s.food, 4000)
        }
        if let date = riverDates[stop] {
            var start = s
            start.day = 0
            s.day = max(1, date - dayOfYear(start))
        } else {
            s.day = trailDays[min(stop, trailDays.count - 1)]
        }
        if s.mile > journey.stops[5].mile { s.food = min(s.food, 4000) }
    }

    /// Standing at a stop, its arrival told; in town if `port`. On the trail in March, on
    /// the river in June.
    static func at(_ s: inout GameState, _ id: String, port: Bool = false, white: Bool = false) {
        guard let i = journey.stops.firstIndex(where: { $0.id == id }) else { return }
        s = fresh(month: 2)
        s.stopIndex = i
        s.mile = journey.stops[i].mile
        settle(&s, toward: i, white: white)
        s.atPort = port
    }

    /// Under way at `mile`, past the stops behind it.
    static func go(_ s: inout GameState, _ mile: Int, white: Bool = false) {
        s = fresh(month: 2)
        s.mile = mile
        s.stopIndex = journey.stops.lastIndex { $0.mile < mile } ?? 0
        settle(&s, toward: s.stopIndex + 1, white: white)
        s.atPort = false
    }
}
