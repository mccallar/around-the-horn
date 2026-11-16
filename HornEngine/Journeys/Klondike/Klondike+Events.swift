#if os(WASI)
import FoundationEssentials
#else
import Foundation
#endif

// What can happen on a day of travel: first the country's own hazard (a snowslide on the
// summits, a gravel bar on the river), else one event in nine. Those that ask something are
// answered in Klondike+Choices.swift.

extension Klondike {
    /// At most one of: a snowslide, a snag, an event.
    func trailDay(_ e: GameEngine, _ q: inout [Interrupt], _ reg: Region) {
        if reg.has("slides") {
            let spring = KlondikeData.season(e.state.month) == .spring
            if e.chance(reg.num(spring ? "slideSpring" : "slide", or: 0)) {
                snowslide(e, &q)
                return
            }
        }
        if reg.has("snags") {
            let pace = e.state.pace == .easy ? 0.6 : e.state.pace == .full ? 1.6 : 1
            if e.chance(0.025 * pace) {
                let d = e.ri(8, 20)
                e.state.hull = max(0, e.state.hull - Double(d))
                e.state.day += 1
                q.append(.message("She runs hard onto a gravel bar hidden under the brown water. It takes a full day of wading and prying to get her off. [red](Boat −\(d)%)[/red]"))
                e.checkSink(&q)
                return
            }
        }
        if e.chance(rules.eventChance) { e.runEvent(events(e, reg), &q) }
    }

    // MARK: - Hazards

    /// Half the time it buries the cache; half the time somebody, the leader included.
    func snowslide(_ e: GameEngine, _ q: inout [Interrupt]) {
        let meter = Self.meterNames(e.state).structure
        if e.chance(0.5) {
            let d = e.ri(10, 25)
            let m = min(e.ri(100, 300), Int(e.state.food.rounded(.down)))
            e.state.hull = max(0, e.state.hull - Double(d))
            e.state.food -= Double(m)
            q.append(.message("A slide comes down off the mountain in the night and buries part of your cache. [red](\(meter) −\(d)%, \(m) lbs of provisions lost)[/red]"))
            e.checkSink(&q)
            return
        }
        let living = e.state.crew.indices.filter { e.state.crew[$0].alive }
        guard let idx = e.pick(living) else { return }
        let name = TextMarkup.escape(e.state.crew[idx].name)
        if e.chance(0.6) {
            e.state.crew[idx].hp = max(1, e.state.crew[idx].hp - 30)
            q.append(.message("A roar, a white wall — and \(name) is under the snow. You dig with your hands and pull \(name) out, alive and half-frozen."))
            return
        }
        e.state.crew[idx].alive = false
        e.state.crew[idx].hp = 0
        if e.state.crew[idx].isCaptain {
            e.state.over = true
            q.append(.gameOver(title: "You, \(name), have been lost in a snowslide.", body: leaderDiedBody(e.state)))
            return
        }
        e.state.graves.append(Grave(name: e.state.crew[idx].name, cause: "a snowslide", date: e.state.dateText,
                                    epitaph: "Under the snow on the pass."))
        q.append(.message("A roar, a white wall — and \(name) is under the snow. You dig until dark. [red]\(name) is gone.[/red]"))
    }

