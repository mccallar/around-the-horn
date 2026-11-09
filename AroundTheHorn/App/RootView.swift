import SwiftUI
import HornEngine

/// The shell every screen sits in: navy background, top bar with the sound toggle, a
/// centred column at most 540 pt wide, and the scanlines over everything.
struct RootView: View {
    @Environment(GameController.self) private var c

    var body: some View {
        #if DEBUG
        if SceneGallery.requested { return AnyView(SceneGallery()) }
        #endif
        return AnyView(shell)
    }

    private var shell: some View {
        ZStack {
            Theme.bg.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    TopBar()
                    screen
                }
                .foregroundStyle(Theme.ink)
                .bodyFont()
                .frame(maxWidth: Theme.maxWidth)
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 48)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
            .id(c.screenID)
            Scanlines().ignoresSafeArea()
        }
    }

    @ViewBuilder private var screen: some View {
        switch c.screen {
        case .title: TitleView()
        case .learn(let i): LearnView(page: i)
        case .role: RoleView()
        case .roleDifferences: RoleDifferencesView()
        case .names: NamesView()
        case .month: MonthView()
        case .outfit: OutfitIntroView()
        case .message(let t, let label, let then): MessageView(text: t, label: label, then: then)
        case .topTen(let hi, let back): TopTenView(table: c.persistence.topTen(), highlight: hi, back: back)
        case .shop(let done): ShopView(done: done)
        case .depart(let t): DepartView(text: t)
        case .travel: TravelView()
        case .seaMenu: SeaMenuView()
        case .portMenu: PortMenuView()
        case .choice(let e): ChoiceEventView(event: e)
        case .burial(let id, let cause): BurialView(crewID: id, cause: cause)
        case .supplies: SuppliesView()
        case .chart: NotYetView(what: "Chart")
        case .pace: PaceView()
        case .rations: RationsView()
        case .rest: RestView()
        case .repairs: RepairsView()
        case .shipyard: ShipyardView()
        case .fishing: NotYetView(what: "Fishing")
        case .finale(let f): FinaleView(finale: f)
        case .gameOver(let title, let body): GameOverView(title: title, bodyText: body)
        }
    }
}

struct TopBar: View {
    @Environment(GameController.self) private var c

    var body: some View {
        @Bindable var c = c
        HStack {
            Text("AROUND THE HORN · 1849").accessibilityHidden(true)
            Spacer()
            Button(c.muted ? "♪ off" : "♪ on") { c.muted.toggle() }
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .overlay(Rectangle().strokeBorder(Theme.line, lineWidth: 1))
                .accessibilityLabel(c.muted ? "Sound off" : "Sound on")
                .accessibilityHint("Toggles sound")
        }
        .bodyFont(18)
        .foregroundStyle(Theme.dim)
        .padding(.bottom, 8)
    }
}
