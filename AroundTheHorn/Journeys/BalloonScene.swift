import SwiftUI
import HornEngine

/// The Jet Stream's scene: a Rozière balloon, a helium cell over a cone of hot air with
/// a sealed capsule slung below, flying east (to the right) over sixteen kinds of country
/// and sea under ten weathers. Three states, as 1849 has sailing, hove to and at anchor:
/// aloft (a watch being flown), loitering low (the menus, a rest, a question) and standing
/// on a field. Each of the six fields is drawn with its hangar, fuel truck and crowd, and
/// every other stop as itself. The burners blast while she flies and blip while she
/// loiters; worn, they sputter orange and soot the cone; with no heat, dry tanks or dead
/// burners, there is no flame at all; her crown sags as the lift goes. Nights fall by the
/// local sun, worked out from where she is along the chart's route, not by the GMT the
/// log keeps.
enum BalloonScene {
    static let aloftHorizon = 46.0
    static let lowHorizon = 40.0

    // MARK: Sky

    struct Palette {
        let top: UInt32, bot: UInt32
        var sun: UInt32?
        var bigSun = false
        var clouds = 0
        var cloud: UInt32 = 0xF4F7FA
        /// Aloft, a cloud deck hides the ground.
        var deck: UInt32?
        /// 0 in smooth air; 2 and more sways her.
        var rough = 0.0
        var cirrus = false
        var still = false
        var shimmer = false
        var dust = false
    }

    /// By the kind of sky. A light wind and a steady one share a clear sky: the light wind
    /// is the one that barely moves her (`speed` under 0.8), and its sky is paler.
    static func palette(_ w: Weather) -> Palette {
        switch w.sky {
        case .clear:
            return w.speed < 0.8 ? Palette(top: 0x3A6AA2, bot: 0xB6DCF0, sun: 0xFFE27A, clouds: 1)
                                 : Palette(top: 0x2D5F9A, bot: 0x9FD0EE, sun: 0xFFE27A, clouds: 1)
        case .breeze:
            return Palette(top: 0x1E4F8F, bot: 0x8CC8EA, sun: 0xFFE27A, cirrus: true)
        case .still:
            return Palette(top: 0xD9893F, bot: 0xF6D78B, sun: 0xFFF1B0, still: true)
        case .heat:
            return Palette(top: 0x3F7FC0, bot: 0xE8F2F8, sun: 0xFFFBE0, bigSun: true, shimmer: true)
        case .fog:
            return Palette(top: 0x8D969E, bot: 0xC5CBD0, deck: 0xC5CBD0)
        case .snow:
            return Palette(top: 0x55606E, bot: 0xA6B2BF, clouds: 3, cloud: 0x8C97A3, deck: 0x8C97A3)
        case .gale:
            return Palette(top: 0x33404F, bot: 0x6E7D8D, clouds: 3, cloud: 0x55616F, rough: 2)
        case .storm:
            return Palette(top: 0x15191F, bot: 0x3A434F, clouds: 3, cloud: 0x2C333D, deck: 0x2C333D, rough: 3)
        case .dust:
            return Palette(top: 0xB98A55, bot: 0xE3C38E, sun: 0xFFE9B0, dust: true)
        case .rain:
            return Palette(top: 0x3E4A5A, bot: 0x7D8A98, clouds: 3, cloud: 0x6B7685, rough: 1)
        }
    }

    // MARK: The balloon

    /// 18 × 20: the helium cell with its gold and red bands, the hot-air cone, the load
    /// cables, the burner and its flame, and the capsule with its portholes and the
    /// propane cylinders along its sides.
    static let balloon = [
        "       eeess      ",
        "     eeeeeesss    ",
        "    eeeeeeeesss   ",
        "   eeeeeeeeeesss  ",
        "  eeeeeeeeeeeesss ",
        "  eeeeeeeeeeeesss ",
        " gggggggggggggggg ",
        " rrrrrrrrrrrrrrrr ",
        " eeeeeeeeeeeeesss ",
        "  eeeeeeeeeeeess  ",
        "   eeeeeeeeeess   ",
        "    kkkkkkkkkk    ",
        "     kkkkkkkk     ",
        "      kkkkkk      ",
        "      l oo l      ",
        "     l  ff  l     ",
        "    l  bbbb  l    ",
        "   tccccccccccct  ",
        "   tcwwcwwcwwcct  ",
        "    cccccccccc    ",
    ].map(Array.init)

    static let colors: [Character: Color] = [
        "e": Color(hex: 0xE6E9EE), "s": Color(hex: 0xB9C0CA), "g": Color(hex: 0xD9A441), "r": Color(hex: 0xD64545),
        "k": Color(hex: 0xEFE6CC), "l": Color(hex: 0x5A6270), "o": Color(hex: 0xFF8A3D), "f": Color(hex: 0xF2B632),
        "b": Color(hex: 0x3A3F48), "c": Color(hex: 0xECE4CF), "w": Color(hex: 0x1A2533), "t": Color(hex: 0x8A949E),
    ]

    static let x0 = 50.0
    static let aloftY = 8.0, loiterY = 18.0, groundY = 33.0

    // MARK: Where she is

    /// Standing on a field with its ground team: on the ground at a stop that has one.
    static func field(_ f: SceneFrame) -> String? {
        guard f.atPort, let g = f.state, BalloonSkin.journey.port(g.currentStop.id) != nil else { return nil }
        return g.currentStop.id
    }

