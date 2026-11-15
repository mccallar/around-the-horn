import SwiftUI
import HornEngine

/// The Iron Road, 1869: everything the shell says and draws for it. The engine counts in
/// turns of four hours and calls its two meters `sails` and `hull`; here they are days and
/// hours, the engine and the running gear. The art is in the files beside this one.
enum RailSkin {
    static let journey = Journeys.journey(Rail.id)

    static let skin = JourneySkin(
        id: Rail.id, card: card, words: words,
        scene: SceneSkin(draw: RailScene.draw, label: RailScene.label),
        chart: RailChart.skin, forage: RailForage.skin, debug: debug)

    /// The freight is due this many turns out of Omaha: the engine's own figure (it pays
    /// for every turn in hand), held to it by `RailSkinTests`.
    static let contractTurns = 72

    /// Turns to the day.
    static var perDay: Int { max(1, 24 / max(1, journey.rules.tickHours)) }

    /// A number of turns as the player reads it: "8 hours", "1 day", "11 days and 4 hours".
    static func span(_ turns: Int) -> String {
        let d = turns / perDay, h = (turns % perDay) * journey.rules.tickHours
        let days = "\(d) day\(d == 1 ? "" : "s")"
        if d == 0 { return "\(h) hours" }
        return h == 0 ? days : "\(days) and \(h) hours"
    }

    static let card = TitleCard(
        banner: "THE IRON ROAD · 1869",
        title: "THE IRON\nROAD",
        year: "~ 1869 ~",
        tagline: "Seventeen hundred miles of new track from Omaha to Sacramento, and a freight due in twelve days.",
        start: "Take the contract",
        resume: { "Climb back aboard the [i]\($0)[/i]" },
        learn: "Learn about the road",
        learnPages: [
            TitleCard.Page(heading: "The road", paragraphs: [
                "In May 1869 two railroads met in the Utah desert, and a crossing that took a wagon most of a year's good weather began to take a train a week or two. It is now possible to cross the continent sitting down.",
                "You are the conductor of a chartered freight: a wood-burning engine, her tender, a tank car, two boxcars and a caboose, with a crew of five counting yourself. The freight is due in Sacramento, 1,776 miles off, in twelve days. After sixteen the contract is torn up.",
            ]),
            TitleCard.Page(heading: "Wood and water", paragraphs: [
                "[amber]Firewood[/amber] is what the engine eats: about a cord every four hours at timetable speed. The tender holds sixteen cords. Wood is cheap in Omaha, cheaper under the Sierra, and painful everywhere between.",
                "Where the line follows a river, driftwood can be hauled out with a [amber]grapnel line[/amber]. It costs four hours and a few casts.",
                "Trackside tanks keep the boiler full for nothing, except in the three deserts. There it drinks from your [amber]tank car[/amber], 80 gallons or more every four hours. Run dry and the engine crawls, and scorches her flues doing it.",
            ]),
            TitleCard.Page(heading: "The hills and the calendar", paragraphs: [
                "Two long grades stand in the way: [amber]Sherman Hill[/amber] past Cheyenne, and the east slope of the [amber]Sierra[/amber] past Reno. A helper engine waits at the foot of each, for a fee. Without one you climb at about half speed.",
                "From Donner Summit the road runs downhill, and the brakes do the work. Come down slow, or find out how fast a freight train can go.",
                "The season matters. The deserts are hot in summer and the mountains fill with snow in winter. The engine and the running gear wear with every mile: carry [amber]boiler fittings[/amber] and [amber]car spares[/amber], or pay a roundhouse.",
            ]),
        ],
        roleHeading: "Who are you?",
        roleIntro: "Three kinds of people chartered a freight west in 1869. Pick yours:",
        differencesAction: "How do they compare?",
        differencesHeading: "How they compare",
        differences: [
            "A chartered train was a rich man's gamble or a poor man's last one.",
            "[amber]Freight contractor[/amber] — starts with $1,000.",
            "[amber]Boilermaker[/amber] — starts with $520. Gets far more out of every set of fittings and crate of spares.",
            "[amber]River hand[/amber] — starts with $350. Has a sure arm with a grapnel, and can stack six cords of driftwood at a time where the others manage four.",
            "The poorer you start, the more your arrival is worth: the boilermaker scores double, the river hand triple.",
        ],
        namesHeading: "Train & crew",
        vesselPrompt: "Name your engine:",
        vesselLabel: "Engine's name",
        leaderPrompt: "Your name, Conductor:",
        leaderLabel: "Conductor's name",
        crewPrompt: "Your four crew members:",
        crewLabel: "Crew member",
        monthHeading: "When will you leave?",
        monthIntro: "The last spike went in at Promontory in May 1869, and the road is open from end to end. The freight is loaded and the consignee is counting days. When will you pull out of Omaha?",
        monthAdvice: "The yardmaster looks at the sky, then at you. “Go in summer and the deserts will cook you while the boiler drinks your tank car dry. Go in winter and the Sierra will bury you: December and January are the worst of it. October. It is the one month this road is polite.”",
        outfitHeading: "Outfitting",
        outfitIntro: { "You have [amber]$\(formatNumber($0.money))[/amber] to stock the [i]\(Markup.escape($0.ship))[/i]. The outfitter by the Omaha yard has what you need:" },
        outfitBullets: [
            "• [b]Firewood[/b] — about a cord every four hours at timetable speed. The tender holds 16 cords, and wood costs more at every yard short of Reno.",
            "• [b]Tank water[/b] — for the three deserts, where the boiler drinks 80 gallons or more every four hours. The car holds 1,200 gallons.",
            "• [b]Provisions[/b] — five people eating well use 15 lbs a day. The run should take about twelve.",
            "• [b]Wool blankets[/b] — one apiece, or the mountain nights will find you.",
            "• [b]Boiler fittings & car spares[/b] — the only way to make repairs between yards.",
            "• [b]Medicine kits & grapnel line[/b] — a coil is good for 20 casts at driftwood.",
        ],
        enterShop: "Enter the store",
        rankLegend: "Superintendent of the Line 7,000+ · Master Conductor 4,000+ · Brakeman 2,000+ · Section Hand")

