import SwiftUI

struct Choice: Identifiable {
    let id = UUID()
    /// Markup.
    let label: String
    /// A second, dim, smaller line (pace and rations screens).
    var detail: String?
    var enabled = true
    var primary = false
    let action: () -> Void
}

/// The numbered choice buttons (spec §3): full width, square, 2-pt border, inverted while
/// pressed. Keys 1–9 pick a choice; Return picks a lone one.
struct ChoiceList: View {
    let choices: [Choice]
    /// Off on screens with a text field, where digits belong to the field.
    var keyboardShortcuts = true

    var body: some View {
        VStack(spacing: 8) {
            ForEach(Array(choices.enumerated()), id: \.element.id) { i, c in
                Button {
                    Feedback.tap()
                    c.action()
                } label: { EmptyView() }
                .buttonStyle(ChoiceStyle(number: i + 1, label: c.label, detail: c.detail, primary: c.primary))
                .disabled(!c.enabled)
                .accessibilityLabel(Markup.plain(c.label) + (c.detail.map { ". " + Markup.plain($0) } ?? ""))
                .modifier(NumberKey(n: i + 1, lone: choices.count == 1, on: keyboardShortcuts))
            }
        }
        .padding(.top, 14)
    }
}

private struct NumberKey: ViewModifier {
    let n: Int
    let lone: Bool
    let on: Bool

    func body(content: Content) -> some View {
        if !on {
            content
        } else if lone {
            content.keyboardShortcut(.defaultAction)
        } else if n <= 9 {
            content.keyboardShortcut(KeyEquivalent(Character(String(n))), modifiers: [])
        } else {
            content
        }
    }
}

struct ChoiceStyle: ButtonStyle {
    let number: Int
    let label: String
    let detail: String?
    let primary: Bool

    func makeBody(configuration: Configuration) -> some View {
        Inner(number: number, label: label, detail: detail, primary: primary, pressed: configuration.isPressed)
    }

    private struct Inner: View {
        let number: Int
        let label: String
        let detail: String?
        let primary: Bool
        let pressed: Bool
        @Environment(\.isEnabled) private var enabled
        @ScaledMetric(relativeTo: .body) private var scale: CGFloat = 100

        var body: some View {
            let size = MarkupText.scaled(22, scale)
            VStack(alignment: .leading, spacing: 2) {
                (Text("\(number). ").foregroundColor(pressed ? .black : Theme.amber)
                    .font(.custom(Theme.bodyFont, fixedSize: size))
                    + Text(Markup.attributed(label, size: size, monochrome: pressed ? .black : nil)))
                    .fixedSize(horizontal: false, vertical: true)
                if let detail {
                    MarkupText(detail, size: 18, base: Theme.dim, monochrome: pressed ? .black : nil)
                }
            }
            .multilineTextAlignment(.leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
            .background(pressed ? Theme.amber : Color.clear)
            .overlay(Rectangle().strokeBorder(primary ? Theme.amber : Theme.line, lineWidth: 2))
            .contentShape(Rectangle())
            .opacity(enabled ? 1 : 0.4)
        }
    }
}
