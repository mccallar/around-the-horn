import SwiftUI
import HornEngine

/// The Long Transfer's scene: a transfer freighter in profile against black sky and fixed
/// stars, nose to the right, where Mars is. Her drive glows behind her when she burns,
/// longer the harder she burns; past Turnover she flies tail first, braking. Earth shrinks
/// behind her over the first weeks and Mars grows ahead over the last; the Sun sits small
/// at the top right edge, smaller the further out she is. Each stretch of the arc has its
/// own sky (Earth's limb, the double star of Earth and the Moon, the ice streams' glitter,
/// the zodiacal light, the Milky Way, the Sun between her and home, Mars and its moons),
/// and each stop is drawn as itself: the yard at Gateway, the Moon going by, the edge of
/// Earth's reach, the cycler's wheel, Turnover with the ship on end, Midway's tanks, the
/// shadow, the approach, Phobos under Mars, the pad at Jezero. Space weather shows as what
/// it is. Her wings lose panels as power falls and go dark at 0%; a dark or dry ship has
/// no glow, and a dry one tumbles; a tired hull leaks.
enum MarsScene {
    // MARK: The freighter

    /// 48 × 27, nose to the right: the two solar wings above and below the truss, the drive
    /// and its bell at the left, radiators, two cargo cans, the habitat with its windows
    /// and stripe, and a dish.
    static let ship = [
        "        fffffffffffff                           ",
        "        fppfppfppfppf                           ",
        "        fppfppfppfppf                           ",
        "        fffffffffffff                           ",
        "        fppfppfppfppf                           ",
        "        fppfppfppfppf                           ",
        "        fffffffffffff                  a a      ",
        "              m                        aaa      ",
        "              m                         k       ",
        "         rr   m   rr                    k       ",
        "n        rr   m   rr  CCCCCC CCCCCC HHHHHHHHHH  ",
        "nn  HHHHttttttttttttttcccccc cccccc hhhhhhhhhhH ",
        "nnnnkkkktt  tt  tt  ttcccccckcccccckhwhwhwhwhhhH",
        "nnnnkkkkt t t t t t t cccccckcccccckhhhhhhhhhhhH",
        "nnnnkkkkt  tt  tt  tt cccccckcccccckRRRRRRRRRRhH",
        "nn  kkkkttttttttttttttcccccc cccccc hhhhhhhhhhH ",
        "n        rr   m   rr  CCCCCC CCCCCC HHHHHHHHHH  ",
        "         rr   m   rr                            ",
        "              m                                 ",
        "              m                                 ",
        "        fffffffffffff                           ",
        "        fppfppfppfppf                           ",
        "        fppfppfppfppf                           ",
        "        fffffffffffff                           ",
        "        fppfppfppfppf                           ",
        "        fppfppfppfppf                           ",
        "        fffffffffffff                           ",
    ].map(Array.init)

    static let colors: [Character: Color] = [
        "f": Color(hex: 0xB8962E), "p": Color(hex: 0x2E4E8C), "m": Color(hex: 0x8C939C), "r": Color(hex: 0xECE4CF),
        "t": Color(hex: 0x9AA1AA), "n": Color(hex: 0x5A5F68), "k": Color(hex: 0x3A3F47), "H": Color(hex: 0xA7AEB7),
        "h": Color(hex: 0xDCE1E6), "w": Color(hex: 0xF2D16B), "R": Color(hex: 0xD64545), "C": Color(hex: 0x9C8A64),
        "c": Color(hex: 0xC9B48A), "a": Color(hex: 0xDCE3EA),
    ]

    static var shipW: Double { Double(ship[0].count) }
    static var shipH: Double { Double(ship.count) }
    /// Her middle under way, and docked beside a station.
    static let flying = (x: 80.0, y: 40.0)
    static let docked = (x: 40.0, y: 40.0)
    /// The row of the drive's bell, where the glow comes out.
    static let driveRow = 13

    /// Which way she points.
    enum Facing: Int { case ahead, down, astern, up }

    /// Where the sprite's (column, row) lands on the canvas, the sprite's middle at `c`.
    static func place(_ col: Double, _ row: Double, _ facing: Facing, _ c: (x: Double, y: Double)) -> (x: Double, y: Double) {
        let w = shipW, h = shipH
        switch facing {
        case .ahead: return ((c.x - w / 2 + col).rounded(.down), (c.y - h / 2 + row).rounded(.down))
        case .astern: return ((c.x - w / 2 + w - 1 - col).rounded(.down), (c.y - h / 2 + row).rounded(.down))
        case .up: return ((c.x - h / 2 + row).rounded(.down), (c.y - w / 2 + w - 1 - col).rounded(.down))
        case .down: return ((c.x - h / 2 + h - 1 - row).rounded(.down), (c.y - w / 2 + col).rounded(.down))
        }
    }

    /// The engine's key for how she was caught at Mars, held to it by `MarsSkinTests`:
    /// 1 aerobraking, 2 a full burn, 3 the tanks ran dry in the burn.
    static let captureKey = "mars.capture"
    /// The engine's key for a set piece reached in the dark and still waiting.
    static let heldKey = "mars.held"

    // MARK: Where she is

    static let j = MarsSkin.journey
    static func index(_ id: String) -> Int { j.stops.firstIndex { $0.id == id } ?? 0 }

    /// The station she is docked at.
    static func dockedAt(_ f: SceneFrame) -> String? {
        guard f.atPort, let g = f.state, !lost(f), j.port(g.currentStop.id) != nil else { return nil }
        return g.currentStop.id
    }

    /// The hull has let go: the run is over and nothing holds the air.
    static func lost(_ f: SceneFrame) -> Bool {
        guard let g = f.state else { return false }
        return g.over && g.hull <= 0
    }

