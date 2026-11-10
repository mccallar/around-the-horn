// swift-tools-version:5.9
// Host-side build of the pure engine, so engine work can be compiled and tested on the
// Mac with `swift test` — no simulator, and several checkouts can test at once. The app
// itself is built by Xcode from project.yml; this package never builds UI.
import PackageDescription

let package = Package(
    name: "HornEngine",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [.library(name: "HornEngine", targets: ["HornEngine"])],
    targets: [
        .target(name: "HornEngine", path: "HornEngine"),
        .testTarget(name: "HornEngineTests", dependencies: ["HornEngine"], path: "HornEngineTests",
                    exclude: ["Fixtures"]),
    ]
)
