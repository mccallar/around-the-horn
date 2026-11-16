#if os(WASI)
import FoundationEssentials
#else
import Foundation
#endif

// The two set pieces (turnover and the capture at Mars) and the answer to everything the
// arc asks.

extension Mars {
    // MARK: - Set pieces

    func setPiece(_ e: GameEngine, _ stop: Stop) -> [Interrupt] {
        let burn = MarsData.tonnes(MarsData.turnoverBurn)
        switch stop.id {
        case "turnover":
            return [e.ask("turnover",
                          prompt: "Turnover. Halfway to Mars by the clock, the ship turns end for end and starts slowing down. The crew have been looking forward to it for weeks, for no reason anyone can explain.",
                          detail: "Run on four more days before you turn and you will be there about four days sooner, for \(burn) of propellant and a braking burn the drive may not enjoy.\n[dim]You have \(MarsData.tonnes(e.state.fuel)).[/dim]",
                          options: [.init("Turn on schedule"),
                                    .init("Run on four more days and brake hard (\(burn))", enabled: e.state.fuel >= MarsData.turnoverBurn)])]
        case "approach":
            return [e.ask("capture",
                          prompt: "Mars approach. Mars is the brightest thing in the sky after the Sun, and brighter every hour, and the ship is coming in far too fast to stay.",
                          detail: "Aerobrake: skim the top of the atmosphere and let the air do the braking. Quick and free, and very hard on the hull. Or burn into orbit: about \(MarsData.tonnes(MarsData.captureBurn)) of propellant and two or three days longer, and kind to the hull.\n[dim]Pressure hull \(Int(jsRound(e.state.hull)))% · you have \(MarsData.tonnes(e.state.fuel)).[/dim]",
                          options: [.init("Aerobrake"), .init("Propulsive capture (\(MarsData.tonnes(MarsData.captureBurn)))")])]
        default:
            return []
        }
    }

    // MARK: - Answers