    /// Down for good: the attempt is over and the lift is gone (never at the finish line,
    /// where she lands as she means to).
    static func down(_ f: SceneFrame) -> Bool {
        guard let g = f.state, g.over, g.currentStop.type != .end else { return false }
        return jsRounded(g.hull) <= 0
    }

    /// The field she is over and has not landed at: its arrival's question on screen, or
    /// flying on past, or grounded there for good. (Marrakech's is behind her as soon as
    /// she climbs away.)
    static func overField(_ f: SceneFrame) -> String? {
        guard let g = f.state, field(f) == nil, g.stopIndex > 0 else { return nil }
        let stop = g.currentStop
        return g.mile == stop.mile && BalloonSkin.journey.port(stop.id) != nil ? stop.id : nil
    }

    /// The stop she is at, its arrival told, when it isn't a field: the High Atlas, the
    /// Himalaya, the edge of the Pacific, the date line, the landfall, the Azores, and the
    /// finish line, where she has come down.
    static func landmark(_ f: SceneFrame) -> Stop? {
        guard let g = f.state, field(f) == nil, g.stopIndex > 0 else { return nil }
        let stop = g.currentStop
        guard stop.type != .port, g.mile == stop.mile else { return nil }
        if down(f) { return nil }
        return stop
    }

    /// Climbing away from Marrakech: the launch said, no watch flown yet.
    static func launching(_ f: SceneFrame) -> Bool {
        guard let g = f.state, !f.moving, !g.atPort, !g.over else { return false }
        return g.stopIndex == 0 && g.mile == 0 && g.day == 0
    }

    /// No heat for the cone, once the flight is under way: the tanks dry or the burners
    /// given out. A flight not yet launched has bought nothing.
    static func cold(_ f: SceneFrame) -> Bool {
        guard let g = f.state, g.day > 0, field(f) == nil, !down(f) else { return false }
        return g.fuel <= 0 || Balloon.burnersOut(g)
    }

    /// Whether she is low, loitering: aloft, not flying a watch.
    static func loitering(_ f: SceneFrame) -> Bool {
        guard f.state != nil, field(f) == nil, !down(f), !launching(f), landmark(f)?.type != .end else { return false }
        return !f.moving
    }

    /// The longitude under her, read along the chart's route, east of Greenwich.
    static func longitude(_ g: GameState) -> Double {
        let track = BalloonChart.onSouthTrack(g) ? BalloonChart.south : BalloonChart.north
        let m = Double(g.mile)
        for (a, b) in zip(track, track.dropFirst()) where m <= b.2 {
            return m <= a.2 || b.2 == a.2 ? a.0 : a.0 + (b.0 - a.0) * (m - a.2) / (b.2 - a.2)
        }
        return track.last?.0 ?? 0
    }

    /// The hour by the sun where she is: the log's GMT and four minutes for every degree
    /// of longitude.
    static func localHour(_ f: SceneFrame) -> Double {
        guard let g = f.state else { return Double(f.hour) }
        let h = Double(f.hour) + longitude(g) / 15
        let m = h.truncatingRemainder(dividingBy: 24)
        return m < 0 ? m + 24 : m
    }

    /// A winter night between about half past six in the evening and half past six in the
    /// morning, local time. The title card is always by day.
    static func isNight(_ f: SceneFrame) -> Bool {
        guard f.state != nil, landmark(f)?.type != .end else { return false }
        let h = localHour(f)
        return h >= 18.5 || h < 6.5
    }

    // MARK: Drawing

    static func wrap(_ x: Double, _ period: Double) -> Double {
        let m = x.truncatingRemainder(dividingBy: period)
        return m < 0 ? m + period : m
    }

