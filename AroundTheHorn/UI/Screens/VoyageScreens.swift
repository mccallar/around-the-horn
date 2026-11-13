import SwiftUI
import HornEngine

// Every screen of a voyage under way. What a thing is called comes from the skin's
// `Words`; what it costs, how long it lasts and whether it is allowed come from the
// `Journey` and the engine.

struct DepartView: View {
    @Environment(GameController.self) private var c
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScenePicture(game: c.game)
            MessageBox(markup: text)
            ChoiceList(choices: [Choice(label: c.game.map(c.skin.words)?.setOut ?? "Continue", primary: true) {
                c.startTravel()
            }])
        }
    }
}

struct TravelView: View {
    @Environment(GameController.self) private var c

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScenePicture(game: c.game, moving: true)
            if let g = c.game { StatusPanel(game: g) }
            ChoiceList(choices: [Choice(label: c.game.map(c.skin.words)?.halt ?? "Continue", primary: true) {
                c.heaveTo()
            }])
        }
    }
}

struct SeaMenuView: View {
    @Environment(GameController.self) private var c

    var body: some View {
        let g = c.game!
        let journey = c.journey, words = c.skin.words(g)
        VStack(alignment: .leading, spacing: 0) {
            ScenePicture(game: g)
            StatusPanel(game: g)
            ChoiceList(choices: [
                Choice(label: words.carryOn, primary: true) { c.startTravel() },
                Choice(label: words.supplies) { c.show(.supplies) },
                Choice(label: words.chart) { c.show(.chart) },
                Choice(label: "\(words.changePace) [dim](\(journey.pace(g.pace).name))[/dim]") { c.show(.pace) },
                Choice(label: "\(words.changeRations) [dim](\(journey.rations(g.rations).name))[/dim]") { c.show(.rations) },
                Choice(label: words.rest) { c.show(.rest) },
                Choice(label: words.repairs) { c.show(.repairs) },
                Choice(label: words.forage) { c.goFishing() },
            ] + c.wayOut)
        }
    }
}

struct PortMenuView: View {
    @Environment(GameController.self) private var c

    var body: some View {
        let g = c.game!
        let journey = c.journey, words = c.skin.words(g)
        VStack(alignment: .leading, spacing: 0) {
            ScenePicture(game: g)
            StatusPanel(game: g)
            Heading(journey.port(g.currentStop.id)?.name ?? g.currentStop.name)
            ChoiceList(choices: [
                Choice(label: words.leavePort, primary: true) { c.startTravel() },
                Choice(label: words.supplies) { c.show(.supplies) },
                Choice(label: words.chart) { c.show(.chart) },
                Choice(label: "\(words.changePace) [dim](\(journey.pace(g.pace).name))[/dim]") { c.show(.pace) },
                Choice(label: "\(words.changeRations) [dim](\(journey.rations(g.rations).name))[/dim]") { c.show(.rations) },
                Choice(label: words.restInPort) { c.show(.rest) },
                Choice(label: words.trade) { c.trade() },
                Choice(label: words.talk) { c.talk() },
                Choice(label: words.buy) { c.buySupplies() },
                Choice(label: words.yard) { c.show(.shipyard) },
            ] + c.wayOut)
        }
    }
}

struct ChoiceEventView: View {
    @Environment(GameController.self) private var c
    let event: ChoiceEvent

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScenePicture(game: c.game)
            MessageBox(markup: event.prompt)
            if let d = event.detail {
                ForEach(d.components(separatedBy: "\n\n"), id: \.self) { Para($0) }
            }
            ChoiceList(choices: event.options.enumerated().map { i, o in
                Choice(label: o.label, enabled: o.enabled) { c.choose(event, option: i) }
            })
        }
    }
}

struct BurialView: View {
    @Environment(GameController.self) private var c
    let crewID: UUID
    let cause: String
    @State private var epitaph = ""

    var body: some View {
        let name = Markup.escape(c.game?.crew.first { $0.id == crewID }?.name ?? "")
        let words = c.game.map(c.skin.words)
        VStack(alignment: .leading, spacing: 0) {
            ScenePicture(game: c.game)
            MessageBox(markup: "[red]\(name) has died of \(cause).[/red]")
            if let words { Para(words.burial(name)) }
            PixelField(text: $epitaph, placeholder: c.journey.text.defaultEpitaph, maxLength: 70, label: "Epitaph")
                .textInputAutocapitalization(.sentences)
            ChoiceList(choices: [Choice(label: words?.commit ?? "Continue", primary: true) {
                c.bury(crewID: crewID, cause: cause, epitaph: epitaph)
            }], keyboardShortcuts: false)
        }
    }
}

