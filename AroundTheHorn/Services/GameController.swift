import SwiftUI
import HornEngine

/// Owns the voyage (spec §2): the engine, which screen is showing, the queue of
/// interrupts being presented, and the travel loop that sails one day every 0.7 s.
///
/// The engine is a plain class, so SwiftUI can't see it change. Every engine call goes
/// through `run`, which copies `engine.state` into the observed `game` afterwards.
@MainActor @Observable
final class GameController {
    enum Screen {
        case title
        case learn(Int)
        case role, roleDifferences, names, month, outfit
        case shop(done: () -> Void)
        case depart(String)
        case travel, seaMenu, portMenu
        case message(String, label: String, then: () -> Void)
        case choice(ChoiceEvent)
        case burial(crewID: UUID, cause: String)
        case supplies, chart, pace, rations, rest
        case repairs, shipyard, fishing
        case finale(Finale)
        case gameOver(title: String, body: String)
        case topTen(highlight: Int?, back: () -> Void)
    }

    struct Finale {
        let score: Score
        let rank: Rank
        let place: Int?
    }

    /// Where to go once the interrupt queue is empty.
    enum After {
        case travel, seaMenu, portMenu, repairs, shipyard
    }

    private(set) var screen: Screen = .title
    /// Changes on every navigation: views key their scroll position and text fields on it.
    private(set) var screenID = 0
    private(set) var game: GameState?
    private(set) var traveling = false
    var muted: Bool {
        didSet { persistence.muted = muted }
    }

    /// Setup choices before the voyage exists.
    var draftRole: Role = .merchant
    private(set) var suggestions = NameSuggestions()
    private var draftNames: (ship: String, captain: String, crew: [String]) = ("", "", [])

    private var engine: GameEngine?
    private var queue: [Interrupt] = []
    private var after: After = .travel
    private var travelTask: Task<Void, Never>?
    let persistence: Persistence
    /// Seconds between sailing days.
    var tickInterval: Duration = .milliseconds(700)

    init(persistence: Persistence = .standard) {
        self.persistence = persistence
        muted = persistence.muted
    }

    // MARK: - Navigation

    func show(_ s: Screen) {
        screen = s
        screenID += 1
    }

    func message(_ text: String, label: String = "Continue", then: @escaping () -> Void) {
        Feedback.play(.message)
        show(.message(text, label: label, then: then))
    }

    /// The menu you came from: ashore or at sea. Saves, as every menu does.
    func backToMenu() {
        guard let g = game else { return show(.title) }
        save()
        show(g.atPort ? .portMenu : .seaMenu)
    }

    @discardableResult
    func run<T>(_ f: (GameEngine) -> T) -> T {
        let r = f(engine!)
        game = engine!.state
        return r
    }

    func save() {
        if let g = game, !g.over { persistence.save(g) }
    }

    // MARK: - Title and setup

    var savedVoyage: GameState? { persistence.loadSave() }

    func goToTitle() {
        stopTravel()
        engine = nil
        game = nil
        queue = []
        show(.title)
    }

    func startNewGame() {
        Feedback.play(.title)
        suggestions = NameSuggestions()
        show(.role)
    }

    func continueSavedVoyage() {
        guard let s = persistence.loadSave() else { return goToTitle() }
        engine = GameEngine(state: s)
        game = s
        backToMenu()
    }

    func chooseRole(_ r: Role) {
        draftRole = r
        suggestions = NameSuggestions()
        show(.names)
    }

    func pickNewNames() {
        suggestions = NameSuggestions()
        show(.names)
    }

    /// Blank fields take their suggestion.
    func setNames(ship: String, captain: String, crew: [String]) {
        func pick(_ typed: String, _ suggested: String, _ max: Int) -> String {
            let t = typed.trimmingCharacters(in: .whitespacesAndNewlines)
            return String((t.isEmpty ? suggested : t).prefix(max))
        }
        draftNames = (pick(ship, suggestions.ship, 22), pick(captain, suggestions.crew[0], 16),
                      (0..<4).map { pick(crew[$0], suggestions.crew[$0 + 1], 16) })
        show(.month)
    }

