import SwiftUI
import HornEngine

/// Over the Pole's scene: a small semi-rigid airship, nose to the right, over nine kinds
/// of country under nine weathers, an airship's scene being mostly sky. A mooring mast at
/// each of the five masts, and the stops between drawn as what they are: the Rhône's
/// mouth, the Circle, Bear Island, flags at the Pole, the village at Point Barrow, two
/// coasts at Cape Prince of Wales, the roofs of Nome. She flies lower as her lift goes,
/// her propeller stutters and smokes as the engines fail and stops altogether with the
/// tanks dry, and icing fog rimes her white.
enum AirshipScene {
    static let horizon = 58.0

    // MARK: Sky

    struct Palette {
        let top: UInt32, bot: UInt32
        /// How much of its own colour the ground keeps under this sky.
        var ground = 1.0
        var clouds = 0
        var cloud: UInt32 = 0xF4F7FA
        var sun = false
        /// How hard she pitches: 1 in ordinary air.
        var rough = 1.0
    }

    /// By the kind of sky. The two winds share a sky, and so do the two fogs: a following
    /// wind is the one that carries her (`speed` over 1), and icing fog is the fog that is
    /// hard on the crew (`harsh`).
    static func palette(_ w: Weather) -> Palette {
        switch w.sky {
        case .clear, .still, .heat, .dust:
            return Palette(top: 0x2D5F9A, bot: 0x9FD0EE, clouds: 1, sun: true)
        case .breeze:
            return w.speed > 1
                ? Palette(top: 0x2A5C98, bot: 0xA8D8F0, clouds: 2, sun: true)
                : Palette(top: 0x3A5F8A, bot: 0x9DB9D0, ground: 0.95, clouds: 3, cloud: 0xE1E8EE)
        case .rain:
            return Palette(top: 0x3E4A5A, bot: 0x7D8A98, ground: 0.75, clouds: 3, cloud: 0x6B7685)
        case .fog:
            return w.harsh > 0 ? Palette(top: 0x7F8C96, bot: 0xB9C4CC, ground: 0.7)
                               : Palette(top: 0x8D969E, bot: 0xC5CBD0, ground: 0.8)
        case .snow:
            return Palette(top: 0x55606E, bot: 0xA6B2BF, ground: 0.85, clouds: 3, cloud: 0x8C97A3)
        case .gale:
            return Palette(top: 0x33404F, bot: 0x6E7D8D, ground: 0.7, clouds: 3, cloud: 0x55616F, rough: 2)
        case .storm:
            return Palette(top: 0x15191F, bot: 0x3A434F, ground: 0.5, clouds: 3, cloud: 0x2C333D, rough: 3)
        }
    }

    static func following(_ w: Weather) -> Bool { w.sky == .breeze && w.speed > 1 }
    static func icing(_ w: Weather) -> Bool { w.sky == .fog && w.harsh > 0 }

    // MARK: The airship

    /// 32 × 14, nose to the right: the envelope with its painted band, the fins, the
    /// engine car with its pusher propeller, and the control car.
    static let ship = [
        "  ff                            ",
        "  ffff     hhhhhhhhhhhhhhh      ",
        "   ffffhhhhhhhhhhhhhhhhhhhhhh   ",
        "   ffeeeeeeeeeeeeeeeeeeeeeeeeee ",
        "    eeeeeeeeeeeeeeeeeeeeeeeeeeen",
        "fffrrrrrrrrrrrrrrrrrrrrrrrrrrrrn",
        "    eeeeeeeeeeeeeeeeeeeeeeeeeeen",
        "   ffeeeeeeeeeeeeeeeeeeeeeeeeee ",
        "   ffffdddddddddddddddddddddd   ",
        "  ffff     ddddddddddddddd      ",
        "  ff      p k k      k   k      ",
        "          pmmmmm   gwgwgwgwg    ",
        "          p mmm     ggggggg     ",
        "          p                     ",
    ].map(Array.init)

    static let colors: [Character: Color] = [
        "h": Color(hex: 0xEEF1F4), "e": Color(hex: 0xC8CDD3), "d": Color(hex: 0x8C939C), "r": Color(hex: 0xD64545),
        "f": Color(hex: 0xA7AEB7), "n": Color(hex: 0x6B6F76), "k": Color(hex: 0x4B4F55), "g": Color(hex: 0x6B4A2B),
        "w": Color(hex: 0xF2D16B), "m": Color(hex: 0x3A3F47), "p": Color(hex: 0xDCE3EA),
    ]

    /// Where she flies, and where she rides at a mast, nose to the mast head.
    static let flyingX = 44.0, flyingY = 14.0
    static let mooredX = 98.0, mooredY = 18.0
    static let mastX = 128.0, mastTop = 22.0

