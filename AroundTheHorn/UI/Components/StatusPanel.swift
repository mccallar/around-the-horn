import SwiftUI
import HornEngine

/// The status box (spec §3): date and region, weather, health, stores, next stop,
/// distance, ship's condition, and the teal note.
struct StatusPanel: View {
    let game: GameState

    var body: some View {
        let next = game.nextStop
        let health = game.healthLabel
        PanelBox(padding: 8) {
            (Text(game.dateText).foregroundColor(Theme.amber)
                + Text(" · \(game.region.name)").foregroundColor(Theme.dim).font(.custom(Theme.bodyFont, size: 18)))
                .bodyFont()
            Row(label: "Weather") {
                Text(game.weather.name).foregroundStyle(game.weather == .storm ? Theme.red : Theme.ink)
            }
            Row(label: "Health") { Text(health.text).foregroundStyle(HealthLabel.color(health)) }
            Row(label: "Provisions") { Text("\(formatNumber(game.food)) lbs") }
            Row(label: "Water") { Text("\(formatNumber(game.water)) gal") }
            Row(label: "Next: \(next?.short ?? "—")") {
                Text(next.map { "\(formatNumber(Double($0.mile - game.mile))) nm" } ?? "")
            }
            Row(label: "Sailed") { Text("\(formatNumber(Double(game.mile))) of 14,000 nm") }
            Row(label: "Hull · Sails") { Text("\(Int(jsRounded(game.hull)))% · \(Int(jsRounded(game.sails)))%") }
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
