import SwiftUI
import HornEngine

/// The stampede's map: the coast from Puget Sound to the head of Lynn Canal and the river
/// from Lake Bennett to Dawson, on a 230×210 grid, x = (lon + 148) × 8.5,
/// y = (65 − lat) × 11.4. North is up, so the party goes up the page and to the left. The
/// thirty-three miles over the passes, which take longer than the thousand before them,
/// are four pixels at this scale, so an inset in the corner of the open sea shows them
/// large: both trails until one is chosen, the stops along it and, while the party is on
/// it, the party.
enum KlondikeChart {
    typealias Point = (lon: Double, lat: Double)

    static let w = 230.0, h = 210.0

    static func project(_ p: Point) -> (x: Double, y: Double) { ((p.lon + 148) * 8.5, (65 - p.lat) * 11.4) }

    // MARK: The way: [lon, lat, miles]

    /// By steamer, from Seattle to the head of Lynn Canal.
    static let steamer: [(Double, Double, Double)] = [
        (-122.33, 47.61, 0), (-122.55, 48.15, 40), (-123.0, 48.6, 95), (-123.9, 49.3, 160),
        (-125.3, 50.1, 245), (-127.0, 50.9, 330), (-128.0, 51.6, 380), (-128.8, 52.8, 480),
        (-130.2, 54.0, 600), (-131.4, 55.2, 700), (-132.4, 56.4, 820), (-133.3, 57.0, 900),
        (-134.1, 57.9, 970), (-134.42, 58.30, 1020), (-134.9, 58.55, 1045), (-135.1, 59.0, 1080),
        (-135.35, 59.33, 1110),
    ]

    /// From Dyea over the Chilkoot to Lake Bennett.
    static let chilkootTrail: [(Double, Double, Double)] = [
        (-135.36, 59.51, 1120), (-135.33, 59.635, 1133), (-135.23, 59.70, 1136.5),
        (-135.17, 59.74, 1141), (-135.08, 59.79, 1146), (-134.99, 59.85, 1153),
    ]

    /// From Skagway over the White Pass to Lake Bennett.
    static let whitePassTrail: [(Double, Double, Double)] = [
        (-135.31, 59.46, 1120), (-135.22, 59.55, 1133), (-135.14, 59.62, 1136.5),
        (-135.05, 59.70, 1141), (-135.02, 59.76, 1146), (-134.99, 59.85, 1153),
    ]

    /// Down the lakes and the river from Bennett to Dawson.
    static let river: [(Double, Double, Double)] = [
        (-134.86, 60.05, 1166), (-134.71, 60.17, 1179), (-134.45, 60.20, 1192), (-134.27, 60.31, 1203),
        (-134.35, 60.50, 1222), (-134.60, 60.62, 1235), (-135.05, 60.67, 1253), (-135.06, 60.72, 1258),
        (-135.15, 60.95, 1275), (-135.00, 61.35, 1305), (-134.88, 61.58, 1340), (-134.90, 61.87, 1375),
        (-135.50, 62.15, 1410), (-136.29, 62.09, 1445), (-136.35, 62.27, 1467), (-137.38, 62.78, 1525),
        (-138.40, 63.00, 1585), (-139.50, 63.20, 1635), (-139.42, 63.28, 1645), (-139.30, 63.70, 1675),
        (-139.43, 64.06, 1700),
    ]

    /// The lakes on the way, by the miles they run between: Bennett to Caribou Crossing,
    /// Tagish and Marsh, and Laberge.
    static let lakes: [ClosedRange<Double>] = [1153...1179, 1203...1235, 1275...1305]

    /// A track in the engine's own distances (tenths of a mile), in map space.
    static func points(_ track: [(Double, Double, Double)]) -> [ChartSkin.Point] {
        track.map { (x: $0.0, y: $0.1, mile: ($0.2 * Double(Klondike.unitsPerMile)).rounded()) }
    }

    static let chilkootRoute = points(steamer + chilkootTrail + river)
    static let whitePassRoute = points(steamer + whitePassTrail + river)
    /// The White Pass as far as the lake, for showing beside the Chilkoot while both are open.
    static let whitePassOpen = points(steamer + whitePassTrail)