struct SuppliesView: View {
    @Environment(GameController.self) private var c

    var body: some View {
        let g = c.game!
        let words = c.skin.words(g)
        let living = g.living
        VStack(alignment: .leading, spacing: 0) {
            Heading("Supplies")
            ForEach(Self.rows(c.journey, g, words), id: \.0) { r in Row(label: r.0) { Text(r.1) }.padding(.vertical, 3) }
            Heading(words.vesselHeading)
            Row(label: words.meters.0) { Text("\(Int(jsRounded(g.hull)))%") }
            Bar(value: g.hull)
            Row(label: words.meters.1) { Text("\(Int(jsRounded(g.sails)))%") }
            Bar(value: g.sails)
            Para(words.suppliesNote, size: 18, color: Theme.dim)
            Heading(words.crewHeading)
            ForEach(living) { p in
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(p.name) + (p.isCaptain ? Text(" (\(words.leaderTag))").foregroundColor(Theme.dim)
                            .font(.custom(Theme.bodyFont, size: 18)) : Text(""))
                        Spacer()
                        Text(Self.condition(p)).bodyFont(18).foregroundStyle(p.ailment == nil ? Theme.dim : Theme.red)
                    }
                    Bar(value: p.hp)
                }
                .padding(.vertical, 6)
                .overlay(alignment: .bottom) { DashedLine() }
                .accessibilityElement(children: .combine)
            }
            if let warning = words.clothesWarning { Para(warning, size: 18) }
            if !g.graves.isEmpty {
                Heading("Lost")
                ForEach(Array(g.graves.enumerated()), id: \.offset) { _, gr in
                    Text("\(gr.name) — \(gr.cause), \(gr.date)").bodyFont(18).foregroundStyle(Theme.dim)
                }
            }
            ChoiceList(choices: [Choice(label: "Back") { c.backToMenu() }])
        }
    }

    /// The money, then everything the journey stocks, in the shop's order.
    static func rows(_ journey: Journey, _ g: GameState, _ words: Words) -> [(String, String)] {
        [(words.cash, "\(words.currency)\(formatNumber(g.money))")]
            + journey.items.map { (words.storeNames[$0.key] ?? $0.name, Stores.amount($0, g, words)) }
    }

    static func condition(_ p: CrewMember) -> String {
        if let a = p.ailment { return a.name + (p.treated ? " · treated" : "") }
        return p.hp > 70 ? "healthy" : p.hp > 40 ? "weary" : "very weak"
    }
}

struct PaceView: View {
    @Environment(GameController.self) private var c

    var body: some View {
        let journey = c.journey, words = c.skin.words(c.game!)
        VStack(alignment: .leading, spacing: 0) {
            Heading(words.paceHeading)
            Para(words.paceNow)
            ChoiceList(choices: Pace.allCases.map { p in
                Choice(label: journey.pace(p).name, detail: journey.pace(p).desc) { c.setPace(p) }
            })
        }
    }
}

struct RationsView: View {
    @Environment(GameController.self) private var c

    var body: some View {
        let journey = c.journey, words = c.skin.words(c.game!)
        VStack(alignment: .leading, spacing: 0) {
            Heading(words.rationsHeading)
            Para(words.rationsNow)
            ChoiceList(choices: Rations.allCases.map { r in
                Choice(label: journey.rations(r).name, detail: journey.rations(r).desc) { c.setRations(r) }
            })
        }
    }
}

struct RestView: View {
    @Environment(GameController.self) private var c

    var body: some View {
        let words = c.skin.words(c.game!)
        VStack(alignment: .leading, spacing: 0) {
            ScenePicture(game: c.game)
            Para(words.restPrompt)
            ChoiceList(choices: c.journey.rules.restChoices.map { n in
                Choice(label: words.restChoice(n)) { c.rest(days: n) }
            } + [Choice(label: "Never mind") { c.backToMenu() }])
        }
    }
}

/// The two meters, by the names the skin gives them.
struct ConditionBox: View {
    let game: GameState
    let meters: (String, String)

    var body: some View {
        PanelBox {
            Row(label: meters.0) { Text("\(Int(jsRounded(game.hull)))%") }
            Bar(value: game.hull)
            Row(label: meters.1) { Text("\(Int(jsRounded(game.sails)))%") }
            Bar(value: game.sails)
        }
        .padding(.vertical, 10)
    }
}

