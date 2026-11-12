import Foundation

// The seven yards where a train can lay over, and the two where a helper engine waits at
// the foot of a grade.

extension Rail {
    /// Wood is dear where no tree grows and cheap under the Sierra. Water is dear in Nevada.
    static let depots: [Port] = [
        Port(id: "omaha", journey: Rail.id, name: "Omaha", shop: "Pruitt & Daughters, Railroad Outfitters", mult: 1,
             arrive: "",
             talk: [
                "The yardmaster doesn't look up from his switch list. \"Wood is cheap here and dear everywhere west of here until you smell pine again. A tender holds sixteen cords. I'd leave with sixteen.\"",
                "A fireman eating his dinner on a baggage truck: \"She'll burn a cord every four hours at timetable speed. Half again that with the throttle wide open, and you'll shake the cars to bits besides.\"",
                "An old riverman is coiling line on the platform. \"Every river on this road carries driftwood, and driftwood is free. Take a grapnel and a few coils. A good hand can pull a day's steam out of the Platte before supper.\"",
                "The freight agent taps your waybill. \"Twelve days to Sacramento earns the bonus. Sixteen and they tear up the contract. I have seen both.\"",
             ]),
        Port(id: "northplatte", journey: Rail.id, name: "North Platte", shop: "The North Platte section store", mult: 1.15,
             mods: [.fuel: 1.3],
             arrive: "A roundhouse, a water tank, and a town that was twice this size last year when the track ended here. The wind has the place mostly to itself now.",
             talk: [
                "The storekeeper weighs out your nails twice. \"Cottonwood is all we have, and it burns like newspaper. That is why it costs what it costs.\"",
                "A brakeman with nine fingers: \"When you couple up, keep your hands where you can see them. I say that to everybody. Nobody listens until after.\"",
                "A section boss points west with his pipe. \"Cheyenne is the foot of Sherman Hill. They keep a helper engine there. The men who don't hire it spend half a day and three cords finding out why it's there.\"",
             ]),
        Port(id: "cheyenne", journey: Rail.id, name: "Cheyenne", shop: "The Cheyenne company store", mult: 1.3,
             mods: [.fuel: 1.4],
             arrive: "The mountains have been a line on the horizon all day. Now they are the horizon. Cheyenne is two years old and already has opinions about newcomers.",
             talk: [
                "The roundhouse foreman wipes his hands. \"Past the Laramie Plains it's the Red Desert: a hundred and thirty miles and not a drop a boiler can use. Fill the tank car here, to the brim. Green River is the next good water.\"",
                "A conductor coming off the westbound: \"Dale Creek trestle is nearly forty miles up. It's sound. It only feels like it isn't. If the wind is up, wait for it to drop.\"",
                "A woman selling pies from a handcart: \"Everybody waits to buy blankets until they can see the snow. By then they are sitting in it.\"",
             ]),
        Port(id: "greenriver", journey: Rail.id, name: "Green River", shop: "The Green River trading tent", mult: 1.45,
             mods: [.fuel: 1.5, .water: 0.5],
             arrive: "After the Red Desert the river looks like a mistake somebody made in your favor. Buttes the color of brick stand over a town made mostly of canvas.",
             talk: [
                "The trader shrugs at his own prices. \"Every stick of that wood came two hundred miles on a flatcar. The river brings some down for nothing, if you've a line to throw.\"",
                "A fireman filling his tender: \"The Wasatch is all river and curve. Good drifting water in Weber Canyon. Slow track, though.\"",
                "An engineer waiting on orders: \"If she starts foaming, that's the alkali in the water. Blow her down and go easy. Fittings cost less than a boiler.\"",
             ]),
        Port(id: "ogden", journey: Rail.id, name: "Ogden", shop: "The Ogden cooperative store", mult: 1.2,
             mods: [.food: 0.8, .fuel: 1.1],
             arrive: "Orchards, irrigation ditches, square fields. After a thousand miles of grass and sagebrush, somebody has planted things in rows. The yard is busy and oddly quiet.",
             talk: [
                "The storekeeper counts your change into your hand. \"West of here is the salt desert. Two hundred miles. The water you can find, your engine won't thank you for. Carry six hundred gallons and then some, and I'm not selling you water, I'm telling you.\"",
                "A telegraph operator on his break: \"They drove the last spike up at Promontory in May. There's a tent there now sells you a piece of the tie. They have sold about four ties.\"",
                "A farmer delivering apples: \"Flour's cheap here. It won't be again.\"",
             ]),
        Port(id: "elko", journey: Rail.id, name: "Elko", shop: "The Elko freight depot store", mult: 1.5,
             mods: [.fuel: 1.6, .water: 1.5],
             arrive: "A row of tents and false fronts along a river you could step across. Freight wagons for the mines stand three deep by the depot.",
             talk: [
                "The storekeeper names the price of a cord and waits for you to finish. \"It's sagebrush country. The Humboldt carries a little down from the hills. I'd fish for it.\"",
                "A teamster loading for the mines: \"Past the Sink it's the Forty-Mile. No water at all, and then the Truckee, the sweetest you ever drank. Keep three hundred gallons aboard for it.\"",
                "An engineer with his arm in a sling: \"Flues go when she's run hard and tired. If the engine is under seventy in the hundred, be gentle with her, or carry fittings.\"",
             ]),
        Port(id: "reno", journey: Rail.id, name: "Reno", shop: "The Truckee lumber yard & store", mult: 1.3,
             mods: [.fuel: 0.5, .water: 0.6],
             arrive: "The Truckee comes down cold and loud out of the mountains, and the mountains stand over the town with snow on them in every month of the year. The whole place smells of sawn pine.",
             talk: [
                "The lumberman laughs. \"Wood? Friend, wood is what we have instead of money. Fill her up.\"",
                "A helper engineer leaning in his cab window: \"Fifty miles up to the summit, and she'll take twice as long alone as she will with me behind her. Your wood, your day.\"",
                "A brakeman just down from the summit: \"Coming off the top, set the retainers and come down slow. The men who let her roll get to Sacramento first, mostly. Mostly.\"",
                "A snowshed carpenter: \"In winter the Sierra gets forty feet of snow. We are building sheds over the track. We are not finished.\"",
             ]),
    ]