    func chooseDeparture(year: Int, month: Int) {
        let s = GameState(role: draftRole, ship: draftNames.ship, captain: draftNames.captain,
                          crew: draftNames.crew, startYear: year, startMonth: month)
        engine = GameEngine(state: s)
        game = s
        show(.outfit)
    }

    func enterNewYorkShop() {
        show(.shop(done: { [weak self] in self?.departNewYork() }))
    }

    func departNewYork() {
        guard let text = run({ $0.departNewYork() }) else {
            return message(GameEngine.noProvisionsRefusal) { [weak self] in self?.enterNewYorkShop() }
        }
        show(.depart(text))
    }

    // MARK: - Travel (spec §2: one day every 0.7 s)

    func startTravel() {
        run { $0.setSail() }
        traveling = true
        show(.travel)
        travelTask?.cancel()
        let interval = tickInterval
        travelTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: interval)
                guard !Task.isCancelled, let self, self.traveling else { return }
                self.tick()
            }
        }
    }

    func stopTravel() {
        traveling = false
        travelTask?.cancel()
        travelTask = nil
    }

    func tick() {
        let q = run { $0.sailDay() }
        save()
        if !q.isEmpty {
            stopTravel()
            present(q, then: .travel)
        }
    }

    func heaveTo() {
        stopTravel()
        backToMenu()
    }

    // MARK: - Interrupts

    func present(_ q: [Interrupt], then: After) {
        queue = q
        after = then
        advance()
    }

    func advance() {
        guard !queue.isEmpty else { return finishQueue() }
        switch queue.removeFirst() {
        case .message(let t):
            message(t) { [weak self] in self?.advance() }
        case .choice(let c):
            if case .stranger = c.kind { Feedback.play(.stranger) } else { Feedback.play(.message) }
            show(.choice(c))
        case .burial(let id, let cause):
            Feedback.play(.death)
            Feedback.warning()
            show(.burial(crewID: id, cause: cause))
        case .arrival(let id):
            Feedback.play(.arrive)
            Feedback.success()
            queue = run { $0.beginArrival(id) } + queue
            advance()
        case .enterPort:
            queue = []
            backToMenu()
        case .gameOver(let title, let body):
            queue = []
            stopTravel()
            persistence.deleteSave()
            Feedback.play(.death)
            Feedback.warning()
            show(.gameOver(title: title, body: body))
        case .finale:
            queue = []
            finish()
        }
    }

    func choose(_ c: ChoiceEvent, option: Int) {
        let r = run { $0.resolve(c, option: option) }
        save()
        queue = r + queue
        advance()
    }

    func bury(crewID: UUID, cause: String, epitaph: String) {
        run { $0.commitBurial(crewID: crewID, cause: cause, epitaph: epitaph) }
        save()
        advance()
    }

    private func finishQueue() {
        guard let g = game, !g.over else { return }
        switch after {
        case .travel: startTravel()
        case .seaMenu, .portMenu: backToMenu()
        case .repairs: show(.repairs)
        case .shipyard: show(.shipyard)
        }
    }

    private func finish() {
        stopTravel()
        let score = run { $0.finish() }
        persistence.deleteSave()
        let (table, place) = TopTen.inserting(name: game!.crew[0].name, score: score.total, into: persistence.topTen())
        if place != nil { persistence.saveTopTen(table) }
        Feedback.play(.win)
        Feedback.success()
        show(.finale(Finale(score: score, rank: Rank(score: score.total), place: place)))
    }

    // MARK: - Menu actions (each takes time, so each may raise interrupts)

    func act(_ q: [Interrupt], then: After) {
        save()
        present(q, then: then)
    }

    // MARK: - Lifecycle

    /// Spec §2: on background, stop the clock and save; on return, a menu, not the loop.
    func scenePhaseChanged(_ phase: ScenePhase) {
        switch phase {
        case .background:
            let wasTraveling = traveling
            stopTravel()
            save()
            if wasTraveling { backToMenu() }
        default: break
        }
    }
}

/// Placeholder names for the names screen: a shuffled draw from the prototype's lists.
struct NameSuggestions {
    let ship: String
    let crew: [String]

    init() {
        ship = GameData.shipNames.randomElement()!
        crew = Array(GameData.firstNames.shuffled().prefix(5))
    }
}
