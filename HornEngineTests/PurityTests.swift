import XCTest

/// Spec §2: the engine is pure Swift with no UI imports. The framework target already
/// links no UI framework; this reads the source so a stray `import SwiftUI` fails a test
/// with a sentence instead of a link error three milestones later.
final class PurityTests: XCTestCase {
    /// Every engine source, in every folder: each journey keeps its sources under
    /// HornEngine/Journeys/<Id>.
    func engineSources() -> [URL] {
        let engineDir = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("HornEngine")
        let all = FileManager.default.enumerator(at: engineDir, includingPropertiesForKeys: nil)?
            .compactMap { $0 as? URL } ?? []
        let files = all.filter { $0.pathExtension == "swift" }
        XCTAssertFalse(files.isEmpty, "found no engine sources at \(engineDir.path)")
        XCTAssertTrue(files.contains { $0.path.contains("/Journeys/") }, "the journeys' sources were not searched")
        return files
    }

    /// The web version compiles the engine for WASI, where Foundation is
    /// FoundationEssentials (decision D12), and nothing on the Apple side would notice a
    /// plain `import Foundation` breaking that build. So every Foundation import sits in the
    /// one guarded shape, the engine imports nothing else, and nothing calls
    /// `String(format:)`, which FoundationEssentials does not have.
    func testEngineStillBuildsForTheWeb() throws {
        let shape = ["#if os(WASI)", "import FoundationEssentials", "#else", "import Foundation", "#endif"]
        for file in engineSources() {
            let name = file.lastPathComponent
            let lines = try String(contentsOf: file, encoding: .utf8).components(separatedBy: "\n")
            for (i, raw) in lines.enumerated() {
                let line = raw.trimmingCharacters(in: .whitespaces)
                if line.hasPrefix("import ") {
                    let at = shape.firstIndex(of: line)
                    let start = i - (at ?? 0)
                    XCTAssertTrue(at != nil && start >= 0 && start + shape.count <= lines.count
                                  && Array(lines[start..<start + shape.count]) == shape,
                                  "\(name):\(i + 1): `\(line)`; the engine imports Foundation only as `\(shape.joined(separator: " / "))`")
                }
                let code = raw.components(separatedBy: "//")[0]
                XCTAssertFalse(code.contains("String(format:"),
                               "\(name):\(i + 1) calls String(format:), which the web build does not have")
            }
        }
    }

    func testEngineImportsNoUIFramework() throws {
        let files = engineSources()

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
