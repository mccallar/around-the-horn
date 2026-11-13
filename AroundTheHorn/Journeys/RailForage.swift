import SwiftUI
import HornEngine

/// Hauling driftwood: a river going by from left to right on a 160×200 field, the crew
/// on the near bank at the bottom with the track behind them, and a grapnel thrown up
/// from (80, 172) at whatever the current is carrying.
enum RailForage {
    static let bank = 160.0
    static let hand = (x: 80.0, y: 172.0)

    static let skin = ForageSkin(
        field: ForageField(w: 160, h: 200, origin: hand, upward: true, line: 156, lanes: 26...146, speed: 150, oneWay: true),
        heading: "Driftwood",
        throwsLabel: "Casts", caughtLabel: "Hauled", timeLabel: "Time",
        hint: { "Tap the river to cast the grapnel. Each cast uses up line. The crew can cut and stack up to \($0) at one stop." },
        label: { "The river from the bank, with \($0) pieces of driftwood going by" },
        actionHint: "Double-tap to cast the grapnel at the nearest driftwood",
        leave: "Back to the train",
        pop: { n, wood in
            let cord = RailSkin.journey.item(.fuel)
            return "+\(n) \(n == "1" ? cord.one : cord.unit), \(wood.name)"
        },
        backdrop: backdrop, quarry: wood, thrown: grapnel)

    /// The far bank and its willows, the river darkening toward the near side, the
    /// current, and the near bank: sand, grass, the one who throws, and the track.
    static func backdrop(_ px: PixelCanvas, now: Double) {
        let w = 160.0
        px.rect(0, 0, w, 10, Color(hex: 0x5E8A44))
        px.rect(0, 10, w, 4, Color(hex: 0xC8B080))
        for i in 0..<7 {
            let x = Double(i * 25 + 6)
            px.rect(x, 3, 9, 5, Color(hex: 0x3E6E34))
            px.rect(x + 2, 1, 5, 2, Color(hex: 0x3E6E34))
        }
        px.bands(top: 0x5A9AB4, bottom: 0x2A5A76, from: 14, each: 21, count: 7)
        // The current: streaks and the odd fleck of foam, all going the one way.
        for i in 0..<16 {
            let di = Double(i)
            let x = PixelCanvas.mod(di * 47 + now * (22 + PixelCanvas.mod(di * 7, 16)), w + 30) - 15
            px.rect(x.rounded(.down), 18 + PixelCanvas.mod(di * 37, 138), 8 + PixelCanvas.mod(di * 3, 7), 1, Color.white.opacity(0.14))
        }
        for i in 0..<5 {
            let di = Double(i)
            let x = PixelCanvas.mod(di * 71 + now * 30, w + 10) - 5
            px.rect(x.rounded(.down), 30 + di * 27, 2, 1, Color.white.opacity(0.55))
        }
        // The water's edge, lapping.
        for i in stride(from: 0, to: 160, by: 6) {
            px.rect(Double(i) + jsRounded(sin(now * 2.5 + Double(i))), bank - 1, 3, 1, Color(hex: 0xD8ECF7))
        }
        px.rect(0, bank, w, 5, Color(hex: 0xC8B080))
        px.rect(0, bank + 5, w, 40 - 5, Color(hex: 0x6E9A4A))
        for i in 0..<12 {
            px.rect(Double(i * 14 + 3), bank + 9 + Double((i * 5) % 14), 1, 2, Color(hex: 0x4E7A36))
        }
        // The track the train is standing on.
        px.rect(0, 188, w, 8, Color(hex: 0x8A8070))
        for i in 0..<20 { px.rect(Double(i * 8 + 2), 188, 3, 8, Color(hex: 0x4A3626)) }
        px.rect(0, 189, w, 1, Color(hex: 0x2A2A30))
        px.rect(0, 194, w, 1, Color(hex: 0x2A2A30))
        // What has been hauled out so far, and the one hauling.
        px.rect(102, 170, 16, 2, Color(hex: 0x8C6B42))
        px.rect(103, 168, 14, 2, Color(hex: 0xB08A5A))
        px.rect(105, 166, 10, 2, Color(hex: 0x8C6B42))
        px.rect(78, 173, 5, 6, Color(hex: 0x3A5A8A))
        px.rect(78, 179, 2, 4, Color(hex: 0x4A3626))
        px.rect(81, 179, 2, 4, Color(hex: 0x4A3626))
        px.rect(79, 170, 3, 3, Color(hex: 0xEFD6B0))
        px.rect(77, 169, 7, 1, Color(hex: 0x4A2E1A))
        px.rect(79, 167, 3, 2, Color(hex: 0x4A2E1A))
        // The rest of the line, coiled at their feet.
        px.rect(70, 181, 5, 1, Color(hex: 0xD8C8A0))
        px.rect(69, 182, 7, 1, Color(hex: 0xD8C8A0))
        px.rect(70, 183, 5, 1, Color(hex: 0xD8C8A0))
    }

