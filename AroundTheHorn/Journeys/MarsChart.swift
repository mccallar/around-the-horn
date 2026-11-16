import SwiftUI
import HornEngine

/// The Long Transfer's plot: the inner solar system seen from above, on a 230×200 grid.
/// The Sun is in the middle, Earth's orbit and Mars's are dotted circles, and the transfer
/// arc is half an ellipse with the Sun at one focus, from Earth on the left (closest to
/// the Sun) round under the Sun to Mars on the right (furthest), the way the planets go
/// round. So the ship heads right on the plot, as she does in the scene. The cycler's loop
/// is a fainter ellipse through the point where she meets it. An inset in the corner shows
/// the Earth and the Moon, where the first three stops are too close together to tell
/// apart at this scale. The route is given already projected.
enum MarsChart {
    static let w = 230.0, h = 200.0
    static let sun = (x: 128.0, y: 100.0)
    /// Pixels to an astronomical unit.
    static let scale = 58.0
    static let earthAU = 1.0, marsAU = 1.524

    /// The transfer ellipse: its semi-major axis and eccentricity, from the two orbits.
    static let a = (earthAU + marsAU) / 2
    static let e = (marsAU - earthAU) / (marsAU + earthAU)

    /// Distance from the Sun, in AU, `theta` radians round from Earth.
    static func radius(_ theta: Double) -> Double { a * (1 - e * e) / (1 + e * cos(theta)) }

    /// A point in AU from the Sun at `r` and position angle `phi` (counted the usual way, up
    /// the page positive), on the canvas.
    static func project(r: Double, phi: Double) -> (x: Double, y: Double) {
        (sun.x + scale * r * cos(phi), sun.y - scale * r * sin(phi))
    }

    /// The arc, `steps` pieces of equal angle, with the length run so far at each.
    static let samples: [(theta: Double, length: Double)] = {
        let steps = 360
        var out: [(Double, Double)] = [(0, 0)]
        var run = 0.0
        var last = project(r: radius(0), phi: .pi)
        for k in 1...steps {
            let th = Double.pi * Double(k) / Double(steps)
            let q = project(r: radius(th), phi: .pi + th)
            run += hypot(q.x - last.x, q.y - last.y)
            last = q
            out.append((th, run))
        }
        return out
    }()

    /// How far round from Earth the ship is at `mile`, by the length of the arc.
    static func theta(atMile mile: Double) -> Double {
        let total = Double(MarsSkin.journey.totalMiles)
        let want = max(0, min(1, mile / total)) * (samples.last?.length ?? 1)
        for (p, q) in zip(samples, samples.dropFirst()) where want <= q.length {
            let f = q.length == p.length ? 0 : (want - p.length) / (q.length - p.length)
            return p.theta + (q.theta - p.theta) * f
        }
        return .pi
    }

    /// The ship's distance from the Sun at `mile`, in AU: the scene sizes the Sun by it.
    static func au(atMile mile: Double) -> Double { radius(theta(atMile: mile)) }

    /// The route: a point every two degrees round, each at the mile its share of the arc's
    /// length makes it, the last at Jezero.
    static let route: [ChartSkin.Point] = {
        let total = Double(MarsSkin.journey.totalMiles)
        let length = samples.last?.length ?? 1
        return samples.enumerated().compactMap { k, s in
            guard k % 4 == 0 else { return nil }
            let q = project(r: radius(s.theta), phi: .pi + s.theta)
            return (x: q.x, y: q.y, mile: k == samples.count - 1 ? total : (s.length / length * total).rounded())
        }
    }()

    /// The cycler's loop: an ellipse a little longer than the transfer's, turned so that it
    /// passes through the point on the arc where the ship meets her.
    static let cyclerA = 1.30, cyclerE = 0.24
    static let cyclerTurn: Double = {
        let mile = Double(MarsSkin.journey.stop("cycler")?.mile ?? 0)
        let th = theta(atMile: mile)
        let r = radius(th), phi = Double.pi + th
        let c = max(-1, min(1, (cyclerA * (1 - cyclerE * cyclerE) / r - 1) / cyclerE))
        return phi - acos(c)
    }()

