import SwiftUI
import HornEngine

/// What one journey looks and reads like. The shell is shared; a view asks the engine's
/// `Journey` for anything the rules know and the skin for the rest, so no view holds a
/// word, a number, a colour or a drawing that belongs to one journey.
///
/// No member has a default: a new skin that leaves something out doesn't compile, and
/// `SkinContractTests` checks that what it did supply is not blank and draws.
struct JourneySkin {
    /// The `Journey.id` this dresses.
    let id: String
    let card: TitleCard
    /// Everything said once a voyage exists, worked out for the state in hand so any of
    /// it can change along the way (a boat becomes a sled).
    let words: (GameState) -> Words
    let scene: SceneSkin
    let chart: ChartSkin
    let forage: ForageSkin
    let debug: DebugSkin
}

/// Every skin. Adding a journey's skin is this line and its file.
enum Skins {
    static let all: [JourneySkin] = [Horn1849Skin.skin, RailSkin.skin]

    static func skin(_ id: String) -> JourneySkin? { all.first { $0.id == id } }
}

// MARK: - Title card and setup

/// What is said before a voyage exists.
struct TitleCard {
    struct Page {
        let heading: String
        let paragraphs: [String]
    }

    /// The top bar.
    let banner: String
    /// The big title as set, line break and all. VoiceOver says `Journey.title`.
    let title: String
    let year: String
    let tagline: String
    let start: String
    /// `vessel` arrives escaped for markup.
    let resume: (_ vessel: String) -> String
    let learn: String
    let learnPages: [Page]

    let roleHeading: String
    let roleIntro: String
    let differencesAction: String
    let differencesHeading: String
    let differences: [String]

    let namesHeading: String
    let vesselPrompt: String
    let vesselLabel: String
    let leaderPrompt: String
    let leaderLabel: String
    let crewPrompt: String
    /// Numbered by the shell: "Crew member 2".
    let crewLabel: String

    let monthHeading: String
    let monthIntro: String
    let monthAdvice: String

    let outfitHeading: String
    let outfitIntro: (GameState) -> String
    let outfitBullets: [String]
    let enterShop: String

    let rankLegend: String
}

// MARK: - Words

/// What things are called on a voyage. Item names and units, pace and ration names,
/// stops, ports and everything the engine says itself come from the `Journey`.
struct Words {
    // The menu under way.
    let setOut: String
    let halt: String
    let carryOn: String
    let supplies: String
    let chart: String
    let changePace: String
    let changeRations: String
    let rest: String
    let repairs: String
    let forage: String

    // The menu in port.
    let leavePort: String
    let restInPort: String
    let trade: String
    let talk: String
    let buy: String
    let yard: String

    // The status panel.
    /// Short names for its rows where the shop's is too long.
    let statusNames: [ItemKey: String]
    let travelled: String
    let distanceUnit: String
    /// A distance as the journey writes it, without its unit.
    let distance: (Int) -> String
    /// The two meters, `GameState.hull` and `.sails`.
    let meters: (String, String)
    /// A row of the journey's own under the meters, for a count the rules keep that the
    /// date does not show: the days left on a contract. Nil when there is none.
    let clock: (label: String, value: String)?

    // Supplies.
    /// What the money is called, and the sign written before an amount of it.
    let cash: String
    let currency: String
    /// Short names for the supplies list where the shop's is too long.
    let storeNames: [ItemKey: String]
    /// What one of a boxed item is called once aboard: a box of tackle is 20 throws.
    let looseUnits: [ItemKey: String]
    /// Items counted to a tenth of their unit though they are stored whole: crates of
    /// citrus. Anything stored in parts of its unit (`Item.per` above one) is counted
    /// that way without being listed, unless it is in `looseUnits`.
    let fractional: Set<ItemKey>
    /// Whether exactly one of a thing is written with the item's `one`: "1 cord". 1849
    /// writes "1 crates", as its prototype did.
    let singular: Bool
    /// Items the shop prices by the lot they are sold in (`Item.step` of them at a time)
    /// where one alone costs pennies: "$2/100 gallons".
    let lots: Set<ItemKey>
    let vesselHeading: String
    /// The line under the meters: pace, rations and anything worth a warning.
    let suppliesNote: String
    let crewHeading: String
    let leaderTag: String
    /// Nil while everyone has their set.
    let clothesWarning: String?
    let lostHeading: String

    // Pace, rations and rest.
    let paceHeading: String
    let paceNow: String
    let rationsHeading: String
    let rationsNow: String
    let restPrompt: String
    /// One entry of `rules.restChoices`, in turns.
    let restChoice: (Int) -> String

