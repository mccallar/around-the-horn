import SwiftUI
import HornEngine

/// The Iron Road's scene: a wood-burning 4-4-0, her tender, a tank car, two boxcars and
/// a caboose, heading west (left) under nine weathers and through thirteen kinds of
/// country. A yard at the stops, a trestle at Dale Creek, snowsheds in the Sierra, and
/// wear that shows: a leaking, rusting engine, and cars with planks gone and a hot box.
enum RailScene {
    static let horizon = 44.0
    /// The top of the rail the wheels stand on.
    static let rail = 62.0

    // MARK: Sky

    struct Palette {
        let top: UInt32, bot: UInt32
        var sun: UInt32?
        var clouds = 0
        var cloud: UInt32 = 0xF4F7FA
        /// What the weather does to the colour of the ground, and how far.
        var tint: UInt32 = 0
        var amount = 0.0
        var water: UInt32 = 0x5C9BD0
    }

    /// By the kind of sky. A blizzard is snow that is hard on the crew.
    static func palette(_ w: Weather) -> Palette {
        switch w.sky {
        case .clear, .still:
            return Palette(top: 0x3A78B8, bot: 0xBFE0F2, sun: 0xFFE27A, clouds: 1)
        case .breeze:
            return Palette(top: 0x3570B0, bot: 0xC6E4F4, sun: 0xFFE27A, clouds: 3, water: 0x5590C4)
        case .heat:
            return Palette(top: 0xE07A3A, bot: 0xF8D27A, sun: 0xFFF6C8, tint: 0xE8B45A, amount: 0.18, water: 0x7FAFC0)
        case .rain, .gale:
            return Palette(top: 0x3E4A5A, bot: 0x7D8A98, clouds: 3, cloud: 0x6B7685, tint: 0x2A3440, amount: 0.3, water: 0x4A6A86)
        case .fog:
            return Palette(top: 0x8D969E, bot: 0xC5CBD0, tint: 0x9AA2A8, amount: 0.25, water: 0x7F97A8)
        case .snow:
            return w.harsh > 1
                ? Palette(top: 0x6E7780, bot: 0xC4CCD4, tint: 0xEEF2F6, amount: 0.88, water: 0xB4C6D4)
                : Palette(top: 0x55606E, bot: 0xA6B2BF, clouds: 3, cloud: 0x8C97A3, tint: 0xE8EEF3, amount: 0.6, water: 0x8FA8BC)
        case .storm:
            return Palette(top: 0x15191F, bot: 0x3A434F, clouds: 3, cloud: 0x2C333D, tint: 0x1A2230, amount: 0.45, water: 0x2E4A64)
        case .dust:
            return Palette(top: 0xB08A55, bot: 0xDCC090, sun: 0xF4E2B0, tint: 0xC9A27A, amount: 0.3, water: 0x8A9A90)
        }
    }

    // MARK: The train

    static let engine = [
        "     kkkkk                    ",
        "    kkkkkkk           oooooooo",
        "     kkkkk            cccccccc",
        "      kkk    g   gg   cwwccwwc",
        "   ll kkk   ggg gggg  cwwccwwc",
        "   llkkkkkkkkkkkkkkkkkcccccccc",
        "    kkkkgkkkkkgkkkkkgkcccccccc",
        "    kkkkgkkkkkgkkkkkgkcccccccc",
        "    kkkkkkkkkkkkkkkkkkcccccccc",
        "  ppnnnnnnnnnnnnnnnnnnnnnnnnnn",
        " ppp  dd   dd   RRR    RRR    ",
        "pppp dddd dddd RRRRR  RRRRR   ",
        "pppp dddd dddd RRhRR  RRhRR   ",
        "pppp  dd   dd   RRR    RRR    ",
    ].map(Array.init)

    static let tender = [
        "ttttttttttttt",
        "ttttttttttttt",
        "tgggggggggggt",
        "ttttttttttttt",
        "ttttttttttttt",
        "nnnnnnnnnnnnn",
        " dd       dd ",
        "dddd     dddd",
        " dd       dd ",
    ].map(Array.init)

    static let tankCar = [
        "  aaaaaaaaaaaa  ",
        " aabaaabaaabaaa ",
        " aabaaabaaabaaa ",
        " aabaaabaaabaaa ",
        " aabaaabaaabaaa ",
        "  aaaaaaaaaaaa  ",
        "ffffffffffffffff",
        " dd          dd ",
        "dddd        dddd",
        " dd          dd ",
    ].map(Array.init)

