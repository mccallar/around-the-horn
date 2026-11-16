#if os(WASI)
import FoundationEssentials
#else
import Foundation
#endif

// To the Klondike: 1898. Seattle to Dawson City, 1,700 miles in three legs: a crowded
// steamer up the Inside Passage, a mountain pass climbed a load at a time, and a boat you
// build at Lake Bennett and float down the lakes and the Yukon.
//
// A turn is a day; distances are in TENTHS of a mile, because the trail moves under a mile
// a day. What it is about: the police's year of grub at the summit, firewood above the
// trees, the ice on Lake Bennett, the boat you build there, scurvy in the long camps, and
// getting to Dawson ahead of the crowd. Tables are in KlondikeData.swift; towns, the boat
// and the ice in Klondike+Towns; events in Klondike+Events; set pieces and answers in
// Klondike+Choices. Spec and the bot's numbers: docs/journeys/klondike.md.
//
// Stock roles: `water` is FIREWOOD (burned by the head, more in the cold, none aboard the
// steamer; deadwood is gathered below the tree line); `hull` is the outfit and then the
// boat, `sails` the sleds and then the oars & sail; `timber` is canvas & pitch, `sailcloth`
// rope & rawhide, `clothes` furs, `limes` lime juice, `tackle` hooks (casts).

public final class Klondike: Journey {
    public static let id = "klondike"

    init() {
        super.init(id: Self.id, text: Self.strings)
        title = "To the Klondike"
        subtitle = "1898 · Seattle to Dawson City by steamer, on foot and by boat"
        blurb = "A crowded steamer up the coast, a year's grub hauled over a mountain pass one load at a time, and a boat you build yourself to float five hundred miles down to the gold fields, ahead of the crowd if you can."
        items = KlondikeData.items
        stops = KlondikeData.stops
        regions = KlondikeData.regions
        ports = Self.towns
        weathers = KlondikeData.weathers
        fairWeather = KlondikeData.fair
        deficiency = KlondikeData.scurvy
        ailments = KlondikeData.mildPool

        roles[.merchant] = RoleInfo(label: "Be a storekeeper from Seattle", title: "storekeeper",
                                    money: 1700, mend: 25, patch: 20, catchLimit: 150, aim: 1.5)
        roles[.shipwright] = RoleInfo(label: "Be a boatbuilder from Port Townsend", title: "boatbuilder",
                                      money: 1000, mend: 40, patch: 35, catchLimit: 150, aim: 1.5)
        roles[.whaler] = RoleInfo(label: "Be a hard-rock miner from Leadville", title: "miner",
                                  money: 720, mend: 25, patch: 20, catchLimit: 150, aim: 1.5)

        // `speed` is a factor: each leg has its own distance a day (KlondikeData.base). `hp`
        // is the boat's; the trail's and the steamer's come from `paceHP`.
        paces[.easy] = PaceInfo(name: "Easy going", speed: 0.75, hp: 0.5, wear: 0.6,
                                desc: "Light loads and early camps; on the river, let the current do the work. Gentle on gear and people.")
        paces[.steady] = PaceInfo(name: "Steady", speed: 1, hp: 0, wear: 1,
                                  desc: "A fair day's work, trail or river.")
        paces[.full] = PaceInfo(name: "Hard driving", speed: 1.3, hp: -1, wear: 2,
                                desc: "Heavy packs, long days, oars always in the water. Fast, but hard on sleds, boats and backs.")

        rationings[.filling] = RationsInfo(name: "Filling", amount: 3, hp: 1,
                                           desc: "3 lbs a day. Flapjacks, bacon and beans, three times over.")
        rationings[.meager] = RationsInfo(name: "Meager", amount: 2, hp: -0.3,
                                          desc: "2 lbs a day. Two small meals and a lot of tea.")
        rationings[.bare] = RationsInfo(name: "Bare bones", amount: 1, hp: -2.2,
                                        desc: "1 lb a day. A biscuit and a strip of bacon.")

        departures = KlondikeData.departures
        firstNames = KlondikeData.firstNames
        vesselNames = KlondikeData.boatNames
        defaultTopTen = KlondikeData.defaultTopTen
        quarry = KlondikeData.fish
        forageSeconds = 25
        forageReward = .food

        // Firewood: 4 lbs a head a day at cool, scaled by the cold (`waterNeed`).
        rules.water = KlondikeData.firewoodPerHead
        rules.hotWater = KlondikeData.firewoodPerHead * KlondikeData.burn(.hot)
        // The shared spoilage roll and the two wear warnings speak of one vessel; this
        // journey has an outfit and then a boat, so `tick` does all three in their words.
        rules.spoilBelow = -1
        rules.hullWarn = -1
        rules.sailsWarn = -1
    }