    static func route(_ g: GameState) -> [ChartSkin.Point] {
        KlondikeSkin.onWhitePass(g) ? whitePassRoute : chilkootRoute
    }

    /// "the Inside Passage", "Lake Laberge": a region's name as it reads inside a sentence.
    static func place(_ g: GameState) -> String {
        let name = g.region.name
        return name.hasPrefix("The ") ? "the " + name.dropFirst(4) : name
    }

    static let skin = ChartSkin(
        w: w, h: h,
        title: "Map of the journey",
        label: { "Map of the route from Seattle to Dawson City. You are in \(place($0))." },
        footer: { "\(Klondike.progress($0)) The ringed stops are towns; the inset is the two passes, "
            + "where a month's hauling is too short to show." },
        background: { px, _, _ in background(px) },
        route: route,
        others: { KlondikeSkin.pass($0) == nil ? [whitePassOpen] : [] },
        project: { project(($0, $1)) },
        routeStep: 30, travelledStep: 10, routeColor: Color(hex: 0x6D7F92),
        overlay: { px, g, t in marks(px, g, t: t) })

    // MARK: The country

    static let land: UInt32 = 0xB9A26C
    static let ocean: UInt32 = 0x0D2A44
    static let fresh: UInt32 = 0x2F6A96

    /// The Pacific and the Gulf of Alaska, clockwise from the bottom left.
    static let sea: [Point] = [
        (-148, 47), (-124.7, 47), (-124.7, 48.4), (-125.5, 48.9), (-127.0, 49.9),
        (-128.4, 50.8), (-127.8, 51.5), (-128.5, 52.5), (-130.0, 54.0), (-130.6, 54.7),
        (-133.5, 55.0), (-134.3, 56.0), (-135.5, 57.0), (-136.4, 57.9), (-137.0, 58.4),
        (-138.0, 58.7), (-139.7, 59.5), (-142.0, 60.0), (-145.0, 60.2), (-148.0, 60.4),
    ]

    /// The big islands off the northern coast.
    static let island: [Point] = [(-131.0, 52.0), (-132.2, 53.0), (-133.0, 54.1), (-132.0, 54.0), (-131.6, 53.2)]

    static func dot(_ px: PixelCanvas, _ q: (x: Double, y: Double), _ color: Color) {
        let x = jsRounded(q.x), y = jsRounded(q.y)
        guard x >= 0, x < px.w, y >= 0, y < px.h else { return }
        px.rect(x, y, 1, 1, color)
    }

    /// A line `width` pixels thick through canvas points: a channel, a river, a lake.
    static func stroke(_ px: PixelCanvas, _ points: [(x: Double, y: Double)], width: Double, _ color: Color) {
        let half = ((width - 1) / 2).rounded(.down)
        for (a, b) in zip(points, points.dropFirst()) {
            let steps = max(1, Int((max(abs(b.x - a.x), abs(b.y - a.y)) * 2).rounded(.up)))
            for k in 0...steps {
                let f = Double(k) / Double(steps)
                px.rect(jsRounded(a.x + (b.x - a.x) * f) - half, jsRounded(a.y + (b.y - a.y) * f) - half, width, width, color)
            }
        }
    }

    /// Whether (lon, lat) is in the open sea, by the sea's outline.
    static func atSea(_ p: Point) -> Bool {
        var inside = false
        for (a, b) in zip(sea, sea.dropFirst() + sea.prefix(1)) where (a.lat > p.lat) != (b.lat > p.lat) {
            if p.lon < a.lon + (b.lon - a.lon) * (p.lat - a.lat) / (b.lat - a.lat) { inside.toggle() }
        }
        return inside
    }

