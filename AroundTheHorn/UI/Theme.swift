import SwiftUI

/// The prototype's CSS, as SwiftUI (spec §3).
enum Theme {
    static let bg = Color(hex: 0x0A0E14)
    static let panel = Color(hex: 0x101722)
    static let ink = Color(hex: 0xECE4CF)
    static let dim = Color(hex: 0x8F8A7A)
    static let amber = Color(hex: 0xF2B632)
    static let teal = Color(hex: 0x56D6C4)
    static let red = Color(hex: 0xFF6B5B)
    static let green = Color(hex: 0x8FE388)
    static let line = Color(hex: 0x2A3547)
    static let placeholder = Color(hex: 0x5C5A52)

    /// The content column on iPad and in landscape.
    static let maxWidth: CGFloat = 540

    static let bodyFont = "VT323-Regular"
    static let headingFont = "PressStart2P-Regular"

    /// A health or condition bar's colour: green above 60, amber above 30, else red.
    static func barColor(_ v: Double) -> Color { v > 60 ? green : v > 30 ? amber : red }
}

extension Color {
    init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 0xFF) / 255, green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255)
    }
}

// MARK: - Type

/// A pixel font that grows with Dynamic Type, up to a cap (spec §3: body ~22 pt, capped
/// near 30).
struct PixelFont: ViewModifier {
    let name: String
    let cap: CGFloat
    @ScaledMetric private var size: CGFloat

    init(name: String, size: CGFloat, relativeTo style: Font.TextStyle, cap: CGFloat) {
        self.name = name
        self.cap = cap
        _size = ScaledMetric(wrappedValue: size, relativeTo: style)
    }

    func body(content: Content) -> some View {
        content.font(.custom(name, fixedSize: min(size, cap)))
    }
}

extension View {
    /// VT323. 22 for body, 18 for small print, 24 in a message box.
    func bodyFont(_ size: CGFloat = 22) -> some View {
        modifier(PixelFont(name: Theme.bodyFont, size: size, relativeTo: .body, cap: size * 30 / 22))
    }

    /// Press Start 2P. 13 for headings, 21 for the title.
    func headingFont(_ size: CGFloat = 13) -> some View {
        modifier(PixelFont(name: Theme.headingFont, size: size, relativeTo: .headline, cap: size * 1.5))
    }
}

// MARK: - Boxes and text

/// `.box` / `.status`: a 2-pt line border on the panel colour.
struct PanelBox<Content: View>: View {
    var border: Color = Theme.line
    var padding: CGFloat = 10
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 2) { content }
            .padding(.horizontal, 12)
            .padding(.vertical, padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.panel)
            .overlay(Rectangle().strokeBorder(border, lineWidth: 2))
    }
}

/// `.msg`: the amber-bordered message box, in slightly larger type.
struct MessageBox: View {
    let markup: String

    var body: some View {
        PanelBox(border: Theme.amber, padding: 14) {
            MarkupText(markup, size: 24)
        }
        .padding(.vertical, 12)
    }
}

/// `h2`
struct Heading: View {
    let text: String

    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .headingFont()
            .lineSpacing(8)
            .foregroundStyle(Theme.amber)
            .padding(.top, 16)
            .padding(.bottom, 10)
            .accessibilityAddTraits(.isHeader)
    }
}

/// `p`
struct Para: View {
    let markup: String
    var size: CGFloat = 22
    var color = Theme.ink

    init(_ markup: String, size: CGFloat = 22, color: Color = Theme.ink) {
        self.markup = markup
        self.size = size
        self.color = color
    }

    var body: some View {
        MarkupText(markup, size: size, base: color)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 9 / 2)
    }
}

/// A label on the left, a value on the right (`.row`).
struct Row<Value: View>: View {
    let label: String
    @ViewBuilder var value: Value

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            MarkupText(label)
            Spacer(minLength: 0)
            value.multilineTextAlignment(.trailing)
        }
        .accessibilityElement(children: .combine)
    }
}

/// A thin condition bar (`.bar`), coloured by value unless told otherwise.
struct Bar: View {
    let value: Double
    var color: Color?

    var body: some View {
        GeometryReader { g in
            Rectangle()
                .fill(color ?? Theme.barColor(value))
                .frame(width: max(0, g.size.width - 2) * min(1, max(0, value / 100)))
                .padding(1)
        }
        .frame(height: 9)
        .background(Color.black)
        .overlay(Rectangle().strokeBorder(Theme.line, lineWidth: 1))
        .padding(.top, 3)
        .padding(.bottom, 2)
        .accessibilityElement()
        .accessibilityValue("\(Int(value.rounded())) percent")
    }
}

/// `body::after`: 1-pt dark lines every 3 pt at 16%, over everything, never touchable.
struct Scanlines: View {
    var body: some View {
        Canvas { ctx, size in
            var y: CGFloat = 0
            while y < size.height {
                ctx.fill(Path(CGRect(x: 0, y: y, width: size.width, height: 1)), with: .color(.black.opacity(0.16)))
                y += 3
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// `input.txt`: black field, line border, amber when focused.
struct PixelField: View {
    @Binding var text: String
    let placeholder: String
    let maxLength: Int
    var label: String
    @FocusState private var focused: Bool

    var body: some View {
        TextField("", text: $text, prompt: Text(placeholder).foregroundStyle(Theme.placeholder))
            .bodyFont()
            .foregroundStyle(Theme.ink)
            .tint(Theme.amber)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.words)
            .focused($focused)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.black)
            .overlay(Rectangle().strokeBorder(focused ? Theme.amber : Theme.line, lineWidth: 2))
            .padding(.bottom, 6)
            .accessibilityLabel(label)
            .onChange(of: text) { _, new in
                if new.count > maxLength { text = String(new.prefix(maxLength)) }
            }
    }
}