    static func draw(_ px: PixelCanvas, _ f: SceneFrame) {
        let onField = field(f)
        let over = overField(f)
        let launch = launching(f)
        let isDown = down(f)
        let stop = landmark(f)
        let finish = stop?.type == .end
        // The finish is the next sunrise; everywhere else the sky is the weather's.
        let s = finish ? sunrise : palette(f.weather)
        let low = loitering(f) && over == nil
        let hz = low ? lowHorizon : aloftHorizon
        let t = f.t
        let night = isNight(f)
        let region = groundRegion(f)
        let still = s.still || isDown || finish || onField != nil
        let heat = !cold(f)
        // How fast the ground slides by, row by row.
        let v: (Int) -> Double = { r in
            if still || launch { return 0 }
            if f.moving { return 4 * f.weather.speed * (heat ? 1 : 0.3) + 1 }
            return 0.5 + 0.25 * Double(r)
        }

        px.sky(top: s.top, bottom: s.bot, horizon: hz)
        if let sun = s.sun, !night { self.sun(px, Color(hex: sun), big: s.bigSun) }
        let drift = f.moving && !still ? 1.6 : 0.4
        if s.clouds > 0 { px.clouds(s.clouds * 2, Color(hex: s.cloud), t: t, drift: drift) }
        if s.cirrus { cirrus(px, t: t, drift: drift) }

        let fieldID = onField ?? over ?? (launch ? BalloonSkin.journey.stops.first?.id : nil)
        let deck = f.moving && fieldID == nil && !isDown && stop == nil ? s.deck : nil
        if let id = fieldID {
            fieldGround(px, id, hz: aloftHorizon)
        } else if finish {
            homeGround(px, t: t)
        } else if let deck {
            px.rect(0, hz, px.w, px.h - hz, Color(hex: deck))
            dashes(px, hz: hz, rows: 8, color: s.bot, v: v, t: t, shimmer: false)
        } else {
            if region == "himalaya" { range(px, hz: hz, scroll: t * v(0) / 4) }
            far(px, region, hz: hz, scroll: t * v(0) / 6)
            var (fill, dash) = ground(region, month: f.state?.month ?? 0)
            if s.dust {
                fill = mixed(fill, 0xC9A36B)
                dash = mixed(dash, 0xC9A36B)
            }
            px.rect(0, hz, px.w, px.h - hz, Color(hex: fill))
            dashes(px, hz: hz, rows: low ? 9 : 8, color: dash, v: v, t: t, shimmer: s.shimmer)
            if let stop { landmark(px, stop.id, f, hz: hz, t: t) }
        }
        if let id = fieldID { props(px, id, t: t, flown: onField == nil) }
        if isDown, let g = f.state {
            wreck(px, f, g, t: t)
        } else {
            sprite(px, f, at: position(f, s, hz: hz), night: false)
        }

        // The weather's own layers, in 1849's order. The finish is a fair morning.
        if !finish {
            if f.weather.sky == .storm { px.rain(t: t) }
            if f.weather.sky == .snow { px.snow(t: t) }
            if s.dust { dust(px, t: t, moving: f.moving) }
            if f.weather.sky == .fog { px.fog() }
            if f.weather.sky == .storm { px.lightning(t: t) }
        }

        if night {
            px.rect(0, 0, px.w, px.h, Color(hex: 0x070B1C).opacity(0.6))
            if s.sun != nil { stars(px, hz: hz) }
            if !isDown {
                // The burner's light on the cone and the capsule's lit portholes.
                sprite(px, f, at: position(f, s, hz: hz), night: true)
            }
            if let id = fieldID { hangarLight(px, id) }
        }
    }

    /// The sky she comes down in at the finish: the next sunrise, gold low in the east.
    static let sunrise = Palette(top: 0x2D5F9A, bot: 0xF6C98B, clouds: 1, cloud: 0xF6E3C0)

    /// The country under her: the region's, except at the landfall, where the coast is
    /// drawn over the ocean she is leaving.
    static func groundRegion(_ f: SceneFrame) -> String {
        guard let g = f.state else { return "sahara" }
        if let stop = landmark(f), stop.id == "landfall" {
            return BalloonSkin.journey.region(g, at: stop.mile - 1).id.rawValue
        }
        return f.region?.id.rawValue ?? "sahara"
    }

    /// 1849's sun, high on the right; in a hot sun one pixel bigger all round.
    static func sun(_ px: PixelCanvas, _ c: Color, big: Bool) {
        if big {
            px.rect(126, 7, 9, 13, c)
            px.rect(124, 9, 13, 9, c)
            px.rect(125, 8, 11, 11, c)
        } else {
            px.sun(x: 125, y: 8, c)
        }
    }

    /// The jet's cirrus: three long streaks, three times as fast as the clouds would go.
    static func cirrus(_ px: PixelCanvas, t: Double, drift: Double) {
        for i in 0..<3 {
            let di = Double(i)
            let x = (wrap(di * 67 + 10 - t * 3 * (2 + di) * drift, 200) - 20).rounded(.down)
            px.rect(x, 6 + 7 * di, 20, 1, Color(hex: 0xF4F7FA).opacity(0.6))
        }
    }

    static func stars(_ px: PixelCanvas, hz: Double) {
        for i in 0..<18 {
            px.rect(Double((i * 37 + 11) % 160), Double((i * 23 + 5) % Int(hz - 4)), 1, 1,
                    Color.white.opacity(i % 3 == 0 ? 0.9 : 0.55))
        }
        px.moon(x: 124, y: 6, Color(hex: 0xF2EED8), sky: Color(hex: 0x141B33))
    }

    static func mixed(_ a: UInt32, _ b: UInt32) -> UInt32 {
        func ch(_ s: UInt32) -> UInt32 { UInt32(jsRounded((Double((a >> s) & 255) + Double((b >> s) & 255)) / 2)) }
        return ch(16) << 16 | ch(8) << 8 | ch(0)
    }

    // MARK: Country

    /// The region's ground and the colour of its texture. The Great Plains lie under snow
    /// from December to February.
    static func ground(_ id: String, month: Int) -> (UInt32, UInt32) {
        switch id {
        case "sahara": return (0xC99A5B, 0xE0B877)
        case "arabia": return (0xD2A86A, 0xEBC98F)
        case "oman": return (0x1D4E7A, 0x7FB8DE)
        case "thar": return (0xBF915E, 0xDDB585)
        case "india": return (0x7A8B4E, 0xA3A86B)
        case "himalaya": return (0x5E6B5A, 0x8C9A86)
        case "eastchina": return (0x22557F, 0x8CC0E0)
        case "npacific": return (0x1F3346, 0xE8EEF3)
        case "nepacific": return (0x24394E, 0x8AA0B4)
        case "southtrack": return (0x1A5A8A, 0x9FD4EE)
        case "subtropic": return (0x1B6A94, 0xA8E0F2)
        case "southwest": return (0xB5754A, 0xD9A06F)
        case "plains": return month == 11 || month <= 1 ? (0xDDE4EA, 0xB8C3CC) : (0x9C9A6A, 0xC2BE8E)
        case "atlantic": return (0x1D4E7A, 0xE9F4FB)
        case "azores": return (0x1A4A78, 0x7FB8DE)
        case "morocco": return (0xC49A62, 0xE2BD86)
        default: return (0xC99A5B, 0xE0B877)
        }
    }

