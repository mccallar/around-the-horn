import SwiftUI
import HornEngine

/// Which journey. Only shown when there is more than one; a journey with a voyage in
/// progress says so.
struct PickerView: View {
    @Environment(GameController.self) private var c

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Heading("Choose a journey")
            ChoiceList(choices: c.journeys.map { j in
                let saved = c.persistence.loadSave(j.id) != nil
                return Choice(label: j.title + (saved ? " [amber]· in progress[/amber]" : ""), detail: j.subtitle) {
                    c.chooseJourney(j.id)
                }
            })
        }
    }
}

struct TitleView: View {
    @Environment(GameController.self) private var c

    var body: some View {
        let saved = c.savedVoyage
        let card = c.skin.card
        VStack(alignment: .leading, spacing: 0) {
            ScenePicture(game: nil)
            Text(card.title)
                .headingFont(21)
                .lineSpacing(10)
                .kerning(1)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.amber)
                .frame(maxWidth: .infinity)
                .padding(.top, 16)
                .padding(.bottom, 4)
                .accessibilityAddTraits(.isHeader)
                .accessibilityLabel(c.journey.title)
                .accessibilityIdentifier("title")
            Text(card.year).foregroundStyle(Theme.amber).frame(maxWidth: .infinity).padding(.vertical, 4)
            Text(card.tagline).bodyFont().foregroundStyle(Theme.dim)
                .multilineTextAlignment(.center).frame(maxWidth: .infinity)
            ChoiceList(choices: [
                Choice(label: card.start) { c.startNewGame() },
            ] + (saved.map { s in
                [Choice(label: card.resume(Markup.escape(s.ship))) { c.continueSavedVoyage() }]
            } ?? []) + [
                Choice(label: card.learn) { c.show(.learn(0)) },
                Choice(label: "See the top ten") { c.show(.topTen(highlight: nil, back: { c.goToTitle() })) },
            ] + (c.hasPicker ? [Choice(label: "Choose another journey") { c.goToPicker() }] : []))
        }
    }
}

struct LearnView: View {
    @Environment(GameController.self) private var c
    let page: Int

    var body: some View {
        let pages = c.skin.card.learnPages
        let p = pages[min(page, pages.count - 1)]
        VStack(alignment: .leading, spacing: 0) {
            Heading(p.heading)
            ForEach(p.paragraphs, id: \.self) { Para($0) }
            ChoiceList(choices: [
                page < pages.count - 1
                    ? Choice(label: "Next") { c.show(.learn(page + 1)) }
                    : Choice(label: "Back to the start") { c.goToTitle() },
            ])
        }
    }
}

struct RoleView: View {
    @Environment(GameController.self) private var c

    var body: some View {
        let card = c.skin.card
        VStack(alignment: .leading, spacing: 0) {
            Heading(card.roleHeading)
            Para(card.roleIntro)
            ChoiceList(choices: Role.allCases.map { r in Choice(label: c.journey.role(r).label) { c.chooseRole(r) } }
                + [Choice(label: card.differencesAction) { c.show(.roleDifferences) }])
        }
    }
}

struct RoleDifferencesView: View {
    @Environment(GameController.self) private var c

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Heading(c.skin.card.differencesHeading)
            ForEach(c.skin.card.differences, id: \.self) { Para($0) }
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
        let card = c.skin.card
        VStack(alignment: .leading, spacing: 0) {
            Heading(card.namesHeading)
            FieldLabel(card.vesselPrompt)
            PixelField(text: $ship, placeholder: s.ship, maxLength: 22, label: card.vesselLabel)
            FieldLabel(card.leaderPrompt)
            PixelField(text: $captain, placeholder: s.crew[0], maxLength: 16, label: card.leaderLabel)
            FieldLabel(card.crewPrompt)
            ForEach(0..<4, id: \.self) { i in
                PixelField(text: $crew[i], placeholder: s.crew[i + 1], maxLength: 16, label: "\(card.crewLabel) \(i + 1)")
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
        let card = c.skin.card
        VStack(alignment: .leading, spacing: 0) {
            Heading(card.monthHeading)
            Para(card.monthIntro)
            ChoiceList(choices: c.journey.departures.map { d in
                Choice(label: "\(monthNames[d.month]) \(d.year)") { c.chooseDeparture(year: d.year, month: d.month) }
            } + [Choice(label: "Ask for advice") { c.message(card.monthAdvice) { c.show(.month) } }])
        }
    }
}

struct OutfitIntroView: View {
    @Environment(GameController.self) private var c

    var body: some View {
        let g = c.game!
        let card = c.skin.card
        VStack(alignment: .leading, spacing: 0) {
            Heading(card.outfitHeading)
            Para(card.outfitIntro(g))
            PanelBox {
                ForEach(card.outfitBullets, id: \.self) { Para($0, size: 18) }
            }
            .padding(.vertical, 10)
            ChoiceList(choices: [Choice(label: card.enterShop) { c.enterFirstShop() }])
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
            ScenePicture(game: c.game)
            MessageBox(markup: text)
            ChoiceList(choices: [Choice(label: label, primary: true, action: then)])
        }
    }
}

struct TopTenView: View {
    @Environment(GameController.self) private var c
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
                    Text(c.journey.rank(r.score)).bodyFont(18).foregroundStyle(Theme.dim)
                    Text(formatNumber(Double(r.score))).frame(minWidth: 56, alignment: .trailing)
                }
                .foregroundStyle(highlight == i ? Theme.amber : Theme.ink)
                .bodyFont()
                .padding(.vertical, 3)
                .accessibilityElement(children: .combine)
            }
            Para(c.skin.card.rankLegend, size: 18, color: Theme.dim)
            ChoiceList(choices: [Choice(label: "Back", action: back)])
        }
    }
}