struct RepairsView: View {
    @Environment(GameController.self) private var c

    var body: some View {
        let g = c.game!
        let words = c.skin.words(g)
        VStack(alignment: .leading, spacing: 0) {
            ScenePicture(game: g)
            Heading(words.repairsHeading)
            ConditionBox(game: g, meters: words.meters)
            Para(words.repairsNote, size: 18, color: Theme.dim)
            ChoiceList(choices: [
                Choice(label: words.mend, enabled: c.read { $0.canMendSails }) { c.mendSails() },
                Choice(label: words.patch, enabled: c.read { $0.canPatchHull }) { c.patchHull() },
                Choice(label: "Done") { c.backToMenu() },
            ])
        }
    }
}

struct ShipyardView: View {
    @Environment(GameController.self) private var c

    var body: some View {
        let g = c.game!
        let words = c.skin.words(g)
        VStack(alignment: .leading, spacing: 0) {
            ScenePicture(game: g)
            Heading(words.yardHeading)
            ConditionBox(game: g, meters: words.meters)
            Para(words.yardIntro)
            ChoiceList(choices: [
                Choice(label: words.yardHull(c.read { $0.shipyardHullCost }),
                       enabled: c.read { $0.canRepairHullAtYard }) { c.repairHullAtYard() },
                Choice(label: words.yardSails(c.read { $0.shipyardSailsCost }),
                       enabled: c.read { $0.canRecutSailsAtYard }) { c.recutSailsAtYard() },
                Choice(label: words.leaveYard) { c.backToMenu() },
            ])
        }
    }
}

struct GameOverView: View {
    @Environment(GameController.self) private var c
    let title: String
    let bodyText: String

    var body: some View {
        let g = c.game
        VStack(alignment: .leading, spacing: 0) {
            ScenePicture(game: g)
            MessageBox(markup: "[red]\(title)[/red]")
            Para(bodyText)
            if let g {
                let words = c.skin.words(g)
                Para(words.gameOverLine, color: Theme.dim)
                GravesList(graves: g.graves, heading: words.lostHeading)
            }
            ChoiceList(choices: [Choice(label: "Try again", primary: true) { c.goToTitle() }])
        }
    }
}

struct GravesList: View {
    let graves: [Grave]
    let heading: String

    var body: some View {
        if !graves.isEmpty {
            Heading(heading)
            ForEach(Array(graves.enumerated()), id: \.offset) { _, g in
                VStack(alignment: .leading, spacing: 2) {
                    Text(g.name) + Text(" — \(g.cause), \(g.date)").foregroundColor(Theme.dim)
                        .font(.custom(Theme.bodyFont, size: 18))
                    Text("“\(g.epitaph)”").bodyFont(18).foregroundStyle(Theme.teal)
                }
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .bottom) { DashedLine() }
                .accessibilityElement(children: .combine)
            }
        }
    }
}

struct FinaleView: View {
    @Environment(GameController.self) private var c
    let finale: GameController.Finale

    var body: some View {
        let g = c.game!
        let words = c.skin.words(g)
        let s = finale.score
        VStack(alignment: .leading, spacing: 0) {
            ScenePicture(game: g)
            MessageBox(markup: words.arrival)
            Para(words.arrivalBody)
            Heading("Your score")
            ForEach(Array(s.lines.enumerated()), id: \.offset) { _, l in
                Row(label: l.label) { Text(formatNumber(Double(l.points))) }.padding(.vertical, 3)
            }
            Row(label: "Subtotal") { Text(formatNumber(Double(s.subtotal))) }.padding(.vertical, 3)
            Row(label: words.bonus) { Text("×\(s.multiplier)") }.padding(.vertical, 3)
            Rectangle().fill(Theme.line).frame(height: 2).padding(.top, 3)
            Row(label: "Final score") { Text(formatNumber(Double(s.total))) }
                .foregroundStyle(Theme.amber).padding(.top, 6)
            Text("Rank: \(finale.rank)\(finale.place.map { " · #\($0 + 1) in the top ten!" } ?? "")")
                .foregroundStyle(Theme.amber).frame(maxWidth: .infinity).padding(.vertical, 9)
            GravesList(graves: g.graves, heading: words.lostHeading)
            ChoiceList(choices: [
                Choice(label: words.again, primary: true) { c.goToTitle() },
                Choice(label: "See the top ten") {
                    c.show(.topTen(highlight: finale.place, back: {
                        c.message(words.thanks, label: words.again) { c.goToTitle() }
                    }))
                },
            ])
        }
    }
}
