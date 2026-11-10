import Foundation

// The 1849 voyage's sea events (spec §5.6), landmarks (§5.7) and the choices both raise.

extension GameEngine {
    // MARK: - Man overboard

    func overboard(_ q: inout [Interrupt]) {
        let candidates = state.crew.indices.filter { state.crew[$0].alive && !state.crew[$0].isCaptain }
        if candidates.isEmpty { return }
        let idx = pick(candidates)!
        let name = TextMarkup.escape(state.crew[idx].name)
        if chance(0.65) {
            state.crew[idx].hp = max(1, state.crew[idx].hp - 25)
            q.append(.message("A sea sweeps the deck and carries \(name) over the side! The crew throws a line — and hauls \(name) back aboard, half-drowned."))
        } else {
            state.crew[idx].alive = false
            state.crew[idx].hp = 0
            state.graves.append(Grave(name: state.crew[idx].name, cause: "drowned", date: state.dateText,
                                      epitaph: "Lost overboard. No grave but the sea."))
            q.append(.message("A great sea sweeps the deck. [red]\(name) has been washed overboard and lost.[/red] In that sea, there was no turning back."))
        }
    }

    // MARK: - Sea events

    func seaEvent(_ q: inout [Interrupt], _ reg: Region) {
        let w = state.weather
        let rough = w.isRough
        let temp = state.temperature(in: reg)
        typealias Event = (weight: Double, ok: Bool, run: () -> Void)
        var out: [Interrupt] = []
        let all: [Event] = [
            (6, state.food > 150, { [self] in
                let l = jsRound(state.food * rnd(0.05, 0.14))
                state.food -= l
                out.append(.message("Rats have gotten into the bread room. \(jsNumber(l)) lbs of provisions are ruined."))
            }),
            (5, state.water > 120, { [self] in
                let l = ri(40, 120)
                state.water = max(0, state.water - Double(l))
                out.append(.message("A water cask has gone foul and green. You pump \(l) gallons over the side."))
            }),
            (4, temp == .hot || temp == .warm, { [self] in
                let g = ri(8, 30)
                state.add(.food, Double(g))
                out.append(.message("A school of flying fish lands on deck overnight. The cook gathers \(g) lbs of fresh fish."))
            }),
            (3, true, { [self] in
                if chance(0.5) {
                    let t = ri(1, 2)
                    state.add(.timber, Double(t))
                    out.append(.message("You pass floating wreckage — spars, a hatch cover, a broken boat. Your crew salvages \(describe(.item(.timber), Double(t)))."))
                } else if chance(0.6) {
                    let f = ri(60, 120)
                    state.add(.food, Double(f))
                    out.append(.message("A barrel of salt pork bobs alongside, still sealed. +\(f) lbs of provisions."))
                } else {
                    let other = pick(GameData.shipNames.filter { $0 != state.ship }) ?? GameData.shipNames[0]
                    out.append(.message("You pass a drifting nameboard: [i]\(other)[/i]. Nobody says much for the rest of the day."))
                }
            }),
            (6, rough || w == .fresh, { [self] in
                let d = ri(12, 28)
                state.sails = max(0, state.sails - Double(d))
                out.append(.message("The topsail splits from head to foot with a crack like a cannon. [red](Sails −\(d)%)[/red]"))
            }),
            (4, rough, { [self] in
                state.sails = max(0, state.sails - 15)
                state.hull = max(0, state.hull - 6)
                var t = "The fore-topmast has carried away! Spars and rigging crash to the deck. [red](Sails −15%, Hull −6%)[/red]"
                let c = state.crew.indices.filter { state.crew[$0].alive && state.crew[$0].ailment == nil }
                if !c.isEmpty && chance(0.5) {
                    let idx = pick(c)!
                    state.crew[idx].ailment = .brokenArm
                    state.crew[idx].ailDays = Double(ri(14, 24))
                    state.crew[idx].hp -= 10
                    t += "\n\n\(TextMarkup.escape(state.crew[idx].name)) has a broken arm."
                }
                out.append(.message(t))
                checkSink(&out)
            }),
            (4, true, { [self] in
                let h = ri(8, 18)
                state.hull = max(0, state.hull - Double(h))
                out.append(.message("You have sprung a leak! The carpenter finds a seam working loose below the waterline. [red](Hull −\(h)%)[/red]"))
                checkSink(&out)
            }),
            (3, rough || w == .cold, { [self] in overboard(&out) }),
            (1.5, state.food > 100, { [self] in
                let l = jsRound(state.food * 0.08)
                state.food -= l
                state.hull = max(0, state.hull - 4)
                out.append(.message("Fire in the galley! The crew smothers it with wet canvas, but \(jsNumber(l)) lbs of provisions are lost. [red](Hull −4%)[/red]"))
            }),
            (2, w == .rain || w == .storm, { [self] in
                state.sails = max(0, state.sails - 18)
                out.append(.message("Lightning strikes the mainmast! Blue fire runs down the rigging and a sail goes up in flames. [red](Sails −18%)[/red]"))
            }),
            (2.5, !reg.horn && !reg.strait, { [self] in out.append(.choice(choice(.stranger))) }),
            (2, reg.south && !state.albatrossSeen, { [self] in
                state.albatrossSeen = true
                out.append(.choice(choice(.albatross)))
            }),
            (1.5, !state.stowawaySeen && state.day < 30, { [self] in
                state.stowawaySeen = true
                let free = GameData.firstNames.filter { f in !state.crew.contains { $0.name == f } }
                let name = pick(free) ?? "Asa"
                out.append(.choice(choice(.stowaway(name: name))))
            }),
            (5, temp == .freezing || (reg.south && state.mile > 6400 && state.mile < 8300), { [self] in
                out.append(.choice(choice(.icebergs(fog: state.weather == .fog))))
            }),
            (2, true, { [self] in
                out.append(.message("A pod of sperm whales surfaces off the bow, blowing and rolling in the swell. The crew lines the rail to watch.\(state.role == .whaler ? " Your hands itch for a harpoon." : "")"))
            }),
            (1.5, rough, { [self] in
                state.forceFair = 2
                out.append(.message("Pale blue fire flickers at every masthead — St. Elmo's fire. The old hands say it means the worst of the blow is over."))
            }),
        ]
        let eligible = all.filter(\.ok)
        if eligible.isEmpty { return }
        let i = weightedPick(eligible.enumerated().map { ($0.offset, $0.element.weight) })
        eligible[i].run()
        q += out
    }

