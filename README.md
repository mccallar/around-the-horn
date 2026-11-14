# Around the Horn: 1849

A retro sea-voyage resource-management game for iOS: New York to San Francisco by way of
Cape Horn, 14,000 nautical miles, 1849. SwiftUI, iOS 17, Apple frameworks only, no
third-party dependencies, all persistence local.

- **What to build:** [`docs/SPEC.md`](docs/SPEC.md), milestones M1–M9 in order (§12).
- **The reference implementation:** [`docs/reference/horn1849.html`](docs/reference/horn1849.html).
  Where the spec and the prototype disagree on a number, a formula or a line of text,
  the prototype wins.
- **Where this repo departs from the spec, and why:** [`docs/decisions.md`](docs/decisions.md).

The Xcode project is generated with [XcodeGen](https://github.com/yonaskolb/XcodeGen).
`project.yml` is the source of truth; the generated project IS committed, because Xcode
Cloud builds straight from the checkout. Regenerate and commit it after any change:

```sh
xcodegen generate
open AroundTheHorn.xcodeproj
```

## Targets

| Target | What it is |
|---|---|
| `HornEngine` | The game: tables, state, the day simulation, events, trading, scoring. A framework with no UI import, so the engine stays pure by construction. |
| `HornEngineTests` | M1 unit tests and the M2 balance harness (headless seeded voyages). |
| `AroundTheHorn` | The SwiftUI app. |
| `AroundTheHornTests` | App unit tests, hosted in the app. |
| `AroundTheHornUITests` | Drives the simulator. |

## Tests

```sh
D='platform=iOS Simulator,name=iPhone 17 Pro'
xcodebuild test -scheme HornEngine           -destination "$D"   # the rules + balance
xcodebuild test -scheme AroundTheHornTests   -destination "$D"   # the app
xcodebuild test -scheme AroundTheHornUITests -destination "$D"   # drives the simulator
```

`Tools/run_tests.sh <scheme> [XCTestClass]` runs the same suites without `xcodebuild
test`, which cannot allocate a pty inside a sandboxed shell. It builds for testing and
spawns the bundle into a booted simulator instead.

The `AroundTheHorn` scheme has no test action, deliberately: a plain Run never drags a
test build along with it.

## Debug launch arguments (debug builds)

| Argument | Does |
|---|---|
| `-HornDebugStart <stopID>` | Starts a stocked merchant ten miles short of a stop (`cv`, `rio`, `tdf`, `gal`, `sf`…), on the sea menu. `-HornDebugMonth 5` sets the departure month. |
| `-HornTickSeconds 4` | Slows the voyage clock (UI tests can't query a screen that redraws every 0.7 s). |
| `-HornSceneGallery YES` | Every weather of the sea scene side by side. |

## Screenshots

`simctl io screenshot` comes back blank in the sandbox. `ScreenshotUITests` walks the
game and saves what is drawn instead:

```sh
SIMCTL_CHILD_HORN_SHOTS=/path/to/dir sh Tools/run_tests.sh AroundTheHornUITests ScreenshotUITests
```

## App icon

`python3 Tools/make_icon.py` writes the icon: the prototype's pixel ship on navy, opaque
1024×1024 (spec M9).

## License

MIT, see [`LICENSE`](LICENSE). The two fonts in `AroundTheHorn/Resources/Fonts`
(VT323 and Press Start 2P) are not covered by it: they ship under the SIL Open Font
License 1.1, in [`OFL.txt`](AroundTheHorn/Resources/Fonts/OFL.txt) beside them.
