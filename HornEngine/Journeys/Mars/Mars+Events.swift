import Foundation

// What can happen on a day along the arc: about one day in six, one of these by weight.
// Those that ask something are answered in Mars+Choices.swift.

extension Mars {
    func arcEvents(_ e: GameEngine, _ reg: Region) -> [JourneyEvent] {
        let s = e.state
        let debris = reg.has("traffic") || reg.has("ice")
        let full = s.pace == .full
        let forecasts = !reg.has("quiet")
        // A shuttle can still catch you a few days out from a station you docked at.
        let lastPortAt = stops[...s.stopIndex].lastIndex { $0.type == .port && $0.id != "cycler" }
        let lastPort = lastPortAt.map { stops[$0] }
        let docked = lastPortAt.map { Double($0) == s.vars[MarsData.dockedKey] } ?? false
        let leavingPort = docked && (lastPort.map { s.mile - $0.mile < 1500 } ?? false)
        let nextPort = stops[(s.stopIndex + 1)...].first { $0.type == .port && $0.id != "cycler" }
        // A promise of money at the next station means something only while one lies ahead.
        let stationAhead = stops[(s.stopIndex + 1)...].contains { $0.type == .port }
        // Trouble with the wings needs power to have trouble with; the thruster grid, and a
        // course trimmed on a good fix, need the drive running.
        let lit = !Self.dark(s)
        let drive = lit && s.fuel > 0
        let thrusting = full && drive

        return [
            // The ship
            JourneyEvent(debris ? 7 : 4) { e, q in
                let hit = self.knock(e, .hull, e.ri(5, 12))
                q.append(.message("A pebble the size of a lentil goes in one side of the cargo bay and out the other. It does not stop to apologise.\(hit)"))
                let c = Self.wellCrew(e)
                if !c.isEmpty && e.chance(0.25) {
                    let idx = e.pick(c)!
                    Self.hurt(e, idx, 6)
                    e.sicken(idx, &q, e.state.temperature(in: reg), nil, MarsData.decompression)
                }
                e.checkSink(&q)
            },
            JourneyEvent(4, when: lit) { e, q in
                let hit = self.knock(e, .power, e.ri(5, 10))
                q.append(.message("A wing actuator sticks halfway through a turn, and a quarter of the array spends the day looking at nothing.\(hit)"))
            },
            JourneyEvent(4, when: lit) { e, q in
                let hit = self.knock(e, .power, e.ri(4, 9))
                q.append(.message("A coolant line splits behind a radiator panel. The fix takes an afternoon and a great deal of tape.\(hit)"))
                let c = Self.wellCrew(e)
                if !c.isEmpty && e.chance(0.35) {
                    let idx = e.pick(c)!
                    Self.hurt(e, idx, 5)
                    e.sicken(idx, &q, e.state.temperature(in: reg), nil, MarsData.burn)
                }
            },
            JourneyEvent(3) { e, q in
                let c = Self.wellCrew(e)
                if c.isEmpty { return }
                let idx = e.pick(c)!
                q.append(.message("A scrubber in the aft cabin has been quietly failing for a day. The first anyone knows of it is \(TextMarkup.escape(e.state.crew[idx].name)) falling asleep mid-sentence."))
                e.sicken(idx, &q, e.state.temperature(in: reg), nil, MarsData.badAir)
            },
            JourneyEvent(3, when: s.water > 60) { e, q in
                let l = min(Int(e.state.water) - 20, e.ri(30, 80))
                e.state.water = max(0, e.state.water - Double(l))
                q.append(.message("The recycler has started making a noise. The engineer says it has always made that noise. Nobody else remembers that noise. By the time it is cleaned out, \(l) litres of water have gone down the drain for good."))
            },
            JourneyEvent(2.5, when: s.food > 50) { e, q in
                let kg = e.ri(15, 40)
                e.state.food = max(0, e.state.food - Double(kg))
                q.append(.message("The galley freezer has failed in the night. The crew eat well for a day and throw out the rest: \(kg) kg of rations."))
            },
            JourneyEvent(2.5, when: forecasts) { e, q in
                q.append(.message("A navigation update from Earth refuses to install, then installs twice, then insists the ship is in Belgium. A day goes by setting it right."))
                q += e.passDays(1, .sea)
            },
            JourneyEvent(thrusting ? 6 : 0, when: thrusting) { e, q in
                let hit = self.knock(e, .power, e.ri(8, 15))
                q.append(.message("Running the drive this hard has worn a groove in the thruster grid. The drive's glow has a flicker in it now.\(hit)"))
            },

            // Choices
            JourneyEvent(forecasts ? 5 : 0, when: forecasts) { e, q in
                q.append(e.ask("flare", prompt: "A flare warning from Earth: a burst of protons is on its way and will be here within the hour.",
                               detail: "The storm shelter in the core is cramped, dark and safe. Working on means taking the dose.",
                               options: [.init("Shelter in the core for a day"), .init("Work on")]))
            },
            JourneyEvent(3) { e, q in
                q.append(e.ask("pod", prompt: "Radar picks up a cargo pod tumbling slowly along the arc, lost by somebody in an earlier window. Its beacon still works. Its label has faded.",
                               detail: "Matching its course would cost about \(MarsData.tonnes(30)) of propellant.",
                               options: [.init("Match and take it aboard", enabled: e.state.fuel >= 30 && !Self.dark(e.state)), .init("Leave it")]))
            },
            JourneyEvent(3, when: stationAhead) { e, q in
                let wantsWater = e.chance(0.5)
                let litres = e.ri(6, 12) * 10
                let want = wantsWater ? "\(litres) litres of water" : "a hull patch"
                let can = wantsWater ? e.state.water >= Double(litres) : e.state.timber >= 1
                q.append(e.ask("distress", [wantsWater ? "water" : "patch", "\(litres)"],
                               prompt: "A call on the common channel: a small survey ship with a cracked tank, not far off your course and in trouble. Her captain asks for \(want), if you can spare it.",
                               options: [.init("Send \(want) across", enabled: can), .init("Say you're sorry, and mean it")]))
            },
            JourneyEvent(4, when: !s.stowawaySeen && leavingPort && nextPort != nil && s.living.count < 6) { e, q in
                e.state.stowawaySeen = true
                guard let port = nextPort else { return }
                let free = self.firstNames.filter { f in !e.state.crew.contains { $0.name == f } }
                let name = e.pick(free) ?? "Anan"
                let shown = TextMarkup.escape(name)
                q.append(e.ask("hitch", [name, port.id],
                               prompt: "A shuttle from \(lastPort?.name ?? "the yard") catches you up before you are far gone. Aboard is a technician called \(shown), who missed a ship and has a job waiting at \(port.name).",
                               detail: "A pump fitter, by trade and by conversation. One more pair of hands; one more mouth.",
                               options: [.init("Take \(shown) as far as \(port.short)"), .init("Send \(shown) back with the shuttle")]))
            },
            JourneyEvent(2.5, when: s.money >= Self.dronePrice && s.meds < item(.meds).max) { e, q in
                q.append(e.ask("drone", prompt: "A pedlar's drone matches course with you and blinks a sign: ONE MEDICAL KIT, VERY GOOD, VERY FRESH.",
                               detail: "$\(Int(Self.dronePrice)), which is a great deal more than the yard charged.\n[dim]You have $\(Int(e.state.money)).[/dim]",
                               options: [.init("Buy the kit ($\(Int(Self.dronePrice)))", enabled: e.state.money >= Self.dronePrice),
                                         .init("Wave it away")]))
            },
            JourneyEvent(3) { e, q in
                q.append(e.ask("creak", prompt: "In the quiet of the night watch the hull makes a long, low creak, like a door in an old house.",
                               detail: "It might be nothing. It might be a seam.",
                               options: [.init("Inspect it now (a day and a patch)", enabled: e.state.timber >= 1),
                                         .init("Note it in the log")]))
            },

            // Luck
            JourneyEvent(2.5) { e, q in
                let kg = e.ri(30, 60)
                let packs = e.ri(1, 3)
                let food = e.state.food, limes = e.state.limes
                e.state.add(.food, Double(kg))
                e.state.add(.limes, Double(packs))
                var got: [String] = []
                let f = (e.state.food - food).rounded(.down)
                if f >= 1 { got.append("+" + self.describe(.item(.food), f)) }
                let p = (e.state.limes - limes).rounded(.down)
                if p >= 1 { got.append("+" + self.describe(.item(.limes), p)) }
                let cache = "A marker buoy on the arc has a supply cache strapped to it, left by somebody for anybody."
                q.append(.message(got.isEmpty
                    ? cache + " There is nothing in it you are short of, so you leave a note to say so."
                    : cache + " You take what you need and leave a note. [green]\(got.joined(separator: ", ")).[/green]"))
            },
            JourneyEvent(3, when: forecasts && drive && (s.nextStop.map { $0.mile - s.mile > 400 } ?? false)) { e, q in
                let gain = Self.cappedGain(e, e.ri(150, 300))
                e.state.mile += gain
                q.append(.message("A perfect tracking fix from Earth. The navigator trims the course by a hair and the whole arc gets shorter. [green]+\(MarsData.km(gain)) along the way.[/green]"))
            },
            JourneyEvent(3) { e, q in
                let l = e.ri(40, 100)
                let before = e.state.water
                e.state.add(.water, Double(l))
                let got = Int(e.state.water - before)
                q.append(.message(got > 0
                    ? "A chunk of ice has wedged itself in the truss overnight. It goes into the melt tank. [green]+\(got) litres of water.[/green]"
                    : "A chunk of ice has wedged itself in the truss overnight. The tanks are full, so it goes overboard again with a ceremony."))
            },
            JourneyEvent(3, when: forecasts) { e, q in
                for i in e.state.crew.indices where e.state.crew[i].alive {
                    e.state.crew[i].hp = min(100, e.state.crew[i].hp + 5)
                }
                q.append(.message("Messages from home get through all at once: birthdays, gossip, a dog learning to skateboard, a child who has lost a tooth. Supper runs late."))
            },

            // Sights
            Self.sight(1.5, when: s.mile >= 3_000 && s.mile < 24_000, "Earth is a bright star now, with a dimmer one beside it. Somebody has taped a note under the window: YOU ARE HERE, with an arrow pointing the wrong way."),
            Self.sight(1.5, when: s.mile >= 30_000, "In the navigation telescope Mars has stopped being a star. This morning it is a disc, small and orange and patient, and everybody finds a reason to borrow the telescope."),
            Self.sight(1, "A comet crosses the far side of the sky, its tail laid out like a scarf. The crew name it after the cook, who is delighted, then suspicious."),
            Self.sight(1.5, "The cabin lights go off for a power check, and the Milky Way is suddenly everywhere. Nobody turns them back on for an hour."),
            Self.sight(1, "It is somebody's birthday. There is a cake, of a kind, and a candle that is not allowed to be lit, and singing that is allowed but not encouraged."),
        ]
    }

    static let dronePrice = 25.0

    static func wellCrew(_ e: GameEngine) -> [Int] {
        e.state.crew.indices.filter { e.state.crew[$0].alive && e.state.crew[$0].ailment == nil }
    }

    /// Distance gained, never past the next stop.
    static func cappedGain(_ e: GameEngine, _ gain: Int) -> Int {
        guard let next = e.state.nextStop else { return 0 }
        return max(0, min(gain, next.mile - 1 - e.state.mile))
    }

    static func sight(_ weight: Double, when ok: Bool = true, _ line: String) -> JourneyEvent {
        JourneyEvent(ok ? weight : 0, when: ok) { e, q in
            for i in e.state.crew.indices where e.state.crew[i].alive {
                e.state.crew[i].hp = min(100, e.state.crew[i].hp + 2)
            }
            q.append(.message(line))
        }
    }
}
