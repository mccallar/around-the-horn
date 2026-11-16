import SwiftUI
import HornEngine

/// The Long Transfer, 2087: everything the shell says and draws for it. The engine counts
/// in days and in units of 10,000 km, and calls its two meters `hull` and `sails`; here
/// they are the pressure hull and power & drive, `sailcloth` is array panels, `timber`
/// hull patches, `limes` supplement packs and `tackle` tether cartridges, counted in shots.
/// Propellant is stored in tenths of a tonne. The art is in the files beside this one.
enum MarsSkin {
    static let journey = Journeys.journey(Mars.id)

    static let skin = JourneySkin(
        id: Mars.id, card: card, words: words,
        scene: SceneSkin(draw: MarsScene.draw, label: MarsScene.label),
        chart: MarsChart.skin, forage: MarsForage.skin, debug: debug)

    /// The engine's own figures, held to it by `MarsSkinTests`: the contract pays for
    /// every day under this, at this much a day.
    static let contractDays = 170
    static let bonusPerDay = 25

    /// Units of 10,000 km as millions of km, without the unit: 31,245 reads "312.45".
    static func millions(_ units: Int) -> String {
        let u = abs(units)
        let part = u % 100
        return "\(units < 0 ? "-" : "")\(formatNumber(Double(u / 100))).\(part < 10 ? "0" : "")\(part)"
    }

    /// "312.45 million km".
    static func km(_ units: Int) -> String { "\(millions(units)) million km" }

    /// "1 day", "3 days".
    static func days(_ n: Int) -> String { "\(n) \(n == 1 ? "day" : "days")" }

    /// A number to a tenth, without a trailing ".0": "2.5", "4".
    static func tenth(_ x: Double) -> String {
        let r = (x * 10).rounded() / 10
        return r == r.rounded() ? String(Int(r)) : String(r)
    }

