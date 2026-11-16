#if os(WASI)
import FoundationEssentials
#else
import Foundation
#endif

// The outfit, the boat and what moves them at nothing (docs/journeys/klondike.md, "As
// built", D14).
//
// Sleds that show 0% (and, once the boat is built, oars & sail) have given out: there is no
// moving a ton of outfit along the trail without them, and a boat with no sweep to steer by
// is tied to the bank. The party stays where it is until they are mended: with a coil of rope
// & rawhide from the stores, with one bought off the next party along, or with two days'
// work making do (pack boards from empty crates on the trail, a sweep cut from a spruce on
// the river), which is always possible. Miles Canyon and Five Fingers, reached as the oars
// give out, wait until there is a sweep. An outfit or a boat that shows 0% is ruined or
// breaks up, which ends the run, as the spec has always had it. The steamer carries the
// party whatever its sleds are like.

extension Klondike {
    /// A meter showing 0%, as the status panel rounds it.
    static func showsNought(_ x: Double) -> Bool { jsRound(x) <= 0 }

    /// The sleds, or the oars & sail, show 0% off the steamer: the party cannot move.
    public static func givenOut(_ s: GameState) -> Bool { leg(s) != .steamer && showsNought(s.sails) }

    /// No firewood where the party needs a fire (anywhere but aboard the steamer): every day
    /// without one costs each of them 12 health.
    public static func noFire(_ s: GameState) -> Bool { leg(s) != .steamer && s.water <= 0 }

    enum Meter { case structure, drive }

    /// Damage to the outfit or the boat (`hull`) or to the sleds or the oars & sail (`sails`),
    /// never past nought, and the part of the red note that says so: the drop the status panel
    /// will show ("Outfit −6%"), or nil when it shows none. An outfit or a boat left showing
    /// 0% is put at nothing, so that `checkSink` ends the run.
    func knock(_ e: GameEngine, _ meter: Meter, _ d: Int) -> String? {
        let before = meter == .structure ? e.state.hull : e.state.sails
        var after = before - Double(d) > 0 ? before - Double(d) : 0
        if meter == .structure && Self.showsNought(after) { after = 0 }
        if meter == .structure { e.state.hull = after } else { e.state.sails = after }
        let shown = Int(jsRound(before)) - Int(jsRound(after))
        guard shown > 0 else { return nil }
        let names = Self.meterNames(e.state)
        return "\(meter == .structure ? names.structure : names.drive) −\(shown)%"
    }

    /// The red note at the end of a line: " [red](Sleds −15%, Outfit −6%)[/red]", or nothing
    /// when nothing shows.
    static func red(_ parts: [String?]) -> String {
        let shown = parts.compactMap { $0 }
        return shown.isEmpty ? "" : " [red](\(shown.joined(separator: ", ")))[/red]"
    }

    // MARK: - Set pieces that need a sweep

    static let needsASweep = ["canyon", "fivefinger"]

    /// The set piece reached as the oars gave out, waiting for a sweep.
    func heldStop(_ s: GameState) -> Stop? {
        guard let i = s.vars[KlondikeData.heldKey].map({ Int($0) }), stops.indices.contains(i) else { return nil }
        return stops[i]
    }

    static func waiting(_ stop: Stop) -> String {
        stop.id == "canyon" ? "Nobody takes a boat into Miles Canyon without a sweep."
            : "Nobody takes a boat through Five Fingers without a sweep."
    }

    /// Reaching Miles Canyon or Five Fingers with the oars given out: it waits.
    func hold(_ e: GameEngine, _ stop: Stop) -> [Interrupt] {
        guard let i = stops.firstIndex(where: { $0.id == stop.id }) else { return [] }
        e.state.vars[KlondikeData.heldKey] = Double(i)
        let boat = "[i]\(TextMarkup.escape(e.state.ship))[/i]"
        return [.message("The \(boat) comes down to \(stop.name) with no sweep to steer by, and you tie her up to the bank above the fast water. \(Self.waiting(stop))")]
    }

    // MARK: - Before a day under way

    /// An outfit or a boat at nothing ends it; given-out sleds or oars are asked about; once
    /// they are mended, a set piece that waited is met. Asking takes no time and draws nothing.
    func trouble(_ e: GameEngine) -> [Interrupt]? {
        let s = e.state
        if s.over { return nil }
        if Self.showsNought(s.hull) {
            // An older save, or anything else that left it there: it goes before another day.
            var q: [Interrupt] = []
            e.state.hull = 0
            e.checkSink(&q)
            return q
        }
        if Self.givenOut(s) { return [givenOutQuestion(e, heldStop(s))] }
        guard let stop = heldStop(s) else { return nil }
        e.state.vars[KlondikeData.heldKey] = nil
        let q = setPiece(e, stop)
        return q.isEmpty ? nil : q
    }

