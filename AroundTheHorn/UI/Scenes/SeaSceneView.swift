import SwiftUI
import HornEngine

/// The pixel-art scene (spec §3), a port of the prototype's `drawScene`: a 160×80
/// logical grid, each logical pixel a filled rectangle snapped to whole points.
struct SeaSceneView: View {
    let game: GameState?
    var moving = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// One clock for every scene, so the clouds don't jump back when the screen changes.
    static let start = Date()

    var body: some View {
        TimelineView(.animation(paused: reduceMotion)) { tl in
            Canvas(rendersAsynchronously: true) { ctx, size in
                var px = PixelCanvas(ctx: ctx, scale: size.width / CGFloat(SeaScene.w))
                SeaScene.draw(&px, t: tl.date.timeIntervalSince(Self.start), weather: game?.weather ?? .fair,
                              moving: moving, atPort: game?.atPort ?? false, sails: game?.sails ?? 100)
            }
        }
        .aspectRatio(2, contentMode: .fit)
        .background(Color.black)
        .overlay(Rectangle().strokeBorder(Theme.line, lineWidth: 2))
        .accessibilityElement()
        .accessibilityLabel(label)
        .accessibilityAddTraits(.isImage)
    }

    private var label: String {
        guard let g = game else { return "A ship under sail" }
        let w = g.weather == .storm ? "a storm" : g.weather.name.lowercased()
        if g.atPort { return "Ship at anchor below a hillside town" }
        return moving ? "Ship sailing in \(w)" : "Ship hove to in \(w)"
    }
}

/// Fills logical pixels at a scale, snapping each edge to a whole device point so
/// neighbouring rectangles never leave a hairline between them.
struct PixelCanvas {
    let ctx: GraphicsContext
    let scale: CGFloat

    func rect(_ x: Double, _ y: Double, _ w: Double, _ h: Double, _ color: Color) {
        let x0 = (CGFloat(x) * scale).rounded(.down), y0 = (CGFloat(y) * scale).rounded(.down)
        let x1 = (CGFloat(x + w) * scale).rounded(.down), y1 = (CGFloat(y + h) * scale).rounded(.down)
        guard x1 > x0, y1 > y0 else { return }
        ctx.fill(Path(CGRect(x: x0, y: y0, width: x1 - x0, height: y1 - y0)), with: .color(color))
    }
}

enum SeaScene {
    static let w = 160.0, h = 80.0, horizon = 46.0

    struct Sky {
        let top: UInt32, bot: UInt32, sea: UInt32, wave: UInt32
        var sun: UInt32?
        var clouds = 0
        var cloud: UInt32 = 0xF4F7FA
        var still = false
        var rough = 1.0
        var rain = false, fog = false, snow = false, lightning = false
    }

    /// The prototype's `SKY`.
    static func sky(_ w: Weather) -> Sky {
        switch w {
        case .fair: return Sky(top: 0x2D5F9A, bot: 0x9FD0EE, sea: 0x1D4E7A, wave: 0x7FB8DE, sun: 0xFFE27A, clouds: 1)
        case .fresh: return Sky(top: 0x2A5C98, bot: 0xA8D8F0, sea: 0x1A4A78, wave: 0xE9F4FB, sun: 0xFFE27A, clouds: 2)
        case .light: return Sky(top: 0x3A6AA2, bot: 0xB6DCF0, sea: 0x22557F, wave: 0x8CC0E0, sun: 0xFFE27A, clouds: 1)
        case .calm: return Sky(top: 0xD9893F, bot: 0xF6D78B, sea: 0x3C6F88, wave: 0x9FC6CF, sun: 0xFFF1B0, still: true)
        case .hot: return Sky(top: 0xE07A3A, bot: 0xF8D27A, sea: 0x3C6F88, wave: 0xA7CBD0, sun: 0xFFF6C8, still: true)
        case .rain: return Sky(top: 0x3E4A5A, bot: 0x7D8A98, sea: 0x24394E, wave: 0x8AA0B4, clouds: 3, cloud: 0x6B7685, rain: true)
        case .fog: return Sky(top: 0x8D969E, bot: 0xC5CBD0, sea: 0x5F6F7C, wave: 0xB5BEC6, fog: true)
        case .cold: return Sky(top: 0x55606E, bot: 0xA6B2BF, sea: 0x2A3C4F, wave: 0xDFE8F0, clouds: 3, cloud: 0x8C97A3, snow: true)
        case .gale: return Sky(top: 0x33404F, bot: 0x6E7D8D, sea: 0x1F3346, wave: 0xE8EEF3, clouds: 3, cloud: 0x55616F, rough: 2)
        case .storm: return Sky(top: 0x15191F, bot: 0x3A434F, sea: 0x121D29, wave: 0xC9D3DC, clouds: 3,
                                cloud: 0x2C333D, rough: 3, rain: true, lightning: true)
        }
    }

    /// The prototype's `SHIP_SPR`, 26 wide.
    static let ship = [
        "           r              ",
        "           rrr            ",
        "    m      m       m      ",
        "   sss    sssss    ss     ",
        "  sssss  sssssss  ssss    ",
        "    m      m       m      ",
        "  sssss  sssssss  sssss   ",
        " ssssss sssssssss ssssss  ",
        " ssssss sssssssss ssssss  ",
        "    m      m       m      ",
        " ssssss sssssssss sssssss ",
        " ssssss sssssssss sssssss b",
        "    m      m       m    bb",
        "hh  m      m       m   hhh",
        "hhhhhhhhhhhhhhhhhhhhhhhhhh",
        " hyyyyyyyyyyyyyyyyyyyyyyh ",
        "  hhhhhhhhhhhhhhhhhhhhhh  ",
        "   hhhhhhhhhhhhhhhhhhhh   ",
    ].map(Array.init)

