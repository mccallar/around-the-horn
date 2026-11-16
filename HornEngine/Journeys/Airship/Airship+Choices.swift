#if os(WASI)
import FoundationEssentials
#else
import Foundation
#endif

// The three set pieces (the Arctic Circle, the North Pole and Point Barrow) and the answer to
// everything the flight asks.

extension Airship {
    // MARK: - Set pieces

    func setPiece(_ e: GameEngine, _ stop: Stop) -> [Interrupt] {
        switch stop.id {
        case "circle":
            return [e.ask("circle", prompt: "You are crossing the Arctic Circle!",
                          detail: "Somewhere below, invisible among the forests, runs the line beyond which the midsummer sun never sets. By the custom of the air service, nobody crosses it for the first time without a toast and a speech.",
                          options: [.init("Hold a celebration (1 watch)"), .init("No time for speeches")])]
        case "pole":
            return [poleChoice(e)]
        case "barrow":
            let low = e.state.vars[AirshipData.routeKey] == AirshipData.routeLow
            return [e.ask("barrow",
                          prompt: low
                            ? "The fog thins, the ice gives way to brown tundra, and there is land: you are over Point Barrow, the northernmost point of Alaska!"
                            : "You let her down through the fog bank, and there below, at last, is land: you are over Point Barrow, the northernmost point of Alaska!",
                          detail: "The whole village has run out onto the ice, waving. There is a trading post, and an aviators' camp with petrol hauled in by sled. If you come down low, they can hold the ship on her lines while you take on what they can spare.",
                          options: [.init("Come down and take on supplies (2 watches)"), .init("Fly on")])]
        default:
            return []
        }
    }

    /// Whether, this month, it really is warmer under the fog than above it (it is never
    /// colder). In April the cold is the same at both heights, and in July the sun has warmed both.
    func warmerUnderTheFog(_ s: GameState) -> Bool {
        temperature(s, in: AirshipData.underFog) != temperature(s, in: AirshipData.aboveFog)
    }

    func poleChoice(_ e: GameEngine) -> Interrupt {
        let low = warmerUnderTheFog(e.state)
            ? "where it is warmer but the fog turns to ice on everything it touches"
            : "where it is no warmer at this time of year and the fog turns to ice on everything it touches"
        var prompt = "You are at the North Pole!"
        if e.state.month == 3 { prompt += " [red]The cold up here is iron-hard.[/red]" }
        if e.state.month == 6 { prompt += " [red]The summer fog lies thick on the ice ahead.[/red]" }
        return e.ask("pole", prompt: prompt,
                     detail: "Every direction is south. The flags go over the side on their weighted staffs and stick upright in the snow. Ahead lie two thousand kilometres of ice that nobody has ever seen. You may [amber]climb above the fog[/amber] into clear, bitter air, or [amber]stay low under it[/amber], \(low).",
                     options: [.init("Climb above the fog"), .init("Stay low, under the fog"), .init("Ask the navigator's advice")])
    }

    func forecastChoice(_ e: GameEngine) -> Interrupt {
        let fee = Int(AirshipData.forecastFee)
        return e.ask("forecast", prompt: "The wireless station at Kings Bay offers to send you a forecast of the fog's height every watch, for $\(fee).",
                     detail: "[dim]You have $\(Int(e.state.money)).[/dim]",
                     options: [.init("Pay for the forecasts ($\(fee))", enabled: e.state.money >= AirshipData.forecastFee),
                               .init("Fly by your own eyes")])
    }

    // MARK: - Answers