    // MARK: - Privateers

    func pirates(ran: Bool) -> [Interrupt] {
        let cash = min(Int(state.money.rounded(.down)), ri(40, 140))
        let f = min(Int(state.food.rounded(.down)), ri(60, 200))
        state.money -= Double(cash)
        state.food -= Double(f)
        var t = "She runs up no flag — [red]privateers![/red] \(ran ? "She overhauls you despite every sail you carry. " : "")They swarm aboard and take $\(cash) and \(f) lbs of provisions."
        let c = state.crew.indices.filter {
            state.crew[$0].alive && !state.crew[$0].isCaptain && state.crew[$0].ailment == nil
        }
        if !c.isEmpty && chance(0.35) {
            let idx = pick(c)!
            state.crew[idx].hp -= 20
            state.crew[idx].ailment = .brokenArm
            state.crew[idx].ailDays = Double(ri(14, 22))
            t += "\n\n\(TextMarkup.escape(state.crew[idx].name)) was hurt in the scuffle."
        }
        return [.message(t)]
    }

    // MARK: - Arrivals (spec §5.7)

    /// Reaching `s`, the prototype's `arrival` screen. Port side effects (a stowaway going
    /// ashore, the trade count) happen in the shared `portArrival`.
    func horn1849Arrive(_ s: Stop) -> [Interrupt] {
        switch s.type {
        case .mark:
            if s.id == "gulf" {
                return [.message("You are crossing the Gulf Stream. The water turns warm and indigo-blue, and squalls blow up out of nowhere. Your mate sets a course southeast for the Cape Verde Islands.")]
            }
            if state.passage == .magellan {
                return [.message("You have threaded the Strait of Magellan! The last rocky headland falls astern and the long Pacific swell lifts the bow. The crew cheers.")]
            }
            return [.message("You have rounded Cape Horn! The longitude creeps east to west at last, and the long Pacific swell lifts the bow. The crew cheers.")]
        case .port:
            return portArrival(s)
        case .line:
            return [.choice(choice(.equator))]
        case .fork:
            return [.choice(choice(.fork))]
        case .island:
            return [.choice(choice(.galapagos))]
        case .end:
            return [.finale]
        }
    }

    // MARK: - Choices

