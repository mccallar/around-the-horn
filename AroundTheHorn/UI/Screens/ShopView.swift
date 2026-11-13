import SwiftUI
import HornEngine

/// A port's shop (spec §6 "Shop"): a cart per item the journey stocks, capped by what
/// fits aboard, and a bill that turns red past your cash. Holding + or − repeats.
struct ShopView: View {
    @Environment(GameController.self) private var c
    let done: () -> Void
    @State private var cart: [ItemKey: Int] = [:]

    var body: some View {
        let g = c.game!
        let journey = c.journey, words = c.skin.words(g)
        let home = journey.stops.first.flatMap { journey.port($0.id) } ?? journey.ports[0]
        let port = journey.port(g.currentStop.id) ?? home
        let bill = GameEngine.bill(cart, at: port)
        let over = bill > g.money
        let sign = words.currency
        VStack(alignment: .leading, spacing: 0) {
            Heading(port.shop)
            if port.id != home.id {
                Para(words.priceNote(Int(jsRounded((port.mult - 1) * 100))), size: 18, color: Theme.dim)
            }
            PanelBox {
                HStack {
                    Text("\(words.cash) \(sign)\(formatNumber(g.money))")
                    Spacer()
                    Text("Bill ") + Text("\(sign)\(String(format: "%.2f", bill))").foregroundColor(over ? Theme.red : Theme.amber)
                }
                .accessibilityElement(children: .combine)
            }
            .padding(.vertical, 10)
            ForEach(journey.items, id: \.key) { it in
                let have = Stores.have(it, g, words), qty = cart[it.key] ?? 0
                ItemRow(item: it, price: Self.priceLabel(it, port.price(it.key), sign, lot: words.lots.contains(it.key)), have: have,
                        haveUnit: Stores.unit(it, count: have, words), qty: qty,
                        qtyUnit: Stores.unit(it, count: String(qty), words), room: roomFor(it, g)) { cart[it.key] = $0 }
            }
            ChoiceList(choices: [
                Choice(label: over ? "[red]You can't afford all that[/red]"
                           : bill > 0 ? "Pay \(sign)\(String(format: "%.2f", bill)) and leave" : "Leave the shop",
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

    /// What an item costs, as its row writes it: "$4/cord", or by the lot it is sold in,
    /// "$2/100 gallons".
    static func priceLabel(_ it: Item, _ price: Double, _ sign: String, lot: Bool) -> String {
        guard lot, it.step > 1 else { return "\(priceText(price, sign))/\(it.one)" }
        // To the cent, as the bill adds it up.
        return "\(priceText((price * Double(it.step) * 100).rounded() / 100, sign))/\(it.step) \(it.unit)"
    }

    /// The prototype's price label: "$0.13", "$4", "$5.20".
    static func priceText(_ p: Double, _ sign: String) -> String {
        sign + (p < 1 || p.truncatingRemainder(dividingBy: 1) != 0 ? String(format: "%.2f", p) : "\(Int(p))")
    }
}

private struct ItemRow: View {
    let item: Item
    let price: String
    let have: String
    /// The item's unit as it reads after `have` and after `qty`.
    let haveUnit: String
    let qty: Int
    let qtyUnit: String
    let room: Int
    let set: (Int) -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                (Text(item.name) + Text(" \(price)")
                    .foregroundColor(Theme.dim).font(.custom(Theme.bodyFont, size: 18)))
                    .fixedSize(horizontal: false, vertical: true)
                Text("Have \(have) \(haveUnit). \(item.desc)").bodyFont(18).foregroundStyle(Theme.dim)
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
        .accessibilityValue("\(qty) \(qtyUnit) in the cart")
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
