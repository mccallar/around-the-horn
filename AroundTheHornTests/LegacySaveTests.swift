import XCTest
@testable import HornEngine
@testable import AroundTheHorn

/// A voyage saved by the build before there were journeys must still be there after the
/// update. That build wrote `save.json` at save version 1, with the weather and each
/// ailment as a bare name; a version 2 file written by hand to the old path proves
/// nothing about it, so the file here is one that build really wrote.
@MainActor
final class LegacySaveTests: XCTestCase {
    var p: Persistence!
    let fm = FileManager.default

    override func setUp() async throws {
        p = Persistence(directory: fm.temporaryDirectory.appendingPathComponent(UUID().uuidString),
                        defaults: UserDefaults(suiteName: UUID().uuidString)!)
        try fm.createDirectory(at: p.directory, withIntermediateDirectories: true)
    }

    /// Written by the 1849-only build: a merchant 95 days out, past Valparaíso in a gale,
    /// the captain down with ship fever and the limes gone.
    static let shipped = """
    {"albatrossSeen":false,"atPort":false,"badLuck":0,"clothes":5,"crew":[{"ailDays":1,"ailment":"ship fever",\
    "alive":true,"hp":10.799999999999919,"id":"D7EA4823-9621-48B5-8222-9661F1A7BEC3","isCaptain":true,"name":"Ezra",\
    "treated":false},{"ailDays":0,"alive":true,"hp":65.79999999999987,"id":"2E97CF3D-18B7-4C19-A2CF-18E1A20FE65B",\
    "isCaptain":false,"name":"Ada","treated":false},{"ailDays":0,"alive":true,"hp":65.79999999999987,\
    "id":"8B27C467-6A2B-4E79-80E5-108EC73F2D05","isCaptain":false,"name":"Silas","treated":false},{"ailDays":0,\
    "alive":true,"hp":65.79999999999987,"id":"E0C2401A-202A-4FC7-AF56-1F3976513D9B","isCaptain":false,"name":"Mercy",\
    "treated":false},{"ailDays":0,"alive":true,"hp":65.79999999999987,"id":"AED5C462-4A0B-4578-8F47-EFFB116E36A0",\
    "isCaptain":false,"name":"Tobias","treated":false}],"day":95,"flags":{"food":false,"hull":false,"limes":true,\
    "lowFood":false,"lowWater":false,"sails":false,"water":false},"food":501,"forceFair":0,"graves":[],\
    "hull":45.0049243877408,"limes":0,"meds":0,"mile":7504,"money":1054,"noCitrus":34,"note":"","over":false,\
    "pace":"steady","pilot":false,"rations":"filling","role":"merchant","sailcloth":4,"sails":31.04514399978621,\
    "saveVersion":1,"ship":"Resolute","startMonth":2,"startYear":1849,"starving":false,"stopIndex":6,\
    "stowawaySeen":false,"tackle":60,"talkIndex":0,"thirst":false,"timber":6,"tradesLeft":3,"water":411,\
    "weather":"gale"}
    """