    func answer(_ e: GameEngine, _ key: String, _ args: [String], _ option: Int) -> [Interrupt] {
        switch key {
        case "circle":
            if option == 1 { return [.message("The old hands grumble, and fly on.")] }
            e.state.day += 1
            e.state.add(.food, -3)
            for i in e.state.crew.indices where e.state.crew[i].alive {
                e.state.crew[i].hp = min(100, e.state.crew[i].hp + 8)
            }
            return [.message("The cook produces a cake from nowhere. There are speeches, a toast in hot cocoa, and a song nobody knows all the words to. Spirits are high. [green](Crew health improves.)[/green]")]

        case "pole":
            switch option {
            case 0:
                e.state.vars[AirshipData.routeKey] = AirshipData.routeHigh
                return [.message("You climb into clear air. The fog lies below you like a white sea, and the sun circles the sky without setting. Up here the sun warms the gas by day and the cold takes it back by night.")]
            case 1:
                e.state.vars[AirshipData.routeKey] = AirshipData.routeLow
                return [forecastChoice(e)]
            default:
                let under = warmerUnderTheFog(e.state) ? "Under it, it's warmer, but" : "Under it, it's no warmer this time of year, and"
                return [.message("Your navigator taps the barometer: “Above the fog it's clear and cold, and the sun will cook a little gas out of her every watch — so carry ballast. \(under) the fog freezes on everything, and there are ridges down there you won't see until you hit them. If you go low, pay for the forecasts.”"),
                        poleChoice(e)]
            }

        case "forecast":
            if option == 0 {
                e.state.money -= AirshipData.forecastFee
                e.state.vars[AirshipData.forecastKey] = 1
                return [.message("The first report comes through within the hour: fog base one hundred and fifty metres, lowering. Your navigator pins it above the chart table.")]
            }
            return [.message("You trust your lookouts and your trail rope. The fog closes over the top of the envelope.")]

        case "barrow":
            return option == 0 ? comeDownAtBarrow(e) : []

        case "steamer":
            if option == 1 {
                return [.message("You fly on. Her lamp blinks something after you that the navigator declines to translate.")]
            }
            if e.chance(0.65) {
                guard let o = e.makeOffer() else {
                    return [.message("She is a collier bound north with nothing to spare but good wishes. Her crew waves their caps as you climb away.")]
                }
                return [.choice(e.tradeChoice(o, intro: "Her master sends up a list of what he'll swap."))]
            }
            let d = e.ri(6, 14)
            e.state.hull = max(0, e.state.hull - Double(d))
            var q: [Interrupt] = [.message("You drop too low. Hot air from her funnel throws the ship about, and the gondola dips into a wave top before you claw back up. [red](Lift −\(d)%)[/red]")]
            e.checkSink(&q)
            return q

        case "stowaway":
            guard args.count == 1 else { return [] }
            let name = TextMarkup.escape(args[0])
            if option == 0 {
                e.state.crew.append(CrewMember(name: args[0], hp: 85))
                e.state.hull = max(0, e.state.hull - 3)
                var q: [Interrupt] = [.message("\(name) grins and gets to work. One more hand — and seventy kilos more to lift. [red](Lift −3%)[/red]")]
                e.checkSink(&q)
                return q
            }
            e.state.crew.append(CrewMember(name: args[0], hp: 85, leaveAt: AirshipData.stowawayLeaves))
            return [.message("\(name) will work for the ride as far as Pulham.")]

        case "flares":
            if option == 1 {
                return [.message("You fly on. The flares fall behind you. Nobody aboard says anything for a long time.")]
            }
            e.state.add(.food, -15)
            let kit = e.state.meds > 0
            if kit { e.state.meds -= 1 }
            for i in e.state.crew.indices where e.state.crew[i].alive {
                e.state.crew[i].hp = min(100, e.state.crew[i].hp + 6)
            }
            let gave = "You lower a sack of provisions\(kit ? " and a medicine kit" : "") on a line."
            var q: [Interrupt]
            if e.chance(0.7) {
                e.state.forceFair = 2
                q = [.message("\(gave) The castaways cheer, and their skipper chalks a message on a board and holds it up: GLASS RISING. CLEAR WEATHER AHEAD. Your crew climbs away grinning. [green](Crew spirits rise.)[/green]")]
            } else {
                e.state.hull = max(0, e.state.hull - 8)
                q = [.message("\(gave) But hovering so low, a gust slams the ship down and the gondola bounces across a pressure ridge before you can climb. [red](Lift −8%)[/red] The castaways are still waving as you go.")]
                e.checkSink(&q)
            }
            return q + e.passDays(1, .sea)

        case "murk":
            if option == 0 {
                var q: [Interrupt] = []
                e.state.day += 1
                e.state.fuel = max(0, e.state.fuel - e.journey.pace(e.state.pace).fuel)
                e.consume(&q, .sail)
                e.health(&q, .sail)
                if e.chance(0.1) {
                    let d = e.ri(6, 12)
                    e.state.hull = max(0, e.state.hull - Double(d))
                    q.insert(.message("You lose a watch circling above the murk, and climbing in the cold has cost you gas. [red](Lift −\(d)%)[/red]"), at: 0)
                } else {
                    q.insert(.message("You lose a watch circling above the murk, but find a clear patch and come down safely beyond it."), at: 0)
                }
                e.checkSink(&q)
                return q
            }
            let thick = args.first == "fog"
            let risk = (thick ? 0.25 : 0.12) + (e.state.pace == .full ? 0.15 : 0)
            if e.chance(risk) {
                let d = e.ri(18, 35)
                e.state.hull = max(0, e.state.hull - Double(d))
                var q: [Interrupt] = [.message("A jolt runs through the whole ship — the gondola has struck a pressure ridge! [red](Lift −\(d)%)[/red]")]
                e.checkSink(&q)
                return q
            }
            return [.message("You hold on with your heart in your mouth. Grey shapes of ice slide past below, close enough to touch.")]

        case "news":
            guard let pay = args.first.flatMap(Int.init) else { return [] }
            if option == 1 { return [.message("You decline. The paper wires back that it will print a drawing instead.")] }
            let burn = e.journey.pace(e.state.pace).fuel * 2
            let spent = min(e.state.fuel, burn)
            e.state.fuel -= spent
            e.state.money += Double(pay)
            return [.message("You circle while the photographer leans out of the window with the camera. The paper wires its thanks, and $\(pay). [red](Petrol −\(formatNumber(spent)) kg)[/red]")]
                + e.passDays(2, .sea)

        default:
            return []
        }
    }

