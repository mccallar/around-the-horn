import SwiftUI
import HornEngine

/// To the Klondike's scene (docs/journeys/klondike.md §4, §9, §16): a coastal steamer on
/// the Inside Passage, a party hauling a sled over the pass, and a home-built boat on the
/// lakes and the Yukon, under ten skies, over fourteen kinds of country, with every stop
/// drawn as itself. Towns come up on the right as you near them and slide away behind;
/// the sled tarp, the outfit, the sail and the hull show their wear.
enum KlondikeScene {
    static let horizon = 46.0

    enum Leg { case steamer, foot, boat }

    // MARK: Sky

    /// §9's palettes, by the kind of sky: the sky's two ends, the water, the snow, and the
    /// dashes on either.
    struct Palette {
        let top: UInt32, bot: UInt32, water: UInt32, snow: UInt32, accent: UInt32
        var sun: UInt32?
        var clouds = 0
        var cloud: UInt32 = 0xF4F7FA
        var rough = 1.0
        /// How far the far mountains fade into the sky.
        var haze = 0.0
    }

    static func palette(_ w: Weather) -> Palette {
        switch w.sky {
        case .clear:
            return Palette(top: 0x2F63A8, bot: 0xBCDDF0, water: 0x23506E, snow: 0xE9EFF4, accent: 0xFFFFFF, sun: 0xFFF1B8)
        case .breeze:
            return Palette(top: 0x3A6CA6, bot: 0xA9CFE6, water: 0x24557A, snow: 0xDCE5EC, accent: 0xCFE3F0, sun: 0xFFE58A,
                           clouds: 1)
        case .rain:
            return Palette(top: 0x3F4A57, bot: 0x7E8A97, water: 0x22384C, snow: 0x8E9488, accent: 0x93A5B6, clouds: 3,
                           cloud: 0x6B7584, haze: 0.3)
        case .fog:
            return Palette(top: 0x8E979F, bot: 0xC7CDD2, water: 0x5E6E7B, snow: 0xC9CFD4, accent: 0xB7C0C8, haze: 0.65)
        case .snow:
            return Palette(top: 0x5A6573, bot: 0xA9B5C1, water: 0x2B3D50, snow: 0xE4EAF0, accent: 0xF4F7FA, clouds: 3,
                           cloud: 0x8E99A5, haze: 0.35)
        case .dust:
            return Palette(top: 0x6F7E8C, bot: 0xB9C4C9, water: 0x34505E, snow: 0x9DA391, accent: 0xC4CBC0, clouds: 2,
                           cloud: 0x8C969F, haze: 0.2)
        case .gale:
            return Palette(top: 0x354251, bot: 0x6F7E8E, water: 0x1F3346, snow: 0xC8D2DC, accent: 0xE6EDF3, clouds: 3,
                           cloud: 0x56626F, rough: 2, haze: 0.15)
        case .storm:
            return Palette(top: 0x1B2028, bot: 0x4A5360, water: 0x141F2B, snow: 0xB5C0CB, accent: 0xD8E0E8, clouds: 3,
                           cloud: 0x2C333D, rough: 3, haze: 0.7)
        case .still:
            return Palette(top: 0x6C8FB0, bot: 0xC9DDEA, water: 0x3D6378, snow: 0xE0E8EE, accent: 0xF2F7FA)
        case .heat:
            return Palette(top: 0xD98A3D, bot: 0xF4D88C, water: 0x3C6A70, snow: 0xD8D2B8, accent: 0xA9CACC, sun: 0xFFF4C2,
                           haze: 0.15)
        }
    }

    // MARK: Sprites (§4)

    static func grid(_ rows: [String], _ width: Int) -> [[Character]] {
        rows.map { r in
            let a = Array(r)
            return a.count >= width ? Array(a.prefix(width)) : a + Array(repeating: " ", count: width - a.count)
        }
    }

    static let steamer = grid([
        "          oo              ",
        "         ooo     m        ",
        "          o      m        ",
        "         tt      m        ",
        "         ff      m        ",
        "         ff      m        ",
        "    wwwwwffwwwwwwwwww     ",
        "    wpwpwwwwpwpwpwpww     ",
        "  wwwwwwwwwwwwwwwwwwwwww  ",
        "kkkkkkkkkkkkkkkkkkkkkkkkkk",
        " kkkkkkkkkkkkkkkkkkkkkkkk ",
        " yyyyyyyyyyyyyyyyyyyyyyyy ",
        "  kkkkkkkkkkkkkkkkkkkkkk  ",
    ], 26)

    static let steamerColors: [Character: Color] = [
        "k": Color(hex: 0x23262B), "y": Color(hex: 0x9E3B2F), "w": Color(hex: 0xE6E0D0), "p": Color(hex: 0xF2C14E),
        "f": Color(hex: 0xA8452F), "t": Color(hex: 0x23262B), "m": Color(hex: 0x6B4A2B), "o": Color(hex: 0x8F959C),
    ]

    static let party = grid([
        "                 hh       hh   ",
        "                hhff     hhff  ",
        "  llllllll      kpp      kdd   ",
        " llllrlllll     kppp     kddd  ",
        " llllllllll  rr kppppr rrkdddd ",
        " llrllllrlll r   pp       dd   ",
        "ssssssssssssr    pp       dd   ",
        "nnnnnnnnnnnn     p p      d d  ",
        "                b   b    b   b ",
    ], 31)

    /// Rows 7 and 8 the other way, every other step.
    static let stride7 = grid(["nnnnnnnnnnnn      pp       dd   ", "                 b b       b b  "], 31)

    static let partyColors: [Character: Color] = [
        "h": Color(hex: 0x4A3222), "f": Color(hex: 0xE6C29A), "p": Color(hex: 0xB5432F), "d": Color(hex: 0x3B3E4A),
        "k": Color(hex: 0x6E5B3E), "l": Color(hex: 0xCDBE94), "r": Color(hex: 0x7A5A3A), "s": Color(hex: 0x8B6A42),
        "n": Color(hex: 0x2E3036), "b": Color(hex: 0x2A2522),
    ]

    /// The columns of the party sprite that are the sled and its load; the rest are people.
    static let sledColumns = 0..<13

    static let boat = grid([
        "            rr            ",
        "            m             ",
        "       mmmmmmmmmmm        ",
        "       sssssssssss        ",
        "       sssssssssss        ",
        "       sssssssssss        ",
        "       sssssssssss        ",
        "       sssssssssss        ",
        "       sssssssssss        ",
        "  hh        m       hh    ",
        " ohff  gggggmgggg   ff    ",
        "o pp   gggggmggggg  dd    ",
        "owwwwwwwwwwwwwwwwwwwwwwwww",
        " wbbbbbbbbbbbbbbbbbbbbbbw ",
        "  wwwwwwwwwwwwwwwwwwwwww  ",
    ], 26)

    /// A raft: a flat log deck and no pitched seam.
    static let raftBoat = Array(boat.prefix(12)) + grid([
        "owwwwwwwwwwwwwwwwwwwwwwwww",
        "owwwwwwwwwwwwwwwwwwwwwwww ",
        "                          ",
    ], 26)

    static let boatColors: [Character: Color] = [
        "s": Color(hex: 0xE8DFC4), "m": Color(hex: 0x6B4A2B), "r": Color(hex: 0xD64545), "g": Color(hex: 0xB8A77A),
        "o": Color(hex: 0x6B4A2B), "p": Color(hex: 0xB5432F), "d": Color(hex: 0x3B3E4A), "f": Color(hex: 0xE6C29A),
        "h": Color(hex: 0x4A3222), "w": Color(hex: 0x9C7A4E), "b": Color(hex: 0x3A2A1A),
    ]

    /// 1849's torn sails: a pixel goes where `((col*7 + row*13) % 37) < (60 − meter)/2.2`.
    static func torn(_ col: Int, _ row: Int, _ meter: Double) -> Bool {
        meter < 60 && Double((col * 7 + row * 13) % 37) < (60 - meter) / 2.2
    }

