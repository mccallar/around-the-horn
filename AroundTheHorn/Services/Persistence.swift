import Foundation
import HornEngine

/// The save, the top ten and the mute setting (spec §11). JSON files in Application
/// Support; the mute flag in UserDefaults.
struct Persistence {
    let directory: URL
    let defaults: UserDefaults

    static let standard: Persistence = {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return Persistence(directory: base, defaults: .standard)
    }()

    var saveURL: URL { directory.appendingPathComponent("save.json") }
    var topTenURL: URL { directory.appendingPathComponent("topten.json") }

    // MARK: Save

    func save(_ s: GameState) {
        guard !s.over else { return }  // never after game over or the finale
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try JSONEncoder().encode(s).write(to: saveURL, options: .atomic)
        } catch {
            print("save failed: \(error)")
        }
    }

    /// The saved voyage, or nil if there is none or it can't be read by this version.
    func loadSave() -> GameState? {
        guard let data = try? Data(contentsOf: saveURL),
              let s = try? JSONDecoder().decode(GameState.self, from: data),
              s.saveVersion == GameState.currentSaveVersion, Journeys.has(s.journey), !s.over
        else { return nil }
        return s
    }

    func deleteSave() {
        try? FileManager.default.removeItem(at: saveURL)
    }

    // MARK: Top ten

    func topTen() -> [TopTenEntry] {
        guard let data = try? Data(contentsOf: topTenURL),
              let t = try? JSONDecoder().decode([TopTenEntry].self, from: data), !t.isEmpty
        else { return GameData.defaultTopTen }
        return t
    }

    func saveTopTen(_ t: [TopTenEntry]) {
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try? JSONEncoder().encode(t).write(to: topTenURL, options: .atomic)
    }

    // MARK: Settings

    static let mutedKey = "horn.muted"

    var muted: Bool {
        get { defaults.bool(forKey: Self.mutedKey) }
        nonmutating set { defaults.set(newValue, forKey: Self.mutedKey) }
    }
}
