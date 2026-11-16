#if os(WASI)
import FoundationEssentials
#else
import Foundation
#endif

// The two set pieces (the Dale Creek trestle and the descent from Donner Summit) and the
// answer to everything the road asks.

extension Rail {
    // MARK: - Set pieces

    func setPiece(_ e: GameEngine, _ stop: Stop) -> [Interrupt] {
        switch stop.id {
        case "dalecreek":
            let w = e.state.weather
            if w.isRough || w == RailData.headwind {
                return [e.ask("dalecreek",
                              prompt: "The Dale Creek trestle: 650 feet of timber, 126 feet above the creek, guyed down with wire rope. Today the wind is blowing straight across it and the whole structure is humming.",
                              options: [.init("Wait for the wind to drop"), .init("Cross now, at a walk")])]
            }
            return [.message("You cross the Dale Creek trestle at a walk: 650 feet of timber, 126 feet above a creek you could jump. Nobody says a word until the caboose is on solid ground.")]
        case "donner":
            return [e.ask("donner",
                          prompt: "Donner Summit, 7,000 feet up. From here the track falls all the way to the Sacramento Valley, with a curve for every one of those feet.",
                          detail: "Set the retainers and the train comes down slow and easy on her brakes. Let her roll and you are in the valley by supper, if the brakes agree.",
                          options: [.init("Set the retainers and come down slow"), .init("Let her roll")])]
        default:
            return []
        }
    }

    /// An answer that burns wood hard, offered only with the most it can burn aboard.
    static func onWood(_ label: String, _ s: GameState, _ most: Int) -> ChoiceEvent.Option {
        s.fuel >= Double(most) ? .init(label) : .init("\(label) [dim](not on the wood aboard)[/dim]", enabled: false)
    }

    // MARK: - Answers