    static let card = TitleCard(
        banner: "THE LONG TRANSFER · 2087",
        title: "THE LONG\nTRANSFER",
        year: "~ 2087 ~",
        tagline: "Four hundred and eighty million kilometres from Earth orbit to Mars, in a freighter that has seen better decades.",
        start: "Take the charter",
        resume: { "Rejoin the [i]\($0)[/i]" },
        learn: "Learn about the transfer",
        learnPages: [
            TitleCard.Page(heading: "The transfer", paragraphs: [
                "Mars has four thousand people on it, and they need everything. Twice a decade the planets line up, and anything that can hold air leaves Earth orbit with cargo.",
                "You have chartered a second-hand transfer freighter, with a crew of five counting yourself, to deliver to the settlement at [amber]Jezero[/amber], 480 million km along the transfer arc. The contract pays a bonus for every day under 170. After that nothing is forfeit; a late ship is merely late.",
                "There are four places to tie up: Gateway Yard, where you start; the cycler [i]Perpetua[/i], passing through at 155 million km; Midway Depot at 300; and Phobos Yard, 7 million short of the landing.",
                "Time passes a day at a time. The ledger counts in thousands of dollars, so a $9 medical kit is nine thousand dollars' worth of very good dressings. Nobody aboard finds this funny any more.",
            ]),
            TitleCard.Page(heading: "Supplies", paragraphs: [
                "[amber]Propellant[/amber] drives the ship: a tonne a day at cruise, 0.7 at an economy burn, 1.6 at a hard burn. The tanks hold 100 tonnes, which is not enough to reach Mars. Run them dry and she coasts at four tenths of her speed, turning slowly with nothing to hold her steady, and power & drive loses a point a day.",
                "[amber]Water[/amber] is the other thing that runs out. The recycler gives back most of it, but 2 litres a head a day are gone for good. In the two old comet streams, a [amber]tether cartridge[/amber] and the grapple turn ice into water for the price of a shot.",
                "[amber]Power & drive[/amber] is the solar wings and the thruster as one. It wears every day, faster far from the Sun, and it heats the cabin: under 40% the crew is cold, under 20% freezing, and [amber]thermal suits[/amber], one each, are all that stands between them and hypothermia.",
                "At 0% the array is dark: no drive, no recycler, twice the water lost. A spare [amber]array panel[/amber] puts it right in a day. Without one, two of the crew can always go out in suits and rewire what is left of the wings: two days, for 10 points of power.",
                "The [amber]pressure hull[/amber] keeps the air in. Pebbles hole it and storms beat on it, and [amber]hull patches[/amber] mend it. If it ever shows 0%, it lets go. [amber]Supplement packs[/amber] keep bones from thinning: a month without, and they start to.",
            ]),
            TitleCard.Page(heading: "Turnover and capture", paragraphs: [
                "Halfway, at [amber]Turnover[/amber], the ship turns end for end and starts braking. Run on four more days first and you arrive about four days sooner, for 8 tonnes of propellant and a braking burn the drive may not enjoy.",
                "At Mars you must be caught. [amber]Aerobraking[/amber], dipping through the top of the atmosphere, is quick and free and very hard on the hull. A [amber]propulsive capture[/amber] costs 10 tonnes and two or three days, and leaves the hull alone.",
                "The cycler [i]Perpetua[/i] never stops: matching orbits to dock costs 6 tonnes. Wave her by and the next station is 145 million km on. The cycler, turnover and the capture all need a drive: reach one with the array dark, and it waits until there is power.",
                "Every launch in the window is on the 7th, August to December 2087. October has the shortest arc. Earlier is slow and calm; later is slow and stormy, because the Sun is building to a maximum next spring.",
            ]),
        ],
        roleHeading: "Who are you?",
        roleIntro: "Plenty of people want to haul cargo to Mars. Three kinds actually do it. Which are you?",
        differencesAction: "Weigh them up",
        differencesHeading: "How they weigh up",
        differences: [
            "A charter costs money every day it runs, and only one of these three started with much of it.",
            "[amber]Charter captain[/amber] — starts with $1,500.",
            "[amber]Yard rigger[/amber] — starts with $850. Gets far more out of every array panel and hull patch.",
            "[amber]Ice hauler[/amber] — starts with $625. A dead eye with the grapple, and her melt tank takes 100 litres from an outing where the others manage 60.",
            "The thinner the purse, the more a delivery is worth: the rigger's counts double, the hauler's triple.",
        ],
        namesHeading: "Freighter & crew",
        vesselPrompt: "Name your freighter:",
        vesselLabel: "Freighter's name",
        leaderPrompt: "Your name, Captain:",
        leaderLabel: "Captain's name",
        crewPrompt: "Your four crew members:",
        crewLabel: "Crew member",
        monthHeading: "When will you launch?",
        monthIntro: "The 2087 window opens in August and closes in December. Gateway has a launch slot on the 7th of every month in it, and the yard wants an answer. When will you go?",
        monthAdvice: "The yard boss looks up from her slate, which she almost never does. “August is calm, but the planets are badly placed and it's a long haul. December is just as long, and the Sun will throw storms at you all the way. October is the window: the shortest arc there is this time round. September or November if you have to.”",
        outfitHeading: "Fitting out",
        outfitIntro: { "You have [amber]$\(formatNumber($0.money))[/amber] to fit out the [i]\(Markup.escape($0.ship))[/i]. The chandlery at Gateway Yard has what you need:" },
        outfitBullets: [
            "• [b]Propellant[/b] — a tonne a day at cruise. The tanks hold 100 tonnes; Gateway to the [i]Perpetua[/i] is 155 million km, about 42 days at cruise. Fill up again there and at Midway, where it is cheapest.",
            "• [b]Rations[/b] — five people on full rations eat 4 kg a day.",
            "• [b]Water[/b] — the recycler loses 2 litres a head a day, 10 a day for five of you. The tanks hold 800 litres.",
            "• [b]Supplement packs[/b] — a pack lasts one person 50 days. A month without, and bones start to thin.",
            "• [b]Thermal suits[/b] — one each. The heat runs off the same power as the drive.",
            "• [b]Array panels & hull patches[/b] — the only repairs you can make between stations.",
            "• [b]Medical kits & tether cartridges[/b] — a cartridge fires the grapple 20 times, at ice in the two comet streams.",
        ],
        enterShop: "Enter the chandlery",
        rankLegend: "Master of Transfer 8,000+ · Deep-space Hand 5,000+ · Orbit Hand 2,500+ · Groundling")

    /// The ship's plight, for the status box (docs/journeys/mars.md, D14): the array dark,
    /// the tanks dry, or less propellant than a day at this burn takes, which drives only
    /// part of one. Nothing before she leaves Gateway. The hull needs no row: at 0% the run
    /// is over.
    static func trouble(_ g: GameState) -> String? {
        guard g.day > 0 else { return nil }
        let dark = Mars.dark(g), dry = g.fuel <= 0
        let coasting = g.atPort ? "" : ", coasting"
        if dark { return dry ? "Array dark, tanks dry" : "Array dark\(coasting)" }
        if dry { return "Tanks dry\(coasting)" }
        return Mars.lastOfThePropellant(g) ? "Last of the propellant" : nil
    }

    /// The contract row: days in hand, as the engine pays for them (one in hand at day
    /// 169), and late from the day its own message says the date has passed.
    static func contract(_ g: GameState) -> String {
        let left = contractDays - g.day
        return left > 0 ? "\(days(left)) in hand" : left == 0 ? "late" : "\(days(-left)) late"
    }

