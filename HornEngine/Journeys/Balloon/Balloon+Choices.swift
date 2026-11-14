import Foundation

// The set pieces (the Himalaya, the edge of the Pacific, the date line, the Azores) and the
// answer to everything the flight asks.

extension Balloon {
    // MARK: - Set pieces

    func setPiece(_ e: GameEngine, _ stop: Stop) -> [Interrupt] {
        switch stop.id {
        case "him":
            return [e.ask("him", prompt: "You are passing the Himalaya.",
                          detail: "The whole range stands up out of the haze to the north, a white wall two hundred miles long. Mission Control says the jet is running hard just over the top — if you can stand the cold.",
                          options: [.init("Climb over the range into the jet (35 gal)", enabled: e.state.fuel >= BalloonData.himalayaBurn),
                                    .init("Stay south of the range")])]
        case "pacific":
            return [forkChoice(e)]
        case "dateline":
            return [e.ask("dateline", prompt: "You are crossing the date line!",
                          detail: "Half a world from Greenwich, the calendar below you jumps back a day. Mission Control keeps Greenwich time, so nothing changes aboard — but somebody has kept a cake in the freezer since Marrakech for exactly this moment.",
                          options: [.init("Hold a party (1 watch)"), .init("Keep to the watch schedule")])]
        case "azores":
            return [e.ask("azores", prompt: "You are passing over the Azores.",
                          detail: "Green volcanic islands in the middle of the Atlantic. A fishing boat out of Ponta Delgada has heard you on the radio, and offers to meet you off the coast with fresh water and bread if you'll come down to the wave tops.",
                          options: [.init("Drop down to meet her (2 watches)"), .init("Fly on")])]
        default:
            return []
        }
    }

    func forkChoice(_ e: GameEngine) -> Interrupt {
        var prompt = "You are leaving the coast of Japan. Ahead lies the Pacific: five thousand miles with nowhere to land."
        let m = e.state.month
        if m == 10 || m == 2 || m == 3 { prompt += " [red]The jet is weak this time of year.[/red]" }
        return e.ask("fork", prompt: prompt,
                     detail: "You may ride the [amber]northern track[/amber] in the core of the jet — fast, and bitter cold — or drop south to the [amber]southern track[/amber], warmer and slower, where the thunderstorms grow.",
                     options: [.init("Ride the northern track"), .init("Take the southern track"),
                               .init("Ask Mission Control's advice")])
    }

    func forecastChoice(_ e: GameEngine) -> Interrupt {
        let fee = Int(BalloonData.forecastFee)
        return e.ask("forecast",
                     prompt: "Mission Control says a forecasting service in Honolulu will radio you a storm plot every watch, all the way across, for $\(fee).",
                     detail: "Hawaii lies far to the south, out of reach of this wind. [dim]You have $\(formatNumber(e.state.money)).[/dim]",
                     options: [.init("Hire the forecasters ($\(fee))", enabled: e.state.money >= BalloonData.forecastFee),
                               .init("Trust your own eyes")])
    }

    // MARK: - Answers