    /// At Jezero, the cargo down.
    static func landed(_ f: SceneFrame) -> Bool {
        guard let g = f.state, !lost(f) else { return false }
        return g.stopIndex == j.stops.count - 1 && g.mile >= g.currentStop.mile
    }

    /// The stop she has reached and not docked at: its question on screen, or going on.
    static func atStop(_ f: SceneFrame) -> Stop? {
        guard let g = f.state, dockedAt(f) == nil, !lost(f), !landed(f), g.stopIndex > 0 else { return nil }
        let stop = g.currentStop
        return g.mile == stop.mile ? stop : nil
    }

    /// Under way with no thrust: the array dark or the tanks dry, once she has left.
    static func coasting(_ f: SceneFrame) -> Bool {
        guard let g = f.state, dockedAt(f) == nil, !lost(f), !landed(f), g.day > 0 else { return false }
        return Mars.coasting(g)
    }

    /// The array dark: every panel dead, docked or not.
    static func dark(_ f: SceneFrame) -> Bool {
        guard let g = f.state, g.day > 0 else { return false }
        return Mars.dark(g)
    }

    /// The tanks dry under way: nothing for the thrusters that keep her pointed.
    static func tumbling(_ f: SceneFrame) -> Bool {
        guard let g = f.state else { return false }
        return coasting(f) && g.fuel <= 0
    }

    /// Turned end for end: past Turnover, unless she reached it dark and it is still
    /// waiting for power.
    static func turned(_ g: GameState) -> Bool {
        let i = index("turnover")
        if g.vars[heldKey].map({ Int($0) }) == i { return false }
        return g.stopIndex > i || (g.stopIndex == i && g.mile > g.currentStop.mile)
    }

    /// Dipping through the top of the Martian air, as the engine counts it: in the capture
    /// region, short of Phobos, having chosen to aerobrake.
    static func aerobraking(_ g: GameState) -> Bool {
        g.region.id.rawValue == "capture" && g.mile < (j.stop("phobos")?.mile ?? 0) && g.vars[captureKey] == 1
    }

    static func facing(_ f: SceneFrame) -> Facing {
        guard let g = f.state else { return .ahead }
        if dockedAt(f) != nil { return .ahead }
        if tumbling(f) { return Facing(rawValue: Int((f.t / 1.6).rounded(.down)) % 4) ?? .ahead }
        if atStop(f)?.id == "turnover" { return .up }
        return turned(g) ? .astern : .ahead
    }

    // MARK: Drawing

    static func wrap(_ x: Double, _ period: Double) -> Double {
        let m = x.truncatingRemainder(dividingBy: period)
        return m < 0 ? m + period : m
    }

    static func draw(_ px: PixelCanvas, _ f: SceneFrame) {
        let g = f.state
        let t = f.t
        if landed(f) {
            jezero(px, t: t)
            weather(px, f, ship: nil)
            return
        }
        let mile = g?.mile ?? 2000
        let region = g?.region.id.rawValue ?? "departure"
        let stop = atStop(f)
        let station = dockedAt(f)

        px.bands(top: 0x04060D, bottom: 0x0B1226, from: 0, each: 10, count: 8)
        stars(px)
        backdrop(px, mile: mile, region: region, stop: stop?.id, station: station, t: t)

        if let station {
            dockedScene(px, station, t: t)
        } else if let stop {
            stopScene(px, stop.id, f, t: t)
        }
        if f.moving && station == nil && !lost(f) { specks(px, t: t, fast: coasting(f) ? 0.4 : 1) }

        if lost(f) {
            if let g, aerobraking(g) { streak(px, t: t) } else { wreck(px, f, t: t) }
            weather(px, f, ship: nil)
            return
        }
        let centre = station != nil ? docked : flying
        let face = facing(f)
        if let g, aerobraking(g), station == nil { plasma(px, t: t) }
        freighter(px, f, at: centre, facing: face)
        if stop?.id == "turnover" { puffs(px, centre, t: t) }
        weather(px, f, ship: (centre, face))
    }

    // MARK: Sky

    /// The same stars every time, a few of them tinted.
    static func stars(_ px: PixelCanvas) {
        for i in 0..<48 {
            let x = Double((i * 53 + 17) % 160), y = Double((i * 29 + 7) % 80)
            let tint: UInt32 = i % 7 == 0 ? 0xFFD9A0 : i % 5 == 0 ? 0xA8C8FF : 0xFFFFFF
            px.rect(x, y, 1, 1, Color(hex: tint).opacity(i % 3 == 0 ? 0.85 : 0.4))
        }
    }

    /// A filled disc, a row at a time, darker on the side away from the Sun (lower left).
    static func disc(_ px: PixelCanvas, _ cx: Double, _ cy: Double, _ r: Double, _ color: UInt32, shade: UInt32? = nil) {
        guard r > 0 else { return }
        if r < 1.5 {
            px.rect(cx.rounded(.down), cy.rounded(.down), r < 1 ? 1 : 2, r < 1 ? 1 : 2, Color(hex: color))
            return
        }
        let ri = Int(r.rounded(.up))
        for dy in -ri...ri {
            let y = Double(dy)
            let half = (r * r - y * y).squareRoot()
            guard half >= 0.5 else { continue }
            let x0 = (cx - half).rounded(.down), wd = (2 * half).rounded()
            px.rect(x0, (cy + y).rounded(.down), max(1, wd), 1, Color(hex: color))
            if let shade, r >= 3 {
                let s = (half * (0.35 + 0.25 * max(0, y) / r)).rounded()
                if s >= 1 { px.rect(x0, (cy + y).rounded(.down), s, 1, Color(hex: shade)) }
            }
        }
    }

    /// The Sun's size: four and a half pixels across at Earth's distance, smaller further out.
    static func sunRadius(_ mile: Int) -> Double { 4.5 / MarsChart.au(atMile: Double(mile)) }

