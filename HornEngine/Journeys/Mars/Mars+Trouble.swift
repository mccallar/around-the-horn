#if os(WASI)
import FoundationEssentials
#else
import Foundation
#endif

// Power, the pressure hull and the propellant at nothing (docs/journeys/mars.md, "As built",
// D14).
//
// Power & drive that shows 0% is dark: the drive has nothing to run on, so she coasts along
// the arc as she does with the tanks dry and burns no propellant; the recycler stops, so the
// water lost each day doubles; and the cabin is as cold as it gets. Before every day in the
// dark she is asked what is to be done: a spare panel, a rewiring of what is left of the wings
// (always possible: two days in suits for a tenth of the power), a day's coast as she is, or
// the menu. A set piece she reaches in the dark waits until there is power. A pressure hull
// that shows 0% has let go, which ends the run, as the spec has always had it. With the tanks
// dry she coasts at the shared `noFuelSpeed`, the last of the propellant burning its share of
// the day; with nothing for the thrusters that keep her pointed, she tumbles slowly and the
// wings wear.

extension Mars {
    /// A meter showing 0%, as the status panel rounds it, has given out.
    static func givenOut(_ x: Double) -> Bool { jsRound(x) <= 0 }

    /// Power & drive shows 0%: no drive, no recycler, no heat.
    public static func dark(_ s: GameState) -> Bool { givenOut(s.sails) }

    /// Some propellant aboard, but less than a day at this burn takes: it drives only part
    /// of one.
    public static func lastOfThePropellant(_ s: GameState) -> Bool {
        s.fuel > 0 && s.fuel < Journeys.journey(id).pace(s.pace).fuel
    }

    /// Under way with no thrust at all: the array dark or the tanks dry.
    public static func coasting(_ s: GameState) -> Bool { !s.atPort && (dark(s) || s.fuel <= 0) }

    enum Meter { case hull, power }

    /// Damage to the pressure hull or to power & drive, never past nought, and the red note
    /// that says so: the drop the status panel will show, or nothing when it shows none. A
    /// hull left showing 0% has let go, and is put at nothing for `checkSink`.
    func knock(_ e: GameEngine, _ meter: Meter, _ d: Int) -> String {
        let before = meter == .hull ? e.state.hull : e.state.sails
        var after = max(0, before - Double(d))
        if meter == .hull && Self.givenOut(after) { after = 0 }
        if meter == .hull { e.state.hull = after } else { e.state.sails = after }
        let shown = Int(jsRound(before)) - Int(jsRound(after))
        return shown > 0 ? " [red](\(meter == .hull ? "Pressure hull" : "Power & drive") −\(shown)%)[/red]" : ""
    }

    /// An accident takes health from one of the crew, never below 1: what kills is the day
    /// that follows, as the shared rules count it.
    static func hurt(_ e: GameEngine, _ idx: Int, _ hp: Double) {
        e.state.crew[idx].hp = max(1, e.state.crew[idx].hp - hp)
    }

    // MARK: - The pressure hull

    /// A hull that shows 0% has let go: the run is over.
    func hullLetsGo(_ e: GameEngine) -> [Interrupt] {
        e.state.hull = 0
        e.state.over = true
        return [.gameOver(title: wreckedTitle(e.state), body: wreckedBody(e.state))]
    }

    // MARK: - The array dark

    /// The set pieces that need a drive: matching orbits with the cycler, turning end for end,
    /// and meeting Mars.
    static let needsTheDrive = ["cycler", "turnover", "approach"]

    /// The set piece reached in the dark, waiting for power.
    func heldStop(_ s: GameState) -> Stop? {
        guard let i = s.vars[MarsData.heldKey].map({ Int($0) }), stops.indices.contains(i) else { return nil }
        return stops[i]
    }

    /// What a dark ship cannot do at a set piece.
    static func waiting(_ stop: Stop) -> String {
        switch stop.id {
        case "cycler": return "The Perpetua is holding her docking window open, and there is no meeting her without a drive."
        case "turnover": return "Turnover is due, and nobody turns a ship end for end without a drive."
        default: return "Mars is coming up, and nobody meets a planet without a drive."
        }
    }

    /// Reaching a set piece in the dark: it waits until there is power.
    func hold(_ e: GameEngine, _ stop: Stop) -> [Interrupt] {
        guard let i = stops.firstIndex(where: { $0.id == stop.id }) else { return [] }
        e.state.vars[MarsData.heldKey] = Double(i)
        let ship = "[i]\(TextMarkup.escape(e.state.ship))[/i]"
        return [.message("The \(ship) reaches \(stop.name) with her array dark. \(Self.waiting(stop))")]
    }

    /// The set piece itself, once there is power to meet it.
    func meet(_ e: GameEngine, _ stop: Stop) -> [Interrupt] {
        stop.id == "cycler" ? [cyclerOffer(e, stop)] : setPiece(e, stop)
    }

