import SwiftUI
import HornEngine

/// The Iron Road's map: the West from the Missouri to the Pacific on a 240×104 grid,
/// x = (lon + 124.6) × 7.8, y = (44.7 − lat) × 10. East is on the right, so the train
/// runs right to left, as it does in the scene. The dotted road, the part covered, the
/// stops and the blinking marker are the shell's.
enum RailChart {
    typealias Point = (lon: Double, lat: Double)

    /// The road: [lon, lat, mile]. Every stop of the journey is a point here, at its mile.
    static let road: [(Double, Double, Double)] = [
        (-95.94, 41.26, 0), (-98.34, 40.92, 154), (-100.77, 41.13, 291), (-102.26, 40.99, 377),
        (-104.82, 41.14, 516), (-105.45, 41.1, 553), (-105.6, 41.31, 573), (-107.24, 41.79, 709),
        (-109.47, 41.53, 845), (-110.96, 41.27, 955), (-111.97, 41.22, 1032), (-112.55, 41.62, 1084),
        (-113.4, 41.75, 1130), (-114.96, 41.11, 1225), (-115.76, 40.83, 1305), (-117.74, 40.97, 1430),
        (-118.6, 40.0, 1530), (-119.81, 39.53, 1620), (-120.33, 39.32, 1669), (-120.95, 39.1, 1721),
        (-121.49, 38.58, 1776),
    ]

    static func project(_ p: Point) -> (x: Double, y: Double) { ((p.lon + 124.6) * 7.8, (44.7 - p.lat) * 10) }

    static let skin = ChartSkin(
        w: 240, h: 104,
        title: "Map of the road",
        label: { "Map of the railroad from Omaha to Sacramento. You are in \(place($0))." },
        footer: {
            let total = RailSkin.journey.totalMiles
            return "\(formatNumber(Double($0.mile))) of \(formatNumber(Double(total))) miles covered. "
                + "\(formatNumber(Double(max(0, total - $0.mile)))) to go. The ringed stops have a yard."
        },
        background: { px, _, _ in background(px) },
        route: { _ in road.map { (x: $0.0, y: $0.1, mile: $0.2) } },
        others: { _ in [] },
        project: { project(($0, $1)) },
        routeStep: 16, travelledStep: 6, routeColor: Color(hex: 0x8A7F6A),
        overlay: { px, _, _ in names(px) })

    static func place(_ g: GameState) -> String {
        let name = g.region.name
        return name.hasPrefix("The ") ? "the " + name.dropFirst(4) : name
    }

    // MARK: The country

    static let coast: [Point] = [
        (-124.6, 44.7), (-124.1, 44.7), (-124.4, 42.8), (-124.2, 41.8), (-124.3, 40.4), (-123.8, 39.4), (-123.0, 38.2),
        (-122.5, 37.8), (-122.4, 37.2), (-121.9, 36.6), (-121.3, 35.7), (-120.6, 34.6), (-120.5, 34.2), (-124.6, 34.2),
    ]

    static let saltLake: [Point] = [
        (-112.9, 41.7), (-112.2, 41.6), (-112.0, 41.05), (-112.3, 40.7), (-112.8, 40.9), (-113.0, 41.3),
    ]

    static let rivers: [[Point]] = [
        // The Missouri.
        [(-97.4, 44.7), (-96.4, 42.7), (-95.9, 41.5), (-95.8, 40.6), (-95.0, 39.8), (-94.6, 39.1)],
        // The Platte, and its north and south forks.
        [(-95.9, 41.05), (-97.2, 41.3), (-98.4, 40.8), (-99.6, 40.7), (-100.75, 41.1)],
        [(-100.75, 41.1), (-102.6, 41.3), (-104.0, 41.9), (-105.5, 42.75), (-106.6, 42.5), (-106.9, 41.3)],
        [(-100.75, 41.1), (-102.3, 40.9), (-103.6, 40.3), (-104.8, 40.2), (-105.0, 39.6)],
        // The Green.
        [(-110.0, 43.2), (-109.9, 42.2), (-109.5, 41.5), (-109.6, 40.6), (-110.0, 39.3)],
        // The Bear and the Weber, into the lake.
        [(-110.9, 41.3), (-111.2, 42.0), (-111.9, 42.4), (-112.2, 41.7)],
        // The Humboldt, and its sink.
        [(-115.2, 41.2), (-115.8, 40.8), (-117.0, 40.65), (-117.75, 40.97), (-118.3, 40.5), (-118.6, 40.0)],
        // The Truckee.
        [(-120.05, 39.2), (-119.8, 39.5), (-119.55, 39.95)],
        // The Sacramento and the San Joaquin, to the bay.
        [(-122.3, 40.6), (-122.0, 39.6), (-121.5, 38.6), (-121.9, 38.05), (-122.4, 37.9)],
        [(-120.8, 36.9), (-121.3, 37.8), (-121.9, 38.05)],
    ]

    /// The two ranges, as rows of peaks, and a few of the basin's lesser ones.
    static let rockies: [Point] = [
        (-105.4, 42.3), (-105.3, 41.6), (-105.5, 40.7), (-105.7, 40.0), (-106.2, 39.3), (-106.4, 40.5), (-106.5, 41.2),
        (-105.9, 38.6), (-106.8, 38.0), (-107.6, 37.7), (-109.3, 43.2), (-109.0, 42.8), (-108.8, 42.4),
        (-110.3, 40.75), (-109.6, 40.75), (-110.9, 40.7), (-111.6, 40.5), (-111.7, 41.0), (-111.5, 41.6), (-111.6, 39.8),
        (-111.4, 42.2), (-110.8, 43.6), (-110.6, 44.2),
    ]

