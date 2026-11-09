# Decisions

Where this repo departs from `SPEC.md`, and why. Balance numbers are never changed
without Ryan (spec §0.5).

## D1 — The engine is a framework target, not a folder (2026-11-09)

Spec §2 puts the engine in `AroundTheHorn/Engine/`. Here it is `HornEngine/`, its own
framework target, following Slap Royale. "No SwiftUI/UIKit imports" is then enforced by
the compiler and by `HornEngineTests/PurityTests`, not by a comment. The file names
inside (`GameState.swift`, `GameData.swift`, `GameEngine.swift`, `Interrupt.swift`,
`RNG.swift`, `Trade.swift`, `Score.swift`) are the spec's.

Consequence: engine types the app uses must be `public`.

## D2 — Engine tests live in `HornEngineTests` (2026-11-09)

Spec §2 lists `AroundTheHornTests/EngineTests.swift` and `BalanceSimulationTests.swift`.
Both go in `HornEngineTests` instead: they need no app host and no simulator UI, so they
run in seconds. `AroundTheHornTests` is for app-side code (`GameController`, persistence,
markup parsing).

## D3 — XcodeGen, generated project committed (2026-11-09)

The spec's fallback path, and how every one of Ryan's apps is set up. `project.yml` is
the source of truth. `AroundTheHorn.xcodeproj` and `AroundTheHorn/Info.plist` are
generated but committed, as in Slap Royale, because Xcode Cloud builds from the checkout
and does not run XcodeGen. Regenerate and commit both whenever `project.yml` or the file
list changes.

## D4 — Swift 5 language mode (2026-11-09)

Spec §1 allows Swift 6 mode "if it compiles cleanly". Starting in 5.0, as Slap Royale
does, so strict concurrency doesn't fight the `@MainActor` travel `Task`, AVAudioEngine
render callbacks or `TimelineView` canvases. Revisit after M8.
