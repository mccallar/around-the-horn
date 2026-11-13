#if DEBUG
import SwiftUI
import HornEngine

/// Every weather of the journey and the skin's extra cells side by side, for checking
/// the scene against its reference. Debug builds only: launch with `-HornSceneGallery YES`
/// (and `-journey <id>` for a journey other than the first).
struct SceneGallery: View {
    @Environment(GameController.self) private var c

    static var requested: Bool { UserDefaults.standard.bool(forKey: "HornSceneGallery") }

    var body: some View {
        let journey = c.journey
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                ForEach(journey.weathers, id: \.self) { w in
                    cell(w.name, Self.state(journey) { $0.weather = w }, moving: true)
                }
                ForEach(Array(c.skin.debug.gallery.enumerated()), id: \.offset) { _, extra in
                    cell(extra.name, Self.state(journey, extra.set), moving: extra.moving)
                }
            }
            .padding(8)
        }
        .background(Theme.bg)
    }

    private func cell(_ name: String, _ s: GameState, moving: Bool) -> some View {
        VStack(spacing: 2) {
            ScenePicture(game: s, moving: moving)
            Text(name).bodyFont(16).foregroundStyle(Theme.dim)
        }
    }

    /// A fresh voyage under way in fair weather, then whatever the cell is showing.
    static func state(_ journey: Journey, _ set: (inout GameState) -> Void) -> GameState {
        let d = journey.departures.first ?? (year: 0, month: 0)
        var s = GameState(journey: journey.id, role: .merchant, ship: "Gallery", captain: "A",
                          crew: ["B", "C", "D", "E"], startYear: d.year, startMonth: d.month)
        s.atPort = false
        set(&s)
        return s
    }
}
#endif