    // MARK: Drawing

    /// Everything one frame needs, worked out once.
    struct Scene {
        let px: PixelCanvas
        let f: SceneFrame
        let g: GameState?
        let p: Palette
        let leg: Leg
        let region: RegionID
        let t: Double
        let mile: Int
        let white: Bool

        var hz: Double { horizon }

        /// Where a thing standing at `stopMile` is drawn from: 0 at the stop, to the right
        /// ahead of it and to the left behind, a day's travel being about 100 pixels.
        func dx(_ stopMile: Int) -> Double {
            let perDay: Double
            switch leg {
            case .steamer: perDay = 2200
            case .foot: perDay = 9
            case .boat: perDay = 300
            }
            return jsRounded(Double(stopMile - mile) * 100 / perDay)
        }

        func c(_ hex: UInt32) -> Color { Color(hex: hex) }

        /// A far colour faded toward the sky's foot by the weather.
        func far(_ hex: UInt32, _ more: Double = 0) -> Color { PixelCanvas.mix(hex, p.bot, min(0.9, p.haze + more)) }

        func rect(_ x: Double, _ y: Double, _ w: Double, _ h: Double, _ color: Color) { px.rect(x, y, w, h, color) }
    }

    static func draw(_ px: PixelCanvas, _ f: SceneFrame) {
        let g = f.state
        let reg = f.region ?? KlondikeSkin.journey.regions.first { $0.id == "chilkootSummit" }!
        let leg: Leg
        if let g {
            switch KlondikeSkin.leg(g) {
            case "steamer": leg = .steamer
            case "boat": leg = .boat
            default: leg = .foot
            }
        } else {
            leg = .foot
        }
        let mile = g?.mile ?? KlondikeSkin.journey.stops[5].mile - 6
        let s = Scene(px: px, f: f, g: g, p: palette(f.weather), leg: leg, region: reg.id, t: f.t, mile: mile,
                      white: g.map(KlondikeSkin.onWhitePass) ?? false)
        px.sky(top: s.p.top, bottom: s.p.bot, horizon: s.hz)
        if let sun = s.p.sun { px.sun(x: 123, y: 8, Color(hex: sun)) }
        px.clouds(s.p.clouds * 2, Color(hex: s.p.cloud), t: f.t, drift: f.moving ? 1.6 : 0.4)
        switch leg {
        case .steamer: coast(s)
        case .foot: mountains(s)
        case .boat: riverBanks(s)
        }
        behind(s)
        switch leg {
        case .steamer: sea(s)
        case .foot: snowfield(s)
        case .boat: river(s)
        }
        front(s)
        switch leg {
        case .steamer: drawSteamer(s)
        case .foot: drawParty(s)
        case .boat: drawBoat(s)
        }
        air(s)
    }

    // MARK: The coast, from the steamer

    static func coast(_ s: Scene) {
        let px = s.px, hz = s.hz
        let ox = Double(s.mile) * 0.01 + (s.f.moving ? s.t * 0.8 : 0)
        let scale: Double
        switch s.region {
        case "queenCharlotte": scale = 0.45
        case "alaskaCoast": scale = 1.5
        default: scale = 1
        }
        let range = s.far(0x3B4A52), cap = s.far(0xE8EEF2)
        let start = s.region == "queenCharlotte" ? 90 : 0
        for i in start..<160 {
            let x = Double(i) + ox
            let h = jsRounded((6 + 4 * sin(x * 0.07) + 3 * sin(x * 0.19)) * scale)
            guard h > 0 else { continue }
            px.rect(Double(i), hz - h, 1, h, range)
            if h > 8 { px.rect(Double(i), hz - h, 1, 2, cap) }
            // Alaska's glaciers come down to the water.
            if s.region == "alaskaCoast" && PixelCanvas.mod(x, 47) < 3 && h > 10 {
                px.rect(Double(i), hz - h + 2, 1, h - 3, s.far(0xD8E6EE))
            }
        }
        // Forested islands in the Passage and down the British Columbia coast.
        if s.region == "insidePassage" || s.region == "bcCoast" {
            let isle = s.far(0x2C3F33, 0.1)
            for k in 0..<3 {
                var x0 = PixelCanvas.mod(Double(k * 67) + 20 - ox * 3, 220)
                if x0 < 0 { x0 += 220 }
                x0 -= 30
                let lo = Int(max(0, x0)), hi = Int(min(160, x0 + 34))
                guard lo < hi else { continue }
                px.hills(lo..<hi, base: hz, isle) { x in
                    max(0, 5 - abs(x - x0 - 17) * 0.3)
                }
            }
        }
    }

    static func sea(_ s: Scene) {
        let px = s.px, hz = s.hz
        px.rect(0, hz, px.w, px.h - hz, s.c(s.p.water))
        let spd = s.f.moving ? 14 * s.f.weather.speed + 2 : 1.5
        waves(s, speed: spd, rough: s.p.rough + (s.region == "queenCharlotte" ? 1 : 0))
        if s.f.weather.sky == .still { floes(s, speed: spd) }
    }

    /// 1849's wave dashes, eight rows of them.
    static func waves(_ s: Scene, speed spd: Double, rough: Double, from y0: Double? = nil) {
        let px = s.px, t = s.t
        let wave = s.c(s.p.accent)
        for row in 0..<8 {
            let y = (y0 ?? s.hz + 2) + Double(row * 4)
            let rs = spd * (0.4 + Double(row) * 0.18) + 1
            for i in 0..<7 {
                var x = PixelCanvas.mod(Double(i * 29 + row * 17) - t * rs, px.w)
                if x < 0 { x += px.w }
                let len = 2 + Double((i + row) % 3) + rough
                let jitter = rough > 1 ? jsRounded(sin(t * 3 + Double(i + row))) : 0
                px.rect(x.rounded(.down), y + jitter, len, 1, wave)
            }
        }
    }

    /// Cakes of ice going by with the water.
    static func floes(_ s: Scene, speed: Double) {
        for i in 0..<6 {
            let rs = speed * (0.4 + Double(i) * 0.25) + 1
            var x = PixelCanvas.mod(Double(i * 31 + 7) - s.t * rs, 172)
            if x < 0 { x += 172 }
            s.rect((x - 6).rounded(.down), s.hz + 4 + Double(i * 5), 6, 2, s.c(0xF2F7FA))
        }
    }

    // MARK: The mountains, from the trail

    static func mountains(_ s: Scene) {
        let px = s.px, hz = s.hz
        let ox = Double(s.mile) * 0.6 + (s.f.moving ? s.t * 0.4 : 0)
        let rock = s.far(0x4E5C68), snowcap = s.far(0xF2F5F8)
        let summit = s.region == "chilkootSummit" || s.region == "whitePassSummit"
        let lakes = s.region == "lindeman" || s.region == "logCabin" || s.f.state?.currentStop.id == "bennett" && s.mile >= KlondikeSkin.journey.stops[7].mile
        for i in 0..<160 {
            let x = Double(i) + ox
            var h: Double
            if s.region == "chilkootSummit" {
                h = 20 + 9 * abs(sin(x * 0.08))
            } else if s.region == "whitePassSummit" {
                h = 15 + 6 * abs(sin(x * 0.09)) + 3 * sin(x * 0.23)
            } else {
                h = 14 + 7 * sin(x * 0.05) + 4 * sin(x * 0.17)
                if s.white { h *= 0.85 }
                if lakes { h *= 0.7 }
            }
            h = jsRounded(h)
            px.rect(Double(i), hz - h, 1, h, rock)
            px.rect(Double(i), hz - h, 1, summit ? 6 : 4, snowcap)
        }
        if s.region == "taiya" || s.region == "skagwayValley" || s.region == "lindeman" {
            spruceLine(s, tall: s.region == "lindeman" ? 5 : 7, every: 3, color: s.far(0x1F3A2A, 0.05), snowy: true)
        } else if s.region == "logCabin" {
            spruceLine(s, tall: 3, every: 5, color: s.far(0x2A4430, 0.05), snowy: true)
        }
        if lakes { frozenOrOpenLake(s) }
    }

