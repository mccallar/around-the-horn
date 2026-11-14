import SwiftUI
import HornEngine

/// The mini-game's simulation (spec §9), stepped by the view with dt ≤ 0.05 s. The field
/// (its size, where a throw starts and which way it goes) is the skin's; the quarry and
/// how long there is are the journey's. In 1849 that is fish under a boat.
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
    private(set) var time: Double
    private(set) var ended = false
    private var spawnTimer = 0.0

    let field: ForageField
    let quarry: [Fish]
    let padding: Double
    private let pop: (Fish) -> String
    private let random: () -> Double
    /// Spends one throw; false when there's no tackle left.
    private let useTackle: () -> Bool
    private let tackleLeft: () -> Int
    var onCatch: (Fish) -> Void = { _ in }

    init(field: ForageField, quarry: [Fish], seconds: Double, padding: Double,
         pop: @escaping (Fish) -> String = { "+\($0.lb)" },
         random: @escaping () -> Double = { Double.random(in: 0..<1) },
         useTackle: @escaping () -> Bool, tackleLeft: @escaping () -> Int)
    {
        self.field = field
        self.quarry = quarry
        time = seconds
        self.padding = padding
        self.pop = pop
        self.random = random
        self.useTackle = useTackle
        self.tackleLeft = tackleLeft
        guard !quarry.isEmpty else { return }
        for i in 0..<4 {
            spawn()
            fish[i].x = rnd(20, field.w - 20)
        }
    }

    private func rnd(_ a: Double, _ b: Double) -> Double { a + random() * (b - a) }

    private func spawn() {
        guard var kind = quarry.first else { return }
        let total = quarry.reduce(0) { $0 + $1.weight }
        var r = random() * total
        for f in quarry {
            r -= f.weight
            if r <= 0 { kind = f; break }
        }
        let flip = random() < 0.5
        let dir: Double = field.oneWay || flip ? 1 : -1
        var s = Swimmer(kind: kind, x: dir > 0 ? -kind.width : field.w + kind.width,
                        y0: rnd(field.lanes.lowerBound, field.lanes.upperBound), y: 0,
                        vx: dir * rnd(kind.speed.lowerBound, kind.speed.upperBound),
                        t: rnd(0, 6), wf: rnd(1.5, 3), wa: rnd(1, 4))
        // The prototype sets y on the first frame, before anything can be tapped.
        s.y = s.y0 + sin(s.t * s.wf) * s.wa
        fish.append(s)
    }

    /// A tap on the field at logical (x, y). One throw in flight at a time.
    func throwAt(x: Double, y: Double) {
        guard harpoon == nil, !ended, field.inReach(y), tackleLeft() > 0, useTackle() else { return }
        let o = field.origin
        let dx = x - o.x, dy = y - o.y
        let l = max(hypot(dx, dy), 1)
        harpoon = Harpoon(x: o.x, y: o.y, vx: dx / l * field.speed, vy: dy / l * field.speed)
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
        fish.removeAll { $0.x <= -40 || $0.x >= field.w + 40 }
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
                pops.append(Pop(x: f.x, y: f.y, t: 1, text: pop(f.kind)))
                harpoon = nil
                onCatch(f.kind)
            } else if h.x < -5 || h.x > field.w + 5 || h.y > field.h + 5 || h.y < -5 {
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
        let journey = c.journey, skin = c.skin.forage
        let field = skin.field
        let reward = Self.reward(journey, c.skin.words(g))
        VStack(alignment: .leading, spacing: 0) {
            Heading(skin.heading)
            if let m = model {
                HStack {
                    Text("\(skin.throwsLabel): \(g.tackle)")
                    Spacer()
                    Text("\(skin.caughtLabel): \(reward.measure(m.caught))")
                    Spacer()
                    Text("\(skin.timeLabel): \(Int(max(0, m.time).rounded(.up)))")
                }
                .bodyFont(18)
                .accessibilityElement(children: .combine)
                GeometryReader { geo in
                    Canvas { ctx, size in
                        Self.draw(PixelCanvas(ctx, size: size, w: field.w, h: field.h), skin, m, now: now)
                    }
                    .contentShape(Rectangle())
                    .gesture(SpatialTapGesture().onEnded { e in
                        m.throwAt(x: Double(e.location.x / geo.size.width) * field.w,
                                  y: Double(e.location.y / geo.size.height) * field.h)
                    })
                }
                .aspectRatio(field.w / field.h, contentMode: .fit)
                .overlay(Rectangle().strokeBorder(Theme.line, lineWidth: 2))
                .accessibilityElement()
                .accessibilityLabel(skin.label(m.fish.count))
                .accessibilityHint(skin.actionHint)
                .accessibilityAction { aimAtNearest(m) }
            }
            Para(skin.hint(reward.measure(journey.role(g.role).catchLimit)), size: 18, color: Theme.dim)
            ChoiceList(choices: [Choice(label: skin.leave) { finish() }])
        }
        .task { await run(g) }
    }

    /// VoiceOver can't aim, so its throw goes at whatever is nearest the thrower.
    private func aimAtNearest(_ m: FishingModel) {
        let f = m.field
        guard let q = m.fish.filter({ $0.x > 0 && $0.x < f.w })
            .min(by: { abs($0.x - f.origin.x) < abs($1.x - f.origin.x) }) else { return }
        m.throwAt(x: q.x, y: q.y)
    }

    private func run(_ g: GameState) async {
        let journey = c.journey, skin = c.skin.forage
        let reward = Self.reward(journey, c.skin.words(g))
        let m = FishingModel(field: skin.field, quarry: journey.quarry, seconds: journey.forageSeconds,
                             padding: journey.role(g.role).aim, pop: Self.pop(skin, reward),
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

    /// What a catch is stowed as, and how the skin has that item counted. The model, a
    /// role's `catchLimit` and a quarry's `lb` are all in the engine's stored units; this
    /// is the one place they are turned into what the player reads.
    struct Reward {
        let item: Item
        let how: Stores.Counting

        /// With its unit: "12 lbs", "1.4 cords".
        func measure(_ stored: Int) -> String { Stores.measure(Double(stored), item, how) }
        /// The bare number: "12", "1.4".
        func count(_ stored: Int) -> String { Stores.count(Double(stored), item, how) }
    }

    static func reward(_ journey: Journey, _ words: Words) -> Reward {
        let item = journey.item(journey.forageReward)
        return Reward(item: item, how: Stores.counting(item, words))
    }

    /// What floats up from a hit: the skin's words round the shell's number.
    static func pop(_ skin: ForageSkin, _ reward: Reward) -> (Fish) -> String {
        { skin.pop(reward.count($0.lb), $0) }
    }

    /// The skin's backdrop, quarry and throw; what floats up from a hit is the shell's.
    static func draw(_ px: PixelCanvas, _ skin: ForageSkin, _ m: FishingModel, now: Double) {
        skin.backdrop(px, now)
        for f in m.fish { skin.quarry(px, f) }
        if let h = m.harpoon { skin.thrown(px, h) }
        for p in m.pops {
            let x = popX(p.x, width: px.width(p.text, size: 8), field: px.w)
            px.text(p.text, x: x, y: p.y, size: 8, Theme.amber.opacity(p.t))
        }
    }

    /// Where a pop `width` wide starts, for a hit at `x`: just left of the hit, or as
    /// far left as it must go to stay inside the field. A long one ("+0.8 cords,
    /// cottonwood limb") from a hit near the right bank would otherwise run off it.
    static func popX(_ x: Double, width: Double, field: Double) -> Double {
        max(0, min(x - 6, field - 1 - width))
    }
}
