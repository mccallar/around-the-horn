#if DEBUG
import HornEngine

extension GameController {
    /// `-HornDebugStart <stopID>` (debug builds only): the skin's well-stocked voyage ten
    /// miles short of that stop, on the menu under way. For screenshots and UI tests of
    /// places a real voyage takes minutes to reach. With `-HornDebugAtStop YES`, at the
    /// stop itself instead, under way, its arrival already told.
    func debugStart(at stopID: String, month: Int = 0, atStop: Bool = false) {
        guard let i = journey.stops.firstIndex(where: { $0.id == stopID }), i > 0 else { return }
        var s = skin.debug.start(i, month)
        if atStop {
            s.mile = journey.stops[i].mile
            s.stopIndex = i
        }
        loadForDebug(s)
    }
}
#endif
