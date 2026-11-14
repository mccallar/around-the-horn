import Foundation

// The set pieces (the fork at Lynn Canal, the police at the summit, Miles Canyon, Five
// Finger Rapids) and the answer to everything the trail asks.

extension Klondike {
    // MARK: - Set pieces

    func setPiece(_ e: GameEngine, _ stop: Stop) -> [Interrupt] {
        switch stop.id {
        case "lynn": return [forkChoice(e)]
        case "summit": return [police(e)]
        case "canyon": return [canyonChoice(e)]
        case "fivefinger":
            return [e.ask("fivefinger",
                          prompt: "Four great towers of rock stand across the river like fingers, and the Yukon pours between them through five channels.",
                          detail: "The right-hand channel is the one the steamboats use. Run it straight and fast, or let her down along the right bank on ropes.",
                          options: [.init("Run the right-hand channel"), .init("Line her down along the bank (2 days)")])]
        default: return []
        }
    }

    func lakesNote(_ s: GameState) -> String {
        Self.onWhitePass(s)
            ? "At Log Cabin the trail comes down into stunted pines and a few huts. The worst of the pass is behind you. From here it's a long, flat haul to Lake Bennett, where everybody is building boats."
            : "The trail drops out of the rocks to Lake Lindeman. There are trees again, and tents, and the rasp of whipsaws in every direction. Some parties build their boats right here, but Bennett is only a few miles on, and the timber is better there."
    }

    func forkChoice(_ e: GameEngine) -> Interrupt {
        var prompt = "Your steamer noses up the head of Lynn Canal between mountains that go straight up into the cloud."
        if KlondikeData.season(e.state.month) == .spring {
            prompt += " [red]The snow on the passes is going rotten. It's slide season.[/red]"
        }
        return e.ask("fork", prompt: prompt,
                     detail: "Two landings lie a few miles apart. From [amber]Dyea[/amber] the trail goes over the [amber]Chilkoot Pass[/amber]: short, steep, too steep for anything but people. From [amber]Skagway[/amber] it goes over the [amber]White Pass[/amber]: lower and longer, and a bog whenever it isn't frozen.",
                     options: [.init("Land at Dyea for the Chilkoot"), .init("Land at Skagway for the White Pass"),
                               .init("Ask the purser's advice")])
    }

    func packersChoice(_ e: GameEngine) -> Interrupt {
        let fee = Int(KlondikeData.packersFee)
        return e.ask("packers",
                     prompt: "As you anchor off Dyea, a man rows out in a skiff. His crew of packers will carry a share of your outfit to the summit, so your own relays go faster — for $\(fee).",
                     detail: "[dim]You have $\(formatNumber(e.state.money)).[/dim]",
                     options: [.init("Hire the packers ($\(fee))", enabled: e.state.money >= KlondikeData.packersFee),
                               .init("Pack it all yourselves")])
    }

    /// The police at the summit want a year's grub a head. Short: buy it from the traders up
    /// here, go back down for it, or go home. Args: short, the traders' price, the trip's
    /// cost, and what the trip brings back.
    func police(_ e: GameEngine) -> Interrupt {
        let s = e.state
        let white = Self.onWhitePass(s)
        let prompt = white
            ? "You have reached the summit of the White Pass — and the border. A British flag flies over a cluster of tents, and the mounted police are checking every outfit that comes up the trail."
            : "You have reached the summit of the Chilkoot Pass — and the border. A British flag snaps over a log hut half buried in snow, and a mounted policeman in a buffalo coat is weighing outfits."
        let req = Self.requirement(s)
        if s.food >= req {
            return e.ask("police", prompt: prompt,
                         detail: "“A year's grub for each of you, that's the rule. Three pounds a head a day.” He looks over your sacks and nods. “You'll do. Welcome to Canada.”",
                         options: [.init("Carry on to the lakes")])
        }
        let short = Int((req - s.food).rounded(.up))
        let a = Int((Double(short) * 0.30).rounded(.up))
        let campPrice = port(s, at: "camp")?.price(.food) ?? 0.19
        let back = short + Int((Double(s.living.count) * rations(s.rations).amount * 6).rounded(.up))
        let b = Int((Double(back) * campPrice).rounded(.up))
        let camp = Self.name(stop("camp")!, s)
        return e.ask("police", ["\(short)", "\(a)", "\(b)", "\(back)"], prompt: prompt,
                     detail: "“A year's grub for each of you. That's [amber]\(formatNumber(req)) lbs[/amber], and you have [amber]\(formatNumber(s.food))[/amber].” He folds his arms. “Nobody goes into the Yukon to starve on my watch.”",
                     options: [.init("Buy the difference from the traders at the summit ($\(a))", enabled: s.money >= Double(a)),
                               .init("Go back down to \(camp) for more (6 days, $\(b))", enabled: s.money >= Double(b)),
                               .init("Turn back for home")])
    }

