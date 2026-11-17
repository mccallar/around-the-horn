import SwiftUI
import HornEngine

/// The Jet Stream, 1999: everything the shell says and draws for it. The engine counts in
/// four-hour watches and calls its two meters `hull` and `sails`; here they are lift and
/// the burners, `timber` is ballast, `sailcloth` burner spares, `limes` CO2 scrubbers and
/// `tackle` fishing line, counted in casts. The art is in the files beside this one.
enum BalloonSkin {
    static let journey = Journeys.journey(Balloon.id)

    static let skin = JourneySkin(
        id: Balloon.id, card: card, words: words,
        scene: SceneSkin(draw: BalloonScene.draw, label: BalloonScene.label),
        chart: BalloonChart.skin, forage: BalloonForage.skin, debug: debug)

    /// Watches to the day.
    static var perDay: Int { max(1, 24 / max(1, journey.rules.tickHours)) }

    /// "1 watch", "3 watches".
    static func watches(_ n: Int) -> String { "\(n) \(n == 1 ? "watch" : "watches")" }

    /// A count of watches as the menus write it: "3 watches", and the whole days a long
    /// one makes, "6 watches (1 day)".
    static func span(_ n: Int) -> String {
        guard n >= perDay, n % perDay == 0 else { return watches(n) }
        let d = n / perDay
        return "\(watches(n)) (\(d) \(d == 1 ? "day" : "days"))"
    }

    /// A number to a tenth, without a trailing ".0": "2.5", "2".
    static func tenth(_ x: Double) -> String {
        let r = (x * 10).rounded() / 10
        return r == r.rounded() ? String(Int(r)) : String(r)
    }

    /// Pounds to a tenth: "2.5 lbs", "1 lb".
    static func pounds(_ x: Double) -> String {
        let n = tenth(x)
        return "\(n) \(n == "1" ? "lb" : "lbs")"
    }

    /// The altitude screen's first lines. Aloft: the height she flies at, and with no heat
    /// that it changes nothing about the drift. On the ground: the height she will climb
    /// to, unless the burners are dead and there is no climb (`Balloon.leaving`).
    static func paceNow(_ g: GameState, _ name: String, dead: Bool, dry: Bool) -> String {
        if g.atPort {
            return "She is on the ground. When she goes up, she will climb to [amber]\(name)[/amber]."
                + (dead ? " [red]Not on dead burners: she can only go up on the helium, and drift.[/red]" : "")
        }
        return "You are flying at [amber]\(name)[/amber]."
            + (dead || dry
                ? " [red]With no heat for the cone, the height makes no difference to how far she drifts.[/red] It still sets how hard the air is on the crew."
                : "")
    }

