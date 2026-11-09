#if DEBUG
import HornEngine

extension GameController {
    /// `-HornDebugStart <stopID>` (debug builds only): a well-stocked merchant ten miles
    /// short of that stop, on the sea menu. For screenshots and UI tests of places a
    /// real voyage takes minutes to reach.
    func debugStart(at stopID: String, month: Int = 0) {
        guard let i = GameData.stops.firstIndex(where: { $0.id == stopID }), i > 0 else { return }
        var s = GameState(role: .merchant, ship: "Resolute", captain: "Ezra",
                          crew: ["Hannah", "Silas", "Mercy", "Tobias"], startYear: 1849, startMonth: month)
        s.stopIndex = i - 1
        s.mile = GameData.stops[i].mile - 10
        s.day = s.mile / 110
        s.food = 1500
        s.water = 600
        s.limes = 10
        s.meds = 3
        s.clothes = 5
        s.sailcloth = 3
        s.timber = 3
        s.tackle = 60
        s.hull = 72
        s.sails = 64
        s.money = 600
        s.atPort = false
        if s.mile > 7800 { s.passage = .horn }
        loadForDebug(s)
    }
}
#endif
