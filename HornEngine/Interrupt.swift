#if os(WASI)
import FoundationEssentials
#else
import Foundation
#endif

// Things that stop the voyage and need the player (spec §2). The engine returns them in
// order; the controller presents them in that order, then resumes travel unless one
// routes elsewhere (`enterPort`, `gameOver`, `finale`). This replaces the prototype's
// queue of screen functions (`runQueue`).

public enum Interrupt: Codable, Equatable {
    /// Markup text and a Continue button.
    case message(String)
    case choice(ChoiceEvent)
    /// A crew member has died; the player writes an epitaph, then
    /// `GameEngine.commitBurial` records the grave.
    case burial(crewID: UUID, cause: String)
    /// Reached a stop. The controller calls `GameEngine.beginArrival`.
    case arrival(stopID: String)
    /// Dropped anchor: show the port menu instead of resuming travel. Under way (a journey's
    /// `stalled` sends it when the player would rather take stock) it is the menu under
    /// way: the controller shows whichever menu `GameState.atPort` says.
    case enterPort
    case gameOver(title: String, body: String)
    /// Reached the end. The controller calls `GameEngine.finish`.
    case finale
}

/// A screen with a prompt and numbered options. The UI calls
/// `GameEngine.resolve(_:option:)` with the chosen index.
public struct ChoiceEvent: Codable, Equatable {
    public enum Kind: Codable, Equatable {
        // The 1849 voyage's.
        case stranger
        case albatross
        case stowaway(name: String)
        case icebergs(fog: Bool)
        case equator
        case galapagos
        case fork
        case pilot(cost: Int)
        // Every journey's.
        case portArrival(stopID: String)
        case tradeOffer(Offer, intro: String)
        /// A choice a journey raised with `GameEngine.ask`. The answer goes back to its
        /// `Journey.resolve` with the same key and arguments.
        case custom(key: String, args: [String])
    }

    public struct Option: Codable, Equatable {
        public let label: String
        public let enabled: Bool

        public init(_ label: String, enabled: Bool = true) {
            self.label = label
            self.enabled = enabled
        }
    }

    public let kind: Kind
    /// The message box, in markup.
    public let prompt: String
    /// An optional paragraph under the box, in markup.
    public let detail: String?
    public let options: [Option]
}
