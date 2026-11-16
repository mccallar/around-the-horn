import SwiftUI
import HornEngine

/// The grapple: 1849's field turned upside down. A rigger in a suit stands on the truss at
/// the bottom of a 160×200 piece of sky, beside the grapple launcher, and fires a tethered
/// grapple from (80, 182) at ice drifting across above in the three filaments of a comet's
/// old stream, all of it going the same way. What is caught goes to the melt tank, in
/// litres of water.
enum MarsForage {
    static let launcher = (x: 80.0, y: 182.0)

    static let skin = ForageSkin(
        field: ForageField(w: 160, h: 200, origin: launcher, upward: true, line: 172, lanes: 18...150, speed: 150,
                           oneWay: true, bands: 3),
        heading: "The grapple",
        throwsLabel: "Shots", caughtLabel: "Caught", timeLabel: "Time", grouped: false,
        hint: { "Tap the dark to fire the grapple at a chunk going by. Each shot spends tether. The melt tank takes up to \($0) from one outing." },
        label: { "The ice stream beyond the truss, with \($0) \($0 == 1 ? "chunk" : "chunks") drifting by" },
        actionHint: "Double-tap to fire the grapple at the nearest chunk",
        leave: "Back inside",
        pop: { n, chunk in
            let water = MarsSkin.journey.item(.water)
            return "+\(n) \(n == "1" ? water.one : water.unit), \(chunk.name)"
        },
        backdrop: backdrop, quarry: ice, thrown: grapple)

    /// Black sky and fixed stars, the stream's three filaments glittering faintly, and at the
    /// bottom the truss, a wing's edge, the habitat can, the rigger and the launcher.
    static func backdrop(_ px: PixelCanvas, now: Double) {
        px.bands(top: 0x04060D, bottom: 0x0E1730, from: 0, each: 20, count: 10)
        for i in 0..<44 {
            px.rect(Double((i * 53 + 11) % 160), Double((i * 37 + 3) % 168), 1, 1, Color.white.opacity(i % 3 == 0 ? 0.8 : 0.35))
        }
        let f = skin.field
        let each = (f.lanes.upperBound - f.lanes.lowerBound) / Double(f.bands)
        for k in 0..<f.bands {
            let y = f.lanes.lowerBound + each * (Double(k) + 0.5)
            px.rect(0, y - 9, 160, 18, Color(hex: 0xC9D6DF).opacity(0.04))
            for i in 0..<9 {
                let x = MarsScene.wrap(Double(i) * 19 + now * (8 + Double(k) * 3), 170) - 5
                let flash = (i + k + Int((now * 2).rounded(.down))) % 5 == 0
                px.rect(x.rounded(.down), y - 8 + Double((i * 7 + k * 5) % 17), 1, 1, Color(hex: 0xD6E2EA).opacity(flash ? 0.9 : 0.3))
            }
        }
        // A wing's edge at the left, the habitat can at the right.
        for i in 0..<5 {
            px.rect(Double(i) * 7, 189, 6, 5, Color(hex: 0x2E4E8C))
            px.rect(Double(i) * 7, 195, 6, 5, Color(hex: 0x2E4E8C))
        }
        px.rect(0, 188, 35, 1, Color(hex: 0xB8962E))
        px.rect(122, 184, 38, 16, Color(hex: 0xDCE1E6))
        px.rect(122, 184, 38, 1, Color(hex: 0xA7AEB7))
        for x in [128.0, 136, 144, 152] { px.rect(x, 189, 3, 3, Color(hex: 0xF2D16B)) }
        // The truss: two rails, uprights, braces.
        let truss = Color(hex: 0x9AA1AA)
        px.rect(30, 186, 92, 1, truss)
        px.rect(30, 196, 92, 1, truss)
        for x in stride(from: 32.0, to: 120, by: 8) {
            px.rect(x, 186, 1, 10, truss)
            px.line(from: (x, 187), to: (x + 7, 195), Color(hex: 0x6B717A))
        }
        // The launcher on its mount, its reel of tether.
        px.rect(78, 183, 5, 3, Color(hex: 0x4B4F55))
        px.rect(79, 178, 3, 5, Color(hex: 0x5A5F68))
        px.rect(84, 182, 4, 4, Color(hex: 0xB8962E))
        px.rect(85, 183, 2, 2, Color(hex: 0x3A3F47))
        // The rigger in a white suit, gold visor, one hand on the launcher.
        let suit = Color(hex: 0xECEEF0)
        px.rect(70, 178, 5, 8, suit)
        px.rect(70, 174, 5, 4, suit)
        px.rect(71, 175, 3, 2, Color(hex: 0xF2B632))
        px.rect(75, 180, 3, 1, suit)
        px.rect(70, 186, 2, 1, suit)
        px.rect(73, 186, 2, 1, suit)
        px.rect(68, 179, 2, 5, Color(hex: 0xA7AEB7))
    }

