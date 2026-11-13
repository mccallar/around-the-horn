import Foundation
import HornEngine

/// Reads a voyage saved by the build before there were journeys (save version 1, in
/// `save.json`), so nobody loses a passage half sailed by updating.
///
/// That build wrote the weather and each ailment as its name alone, where this one writes
/// the whole of each, and it had no journey id, fuel or journey variables to write.
/// Everything else in the old file is carried over as it stands.
enum Horn1849LegacySave {
    static let version = 1

    /// Every ailment that build could write, by the name it wrote.
    static let ailments: [Ailment] = [
        .scurvy, .shipFever, .dysentery, .yellowFever, .fever, .pneumonia, .frostbite, .brokenArm, .exhaustion,
    ]

    /// The old save as a voyage of this version, or nil if `data` isn't one: another
    /// version, or a weather or an ailment that build never had.
    static func upgrade(_ data: Data) -> GameState? {
        guard var o = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
              o["saveVersion"] as? Int == version,
              let raw = o["weather"] as? String,
              let weather = Weather.allCases.first(where: { $0.rawValue == raw }).flatMap(json),
              var crew = o["crew"] as? [[String: Any]],
              var flags = o["flags"] as? [String: Any]
        else { return nil }
        for i in crew.indices {
            guard let was = crew[i]["ailment"] else { continue }
            guard let name = was as? String,
                  let now = ailments.first(where: { $0.rawValue == name }).flatMap(json)
            else { return nil }
            crew[i]["ailment"] = now
        }
        flags["fuel"] = false
        flags["lowFuel"] = false
        o["weather"] = weather
        o["crew"] = crew
        o["flags"] = flags
        o["journey"] = Horn1849.id
        o["fuel"] = 0.0
        o["vars"] = [String: Double]()
        o["saveVersion"] = GameState.currentSaveVersion
        guard let out = try? JSONSerialization.data(withJSONObject: o) else { return nil }
        return try? JSONDecoder().decode(GameState.self, from: out)
    }

    /// A value as this version writes it.
    private static func json<T: Encodable>(_ v: T) -> Any? {
        (try? JSONEncoder().encode(v)).flatMap { try? JSONSerialization.jsonObject(with: $0) }
    }
}