    /// The shipped file with one value swapped for another.
    func shipped(_ change: (inout [String: Any]) -> Void) throws -> Data {
        var o = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(Self.shipped.utf8)) as? [String: Any])
        change(&o)
        return try JSONSerialization.data(withJSONObject: o)
    }

    func writeShipped() throws { try Data(Self.shipped.utf8).write(to: p.legacySaveURL) }

    func testTheShippedSaveIsNotThisVersions() throws {
        // What made the old file unreadable: without the upgrade it does not decode.
        XCTAssertNil(try? JSONDecoder().decode(GameState.self, from: Data(Self.shipped.utf8)))
        XCTAssertNotEqual(Horn1849LegacySave.version, GameState.currentSaveVersion)
    }

    func testAVoyageSavedByTheOldBuildIsReadWhole() throws {
        try writeShipped()
        let s = try XCTUnwrap(p.loadSave(Horn1849.id), "the voyage a player had under way is gone")
        XCTAssertTrue(p.hasSave(Horn1849.id))
        XCTAssertEqual(s.journey, Horn1849.id)
        XCTAssertEqual(s.saveVersion, GameState.currentSaveVersion)
        XCTAssertEqual(s.ship, "Resolute")
        XCTAssertEqual(s.role, .merchant)
        XCTAssertEqual(s.day, 95)
        XCTAssertEqual(s.mile, 7504)
        XCTAssertEqual(s.stopIndex, 6)
        XCTAssertEqual(s.startYear, 1849)
        XCTAssertEqual(s.startMonth, 2)
        XCTAssertFalse(s.atPort)
        XCTAssertFalse(s.over)

        // The weather comes back as the whole weather, not a name.
        XCTAssertEqual(s.weather, .gale)
        XCTAssertEqual(s.weather.name, "Gale")
        XCTAssertEqual(s.weather.harsh, 0.6)
        XCTAssertTrue(s.weather.isRough)

        XCTAssertEqual(s.crew.map(\.name), ["Ezra", "Ada", "Silas", "Mercy", "Tobias"])
        XCTAssertEqual(s.crew[0].id, UUID(uuidString: "D7EA4823-9621-48B5-8222-9661F1A7BEC3"))
        XCTAssertTrue(s.crew[0].isCaptain)
        XCTAssertEqual(s.crew[0].ailment, .shipFever)
        XCTAssertEqual(s.crew[0].ailment?.damage, 4.5)
        XCTAssertEqual(s.crew[0].ailDays, 1)
        XCTAssertEqual(s.crew[0].hp, 10.799999999999919)
        XCTAssertEqual(s.crew.dropFirst().map(\.hp), [Double](repeating: 65.79999999999987, count: 4))
        XCTAssertTrue(s.crew.dropFirst().allSatisfy { $0.ailment == nil && $0.alive })

        XCTAssertEqual(s.money, 1054)
        XCTAssertEqual(s.food, 501)
        XCTAssertEqual(s.water, 411)
        XCTAssertEqual(s.limes, 0)
        XCTAssertEqual(s.meds, 0)
        XCTAssertEqual(s.clothes, 5)
        XCTAssertEqual(s.sailcloth, 4)
        XCTAssertEqual(s.timber, 6)
        XCTAssertEqual(s.tackle, 60)
        XCTAssertEqual(s.hull, 45.0049243877408)
        XCTAssertEqual(s.sails, 31.04514399978621)
        XCTAssertEqual(s.noCitrus, 34)
        XCTAssertTrue(s.flags.limes, "what has already been said stays said")
        XCTAssertFalse(s.flags.food)
        XCTAssertEqual(s.tradesLeft, 3)
        XCTAssertEqual(s.pace, .steady)
        XCTAssertEqual(s.rations, .filling)

        // What the old build had no word for.
        XCTAssertEqual(s.fuel, 0)
        XCTAssertTrue(s.vars.isEmpty)
        XCTAssertFalse(s.flags.fuel)
        XCTAssertFalse(s.flags.lowFuel)
        XCTAssertNil(p.loadSave("rail"), "and it is nobody else's")
    }

    func testTheOldVoyageSailsOn() throws {
        try writeShipped()
        let s = try XCTUnwrap(p.loadSave(Horn1849.id))
        let engine = GameEngine(state: s, rng: SeededRNG(seed: 1849))
        engine.setSail()
        _ = engine.sailDay()
        XCTAssertEqual(engine.state.day, 96)
        XCTAssertGreaterThanOrEqual(engine.state.mile, 7504)
        // And it is written back as this version's, which reads straight in.
        let again = try JSONDecoder().decode(GameState.self, from: JSONEncoder().encode(engine.state))
        XCTAssertEqual(again, engine.state)
    }

    func testTheTitleOffersItAndItMovesToItsOwnFileOnTheNextSave() throws {
        try writeShipped()
        let c = GameController(persistence: p)
        c.tickInterval = .seconds(3600)
        XCTAssertEqual(c.savedVoyage?.ship, "Resolute", "the title card offers to continue")
        XCTAssertTrue(fm.fileExists(atPath: p.legacySaveURL.path), "looking leaves it where it was")
        XCTAssertEqual(try Data(contentsOf: p.legacySaveURL), Data(Self.shipped.utf8), "and as it was")

        c.continueSavedVoyage()
        guard case .seaMenu = c.screen else { return XCTFail("\(c.screen)") }
        XCTAssertEqual(c.game?.ship, "Resolute")
        XCTAssertEqual(c.game?.mile, 7504)
        // Every menu saves: the voyage now has its own file and the old one is done with.
        XCTAssertTrue(fm.fileExists(atPath: p.saveURL(Horn1849.id).path))
        XCTAssertFalse(fm.fileExists(atPath: p.legacySaveURL.path))
        XCTAssertEqual(p.loadSave(Horn1849.id), c.game)
        let onDisk = try JSONDecoder().decode(GameState.self, from: Data(contentsOf: p.saveURL(Horn1849.id)))
        XCTAssertEqual(onDisk.saveVersion, GameState.currentSaveVersion)
        XCTAssertEqual(onDisk.weather, .gale)
    }

    func testEndingTheVoyageClearsTheOldFile() throws {
        try writeShipped()
        p.deleteSave(Horn1849.id)
        XCTAssertNil(p.loadSave(Horn1849.id), "or the title would offer a voyage that has ended")
        XCTAssertFalse(fm.fileExists(atPath: p.legacySaveURL.path))
    }

    func testANewerSaveWinsOverTheOldFile() throws {
        try writeShipped()
        var newer = try XCTUnwrap(p.loadSave(Horn1849.id))
        newer.ship = "Newer"
        try JSONEncoder().encode(newer).write(to: p.saveURL(Horn1849.id))
        XCTAssertEqual(p.loadSave(Horn1849.id)?.ship, "Newer")
    }

    /// Every weather and every ailment the old build could write, by the names it wrote.
    func testEveryWeatherAndAilmentTheOldBuildWroteIsRead() throws {
        let weathers = ["fair": "Fair winds", "fresh": "Fresh breeze", "light": "Light airs", "calm": "Becalmed",
                        "hot": "Hot & still", "rain": "Rain squalls", "fog": "Thick fog", "cold": "Sleet & snow",
                        "gale": "Gale", "storm": "STORM"]
        let journey = Journeys.journey(Horn1849.id)
        for (raw, name) in weathers {
            let s = try XCTUnwrap(Horn1849LegacySave.upgrade(try shipped { $0["weather"] = raw }), raw)
            XCTAssertEqual(s.weather.name, name)
            XCTAssertTrue((journey.weathers + [journey.fairWeather]).contains(s.weather), "\(raw) is a weather 1849 still has")
        }
        let ailments = ["scurvy", "ship fever", "dysentery", "yellow fever", "a fever", "pneumonia", "frostbite",
                        "a broken arm", "exhaustion"]
        XCTAssertEqual(Horn1849LegacySave.ailments.map(\.name), ailments)
        for a in journey.ailments + [journey.deficiency].compactMap({ $0 }) {
            XCTAssertTrue(Horn1849LegacySave.ailments.contains(a), "\(a.name) is as the engine has it")
        }
        for name in ailments {
            let data = try shipped {
                var crew = $0["crew"] as! [[String: Any]]
                crew[0]["ailment"] = name
                crew[3]["ailment"] = name
                crew[3]["treated"] = true
                $0["crew"] = crew
            }
            let s = try XCTUnwrap(Horn1849LegacySave.upgrade(data), name)
            XCTAssertEqual(s.crew[0].ailment?.name, name)
            XCTAssertEqual(s.crew[3].ailment?.name, name)
            XCTAssertTrue(s.crew[3].treated)
            XCTAssertNil(s.crew[1].ailment)
            // The whole ailment as the engine has it now (its harm, its length), not the
            // name alone. Some only ever come from an event, so the journey's own list of
            // the ones that strike by chance is not the place to look.
            XCTAssertEqual(s.crew[0].ailment, Horn1849LegacySave.ailments.first { $0.name == name }, name)
        }
    }

    /// In port, with graves and a voyage's worth of flags set: nothing else in the file
    /// is touched on the way through.
    func testEverythingElseIsCarriedAcross() throws {
        let data = try shipped {
            $0["atPort"] = true
            $0["pilot"] = true
            $0["note"] = "Wind's getting up."
            $0["albatrossSeen"] = true
            $0["badLuck"] = 7
            $0["forceFair"] = 2
            $0["talkIndex"] = 4
            $0["passage"] = "magellan"
            $0["graves"] = [["name": "Amos", "cause": "scurvy", "date": "March 9, 1849", "epitaph": "Gone below."]]
            var crew = $0["crew"] as! [[String: Any]]
            crew[4]["alive"] = false
            crew[4]["hp"] = 0
            crew[3]["leaveAt"] = "valp"
            $0["crew"] = crew
        }
        let s = try XCTUnwrap(Horn1849LegacySave.upgrade(data))
        XCTAssertTrue(s.atPort && s.pilot && s.albatrossSeen)
        XCTAssertEqual(s.note, "Wind's getting up.")
        XCTAssertEqual(s.badLuck, 7)
        XCTAssertEqual(s.forceFair, 2)
        XCTAssertEqual(s.talkIndex, 4)
        XCTAssertEqual(s.passage, .magellan)
        XCTAssertEqual(s.graves, [Grave(name: "Amos", cause: "scurvy", date: "March 9, 1849", epitaph: "Gone below.")])
        XCTAssertFalse(s.crew[4].alive)
        XCTAssertEqual(s.crew[3].leaveAt, "valp")
        XCTAssertEqual(s.living.count, 4)
    }

    /// A file in the old place that this build cannot read is somebody's voyage all the
    /// same, or nothing of ours: it is not offered, and it is never deleted.
    func testAnOldFileThisBuildCannotReadIsLeftAlone() throws {
        let strange: [(String, Data)] = [
            ("not JSON", Data("the quick brown fox".utf8)),
            ("a version from the future", try shipped { $0["saveVersion"] = 99 }),
            ("version 0", try shipped { $0["saveVersion"] = 0 }),
            ("a weather nobody had", try shipped { $0["weather"] = "hail" }),
            ("an ailment nobody had", try shipped {
                var crew = $0["crew"] as! [[String: Any]]
                crew[2]["ailment"] = "the vapours"
                $0["crew"] = crew
            }),
            ("half a file", Data(Self.shipped.utf8.prefix(300))),
        ]
        for (what, data) in strange {
            try data.write(to: p.legacySaveURL)
            XCTAssertNil(Horn1849LegacySave.upgrade(data), what)
            XCTAssertNil(p.loadSave(Horn1849.id), "\(what) is not offered")
            XCTAssertFalse(p.hasSave(Horn1849.id), what)

            // A new voyage is begun, saved and ended over the top of it.
            var s = GameState(journey: Horn1849.id, role: .whaler, ship: "Sea Lark", captain: "Ira",
                              crew: ["A", "B", "C", "D"], startYear: 1849, startMonth: 0)
            s.day = 3
            p.save(s)
            XCTAssertEqual(p.loadSave(Horn1849.id), s)
            XCTAssertEqual(try Data(contentsOf: p.legacySaveURL), data, "\(what): saving a new voyage threw the old file away")
            p.deleteSave(Horn1849.id)
            XCTAssertNil(p.loadSave(Horn1849.id))
            XCTAssertEqual(try Data(contentsOf: p.legacySaveURL), data, "\(what): ending a voyage threw the old file away")
            try fm.removeItem(at: p.legacySaveURL)
        }
    }

    /// An old voyage that had already ended is not one to go back to, and has nothing
    /// left to lose.
    func testAnOldSaveOfAFinishedVoyageIsNotOffered() throws {
        try shipped { $0["over"] = true }.write(to: p.legacySaveURL)
        XCTAssertNil(p.loadSave(Horn1849.id))
    }
}