    static let boxcar = [
        "    yyyyyyyyyy    ",
        "oooooooooooooooooo",
        "BBBBBBBBBBBBBBBBBB",
        "BBBBBBDDDDDDBBBBBB",
        "BBBBBBDDDDDDBBBBBB",
        "BBBBBBDDDDDDBBBBBB",
        "BBBBBBDDDDDDBBBBBB",
        "BBBBBBBBBBBBBBBBBB",
        " dd            dd ",
        "dddd          dddd",
        " dd            dd ",
    ].map(Array.init)

    static let caboose = [
        "     ooooo     ",
        "     CwCwC     ",
        "ooooooooooooooo",
        " CCCCCCCCCCCCC ",
        " CCwwCCCCCwwCC ",
        " CCwwCCCCCwwCC ",
        " CCCCCCCCCCCCC ",
        " CCCCCCCCCCCCC ",
        "nnnnnnnnnnnnnnn",
        "  dd       dd  ",
        " dddd     dddd ",
        "  dd       dd  ",
    ].map(Array.init)

    static let colors: [Character: Color] = [
        "k": Color(hex: 0x26262B), "o": Color(hex: 0x4A2E1A), "c": Color(hex: 0x7E2F24), "w": Color(hex: 0x9FC6DE),
        "g": Color(hex: 0xD9A441), "l": Color(hex: 0xF2E3A6), "n": Color(hex: 0x3A3A40), "p": Color(hex: 0xB03A2E),
        "d": Color(hex: 0x4A4A52), "R": Color(hex: 0xA83A2C), "h": Color(hex: 0x26262B), "t": Color(hex: 0x2F4A3A),
        "a": Color(hex: 0x9A7A4E), "b": Color(hex: 0x4A4A52), "f": Color(hex: 0x5A3F2A), "y": Color(hex: 0x8A6A48),
        "B": Color(hex: 0x8C4A32), "D": Color(hex: 0x74391F), "C": Color(hex: 0xB5382C),
    ]
    /// The second boxcar is a different road's.
    static let ochre: [Character: Color] = colors.merging(["B": Color(hex: 0xB8893C), "D": Color(hex: 0x94692A)]) { $1 }

    /// Where each car's left edge stands.
    static let engineX = 16.0, tenderX = 47.0, tankX = 61.0, box1X = 78.0, box2X = 97.0, cabooseX = 116.0

    // MARK: Drawing

    static func wrap(_ x: Double, _ period: Double) -> Double {
        let m = x.truncatingRemainder(dividingBy: period)
        return m < 0 ? m + period : m
    }

    static func isNight(_ hour: Int) -> Bool { hour >= 20 || hour < 5 }

    /// The Dale Creek trestle, for the few miles either side of it.
    static func onTrestle(_ f: SceneFrame) -> Bool {
        guard let g = f.state, !f.atPort else { return false }
        return (540...556).contains(g.mile)
    }

    static func draw(_ px: PixelCanvas, _ f: SceneFrame) {
        let s = palette(f.weather)
        let t = f.t, w = px.w, h = px.h, hz = horizon
        let night = isNight(f.hour)
        let blizzard = f.weather.sky == .snow && f.weather.harsh > 1
        let id = f.region?.id.rawValue ?? "platte"
        // How far the country has slid past, in pixels at the track.
        let scroll = f.moving ? t * 34 * max(0.35, min(1.2, f.weather.speed)) : 0
        let tint: (UInt32) -> Color = { PixelCanvas.mix($0, s.tint, s.amount) }
        let water = Color(hex: s.water)

        px.sky(top: s.top, bottom: s.bot, horizon: hz)
        if let sun = s.sun, !night {
            let across = Double(max(0, min(14, f.hour - 5))) / 14
            px.sun(x: 138 - across * 122, y: 5 + abs(Double(f.hour) - 12) * 2.2, Color(hex: sun))
        }
        px.clouds(s.clouds * 2, Color(hex: s.cloud), t: t, drift: f.weather.sky == .breeze ? -3 : -0.5)

        let trestle = onTrestle(f)
        far(px, id, scroll: scroll * 0.12, tint)
        px.rect(0, hz, w, h - hz, tint(trestle ? 0x55634F : ground(id)))
        if trestle {
            gorge(px, scroll: scroll, tint, water)
        } else {
            middle(px, id, scroll: scroll * 0.35, tint, water)
            if f.atPort { yard(px, tint) } else { poles(px, scroll: scroll) }
            if id == "sierra" && !f.atPort { shedBack(px, scroll: scroll) }
            roadbed(px, id, scroll: scroll, tint)
        }

        train(px, f, night: night)
        smoke(px, f, night: night)

        if !trestle {
            near(px, id, scroll: scroll * 1.5, tint, water)
            if id == "sierra" && !f.atPort { shedFront(px, scroll: scroll) }
        }
        if blizzard {
            // Drifts over the rails and a second fall of snow, driven.
            for i in 0..<9 {
                let x = wrap(Double(i) * 23 + scroll, w + 20) - 10
                px.rect(x.rounded(.down), rail - 1, 12, 2, Color(hex: 0xF4F7FA))
            }
            px.rect(0, 0, w, h, Color.white.opacity(0.22))
            px.snow(t: t * 2.3 + 40)
        }
        if f.weather.sky == .breeze { wind(px, t: t) }
        if f.weather.sky == .heat { shimmer(px, t: t) }
        px.air(f.weather.sky, t: t)

        if night {
            px.rect(0, 0, w, h, Color(hex: 0x070B1C).opacity(0.62))
            lights(px, f, clear: s.sun != nil)
        } else if (17..<20).contains(f.hour) {
            px.rect(0, 0, w, h, Color(hex: 0xE0703A).opacity(0.16))
        } else if f.hour == 5 {
            px.rect(0, 0, w, h, Color(hex: 0xE8A0A8).opacity(0.14))
        }
    }

