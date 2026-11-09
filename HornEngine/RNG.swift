// Every random number the engine draws comes through a `RandomSource` (spec §2), so a
// test or the balance harness can replay a voyage exactly from a seed.

public protocol RandomSource {
    /// A uniformly distributed value in `0..<1`.
    mutating func nextUnit() -> Double
}

public extension RandomSource {
    /// The prototype's `rnd(a, b)`: a uniform Double in `a..<b`.
    mutating func uniform(_ low: Double, _ high: Double) -> Double {
        low + (high - low) * nextUnit()
    }

    /// The prototype's `ri(a, b)`: a uniform Int in `a...b`, both ends included.
    mutating func int(_ low: Int, _ high: Int) -> Int {
        low + Int(nextUnit() * Double(high - low + 1))
    }

    /// True with probability `p`.
    mutating func chance(_ p: Double) -> Bool {
        nextUnit() < p
    }
}

/// SplitMix64. Small, fast, and identical on every device, which is all a game needs.
public struct SeededRNG: RandomSource, Codable, Equatable {
    public private(set) var state: UInt64

    public init(seed: UInt64) {
        state = seed
    }

    public mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    public mutating func nextUnit() -> Double {
        // The top 53 bits: every representable Double in [0, 1) at that spacing.
        Double(next() >> 11) * 0x1.0p-53
    }
}
