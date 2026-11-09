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

## App icon

`python3 Tools/make_icon.py` writes the placeholder icon (the prototype's pixel ship on
navy). M9 replaces it.
