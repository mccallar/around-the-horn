import SwiftUI
import HornEngine

/// The fishing mini-game's simulation (spec §9), stepped by the view with dt ≤ 0.05 s.
/// Logical canvas 160×200; the boat is at the top centre and harpoons fly from (80, 28).
@MainActor @Observable
final class FishingModel {
    struct Swimmer: Identifiable {
        let id = UUID()
        let kind: Fish
        var x: Double
        let y0: Double
        var y: Double
        let vx: Double
        var t: Double
        let wf: Double
        let wa: Double
    }

    struct Harpoon { var x, y, vx, vy: Double }

    struct Pop: Identifiable {
        let id = UUID()
        var x, y, t: Double
        let text: String
    }

    private(set) var fish: [Swimmer] = []
    private(set) var harpoon: Harpoon?
    private(set) var pops: [Pop] = []
    private(set) var caught = 0
    private(set) var time = GameData.fishingSeconds
    private(set) var ended = false
    private var spawnTimer = 0.0

    let padding: Double
    private let random: () -> Double
    /// Spends one throw; false when there's no tackle left.
    private let useTackle: () -> Bool
    private let tackleLeft: () -> Int
    var onCatch: (Fish) -> Void = { _ in }

    init(padding: Double, random: @escaping () -> Double = { Double.random(in: 0..<1) },
         useTackle: @escaping () -> Bool, tackleLeft: @escaping () -> Int)
    {
        self.padding = padding
        self.random = random
        self.useTackle = useTackle
        self.tackleLeft = tackleLeft
        for i in 0..<4 {
            spawn()
            fish[i].x = rnd(20, 140)
        }
    }

    private func rnd(_ a: Double, _ b: Double) -> Double { a + random() * (b - a) }

    private func spawn() {
        let total = GameData.fish.reduce(0) { $0 + $1.weight }
        var r = random() * total
        var kind = GameData.fish[0]
        for f in GameData.fish {
            r -= f.weight
            if r <= 0 { kind = f; break }
        }
        let dir: Double = random() < 0.5 ? 1 : -1
        var s = Swimmer(kind: kind, x: dir > 0 ? -kind.width : 160 + kind.width, y0: rnd(45, 188), y: 0,
                        vx: dir * rnd(kind.speed.lowerBound, kind.speed.upperBound),
                        t: rnd(0, 6), wf: rnd(1.5, 3), wa: rnd(1, 4))
        // The prototype sets y on the first frame, before anything can be tapped.
        s.y = s.y0 + sin(s.t * s.wf) * s.wa
        fish.append(s)
    }

    /// A tap on the water at logical (x, y). One harpoon in flight at a time.
    func throwAt(x: Double, y: Double) {
        guard harpoon == nil, !ended, y >= 30, tackleLeft() > 0, useTackle() else { return }
        let dx = x - 80, dy = y - 28
        let l = max(hypot(dx, dy), 1)
        harpoon = Harpoon(x: 80, y: 28, vx: dx / l * 150, vy: dy / l * 150)
    }

    func step(_ rawDt: Double) {
        guard !ended else { return }
        let dt = min(0.05, max(0, rawDt))
        time -= dt
        spawnTimer -= dt
        if spawnTimer <= 0 {
            spawnTimer = rnd(0.5, 1.1)
            spawn()
        }
        for i in fish.indices {
            fish[i].x += fish[i].vx * dt
            fish[i].t += dt
            fish[i].y = fish[i].y0 + sin(fish[i].t * fish[i].wf) * fish[i].wa
        }
        fish.removeAll { $0.x <= -40 || $0.x >= 200 }
        for i in pops.indices {
            pops[i].t -= dt * 0.8
            pops[i].y -= dt * 12
        }
        pops.removeAll { $0.t <= 0 }
        if var h = harpoon {
            h.x += h.vx * dt
            h.y += h.vy * dt
            harpoon = h
            if let i = fish.firstIndex(where: { abs(h.x - $0.x) < $0.kind.width / 2 + padding
                    && abs(h.y - $0.y) < $0.kind.height / 2 + padding })
            {
                let f = fish.remove(at: i)
                caught += f.kind.lb
                pops.append(Pop(x: f.x, y: f.y, t: 1, text: "+\(f.kind.lb) lb \(f.kind.name)"))
                harpoon = nil
                onCatch(f.kind)
            } else if h.x < -5 || h.x > 165 || h.y > 205 {
                harpoon = nil
            }
        }
        if time <= 0 || (tackleLeft() <= 0 && harpoon == nil) { ended = true }
    }

    func stop() { ended = true }
}

struct FishingView: View {
    @Environment(GameController.self) private var c
    @State private var model: FishingModel?
    @State private var landed = false
    @State private var now = 0.0