    func answer(_ e: GameEngine, _ key: String, _ args: [String], _ option: Int) -> [Interrupt] {
        switch key {
        case "helper": return answerHelper(e, args, option)

        case "dalecreek":
            if option == 0 {
                return [.message("You set the brakes and wait it out. Four hours later the humming stops, and you cross on a bridge that is only a bridge again.")]
                    + e.passDays(1, .sea)
            }
            if e.chance(0.35) {
                let d = e.ri(8, 16)
                let hurt = knock(e, engine: false, d)
                var q: [Interrupt] = [.message("Halfway over, a gust takes the roof walk off the second car and slams a door flat on the third. Everyone aboard discovers they can hold their breath for 650 feet.\(hurt)")]
                e.checkSink(&q)
                return q
            }
            return [.message("The trestle sways under you like a ship at a dock. Then the far abutment arrives, and the fireman remembers to breathe.")]

        case "donner":
            if option == 0 {
                e.state.vars["rail.retainers"] = 1
                return [.message("The brakemen walk the roofs setting a retainer on every car. The train starts down with her shoes smoking, slow as a hearse and a good deal safer.")]
            }
            var p = e.state.pace == .full ? 0.4 : 0.25
            if e.state.hull < 50 { p += 0.15 }
            if e.chance(p) {
                let d = e.ri(15, 30)
                let hurt = knock(e, engine: false, d)
                for i in e.state.crew.indices where e.state.crew[i].alive {
                    e.state.crew[i].hp = max(1, e.state.crew[i].hp - 6)
                }
                var q: [Interrupt] = [.message("Ten miles down, the brakes fade and the train gets away from you. You go through the snowsheds like a ball down a rifle barrel, and it takes the upgrade at Cape Horn to stop her. Every wheel on the train is flat on one side.\(hurt)")]
                e.checkSink(&q)
                return q
            }
            return [.message("She comes off the mountain singing, with the whistle tied down. Nothing breaks. The engineer looks ten years younger and the conductor ten years older.")]

        case "bison":
            if option == 0 {
                return [.message("It takes four hours for the herd to finish crossing. The crew sits on the car roofs and watches. Nobody has anything clever to say about it.")]
                    + e.passDays(1, .sea)
            }
            if e.chance(0.3) {
                let d = e.ri(3, 7)
                let hurt = knock(e, engine: false, d)
                return [.message("The herd will not be hurried. You inch through with the whistle going, and an old bull takes the opportunity to scratch himself on the first boxcar until her door comes off its track.\(hurt)")]
            }
            return [.message("At the first long blast the herd parts around the engine like a river around a rock, and closes again behind the caboose.")]

        case "culvert":
            if option == 0 {
                e.state.timber -= 1
                return [.message("An hour of work with timbers and wedges, and the track sits on a crib a section boss would not be ashamed of. You roll across. (\(e.state.timber) left)")]
            }
            if option == 1 {
                return [.message("The section gang arrives on a handcar in their own good time, and rebuilds the culvert with the calm of men paid by the day. You lose eight hours.")]
                    + e.passDays(2, .sea)
            }
            if e.chance(0.4) {
                let d = e.ri(10, 18)
                let hurt = knock(e, engine: false, d)
                var q: [Interrupt] = [.message("The engine gets across. The track sags under the second car, and it comes over leaning like a tired horse, dragging the third.\(hurt)")]
                e.checkSink(&q)
                return q
            }
            return [.message("The rails groan and dip and hold. On the far side the fireman asks you, respectfully, never to do that again.")]

        case "express":
            if option == 0 {
                return [.message("You back into the spur and wait. The express goes by in a roar of varnish and lit windows, and a passenger in the dining car raises a glass to you.")]
                    + e.passDays(1, .sea)
            }
            let n = min(e.ri(RailData.dashWood.lowerBound, RailData.dashWood.upperBound), Int(e.state.fuel))
            e.state.fuel = max(0, e.state.fuel - Double(n))
            if e.chance(0.3) {
                let fine = min(e.state.money, Double(e.ri(4, 8) * 5))
                e.state.money -= fine
                return [.message("You make the station with the express's headlamp in your caboose windows, \(RailData.cords(n)) of wood lighter. Her conductor reports you to the dispatcher for delaying the mail. [red]A fine of $\(Int(fine)).[/red]")]
            }
            return [.message("Nine miles in eleven minutes. You clear the main with a minute to spare, \(RailData.cords(n)) of wood lighter, and the express never knows you were there.")]

        case "fire":
            if option == 0 {
                return [.message("You back down to the creek and watch the fire go by on both sides of the track. Afterward the prairie is black to the horizon and the ties are smoking.")]
                    + e.passDays(1, .sea)
            }
            if e.chance(0.45) {
                let d = e.ri(6, 12)
                let hurt = knock(e, engine: false, d)
                for i in e.state.crew.indices where e.state.crew[i].alive {
                    e.state.crew[i].hp = max(1, e.state.crew[i].hp - 5)
                }
                return [.message("For half a mile there is nothing to breathe but smoke. You come out the far side with the paint blistered off the cars and everyone coughing.\(hurt)")]
            }
            return [.message("You go through the smoke with the throttle open and the cab windows shut, and come out the far side with nothing worse than watering eyes.")]

        case "drift":
            if option == 0 {
                for i in e.state.crew.indices where e.state.crew[i].alive {
                    e.state.crew[i].hp = max(1, e.state.crew[i].hp - 4)
                }
                return [.message("Everybody digs, the conductor included. Four hours and one broken shovel later, there is a train-sized slot through the drift.")]
                    + e.passDays(1, .sea)
            }
            let n = min(e.ri(RailData.buckWood.lowerBound, RailData.buckWood.upperBound), Int(e.state.fuel))
            e.state.fuel = max(0, e.state.fuel - Double(n))
            if e.chance(0.4) {
                let d = e.ri(8, 15)
                let hurt = knock(e, engine: true, d)
                return [.message("The engine hits the drift, climbs it, and stops dead with snow packed to the cab windows. Digging her out takes as long as digging the cut would have, and it has not done her front end any good.\(hurt)")]
                    + e.passDays(1, .sea)
            }
            return [.message("The third run does it. The engine bursts out the far side wearing most of the drift, \(RailData.cords(n)) of wood the poorer.")]

        case "tramp":
            guard args.count == 2 else { return [] }
            let name = TextMarkup.escape(args[0])
            if option == 0 {
                e.state.crew.append(CrewMember(name: args[0], hp: 85, leaveAt: args[1]))
                return [.message("\(name) turns out to be handy with a cordwood stick, and knows a remarkable number of songs. One more pair of hands, and one more plate at supper.")]
            }
            e.state.food = max(0, e.state.food - 2)
            return [.message("You set \(name) down at the next section house with a meal wrapped in newspaper. He reads the newspaper first.")]

        case "drummer":
            if option == 1 { return [.message("He closes the case, tips his hat, and goes to try the caboose.")] }
            e.state.money -= 6
            if e.chance(0.5) {
                e.state.add(.meds, 1)
                return [.message("The bottle is nonsense, but he throws in a tin of salve, lint and a roll of clean bandage, which are not. [green]+1 medicine kit.[/green]")]
            }
            return [.message("It turns out to be colored water with a good deal of peppermint in it. The fireman finishes the bottle anyway and reports no change.")]

        default:
            return []
        }
    }
}