    /// Through the ice at a creek or on a lake, or over the side in fast water. Never the leader.
    func overboard(_ e: GameEngine, _ q: inout [Interrupt], onFoot: Bool, onLake: Bool = false, epitaph: String?) {
        let candidates = e.state.crew.indices.filter { e.state.crew[$0].alive && !e.state.crew[$0].isCaptain }
        guard let idx = e.pick(candidates) else { return }
        let name = TextMarkup.escape(e.state.crew[idx].name)
        if e.chance(0.65) {
            e.state.crew[idx].hp = max(1, e.state.crew[idx].hp - 25)
            q.append(.message(onLake
                ? "\(name) goes into the black water after the sled! The others crawl out flat on the ice and haul \(name) back, soaked and blue with cold."
                : onFoot
                ? "\(name) breaks through the ice at a creek crossing! The others haul \(name) out, soaked and blue with cold."
                : "The boat lurches in fast water and \(name) goes over the side! You get an oar to \(name) and haul \(name) back aboard, half-drowned."))
            return
        }
        e.state.crew[idx].alive = false
        e.state.crew[idx].hp = 0
        e.state.graves.append(Grave(name: e.state.crew[idx].name, cause: "drowned", date: e.state.dateText,
                                    epitaph: epitaph ?? (onLake ? "Lost through the lake ice. No grave but the lake."
                                                         : onFoot ? "Lost through the ice. No grave but the creek."
                                                         : "Lost to the river. No grave but the Yukon.")))
        q.append(.message(onLake
            ? "\(name) goes into the black water after the sled, and the ice closes over. [red]\(name) is gone.[/red] There was nothing anyone could do."
            : onFoot
            ? "\(name) breaks through the ice at a creek crossing, and the current takes \(name) under. [red]\(name) is gone.[/red] There was nothing anyone could do."
            : "The boat lurches in fast water and \(name) goes over the side. [red]\(name) is gone.[/red] In that current, there was no going back."))
    }

    // MARK: - Events

