import SwiftUI
import HornEngine

/// The status box (spec §3): date and region, weather, health, stores, next stop,
/// distance, the two meters, and the teal note. Which stores it lists is the journey's
/// business: food always, water if the journey stocks it, fuel if it burns any.
struct StatusPanel: View {
    @Environment(GameController.self) private var c
    let game: GameState

    var body: some View {
        let journey = c.journey, words = c.skin.words(game)
        let next = game.nextStop
        let health = game.healthLabel
        PanelBox(padding: 8) {
            (Text(game.dateText).foregroundColor(Theme.amber)
                + Text(" · \(game.region.name)").foregroundColor(Theme.dim).font(.custom(Theme.bodyFont, size: 18)))
                .bodyFont()
            Row(label: "Weather") {
                Text(game.weather.name).foregroundStyle(Self.isWorst(game.weather, of: journey) ? Theme.red : Theme.ink)
            }
            Row(label: "Health") { Text(health.text).foregroundStyle(HealthLabel.color(health)) }
            ForEach(Self.stores(journey, game, words), id: \.label) { r in
                Row(label: r.label) { Text(r.value) }
            }
            Row(label: "Next: \(next?.short ?? "—")") {
                Text(next.map { "\(words.distance($0.mile - game.mile)) \(words.distanceUnit)" } ?? "")
            }
            Row(label: words.travelled) {
                Text("\(words.distance(game.mile)) of \(words.distance(journey.totalMiles)) \(words.distanceUnit)")
            }
            Row(label: "\(words.meters.0) · \(words.meters.1)") {
                Text("\(Int(jsRounded(game.hull)))% · \(Int(jsRounded(game.sails)))%")
            }
            if let clock = words.clock {
                Row(label: clock.label) { Text(clock.value) }
            }
            if let trouble = words.trouble {
                Row(label: trouble.label) { Text(trouble.value).foregroundStyle(Theme.red) }
            }
            Text(game.note)
                .bodyFont(19)
                .foregroundStyle(Theme.teal)
                .frame(minHeight: 22, alignment: .topLeading)
                .padding(.top, 4)
        }
        .bodyFont()
        .foregroundStyle(Theme.ink)
        .padding(.top, 10)
    }

    /// The weather that reads in red: the hardest on the crew the journey has, by the
    /// rules' own figure (`Weather.harsh`), whatever its sky looks like. 1849's is the
    /// storm; a gale, which is rough but half as hard, reads plain.
    static func isWorst(_ w: Weather, of journey: Journey) -> Bool {
        w.harsh > 0 && w.harsh >= (journey.weathers.map(\.harsh).max() ?? 0)
    }

    /// The rows between health and the next stop.
    static func stores(_ journey: Journey, _ g: GameState, _ words: Words) -> [(label: String, value: String)] {
        var keys: [ItemKey] = [.food]
        if journey.items.contains(where: { $0.key == .water }) { keys.append(.water) }
        if journey.burnsFuel { keys.append(.fuel) }
        return keys.map { key in
            let it = journey.item(key)
            return (words.statusNames[key] ?? it.name, Stores.amount(it, g, words))
        }
    }
}

/// How much of an item there is, as the shop, the lists and the mini-game write it. The
/// engine counts in stored units (`Item.per` of them to the unit the shop sells); nothing
/// here shows a stored count as if it were units.
enum Stores {
    /// How one item is counted.
    struct Counting: Equatable {
        /// What one stored unit is called when the item is counted loose aboard.
        var loose: String?
        /// Counted to a tenth of its unit, not in whole ones.
        var tenths = false
        /// Exactly one is written with `Item.one`.
        var singular = false
    }

    /// An item is counted in tenths when the skin lists it, and whenever it is stored in
    /// parts of its unit (ten to the cord) and isn't counted loose: less than one unit of
    /// it is still something aboard, and has to read as something.
    static func counting(_ it: Item, _ words: Words) -> Counting {
        let loose = words.looseUnits[it.key]
        return Counting(loose: loose, tenths: words.fractional.contains(it.key) || (it.per > 1 && loose == nil),
                        singular: words.singular)
    }

    /// `stored` in the item's own unit, rounded down to a tenth: "9.5", "1.4", "2".
    private static func tenths(_ stored: Double, _ it: Item) -> String {
        let x = (stored * 10 / Double(max(1, it.per))).rounded(.down) / 10
        return x == x.rounded() ? String(Int(x)) : String(x)
    }

    private static func whole(_ stored: Double, _ it: Item) -> Double {
        (stored / Double(max(1, it.per))).rounded(.down)
    }

    /// The unit to write after `count` of an item.
    static func unit(_ it: Item, count: String, _ how: Counting) -> String {
        how.singular && count == "1" ? it.one : it.unit
    }

    static func unit(_ it: Item, count: String, _ words: Words) -> String { unit(it, count: count, counting(it, words)) }

    /// The shop's "Have N": units of the item as it is sold, whole or to a tenth.
    static func have(_ stored: Double, _ it: Item, _ how: Counting) -> String {
        how.tenths ? tenths(stored, it) : String(Int(whole(stored, it)))
    }

    static func have(_ it: Item, _ g: GameState, _ words: Words) -> String { have(g[it.key], it, counting(it, words)) }

    /// The bare number of `stored`, in whatever the item is counted in: its unit, or
    /// singly when it is loose aboard. `grouped` puts commas in the thousands.
    static func count(_ stored: Double, _ it: Item, _ how: Counting, grouped: Bool = false) -> String {
        if how.loose != nil { return String(Int(stored.rounded(.down))) }
        if how.tenths { return tenths(stored, it) }
        return grouped ? formatNumber(whole(stored, it)) : String(Int(whole(stored, it)))
    }

    /// `stored` with what it is counted in: "1,500 lbs", "9.5 crates", "1.4 cords", and
    /// what is loose aboard counted singly and written plain, "60 throws".
    static func measure(_ stored: Double, _ it: Item, _ how: Counting, grouped: Bool = false) -> String {
        let n = count(stored, it, how, grouped: grouped)
        return "\(n) \(how.loose ?? unit(it, count: n, how))"
    }

    /// With its unit, for the supplies list and the status box.
    static func amount(_ it: Item, _ g: GameState, _ words: Words) -> String {
        measure(g[it.key], it, counting(it, words), grouped: true)
    }
}

extension HealthLabel {
    static func color(_ h: HealthLabel) -> Color {
        switch h {
        case .good: return Theme.green
        case .fair: return Theme.amber
        case .poor, .veryPoor: return Theme.red
        }
    }
}

/// `Math.round`, for percentages shown to the player.
func jsRounded(_ x: Double) -> Double {
    let f = x.rounded(.down)
    return x - f >= 0.5 ? f + 1 : f
}
