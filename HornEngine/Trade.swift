// The prototype's `makeOffer` (spec §5.8). What each good is worth, how amounts round and
// how they read come from the journey.

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
    /// A trader's offer, or nil when you have nothing they want or they have nothing
    /// you lack. Every random draw is taken in the prototype's order, including the one a
    /// pick from an empty list still spends. The journey's `fitOffer` has the last word,
    /// after every draw. Goods in `excluding` are neither wanted nor
    /// given; they are left out before any draw, so an empty list changes nothing.
    func makeOffer(excluding: [ItemKey] = []) -> Offer? {
        let r = journey.rules
        let keys = excluding.isEmpty ? journey.tradeKeys : journey.tradeKeys.filter { !excluding.contains($0) }
        var wantable: [TradeGood] = keys.filter { state[$0] * journey.tradeValue(.item($0)) >= r.tradeWorth }
            .map { .item($0) }
        if state.money >= r.tradeCash { wantable.append(.money) }
        if wantable.isEmpty { return nil }
        guard let want = pick(wantable) else { return nil }
        let giveCandidates = keys.filter { .item($0) != want && state[$0] < journey.item($0).cap * 0.8 }
        guard let giveKey = pick(giveCandidates) else { return nil }
        let give = TradeGood.item(giveKey)

        let v = rng.uniform(r.tradeSize.lowerBound, r.tradeSize.upperBound)
        let wantAmount = journey.roundTrade(want, min(state[want] * 0.6, v * rng.uniform(1, 1.35) / journey.tradeValue(want)))
        let giveAmount = journey.roundTrade(give, v * rng.uniform(0.8, 1.1) / journey.tradeValue(give))
        if Double(wantAmount) > state[want] { return nil }
        return journey.fitOffer(self, Offer(give: give, giveAmount: giveAmount, want: want, wantAmount: wantAmount))
    }

    func applyTrade(_ o: Offer) {
        state[o.want] -= Double(o.wantAmount)
        switch o.give {
        case .item(let k): state.add(k, Double(o.giveAmount))
        case .money: state.money += Double(o.giveAmount)  // the prototype never offers money
        }
    }
}

/// A number as JavaScript prints it: "3", "1.5", never "3.0".
func jsNumber(_ x: Double) -> String {
    x == x.rounded() && abs(x) < 1e15 ? String(Int(x)) : String(x)
}