    // MARK: - Sentences

    static let strings = JourneyText(
        rainCaught: { "The party gathers \($0) lbs of deadwood." },
        outOfFood: "[red]The grub is gone![/red] Your party is starving.",
        lowFood: "The cook warns you: provisions will last about a week.",
        outOfWater: "[red]The woodpile is gone![/red] Without a fire, the cold will kill you within days.",
        lowWater: "The woodpile is nearly gone — a few days left.",
        preventiveGone: "The last of the lime juice is gone. Scurvy will follow within a few weeks unless you find fresh food.",
        outOfFuel: "",
        lowFuel: "",
        deficiencyCured: { "\($0) is recovering from scurvy." },
        wellAgain: { "\($0) is well again." },
        hasAilment: { name, a in "\(name) has \(a.name)." },
        deficiencyHint: " [dim]Soft gums, and old bruises that won't fade. Lime juice or a stay in town will cure it.[/dim]",
        medsUsed: { " [dim]You open the medicine chest (\($0) \($0 == 1 ? "kit" : "kits") left).[/dim]" },
        causeThirst: "exposure",
        causeStarvation: "starvation",
        causeExhaustion: "exhaustion",
        leaderDied: { name, cause in "You, \(name), have died of \(cause)." },
        leaderDiedBody: "Your partners split up the outfit. One or two go on to Dawson; the rest turn for home. The journey is over.",
        spoiled: { "Meltwater has gotten into a cache. \($0) lbs of provisions are spoiled." },
        hullWarning: "[red]Your outfit is falling apart.[/red] Sacks split, tarps in rags — patch it before you lose it.",
        sailsWarning: "[red]Your sleds are wrecks and your straps are knotted string.[/red] Every load takes twice as long. Mend them if you can.",
        wrecked: { "The [i]\($0)[/i] has broken up." },
        wreckedBody: "Her planks sprang one after another, and the river took her and everything in her. You stand on a gravel bar with the clothes on your back. The Klondike will have to wait for another year.",
        depart: { s in
            "Your steamer backs away from the Seattle waterfront on \(s.dateText), so crowded that people are sleeping on the freight. Behind you the city's hills sink into the rain. Ahead lie a thousand miles of coast, a mountain pass and a river."
        },
        noProvisions: "You can't go north with no provisions! The outfitter laughs and points you back inside.",
        rested: { days, h in
            "After \(days) \(days == 1 ? "day" : "days") of rest, your party's health is [\(h.color)]\(h.text)[/\(h.color)]."
        },
        mended: { "A day of splicing, lacing and shaving new runners. [green](Sleds now \($0)%)[/green]" },
        patched: { "You spend the day re-sacking split flour and lashing new tarps over the caches. [green](Outfit now \($0)%)[/green]" },
        yardHull: "A crew re-sacks, re-crates and re-tarps the lot. Your outfit is as good as new.",
        yardSails: "The sled maker fits new runners and fresh harness.",
        noTradersLeft: "Nobody else in camp wants to trade with you today.",
        nobodyWants: "You ask around, but nobody wants what you have.",
        traderIntro: "A packer outside the store looks over your goods.",
        noTackle: "You have no hooks and line left.",
        tooRough: "The wind's far too high to fish.",
        catchReport: { caught, limit, got in
            var t = caught > 0 ? "You caught [amber]\(caught) lbs[/amber] of fish." : "You caught nothing."
            if caught > limit { t += " You can only smoke and keep \(limit) lbs before the rest spoils." }
            if got != 0 { t += " [green]+\(got) lbs of provisions.[/green]" }
            t += " [dim]A day has passed.[/dim]"
            return t
        },
        defaultEpitaph: "Rest easy, partner.",
        tradeOffer: { intro, give, want in
            "\(intro)\n\nThey will give you [amber]\(give)[/amber] for [amber]\(want)[/amber]."
        },
        tradeHave: { "[dim]You have \($0).[/dim]" },
        tradeAccept: "Accept the trade",
        tradeDecline: "Decline",
        tradeDone: "Done. Goods change hands.",
        reached: { stop, s in "You have reached \(Klondike.name(stop, s)).\n[dim]\(s.dateText) · day \(s.day)[/dim]" },
        goAshore: "Go ashore",
        passBy: "Keep going",
        wavesGoodbye: { "\($0) waves goodbye and goes off to look for work." },
        scoreSurvivors: { alive, health in "\(alive) in the party, health \(health.text)" },
        scoreCondition: "Boat & oars",
        scoreProvisions: "Provisions & firewood",
        scoreStores: "Stores & spares",
        scoreCash: "Cash",
        ranks: ["Sourdough", "Old Hand", "Stampeder", "Cheechako"])

