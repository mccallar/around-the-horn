import SwiftUI
import HornEngine

/// Trailing a line: 1849's sea, seen from a capsule hanging just above the wave tops. The
/// field is 1849's way up: the underside of the capsule at the top of a 160×200 sea, a
/// crew member at the open hatch, and lures cast down from (80.5, 27.5) at whatever swims
/// below. What is caught is pounds of rations.
enum BalloonForage {
    static let hatch = (x: 80.5, y: 27.5)

    static let skin = ForageSkin(
        field: ForageField(w: 160, h: 200, origin: hatch, upward: false, line: 30, lanes: 45...188, speed: 150, oneWay: false),
        heading: "Trailing a line",
        throwsLabel: "Casts", caughtLabel: "Caught", timeLabel: "Time", grouped: false,
        hint: { "Tap the water to cast a lure. Each cast uses line. You can stow up to \($0)." },
        label: { "The sea below the capsule, with \($0) fish swimming" },
        actionHint: "Double-tap to cast a lure at the nearest fish",
        leave: "Back to the capsule",
        pop: { n, fish in
            let food = BalloonSkin.journey.item(.food)
            return "+\(n) \(n == "1" ? food.one : food.unit) \(fish.name)"
        },
        backdrop: backdrop, quarry: fish, thrown: lure)

    /// A strip of gold sky, the underside of the capsule hanging from its cables with a
    /// crew member at the open hatch, and below it 1849's water: darker with depth, shafts
    /// of light, ripples at the top.
    static func backdrop(_ px: PixelCanvas, now: Double) {
        let ms = now * 1000
        px.rect(0, 0, 160, 28, Color(hex: 0xF6D78B))
        px.bands(top: 0x1F6B96, bottom: 0x061A2B, from: 28, each: 18, count: 10)
        for i in 0..<4 {
            px.rect(PixelCanvas.mod(Double(i * 45) + ms / 80, 200) - 20, 28, 6, 172, Color.white.opacity(0.06))
        }
        for i in stride(from: 0, to: 160, by: 6) {
            px.rect(Double(i) + jsRounded(sin(ms / 400 + Double(i))), 28, 3, 1, Color(hex: 0xD8ECF7))
        }
        // The load cables, the capsule and its portholes, and the hatch in its floor.
        let cable = Color(hex: 0x5A6270)
        px.line(from: (68, 0), to: (70, 8), cable)
        px.line(from: (90, 0), to: (92, 8), cable)
        px.rect(66, 8, 29, 14, Color(hex: 0xECE4CF))
        for x in [70.0, 76, 84, 90] { px.rect(x, 14, 2, 2, Color(hex: 0x1A2533)) }
        px.rect(78, 22, 5, 2, Color(hex: 0x3A3F48))
        // Whoever is fishing: a red suit through the hatch, face down to the water.
        px.rect(79, 22, 2, 4, Color(hex: 0xD64545))
        px.rect(79, 26, 2, 2, Color(hex: 0xEFD6B0))
    }

    /// The line back to the hatch, a pale trail behind the lure, and the lure's gold head.
    static func lure(_ px: PixelCanvas, _ h: FishingModel.Harpoon) {
        px.line(from: (hatch.x, hatch.y), to: (h.x, h.y), Color(red: 236 / 255, green: 228 / 255, blue: 207 / 255).opacity(0.5))
        let a = atan2(h.vy, h.vx)
        for k in 0..<6 {
            px.rect(jsRounded(h.x - cos(a) * Double(k)), jsRounded(h.y - sin(a) * Double(k)), 1, 1, Color(hex: 0xECE4CF))
        }
        px.rect(jsRounded(h.x), jsRounded(h.y), 2, 2, Color(hex: 0xF2B632))
    }

    /// 1849's fish in the Pacific's colours; the yellowfin carries a gold dorsal fin.
    static func fish(_ px: PixelCanvas, _ f: FishingModel.Swimmer) {
        let x = jsRounded(f.x), y = jsRounded(f.y)
        let right = f.vx > 0
        let w = f.kind.width, h = f.kind.height
        let hw = (w / 2).rounded(.towardZero), hh = (h / 2).rounded(.towardZero)
        let c = Color(hex: UInt32(f.kind.color.dropFirst(), radix: 16) ?? 0x9FC9E8)
        px.rect(x - hw, y - hh, w, h, c)
        px.rect(x - hw + 2, y - hh - 1, w - 4, 1, c)
        px.rect(x - hw + 2, y + hh + h.truncatingRemainder(dividingBy: 2), w - 4, 1, c)
        let tx = right ? x - hw - 3 : x + hw
        px.rect(tx, y - hh - 1, 3, 2, c)
        px.rect(tx, y + hh, 3, 2, c)
        px.rect(right ? x - hw - 1 : x + hw, y - 1, 1, 2, c)
        if f.kind.name == "yellowfin" {
            let fin = Color(hex: 0xF2D04B)
            px.rect(x - 2, y - hh - 4, 4, 3, fin)
            px.rect(x - 1, y - hh - 5, 2, 1, fin)
        }
        if f.kind.name == "flying fish" {
            // Its long fins, folded back along the body.
            px.rect(right ? x - 2 : x - 1, y - hh - 2, 4, 1, PixelCanvas.mix(0x9FC9E8, 0xFFFFFF, 0.4))
        }
        px.rect(right ? x + hw - 3 : x - hw + 2, y - 1, 1, 1, Color(hex: 0x111111))
    }
}
