import XCTest
@testable import AroundTheHorn

final class SynthTests: XCTestCase {
    func testEveryCueRendersQuietly() {
        for cue in [Cue.click, .message, .shopUp, .shopDown, .harpoon, .stranger, .unmute,
                    .title, .arrive, .death, .win, .fishHit] {
            let s = Synth.render(Synth.notes(cue))
            XCTAssertFalse(s.isEmpty, "\(cue)")
            XCTAssertLessThanOrEqual(s.map(abs).max()!, 0.036, "\(cue) must stay at about 0.03 amplitude")
            XCTAssertGreaterThan(s.map(abs).max()!, 0.02, "\(cue) is silent")
        }
    }

    func testANoteDecaysToNearSilence() {
        let s = Synth.render([Synth.Note(hz: 440, seconds: 0.1)])
        let early = s.prefix(200).map(abs).max()!
        let late = s[Int(0.09 * Synth.sampleRate)...].map(abs).max()!
        XCTAssertGreaterThan(early, 0.025)
        XCTAssertLessThan(late, 0.001)
    }

    func testTunesPlayBackToBack() {
        let t = Synth.notes(.arrive)
        XCTAssertEqual(t.map(\.at), [0, 0.1, 0.2, 0.30000000000000004])
        XCTAssertEqual(t.last!.seconds, 0.25 * 0.95, accuracy: 1e-12)
        XCTAssertEqual(Synth.render(t).count, Int((0.3 + 0.2375 + 0.03) * Synth.sampleRate))
    }
}