    // MARK: Country

    /// The ground at the track, by region.
    static func ground(_ id: String) -> UInt32 {
        switch id {
        case "platte": return 0x7C9A4A
        case "highplains": return 0xB4A45A
        case "sherman": return 0x8E8A64
        case "laramie": return 0x9AA05C
        case "reddesert": return 0xC07A4A
        case "wasatch": return 0x9A7A52
        case "saltdesert": return 0xE2DFD2
        case "humboldt": return 0x9A9A6C
        case "fortymile": return 0xD2C8A8
        case "truckee": return 0x74A050
        case "eastslope": return 0x6E8456
        case "sierra": return 0x8A9484
        case "valley": return 0x7DAA4C
        default: return 0x7C9A4A
        }
    }

    /// What stands on the horizon.
    static func far(_ px: PixelCanvas, _ id: String, scroll: Double, _ tint: (UInt32) -> Color) {
        let hz = horizon
        let all = 0..<Int(px.w)
        func ridge(_ color: UInt32, snow: Double? = nil, _ height: @escaping (Double) -> Double) {
            px.hills(all, base: hz, tint(color)) { height($0 - scroll) }
            guard let snow else { return }
            // Snow on whatever stands above the line.
            for i in all {
                let hh = jsRounded(height(Double(i) - scroll))
                if hh > snow { px.rect(Double(i), hz - hh, 1, min(4, hh - snow), Color(hex: 0xF4F7FA)) }
            }
        }
        switch id {
        case "highplains":
            ridge(0x9C8F5E) { sin($0 * 0.03) > 0.55 ? 5 : 1.5 + sin($0 * 0.11) }
        case "sherman":
            ridge(0x7D776E) { 10 + 6 * sin($0 * 0.07) + 3 * sin($0 * 0.19) }
        case "laramie":
            ridge(0x6A7C96, snow: 8) { 7 + 4 * sin($0 * 0.05) + 2 * sin($0 * 0.13) }
        case "reddesert":
            ridge(0xA5553A) { x in
                let m = sin(x * 0.04)
                return m > 0.3 ? 10 : m > -0.2 ? 4 : 1
            }
        case "wasatch":
            ridge(0x9B4B33) { 27 + 8 * sin($0 * 0.05) + 4 * sin($0 * 0.21) }
            ridge(0x7E3A28) { 15 + 6 * sin($0 * 0.05 + 0.6) + 3 * sin($0 * 0.21) }
        case "saltdesert":
            ridge(0x8C93B0) { 4 + 2 * sin($0 * 0.06) + sin($0 * 0.17) }
        case "humboldt":
            ridge(0x8A7458) { 7 + 4 * sin($0 * 0.045) + 2 * sin($0 * 0.17) }
        case "fortymile":
            ridge(0x6E6258) { 5 + 3 * sin($0 * 0.05) + sin($0 * 0.21) }
        case "truckee":
            ridge(0x5E6E86, snow: 22) { 20 + 7 * sin($0 * 0.045) + 4 * sin($0 * 0.15) }
            ridge(0x2F5A3A) { 6 + 2 * sin($0 * 0.12) }
        case "eastslope":
            ridge(0x77808C, snow: 30) { 28 + 8 * sin($0 * 0.04 + 1) + 4 * sin($0 * 0.17) }
            ridge(0x2E5237) { 17 + 7 * sin($0 * 0.05) + 3 * sin($0 * 0.23) }
        case "sierra":
            ridge(0x8A8F9A, snow: 24) { 28 + 9 * sin($0 * 0.05) + 5 * sin($0 * 0.19) }
            ridge(0x34573E) { 9 + 4 * sin($0 * 0.08) + 2 * sin($0 * 0.29) }
        case "valley":
            ridge(0x7C92A8) { 4 + 2 * sin($0 * 0.05) + sin($0 * 0.13) }
        default:
            ridge(0x6E8A5A) { 2 + 1.5 * sin($0 * 0.05) }
        }
    }

