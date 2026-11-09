import XCTest
@testable import HornEngine

final class RNGTests: XCTestCase {
    func testSameSeedSameSequence() {
        var a = SeededRNG(seed: 1849)
        var b = SeededRNG(seed: 1849)
        for _ in 0..<100 { XCTAssertEqual(a.next(), b.next()) }
    }

    func testUnitStaysInHalfOpenRange() {
        var r = SeededRNG(seed: 7)
        for _ in 0..<10_000 {
            let u = r.nextUnit()
            XCTAssertGreaterThanOrEqual(u, 0)
            XCTAssertLessThan(u, 1)
        }
    }

    func testIntIncludesBothEnds() {
        var r = SeededRNG(seed: 42)
        let seen = Set((0..<2_000).map { _ in r.int(1, 3) })
        XCTAssertEqual(seen, [1, 2, 3])
    }
}