    /// The line back to the hand, and the hooks.
    static func grapnel(_ px: PixelCanvas, _ h: FishingModel.Harpoon) {
        px.line(from: (hand.x + 0.5, hand.y), to: (h.x, h.y), Color(hex: 0xD8C8A0).opacity(0.8))
        let x = jsRounded(h.x), y = jsRounded(h.y)
        let iron = Color(hex: 0xE4E4EA)
        px.rect(x - 2, y - 1, 5, 1, iron)
        px.rect(x - 2, y, 1, 2, iron)
        px.rect(x + 2, y, 1, 2, iron)
        px.rect(x, y - 1, 1, 4, Theme.amber)
    }

    /// One piece of driftwood, by its size: a branch, a rail, a forked limb, a log with
    /// its sawn end showing, a raft of ties.
    static func wood(_ px: PixelCanvas, _ f: FishingModel.Swimmer) {
        let x = jsRounded(f.x), y = jsRounded(f.y)
        let w = f.kind.width, h = f.kind.height
        let hw = (w / 2).rounded(.towardZero), hh = (h / 2).rounded(.towardZero)
        let rgb = UInt32(f.kind.color.dropFirst(), radix: 16) ?? 0x8C6B42
        let c = Color(hex: rgb)
        let light = PixelCanvas.mix(rgb, 0xFFFFFF, 0.3), dark = PixelCanvas.mix(rgb, 0x000000, 0.4)
        let left = x - hw, top = y - hh
        // The water it pushes aside.
        let lead = f.vx > 0 ? left + w : left - 3
        px.rect(lead, y, 3, 1, Color.white.opacity(0.4))
        px.rect(left + 1, top + h, w - 2, 1, Color.black.opacity(0.18))
        if h >= 7 {
            // Ties lashed side by side.
            var row = 0.0
            while row < h {
                px.rect(left, top + row, w, 1, Int(row) % 2 == 0 ? c : dark)
                row += 1
            }
            px.rect(left + 5, top, 1, h, light)
            px.rect(left + w - 6, top, 1, h, light)
        } else if h >= 6 {
            px.rect(left, top, w, h, c)
            px.rect(left + 1, top, w - 2, 1, light)
            px.rect(left, top + h - 1, w, 1, dark)
            let end = f.vx > 0 ? left + w - 3 : left
            px.rect(end, top + 1, 3, h - 2, light)
            px.rect(end + 1, top + 2, 1, h - 4, dark)
        } else if h >= 4 {
            px.rect(left, top + 1, w, h - 2, c)
            px.rect(left, top + 1, w, 1, light)
            px.rect(left + 4, top, 1, 1, c)
            px.rect(left + 5, top - 1, 3, 1, c)
            px.rect(left + w - 5, top + h - 1, 3, 1, c)
            px.rect(left + w - 3, top + h, 2, 1, dark)
        } else if w >= 12 {
            px.rect(left, top, w, 2, c)
            px.rect(left, top, w, 1, light)
            px.rect(left + 3, top, 1, 2, dark)
            px.rect(left + w - 4, top, 1, 2, dark)
        } else {
            px.rect(left, top + 1, w, 1, c)
            px.rect(left + 2, top, 2, 1, c)
            px.rect(left + w - 4, top + 2, 3, 1, c)
            px.rect(left + w - 1, top, 1, 1, light)
        }
    }
}
