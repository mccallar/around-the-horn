import UIKit

/// Sound cues (spec §10). The synth arrives in M8; until then these are silent.
enum Cue {
    case click, message, shopUp, shopDown, harpoon, stranger
    case title, arrive, death, win, fishHit
}

@MainActor
enum Feedback {
    static var play: (Cue) -> Void = { _ in }

    /// A choice button: light haptic and the click.
    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        play(.click)
    }

    static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    static func warning() { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
}
