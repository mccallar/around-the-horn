import SwiftUI
import HornEngine

/// Reading the winds: the field is upside down from 1849's. The meteorologist stands on
/// the roof hatch of the control car at the bottom of a 160×200 sky, beside a theodolite,
/// and sends pilot balloons up from (80, 172) at the winds crossing overhead. What a
/// balloon finds is petrol the ship need not burn.
enum AirshipForage {
    static let hand = (x: 80.0, y: 172.0)
    /// Where the theodolite's eyepiece is: the sight line runs from here to the balloon.
    static let eyepiece = (x: 86.0, y: 181.0)

    static let skin = ForageSkin(
        field: ForageField(w: 160, h: 200, origin: hand, upward: true, line: 170, lanes: 12...155, speed: 150, oneWay: false),
        heading: "Reading the winds",
        throwsLabel: "Balloons", caughtLabel: "Found", timeLabel: "Time", grouped: true,
        hint: { "Tap the sky to send up a pilot balloon and follow it through the theodolite. Each one goes for good. The navigator can plan around winds worth up to \($0) of petrol in one session." },
        label: { "The sky above the control car, with \($0) \($0 == 1 ? "wind" : "winds") crossing it" },
        actionHint: "Double-tap to send a balloon up at the nearest wind",
        leave: "Back to the chart table",
        pop: { n, wind in
            let petrol = AirshipSkin.journey.item(.fuel)
            return "+\(n) \(n == "1" ? petrol.one : petrol.unit), \(wind.name)"
        },
        backdrop: backdrop, quarry: wind, thrown: balloon)

    /// The sky darkening upward, thin wisps of cloud, and at the bottom the roof of the
    /// control car, the meteorologist in a red scarf, and the theodolite on its tripod.
    static func backdrop(_ px: PixelCanvas, now: Double) {
        let w = 160.0
        px.bands(top: 0x1F4E86, bottom: 0xBFE0F2, from: 0, each: 20, count: 10)
        for i in 0..<3 {
            let di = Double(i)
            let x = PixelCanvas.mod(di * 61 + now * (4 + di * 2), w + 40) - 30
            let y = 30 + di * 47
            px.rect(x.rounded(.down), y, 26, 2, Color(hex: 0xF4F7FA).opacity(0.2))
            px.rect((x + 6).rounded(.down), y - 1, 12, 1, Color(hex: 0xF4F7FA).opacity(0.2))
        }
        // The control car's roof and its windows.
        px.rect(66, 188, 29, 8, Color(hex: 0x6B4A2B))
        px.rect(64, 187, 33, 1, Color(hex: 0x4A2E1A))
        for i in 0..<5 { px.rect(68 + Double(i) * 6, 191, 3, 3, Color(hex: 0xF2D16B)) }
        // The meteorologist, one arm up to let the balloon go.
        let coat = Color(hex: 0x3A4A5E)
        px.rect(78, 178, 4, 9, coat)
        px.rect(78, 187, 1, 1, coat)
        px.rect(81, 187, 1, 1, coat)
        px.rect(78, 177, 4, 1, Color(hex: 0xD64545))
        px.rect(79, 174, 3, 3, Color(hex: 0xEFD6B0))
        px.rect(78, 173, 5, 1, Color(hex: 0x5A4632))
        px.rect(79, 172, 3, 1, Color(hex: 0x5A4632))
        px.rect(77, 175, 1, 4, coat)
        // The theodolite on its tripod.
        let brass = Color(hex: 0xECE4CF)
        px.rect(84, 180, 5, 3, brass)
        px.rect(88, 181, 2, 1, brass)
        px.line(from: (86, 183), to: (83, 187), brass)
        px.line(from: (86, 183), to: (89, 187), brass)
        px.rect(86, 183, 1, 4, brass)
    }

    /// The red balloon, its string, and the dotted sight line back to the theodolite.
    static func balloon(_ px: PixelCanvas, _ b: FishingModel.Harpoon) {
        let x = jsRounded(b.x), y = jsRounded(b.y)
        let dx = x - eyepiece.x, dy = y - eyepiece.y
        let steps = Int(hypot(dx, dy) / 3)
        for k in 1..<max(2, steps) {
            let f = Double(k) / Double(max(2, steps))
            px.rect(jsRounded(eyepiece.x + dx * f), jsRounded(eyepiece.y + dy * f), 1, 1, Theme.ink.opacity(0.6))
        }
        let red = Color(hex: 0xD64545)
        px.rect(x - 1, y - 1, 3, 3, red)
        px.rect(x, y - 2, 1, 1, red)
        px.rect(x - 1, y - 1, 1, 1, Color(hex: 0xF08A7A))
        px.rect(x, y + 2, 1, 2, Theme.ink.opacity(0.7))
    }

    /// A wind as the theodolite shows it: two or three rows of dashes in its colour,
    /// running the way it blows; the widest, a river of air, trails a long streak behind it.
    static func wind(_ px: PixelCanvas, _ f: FishingModel.Swimmer) {
        let x = jsRounded(f.x), y = jsRounded(f.y)
        let w = f.kind.width, h = f.kind.height
        let hw = (w / 2).rounded(.towardZero), hh = (h / 2).rounded(.towardZero)
        let rgb = UInt32(f.kind.color.dropFirst(), radix: 16) ?? 0xCFE8F5
        let c = Color(hex: rgb)
        let left = x - hw, top = y - hh
        let rows = h >= 5 ? 3 : 2
        let gap = rows == 3 ? (h - 1) / 2 : h - 1
        let right = f.vx > 0
        // The dashes shuffle along as it goes, so a wind reads as moving air.
        let phase = Int(PixelCanvas.mod(abs(f.x) / 2, 4))
        for r in 0..<rows {
            let ry = (top + Double(r) * gap).rounded(.down)
            let inset = Double((r * 3 + phase) % 4)
            var dx = inset
            while dx < w {
                let len = min(3 + Double(r % 2), w - dx)
                px.rect(left + dx, ry, len, 1, c)
                dx += len + 2
            }
        }
        // Its leading edge, a little brighter.
        let lead = right ? left + w - 1 : left
        px.rect(lead, top + gap / 2, 1, max(1, gap), PixelCanvas.mix(rgb, 0xFFFFFF, 0.4))
        if w >= 28 {
            let tail = right ? left - 6 : left + w
            px.rect(tail, y, 6, 1, c.opacity(0.6))
        }
    }
}
