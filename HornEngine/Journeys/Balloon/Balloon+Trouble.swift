#if os(WASI)
import FoundationEssentials
#else
import Foundation
#endif

// Lift and the burners at nothing, and the tanks dry (docs/journeys/balloon.md, "As built",
// D14).
//
// Burners that show 0% have given out: there is no heat for the cone, so she drifts on the
// helium alone and sinks as she does with the tanks dry, burning no propane, until a burner
// kit goes into them aloft or a field's burner man gets at them. The last of the propane heats
// its share of a watch, and the rest of it drifts and sinks. Lift that shows 0% sends her
// down: before another watch is flown something goes over the side, a sack of ballast or,
// dearer, a full propane cylinder, or, over a field, she comes down to its ground team. With
// none of those she comes down for good, and the attempt is over.

extension Balloon {
    /// A meter showing 0%, as the status panel rounds it, has given out.
    static func givenOut(_ x: Double) -> Bool { jsRound(x) <= 0 }

    /// The burners have given out: no heat for the cone until they are mended.
    public static func burnersOut(_ s: GameState) -> Bool { givenOut(s.sails) }

    /// The lift is gone and she is going down.
    public static func goingDown(_ s: GameState) -> Bool { givenOut(s.hull) }

    /// Gallons a watch flown at this altitude in this air burns.
    public static func watchBurn(_ s: GameState) -> Double {
        Journeys.journey(id).pace(s.pace).fuel * BalloonData.burnFactor(s.temperature(in: s.region))
    }

    /// Some propane left, but less than a watch flown here burns: it heats only part of one.
    public static func lastOfThePropane(_ s: GameState) -> Bool { s.fuel > 0 && s.fuel < watchBurn(s) }

    /// The burners can be lit: they have not given out, and there is propane for them.
    static func lit(_ s: GameState) -> Bool { !burnersOut(s) && s.fuel > 0 }

    /// The share of a watch burning `gallons` that the burners can heat: none with them given
    /// out or the tanks dry, the propane's share when there is less than that, else all of it.
    static func heated(_ s: GameState, _ gallons: Double) -> Double {
        if burnersOut(s) { return 0 }
        return gallons > 0 ? min(1, max(0, s.fuel) / gallons) : 1
    }

    /// A watch that burns `gallons` through burners that work, or what there is of them;
    /// returns the share of it that had no heat.
    func burnWatch(_ e: GameEngine, _ gallons: Double) -> Double {
        let heat = Self.heated(e.state, gallons)
        if !Self.burnersOut(e.state) { e.state.fuel = max(0, e.state.fuel - gallons) }
        return 1 - heat
    }

    /// What a watch, or the share of one, without heat costs: the envelope cools and sinks.
    func sink(_ e: GameEngine, _ cold: Double) {
        guard cold > 0 else { return }
        e.state.hull = max(0, e.state.hull - BalloonData.emptyLift * cold)
    }

    /// The note for a watch, or part of one, flown or loitered without heat.
    static func coldNote(_ s: GameState, _ cold: Double) -> String {
        if burnersOut(s) { return "The burners are dead. The balloon is sinking." }
        return cold < 1 ? "The burners sputter out partway through the watch. The balloon is sinking."
            : "The burners are cold. The balloon is sinking."
    }

    /// The crew is told, once, when the burners give out (`adjustSpeed` forgets it once they
    /// burn again).
    func sayBurnersOut(_ e: GameEngine, _ q: inout [Interrupt]) {
        guard !e.state.over, Self.burnersOut(e.state), e.state.vars[BalloonData.burnersOutKey] != 1 else { return }
        e.state.vars[BalloonData.burnersOutKey] = 1
        q.append(.message("[red]The burners have given out.[/red] Every jet is fouled and every igniter dead. Until a burner kit goes into them, or a field's burner man gets at them, there is no heat for the cone: the balloon drifts on the helium alone, and sinks."))
    }

    enum Meter { case lift, burners }

    /// Damage to the lift (`hull`) or the burners (`sails`), never past nought, and the red
    /// note that says so: the drops the status panel will show, in the order given, or
    /// nothing when it shows none.
    func knock(_ e: GameEngine, _ hits: [(Meter, Int)]) -> String {
        var said: [String] = []
        for (meter, d) in hits {
            let before = meter == .lift ? e.state.hull : e.state.sails
            let after = max(0, before - Double(d))
            if meter == .lift { e.state.hull = after } else { e.state.sails = after }
            let shown = Int(jsRound(before)) - Int(jsRound(after))
            if shown > 0 { said.append("\(meter == .lift ? "Lift" : "Burners") −\(shown)%") }
        }
        return said.isEmpty ? "" : " [red](\(said.joined(separator: ", ")))[/red]"
    }