    static func sun(_ px: PixelCanvas, x: Double, y: Double, r: Double, corona: Bool) {
        if corona {
            let c = Color(hex: 0xFFF2C8)
            for (dx, dy, l) in [(1.0, 0.0, 16.0), (-1, 0, 12), (0, 1, 9), (0, -1, 10), (0.7, -0.7, 8), (-0.7, 0.7, 7)] {
                for k in stride(from: r + 1, to: r + l, by: 1) {
                    px.rect((x + dx * k).rounded(.down), (y + dy * k).rounded(.down), 1, 1, c.opacity(0.5 * (1 - (k - r) / l)))
                }
            }
        }
        disc(px, x, y, r + 1, 0xC9A84A)
        disc(px, x, y, r, 0xFFF4C2)
        disc(px, x, y, max(1, r - 2), 0xFFFFFF)
    }

    /// Earth's size behind her: filling the lower left at Gateway, a disc for the first
    /// weeks, then a point of light.
    static func earthRadius(_ mile: Int) -> Double {
        let m = Double(max(0, mile))
        if m <= 150 { return 34 * (1 - m / 150 * 0.65) }
        return max(2, 11.9 * pow(150 / m, 0.6))
    }

    /// Earth, its clouds and a continent, the Moon beside it.
    static func earth(_ px: PixelCanvas, _ r: Double) {
        let cx = 26 - r * 0.5, cy = 20 + r * 1.5
        disc(px, cx, cy, r + 1, 0x7FB6F0)
        disc(px, cx, cy, r, 0x2E6FB5, shade: 0x1B4778)
        if r >= 5 {
            disc(px, cx + r * 0.2, cy - r * 0.25, r * 0.38, 0x5F8A4A)
            for k in 0..<3 {
                let dk = Double(k)
                px.rect((cx - r * 0.5 + dk * r * 0.3).rounded(.down), (cy - r * 0.55 + dk * r * 0.4).rounded(.down),
                        max(2, (r * 0.5).rounded()), 1, Color(hex: 0xEEF1F4).opacity(0.85))
            }
        }
        let mr = max(1, r * 0.27)
        disc(px, cx + r + 6, cy - r / 3 - 2, mr, 0xB8B8B0, shade: 0x7F7F78)
    }

    /// Mars's size ahead: a red point from 300 million km, a disc on the approach, and most
    /// of the view in the capture.
    static func marsRadius(_ mile: Int) -> Double {
        if mile < 30_000 { return 0 }
        if mile <= 46_000 { return 1 + 6 * Double(mile - 30_000) / 16_000 }
        let f = min(1, Double(mile - 46_000) / 2000)
        return 7 * pow(46.0 / 7, f)
    }

    static func marsCentre(_ r: Double) -> (x: Double, y: Double) {
        r <= 7 ? (140, 30) : (140 + (r - 7) * 0.45, 30 + (r - 7) * 1.1)
    }

    /// Mars: rust, shaded away from the Sun, its dark country and a white cap once it is
    /// big enough to show them.
    static func mars(_ px: PixelCanvas, _ cx: Double, _ cy: Double, _ r: Double) {
        if r >= 6 { disc(px, cx, cy, r + 1, 0xE2A06A) }
        disc(px, cx, cy, r, 0xC0613A, shade: 0x7E3A22)
        guard r >= 4 else { return }
        for (dx, dy, s) in [(-0.1, 0.1, 0.32), (0.3, -0.2, 0.18), (0.15, 0.45, 0.22)] {
            disc(px, cx + dx * r, cy + dy * r, max(1, r * s), 0x8A4129)
        }
        disc(px, cx + r * 0.05, cy - r * 0.85, max(1, r * 0.22), 0xF4F1EA)
    }

    /// What is in the sky for this stretch of the arc, this stop or this station.
    static func backdrop(_ px: PixelCanvas, mile: Int, region: String, stop: String?, station: String?, t: Double) {
        let behind = region == "shadow" || stop == "shadow"
        if region == "deep" || behind { milkyWay(px) }
        if region == "inner" { px.polygon([(146, 6), (146, 13), (0, 34), (0, 12)], Color(hex: 0xFFF2C8).opacity(0.07)) }
        let rs = sunRadius(mile)
        if behind {
            sun(px, x: 18, y: 36, r: rs + 1, corona: true)
        } else if station != "phobos" {
            sun(px, x: 147, y: 9, r: rs, corona: false)
        }
        if station == "gateway" || station == "phobos" || stop == "lunar" { return }
        if mile < 3000 {
            earth(px, earthRadius(mile))
        } else if mile < 24_000 {
            // Earth and the Moon as a double star.
            px.rect(23, 19, 2, 2, Color(hex: 0x9CC8F2))
            px.rect(27, 20, 1, 1, Color(hex: 0xD8D8D0))
        }
        if region == "stream1" || region == "stream2" { stream(px, second: region == "stream2", t: t) }
        let r = marsRadius(mile)
        if r > 0 && stop != "phobos" {
            let c = marsCentre(r)
            mars(px, c.x, c.y, r)
            if region == "capture" { limb(px, c, r) }
            if r >= 4 && r <= 12 {
                px.rect((c.x - r - 5).rounded(.down), (c.y - 3).rounded(.down), 2, 1, Color(hex: 0x9C8F80))
                px.rect((c.x + r + 3).rounded(.down), (c.y + 4).rounded(.down), 1, 1, Color(hex: 0xB0A595))
            }
        }
    }

    /// The thin air over Mars, a pale band on its edge.
    static func limb(_ px: PixelCanvas, _ c: (x: Double, y: Double), _ r: Double) {
        for k in stride(from: 0.0, to: 360, by: 3) {
            let a = k * .pi / 180
            px.rect((c.x + (r + 1.5) * cos(a)).rounded(.down), (c.y + (r + 1.5) * sin(a)).rounded(.down), 1, 1,
                    Color(hex: 0xF0C8A0).opacity(0.5))
        }
    }