    static let card = TitleCard(
        banner: "THE JET STREAM · 1999",
        title: "THE JET\nSTREAM",
        year: "~ 1999 ~",
        tagline: "Eighteen thousand nautical miles round the world by balloon, riding the winter jet stream.",
        start: "Fly round the world",
        resume: { "Continue the flight of the [i]\($0)[/i]" },
        learn: "Learn about the flight",
        learnPages: [
            TitleCard.Page(heading: "The flight", paragraphs: [
                "In the winter of 1998 nobody had yet flown a balloon around the world. Teams had been trying for twenty years, and many of them had ended up in the sea, which is a long way down from the jet stream.",
                "You command a balloon with a sealed capsule and a crew of five, counting yourself. Ride the jet stream east from Marrakech until you cross its meridian again from the west, 18,300 nautical miles later. Five fields along the way have a ground team waiting with propane and supplies, if you choose to land.",
                "Time passes in [amber]watches[/amber] of four hours, six to a day.",
            ]),
            TitleCard.Page(heading: "Propane, lift and burners", paragraphs: [
                "[amber]Propane[/amber] keeps you up. You burn it every watch, flying or loitering, and more in the cold; climbing away from a field takes 25 gallons. When the tanks run dry the envelope cools, and you drift on the helium alone, sinking as you go.",
                "[amber]Lift[/amber] leaks away a little every watch, and hot sun, ice and storms take more. Drop a sack of [amber]ballast[/amber] to win it back, or have the riggers at a field top up the helium. When the lift is gone she starts down, and something heavy must go over the side: ballast, or a whole cylinder of propane. With neither, she comes down for good.",
                "[amber]Burners[/amber] wear, worst of all up in the jet and in rough air. Fit [amber]burner spares[/amber] aloft, or have a field's burner man overhaul them. Worn to nothing they give no heat at all, and she drifts and sinks as if the tanks were dry.",
            ]),
            TitleCard.Page(heading: "Air, food and the cold", paragraphs: [
                "[amber]Food[/amber] and [amber]water[/amber] run out too. The fields sell more, at a price.",
                "[amber]CO2 scrubbers[/amber] keep the capsule air fit to breathe. Three days without them, and the crew starts to sicken.",
                "[amber]Down suits[/amber] keep the crew alive in the cold of the jet, one each. [amber]Fishing line[/amber] lets you catch food over the sea, at the wave tops, with the hatch open.",
            ]),
            TitleCard.Page(heading: "The Pacific", paragraphs: [
                "From Saga to Albuquerque is 5,850 nautical miles with nowhere to land. In good winds the crossing burns some 600 gallons of propane; in poor ones, far more. Fill every tank at Saga. Off the coast of Japan you must choose: ride the bitter-cold [amber]northern track[/amber] in the core of the jet, or drop to the warmer, slower [amber]southern track[/amber], where the thunderstorms grow.",
                "Timing matters. The jet is strongest from December to February. Launch in November or March and you'll wallow.",
                "Height matters too: up in the jet you're fast and burn less propane for every mile, if your crew can stand it.",
            ]),
        ],
        roleHeading: "Who are you?",
        roleIntro: "Balloonists came from every walk of life, and with every size of bank balance. Which one are you?",
        differencesAction: "Compare the three",
        differencesHeading: "How they compare",
        differences: [
            "Flying round the world is expensive, and not everyone who tried it was rich.",
            "[amber]Chocolate maker[/amber] — starts with $15,000.",
            "[amber]Balloon builder[/amber] — starts with $7,250. Gets far more out of every sack of ballast and every burner kit.",
            "[amber]Bush pilot[/amber] — starts with $6,500. Deadly with a fishing line, and can stow half as much again of a catch.",
            "The poorer you start, the more your finish is worth: the builder's counts double, the bush pilot's triple.",
        ],
        namesHeading: "Balloon & crew",
        vesselPrompt: "Name your balloon:",
        vesselLabel: "Balloon's name",
        leaderPrompt: "Your name, Pilot:",
        leaderLabel: "Pilot's name",
        crewPrompt: "Your four crew members:",
        crewLabel: "Crew member",
        monthHeading: "When will you launch?",
        monthIntro: "The winds that can carry a balloon round the world blow hardest in the dead of winter. Your balloon is ready in November 1998. When will you launch?",
        monthAdvice: "Your meteorologist taps the chart: “The jet is weak in November and starts breaking up in March. Launch in December, January or February, and you'll have it under you most of the way.”",
        outfitHeading: "Outfitting",
        outfitIntro: { "You have [amber]$\(formatNumber($0.money))[/amber] to fit out the [i]\(Markup.escape($0.ship))[/i]. The supply hangar at the launch field has what you need:" },
        outfitBullets: [
            "• [b]Propane[/b] — 12 to 16 gallons a watch, more in the cold, and 25 to climb away from any field. You can lift 1,200 gallons. There is nowhere to land between Saga and Albuquerque: fill every tank at Saga.",
            "• [b]Food[/b] — five of you on hot meals eat 2.5 lbs a watch, and the flight takes three or four weeks. The fields along the way sell more, at a markup.",
            "• [b]Water[/b] — a fifth of a gallon each a watch, more in the heat. In snow you can melt rime off the hatch rim.",
            "• [b]CO2 scrubbers[/b] — a canister lasts five of you ten watches. Without them the capsule air goes stale within three days.",
            "• [b]Down suits[/b] — one per person, or the cold of the jet will kill them.",
            "• [b]Ballast & burner spares[/b] — the only repairs you can make aloft.",
            "• [b]Medical kits & fishing line[/b] — a spool is 20 casts, trailed from the hatch at the wave tops.",
        ],
        enterShop: "Enter the supply hangar",
        rankLegend: "Master Aeronaut 7,000+ · Balloon Captain 4,000+ · Co-pilot 2,000+ · Ballast")