    static let crowdLabel = "Ahead of the crowd"

    // MARK: - For the skin: the words that change with the pass and the leg

    /// Distances (`state.mile`, `stop.mile`, `totalMiles`) are in tenths of a mile: divide
    /// by this to show miles.
    public static let unitsPerMile = KlondikeData.unitsPerMile

    /// A distance in tenths, as the status line and the legend show it: "1,136.5".
    public static func mileNumber(_ units: Int) -> String { KlondikeData.mileNumber(units) }

    /// A distance in tenths, in words: "1,136.5 miles".
    public static func miles(_ units: Int) -> String { KlondikeData.miles(units) }

    /// The chart's line under the legend: "1,136.5 of 1,700.0 miles traveled. 563.5 to go."
    public static func progress(_ s: GameState) -> String {
        let total = KlondikeData.stops[KlondikeData.stops.count - 1].mile
        return "\(mileNumber(s.mile)) of \(mileNumber(total)) miles traveled. \(mileNumber(total - s.mile)) to go."
    }

    static func route(_ s: GameState) -> Double? { s.vars[KlondikeData.routeKey] }
    static func onWhitePass(_ s: GameState) -> Bool { route(s) == KlondikeData.whitePass }

    /// Whether the boat has been built (or bought) at Bennett: the two meters are the boat's.
    public static func hasBoat(_ s: GameState) -> Bool { s.vars[KlondikeData.boatKey] != nil }

    /// What the two meters are called now: the structure (`hull`) and the drive (`sails`).
    public static func meterNames(_ s: GameState) -> (structure: String, drive: String) {
        hasBoat(s) ? ("Boat", "Oars & sail") : ("Outfit", "Sleds")
    }

    /// "steamer", "foot" or "boat": how the party is travelling where it is.
    public static func legName(_ s: GameState) -> String { leg(s).rawValue }

    /// The leg the party is on. Camped at Bennett, it is still on foot until it has a boat:
    /// the town stands at the start of the boat leg's country.
    static func leg(_ s: GameState) -> KlondikeData.Leg {
        if s.mile == KlondikeData.bennettMile && !hasBoat(s) { return .foot }
        return KlondikeData.leg(s.region)
    }

    /// Camped at Lake Bennett before the ice goes out.
    static func frozenAtBennett(_ s: GameState) -> Bool { s.mile == KlondikeData.bennettMile && !iceOut(s) }

