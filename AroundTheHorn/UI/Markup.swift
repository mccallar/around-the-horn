import SwiftUI
import HornEngine

/// The spec §13 markup: `[red]…[/red]`, `[green]`, `[amber]`, `[dim]`, `[teal]`, `[i]`,
/// `[b]`, and `[[` for a literal "[" (decisions D5). Anything else in brackets is plain
/// text. Engine messages and screen copy are written in it; player-entered names arrive
/// already escaped, so they can never turn into markup.
enum Markup {
    enum Style: String, CaseIterable {
        case red, green, amber, dim, teal, i, b

        var color: Color? {
            switch self {
            case .red: return Theme.red
            case .green: return Theme.green
            case .amber: return Theme.amber
            case .dim: return Theme.dim
            case .teal: return Theme.teal
            case .i, .b: return nil
            }
        }
    }

    struct Run: Equatable {
        var text: String
        var styles: [Style]
    }

    static func runs(_ s: String) -> [Run] {
        var out: [Run] = []
        var stack: [Style] = []
        var buf = ""
        func flush() {
            if !buf.isEmpty { out.append(Run(text: buf, styles: stack)) }
            buf = ""
        }
        var i = s.startIndex
        while i < s.endIndex {
            let rest = s[i...]
            if rest.hasPrefix("[[") {
                buf.append("[")
                i = s.index(i, offsetBy: 2)
                continue
            }
            if rest.hasPrefix("["), let close = rest.firstIndex(of: "]") {
                let tag = rest[rest.index(after: rest.startIndex)..<close]
                if tag.hasPrefix("/"), let st = Style(rawValue: String(tag.dropFirst())),
                   let at = stack.lastIndex(of: st)
                {
                    flush()
                    stack.remove(at: at)
                    i = s.index(after: close)
                    continue
                }
                if let st = Style(rawValue: String(tag)) {
                    flush()
                    stack.append(st)
                    i = s.index(after: close)
                    continue
                }
            }
            buf.append(s[i])
            i = s.index(after: i)
        }
        flush()
        return out
    }

    /// A player-entered string made safe to put in markup (the engine's rule, D5).
    static func escape(_ s: String) -> String { TextMarkup.escape(s) }

    /// The text with every tag removed: for accessibility and for a pressed button.
    static func plain(_ s: String) -> String { runs(s).map(\.text).joined() }

    /// `size` is the final point size (already scaled). Neither pixel font has an
    /// italic or bold face, so [i] is the regular face slanted (the browser's synthetic
    /// oblique, which the prototype showed) and [b] is drawn amber.
    static func attributed(_ s: String, size: CGFloat, base: Color = Theme.ink, monochrome: Color? = nil) -> AttributedString {
        var out = AttributedString()
        for r in runs(s) {
            var a = AttributedString(r.text)
            let color = r.styles.last { $0.color != nil }?.color ?? (r.styles.contains(.b) ? Theme.amber : base)
            a.foregroundColor = monochrome ?? color
            a.font = r.styles.contains(.i) ? oblique(size) : .custom(Theme.bodyFont, fixedSize: size)
            out += a
        }
        return out
    }

    static func oblique(_ size: CGFloat) -> Font {
        guard let f = UIFont(name: Theme.bodyFont, size: size) else { return .custom(Theme.bodyFont, fixedSize: size).italic() }
        let slant = CGAffineTransform(a: 1, b: 0, c: 0.21, d: 1, tx: 0, ty: 0)
        return Font(UIFont(descriptor: f.fontDescriptor.withMatrix(slant), size: size) as CTFont)
    }
}

/// Body-face text in markup. Owns its type size, scaled with Dynamic Type and capped
/// (spec §3), because each run carries its own font.
struct MarkupText: View {
    let markup: String
    var size: CGFloat = 22
    var base: Color = Theme.ink
    var monochrome: Color?
    @ScaledMetric(relativeTo: .body) private var scale: CGFloat = 100

    init(_ markup: String, size: CGFloat = 22, base: Color = Theme.ink, monochrome: Color? = nil) {
        self.markup = markup
        self.size = size
        self.base = base
        self.monochrome = monochrome
    }

    var body: some View {
        Text(Markup.attributed(markup, size: Self.scaled(size, scale), base: base, monochrome: monochrome))
            .fixedSize(horizontal: false, vertical: true)
    }

    /// The body cap: 22 pt grows to at most 30.
    static func scaled(_ size: CGFloat, _ scale: CGFloat) -> CGFloat {
        min(size * scale / 100, size * 30 / 22)
    }
}