    /// Between the horizon and the track: rivers, trees, rock.
    static func middle(_ px: PixelCanvas, _ id: String, scroll: Double, _ tint: (UInt32) -> Color, _ water: Color) {
        let hz = horizon, w = px.w
        /// `n` things spread along the line, each asked to draw itself at its x.
        func scatter(_ n: Int, every: Double, seed: Double = 0, _ put: (Double, Int) -> Void) {
            for i in 0..<n {
                let x = wrap(Double(i) * every + seed + scroll, w + 24) - 12
                put(x.rounded(.down), i)
            }
        }
        switch id {
        case "highplains":
            scatter(9, every: 21, seed: 5) { x, i in px.rect(x, hz + 3 + Double(i % 4) * 3, 3, 1, tint(0xD8C878)) }
        case "sherman":
            scatter(5, every: 39, seed: 8) { x, i in
                px.rect(x, hz + 4 + Double(i % 2) * 5, 6, 3, tint(0x9A948A))
                px.rect(x + 1, hz + 2 + Double(i % 2) * 5, 4, 2, tint(0xB0AAA0))
            }
            scatter(3, every: 61, seed: 30) { x, _ in pine(px, x, hz + 4, tint) }
        case "laramie":
            scatter(8, every: 23, seed: 3) { x, i in px.rect(x, hz + 2 + Double(i % 5) * 3, 4, 1, tint(0xC8C070)) }
        case "reddesert":
            scatter(8, every: 23, seed: 9) { x, i in px.rect(x, hz + 3 + Double(i % 4) * 3, 2, 2, tint(0x7E8A66)) }
            scatter(2, every: 92, seed: 40) { x, _ in
                px.rect(x, hz + 2, 9, 4, tint(0x9A4A32))
                px.rect(x + 2, hz, 5, 2, tint(0x9A4A32))
            }
        case "wasatch":
            scatter(6, every: 31, seed: 6) { x, i in pine(px, x, hz + 3 + Double(i % 3) * 3, tint) }
        case "saltdesert":
            px.rect(0, hz + 1, w, 2, PixelCanvas.mix(0xB8D4E0, 0xE2DFD2, 0.25))
            scatter(10, every: 19, seed: 2) { x, i in px.rect(x, hz + 5 + Double(i % 4) * 3, 5, 1, Color(hex: 0xF6F4EC)) }
        case "fortymile":
            scatter(7, every: 27, seed: 4) { x, i in px.rect(x, hz + 3 + Double(i % 4) * 4, 7, 1, Color(hex: 0xEEE8D4)) }
            scatter(4, every: 47, seed: 19) { x, i in px.rect(x, hz + 8 + Double(i % 2) * 5, 3, 2, tint(0x7A7064)) }
        case "truckee", "humboldt", "platte", "valley":
            // A river running with the line, sandbars or willows along it.
            let y = id == "humboldt" ? hz + 6 : hz + 3
            let green: UInt32 = id == "humboldt" ? 0x6E9450 : id == "valley" ? 0x4E8A3E : 0x5E9048
            px.rect(0, y - 1, w, 1, tint(green))
            px.rect(0, y, w, id == "platte" ? 5 : 3, water)
            px.rect(0, y + (id == "platte" ? 5 : 3), w, 1, tint(green))
            if id == "platte" {
                scatter(5, every: 41, seed: 12) { x, i in px.rect(x, y + 1 + Double(i % 3), 11, 1, tint(0xD8C690)) }
            }
            scatter(id == "humboldt" ? 6 : 4, every: id == "humboldt" ? 33 : 47, seed: 17) { x, i in
                if id == "valley" { oak(px, x, y - 1, tint) } else { bush(px, x, y - (i % 2 == 0 ? 1 : -4), tint, green) }
            }
            if id == "valley" {
                scatter(4, every: 46, seed: 2) { x, i in px.rect(x, hz + 10 + Double(i % 2) * 4, 22, 2, tint(0xD8B84A)) }
            }
            if id == "truckee" {
                scatter(3, every: 63, seed: 28) { x, _ in pine(px, x, hz + 11, tint) }
            }
        case "eastslope", "sierra":
            scatter(7, every: 27, seed: 5) { x, i in pine(px, x, hz + 2 + Double(i % 3) * 4, tint) }
            scatter(3, every: 67, seed: 44) { x, _ in
                px.rect(x, hz + 9, 7, 3, tint(0xA8A8AC))
                px.rect(x + 1, hz + 8, 4, 1, Color(hex: 0xF4F7FA))
            }
        default:
            break
        }
    }

