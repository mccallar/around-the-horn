import SwiftUI
import HornEngine

/// 1849's scene (spec §3), a port of the prototype's `drawScene`: a ship on the sea
/// under ten skies, a hillside town in port, sails that tear as they wear.
enum Horn1849Scene {
    static let horizon = 46.0

    struct Palette {
        let top: UInt32, bot: UInt32, sea: UInt32, wave: UInt32
        var sun: UInt32?
        var clouds = 0
        var cloud: UInt32 = 0xF4F7FA
        var still = false
        var rough = 1.0
    }

    /// The prototype's `SKY`, by the kind of sky. Light airs and a dead calm are both
    /// `.still`; the calm is the one that all but stops the ship.
    static func palette(_ w: Weather) -> Palette {
        switch w.sky {
        case .clear: return Palette(top: 0x2D5F9A, bot: 0x9FD0EE, sea: 0x1D4E7A, wave: 0x7FB8DE, sun: 0xFFE27A, clouds: 1)
        case .breeze: return Palette(top: 0x2A5C98, bot: 0xA8D8F0, sea: 0x1A4A78, wave: 0xE9F4FB, sun: 0xFFE27A, clouds: 2)
        case .still:
            return w.speed < 0.1
                ? Palette(top: 0xD9893F, bot: 0xF6D78B, sea: 0x3C6F88, wave: 0x9FC6CF, sun: 0xFFF1B0, still: true)
                : Palette(top: 0x3A6AA2, bot: 0xB6DCF0, sea: 0x22557F, wave: 0x8CC0E0, sun: 0xFFE27A, clouds: 1)
        case .heat: return Palette(top: 0xE07A3A, bot: 0xF8D27A, sea: 0x3C6F88, wave: 0xA7CBD0, sun: 0xFFF6C8, still: true)
        case .rain: return Palette(top: 0x3E4A5A, bot: 0x7D8A98, sea: 0x24394E, wave: 0x8AA0B4, clouds: 3, cloud: 0x6B7685)
        case .fog: return Palette(top: 0x8D969E, bot: 0xC5CBD0, sea: 0x5F6F7C, wave: 0xB5BEC6)
        case .snow: return Palette(top: 0x55606E, bot: 0xA6B2BF, sea: 0x2A3C4F, wave: 0xDFE8F0, clouds: 3, cloud: 0x8C97A3)
        case .gale: return Palette(top: 0x33404F, bot: 0x6E7D8D, sea: 0x1F3346, wave: 0xE8EEF3, clouds: 3, cloud: 0x55616F, rough: 2)
        case .storm: return Palette(top: 0x15191F, bot: 0x3A434F, sea: 0x121D29, wave: 0xC9D3DC, clouds: 3,
                                    cloud: 0x2C333D, rough: 3)
        case .dust: return Palette(top: 0x2D5F9A, bot: 0x9FD0EE, sea: 0x1D4E7A, wave: 0x7FB8DE, sun: 0xFFE27A, clouds: 1)
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

    static func draw(_ px: PixelCanvas, _ f: SceneFrame) {
        let s = palette(f.weather)
        let t = f.t, w = px.w, h = px.h, hz = horizon
        px.sky(top: s.top, bottom: s.bot, horizon: hz)
        if let sun = s.sun { px.sun(x: 123, y: 8, Color(hex: sun)) }
        let spd = f.moving ? 14 * f.weather.speed + 2 : 1.5
        px.clouds(s.clouds * 2, Color(hex: s.cloud), t: t, drift: f.moving ? 1.6 : 0.4)
        if f.atPort { town(px) }
        px.rect(0, hz, w, h - hz, Color(hex: s.sea))
        let rough = s.rough
        let wave = Color(hex: s.wave)
        for row in 0..<8 {
            let y = hz + 2 + Double(row * 4)
            let rs = spd * (0.4 + Double(row) * 0.18) + (s.still ? 0 : 1)
            for i in 0..<7 {
                var x = PixelCanvas.mod(Double(i * 29 + row * 17) - t * rs, w)
                if x < 0 { x += w }
                let len = s.still ? 1 : 2 + Double((i + row) % 3) + rough
                let jitter = rough > 1 ? jsRounded(sin(t * 3 + Double(i + row))) : 0
                px.rect(x.rounded(.down), y + jitter, len, 1, wave)
            }
        }
        let bob = jsRounded(sin(t * (1.4 + rough * 0.7)) * (0.5 + rough * 0.5))
        px.sprite(ship, x: 44, y: hz - 14 + bob, shipColors) { col, r, ch in
            ch == "s" && f.sails < 60 && Double((col * 7 + r * 13) % 37) < (60 - f.sails) / 2.2
        }
        if f.moving && !s.still {
            for i in 0..<4 {
                px.rect(66 + Double((i * 5 + Int((t * 8).rounded(.down))) % 10), hz + 3 + Double(i % 2), 2, 1, wave)
            }
        }
        px.air(f.weather.sky, t: t)
    }

    /// The hillside and its seven houses, in port.
    static func town(_ px: PixelCanvas) {
        let hz = horizon
        px.hills(92..<160, base: hz, Color(hex: 0x2F4A35)) { 11 + 7 * sin($0 * 0.09) + 4 * sin($0 * 0.23) }
        for i in 0..<7 {
            let bx = Double(104 + i * 8), bh = Double(3 + (i * 5) % 4)
            px.rect(bx, hz - bh - 1, 5, bh + 1, Color(hex: 0xE9DFC8))
            px.rect(bx, hz - bh - 2, 5, 1, Color(hex: 0x9A3B2E))
        }
    }

    static func label(_ f: SceneFrame) -> String {
        guard f.state != nil else { return "A ship under sail" }
        let w = f.weather.sky == .storm ? "a storm" : f.weather.name.lowercased()
        if f.atPort { return "Ship at anchor below a hillside town" }
        return f.moving ? "Ship sailing in \(w)" : "Ship hove to in \(w)"
    }
}
