import Foundation

// What can happen in a turn on the road. One of these, by weight, on about one turn in six.
// Those that ask something are answered in Rail+Choices.swift.

extension Rail {
    func roadEvents(_ e: GameEngine, _ reg: Region) -> [JourneyEvent] {
        let s = e.state
        let w = s.weather
        let season = RailData.season(s.month)
        let plains = reg.has("plains")
        let dry = reg.has("dry")
        let mountain = reg.has("mountain")
        let snowing = w == RailData.snow || w == RailData.blizzard
        let full = s.pace == .full
        let climbing = reg.num("grade") < 1 && s.vars[Self.helperKey(reg)] != 1
        let nextYard = stops[(s.stopIndex + 1)...].first { $0.type == .port }

        return [
            // The train
            JourneyEvent(full ? 8 : 5) { e, q in
                let d = e.ri(5, 11)
                e.state.hull = max(0, e.state.hull - Double(d))
                q.append(.message("Smoke from under the third car: a hot box. The crew stops, packs the journal with fresh waste and oil, and stands around it looking stern. [red](Running gear −\(d)%)[/red]"))
            },
            JourneyEvent(5) { e, q in
                let d = e.ri(6, 13)
                e.state.sails = max(0, e.state.sails - Double(d))
                q.append(.message("A flue has started to weep into the firebox. The fireman says a word he will have to apologize for later. [red](Engine −\(d)%)[/red]"))
            },
            JourneyEvent(6, when: s.sails < 70) { e, q in
                let d = e.ri(10, 18)
                e.state.sails = max(0, e.state.sails - Double(d))
                q.append(.message("With a bang and a roar of steam, a tired flue lets go. The cab empties in a hurry. [red](Engine −\(d)%)[/red]"))
                let c = e.state.crew.indices.filter { e.state.crew[$0].alive && e.state.crew[$0].ailment == nil }
                if !c.isEmpty && e.chance(0.4) {
                    let idx = e.pick(c)!
                    e.state.crew[idx].hp -= 8
                    e.sicken(idx, &q, e.state.temperature(in: reg), nil, RailData.scald)
                }
            },
            JourneyEvent(5, when: dry || reg.id == "humboldt") { e, q in
                let d = e.ri(4, 8)
                let gal = e.ri(40, 90)
                e.state.sails = max(0, e.state.sails - Double(d))
                e.state.water = max(0, e.state.water - Double(gal))
                q.append(.message("The last water you took on was full of alkali, and the boiler is foaming like a washtub. You blow her down and lose \(gal) gallons doing it. [red](Engine −\(d)%)[/red]"))
            },
            JourneyEvent(full ? 5 : 2.5) { e, q in
                let d = full ? e.ri(6, 14) : e.ri(3, 7)
                e.state.hull = max(0, e.state.hull - Double(d))
                q.append(.message("A rail has cracked clean through in the cold of the night, and you find it the way trains do. The whole train steps over the gap one wheel at a time. [red](Running gear −\(d)%)[/red]"))
            },
            JourneyEvent(5, when: climbing) { e, q in
                let n = e.ri(8, 16)
                e.state.fuel = max(0, e.state.fuel - Double(n))
                q.append(.message("The drivers lose their feet on the grade and spin. It takes sand, patience and \(RailData.cords(n)) of wood to get the train moving again."))
            },
            JourneyEvent(3, when: !w.wet && !snowing && s.fuel > 30) { e, q in
                let n = e.ri(8, 20)
                e.state.fuel = max(0, e.state.fuel - Double(n))
                q.append(.message("A spark from the stack lands in the tender, and the woodpile gets a head start on the firebox. The crew pitches burning wood overboard: \(RailData.cords(n)) of it."))
            },
            JourneyEvent(3) { e, q in
                let c = e.state.crew.indices.filter { e.state.crew[$0].alive && e.state.crew[$0].ailment == nil }
                if c.isEmpty { return }
                let idx = e.pick(c)!
                e.state.crew[idx].hp -= 8
                q.append(.message("Coupling the cars after a water stop, \(TextMarkup.escape(e.state.crew[idx].name)) is a half second slow getting a hand clear of the link."))
                e.sicken(idx, &q, e.state.temperature(in: reg), nil, RailData.crushedHand)
            },

            // The road
            JourneyEvent(5, when: plains && season != .winter) { e, q in
                q.append(e.ask("bison", prompt: "A herd of bison is crossing the track ahead, a mile wide and in no hurry at all.",
                               detail: "They have the right of way by about ten thousand years.",
                               options: [.init("Wait for them to cross"), .init("Ease through on the whistle")]))
            },
            JourneyEvent(4, when: w.wet || season == .spring) { e, q in
                q.append(e.ask("culvert", prompt: "The creek ahead is over its banks, and it has taken most of a culvert with it. The rails hang across the gap with the ties still on them.",
                               options: [.init("Crib it up with a crate of car spares", enabled: e.state.timber >= 1),
                                         .init("Wait for the section gang"),
                                         .init("Creep across and hope")]))
            },
            JourneyEvent(4) { e, q in
                q.append(e.ask("express", prompt: "A flagman at a water tank waves you down. The westbound express is forty minutes behind you and wants the main line.",
                               detail: "The next station with a siding long enough is nine miles on.",
                               options: [.init("Back into the spur here and let her by"),
                                         .init("Run for the next station, wide open")]))
            },
            JourneyEvent(3, when: plains && !w.wet && (season == .summer || season == .autumn)) { e, q in
                q.append(e.ask("fire", prompt: "A line of smoke on the horizon becomes a prairie fire, coming down on the track faster than a horse can run.",
                               options: [.init("Back up to the last creek and let it pass"),
                                         .init("Run through the smoke")]))
            },
            JourneyEvent(9, when: snowing || (mountain && season == .winter)) { e, q in
                q.append(e.ask("drift", prompt: "A cut ahead has drifted full of snow, level with the top of the smokestack.",
                               options: [.init("Dig it out by hand"), .init("Back up, open the throttle and buck it")]))
            },
            JourneyEvent(3, when: !s.stowawaySeen && nextYard != nil && s.living.count < 6) { e, q in
                e.state.stowawaySeen = true
                guard let yard = nextYard else { return }
                let free = self.firstNames.filter { f in !e.state.crew.contains { $0.name == f } }
                let name = e.pick(free) ?? "Amos"
                q.append(e.ask("tramp", [name, yard.id],
                               prompt: "The fireman finds a stranger asleep in the wood car. He says his name is \(name), that he is a printer, and that there is a newspaper in \(yard.short) holding a job for him.",
                               detail: "He has ink on his cuffs, at least.",
                               options: [.init("Let him pass wood as far as \(yard.short)"),
                                         .init("Set him down at the next section house with a meal")]))
            },
            JourneyEvent(3, when: s.money >= 6) { e, q in
                q.append(e.ask("drummer", prompt: "At a water stop a drummer in a yellow waistcoat opens his sample case on your pilot beam. Professor Quillfeather's Vegetable Restorative, he says, cures everything a railroad can do to a person.",
                               detail: "$6 the bottle.\n[dim]You have $\(Int(e.state.money)).[/dim]",
                               options: [.init("Buy a bottle ($6)", enabled: e.state.money >= 6), .init("Decline, politely")]))
            },

            // Luck
            JourneyEvent(4) { e, q in
                let n = e.ri(10, 25)
                e.state.add(.fuel, Double(n))
                q.append(.message("The graders left a stack of culled ties beside the track, too warped to lay. They are not too warped to burn. [green]+\(RailData.cords(n)) of firewood.[/green]"))
            },
            JourneyEvent(dry ? 2 : 4) { e, q in
                let gal = e.ri(80, 160)
                e.state.add(.water, Double(gal))
                q.append(.message(dry
                    ? "A railroad water train is waiting on a siding for orders. Her crew, bored past bearing, runs you off \(gal) gallons for the company."
                    : "A spring comes out of the bank right beside the track, cold and sweet. You fill everything that will hold water. [green]+\(gal) gallons.[/green]"))
            },
            JourneyEvent(2.5) { e, q in
                let pay = e.ri(4, 9) * 5
                e.state.money += Double(pay)
                q.append(.message("A rancher flags you down at a crossing with six crates of eggs and no other way to get them to town. He pays cash, in advance. [green]+$\(pay).[/green]"))
            },
            JourneyEvent(5) { e, q in
                let sights = [
                    "A band of antelope paces the train for a mile, easily, then loses interest and turns away.",
                    "You pass a grading camp from last year: forty chimneys, no roofs, and a sign that still says HOTEL.",
                    "An emigrant family in a wagon, on the old road beside the track, stops to watch you go by. Their children wave until you are out of sight.",
                    "Sunset fills the whole sky. Even the fireman comes out on the running board to look.",
                    "A section gang lifts their hats as you pass, and one of them throws a fresh loaf up into the cab.",
                ]
                let line = e.pick(sights)!
                for i in e.state.crew.indices where e.state.crew[i].alive {
                    e.state.crew[i].hp = min(100, e.state.crew[i].hp + 2)
                }
                q.append(.message(line))
            },
        ]
    }
}