    /// A line of spruce along the horizon, scrolling a little with the ground.
    static func spruceLine(_ s: Scene, tall: Int, every: Int, color: Color, snowy: Bool, base: Double? = nil,
                           speed: Double = 0)
    {
        let px = s.px, by = base ?? s.hz
        let off = Double(s.mile) * (s.leg == .foot ? 1.5 : 0.1) + s.t * speed
        // Snow sits on the trees from the first fall to break-up.
        let snowOn = snowy && !(6...8).contains(s.g?.month ?? 2)
        let frost = s.c(0xE8EEF2).opacity(0.8)
        var i = -every
        while i < 164 {
            let k = Int(PixelCanvas.mod(Double(i) + off, 997))
            let seed = abs(k / max(1, every))
            let h = Double(max(2, tall - 2 + seed % 5))
            let x = Double(i) - PixelCanvas.mod(off, Double(every))
            tree(px, x: x, base: by, height: h, color)
            if snowOn { px.rect(x, by - h, 1, 1, frost) }
            i += every
        }
    }

    /// A spruce: a narrow spire, wider toward its foot.
    static func tree(_ px: PixelCanvas, x: Double, base: Double, height h: Double, _ color: Color) {
        let n = max(0, Int(h))
        for r in 0..<n {
            let half = Double(r / 3)
            px.rect(x - half, base - h + Double(r), 1 + 2 * half, 1, color)
        }
    }

    /// The lakes beyond the trail: frozen white, or open water once summer comes.
    static func frozenOrOpenLake(_ s: Scene) {
        let frozen: Bool
        if let g = s.g {
            frozen = s.f.state?.currentStop.id == "bennett" && s.mile == KlondikeSkin.journey.stops[7].mile
                ? !KlondikeSkin.iceOut(g) : !(5...9).contains(g.month)
        } else {
            frozen = true
        }
        let y = s.hz
        if frozen {
            s.rect(0, y, 160, 5, PixelCanvas.mix(0xE8F0F5, s.p.snow, 0.3))
            for i in stride(from: 3, to: 160, by: 11) { s.rect(Double(i), y + 2, 4, 1, s.c(0xC9D8E2)) }
        } else {
            s.rect(0, y, 160, 5, s.c(s.p.water))
            for i in stride(from: 5, to: 160, by: 13) {
                s.rect(PixelCanvas.mod(Double(i) - s.t * 2, 160), y + 1 + Double(i % 3), 3, 1, s.c(s.p.accent))
            }
        }
        s.rect(0, y + 5, 160, 1, s.c(0x6E7A82).opacity(0.5))
    }

    static func snowfield(_ s: Scene) {
        let px = s.px, t = s.t
        let lakes = s.region == "lindeman" || s.region == "logCabin" || s.f.state?.currentStop.id == "bennett" && s.mile >= KlondikeSkin.journey.stops[7].mile
        let top = lakes ? s.hz + 6 : s.hz
        px.rect(0, top, px.w, px.h - top, s.c(s.p.snow))
        let rough = s.p.rough
        let moving = s.f.moving
        let spd = moving ? (14 * s.f.weather.speed + 2) * 0.25 : 0
        let dash = s.c(s.p.accent)
        for row in 0..<8 {
            let y = s.hz + 2 + Double(row * 4)
            guard y > top else { continue }
            let rs = spd * (0.4 + Double(row) * 0.18) + (moving ? 0.25 : 0)
            for i in 0..<7 {
                var x = PixelCanvas.mod(Double(i * 29 + row * 17) - t * rs, px.w)
                if x < 0 { x += px.w }
                let jitter = rough > 1 ? jsRounded(sin(t * 3 + Double(i + row))) : 0
                px.rect(x.rounded(.down), y + jitter, 2 + Double((i + row) % 3), 1, dash)
            }
        }
        // The Skagway valley's wagon road.
        if s.region == "skagwayValley" {
            px.rect(0, s.hz + 12, px.w, 2, PixelCanvas.mix(0x6E5A44, s.p.snow, 0.45))
        }
        // Rock through the snow on the White Pass.
        if s.region == "whitePassSummit" {
            for i in 0..<6 {
                let x = PixelCanvas.mod(Double(i * 37 + 11) - (moving ? t * spd : 0) - Double(s.mile) * 3, 172) - 6
                let y = s.hz + 3 + Double((i * 7) % 18)
                px.rect(x.rounded(.down), y, 5, 2, s.c(0x6B6E72))
                px.rect(x.rounded(.down) + 1, y - 1, 3, 1, s.c(0x85888C))
            }
        }
        // Trail poles every 24 pixels, going by with the ground.
        let pole = s.c(0x3A2A1A)
        let gs = spd * (0.4 + 2 * 0.18) + (moving ? 0.25 : 0)
        for i in 0..<8 {
            var x = PixelCanvas.mod(Double(i * 24) - t * gs - Double(s.mile) * 2, 192)
            if x < 0 { x += 192 }
            px.rect((x - 16).rounded(.down), s.hz + 4, 1, 5, pole)
        }
    }

    // MARK: The river, from the boat

    static func riverBanks(_ s: Scene) {
        let px = s.px, hz = s.hz
        let ox = Double(s.mile) * 0.05 + (s.f.moving ? s.t * 0.5 : 0)
        switch s.region {
        case "upperLakes":
            let rock = s.far(0x56636E), cap = s.far(0xF2F5F8)
            for i in 0..<160 {
                let x = Double(i) + ox
                let h = jsRounded(13 + 6 * sin(x * 0.04) + 3 * sin(x * 0.13))
                px.rect(Double(i), hz - h, 1, h, rock)
                px.rect(Double(i), hz - h, 1, 3, cap)
            }
        case "laberge":
            let hill = s.far(0x8D8C84)
            px.hills(0..<160, base: hz, hill) { 9 + 5 * sin(($0 + ox) * 0.06) + 2 * sin(($0 + ox) * 0.2) }
        case "yukon":
            let hill = s.far(0x4C5A4A)
            px.hills(0..<160, base: hz, hill) { 8 + 4 * sin(($0 + ox) * 0.05) + 2 * sin(($0 + ox) * 0.21) }
        default:
            break
        }
        let spd = s.f.moving ? 10 * s.f.weather.speed + 3 : 3
        let lake = s.region == "upperLakes" || s.region == "laberge"
        if s.region == "yukon" || s.region == "fiftyMile" {
            // The cutbank under the trees.
            px.rect(0, hz - 2, 160, 2, s.far(0xB59A6A, 0.1))
            spruceLine(s, tall: s.region == "fiftyMile" ? 9 : 7, every: 3, color: s.far(0x1F3A2A), snowy: false, base: hz - 2,
                       speed: spd * 0.3)
        } else {
            spruceLine(s, tall: lake ? 4 : 7, every: 3, color: s.far(0x1F3A2A, 0.05), snowy: false, speed: spd * 0.3)
        }
    }

