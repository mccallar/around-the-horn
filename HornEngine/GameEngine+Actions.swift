import Foundation

// What the player does from a menu: shop, depart, rest, repair, trade, talk, fish, bury.

extension GameEngine {
    // MARK: - Shop

    /// The port whose prices apply right now.
    public var currentPort: Port? { state.currentStop.portID.map(GameData.port) }

    /// Most bought units of `key` that still fit aboard (the shop's + cap).
    public func room(for key: ItemKey) -> Int {
        let it = GameData.item(key)
        return max(0, Int(((it.cap - state[key]) / Double(it.per)).rounded(.down)))
    }

    public static func bill(_ cart: [ItemKey: Int], at port: Port) -> Double {
        GameData.items.reduce(0) { $0 + Double(cart[$1.key] ?? 0) * port.price($1.key) }
    }

    /// Pays for `cart` (bought units per item) at the current port. False, and nothing
    /// changes, if it costs more than you have.
    @discardableResult
    public func buy(_ cart: [ItemKey: Int]) -> Bool {
        guard let port = currentPort else { return false }
        let total = Self.bill(cart, at: port)
        guard total <= state.money else { return false }
        state.money -= total
        for it in GameData.items { state.add(it.key, Double((cart[it.key] ?? 0) * it.per)) }
        return true
    }

    // MARK: - Departure

    /// Leaving New York. Nil and the ship stays if there's no food; otherwise the
    /// casting-off message.
    public func departNewYork() -> String? {
        if state.food <= 0 { return nil }
        state.atPort = false
        return "The [i]\(TextMarkup.escape(state.ship))[/i] casts off from South Street on \(state.dateText). Behind you, New York shrinks to a smudge of chimney smoke. Ahead lie fourteen thousand miles of ocean."
    }

    public static let noProvisionsRefusal =
        "You can't put to sea with no provisions! The chandler shakes his head and points you back inside."

    /// Weigh anchor / continue on your voyage.
    public func setSail() {
        state.atPort = false
    }

    // MARK: - Rest

    public func rest(days: Int) -> [Interrupt] {
        var q = passDays(days, state.atPort ? .port : .sea)
        if !state.over {
            let h = state.healthLabel
            q.append(.message("After \(days) day\(days > 1 ? "s" : "") of rest, your crew's health is [\(h.color)]\(h.text)[/\(h.color)]."))
        }
        return q
    }

    // MARK: - Repairs at sea

    public var canMendSails: Bool { state.sailcloth >= 1 && state.sails < 100 }
    public var canPatchHull: Bool { state.timber >= 1 && state.hull < 100 }

    public func mendSails() -> [Interrupt] {
        guard canMendSails else { return [] }
        state.sailcloth -= 1
        state.sails = min(100, state.sails + state.role.sailMend)
        var q = passDays(1, .sea)
        if !state.over {
            q.append(.message("The sailmaker's palm and needle are busy all day. [green](Sails now \(Int(jsRound(state.sails)))%)[/green]"))
        }
        return q
    }

    public func patchHull() -> [Interrupt] {
        guard canPatchHull else { return [] }
        state.timber -= 1
        state.hull = min(100, state.hull + state.role.hullPatch)
        var q = passDays(1, .sea)
        if !state.over {
            q.append(.message("The carpenter caulks and planks over the worst of it. [green](Hull now \(Int(jsRound(state.hull)))%)[/green]"))
        }
        return q
    }

    // MARK: - Shipyard

    public var shipyardHullCost: Int {
        Int(((100 - state.hull) * 2.5 * (currentPort?.mult ?? 1)).rounded(.up))
    }

    public var shipyardSailsCost: Int {
        Int(((100 - state.sails) * 1.8 * (currentPort?.mult ?? 1)).rounded(.up))
    }

    public var canRepairHullAtYard: Bool { state.hull < 99.5 && state.money >= Double(shipyardHullCost) }
    public var canRecutSailsAtYard: Bool { state.sails < 99.5 && state.money >= Double(shipyardSailsCost) }

    public func repairHullAtYard() -> [Interrupt] {
        guard canRepairHullAtYard else { return [] }
        state.money -= Double(shipyardHullCost)
        state.hull = 100
        var q = passDays(1, .port)
        if !state.over { q.append(.message("Shipwrights swarm over her. She is tight as a drum again.")) }
        return q
    }

    public func recutSailsAtYard() -> [Interrupt] {
        guard canRecutSailsAtYard else { return [] }
        state.money -= Double(shipyardSailsCost)
        state.sails = 100
        var q = passDays(1, .port)
        if !state.over { q.append(.message("A sail loft fits you out with fresh canvas.")) }
        return q
    }

    // MARK: - Port: trade and talk

    public func tradeAtPort() -> [Interrupt] {
        if state.tradesLeft <= 0 { return [.message("Nobody else on the waterfront wants to trade with you today.")] }
        state.tradesLeft -= 1
        guard let o = makeOffer() else { return [.message("You walk the quays, but nobody wants what you have.")] }
        return [.choice(choice(.tradeOffer(o, intro: "A trader on the quay looks over your stores.")))]
    }

    public func talk() -> String {
        guard let port = currentPort else { return "" }
        let t = port.talk[state.talkIndex % port.talk.count]
        state.talkIndex += 1
        return t
    }

    // MARK: - Fishing (spec §9)

    /// Why you can't fish right now, or nil if you can.
    public var fishingRefusal: String? {
        if state.tackle <= 0 { return "You have no fishing tackle left." }
        if state.weather.isRough { return "The seas are far too rough to fish." }
        return nil
    }

    /// One harpoon thrown. False if there's no tackle left.
    @discardableResult
    public func throwHarpoon() -> Bool {
        guard state.tackle > 0 else { return false }
        state.tackle -= 1
        return true
    }

    /// The outing is over: keep what the cook can salt, then a day passes.
    public func landCatch(_ caught: Int) -> [Interrupt] {
        let limit = state.role.catchLimit
        let kept = min(caught, limit)
        let room = Int((GameData.item(.food).cap - state.food).rounded(.down))
        let got = min(kept, room)
        state.add(.food, Double(got))
        var t = caught > 0 ? "You caught [amber]\(caught) lbs[/amber] of fish." : "You caught nothing."
        if caught > limit { t += " The cook can only salt and stow \(limit) lbs before the rest spoils." }
        if got != 0 { t += " [green]+\(got) lbs of provisions.[/green]" }
        t += " [dim]A day has passed.[/dim]"
        return [.message(t)] + passDays(1, .sea)
    }

    // MARK: - Burial

    public static let defaultEpitaph = "Fair winds, shipmate."

    /// Records the grave the burial screen wrote. An empty epitaph takes the placeholder.
    public func commitBurial(crewID: UUID, cause: String, epitaph: String) {
        guard let p = state.crew.first(where: { $0.id == crewID }) else { return }
        let e = epitaph.trimmingCharacters(in: .whitespacesAndNewlines)
        state.graves.append(Grave(name: p.name, cause: cause, date: state.dateText,
                                  epitaph: e.isEmpty ? Self.defaultEpitaph : String(e.prefix(70))))
    }
}