    /// Texture under her, one pixel tall: aloft every row at the same pace, there being no
    /// parallax from that height; loitering, the nearer rows faster.
    static func dashes(_ px: PixelCanvas, hz: Double, rows: Int, color: UInt32, v: (Int) -> Double, t: Double,
                       shimmer: Bool)
    {
        let c = Color(hex: color)
        let flick = Int((t / 0.5).rounded(.down)) % 2 == 0
        for r in 0..<rows {
            let y = hz + 2 + 4 * Double(r)
            guard y < px.h else { break }
            let nudge = shimmer && r % 2 == 1 && flick ? 1.0 : 0
            for i in 0..<7 {
                let x = wrap(Double(i * 29 + r * 17) - t * v(r), px.w).rounded(.down) + nudge
                px.rect(x, y, Double(2 + (i + r) % 3), 1, c)
            }
        }
    }

    /// The Himalaya's band of peaks on the horizon, snow-capped, wrapping round.
    static let peakTable: [(c: Double, w: Double, h: Double)] = [
        (8, 6, 5), (26, 8, 8), (41, 5, 4), (59, 9, 9), (77, 6, 6), (92, 7, 7), (110, 8, 9), (128, 5, 3), (146, 7, 6),
    ]

    /// A band of peaks standing on the horizon, a third of each snow, wrapping round as
    /// she flies: the Himalaya's by default, or another range's table and colours.
    static func range(_ px: PixelCanvas, hz: Double, scroll: Double, big: Double = 1,
                      table: [(c: Double, w: Double, h: Double)] = peakTable, rock: UInt32 = 0x6E7480,
                      snow: UInt32 = 0xEEF3F7, wraps: Bool = true)
    {
        let shift = wrap(scroll, 160)
        for p in table {
            let h = (p.h * big).rounded(), w = (p.w * big).rounded()
            for copy in wraps ? [0.0, 160] : [0.0] {
                let c = p.c - shift + copy
                for j in 0..<Int(h) {
                    let half = (w * Double(j + 1) / h).rounded(.down)
                    let white = Double(j) < (h / 3).rounded(.up)
                    px.rect(c - half, hz - h + Double(j), 2 * half + 1, 1, Color(hex: white ? snow : rock))
                }
            }
        }
    }

    /// The High Atlas, south of Marrakech: lower than the Himalaya, and browner.
    static let atlasTable: [(c: Double, w: Double, h: Double)] = [
        (6, 9, 6), (22, 10, 9), (38, 7, 5), (55, 11, 8), (74, 8, 6), (90, 12, 10), (110, 8, 5), (126, 10, 8), (146, 9, 6),
    ]

    /// What stands on the far horizon of some of the country: dunes, the Atlas, mesas.
    static func far(_ px: PixelCanvas, _ id: String, hz: Double, scroll: Double) {
        switch id {
        case "sahara":
            px.hills(0..<160, base: hz, Color(hex: 0xB4884E)) { x in
                let u = x + scroll
                return max(0, 2 + 1.5 * sin(u * 0.09) + sin(u * 0.23))
            }
        case "southwest":
            // Mesas, flat-topped, the colour of rust.
            for (x, w, h) in [(14.0, 18.0, 5.0), (70, 26, 7), (122, 14, 4)] {
                let left = wrap(x - scroll, 180) - 10
                px.rect(left.rounded(.down), hz - h, w, h, Color(hex: 0x8E5634))
                px.rect((left + 2).rounded(.down), hz - h - 1, w - 4, 1, Color(hex: 0x8E5634))
            }
        case "morocco", "thar":
            if id == "morocco" {
                // The Atlas, white along the top, far off to the south.
                range(px, hz: hz, scroll: scroll, big: 0.7, table: atlasTable, rock: 0x8A7A68)
            } else {
                // Scrub, in tufts.
                for i in 0..<9 {
                    let x = wrap(Double(i * 19) - scroll, 160).rounded(.down)
                    px.rect(x, hz - 1, 2, 1, Color(hex: 0x8C8A55))
                }
            }
        case "india":
            // Fields in patches beyond the haze.
            for i in 0..<6 {
                let x = wrap(Double(i * 31) - scroll, 170).rounded(.down) - 5
                px.rect(x, hz - 1, 12, 1, Color(hex: 0x5E7040))
            }
        default:
            break
        }
    }

    // MARK: Stops

