import SwiftUI
import HornEngine

/// The chandler (spec §6 "Shop"): a cart per item, capped by what fits aboard, and a
/// bill that turns red past your cash. Holding + or − repeats.
struct ShopView: View {
    @Environment(GameController.self) private var c
    let done: () -> Void
    @State private var cart: [ItemKey: Int] = [:]

    var body: some View {
        let g = c.game!
        let port = GameData.port(g.currentStop.portID ?? .ny)
        let bill = GameEngine.bill(cart, at: port)
        let over = bill > g.money
        VStack(alignment: .leading, spacing: 0) {
            Heading(port.shop)
            if port.id != .ny {
                Para("Prices here are \(Int(jsRounded((port.mult - 1) * 100)))% above New York, more or less.",
                     size: 18, color: Theme.dim)
            }
            PanelBox {
                HStack {
                    Text("Cash $\(formatNumber(g.money))")
                    Spacer()
                    Text("Bill ") + Text("$\(String(format: "%.2f", bill))").foregroundColor(over ? Theme.red : Theme.amber)
                }
                .accessibilityElement(children: .combine)
            }
            .padding(.vertical, 10)
            ForEach(GameData.items, id: \.key) { it in
                ItemRow(item: it, price: port.price(it.key), have: Self.have(it, g),
                        qty: cart[it.key] ?? 0, room: roomFor(it, g)) { cart[it.key] = $0 }
            }
            ChoiceList(choices: [
                Choice(label: over ? "[red]You can't afford all that[/red]"
                           : bill > 0 ? "Pay $\(String(format: "%.2f", bill)) and leave" : "Leave the shop",
                       enabled: !over, primary: true) {
                    if bill > 0 { c.run { $0.buy(cart) } }
                    c.save()
                    done()
                },
            ] + (bill > 0 ? [Choice(label: "Leave without buying", action: done)] : []))
        }
    }

    private func roomFor(_ it: Item, _ g: GameState) -> Int {
        max(0, Int(((it.cap - g[it.key]) / Double(it.per)).rounded(.down)))
    }

    /// "Have N": boxes for tackle, tenths of a crate for citrus, whole units otherwise.
    static func have(_ it: Item, _ g: GameState) -> String {
        if it.per > 1 { return String(Int((g[it.key] / Double(it.per)).rounded(.down))) }
        if it.key == .limes { return jsNumber((g.limes * 10).rounded(.down) / 10) }
        return String(Int(g[it.key].rounded(.down)))
    }

    /// The prototype's price label: "$0.13", "$4", "$5.20".
    static func priceText(_ p: Double) -> String {
        p < 1 || p.truncatingRemainder(dividingBy: 1) != 0 ? String(format: "$%.2f", p) : "$\(Int(p))"
    }
}

private func jsNumber(_ x: Double) -> String {
    x == x.rounded() ? String(Int(x)) : String(x)
}

private struct ItemRow: View {
    let item: Item
    let price: Double
    let have: String
    let qty: Int
    let room: Int
    let set: (Int) -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                (Text(item.name) + Text(" \(ShopView.priceText(price))/\(item.one)")
                    .foregroundColor(Theme.dim).font(.custom(Theme.bodyFont, size: 18)))
                    .fixedSize(horizontal: false, vertical: true)
                Text("Have \(have) \(item.unit). \(item.desc)").bodyFont(18).foregroundStyle(Theme.dim)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: 4) {
                RepeatButton(symbol: "−", label: "Less \(item.name)") {
                    guard qty > 0 else { return false }
                    set(max(0, qty - item.step))
                    Feedback.play(.shopDown)
                    return true
                }
                Text("\(qty)").frame(minWidth: 66).accessibilityHidden(true)
                RepeatButton(symbol: "+", label: "More \(item.name)") {
                    let next = min(room, qty + item.step)
                    guard next != qty else { return false }
                    set(next)
                    Feedback.play(.shopUp)
                    return true
                }
            }
        }
        .padding(.vertical, 9)
        .overlay(alignment: .bottom) { DashedLine() }
        .accessibilityElement(children: .contain)
        .accessibilityValue("\(qty) \(item.unit) in the cart")
    }
}

/// A − or + that steps once on touch and keeps stepping while held (an iOS improvement
/// on the prototype, spec §6). `step` returns false when it can't go further.
struct RepeatButton: View {
    let symbol: String
    let label: String
    let step: () -> Bool
    @State private var pressed = false
    @State private var repeater: Task<Void, Never>?

    var body: some View {
        Text(symbol)
            .bodyFont(24)
            .foregroundStyle(pressed ? Color.black : Theme.amber)
            .frame(width: 44, height: 42)
            .background(pressed ? Theme.amber : Color.clear)
            .overlay(Rectangle().strokeBorder(Theme.line, lineWidth: 2))
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard !pressed else { return }
                    pressed = true
                    _ = step()
                    repeater = Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(400))
                        while !Task.isCancelled && pressed {
                            if !step() { break }
                            try? await Task.sleep(for: .milliseconds(70))
                        }
                    }
                }
                .onEnded { _ in
                    pressed = false
                    repeater?.cancel()
                })
            .accessibilityElement()
            .accessibilityLabel(label)
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { _ = step() }
    }
}

struct DashedLine: View {
    var body: some View {
        Rectangle()
            .stroke(style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
            .foregroundStyle(Theme.line)
            .frame(height: 1)
    }
}
