#if os(WASI)
import FoundationEssentials
#else
import Foundation
#endif

// What the player does from a menu: shop, depart, rest, repair, trade, talk, forage, bury.

extension GameEngine {
    // MARK: - Shop

    /// The port whose prices apply right now.
    public var currentPort: Port? { journey.port(state, at: state.currentStop.id) }

    /// Most bought units of `key` that still fit aboard (the shop's + cap).
    public func room(for key: ItemKey) -> Int {
        let it = journey.item(key)
        return max(0, Int(((it.cap - state[key]) / Double(it.per)).rounded(.down)))
    }

    public static func bill(_ cart: [ItemKey: Int], at port: Port) -> Double {
        Journeys.journey(port.journey).items.reduce(0) { $0 + Double(cart[$1.key] ?? 0) * port.price($1.key) }
    }

    /// Pays for `cart` (bought units per item) at the current port. False, and nothing
    /// changes, if it costs more than you have.
    @discardableResult
    public func buy(_ cart: [ItemKey: Int]) -> Bool {
        guard let port = currentPort else { return false }
        let total = Self.bill(cart, at: port)
        guard total <= state.money else { return false }
        state.money -= total
        for it in journey.items { state.add(it.key, Double((cart[it.key] ?? 0) * it.per)) }
        return true
    }

    // MARK: - Departure

    /// Leaving the first port. Nil, and nobody leaves, if there's no food (the journey's
    /// `text.noProvisions` says why); otherwise the setting-off message.
    public func depart() -> String? {
        if state.food <= 0 || !journey.mayDepart(state) { return nil }
        state.atPort = false
        journey.leaving(self)
        return journey.text.depart(state)
    }

    /// Leave a port along the way. Also called to resume travel between ports, where it
    /// changes nothing. A journey can hold you ashore (`Journey.holdInPort`): then you are
    /// still in port, and what it returns is what happens instead. Empty when you leave.
    @discardableResult
    public func setSail() -> [Interrupt] {
        let ashore = state.atPort
        if ashore, let hold = journey.holdInPort(self) { return hold }
        state.atPort = false
        if ashore { journey.leaving(self) }
        return []
    }

    // MARK: - Rest

    public func rest(days: Int) -> [Interrupt] {
        var q = passDays(days, state.atPort ? .port : .sea)
        if !state.over { q.append(.message(journey.text.rested(days, state.healthLabel))) }
        return q
    }

    // MARK: - Repairs under way

    public var canMendSails: Bool { state.sailcloth >= 1 && state.sails < 100 }
    public var canPatchHull: Bool { state.timber >= 1 && state.hull < 100 }

    public func mendSails() -> [Interrupt] {
        guard canMendSails else { return [] }
        state.sailcloth -= 1
        state.sails = min(100, state.sails + journey.role(state.role).mend)
        var q = passDays(1, .sea)
        if !state.over { q.append(.message(journey.repaired(state, .mend))) }
        return q
    }

    public func patchHull() -> [Interrupt] {
        guard canPatchHull else { return [] }
        state.timber -= 1
        state.hull = min(100, state.hull + journey.role(state.role).patch)
        var q = passDays(1, .sea)
        if !state.over { q.append(.message(journey.repaired(state, .patch))) }
        return q
    }

    // MARK: - The yard

    public var shipyardHullCost: Int {
        Int(((100 - state.hull) * journey.rules.yardHull * (currentPort?.mult ?? 1)).rounded(.up))
    }

    public var shipyardSailsCost: Int {
        Int(((100 - state.sails) * journey.rules.yardSails * (currentPort?.mult ?? 1)).rounded(.up))
    }

    public var canRepairHullAtYard: Bool { state.hull < 99.5 && state.money >= Double(shipyardHullCost) }
    public var canRecutSailsAtYard: Bool { state.sails < 99.5 && state.money >= Double(shipyardSailsCost) }

    public func repairHullAtYard() -> [Interrupt] {
        guard canRepairHullAtYard else { return [] }
        state.money -= Double(shipyardHullCost)
        state.hull = 100
        var q = passDays(1, .port)
        if !state.over { q.append(.message(journey.repaired(state, .yardHull))) }
        return q
    }

    public func recutSailsAtYard() -> [Interrupt] {
        guard canRecutSailsAtYard else { return [] }
        state.money -= Double(shipyardSailsCost)
        state.sails = 100
        var q = passDays(1, .port)
        if !state.over { q.append(.message(journey.repaired(state, .yardSails))) }
        return q
    }

    // MARK: - Port: trade and talk

    public func tradeAtPort() -> [Interrupt] {
        let text = journey.text
        if state.tradesLeft <= 0 { return [.message(text.noTradersLeft)] }
        state.tradesLeft -= 1
        guard let o = makeOffer() else { return [.message(text.nobodyWants)] }
        return [.choice(tradeChoice(o, intro: text.traderIntro))]
    }

    public func talk() -> String {
        guard let port = currentPort, !port.talk.isEmpty else { return "" }
        let t = port.talk[state.talkIndex % port.talk.count]
        state.talkIndex += 1
        return t
    }

    // MARK: - Foraging (spec §9; 1849's is fishing)

    /// Why you can't forage right now, or nil if you can.
    public var fishingRefusal: String? { journey.forageRefusal(self) }

    /// One throw. False if there's no tackle left.
    @discardableResult
    public func throwHarpoon() -> Bool {
        guard state.tackle > 0 else { return false }
        state.tackle -= 1
        return true
    }

    /// The outing is over: keep what can be stowed, then a turn passes.
    public func landCatch(_ caught: Int) -> [Interrupt] {
        let limit = journey.role(state.role).catchLimit
        let kept = min(caught, limit)
        let reward = journey.forageReward
        let room = Int((journey.item(reward).cap - state[reward]).rounded(.down))
        let got = min(kept, room)
        state.add(reward, Double(got))
        journey.foraged(self)
        return [.message(journey.text.catchReport(caught, limit, got))] + passDays(1, .sea)
    }

    // MARK: - Burial

    /// Records the grave the burial screen wrote. An empty epitaph takes the placeholder.
    public func commitBurial(crewID: UUID, cause: String, epitaph: String) {
        guard let p = state.crew.first(where: { $0.id == crewID }) else { return }
        let e = epitaph.trimmingCharacters(in: .whitespacesAndNewlines)
        state.graves.append(Grave(name: p.name, cause: cause, date: state.dateText,
                                  epitaph: e.isEmpty ? journey.text.defaultEpitaph : String(e.prefix(70))))
    }
}