    static func river(_ s: Scene) {
        let px = s.px, hz = s.hz
        if let g = s.g, g.mile == KlondikeSkin.journey.stops[7].mile, !KlondikeSkin.iceOut(g) {
            // A boat built at Bennett before break-up waits on the ice: white from shore to
            // shore, with a few grey cracks.
            s.rect(0, hz, px.w, px.h - hz, PixelCanvas.mix(0xE8F0F5, s.p.snow, 0.3))
            for i in stride(from: 3, to: 160, by: 11) { s.rect(Double(i), hz + 3 + Double(i % 4) * 4, 5, 1, s.c(0xC9D8E2)) }
        } else {
            let water = PixelCanvas.mix(s.p.water, 0x2E5A4E, 0.5)
            px.rect(0, hz, px.w, px.h - hz, water)
            let spd = s.f.moving ? 10 * s.f.weather.speed + 3 : 3
            waves(s, speed: spd, rough: s.p.rough)
            if s.f.weather.sky == .still { floes(s, speed: spd) }
        }
        // The near bank.
        let pulledIn = !s.f.moving || (s.g.map(Klondike.givenOut) ?? false)
        let top = pulledIn ? 74.0 : 78.0
        px.rect(0, top, px.w, px.h - top, s.c(0x6B5A3A))
        if pulledIn {
            for i in stride(from: 2, to: 160, by: 7) { px.rect(Double(i), top + 1 + Double(i % 3), 2, 1, s.c(0x8A7A5A)) }
        }
    }

    // MARK: Places

    /// Whatever stands at a stop and behind the horizon line: hills, a town's far side.
    static func behind(_ s: Scene) {
        let stops = KlondikeSkin.journey.stops
        func near(_ id: String) -> Double? {
            guard let st = stops.first(where: { $0.id == id }) else { return nil }
            let d = s.dx(st.mile)
            return abs(d) < 230 ? d : nil
        }
        if let d = near("seattle") { seattleHills(s, d) }
        if let d = near("juneau") { juneauHills(s, d) }
        if let d = near("lynn"), s.leg == .steamer { fjord(s, d) }
        if s.leg == .foot, s.region == "chilkootSummit", s.g?.over != true {
            let d = s.dx(11360)
            if abs(d) < 230 { goldenStairs(s, d) }
        }
        if let d = near("canyon"), s.leg == .boat { canyonWalls(s, d) }
        if let d = near("selkirk"), s.leg == .boat { selkirkBench(s, d) }
        if let d = near("dawson"), s.leg == .boat { dawsonHill(s, d) }
    }

    /// Whatever stands on the near side of the horizon: tents, buildings, the frames of boats.
    static func front(_ s: Scene) {
        let stops = KlondikeSkin.journey.stops
        func near(_ id: String) -> Double? {
            guard let st = stops.first(where: { $0.id == id }) else { return nil }
            let d = s.dx(st.mile)
            return abs(d) < 230 ? d : nil
        }
        if let d = near("seattle"), s.leg == .steamer { wharf(s, d, crowd: true) }
        if let d = near("juneau"), s.leg == .steamer { wharf(s, d, crowd: false) }
        if let d = near("landing"), s.leg == .foot { s.white ? skagway(s, d) : dyea(s, d) }
        if let d = near("camp"), s.leg == .foot { s.white ? whitePassCity(s, d) : sheepCamp(s, d) }
        if let d = near("summit"), s.leg == .foot { s.white ? whitePassSummit(s, d) : chilkootSummit(s, d) }
        if let d = near("lakes"), s.leg == .foot { s.white ? logCabin(s, d) : lindeman(s, d) }
        if let d = near("bennett") { bennett(s, d) }
        if let d = near("tagish"), s.leg == .boat { tagish(s, d) }
        if let d = near("canyon"), s.leg == .boat { canyonWater(s, d) }
        if let d = near("fivefinger"), s.leg == .boat { fiveFingers(s, d) }
        if let d = near("selkirk"), s.leg == .boat { selkirk(s, d) }
        if let d = near("dawson"), s.leg == .boat { dawson(s, d) }
    }

    // Small pieces.

    /// §16's tent: a 6×4 triangle-roofed block, a stovepipe, and a puff of smoke.
    static func tent(_ s: Scene, _ x: Double, _ y: Double, smoke: Bool = true) {
        let canvas = s.c(0xE9E3D2)
        s.rect(x + 2, y, 2, 1, canvas)
        s.rect(x + 1, y + 1, 4, 1, canvas)
        s.rect(x, y + 2, 6, 2, canvas)
        s.rect(x + 2, y + 3, 1, 1, s.c(0x6E6458))
        s.rect(x + 4, y - 2, 1, 3, s.c(0x555555))
        if smoke {
            let k = PixelCanvas.mod(s.t * 2 + x, 4).rounded(.down)
            s.rect(x + 4 - (k > 1 ? 1 : 0), y - 3 - k, 1, 1, s.c(0xC8CCD0).opacity(0.85))
        }
    }

    /// A log building: walls, darker courses, a roof line, a door.
    static func cabin(_ s: Scene, _ x: Double, _ y: Double, _ w: Double, _ h: Double, roof: UInt32 = 0x4A3222) {
        s.rect(x, y, w, h, s.c(0x6B4A2B))
        for r in stride(from: 1.0, to: h, by: 2) { s.rect(x, y + r, w, 1, s.c(0x5A3D24)) }
        s.rect(x - 1, y - 1, w + 2, 1, s.c(roof))
        s.rect(x + 1, y - 2, w - 2, 1, s.c(roof))
        s.rect(x + (w / 2).rounded(.down), y + h - 3, 2, 3, s.c(0x2A1E14))
    }

    /// A false-fronted store with two lit windows.
    static func storefront(_ s: Scene, _ x: Double, _ y: Double, _ w: Double, _ h: Double, _ wood: UInt32) {
        s.rect(x, y, w, h, s.c(wood))
        s.rect(x, y - 2, w, 2, PixelCanvas.mix(wood, 0x2A1E14, 0.35))
        s.rect(x + 1, y + 2, 2, 2, s.c(0xF2C14E))
        s.rect(x + w - 3, y + 2, 2, 2, s.c(0xF2C14E))
        s.rect(x + (w / 2).rounded(.down) - 1, y + h - 3, 2, 3, s.c(0x2A1E14))
    }

    /// A flag on a pole: the red ensign at the border posts, its corner fluttering.
    static func flag(_ s: Scene, _ x: Double, _ base: Double, height: Double = 12, red: UInt32 = 0xC8102E) {
        s.rect(x, base - height, 1, height, s.c(0x8F8A7A))
        let lift = Int((s.t * 2).rounded(.down)) % 2 == 0 ? 0.0 : 1.0
        s.rect(x + 1, base - height, 5, 3, s.c(red))
        s.rect(x + 1, base - height, 2, 2, s.c(0x2B3F7A))
        s.rect(x + 2, base - height, 1, 1, s.c(0xE8E8E8))
        s.rect(x + 1, base - height + 1, 1, 1, s.c(0xE8E8E8))
        s.rect(x + 6, base - height + lift, 1, 2, s.c(red))
    }

    /// Somebody standing about: a head and a coat.
    static func person(_ s: Scene, _ x: Double, _ y: Double, coat: UInt32) {
        s.rect(x, y, 1, 1, s.c(0xE6C29A))
        s.rect(x, y + 1, 1, 2, s.c(coat))
    }

    /// Crates and sacks of somebody's outfit, stacked.
    static func goods(_ s: Scene, _ x: Double, _ y: Double) {
        s.rect(x, y, 3, 2, s.c(0x8B6A42))
        s.rect(x + 3, y + 1, 2, 1, s.c(0xCDBE94))
        s.rect(x + 1, y - 1, 2, 1, s.c(0xA8845A))
    }

    /// The ribs of a boat on the stocks.
    static func frame(_ s: Scene, _ x: Double, _ y: Double) {
        let rib = s.c(0x9C7A4E)
        s.rect(x, y + 4, 12, 1, rib)
        for k in 0..<5 {
            let rx = x + 1 + Double(k * 2) + (k > 2 ? 1 : 0)
            let h = 4 - abs(Double(k) - 2) * 0.5
            s.rect(rx, y + 4 - h.rounded(.down), 1, h.rounded(.down), rib)
        }
        s.rect(x - 1, y + 5, 2, 1, s.c(0x6B4A2B))
        s.rect(x + 11, y + 5, 2, 1, s.c(0x6B4A2B))
    }