    // MARK: When and where

    static func isNight(_ hour: Int) -> Bool { hour >= 20 || hour < 5 }

    /// Days in 1926 before the first of each month.
    static let daysBefore = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334]

    /// Whether the sun stays up all night where she is on this date: when the sun's
    /// declination is more than 90° less her latitude, less 0.83° for refraction and its
    /// half-width. North of the Circle, and later in the spring the nearer the Circle:
    /// Kings Bay from about April 17, Vadsø from about May 16, the Circle itself only for
    /// a month round midsummer. Oslo, Pulham and Nome never.
    static func midnightSun(_ f: SceneFrame) -> Bool {
        guard let g = f.state else { return false }
        let d = g.date
        let declination = 23.44 * sin(2 * .pi * (Double(daysBefore[d.month] + d.day) - 80) / 365.24)
        return AirshipChart.latitude(atKm: Double(g.mile)) + declination > 89.17
    }

    /// The mast she is moored to, if she is: in port at a stop that has one. (At the end
    /// of the flight she is "in port" at Nome, which has no mast.)
    static func moored(_ f: SceneFrame) -> String? {
        guard f.atPort, let g = f.state, AirshipSkin.journey.port(g.currentStop.id) != nil else { return nil }
        return g.currentStop.id
    }

    /// With the tanks dry, once the flight is under way: a fresh voyage has bought nothing yet.
    static func drifting(_ f: SceneFrame) -> Bool {
        guard let g = f.state, moored(f) == nil, !down(f) else { return false }
        return g.fuel <= 0 && g.day > 0
    }

    /// Forced down: the flight is over and her lift is gone.
    static func down(_ f: SceneFrame) -> Bool {
        guard let g = f.state else { return false }
        return g.over && g.hull <= 0
    }

    /// The mast at the stop she has reached and is not moored to: its arrival's question
    /// on screen, or flying on past it, or just cast off. (Rome's is behind her as soon as
    /// she leaves.)
    static func passing(_ f: SceneFrame) -> String? {
        guard let g = f.state, moored(f) == nil, !down(f), g.stopIndex > 0 else { return nil }
        let stop = g.currentStop
        return g.mile == stop.mile && AirshipSkin.journey.port(stop.id) != nil ? stop.id : nil
    }

    /// The stop she is standing at, its arrival told, when it isn't a mast she is moored to.
    static func landmark(_ f: SceneFrame) -> Stop? {
        guard let g = f.state, moored(f) == nil, !down(f), g.stopIndex > 0 else { return nil }
        let stop = g.currentStop
        return stop.type != .port && g.mile == stop.mile ? stop : nil
    }

    // MARK: Drawing

    static func wrap(_ x: Double, _ period: Double) -> Double {
        let m = x.truncatingRemainder(dividingBy: period)
        return m < 0 ? m + period : m
    }

    static func draw(_ px: PixelCanvas, _ f: SceneFrame) {
        let s = palette(f.weather)
        let t = f.t, w = px.w, h = px.h, hz = horizon
        let region = f.region?.id.rawValue ?? "med"
        let sunUp = midnightSun(f)
        let dark = isNight(f.hour)
        let night = dark && !sunUp
        let dry = drifting(f)
        let stop = landmark(f)
        let port = moored(f)
        let atMast = port ?? passing(f)
        let tint: (UInt32) -> Color = { PixelCanvas.mix($0, 0x000000, 1 - s.ground) }
        // How fast the nearest country slides by, in pixels a second.
        let pace = f.moving ? 14 * (dry ? 0.25 : f.weather.speed) + 2 : 1.5

        px.sky(top: s.top, bottom: s.bot, horizon: hz)
        if s.sun && !night { sun(px, f, circling: sunUp, moored: port != nil) }
        let drift = f.moving ? (f.weather.sky == .breeze && !following(f.weather) ? 3.2 : 1.6) : 0.4
        px.clouds(s.clouds * 2, Color(hex: s.cloud), t: t, drift: drift)

        // The country: a mast's own ground, a stop's, or the region's.
        let country = atMast.map { "mast-" + $0 } ?? stop.map { ground(forStop: $0.id) } ?? region
        far(px, country, scroll: f.moving ? t * pace * 0.08 : 0, tint)
        px.rect(0, hz, w, h - hz, tint(base(country)))
        detail(px, country, t: t, pace: pace, rough: s.rough, tint)
        if let atMast { mast(px, atMast, t: t, lines: port != nil, tint) }
        if let stop { landmark(px, stop.id, t: t, tint) }
        if down(f) { camp(px, f.region, t: t, tint) }

        let at = position(f, s)
        airship(px, f, s, dry: dry || down(f), at: at)

        if region == "underFog" && port == nil && stop == nil && !down(f) { ceiling(px, t: t) }
        if following(f.weather) { streaks(px, t: t, pace: pace) }
        px.air(f.weather.sky, t: t)

        if night {
            px.rect(0, 0, w, h, Color(hex: 0x070B1C).opacity(0.6))
            lights(px, at: at, clear: s.sun)
        } else if dark {
            // The midnight sun: low, gold light the whole night through.
            px.rect(0, 0, w, h, Color(hex: 0xE8A070).opacity(0.14))
        }
    }

    /// Climbing and sinking across whichever side of the sky she isn't in; where it does
    /// not set, the midnight sun, circling low.
    static func sun(_ px: PixelCanvas, _ f: SceneFrame, circling: Bool, moored: Bool) {
        let color = Color(hex: 0xFFE27A)
        if circling {
            let a = Double(f.hour) / 24 * 2 * .pi
            // Round the far side of her: at (126, 44) at midnight, highest and nearest at noon.
            px.sun(x: (96 + 30 * cos(a)).rounded(.down), y: (40 + 4 * cos(a)).rounded(.down), color)
        } else {
            let across = Double(max(0, min(14, f.hour - 5))) / 14
            let x = (moored ? 60 : 140) - across * 40
            px.sun(x: x.rounded(.down), y: (5 + abs(Double(f.hour) - 12) * 2.2).rounded(.down), color)
        }
    }

    // MARK: Country

    /// What a stop stands on, when it isn't the region's ground: the ice at the Pole, the
    /// strait at Cape Prince of Wales.
    static func ground(forStop id: String) -> String {
        switch id {
        case "pole": return "polarSea"
        case "wales": return "strait"
        case "rhone": return "france"
        case "circle": return "scandinavia"
        case "bear": return "barents"
        default: return "alaska"
        }
    }

    static func base(_ id: String) -> UInt32 {
        switch id {
        case "med": return 0x1D4E7A
        case "france": return 0x4F6B3A
        case "northSea", "strait": return 0x24394E
        case "scandinavia": return 0xDDE6EC
        case "barents": return 0x1A2C3C
        case "polarSea", "underFog": return 0xE6EDF2
        case "aboveFog": return 0xD9DEE2
        case "alaska": return 0x6B6A4F
        case "mast-rome": return 0x8A8F4E
        case "mast-pulham": return 0x5E7A3E
        case "mast-oslo": return 0x4F6B3A
        case "mast-vadso": return 0x1A2C3C
        case "mast-kingsbay": return 0xE6EDF2
        default: return 0x4F6B3A
        }
    }

    /// What stands on the horizon.
    static func far(_ px: PixelCanvas, _ id: String, scroll: Double, _ tint: (UInt32) -> Color) {
        let hz = horizon
        let all = 0..<Int(px.w)
        func ridge(_ color: UInt32, _ range: Range<Int>? = nil, snow: Double? = nil, _ height: @escaping (Double) -> Double) {
            px.hills(range ?? all, base: hz, tint(color)) { height($0 + scroll) }
            guard let snow else { return }
            for i in range ?? all {
                let hh = jsRounded(height(Double(i) + scroll))
                if hh > snow { px.rect(Double(i), hz - hh, 1, min(3, hh - snow), tint(0xF4F7FA)) }
            }
        }
        switch id {
        case "med":
            ridge(0x4A6A7E, 112..<150) { x in max(0, 3 + 2 * sin(x * 0.2) - abs(x - 131) * 0.18) }
        case "france", "mast-rome":
            ridge(0x5E7A48) { 2 + 1.5 * sin($0 * 0.06) + sin($0 * 0.17) }
        case "scandinavia", "mast-oslo":
            ridge(0x6E7C8A, snow: 6) { 6 + 4 * sin($0 * 0.05) + 2 * sin($0 * 0.17) }
        case "barents", "polarSea", "mast-vadso":
            // Ice blink: the pale sky over far-off ice.
            px.rect(0, hz - 1, px.w, 1, tint(0xC8D4DC))
        case "aboveFog":
            ridge(0xF4F7FA) { 2 + 1.5 * sin($0 * 0.09) + sin($0 * 0.23) }
        case "alaska":
            ridge(0x5A5A44, snow: 4) { 3 + 2 * sin($0 * 0.05) + sin($0 * 0.19) }
        case "mast-kingsbay":
            // White peaks beyond the fjord, grey where the snow has slid off.
            ridge(0xF4F7FA) { 13 + 8 * sin($0 * 0.07) + 4 * sin($0 * 0.21) }
            ridge(0x8C939C) { max(0, 6 + 6 * sin($0 * 0.07 + 0.8) + 2 * sin($0 * 0.33)) }
        default:
            break
        }
    }

    /// Six rows of country sliding by under her, the nearer rows faster.
    static func detail(_ px: PixelCanvas, _ id: String, t: Double, pace: Double, rough: Double, _ tint: (UInt32) -> Color) {
        let w = px.w, hz = horizon
        for row in 0..<6 {
            let y = (hz + 2 + Double(row) * 3.4).rounded(.down)
            let rs = pace * (0.4 + Double(row) * 0.18)
            for i in 0..<7 {
                // Spread along the row, each nudged its own way, so no two rows line up.
                let spot = Double(i * 25 + (row * 41) % 25 + (i * 13 + row * 29) % 11)
                let x = (wrap(spot - t * rs, w + 12) - 6).rounded(.down)
                let k = (i + row) % 3
                let jitter = rough > 1 ? jsRounded(sin(t * 3 + Double(i + row))) : 0
                switch id {
                case "med", "northSea", "strait", "mast-vadso":
                    let wave: UInt32 = id == "med" ? 0x7FB8DE : 0x8AA0B4
                    px.rect(x, y + jitter, 2 + Double(k) + rough - 1, 1, tint(wave))
                case "france", "mast-rome", "mast-pulham", "mast-oslo":
                    // Hedgerows, and every so often a village.
                    px.rect(x, y + jitter, 4 + Double(k), 1, tint(0x3A5229))
                    if id == "france" && (row == 1 || row == 4) && i % 3 == 0 {
                        px.rect(x + 8, y - 1, 3, 2, tint(0xE9DFC8))
                        px.rect(x + 8, y - 2, 3, 1, tint(0x9A3B2E))
                    }
                case "scandinavia":
                    // Pines.
                    px.rect(x, y - 1, 1, 2, tint(0x2F4A35))
                    px.rect(x + 2 + Double(k), y, 1, 2, tint(0x2F4A35))
                case "barents":
                    // Floes, two to four pixels.
                    px.rect(x, y + jitter, 2 + Double(k), 1, tint(0xE8EEF3))
                case "polarSea", "underFog", "mast-kingsbay":
                    // Pressure ridges, and now and then a lead of open water.
                    px.rect(x, y + jitter, 3 + Double(k), 1, tint(0x9FB0BF))
                    if i % 4 == 1 { px.rect(x + 7, y + 1, 9 + Double(k) * 3, 1, tint(0x2A3C4F)) }
                case "aboveFog":
                    // The top of the fog, billowing.
                    px.rect(x, y, 6, 2, tint(0xF4F7FA))
                    px.rect(x + 1, y - 1, 4, 1, tint(0xF4F7FA))
                case "alaska":
                    // Snow lying in patches on the tundra.
                    px.rect(x, y + jitter, 3 + Double(k), k == 2 ? 2 : 1, tint(0xE6EDF2))
                default:
                    break
                }
            }
        }
    }

    /// Under the fog: its underside just over the envelope.
    static func ceiling(_ px: PixelCanvas, t: Double) {
        let c = Color(hex: 0xB9C1C8).opacity(0.9)
        px.rect(0, 0, px.w, 8, c)
        for i in 0..<12 {
            let x = (wrap(Double(i) * 14 - t * 4, px.w + 14) - 7).rounded(.down)
            px.rect(x, 8, 9, 2, c)
            px.rect(x + 2, 10, 5, 1, c.opacity(0.7))
        }
    }

    /// A following wind: streaks racing past her, faster than the country.
    static func streaks(_ px: PixelCanvas, t: Double, pace: Double) {
        for i in 0..<4 {
            let x = (wrap(Double(i * 47) - t * pace * 3, px.w + 12) - 6).rounded(.down)
            px.rect(x, 8 + Double(i) * 11, 6, 1, Color(hex: 0xE9F4FB))
        }
    }

    // MARK: Masts

    /// The town beside each mast, the lattice mast itself, and the ground crew: on her
    /// handling lines when she is moored (`lines`), waiting at the foot of the mast when not.
    static func mast(_ px: PixelCanvas, _ id: String, t: Double, lines: Bool, _ tint: (UInt32) -> Color) {
        let hz = horizon
        let roof = tint(0x9A3B2E)
        switch id {
        case "rome":
            // Two umbrella pines.
            for x in [10.0, 24] {
                px.rect(x + 5, hz - 14, 1, 14, tint(0x6B4A2B))
                px.rect(x, hz - 18, 12, 3, tint(0x2F4A35))
                px.rect(x + 2, hz - 20, 8, 2, tint(0x2F4A35))
                px.rect(x + 1, hz - 15, 10, 1, tint(0x24402C))
            }
        case "pulham":
            // A long airship shed, its doors open.
            px.rect(4, hz - 14, 40, 14, tint(0x8C939C))
            px.rect(6, hz - 16, 36, 2, tint(0x8C939C))
            px.rect(10, hz - 17, 28, 1, tint(0x8C939C))
            px.rect(38, hz - 12, 6, 12, tint(0x2A2D33))
            for i in 0..<5 { px.rect(8 + Double(i) * 6, hz - 13, 1, 13, tint(0x7A818A)) }
        case "oslo":
            // Ekeberg hill and its houses.
            px.hills(0..<64, base: hz, tint(0x2F4A35)) { max(0, 12 + 5 * sin($0 * 0.08) - abs($0 - 30) * 0.25) }
            for i in 0..<5 {
                let x = 8 + Double(i) * 9, bh = Double(3 + (i * 5) % 3)
                let top = hz - max(0, 12 + 5 * sin(x * 0.08) - abs(x - 30) * 0.25) + 2
                px.rect(x, top - bh, 5, bh, tint(0xE9DFC8))
                px.rect(x, top - bh - 1, 5, 1, roof)
            }
        case "vadso":
            // A strip of shore with four wooden houses, and the mast's bare island.
            px.rect(0, hz, 50, 4, tint(0x6E6A5E))
            for i in 0..<4 {
                let x = 4 + Double(i) * 11
                px.rect(x, hz - 4, 6, 4, tint(0xC9A27A))
                px.rect(x, hz - 5, 6, 1, roof)
                px.rect(x + 2, hz - 3, 1, 1, tint(0x3A2A1E))
            }
            px.rect(116, hz, 24, 3, tint(0x6E6A5E))
            px.rect(119, hz - 1, 18, 1, tint(0x6E6A5E))
        case "kingsbay":
            // The tall hangar of timber and canvas, and a heap of coal.
            px.rect(6, hz - 20, 26, 20, tint(0xB9A26C))
            px.rect(8, hz - 22, 22, 2, tint(0xB9A26C))
            for i in 0..<4 { px.rect(9 + Double(i) * 6, hz - 19, 1, 19, tint(0x9A845A)) }
            px.rect(28, hz - 16, 4, 16, tint(0x3A3226))
            px.polygon([(40, hz), (47, hz - 6), (54, hz)], tint(0x26262B))
        default:
            break
        }
        // The mast: two steel legs braced every four pixels, a platform and the mast head.
        let steel = tint(0x6B6F76), brace = tint(0x8C939C)
        px.rect(mastX, mastTop, 1, hz - mastTop, steel)
        px.rect(mastX + 4, mastTop, 1, hz - mastTop, steel)
        for y in stride(from: mastTop + 2, to: hz - 3, by: 4) {
            px.line(from: (mastX, y), to: (mastX + 4, y + 4), brace)
            px.rect(mastX, y, 5, 1, brace)
        }
        px.rect(mastX - 1, mastTop - 1, 7, 1, steel)
        px.rect(mastX + 1, mastTop - 3, 3, 2, steel)
        // The ground crew, on her handling lines.
        let rope = Color(hex: 0xD8C8A0).opacity(0.8)
        for (from, to) in [((mooredX + 19.0, mooredY + 12), (108.0, hz - 2)), ((mooredX + 25.0, mooredY + 12), (119.0, hz - 2))] {
            if lines { px.line(from: from, to: to, rope) }
            let sway = jsRounded(sin(t * 1.3 + to.0))
            px.rect(to.0 + sway, hz - 3, 1, 3, Color(hex: 0x2A2A30))
            px.rect(to.0 + sway, hz - 4, 1, 1, Color(hex: 0xEFD6B0))
        }
    }

    // MARK: Stops

    static func landmark(_ px: PixelCanvas, _ id: String, t: Double, _ tint: (UInt32) -> Color) {
        let hz = horizon, w = px.w
        switch id {
        case "rhone":
            // The coast behind her, and the river winding up its valley between the hills.
            px.polygon([(0, hz), (30, hz), (16, 80), (0, 80)], tint(0x1D4E7A))
            for i in 0..<4 { px.rect(2 + Double(i % 2) * 6, 61 + Double(i) * 4, 3, 1, tint(0x7FB8DE)) }
            px.hills(30..<160, base: hz, tint(0x6E7C5A)) { 6 + 3 * sin($0 * 0.07) + 2 * sin($0 * 0.19) }
            for x in stride(from: 22.0, to: w, by: 1) {
                let y = 68 + 4 * sin(x * 0.06) - (x - 22) * 0.06
                px.rect(x, y.rounded(.down), 1, 2, tint(0x7FB8DE))
            }
        case "circle":
            // The line nobody can see, drawn anyway.
            for x in stride(from: 0.0, to: w, by: 6) {
                px.rect(x, 69, 3, 1, Color(hex: 0xF2D16B).opacity(0.75))
            }
        case "bear":
            // A black wedge of cliffs to the west, streaked with snow, and its birds.
            px.polygon([(2, hz), (10, 47), (20, 43), (31, 46), (44, hz)], tint(0x2A2D33))
            for (x, y, l) in [(12.0, 48.0, 4.0), (19, 45, 5), (26, 47, 3), (33, 51, 4)] {
                px.rect(x, y, 1, l, tint(0xE8EEF3))
            }
            for i in 0..<7 {
                let a = t * 0.9 + Double(i) * 0.9
                let x = (24 + 16 * cos(a)).rounded(.down), y = (34 + 5 * sin(a * 1.3)).rounded(.down)
                px.rect(x, y, 1, 1, Color(hex: 0xECE4CF))
                px.rect(x + 1, y - 1, 1, 1, Color(hex: 0xECE4CF))
                px.rect(x - 1, y - 1, 1, 1, Color(hex: 0xECE4CF))
            }
        case "pole":
            // Flags on weighted staffs, standing in the snow below her.
            for (x, y, c) in [(62.0, 66.0, 0xD64545 as UInt32), (75, 70, 0x2E6FB0), (88, 65, 0xF2D16B)] {
                px.rect(x, y - 8, 1, 8, tint(0x4B4F55))
                let flap = jsRounded(sin(t * 4 + x))
                px.rect(x + 1, y - 8, 4, 2, tint(c))
                px.rect(x + 1, y - 6, 3 + flap, 1, tint(c))
                px.rect(x - 1, y, 3, 1, tint(0xF4F7FA))
            }
        case "barrow":
            // The village out on the shore ice, the trading post, the aviators' tent and
            // their petrol drums, and everyone waving.
            px.rect(0, 70, w, 10, tint(0xE6EDF2))
            for i in 0..<4 {
                let x = 6 + Double(i) * 10
                px.rect(x, hz - 4, 6, 5, tint(0x8A6A48))
                px.rect(x, hz - 5, 6, 1, tint(0xE6EDF2))
            }
            px.rect(48, hz - 6, 11, 7, tint(0x9A7A52))
            px.rect(48, hz - 7, 11, 1, tint(0x6B4A2B))
            px.rect(51, hz - 5, 5, 1, tint(0xF0E8D0))
            px.polygon([(98, hz + 1), (104, hz - 6), (110, hz + 1)], tint(0xD9C9A0))
            for i in 0..<5 { px.rect(114 + Double(i) * 3, hz - 1, 2, 2, tint(0x6B4A2B)) }
            for i in 0..<9 {
                let x = 20 + Double(i) * 9, wave = jsRounded(sin(t * 5 + Double(i))) < 0 ? 1.0 : 0
                px.rect(x, 63, 1, 3, Color(hex: 0x2A2A30))
                px.rect(x, 62, 1, 1, Color(hex: 0xEFD6B0))
                px.rect(x + 1, 62 - wave, 1, 1, Color(hex: 0x2A2A30))
            }
        case "wales":
            // The cape below her, and across the strait the blue hills of Asia.
            px.polygon([(0, hz), (28, hz), (48, 80), (0, 80)], tint(0x4A4A3A))
            for (x, y) in [(6.0, 62.0), (14, 66), (9, 71), (22, 74)] { px.rect(x, y, 4, 1, tint(0xE6EDF2)) }
            px.hills(104..<160, base: hz, tint(0x6E86A8)) { max(0, 5 + 3 * sin($0 * 0.11) - abs($0 - 134) * 0.06) }
        case "nome":
            // The beach, the roofs of Nome, and the whole town turned out.
            px.rect(0, 64, w, 4, tint(0xC8B98A))
            px.rect(0, 68, w, 12, tint(0x24394E))
            for i in 0..<10 {
                let x = 92 + Double(i) * 7, bh = Double(4 + (i * 7) % 5)
                let wall: UInt32 = [0xA88A62, 0xC9A27A, 0x8C6A48][i % 3]
                px.rect(x, hz - bh, 6, bh + 1, tint(wall))
                px.rect(x, hz - bh - 1, 6, 1, tint(i % 2 == 0 ? 0x6B4A2B : 0x9A3B2E))
            }
            for i in 0..<16 {
                let x = 40 + Double(i) * 6 + jsRounded(sin(t * 2 + Double(i)))
                px.rect(x, 61, 1, 3, Color(hex: 0x2A2A30))
                px.rect(x, 60, 1, 1, Color(hex: 0xEFD6B0))
            }
        default:
            break
        }
    }

    // MARK: Forced down

    /// Beside her where she came down, as the engine tells it (`Airship.wreckedBody`): a
    /// camp on the ice where there is sea ice below, a fishing boat on open sea, or a
    /// farmer and his dog in a field, Scandinavia's included.
    static func camp(_ px: PixelCanvas, _ region: Region?, t: Double, _ tint: (UInt32) -> Color) {
        let hz = horizon
        let ink = Color(hex: 0x2A2A30), face = Color(hex: 0xEFD6B0)
        if region?.has("pack") == true {
            // The floe she came down on, and the camp beside the gondola.
            px.polygon([(40, hz + 1), (146, hz + 1), (152, hz + 6), (142, hz + 10), (48, hz + 9), (36, hz + 5)], tint(0xE6EDF2))
            px.rect(48, hz + 9, 94, 1, tint(0x9FB0BF))
            px.polygon([(104, hz + 6), (111, hz - 2), (118, hz + 6)], tint(0xD9C9A0))
            px.rect(110, hz + 2, 2, 4, tint(0x6B4A2B))
            for (i, x) in [122.0, 127, 131].enumerated() {
                px.rect(x, hz + 2, 1, 3, ink)
                px.rect(x, hz + 1, 1, 1, face)
                if i == 1 && Int(t * 2) % 2 == 0 { px.rect(x + 1, hz, 1, 1, ink) }
            }
        } else if region?.has("sea") == true {
            let bob = jsRounded(sin(t * 2))
            px.rect(112, hz + 6 + bob, 16, 3, tint(0x6B4A2B))
            px.rect(114, hz + 9 + bob, 12, 1, tint(0x4A2E1A))
            px.rect(121, hz - 4 + bob, 1, 10, tint(0x4A2E1A))
            px.rect(122, hz - 3 + bob, 4, 3, tint(0xD9C9A0))
            px.rect(116, hz + 4 + bob, 1, 2, ink)
        } else {
            px.rect(112, hz + 4, 1, 4, ink)
            px.rect(112, hz + 3, 1, 1, face)
            px.rect(111, hz + 2, 3, 1, tint(0x6B4A2B))
            let wag = Int(t * 4) % 2 == 0 ? 1.0 : 0
            px.rect(116, hz + 6, 4, 2, tint(0x8A6A48))
            px.rect(119, hz + 5, 2, 1, tint(0x8A6A48))
            px.rect(115, hz + 5 - wag, 1, 1, tint(0x8A6A48))
        }
    }

    // MARK: The airship

    /// Where her top-left corner is: on the mast, coming down at Nome, or flying, lower
    /// as the gas goes and pitching with the air.
    static func position(_ f: SceneFrame, _ s: Palette) -> (x: Double, y: Double) {
        if moored(f) != nil { return (mooredX, mooredY) }
        if down(f) { return (flyingX + 8, horizon - 10) }
        if landmark(f)?.id == AirshipSkin.journey.stops.last?.id { return (flyingX + 20, 30) }
        let drop = jsRounded((100 - max(0, min(100, f.hull))) / 10)
        let bob = jsRounded(sin(f.t * (1.4 + s.rough * 0.7)) * (0.5 + s.rough * 0.5))
        return (flyingX, flyingY + drop + bob)
    }

    static func airship(_ px: PixelCanvas, _ f: SceneFrame, _ s: Palette, dry: Bool, at: (x: Double, y: Double)) {
        let t = f.t
        let running = f.moving && !dry
        let x = at.x, y = at.y
        var c = colors
        if icing(f.weather) {
            // Rime on the envelope's top and on every strut.
            c["h"] = .white
            c["k"] = Color(hex: 0xDDE6EC)
        }
        let frame = Int((t * 12).rounded(.down))
        let stutter = max(0, 60 - f.sails) / 2.2
        px.sprite(ship, x: x, y: y, c) { col, row, ch in
            guard ch == "p" else { return false }
            if dry { return true }
            if Double((col * 7 + row * 13) % 37) < stutter { return true }
            // A turning propeller shows half its blade at a time.
            return running && (row + frame) % 2 == 0
        }
        // Slack, creased fabric as the lift goes.
        if f.hull < 50 {
            let crease = Color(hex: 0xA9AFB7)
            px.sprite(ship, x: x, y: y, ["e": crease]) { col, row, _ in
                (col * 5 + row * 3) % 11 != 0 || Double(col) > 4 + (50 - f.hull) / 2
            }
        }
        if icing(f.weather) {
            // Icicles under the cars.
            for (cx, l) in [(12.0, 2.0), (14, 1), (20, 2), (23, 1), (26, 2)] {
                px.rect(x + cx, y + 13, 1, l, Color(hex: 0xEEF4F8))
            }
        }
        if f.sails < 40 && running {
            // A failing engine: grey puffs going back from the engine car, fading as they go.
            let grey = Color(hex: 0x8F8A7A)
            for k in 0..<2 {
                let p = wrap(t / 0.3 + Double(k) * 3.5, 7).rounded(.down)
                px.rect(x + 8 - p, y + 11 - Double(k), 2, 1, grey.opacity(max(0.15, 1 - p / 6)))
            }
        }
    }

    /// What shows in the dark: stars, a moon in a clear sky, the lit windows of the
    /// control car and the riding lights.
    static func lights(_ px: PixelCanvas, at: (x: Double, y: Double), clear: Bool) {
        if clear {
            for i in 0..<16 {
                px.rect(Double((i * 37 + 11) % 160), Double((i * 23 + 5) % 50), 1, 1, Color.white.opacity(i % 3 == 0 ? 0.9 : 0.55))
            }
            px.moon(x: 128, y: 6, Color(hex: 0xF2EED8), sky: Color(hex: 0x141B33))
        }
        let x = at.x, y = at.y
        px.sprite(ship, x: x, y: y, ["w": Color(hex: 0xFFE27A)])
        px.rect(x + 31, y + 5, 1, 1, .white)
        px.rect(x, y + 5, 1, 1, Color(hex: 0xFF5A4A))
    }

    // MARK: VoiceOver

    /// Where she is, as a sentence says it after a verb: "over the North Sea", "above the
    /// fog". The engine's names are headings ("Mediterranean", "Under the Fog").
    static let whereabouts: [String: String] = [
        "med": "over the Mediterranean", "france": "over France", "northSea": "over the North Sea",
        "scandinavia": "over Scandinavia", "barents": "over the Barents Sea", "polarSea": "over the Polar Sea",
        "aboveFog": "above the fog", "underFog": "under the fog", "alaska": "over the Alaskan coast",
    ]

    static func whereabouts(_ region: Region?) -> String {
        guard let region else { return "over open country" }
        return whereabouts[region.id.rawValue] ?? "over \(region.name)"
    }

    static func label(_ f: SceneFrame) -> String {
        guard let g = f.state else { return "An airship flying north in clear weather" }
        if let id = moored(f) {
            return "Airship moored at the mast at \(AirshipSkin.journey.port(id)?.name ?? g.currentStop.short)"
        }
        if down(f) {
            let r = f.region
            return r?.has("pack") == true ? "The airship down on the ice, her crew camped beside the gondola"
                : r?.has("sea") == true ? "The airship down on the sea, a fishing boat coming alongside"
                : "The airship down in a field, a farmer and his dog looking her over"
        }
        let weather = f.weather.name.lowercased()
        if let id = passing(f) {
            let name = AirshipSkin.journey.port(id)?.name ?? g.currentStop.short
            if drifting(f) { return "Airship drifting past the mast at \(name), engines stopped. Weather: \(weather)" }
            return f.moving ? "Airship flying past the mast at \(name). Weather: \(weather)"
                            : "Airship over the mast at \(name), the ground crew waiting below. Weather: \(weather)"
        }
        if let stop = landmark(f) {
            switch stop.id {
            case "rhone": return "Airship over the mouth of the Rhône, the coast behind her. Weather: \(weather)"
            case "circle": return "Airship crossing the Arctic Circle above the forests. Weather: \(weather)"
            case "bear": return "Airship passing Bear Island, its cliffs to the west. Weather: \(weather)"
            case "pole": return "Airship over the North Pole, flags standing in the snow below. Weather: \(weather)"
            case "barrow": return "Airship low over Point Barrow, the village out on the ice. Weather: \(weather)"
            case "wales": return "Airship over Cape Prince of Wales, the hills of Asia across the strait. Weather: \(weather)"
            case "nome": return "Airship coming down over the roofs of Nome, the town on the beach"
            default: return "Airship over \(stop.name). Weather: \(weather)"
            }
        }
        let over = whereabouts(f.region)
        if drifting(f) { return "Airship drifting \(over), engines stopped. Weather: \(weather)" }
        let time = isNight(f.hour) ? (midnightSun(f) ? " in the midnight sun" : " by night") : ""
        return f.moving ? "Airship flying \(over)\(time). Weather: \(weather)"
                        : "Airship \(over)\(time), engines stopped. Weather: \(weather)"
    }
}