    static func landmark(_ px: PixelCanvas, _ id: String, _ f: SceneFrame, hz: Double, t: Double) {
        let w = px.w
        switch id {
        case "atlas":
            // Snowfields close below and the white range across the horizon, mule tracks
            // running along the slopes.
            range(px, hz: hz, scroll: 0, big: 1.4, table: atlasTable, rock: 0x8A7A68)
            px.rect(0, hz, w, 14, Color(hex: 0xE6EDF2))
            for i in 0..<14 {
                let x = Double(i * 11 + (i % 3) * 3)
                px.rect(x, hz + 5 + Double(i % 3) * 3, 3, 1, Color(hex: 0x8A7A68))
            }
        case "him":
            // The whole range, a white wall standing up out of the haze, and Everest with
            // snow streaming east off its summit.
            range(px, hz: hz, scroll: 0, big: 1.8)
            let ex = 96.0
            for j in 0..<20 {
                let half = (Double(j + 1) * 10 / 20).rounded(.down)
                px.rect(ex - half, hz - 20 + Double(j), 2 * half + 1, 1, Color(hex: j < 7 ? 0xF4F7FA : 0x6E7480))
            }
            for k in 0..<4 {
                let p = wrap(t * 6 + Double(k) * 5, 20).rounded(.down)
                px.rect(ex + 1 + p, hz - 21 + Double(k % 2), 3, 1, Color.white.opacity(max(0.2, 0.8 - p / 25)))
            }
        case "pacific":
            // The coast of Japan falling behind on the left, a white cone among its hills;
            // ahead, nothing but sea.
            px.polygon([(0, hz), (0, hz - 7), (12, hz - 9), (26, hz - 4), (40, hz), (34, hz + 6), (0, hz + 10)],
                       Color(hex: 0x4F6B3A))
            px.polygon([(8, hz - 8), (16, hz - 18), (24, hz - 7)], Color(hex: 0x6E7480))
            px.polygon([(13, hz - 14), (16, hz - 18), (19, hz - 14)], Color(hex: 0xF4F7FA))
            px.rect(0, hz + 10, 30, 1, Color(hex: 0xE8EEF3))
        case "dateline":
            // The line nobody can see, drawn anyway, running north across the sea.
            for k in 0..<9 {
                let y = hz + 1 + Double(k) * 4
                guard y < px.h else { break }
                let x = 104 + Double(k) * 1.5
                px.rect(x.rounded(.down), y, 1, 2, Color(hex: 0xF2D16B).opacity(0.85))
            }
            px.rect(103, hz - 1, 3, 1, Color(hex: 0xF2D16B).opacity(0.6))
        case "landfall":
            let south = f.state.map(BalloonChart.onSouthTrack) ?? false
            // The coast ahead: a white line of surf, then the dark of the redwoods, or
            // San Diego's brown hills and the desert.
            let land: UInt32 = south ? 0x9A7A52 : 0x2E4A2E
            px.polygon([(96, hz), (w, hz), (w, px.h), (70, px.h)], Color(hex: land))
            px.line(from: (96, hz), to: (70, px.h), Color(hex: 0xF4F7FA))
            px.line(from: (98, hz), to: (73, px.h), Color(hex: 0xF4F7FA).opacity(0.6))
            if south {
                px.hills(100..<160, base: hz, Color(hex: 0x8A6A48)) { max(0, 4 + 3 * sin($0 * 0.13)) }
                for (x, y) in [(110.0, 58.0), (128, 64), (146, 55), (136, 72)] { px.rect(x, y, 3, 1, Color(hex: 0xC9A36B)) }
            } else {
                for i in 0..<12 {
                    let x = 100 + Double(i) * 5, top = hz - 3 - Double((i * 7) % 4)
                    px.rect(x, top, 2, hz - top + 1, Color(hex: 0x1E3A24))
                    px.rect(x - 1, top + 2, 4, 2, Color(hex: 0x1E3A24))
                }
            }
        case "azores":
            // A green volcanic island on the horizon, its white town at the shore, a
            // smaller one beyond, and the fishing boat waiting out from Ponta Delgada.
            px.polygon([(86, hz), (100, hz - 9), (108, hz - 11), (118, hz - 6), (132, hz)], Color(hex: 0x4F7A3A))
            px.polygon([(140, hz), (147, hz - 4), (156, hz)], Color(hex: 0x5E8A48))
            for x in [94.0, 98, 102, 121, 125] { px.rect(x, hz - 2, 2, 2, Color(hex: 0xF4F1E6)) }
            let bob = jsRounded(sin(t * 2))
            px.rect(70, 66 + bob, 14, 3, Color(hex: 0x2E6FB0))
            px.rect(72, 69 + bob, 10, 1, Color(hex: 0x1A2533))
            px.rect(78, 62 + bob, 3, 4, Color(hex: 0xECE4CF))
            px.rect(75, 59 + bob, 1, 7, Color(hex: 0x4A2E1A))
        default:
            break
        }
    }

    // MARK: Fields