    /// On the ground at a field, short of what the climb needs or with no lift, when the
    /// field sells the remedy (`Balloon.relaunchRefusal`). Marrakech's launch is the
    /// engine's own refusal, through `depart`.
    static func relaunchRefusal(_ g: GameState) -> String? {
        guard g.atPort, g.stopIndex > 0, !g.over else { return nil }
        return Balloon.relaunchRefusal(GameEngine(state: g))
    }

    /// The balloon's plight, for the status box: going down (the engine's own rule), no
    /// heat with the burners dead or the tanks dry, or less propane than a watch flown here
    /// burns, which heats only part of one. Nothing before the launch.
    static func trouble(_ g: GameState) -> String? {
        guard g.day > 0 else { return nil }
        if Balloon.goingDown(g) { return g.atPort ? "No lift" : "Going down" }
        let dead = Balloon.burnersOut(g), dry = g.fuel <= 0
        if dead { return dry ? "Burners dead, tanks dry" : g.atPort ? "Burners dead" : "Burners dead, sinking" }
        if dry { return g.atPort ? "Tanks dry" : "Tanks dry, sinking" }
        return Balloon.lastOfThePropane(g) ? "Last of the propane" : nil
    }

    static func words(_ g: GameState) -> Words {
        let pace = journey.pace(g.pace), rations = journey.rations(g.rations)
        let n = g.living.count
        let home = journey.stops.first?.name ?? ""
        let title = journey.role(g.role).title
        // The engine's finale: the crossing, then the landing and who climbs out.
        let finale = Balloon.finale(g).components(separatedBy: "\n\n")
        let dry = g.fuel <= 0 && g.day > 0
        let dead = Balloon.burnersOut(g)
        let field = g.atPort && journey.port(g.currentStop.id) != nil
        return Words(
            setOut: "Climb away",
            halt: "Hold & take stock",
            carryOn: "Continue the flight",
            supplies: "Check supplies & crew",
            chart: "Look at the chart",
            changePace: "Change altitude",
            changeRations: "Change rations",
            rest: "Loiter low and rest",
            repairs: "Make repairs",
            forage: "Trail a fishing line",
            // On dead burners there is no climb to burn propane on (`Balloon.leaving`).
            leavePort: "Relaunch [dim](\(dead ? "on the helium alone" : "25 gallons"))[/dim]",
            restInPort: "Rest on the ground",
            trade: "See who'll trade",
            talk: "Ask around the field",
            buy: "Buy supplies",
            yard: "Visit the riggers",
            yardQuestion: nil,
            place: field ? g.currentStop.short : nil,
            stopName: { $0.short },
            statusNames: [.water: "Water"],
            travelled: "Flown",
            distanceUnit: "nm",
            distance: { formatNumber(Double($0)) },
            meters: ("Lift", "Burners"),
            clock: nil,
            trouble: trouble(g).map { ("Balloon", $0) },
            cash: "Cash",
            currency: "$",
            storeNames: [:],
            looseUnits: [.tackle: "casts"],
            looseOne: [.tackle: "cast"],
            fractional: [.limes],
            singular: true,
            lots: [.water, .fuel],
            departRefusal: nil,
            departWarning: nil,
            resumesInFirstShop: true,
            leaveRefusal: relaunchRefusal(g),
            vesselHeading: "The \(g.ship)",
            suppliesNote: "Altitude: \(pace.name) · Rations: \(rations.name)"
                + (g.noCitrus > 12 ? " · [red]\(watches(g.noCitrus)) without scrubbers[/red]" : "")
                + (dry ? " · [red]the tanks are dry[/red]" : "")
                + (dead ? " · [red]the burners are dead[/red]" : ""),
            crewHeading: "Crew · health \(g.healthLabel.text)",
            leaderTag: "pilot",
            clothesWarning: g.clothes < n ? "[red]Only \(g.clothes) of \(n) aboard have a down suit.[/red]" : nil,
            lostHeading: "Lost on the flight",
            paceHeading: "Altitude",
            paceNow: paceNow(g, pace.name, dead: dead, dry: dry),
            rationsHeading: "Rations",
            rationsNow: "The crew is on [amber]\(rations.name)[/amber]. With \(n) aboard, that's \(pounds(Double(n) * rations.amount)) a watch.",
            restPrompt: g.atPort
                ? "The ground team pitches tents beside the field, and everyone sleeps on ground that keeps still. How long will you stay?"
                : "You drop into slow, low air and let the crew sleep in turns. You make no headway east, and the burners still want about 10 gallons a watch. How long will you loiter?",
            restChoice: { "\(g.atPort ? "Rest" : "Loiter") \(span($0))" },
            repairsHeading: "Repairs aloft",
            repairsNote: "Each repair takes a watch." + (g.role == .shipwright ? " As a balloon builder, your repairs go much further." : ""),
            mend: "Service the burners — 1 kit [dim](have \(g.sailcloth))[/dim]",
            patch: "Drop a sack of ballast [dim](have \(g.timber))[/dim]",
            yardHeading: "The riggers",
            yardIntro: "You have [amber]$\(formatNumber(g.money))[/amber]. Each job takes a watch on the ground.",
            yardHull: { "Top up the helium — $\(formatNumber(Double($0)))" },
            yardSails: { "Overhaul the burners — $\(formatNumber(Double($0)))" },
            leaveYard: "Back to the field",
            priceNote: { "Prices here are \($0)% above \(home), more or less." },
            burial: { name in
                g.atPort
                    ? "The ground team will take \(name) home. What words will you say?"
                    : "There is nowhere to bury anyone up here. The crew wraps \(name) in a sleeping bag and settles them in the quietest corner of the capsule, to be carried home. What words will you say?"
            },
            commit: g.atPort ? "Say goodbye" : "Carry them home",
            gameOverLine: Balloon.shortfall(g),
            arrival: finale.first ?? "",
            arrivalBody: finale.dropFirst().joined(separator: "\n\n"),
            bonus: "Bonus for being a \(title)",
            again: "Fly again",
            thanks: "Thanks for flying.")
    }