    /// Where a helper waits, and the grade it pushes up.
    static let helpers: [(stop: String, region: RegionID, hill: String)] = [
        ("cheyenne", "sherman", "Sherman Hill"),
        ("reno", "eastslope", "the east slope of the Sierra"),
    ]

    /// At the foot of a grade the helper's engineer asks first; the yard comes after.
    func helperOffer(_ e: GameEngine, _ stop: Stop) -> [Interrupt]? {
        guard let h = Self.helpers.first(where: { $0.stop == stop.id }),
              let fee = RailData.helperFee[h.region.rawValue] else { return nil }
        let cost = Int(fee)
        return [e.ask("helper", [stop.id, h.region.rawValue],
                      prompt: "A helper engine is steaming on the siding at \(stop.name), at the foot of \(h.hill).",
                      detail: "Her engineer will couple on behind and push you over the top for $\(cost). Alone, you will climb at about half speed and burn wood the whole way.\n[dim]You have $\(Int(e.state.money)).[/dim]",
                      options: [.init("Hire the helper ($\(cost))", enabled: e.state.money >= fee),
                                .init("Take the hill on your own steam")])]
    }

    func answerHelper(_ e: GameEngine, _ args: [String], _ option: Int) -> [Interrupt] {
        guard args.count == 2, let stop = e.journey.stop(args[0]), let fee = RailData.helperFee[args[1]] else { return [] }
        var out: [Interrupt] = []
        if option == 0 {
            e.state.money -= fee
            e.state.vars["rail.helper.\(args[1])"] = 1
            out.append(.message("Money changes hands. The helper's engineer says she will be on your tail when you whistle off, and to mind you don't outrun her."))
        }
        return out + e.portArrival(stop)
    }
}
