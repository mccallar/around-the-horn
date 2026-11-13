import SwiftUI
import HornEngine

/// 1849's chart (spec §8): a 230×210 equirectangular map, x = (lon + 130) × 2,
/// y = (45 − lat) × 2. The route, the sailed part, stops and the blinking ship are the shell's.
enum ChartData {
    typealias Point = (lon: Double, lat: Double)

    /// The prototype's `ROUTE`: [lon, lat, mile].
    static let horn: [(Double, Double, Double)] = [
        (-74, 40.7, 0), (-70, 37, 300), (-55, 30, 1300), (-38, 21, 2200), (-23.5, 15, 2900), (-28, 0, 3850),
        (-35, -10, 4500), (-43.2, -22.9, 5200), (-48, -33, 6000), (-57.9, -51.7, 7000), (-64, -55, 7350),
        (-67.3, -56.6, 7550), (-75.5, -53, 7800), (-74, -45, 8200), (-71.6, -33, 8900), (-77.1, -12, 10200),
        (-89.6, -0.9, 11300), (-110, 12, 12300), (-126, 28, 13300), (-122.4, 37.8, 14000),
    ]

    /// The prototype's `ROUTE_M`, through the Strait.
    static let magellan: [(Double, Double, Double)] = [
        (-74, 40.7, 0), (-70, 37, 300), (-55, 30, 1300), (-38, 21, 2200), (-23.5, 15, 2900), (-28, 0, 3850),
        (-35, -10, 4500), (-43.2, -22.9, 5200), (-48, -33, 6000), (-57.9, -51.7, 7000), (-64, -54, 7200),
        (-68.4, -52.4, 7350), (-70.9, -53.3, 7550), (-74.5, -52.7, 7800), (-74, -45, 8200), (-71.6, -33, 8900),
        (-77.1, -12, 10200), (-89.6, -0.9, 11300), (-110, 12, 12300), (-126, 28, 13300), (-122.4, 37.8, 14000),
    ]

    /// The prototype's `LAND`: North & Central America, South America, West Africa, Cuba.
    static let land: [[Point]] = [
        [(-124.5, 46), (-124.5, 45), (-124, 42), (-122.5, 37.8), (-120.5, 34.5), (-117, 32.5), (-114, 30), (-110, 23),
         (-105, 20), (-97, 16), (-92, 14.5), (-87.5, 13), (-85.7, 10), (-83, 8.2), (-80, 7.5), (-77.5, 8.5),
         (-79.5, 9.6), (-83.5, 11), (-83.5, 15), (-88, 15.8), (-87.5, 21.5), (-90.5, 21), (-91, 18.5), (-94.5, 18.3),
         (-97.5, 22), (-97, 27.8), (-94, 29.7), (-89, 30), (-84, 30), (-82.5, 27.5), (-81, 25.2), (-80.1, 26.8),
         (-81.2, 31), (-76, 35), (-75.5, 38.5), (-74, 40.5), (-70, 41.5), (-70, 43.5), (-67, 45), (-66, 46)],
        [(-77.5, 8.5), (-72, 12), (-63, 10.7), (-60, 8.5), (-52, 5), (-50, 0), (-44, -2.5), (-35, -5.5), (-35, -9),
         (-39, -13), (-39.5, -18), (-41, -22), (-44, -23), (-48.5, -27), (-51, -31), (-53.5, -34), (-58, -34.5),
         (-57, -37), (-62, -39), (-65, -42), (-67.5, -46), (-69, -50), (-68.5, -52.5), (-67, -55), (-68.5, -55.6),
         (-72, -54), (-75, -50), (-74, -45), (-73.5, -41), (-73.5, -37), (-71.6, -33), (-71.5, -28), (-70.3, -18.5),
         (-71.5, -17), (-76, -14), (-77.1, -12), (-79, -8), (-81.3, -5), (-80.5, -1), (-80, 1), (-78.8, 2), (-77.5, 7)],
        [(-17.5, 14.7), (-16.7, 12.5), (-13, 9), (-11, 6.5), (-7.5, 4.4), (0, 5), (0, 40), (-6, 36), (-9.5, 33),
         (-10, 30), (-13, 27.5), (-16, 23.5), (-17, 21), (-16, 18)],
        [(-85, 22), (-80, 23.2), (-75, 20), (-77.5, 19.8), (-82, 21.5)],
    ]

    /// Cape Verde, the Falklands and the Galápagos, as little blocks.
    static let islands: [Point] = [(-23.5, 15), (-24.5, 16.5), (-59, -51.7), (-60.5, -51.5), (-90.5, -0.6), (-91, -0.2)]

    static func route(_ p: Passage?) -> [(Double, Double, Double)] { p == .magellan ? magellan : horn }

    /// The prototype's `posAt`: the ship's longitude and latitude at a mile.
    static func position(atMile m: Double, passage: Passage?) -> Point {
        let r = route(passage)
        for i in 1..<r.count where m <= r[i].2 {
            let a = r[i - 1], b = r[i]
            let span = b.2 - a.2
            let t = (m - a.2) / (span == 0 ? 1 : span)
            return (a.0 + (b.0 - a.0) * t, a.1 + (b.1 - a.1) * t)
        }
        return (r.last!.0, r.last!.1)
    }

    static func project(_ p: Point) -> (x: Double, y: Double) { ((p.lon + 130) * 2, (45 - p.lat) * 2) }
}

enum Horn1849Chart {
    static let skin = ChartSkin(
        w: 230, h: 210,
        title: "Chart of the voyage",
        label: { "Chart of the route from New York to San Francisco. You are near \($0.region.name)." },
        footer: { "\(formatNumber(Double($0.mile))) of 14,000 nautical miles sailed. \(formatNumber(Double(14000 - $0.mile))) to go." },
        background: { px, _, _ in background(px) },
        route: { ChartData.route($0.passage).map { (x: $0.0, y: $0.1, mile: $0.2) } },
        others: { _ in [] },
        project: { ChartData.project(($0, $1)) },
        routeStep: 90, travelledStep: 25, routeColor: Color(hex: 0x6D7F92),
        overlay: { _, _, _ in })

    /// Sea, graticule, the equator, and the land the prototype drew.
    static func background(_ px: PixelCanvas) {
        let w = px.w, h = px.h
        let P = { (lon: Double, lat: Double) in ChartData.project((lon, lat)) }
        px.rect(0, 0, w, h, Color(hex: 0x0D2A44))
        let grid = Color(hex: 0x173B5C)
        for lon in stride(from: -120.0, through: -15, by: 15) {
            for y in stride(from: 0.0, to: h, by: 3) { px.rect(P(lon, 0).x, y, 1, 1, grid) }
        }
        for lat in stride(from: 30.0, through: -60, by: -15) {
            for x in stride(from: 0.0, to: w, by: 3) { px.rect(x, P(0, lat).y, 1, 1, grid) }
        }
        for x in stride(from: 0.0, to: w, by: 2) { px.rect(x, P(0, 0).y, 1, 1, Color(hex: 0x2F6A96)) }
        let landColor = Color(hex: 0xB9A26C)
        for poly in ChartData.land { px.polygon(poly.map(ChartData.project), landColor) }
        for pt in ChartData.islands {
            let q = ChartData.project(pt)
            px.rect(jsRounded(q.x) - 1, jsRounded(q.y) - 1, 3, 2, landColor)
        }
    }
}