    static func background(_ px: PixelCanvas) {
        px.rect(0, 0, px.w, px.h, Color(hex: land))
        px.polygon(sea.map(project), Color(hex: ocean))
        px.polygon(island.map(project), Color(hex: land))
        // The graticule every five degrees: blue on the water, a darker tan on the land.
        let onSea = Color(hex: 0x173B5C), onLand = Color(hex: 0xA38D5A)
        for lon in stride(from: -145.0, through: -125, by: 5) {
            for lat in stride(from: 47.0, through: 65, by: 0.25) {
                dot(px, project((lon, lat)), atSea((lon, lat)) ? onSea : onLand)
            }
        }
        for lat in [50.0, 55, 60] {
            for lon in stride(from: -148.0, through: -121, by: 0.35) {
                dot(px, project((lon, lat)), atSea((lon, lat)) ? onSea : onLand)
            }
        }
        // The 141st meridian, north of the coast mountains.
        for lat in stride(from: 60.3, through: 65, by: 0.25) { dot(px, project((-141, lat)), Color(hex: 0x8F8A7A)) }
        // The inside waters the steamers keep to, and the canal up to the two landings.
        stroke(px, steamer.map { project(($0.0, $0.1)) }, width: 3, Color(hex: ocean))
        stroke(px, [steamer[steamer.count - 1], chilkootTrail[0]].map { project(($0.0, $0.1)) }, width: 2, Color(hex: ocean))
        // The river, and the lakes along it.
        let water = [chilkootTrail[chilkootTrail.count - 1]] + river
        stroke(px, water.map { project(($0.0, $0.1)) }, width: 2, Color(hex: fresh))
        for lake in lakes {
            stroke(px, water.filter { lake.contains($0.2) }.map { project(($0.0, $0.1)) }, width: 4, Color(hex: fresh))
        }
    }

    // MARK: Over the top

    static func ring(_ px: PixelCanvas, _ q: (x: Double, y: Double), _ color: Color) {
        let x = jsRounded(q.x) - 3, y = jsRounded(q.y) - 3
        px.rect(x + 1, y, 5, 1, color)
        px.rect(x + 1, y + 6, 5, 1, color)
        px.rect(x, y + 1, 1, 5, color)
        px.rect(x + 6, y + 1, 1, 5, color)
    }

    /// The towns too far apart to need the inset: ringed, and the two ends and Juneau named.
    static let far = ["seattle", "juneau", "selkirk"]

    static func marks(_ px: PixelCanvas, _ g: GameState, t: Double) {
        let j = KlondikeSkin.journey
        let way = route(g)
        let pale = Color(hex: 0xECE4CF), dark = Color(hex: 0x3A2A1A)
        for id in far {
            guard let stop = j.stop(id) else { continue }
            ring(px, ChartView.position(way, atMile: Double(stop.mile), skin), dark)
        }
        let seattle = project((steamer[0].0, steamer[0].1))
        let juneau = ChartView.position(way, atMile: Double(j.stop("juneau")?.mile ?? 0), skin)
        let dawson = project((river[river.count - 1].0, river[river.count - 1].1))
        px.text("SEATTLE", x: seattle.x - 46, y: seattle.y + 6, size: 8, pale)
        px.text("JUNEAU", x: juneau.x + 6, y: juneau.y + 4, size: 8, dark)
        px.text("DAWSON", x: dawson.x + 6, y: dawson.y + 4, size: 8, dark)
        inset(px, g, t: t)
    }

    // MARK: The passes

    static let box = (x: 6.0, y: 134.0, w: 70.0, h: 70.0)

    static func insetPoint(_ p: Point) -> (x: Double, y: Double) {
        (box.x + (p.lon + 135.45) * 127, box.y + (59.88 - p.lat) * 152)
    }

    /// Where `mile` (in the engine's distances) falls in the inset on a trail, or nil
    /// when the party is not on it: at sea below the landing, or away down the lakes.
    static func insetPosition(_ trail: [(Double, Double, Double)], atMile mile: Double) -> (x: Double, y: Double)? {
        let m = mile / Double(Klondike.unitsPerMile)
        let track = [steamer[steamer.count - 1]] + trail
        guard let first = track.first, let last = track.last, m >= first.2, m <= last.2 else { return nil }
        for (a, b) in zip(track, track.dropFirst()) where m <= b.2 {
            let f = b.2 == a.2 ? 0 : (m - a.2) / (b.2 - a.2)
            let q = insetPoint((a.0 + (b.0 - a.0) * f, a.1 + (b.1 - a.1) * f))
            let inside = q.x >= box.x + 3 && q.x <= box.x + box.w - 4 && q.y >= box.y + 3 && q.y <= box.y + box.h - 4
            return inside ? q : nil
        }
        return nil
    }

