import SwiftUI
import HornEngine

/// Fills logical pixels at a scale, snapping each edge to a whole device point so
/// neighbouring rectangles never leave a hairline between them.
struct PixelCanvas {
    /// Nil when a draw is run for its own sake (the skin contract test): calls are
    /// counted and, with nothing to paint on, noted down instead.
    let ctx: GraphicsContext?
    let scale: CGFloat
    /// The logical grid.
    let w: Double, h: Double
    let tally = Tally()

    /// What was drawn, for tests: a picture can't be looked at there, but two can be
    /// told apart and the ground one covers can be measured.
    final class Tally {
        var marks = 0
        private var hasher = Hasher()
        /// The box around every rectangle and outline noted, or nil before the first.
        private(set) var bounds: CGRect?

        /// The same for two drawings exactly when the same marks were made in the same
        /// order, place and colour. Only good within one run of the program.
        var picture: Int {
            var h = hasher
            return h.finalize()
        }

        func note(_ kind: String, _ numbers: [Double], _ color: Color, text: String = "", box: CGRect? = nil) {
            hasher.combine(kind)
            hasher.combine(numbers)
            hasher.combine(color)
            hasher.combine(text)
            if let box { bounds = bounds?.union(box) ?? box }
        }
    }

    init(_ ctx: GraphicsContext, size: CGSize, w: Double, h: Double) {
        self.ctx = ctx
        scale = size.width / CGFloat(w)
        self.w = w
        self.h = h
    }

    /// A canvas with nothing behind it.
    init(w: Double, h: Double) {
        ctx = nil
        scale = 1
        self.w = w
        self.h = h
    }

    func rect(_ x: Double, _ y: Double, _ w: Double, _ h: Double, _ color: Color) {
        let x0 = (CGFloat(x) * scale).rounded(.down), y0 = (CGFloat(y) * scale).rounded(.down)
        let x1 = (CGFloat(x + w) * scale).rounded(.down), y1 = (CGFloat(y + h) * scale).rounded(.down)
        guard x1 > x0, y1 > y0 else { return }
        tally.marks += 1
        let box = CGRect(x: x0, y: y0, width: x1 - x0, height: y1 - y0)
        guard let ctx else { return tally.note("rect", [Double(x0), Double(y0), Double(x1), Double(y1)], color, box: box) }
        ctx.fill(Path(box), with: .color(color))
    }

    /// A filled outline through logical points, left unsnapped: a coastline.
    func polygon(_ points: [(x: Double, y: Double)], _ color: Color) {
        guard points.count > 2 else { return }
        tally.marks += 1
        guard let ctx else {
            let xs = points.map(\.x), ys = points.map(\.y)
            return tally.note("polygon", xs + ys, color,
                              box: CGRect(x: xs.min()!, y: ys.min()!, width: xs.max()! - xs.min()!, height: ys.max()! - ys.min()!))
        }
        var path = Path()
        for (i, q) in points.enumerated() {
            let cg = CGPoint(x: q.x * scale, y: q.y * scale)
            if i == 0 { path.move(to: cg) } else { path.addLine(to: cg) }
        }
        path.closeSubpath()
        ctx.fill(path, with: .color(color))
    }

    /// A straight line one logical pixel wide: a rope.
    func line(from a: (x: Double, y: Double), to b: (x: Double, y: Double), _ color: Color) {
        tally.marks += 1
        guard let ctx else { return tally.note("line", [a.x, a.y, b.x, b.y], color) }
        var path = Path()
        path.move(to: CGPoint(x: a.x * scale, y: a.y * scale))
        path.addLine(to: CGPoint(x: b.x * scale, y: b.y * scale))
        ctx.stroke(path, with: .color(color), lineWidth: scale)
    }

    /// Words in the body font, `size` logical pixels tall, standing on (x, y).
    func text(_ s: String, x: Double, y: Double, size: Double, _ color: Color) {
        tally.marks += 1
        guard let ctx else { return tally.note("text", [x, y, size], color, text: s) }
        ctx.draw(Text(s).font(.custom(Theme.bodyFont, fixedSize: size * scale)).foregroundColor(color),
                 at: CGPoint(x: x * scale, y: y * scale), anchor: .bottomLeading)
    }
}

// MARK: - What scenes are made of

/// The pieces every journey's scene is built from, so a skin's own art is only what is
/// its own. Numbers are the prototype's.
extension PixelCanvas {
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

    /// The sky, graded from `top` to `bottom` in overlapping bands down to `horizon`.
    func sky(top: UInt32, bottom: UInt32, horizon: Double, bands: Int = 8) {
        let n = Double(bands)
        for i in 0..<bands {
            rect(0, (Double(i) * horizon / n).rounded(.down), w, (horizon / n).rounded(.up) + 1,
                 Self.mix(top, bottom, Double(i) / (n - 1)))
        }
    }

