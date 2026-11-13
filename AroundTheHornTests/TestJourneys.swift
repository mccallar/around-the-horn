import Foundation
@testable import HornEngine
@testable import AroundTheHorn

/// Journeys the engine doesn't have, for what one journey can't show: a picker with two
/// different rows, a table the shell must not read 1849's way.
///
/// The engine can't sail one (a `GameState` only takes the id of a journey in
/// `Journeys.all`), so these stand in wherever the shell needs only the journey's tables
/// and a skin: the picker, the title cards, the top tens, how an amount is written.
enum TestJourneys {
    static var horn: Journey { Journeys.journey(Horn1849.id) }

    /// 1849's tables under another id and title, then whatever `change` makes of them.
    static func copy(id: String, title: String = "The Other Way", _ change: (Journey) -> Void = { _ in }) -> Journey {
        let base = horn
        let j = Journey(id: id, text: base.text)
        j.title = title
        j.subtitle = "A journey only the tests take"
        j.blurb = base.blurb
        j.items = base.items
        j.stops = base.stops
        j.regions = base.regions
        j.ports = base.ports
        j.weathers = base.weathers
        j.fairWeather = base.fairWeather
        j.deficiency = base.deficiency
        j.ailments = base.ailments
        j.roles = base.roles
        j.paces = base.paces
        j.rationings = base.rationings
        j.departures = base.departures
        j.firstNames = base.firstNames
        j.vesselNames = base.vesselNames
        j.defaultTopTen = [TopTenEntry(name: "Nobody", score: 1)]
        j.quarry = base.quarry
        j.forageSeconds = base.forageSeconds
        j.forageReward = base.forageReward
        j.rules = base.rules
        change(j)
        return j
    }

    /// 1849's skin under another id.
    static func skin(_ id: String) -> JourneySkin {
        let s = Horn1849Skin.skin
        return JourneySkin(id: id, card: s.card, words: s.words, scene: s.scene, chart: s.chart, forage: s.forage,
                           debug: s.debug)
    }

    // What a journey by rail stocks and meets, as far as the shell's sums care.

    /// Sold by the cord, burned and cut by the tenth of one.
    static let firewood = Item(key: .fuel, name: "Firewood", unit: "cords", one: "cord", step: 1, per: 10, price: 6,
                               max: 20, desc: "For the firebox.")
    static let thunderstorm = Weather("test-thunder", name: "Thunderstorm", speed: 0.7, wear: 1, harsh: 0.6, rough: true,
                                      wet: true, sky: .storm)
    static let snow = Weather("test-snow", name: "Snow", speed: 0.6, wear: 1, harsh: 0.5, sky: .snow)
    static let blizzard = Weather("test-blizzard", name: "Blizzard", speed: 0.3, wear: 1.5, harsh: 1.5, rough: true,
                                  sky: .snow)

    /// A journey whose catch is firewood, in tenths of a cord, and whose worst weather
    /// falls from a snowy sky.
    static func woodBurner(id: String = "test-rail") -> Journey {
        copy(id: id, title: "The Iron Road") { j in
            j.items = j.items + [firewood]
            j.forageReward = .fuel
            j.quarry = [2, 4, 8, 14, 25].map {
                Fish(name: "log \($0)", lb: $0, width: 12, height: 6, speed: 20...40, weight: 1, color: "#886644")
            }
            for r in Role.allCases {
                let was = j.role(r)
                j.roles[r] = RoleInfo(label: was.label, title: was.title, money: was.money, mend: was.mend,
                                      patch: was.patch, catchLimit: r == .whaler ? 60 : 40, aim: was.aim)
            }
            j.weathers = [j.fairWeather, thunderstorm, snow, blizzard]
        }
    }
}