    /// In front of the track.
    static func near(_ px: PixelCanvas, _ id: String, scroll: Double, _ tint: (UInt32) -> Color, _ water: Color) {
        let w = px.w, h = px.h
        func scatter(_ n: Int, every: Double, seed: Double = 0, _ put: (Double, Int) -> Void) {
            for i in 0..<n {
                let x = wrap(Double(i) * every + seed + scroll, w + 24) - 12
                put(x.rounded(.down), i)
            }
        }
        switch id {
        case "wasatch", "eastslope":
            // The river the grade was cut beside.
            px.rect(0, 71, w, h - 71, water)
            px.rect(0, 70, w, 1, tint(0x5E7A48))
            scatter(6, every: 31, seed: 3) { x, i in px.rect(x, 73 + Double(i % 3) * 2, 6, 1, Color.white.opacity(0.7)) }
            scatter(3, every: 71, seed: 20) { x, _ in px.rect(x, 71, 5, 2, tint(0x8A8378)) }
        case "saltdesert", "fortymile":
            scatter(6, every: 33, seed: 7) { x, i in px.rect(x, 68 + Double(i % 3) * 4, 9, 1, Color(hex: 0xF6F4EC)) }
        case "reddesert", "humboldt":
            scatter(7, every: 27, seed: 5) { x, i in
                px.rect(x, 68 + Double(i % 3) * 4, 3, 2, tint(0x7E8A66))
                px.rect(x + 1, 67 + Double(i % 3) * 4, 1, 1, tint(0x98A47E))
            }
        case "sherman", "sierra":
            scatter(4, every: 47, seed: 9) { x, i in
                px.rect(x, 69 + Double(i % 2) * 5, 6, 3, tint(0x9A948A))
                px.rect(x + 1, 68 + Double(i % 2) * 5, 3, 1, tint(0xB8B2A8))
            }
        case "valley":
            scatter(5, every: 37, seed: 4) { x, i in px.rect(x, 68 + Double(i % 2) * 6, 18, 2, tint(0xD8B84A)) }
            scatter(8, every: 23, seed: 11) { x, i in px.rect(x, 72 + Double(i % 3) * 2, 1, 2, tint(0x4E8A3E)) }
        default:
            // Grass, in tufts.
            let blade: UInt32 = id == "highplains" || id == "laramie" ? 0xD8C878 : 0x4E7A36
            scatter(11, every: 17, seed: 6) { x, i in
                px.rect(x, 68 + Double(i % 4) * 3, 1, 2, tint(blade))
                px.rect(x + 2, 69 + Double(i % 4) * 3, 1, 1, tint(blade))
            }
        }
    }

    static func pine(_ px: PixelCanvas, _ x: Double, _ base: Double, _ tint: (UInt32) -> Color) {
        let c = tint(0x24482E)
        px.rect(x + 2, base - 8, 1, 2, c)
        px.rect(x + 1, base - 6, 3, 2, c)
        px.rect(x, base - 4, 5, 3, c)
        px.rect(x + 2, base - 1, 1, 1, Color(hex: 0x4A2E1A))
    }

    static func oak(_ px: PixelCanvas, _ x: Double, _ base: Double, _ tint: (UInt32) -> Color) {
        let c = tint(0x3E6E34)
        px.rect(x + 1, base - 6, 5, 1, c)
        px.rect(x, base - 5, 7, 3, c)
        px.rect(x + 3, base - 2, 1, 2, Color(hex: 0x4A2E1A))
    }

    static func bush(_ px: PixelCanvas, _ x: Double, _ base: Double, _ tint: (UInt32) -> Color, _ color: UInt32) {
        px.rect(x + 1, base - 3, 4, 1, tint(color))
        px.rect(x, base - 2, 6, 2, tint(color))
    }

    /// Ballast, ties and the rail.
    static func roadbed(_ px: PixelCanvas, _ id: String, scroll: Double, _ tint: (UInt32) -> Color) {
        let w = px.w
        px.rect(0, rail, w, 4, tint(0x8A8070))
        for i in 0..<28 {
            let x = wrap(Double(i) * 6 + scroll, w + 6) - 3
            px.rect(x.rounded(.down), rail + 1, 2, 2, Color(hex: 0x4A3626))
        }
        px.rect(0, rail, w, 1, Color(hex: 0x2A2A30))
    }

