import SwiftUI
import HornEngine

/// The chart (spec §8). The skin draws the map and says where the route runs; the dotted
/// route, the part travelled, the stop marks, the blinking marker and the legend are
/// shared and come from `journey.stops`.
struct ChartView: View {
    @Environment(GameController.self) private var c
    @State private var start = Date()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let g = c.game!
        let journey = c.journey, chart = c.skin.chart
        VStack(alignment: .leading, spacing: 0) {
            Heading(chart.title)
            TimelineView(.animation(minimumInterval: 0.25, paused: reduceMotion)) { tl in
                Canvas { ctx, size in
                    Self.draw(PixelCanvas(ctx, size: size, w: chart.w, h: chart.h), chart, journey, g,
                              t: tl.date.timeIntervalSince(start))
                }
            }
            .aspectRatio(chart.w / chart.h, contentMode: .fit)
            .overlay(Rectangle().strokeBorder(Theme.line, lineWidth: 2))
            .accessibilityElement()
            .accessibilityLabel(chart.label(g))
            .accessibilityAddTraits(.isImage)
            LazyVGrid(columns: [GridItem(.flexible(), alignment: .leading), GridItem(.flexible(), alignment: .leading)],
                      spacing: 2) {
                ForEach(Array(journey.stops.enumerated()), id: \.offset) { i, s in
                    let passed = i <= g.stopIndex, next = i == g.stopIndex + 1
                    Text("\(passed ? "✓" : next ? "►" : "·") \(s.short)")
                        .foregroundStyle(passed ? Theme.amber : next ? Theme.ink : Theme.dim)
                        .accessibilityLabel("\(s.short), \(passed ? "passed" : next ? "next" : "ahead")")
                }
            }
            .bodyFont(18)
            .padding(.top, 8)
            Para(chart.footer(g), size: 18, color: Theme.dim)
            ChoiceList(choices: [Choice(label: "Back") { c.backToMenu() }])
        }
    }

    /// Where `m` falls on a route, in canvas pixels: straight between the two points
    /// either side of it, worked out in the skin's map space and then projected.
    static func position(_ route: [ChartSkin.Point], atMile m: Double, _ chart: ChartSkin) -> (x: Double, y: Double) {
        guard let last = route.last else { return (0, 0) }
        for i in route.indices.dropFirst() where m <= route[i].mile {
            let a = route[i - 1], b = route[i]
            let span = b.mile - a.mile
            let t = (m - a.mile) / (span == 0 ? 1 : span)
            return chart.project(a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t)
        }
        return chart.project(last.x, last.y)
    }

    static func draw(_ px: PixelCanvas, _ chart: ChartSkin, _ journey: Journey, _ g: GameState, t: Double) {
        chart.background(px, g, t)
        func dots(_ route: [ChartSkin.Point], through end: Double, every step: Double, _ color: Color) {
            guard step > 0 else { return }
            for m in stride(from: 0.0, through: end, by: step) {
                let q = position(route, atMile: m, chart)
                px.rect(jsRounded(q.x), jsRounded(q.y), 1, 1, color)
            }
        }
        let route = chart.route(g)
        let total = Double(journey.totalMiles)
        for other in chart.others(g) {
            dots(other, through: other.last?.mile ?? total, every: chart.routeStep * 2, chart.routeColor)
        }
        dots(route, through: total, every: chart.routeStep, chart.routeColor)
        dots(route, through: Double(g.mile), every: chart.travelledStep, Theme.amber)
        for (i, s) in journey.stops.enumerated() {
            let q = position(route, atMile: Double(s.mile), chart)
            px.rect(jsRounded(q.x) - 1, jsRounded(q.y) - 1, 3, 3, i <= g.stopIndex ? Theme.amber : Theme.ink)
        }
        if Int((t * 2).rounded(.down)) % 2 == 0 {
            let q = position(route, atMile: Double(g.mile), chart)
            px.rect(jsRounded(q.x) - 2, jsRounded(q.y) - 2, 5, 5, Theme.red)
        }
        chart.overlay(px, g, t)
    }
}
