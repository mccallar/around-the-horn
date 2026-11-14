import Foundation

// The towns: six on the way, two of them different for each pass. And Lake Bennett, where
// the party builds a boat and waits for the ice.

extension Klondike {
    /// The Chilkoot's towns stand in the table; the White Pass's two are `whitePassTowns`.
    static let towns: [Port] = [
        Port(id: "seattle", journey: Klondike.id, name: "Seattle", shop: "An outfitter on First Avenue", mult: 1,
             arrive: "",
             talk: [
                "An outfitter with a pencil behind his ear: “The Canadians won't let you over the summit without a year's grub — three pounds a head a day. Don't argue with me about it. Argue with the mounted police.”",
                "A man back from the North, thin as a rail: “Go in March. You'll cross while there's still snow for the sleds, and be at the lakes when the ice goes out. Go sooner and the pass will freeze you; later and you'll wade.”",
                "A doctor on the dock: “Take lime juice. A winter on beans and bacon and your gums go soft and your old cuts open up again. I saw it all last year in Circle City.”",
             ]),
        Port(id: "juneau", journey: Klondike.id, name: "Juneau", shop: "A general store on Front Street", mult: 1.25,
             mods: [.water: 1.5, .clothes: 0.75],
             arrive: "Juneau is a mining town wedged between the water and a mountain. The steamer stops for coal and mail, and half the passengers go ashore to buy what they forgot in Seattle.",
             talk: [
                "A clerk at the mining office: “They say there are more people on the trail than there's grub in the whole Yukon. That's why the police make you carry your own.”",
                "A deckhand coiling a line: “Fill up your woodpile at the landing. There's nothing to burn up on the pass, and they'll charge you like it's gold.”",
                "The storekeeper: “Furs are cheaper here than in Seattle. The trappers bring them to us.”",
             ]),
        Port(id: "landing", journey: Klondike.id, name: "Dyea", shop: "A tent store above the tide flats", mult: 1.4,
             mods: [.water: 0.8], fever: true,
             arrive: "Dyea is a tide flat, a river and a forest of tents. Your outfit comes ashore in a lighter and is dumped on the beach just above the tide line. The tide here comes in fast, and nobody waits for it.",
             talk: [
                "A packer resting on his load: “Fifty pounds a trip and you'll make forty trips. Sixty and you'll make thirty, and hate every one of them.”",
                "A woman selling bread from a tent: “A dollar a loaf. You'll think it was cheap when you're up at the Scales.”",
                "A man wrapped in a blanket: “There's fever in these tents. Don't drink from the river below the camp.”",
             ]),
        Port(id: "camp", journey: Klondike.id, name: "Sheep Camp", shop: "A canvas store at Sheep Camp", mult: 1.9,
             mods: [.water: 2.5, .limes: 1.2],
             arrive: "Sheep Camp is the last place with trees: a mile of tents, cook-fires and stacked outfits in the snow. Above it the valley climbs into bare white country, and every scrap of wood up there has been carried up on somebody's back.",
             talk: [
                "A woman selling firewood by the armload: “Buy it here, dear. Above the timber it's packed up on somebody's back, and they charge like it.”",
                "A packer: “At the Scales they weigh it again and the price goes up. Then it's the Golden Stairs — steps cut in the snow, straight up. You'll climb them thirty times.”",
                "An old-timer cleaning his pipe: “When the snow on the mountain starts to talk, get off the trail. I mean it.”",
             ]),
        Port(id: "bennett", journey: Klondike.id, name: "Lake Bennett", shop: "The sawmill store at Bennett", mult: 2.2,
             mods: [.water: 0.25, .timber: 0.8],
             arrive: "Lake Bennett is a city of tents on the shore of a long, narrow lake. Every tree for miles has been cut, and the whipsaws never stop. Half-built boats stand everywhere.",
             talk: [
                "A boatbuilder with pitch to the elbows: “Plank her thick at the bow and pitch every seam twice. The river finds any seam you skipped.”",
                "A mounted policeman: “We'll stop you at Tagish to number your boat. And nobody runs Miles Canyon now without a pilot.”",
                "An old-timer: “The ice goes out the end of May, near enough. Sit tight till then. People who try the ice early end up walking.”",
             ]),
        Port(id: "selkirk", journey: Klondike.id, name: "Fort Selkirk", shop: "The trading post at Fort Selkirk", mult: 2.6,
             mods: [.water: 0.25],
             arrive: "Fort Selkirk is a trading post and a few cabins on a flat above the river, where the Pelly comes in from the east. After weeks on the river, a counter with tinned goods on it looks like a palace.",
             talk: [
                "The trader: “Dawson's a week's float, less if you keep at it. Everything costs more there than here, and here costs plenty.”",
                "A man going out: “Every creek worth a dollar was staked before you left home. But there's wages, if you'll work.”",
                "A woman at the counter: “Lime juice is dear, but scurvy is dearer. Half of Dawson had it last winter.”",
             ]),
    ]