    /// Two watches on the lines at Point Barrow: petrol, food, water, coffee, and sleep.
    func comeDownAtBarrow(_ e: GameEngine) -> [Interrupt] {
        let p = e.ri(200, 500), f = e.ri(10, 25), w = e.ri(30, 60)
        e.state.add(.fuel, Double(p))
        e.state.add(.food, Double(f))
        e.state.add(.water, Double(w))
        e.state.add(.limes, AirshipData.barrowCoffee)
        e.state.noCitrus = 0
        for i in e.state.crew.indices where e.state.crew[i].alive && e.state.crew[i].ailment == AirshipData.watchFatigue {
            e.state.crew[i].ailment = nil
        }
        var q: [Interrupt] = [.message("The villagers take your lines and walk the ship down to the ice like a great kite. You take on \(p) kg of petrol, \(f) kg of dried fish and caribou meat, \(w) litres of water, and a sack of coffee from the trading post. [green]Everyone has a hot drink and a few hours' sleep.[/green]")]
        let c = e.state.crew.indices.filter {
            e.state.crew[$0].alive && e.state.crew[$0].ailment == nil && !e.state.crew[$0].isCaptain
        }
        if !c.isEmpty && e.chance(0.15) {
            let idx = e.pick(c)!
            e.state.crew[idx].ailment = AirshipData.brokenArm
            e.state.crew[idx].ailDays = Double(e.ri(14, 22))
            e.state.crew[idx].treated = false
            q.append(.message("\(TextMarkup.escape(e.state.crew[idx].name)) was dragged off their feet by a handling line and has a broken arm."))
        }
        // Two watches on the lines, without the weather roll `passDays` would make.
        for _ in 0..<2 where !e.state.over {
            e.state.day += 1
            e.consume(&q, .sea)
            e.health(&q, .sea)
        }
        return q
    }
}