    /// The grapple's head, three prongs open, and its tether back to the launcher.
    static func grapple(_ px: PixelCanvas, _ h: FishingModel.Harpoon) {
        let x = jsRounded(h.x), y = jsRounded(h.y)
        let dx = x - launcher.x, dy = y - (launcher.y - 4)
        let steps = Int(hypot(dx, dy) / 2)
        for k in 1..<max(2, steps) {
            let f = Double(k) / Double(max(2, steps))
            px.rect(jsRounded(launcher.x + dx * f), jsRounded(launcher.y - 4 + dy * f), 1, 1, Color(hex: 0xECE4CF).opacity(0.55))
        }
        let steel = Color(hex: 0xC8CED6)
        px.rect(x - 1, y - 1, 2, 3, steel)
        px.rect(x - 3, y - 3, 1, 2, steel)
        px.rect(x + 2, y - 3, 1, 2, steel)
        px.rect(x - 2, y - 1, 1, 1, steel)
        px.rect(x + 1, y - 1, 1, 1, steel)
        px.rect(x, y - 4, 1, 3, steel)
    }

    /// A chunk of ice as it tumbles past: a scatter of grit, a pale lump with a dark side,
    /// a big berg with a crack in it; and now and then somebody's lost water bladder,
    /// orange, with its strap and a beacon blinking.
    static func ice(_ px: PixelCanvas, _ f: FishingModel.Swimmer) {
        let x = jsRounded(f.x), y = jsRounded(f.y)
        let w = f.kind.width, h = f.kind.height
        let hw = (w / 2).rounded(.towardZero), hh = (h / 2).rounded(.towardZero)
        let rgb = UInt32(f.kind.color.dropFirst(), radix: 16) ?? 0xC9D6DF
        let c = Color(hex: rgb), dark = PixelCanvas.mix(rgb, 0x1A2533, 0.45), bright = PixelCanvas.mix(rgb, 0xFFFFFF, 0.5)
        let left = x - hw, top = y - hh
        switch f.kind.name {
        case "grit":
            for (dx, dy) in [(0.0, 1.0), (2, 0), (3, 2), (5, 1), (1, 2)] where dx < w {
                px.rect(left + dx, top + dy, 1, 1, c)
            }
        case "lost water bladder":
            px.rect(left + 1, top, w - 2, h, Color(hex: rgb))
            px.rect(left, top + 1, w, h - 2, Color(hex: rgb))
            px.rect(left + 1, top + h - 2, w - 2, 1, PixelCanvas.mix(rgb, 0x000000, 0.3))
            px.rect(left + 4, top, 2, h, Color(hex: 0xECEEF0))
            px.rect(left + w - 4, top + 2, 2, 2, Color(hex: 0x2E6FB5))
            if Int((f.t * 2).rounded(.down)) % 2 == 0 { px.rect(left + w - 2, top - 1, 1, 1, Color(hex: 0xFF5A4A)) }
        default:
            // A lump: rounded, its underside in shadow, a lit edge on top.
            px.rect(left + 1, top, w - 2, h, c)
            px.rect(left, top + 1, w, h - 2, c)
            px.rect(left + 1, top + h - 2, w - 2, 2, dark)
            px.rect(left + 2, top, w - 4, 1, bright)
            if w >= 13 {
                px.rect(left + 3, top + 2, 2, 2, dark)
                px.rect(left + w - 5, top + 1, 1, 3, dark)
            }
            if w >= 20 {
                // The berg: a notch out of its top and a crack down its face.
                px.rect(left + 6, top, 3, 2, Color(hex: 0x04060D))
                px.line(from: (left + 10, top + 2), to: (left + 13, top + h - 3), dark)
                px.rect(left + w - 3, top + 3, 2, 1, bright)
            }
        }
    }
}