    /// The telegraph, which came west with the rails.
    static func poles(_ px: PixelCanvas, scroll: Double) {
        let c = Color(hex: 0x5A4632)
        for i in 0..<3 {
            let x = (wrap(Double(i) * 72 + 30 + scroll, px.w + 56) - 28).rounded(.down)
            px.rect(x, 37, 1, 25, c)
            px.rect(x - 2, 38, 5, 1, c)
        }
    }

    /// A yard: the water tank ahead of the engine, the depot behind the cars, cordwood.
    static func yard(_ px: PixelCanvas, _ tint: (UInt32) -> Color) {
        let wood = Color(hex: 0x8A6A48), dark = Color(hex: 0x4A2E1A)
        // The depot: board walls, a wide roof, a chimney, a signboard.
        px.rect(96, 36, 50, 26, tint(0xC8B080))
        px.rect(92, 31, 58, 5, tint(0x7A3A2A))
        px.rect(96, 29, 50, 2, tint(0x7A3A2A))
        px.rect(134, 24, 4, 6, tint(0x8A8378))
        px.rect(112, 38, 18, 5, Color(hex: 0xF0E8D0))
        px.rect(114, 40, 14, 1, dark)
        for i in 0..<4 { px.rect(100 + Double(i) * 12, 44, 6, 5, Color(hex: 0x4A6A86)) }
        px.rect(88, 60, 66, 2, wood)
        // The tank: a tub on legs with a spout that swings down over the tender.
        px.rect(1, 22, 14, 2, dark)
        px.rect(0, 24, 16, 13, wood)
        for i in 0..<3 { px.rect(0, 27 + Double(i) * 4, 16, 1, dark) }
        px.rect(2, 37, 1, 25, dark)
        px.rect(13, 37, 1, 25, dark)
        px.rect(7, 37, 1, 25, dark)
        px.line(from: (2, 40), to: (13, 58), dark)
        px.line(from: (13, 40), to: (2, 58), dark)
        px.line(from: (16, 34), to: (26, 41), dark)
        px.rect(25, 41, 2, 3, dark)
        // Cordwood, stacked for sale.
        for r in 0..<3 {
            px.rect(137 + Double(r), 73 - Double(r) * 2, 18 - Double(r) * 2, 2, r % 2 == 0 ? wood : dark)
        }
        px.rect(134, 75, 24, 1, dark)
    }

    /// The Dale Creek trestle: timber bents down to a creek a long way below.
    static func gorge(_ px: PixelCanvas, scroll: Double, _ tint: (UInt32) -> Color, _ water: Color) {
        let w = px.w, h = px.h
        let timber = Color(hex: 0x6B4A2B), dark = Color(hex: 0x4A2E1A)
        px.hills(0..<Int(w), base: h, tint(0x6E7466)) { 9 + 5 * sin(($0 - scroll * 0.3) * 0.06) }
        px.rect(0, h - 4, w, 4, water)
        for i in 0..<5 {
            let x = wrap(Double(i) * 37 + 5 + scroll * 0.3, w + 20) - 10
            px.rect(x.rounded(.down), h - 4, 5, 2, tint(0x8A8378))
        }
        for i in 0..<9 {
            let x = (wrap(Double(i) * 20 + scroll, w + 20) - 10).rounded(.down)
            px.rect(x, rail + 3, 1, h - rail - 5, timber)
            px.rect(x + 5, rail + 3, 1, h - rail - 5, timber)
            px.line(from: (x, rail + 4), to: (x + 6, rail + 10), dark)
            px.line(from: (x + 6, rail + 4), to: (x, rail + 10), dark)
            px.rect(x - 1, rail + 10, 8, 1, timber)
        }
        px.rect(0, rail + 6, w, 1, dark)
        px.rect(0, rail, w, 3, timber)
        px.rect(0, rail, w, 1, Color(hex: 0x2A2A30))
    }

    static let shedLength = 74.0

    static func shedX(_ scroll: Double) -> Double { (wrap(150 + scroll, 250) - 80).rounded(.down) }

    /// A snowshed's far wall, behind the train.
    static func shedBack(_ px: PixelCanvas, scroll: Double) {
        let x = shedX(scroll)
        px.rect(x, 45, shedLength, rail - 45, Color(hex: 0x4A3626))
        for i in 0..<9 { px.rect(x + 4 + Double(i) * 8, 45, 1, rail - 45, Color(hex: 0x3A2A1E)) }
    }