    /// The galaxy edge-on: a band of faint stars from lower left to upper right.
    static func milkyWay(_ px: PixelCanvas) {
        px.polygon([(0, 60), (0, 74), (160, 18), (160, 4)], Color(hex: 0xC8D2F0).opacity(0.05))
        for i in 0..<70 {
            let s = Double(i) / 70
            let x = (160 * s + Double((i * 37) % 11) - 5).rounded(.down)
            let y = (67 - 56 * s + Double((i * 53) % 15) - 7).rounded(.down)
            px.rect(x, y, 1, 1, Color.white.opacity(i % 4 == 0 ? 0.5 : 0.22))
        }
    }

    /// A comet's old debris stream across the sky, glittering as it turns; the second is
    /// bluer, sparser and coarser.
    static func stream(_ px: PixelCanvas, second: Bool, t: Double) {
        let n = second ? 30 : 46
        let base: UInt32 = second ? 0x9DB8D6 : 0xD6E2EA
        px.polygon([(0, 8), (0, 22), (160, 42), (160, 28)], Color(hex: base).opacity(0.05))
        for i in 0..<n {
            let di = Double(i)
            let x = wrap(di * 23 + 7 - t * (1 + Double(i % 3)), 170) - 5
            let y = 15 + x * 0.125 + Double((i * 17) % 13) - 6
            let flash = (i + Int((t * 3).rounded(.down))) % 9 == 0
            let size: Double = second && i % 4 == 0 ? 2 : 1
            px.rect(x.rounded(.down), y.rounded(.down), size, size, Color(hex: flash ? 0xFFFFFF : base).opacity(flash ? 0.95 : 0.6))
        }
    }

    /// Near dust going by: how fast she is moving, whether or not the drive is lit.
    static func specks(_ px: PixelCanvas, t: Double, fast: Double) {
        for i in 0..<7 {
            let di = Double(i)
            let x = wrap(di * 47 - t * (30 + di * 6) * fast, 170) - 5
            px.rect(x.rounded(.down), Double((i * 31 + 9) % 76) + 2, 1, 1, Color(hex: 0x8C939C).opacity(0.7))
        }
    }

    // MARK: The freighter

    static func freighter(_ px: PixelCanvas, _ f: SceneFrame, at c: (x: Double, y: Double), facing: Facing) {
        let t = f.t
        let isDark = dark(f)
        let power = max(0, min(100, f.sails)), hull = max(0, min(100, f.hull))
        let gusting = f.weather.sky == .breeze
        var col = colors
        if isDark {
            col["p"] = Color(hex: 0x23262E)
            col["f"] = Color(hex: 0x6E5C2A)
            col["w"] = Color(hex: 0x3A3F47)
        }
        let missing = Color(hex: 0x10141C), dent = Color(hex: 0x8C939C)
        for (r, row) in ship.enumerated() {
            for (k, ch) in row.enumerated() where ch != " " {
                guard var color = col[ch] else { continue }
                // Panels fall dark cell by cell as power goes.
                if ch == "p" && !isDark {
                    let cell = ((k / 3) * 37 + (r / 3) * 61) % 100
                    if Double(cell) >= power + 12 { color = missing }
                }
                // Dents, and later bare plate, as the hull wears.
                if (ch == "h" || ch == "c") && hull < 60 && (k * 5 + r * 3) % 9 == 0 { color = dent }
                var y = Double(r)
                if gusting && (ch == "f" || ch == "p") {
                    y += (sin(t * 7 + Double(k) * 0.9) > 0.55) ? (r < 10 ? -1 : 1) : 0
                }
                let q = place(Double(k), y, facing, c)
                px.rect(q.x, q.y, 1, 1, color)
            }
        }
        if hull < 35 {
            // Silver patches, and air going out of a seam.
            for (k, r) in [(24.0, 12.0), (39, 14), (31, 13)] {
                let q = place(k, r, facing, c)
                px.rect(q.x, q.y, 2, 2, Color(hex: 0xC8CED6))
            }
            for i in 0..<4 {
                let d = wrap(t * 6 + Double(i) * 2.5, 10)
                let q = place(38 - d * 0.6, 17 + d, facing, c)
                px.rect(q.x, q.y, 1, 1, Color.white.opacity(max(0.1, 0.8 - d / 12)))
            }
        }
        if f.moving || f.state == nil, dockedAt(f) == nil, !coasting(f) {
            glow(px, f, at: c, facing: facing)
        }
    }

    /// How long the drive's glow is, by thrust: a faint one at an economy burn.
    static func glowLength(_ pace: Pace) -> Int {
        switch pace {
        case .easy: return 4
        case .steady: return 6
        case .full: return 10
        }
    }

    static func glow(_ px: PixelCanvas, _ f: SceneFrame, at c: (x: Double, y: Double), facing: Facing) {
        let len = glowLength(f.state?.pace ?? .steady) + (Int((f.t * 9).rounded(.down)) % 3 == 0 ? 1 : 0)
        let core = Color(hex: 0xEAF2FF), mid = Color(hex: 0x8FB0FF), outer = Color(hex: 0x5368D0)
        for d in 1...len {
            let fade = 1 - Double(d) / Double(len + 1)
            let spread = d > 2 ? 2 : 1
            for dr in -spread...spread {
                let q = place(Double(-d), Double(driveRow + dr), facing, c)
                let color = dr == 0 ? (d <= 2 ? core : mid) : outer
                px.rect(q.x, q.y, 1, 1, color.opacity(0.35 + 0.6 * fade))
            }
        }
    }

    /// Small white puffs at both ends: the thrusters turning her end for end.
    static func puffs(_ px: PixelCanvas, _ c: (x: Double, y: Double), t: Double) {
        let p = wrap(t * 3, 4)
        for (k, r) in [(-2.0 - p, 11.0), (49 + p, 15)] {
            let q = place(k, r, .up, c)
            px.rect(q.x, q.y, 2, 2, Color.white.opacity(0.8 - p * 0.15))
        }
    }

