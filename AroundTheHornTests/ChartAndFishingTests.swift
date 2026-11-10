import XCTest
import HornEngine
@testable import AroundTheHorn

final class ChartTests: XCTestCase {
    func testPositionInterpolatesAlongTheRoute() {
        let ny = ChartData.position(atMile: 0, passage: nil)
        XCTAssertEqual(ny.lon, -74)
        XCTAssertEqual(ny.lat, 40.7)
        let mid = ChartData.position(atMile: 150, passage: nil)  // halfway to the Gulf Stream vertex
        XCTAssertEqual(mid.lon, -72, accuracy: 1e-9)
        XCTAssertEqual(mid.lat, 38.85, accuracy: 1e-9)
        let sf = ChartData.position(atMile: 14000, passage: .horn)
        XCTAssertEqual(sf.lon, -122.4)
    }

    func testTheStraitBendsTheRouteOnlyAtTheBottom() {
        let horn = ChartData.position(atMile: 7550, passage: .horn)
        let strait = ChartData.position(atMile: 7550, passage: .magellan)
        XCTAssertNotEqual(horn.lat, strait.lat)
        XCTAssertLessThan(horn.lat, strait.lat, "the Horn runs further south")
        XCTAssertEqual(ChartData.position(atMile: 5200, passage: .horn).lon,
                       ChartData.position(atMile: 5200, passage: .magellan).lon)
    }

    func testProjection() {
        let p = ChartData.project((-130, 45))
        XCTAssertEqual(p.x, 0)
        XCTAssertEqual(p.y, 0)
        XCTAssertEqual(ChartData.project((-15, -60)).y, 210)
    }
}

@MainActor
final class FishingModelTests: XCTestCase {
    var tackle = 0

    func model(padding: Double = 1.5, random: @escaping () -> Double = { 0.5 }) -> FishingModel {
        FishingModel(padding: padding, random: random,
                     useTackle: { [unowned self] in
                         guard tackle > 0 else { return false }
                         tackle -= 1
                         return true
                     },
                     tackleLeft: { [unowned self] in tackle })
    }

    func testAThrowSpendsTackleAndOnlyOneFliesAtATime() {
        tackle = 5
        let m = model()
        m.throwAt(x: 80, y: 150)
        XCTAssertNotNil(m.harpoon)
        XCTAssertEqual(tackle, 4)
        m.throwAt(x: 20, y: 150)
        XCTAssertEqual(tackle, 4, "one harpoon in flight at a time")
        XCTAssertEqual(m.harpoon!.vy, 150, accuracy: 1e-9, "150 px/s toward the tap")
    }

    func testTapsAboveTheWaterAreIgnored() {
        tackle = 5
        let m = model()
        m.throwAt(x: 80, y: 20)
        XCTAssertNil(m.harpoon)
        XCTAssertEqual(tackle, 5)
    }

    func testAHitAddsTheFishsWeight() {
        tackle = 5
        let m = model()
        let target = m.fish[0]
        var caught: [String] = []
        m.onCatch = { caught.append($0.name) }
        // Lead the target: aim where it will be when the harpoon (150 px/s) gets there.
        var aim = (x: target.x, y: target.y)
        for _ in 0..<3 {
            let flight = hypot(aim.x - 80, aim.y - 28) / 150
            aim = (target.x + target.vx * flight, target.y)
        }
        m.throwAt(x: aim.x, y: aim.y)
        for _ in 0..<200 where m.harpoon != nil { m.step(0.01) }
        XCTAssertGreaterThan(m.caught, 0)
        XCTAssertEqual(caught.count, 1)
        XCTAssertEqual(m.pops.count, 1)
    }

    func testTheOutingEndsAtTwentyFiveSecondsOrWhenTheTackleIsGone() {
        tackle = 5
        let m = model()
        for _ in 0..<499 { m.step(0.05) }
        XCTAssertFalse(m.ended)
        for _ in 0..<2 { m.step(0.05) }
        XCTAssertTrue(m.ended)

        tackle = 0
        let empty = model()
        empty.step(0.01)
        XCTAssertTrue(empty.ended)
    }

    func testAStepNeverAdvancesMoreThanFiftyMilliseconds() {
        tackle = 5
        let m = model()
        m.step(10)
        XCTAssertEqual(m.time, 25 - 0.05, accuracy: 1e-9)
    }
}