    static func words(_ g: GameState) -> Words {
        let pace = journey.pace(g.pace), rations = journey.rations(g.rations)
        let n = g.living.count
        let home = journey.stops.first?.name ?? ""
        let title = journey.role(g.role).title
        let article = title.first.map { "aeiou".contains($0) } == true ? "an" : "a"
        let gone = g.day > 0
        let dark = Mars.dark(g) && gone, dry = g.fuel <= 0 && gone
        let docked = g.atPort && journey.port(g.currentStop.id) != nil
        let left = contractDays - g.day
        return Words(
            setOut: "Burn for Mars",
            halt: "Cut the drive & take stock",
            carryOn: "Continue the transfer",
            supplies: "Check supplies & crew",
            chart: "Look at the plot",
            changePace: "Change thrust",
            changeRations: "Change rations",
            rest: "Idle the drive and rest",
            repairs: "Make repairs",
            forage: "Work the grapple",
            leavePort: "Undock and burn on",
            restInPort: "Rest aboard the station",
            trade: "Trade along the docking ring",
            talk: "Talk to people",
            buy: "Buy supplies",
            yard: "Visit the yard crew",
            place: docked ? "Docked at \(g.currentStop.short)" : nil,
            statusNames: [:],
            travelled: "Along the arc",
            distanceUnit: "million km",
            distance: { millions($0) },
            meters: ("Pressure hull", "Power & drive"),
            clock: ("Contract", contract(g)),
            trouble: trouble(g).map { ("Ship", $0) },
            cash: "Cash",
            currency: "$",
            storeNames: [:],
            looseUnits: [.tackle: "shots"],
            looseOne: [.tackle: "shot"],
            fractional: [.limes],
            singular: true,
            lots: [],
            departRefusal: g.fuel <= 0
                ? "Gateway's traffic office won't clear a ship to leave the yard with her tanks empty. The quartermaster points you back at the propellant."
                : nil,
            resumesInFirstShop: true,
            leaveRefusal: nil,
            vesselHeading: "The \(g.ship)",
            suppliesNote: "Thrust: \(pace.name) · Rations: \(rations.name)"
                + (g.noCitrus > journey.rules.deficiencyAfter / 2 ? " · [red]\(days(g.noCitrus)) without supplements[/red]" : "")
                + (dark ? " · [red]the array is dark[/red]" : "")
                + (dry ? " · [red]the tanks are dry[/red]" : ""),
            crewHeading: "Crew · health \(g.healthLabel.text)",
            leaderTag: "captain",
            clothesWarning: g.clothes < n ? "[red]Only \(g.clothes) of \(n) aboard have a thermal suit.[/red]" : nil,
            lostHeading: "Lost on the transfer",
            paceHeading: "Thrust",
            paceNow: "The drive is set for [amber]\(pace.name)[/amber]."
                + (dark ? " [red]The array is dark: she is only coasting.[/red]"
                    : dry ? " [red]The tanks are dry: she is only coasting.[/red]" : ""),
            rationsHeading: "Rations",
            rationsNow: "The crew is on [amber]\(rations.name)[/amber]. With \(n) aboard, that's \(tenth(Double(n) * rations.amount)) kg a day.",
            restPrompt: g.atPort
                ? "The station has bunks with curtains and a shower that runs for whole minutes. How long will you stay?"
                : "You idle the drive, and the crew sleeps in shifts with the cabin lights down. How long will you rest?",
            restChoice: { days($0) },
            repairsHeading: "Repairs",
            repairsNote: "Each repair takes a day." + (g.role == .shipwright ? " As a yard rigger, your repairs go much further." : ""),
            mend: "Fit a spare array panel — 1 panel [dim](have \(g.sailcloth))[/dim]",
            patch: "Patch the pressure hull — 1 patch [dim](have \(g.timber))[/dim]",
            yardHeading: "The yard crew",
            yardIntro: "You have [amber]$\(formatNumber(g.money))[/amber]. Each job takes a day.",
            yardHull: { "Reseal the pressure hull — $\(formatNumber(Double($0)))" },
            yardSails: { "New panels and a rebuilt thruster grid — $\(formatNumber(Double($0)))" },
            leaveYard: "Back to the station",
            priceNote: { p in
                p >= 0 ? "Prices here run about \(p)% above \(home)'s, give or take what is scarce."
                       : "Prices here run about \(-p)% below \(home)'s, give or take what is scarce."
            },
            burial: { "The crew gathers at the lock for \($0). What words will you say?" },
            commit: "Say a few words",
            gameOverLine: "\(g.dateText) · \(km(g.mile)) out from \(home).",
            arrival: "Jezero Landing! The [i]\(Markup.escape(g.ship))[/i] sets her cargo down on \(g.dateText), \(days(g.day)) out of \(home).",
            arrivalBody: (left > 0
                ? "The contract allowed 170 days, and you have \(days(left)) in hand. The settlement turns out in suits to watch the crates come down the ramp, and somebody has painted a banner, slightly misspelled. "
                : "The contract date is behind you, and so is the bonus. The settlement turns out in suits all the same, and nobody mentions the date. ")
                + (n > 1 ? "Your crew is asking where a person gets a hot shower that lasts more than four minutes."
                         : "You walk down the ramp alone, and stand a while under a sky the colour of weak tea."),
            bonus: "Bonus for being \(article) \(title)",
            again: "Take another charter",
            thanks: "Thanks for hauling.")
    }

