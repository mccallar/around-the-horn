import SwiftUI
import HornEngine

/// Over the Pole, 1926: everything the shell says and draws for it. The engine counts in
/// four-hour watches and calls its two meters `hull` and `sails`; here they are lift and
/// the engines, `timber` is water ballast and `sailcloth` engine spares. The art is in the
/// files beside this one.
enum AirshipSkin {
    static let journey = Journeys.journey(Airship.id)

    static let skin = JourneySkin(
        id: Airship.id, card: card, words: words,
        scene: SceneSkin(draw: AirshipScene.draw, label: AirshipScene.label),
        chart: AirshipChart.skin, forage: AirshipForage.skin, debug: debug)

    /// Watches to the day.
    static var perDay: Int { max(1, 24 / max(1, journey.rules.tickHours)) }

    /// "1 watch", "3 watches".
    static func watches(_ n: Int) -> String { "\(n) \(n == 1 ? "watch" : "watches")" }

    /// A rest as the menu offers it: "3 watches", and the whole days a long one makes,
    /// "6 watches (1 day)".
    static func span(_ n: Int) -> String {
        guard n >= perDay, n % perDay == 0 else { return watches(n) }
        let d = n / perDay
        return "\(watches(n)) (\(d) \(d == 1 ? "day" : "days"))"
    }

    /// A number to a tenth, without a trailing ".0": "1.5", "2".
    static func tenth(_ x: Double) -> String {
        let r = (x * 10).rounded() / 10
        return r == r.rounded() ? String(Int(r)) : String(r)
    }

    static let card = TitleCard(
        banner: "OVER THE POLE · 1926",
        title: "OVER\nTHE POLE",
        year: "~ 1926 ~",
        tagline: "Nine thousand six hundred kilometres from Rome to Nome, the short way: over the top of the world.",
        start: "Fly for the Pole",
        resume: { "Continue the flight of the [i]\($0)[/i]" },
        learn: "Learn about the flight",
        learnPages: [
            TitleCard.Page(heading: "The flight", paragraphs: [
                "In the spring of 1926 nobody had crossed the Arctic Ocean by air. An airship could stay up for days and tie up to a mast instead of needing a field, which made her the likeliest thing to try it. She was also a bag of hydrogen with engines hung underneath, which made the trying interesting.",
                "You command a small airship with a crew of five, counting yourself. Fly north from Rome, mast by mast, as far as Kings Bay on Spitsbergen. Then cross the North Pole and 4,300 kilometres of ice with no mast at all, to Nome in Alaska.",
                "Time passes in [amber]watches[/amber] of four hours, six to a day.",
            ]),
            TitleCard.Page(heading: "Petrol, lift and engines", paragraphs: [
                "[amber]Petrol[/amber] turns the engines. When the tanks run dry she becomes a free balloon and goes wherever the wind is going, which is seldom where you are.",
                "[amber]Lift[/amber] keeps her up. Gas seeps away every watch, and snow, ice and storms take more. When it is gone she comes down for good. Drop a bag of [amber]water ballast[/amber] and she rises at once, or top up the gas at a mast.",
                "[amber]Engines[/amber] wear, worst of all at full speed and in foul weather. Fit [amber]engine spares[/amber] aloft, or have the mechanics at a mast overhaul them.",
                "[amber]Coffee & cocoa[/amber] keeps the watch awake: two days without it and the crew is asleep on its feet. [amber]Fur flying suits[/amber], one each, keep them alive in the far north. [amber]Pilot balloons[/amber] find kinder winds aloft, and kinder winds save petrol.",
            ]),
            TitleCard.Page(heading: "The Pole", paragraphs: [
                "At the North Pole you must choose your height. Climb [amber]above the fog[/amber] into clear, bitter air, where the sun bakes a little gas out of her every watch, or stay [amber]under it[/amber], where in May and June it is warmer, but the fog freezes on everything and hides pressure ridges as tall as houses.",
                "The calendar matters. Leave Rome in April and the Arctic is still iron-cold; leave in July and the summer fog has settled on the ice. May is the month.",
                "Speed matters too. Full speed gets you there sooner, if the petrol lasts. Over the ice, on one tankful, it usually doesn't.",
            ]),
        ],
        roleHeading: "Who are you?",
        roleIntro: "A flight to the Pole in 1926 took money, nerve or know-how, and seldom all three at once. Which do you bring?",
        differencesAction: "What does each one bring?",
        differencesHeading: "What each one brings",
        differences: [
            "An airship burns money by the tonne, and only one of these three has much of it.",
            "[amber]Financier[/amber] — starts with $1,200.",
            "[amber]Airship engineer[/amber] — starts with $580. Gets far more out of every bag of ballast and every box of engine spares.",
            "[amber]Meteorologist[/amber] — starts with $470. Reads the winds aloft like a morning paper: a surer eye with a pilot balloon, and twice the petrol's worth of winds from every session.",
            "The leaner the purse, the more a landing at Nome is worth: the engineer's counts double, the meteorologist's triple.",
        ],
        namesHeading: "Airship & crew",
        vesselPrompt: "Name your airship:",
        vesselLabel: "Airship's name",
        leaderPrompt: "Your name, Captain:",
        leaderLabel: "Captain's name",
        crewPrompt: "Your four crew members:",
        crewLabel: "Crew member",
        monthHeading: "When will you cast off?",
        monthIntro: "Five mooring masts stand ready between Rome and Spitsbergen, the hydrogen cylinders are stacked at Kings Bay, and the newspapers are running out of patience. When will you leave?",
        monthAdvice: "The old balloonist on the bench outside the shed knocks out his pipe. “Go in April and the cold up there will freeze your crew to their seats. Go in July and the summer fog will freeze to your envelope instead. Go in May, when the sun never sets up north and the air is clear. June, if you must. Any later and you may be walking home.”",
        outfitHeading: "Fitting out",
        outfitIntro: { "You have [amber]$\(formatNumber($0.money))[/amber] to fit out the [i]\(Markup.escape($0.ship))[/i]. The stores at the Ciampino works have what you need:" },
        outfitBullets: [
            "• [b]Petrol[/b] — cruising, she burns 250 kg a watch and covers up to 250 km on it in still air, less against the wind. Rome to Pulham is 1,700 km. The tanks hold 8,000 kg, and petrol costs more at every mast north of here.",
            "• [b]Provisions & drinking water[/b] — on full rations, five people eat 1.5 kg and drink 3 litres a watch.",
            "• [b]Coffee & cocoa[/b] — a tin lasts five people ten watches. Two days without it and the crew is asleep on its feet.",
            "• [b]Fur flying suits[/b] — one per person, or the polar cold will kill them.",
            "• [b]Water ballast & engine spares[/b] — the only way to make repairs aloft.",
            "• [b]Medicine & pilot balloons[/b] — a box holds ten balloons, each one a look at the winds aloft.",
        ],
        enterShop: "Enter the stores",
        rankLegend: "Commander 7,000+ · Navigator 4,000+ · Rigger 2,000+ · Ballast")

