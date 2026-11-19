import XCTest
import HornEngine
@testable import AroundTheHorn

/// The words each skin shows at the edge of each condition that picks them, from
/// `Fixtures/word-edges.json`, which the web's `Tools/web-tests/word-edges.mjs` reads too:
/// a `<` that became `<=` on either platform fails against the same expectations.
final class WordEdgeTests: XCTestCase {
    struct Fixture: Decodable {
        struct Case: Decodable {
            let set: [String: Double]
            let field: String
            let `is`: String??
            let has: String?
            let lacks: String?

            enum CodingKeys: String, CodingKey { case set, field, `is`, has, lacks }

            init(from d: Decoder) throws {
                let c = try d.container(keyedBy: CodingKeys.self)
                set = try c.decode([String: Double].self, forKey: .set)
                field = try c.decode(String.self, forKey: .field)
                // Present and null is "no words"; absent is "not asked".
                `is` = c.contains(.is) ? .some(try c.decodeNil(forKey: .is) ? nil : try c.decode(String.self, forKey: .is)) : nil
                has = try c.decodeIfPresent(String.self, forKey: .has)
                lacks = try c.decodeIfPresent(String.self, forKey: .lacks)
            }
        }
        let journeys: [String: [Case]]
    }

    func fixture() throws -> Fixture {
        let url = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .appendingPathComponent("Fixtures/word-edges.json")
        return try JSONDecoder().decode(Fixture.self, from: Data(contentsOf: url))
    }

    func value(_ w: Words, _ field: String) -> String?? {
        switch field {
        case "clothesWarning": return .some(w.clothesWarning)
        case "suppliesNote": return .some(w.suppliesNote)
        case "departRefusal": return .some(w.departRefusal)
        default: return nil
        }
    }

    func testEverySkinsWordsAtTheEdgeOfEachCondition() throws {
        let f = try fixture()
        XCTAssertEqual(Set(f.journeys.keys), Set(Journeys.all.map(\.id)), "every journey has its edges")
        var cases = 0
        for (id, list) in f.journeys {
            let j = Journeys.journey(id)
            let skin = try XCTUnwrap(Skins.skin(id), id)
            let d = j.departures[0]
            let base = GameState(journey: id, role: .merchant, ship: "Wren", captain: "Ada", crew: ["Bo", "Cy", "Di", "Ed"],
                                 startYear: d.year, startMonth: d.month)
            for c in list {
                var g = base
                for (k, v) in c.set {
                    switch k {
                    case "clothes": g.clothes = Int(v)
                    case "noCitrus": g.noCitrus = Int(v)
                    case "day": g.day = Int(v)
                    case "fuel": g.fuel = v
                    case "money": g.money = v
                    default: XCTFail("\(id): the fixture sets \(k), which this test does not know")
                    }
                }
                let what = "\(id) \(c.set) \(c.field)"
                guard let got = value(skin.words(g), c.field) else { XCTFail("\(what): no such field"); continue }
                cases += 1
                if let want = c.is { XCTAssertEqual(got, want, what) }
                if let has = c.has { XCTAssertTrue(got?.contains(has) ?? false, "\(what): \(got ?? "nil") lacks \(has)") }
                if let lacks = c.lacks { XCTAssertFalse(got?.contains(lacks) ?? false, "\(what): \(got ?? "nil") has \(lacks)") }
            }
        }
        XCTAssertGreaterThan(cases, 30)
    }
}
