import Foundation

// What can happen in a watch aloft: the southern track's thunderstorms, the North Pacific's
// iced roof, and one of seventeen events, by weight, on about one watch in nine. Those that
// ask something are answered in Balloon+Choices.swift.

extension Balloon {
    /// A living crew member other than you, or nil.
    func someoneElse(_ e: GameEngine) -> Int? {
        e.pick(e.state.crew.indices.filter { e.state.crew[$0].alive && !e.state.crew[$0].isCaptain })
    }

    /// Breaks an arm. No medical kit is opened for it.
    func breakArm(_ e: GameEngine, _ idx: Int, days: ClosedRange<Int>) {
        e.state.crew[idx].ailment = BalloonData.brokenArm
        e.state.crew[idx].ailDays = Double(e.ri(days.lowerBound, days.upperBound))
        e.state.crew[idx].treated = false
    }

    func hurt(_ e: GameEngine, _ idx: Int, _ hp: Double) {
        e.state.crew[idx].hp = max(1, e.state.crew[idx].hp - hp)
    }

    /// The southern track's thunderstorm: a lift-tearing ride and a whole watch lost.
    func strike(_ e: GameEngine, _ q: inout [Interrupt], _ reg: Region) {
        let d = e.ri(15, 35)
        e.state.hull -= Double(d)
        e.state.day += 1
        e.state.fuel -= min(e.state.fuel, burn(e.state, reg))
        e.state.weather = BalloonData.storm
        q.append(.message("A thunderstorm boils up beneath you without warning. The updraft flings the balloon two miles up and the downdraft drops it three. It takes a whole watch to fight clear. [red](Lift −\(d)%)[/red]"))
        e.checkSink(&q)
    }

    /// Somebody goes out on the iced roof.
    func roofAccident(_ e: GameEngine, _ q: inout [Interrupt]) {
        guard let idx = someoneElse(e) else { return }
        let name = TextMarkup.escape(e.state.crew[idx].name)
        if e.chance(0.65) {
            hurt(e, idx, 25)
            q.append(.message("\(name) climbs out of the top hatch with an ice axe to knock the ice off the burners, and comes back an hour later with fingers like frozen sausages."))
        } else {
            hurt(e, idx, 20)
            if e.state.crew[idx].ailment == nil { breakArm(e, idx, days: 14...24) }
            q.append(.message("\(name) slips on the iced roof of the capsule. The harness holds, but \(name) has a broken arm."))
        }
    }