    static let shipColors: [Character: Color] = [
        "s": Color(hex: 0xEFE6CC), "m": Color(hex: 0x6B4A2B), "h": Color(hex: 0x4A2E1A),
        "y": Color(hex: 0xD9A441), "r": Color(hex: 0xD64545), "b": Color(hex: 0x6B4A2B),
    ]

    /// The prototype's `mix`: a colour `t` of the way from `a` to `b`, rounded per channel.
    static func mix(_ a: UInt32, _ b: UInt32, _ t: Double) -> Color {
        func ch(_ s: UInt32) -> Double {
            let x = Double((a >> s) & 255), y = Double((b >> s) & 255)
            return jsRounded(x * (1 - t) + y * t) / 255
        }
        return Color(red: ch(16), green: ch(8), blue: ch(0))
    }

    /// JavaScript's `%`: the sign follows the dividend.
    static func mod(_ a: Double, _ b: Double) -> Double { a.truncatingRemainder(dividingBy: b) }

    static func draw(_ px: inout PixelCanvas, t: Double, weather: Weather, moving: Bool, atPort: Bool, sails: Double) {
        let s = sky(weather)
        let hz = horizon
        for i in 0..<8 {
            px.rect(0, (Double(i) * hz / 8).rounded(.down), w, (hz / 8).rounded(.up) + 1, mix(s.top, s.bot, Double(i) / 7))
        }
        if let sun = s.sun {
            let c = Color(hex: sun)
            px.rect(125, 8, 7, 11, c)
            px.rect(123, 10, 11, 7, c)
            px.rect(124, 9, 9, 9, c)
        }
        let spd = moving ? 14 * weather.speed + 2 : 1.5
        if s.clouds > 0 {
            let c = Color(hex: s.cloud)
            for i in 0..<(s.clouds * 2) {
                let di = Double(i)
                var x = mod(di * 61 + 20 - t * (2 + di) * (moving ? 1.6 : 0.4), w + 40)
                if x < 0 { x += w + 40 }
                x = jsRounded(x - 20)
                let y = 5 + Double((i * 13) % 24)
                px.rect(x, y, 16, 3, c)
                px.rect(x + 3, y - 2, 9, 2, c)
                px.rect(x + 2, y + 3, 12, 1, c)
            }
        }
        if atPort {
            let hill = Color(hex: 0x2F4A35)
            for i in 92..<160 {
                let di = Double(i)
                let hh = jsRounded(11 + 7 * sin(di * 0.09) + 4 * sin(di * 0.23))
                px.rect(di, hz - hh, 1, hh, hill)
            }
            for i in 0..<7 {
                let bx = Double(104 + i * 8), bh = Double(3 + (i * 5) % 4)
                px.rect(bx, hz - bh - 1, 5, bh + 1, Color(hex: 0xE9DFC8))
                px.rect(bx, hz - bh - 2, 5, 1, Color(hex: 0x9A3B2E))
            }
        }
        px.rect(0, hz, w, h - hz, Color(hex: s.sea))
        let rough = s.rough
        let wave = Color(hex: s.wave)
        for row in 0..<8 {
            let y = hz + 2 + Double(row * 4)
            let rs = spd * (0.4 + Double(row) * 0.18) + (s.still ? 0 : 1)
            for i in 0..<7 {
                var x = mod(Double(i * 29 + row * 17) - t * rs, w)
                if x < 0 { x += w }
                let len = s.still ? 1 : 2 + Double((i + row) % 3) + rough
                let jitter = rough > 1 ? jsRounded(sin(t * 3 + Double(i + row))) : 0
                px.rect(x.rounded(.down), y + jitter, len, 1, wave)
            }
        }
        let bob = jsRounded(sin(t * (1.4 + rough * 0.7)) * (0.5 + rough * 0.5))
        for (r, row) in ship.enumerated() {
            for (col, ch) in row.enumerated() where ch != " " {
                if ch == "s" && sails < 60 && Double((col * 7 + r * 13) % 37) < (60 - sails) / 2.2 { continue }
                px.rect(44 + Double(col), hz - 14 + bob + Double(r), 1, 1, shipColors[ch]!)
            }
        }
        if moving && !s.still {
            for i in 0..<4 {
                px.rect(66 + Double((i * 5 + Int((t * 8).rounded(.down))) % 10), hz + 3 + Double(i % 2), 2, 1, wave)
            }
        }
        if s.rain {
            let c = Color(red: 200 / 255, green: 215 / 255, blue: 230 / 255).opacity(0.6)
            for i in 0..<45 {
                let di = Double(i)
                px.rect(mod(di * 37 + t * 30, w).rounded(.down), mod(di * 53 + t * 150, h).rounded(.down), 1, 3, c)
            }
        }
        if s.snow {
            for i in 0..<30 {
                let di = Double(i)
                let x = mod(mod(di * 41 + t * 10 + sin(t + di) * 4, w) + w, w)
                px.rect(x.rounded(.down), mod(di * 29 + t * 16, h).rounded(.down), 1, 1, .white)
            }
        }
        if s.fog {
            px.rect(0, 0, w, h, Color(red: 210 / 255, green: 215 / 255, blue: 220 / 255).opacity(0.38))
        }
        if s.lightning && Int((t * 10).rounded(.down)) % 53 == 0 {
            px.rect(0, 0, w, h, Color.white.opacity(0.55))
        }
    }
}
