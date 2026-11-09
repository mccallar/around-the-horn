import SwiftUI
import HornEngine

struct DepartView: View {
    @Environment(GameController.self) private var c
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SeaSceneView(game: c.game)
            MessageBox(markup: text)
            ChoiceList(choices: [Choice(label: "Set sail", primary: true) { c.startTravel() }])
        }
    }
}

struct TravelView: View {
    @Environment(GameController.self) private var c

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SeaSceneView(game: c.game, moving: true)
            if let g = c.game { StatusPanel(game: g) }
            ChoiceList(choices: [Choice(label: "Heave to & take stock", primary: true) { c.heaveTo() }])
        }
    }
}

struct SeaMenuView: View {
    @Environment(GameController.self) private var c

    var body: some View {
        let g = c.game!
        VStack(alignment: .leading, spacing: 0) {
            SeaSceneView(game: g)
            StatusPanel(game: g)
            ChoiceList(choices: [
                Choice(label: "Continue on your voyage", primary: true) { c.startTravel() },
                Choice(label: "Check supplies & crew") { c.show(.supplies) },
                Choice(label: "Look at the chart") { c.show(.chart) },
                Choice(label: "Change pace [dim](\(g.pace.name))[/dim]") { c.show(.pace) },
                Choice(label: "Change rations [dim](\(g.rations.name))[/dim]") { c.show(.rations) },
                Choice(label: "Heave to and rest") { c.show(.rest) },
                Choice(label: "Make repairs") { c.show(.repairs) },
                Choice(label: "Go fishing") { c.goFishing() },
            ])
        }
    }
}

struct PortMenuView: View {
    @Environment(GameController.self) private var c

    var body: some View {
        let g = c.game!
        let port = GameData.port(g.currentStop.portID ?? .ny)
        VStack(alignment: .leading, spacing: 0) {
            SeaSceneView(game: g)
            StatusPanel(game: g)
            Heading(port.name)
            ChoiceList(choices: [
                Choice(label: "Weigh anchor and sail on", primary: true) { c.startTravel() },
                Choice(label: "Check supplies & crew") { c.show(.supplies) },
                Choice(label: "Look at the chart") { c.show(.chart) },
                Choice(label: "Change pace [dim](\(g.pace.name))[/dim]") { c.show(.pace) },
                Choice(label: "Change rations [dim](\(g.rations.name))[/dim]") { c.show(.rations) },
                Choice(label: "Rest ashore") { c.show(.rest) },
                Choice(label: "Attempt to trade") { c.trade() },
                Choice(label: "Talk to people") { c.talk() },
                Choice(label: "Buy supplies") { c.buySupplies() },
                Choice(label: "Visit the shipyard") { c.show(.shipyard) },
            ])
        }
    }
}

struct ChoiceEventView: View {
    @Environment(GameController.self) private var c
    let event: ChoiceEvent

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SeaSceneView(game: c.game)
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
        VStack(alignment: .leading, spacing: 0) {
            SeaSceneView(game: c.game)
            MessageBox(markup: "[red]\(name) has died of \(cause).[/red]")
            Para("The crew sews \(name) into a sailcloth shroud, weighted with a cannonball. What words will you say?")
            PixelField(text: $epitaph, placeholder: GameEngine.defaultEpitaph, maxLength: 70, label: "Epitaph")
                .textInputAutocapitalization(.sentences)
            ChoiceList(choices: [Choice(label: "Commit to the deep", primary: true) {
                c.bury(crewID: crewID, cause: cause, epitaph: epitaph)
            }], keyboardShortcuts: false)
        }
    }
}

struct SuppliesView: View {
    @Environment(GameController.self) private var c