    static func tentCity(_ s: Scene, _ x0: Double, count: Int = 7, y: Double? = nil) {
        let base = y ?? s.hz - 2
        for i in 0..<count {
            let x = x0 + Double(i * 9)
            let up = Double((i * 3) % 4)
            tent(s, x, base - up)
        }
    }

    // Seattle.

    static func seattleHills(_ s: Scene, _ d: Double) {
        let px = s.px, hz = s.hz
        // Gone astern within the first day out.
        let lo = Int(max(0, 84 + d)), hi = Int(min(160, 160 + d))
        guard lo < hi, d > -120 else { return }
        px.hills(lo..<hi, base: hz, s.far(0x3E5242)) { x in 10 + 6 * sin((x - d) * 0.08) + 3 * sin((x - d) * 0.2) }
        for i in 0..<9 {
            let bx = 92 + d + Double(i * 8), bh = Double(3 + (i * 5) % 4)
            let ground = jsRounded(10 + 6 * sin((bx + 2 - d) * 0.08) + 3 * sin((bx + 2 - d) * 0.2))
            s.rect(bx, hz - ground - bh + 2, 5, bh, s.c(0xE9DFC8))
            s.rect(bx, hz - ground - bh + 1, 5, 1, s.c(0x9A3B2E))
        }
        // A church spire above the roofs.
        s.rect(124 + d, hz - 24, 1, 6, s.c(0xE9DFC8))
    }

    static func wharf(_ s: Scene, _ d: Double, crowd: Bool) {
        let x0 = 76 + d
        s.rect(x0, s.hz - 1, 90, 2, s.c(0x5A4030))
        for k in stride(from: 0.0, to: 90, by: 6) { s.rect(x0 + k, s.hz + 1, 1, 3, s.c(0x3A2A1A)) }
        if crowd {
            for k in 0..<8 { person(s, x0 + 8 + Double(k * 4) + Double(k % 2), s.hz - 4, coat: k % 3 == 0 ? 0xB5432F : 0x3B3E4A) }
        }
        if s.f.atPort && s.leg == .steamer && abs(d) < 1 {
            // The gangway down to the wharf.
            s.px.line(from: (66, s.hz - 3), to: (x0, s.hz - 1), s.c(0x8B6A42))
        }
    }

    // Juneau: 1849's hillside town, under its mountain.

    static func juneauHills(_ s: Scene, _ d: Double) {
        let px = s.px, hz = s.hz
        let lo = Int(max(0, 92 + d)), hi = Int(min(160, 175 + d))
        guard lo < hi else { return }
        let rock = s.far(0x46545C), cap = s.far(0xE8EEF2)
        for i in lo..<hi {
            let off: Double = abs(Double(i) - d - 132)
            let h = jsRounded(max(0, 34 - off * 0.9))
            guard h > 0 else { continue }
            px.rect(Double(i), hz - h, 1, h, rock)
            if h > 18 { px.rect(Double(i), hz - h, 1, h - 18, cap) }
        }
        px.hills(lo..<hi, base: hz, s.c(0x2F4A35)) { x in
            let u: Double = x - d
            return 11 + 7 * sin(u * 0.09) + 4 * sin(u * 0.23)
        }
        for i in 0..<7 {
            let bx = 104 + d + Double(i * 8), bh = Double(3 + (i * 5) % 4)
            s.rect(bx, hz - bh - 1, 5, bh + 1, s.c(0xE9DFC8))
            s.rect(bx, hz - bh - 2, 5, 1, s.c(0x9A3B2E))
        }
    }

    // The head of Lynn Canal: mountains straight up into the cloud on either hand. Coming
    // up the canal the left-hand wall is a peak ahead, not a cliff over everything astern.

    static func fjord(_ s: Scene, _ d: Double) {
        let px = s.px, hz = s.hz
        let wall = s.far(0x3B4A52, -0.1), streak = s.far(0xE8EEF2)
        // Rising out of the sea over the last day's steaming.
        let rise = min(1, max(0, (60 - d) / 60))
        guard rise > 0 else { return }
        for i in 0..<160 {
            let x = Double(i) - d
            let left = (48 - abs(x) * 1.4) * rise, right = (x - 112) * 1.3 * rise
            let h = jsRounded(min(hz, max(0, max(left, right))))
            guard h > 0 else { continue }
            px.rect(Double(i), hz - h, 1, h, wall)
            if Int(x) % 9 < 2 { px.rect(Double(i), hz - h + 3, 1, max(0, h - 10), streak) }
        }
        // The cloud the walls go up into.
        px.rect(0, 7, 160, 7, s.c(0xC9CED4).opacity(0.75 * rise))
        px.rect(10, 5, 60, 2, s.c(0xC9CED4).opacity(0.6 * rise))
    }

    // The landing: Dyea's tent flats, Skagway's false fronts.

    static func dyea(_ s: Scene, _ d: Double) {
        // Lynn Canal behind, the tide flats grey in front of the tents.
        s.rect(0 + d, s.hz - 2, 70, 2, s.c(s.p.water))
        s.rect(80 + d, s.hz + 1, 90, 3, PixelCanvas.mix(0x8A8470, s.p.snow, 0.35))
        tentCity(s, 98 + d, count: 7, y: s.hz - 3)
        for k in 0..<5 { goods(s, 84 + d + Double(k * 15), s.hz + 6 + Double(k % 2) * 3) }
        // A lighter left on the flats.
        s.rect(84 + d, s.hz + 2, 10, 2, s.c(0x4A3A2A))
        s.rect(85 + d, s.hz + 4, 8, 1, s.c(0x3A2A1A))
    }

    static func skagway(_ s: Scene, _ d: Double) {
        // The long wharf out into the canal, and the muddy street.
        s.rect(0 + d, s.hz - 2, 70, 2, s.c(s.p.water))
        s.rect(4 + d, s.hz - 3, 60, 1, s.c(0x5A4030))
        s.rect(90 + d, s.hz + 1, 80, 3, PixelCanvas.mix(0x6E5A44, s.p.snow, 0.4))
        let woods: [UInt32] = [0x8C6A48, 0xA8845A, 0x6E5A44, 0x9A7A56, 0x7E6448]
        for i in 0..<5 {
            let w = Double(9 + i % 2 * 2), h = Double(8 + (i * 3) % 5)
            storefront(s, 96 + d + Double(i * 12), s.hz - h + 1, w, h, woods[i])
        }
        tent(s, 154 + d, s.hz - 3)
    }

    // The camps below the summit.

    static func sheepCamp(_ s: Scene, _ d: Double) {
        let green = s.c(0x1F3A2A)
        for k in 0..<5 { tree(s.px, x: 92 + d + Double(k * 15), base: s.hz + 1, height: Double(8 + (k * 3) % 4), green) }
        tentCity(s, 96 + d, count: 7, y: s.hz - 1)
        for k in 0..<4 { goods(s, 90 + d + Double(k * 17), s.hz + 6 + Double(k % 2) * 2) }
    }

    static func whitePassCity(_ s: Scene, _ d: Double) {
        for k in 0..<3 { cabin(s, 98 + d + Double(k * 16), s.hz - 5, 9, 6) }
        for k in 0..<4 { tent(s, 106 + d + Double(k * 16), s.hz - 1) }
        // Where the wagon road gives out.
        s.rect(60 + d, s.hz + 12, 40, 2, PixelCanvas.mix(0x6E5A44, s.p.snow, 0.45))
    }

    // The summit: the Golden Stairs below it, the border at the top.

