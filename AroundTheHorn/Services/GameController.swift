import SwiftUI
import HornEngine

/// Owns the voyage (spec §2): which journey is on the table, the engine, which screen is
/// showing, the queue of interrupts being presented, and the travel loop that takes one
/// turn every 0.7 s.
///
/// The engine is a plain class, so SwiftUI can't see it change. Every engine call goes
/// through `run`, which copies `engine.state` into the observed `game` afterwards.
@MainActor @Observable
final class GameController {
    enum Screen {
        /// Which journey: only ever shown when there is more than one.
        case picker
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
        let rank: String
        let place: Int?
    }

    /// Where to go once the interrupt queue is empty.
    enum After {
        case travel, seaMenu, portMenu, repairs, shipyard
    }

    /// Every journey on offer, in the order the picker lists them: each one the engine
    /// has that a skin has been written for. A journey without a skin is not offered,
    /// rather than shown wearing another journey's.
    let journeys: [Journey]
    private let skins: [String: JourneySkin]
    /// The journey whose title card, voyage, save and top ten are in hand, and how it
    /// looks and reads. Only `select` sets them, so they are always the same journey's.
    private(set) var journey: Journey
    private(set) var skin: JourneySkin
    var journeyID: String { journey.id }
    /// With one journey there is nothing to pick, and no way back from its title card.
    var hasPicker: Bool { journeys.count > 1 }
    /// The journeys with a voyage to go back to, as the picker last found them. Kept
    /// here so the picker's rows don't each read and decode a file every time they draw.
    private(set) var inProgress: Set<String> = []

    private(set) var screen: Screen = .title
    /// Changes on every navigation: views key their scroll position and text fields on it.
    private(set) var screenID = 0
    private(set) var game: GameState?
    private(set) var traveling = false
    var muted: Bool {
        didSet {
            persistence.muted = muted
            if !muted { Feedback.play(.unmute) }
        }
    }

    /// Setup choices before the voyage exists.
    var draftRole: Role = .merchant
    private(set) var suggestions: NameSuggestions
    private var draftNames: (ship: String, captain: String, crew: [String]) = ("", "", [])

    private var engine: GameEngine?
    private var queue: [Interrupt] = []
    /// The interrupt on screen: taken off the queue, not yet answered.
    private var showing: Interrupt?
    private var after: After = .travel
    private var travelTask: Task<Void, Never>?
    let persistence: Persistence
    /// Seconds between turns.
    var tickInterval: Duration = .milliseconds(700)

