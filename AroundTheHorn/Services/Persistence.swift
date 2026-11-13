import Foundation
import HornEngine

/// The saves, the top tens and the mute setting (spec §11). JSON files in Application
/// Support, one save and one top ten per journey; the mute flag in UserDefaults.
struct Persistence {
    let directory: URL
    let defaults: UserDefaults

    static let standard: Persistence = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return Persistence(directory: base, defaults: .standard)
    }()

    /// Before there were journeys there was one, and its files had no id in their names.
    /// They are still read as its own; nothing written before is lost.
    static let legacyJourney = Horn1849.id
    var legacySaveURL: URL { directory.appendingPathComponent("save.json") }
    var legacyTopTenURL: URL { directory.appendingPathComponent("topten.json") }

    func saveURL(_ journey: String) -> URL { directory.appendingPathComponent("save-\(journey).json") }
    func topTenURL(_ journey: String) -> URL { directory.appendingPathComponent("topten-\(journey).json") }

    // MARK: Save

    func save(_ s: GameState) {
        guard !s.over else { return }  // never after game over or the finale
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try JSONEncoder().encode(s).write(to: saveURL(s.journey), options: .atomic)
            // The voyage has moved to its own file; the old one would only bring back a
            // voyage that has since ended.
            if s.journey == Self.legacyJourney { try? FileManager.default.removeItem(at: legacySaveURL) }
        } catch {
            print("save failed: \(error)")
        }
    }

    /// That journey's saved voyage, or nil if there is none or it can't be read by this
    /// version.
    func loadSave(_ journey: String) -> GameState? {
        if let s = voyage(at: saveURL(journey), journey) { return s }
        return journey == Self.legacyJourney ? voyage(at: legacySaveURL, journey) : nil
    }

    private func voyage(at url: URL, _ journey: String) -> GameState? {
        guard let data = try? Data(contentsOf: url),
              let s = try? JSONDecoder().decode(GameState.self, from: data),
              s.saveVersion == GameState.currentSaveVersion, s.journey == journey, Journeys.has(s.journey), !s.over
        else { return nil }
        return s
    }

    func deleteSave(_ journey: String) {
        try? FileManager.default.removeItem(at: saveURL(journey))
        if journey == Self.legacyJourney { try? FileManager.default.removeItem(at: legacySaveURL) }
    }

    // MARK: Top ten

    func topTen(_ journey: Journey) -> [TopTenEntry] {
        if let t = table(at: topTenURL(journey.id)) { return t }
        if journey.id == Self.legacyJourney, let t = table(at: legacyTopTenURL) { return t }
        return journey.defaultTopTen
    }

    private func table(at url: URL) -> [TopTenEntry]? {
        guard let data = try? Data(contentsOf: url),
              let t = try? JSONDecoder().decode([TopTenEntry].self, from: data), !t.isEmpty
        else { return nil }
        return t
    }

    /// Writes the journey's own file. The old `topten.json` is left where it is.
    func saveTopTen(_ t: [TopTenEntry], for journey: String) {
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try? JSONEncoder().encode(t).write(to: topTenURL(journey), options: .atomic)
    }

    // MARK: Settings

    static let mutedKey = "horn.muted"

    var muted: Bool {
        get { defaults.bool(forKey: Self.mutedKey) }
        nonmutating set { defaults.set(newValue, forKey: Self.mutedKey) }
    }
}