    func canyonChoice(_ e: GameEngine) -> Interrupt {
        let fee = Int(KlondikeData.pilotFee)
        return e.ask("canyon",
                     prompt: "Below Marsh Lake the river narrows and quickens, and then you hear it: Miles Canyon, a slot of black rock a few boat-lengths wide, with the White Horse Rapids roaring below it. Wrecked boats and split sacks line the shore.",
                     detail: "A mounted policeman at the head of the canyon has the say here now: any boat going through takes a registered pilot. You can pay one, or unload, carry your outfit around on your backs and let the empty boat down on ropes.\n[dim]You have $\(formatNumber(e.state.money)).[/dim]",
                     options: [.init("Hire a pilot to run her through ($\(fee))", enabled: e.state.money >= KlondikeData.pilotFee),
                               .init("Portage the outfit and line her down (4 days)"),
                               .init("Ask the constable's advice")])
    }

    // MARK: - Answers

    func answer(_ e: GameEngine, _ key: String, _ args: [String], _ option: Int) -> [Interrupt] {
        switch key {
        case "boat": return answerBoat(e, option)
        case "ice": return answerIce(e, option)

        case "fork":
            switch option {
            case 0:
                e.state.vars[KlondikeData.routeKey] = KlondikeData.chilkoot
                return [packersChoice(e)]
            case 1:
                e.state.vars[KlondikeData.routeKey] = KlondikeData.whitePass
                return [.message("You make for Skagway, where the wharf is long, the street is mud, and everyone seems to have something to sell you.")]
            default:
                return [.message("The purser leans on the rail: “The Chilkoot's shorter, and the steps up the last pitch will break your heart and nothing else. The White Pass is easier going and ten miles longer, and when it thaws it's a swamp. In the cold months, take the Chilkoot — and if you can pay for packers, so much the better. Come slide season, I'd want the White Pass.”"),
                        forkChoice(e)]
            }

        case "packers":
            if option == 0 {
                e.state.money -= KlondikeData.packersFee
                e.state.vars[KlondikeData.packersKey] = 1
                return [.message("The head packer weighs your sacks on a spring scale, names a load for each of his crew, and they set off up the valley at a pace that makes you tired just watching.")]
            }
            return [.message("You look at the mountains, then at your sacks, then at each other. Nobody says anything. You start sorting loads.")]

        case "police":
            guard args.count == 4, let short = Double(args[0]), let a = Double(args[1]), let b = Double(args[2]),
                  let back = Double(args[3]) else { return [] }
            switch option {
            case 0:
                e.state.money -= a
                e.state.add(.food, short)
                return [.message("A trader with a sled full of flour is delighted to see you. [amber](+\(formatNumber(short)) lbs of provisions)[/amber] The constable waves you through.")]
            case 1:
                e.state.money -= b
                let q = e.passDays(6, .sea)
                if e.state.over { return q }
                e.state.add(.food, back)
                return q + [.message(Self.onWhitePass(e.state)
                    ? "Six days down to White Pass City and back up again, with sacks on your backs. The constable remembers you, and this time he waves you through."
                    : "Six days down the Golden Stairs and back up again, with sacks on your backs. The constable remembers you, and this time he waves you through.")]
            default:
                e.state.over = true
                return [.gameOver(title: "The police have turned you back.",
                                  body: "There's no arguing with the rule, and no living in the Yukon without a year's grub. You sell what you have to somebody with more of it, and take the next steamer south.")]
            }

        case "canyon":
            switch option {
            case 0:
                e.state.money -= KlondikeData.pilotFee
                if e.chance(0.06) {
                    let d = e.ri(5, 15)
                    return holed(e, d, "Even a pilot can't miss every rock. She shudders, slews round and comes through with a plank stove in. [red](Boat −\(d)%)[/red]")
                }
                return [.message("A pilot steps aboard, takes the sweep, and says nothing at all for six of the longest minutes of your life. Then you're through, soaked and laughing, in the slack water below the rapids.")]
            case 1:
                let q = e.passDays(4, .sea)
                if e.state.over { return q }
                if e.chance(0.15 + (e.state.hull < 50 ? 0.10 : 0)) {
                    let d = e.ri(10, 25)
                    return q + holed(e, d, "Halfway down, a line parts. She bangs from rock to rock before you catch her in an eddy. [red](Boat −\(d)%)[/red]")
                }
                return q + [.message("Four days of hauling sacks along the rim and paying out rope from rock to rock. Your hands are raw, but she's down, and so is everything you own.")]
            default:
                return [.message("The constable takes his pipe out of his mouth: “Five drowned and a couple of hundred boats smashed before we made the rule. The pilots know the water. If you line her down, keep a hand on every rope — she'll try to get away from you at the bottom.”"),
                        canyonChoice(e)]
            }

        case "fivefinger":
            if option == 0 {
                let risk = 0.12 + (e.state.pace == .full ? 0.10 : 0) + (e.state.hull < 40 ? 0.10 : 0)
                guard e.chance(risk) else {
                    return [.message("You aim for the right-hand gap, the rock slides by close enough to touch, and the standing waves throw spray over everyone. Then the river widens and goes quiet. Rink Rapids, a little below, is nothing after that.")]
                }
                let d = e.ri(12, 30)
                e.state.hull = max(0, e.state.hull - Double(d))
                var q: [Interrupt] = [.message("The current shoves you at the rock. She strikes hard, swings, and comes off through the gap half full of water. [red](Boat −\(d)%)[/red]")]
                if e.chance(0.3) { overboard(e, &q, onFoot: false, epitaph: "Taken by the river at Five Fingers.") }
                e.checkSink(&q)
                return q
            }
            let q = e.passDays(2, .sea)
            if e.state.over { return q }
            if e.chance(0.05 + (e.state.hull < 50 ? 0.10 : 0)) {
                let d = e.ri(8, 20)
                return q + holed(e, d, "A rope slips and she grinds along the rocks before you check her. [red](Boat −\(d)%)[/red]")
            }
            return q + [.message("Two days of easing her down from rock to rock along the right bank. Slow, wet and safe.")]

        case "quitters":
            if option == 1 { return [.message("You wave and keep moving. Behind you, someone laughs.")] }
            if e.chance(0.65) {
                guard let o = e.makeOffer() else {
                    return [.message("They have nothing you need. They wish you luck and go on toward the coast.")]
                }
                return [.choice(e.tradeChoice(o, intro: "They're sick of the North and want to trade."))]
            }
            let n = min(Int(e.state.money.rounded(.down)), e.ri(40, 140))
            if n == 0 {
                return [.message("It's a crooked game of chance, and the “quitters” are partners in it. They take one look at your empty pockets and go back to waiting for somebody richer.")]
            }
            e.state.money -= Double(n)
            return [.message("It's a crooked game of chance, and the “quitters” are partners in it. By the time you see the trick, $\(n) of yours has changed hands.")]

        case "partner":
            guard args.count == 3 else { return [] }
            let name = TextMarkup.escape(args[0])
            if option == 0 {
                e.state.crew.append(CrewMember(name: args[0], hp: 85))
                return [.message("\(name) shakes your hand and picks up a pack. One more back on the trail — and one more year's grub the police will want to see.")]
            }
            e.state.crew.append(CrewMember(name: args[0], hp: 85, leaveAt: args[1]))
            return [.message("\(name) will travel with you as far as \(args[2]).")]

        case "slidewarning":
            if option == 0 {
                return [.message("You wait two days in camp while the mountain grumbles. On the third morning it is quiet, and you go on.")]
                    + e.passDays(2, .sea)
            }
            let risk = 0.15 + (e.state.weather == KlondikeData.thaw ? 0.15 : 0) + (e.state.pace == .full ? 0.10 : 0)
            if e.chance(risk) {
                var q: [Interrupt] = []
                snowslide(e, &q)
                return q
            }
            return [.message("You push on under the slope, nobody speaking. The mountain holds.")]

        case "thinice":
            if option == 0 {
                // A day lost going round: eaten and endured, but no miles.
                var q: [Interrupt] = []
                e.state.day += 1
                e.consume(&q, .sail)
                e.health(&q, .sail)
                if e.state.over { return q }
                if e.chance(0.1) {
                    let d = e.ri(4, 10)
                    e.state.hull = max(0, e.state.hull - Double(d))
                    q.append(.message("An extra day around by the shore, and a sled overturns on the rocks. [red](Outfit −\(d)%)[/red]"))
                    e.checkSink(&q)
                    return q
                }
                return q + [.message("It takes an extra day to haul around by the shore, over rocks and drifts, but you all get there.")]
            }
            let risk = 0.12 + (e.state.weather == KlondikeData.thaw ? 0.15 : 0) + (e.state.pace == .full ? 0.15 : 0)
            guard e.chance(risk) else {
                return [.message("You spread out and cross fast, listening to the ice tick and groan. Nobody goes through.")]
            }
            let d = e.ri(5, 15)
            e.state.hull = max(0, e.state.hull - Double(d))
            var q: [Interrupt] = [.message("With a crack like a rifle shot, the ice gives way under a loaded sled! [red](Outfit −\(d)%)[/red]")]
            overboard(e, &q, onFoot: true, epitaph: nil)
            e.checkSink(&q)
            return q

        case "rumour":
            if option == 1 { return [.message("You let them run. By nightfall the first of them are trickling back, saying nothing.")] }
            let q = e.passDays(3, .sea)
            if e.state.over { return q }
            if e.chance(0.15) {
                let n = e.ri(40, 160)
                e.state.money += Double(n)
                return q + [.message("Three days of bog and mosquitoes, and at the end of it — color in the pan! You stake a claim and, back at the river, sell it to a speculator for $\(n).")]
            }
            return q + [.message("Three days of bog and mosquitoes, and at the end of it a creek staked from end to end by people who got there yesterday. You come back to the boat empty-handed and bitten all over.")]

        default:
            return []
        }
    }

    /// The boat takes `d` points of damage and says so; she may break up.
    func holed(_ e: GameEngine, _ d: Int, _ line: String) -> [Interrupt] {
        e.state.hull = max(0, e.state.hull - Double(d))
        var q: [Interrupt] = [.message(line)]
        e.checkSink(&q)
        return q
    }
}