    /// The glow of the air she is pushing through, round her front and trailing back.
    static func plasma(_ px: PixelCanvas, t: Double) {
        let c = flying
        px.polygon([(c.x + 22, c.y - 9), (c.x + 30, c.y), (c.x + 22, c.y + 9), (c.x - 40, c.y + 3), (c.x - 40, c.y - 3)],
                   Color(hex: 0xFF9A50).opacity(0.25 + 0.1 * sin(t * 11)))
        px.polygon([(c.x + 25, c.y - 6), (c.x + 29, c.y), (c.x + 25, c.y + 6)], Color(hex: 0xFFE2B0).opacity(0.8))
    }

    // MARK: Stops

    static func stopScene(_ px: PixelCanvas, _ id: String, _ f: SceneFrame, t: Double) {
        switch id {
        case "lunar":
            earth(px, earthRadius(f.state?.mile ?? 38))
            disc(px, 134, 62, 26, 0xBDBDB4, shade: 0x84847C)
            for (dx, dy, r) in [(-8.0, -10.0, 4.0), (6, -2, 6), (-2, 9, 3), (12, 12, 2), (-14, 4, 2)] {
                disc(px, 134 + dx, 62 + dy, r, 0x9A9A92)
                px.rect(134 + dx - r + 1, 62 + dy - r, max(1, r), 1, Color(hex: 0x6F6F68))
            }
        case "hill":
            // The edge of Earth's reach: a line nobody can see, dotted anyway.
            for y in stride(from: 0.0, to: 80, by: 3) {
                let x = 44 + 6 * sin(y / 80 * .pi)
                px.rect(x.rounded(.down), y, 1, 1, Color(hex: 0x6D9CC8).opacity(0.6))
            }
        case "cycler":
            cycler(px, centre: (128, 17), scale: 0.45, t: t)
        case "midway":
            midway(px, at: (128, 6), scale: 0.4)
        case "shadow":
            // Earth at the Sun's edge, about to go behind it.
            px.rect(23, 33, 1, 1, Color(hex: 0x9CC8F2))
            noise(px, t: t, count: 18)
        case "approach":
            // The way in: a dashed line from her bow down round the planet's edge.
            for k in stride(from: 0.0, to: 1, by: 0.06) {
                let x = 106 + 30 * k, y = 40 - 14 * k * (1 - k) + 2 * k
                px.rect(x.rounded(.down), y.rounded(.down), 2, 1, Color(hex: 0xF2D16B).opacity(0.6))
            }
        case "phobos":
            mars(px, 150, 70, 40)
            limb(px, (150, 70), 40)
            phobosMoon(px, 122, 18, 9)
        default:
            break
        }
    }

    // MARK: Stations

    static func dockedScene(_ px: PixelCanvas, _ id: String, t: Double) {
        // The arm she is docked by.
        let arm = Color(hex: 0x8C939C)
        switch id {
        case "gateway":
            gateway(px, t: t)
            px.rect(64, 39, 22, 2, arm)
        case "cycler":
            px.rect(64, 39, 8, 2, arm)
            cycler(px, centre: (126, 40), scale: 1, t: t)
        case "midway":
            px.rect(64, 39, 22, 2, arm)
            midway(px, at: (100, 6), scale: 1)
        case "phobos":
            mars(px, 118, -70, 100)
            phobosYard(px, t: t)
            px.rect(64, 39, 10, 2, arm)
        default:
            break
        }
    }

    /// Gateway Yard: Earth's curve below, and the yard's open frame with a crane and lights.
    static func gateway(_ px: PixelCanvas, t: Double) {
        for y in stride(from: 58.0, to: 80, by: 1) {
            let half = (220.0 * 220 - (276 - y) * (276 - y)).squareRoot()
            let x0 = 70 - half
            px.rect(x0.rounded(.down), y, (2 * half).rounded(), 1, Color(hex: y < 60 ? 0x7FB6F0 : 0x2E6FB5))
        }
        for (x, y, w) in [(10.0, 64.0, 18.0), (60, 68, 26), (110, 63, 14), (130, 72, 22), (30, 75, 16)] {
            px.rect(x, y, w, 2, Color(hex: 0xEEF1F4).opacity(0.75))
        }
        px.rect(96, 66, 14, 4, Color(hex: 0x5F8A4A))
        let frame = Color(hex: 0x9AA1AA), dim = Color(hex: 0x6B717A)
        px.rect(86, 10, 70, 2, frame)
        px.rect(86, 54, 70, 2, frame)
        px.rect(86, 10, 2, 46, frame)
        px.rect(154, 10, 2, 46, frame)
        for k in stride(from: 0.0, to: 66, by: 11) {
            px.line(from: (88 + k, 12), to: (99 + k, 54), dim)
            px.rect(88 + k, 12, 1, 42, dim)
        }
        // The crane, its arm over a cargo can.
        px.rect(120, 4, 2, 8, frame)
        px.rect(104, 4, 26, 2, frame)
        px.rect(105, 6, 1, 14, Color(hex: 0x4B4F55))
        px.rect(100, 20, 12, 7, Color(hex: 0xC9B48A))
        px.rect(100, 20, 12, 1, Color(hex: 0x9C8A64))
        // A habitat ring segment with lit windows, and work lights blinking.
        px.rect(126, 30, 22, 10, Color(hex: 0xDCE1E6))
        for k in 0..<5 { px.rect(128 + Double(k) * 4, 34, 2, 2, Color(hex: 0xF2D16B)) }
        let on = Int((t * 2).rounded(.down)) % 2 == 0
        for (x, y) in [(86.0, 9.0), (155, 9), (86, 55), (155, 55)] {
            px.rect(x, y, 2, 2, Color(hex: on ? 0xFFB347 : 0x7A5A2A))
        }
    }