    // Repairs and the yard.
    let repairsHeading: String
    let repairsNote: String
    let mend: String
    let patch: String
    let yardHeading: String
    let yardIntro: String
    let yardHull: (_ cost: Int) -> String
    let yardSails: (_ cost: Int) -> String
    let leaveYard: String

    /// Under the heading of every shop but the first; `percent` is the port's markup.
    let priceNote: (_ percent: Int) -> String

    // Burials and endings.
    /// `name` arrives escaped for markup.
    let burial: (_ name: String) -> String
    let commit: String
    let gameOverLine: String
    let arrival: String
    let arrivalBody: String
    let bonus: String
    let again: String
    let thanks: String
}

// MARK: - The scene

/// What a scene is asked to draw.
struct SceneFrame {
    let t: Double
    let weather: Weather
    let moving: Bool
    let atPort: Bool
    /// The two meters, 0–100.
    let hull: Double
    let sails: Double
    /// Nil on the title card, like `state`.
    let region: Region?
    let hour: Int
    let state: GameState?
}

struct SceneSkin {
    /// One frame on the 160×80 grid. Palettes go by `frame.weather.sky`, never by a
    /// weather's name.
    let draw: (PixelCanvas, SceneFrame) -> Void
    /// What VoiceOver says the picture shows.
    let label: (SceneFrame) -> String

    static let w = 160.0, h = 80.0
}

// MARK: - The chart

struct ChartSkin {
    /// A place on the route in the skin's own map space, and the mile reached there.
    typealias Point = (x: Double, y: Double, mile: Double)

    let w: Double
    let h: Double
    let title: String
    let label: (GameState) -> String
    let footer: (GameState) -> String
    /// Sea, land and grid. The route, stops and marker go on top.
    let background: (PixelCanvas, GameState, _ t: Double) -> Void
    /// The way being taken: a fork changes it.
    let route: (GameState) -> [Point]
    /// Ways still open that aren't the one in `route`, dotted half as often.
    let others: (GameState) -> [[Point]]
    /// Map space to canvas pixels. Positions between points are worked out in map space
    /// first, so a curved projection wants its route given already projected.
    let project: (_ x: Double, _ y: Double) -> (x: Double, y: Double)
    /// Miles between the dots of the whole route, and of the part travelled.
    let routeStep: Double
    let travelledStep: Double
    /// The dots of the way ahead. The part travelled, the stops and the marker are the
    /// shell's amber, ink and red on every chart.
    let routeColor: Color
    /// Anything over the top: an inset, a compass.
    let overlay: (PixelCanvas, GameState, _ t: Double) -> Void
}

// MARK: - Foraging

/// The mini-game's canvas: who throws from where, and where the quarry runs.
struct ForageField {
    let w: Double
    let h: Double
    /// Where a throw starts.
    let origin: (x: Double, y: Double)
    /// True when the thrower stands at the bottom and throws up.
    let upward: Bool
    /// Taps on the thrower's side of this line are ignored.
    let line: Double
    /// The band the quarry crosses in.
    let lanes: ClosedRange<Double>
    /// Pixels a second.
    let speed: Double
    /// The quarry all crosses the same way, left to right: wood on a river's current.
    let oneWay: Bool

    func inReach(_ y: Double) -> Bool { upward ? y <= line : y >= line }
}

struct ForageSkin {
    let field: ForageField
    let heading: String
    /// The tally reads "Throws: 60", "Caught: 12 lbs", "Time: 25". The amount and its
    /// unit are the shell's, from the item the journey stows a catch as (`forageReward`)
    /// and counted the way `Words` counts that item everywhere else, so what the engine
    /// holds in tenths of a cord is never shown as cords.
    let throwsLabel: String
    let caughtLabel: String
    let timeLabel: String
    /// `limit` is the most the role can keep, written out with its unit: "200 lbs".
    let hint: (_ limit: String) -> String
    let label: (_ quarry: Int) -> String
    let actionHint: String
    let leave: String
    /// What floats up from a hit. `worth` is what it adds, as a bare number in the same
    /// unit as the tally: "12", "1.4".
    let pop: (_ worth: String, Fish) -> String
    let backdrop: (PixelCanvas, _ now: Double) -> Void
    let quarry: (PixelCanvas, FishingModel.Swimmer) -> Void
    let thrown: (PixelCanvas, FishingModel.Harpoon) -> Void
}

// MARK: - Debug

/// For screenshots, UI tests and the scene gallery; nothing a player reaches.
struct DebugSkin {
    /// A well-stocked voyage ten miles short of `stops[stop]`, on the menu under way.
    let start: (_ stop: Int, _ month: Int) -> GameState
    /// Gallery cells beyond one per weather.
    let gallery: [(name: String, moving: Bool, set: (inout GameState) -> Void)]
}