    static func words(_ g: GameState) -> Words {
        let pace = journey.pace(g.pace), rations = journey.rations(g.rations)
        let n = g.living.count
        let left = contractTurns - g.day
        // A turn's ration for everyone, over a day's turns, to a tenth of a pound.
        let daily = (Double(n) * rations.amount * Double(perDay) * 10).rounded() / 10
        let home = journey.stops.first?.name ?? ""
        return Words(
            setOut: "Whistle off",
            halt: "Stop the train & take stock",
            carryOn: "Continue down the line",
            supplies: "Check supplies & crew",
            chart: "Look at the map",
            changePace: "Change pace",
            changeRations: "Change rations",
            rest: "Stop and rest",
            repairs: "Make repairs",
            forage: "Haul driftwood",
            leavePort: "Whistle off and roll on",
            restInPort: "Lay over in the yard",
            trade: "Look for a swap",
            talk: "Talk to people",
            buy: "Buy supplies",
            yard: "Visit the roundhouse",
            statusNames: [.water: "Tank car"],
            travelled: "Covered",
            distanceUnit: "miles",
            distance: { formatNumber(Double($0)) },
            meters: ("Running gear", "Engine"),
            // Late from the turn the engine calls it late, as the note and the score have it.
            clock: ("Contract", left > 0 ? "\(span(left)) left" : left == 0 ? "late" : "\(span(-left)) late"),
            cash: "Cash",
            currency: "$",
            storeNames: [.clothes: "Blankets"],
            looseUnits: [.tackle: "casts"],
            fractional: [],
            singular: true,
            lots: [.water],
            departRefusal: nil,
            vesselHeading: "The \(g.ship)",
            suppliesNote: "Pace: \(pace.name) · Rations: \(rations.name) · "
                + (left > 0 ? "\(span(left)) left on the contract" : "[red]the freight is late[/red]"),
            crewHeading: "Crew · health \(g.healthLabel.text)",
            leaderTag: "conductor",
            clothesWarning: g.clothes < n ? "[red]Only \(g.clothes) of \(n) have a blanket.[/red]" : nil,
            lostHeading: "Lost on the road",
            paceHeading: "Pace",
            paceNow: "The pace is currently [amber]\(pace.name)[/amber].",
            rationsHeading: "Rations",
            rationsNow: "Rations are currently [amber]\(rations.name)[/amber]. With \(n) aboard, that's \(formatNumber(daily)) lbs a day.",
            restPrompt: g.atPort ? "The crew can sleep in beds that stand still and eat at a table. How long will you lay over?"
                                 : "You set the brakes and the crew sleeps where it falls. How long will you stop?",
            restChoice: { span($0) },
            repairsHeading: "Repairs",
            repairsNote: "Each repair takes four hours." + (g.role == .shipwright ? " As a boilermaker, your repairs go much further." : ""),
            mend: "Work on the engine — 1 set of boiler fittings [dim](have \(g.sailcloth))[/dim]",
            patch: "Mend the running gear — 1 crate of car spares [dim](have \(g.timber))[/dim]",
            yardHeading: "Roundhouse",
            yardIntro: "You have [amber]$\(formatNumber(g.money))[/amber]. Each job takes four hours.",
            yardHull: { "Send the cars through the car shop — $\($0)" },
            yardSails: { "Have the engine overhauled — $\($0)" },
            leaveYard: "Leave the roundhouse",
            priceNote: { "Prices here run about \($0)% above \(home), give or take what the country grows." },
            burial: { "The crew digs a grave on a rise beside the track and marks it with a board from a crate, for \($0). What words will you say?" },
            commit: "Lay to rest",
            gameOverLine: "\(g.dateText) · \(formatNumber(Double(g.mile))) miles out of \(home).",
            arrival: "Sacramento! The [i]\(Markup.escape(g.ship))[/i] rolls into the yard by the river on \(g.dateText), \(span(g.day)) out of \(home).",
            // On time as the engine pays it: a turn in hand. At twelve days to the hour its
            // own message has already called the freight late.
            arrivalBody: (left > 0
                ?"The consignee is on the platform with a watch in his hand, and puts it away looking faintly let down. The freight is on time. "
                : "The consignee is on the platform with a watch in his hand and a good deal to say about the date. He signs for the freight anyway. ")
                + (n > 1 ? "Your crew is asking where a person gets a bath and a beefsteak."
                         : "You climb down alone and stand a while on ground that does not move."),
            bonus: "Bonus for being a \(journey.role(g.role).title)",
            again: "Run it again",
            thanks: "Thanks for riding.")
    }