    /// Its roof and the posts of the open side, in front.
    static func shedFront(_ px: PixelCanvas, scroll: Double) {
        let x = shedX(scroll)
        let timber = Color(hex: 0x7A5A38)
        px.polygon([(x - 3, 46), (x + 4, 41), (x + shedLength - 4, 41), (x + shedLength + 3, 46)], timber)
        px.rect(x, 40, shedLength, 2, Color(hex: 0xF4F7FA))
        px.rect(x - 2, 45, shedLength + 4, 2, Color(hex: 0x5A4028))
        for i in 0..<8 { px.rect(x + 1 + Double(i) * 10.3, 47, 2, rail - 46, timber) }
    }

    // MARK: Train, smoke, lights

    static func train(_ px: PixelCanvas, _ f: SceneFrame, night: Bool) {
        let t = f.t
        // Planks go missing as the running gear wears; the dark of the car shows through.
        let gaps = max(0, 60 - f.hull) / 2.2
        let holed: (Int, Int, Character) -> Bool = { col, r, ch in
            (ch == "B" || ch == "D" || ch == "C") && Double((col * 7 + r * 13) % 37) < gaps
        }
        let inside = Color(hex: 0x1E1612)
        func stand(_ rows: [[Character]], _ x: Double, sag: Double = 0, _ c: [Character: Color] = colors,
                   skip: (Int, Int, Character) -> Bool = { _, _, _ in false }) {
            px.sprite(rows, x: x, y: rail - Double(rows.count) + sag, c, skip: skip)
        }
        // Couplings.
        for x in [tenderX, tankX, box1X, box2X, cabooseX] { px.rect(x - 2, rail - 5, 3, 1, Color(hex: 0x26262B)) }

        px.rect(box1X + 1, rail - 9, 16, 6, inside)
        px.rect(box2X + 1, rail - 9, 16, 6, inside)
        stand(caboose, cabooseX, sag: f.hull < 30 ? 1 : 0, skip: holed)
        stand(boxcar, box2X, ochre, skip: holed)
        stand(boxcar, box1X, skip: holed)
        stand(tankCar, tankX)
        stand(tender, tenderX)
        // Cordwood on the tender, as much as is left.
        let cap = RailSkin.journey.item(.fuel).cap
        let stock = f.state.map { cap > 0 ? $0.fuel / cap : 1 } ?? 1
        let rows = stock > 0.6 ? 3 : stock > 0.3 ? 2 : stock > 0.03 ? 1 : 0
        for r in 0..<rows {
            let inset = Double(r)
            px.rect(tenderX + 1 + inset, rail - 10 - Double(r), 11 - inset * 2, 1, Color(hex: r % 2 == 0 ? 0xB08A5A : 0x8C6B42))
        }
        stand(engine, engineX)
        // Rust on the boiler as the engine wears.
        let rust = max(0, 60 - f.sails) / 2.4
        if rust > 0 {
            px.sprite(engine, x: engineX, y: rail - Double(engine.count), ["k": Color(hex: 0x7A4A2A)]) { col, r, _ in
                r < 4 || Double((col * 11 + r * 17) % 37) >= rust
            }
        }
        // The side rod, going round.
        let turn = f.moving ? Int((t * 7).rounded(.down)) % 2 : 0
        px.rect(engineX + 16, rail - 3 + Double(turn), 10, 1, Color(hex: 0xC8C8D0))

        if f.hull < 60 {
            // A hot box: a journal glowing under the first boxcar, and more as it worsens.
            let glow = Color(hex: Int((t * 5).rounded(.down)) % 2 == 0 ? 0xFF9A3A : 0xFFD27A)
            px.rect(box1X + 15, rail - 2, 2, 1, glow)
            wisp(px, x: box1X + 16, y: rail - 3, t: t, Color(hex: 0x6A6A70))
            if f.hull < 30 {
                px.rect(box2X + 2, rail - 2, 2, 1, glow)
                wisp(px, x: box2X + 3, y: rail - 3, t: t + 1.7, Color(hex: 0x6A6A70))
            }
        }
        if f.sails < 60 {
            // Steam getting out where it should not.
            let white = Color(hex: 0xF4F7FA)
            wisp(px, x: engineX + 9, y: rail - 8, t: t * 1.3, white)
            px.rect(engineX + 3, rail - 3, 2, 1, white.opacity(0.8))
            if f.sails < 30 {
                wisp(px, x: engineX + 17, y: rail - 9, t: t * 1.3 + 0.9, white)
                wisp(px, x: engineX + 5, y: rail - 4, t: t * 1.1 + 2.1, white)
            }
        }
    }

    /// A thin thread of smoke or steam rising from a point.
    static func wisp(_ px: PixelCanvas, x: Double, y: Double, t: Double, _ color: Color) {
        for i in 0..<4 {
            let p = wrap(t * 0.9 + Double(i) * 0.25, 1)
            px.rect((x + sin(t * 2 + Double(i)) * 1.5 + p * 3).rounded(.down), (y - p * 7).rounded(.down), 1 + (p > 0.5 ? 1 : 0), 1,
                    color.opacity(0.9 - p * 0.7))
        }
    }