    static func words(_ g: GameState) -> Words {
        let pace = journey.pace(g.pace), rations = journey.rations(g.rations)
        let n = g.living.count
        let home = journey.stops.first?.name ?? ""
        let title = journey.role(g.role).title
        let article = title.first.map { "aeiou".contains($0) } == true ? "an" : "a"
        // The engine's finale: the landing, then the town and who climbs down.
        let finale = Airship.finale(g).components(separatedBy: "\n\n")
        let dry = g.fuel <= 0 && g.day > 0
        return Words(
            setOut: "Head north",
            halt: "Stop the engines & take stock",
            carryOn: "Continue the flight",
            supplies: "Check supplies & crew",
            chart: "Look at the chart",
            changePace: "Change speed",
            changeRations: "Change rations",
            rest: "Stop the engines and rest",
            repairs: "Make repairs aloft",
            forage: "Send up pilot balloons",
            leavePort: "Cast off",
            restInPort: "Rest at the mast",
            trade: "Barter with the ground crew",
            talk: "Talk to people",
            buy: "Buy supplies",
            yard: "Visit the gas plant and the mechanics",
            statusNames: [.water: "Water"],
            travelled: "Flown",
            distanceUnit: "km",
            distance: { formatNumber(Double($0)) },
            meters: ("Lift", "Engines"),
            clock: nil,
            trouble: nil,
            cash: "Cash",
            currency: "$",
            storeNames: [.clothes: "Fur suits"],
            looseUnits: [.tackle: "balloons"],
            looseOne: [.tackle: "balloon"],
            fractional: [.limes],
            singular: true,
            lots: [.water, .fuel],
            departRefusal: g.fuel <= 0
                ? "You can't cast off with empty tanks! The storekeeper shakes his head and points you back to the petrol."
                : nil,
            resumesInFirstShop: true,
            vesselHeading: "The \(g.ship)",
            suppliesNote: "Speed: \(pace.name) · Rations: \(rations.name)"
                + (g.noCitrus > 6 ? " · [red]\(watches(g.noCitrus)) without coffee[/red]" : "")
                + (dry ? " · [red]the tanks are dry[/red]" : ""),
            crewHeading: "Crew · health \(g.healthLabel.text)",
            leaderTag: "captain",
            clothesWarning: g.clothes < n ? "[red]Only \(g.clothes) of \(n) aboard have a fur suit.[/red]" : nil,
            lostHeading: "Lost on the flight",
            paceHeading: "Speed",
            paceNow: "The engines are set for [amber]\(pace.name)[/amber]."
                + (dry ? " [red]With the tanks dry, it makes no difference.[/red]" : ""),
            rationsHeading: "Rations",
            rationsNow: "The crew is on [amber]\(rations.name)[/amber]. With \(n) aboard, that's \(tenth(Double(n) * rations.amount)) kg a watch.",
            restPrompt: g.atPort ? "The ground crew holds her on the mast while your people sleep in beds that keep still. How long will you stay?"
                                 : "You stop the engines and the crew sleeps in turns, wrapped in everything they own. How long will you rest?",
            restChoice: { span($0) },
            repairsHeading: "Repairs aloft",
            repairsNote: "Each repair takes a watch." + (g.role == .shipwright ? " As an airship engineer, your repairs go much further." : ""),
            mend: "Fit engine spares — 1 box [dim](have \(g.sailcloth))[/dim]",
            patch: "Drop a bag of ballast [dim](have \(g.timber))[/dim]",
            yardHeading: "Gas plant & mechanics",
            yardIntro: "You have [amber]$\(formatNumber(g.money))[/amber]. Each job takes a watch.",
            yardHull: { "Top up the gas — $\($0)" },
            yardSails: { "Overhaul the engines — $\($0)" },
            leaveYard: "Back to the mast",
            priceNote: { "Everything here runs about \($0)% dearer than in \(home), give or take what had to come by ship." },
            burial: { "The crew wraps \($0) in a blanket and lays them gently along the keel, to be buried properly when the ship comes down. What words will you say?" },
            commit: "Say a few words",
            gameOverLine: "\(g.dateText) · \(formatNumber(Double(g.mile))) kilometres from \(home).",
            arrival: finale.first ?? "",
            arrivalBody: finale.dropFirst().joined(separator: "\n\n"),
            bonus: "Bonus for being \(article) \(title)",
            again: "Fly again",
            thanks: "Thanks for flying.")
    }

