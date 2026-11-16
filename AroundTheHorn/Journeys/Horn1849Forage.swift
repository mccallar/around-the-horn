import SwiftUI
import HornEngine

/// 1849's fishing (spec §9): a boat at the top of a 160×200 sea, harpoons thrown down
/// from (80, 28) at whatever swims below.
enum Horn1849Forage {
    static let skin = ForageSkin(
        field: ForageField(w: 160, h: 200, origin: (80, 28), upward: false, line: 30, lanes: 45...188, speed: 150, oneWay: false),
        heading: "Fishing",
        throwsLabel: "Throws", caughtLabel: "Caught", timeLabel: "Time", grouped: false,
        hint: { "Tap the water to throw a harpoon. Each throw uses tackle. You can salt and keep up to \($0)." },
        label: { "The sea below the boat, with \($0) fish swimming" },
        actionHint: "Double-tap to throw a harpoon at the nearest fish",
        leave: "Back to the ship",
        pop: { "+\($0) lb \($1.name)" },
        backdrop: backdrop, quarry: fish, thrown: harpoon)

    /// A strip of sky, the water darkening with depth, shafts of light, ripples, and the boat.
    static func backdrop(_ px: PixelCanvas, now: Double) {
        let ms = now * 1000
        px.rect(0, 0, 160, 28, Color(hex: 0x9FD0EE))
        px.bands(top: 0x1F6B96, bottom: 0x061A2B, from: 28, each: 18, count: 10)
        for i in 0..<4 {
            px.rect(PixelCanvas.mod(Double(i * 45) + ms / 80, 200) - 20, 28, 6, 172, Color.white.opacity(0.06))
        }
        for i in stride(from: 0, to: 160, by: 6) {
            px.rect(Double(i) + jsRounded(sin(ms / 400 + Double(i))), 28, 3, 1, Color(hex: 0xD8ECF7))
        }
        px.rect(70, 24, 20, 4, Color(hex: 0x4A2E1A))
        px.rect(72, 28, 16, 1, Color(hex: 0x4A2E1A))
        px.rect(79, 18, 2, 6, Color(hex: 0xD64545))
        px.rect(79, 16, 2, 2, Color(hex: 0xEFD6B0))
    }

    /// The line back to the fisher's hand, the shaft, and the head.
    static func harpoon(_ px: PixelCanvas, _ h: FishingModel.Harpoon) {
        px.line(from: (80.5, 24.5), to: (h.x, h.y), Color(red: 236 / 255, green: 228 / 255, blue: 207 / 255).opacity(0.5))
        let a = atan2(h.vy, h.vx)
        for k in 0..<6 {
            px.rect(jsRounded(h.x - cos(a) * Double(k)), jsRounded(h.y - sin(a) * Double(k)), 1, 1, Theme.ink)
        }
        px.rect(jsRounded(h.x), jsRounded(h.y), 2, 2, Theme.amber)
    }

    static func fish(_ px: PixelCanvas, _ f: FishingModel.Swimmer) {
        let x = jsRounded(f.x), y = jsRounded(f.y)
        let right = f.vx > 0
        let w = f.kind.width, h = f.kind.height
        let hw = (w / 2).rounded(.towardZero), hh = (h / 2).rounded(.towardZero)
        let c = Color(hex: UInt32(f.kind.color.dropFirst(), radix: 16)!)
        px.rect(x - hw, y - hh, w, h, c)
        px.rect(x - hw + 2, y - hh - 1, w - 4, 1, c)
        px.rect(x - hw + 2, y + hh + h.truncatingRemainder(dividingBy: 2), w - 4, 1, c)
        let tx = right ? x - hw - 3 : x + hw
        px.rect(tx, y - hh - 1, 3, 2, c)
        px.rect(tx, y + hh, 3, 2, c)
        px.rect(right ? x - hw - 1 : x + hw, y - 1, 1, 2, c)
        if f.kind.name == "shark" {
            px.rect(x - 2, y - hh - 4, 4, 3, c)
            px.rect(x - 1, y - hh - 5, 2, 1, c)
        }
        px.rect(right ? x + hw - 3 : x - hw + 2, y - 1, 1, 1, Color(hex: 0x111111))
    }
}