    func choice(_ kind: ChoiceEvent.Kind) -> ChoiceEvent {
        switch kind {
        case .stranger:
            return ChoiceEvent(kind: kind, prompt: "A strange sail on the horizon — and she is closing on you fast.",
                               detail: nil, options: [.init("Hail her"), .init("Crowd on sail and run")])
        case .albatross:
            return ChoiceEvent(kind: kind,
                               prompt: "A great albatross has followed the ship for three days, never once beating its wings. One of the crew wants to shoot it for the pot.",
                               detail: nil, options: [.init("Let it be"), .init("Shoot it")])
        case .stowaway(let name):
            return ChoiceEvent(kind: kind,
                               prompt: "A skinny youngster is found hiding in the hold among the flour barrels. The name is \(name), and \(name) wants to see California more than anything in the world.",
                               detail: nil,
                               options: [.init("Sign them on as cabin hand"), .init("Put them ashore at Cape Verde")])
        case .icebergs(let fog):
            return ChoiceEvent(kind: kind,
                               prompt: "Icebergs! Great white islands loom out of the \(fog ? "fog" : "murk") — and between them, smaller growlers, half-sunk and nearly invisible.",
                               detail: nil,
                               options: [.init("Shorten sail and pick your way through"), .init("Hold your course")])
        case .equator:
            return ChoiceEvent(kind: kind, prompt: "You are crossing the Equator!",
                               detail: "By old custom, every sailor crossing the line for the first time must face King Neptune's court — an old hand in a rope-yarn beard who lathers the greenhands with tar and \"shaves\" them with a rusty barrel hoop.",
                               options: [.init("Hold the ceremony (1 day)"), .init("No time for foolishness")])
        case .galapagos:
            return ChoiceEvent(kind: kind, prompt: "You are passing the Galápagos Islands.",
                               detail: "Black lava, cactus, and strange creatures that have never learned to fear people. There is fresh water in the highlands, if you're willing to climb for it.",
                               options: [.init("Send a party ashore (2 days)"), .init("Sail on")])
        case .fork:
            return ChoiceEvent(kind: kind,
                               prompt: "You are off Tierra del Fuego, at the bottom of the world.\(state.southernWinter ? " [red]It is the dead of the southern winter.[/red]" : "")",
                               detail: "You may stand south and round [amber]Cape Horn[/amber] in open ocean, or turn west into the narrow [amber]Strait of Magellan[/amber].",
                               options: [.init("Round Cape Horn"), .init("Take the Strait of Magellan"),
                                         .init("Ask the first mate's advice")])
        case .pilot(let cost):
            return ChoiceEvent(kind: kind,
                               prompt: "At the little Chilean settlement of Punta Arenas, a pilot offers to take you through the Strait for $\(cost).",
                               detail: "[dim]You have $\(formatNumber(state.money)).[/dim]",
                               options: [.init("Hire the pilot ($\(cost))", enabled: state.money >= Double(cost)),
                                         .init("Navigate it yourself")])
        case .portArrival(let stopID):
            // `portArrival` builds the real one, with any stowaway's goodbye in the detail.
            let s = GameData.stop(stopID)!
            return portChoice(s, detail: GameData.port(s.portID!).arrive)
        case .tradeOffer(let o, let intro):
            return tradeChoice(o, intro: intro)
        case .custom:
            // Other journeys build their choices where they ask them (`GameEngine.ask`).
            return ChoiceEvent(kind: kind, prompt: "", detail: nil, options: [])
        }
    }

