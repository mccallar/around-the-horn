#if os(WASI)
import FoundationEssentials
#else
import Foundation
#endif

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

#if os(WASI)
// Under WASI the engine links FoundationEssentials alone (the full Foundation brings
// tens of megabytes of ICU data to the browser), and Essentials lacks the two String
// methods the engine uses. These are them, for what the engine asks of them.
struct CharacterSet {
    let contains: (Unicode.Scalar) -> Bool
    /// Unicode's White_Space: the Z categories, U+0009 to U+000D and U+0085.
    static let whitespacesAndNewlines = CharacterSet { $0.properties.isWhitespace }
}

extension StringProtocol {
    func trimmingCharacters(in set: CharacterSet) -> String {
        let u = unicodeScalars
        var lo = u.startIndex, hi = u.endIndex
        while lo < hi && set.contains(u[lo]) { lo = u.index(after: lo) }
        while hi > lo && set.contains(u[u.index(before: hi)]) { hi = u.index(before: hi) }
        return String(String.UnicodeScalarView(u[lo..<hi]))
    }

    func replacingOccurrences(of target: String, with replacement: String) -> String {
        let t = Array(target.unicodeScalars)
        let u = Array(unicodeScalars)
        var out = String.UnicodeScalarView()
        var i = 0
        while i < u.count {
            if !t.isEmpty && i + t.count <= u.count && Array(u[i..<i + t.count]) == t {
                out.append(contentsOf: replacement.unicodeScalars)
                i += t.count
            } else {
                out.append(u[i])
                i += 1
            }
        }
        return String(out)
    }
}
#endif