    static func goldenStairs(_ s: Scene, _ d: Double) {
        let px = s.px, hz = s.hz
        let lo = Int(max(0, 96 + d)), hi = Int(min(160, 200 + d))
        guard lo < hi else { return }
        let slope = PixelCanvas.mix(0xF2F5F8, s.p.snow, 0.4)
        px.hills(lo..<hi, base: hz + 3, slope) { x in min(hz - 2, (x - 96 - d) * 0.7) }
        // The line of climbers, one step at a time.
        let climb = (s.t * 0.8).rounded(.down)
        for k in 0..<14 {
            let along = PixelCanvas.mod(Double(k * 5) + climb, 70)
            let x = 98 + d + along
            guard x >= 0 && x < 160 else { continue }
            let y = hz + 3 - min(hz - 2, along * 0.7) - 2
            s.rect(x, y, 1, 2, s.c(0x2A2522))
        }
        // The Scales at the foot: outfits waiting to be weighed.
        for k in 0..<3 { goods(s, 90 + d + Double(k * 5), hz + 4) }
    }

    static func chilkootSummit(_ s: Scene, _ d: Double) {
        // A log hut half buried in snow, the flag, and the police.
        cabin(s, 112 + d, s.hz - 4, 13, 6)
        s.rect(108 + d, s.hz - 1, 22, 3, s.c(s.p.snow))
        s.rect(110 + d, s.hz - 2, 18, 1, s.c(s.p.snow))
        flag(s, 132 + d, s.hz)
        person(s, 128 + d, s.hz - 3, coat: 0x3A2A1E)
        s.rect(127 + d, s.hz - 1, 3, 1, s.c(0x3A2A1E))
        // The scale, and the outfits waiting for it.
        s.rect(140 + d, s.hz - 6, 1, 6, s.c(0x6B4A2B))
        s.rect(138 + d, s.hz - 6, 5, 1, s.c(0x6B4A2B))
        s.rect(138 + d, s.hz - 4, 1, 2, s.c(0x8F8A7A))
        for k in 0..<3 { goods(s, 144 + d + Double(k * 5), s.hz + 2 + Double(k % 2)) }
    }

    static func whitePassSummit(_ s: Scene, _ d: Double) {
        for k in 0..<3 { tent(s, 112 + d + Double(k * 8), s.hz - 2 - Double(k % 2)) }
        flag(s, 140 + d, s.hz)
        person(s, 136 + d, s.hz - 3, coat: 0x3A2A1E)
        for k in 0..<3 { goods(s, 146 + d + Double(k * 4), s.hz + 2) }
    }

    // The lakes: Lindeman's whipsaws, Log Cabin's huts.

    static func lindeman(_ s: Scene, _ d: Double) {
        tentCity(s, 102 + d, count: 6, y: s.hz - 3)
        // A whipsaw pit: a log up on a frame, one sawyer above and one below.
        let wood = s.c(0x6B4A2B)
        s.px.line(from: (88 + d, s.hz + 10), to: (92 + d, s.hz + 2), wood)
        s.px.line(from: (100 + d, s.hz + 10), to: (96 + d, s.hz + 2), wood)
        s.rect(86 + d, s.hz + 2, 16, 2, s.c(0x8B6A42))
        person(s, 93 + d, s.hz - 1, coat: 0xB5432F)
        person(s, 94 + d, s.hz + 5, coat: 0x3B3E4A)
        let saw = (Int((s.t * 3).rounded(.down)) % 2 == 0) ? 0.0 : 1.0
        s.rect(94 + d, s.hz + 1 + saw, 1, 4, s.c(0xA0A4A8))
    }

    static func logCabin(_ s: Scene, _ d: Double) {
        let pine = s.c(0x2A4430)
        for k in 0..<4 { tree(s.px, x: 96 + d + Double(k * 17), base: s.hz + 2, height: Double(4 + k % 2), pine) }
        for k in 0..<3 { cabin(s, 100 + d + Double(k * 17), s.hz - 3, 7, 4) }
    }

    // Lake Bennett: the tent city, boats on the stocks, the lake frozen or full of sails.

    static func bennett(_ s: Scene, _ d: Double) {
        guard abs(d) < 200 else { return }
        tentCity(s, 98 + d, count: 7, y: s.hz - 3)
        let built = s.g.map(Klondike.hasBoat) ?? false
        let frames = built ? 3 : 4
        for k in 0..<frames {
            let x = 2 + d + Double(k * 9)
            frame(s, x, s.leg == .boat ? s.hz - 8 : s.hz + 8 + Double(k % 2) * 3)
        }
        if s.leg == .boat, let g = s.g, KlondikeSkin.iceOut(g) {
            // The lake full of sails, going north.
            for k in 0..<6 {
                var x = PixelCanvas.mod(Double(k * 27) + s.t * 1.5, 170)
                if x < 0 { x += 170 }
                s.rect(x - 5, s.hz + 1 + Double(k % 3), 2, 3, s.c(0xE8DFC4))
                s.rect(x - 6, s.hz + 4 + Double(k % 3), 4, 1, s.c(0x6B4A2B))
            }
        }
    }

    // The river's stops.

    static func tagish(_ s: Scene, _ d: Double) {
        cabin(s, 110 + d, s.hz - 6, 16, 6)
        flag(s, 130 + d, s.hz - 1, height: 14)
        person(s, 106 + d, s.hz - 3, coat: 0xB5432F)
        // Boats tied up waiting to be numbered.
        for k in 0..<3 {
            s.rect(92 + d + Double(k * 9), s.hz + 1, 7, 2, s.c(0x9C7A4E))
            s.rect(95 + d + Double(k * 9), s.hz - 3, 1, 4, s.c(0x6B4A2B))
        }
    }

    /// Where the slot runs, from the stop: ahead of the boat on the morning she reaches it
    /// (not across the upper lakes), around her at it, and behind her within the day, before
    /// Lake Laberge opens out.
    static let canyonSpan = (from: 20.0, to: 90.0, ahead: 60.0)

    static func canyonWalls(_ s: Scene, _ d: Double) {
        let px = s.px
        let rock = s.c(0x2B2B30), lit = s.c(0x4A4A52)
        let lo = Int(max(0, d + canyonSpan.from)), hi = Int(min(160, d + canyonSpan.to))
        guard lo < hi, d < canyonSpan.ahead else { return }
        for i in lo..<hi {
            let x = Double(i) - d
            let h = jsRounded(26 + 4 * sin(x * 0.3) + 2 * sin(x * 0.9))
            px.rect(Double(i), s.hz - h, 1, h + 2, rock)
            if Int(x) % 6 == 0 { px.rect(Double(i), s.hz - h + 2, 1, h - 6, lit) }
        }
        // Spruce along the rim.
        for k in stride(from: lo, to: hi, by: 5) {
            let x = Double(k) - d
            let h = jsRounded(26 + 4 * sin(x * 0.3) + 2 * sin(x * 0.9))
            tree(px, x: Double(k), base: s.hz - h, height: 4, s.c(0x1F3A2A))
        }
    }

    static func canyonWater(_ s: Scene, _ d: Double) {
        let px = s.px
        let lo = max(0, d + canyonSpan.from), hi = min(160, d + canyonSpan.to)
        guard lo < hi, d < canyonSpan.ahead else { return }
        // White water the length of the slot, and the near wall's foot.
        let foam = s.c(0xEEF3F5)
        for k in 0..<22 {
            var x = PixelCanvas.mod(Double(k * 23) - s.t * 40, hi - lo + 10) + lo
            if x < lo { x += hi - lo }
            px.rect(x.rounded(.down), s.hz + 1 + Double((k * 5) % 24), 3 + Double(k % 3), 1, foam)
        }
        px.rect(lo, 75, hi - lo, 5, s.c(0x2B2B30))
        px.rect(lo, 74, hi - lo, 1, s.c(0x4A4A52))
    }