    /// The player answered one of this voyage's choices. The shared `resolve` has already
    /// turned away a disabled or out-of-range option, and answers port arrivals and trades.
    func horn1849Resolve(_ event: ChoiceEvent, _ option: Int) -> [Interrupt] {
        switch event.kind {
        case .stranger:
            if option == 0 {
                if chance(0.65) {
                    guard let o = makeOffer() else {
                        return [.message("She is a whaler out of New Bedford, three years from home. Her captain shouts the news across the water and sails on.")]
                    }
                    return [.choice(choice(.tradeOffer(o, intro: "She is a Yankee merchant brig, and her captain is in a trading mood.")))]
                }
                return pirates(ran: false)
            }
            state.sails = max(0, state.sails - Double(ri(5, 12)))
            if chance(0.75) {
                return [.message("You crowd on every stitch of canvas and leave her hull-down astern. Your sails took a beating in the chase.")]
            }
            return pirates(ran: true)

        case .albatross:
            if option == 0 { return [.message("The bird wheels away over the swells. The old hands nod at you approvingly.")] }
            state.add(.food, 12)
            state.badLuck = 25
            return [.message("One shot, and it falls into the sea. The crew hauls it aboard for 12 lbs of tough meat. The old hands go quiet. Nobody will look you in the eye.")]

        case .stowaway(let name):
            if option == 0 {
                state.crew.append(CrewMember(name: name, hp: 85))
                return [.message("\(name) grins and gets to work. One more hand — and one more mouth to feed.")]
            }
            state.crew.append(CrewMember(name: name, hp: 85, leaveAt: "cv"))
            return [.message("\(name) will work for passage as far as the Cape Verde Islands.")]

        case .icebergs(let fog):
            if option == 0 {
                var q: [Interrupt] = []
                state.day += 1
                consume(&q, .sail)
                health(&q, .sail)
                if chance(0.1) {
                    let h = ri(6, 12)
                    state.hull -= Double(h)
                    q.insert(.message("You lose a day creeping through, and still scrape a growler. [red](Hull −\(h)%)[/red]"), at: 0)
                } else {
                    q.insert(.message("You lose a day creeping through the ice, but come out the other side unscathed."), at: 0)
                }
                checkSink(&q)
                return q
            }
            let risk = (fog ? 0.25 : 0.12) + (state.pace == .full ? 0.15 : 0)
            if chance(risk) {
                let h = ri(18, 35)
                state.hull = max(0, state.hull - Double(h))
                var q: [Interrupt] = [.message("A sickening crunch — you've struck a growler! [red](Hull −\(h)%)[/red]")]
                checkSink(&q)
                return q
            }
            return [.message("You stand on with your heart in your mouth. The ice slides past on either side.")]

        case .equator:
            if option == 0 {
                state.day += 1
                state.add(.food, -20)
                for i in state.crew.indices where state.crew[i].alive { state.crew[i].hp = min(100, state.crew[i].hp + 8) }
                return [.message("There is shouting, tar, buckets of seawater and an extra ration of grog. Spirits are high. [green](Crew health improves.)[/green]")]
            }
            return [.message("The old hands grumble, but sail on.")]

        case .galapagos:
            if option == 1 { return [] }
            let w = ri(150, 250), f = ri(40, 100)
            state.add(.water, Double(w))
            state.add(.food, Double(f))
            state.noCitrus = 0
            for i in state.crew.indices where state.crew[i].alive && state.crew[i].ailment == .scurvy {
                state.crew[i].ailment = nil
            }
            var q: [Interrupt] = [.message("The shore party returns sunburned and scratched, with \(w) gallons of water and \(f) lbs of fish and wild fruit.")]
            let c = state.crew.indices.filter {
                state.crew[$0].alive && state.crew[$0].ailment == nil && !state.crew[$0].isCaptain
            }
            if !c.isEmpty && chance(0.15) {
                let idx = pick(c)!
                state.crew[idx].ailment = .brokenArm
                state.crew[idx].ailDays = Double(ri(14, 22))
                q.append(.message("\(TextMarkup.escape(state.crew[idx].name)) slipped on the lava and broke an arm."))
            }
            // Two days ashore, without the weather roll `passDays` would make.
            for _ in 0..<2 {
                state.day += 1
                consume(&q, .sea)
                health(&q, .sea)
            }
            return q

        case .fork:
            switch option {
            case 0:
                state.passage = .horn
                return [.message("You stand south for the Horn. The crew double-lashes everything on deck. Nobody speaks much.")]
            case 1:
                state.passage = .magellan
                return [.choice(choice(.pilot(cost: 75)))]
            default:
                return [.message("Your first mate spits over the rail: “The Horn is quicker if the wind is kind — and if it isn't, it'll tear the masts out of her. The Strait is sheltered, but it's slow, cold and full of rocks. Without a pilot, I wouldn't try it.”"),
                        .choice(choice(.fork))]
            }

        case .pilot(let cost):
            if option == 0 {
                state.money -= Double(cost)
                state.pilot = true
                return [.message("The pilot comes aboard with a sealskin coat and a bottle of pisco. “Slow,” he says. “Always slow.”")]
            }
            return [.message("You trust your charts and your lookouts. The Strait narrows ahead between dark, snow-dusted mountains.")]

        default:
            return []
        }
    }
}