    /// Before a day under way: a hull at nothing ends it; a dark array is asked about, unless
    /// a day's coast was chosen for today; with power back, a set piece that waited is met.
    func trouble(_ e: GameEngine) -> [Interrupt]? {
        let s = e.state
        if s.atPort || s.over { return nil }
        if Self.givenOut(s.hull) { return hullLetsGo(e) }
        if Self.dark(s) {
            let held = heldStop(s)
            if held == nil && s.vars[MarsData.coastKey] == Double(s.day) {
                e.state.vars[MarsData.coastKey] = nil
                return nil
            }
            return [darkQuestion(e, held)]
        }
        e.state.vars[MarsData.coastKey] = nil
        guard let stop = heldStop(s) else { return nil }
        e.state.vars[MarsData.heldKey] = nil
        let q = meet(e, stop)
        return q.isEmpty ? nil : q
    }

    func darkQuestion(_ e: GameEngine, _ held: Stop?) -> Interrupt {
        let s = e.state
        let ship = "[i]\(TextMarkup.escape(s.ship))[/i]"
        var kinds = ["panel", "rewire"]
        var options: [ChoiceEvent.Option] = [
            .init("Fit a spare array panel [dim](have \(s.sailcloth))[/dim]", enabled: s.sailcloth >= 1),
            .init("Rewire what is left of the wings: two days in suits"),
        ]
        if held == nil {
            kinds.append("coast")
            options.append(.init("Coast on in the dark for a day"))
        }
        kinds.append("stock")
        options.append(.init("Take stock first"))
        let dark = "[red]The array has gone dark.[/red] The drive is dead, the recycler has stopped and the cabin is getting colder by the hour."
        let prompt = held.map { "\(dark) \(Self.waiting($0))" }
            ?? "\(dark) The \(ship) coasts on along the arc at the speed she had, which is not much."
        let out = Self.riggers(s).count > 1 ? "two of you" : "you"
        return e.ask("dark", kinds, prompt: prompt,
                     detail: "A spare panel goes in from the truss in a day. Without one, \(out) can go out and rewire what is left of the wings: two days in suits for a tenth of the power, which is enough to run the drive and the recycler. Until then the water lost each day is twice the usual, \(jsNumber(MarsData.darkWater)) litres a head.",
                     options: options)
    }

    /// Who goes out on the truss: the two fittest hands, or the captain to make up two.
    static func riggers(_ s: GameState) -> [Int] {
        let hands = s.crew.indices.filter { s.crew[$0].alive && !s.crew[$0].isCaptain }
            .sorted { s.crew[$0].hp != s.crew[$1].hp ? s.crew[$0].hp > s.crew[$1].hp : $0 < $1 }
        var out = Array(hands.prefix(2))
        if out.count < 2, let you = s.crew.indices.first(where: { s.crew[$0].alive && s.crew[$0].isCaptain }) {
            out.append(you)
        }
        return out
    }

    func answerDark(_ e: GameEngine, _ args: [String], _ option: Int) -> [Interrupt] {
        guard args.indices.contains(option), Self.dark(e.state), !e.state.over, !e.state.atPort else { return [] }
        switch args[option] {
        case "panel": return e.mendSails()
        case "rewire": return rewire(e)
        case "coast":
            guard heldStop(e.state) == nil else { return [] }
            e.state.vars[MarsData.coastKey] = Double(e.state.day)
            return []
        case "stock": return [.enterPort]
        default: return []
        }
    }

    /// Two days on the truss in suits, stripping good cells from dead panels and wiring a
    /// string round everything burnt out: a tenth of the power, and cold, tired riggers.
    func rewire(_ e: GameEngine) -> [Interrupt] {
        let who = Self.riggers(e.state)
        guard !who.isEmpty else { return [] }
        let hands = who.filter { !e.state.crew[$0].isCaptain }.map { TextMarkup.escape(e.state.crew[$0].name) }
        let out = who.count == 1 ? "You suit up and go out along the truss alone"
            : hands.count == 1 ? "You and \(hands[0]) suit up and go out along the truss"
            : "\(hands[0]) and \(hands[1]) suit up and go out along the truss"
        var q: [Interrupt] = [.message("\(out) with a reel of cable, a meter and a flask of something hot.")]
        q += e.passDays(MarsData.rigDays, .sea)
        if e.state.over { return q }
        e.state.sails = min(100, e.state.sails + MarsData.rigPower)
        q.append(.message("Two days later the wings are not mended so much as talked round: one string of cells on each, wired past everything that has burnt out. The drive lights, and so does the recycler. [green](Power & drive now \(Int(jsRound(e.state.sails)))%)[/green]"))
        for i in who where e.state.crew[i].alive {
            Self.hurt(e, i, Double(e.ri(MarsData.rigWear.lowerBound, MarsData.rigWear.upperBound)))
            if e.state.crew[i].ailment == nil && e.chance(MarsData.rigInjury) {
                e.sicken(i, &q, e.state.temperature(in: e.state.region), nil, MarsData.decompression)
            }
        }
        return q
    }
}
