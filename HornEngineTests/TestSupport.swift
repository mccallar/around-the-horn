@testable import HornEngine

/// Hands out the numbers it is given, in order, then `fallback`. A high fallback (the
/// default) makes every `chance` fail, so a test sees only what it scripted.
struct ScriptedRNG: RandomSource {
    var values: [Double]
    var fallback = 0.999
    private(set) var draws = 0

    init(_ values: [Double] = [], fallback: Double = 0.999) {
        self.values = values
        self.fallback = fallback
    }

    mutating func nextUnit() -> Double {
        defer { draws += 1 }
        return draws < values.count ? values[draws] : fallback
    }
}

extension GameState {
    /// Five aboard at sea, well stocked, in January 1849.
    static func fixture(role: Role = .merchant, year: Int = 1849, month: Int = 0) -> GameState {
        var s = GameState(role: role, ship: "Resolute", captain: "Ezra",
                          crew: ["Hannah", "Silas", "Mercy", "Tobias"], startYear: year, startMonth: month)
        s.food = 2000
        s.water = 800
        s.limes = 10
        s.meds = 4
        s.clothes = 5
        s.sailcloth = 4
        s.timber = 4
        s.tackle = 100
        s.atPort = false
        return s
    }
}

func engine(_ s: GameState = .fixture(), _ values: [Double] = [], fallback: Double = 0.999) -> GameEngine {
    GameEngine(state: s, rng: ScriptedRNG(values, fallback: fallback))
}