    /// The cycler: an ice shield like a dirty snowball, a spine of tanks, and a wheel
    /// turning round its hub with lit windows on the rim.
    static func cycler(_ px: PixelCanvas, centre c: (x: Double, y: Double), scale s: Double, t: Double) {
        let spine = Color(hex: 0xA7AEB7)
        disc(px, c.x + 26 * s, c.y, 12 * s, 0x8E8A84, shade: 0x5E5A56)
        for (dx, dy) in [(-3.0, -4.0), (4, 3), (1, -8), (-6, 5)] {
            px.rect((c.x + (26 + dx) * s).rounded(.down), (c.y + dy * s).rounded(.down), max(1, 2 * s), max(1, 2 * s),
                    Color(hex: 0xDAD6CC))
        }
        px.rect((c.x - 56 * s).rounded(.down), (c.y - 2 * s).rounded(.down), max(2, 70 * s), max(1, 4 * s), spine)
        for k in 0..<3 {
            px.rect((c.x - (50 - Double(k) * 14) * s).rounded(.down), (c.y - 4 * s).rounded(.down), max(2, 10 * s), max(2, 8 * s),
                    Color(hex: 0xDCE1E6))
        }
        let r = 15 * s
        let turn = t * 0.6
        for k in 0..<4 {
            let a = turn + Double(k) * .pi / 2
            px.line(from: (c.x, c.y), to: (c.x + r * cos(a), c.y + r * sin(a)), spine)
        }
        for k in stride(from: 0.0, to: 360, by: s < 1 ? 20 : 10) {
            let a = k * .pi / 180
            px.rect((c.x + r * cos(a)).rounded(.down), (c.y + r * sin(a)).rounded(.down), max(1, 2 * s), max(1, 2 * s),
                    Color(hex: 0xC8CDD3))
        }
        for k in 0..<8 {
            let a = turn + Double(k) * .pi / 4 + 0.3
            px.rect((c.x + r * cos(a)).rounded(.down), (c.y + r * sin(a)).rounded(.down), 1, 1, Color(hex: 0xFFE27A))
        }
        disc(px, c.x, c.y, max(1, 3 * s), 0x8C939C)
    }

    /// Midway Depot: three tanks, a habitat can, and a light in one window.
    static func midway(_ px: PixelCanvas, at o: (x: Double, y: Double), scale s: Double) {
        func r(_ x: Double, _ y: Double, _ w: Double, _ h: Double, _ c: UInt32) {
            px.rect((o.x + x * s).rounded(.down), (o.y + y * s).rounded(.down), max(1, (w * s).rounded()), max(1, (h * s).rounded()),
                    Color(hex: c))
        }
        for k in 0..<3 {
            let x = Double(k) * 18
            r(x, 6, 14, 52, 0xD9D4C8)
            r(x, 4, 14, 2, 0xA7A196)
            r(x, 58, 14, 2, 0xA7A196)
            r(x, 22, 14, 4, 0xA65A32)
            r(x + 2, 8, 2, 48, 0xEFEBE2)
        }
        r(-14, 30, 62, 3, 0x8C939C)
        r(10, 34, 34, 14, 0xDCE1E6)
        r(10, 34, 34, 2, 0xA7AEB7)
        r(16, 39, 3, 3, 0x3A3F47)
        r(24, 39, 3, 3, 0xF2D16B)
        r(32, 39, 3, 3, 0x3A3F47)
    }

    /// Phobos, a lumpy grey potato, from a distance.
    static func phobosMoon(_ px: PixelCanvas, _ cx: Double, _ cy: Double, _ r: Double) {
        disc(px, cx, cy, r, 0x7A6E64, shade: 0x4E453E)
        disc(px, cx + r * 0.5, cy - r * 0.3, r * 0.6, 0x7A6E64)
        disc(px, cx - r * 0.2, cy + r * 0.1, max(1, r * 0.3), 0x5E544B)
    }

    /// Phobos Yard: the moon's ground close below, the yard dug into it, Mars overhead.
    static func phobosYard(_ px: PixelCanvas, t: Double) {
        px.hills(0..<160, base: 80, Color(hex: 0x6E6259)) { x in 20 + 3 * sin(x / 13) + 2 * sin(x / 5 + 1) }
        for (x, y, r) in [(20.0, 70.0, 4.0), (60, 74, 3), (140, 72, 5), (95, 76, 2)] {
            disc(px, x, y, r, 0x564B43)
        }
        // The hangar mouth and its lights, and a crane over it.
        px.rect(104, 58, 34, 14, Color(hex: 0x1E1B19))
        px.rect(102, 56, 38, 2, Color(hex: 0x9AA1AA))
        let on = Int((t * 2).rounded(.down)) % 2 == 0
        for k in 0..<5 { px.rect(107 + Double(k) * 7, 62, 2, 2, Color(hex: k % 2 == (on ? 0 : 1) ? 0xFFB347 : 0xF2D16B)) }
        px.rect(146, 34, 2, 26, Color(hex: 0x9AA1AA))
        px.rect(126, 34, 22, 2, Color(hex: 0x9AA1AA))
        px.rect(128, 36, 1, 10, Color(hex: 0x4B4F55))
    }

    // MARK: Jezero