    var body: some View {
        let g = c.game!
        let living = g.living
        VStack(alignment: .leading, spacing: 0) {
            Heading("Supplies")
            ForEach(Self.rows(g), id: \.0) { r in Row(label: r.0) { Text(r.1) }.padding(.vertical, 3) }
            Heading("The \(g.ship)")
            Row(label: "Hull") { Text("\(Int(jsRounded(g.hull)))%") }
            Bar(value: g.hull)
            Row(label: "Sails") { Text("\(Int(jsRounded(g.sails)))%") }
            Bar(value: g.sails)
            Para("Pace: \(g.pace.name) · Rations: \(g.rations.name)"
                 + (g.noCitrus > 20 ? " · [red]\(g.noCitrus) days without citrus[/red]" : ""),
                 size: 18, color: Theme.dim)
            Heading("Crew · health \(g.healthLabel.text)")
            ForEach(living) { p in
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(p.name) + (p.isCaptain ? Text(" (captain)").foregroundColor(Theme.dim)
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
            if g.clothes < living.count {
                Para("[red]Only \(g.clothes) of \(living.count) have woolens.[/red]", size: 18)
            }
            if !g.graves.isEmpty {
                Heading("Lost")
                ForEach(Array(g.graves.enumerated()), id: \.offset) { _, gr in
                    Text("\(gr.name) — \(gr.cause), \(gr.date)").bodyFont(18).foregroundStyle(Theme.dim)
                }
            }
            ChoiceList(choices: [Choice(label: "Back") { c.backToMenu() }])
        }
    }

    static func rows(_ g: GameState) -> [(String, String)] {
        [("Cash", "$\(formatNumber(g.money))"), ("Provisions", "\(formatNumber(g.food)) lbs"),
         ("Fresh water", "\(formatNumber(g.water)) gal"),
         ("Citrus", "\(ShopView.have(GameData.item(.limes), g)) crates"), ("Medicine", "\(g.meds) kits"),
         ("Woolens", "\(g.clothes) sets"), ("Sailcloth", "\(g.sailcloth) bolts"), ("Timber", "\(g.timber) bundles"),
         ("Fishing tackle", "\(g.tackle) throws")]
    }

    static func condition(_ p: CrewMember) -> String {
        if let a = p.ailment { return a.name + (p.treated ? " · treated" : "") }
        return p.hp > 70 ? "healthy" : p.hp > 40 ? "weary" : "very weak"
    }
}

struct PaceView: View {
    @Environment(GameController.self) private var c

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Heading("Pace")
            Para("The pace is currently [amber]\(c.game!.pace.name)[/amber].")
            ChoiceList(choices: Pace.allCases.map { p in Choice(label: p.name, detail: p.desc) { c.setPace(p) } })
        }
    }
}

struct RationsView: View {
    @Environment(GameController.self) private var c

    var body: some View {
        let g = c.game!
        let n = g.living.count
        VStack(alignment: .leading, spacing: 0) {
            Heading("Rations")
            Para("Rations are currently [amber]\(g.rations.name)[/amber]. With \(n) aboard, that's \(n * Int(g.rations.lb)) lbs a day.")
            ChoiceList(choices: Rations.allCases.map { r in Choice(label: r.name, detail: r.desc) { c.setRations(r) } })
        }
    }
}

struct RestView: View {
    @Environment(GameController.self) private var c

    var body: some View {
        let port = c.game!.atPort
        VStack(alignment: .leading, spacing: 0) {
            SeaSceneView(game: c.game)
            Para(port ? "Your crew can sleep ashore, eat fresh food and recover. How many days?"
                      : "You heave to, and the crew rests below. How many days?")
            ChoiceList(choices: [1, 2, 3, 5].map { d in Choice(label: "\(d) day\(d > 1 ? "s" : "")") { c.rest(days: d) } }
                + [Choice(label: "Never mind") { c.backToMenu() }])
        }
    }
}

struct ConditionBox: View {
    let game: GameState

    var body: some View {
        PanelBox {
            Row(label: "Hull") { Text("\(Int(jsRounded(game.hull)))%") }
            Bar(value: game.hull)
            Row(label: "Sails") { Text("\(Int(jsRounded(game.sails)))%") }
            Bar(value: game.sails)
        }
        .padding(.vertical, 10)
    }
}

struct RepairsView: View {
    @Environment(GameController.self) private var c

    var body: some View {
        let g = c.game!
        let shipwright = g.role == .shipwright
        VStack(alignment: .leading, spacing: 0) {
            SeaSceneView(game: g)
            Heading("Repairs")
            ConditionBox(game: g)
            Para("Each repair takes a day.\(shipwright ? " As a shipwright, your repairs go much further." : "")",
                 size: 18, color: Theme.dim)
            ChoiceList(choices: [
                Choice(label: "Mend sails — 1 bolt of sailcloth [dim](have \(g.sailcloth))[/dim]",
                       enabled: g.sailcloth >= 1 && g.sails < 100) { c.mendSails() },
                Choice(label: "Patch the hull — 1 bundle of timber [dim](have \(g.timber))[/dim]",
                       enabled: g.timber >= 1 && g.hull < 100) { c.patchHull() },
                Choice(label: "Done") { c.backToMenu() },
            ])
        }
    }
}