    func airEvents(_ e: GameEngine, _ reg: Region) -> [JourneyEvent] {
        let s = e.state
        let w = s.weather
        let temp = s.temperature(in: reg)
        let rough = w.isRough
        let cold = temp == .cold || temp == .freezing
        let sea = reg.has("sea")

        return [
            // 1–4: stores
            JourneyEvent(6, when: s.food > 40) { e, q in
                let n = Int(jsRound(e.state.food * e.rnd(0.05, 0.14)))
                e.state.food -= Double(n)
                q.append(.message("Condensation has been dripping into a food locker for hours. \(n) lbs of rations are soaked and ruined."))
            },
            JourneyEvent(5, when: s.water > 30 && temp != .hot) { e, q in
                let n = e.ri(6, 20)
                e.state.water -= Double(n)
                q.append(.message("A water jug left against the cold capsule wall has frozen solid and split down the side. \(n) gallons are now a sheet of ice under the floor panels."))
            },
            JourneyEvent(4) { e, q in
                let n = e.ri(3, 8)
                e.state.add(.food, Double(n))
                q.append(.message("Behind the radio rack, someone finds a bag of chocolate bars and a note from the ground crew: “For emergencies. This counts.” [green]+\(n) lbs of rations.[/green]"))
            },
            JourneyEvent(3) { e, q in
                if e.chance(0.5) {
                    e.state.add(.sailcloth, 1)
                    q.append(.message("Under a bunk you find a burner kit that was never on the manifest. [green]+1 burner kit.[/green]"))
                } else if e.chance(0.6) {
                    let n = e.ri(10, 25)
                    e.state.add(.food, Double(n))
                    q.append(.message("A case of rations turns up behind the oxygen bottles, still sealed. [green]+\(n) lbs of rations.[/green]"))
                } else {
                    let others = self.vesselNames.filter { $0 != e.state.ship }
                    let other = e.pick(others) ?? "Zephyr"
                    q.append(.message("Mission Control reads you the news: the [i]\(other)[/i] has come down in the sea, and her crew is safe aboard a freighter. Nobody says much for the rest of the watch."))
                }
            },

            // 5–10: the balloon
            JourneyEvent(6, when: rough || w == BalloonData.jet) { e, q in
                let d = e.ri(12, 28)
                e.state.sails = max(0, e.state.sails - Double(d))
                q.append(.message("Number two burner coughs, flares yellow and dies. It takes an hour of coaxing to bring it back. [red](Burners −\(d)%)[/red]"))
            },
            JourneyEvent(4, when: rough) { e, q in
                e.state.sails = max(0, e.state.sails - 15)
                e.state.hull -= 6
                var t = "A load cable parts with a bang like a rifle shot, and the capsule lurches on the rest. [red](Burners −15%, Lift −6%)[/red]"
                if e.chance(0.5) {
                    let well = e.state.crew.indices.filter { e.state.crew[$0].alive && e.state.crew[$0].ailment == nil }
                    if let idx = e.pick(well) {
                        self.hurt(e, idx, 10)
                        self.breakArm(e, idx, days: 14...24)
                        t += "\n\n\(TextMarkup.escape(e.state.crew[idx].name)) was thrown against the burner frame and has a broken arm."
                    }
                }
                q.append(.message(t))
                e.checkSink(&q)
            },
            JourneyEvent(4) { e, q in
                let d = e.ri(8, 18)
                e.state.hull -= Double(d)
                q.append(.message("The gas cell is leaking. Somewhere up near the crown a seam has opened, and nobody can reach it. [red](Lift −\(d)%)[/red]"))
                e.checkSink(&q)
            },
            JourneyEvent(3, when: rough || w == BalloonData.snow) { e, q in
                self.roofAccident(e, &q)
            },
            JourneyEvent(1.5, when: s.fuel > 100) { e, q in
                let n = Int(jsRound(e.state.fuel * 0.08))
                e.state.fuel -= Double(n)
                q.append(.message("A valve on the tank rack outside has frozen open, and before you can close it, \(n) gallons have vented away."))
            },
            JourneyEvent(2, when: w == BalloonData.storm) { e, q in
                e.state.sails = max(0, e.state.sails - 18)
                q.append(.message("Lightning cracks past close enough to taste. A burner valve is welded shut. [red](Burners −18%)[/red]"))
            },

            // 11–15: choices
            JourneyEvent(2.5, when: sea && !rough) { e, q in
                q.append(e.ask("freighter",
                               prompt: "A container ship's captain radios up from the sea far below. She'll trade, if you'll come down low enough to pass a line.",
                               options: [.init("Drop down to meet her (1 watch)"), .init("Wave and fly on")]))
            },
            JourneyEvent(2, when: cold && !s.albatrossSeen) { e, q in
                e.state.albatrossSeen = true
                q.append(e.ask("mascot",
                               prompt: "The mascot — a knitted bear in a flying helmet, made by a schoolgirl in Marrakech — has ridden on the instrument panel since launch. Your flight engineer eyes it: “Every ounce counts.”",
                               options: [.init("Keep the bear"), .init("Drop it over the side (Lift +1%)")]))
            },
            JourneyEvent(5, when: temp == .warm || temp == .hot || reg.has("storms")) { e, q in
                let cloudy = e.state.weather == BalloonData.cloud
                q.append(e.ask("thunderheads",
                               prompt: cloudy
                                ? "A line of thunderheads stands across your track, half hidden in the murk. There may be a gap between two of them."
                                : "A line of thunderheads stands across your track, their tops higher than you can fly. There's a gap between two of them — narrowing.",
                               options: [.init("Descend and go around (lose a watch)"), .init("Hold your course through the gap")]))
            },
            JourneyEvent(4, when: cold && (w == BalloonData.snow || w == BalloonData.cloud)) { e, q in
                q.append(e.ask("ice",
                               prompt: "Ice is building on top of the envelope. You can't see it, but you can feel it: the balloon is getting heavy and slow to answer.",
                               options: [.init("Climb above the cloud to melt it (40 gal)", enabled: e.state.fuel >= BalloonData.iceBurn),
                                         .init("Ride it out")]))
            },
            JourneyEvent(2, when: !sea && !rough) { e, q in
                q.append(e.ask("camera",
                               prompt: "A small plane full of television cameras climbs up to circle you. Its pilot comes on the radio: closer, they want closer.",
                               options: [.init("Wave them in close"), .init("Wave them off")]))
            },

            // 16–17: quiet
            JourneyEvent(2, when: !rough) { e, q in
                var t = "For a whole watch the air is smooth, the burners are quiet and the radio has nothing to say. You can hear the envelope creak above you. Nobody speaks for a while."
                if e.state.role == .whaler { t += " It is as quiet as a lake in Alaska with the floatplane's engine off." }
                q.append(.message(t))
            },
            JourneyEvent(1.5, when: rough) { e, q in
                e.state.forceFair = 2
                q.append(.message("Mission Control radios: you've dropped out of the rough air into a steady stream, and the next two watches should be easy. The capsule stops shaking for the first time in a day."))
            },
        ]
    }
}
