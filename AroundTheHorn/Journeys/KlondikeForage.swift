import SwiftUI
import HornEngine

/// Fishing the lakes and the river: 1849's field under a northern sky. A small boat sits at
/// the top of a 160×200 piece of green water with a spruce shore behind it, and a hook on a
/// line is cast down from (80, 28) at grayling, whitefish, pike, lake trout and king salmon.
/// What is caught is smoked and goes in with the provisions.
enum KlondikeForage {
    static let rod = (x: 80.0, y: 28.0)

    static let skin = ForageSkin(
        field: ForageField(w: 160, h: 200, origin: rod, upward: false, line: 30, lanes: 45...188, speed: 150, oneWay: false),
        heading: "Fishing",
        throwsLabel: "Casts", caughtLabel: "Caught", timeLabel: "Time", grouped: false,
        hint: { "Tap the water to cast. Each cast uses a hook. You can smoke and keep up to \($0)." },
        label: { "The water below the boat, with \($0) fish swimming" },
        actionHint: "Double-tap to cast at the nearest fish",
        leave: "Back to camp",
        pop: { n, fish in
            let food = KlondikeSkin.journey.item(.food)
            return "+\(n) \(n == "1" ? food.one : food.unit) \(fish.name)"
        },
        backdrop: backdrop, quarry: fish, thrown: hook)

    /// A strip of pale sky with the spruce shore along the bottom of it, the water going
    /// from green to black with depth, shafts of light, ripples, and the boat with the
    /// fisher in a red mackinaw.
    static func backdrop(_ px: PixelCanvas, now: Double) {
        let ms = now * 1000
        px.rect(0, 0, 160, 28, Color(hex: 0xBFD9E6))
        // Far hills under snow, then the shore's spruce: one every four pixels, 3 to 7 tall.
        px.hills(0..<160, base: 28, Color(hex: 0xE8EEF2)) { x in 9 + 4 * sin(x * 0.05) + 2 * sin(x * 0.17) }
        px.rect(0, 26, 160, 2, Color(hex: 0x1F3A2A))
        for i in 0..<40 {
            KlondikeScene.tree(px, x: Double(i * 4 + 1), base: 27, height: Double(3 + (i * 7 + i / 3) % 5), Color(hex: 0x1F3A2A))
        }
        px.bands(top: 0x3D7C78, bottom: 0x0A2422, from: 28, each: 18, count: 10)
        for i in 0..<4 {
            px.rect(PixelCanvas.mod(Double(i * 45) + ms / 80, 200) - 20, 28, 6, 172, Color.white.opacity(0.06))
        }
        for i in stride(from: 0, to: 160, by: 6) {
            px.rect(Double(i) + jsRounded(sin(ms / 400 + Double(i))), 28, 3, 1, Color(hex: 0xCFE6DF))
        }
        // The boat: a double-ended skiff, its stem and stern turned up, an oar shipped.
        let wood = Color(hex: 0x9C7A4E), shade = Color(hex: 0x6B5132)
        px.rect(69, 24, 22, 3, wood)
        px.rect(71, 27, 18, 1, shade)
        px.rect(68, 23, 2, 2, wood)
        px.rect(90, 23, 2, 2, wood)
        px.rect(69, 25, 22, 1, shade)
        px.line(from: (84, 23), to: (93, 20), shade)
        // The fisher, in a red mackinaw and a dark cap, the rod out over the side.
        px.rect(77, 18, 3, 6, Color(hex: 0xB5432F))
        px.rect(77, 15, 3, 3, Color(hex: 0xEFD6B0))
        px.rect(77, 14, 3, 1, Color(hex: 0x3A2A1A))
        px.rect(80, 19, 1, 1, Color(hex: 0xB5432F))
        px.line(from: (80.5, 19.5), to: (rod.x + 0.5, rod.y - 6.5), Color(hex: 0x3A2A1A))
    }

    /// The line from the rod's tip and the hook at the end of it.
    static func hook(_ px: PixelCanvas, _ h: FishingModel.Harpoon) {
        px.line(from: (rod.x + 0.5, rod.y - 6.5), to: (h.x, h.y), Color(hex: 0xE9E3D2).opacity(0.7))
        px.rect(jsRounded(h.x), jsRounded(h.y), 2, 2, Color(hex: 0xC9CED4))
    }

    /// 1849's fish, in this water's kinds: the grayling with its tall back fin, the lake
    /// trout spotted, the pike long and narrow in the snout.
    static func fish(_ px: PixelCanvas, _ f: FishingModel.Swimmer) {
        let x = jsRounded(f.x), y = jsRounded(f.y)
        let right = f.vx > 0
        let w = f.kind.width, h = f.kind.height
        let hw = (w / 2).rounded(.towardZero), hh = (h / 2).rounded(.towardZero)
        let rgb = UInt32(f.kind.color.dropFirst(), radix: 16) ?? 0x9DB7C9
        let c = Color(hex: rgb)
        px.rect(x - hw, y - hh, w, h, c)
        px.rect(x - hw + 2, y - hh - 1, w - 4, 1, c)
        px.rect(x - hw + 2, y + hh + h.truncatingRemainder(dividingBy: 2), w - 4, 1, c)
        let tx = right ? x - hw - 3 : x + hw
        px.rect(tx, y - hh - 1, 3, 2, c)
        px.rect(tx, y + hh, 3, 2, c)
        px.rect(right ? x - hw - 1 : x + hw, y - 1, 1, 2, c)
        switch f.kind.name {
        case "grayling":
            // The sail of a fin, three pixels above the back.
            px.rect(x - 2, y - hh - 3, 4, 2, c)
            px.rect(x - 1, y - hh - 4, 2, 1, c)
        case "lake trout":
            for k in stride(from: 2.0, to: w - 2, by: 4) {
                px.rect(x - hw + k, y - hh + 1 + Double(Int(k / 4) % 2) * 2, 1, 1, Color(hex: 0xD9D1B0))
            }
        case "pike":
            // A long flat snout past the head.
            px.rect(right ? x + hw : x - hw - 2, y - hh + 1, 2, max(1, h - 2), c)
            px.rect(x - hw + 3, y - hh, w - 6, 1, PixelCanvas.mix(rgb, 0x2A3A1A, 0.45))
        case "king salmon":
            // A dark back and a pale belly.
            px.rect(x - hw + 1, y - hh, w - 2, 2, PixelCanvas.mix(rgb, 0x3A2A2A, 0.45))
            px.rect(x - hw + 2, y + hh, w - 4, 1, PixelCanvas.mix(rgb, 0xFFFFFF, 0.45))
        default: break
        }
        px.rect(right ? x + hw - 3 : x - hw + 2, y - 1, 1, 1, Color(hex: 0x111111))
    }
}