    /// The pad at Jezero: a sky the colour of weak tea, the crater rim on the horizon, the
    /// settlement's domes, and the cargo lander on the pad with people in suits about it.
    static func jezero(_ px: PixelCanvas, t: Double) {
        px.sky(top: 0xB98457, bottom: 0xE6B98A, horizon: 60)
        // The freighter, a moving star in orbit.
        px.rect(wrap(30 + t * 2, 160).rounded(.down), 8, 1, 1, Color.white)
        px.hills(0..<160, base: 58, Color(hex: 0x9A5A3A)) { x in 4 + 3 * sin(x / 17) + 2 * sin(x / 7) }
        px.rect(0, 58, 160, 22, Color(hex: 0xA65A32))
        for (x, y) in [(8.0, 66.0), (30, 74), (90, 70), (140, 76), (120, 64), (64, 77)] {
            px.rect(x, y, 3, 2, Color(hex: 0x7E3A22))
        }
        // Domes.
        for (x, r) in [(112.0, 9.0), (131, 12.0), (148, 7.0)] {
            disc(px, x, 58, r, 0xE4DDD0, shade: 0xB9B0A2)
            px.rect(x - 1, 54, 2, 2, Color(hex: 0xF2D16B))
        }
        px.rect(96, 56, 64, 4, Color(hex: 0xA65A32))
        // The pad, the lander on its legs, its ramp down, and three people in suits.
        px.rect(30, 62, 46, 3, Color(hex: 0x8C8378))
        let shell = Color(hex: 0xDCE1E6)
        px.polygon([(44, 58), (62, 58), (58, 40), (48, 40)], shell)
        px.rect(48, 38, 10, 2, Color(hex: 0xA7AEB7))
        px.rect(50, 46, 6, 2, Color(hex: 0xF2D16B))
        px.line(from: (45, 58), to: (40, 62), Color(hex: 0x8C939C))
        px.line(from: (61, 58), to: (66, 62), Color(hex: 0x8C939C))
        px.polygon([(58, 56), (70, 61), (70, 62), (58, 58)], Color(hex: 0x8C939C))
        for (k, x) in [70.0, 76, 82].enumerated() {
            px.rect(x, 57 + Double(k % 2), 2, 4, Color.white)
            px.rect(x, 57 + Double(k % 2), 2, 1, Color(hex: 0xF2B632))
        }
    }

    // MARK: The end of her

    /// The hull has let go: two pieces going apart, and what was inside them.
    static func wreck(_ px: PixelCanvas, _ f: SceneFrame, t: Double) {
        let d = 3 + min(8, t * 0.4)
        let c = flying
        for (r, row) in ship.enumerated() {
            for (k, ch) in row.enumerated() where ch != " " {
                guard let color = colors[ch] else { continue }
                let fore = k >= 28
                let x = c.x - shipW / 2 + Double(k) + (fore ? d : -d)
                let y = c.y - shipH / 2 + Double(r) + (fore ? -d / 3 : d / 2)
                px.rect(x.rounded(.down), y.rounded(.down), 1, 1, fore ? color : color.opacity(0.85))
            }
        }
        for i in 0..<16 {
            let a = Double(i) * 2.4, s = d * (0.8 + Double(i % 5) * 0.35)
            px.rect((c.x + 4 + s * cos(a)).rounded(.down), (c.y + s * sin(a) * 0.7).rounded(.down), 1, 1,
                    Color(hex: i % 3 == 0 ? 0xF2D16B : 0xDCE1E6).opacity(0.85))
        }
    }

    /// Lost in the aerobrake: Mars's edge, and a short bright line across its sky.
    static func streak(_ px: PixelCanvas, t: Double) {
        mars(px, 110, 120, 70)
        limb(px, (110, 120), 70)
        let x = 40 + wrap(t * 20, 90)
        px.line(from: (x - 24, 46), to: (x, 54), Color(hex: 0xFFE2B0))
        px.line(from: (x - 24, 47), to: (x, 55), Color(hex: 0xFF9A50).opacity(0.7))
        px.rect(x.rounded(.down), 54, 2, 2, Color.white)
    }

    // MARK: Space weather

    /// Interference on the picture.
    static func noise(_ px: PixelCanvas, t: Double, count: Int) {
        let frame = Int((t * 10).rounded(.down))
        for i in 0..<count {
            let h = (i * 7919 + frame * 104_729) & 0xFFFF
            px.rect(Double(h % 160), Double((h / 160) % 80), 1, 1, Color.white.opacity(i % 2 == 0 ? 0.55 : 0.3))
        }
    }

    /// What the weather looks like out here, over everything. The kind of sky picks it.
    static func weather(_ px: PixelCanvas, _ f: SceneFrame, ship: (at: (x: Double, y: Double), facing: Facing)?) {
        let t = f.t
        switch f.weather.sky {
        case .clear, .heat, .rain, .snow:
            break
        case .still:
            // A clean fix: Earth's signal reaching her dish, a pulse along it.
            guard let ship else { break }
            let dish = place(40, 6, ship.facing, ship.at)
            let from = (x: 0.0, y: 16.0)
            let n = 30.0
            for k in stride(from: 0.0, to: n, by: 1) {
                let x = from.x + (dish.x - from.x) * k / n, y = from.y + (dish.y - from.y) * k / n
                px.rect(x.rounded(.down), y.rounded(.down), 1, 1, Color(hex: 0x9FE8B0).opacity(0.35))
            }
            let p = wrap(t * 0.8, 1)
            px.rect((from.x + (dish.x - from.x) * p).rounded(.down), (from.y + (dish.y - from.y) * p).rounded(.down), 2, 2,
                    Color(hex: 0xC8FFD4))
        case .breeze:
            // The solar wind, streaming away from the Sun.
            for i in 0..<10 {
                let di = Double(i)
                let x = wrap(150 - t * (50 + di * 7) + di * 31, 180) - 10
                px.rect(x.rounded(.down), Double((i * 23 + 5) % 74) + 3, 9, 1, Color(hex: 0xF2D16B).opacity(0.22))
            }
        case .dust:
            // Pebbles going by, and now and then one hitting her.
            for i in 0..<14 {
                let di = Double(i)
                let p = wrap(t * (90 + di * 9) + di * 41, 200)
                let x = 170 - p, y = Double((i * 19) % 60) + p * 0.18 - 10
                px.line(from: (x, y), to: (x + 4, y - 1), Color(hex: 0xD9C9A8).opacity(0.8))
            }
            if let ship, Int((t * 1.3).rounded(.down)) % 3 == 0 {
                let q = place(30, 11, ship.facing, ship.at)
                px.rect(q.x, q.y, 2, 2, Color.white)
            }
        case .fog:
            // Radio noise: static over the picture.
            px.rect(0, 0, 160, 80, Color(hex: 0x8A93A0).opacity(0.1))
            noise(px, t: t, count: 70)
            let band = wrap(t * 25, 90) - 5
            px.rect(0, band.rounded(.down), 160, 1, Color.white.opacity(0.12))
        case .storm:
            // A proton storm: a pale wash, and hits flickering on the picture.
            px.rect(0, 0, 160, 80, Color(hex: 0xDDEBD9).opacity(0.16))
            hits(px, t: t, count: 14)
        case .gale:
            // A mass ejection: a bright front going through, and everything lit by it.
            px.rect(0, 0, 160, 80, Color(hex: 0xFFB070).opacity(0.12))
            let x0 = 160 - wrap(t * 45, 260)
            for k in 0..<40 {
                let x = x0 + Double(k) * 2
                guard x > -2, x < 160 else { continue }
                px.rect(x.rounded(.down), 0, 2, 80, Color(hex: 0xFFE2B8).opacity(0.5 * (1 - Double(k) / 40)))
            }
            hits(px, t: t, count: 20)
        }
    }