    /// "You have reached ___": the pass's own name once the pass is chosen. Before it, the
    /// landing reads as the head of Lynn Canal's.
    public static func name(_ stop: Stop, _ s: GameState) -> String {
        guard let v = KlondikeData.variants[stop.id] else { return stop.name }
        switch route(s) {
        case KlondikeData.chilkoot?: return v.chilkoot.name
        case KlondikeData.whitePass?: return v.whitePass.name
        default: return stop.id == "landing" ? "the landing at Lynn Canal" : stop.name
        }
    }

    /// The legend's and the status panel's name: "Dyea · Skagway" before the fork.
    public static func shortName(_ stop: Stop, _ s: GameState) -> String {
        guard let v = KlondikeData.variants[stop.id] else { return stop.short }
        switch route(s) {
        case KlondikeData.chilkoot?: return v.chilkoot.short
        case KlondikeData.whitePass?: return v.whitePass.short
        default: return stop.short
        }
    }

    /// The year of grub the police will want at the summit, for everyone in the party now.
    public static func requirement(_ s: GameState) -> Double { KlondikeData.yearOfGrub * Double(s.living.count) }

    /// The warning before leaving Seattle with less than the police will want, or nil. The
    /// skin offers "Back to the shop" and "Leave anyway".
    public static func shortOfGrubWarning(_ s: GameState) -> String? {
        let req = requirement(s)
        guard s.food < req else { return nil }
        return "You have [amber]\(formatNumber(s.food)) lbs[/amber] of provisions. The police at the summit will want [amber]\(formatNumber(req))[/amber] — a year's worth for every one of you."
    }

    /// The finale's two paragraphs.
    public static func finale(_ s: GameState) -> (title: String, body: String) {
        let title = "The [i]\(TextMarkup.escape(s.ship))[/i] noses into the mud below Dawson City on \(s.dateText), \(s.day) days after you left Seattle."
        var body = "The bank is lined three deep with boats, and the town behind them is a sprawl of tents, saloons and fresh-sawn lumber. Every creek for miles was staked before you left home — but there is work at wages nobody in Seattle would believe, and you have most of a year's grub to live on while you look."
        body += s.living.count > 1 ? " Your partners are already asking the way to the creeks."
            : " You stand alone on the bank, asking the way to the creeks."
        return (title, body)
    }

    /// The burial screen's line, by where it happens. `name` is escaped here.
    public static func burialText(_ s: GameState, name: String) -> String {
        let n = TextMarkup.escape(name)
        switch leg(s) {
        case .steamer: return "The purser has \(n) carried ashore at the next landing and buried on a hill above the water. What words will you say?"
        case .foot: return "Your partners lay \(n) to rest beside the trail under a cairn of stones, with a cross cut from a packing crate. What words will you say?"
        case .boat: return "You bury \(n) on a bluff above the river, where the boats going by can see the cross. What words will you say?"
        }
    }

    // MARK: - Where and when

    /// The fork swaps the Chilkoot's three regions for the White Pass's.
    public override func region(_ s: GameState, at m: Int) -> Region {
        if Self.onWhitePass(s), let r = KlondikeData.whitePassRegions.first(where: { m < $0.to }),
           m >= KlondikeData.landingMile {
            return r
        }
        return regions.first { m < $0.to } ?? regions[regions.count - 1]
    }

    public override func temperature(_ s: GameState, in reg: Region) -> Temp {
        KlondikeData.temps[reg.id]?[KlondikeData.season(s.month).rawValue] ?? reg.temp
    }

    public override func harshSeason(_ s: GameState) -> Bool { KlondikeData.deepWinter(s.month) }