    static let whitePassTowns: [Port] = [
        Port(id: "landing", journey: Klondike.id, name: "Skagway", shop: "A false-front store on Broadway", mult: 1.35,
             mods: [.water: 0.8], fever: true,
             arrive: "Skagway is a few months old and already has a dozen saloons, a newspaper and a reputation. The street is ankle-deep in mud, and every second man has something to sell you.",
             talk: [
                "A storekeeper behind a plank counter: “Keep your money in your boot. There are men in this town who can find it anywhere else.”",
                "A teamster: “The White Pass was a swamp last fall. Frozen, it's not so bad. Just slow.”",
                "A newsboy: “Extra! Another strike on the Klondike! Only a nickel!”",
             ]),
        Port(id: "camp", journey: Klondike.id, name: "White Pass City", shop: "A log store at White Pass City", mult: 1.8,
             mods: [.water: 2.0],
             arrive: "White Pass City is a camp of tents and log shanties where the wagon road gives out. From here the trail climbs over rock and ice to the summit.",
             talk: [
                "A blacksmith: “Bring your sled to me before the summit, not after. The next smith is at Bennett, and he charges like it.”",
                "A cook ladling beans: “Fifty cents a plate. The coffee's free if you'll listen to me complain.”",
                "A tired stampeder: “Last fall this trail was mud to your knees, and worse. Be glad it's frozen.”",
             ]),
    ]

    // MARK: - Arriving in town

    /// The shared arrival (trades, talk, partners going ashore) with this leg's words, and at
    /// Bennett the ice date and only one way to go: into camp.
    func townArrival(_ e: GameEngine, _ stop: Stop) -> [Interrupt] {
        var extra = ""
        if stop.id == "bennett" {
            if e.state.vars[KlondikeData.breakupKey] == nil {
                e.state.vars[KlondikeData.breakupKey] = Double(KlondikeData.breakupEarliest + e.ri(0, 8))
            }
            if !Self.iceOut(e.state) {
                extra = "\n\n[dim]The lake is still frozen. The old-timers say the ice goes out at the end of May.[/dim]"
            }
        }
        let q = e.portArrival(stop)
        guard case .choice(let c)? = q.first else { return q }
        let options: [ChoiceEvent.Option]
        if stop.id == "bennett" {
            options = [.init("Make camp at the lakes")]
        } else {
            switch KlondikeData.leg(e.state.region) {
            case .steamer: options = [.init("Go ashore while the steamer takes on coal"), .init("Stay aboard")]
            case .foot: options = [.init("Stop and make camp here"), .init("Keep moving")]
            case .boat: options = [.init("Tie up and go ashore"), .init("Float on past")]
            }
        }
        return [.choice(ChoiceEvent(kind: c.kind, prompt: c.prompt, detail: (c.detail ?? "") + extra, options: options))]
    }

    // MARK: - Lake Bennett

    static func breakup(_ s: GameState) -> Int {
        Int(s.vars[KlondikeData.breakupKey] ?? Double(KlondikeData.breakupUsual))
    }

    static func iceOut(_ s: GameState) -> Bool { KlondikeData.dayOfYear(s) >= breakup(s) }

    /// Days a build takes, by role: (properly, scow, raft).
    static func buildDays(_ r: Role) -> (proper: Int, scow: Int, raft: Int) {
        r == .shipwright ? (14, 6, 4) : (21, 9, 5)
    }