    /// Particles striking the camera: single bright pixels, somewhere new each moment.
    static func hits(_ px: PixelCanvas, t: Double, count: Int) {
        let frame = Int((t * 8).rounded(.down))
        for i in 0..<count {
            let h = (i * 2971 + frame * 7703) & 0x3FFF
            px.rect(Double(h % 160), Double((h / 160) % 80), 1, 1, Color.white.opacity(0.9))
        }
    }

    // MARK: VoiceOver

    /// Where she is, as a sentence says it after a verb: "in the first ice stream",
    /// "on the approach to Mars". The engine's region names are headings.
    static let phrases: [String: String] = [
        "cislunar": "in cislunar space, between the Earth and the Moon",
        "departure": "on the departure leg, Earth and the Moon behind her",
        "stream1": "in the first ice stream",
        "inner": "on the inner arc",
        "deep": "in deep space",
        "stream2": "in the second ice stream",
        "shadow": "in the conjunction shadow, the Sun between her and Earth",
        "approach": "on the approach to Mars",
        "capture": "closing on Mars",
    ]

    static func phrase(_ region: Region?) -> String {
        guard let region else { return "out along the arc" }
        return phrases[region.id.rawValue] ?? "out along the arc"
    }

    /// For the plot's label: docked somewhere, or out on the arc.
    static func whereabouts(_ g: GameState) -> String {
        if g.atPort, let port = j.port(g.currentStop.id) { return "docked at \(port.name)" }
        if g.stopIndex == j.stops.count - 1 && g.mile >= g.currentStop.mile { return "at Jezero Landing" }
        return phrase(g.region)
    }

    static func label(_ f: SceneFrame) -> String {
        guard let g = f.state else { return "A transfer freighter burning out from Earth, her solar wings spread" }
        let weather = "Weather: \(f.weather.name.lowercased())"
        if lost(f) {
            return aerobraking(g) ? "A short bright line across the top of the Martian sky, where the freighter was"
                : "The freighter in two pieces, drifting apart among her own debris. The pressure hull has let go"
        }
        if landed(f) { return "The cargo lander on the pad at Jezero Landing, the settlement's domes beyond and the crater rim on the horizon" }
        let wings = dark(f) ? ", her array dark" : ""
        if let id = dockedAt(f) {
            switch id {
            case "gateway": return "The freighter docked at Gateway Yard, Earth's blue curve below\(wings)"
            case "cycler": return "The freighter docked alongside the cycler Perpetua, her wheel turning\(wings)"
            case "midway": return "The freighter docked at Midway Depot, beside its three tanks\(wings)"
            default: return "The freighter docked at Phobos Yard, Mars overhead\(wings)"
            }
        }
        let how = tumbling(f) ? "tumbling slowly, her tanks dry," : coasting(f) ? "coasting with her array dark," : ""
        if let stop = atStop(f) {
            let lead = how.isEmpty ? "The freighter" : "The freighter, \(how)"
            switch stop.id {
            case "lunar": return "\(lead) passing the Moon, close enough to see its craters. \(weather)"
            case "hill": return "\(lead) crossing the edge of Earth's reach, Earth and the Moon behind her. \(weather)"
            case "cycler": return "\(lead) coming up on the cycler Perpetua, lit like a town at night. \(weather)"
            case "turnover": return "\(lead) standing on end at Turnover, halfway through turning round. \(weather)"
            case "midway": return "\(lead) coming up on Midway Depot's three tanks. \(weather)"
            case "shadow": return "\(lead) entering the conjunction shadow, Earth sliding behind the Sun. \(weather)"
            case "approach": return "\(lead) on the approach, Mars and its two moons ahead. \(weather)"
            case "phobos": return "\(lead) closing on Phobos, Mars filling half the sky. \(weather)"
            default: return "\(lead) at \(stop.name). \(weather)"
            }
        }
        let place = phrase(f.region)
        if !how.isEmpty { return "The freighter \(how) \(place)\(dark(f) && tumbling(f) ? ", her array dark" : ""). \(weather)" }
        if !f.moving { return "The freighter \(place), her drive idle\(wings). \(weather)" }
        if aerobraking(g) { return "The freighter skimming the top of the Martian air, glowing. \(weather)" }
        let verb = turned(g) ? "braking tail first" : "burning"
        return "The freighter \(verb) \(place). \(weather)"
    }
}