    /// A field seen from the ground: its own fill, and what each place has beyond it.
    static func fieldGround(_ px: PixelCanvas, _ id: String, hz: Double) {
        let fill: UInt32
        switch id {
        case "mar": fill = 0xC99A5B
        case "lux": fill = 0xC9A36B
        case "jod": fill = 0xB5754A
        case "saga": fill = 0x7C8F5A
        case "abq": fill = 0xA88A5E
        case "kh": fill = 0xD9C79A
        default: fill = 0xC99A5B
        }
        // Beyond the field, on the left.
        switch id {
        case "mar":
            // The Atlas, white to the south.
            range(px, hz: hz, scroll: 0, table: [(8, 8, 6), (22, 10, 9), (37, 8, 6)], rock: 0x8A7A68, wraps: false)
        case "lux":
            // Temple columns across the river.
            px.rect(6, hz - 3, 34, 3, Color(hex: 0xC9A36B))
            for i in 0..<6 { px.rect(9 + Double(i) * 5, hz - 9, 2, 6, Color(hex: 0xD9C79A)) }
            px.rect(7, hz - 10, 32, 1, Color(hex: 0xD9C79A))
        case "jod":
            // The great fort on its rock above the city.
            px.polygon([(0, hz), (8, hz - 6), (36, hz - 7), (46, hz)], Color(hex: 0x8E5634))
            px.rect(10, hz - 13, 24, 6, Color(hex: 0xB5754A))
            for i in 0..<5 { px.rect(11 + Double(i) * 5, hz - 15, 3, 2, Color(hex: 0xB5754A)) }
            for i in 0..<6 { px.rect(4 + Double(i) * 7, hz - 2, 4, 2, Color(hex: 0x6FA3D0)) }
        case "saga":
            // Green hills behind the river.
            px.hills(0..<48, base: hz, Color(hex: 0x4F6B3A)) { max(0, 6 + 3 * sin($0 * 0.12) + 1.5 * sin($0 * 0.31)) }
        case "abq":
            // The long mountain east of town.
            px.hills(0..<48, base: hz, Color(hex: 0x7A6A7A)) { max(0, 10 - abs($0 - 20) * 0.35 + sin($0 * 0.4)) }
        case "kh":
            // The memorial's pylon on its dune.
            px.polygon([(2, hz), (18, hz - 6), (34, hz)], Color(hex: 0xC9B98A))
            px.rect(16, hz - 14, 4, 8, Color(hex: 0xD5D7D9))
            px.rect(17, hz - 15, 2, 1, Color(hex: 0xD5D7D9))
        default:
            break
        }
        px.rect(0, hz, px.w, px.h - hz, Color(hex: fill))
        switch id {
        case "lux": px.rect(0, 56, px.w, 3, Color(hex: 0x2F6A96))
        case "saga": px.rect(0, 60, px.w, 2, Color(hex: 0x2F6A96))
        case "kh": px.rect(0, 46, px.w, 3, Color(hex: 0x1D4E7A))
        default: break
        }
    }

    /// The hangar, the windsock streaming east, the fuel truck and the crowd. Flown over
    /// (`flown`), the crowd looks up and waves.
    static func props(_ px: PixelCanvas, _ id: String, t: Double, flown: Bool) {
        px.rect(112, 36, 34, 10, Color(hex: 0x8A949E))
        px.rect(114, 34, 30, 1, Color(hex: 0x6E7480))
        px.rect(112, 35, 34, 1, Color(hex: 0x6E7480))
        px.rect(121, 38, 16, 8, Color(hex: 0x3A3F48))
        px.rect(128, 38, 1, 8, Color(hex: 0x5A6270))
        px.rect(104, 30, 1, 16, Color(hex: 0xECE4CF))
        let flutter = Int((t * 4).rounded(.down)) % 2 == 0 ? 1.0 : 0
        for (i, x) in [105.0, 106, 107, 108, 109].enumerated() {
            px.rect(x, 30 + (i == 4 ? flutter : 0), 1, 2, Color(hex: i % 2 == 0 ? 0xF2B632 : 0xD64545))
        }
        px.rect(20, 48, 10, 4, Color(hex: 0xECE4CF))
        px.rect(30, 49, 4, 3, Color(hex: 0xD64545))
        px.rect(32, 49, 2, 1, Color(hex: 0x9FD0EE))
        px.rect(20, 52, 14, 1, Color(hex: 0x3A3F48))
        for x in [21.0, 26, 31] { px.rect(x, 53, 2, 1, Color(hex: 0x1A2533)) }
        let crowd: [UInt32] = [0x2C333D, 0xD64545, 0xF2B632]
        for i in 0..<12 {
            let x = 70 + (30 * Double(i) / 11).rounded(.down)
            let wave = flown && Int((t * 3).rounded(.down) + Double(i)) % 3 == 0 ? 1.0 : 0
            px.rect(x, 50 - wave, 1, 2 + wave, Color(hex: crowd[i % 3]))
            px.rect(x, 49 - wave, 1, 1, Color(hex: 0xEFD6B0))
        }
    }

    static func hangarLight(_ px: PixelCanvas, _ id: String) {
        px.rect(122, 39, 14, 7, Color(hex: 0xFFE27A).opacity(0.7))
        px.rect(33, 50, 1, 1, Color(hex: 0xFFE27A))
    }

    /// The finish: a stony plain outside Marrakech, a white village, and its children
    /// running out to see what has fallen out of the sky.
    static func homeGround(_ px: PixelCanvas, t: Double) {
        let hz = aloftHorizon
        px.sun(x: 136, y: hz - 7, Color(hex: 0xFFD27A))
        px.hills(0..<160, base: hz, Color(hex: 0x8A7A68)) { max(0, 6 + 3 * sin($0 * 0.05) + 1.5 * sin($0 * 0.17)) }
        px.rect(0, hz, px.w, px.h - hz, Color(hex: 0xC49A62))
        for i in 0..<22 {
            px.rect(Double((i * 37 + 5) % 160), hz + 3 + Double((i * 13) % 30), 2, 1, Color(hex: 0x9A7A52))
        }
        for i in 0..<5 {
            let x = 112 + Double(i) * 9, h = Double(4 + (i * 3) % 3)
            px.rect(x, hz - h + 2, 7, h, Color(hex: 0xF4F1E6))
            px.rect(x + 2, hz - h + 4, 2, 2, Color(hex: 0x6B4A2B))
        }
        for i in 0..<6 {
            let run = wrap(t * 6 + Double(i) * 7, 30)
            let x = (108 - run - Double(i) * 2).rounded(.down)
            let hop = Int((t * 6).rounded(.down) + Double(i)) % 2 == 0 ? 1.0 : 0
            px.rect(x, 52 - hop, 1, 2, Color(hex: [0xD64545, 0x2E6FB0, 0xF2B632][i % 3]))
            px.rect(x, 51 - hop, 1, 1, Color(hex: 0x9A6A48))
        }
    }