    /// The season's list; the ice is off the river from July; sundogs force clear skies.
    override func weatherWeights(_ e: GameEngine, _ reg: Region, cursed: Bool) -> WeatherOdds {
        if (e.state.vars[KlondikeData.clearKey] ?? 0) > 0 { return [(KlondikeData.clear, 1)] }
        let month = e.state.month
        var w = KlondikeData.odds[reg.id]?[KlondikeData.season(month).rawValue] ?? reg.weights
        // No ice running on the river from July, nor on a lake that is still frozen.
        if KlondikeData.leg(reg) == .boat && (month >= 6 || Self.frozenAtBennett(e.state)) {
            w.removeAll { $0.0 == KlondikeData.ice }
        }
        return w
    }

    // MARK: - A turn under way

    /// The steamer is a passenger leg: the captain's pace, nothing of yours. On foot and
    /// afloat the shared formula runs on the leg's own distance a day.
    override func adjustSpeed(_ e: GameEngine, _ reg: Region, _ sp: inout Double) {
        switch KlondikeData.leg(reg) {
        case .steamer:
            sp = KlondikeData.base(.steamer) * e.state.weather.speed
        case .foot:
            sp *= KlondikeData.base(.foot) * reg.num("speed")
            if e.state.role == .whaler { sp *= KlondikeData.minerTrail }
            if e.state.vars[KlondikeData.packersKey] == 1 && e.state.mile < KlondikeData.summitMile {
                sp *= KlondikeData.packersFactor
            }
        case .boat:
            sp *= KlondikeData.base(.boat) * reg.num("speed")
        }
    }

    /// Hauling a ton over a pass is harder than rowing, and the steamer is no work at all.
    /// A day of hauling off the route (`haulDays`) is the trail's work wherever it is.
    public override func paceHP(_ s: GameState) -> Double {
        let reg = s.region
        let leg = s.vars[KlondikeData.haulingKey] != nil ? KlondikeData.Leg.foot : KlondikeData.leg(reg)
        let hp = KlondikeData.paceHP(leg, s.pace)
        return reg.has("gentle") ? hp * KlondikeData.gentleFactor : hp
    }

    /// Firewood by the head, by the cold; the steamer keeps its own stove.
    public override func waterNeed(_ s: GameState, _ temp: Temp) -> Double {
        if KlondikeData.leg(s.region) == .steamer { return 0 }
        return KlondikeData.firewoodPerHead * KlondikeData.burn(temp)
    }

    /// Nothing of yours wears aboard the steamer.
    override func propulsionWear(_ e: GameEngine) -> Double {
        KlondikeData.leg(e.state.region) == .steamer ? 0 : super.propulsionWear(e)
    }

    /// Blizzards bury caches (worse on the slide slopes), wind tears, ice grinds.
    override func structureDamage(_ e: GameEngine, _ reg: Region) -> Double {
        if KlondikeData.leg(reg) == .steamer { return 0 }
        var hd = rules.hullCreep
        let w = e.state.weather
        let full = e.state.pace == .full
        if w == KlondikeData.blizzard {
            hd += e.rnd(1, 2.6) * (full ? 1.6 : e.state.pace == .easy ? 0.7 : 1) * (reg.has("slides") ? 1.5 : 1)
        } else if w == KlondikeData.wind {
            hd += e.rnd(0, 0.8) * (full ? 1.5 : 1)
        } else if w == KlondikeData.ice {
            hd += e.rnd(0, 1.2) * (full ? 1.5 : 1)
        }
        return hd
    }

    public override func wreckedTitle(_ s: GameState) -> String {
        Self.hasBoat(s) ? text.wrecked(TextMarkup.escape(s.ship)) : "Your outfit is ruined."
    }

    /// Ruined before the summit, there is nothing to show the police; past it, nothing to
    /// build a boat with.
    public override func wreckedBody(_ s: GameState) -> String {
        if Self.hasBoat(s) { return text.wreckedBody }
        return s.mile > KlondikeData.summitMile
            ? "Split sacks, sodden flour, a stove with no pipe. There's nothing left worth carrying to the lakes and nothing to live on if you got there. You sell the scraps to a party coming up and walk back over the pass for a ticket home."
            : "Split sacks, sodden flour, a stove with no pipe. There's nothing left worth carrying and nothing to show the police. You sell the scraps for a ticket home."
    }

