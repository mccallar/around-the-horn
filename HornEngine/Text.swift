import Foundation

// Message text helpers. Engine messages use the spec §13 markup: [red]…[/red],
// [green], [amber], [dim], [i]. A literal "[" is written "[[" (docs/decisions.md D5),
// which is how a player-entered name stays plain text however it is spelled.

public enum TextMarkup {
    /// The prototype's `esc`: a player-entered string, made safe to put in markup.
    public static func escape(_ s: String) -> String {
        s.replacingOccurrences(of: "[", with: "[[")
    }
}

/// The prototype's `fmt`: floor, then en-US thousands separators.
public func formatNumber(_ n: Double) -> String {
    let v = Int(n.rounded(.down))
    let digits = String(abs(v))
    var out = ""
    for (i, ch) in digits.enumerated() {
        if i > 0 && (digits.count - i) % 3 == 0 { out.append(",") }
        out.append(ch)
    }
    return (v < 0 ? "-" : "") + out
}

/// JavaScript's `Math.round`: halves go toward +∞ (−2.5 → −2), unlike Swift's
/// `.rounded()`, which goes away from zero. Every rounding the prototype does is this one.
@inline(__always)
func jsRound(_ x: Double) -> Double {
    let f = x.rounded(.down)
    return x - f >= 0.5 ? f + 1 : f
}
