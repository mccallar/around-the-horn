#if DEBUG
import HornEngine

extension GameController {
    /// `-HornDebugStart <stopID>` (debug builds only): the skin's well-stocked voyage ten
    /// miles short of that stop, on the menu under way. For screenshots and UI tests of
    /// places a real voyage takes minutes to reach.
    func debugStart(at stopID: String, month: Int = 0) {
        guard let i = journey.stops.firstIndex(where: { $0.id == stopID }), i > 0 else { return }
        loadForDebug(skin.debug.start(i, month))
    }
}
#endif