    func answer(_ e: GameEngine, _ key: String, _ args: [String], _ option: Int) -> [Interrupt] {
        switch key {
        case "him":
            if option == 1 {
                return [.message("You keep to the warm side of the mountains. The peaks slide past to the north, one white summit after another.")]
            }
            e.state.fuel = max(0, e.state.fuel - BalloonData.himalayaBurn)
            if let next = e.state.nextStop {
                e.state.mile = min(e.state.mile + BalloonData.himalayaGain, next.mile - 1)
            }
            let living = e.state.crew.indices.filter { e.state.crew[$0].alive }
            for (i, idx) in living.enumerated() {
                e.state.crew[idx].hp -= 3 + (i < e.state.clothes ? 0 : 10)
            }
            var t = "You climb to thirty thousand feet and the jet takes you like a leaf in a gutter. For an hour Everest stands just below the porthole, close enough to see the snow streaming off the summit. You've gained two hundred miles. The cold has gained on all of you. [red](Crew health falls.)[/red]"
            if e.chance(0.25) {
                e.state.sails = max(0, e.state.sails - 10)
                t += " Ice forms in a burner valve on the way down. [red](Burners −10%)[/red]"
            }
            var q: [Interrupt] = [.message(t)]
            for idx in living where e.state.crew[idx].hp < 0 { e.state.crew[idx].hp = 0 }
            e.deaths(&q)
            return q

        case "fork":
            switch option {
            case 0:
                e.state.vars[BalloonData.southKey] = nil
                return [.message("You climb into the jet, and the Pacific starts to slide by at a hundred knots. Everyone puts on a second pair of socks.")]
            case 1:
                e.state.vars[BalloonData.southKey] = 1
                return [forecastChoice(e)]
            default:
                return [.message("Mission Control's chief meteorologist comes on the radio: “The north is quicker if the jet holds, and it's brutal cold up there — nobody without a down suit should go. The south is warmer and slower, and it's thunderstorm country. If you go south and can spare the money, buy the storm plots.”"),
                        forkChoice(e)]
            }

        case "forecast":
            if option == 0 {
                e.state.money -= BalloonData.forecastFee
                e.state.vars[BalloonData.forecastKey] = 1
                return [.message("The first plot comes over the fax an hour later, dense with red blobs. A note at the bottom says: “Stay out of the red. Always out of the red.”")]
            }
            return [.message("You'll read the clouds yourselves. To the south the sky is already stacking up in towers.")]

        case "dateline":
            if option == 1 {
                return [.message("You note the moment in the log and keep the watch schedule. Somebody eats the cake anyway, quietly, at three in the morning.")]
            }
            e.state.day += 1
            e.state.fuel = max(0, e.state.fuel - BalloonData.partyBurn)
            e.state.food = max(0, e.state.food - 3)
            for i in e.state.crew.indices where e.state.crew[i].alive {
                e.state.crew[i].hp = min(100, e.state.crew[i].hp + 8)
            }
            return [.message("There is cake, cocoa, a paper hat for everyone and a crackly telephone call from home. Spirits climb higher than the balloon. [green](Crew health improves.)[/green]")]

        case "azores":
            if option == 1 { return [] }
            let w = e.ri(20, 40)
            let f = e.ri(10, 25)
            e.state.add(.water, Double(w))
            e.state.add(.food, Double(f))
            e.state.noCitrus = 0
            for i in e.state.crew.indices where e.state.crew[i].alive && e.state.crew[i].ailment == BalloonData.staleAir {
                e.state.crew[i].ailment = nil
                e.state.crew[i].treated = false
            }
            var q: [Interrupt] = [.message("Her crew passes up water jugs, bread, cheese and oranges in a net on the end of your trail line. With the hatch open at sea level, the capsule fills with real air for the first time in days. [green](+\(w) gallons of water, +\(f) lbs of rations.)[/green]")]
            if e.chance(0.15) {
                let well = e.state.crew.indices.filter {
                    e.state.crew[$0].alive && !e.state.crew[$0].isCaptain && e.state.crew[$0].ailment == nil
                }
                if let idx = e.pick(well) {
                    breakArm(e, idx, days: 14...22)
                    q.append(.message("\(TextMarkup.escape(e.state.crew[idx].name)) caught a hand in the line hauling the net up, and has a broken arm."))
                }
            }
            // Two watches at the wave tops, in whatever weather there is.
            for _ in 0..<2 where !e.state.over {
                e.state.day += 1
                e.consume(&q, .sea)
                e.health(&q, .sea)
                if !e.state.over { tick(e, &q, .sea, e.state.region) }
            }
            return q

        case "freighter":
            if option == 1 {
                return [.message("You blip the burners at her by way of a wave. She sounds her horn, faint and far below.")]
            }
            var q = e.passDays(1, .sea)
            if e.state.over { return q }
            if e.chance(0.75) {
                // Propane and sand weigh too much to pass up a trail line.
                if let o = e.makeOffer(excluding: [.fuel, .timber]) {
                    q.append(.choice(e.tradeChoice(o, intro: "Her bosun ties a sack to your trail line and shouts up what's in it.")))
                } else {
                    q.append(.message("She has nothing you need. Her cook sends up a bag of oranges anyway, and the football scores."))
                }
            } else {
                e.state.sails = max(0, e.state.sails - 10)
                q.append(.message("The line snags on her radio mast as she rolls. It parts before it can drag you down, but the jolt rattles every burner. [red](Burners −10%)[/red]"))
            }
            return q

        case "mascot":
            if option == 0 {
                return [.message("The bear stays where it is. Nobody says so, but everyone is relieved.")]
            }
            e.state.hull = min(100, e.state.hull + 1)
            e.state.badLuck = 25
            return [.message("The bear tumbles away into the cloud. The balloon doesn't notice the difference. The crew does. [dim](Lift +1%)[/dim]")]

        case "thunderheads":
            if option == 0 {
                var q: [Interrupt] = []
                e.state.day += 1
                e.state.fuel -= min(e.state.fuel, burn(e.state, e.state.region))
                e.consume(&q, .sail)
                e.health(&q, .sail)
                if e.state.over { return q }
                if e.chance(0.1) {
                    let d = e.ri(6, 12)
                    e.state.hull -= Double(d)
                    q.append(.message("You lose a watch detouring round the cells, and still catch the edge of one. [red](Lift −\(d)%)[/red]"))
                } else {
                    q.append(.message("You lose a watch detouring round the cells, but come out the other side unharmed."))
                }
                e.checkSink(&q)
                return q
            }
            let cloudy = e.state.weather == BalloonData.cloud
            let risk = (cloudy ? 0.25 : 0.12) + (e.state.pace == .full ? 0.15 : 0)
            if e.chance(risk) {
                let d = e.ri(18, 35)
                e.state.hull -= Double(d)
                var q: [Interrupt] = [.message("The gap closes. For ten minutes the balloon is flung up and down like a toy, and hail hammers on the capsule. [red](Lift −\(d)%)[/red]")]
                e.checkSink(&q)
                return q
            }
            return [.message("You hold your course with your heart in your mouth. Lightning walks the cloud walls on either side — and then you're through.")]

        case "ice":
            if option == 0 {
                e.state.fuel = max(0, e.state.fuel - BalloonData.iceBurn)
                return [.message("You burn hard and climb out of the cloud into clear, dry air. Within the hour the ice is sliding off the envelope in sheets and tumbling away below.")]
            }
            let d = e.ri(5, 15)
            e.state.hull -= Double(d)
            var q: [Interrupt] = [.message("You ride it out. By the time the cloud thins, the balloon is carrying a ton of ice and sagging like a wet tent. [red](Lift −\(d)%)[/red]")]
            e.checkSink(&q)
            return q

        case "camera":
            if option == 1 {
                return [.message("They circle twice, film the envelope against the sky, and drone away home.")]
            }
            if e.chance(0.5) {
                let n = 50 * e.ri(6, 16)
                e.state.money += Double(n)
                return [.message("The pictures go out on the news around the world. Your sponsors are delighted, and wire you a bonus. [green](+$\(n))[/green]")]
            }
            e.state.hull -= 8
            e.state.sails = max(0, e.state.sails - 12)
            var q: [Interrupt] = [.message("The plane cuts across in front of you, and its wash sets the whole balloon swinging. [red](Lift −8%, Burners −12%)[/red]")]
            e.checkSink(&q)
            return q

        default:
            return []
        }
    }
}
