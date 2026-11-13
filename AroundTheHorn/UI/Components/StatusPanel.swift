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
                Text(game.weather.name).foregroundStyle(game.weather.sky == .storm ? Theme.red : Theme.ink)
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

/// How much of an item is aboard, as the shop and the lists write it.
enum Stores {
    /// In the item's own unit: boxes of tackle, cords of firewood.
    private static func units(_ it: Item, _ g: GameState) -> Double { g[it.key] / Double(max(1, it.per)) }

    private static func tenths(_ v: Double) -> String {
        let x = (v * 10).rounded(.down) / 10
        return x == x.rounded() ? String(Int(x)) : String(x)
    }

    /// The shop's "Have N": whole units, or tenths for an item the skin counts that way.
    static func have(_ it: Item, _ g: GameState, _ words: Words) -> String {
        let v = units(it, g)
        return words.fractional.contains(it.key) ? tenths(v) : String(Int(v.rounded(.down)))
    }

    /// With its unit, for the supplies list and the status box: "1,500 lbs", "9.5 crates",
    /// and what is loose aboard counted singly and written plain, "60 throws".
    static func amount(_ it: Item, _ g: GameState, _ words: Words) -> String {
        if let loose = words.looseUnits[it.key] { return "\(Int(g[it.key].rounded(.down))) \(loose)" }
        if words.fractional.contains(it.key) { return "\(tenths(units(it, g))) \(it.unit)" }
        return "\(formatNumber(units(it, g))) \(it.unit)"
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