    static let debug = DebugSkin(
        start: { stop, month in
            // January 1999 unless the month asked for is one she can launch in.
            let d = journey.departures.first { $0.month == month } ?? (year: 1999, month: 0)
            var s = GameState(journey: Balloon.id, role: .merchant, ship: "Skylark", captain: "Greta",
                              crew: ["Hugo", "Yuki", "Conor", "Rosa"], startYear: d.year, startMonth: d.month)
            s.stopIndex = stop - 1
            s.mile = journey.stops[stop].mile - 10
            daytime(&s)
            s.fuel = 900
            s.water = 150
            s.food = 200
            s.limes = 8
            s.meds = 3
            s.clothes = 5
            s.sailcloth = 3
            s.timber = 4
            s.tackle = 60
            s.hull = 72
            s.sails = 64
            s.money = 2000
            s.atPort = false
            return s
        },
        gallery: [
            ("By night over the Sahara", true, { fly(&$0, 1200); $0.day = 3 }),
            ("Marrakech", false, { $0.atPort = true }),
            ("Climbing away", false, { $0.fuel = 900 }),
            ("Luxor", false, { at(&$0, "lux", port: true) }),
            ("Jodhpur", false, { at(&$0, "jod", port: true) }),
            ("Saga", false, { at(&$0, "saga", port: true) }),
            ("Albuquerque", false, { at(&$0, "abq", port: true) }),
            ("Kitty Hawk", false, { at(&$0, "kh", port: true) }),
            ("Over the Luxor field", false, { at(&$0, "lux") }),
            ("High Atlas", false, { at(&$0, "atlas") }),
            ("Himalaya", false, { at(&$0, "him") }),
            ("Off Japan", false, { at(&$0, "pacific") }),
            ("Date line", false, { at(&$0, "dateline") }),
            ("Landfall, north", false, { at(&$0, "landfall") }),
            ("Landfall, south", false, { $0.vars["balloon.south"] = 1; at(&$0, "landfall") }),
            ("Azores", false, { at(&$0, "azores") }),
            ("Finish line", false, { at(&$0, "finish"); $0.atPort = true; $0.over = true }),
            ("Sahara", true, { fly(&$0, 1200) }),
            ("Arabia", true, { fly(&$0, 3000) }),
            ("Gulf of Oman", true, { fly(&$0, 3650) }),
            ("Indus & Thar", true, { fly(&$0, 4200) }),
            ("Northern India", true, { fly(&$0, 4800) }),
            ("Himalaya & China", true, { fly(&$0, 6200) }),
            ("East China Sea", true, { fly(&$0, 7700) }),
            ("North Pacific", true, { fly(&$0, 9000) }),
            ("Northeast Pacific", true, { fly(&$0, 11500) }),
            ("Southern track", true, { $0.vars["balloon.south"] = 1; fly(&$0, 9000) }),
            ("Subtropical Pacific", true, { $0.vars["balloon.south"] = 1; fly(&$0, 11500) }),
            ("American Southwest", true, { fly(&$0, 13000) }),
            ("Great Plains, January", true, { $0.startYear = 1999; $0.startMonth = 0; fly(&$0, 14300) }),
            ("North Atlantic", true, { fly(&$0, 16300) }),
            ("Past the Azores", true, { fly(&$0, 17800) }),
            ("Morocco", true, { fly(&$0, 18260) }),
            ("Loitering", false, { fly(&$0, 9000) }),
            ("Tanks dry", true, { fly(&$0, 9000); $0.fuel = 0 }),
            ("Burners 10%", true, { fly(&$0, 9000); $0.sails = 10 }),
            ("Lift 10%", true, { fly(&$0, 9000); $0.hull = 10 }),
            ("Going down", false, { fly(&$0, 9000); $0.hull = 0 }),
            ("Down in the sea", false, { fly(&$0, 9000); $0.hull = 0; $0.over = true }),
            ("Down on land", false, { fly(&$0, 4800); $0.hull = 0; $0.over = true }),
        ])