    func givenOutQuestion(_ e: GameEngine, _ held: Stop?) -> Interrupt {
        let s = e.state
        let boat = Self.hasBoat(s)
        let price = Int(KlondikeData.coilPrice)
        var kinds = ["mend"]
        var options: [ChoiceEvent.Option] = [
            .init(boat ? "Re-rig the oars & sail: 1 coil of rope & rawhide [dim](have \(s.sailcloth))[/dim]"
                       : "Mend the sleds: 1 coil of rope & rawhide [dim](have \(s.sailcloth))[/dim]",
                  enabled: s.sailcloth >= 1),
        ]
        let buy = s.sailcloth < 1
        if buy {
            kinds.append("buy")
            options.append(.init("Buy a coil off the next \(boat ? "boat" : "party") along ($\(price))",
                                 enabled: s.money >= KlondikeData.coilPrice))
        }
        kinds += ["makeDo", "stock"]
        options += [
            .init(boat ? "Cut a sweep and oars from a spruce on the bank (2 days)"
                       : "Lash up pack boards from empty crates and sacking (2 days)"),
            .init("Take stock first"),
        ]
        let name = "[i]\(TextMarkup.escape(s.ship))[/i]"
        var prompt = boat
            ? "[red]The oars and sail have given out.[/red] With no sweep to steer by, the \(name) goes wherever the water likes, so you work her into the bank and tie up. She stays there until she is re-rigged."
            : "[red]Your sleds have given out.[/red] Split runners, knotted straps, harness in pieces: there is no moving a ton of outfit along the trail until they are mended."
        if let held { prompt += " " + Self.waiting(held) }
        let points = Int(KlondikeData.makeDoPoints)
        var detail = boat ? "A coil of rope & rawhide re-rigs her in a day." : "A coil of rope & rawhide mends them in a day."
        if buy {
            detail += boat
                ? " Boats go by all day, and somebody in one will part with a coil for $\(price), three times the Seattle price."
                : " The trail is never empty, and somebody on it will sell you a coil for $\(price), three times the Seattle price."
        }
        detail += boat
            ? " Or you can cut a new sweep and a pair of oars from a spruce on the bank: two days' work, and they will barely do (Oars & sail \(points)%)."
            : " Or you can lash up pack boards from the crates you have already emptied: two days' work, for gear that will barely hold (Sleds \(points)%)."
        if buy { detail += "\n[dim]You have $\(formatNumber(s.money)).[/dim]" }
        return e.ask("givenout", kinds, prompt: prompt, detail: detail, options: options)
    }

    func answerGivenOut(_ e: GameEngine, _ args: [String], _ option: Int) -> [Interrupt] {
        guard args.indices.contains(option), Self.givenOut(e.state), !e.state.over else { return [] }
        let boat = Self.hasBoat(e.state)
        switch args[option] {
        case "mend": return e.mendSails()
        case "buy":
            guard e.state.sailcloth < 1, e.state.money >= KlondikeData.coilPrice else { return [] }
            e.state.money -= KlondikeData.coilPrice
            e.state.sailcloth += 1
            let line = boat ? "A boat drifting by pulls in long enough to sell you a coil of rope, at their price."
                : "A packer coming down the trail with an empty sled sells you a coil of his rope, at his price."
            return [.message(line)] + e.mendSails()
        case "makeDo": return makeDo(e)
        case "stock": return [.enterPort]
        default: return []
        }
    }

    /// Two days of hard work, as the trail counts it, for gear that will barely do.
    func makeDo(_ e: GameEngine) -> [Interrupt] {
        let boat = Self.hasBoat(e.state)
        var q = haulDays(e, KlondikeData.makeDoDays)
        if e.state.over { return q }
        e.state.sails = min(100, e.state.sails + KlondikeData.makeDoPoints)
        let now = Int(jsRound(e.state.sails))
        q.append(.message(boat
            ? "Two days with an axe and a drawknife turn a spruce on the bank into a sweep and a pair of oars, green and heavy. She answers again, more or less. [green](Oars & sail now \(now)%)[/green]"
            : "Two days of knocking crates apart and lacing sacking into straps. The pack boards are ugly and they creak, but they carry. [green](Sleds now \(now)%)[/green]"))
        return q
    }
}