    /// Wood smoke from the balloon stack: streaming back over the cars under way, standing
    /// straight up at rest, thin and dark from an engine in a bad way.
    static func smoke(_ px: PixelCanvas, _ f: SceneFrame, night: Bool) {
        let t = f.t
        let x0 = engineX + 7.0, y0 = rail - Double(engine.count) - 1
        let sick = f.sails < 30
        let color: UInt32 = sick ? 0x4A4A50 : 0xE4E4E0
        let puffs = sick ? 5 : 8
        // A head wind lays it flat.
        let lift = f.weather.sky == .breeze ? 7.0 : 15.0
        for i in 0..<puffs {
            let p = wrap(t * (f.moving ? 0.55 : 0.3) + Double(i) / Double(puffs), 1)
            let size = (2 + p * 5).rounded(.down)
            let back = f.moving ? p * 78 : p * 6 + sin(t + Double(i)) * 1.5
            let x = (x0 + back - size / 2).rounded(.down), y = (y0 - p * lift - size / 2).rounded(.down)
            px.rect(x, y, size, max(2, size - 1), Color(hex: color).opacity(0.85 - p * 0.65))
        }
    }

    /// What shows in the dark: stars, a moon in a clear sky, the headlamp and its beam,
    /// lamplight in the cab and the caboose, the fire.
    static func lights(_ px: PixelCanvas, _ f: SceneFrame, clear: Bool) {
        let lamp = Color(hex: 0xFFE27A)
        if clear {
            for i in 0..<16 {
                px.rect(Double((i * 37 + 11) % 160), Double((i * 23 + 5) % 38), 1, 1, Color.white.opacity(i % 3 == 0 ? 0.9 : 0.55))
            }
            px.moon(x: 124, y: 7, Color(hex: 0xF2EED8), sky: Color(hex: 0x141B33))
        }
        let top = rail - Double(engine.count)
        px.polygon([(engineX + 4, top + 4), (0, top - 4), (0, rail + 2), (engineX + 4, top + 6)], lamp.opacity(0.22))
        px.rect(engineX + 3, top + 4, 2, 2, lamp)
        for x in [engineX + 23, engineX + 27] { px.rect(x, top + 3, 2, 2, lamp) }
        px.rect(engineX + 21, rail - 5, 2, 1, Color(hex: 0xFF8A3A))
        let c = rail - Double(caboose.count) + (f.hull < 30 ? 1 : 0)
        for x in [cabooseX + 3, cabooseX + 10] { px.rect(x, c + 4, 2, 2, lamp) }
        px.rect(cabooseX + 6, c + 1, 1, 1, lamp)
        px.rect(cabooseX + 8, c + 1, 1, 1, lamp)
        if f.atPort {
            for i in 0..<4 { px.rect(100 + Double(i) * 12, 44, 6, 5, lamp.opacity(0.85)) }
        }
    }

    /// A head wind: streaks coming down the train.
    static func wind(_ px: PixelCanvas, t: Double) {
        for i in 0..<9 {
            let di = Double(i)
            let x = wrap(di * 47 + t * (120 + di * 9), px.w + 30) - 15
            px.rect(x.rounded(.down), 8 + PixelCanvas.mod(di * 23, 62), 9 + PixelCanvas.mod(di * 5, 8), 1, Color.white.opacity(0.35))
        }
    }

    /// Heat coming off the ground.
    static func shimmer(_ px: PixelCanvas, t: Double) {
        for i in 0..<10 {
            let di = Double(i)
            let x = wrap(di * 31 + sin(t * 1.3 + di) * 4, px.w)
            px.rect(x.rounded(.down), horizon - 1 + PixelCanvas.mod(di * 7, 5), 10, 1, Color(hex: 0xFFF6C8).opacity(0.3))
        }
    }

    // MARK: VoiceOver

    static func label(_ f: SceneFrame) -> String {
        guard f.state != nil else { return "A wood-burning freight train on the prairie" }
        if f.atPort { return "The train standing in the yard, by the water tank and the depot" }
        let weather = f.weather.name.lowercased()
        if onTrestle(f) { return "The train on the Dale Creek trestle. Weather: \(weather)" }
        var country = f.region?.name ?? "open country"
        if country.hasPrefix("The ") { country = "the " + country.dropFirst(4) }
        let hour = isNight(f.hour) ? " by night" : ""
        return "The train \(f.moving ? "rolling through" : "stopped in") \(country)\(hour). Weather: \(weather)"
    }
}
