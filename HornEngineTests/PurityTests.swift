import XCTest

/// Spec §2: the engine is pure Swift with no UI imports. The framework target already
/// links no UI framework; this reads the source so a stray `import SwiftUI` fails a test
/// with a sentence instead of a link error three milestones later.
final class PurityTests: XCTestCase {
    func testEngineImportsNoUIFramework() throws {
        let engineDir = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("HornEngine")
        // Every folder: each journey keeps its sources under HornEngine/Journeys/<Id>.
        let all = FileManager.default.enumerator(at: engineDir, includingPropertiesForKeys: nil)?
            .compactMap { $0 as? URL } ?? []
        let files = all.filter { $0.pathExtension == "swift" }
        XCTAssertFalse(files.isEmpty, "found no engine sources at \(engineDir.path)")
        XCTAssertTrue(files.contains { $0.path.contains("/Journeys/") }, "the journeys' sources were not searched")

        let banned = ["SwiftUI", "UIKit", "AVFoundation", "CoreHaptics", "Combine"]
        for file in files {
            let text = try String(contentsOf: file, encoding: .utf8)
            for line in text.split(separator: "\n") where line.hasPrefix("import ") {
                let module = line.dropFirst("import ".count).trimmingCharacters(in: .whitespaces)
                XCTAssertFalse(banned.contains(module),
                               "\(file.lastPathComponent) imports \(module); the engine must stay UI-free")
            }
        }
    }
}
