#if DEBUG
import SwiftUI
import HornEngine

/// Every weather, the port town and torn sails side by side, for checking the scene
/// against the prototype. Debug builds only: launch with `-HornSceneGallery YES`.
struct SceneGallery: View {
    static var requested: Bool { UserDefaults.standard.bool(forKey: "HornSceneGallery") }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                ForEach(Weather.allCases, id: \.self) { w in
                    cell(w.name, Self.state(w), moving: true)
                }
                cell("At port", Self.state(.fair, atPort: true), moving: false)
                cell("Sails 10%", Self.state(.gale, sails: 10), moving: true)
            }
            .padding(8)
        }
        .background(Theme.bg)
    }

    private func cell(_ name: String, _ s: GameState, moving: Bool) -> some View {
        VStack(spacing: 2) {
            SeaSceneView(game: s, moving: moving)
            Text(name).bodyFont(16).foregroundStyle(Theme.dim)
        }
    }

    static func state(_ w: Weather, atPort: Bool = false, sails: Double = 100) -> GameState {
        var s = GameState(role: .merchant, ship: "Gallery", captain: "A", crew: ["B", "C", "D", "E"],
                          startYear: 1849, startMonth: 0)
        s.weather = w
        s.atPort = atPort
        s.sails = sails
        return s
    }
}
#endif
