#if os(WASI)
import FoundationEssentials
#else
import Foundation
#endif

// A train whose engine or running gear has given out (docs/journeys/rail.md,
// "Breakdowns"). She stands where she is until she is mended: with fittings or car spares
// from the train's own stores, by a mechanic somebody walks down the line to fetch, or at
// the roundhouse if she gave out in a yard. With none of those to be had the run ends,
// stranded. Time passes only while something is done about it.

extension Rail {
    /// A meter showing 0%, as the status box rounds it, has given out.
    static func givenOut(_ x: Double) -> Bool { jsRound(x) <= 0 }

    /// The engine or the running gear has given out, and the train cannot move.
    public static func brokenDown(_ s: GameState) -> Bool { givenOut(s.sails) || givenOut(s.hull) }

    /// The damage a road event does to the engine (`sails`) or the running gear (`hull`),
    /// never past nought, and the red note that says so: the drop the status box will
    /// show, or nothing when it shows none.
    func knock(_ e: GameEngine, engine: Bool, _ d: Int) -> String {
        let before = engine ? e.state.sails : e.state.hull
        let after = max(0, before - Double(d))
        if engine { e.state.sails = after } else { e.state.hull = after }
        let shown = Int(jsRound(before)) - Int(jsRound(after))
        return shown > 0 ? " [red](\(engine ? "Engine" : "Running gear") −\(shown)%)[/red]" : ""
    }

    /// Who walks for the mechanic: the fittest of the crew, or the conductor alone.
    static func walker(_ s: GameState) -> Int? {
        let hands = s.crew.indices.filter { s.crew[$0].alive && !s.crew[$0].isCaptain }
        return hands.max { s.crew[$0].hp < s.crew[$1].hp } ?? s.crew.indices.first { s.crew[$0].alive }
    }

    /// The train is standing in a yard: at a yard's mile, with the yard behind her.
    static func inYard(_ e: GameEngine) -> Port? {
        let stop = e.state.currentStop
        return stop.type == .port && e.state.mile == stop.mile ? e.journey.port(stop.id) : nil
    }

    // MARK: - The breakdown

    func breakdown(_ e: GameEngine) -> [Interrupt]? {
        let s = e.state
        guard Self.brokenDown(s) else { return nil }
        let engine = Self.givenOut(s.sails), gear = Self.givenOut(s.hull)
        let ship = "[i]\(TextMarkup.escape(s.ship))[/i]"
        let what = engine && gear ? "The engine and the running gear have both given out."
            : engine ? "The engine has given out." : "The running gear has given out."

        if let yard = Self.inYard(e) {
            // Every part that is out can be mended here: from the stores, the store or the shop.
            func fixable(_ out: Bool, _ have: Int, _ key: ItemKey, _ job: Int) -> Bool {
                !out || have >= 1 || s.money >= yard.price(key) || s.money >= Double(job)
            }
            if fixable(engine, s.sailcloth, .sailcloth, e.shipyardSailsCost) && fixable(gear, s.timber, .timber, e.shipyardHullCost) {
                e.state.atPort = true
                return [.message("[red]\(what)[/red] The \(ship) will not leave \(yard.name) like this, which is the one piece of luck in it: the roundhouse is across the yard."),
                        .enterPort]
            }
            return stranded(e, what)
        }

        let canWalk = s.money >= RailData.mechanicFee
        if !canWalk && ((engine && s.sailcloth < 1) || (gear && s.timber < 1)) { return stranded(e, what) }

        var kinds: [String] = [], options: [ChoiceEvent.Option] = []
        if engine {
            kinds.append("engine")
            options.append(.init("Work on the engine: 1 set of boiler fittings [dim](have \(s.sailcloth))[/dim]", enabled: s.sailcloth >= 1))
        }
        if gear {
            kinds.append("gear")
            options.append(.init("Mend the running gear: 1 crate of car spares [dim](have \(s.timber))[/dim]", enabled: s.timber >= 1))
        }
        let w = Self.walker(s) ?? 0
        let fee = Int(RailData.mechanicFee)
        kinds.append("walk")
        options.append(.init(s.crew[w].isCaptain ? "Walk down the line for a mechanic yourself ($\(fee))"
                                                 : "Send \(TextMarkup.escape(s.crew[w].name)) walking for a mechanic ($\(fee))",
                             enabled: canWalk))
        kinds.append("stock")
        options.append(.init("Climb down and take stock first"))
        return [e.ask("breakdown", [String(w)] + kinds,
                      prompt: "[red]\(what)[/red] The \(ship) stands dead on the line at mile \(s.mile), and she will not turn a wheel until she is mended.",
                      detail: "There is a section house every dozen miles or so on this road, each with a handcar and a telegraph key. Whoever walks will be gone from twelve hours to a day, and the mechanic who comes back with them will want $\(fee) for his time and the parts.\n[dim]You have $\(Int(s.money)).[/dim]",
                      options: options)]
    }