    static let debug = DebugSkin(
        start: { stop, month in
            // October unless the month asked for is one a train can leave in.
            let d = journey.departures.first { $0.month == month } ?? (year: 1869, month: 9)
            var s = GameState(journey: Rail.id, role: .merchant, ship: "Prairie Queen", captain: "Amos",
                              crew: ["Hattie", "Lars", "Clara", "Otto"], startYear: d.year, startMonth: d.month)
            s.stopIndex = stop - 1
            s.mile = journey.stops[stop].mile - 10
            s.day = s.mile / 42
            s.fuel = 120
            s.water = 900
            s.food = 250
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
            ("Night", true, { $0.day = 4 }),
            ("In the yard", false, { $0.atPort = true }),
            ("Dale Creek", true, { $0.mile = 550 }),
            ("Red Desert", true, { $0.mile = 780 }),
            ("The Wasatch", true, { $0.mile = 950 }),
            ("Salt Desert", true, { $0.mile = 1150 }),
            ("The Humboldt", true, { $0.mile = 1400 }),
            ("Snowsheds", true, { $0.mile = 1700 }),
            ("Sacramento Valley", true, { $0.mile = 1760 }),
            ("Engine 10%", true, { $0.sails = 10 }),
            ("Running gear 10%", true, { $0.hull = 10 }),
        ])
}