    // MARK: The balloon

    /// Her top-left corner: aloft or loitering, bobbing with the air and swaying when it is
    /// rough, three pixels lower with the crown sagging below 40% lift; standing on a field
    /// or at the finish, still.
    static func position(_ f: SceneFrame, _ s: Palette, hz: Double) -> (x: Double, y: Double) {
        if field(f) != nil || landmark(f)?.type == .end { return (x0, groundY) }
        if launching(f) { return (x0, 20) }
        let base = loitering(f) ? loiterY : aloftY
        let sag = f.hull < 40 ? 3.0 : 0
        guard !s.still else { return (x0, base + sag) }
        let bob = jsRounded(sin(f.t * (1.0 + s.rough * 0.5)) * (0.5 + s.rough * 0.5))
        let sway = s.rough >= 2 ? jsRounded(sin(f.t * 1.3)) : 0
        return (x0 + sway, base + bob + sag)
    }

    /// The flame shows while the burners blast, 0.6 s in every 1.5 flying, less as they
    /// wear; loitering they blip, 0.4 s in every 3; on the ground, and with no heat,
    /// never.
    static func flame(_ f: SceneFrame) -> Bool {
        guard field(f) == nil, landmark(f)?.type != .end, !cold(f) else { return false }
        if f.moving || launching(f) {
            let window = f.sails < 60 ? 0.6 * max(0, f.sails) / 60 : 0.6
            return wrap(f.t, 1.5) < window
        }
        return wrap(f.t, 3) < 0.4
    }

    /// The sprite, or at night only what shows in the dark: the flame and the cone it
    /// lights, and the lit portholes.
    static func sprite(_ px: PixelCanvas, _ f: SceneFrame, at: (x: Double, y: Double), night: Bool) {
        let lit = flame(f)
        let sag = f.hull < 40
        var c = colors
        if f.sails < 60 { c["f"] = Color(hex: 0xFF8A3D) }
        if night {
            c = ["w": Color(hex: 0xFFE27A)]
            if lit {
                c["o"] = colors["o"]
                c["f"] = f.sails < 60 ? Color(hex: 0xFF8A3D) : colors["f"]
                c["k"] = Color(hex: 0xF7C98A).opacity(0.85)
            }
        }
        px.sprite(balloon, x: at.x, y: at.y, c) { _, row, ch in
            if sag && row == 0 { return true }
            if ch == "o" || ch == "f" { return !lit }
            return false
        }
        if f.sails < 40 && !night {
            let soot = Color(hex: 0x3A3F48)
            for (row, col) in [(12.0, 7.0), (12, 10), (13, 8)] { px.rect(at.x + col, at.y + row, 1, 1, soot) }
        }
    }

    // MARK: Down

    /// Where she came down, as the engine tells it: in the sea, the envelope folded over
    /// the capsule like a tent and a freighter coming; on land, in a cloud of dust and
    /// torn fabric; or on a field, laid out flat for the trucks.
    static func wreck(_ px: PixelCanvas, _ f: SceneFrame, _ g: GameState, t: Double) {
        let hz = aloftHorizon
        let cell = Color(hex: 0xE6E9EE), shade = Color(hex: 0xB9C0CA)
        if overField(f) != nil {
            px.rect(44, 54, 56, 3, cell)
            px.rect(44, 57, 56, 1, shade)
            px.rect(60, 54, 3, 4, Color(hex: 0xD9A441))
            px.rect(64, 54, 3, 4, Color(hex: 0xD64545))
            px.rect(36, 52, 9, 5, Color(hex: 0xECE4CF))
            return
        }
        if f.region?.has("sea") == true {
            let bob = jsRounded(sin(t * 2))
            px.rect(54, 56 + bob, 13, 4, Color(hex: 0xECE4CF))
            px.polygon([(48, 57 + bob), (60, 47 + bob), (73, 57 + bob)], cell)
            px.polygon([(60, 47 + bob), (73, 57 + bob), (66, 57 + bob)], shade)
            px.rect(52, 52 + bob, 17, 1, Color(hex: 0xD64545))
            // The freighter, coming.
            px.rect(118, hz - 3, 22, 3, Color(hex: 0x3A3F48))
            px.rect(134, hz - 7, 5, 4, Color(hex: 0xECE4CF))
            px.rect(122, hz - 5, 8, 2, Color(hex: 0xD64545))
            px.rect(136, hz - 9, 1, 2, Color(hex: 0x3A3F48))
        } else {
            px.rect(46, 54, 11, 6, Color(hex: 0xECE4CF))
            px.rect(48, 56, 2, 2, Color(hex: 0x1A2533))
            px.polygon([(57, 58), (66, 53), (98, 55), (112, 60), (70, 61)], cell)
            px.rect(76, 55, 3, 5, Color(hex: 0xD9A441))
            px.rect(80, 55, 3, 5, Color(hex: 0xD64545))
            for k in 0..<5 {
                let p = wrap(t * 3 + Double(k) * 2, 10)
                px.rect(44 + Double(k) * 14, 52 - p / 2, 4, 2, Color(hex: 0xD9B07A).opacity(max(0.1, 0.6 - p / 18)))
            }
        }
    }