    var body: some View {
        let g = c.game!
        VStack(alignment: .leading, spacing: 0) {
            Heading("Fishing")
            if let m = model {
                HStack {
                    Text("Throws: \(g.tackle)")
                    Spacer()
                    Text("Caught: \(m.caught) lbs")
                    Spacer()
                    Text("Time: \(Int(max(0, m.time).rounded(.up)))")
                }
                .bodyFont(18)
                .accessibilityElement(children: .combine)
                GeometryReader { geo in
                    Canvas { ctx, size in
                        Self.draw(PixelCanvas(ctx: ctx, scale: size.width / 160), m, now: now, ctx: ctx, size: size)
                    }
                    .contentShape(Rectangle())
                    .gesture(SpatialTapGesture().onEnded { e in
                        m.throwAt(x: Double(e.location.x / geo.size.width * 160), y: Double(e.location.y / geo.size.height * 200))
                    })
                }
                .aspectRatio(160 / 200, contentMode: .fit)
                .overlay(Rectangle().strokeBorder(Theme.line, lineWidth: 2))
                .accessibilityElement()
                .accessibilityLabel("The sea below the boat, with \(m.fish.count) fish swimming")
                .accessibilityHint("Double-tap to throw a harpoon at the nearest fish")
                .accessibilityAction { aimAtNearest(m) }
            }
            Para("Tap the water to throw a harpoon. Each throw uses tackle. You can salt and keep up to \(g.role.catchLimit) lbs.",
                 size: 18, color: Theme.dim)
            ChoiceList(choices: [Choice(label: "Back to the ship") { finish() }])
        }
        .task { await run(g) }
    }

    /// VoiceOver can't aim, so its throw goes at the nearest fish.
    private func aimAtNearest(_ m: FishingModel) {
        guard let f = m.fish.filter({ $0.x > 0 && $0.x < 160 }).min(by: { abs($0.x - 80) < abs($1.x - 80) }) else { return }
        m.throwAt(x: f.x, y: f.y)
    }

    private func run(_ g: GameState) async {
        let m = FishingModel(padding: g.role.harpoonPadding,
                             useTackle: { [c] in
                                 let ok = c.throwHarpoon()
                                 if ok { Feedback.play(.harpoon) }
                                 return ok
                             },
                             tackleLeft: { [c] in c.game?.tackle ?? 0 })
        m.onCatch = { _ in
            Feedback.play(.fishHit)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        model = m
        var last = Date()
        while !Task.isCancelled && !m.ended {
            try? await Task.sleep(for: .milliseconds(16))
            let t = Date()
            m.step(t.timeIntervalSince(last))
            now += t.timeIntervalSince(last)
            last = t
        }
        if !Task.isCancelled { finish() }
    }

    private func finish() {
        guard !landed, let m = model else { return }
        landed = true
        m.stop()
        c.endFishing(caught: m.caught)
    }

    static func draw(_ px: PixelCanvas, _ m: FishingModel, now: Double, ctx: GraphicsContext, size: CGSize) {
        let ms = now * 1000
        px.rect(0, 0, 160, 28, Color(hex: 0x9FD0EE))
        for i in 0..<10 {
            px.rect(0, 28 + Double(i * 18), 160, 18, SeaScene.mix(0x1F6B96, 0x061A2B, Double(i) / 9))
        }
        for i in 0..<4 {
            px.rect(SeaScene.mod(Double(i * 45) + ms / 80, 200) - 20, 28, 6, 172, Color.white.opacity(0.06))
        }
        for i in stride(from: 0, to: 160, by: 6) {
            px.rect(Double(i) + jsRounded(sin(ms / 400 + Double(i))), 28, 3, 1, Color(hex: 0xD8ECF7))
        }
        px.rect(70, 24, 20, 4, Color(hex: 0x4A2E1A))
        px.rect(72, 28, 16, 1, Color(hex: 0x4A2E1A))
        px.rect(79, 18, 2, 6, Color(hex: 0xD64545))
        px.rect(79, 16, 2, 2, Color(hex: 0xEFD6B0))
        for f in m.fish { drawFish(px, f) }
        if let h = m.harpoon {
            var line = Path()
            line.move(to: CGPoint(x: 80.5 * px.scale, y: 24.5 * px.scale))
            line.addLine(to: CGPoint(x: h.x * px.scale, y: h.y * px.scale))
            ctx.stroke(line, with: .color(Color(red: 236 / 255, green: 228 / 255, blue: 207 / 255).opacity(0.5)),
                       lineWidth: px.scale)
            let a = atan2(h.vy, h.vx)
            for k in 0..<6 {
                px.rect(jsRounded(h.x - cos(a) * Double(k)), jsRounded(h.y - sin(a) * Double(k)), 1, 1, Theme.ink)
            }
            px.rect(jsRounded(h.x), jsRounded(h.y), 2, 2, Theme.amber)
        }
        for p in m.pops {
            ctx.draw(Text(p.text).font(.custom(Theme.bodyFont, fixedSize: 8 * px.scale))
                .foregroundColor(Theme.amber.opacity(p.t)),
                     at: CGPoint(x: (p.x - 6) * px.scale, y: p.y * px.scale), anchor: .bottomLeading)
        }
    }

    static func drawFish(_ px: PixelCanvas, _ f: FishingModel.Swimmer) {
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