    /// Flat bands of `each` pixels from `y` down, graded the same way: deep water, a cliff.
    func bands(top: UInt32, bottom: UInt32, from y: Double, each: Double, count: Int) {
        for i in 0..<count {
            rect(0, y + Double(i) * each, w, each, Self.mix(top, bottom, Double(i) / Double(count - 1)))
        }
    }

    /// The sun: an 11×11 disc with its corners off, its box's top-left at (x, y).
    func sun(x: Double, y: Double, _ color: Color) {
        rect(x + 2, y, 7, 11, color)
        rect(x, y + 2, 11, 7, color)
        rect(x + 1, y + 1, 9, 9, color)
    }

    /// A crescent: the same disc with a bite of `sky` out of its right side.
    func moon(x: Double, y: Double, _ color: Color, sky: Color) {
        sun(x: x, y: y, color)
        sun(x: x + 4, y: y - 1, sky)
    }

    /// `count` clouds sliding left and coming round again, the far ones slower.
    func clouds(_ count: Int, _ color: Color, t: Double, drift: Double) {
        for i in 0..<count {
            let di = Double(i)
            var x = Self.mod(di * 61 + 20 - t * (2 + di) * drift, w + 40)
            if x < 0 { x += w + 40 }
            x = jsRounded(x - 20)
            let y = 5 + Double((i * 13) % 24)
            rect(x, y, 16, 3, color)
            rect(x + 3, y - 2, 9, 2, color)
            rect(x + 2, y + 3, 12, 1, color)
        }
    }

    /// Ground one column at a time, standing on `base`; `height` is asked for each x.
    func hills(_ columns: Range<Int>, base: Double, _ color: Color, height: (Double) -> Double) {
        for i in columns {
            let di = Double(i)
            let hh = jsRounded(height(di))
            rect(di, base - hh, 1, hh, color)
        }
    }

    /// Blits a sprite written as rows of characters, a space being clear, with its
    /// top-left at (x, y). `skip` drops single pixels: torn sails, a holed envelope.
    func sprite(_ rows: [[Character]], x: Double, y: Double, _ colors: [Character: Color],
                skip: (_ column: Int, _ row: Int, Character) -> Bool = { _, _, _ in false })
    {
        for (r, row) in rows.enumerated() {
            for (col, ch) in row.enumerated() where ch != " " {
                guard let c = colors[ch], !skip(col, r, ch) else { continue }
                rect(x + Double(col), y + Double(r), 1, 1, c)
            }
        }
    }

    func rain(t: Double) {
        let c = Color(red: 200 / 255, green: 215 / 255, blue: 230 / 255).opacity(0.6)
        for i in 0..<45 {
            let di = Double(i)
            rect(Self.mod(di * 37 + t * 30, w).rounded(.down), Self.mod(di * 53 + t * 150, h).rounded(.down), 1, 3, c)
        }
    }

    func snow(t: Double) {
        for i in 0..<30 {
            let di = Double(i)
            let x = Self.mod(Self.mod(di * 41 + t * 10 + sin(t + di) * 4, w) + w, w)
            rect(x.rounded(.down), Self.mod(di * 29 + t * 16, h).rounded(.down), 1, 1, .white)
        }
    }

    func fog() {
        rect(0, 0, w, h, Color(red: 210 / 255, green: 215 / 255, blue: 220 / 255).opacity(0.38))
    }

    /// A flash now and then.
    func lightning(t: Double) {
        if Int((t * 10).rounded(.down)) % 53 == 0 { rect(0, 0, w, h, Color.white.opacity(0.55)) }
    }

    /// Grit blowing across, and a haze of the same colour.
    func dust(t: Double, _ color: Color) {
        rect(0, 0, w, h, color.opacity(0.3))
        for i in 0..<40 {
            let di = Double(i)
            rect(Self.mod(di * 43 + t * 90, w).rounded(.down), Self.mod(di * 31 + sin(t + di) * 3 + h, h).rounded(.down),
                 2, 1, color.opacity(0.7))
        }
    }

    /// Whatever falls from or hangs in a sky of this kind, in the order the layers go on.
    func air(_ sky: Sky, t: Double, dust color: Color = Color(hex: 0xC9A27A)) {
        switch sky {
        case .rain: rain(t: t)
        case .snow: snow(t: t)
        case .fog: fog()
        case .storm:
            rain(t: t)
            lightning(t: t)
        case .dust: dust(t: t, color)
        case .clear, .breeze, .still, .heat, .gale: break
        }
    }
}
