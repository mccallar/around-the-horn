import SwiftUI
import HornEngine

struct TitleView: View {
    @Environment(GameController.self) private var c

    var body: some View {
        let saved = c.savedVoyage
        VStack(alignment: .leading, spacing: 0) {
            SeaSceneView(game: nil)
            Text("AROUND\nTHE HORN")
                .headingFont(21)
                .lineSpacing(10)
                .kerning(1)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.amber)
                .frame(maxWidth: .infinity)
                .padding(.top, 16)
                .padding(.bottom, 4)
                .accessibilityAddTraits(.isHeader)
                .accessibilityLabel("Around the Horn")
                .accessibilityIdentifier("title")
            Text("~ 1849 ~").foregroundStyle(Theme.amber).frame(maxWidth: .infinity).padding(.vertical, 4)
            Text(Copy.titleTagline).bodyFont().foregroundStyle(Theme.dim)
                .multilineTextAlignment(.center).frame(maxWidth: .infinity)
            ChoiceList(choices: [
                Choice(label: "Sail for California") { c.startNewGame() },
            ] + (saved.map { s in
                [Choice(label: "Continue the voyage of the [i]\(Markup.escape(s.ship))[/i]") { c.continueSavedVoyage() }]
            } ?? []) + [
                Choice(label: "Learn about the passage") { c.show(.learn(0)) },
                Choice(label: "See the top ten") { c.show(.topTen(highlight: nil, back: { c.goToTitle() })) },
            ])
        }
    }
}

struct LearnView: View {
    @Environment(GameController.self) private var c
    let page: Int

    var body: some View {
        let p = Copy.learn[page]
        VStack(alignment: .leading, spacing: 0) {
            Heading(p.heading)
            ForEach(p.paragraphs, id: \.self) { Para($0) }
            ChoiceList(choices: [
                page < Copy.learn.count - 1
                    ? Choice(label: "Next") { c.show(.learn(page + 1)) }
                    : Choice(label: "Back to the start") { c.goToTitle() },
            ])
        }
    }
}

struct RoleView: View {
    @Environment(GameController.self) private var c

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Heading("Who are you?")
            Para(Copy.roleIntro)
            ChoiceList(choices: Role.allCases.map { r in Choice(label: r.label) { c.chooseRole(r) } }
                + [Choice(label: "Find out the differences") { c.show(.roleDifferences) }])
        }
    }
}

struct RoleDifferencesView: View {
    @Environment(GameController.self) private var c

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Heading("The differences")
            ForEach(Copy.roleDifferences, id: \.self) { Para($0) }
            ChoiceList(choices: [Choice(label: "Back") { c.show(.role) }])
        }
    }
}

struct NamesView: View {
    @Environment(GameController.self) private var c
    @State private var ship = ""
    @State private var captain = ""
    @State private var crew = ["", "", "", ""]

    var body: some View {
        let s = c.suggestions
        VStack(alignment: .leading, spacing: 0) {
            Heading("Ship & crew")
            FieldLabel("Name your ship:")
            PixelField(text: $ship, placeholder: s.ship, maxLength: 22, label: "Ship's name")
            FieldLabel("Your name, Captain:")
            PixelField(text: $captain, placeholder: s.crew[0], maxLength: 16, label: "Captain's name")
            FieldLabel("Your four crew members:")
            ForEach(0..<4, id: \.self) { i in
                PixelField(text: $crew[i], placeholder: s.crew[i + 1], maxLength: 16, label: "Crew member \(i + 1)")
            }
            ChoiceList(choices: [
                Choice(label: "Use these names") { c.setNames(ship: ship, captain: captain, crew: crew) },
                Choice(label: "Pick new names for me") { c.pickNewNames() },
            ], keyboardShortcuts: false)
        }
    }
}

struct FieldLabel: View {
    let text: String

    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text).bodyFont().foregroundStyle(Theme.dim).padding(.top, 10).padding(.bottom, 4)
    }
}

struct MonthView: View {
    @Environment(GameController.self) private var c

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Heading("When will you sail?")
            Para(Copy.monthIntro)
            ChoiceList(choices: GameData.departures.map { d in
                Choice(label: "\(GameData.months[d.month]) \(d.year)") { c.chooseDeparture(year: d.year, month: d.month) }
            } + [Choice(label: "Ask for advice") { c.message(Copy.monthAdvice) { c.show(.month) } }])
        }
    }
}

struct OutfitIntroView: View {
    @Environment(GameController.self) private var c

    var body: some View {
        let g = c.game!
        VStack(alignment: .leading, spacing: 0) {
            Heading("Outfitting")
            Para(Copy.outfitIntro(money: g.money, ship: Markup.escape(g.ship)))
            PanelBox {
                ForEach(Copy.outfitBullets, id: \.self) { Para($0, size: 18) }
            }
            .padding(.vertical, 10)
            ChoiceList(choices: [Choice(label: "Enter the shop") { c.enterNewYorkShop() }])
        }
    }
}

struct MessageView: View {
    @Environment(GameController.self) private var c
    let text: String
    let label: String
    let then: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SeaSceneView(game: c.game)
            MessageBox(markup: text)
            ChoiceList(choices: [Choice(label: label, primary: true, action: then)])
        }
    }
}

struct TopTenView: View {
    let table: [TopTenEntry]
    let highlight: Int?
    let back: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Heading("The top ten")
            ForEach(Array(table.enumerated()), id: \.offset) { i, r in
                HStack(alignment: .firstTextBaseline) {
                    Text("\(i + 1). \(r.name)")
                    Spacer(minLength: 8)
                    Text(Rank(score: r.score).rawValue).bodyFont(18).foregroundStyle(Theme.dim)
                    Text(formatNumber(Double(r.score))).frame(minWidth: 56, alignment: .trailing)
                }
                .foregroundStyle(highlight == i ? Theme.amber : Theme.ink)
                .bodyFont()
                .padding(.vertical, 3)
                .accessibilityElement(children: .combine)
            }
            Para(Copy.rankLegend, size: 18, color: Theme.dim)
            ChoiceList(choices: [Choice(label: "Back", action: back)])
        }
    }
}