    static func cyclerPoint(_ phi: Double) -> (x: Double, y: Double) {
        project(r: cyclerA * (1 - cyclerE * cyclerE) / (1 + cyclerE * cos(phi - cyclerTurn)), phi: phi)
    }

    static let skin = ChartSkin(
        w: w, h: h,
        title: "Plot of the transfer",
        label: { "Plot of the transfer arc round the Sun, from Earth orbit to Mars. You are \(MarsScene.whereabouts($0))." },
        footer: {
            let total = MarsSkin.journey.totalMiles
            return "\(MarsSkin.millions($0.mile)) of \(MarsSkin.km(total)) along the arc. "
                + "\(MarsSkin.millions(max(0, total - $0.mile))) to go. The ringed stops are stations; "
                + "the inset is the Earth and the Moon, where the trip begins."
        },
        background: { px, _, _ in background(px) },
        route: { _ in route },
        others: { _ in [] },
        project: { ($0, $1) },
        routeStep: 600, travelledStep: 200, routeColor: Color(hex: 0x6D7F92),
        overlay: { px, g, t in marks(px, g, t: t) })

    // MARK: The inner solar system

    static let space: UInt32 = 0x070B18
    static let earthBlue: UInt32 = 0x3C7CC4
    static let marsRust: UInt32 = 0xC0613A

    static func dot(_ px: PixelCanvas, _ q: (x: Double, y: Double), _ color: Color) {
        let x = jsRounded(q.x), y = jsRounded(q.y)
        guard x >= 0, x < px.w, y >= 0, y < px.h else { return }
        px.rect(x, y, 1, 1, color)
    }

    static func background(_ px: PixelCanvas) {
        px.rect(0, 0, px.w, px.h, Color(hex: space))
        // A scatter of stars, the same every time.
        for i in 0..<70 {
            let x = Double((i * 97 + 13) % Int(w)), y = Double((i * 61 + 29) % Int(h))
            px.rect(x, y, 1, 1, Color.white.opacity(i % 4 == 0 ? 0.55 : 0.22))
        }
        // The cycler's loop, faintly; then the two orbits.
        for k in stride(from: 0.0, to: 360, by: 4) {
            dot(px, cyclerPoint(k * .pi / 180), Color(hex: 0x4B5566))
        }
        for k in stride(from: 0.0, to: 360, by: 3) {
            dot(px, project(r: earthAU, phi: k * .pi / 180), Color(hex: earthBlue).opacity(0.8))
            dot(px, project(r: marsAU, phi: k * .pi / 180), Color(hex: marsRust).opacity(0.8))
        }
        // The Sun, and its glow.
        let s = (x: sun.x, y: sun.y)
        px.rect(s.x - 4, s.y - 1, 9, 3, Color(hex: 0xFFE27A).opacity(0.35))
        px.rect(s.x - 1, s.y - 4, 3, 9, Color(hex: 0xFFE27A).opacity(0.35))
        px.rect(s.x - 2, s.y - 2, 5, 5, Color(hex: 0xFFE27A))
        px.rect(s.x - 1, s.y - 3, 3, 7, Color(hex: 0xFFE27A))
        px.rect(s.x - 3, s.y - 1, 7, 3, Color(hex: 0xFFE27A))
        // Earth where the ship leaves it, Mars where she meets it.
        let earth = project(r: earthAU, phi: .pi), mars = project(r: marsAU, phi: 0)
        px.rect(jsRounded(earth.x) - 2, jsRounded(earth.y) - 2, 5, 5, Color(hex: earthBlue))
        px.rect(jsRounded(mars.x) - 2, jsRounded(mars.y) - 2, 5, 5, Color(hex: marsRust))
    }