    override func tick(_ e: GameEngine, _ q: inout [Interrupt], _ mode: GameEngine.DayMode, _ reg: Region) {
        let leg = KlondikeData.leg(reg)
        let boat = Self.hasBoat(e.state)
        if mode != .port, let left = e.state.vars[KlondikeData.clearKey], left > 0 {
            e.state.vars[KlondikeData.clearKey] = left - 1
        }
        if mode == .sail && leg != .steamer {
            // A wet cache or a full bilge.
            if e.state.hull < 35 && e.state.food > 50 && e.chance(0.06) {
                let l = e.ri(20, 60)
                e.state.food = max(0, e.state.food - Double(l))
                q.append(.message(boat ? "The bilge is full and the grub is in it. \(l) lbs of provisions are spoiled."
                                       : text.spoiled(l)))
            }
        }
        // The blizzard's line is the trail's.
        if mode == .sail && leg != .foot && e.state.weather == KlondikeData.blizzard { e.state.note = "" }

        // Deadwood below the tree line, any day not in town.
        let wood = item(.water)
        if mode != .port && reg.has("timber") && e.state.weather != KlondikeData.blizzard && e.state.water < wood.cap {
            let n = e.ri(KlondikeData.deadwood.lowerBound, KlondikeData.deadwood.upperBound)
            e.state.add(.water, Double(n))
            e.state.note = text.rainCaught(n)
        }

        // The wear warnings, in the words of what is wearing.
        if e.state.hull < 30 && !e.state.flags.hull {
            e.state.flags.hull = true
            q.append(.message(boat ? "[red]She's leaking like a basket.[/red] Somebody bails day and night. Patch her — soon."
                                   : text.hullWarning))
        }
        if e.state.hull > rules.warnRearm { e.state.flags.hull = false }
        if e.state.sails < 25 && !e.state.flags.sails {
            e.state.flags.sails = true
            q.append(.message(boat ? "[red]The sail is in rags and you're down to one good oar.[/red] She barely answers the sweep. Mend them if you can."
                                   : text.sailsWarning))
        }
        if e.state.sails > rules.warnRearm { e.state.flags.sails = false }
    }

    override func sickPool(_ e: GameEngine, _ temp: Temp, _ port: Port?) -> [Ailment] {
        if port?.fever == true { return KlondikeData.feverPortPool }
        switch temp {
        case .hot: return KlondikeData.hotPool
        case .cold, .freezing: return KlondikeData.coldPool
        case .cool, .warm: return KlondikeData.mildPool
        }
    }

    /// Fish need open water you are stopped beside.
    override func forageRefusal(_ e: GameEngine) -> String? {
        if e.state.tackle <= 0 { return text.noTackle }
        let reg = e.state.region
        if KlondikeData.leg(reg) == .steamer { return "The steamer won't stop so you can fish." }
        if !reg.has("fishable") { return "There's nothing to fish in up here but snow." }
        if e.state.weather.isRough { return text.tooRough }
        return nil
    }

    /// The repair lines are the outfit's until the boat is built.
    public override func repaired(_ s: GameState, _ job: RepairJob) -> String {
        guard Self.hasBoat(s) else { return super.repaired(s, job) }
        switch job {
        case .mend:
            return "You shave a new oar from a spruce and lace up the sail. [green](Oars & sail now \(Int(jsRound(s.sails)))%)[/green]"
        case .patch:
            return "You haul her up on the gravel, tack canvas over the worst seams and pay them with hot pitch. [green](Boat now \(Int(jsRound(s.hull)))%)[/green]"
        case .yardHull: return "The boatwrights haul her out and recaulk every seam. She's tight."
        case .yardSails: return "New oars, a new sweep, and a sail sewn from good duck."
        }
    }