    /// Opens on the picker when there is more than one journey, unless `journey` (the
    /// `-journey <id>` launch argument) names one, or failing that the journey last
    /// chosen is still on offer: then, as with a single journey, on that journey's title
    /// card. An id that names no journey on offer is no choice at all.
    init(persistence: Persistence = .standard, journeys: [Journey] = Journeys.all,
         skins: [JourneySkin] = Skins.all, journey: String? = nil) {
        let offered = journeys.filter { j in skins.contains { $0.id == j.id } }
        precondition(!offered.isEmpty, "no journey has a skin")
        self.persistence = persistence
        self.journeys = offered
        self.skins = Dictionary(skins.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        func offer(_ id: String?) -> Journey? { id.flatMap { id in offered.first { $0.id == id } } }
        let chosen = offer(journey) ?? (offered.count > 1 ? offer(persistence.lastJourney) : nil)
        let first = chosen ?? offered[0]
        self.journey = first
        skin = self.skins[first.id]!
        suggestions = NameSuggestions(first)
        muted = persistence.muted
        if chosen == nil && offered.count > 1 { showPicker() }
    }

    /// The one place the journey in hand changes. False, and nothing changes, for a
    /// journey that is not on offer.
    @discardableResult
    private func select(_ id: String) -> Bool {
        guard let j = journeys.first(where: { $0.id == id }), let s = skins[id] else { return false }
        journey = j
        skin = s
        return true
    }

    private func showPicker() {
        inProgress = Set(journeys.map(\.id).filter(persistence.hasSave))
        show(.picker)
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

    /// The menu you came from: in port or under way. Saves, as every menu does, with
    /// nothing waiting: whatever was, the menu has put aside.
    func backToMenu() {
        guard let g = game else { return show(.title) }
        queue = []
        showing = nil
        save()
        show(g.atPort ? .portMenu : .seaMenu)
    }

    @discardableResult
    func run<T>(_ f: (GameEngine) -> T) -> T {
        let r = f(engine!)
        game = engine!.state
        return r
    }

    /// Asks the engine something without changing anything: what a job costs, whether a
    /// repair is possible. Safe inside a view's body, where `run` is not.
    func read<T>(_ f: (GameEngine) -> T) -> T { f(engine!) }

    /// The voyage, and with it whatever is still waiting to be shown (`pending`): the
    /// engine has already moved on from what raised it, so the two only make sense
    /// together.
    func save() {
        if let g = game, !g.over { persistence.save(g, pending: pending) }
    }

    /// What the last turn raised and the player has not yet dealt with, in order.
    private var pending: [Interrupt] { (showing.map { [$0] } ?? []) + queue }

    // MARK: - Title and setup

    var savedVoyage: GameState? { persistence.loadSave(journeyID) }

    func goToTitle() {
        stopTravel()
        engine = nil
        game = nil
        queue = []
        showing = nil
        show(.title)
    }

    /// Back from a title card to the list of journeys.
    func goToPicker() {
        goToTitle()
        if hasPicker { showPicker() }
    }

    /// A row of the picker: that journey's title card. It is remembered, and the app
    /// opens there next time.
    func chooseJourney(_ id: String) {
        guard select(id) else { return }
        persistence.lastJourney = id
        goToTitle()
    }

    /// Out of a voyage under way to its title card, where it waits to be continued and
    /// another journey can be chosen.
    func leaveVoyage() {
        stopTravel()
        save()
        goToTitle()
    }

    func startNewGame() {
        Feedback.play(.title)
        suggestions = NameSuggestions(journey)
        show(.role)
    }

    /// Starts from a given state on the menu under way (debug starts and tests). A state
    /// from a journey that is not on offer is refused: it would be played with another
    /// journey's words and pictures.
    func loadForDebug(_ s: GameState) {
        guard select(s.journey) else { return }
        engine = GameEngine(state: s)
        game = s
        backToMenu()
    }

    /// Back to where the voyage was left: on a menu, or, if it was left with something
    /// on screen (an arrival's question, a warning, a burial), on that, with whatever was
    /// queued behind it still to come. After those, a menu, not the loop.
    func continueSavedVoyage() {
        guard let v = persistence.loadVoyage(journeyID) else { return goToTitle() }
        let s = v.state
        engine = GameEngine(state: s)
        game = s
        var waiting = v.pending
        // A voyage standing on its last stop has arrived and not yet been told so: no turn
        // can be taken from there, so it would never end. (A save from before the queue
        // was kept can be in this state.)
        let ends = waiting.contains { i in
            switch i {
            case .arrival, .finale: return true
            default: return false
            }
        }
        if s.nextStop == nil && !ends { waiting.append(.arrival(stopID: s.currentStop.id)) }
        // Saved in the first port's stores, or beside them, before it set out: back to
        // them, if the skin says so, so that it can only leave through `depart`.
        if waiting.isEmpty && Self.notYetLeft(s) && skin.words(s).resumesInFirstShop { return enterFirstShop() }
        if waiting.isEmpty { return backToMenu() }
        present(waiting, then: s.atPort ? .portMenu : .seaMenu)
    }

    /// Still at the first port with no turn taken: `depart` has not let it go.
    static func notYetLeft(_ s: GameState) -> Bool { s.atPort && s.stopIndex == 0 && s.day == 0 }

    func chooseRole(_ r: Role) {
        draftRole = r
        suggestions = NameSuggestions(journey)
        show(.names)
    }

    func pickNewNames() {
        suggestions = NameSuggestions(journey)
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
        let s = GameState(journey: journeyID, role: draftRole, ship: draftNames.ship, captain: draftNames.captain,
                          crew: draftNames.crew, startYear: year, startMonth: month)
        engine = GameEngine(state: s)
        game = s
        show(.outfit)
    }

    /// The shop at the first stop, which leads straight to the departure.
    func enterFirstShop() {
        show(.shop(done: { [weak self] in self?.depart() }))
    }

    func depart() {
        if let g = game, let why = skin.words(g).departRefusal {
            return message(why) { [weak self] in self?.enterFirstShop() }
        }
        guard let text = run({ $0.depart() }) else {
            return message(journey.text.noProvisions) { [weak self] in self?.enterFirstShop() }
        }
        show(.depart(text))
    }

    // MARK: - Travel (spec §2: one turn every 0.7 s)

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
        if q.isEmpty { return save() }
        stopTravel()
        present(q, then: .travel)
    }

    func heaveTo() {
        stopTravel()
        backToMenu()
    }

    // MARK: - Interrupts

    /// Shows `q` in order, then goes where `then` says. The save follows the queue: it is
    /// written each time an interrupt goes up and once more when the last is dealt with,
    /// so a voyage left at any point comes back to that point.
    func present(_ q: [Interrupt], then: After) {
        queue = q
        after = then
        advance()
    }

    func advance() {
        showing = nil
        guard !queue.isEmpty else {
            save()
            return finishQueue()
        }
        let next = queue.removeFirst()
        switch next {
        case .message(let t):
            hold(next)
            message(t) { [weak self] in self?.advance() }
        case .choice(let c):
            hold(next)
            if case .stranger = c.kind { Feedback.play(.stranger) } else { Feedback.play(.message) }
            show(.choice(c))
        case .burial(let id, let cause):
            hold(next)
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
            persistence.deleteSave(journeyID)
            Feedback.play(.death)
            Feedback.warning()
            show(.gameOver(title: title, body: body))
        case .finale:
            queue = []
            finish()
        }
    }

    /// `i` is on screen until it is answered. Saved with it there, so that leaving now
    /// comes back to it.
    private func hold(_ i: Interrupt) {
        showing = i
        save()
    }

    func choose(_ c: ChoiceEvent, option: Int) {
        let r = run { $0.resolve(c, option: option) }
        queue = r + queue
        advance()
    }

    func bury(crewID: UUID, cause: String, epitaph: String) {
        run { $0.commitBurial(crewID: crewID, cause: cause, epitaph: epitaph) }
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
        persistence.deleteSave(journeyID)
        let (table, place) = TopTen.inserting(name: game!.crew[0].name, score: score.total,
                                              into: persistence.topTen(journey))
        if place != nil { persistence.saveTopTen(table, for: journeyID) }
        Feedback.play(.win)
        Feedback.success()
        show(.finale(Finale(score: score, rank: journey.rank(score.total), place: place)))
    }

    // MARK: - Menu actions (each takes time, so each may raise interrupts)

    func act(_ q: [Interrupt], then: After) {
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

/// Placeholder names for the names screen: a shuffled draw from the journey's lists.
struct NameSuggestions {
    let ship: String
    let crew: [String]

    init(_ journey: Journey) {
        ship = journey.vesselNames.randomElement() ?? ""
        let names = journey.firstNames.shuffled()
        crew = (0..<5).map { names.isEmpty ? "" : names[$0 % names.count] }
    }
}
