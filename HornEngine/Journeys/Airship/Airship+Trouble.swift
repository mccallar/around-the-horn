#if os(WASI)
import FoundationEssentials
#else
import Foundation
#endif

// Lift and the engines at nothing (docs/journeys/airship.md, "As built", D14).
//
// Engines that show 0% have given out: she drifts like a free balloon, burning no petrol,
// until a box of spares goes into them aloft or a mast overhauls them (Airship.swift's
// `adjustSpeed` and `fuelBurn`). Lift that shows 0% sends her down: before another watch is
// flown something heavy goes over the side, a bag of ballast or, dearer, a dump of petrol,
// or, over a mast, the ground crew walks her in. With none of those she is forced down, and
// the flight is over.

extension Airship {
    /// A meter showing 0%, as the status box rounds it, has given out.
    static func givenOut(_ x: Double) -> Bool { jsRound(x) <= 0 }

    /// Both engines have given out: she is a free balloon until they are mended.
    public static func enginesOut(_ s: GameState) -> Bool { givenOut(s.sails) }

    /// The lift is gone and she is going down.
    public static func goingDown(_ s: GameState) -> Bool { givenOut(s.hull) }

    /// The crew is told, once, when the engines give out (`adjustSpeed` forgets it once they
    /// run again).
    func sayEnginesOut(_ e: GameEngine, _ q: inout [Interrupt]) {
        guard !e.state.over, Self.enginesOut(e.state), e.state.vars[AirshipData.enginesOutKey] != 1 else { return }
        e.state.vars[AirshipData.enginesOutKey] = 1
        q.append(.message("[red]The engines have given out.[/red] The mechanics have both of them in pieces on the catwalk, and until a box of spares goes into them, or a mast's mechanics get at them, she is a free balloon, going where the wind goes."))
    }

    enum Meter { case lift, engines }

    /// Damage to the lift (`hull`) or the engines (`sails`), never past nought, and the red
    /// note that says so: the drops the status box will show, in the order given, or nothing
    /// when it shows none.
    func knock(_ e: GameEngine, _ hits: [(Meter, Int)]) -> String {
        var said: [String] = []
        for (meter, d) in hits {
            let before = meter == .lift ? e.state.hull : e.state.sails
            let after = max(0, before - Double(d))
            if meter == .lift { e.state.hull = after } else { e.state.sails = after }
            let shown = Int(jsRound(before)) - Int(jsRound(after))
            if shown > 0 { said.append("\(meter == .lift ? "Lift" : "Engines") −\(shown)%") }
        }
        return said.isEmpty ? "" : " [red](\(said.joined(separator: ", ")))[/red]"
    }

    /// After something has taken lift: if it is gone, what goes over the side.
    func checkLift(_ e: GameEngine, _ q: inout [Interrupt]) {
        if !e.state.over && Self.goingDown(e.state) { q += sinking(e) }
    }

    /// The mast she is over: at its kilometre, with it behind her.
    static func overMast(_ e: GameEngine) -> Port? {
        let stop = e.state.currentStop
        return stop.type == .port && e.state.mile == stop.mile ? e.journey.port(stop.id) : nil
    }

    // MARK: - Going down

    func sinking(_ e: GameEngine) -> [Interrupt] {
        let s = e.state
        let mast = Self.overMast(e)
        let canDrop = s.timber >= 1
        let canDump = s.fuel >= AirshipData.dumpPetrol
        // The mast's store sells ballast; without the price of a bag, mooring only puts off
        // the end.
        let canMoor = mast.map { canDrop || canDump || s.money >= $0.price(.timber) } ?? false
        guard canDrop || canDump || canMoor else { return downForGood(e, at: mast) }

        let ship = "[i]\(TextMarkup.escape(s.ship))[/i]"
        let dump = Int(AirshipData.dumpPetrol)
        var kinds = ["ballast", "petrol"]
        var options: [ChoiceEvent.Option] = [
            .init("Drop a bag of ballast [dim](have \(s.timber))[/dim]", enabled: canDrop),
            .init("Open the dump valves: \(dump) kg of petrol [dim](have \(formatNumber(s.fuel)) kg)[/dim]", enabled: canDump),
        ]
        let have = "[dim]You have $\(Int(s.money)).[/dim]"
        if let mast {
            kinds.append("mast")
            options.append(.init("Let the ground crew walk her in to the mast", enabled: canMoor))
            return [e.ask("sinking", kinds,
                          prompt: "[red]She is going down.[/red] The last of her lift is gone, and the \(ship) is settling toward the field below the mast at \(mast.name). The ground crew is already running for her lines.",
                          detail: "They can hold her on the mast while you buy ballast or top up the gas, or something heavy can go over the side here and now.\n\(have)",
                          options: options)]
        }
        let below = s.region.has("pack") ? "the ice" : s.region.has("sea") ? "the sea" : "the ground"
        return [e.ask("sinking", kinds,
                      prompt: "[red]She is going down.[/red] The last of her lift is gone, and the \(ship) is sinking toward \(below), slowly at first.",
                      detail: "Something heavy has to go over the side, and soon. A bag of ballast is what it is for. Petrol will do, but nobody can meter a dump valve in a hurry, and it is the petrol you will miss.",
                      options: options)]
    }

    /// Nothing aboard to throw over the side, and no mast to hold her (or not the price of a
    /// bag of ballast at the one below).
    func downForGood(_ e: GameEngine, at mast: Port?) -> [Interrupt] {
        e.state.hull = 0
        e.state.over = true
        if let mast {
            return [.gameOver(title: "Grounded at \(mast.name).",
                              body: "With no lift left in her, nothing aboard worth throwing over the side and not the price of a bag of ballast in your pocket, the [i]\(TextMarkup.escape(e.state.ship))[/i] is walked into the shed at \(mast.name), deflated and folded up to go home as freight. The expedition is over.")]
        }
        return [.gameOver(title: wreckedTitle(e.state), body: wreckedBody(e.state))]
    }

    func answerSinking(_ e: GameEngine, _ args: [String], _ option: Int) -> [Interrupt] {
        guard args.indices.contains(option), Self.goingDown(e.state), !e.state.over else { return [] }
        switch args[option] {
        case "ballast": return e.patchHull()
        case "petrol": return dumpPetrol(e)
        case "mast":
            guard Self.overMast(e) != nil else { return [] }
            e.state.atPort = true
            return [.enterPort]
        default: return []
        }
    }

    /// The dump valves: a watch to trim her and settle the crew's nerves.
    func dumpPetrol(_ e: GameEngine) -> [Interrupt] {
        guard e.state.fuel >= AirshipData.dumpPetrol else { return [] }
        e.state.fuel -= AirshipData.dumpPetrol
        e.state.hull = min(100, e.state.hull + AirshipData.dumpLift)
        var q = e.passDays(1, .sea)
        if !e.state.over {
            let kg = Int(AirshipData.dumpPetrol), lift = Int(jsRound(e.state.hull))
            q.append(.message("The engineer opens the dump valves, and \(kg) kg of petrol go over the side in a long glittering spray. Lighter by that much, she checks her fall and climbs. [green](Lift now \(lift)%)[/green]"))
        }
        return q
    }
}