    func answer(_ e: GameEngine, _ key: String, _ args: [String], _ option: Int) -> [Interrupt] {
        switch key {
        case "cycler": return answerCycler(e, args, option)

        case "turnover":
            if option == 0 {
                return [.message("The ship turns, slowly and exactly, end over end. Nothing happens, and that is the point. Somebody plays a fanfare over the galley speaker anyway.")]
            }
            e.state.fuel = max(0, e.state.fuel - MarsData.turnoverBurn)
            let gain = Self.cappedGain(e, MarsData.turnoverGain)
            e.state.mile += gain
            var p = 0.3
            if e.state.sails < 50 { p += 0.2 }
            if e.chance(p) {
                let d = e.ri(10, 20)
                e.state.sails = max(0, e.state.sails - Double(d))
                return [.message("Four more days of burning, then a turn and a braking burn that rattles the cups in the galley. Something in the drive rattles too, and keeps rattling. [green]+\(MarsData.km(gain)).[/green] [red](Power & drive −\(d)%)[/red]")]
            }
            return [.message("Four more days of burning, then a turn and a braking burn that rattles the cups in the galley. The drive takes it without complaint. [green]+\(MarsData.km(gain)).[/green]")]

        case "capture":
            if option == 0 {
                e.state.vars[MarsData.captureKey] = 1
                return [.message("You line up on the thin top of the sky. For the next few days the hull will glow, and so will everyone's nerves.")]
            }
            if e.state.fuel >= MarsData.captureBurn {
                e.state.fuel -= MarsData.captureBurn
                e.state.vars[MarsData.captureKey] = 2
                return [.message("A long, steady burn, and Mars lets you in. The orbit is slow and safe and takes its time bringing you round to Phobos.")]
            }
            e.state.fuel = 0
            e.state.vars[MarsData.captureKey] = 3
            return [.message("[red]The tanks run dry halfway through the burn.[/red] Mars keeps you, just, on a long lazy orbit, and the rest of the approach is coasting.")]

        case "flare":
            if option == 0 {
                return [.message("Everybody crowds into the core with the water tanks around them, and the day goes by in cards, naps and elbows. The counters chatter outside. Inside, nobody's badge moves.")]
                    + e.passDays(1, .sea)
            }
            var q: [Interrupt] = [.message("You work on through it. The counters click all afternoon.")]
            var hurt = 0
            for _ in 0..<e.ri(1, 2) {
                let c = Self.wellCrew(e)
                guard !c.isEmpty else { break }
                let idx = e.pick(c)!
                if e.chance(0.75) {
                    hurt += 1
                    e.state.crew[idx].hp -= 8
                    e.sicken(idx, &q, e.state.temperature(in: e.state.region), nil, MarsData.radiation)
                }
            }
            if hurt == 0 { q.append(.message("When it is over, every badge aboard is still on the right side of yellow.")) }
            return q

        case "pod":
            if option == 1 { return [.message("You let it tumble on by. It can be somebody else's mystery.")] }
            e.state.fuel = max(0, e.state.fuel - 30)
            if e.chance(0.15) {
                return [.message("An hour of careful flying, a grapple, a lot of swearing at a stiff latch, and the pod is empty except for a very old sandwich.")]
            }
            let found: String
            switch e.ri(0, 5) {
            case 0:
                let kg = e.ri(40, 90)
                found = "rations, still sealed and still in date, more or less. " + stow(e, .food, kg)
            case 1:
                let l = e.ri(80, 160)
                found = "water bladders, full. " + stow(e, .water, l)
            case 2:
                let n = e.ri(1, 2)
                found = "a hospital's worth of dressings. " + stow(e, .meds, n)
            case 3:
                found = "a spare array panel, still in its foam. " + stow(e, .sailcloth, 1)
            case 4:
                found = "hull sealant and plate. " + stow(e, .timber, 1)
            default:
                let t = e.ri(4, 8) * 10
                found = "a propellant bladder, nearly full. " + stow(e, .fuel, t)
            }
            return [.message("An hour of careful flying and a grapple, and the pod is open on the cargo deck. Inside: \(found)")]

        case "distress":
            guard args.count == 2, let litres = Double(args[1]) else { return [] }
            if option == 1 {
                return [.message("You tell her captain you cannot spare it, and wish her luck, and she thanks you anyway. The crew are quiet at supper.")]
            }
            if args[0] == "water" {
                e.state.water = max(0, e.state.water - litres)
            } else {
                e.state.timber = max(0, e.state.timber - 1)
            }
            let wired = e.ri(3, 6) * 5
            e.state.vars[MarsData.owedKey, default: 0] += Double(wired)
            return [.message("You send it across on a drone. An hour later the survey ship's whole crew crowd into her camera to say thank you, and her captain promises a transfer at the next station you reach.")]

        case "hitch":
            guard args.count == 2 else { return [] }
            let name = TextMarkup.escape(args[0])
            if option == 0 {
                e.state.crew.append(CrewMember(name: args[0], hp: 85, leaveAt: args[1]))
                return [.message("\(name) moves into the spare bunk, fixes the shower on the first day and the coffee machine on the second. One more pair of hands, and one more plate at supper.")]
            }
            return [.message("\(name) takes it well, and goes back with the shuttle to wait for a less crowded ship.")]

        case "drone":
            if option == 1 { return [.message("The drone blinks SAD, then BYE, and goes looking for someone with less sense.")] }
            e.state.money -= Self.dronePrice
            e.state.add(.meds, 1)
            return [.message("The money goes one way and a medical kit comes the other, in a drone's claw. It is, against all expectation, very good and very fresh. [green]+1 medical kit.[/green]")]

        case "creak":
            if option == 0 {
                e.state.timber = max(0, e.state.timber - 1)
                return [.message("A day with lights, a stethoscope and the panels off, and there it is: a seam starting to lift. One patch later it is a seam again. (\(e.state.timber) left)")]
                    + e.passDays(1, .sea)
            }
            if e.chance(0.35) {
                let d = e.ri(10, 20)
                e.state.hull = max(0, e.state.hull - Double(d))
                var q: [Interrupt] = [.message("Three days later the creak becomes a hiss, and the hiss becomes a frantic afternoon with the sealant gun. [red](Pressure hull −\(d)%)[/red]")]
                e.checkSink(&q)
                return q
            }
            return [.message("The creak does not come back. Somebody writes \"probably nothing\" in the log, and underlines it.")]

        default:
            return []
        }
    }

    /// Puts what the pod held in the hold, as far as there is room, and says what went in:
    /// "[green]+20 litres of water.[/green] The rest stays in the pod."
    func stow(_ e: GameEngine, _ key: ItemKey, _ amount: Int) -> String {
        let before = e.state[key]
        e.state.add(key, Double(amount))
        let got = (e.state[key] - before).rounded(.down)
        if got < 1 { return "There is no room aboard for any of it, so it stays in the pod." }
        let rest = got < Double(amount) ? " The rest stays in the pod." : ""
        return "[green]+\(describe(.item(key), got)).[/green]\(rest)"
    }
}