struct ShipyardView: View {
    @Environment(GameController.self) private var c

    var body: some View {
        let g = c.game!
        let mult = GameData.port(g.currentStop.portID ?? .ny).mult
        let hullCost = Int(((100 - g.hull) * 2.5 * mult).rounded(.up))
        let sailCost = Int(((100 - g.sails) * 1.8 * mult).rounded(.up))
        VStack(alignment: .leading, spacing: 0) {
            SeaSceneView(game: g)
            Heading("Shipyard")
            ConditionBox(game: g)
            Para("You have [amber]$\(formatNumber(g.money))[/amber]. Each job takes a day.")
            ChoiceList(choices: [
                Choice(label: "Haul out and repair the hull — $\(hullCost)",
                       enabled: g.hull < 99.5 && g.money >= Double(hullCost)) { c.repairHullAtYard() },
                Choice(label: "Have new sails cut — $\(sailCost)",
                       enabled: g.sails < 99.5 && g.money >= Double(sailCost)) { c.recutSailsAtYard() },
                Choice(label: "Leave the shipyard") { c.backToMenu() },
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
            SeaSceneView(game: g)
            MessageBox(markup: "[red]\(title)[/red]")
            Para(bodyText)
            if let g {
                Para("\(g.dateText) · \(formatNumber(Double(g.mile))) nautical miles from New York.", color: Theme.dim)
                GravesList(graves: g.graves)
            }
            ChoiceList(choices: [Choice(label: "Try again", primary: true) { c.goToTitle() }])
        }
    }
}

struct GravesList: View {
    let graves: [Grave]

    var body: some View {
        if !graves.isEmpty {
            Heading("Lost on the voyage")
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
        let s = finale.score
        VStack(alignment: .leading, spacing: 0) {
            SeaSceneView(game: g)
            MessageBox(markup: "Land ho! The [i]\(Markup.escape(g.ship))[/i] passes through the Golden Gate on \(g.dateText), after \(g.day) days at sea.")
            Para("San Francisco Bay is a forest of masts — hundreds of ships abandoned by crews who ran for the gold fields the moment the anchor dropped. "
                 + (g.living.count > 1 ? "Your crew is already eyeing the hills." : "You stand alone on the deck, looking at the hills."))
            Heading("Your score")
            ForEach(Array(s.lines.enumerated()), id: \.offset) { _, l in
                Row(label: l.label) { Text(formatNumber(Double(l.points))) }.padding(.vertical, 3)
            }
            Row(label: "Subtotal") { Text(formatNumber(Double(s.subtotal))) }.padding(.vertical, 3)
            Row(label: "Bonus for being a \(g.role.title)") { Text("×\(s.multiplier)") }.padding(.vertical, 3)
            Rectangle().fill(Theme.line).frame(height: 2).padding(.top, 3)
            Row(label: "Final score") { Text(formatNumber(Double(s.total))) }
                .foregroundStyle(Theme.amber).padding(.top, 6)
            Text("Rank: \(finale.rank.rawValue)\(finale.place.map { " · #\($0 + 1) in the top ten!" } ?? "")")
                .foregroundStyle(Theme.amber).frame(maxWidth: .infinity).padding(.vertical, 9)
            GravesList(graves: g.graves)
            ChoiceList(choices: [
                Choice(label: "Sail again", primary: true) { c.goToTitle() },
                Choice(label: "See the top ten") {
                    c.show(.topTen(highlight: finale.place, back: {
                        c.message("Thanks for sailing.", label: "Sail again") { c.goToTitle() }
                    }))
                },
            ])
        }
    }
}

struct NotYetView: View {
    @Environment(GameController.self) private var c
    let what: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Heading(what)
            Para("Coming in a later milestone.", color: Theme.dim)
            ChoiceList(choices: [Choice(label: "Back") { c.backToMenu() }])
        }
    }
}