    static let debug = DebugSkin(
        start: { stop, month in
            // October unless the month asked for is one she can launch in.
            let d = journey.departures.first { $0.month == month } ?? (year: 2087, month: 9)
            var s = GameState(journey: Mars.id, role: .merchant, ship: "Fair Copy", captain: "Noor",
                              crew: ["Tomasz", "Priya", "Kenji", "Lucía"], startYear: d.year, startMonth: d.month)
            s.stopIndex = stop - 1
            s.mile = journey.stops[stop].mile - 10
            s.day = max(1, s.mile / 330)
            s.fuel = 600
            s.water = 400
            s.food = 300
            s.limes = 6
            s.meds = 3
            s.clothes = 5
            s.sailcloth = 3
            s.timber = 3
            s.tackle = 60
            s.hull = 72
            s.sails = 64
            s.money = 400
            s.atPort = false
            return s
        },
        gallery: [
            ("Gateway Yard", false, { $0.atPort = true }),
            ("Lunar distance", false, { at(&$0, "lunar") }),
            ("Earth's reach", false, { at(&$0, "hill") }),
            ("The Perpetua, docked", false, { at(&$0, "cycler", port: true) }),
            ("The Perpetua, passing", false, { at(&$0, "cycler") }),
            ("Turnover", false, { at(&$0, "turnover") }),
            ("Midway Depot", false, { at(&$0, "midway", port: true) }),
            ("Conjunction shadow", false, { at(&$0, "shadow") }),
            ("Mars approach", false, { at(&$0, "approach") }),
            ("Phobos Yard", false, { at(&$0, "phobos", port: true) }),
            ("Jezero Landing", false, { at(&$0, "jezero"); $0.atPort = true }),
            ("Cislunar space", true, { fly(&$0, 120) }),
            ("Departure leg", true, { fly(&$0, 1500) }),
            ("First ice stream", true, { fly(&$0, 9500) }),
            ("Inner arc", true, { fly(&$0, 20000) }),
            ("Deep space, braking", true, { fly(&$0, 30500) }),
            ("Second ice stream", true, { fly(&$0, 35500) }),
            ("Shadow", true, { fly(&$0, 39000) }),
            ("Approach", true, { fly(&$0, 44000) }),
            ("Aerobraking", true, { fly(&$0, 46800); $0.vars[MarsScene.captureKey] = 1 }),
            ("Burning into orbit", true, { fly(&$0, 46800); $0.vars[MarsScene.captureKey] = 2 }),
            ("Hard burn", true, { fly(&$0, 20000); $0.pace = .full }),
            ("Array dark", true, { fly(&$0, 30500); $0.sails = 0 }),
            ("Tanks dry, tumbling", true, { fly(&$0, 20000); $0.fuel = 0 }),
            ("Power 15%", true, { fly(&$0, 20000); $0.sails = 15 }),
            ("Hull 15%", true, { fly(&$0, 20000); $0.hull = 15 }),
            ("The hull lets go", false, { fly(&$0, 20000); $0.hull = 0; $0.over = true }),
            ("Lost aerobraking", false, { fly(&$0, 46800); $0.vars[MarsScene.captureKey] = 1; $0.hull = 0; $0.over = true }),
        ])

    /// Under way at `mile`, past the stops behind it, with propellant aboard.
    static func fly(_ s: inout GameState, _ mile: Int) {
        s.mile = mile
        s.stopIndex = journey.stops.lastIndex { $0.mile < mile } ?? 0
        s.day = max(1, mile / 330)
        s.fuel = 600
    }

    /// Standing at a stop, its arrival told: docked, if it is a station and `port` says so.
    static func at(_ s: inout GameState, _ id: String, port: Bool = false) {
        guard let i = journey.stops.firstIndex(where: { $0.id == id }) else { return }
        s.stopIndex = i
        s.mile = journey.stops[i].mile
        s.day = max(1, s.mile / 330)
        if s.fuel <= 0 { s.fuel = 600 }
        s.atPort = port
    }
}