    static func fiveFingers(_ s: Scene, _ d: Double) {
        for k in 0..<4 {
            let x = 96 + d + Double(k * 15), h = Double(18 + (k * 5) % 7)
            s.rect(x, s.hz - h, 7, h + 2, s.c(0x4A4038))
            s.rect(x + 1, s.hz - h + 1, 1, h - 2, s.c(0x6A5E52))
            tree(s.px, x: x + 2, base: s.hz - h, height: 4, s.c(0x1F3A2A))
            tree(s.px, x: x + 5, base: s.hz - h, height: 3, s.c(0x1F3A2A))
            // The water piling white between them.
            let surge = PixelCanvas.mod(s.t * 6 + Double(k * 2), 4).rounded(.down)
            s.rect(x + 7, s.hz + 1 + surge, 8, 1, s.c(0xEEF3F5))
            s.rect(x - 1, s.hz + 2, 9, 1, s.c(0xEEF3F5))
        }
    }

    static func selkirkBench(_ s: Scene, _ d: Double) {
        // The flat above the river, and the Pelly coming in from the east.
        s.rect(78 + d, s.hz - 6, 100, 6, s.far(0x6E7350))
        s.rect(78 + d, s.hz - 7, 100, 1, s.far(0x8A8A5E))
        s.rect(96 + d, s.hz - 6, 5, 6, PixelCanvas.mix(s.p.water, 0x2E5A4E, 0.5))
    }

    static func selkirk(_ s: Scene, _ d: Double) {
        cabin(s, 110 + d, s.hz - 13, 16, 7)
        s.rect(112 + d, s.hz - 15, 12, 1, s.c(0xE9DFC8))
        for k in 0..<3 { cabin(s, 130 + d + Double(k * 9), s.hz - 11, 6, 5) }
        tent(s, 102 + d, s.hz - 10)
        flag(s, 106 + d, s.hz - 6, height: 12, red: 0xB5432F)
    }

    static func dawsonHill(_ s: Scene, _ d: Double) {
        let px = s.px, hz = s.hz
        let lo = Int(max(0, 40 + d)), hi = Int(min(160, 230 + d))
        guard lo < hi else { return }
        px.hills(lo..<hi, base: hz, s.far(0x3E4A3A)) { x in 22 + 6 * sin((x - d) * 0.05) + 2 * sin((x - d) * 0.3) }
        // The old slide's scar on the hill behind the town.
        for r in 0..<14 {
            let w = Double(2 + r / 2)
            px.rect(132 + d - w / 2, hz - 30 + Double(r), w, 1, s.far(0xA59C88))
        }
    }

    static func dawson(_ s: Scene, _ d: Double) {
        let lumber: [UInt32] = [0xC9A06A, 0xB08850, 0xD8B47E]
        for i in 0..<8 {
            let x = 56 + d + Double(i * 13), h = Double(6 + (i * 5) % 5)
            if i % 3 == 1 {
                tent(s, x, s.hz - 5)
            } else {
                storefront(s, x, s.hz - h, 9, h, lumber[i % 3])
            }
        }
        // Boats along the bank, three deep.
        for row in 0..<3 {
            for k in 0..<12 {
                let x = 38 + d + Double(k * 10) + Double(row * 4)
                let y = s.hz + 1 + Double(row * 2)
                s.rect(x, y, 7, 2, s.c(row == 1 ? 0x8C6A42 : 0x9C7A4E))
                s.rect(x + 3, y - 3, 1, 3, s.c(0x6B4A2B))
            }
        }
    }

    // MARK: The steamer, the party and the boat

    static func drawSteamer(_ s: Scene) {
        let hz = s.hz, t = s.t
        let rough = s.p.rough + (s.region == "queenCharlotte" ? 1 : 0)
        let docked = s.f.atPort
        let bob = docked ? 0 : jsRounded(sin(t * (1.4 + rough * 0.7)) * (0.5 + rough * 0.5))
        let top = hz - 9 + bob
        // Smoke streams back from the funnel (rises straight at the wharf).
        s.px.sprite(Array(steamer.dropFirst(3)), x: 44, y: top + 3, steamerColors)
        let smoke = s.c(0x8F959C)
        for k in 0..<4 {
            let age = PixelCanvas.mod(t * 2.5 + Double(k) * 5, 20)
            let x = docked ? 54 + jsRounded(sin(t + Double(k))) : 54 - age
            let y = top + 2 - (docked ? age * 0.6 : age * 0.25)
            s.rect(x.rounded(.down), y.rounded(.down), 2 + (age > 10 ? 1 : 0), 1, smoke.opacity(1 - age / 25))
        }
        if s.f.moving {
            let wave = s.c(s.p.accent)
            for i in 0..<5 {
                s.rect(70 + Double((i * 5 + Int((t * 8).rounded(.down))) % 12), hz + 3 + Double(i % 2), 2, 1, wave)
            }
        }
    }

    /// The party and its sled, worn as the meters say; or, the trek over, what is left.
    static func drawParty(_ s: Scene) {
        let px = s.px, hz = s.hz, t = s.t
        let g = s.g
        let sails = s.f.sails, hull = s.f.hull
        let over = g?.over ?? false
        let givenOut = g.map(Klondike.givenOut) ?? false
        let ruined = over && hull < 0.5
        let turnedBack = over && !ruined && g?.currentStop.id == "summit" && (g?.crew.first?.alive ?? false)
        let walking = s.f.moving && !givenOut && !over
        var rows = party
        if walking && Int((t / 0.35).rounded(.down)) % 2 == 1 {
            rows[7] = stride7[0]
            rows[8] = stride7[1]
        }
        let x = 40.0, y = hz + 2
        let inTown = s.f.atPort
        // Your own camp, pitched off the trail.
        if !s.f.moving && !inTown && !over {
            tent(s, 80, hz + 1, smoke: (g?.water ?? 1) > 0)
        }
        if turnedBack {
            // Facing home, down the pass.
            px.sprite(rows.map { Array($0.reversed()) }, x: x, y: y, partyColors)
            return
        }
        if ruined {
            // No load left on the sled: split sacks and flour in the snow.
            px.sprite(rows, x: x, y: y, partyColors) { col, _, ch in ch == "l" || ch == "r" && sledColumns.contains(col) }
            for k in 0..<9 {
                s.rect(x - 24 + Double(k * 4), hz + 8 + Double(k % 3), 2, 1, s.c(0xF2EEE2))
                if k % 3 == 0 { s.rect(x - 22 + Double(k * 4), hz + 6, 3, 2, s.c(0xCDBE94)) }
            }
            return
        }
        // In town the sled is left at the edge and the party walks in among the tents.
        let people = sledColumns.upperBound
        px.sprite(rows, x: x, y: y, partyColors) { col, row, ch in
            if inTown && col >= people { return true }
            if givenOut && ch == "n" && col % 3 == 0 { return true }
            if givenOut && row == 6 && col < 5 { return true }
            return (ch == "l" || ch == "s") && torn(col, row, sails)
        }
        if inTown {
            let walkers = rows.map { Array($0.dropFirst(people)) }
            px.sprite(walkers, x: x + 34, y: y, partyColors)
        }
        if givenOut {
            // A split runner and a broken slat lying in the snow.
            s.rect(x - 4, hz + 9, 5, 1, s.c(0x8B6A42))
            s.rect(x - 7, hz + 10, 4, 1, s.c(0x2E3036))
        }
        // The outfit itself: patched tarps, then flour leaking out behind.
        if hull < 60 {
            s.rect(x + 3, y + 3, 2, 1, s.c(0x9E8E64))
            s.rect(x + 7, y + 2, 1, 2, s.c(0x9E8E64))
        }
        if hull < 35 {
            s.rect(x + 9, y + 5, 2, 2, s.c(0xCDBE94))
            let drift = walking ? PixelCanvas.mod(t * 3, 6) : 0
            for k in 0..<5 { s.rect(x - 3 - Double(k * 5) - drift, hz + 9 + Double(k % 2), 1, 1, s.c(0xF2EEE2)) }
        }
    }