    static let debug = DebugSkin(
        start: { stop, month in
            // May unless the month asked for is one she can leave in.
            let d = journey.departures.first { $0.month == month } ?? (year: 1926, month: 4)
            var s = GameState(journey: Airship.id, role: .merchant, ship: "Kittiwake", captain: "Leif",
                              crew: ["Rosa", "Olav", "Edith", "Natale"], startYear: d.year, startMonth: d.month)
            s.stopIndex = stop - 1
            s.mile = journey.stops[stop].mile - 10
            s.day = s.mile / 190
            s.fuel = 5000
            s.water = 200
            s.food = 150
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
            ("France by night", true, { $0.mile = 1200; $0.day = 3; $0.fuel = 3000 }),
            ("Midnight sun", true, { $0.mile = 6000; $0.day = 4; $0.fuel = 3000 }),
            ("Rome", false, { $0.atPort = true }),
            ("Pulham", false, { at(&$0, "pulham", port: true) }),
            ("Oslo", false, { at(&$0, "oslo", port: true) }),
            ("Vadsø", false, { at(&$0, "vadso", port: true) }),
            ("Kings Bay", false, { at(&$0, "kingsbay", port: true) }),
            ("Rhône valley", false, { at(&$0, "rhone") }),
            ("Arctic Circle", false, { at(&$0, "circle") }),
            ("Bear Island", false, { at(&$0, "bear") }),
            ("North Pole", false, { at(&$0, "pole") }),
            ("Point Barrow", false, { at(&$0, "barrow") }),
            ("Cape Prince of Wales", false, { at(&$0, "wales") }),
            ("Nome", false, { at(&$0, "nome") }),
            ("France", true, { $0.mile = 1200; $0.fuel = 3000 }),
            ("North Sea", true, { $0.mile = 2200; $0.fuel = 3000 }),
            ("Scandinavia", true, { $0.mile = 3300; $0.fuel = 3000 }),
            ("Barents Sea", true, { $0.mile = 4700; $0.fuel = 3000 }),
            ("Polar Sea", true, { $0.mile = 6000; $0.fuel = 3000 }),
            ("Above the fog", true, { $0.mile = 7500; $0.fuel = 3000 }),
            ("Alaskan coast", true, { $0.mile = 9000; $0.fuel = 3000 }),
            ("Drifting", true, { $0.mile = 2200; $0.day = 9 }),
            ("Engines 10%", true, { $0.sails = 10; $0.fuel = 3000 }),
            ("Lift 10%", true, { $0.hull = 10; $0.fuel = 3000 }),
        ])

    /// Standing at a stop, its arrival told: moored, if it has a mast and `port` says so.
    static func at(_ s: inout GameState, _ id: String, port: Bool = false) {
        guard let i = journey.stops.firstIndex(where: { $0.id == id }) else { return }
        s.stopIndex = i
        s.mile = journey.stops[i].mile
        s.day = max(1, s.mile / 190)
        s.fuel = 3000
        s.atPort = port
    }
}