    /// "See about a boat". The skin can offer it from the yard slot at Bennett; pushing off
    /// without a boat offers it too.
    public static func boatChoice(_ e: GameEngine) -> Interrupt {
        let s = e.state
        let d = buildDays(s.role)
        let bb = s.role == .shipwright
        return e.ask("boat", prompt: "Lumber, pitch and know-how make a boat. You can saw your own, buy one, or make do.",
                     detail: "[dim]You have $\(formatNumber(s.money)), \(s.timber) \(s.timber == 1 ? "bundle" : "bundles") of canvas & pitch and \(s.sailcloth) \(s.sailcloth == 1 ? "coil" : "coils") of rope & rawhide.[/dim]",
                     options: [
                        .init("Whipsaw lumber and build her properly — \(bb ? "2 weeks" : "3 weeks") [dim](3 canvas & pitch, 2 rope)[/dim]",
                              enabled: s.timber >= 3 && s.sailcloth >= 2),
                        .init("Knock a scow together in a hurry — \(d.scow) days [dim](2 canvas & pitch, 1 rope)[/dim]",
                              enabled: s.timber >= 2 && s.sailcloth >= 1),
                        .init("Buy a boat from the sawmill crew — $\(Int(KlondikeData.boatPrice))", enabled: s.money >= KlondikeData.boatPrice),
                        .init("Lash a raft together from green logs — \(d.raft) days"),
                        .init("Not yet"),
                     ])
    }

    /// Pushing off from Bennett: first a boat, then open water.
    func bennettHold(_ e: GameEngine) -> [Interrupt]? {
        guard e.state.currentStop.id == "bennett" else { return nil }
        if !Self.hasBoat(e.state) {
            return [.message("You can't float to Dawson on a sled. See about a boat first."), Self.boatChoice(e)]
        }
        if Self.iceOut(e.state) { return nil }
        return [e.ask("ice", prompt: "Lake Bennett is still white from shore to shore. Nobody is going anywhere until the ice goes out.",
                      options: [.init("Wait in camp for the ice to go out"), .init("Not yet")])]
    }

    func answerBoat(_ e: GameEngine, _ option: Int) -> [Interrupt] {
        let d = Self.buildDays(e.state.role)
        let bb = e.state.role == .shipwright
        let boat = "[i]\(TextMarkup.escape(e.state.ship))[/i]"
        var q: [Interrupt]
        let line: String
        switch option {
        case 0:
            guard e.state.timber >= 3 && e.state.sailcloth >= 2 else { return [] }
            e.state.timber -= 3
            e.state.sailcloth -= 2
            q = e.passDays(d.proper, .sea)
            if e.state.over { return q }
            e.state.hull = 100
            e.state.sails = 100
            line = "Two of you on the whipsaw, one above the log and one below, from first light to dark. It takes \(bb ? "two weeks" : "three weeks") and most of your good humor, but she's a real boat — ribbed, planked, caulked and pitched, with a square sail sewn from flour sacks. You paint \(boat) on her bow."
        case 1:
            guard e.state.timber >= 2 && e.state.sailcloth >= 1 else { return [] }
            e.state.timber -= 2
            e.state.sailcloth -= 1
            q = e.passDays(d.scow, .sea)
            if e.state.over { return q }
            e.state.hull = bb ? Double(85 + e.ri(0, 10)) : Double(60 + e.ri(0, 15))
            e.state.sails = bb ? 95 : 80
            line = "Green planks, too few nails and a great deal of pitch. She's ugly and she leaks a little, but she floats. You paint \(boat) on her bow anyway."
        case 2:
            guard e.state.money >= KlondikeData.boatPrice else { return [] }
            e.state.money -= KlondikeData.boatPrice
            q = e.passDays(2, .port)
            if e.state.over { return q }
            e.state.hull = Double(90 + e.ri(0, 10))
            e.state.sails = 100
            line = "The sawmill crew has a boat that a party of quitters left behind. You haggle, pay, and paint \(boat) over the old name."
        case 3:
            q = e.passDays(d.raft, .sea)
            if e.state.over { return q }
            e.state.hull = bb ? Double(45 + e.ri(0, 10)) : Double(35 + e.ri(0, 10))
            e.state.sails = 50
            line = "Logs, rope, a sweep at each end and a prayer. The old-timers shake their heads, but a raft is a raft. You carve \(boat) into the front log."
        default:
            return []
        }
        e.state.vars[KlondikeData.boatKey] = Double(option + 1)
        e.state.flags.hull = false
        e.state.flags.sails = false
        return q + [.message("\(line) [dim](Boat \(Int(jsRound(e.state.hull)))% · Oars & sail \(Int(jsRound(e.state.sails)))%)[/dim]")]
    }

    func answerIce(_ e: GameEngine, _ option: Int) -> [Interrupt] {
        guard option == 0 else { return [] }
        let days = max(0, Self.breakup(e.state) - KlondikeData.dayOfYear(e.state))
        let q = e.passDays(days, .sea)
        if e.state.over { return q }
        e.state.atPort = false
        return q + [.message("On \(e.state.dateText) the ice goes out with a long groan and a crack like a rifle shot. By noon the lake is full of sails. You push off with the rest.")]
    }
}