    static func inset(_ px: PixelCanvas, _ g: GameState, t: Double) {
        let b = box
        let edge = Color(hex: 0x2A3547)
        px.rect(b.x, b.y, b.w, b.h, Color(hex: land))
        // Lynn Canal, to Dyea and to Skagway, and Lake Bennett at the top of both trails.
        let foot: Point = (-135.33, 59.42)
        stroke(px, [foot, (chilkootTrail[0].0, chilkootTrail[0].1)].map(insetPoint), width: 3, Color(hex: ocean))
        stroke(px, [foot, (whitePassTrail[0].0, whitePassTrail[0].1)].map(insetPoint), width: 3, Color(hex: ocean))
        let lake = insetPoint((chilkootTrail[chilkootTrail.count - 1].0, chilkootTrail[chilkootTrail.count - 1].1))
        stroke(px, [(lake.x, lake.y), (lake.x + 4, lake.y - 3)], width: 3, Color(hex: fresh))
        px.rect(b.x, b.y, b.w, 1, edge)
        px.rect(b.x, b.y + b.h - 1, b.w, 1, edge)
        px.rect(b.x, b.y, 1, b.h, edge)
        px.rect(b.x + b.w - 1, b.y, 1, b.h, edge)

        let chosen = KlondikeSkin.pass(g)
        let white = KlondikeSkin.onWhitePass(g)
        let dark = Color(hex: 0x3A2A1A), faint = Color(hex: 0x8F7B4E)
        func trail(_ track: [(Double, Double, Double)], _ color: Color) {
            for (p, q) in zip(track, track.dropFirst()) {
                let a = insetPoint((p.0, p.1)), z = insetPoint((q.0, q.1))
                let steps = max(1, Int((hypot(z.x - a.x, z.y - a.y) / 2).rounded()))
                for k in 0...steps {
                    let f = Double(k) / Double(steps)
                    dot(px, (a.x + (z.x - a.x) * f, a.y + (z.y - a.y) * f), color)
                }
            }
        }
        // Both ways while both are open; afterwards the one not taken fades.
        let mine = white ? whitePassTrail : chilkootTrail
        let other = white ? chilkootTrail : whitePassTrail
        trail(other, chosen == nil ? dark : faint)
        trail(mine, dark)
        // The part hauled so far, in the shell's amber.
        let j = KlondikeSkin.journey
        if chosen != nil {
            let done = Double(g.mile) / Double(Klondike.unitsPerMile)
            for m in stride(from: mine[0].2, through: min(done, mine[mine.count - 1].2), by: 0.25) {
                if let q = insetPosition(mine, atMile: m * Double(Klondike.unitsPerMile)) { dot(px, q, Theme.amber) }
            }
        }
        // The stops along it, the towns ringed, on both trails while both are open.
        for (i, stop) in j.stops.enumerated() {
            let m = Double(stop.mile)
            for track in chosen == nil ? [chilkootTrail, whitePassTrail] : [mine] {
                guard let q = insetPosition(track, atMile: m), m >= track[0].2 * Double(Klondike.unitsPerMile) else { continue }
                px.rect(jsRounded(q.x) - 1, jsRounded(q.y) - 1, 3, 3, i <= g.stopIndex ? Theme.amber : Theme.ink)
                if j.port(stop.id) != nil { ring(px, q, dark) }
            }
        }
        px.text("THE PASSES", x: b.x + 3, y: b.y + 10, size: 8, dark)
        if chosen == nil {
            px.text("Chilkoot", x: b.x + 3, y: b.y + 22, size: 8, dark)
            px.text("White Pass", x: b.x + 36, y: b.y + 58, size: 8, dark)
        }
        if let q = insetPosition(mine, atMile: Double(g.mile)), Int((t * 2).rounded(.down)) % 2 == 0 {
            px.rect(jsRounded(q.x) - 2, jsRounded(q.y) - 2, 5, 5, Theme.red)
        }
    }
}