    /// After something has taken lift: if it is gone, what goes over the side.
    func checkLift(_ e: GameEngine, _ q: inout [Interrupt]) {
        if !e.state.over && Self.goingDown(e.state) { q += sinking(e) }
    }

    /// The field she is over: at its mile, with it behind her, and not landed.
    static func overField(_ e: GameEngine) -> Port? {
        let stop = e.state.currentStop
        return !e.state.atPort && stop.type == .port && e.state.mile == stop.mile ? e.journey.port(stop.id) : nil
    }

    static func isSinking(_ i: Interrupt) -> Bool {
        if case .choice(let c) = i, case .custom("sinking", _) = c.kind { return true }
        return false
    }

    // MARK: - Going down

    func sinking(_ e: GameEngine) -> [Interrupt] {
        let s = e.state
        let field = Self.overField(e)
        let canDrop = s.timber >= 1
        let canCut = s.fuel >= BalloonData.cylinder
        // The field's store sells ballast; without the price of a sack, landing only puts off
        // the end.
        let canLand = field.map { canDrop || canCut || s.money >= $0.price(.timber) } ?? false
        guard canDrop || canCut || canLand else { return downForGood(e, at: field) }

        let ship = "[i]\(TextMarkup.escape(s.ship))[/i]"
        var kinds = ["ballast", "propane"]
        var options: [ChoiceEvent.Option] = [
            .init("Cut away a sack of ballast [dim](have \(s.timber))[/dim]", enabled: canDrop),
            .init("Cut away a propane cylinder: \(Int(BalloonData.cylinder)) gallons [dim](have \(formatNumber(s.fuel.rounded(.down))) gallons)[/dim]",
                  enabled: canCut),
        ]
        if let field {
            kinds.append("field")
            options.append(.init("Come down on the field at \(field.name)", enabled: canLand))
            return [e.ask("sinking", kinds,
                          prompt: "[red]She is going down.[/red] The last of the lift is gone, and the \(ship) is settling toward the field at \(field.name). The ground team is already out with the trucks.",
                          detail: "You can come down to them and buy ballast or helium, or something can go over the side here and now.\n[dim]You have $\(formatNumber(s.money.rounded(.down))).[/dim]",
                          options: options)]
        }
        let below = s.region.has("sea") ? "the sea" : "the ground"
        return [e.ask("sinking", kinds,
                      prompt: "[red]She is going down.[/red] The last of the lift is gone, and the \(ship) is sinking toward \(below), slowly at first.",
                      detail: "Something has to go over the side, and soon. A sack of ballast is what it is for. A full propane cylinder will do as well, but it is propane you will want later.",
                      options: options)]
    }

    /// Nothing aboard to cut away, and no field to come down on (or not the price of a sack
    /// of ballast at the one below).
    func downForGood(_ e: GameEngine, at field: Port?) -> [Interrupt] {
        e.state.hull = 0
        e.state.over = true
        if let field {
            return [.gameOver(title: "Grounded at \(field.name).",
                              body: "With no lift left in her, nothing aboard to cut away and not the price of a sack of ballast in your pocket, the [i]\(TextMarkup.escape(e.state.ship))[/i] comes down on the field at \(field.name) for the last time. The ground team folds the envelope into a truck and flies everyone home. The attempt is over.")]
        }
        return [.gameOver(title: wreckedTitle(e.state), body: wreckedBody(e.state))]
    }

    func answerSinking(_ e: GameEngine, _ args: [String], _ option: Int) -> [Interrupt] {
        guard args.indices.contains(option), Self.goingDown(e.state), !e.state.over, !e.state.atPort else { return [] }
        switch args[option] {
        case "ballast": return e.patchHull()
        case "propane": return cutCylinder(e)
        case "field":
            guard Self.overField(e) != nil else { return [] }
            e.state.atPort = true
            return [.enterPort]
        default: return []
        }
    }

    /// A full cylinder over the side, where it can fall on nobody: a watch to pick the place
    /// and trim her.
    func cutCylinder(_ e: GameEngine) -> [Interrupt] {
        guard e.state.fuel >= BalloonData.cylinder else { return [] }
        let below = e.state.region.has("sea") ? "empty sea" : "empty country"
        e.state.fuel -= BalloonData.cylinder
        e.state.hull = min(100, e.state.hull + BalloonData.cylinderLift)
        var q = e.passDays(1, .sea)
        if !e.state.over {
            q.append(.message("The flight engineer waits for \(below) below, then cuts a propane cylinder loose, fifty gallons and all. Lighter by that much, the balloon checks its fall and climbs. [green](Lift now \(Int(jsRound(e.state.hull)))%)[/green]"))
        }
        return q
    }
}