    /// The stations ringed, the three names, and the inset of the Earth and the Moon with
    /// the first stops and, while she is there, the ship.
    static func marks(_ px: PixelCanvas, _ g: GameState, t: Double) {
        let ink = Color(hex: 0xECE4CF)
        let j = MarsSkin.journey
        for stop in j.stops where j.port(stop.id) != nil {
            let q = ChartView.position(route, atMile: Double(stop.mile), skin)
            let x = jsRounded(q.x) - 3, y = jsRounded(q.y) - 3
            px.rect(x + 1, y, 5, 1, ink)
            px.rect(x + 1, y + 6, 5, 1, ink)
            px.rect(x, y + 1, 1, 5, ink)
            px.rect(x + 6, y + 1, 1, 5, ink)
        }
        let dim = Color(hex: 0xB8B2A2)
        px.text("Sun", x: sun.x + 6, y: sun.y - 4, size: 8, dim)
        let earth = project(r: earthAU, phi: .pi), mars = project(r: marsAU, phi: 0)
        px.text("Earth", x: earth.x + 4, y: earth.y - 3, size: 8, dim)
        px.text("Mars", x: mars.x - 18, y: mars.y - 5, size: 8, dim)
        inset(px, g, t: t)
    }

    /// The inset's box, top left.
    static let box = (x: 3.0, y: 3.0, w: 50.0, h: 44.0)
    static let insetEarth = (x: 14.0, y: 25.0)
    /// Pixels from the Earth's middle to Gateway Yard (high orbit), the Moon's distance and
    /// the edge of Earth's reach, in the inset.
    static let insetRadius: [String: Double] = ["gateway": 5, "lunar": 9, "hill": 31]

    /// Where `mile` falls in the inset, out along the way the ship leaves.
    static func insetX(atMile mile: Double) -> Double {
        let j = MarsSkin.journey
        let marks = ["gateway", "lunar", "hill"].compactMap { id in
            j.stop(id).map { (mile: Double($0.mile), r: insetRadius[id] ?? 0) }
        }
        guard let first = marks.first, let last = marks.last else { return insetEarth.x }
        if mile <= first.mile { return insetEarth.x + first.r }
        for (p, q) in zip(marks, marks.dropFirst()) where mile <= q.mile {
            return insetEarth.x + p.r + (q.r - p.r) * (mile - p.mile) / max(1, q.mile - p.mile)
        }
        return insetEarth.x + last.r
    }

    static func inset(_ px: PixelCanvas, _ g: GameState, t: Double) {
        let b = box
        let edge = Color(hex: 0x3A4A5E)
        px.rect(b.x, b.y, b.w, b.h, Color(hex: 0x0A1222))
        px.rect(b.x, b.y, b.w, 1, edge)
        px.rect(b.x, b.y + b.h - 1, b.w, 1, edge)
        px.rect(b.x, b.y, 1, b.h, edge)
        px.rect(b.x + b.w - 1, b.y, 1, b.h, edge)
        let c = insetEarth
        // The Moon's orbit, and the edge of Earth's reach on the side she leaves by.
        for k in stride(from: 0.0, to: 360, by: 20) {
            let a = k * .pi / 180
            dot(px, (c.x + 9 * cos(a), c.y + 9 * sin(a)), Color(hex: 0x8F8F88))
        }
        for k in stride(from: -40.0, through: 40, by: 8) {
            let a = k * .pi / 180
            dot(px, (c.x + 31 * cos(a), c.y + 31 * sin(a)), Color(hex: 0x6D7F92))
        }
        px.rect(c.x - 2, c.y - 2, 5, 5, Color(hex: earthBlue))
        px.rect(c.x - 1, c.y - 3, 3, 7, Color(hex: earthBlue))
        px.rect(c.x - 3, c.y - 1, 7, 3, Color(hex: earthBlue))
        px.rect(c.x + 6, c.y - 7, 2, 2, Color(hex: 0xB8B8B0))
        // The first three stops on the way out, and the ship while she is among them.
        let j = MarsSkin.journey
        for id in ["gateway", "lunar", "hill"] {
            guard let i = j.stops.firstIndex(where: { $0.id == id }) else { continue }
            let x = jsRounded(insetX(atMile: Double(j.stops[i].mile)))
            px.rect(x - 1, c.y - 1, 3, 3, i <= g.stopIndex ? Theme.amber : Theme.ink)
        }
        let hill = Double(j.stop("hill")?.mile ?? 0)
        if Double(g.mile) <= hill && Int((t * 2).rounded(.down)) % 2 == 0 {
            px.rect(jsRounded(insetX(atMile: Double(g.mile))) - 2, c.y - 2, 5, 5, Theme.red)
        }
    }
}