    func trailEvents(_ e: GameEngine, _ reg: Region) -> [JourneyEvent] {
        let s = e.state
        let w = s.weather
        let leg = KlondikeData.leg(reg)
        let steamer = leg == .steamer
        let foot = leg == .foot
        let boat = leg == .boat
        let temp = s.temperature(in: reg)
        let cold = temp == .cold || temp == .freezing
        let rough = w.isRough
        let windOrIce = w == KlondikeData.wind || w == KlondikeData.ice
        let meters = Self.meterNames(s)
        let healthy = s.crew.indices.filter { s.crew[$0].alive && s.crew[$0].ailment == nil }
        let nextTown = stops[(s.stopIndex + 1)...].first { $0.type == .port }

        return [
            // E1 Damp in the flour
            JourneyEvent(6, when: s.food > 150) { e, q in
                let n = min(e.ri(100, 300), Int(e.state.food.rounded(.down)))
                e.state.food -= Double(n)
                q.append(.message("Damp has gotten into the flour sacks. \(n) lbs of provisions have gone sour and moldy."))
            },
            // E2 A soaked woodpile
            JourneyEvent(5, when: s.water > 120 && !steamer) { e, q in
                let n = min(e.ri(40, 120), Int(e.state.water.rounded(.down)))
                e.state.water -= Double(n)
                q.append(.message("The woodpile has been soaked through. \(n) lbs of firewood will only hiss and smoke."))
            },
            // E3 Fresh fish from a camp on the bank
            JourneyEvent(4, when: boat && !cold) { e, q in
                let n = e.ri(15, 40)
                e.state.add(.food, Double(n))
                q.append(.message("A family drying salmon at a camp on the bank trades you fresh fish for a little tea and sugar. +\(n) lbs of provisions."))
            },
            // E4 What others left behind
            JourneyEvent(3, when: !steamer) { e, q in
                if e.chance(0.5) {
                    let n = e.ri(1, 2)
                    e.state.add(.timber, Double(n))
                    let got = self.describe(.item(.timber), Double(n))
                    q.append(.message(foot ? "Someone has given up and left an outfit by the trail. Your party salvages \(got)."
                                           : "A wrecked boat lies on a gravel bar. Your party salvages \(got)."))
                } else if e.chance(0.6) {
                    let n = e.ri(60, 120)
                    e.state.add(.food, Double(n))
                    q.append(.message(foot ? "A sack of beans and a side of bacon lie beside the trail, abandoned and still sound. +\(n) lbs of provisions."
                                           : "A crate of tinned goods bobs against the bank, still sealed. +\(n) lbs of provisions."))
                } else {
                    let others = self.vesselNames.filter { $0 != e.state.ship }
                    let other = TextMarkup.escape(e.pick(others) ?? self.vesselNames[0])
                    q.append(.message(foot ? "You pass an abandoned sled with a name burned into the crossbar: [i]\(other)[/i]. Nobody says much for the rest of the day."
                                           : "You pass a broken boat on a sandbar with a name painted on her bow: [i]\(other)[/i]. Nobody says much for the rest of the day."))
                }
            },
            // E5 A split runner, a snapped sweep, a split sail
            JourneyEvent(6, when: (foot && [KlondikeData.wind, KlondikeData.blizzard, KlondikeData.thaw, KlondikeData.snow].contains(w))
                            || (boat && windOrIce)) { e, q in
                let n = e.ri(12, 28)
                e.state.sails = max(0, e.state.sails - Double(n))
                let line = foot ? "A sled runner splits on a hidden rock, and a pack strap goes with it. [red](Sleds −\(n)%)[/red]"
                    : w == KlondikeData.ice ? "A cake of ice catches the steering sweep and snaps it like a match. [red](Oars & sail −\(n)%)[/red]"
                    : "A gust splits the sail from yard to foot with a bang. [red](Oars & sail −\(n)%)[/red]"
                q.append(.message(line))
            },
            // E6 A runaway sled, a swamping squall
            JourneyEvent(4, when: (foot && rough) || (boat && windOrIce)) { e, q in
                e.state.sails = max(0, e.state.sails - 15)
                e.state.hull = max(0, e.state.hull - 6)
                var line = foot
                    ? "A loaded sled gets away on the steep pitch and runs wild down the slope, spilling sacks the length of the hill. [red](Sleds −15%, Outfit −6%)[/red]"
                    : "A squall comes down the water and swamps her to the gunwales before you can reach the shore. [red](Oars & sail −15%, Boat −6%)[/red]"
                if !healthy.isEmpty && e.chance(0.5) {
                    let idx = e.pick(healthy)!
                    let leg = KlondikeData.brokenLeg
                    e.state.crew[idx].hp = max(1, e.state.crew[idx].hp - 10)
                    e.state.crew[idx].ailment = leg
                    e.state.crew[idx].ailDays = Double(e.ri(leg.duration.lowerBound, leg.duration.upperBound))
                    e.state.crew[idx].treated = false
                    line += "\n\n\(TextMarkup.escape(e.state.crew[idx].name)) was in the way, and has a broken leg."
                    if e.state.meds > 0 {
                        e.state.meds -= 1
                        e.state.crew[idx].treated = true
                        line += self.text.medsUsed(e.state.meds)
                    }
                }
                q.append(.message(line))
                e.checkSink(&q)
            },
            // E7 Shifted freight, a wet cache, a sprung plank
            JourneyEvent(4) { e, q in
                let n = e.ri(8, 18)
                e.state.hull = max(0, e.state.hull - Double(n))
                q.append(.message(steamer ? "The steamer rolls hard all night and the freight shifts. Crates of your outfit are smashed. [red](Outfit −\(n)%)[/red]"
                                  : foot ? "Water has gotten under the tarps at your cache. Sacks are splitting and crates coming apart. [red](Outfit −\(n)%)[/red]"
                                  : "She grinds over a hidden rock and a plank starts. [red](Boat −\(n)%)[/red]"))
                e.checkSink(&q)
            },
            // E8 Through the ice, or over the side
            JourneyEvent(3, when: (foot && cold && [KlondikeData.wind, KlondikeData.blizzard, KlondikeData.thaw].contains(w))
                            || (boat && windOrIce)) { e, q in
                self.overboard(e, &q, onFoot: foot, epitaph: nil)
            },
            // E9 The stovepipe
            JourneyEvent(1.5, when: s.food > 100 && !steamer) { e, q in
                let n = min(e.ri(60, 180), Int(e.state.food.rounded(.down)))
                e.state.food -= Double(n)
                e.state.hull = max(0, e.state.hull - 4)
                q.append(.message("The stovepipe sets the tent roof alight! You beat it out, but \(n) lbs of provisions are scorched and ruined. [red](\(meters.structure) −4%)[/red]"))
                e.checkSink(&q)
            },
            // E10 Seasick
            JourneyEvent(3, when: steamer && (rough || w == KlondikeData.rain || reg.has("open"))) { e, q in
                for i in e.state.crew.indices where e.state.crew[i].alive {
                    e.state.crew[i].hp = max(1, e.state.crew[i].hp - 4)
                }
                q.append(.message("The steamer pitches and rolls for a day and a night. Half the passengers are seasick, and your party is in the worse half. [red](Health suffers.)[/red]"))
            },
            // E11 Quitters
            JourneyEvent(2.5, when: !steamer) { e, q in
                q.append(e.ask("quitters",
                               prompt: foot ? "A party coming back down the trail hails you. They're done with the North and want to sell out before they go home."
                                            : "A boat is tied up at the bank, and the people in it wave you over. They've had enough, and want to sell out before they turn back.",
                               options: [.init("Hear them out"), .init("Keep going")]))
            },
            // E12 A partner
            JourneyEvent(1.5, when: !s.stowawaySeen && s.mile < KlondikeData.campMile && nextTown != nil && !boat) { e, q in
                e.state.stowawaySeen = true
                guard let town = nextTown else { return }
                let free = self.firstNames.filter { f in !e.state.crew.contains { $0.name == f } }
                let drawn = e.pick(free) ?? self.firstNames[0]
                let name = TextMarkup.escape(drawn)
                let next = Self.name(town, e.state)
                q.append(e.ask("partner", [drawn, town.id, next],
                               prompt: steamer
                                   ? "The purser comes along the deck with a youngster he found hiding among the freight: no ticket, no outfit and no money — only a great wish to see the Klondike. The name is \(name)."
                                   : "A young stampeder is sitting on a sack beside the trail. \(name)'s partners quit and went home, and took the outfit with them.",
                               options: [.init("Take \(name) on as a partner"),
                                         .init("Feed \(name) and send them on to \(next)")]))
            },
            // E13 The slope above is talking
            JourneyEvent(reg.id == "chilkootSummit" ? 5 : 2,
                         when: reg.has("slides") && ([KlondikeData.snow, KlondikeData.thaw, KlondikeData.blizzard].contains(w)
                                                      || s.month == 2 || s.month == 3)) { e, q in
                q.append(e.ask("slidewarning",
                               prompt: "The snow on the slope above the trail is booming and cracking. The packers ahead of you have stopped and are looking up.",
                               options: [.init("Wait in camp until it settles (2 days)"), .init("Push on")]))
            },
            // E14 Thin ice
            JourneyEvent(3, when: reg.has("lakeIce") && cold && KlondikeData.season(s.month) != .summer) { e, q in
                q.append(e.ask("thinice",
                               prompt: "The trail runs straight across the frozen lake — but the ice is grey, and in places you can see water moving under it.",
                               options: [.init("Go round by the shore (lose a day)"), .init("Cross on the ice")]))
            },
            // E15 A gold rumour
            JourneyEvent(2, when: boat && s.vars[KlondikeData.rumourKey] == nil) { e, q in
                e.state.vars[KlondikeData.rumourKey] = 1
                q.append(e.ask("rumour",
                               prompt: "At a camp on the bank, a man is shouting that there's gold in a creek just up the valley — coarse gold, right on the bedrock — and half the camp is already running.",
                               options: [.init("Join the stampede (3 days)"), .init("Stay with the boat")]))
            },
            // E16 Northern lights
            JourneyEvent(2, when: cold && (s.month >= 8 || s.month <= 3)) { _, q in
                q.append(.message("The northern lights hang over the mountains all night, green curtains folding and unfolding. Nobody wants to go to sleep."))
            },
            // E17 Sundogs
            JourneyEvent(1.5, when: rough) { e, q in
                e.state.vars[KlondikeData.clearKey] = 2
                q.append(.message("Bright sundogs blaze on either side of the sun. The old-timers say the blow is breaking up."))
            },
            // E18 Spruce tea
            JourneyEvent(3, when: reg.has("timber") && s.noCitrus > 5) { e, q in
                e.state.noCitrus = 0
                q.append(.message("An old-timer shows you how to brew tea from spruce tips. It tastes like the inside of a turpentine barrel, but everyone drinks it. [green](Good against scurvy.)[/green]"))
            },
        ]
    }
}