    static let sierra: [Point] = [
        (-121.5, 40.5), (-121.0, 40.0), (-120.6, 39.6), (-120.3, 39.3), (-120.1, 38.8), (-119.7, 38.3), (-119.3, 37.8),
        (-118.9, 37.3), (-118.6, 36.8), (-118.3, 36.4), (-118.2, 35.8), (-121.9, 41.3), (-122.2, 41.4),
    ]

    static let basin: [Point] = [
        (-115.4, 40.4), (-115.3, 39.7), (-116.9, 39.3), (-117.2, 38.8), (-114.3, 39.0), (-116.2, 41.5), (-117.6, 41.7),
        (-114.2, 40.2),
    ]

    /// The three deserts the boiler cannot drink in: [west, east, south, north].
    static let deserts: [(Double, Double, Double, Double, UInt32)] = [
        (-109.3, -107.5, 41.35, 42.3, 0xB5673F),
        (-114.7, -113.0, 40.1, 41.6, 0xE2DFD2),
        (-119.5, -118.7, 39.55, 40.0, 0xD2C8A8),
    ]

    static func background(_ px: PixelCanvas) {
        let w = px.w, h = px.h
        let P = { (lon: Double, lat: Double) in project((lon, lat)) }
        // The mountain West, the plains east of it, and the sea.
        px.rect(0, 0, w, h, Color(hex: 0x2E3A2C))
        px.polygon([P(-104.6, 44.7), (w, 0), (w, h), P(-103.6, 34.2), P(-104.2, 38), P(-104.9, 41)], Color(hex: 0x3D4A2E))
        px.polygon([P(-123.0, 40.3), P(-121.6, 40.2), P(-120.4, 37.4), P(-119.0, 35.2), P(-119.8, 35.0), P(-121.8, 37.4)],
                   Color(hex: 0x3D4A2E))
        px.polygon(coast.map(project), Color(hex: 0x0D2A44))
        let grid = Color(hex: 0x384636)
        for lon in stride(from: -120.0, through: -100, by: 5) { px.rect(P(lon, 0).x.rounded(.down), 0, 1, h, grid) }
        for lat in stride(from: 36.0, through: 44, by: 2) { px.rect(0, P(0, lat).y.rounded(.down), w, 1, grid) }

        for d in deserts {
            let a = P(d.0, d.3), b = P(d.1, d.2)
            let x0 = Int(a.x.rounded()), x1 = Int(b.x.rounded()), y0 = Int(a.y.rounded()), y1 = Int(b.y.rounded())
            for y in y0...y1 {
                for x in x0...x1 where (x + y * 2) % 3 == 0 { px.rect(Double(x), Double(y), 1, 1, Color(hex: d.4).opacity(0.75)) }
            }
        }

        let water = Color(hex: 0x4A8AB8)
        for river in rivers {
            for i in river.indices.dropFirst() {
                let a = P(river[i - 1].lon, river[i - 1].lat), b = P(river[i].lon, river[i].lat)
                px.line(from: (a.x, a.y), to: (b.x, b.y), water)
            }
        }
        px.polygon(saltLake.map(project), water)
        for lake in [(-120.05, 39.1), (-119.55, 40.05), (-111.75, 40.2)] {
            let q = P(lake.0, lake.1)
            px.rect(q.x.rounded(.down), q.y.rounded(.down) - 1, 2, 3, water)
        }

        func peaks(_ at: [Point], _ rock: UInt32, snow: Bool) {
            for p in at {
                let q = project(p)
                let x = q.x.rounded(.down), y = q.y.rounded(.down)
                px.rect(x - 2, y + 1, 5, 1, Color(hex: rock))
                px.rect(x - 1, y, 3, 1, Color(hex: rock))
                px.rect(x, y - 1, 1, 1, snow ? Color(hex: 0xF4F7FA) : Color(hex: rock))
            }
        }
        peaks(basin, 0x5E6656, snow: false)
        peaks(rockies, 0x8A8F84, snow: true)
        peaks(sierra, 0x9AA0A6, snow: true)
    }

    /// The yards ringed, and the two ends named.
    static func names(_ px: PixelCanvas) {
        let ink = Color(hex: 0xD8D0B8)
        for stop in RailSkin.journey.stops where stop.type == .port {
            guard let at = road.first(where: { Int($0.2) == stop.mile }) else { continue }
            let q = project((at.0, at.1))
            let x = jsRounded(q.x) - 3, y = jsRounded(q.y) - 3
            px.rect(x + 1, y, 5, 1, ink)
            px.rect(x + 1, y + 6, 5, 1, ink)
            px.rect(x, y + 1, 1, 5, ink)
            px.rect(x + 6, y + 1, 1, 5, ink)
        }
        let east = project((road[0].0, road[0].1)), west = project((road[road.count - 1].0, road[road.count - 1].1))
        px.text("OMAHA", x: east.x - 22, y: east.y - 4, size: 8, ink)
        px.text("SACRAMENTO", x: west.x - 4, y: west.y + 12, size: 8, ink)
    }
}
