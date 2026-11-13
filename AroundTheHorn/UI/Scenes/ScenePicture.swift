import SwiftUI
import HornEngine

/// The pixel-art scene (spec §3) at the top of most screens: the journey's skin draws
/// it on the 160×80 grid, each logical pixel a rectangle snapped to whole points.
struct ScenePicture: View {
    @Environment(GameController.self) private var c
    let game: GameState?
    var moving = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// One clock for every scene, so the clouds don't jump back when the screen changes.
    static let start = Date()

    var body: some View {
        let scene = c.skin.scene
        let still = Self.frame(c.journey, game, moving: moving, t: 0)
        TimelineView(.animation(paused: reduceMotion)) { tl in
            Canvas(rendersAsynchronously: true) { ctx, size in
                scene.draw(PixelCanvas(ctx, size: size, w: SceneSkin.w, h: SceneSkin.h),
                           still.at(tl.date.timeIntervalSince(Self.start)))
            }
        }
        .aspectRatio(SceneSkin.w / SceneSkin.h, contentMode: .fit)
        .background(Color.black)
        .overlay(Rectangle().strokeBorder(Theme.line, lineWidth: 2))
        .accessibilityElement()
        .accessibilityLabel(scene.label(still))
        .accessibilityAddTraits(.isImage)
    }

    /// What the skin is asked to draw. With no voyage yet (the title card) it is the
    /// journey's fair weather and a sound vessel.
    static func frame(_ journey: Journey, _ g: GameState?, moving: Bool, t: Double) -> SceneFrame {
        SceneFrame(t: t, weather: g?.weather ?? journey.fairWeather, moving: moving, atPort: g?.atPort ?? false,
                   hull: g?.hull ?? 100, sails: g?.sails ?? 100, region: g?.region,
                   hour: g?.hour ?? journey.rules.startHour, state: g)
    }
}

extension SceneFrame {
    /// The same frame at another moment.
    func at(_ t: Double) -> SceneFrame {
        SceneFrame(t: t, weather: weather, moving: moving, atPort: atPort, hull: hull, sails: sails,
                   region: region, hour: hour, state: state)
    }
}