    // MARK: - Events, stops and answers (Klondike+Events, Klondike+Towns, Klondike+Choices)

    override func dayEvents(_ e: GameEngine, _ q: inout [Interrupt], _ reg: Region) { trailDay(e, &q, reg) }

    override func events(_ e: GameEngine, _ reg: Region) -> [JourneyEvent] { trailEvents(e, reg) }

    override func arrive(_ e: GameEngine, _ stop: Stop) -> [Interrupt] {
        switch stop.type {
        case .port: return townArrival(e, stop)
        case .mark where stop.id == "lakes": return [.message(lakesNote(e.state))]
        default: return super.arrive(e, stop)
        }
    }

    override func special(_ e: GameEngine, _ stop: Stop) -> [Interrupt] { setPiece(e, stop) }

    override func resolve(_ e: GameEngine, _ key: String, _ args: [String], _ option: Int) -> [Interrupt] {
        answer(e, key, args, option)
    }

    public override func port(_ s: GameState, at stopID: String) -> Port? {
        if Self.onWhitePass(s), let p = Self.whitePassTowns.first(where: { $0.id == stopID }) { return p }
        return port(stopID)
    }

    override func holdInPort(_ e: GameEngine) -> [Interrupt]? { bennettHold(e) }

    // MARK: - Trade and score

    /// A trader prices grub and wood above what Seattle charges for them.
    public override func tradeValue(_ good: TradeGood) -> Double {
        switch good {
        case .item(.food): return 0.14
        case .item(.water): return 0.03
        default: return super.tradeValue(good)
        }
    }

    /// The names already carry their units: "2 coils of rope & rawhide", "3 boxes of hooks & line".
    public override func describe(_ good: TradeGood, _ amount: Double) -> String {
        let n = jsNumber(amount)
        let one = amount == 1
        switch good {
        case .money: return "$\(formatNumber(amount))"
        case .item(.food): return "\(formatNumber(amount)) lbs of provisions"
        case .item(.water): return "\(formatNumber(amount)) lbs of firewood"
        case .item(.limes): return "\(n) \(one ? "jug" : "jugs") of lime juice"
        case .item(.meds): return "\(n) medicine \(one ? "kit" : "kits")"
        case .item(.clothes): return "\(n) \(one ? "set" : "sets") of furs"
        case .item(.sailcloth): return "\(n) \(one ? "coil" : "coils") of rope & rawhide"
        case .item(.timber): return "\(n) \(one ? "bundle" : "bundles") of canvas & pitch"
        case .item(.tackle):
            let boxes = amount / 20
            return "\(jsNumber(boxes)) \(boxes == 1 ? "box" : "boxes") of hooks & line"
        case .item(.fuel): return n
        }
    }

    /// Days before August 1, 1898 that the party reaches Dawson.
    static func daysAhead(_ s: GameState) -> Int { max(0, KlondikeData.august1 - KlondikeData.dayOfYear(s)) }

    public override func score(_ s: GameState) -> Score {
        let alive = s.living.count
        let health = s.healthLabel
        let stores = Int(s.limes.rounded(.down)) * 2 + s.meds * 5 + s.clothes * 2 + s.sailcloth * 4 + s.timber * 4
            + s.tackle / 20
        return Score(lines: [
            .init(label: text.scoreSurvivors(alive, health), points: alive * health.scorePerSurvivor),
            .init(label: text.scoreCondition, points: Int(jsRound(s.hull * 2 + s.sails))),
            .init(label: text.scoreProvisions,
                  points: Int((s.food / 25).rounded(.down)) + Int((s.water / 50).rounded(.down))),
            .init(label: text.scoreStores, points: stores),
            .init(label: text.scoreCash, points: Int((s.money / 5).rounded(.down))),
            .init(label: Self.crowdLabel, points: Self.daysAhead(s) * KlondikeData.crowdBonusPerDay),
        ], multiplier: s.role.scoreMultiplier)
    }
}
