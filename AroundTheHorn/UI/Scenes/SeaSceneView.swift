import SwiftUI
import HornEngine

/// The pixel-art sea scene. M5 draws it; until then, the frame it will fill.
struct SeaSceneView: View {
    let game: GameState?
    var moving = false

    var body: some View {
        Rectangle()
            .fill(Color.black)
            .aspectRatio(2, contentMode: .fit)
            .overlay(Rectangle().strokeBorder(Theme.line, lineWidth: 2))
            .accessibilityHidden(true)
    }
}
