# Around the Horn

A retro resource-management game for iOS, with a web version, in six journeys that share
one engine and one app shell:

| Journey | Id | Design |
|---|---|---|
| Around the Horn, 1849: New York to San Francisco by way of Cape Horn, 14,000 nautical miles | `horn1849` | [`docs/SPEC.md`](docs/SPEC.md), [`docs/reference/horn1849.html`](docs/reference/horn1849.html) |
| The Iron Road, 1869: freight from Omaha to Sacramento | `rail` | [`docs/journeys/rail.md`](docs/journeys/rail.md) |
| Over the Pole, 1926: an airship from Rome to Nome | `airship` | [`docs/journeys/airship.md`](docs/journeys/airship.md) |
| The Jet Stream, 1999: a balloon round the world from Marrakech | `balloon` | [`docs/journeys/balloon.md`](docs/journeys/balloon.md) |
| The Long Transfer, 2087: a chartered freighter from Earth orbit to Jezero on Mars | `mars` | [`docs/journeys/mars.md`](docs/journeys/mars.md) |
| To the Klondike, 1898: Seattle to Dawson over a pass | `klondike` | [`docs/journeys/klondike.md`](docs/journeys/klondike.md) |

SwiftUI, iOS 17, Apple frameworks only, no third-party dependencies, all persistence local.

- **How the journeys share the engine and the shell:** [`docs/design/journeys-architecture.md`](docs/design/journeys-architecture.md).
- **1849's reference implementation:** [`docs/reference/horn1849.html`](docs/reference/horn1849.html).
  Where its spec and the prototype disagree on a number, a formula or a line of text,
  the prototype wins.
- **Where this repo departs from a spec, and why:** [`docs/decisions.md`](docs/decisions.md).
- **The web version:** [`web/README.md`](web/README.md). The same engine compiled to
  WebAssembly (`web/horn.wasm`, built from `HornEngine` and the bridge in `HornWeb`) under
  a JavaScript shell ported file for file from the app's (`web/js`).

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
| `HornEngine` | The game: every journey's tables, rules, events, trading and scoring, under one day simulation. A framework with no UI import, so the engine stays pure by construction. |
| `HornEngineTests` | The rules of every journey, 1849's prototype parity and golden voyages, and each journey's balance harness (headless seeded voyages). |
| `AroundTheHorn` | The SwiftUI app: the shared shell, and each journey's skin under `AroundTheHorn/Journeys/`. |
| `AroundTheHornTests` | App unit tests, hosted in the app. |
| `AroundTheHornUITests` | Drives the simulator: launches, saves, a smoke test per journey, and the screenshot walks. |

`HornWeb` (in `Package.swift` only) is the bridge the web build compiles with the engine.

## Tests

```sh
swift test --disable-sandbox --scratch-path "$TMPDIR/horn-engine"   # the engine on the Mac, ~2 min

D='platform=iOS Simulator,name=iPhone 17 Pro'
xcodebuild test -scheme HornEngine           -destination "$D"   # the engine in the simulator
xcodebuild test -scheme AroundTheHornTests   -destination "$D"   # the app
xcodebuild test -scheme AroundTheHornUITests -destination "$D"   # drives the simulator
```

`Tools/run_tests.sh <scheme> [XCTestClass]` runs the same suites without `xcodebuild
test`, which cannot allocate a pty inside a sandboxed shell. It builds for testing and
spawns the bundle into a booted simulator instead.

The web version's tests run in Node 20 or later; [`web/README.md`](web/README.md) lists
them. All of them, from the repository's root:

```sh
for f in Tools/web-tests/*.mjs; do
  case $f in */lib.mjs|*/player.mjs|*/dom.mjs|*/port.mjs) continue;; esac
  echo "$f: $(node "$f" 2>&1 | tail -1)"
done
```

No CI runs the Node tests: run them before committing any change to `web/`, `HornWeb/`,
`HornEngine/` or a skin.

The `AroundTheHorn` scheme has no test action, deliberately: a plain Run never drags a
test build along with it.

## Debug launch arguments (debug builds)

| Argument | Does |
|---|---|
| `-journey <id>` | Opens on that journey's title card. Without it the app opens on the picker, or on the journey last chosen. Every UI test names one. |
| `-HornDebugStart <stopID>` | Starts the journey's well-stocked voyage ten units short of a stop (1849: `cv`, `rio`, `tdf`, `gal`, `sf`…), on its menu. `-HornDebugMonth <n>` sets the departure month. |
| `-HornDebugAtStop YES` | With `-HornDebugStart`: at the stop itself, under way, its arrival already told. |
| `-HornDebugMile <n>` | With `-HornDebugStart`: at that point of the route instead. |
| `-HornDebugHull <n>`, `-HornDebugSails <n>` | With `-HornDebugStart`: the two condition meters down to `n`%. |
| `-HornDebugFuel <n>`, `-HornDebugFood <n>`, `-HornDebugWater <n>` | With `-HornDebugStart`: that much aboard. |
| `-HornDebugVar <key>=<n>` | With `-HornDebugStart`: one of the journey's own variables (a fork's way taken, say). |
| `-HornTickSeconds 4` | Slows the travel clock (UI tests can't query a screen that redraws every 0.7 s). |
| `-HornSceneGallery YES` | Every weather of the journey's scene side by side. |

## Screenshots

`simctl io screenshot` comes back blank in the sandbox. A screenshot walk per journey
(`ScreenshotUITests` for 1849, `RailScreenshotUITests`, `AirshipScreenshotUITests`,
`BalloonScreenshotUITests`, `MarsScreenshotUITests`, `KlondikeScreenshotUITests`) plays
the game and saves what is drawn instead; the reference sets are in `docs/reference/`.

```sh
SIMCTL_CHILD_HORN_SHOTS=/path/to/new/dir sh Tools/run_tests.sh AroundTheHornUITests ScreenshotUITests
```

## App icon

`python3 Tools/make_icon.py` writes the icon: the prototype's pixel ship on navy, opaque
1024×1024 (spec M9).

## License

MIT, see [`LICENSE`](LICENSE). The two fonts in `AroundTheHorn/Resources/Fonts`
(VT323 and Press Start 2P) are not covered by it: they ship under the SIL Open Font
License 1.1, in [`OFL.txt`](AroundTheHorn/Resources/Fonts/OFL.txt) beside them.
