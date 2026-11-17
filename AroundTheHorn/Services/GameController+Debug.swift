#if DEBUG
import HornEngine

extension GameController {
    /// `-HornDebugStart <stopID>` (debug builds only): the skin's well-stocked voyage ten
    /// miles short of that stop, on the menu under way. For screenshots and UI tests of
    /// places a real voyage takes minutes to reach. With `-HornDebugAtStop YES`, at the
    /// stop itself instead, under way, its arrival already told. With `-HornDebugHull <n>`,
    /// what holds the vessel together is down to `n`%: an ending by wreck a turn or two away.
    /// With `-HornDebugFuel <n>`, `n` of fuel aboard: the last of it, or none. With
    /// `-HornDebugSails <n>`, what drives the vessel is down to `n`%: given out, at 0. With
    /// `-HornDebugFood <n>`, `n` of food aboard: short of what a stop will want to see.
    func debugStart(at stopID: String, month: Int = 0, atStop: Bool = false, hull: Double? = nil, fuel: Double? = nil,
                    sails: Double? = nil, food: Double? = nil) {
        guard let i = journey.stops.firstIndex(where: { $0.id == stopID }), i > 0 else { return }
        var s = skin.debug.start(i, month)
        if atStop {
            s.mile = journey.stops[i].mile
            s.stopIndex = i
        }
        if let hull { s.hull = hull }
        if let fuel { s.fuel = fuel }
        if let sails { s.sails = sails }
        if let food { s.food = food }
        loadForDebug(s)
    }
}
#endif
