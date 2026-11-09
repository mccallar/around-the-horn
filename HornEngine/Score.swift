// Scoring and the top ten (spec §7), the prototype's `score`, `rankOf` and `finale`.

public struct Score: Equatable {
    public struct Line: Equatable {
        public let label: String
        public let points: Int
    }

    public let lines: [Line]
    public let subtotal: Int
    public let multiplier: Int
    public var total: Int { subtotal * multiplier }

    public init(_ s: GameState) {
        let alive = s.living.count
        let health = s.healthLabel
        let stores = Int(s.limes.rounded(.down)) * 2 + s.meds * 5 + s.clothes * 2 + s.sailcloth * 4
            + s.timber * 4 + s.tackle / 20
        lines = [
            Line(label: "\(alive) aboard, health \(health.text)", points: alive * health.scorePerSurvivor),
            Line(label: "Hull & sails", points: Int(jsRound(s.hull * 2 + s.sails))),
            Line(label: "Provisions & water",
                 points: Int((s.food / 25).rounded(.down)) + Int((s.water / 50).rounded(.down))),
            Line(label: "Stores & spares", points: stores),
            Line(label: "Cash", points: Int((s.money / 5).rounded(.down))),
        ]
        subtotal = lines.reduce(0) { $0 + $1.points }
        multiplier = s.role.scoreMultiplier
    }
}

public enum Rank: String {
    case masterMariner = "Master Mariner"
    case ableSeaman = "Able Seaman"
    case ordinarySeaman = "Ordinary Seaman"
    case greenhand = "Greenhand"

    public init(score: Int) {
        self = score >= 7000 ? .masterMariner : score >= 4000 ? .ableSeaman : score >= 2000 ? .ordinarySeaman : .greenhand
    }
}

public struct TopTenEntry: Codable, Equatable {
    public var name: String
    public var score: Int

    public init(name: String, score: Int) {
        self.name = name
        self.score = score
    }
}

public enum TopTen {
    /// Adds a score if it beats the tenth, keeping ten. Returns the new table and the new
    /// row's index (nil when it didn't place). A tie with an existing score ranks below
    /// it, as the prototype's stable sort does.
    public static func inserting(name: String, score: Int, into table: [TopTenEntry])
        -> (table: [TopTenEntry], index: Int?)
    {
        guard let last = table.last, score > last.score else { return (table, nil) }
        var t = table
        let at = t.firstIndex { $0.score < score } ?? t.count
        t.insert(TopTenEntry(name: name, score: score), at: at)
        return (Array(t.prefix(10)), at < 10 ? at : nil)
    }
}
