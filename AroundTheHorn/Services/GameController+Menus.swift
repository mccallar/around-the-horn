import HornEngine

// The actions of the menus under way and in port (spec §6). Anything that takes time can raise
// interrupts, so it goes through `act`, which presents them and then returns where it
// should.
extension GameController {
    private var menu: After { game?.atPort == true ? .portMenu : .seaMenu }

    func setPace(_ p: Pace) {
        run { $0.state.pace = p }
        backToMenu()
    }

    func setRations(_ r: Rations) {
        run { $0.state.rations = r }
        backToMenu()
    }

    func rest(days: Int) { act(run { $0.rest(days: days) }, then: menu) }

    func mendSails() { act(run { $0.mendSails() }, then: .repairs) }
    func patchHull() { act(run { $0.patchHull() }, then: .repairs) }

    func repairHullAtYard() { act(run { $0.repairHullAtYard() }, then: .shipyard) }
    func recutSailsAtYard() { act(run { $0.recutSailsAtYard() }, then: .shipyard) }

    func trade() { act(run { $0.tradeAtPort() }, then: .portMenu) }

    func talk() {
        let t = run { $0.talk() }
        message(t) { [weak self] in self?.backToMenu() }
    }

    func goFishing() {
        if let refusal = run({ $0.fishingRefusal }) {
            return message(refusal) { [weak self] in self?.backToMenu() }
        }
        show(.fishing)
    }

    /// One throw in the mini-game. False when the tackle is gone.
    func throwHarpoon() -> Bool { run { $0.throwHarpoon() } }

    func endFishing(caught: Int) { act(run { $0.landCatch(caught) }, then: .seaMenu) }

    /// The port menu's yard row: the yard, unless the skin has a question to ask there
    /// instead (`Words.yardQuestion`).
    func openYard() {
        guard let g = game, let ask = skin.words(g).yardQuestion else { return show(.shipyard) }
        act([run(ask)], then: .portMenu)
    }

    func buySupplies() { show(.shop(done: { [weak self] in self?.backToMenu() })) }
}
