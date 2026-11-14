import Foundation

// The four places a freighter can tie up, and the cycler, which will not stop for you.

extension Mars {
    /// Food is dear on the cycler and cheap at Phobos; propellant is cheap at Midway and
    /// dear at Phobos; repairs are cheapest at Phobos.
    static let stations: [Port] = [
        Port(id: "gateway", journey: Mars.id, name: "Gateway Yard", shop: "Gateway Yard Chandlery", mult: 1,
             arrive: "",
             talk: [
                 "The yard boss does not look up from her slate. \"Cruise burns a tonne of propellant a day. Your tanks hold a hundred. That will not get you to Mars and nobody pretends it will: fill up on the Perpetua and again at Midway.\"",
                 "A tug pilot eating noodles out of a bag: \"Two old comet streams cross the arc, at 80 to 110 million km and again at 340 to 370. Take a grapple and a few cartridges. Ice is water, and water costs money everywhere but there.\"",
                 "A forecaster on her break: \"The Sun is building to a maximum next spring. Leave in August and it's calm, but the planets are badly placed and it's a long trip. Leave in December and it's a long trip through the storms. October is the window.\"",
                 "The quartermaster holds up a thermal suit. \"One each. The heat runs off the same power as the drive. When the panels go, the warmth goes with them, and faster than you would think.\"",
             ]),
        Port(id: "cycler", journey: Mars.id, name: "the cycler Perpetua", shop: "The Perpetua's stores", mult: 1.2,
             mods: [.food: 1.6, .water: 0.4],
             arrive: "The Perpetua comes up out of the dark exactly on time, as she has every twenty-six months for forty years: a turning wheel of habitat, a spine of tanks, and an ice shield like a dirty snowball. She never stops. You latch on and ride along for as long as you like.",
             talk: [
                 "A dockhand counting crates: \"Rations are dear here. Everything we eat came up from Earth the long way round. Water is nearly free: we carry it as shielding and we have plenty.\"",
                 "An engineer in the gravity ring: \"Past 240 million km the Sun gets thin. Your wings work harder and wear faster out there. Carry panels, or carry a coat.\"",
                 "A pilot waiting for her own ride home: \"At turnover you can burn on four more days and brake hard at the end. It's worth about four days and costs eight tonnes. Drives don't love it, and a tired one loves it less.\"",
                 "The station doctor: \"A supplement pack keeps one person going fifty days. Run out and you'll feel it in your bones within the month, and a bone that breaks out there takes a long time to knit.\"",
             ]),
        Port(id: "midway", journey: Mars.id, name: "Midway Depot", shop: "Midway Depot stores", mult: 1.6,
             mods: [.fuel: 0.4],
             arrive: "Three tanks, a habitat can and a light in one window. Midway's two keepers have not seen a third face in a year, and they talk over each other to tell you so. The propellant is cheap. Everything else came a long way to get here.",
             talk: [
                 "The older keeper taps a tank gauge. \"Fill up. Phobos charges the earth for propellant, and if your hull isn't fit to aerobrake you'll want ten tonnes at Mars for a capture burn.\"",
                 "The younger keeper: \"Past 370 million the Sun gets between you and home. No forecasts. If the counters start chattering, get in the core. Don't wait for a warning. There won't be one.\"",
                 "\"Aerobraking is free and quick, and it is very hard on a hull. Under sixty in the hundred, I'd pay for the burn.\"",
                 "\"The second ice stream starts at 340 million, not far ahead. Worth a grapple. Nobody gives water away at Phobos.\"",
             ]),
        Port(id: "phobos", journey: Mars.id, name: "Phobos Yard", shop: "Phobos Yard supply", mult: 0.8,
             mods: [.food: 0.7, .fuel: 2.2, .water: 1.2],
             arrive: "Phobos Yard is dug into the side of a moon so small you could throw a ball clean off it, and some of the yard crew have. Mars fills half the sky, rust and butterscotch. Repairs are cheap here, and so is food: the settlements grow more than they eat.",
             talk: [
                 "A yard foreman: \"Seven million km to Jezero and then down. Get her fixed while you're here. We're the cheapest yard between here and Earth.\"",
                 "A grower from the settlement, selling greens off a tray: \"Rations are cheap. Propellant isn't: it comes up from the surface a little at a time.\"",
                 "A traffic controller: \"Jezero takes you whenever you come in. The contract bonus stops at day 170, but nobody down there turns away cargo.\"",
             ]),
    ]

    /// The cycler asks before it is a port; a station pays what a grateful ship wired.
    func stationArrival(_ e: GameEngine, _ stop: Stop) -> [Interrupt]? {
        guard stop.type == .port else { return nil }
        if stop.id == "cycler" {
            return [e.ask("cycler", [stop.id],
                          prompt: "The cycler Perpetua is coming up on her endless loop between the planets. She will not slow down for you.",
                          detail: "Matching orbits to dock costs \(MarsData.tonnes(MarsData.dockBurn)) of propellant. Her stores are open to anyone who does.\n[dim]You have \(MarsData.tonnes(e.state.fuel)).[/dim]",
                          options: [.init("Match and dock (\(MarsData.tonnes(MarsData.dockBurn)))", enabled: e.state.fuel >= MarsData.dockBurn),
                                    .init("Wave as she goes by")])]
        }
        return paid(e) + e.portArrival(stop)
    }

    /// Money a ship you helped has wired, collected at the next port.
    func paid(_ e: GameEngine) -> [Interrupt] {
        let owed = e.state.vars[MarsData.owedKey] ?? 0
        guard owed > 0 else { return [] }
        e.state.vars[MarsData.owedKey] = 0
        e.state.money += owed
        return [.message("A transfer is waiting for you, with a note: [i]for the help, with thanks.[/i] [green]+$\(Int(owed)).[/green]")]
    }

    func answerCycler(_ e: GameEngine, _ args: [String], _ option: Int) -> [Interrupt] {
        guard let id = args.first, let stop = e.journey.stop(id) else { return [] }
        if option == 0 {
            e.state.fuel = max(0, e.state.fuel - MarsData.dockBurn)
            return [.message("A long, careful burn, a lot of small corrections, and the latches close with a clunk you feel in your teeth.")]
                + paid(e) + e.portArrival(stop)
        }
        return [.message("The Perpetua slides past a few kilometres off, lit up like a town at night. Somebody in her observation ring waves. Everybody waves back.")]
    }
}
