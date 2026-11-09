import XCTest
@testable import AroundTheHorn

final class AppInfoTests: XCTestCase {
    /// The two rename points must agree: the code's name and the one the home screen shows.
    func testDisplayNameMatchesBundle() {
        let bundled = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        XCTAssertEqual(bundled, AppInfo.displayName)
    }
}