    /// Nothing to mend her with, and no money to send for anyone who has.
    func stranded(_ e: GameEngine, _ what: String) -> [Interrupt] {
        e.state.over = true
        return [.gameOver(title: "Stranded at mile \(e.state.mile).",
                          body: "\(what) There is nothing aboard to mend her with and no money to send for a man who has. Two days later a work train tows the [i]\(TextMarkup.escape(e.state.ship))[/i] to the next siding, where the freight is loaded onto somebody else's cars and the road sends you a bill for the towing.")]
    }

    // MARK: - Answers

    func answerBreakdown(_ e: GameEngine, _ args: [String], _ option: Int) -> [Interrupt] {
        guard args.count > option + 1, let w = Int(args[0]), e.state.crew.indices.contains(w) else { return [] }
        switch args[option + 1] {
        case "engine": return e.mendSails()
        case "gear": return e.patchHull()
        case "stock": return [.enterPort]
        case "walk": return walkForAMechanic(e, w)
        default: return []
        }
    }

    /// Somebody walks to the nearest section house; a mechanic comes back on the handcar.
    func walkForAMechanic(_ e: GameEngine, _ w: Int) -> [Interrupt] {
        let fee = RailData.mechanicFee
        guard e.state.money >= fee, Self.brokenDown(e.state) else { return [] }
        e.state.money -= fee
        let you = e.state.crew[w].isCaptain
        let name = TextMarkup.escape(e.state.crew[w].name)
        var q: [Interrupt] = [.message(you
            ? "You leave the train in the crew's hands and set off down the ties with a canteen and the waybill, in case anybody asks."
            : "\(name) sets off down the ties with a canteen and a note for the section foreman. The rest of you sit on the rail and wait.")]
        q += e.passDays(e.ri(RailData.mechanicTurns.lowerBound, RailData.mechanicTurns.upperBound), .sea)
        if e.state.over { return q }
        var mended: [String] = []
        if Self.givenOut(e.state.sails) {
            e.state.sails = RailData.mechanicMends
            mended.append("Engine")
        }
        if Self.givenOut(e.state.hull) {
            e.state.hull = RailData.mechanicMends
            mended.append("Running gear")
        }
        let back = e.state.crew[w].alive
        let who = !back ? "" : you ? ", and you, on the handcar's tool box with your boots off" : ", and \(name), who has walked further today than in the year before"
        let parts = mended.map { "\($0) \(Int(RailData.mechanicMends))%" }.joined(separator: ", ")
        q.append(.message("A handcar comes clacking up the line with a mechanic, a box of parts\(who). He works without saying much, takes his $\(Int(fee)) and pumps away down the line. She is not mended so much as persuaded. [green](\(parts))[/green]"))
        if back {
            e.state.crew[w].hp = max(1, e.state.crew[w].hp - Double(e.ri(RailData.walkWear.lowerBound, RailData.walkWear.upperBound)))
            if e.state.crew[w].ailment == nil && e.chance(RailData.walkSickness) {
                e.sicken(w, &q, e.state.temperature(in: e.state.region), nil, nil)
            }
        }
        return q
    }
}
