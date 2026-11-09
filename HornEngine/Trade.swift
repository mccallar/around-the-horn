// The prototype's `makeOffer` and `describe` (spec §5.8).

public enum TradeGood: Codable, Equatable, Hashable {
    case money
    case item(ItemKey)
}

public struct Offer: Codable, Equatable {
    /// What the trader hands over, in stored units.
    public let give: TradeGood
    public let giveAmount: Int
    /// What the trader wants from you.
    public let want: TradeGood
    public let wantAmount: Int
}

extension GameEngine {
    static let tradeKeys: [ItemKey] = [.food, .water, .limes, .meds, .clothes, .sailcloth, .timber, .tackle]

    /// A trader's offer, or nil when you have nothing they want or they have nothing
    /// you lack. Every random draw is taken in the prototype's order, including the one a
    /// pick from an empty list still spends.
    func makeOffer() -> Offer? {
        let keys = Self.tradeKeys
        var wantable: [TradeGood] = keys.filter { state[$0] * GameData.tradeValue(.item($0)) >= 25 }.map { .item($0) }
        if state.money >= 30 { wantable.append(.money) }
        if wantable.isEmpty { return nil }
        guard let want = pick(wantable) else { return nil }
        let giveCandidates = keys.filter { .item($0) != want && state[$0] < GameData.item($0).cap * 0.8 }
        guard let giveKey = pick(giveCandidates) else { return nil }
        let give = TradeGood.item(giveKey)

        let v = rng.uniform(25, 70)
        let wantAmount = Self.roundTrade(want, min(state[want] * 0.6, v * rng.uniform(1, 1.35) / GameData.tradeValue(want)))
        let giveAmount = Self.roundTrade(give, v * rng.uniform(0.8, 1.1) / GameData.tradeValue(give))
        if Double(wantAmount) > state[want] { return nil }
        return Offer(give: give, giveAmount: giveAmount, want: want, wantAmount: wantAmount)
    }

    /// Food and water to 10s (min 10), tackle to 20s (min 20), money to 5s (min 5),
    /// everything else to whole units (min 1).
    static func roundTrade(_ good: TradeGood, _ v: Double) -> Int {
        switch good {
        case .item(.food), .item(.water): return Int(max(10, jsRound(v / 10) * 10))
        case .item(.tackle): return Int(max(20, jsRound(v / 20) * 20))
        case .money: return Int(max(5, jsRound(v / 5) * 5))
        default: return Int(max(1, jsRound(v)))
        }
    }

    func applyTrade(_ o: Offer) {
        state[o.want] -= Double(o.wantAmount)
        switch o.give {
        case .item(let k): state.add(k, Double(o.giveAmount))
        case .money: state.money += Double(o.giveAmount)  // the prototype never offers money
        }
    }
}

/// The prototype's `describe`: "120 lbs of provisions", "2 crates of citrus", "$45".
public func describe(_ good: TradeGood, _ a: Double) -> String {
    let n = jsNumber(a)
    let s = a > 1 ? "s" : ""
    switch good {
    case .money: return "$\(n)"
    case .item(let k):
        switch k {
        case .food: return "\(n) lbs of provisions"
        case .water: return "\(n) gallons of water"
        case .limes: return "\(n) crate\(s) of citrus"
        case .meds: return "\(n) medicine kit\(s)"
        case .clothes: return "\(n) set\(s) of woolens"
        case .sailcloth: return "\(n) bolt\(s) of sailcloth"
        case .timber: return "\(n) bundle\(s) of timber"
        case .tackle: return "\(jsNumber(a / 20)) box\(a > 20 ? "es" : "") of fishing tackle"
        }
    }
}

/// A number as JavaScript prints it: "3", "1.5", never "3.0".
func jsNumber(_ x: Double) -> String {
    x == x.rounded() && abs(x) < 1e15 ? String(Int(x)) : String(x)
}
