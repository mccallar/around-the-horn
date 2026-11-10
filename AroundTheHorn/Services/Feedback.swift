import UIKit

/// Sound cues (spec §10), played by `Synth`.
enum Cue {
    case click, message, shopUp, shopDown, harpoon, stranger, unmute
    case title, arrive, death, win, fishHit
}

@MainActor
enum Feedback {
    /// Set by the app to the synth, gated on the mute toggle. Silent until then (tests).
    static var play: (Cue) -> Void = { _ in }

    /// A choice button: light haptic and the click.
    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        play(.click)
    }

    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func warning() { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
}