    /// A watch that falls in the morning where she is, between about half past six and
    /// half past ten by the sun, at or a little after the day her miles suggest: so a
    /// debug start or a gallery cell is by day, and stays so for the watch or two a walk
    /// flies on.
    static func daytime(_ s: inout GameState) {
        let start = journey.rules.startHour, each = journey.rules.tickHours
        let target = (8.5 - BalloonScene.longitude(s) / 15).truncatingRemainder(dividingBy: 24)
        func off(_ d: Int) -> Double {
            let x = abs(Double((start + each * d) % 24) - (target < 0 ? target + 24 : target))
            return min(x, 24 - x)
        }
        let base = max(1, s.mile / 115)
        s.day = (base..<base + 24 / max(1, each)).min { off($0) < off($1) } ?? base
    }

    /// Flying at `mile`, past the stops behind it, with propane aboard, by day.
    static func fly(_ s: inout GameState, _ mile: Int) {
        s.mile = mile
        s.stopIndex = journey.stops.lastIndex { $0.mile < mile } ?? 0
        s.fuel = 900
        daytime(&s)
    }

    /// Standing at a stop, its arrival told: on the ground, if it is a field and `port`
    /// says so.
    static func at(_ s: inout GameState, _ id: String, port: Bool = false) {
        guard let i = journey.stops.firstIndex(where: { $0.id == id }) else { return }
        s.stopIndex = i
        s.mile = journey.stops[i].mile
        if s.fuel <= 0 { s.fuel = 900 }
        daytime(&s)
        s.atPort = port
    }
}