    /// Dust haze: forty specks drifting across, a little slower loitering.
    static func dust(_ px: PixelCanvas, t: Double, moving: Bool) {
        let c = Color(hex: 0xD9B07A)
        for i in 0..<40 {
            let di = Double(i)
            let x = wrap(di * 37 - t * (6 + Double(i % 5)) * (moving ? 1 : 0.3), 160).rounded(.down)
            let y = Double((i * 53) % 78) + jsRounded(sin(t * 0.7 + di))
            px.rect(x, y, 1, 1, c)
        }
    }

    // MARK: VoiceOver

    /// Where she is, as a sentence says it after a verb. The engine's names are headings
    /// ("The Indus & the Thar", "Past the Azores").
    static let regionPhrase: [String: String] = [
        "sahara": "over the Sahara", "arabia": "over Arabia", "oman": "over the Gulf of Oman",
        "thar": "over the Indus and the Thar desert", "india": "over northern India",
        "himalaya": "over the Himalaya and China", "eastchina": "over the East China Sea",
        "npacific": "over the North Pacific", "nepacific": "over the northeast Pacific",
        "southtrack": "over the Pacific on the southern track", "subtropic": "over the subtropical Pacific",
        "southwest": "over the American Southwest", "plains": "over the Great Plains",
        "atlantic": "over the North Atlantic", "azores": "over the Atlantic past the Azores",
        "morocco": "over Morocco",
    ]

    static func phrase(_ region: Region?) -> String {
        guard let region else { return "over open country" }
        return regionPhrase[region.id.rawValue] ?? "over \(region.name)"
    }

    /// For the chart's caption: on a field, over one, or over the country.
    static func whereabouts(_ g: GameState) -> String {
        let stop = g.currentStop
        if let port = BalloonSkin.journey.port(stop.id) {
            if g.atPort { return "on the ground at \(port.name)" }
            if g.mile == stop.mile && g.stopIndex > 0 { return "over the field at \(port.name)" }
        }
        return phrase(g.region)
    }

    static func label(_ f: SceneFrame) -> String {
        guard let g = f.state else { return "A balloon flying east under a clear sky" }
        let night = isNight(f) ? " by night" : ""
        if let id = field(f) {
            return "Balloon standing on the field at \(BalloonSkin.journey.port(id)?.name ?? g.currentStop.short)\(night), its ground team beside it"
        }
        if down(f) {
            if let id = overField(f) {
                return "The balloon down for good on the field at \(BalloonSkin.journey.port(id)?.name ?? g.currentStop.short), its envelope laid out flat"
            }
            return f.region?.has("sea") == true
                ? "The balloon down in the sea, its envelope folded over the capsule, a freighter coming"
                : "The balloon down on open ground, its envelope torn and spread out in the dust"
        }
        let weather = f.weather.name.lowercased()
        if launching(f) {
            return "Balloon climbing away from the launch field at Marrakech, the crowd waving. Weather: \(weather)"
        }
        let burners = Balloon.burnersOut(g) ? "burners dead" : "burners cold"
        if let id = overField(f) {
            let name = BalloonSkin.journey.port(id)?.name ?? g.currentStop.short
            if cold(f) { return "Balloon drifting over the field at \(name), \(burners). Weather: \(weather)" }
            return f.moving ? "Balloon flying over the field at \(name)\(night). Weather: \(weather)"
                            : "Balloon low over the field at \(name)\(night), the ground team waiting below. Weather: \(weather)"
        }
        if let stop = landmark(f) {
            switch stop.id {
            case "atlas": return "Balloon crossing the High Atlas, snowfields below\(night). Weather: \(weather)"
            case "him": return "Balloon passing the Himalaya, Everest on the horizon\(night). Weather: \(weather)"
            case "pacific": return "Balloon leaving the coast of Japan, the open Pacific ahead\(night). Weather: \(weather)"
            case "dateline": return "Balloon crossing the date line over the Pacific\(night). Weather: \(weather)"
            case "landfall":
                return BalloonChart.onSouthTrack(g)
                    ? "Balloon crossing the coast at San Diego, brown hills ahead\(night). Weather: \(weather)"
                    : "Balloon crossing the coast of California, the redwoods ahead\(night). Weather: \(weather)"
            case "azores": return "Balloon over the Azores, a fishing boat waiting below\(night). Weather: \(weather)"
            case "finish": return "The balloon down on a stony plain outside Marrakech, children running out from a village"
            default: return "Balloon over \(stop.name)\(night). Weather: \(weather)"
            }
        }
        let over = phrase(f.region)
        if cold(f) { return "Balloon drifting \(over)\(night), \(burners), sinking. Weather: \(weather)" }
        return f.moving ? "Balloon flying \(over)\(night). Weather: \(weather)"
                        : "Balloon loitering low \(over)\(night), the burners blipping. Weather: \(weather)"
    }
}