    static func drawBoat(_ s: Scene) {
        let px = s.px, hz = s.hz, t = s.t
        let g = s.g
        let hull = s.f.hull, sails = s.f.sails
        let over = g?.over ?? false
        if over && hull < 0.5 {
            // Broken up: planks going downriver, the party on a gravel bar.
            for k in 0..<7 {
                var x = PixelCanvas.mod(Double(k * 23) - t * 6, 170)
                if x < 0 { x += 170 }
                s.rect(x - 6, hz + 3 + Double((k * 5) % 20), 5, 1, s.c(0x9C7A4E))
            }
            s.rect(36, 62, 52, 4, s.c(0x8A7A5A))
            s.rect(40, 61, 44, 1, s.c(0x9E8E6A))
            let people = sledColumns.upperBound
            let walkers = party.map { Array($0.dropFirst(people)) }
            px.sprite(walkers, x: 46, y: 52, partyColors)
            return
        }
        let raft = g?.vars[KlondikeSkin.boatKey] == KlondikeSkin.raft
        let givenOut = g.map(Klondike.givenOut) ?? false
        let tied = s.f.atPort || givenOut
        let rough = s.p.rough
        let bob = tied ? 0 : jsRounded(sin(t * (1.4 + rough * 0.7)) * (0.5 + rough * 0.5))
        let low = hull < 35 ? 1.0 : 0
        let top = hz - 10 + bob + low
        let ashore = s.f.atPort
        let patched = hull < 60
        px.sprite(raft ? raftBoat : boat, x: 44, y: top, boatColors) { col, row, ch in
            if givenOut && (ch == "s" || ch == "o") { return true }
            if ashore && "phfd".contains(ch) { return true }
            if ch == "s" { return torn(col, row, sails) }
            return false
        }
        if patched {
            s.rect(52, top + 12, 3, 1, s.c(0xC9BC94))
            s.rect(61, top + 13, 2, 1, s.c(0xC9BC94))
        }
        if givenOut {
            // Furled sail on the yard, and a line to a stake on the bank.
            s.rect(51, top + 2, 11, 1, s.c(0xD8CFB4))
        }
        if tied {
            px.line(from: (69.5, top + 12.5), to: (88, 75), s.c(0x7A5A3A))
            s.rect(88, 73, 1, 3, s.c(0x5A4030))
        }
        if ashore {
            // The party stretching its legs on the bank.
            for k in 0..<4 { person(s, 96 + Double(k * 5), 71, coat: k % 2 == 0 ? 0xB5432F : 0x3B3E4A) }
        }
        if hull < 35 && !tied {
            // Somebody bailing over the side.
            let phase = PixelCanvas.mod(t * 1.6, 1)
            let drop = s.c(0x9FC6DE)
            s.rect(48 + phase * 4, top + 10 - sin(phase * .pi) * 4, 1, 1, drop)
            s.rect(47 + phase * 5, top + 11 - sin(phase * .pi) * 3, 1, 1, drop)
        }
        // A fire on the bank where the party has pulled in for the night.
        if !s.f.moving && !s.f.atPort && !givenOut && (g?.water ?? 1) > 0 {
            let flick = Int((t * 6).rounded(.down)) % 2 == 0 ? 0xF2A03A : 0xE36A2A
            s.rect(104, 75, 2, 1, s.c(UInt32(flick)))
            s.rect(103, 76, 4, 1, s.c(0x5A4030))
            let k = PixelCanvas.mod(t * 2, 5).rounded(.down)
            s.rect(105, 73 - k, 1, 1, s.c(0xC8CCD0).opacity(0.8))
        }
    }

    // MARK: What the weather is doing

    static func air(_ s: Scene) {
        let px = s.px, t = s.t
        switch s.f.weather.sky {
        case .rain: px.rain(t: t)
        case .snow: px.snow(t: t)
        case .fog: px.fog()
        case .dust:
            // Thaw: a thin rain over the slush.
            let c = Color(red: 200 / 255, green: 215 / 255, blue: 230 / 255).opacity(0.55)
            for i in 0..<20 {
                let di = Double(i)
                px.rect(PixelCanvas.mod(di * 37 + t * 24, px.w).rounded(.down), PixelCanvas.mod(di * 53 + t * 120, px.h).rounded(.down), 1, 2, c)
            }
        case .gale:
            if s.leg == .foot {
                // Snow blowing off the ground.
                for i in 0..<24 {
                    var x = PixelCanvas.mod(Double(i * 41) - t * 90, 170)
                    if x < 0 { x += 170 }
                    px.rect((x - 5).rounded(.down), 4 + Double((i * 23) % 72), 3, 1, Color.white.opacity(0.85))
                }
            }
        case .storm:
            for i in 0..<60 {
                let di = Double(i)
                var x = PixelCanvas.mod(di * 37 - t * 40 + sin(t + di) * 2, 165)
                if x < 0 { x += 165 }
                px.rect(x.rounded(.down), PixelCanvas.mod(di * 29 + t * 24, px.h).rounded(.down), 1, 1, .white)
            }
            px.rect(0, 0, px.w, px.h, Color(red: 220 / 255, green: 228 / 255, blue: 235 / 255).opacity(0.25))
        case .heat:
            // Mosquitoes, in clouds.
            for i in 0..<12 {
                let jx = jsRounded(sin(t * 9 + Double(i) * 1.7)), jy = jsRounded(cos(t * 11 + Double(i)))
                px.rect(50 + Double((i * 13) % 40) + jx, s.hz - 16 + Double((i * 7) % 14) + jy, 1, 1, Color(hex: 0x2A2A2A))
            }
        case .still:
            // Rime in the air over the ice.
            if s.leg == .foot {
                for i in 0..<10 {
                    let on = Int((t * 3).rounded(.down) + Double(i)) % 3 == 0
                    if on { px.rect(Double((i * 31) % 160), Double((i * 17) % 40) + 4, 1, 1, Color.white.opacity(0.9)) }
                }
            }
        case .clear, .breeze:
            break
        }
    }

    // MARK: What VoiceOver says

    static func phrase(_ sky: Sky) -> String {
        switch sky {
        case .clear: return "under clear skies"
        case .breeze: return "in fair weather"
        case .rain: return "in the rain"
        case .fog: return "under low cloud"
        case .snow: return "in falling snow"
        case .dust: return "in slush and mud"
        case .gale: return "in a high wind"
        case .storm: return "in a blizzard"
        case .still: return "among cakes of running ice"
        case .heat: return "in the heat, under clouds of mosquitoes"
        }
    }

    static func label(_ f: SceneFrame) -> String {
        guard let g = f.state else { return "A party hauling a loaded sled up a snowy mountain pass" }
        let w = phrase(f.weather.sky)
        let town = f.atPort ? KlondikeSkin.journey.port(g, at: g.currentStop.id)?.name : nil
        let boat = Klondike.hasBoat(g)
        switch KlondikeSkin.leg(g) {
        case "steamer":
            if let town { return "The steamer tied up at \(town), \(w)" }
            return f.moving ? "A crowded steamer heading north \(w)" : "A crowded steamer lying to \(w)"
        case "foot":
            if g.over && f.hull < 0.5 { return "Your outfit lies ruined in the snow, \(w)" }
            if g.over && g.currentStop.id == "summit" { return "Your party turning back from the summit, \(w)" }
            if Klondike.givenOut(g) { return "Your party beside sleds that have given out, \(w)" }
            if let town { return "Your party in camp at \(town), \(w)" }
            return f.moving ? "Your party hauling sleds \(w)" : "Your party camped beside the trail \(w)"
        default:
            if g.over && f.hull < 0.5 { return "The wreck of your boat going down the river, \(w)" }
            if Klondike.givenOut(g) { return "Your boat tied to the bank with no oars or sail, \(w)" }
            if let town { return "Your boat tied up at \(town), \(w)" }
            let what = boat ? "Your boat" : "A boat"
            return f.moving ? "\(what) on the river \(w)" : "\(what) pulled in to the bank \(w)"
        }
    }
}
