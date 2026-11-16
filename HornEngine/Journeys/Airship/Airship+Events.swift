#if os(WASI)
import FoundationEssentials
#else
import Foundation
#endif

// What can happen in a flying watch. One of these, by weight, on about one watch in seven;
// under the fog the pressure ridges are checked first. Those that ask something are
// answered in Airship+Choices.swift.

extension Airship {
    func airEvents(_ e: GameEngine, _ reg: Region) -> [JourneyEvent] {
        let s = e.state
        let w = s.weather
        let rough = w.isRough
        let north = reg.has("north")
        let sea = reg.has("sea")
        let overIce = reg.has("pack")
        let engines = !Self.drifting(s) && s.fuel > 0
        let temp = s.temperature(in: reg)
        let cold = temp == .cold || temp == .freezing
        let km = s.mile
        let icing = w == AirshipData.ice
        let foggy = w == AirshipData.fog || icing

        return [
            // 1. A crate goes through the keel.
            JourneyEvent(6, when: s.food > 40) { e, q in
                let n = Int(jsRound(e.state.food * e.rnd(0.05, 0.14)))
                e.state.food = max(0, e.state.food - Double(n))
                q.append(.message("A crate of provisions slides off the catwalk and punches straight through the keel fabric. \(n) kg of provisions are somewhere below you now."))
            },
            // 2. A split water can.
            JourneyEvent(5, when: s.water > 40) { e, q in
                let n = e.ri(6, 18)
                e.state.water = max(0, e.state.water - Double(n))
                q.append(.message("A water can has worked loose and split its seam on a girder. \(n) litres drip away into the keel."))
            },
            // 3. A fishing boat.
            JourneyEvent(4, when: sea && (w == AirshipData.fair || w == AirshipData.tail || w == AirshipData.head)) { e, q in
                let n = e.ri(8, 25)
                e.state.add(.food, Double(n))
                q.append(.message("A fishing boat below hails you. You drop low and lower a line, and they send up a basket of fresh fish with their compliments. [green]+\(n) kg of provisions.[/green]"))
            },
            // 4. Something turns up.
            JourneyEvent(3) { e, q in
                if e.chance(0.5) {
                    e.state.add(.sailcloth, 1)
                    q.append(.message("Stowing the gear, the rigger finds a box of engine spares that someone had labelled SOAP. [green]+1 box of engine spares.[/green]"))
                } else if e.chance(0.6) {
                    let n = e.ri(10, 25)
                    e.state.add(.food, Double(n))
                    q.append(.message("A forgotten sack of biscuit and chocolate turns up behind the water cans. [green]+\(n) kg of provisions.[/green]"))
                } else {
                    let name = e.pick(AirshipData.wrecks)!
                    let lies = north ? "lies frozen into the ice" : "lies abandoned on a beach"
                    q.append(.message("Far below, the hulk of an old ship \(lies), her name still on her stern: [i]\(name)[/i]. Nobody says much for the rest of the watch."))
                }
            },
            // 5. An engine stops.
            JourneyEvent(6, when: rough || w == AirshipData.head) { e, q in
                let d = e.ri(12, 28)
                e.state.sails = max(0, e.state.sails - Double(d))
                q.append(.message("The port engine coughs, backfires and stops. A mechanic climbs out along the strut into the slipstream to coax it back to life. [red](Engines −\(d)%)[/red]"))
            },
            // 6. Ice off the propellers.
            JourneyEvent(4, when: rough || icing) { e, q in
                e.state.sails = max(0, e.state.sails - 15)
                e.state.hull = max(0, e.state.hull - 6)
                var t = "Ice builds on the propellers and flies off like shrapnel. A chunk rips through the envelope and into the gas cell behind it. [red](Engines −15%, Lift −6%)[/red]"
                if e.chance(0.5) {
                    let c = e.state.crew.indices.filter { e.state.crew[$0].alive && e.state.crew[$0].ailment == nil }
                    if let idx = e.pick(c) {
                        e.state.crew[idx].ailment = AirshipData.brokenArm
                        e.state.crew[idx].ailDays = Double(e.ri(14, 24))
                        e.state.crew[idx].treated = false
                        e.state.crew[idx].hp = max(1, e.state.crew[idx].hp - 10)
                        t += "\n\n\(TextMarkup.escape(e.state.crew[idx].name)) was struck by flying ice and has a broken arm."
                    }
                }
                q.append(.message(t))
                e.checkSink(&q)
            },
            // 7. A stuck valve.
            JourneyEvent(4) { e, q in
                let d = e.ri(8, 18)
                e.state.hull = max(0, e.state.hull - Double(d))
                q.append(.message("A gas valve has stuck half open. By the time the rigger has climbed up inside the envelope and freed it, a great deal of gas has gone. [red](Lift −\(d)%)[/red]"))
                e.checkSink(&q)
            },
            // 8. A slip on the ladder.
            JourneyEvent(3, when: rough || w == AirshipData.snow || icing) { e, q in
                let c = e.state.crew.indices.filter { e.state.crew[$0].alive && !e.state.crew[$0].isCaptain }
                guard let idx = e.pick(c) else { return }
                let name = TextMarkup.escape(e.state.crew[idx].name)
                if e.chance(0.65) {
                    e.state.crew[idx].hp = max(1, e.state.crew[idx].hp - 25)
                    q.append(.message("In the gusts, \(name) loses footing on the ladder to the engine car! The safety line holds, and the crew hauls \(name) back inside, shaking."))
                } else {
                    e.state.crew[idx].alive = false
                    e.state.crew[idx].hp = 0
                    e.state.graves.append(Grave(name: e.state.crew[idx].name, cause: "a fall", date: e.state.dateText,
                                                epitaph: "Lost from the ship. No grave but the sky."))
                    q.append(.message("In the gusts, \(name) loses footing on the ladder to the engine car. [red]The safety line parts, and \(name) is gone.[/red] There was no going back for them."))
                }
            },
            // 9. Fire in the engine car.
            JourneyEvent(1.5) { e, q in
                e.state.hull = max(0, e.state.hull - 4)
                e.state.sails = max(0, e.state.sails - 6)
                q.append(.message("Fire! A backfire sets oily rags alight in the engine car. The mechanic smothers it with a coat — and this close to the hydrogen, nobody breathes until it is out. [red](Lift −4%, Engines −6%)[/red]"))
                e.checkSink(&q)
            },
            // 10. Lightning.
            JourneyEvent(2, when: w == AirshipData.rain || w == AirshipData.storm) { e, q in
                e.state.sails = max(0, e.state.sails - 18)
                q.append(.message("A flash and a bang: lightning has struck the ship. By some mercy the hydrogen does not catch, but the magnetos on both engines are scorched. [red](Engines −18%)[/red]"))
            },
            // 11. A steamer that wants to trade.
            JourneyEvent(2.5, when: sea) { e, q in
                q.append(e.ask("steamer", prompt: "A steamer below is flashing her signal lamp at you: [amber]CAN TRADE. LOWER A LINE.[/amber]",
                               options: [.init("Drop low and lower a line"), .init("Fly on")]))
            },
            // 12. A stowaway, found before Pulham.
            JourneyEvent(1.5, when: !s.stowawaySeen && s.day < AirshipData.stowawayBefore
                            && s.mile < (stop(AirshipData.stowawayLeaves)?.mile ?? 0)) { e, q in
                e.state.stowawaySeen = true
                let free = self.firstNames.filter { f in !e.state.crew.contains { $0.name == f } }
                let name = e.pick(free) ?? AirshipData.stowawayFallback
                q.append(e.ask("stowaway", [name],
                               prompt: "A pair of boots is sticking out from behind the petrol tanks. They belong to \(TextMarkup.escape(name)), an apprentice from the ground crew at Rome, who wants to see the top of the world more than anything in it.",
                               options: [.init("Sign them on as a hand"), .init("Put them off at Pulham")]))
            },
            // 13. Distress flares on the ice.
            JourneyEvent(2, when: north && km >= 4200 && km < AirshipData.forkTo && s.vars[AirshipData.flaresKey] != 1) { e, q in
                e.state.vars[AirshipData.flaresKey] = 1
                q.append(e.ask("flares", prompt: "Red flares rise from the ice ahead. A small expedition ship lies crushed between the floes, and her crew stands beside her on the ice, waving.",
                               options: [.init("Come down and drop what you can spare (1 watch)"), .init("Fly on")]))
            },
            // 14. Fog down to the ice: over the pack when it freezes, and always on the polar
            // leap. A drifting ship cannot circle, so it is not asked.
            JourneyEvent(5, when: engines && overIce && (temp == .freezing || (km > 5300 && km < AirshipData.forkTo))) { e, q in
                let what = foggy ? "The fog has" : "Low cloud has"
                q.append(e.ask("murk", [foggy ? "fog" : "cloud"],
                               prompt: "\(what) come right down to the ice. Somewhere below, pressure ridges stand as high as houses, and the trail rope is bumping over them.",
                               options: [.init("Climb out of it and wait for a clear patch"),
                                         .init("Hold your height and keep a sharp lookout")]))
            },
            // 15. Something to see.
            JourneyEvent(2) { e, q in
                if north {
                    var t = "A ring of light surrounds the sun, with two bright mock suns burning on either side of it. The crew crowds to the windows."
                    if e.state.role == .whaler { t += " You fill three pages of your notebook." }
                    q.append(.message(t))
                } else if sea {
                    q.append(.message("Far below, a fishing fleet has stopped work to watch you pass. The crews wave their caps from every deck until you are out of sight."))
                } else {
                    q.append(.message("Far below, a whole village has come out to watch you pass. Children run along the road beneath you, waving, until they are left behind."))
                }
            },
            // 16. The glass rises.
            JourneyEvent(1.5, when: rough) { e, q in
                e.state.forceFair = 2
                q.append(.message("The barometer jumps five millibars in an hour. Your navigator grins: the worst of the blow is behind you."))
            },
            // 17. A cracked petrol line.
            JourneyEvent(4, when: s.fuel > 500 && cold) { e, q in
                let n = e.ri(150, 400)
                e.state.fuel = max(0, e.state.fuel - Double(n))
                q.append(.message("A petrol line cracks in the cold. Petrol sprays along the keel before the mechanic can shut it off. \(n) kg are lost. For once, nobody needs telling not to smoke."))
            },
            // 18. A newspaper wants photographs, if the engines can circle for them.
            JourneyEvent(2, when: engines && s.vars[AirshipData.newsKey] != 1) { e, q in
                e.state.vars[AirshipData.newsKey] = 1
                let pay = e.ri(8, 18) * 5
                q.append(e.ask("news", [String(pay)],
                               prompt: "The wireless crackles. A newspaper in New York offers $\(pay) for photographs, if you will circle and take them.",
                               options: [.init("Circle for the photographs (2 watches)"), .init("Decline")]))
            },
        ]
    }

    /// Under the fog, a pressure ridge out of nowhere.
    func ridgeStrike(_ e: GameEngine, _ q: inout [Interrupt]) {
        let d = e.ri(10, 22)
        e.state.hull = max(0, e.state.hull - Double(d))
        e.state.day += 1
        q.append(.message("Out of the fog a pressure ridge rears up under the bow. The trail rope snags, the gondola thumps across the ice, and it takes a whole watch to get her trimmed and aloft again. [red](Lift −\(d)%)[/red]"))
        e.checkSink(&q)
    }
}
