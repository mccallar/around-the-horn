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

## D5 — A literal "[" in markup is written "[[" (2026-11-09)

Spec §13 says names must never be read as markup. `Markup.escape` doubles every "[" in
a player-entered string before it goes into a message, and the M3 parser reads "[[" as
a plain "[". A captain named "[red]Bob" reads as exactly that.

## D6 — Where the spec and the prototype disagree, the prototype wins (2026-11-09)

Found while porting, and settled the spec's way: the prototype is the reference.

- **Tackle cap.** Spec §4 lists "600 throws". The prototype's `cap()` is `max × per` =
  600 boxes × 20 = **12,000 throws**. HornEngine follows the prototype.
- **Speed rounding and every other rounding** use JavaScript's `Math.round` (halves go
  up, −2.5 → −2), via `jsRound`, not Swift's `.rounded()`.

Prototype quirks kept on purpose, because changing them changes the game:

- A stowaway found after Cape Verde and told to go ashore there is never put ashore
  (they sail on to California as crew).
- The Galápagos landing passes two days without rolling the weather, unlike resting.
- Hull damage from running aground and from ice can take the hull below 0 for an
  instant; `checkSink` then sets it to 0 and ends the game, as in the prototype.

## D7 — The engine is checked against the prototype itself (2026-11-09)

`Tools/prototype-diff/trace.mjs` runs the prototype's own `<script>`, unmodified, in
Node with `Math.random` replaced by the engine's SplitMix64, and records the full state
before every sailing day of sixteen voyages (`voyages.json`; ports, repairs, rests,
trades, burials, both passages, the pilot, starvation, sinkings).
`PrototypeParityTests` replays each through HornEngine with the same seed and the same
decisions and requires identical state, exactly, every day. To make that possible every
engine function draws its random numbers in the prototype's order, including draws
whose result is thrown away. Regenerate the fixture whenever the prototype changes.

## D8 — The M2 bot is rebuilt from the spec's description (2026-11-09)

The prototype's `test/bot.js` was not supplied. `SensibleBot`
(HornEngineTests/BalanceSimulationTests.swift) follows spec §12 M2 to the letter, and
where the spec is silent it takes the cautious choice:

- departs December or January (alternating by seed), the game's own advice;
- runs from strange sails, lets the albatross be, puts the stowaway ashore, shortens sail
  in ice, hires the pilot when it can afford him, declines trades, goes ashore at every
  port;
- buys, in order while money lasts: food, water (1 gal/person/day, no tropical margin),
  citrus, woolens to crew, then 2 medicine, 2 sailcloth, 2 timber, and 3 boxes of tackle
  for non-merchants;
- recuts sails at the shipyard below 70%, as well as the hull;
- fishing is simulated as up to 15 throws, each hitting (35%, whaler 55%) a fish drawn by
  the game's own weights.

Results, three seed sets of 30 voyages per role:

| | seeds 1849 | 50000 | 90000 | spec band (±15 pp) |
|---|---|---|---|---|
| merchant | 30/30 | 29/30 | 30/30 | ≥ 85% |
| shipwright | 28/30 | 28/30 | 28/30 | 45–85% |
| whaler | 17/30 | 17/30 | 16/30 | 15–50% |
| median winning voyage | 165 d | 165 d | 165 d | 150–200 d |

All pass with the tolerance. **The shipwright wins 93% every time, above the
untolerated band.** Most likely this bot plays better than bot.js did, not that the
balance moved: the engine matches the prototype exactly (D7). No balance number has been
touched; whether to tighten the shipwright is Ryan's call (spec §0.5).

Most whaler losses are thirst: the bot's water rule has no margin for the Doldrums.

(Corrected 2026-11-09: the first row was first recorded as 13/30 for the whaler from a
draft of the bot that spent one extra random draw before sailing. The committed bot
gives 17/30, on the simulator and on the Mac alike — the engine is deterministic across
both.)

## D9 — One engine, many journeys (2026-11-10)

Ryan asked for variations on the game (rails, airships, balloons, another planet), planned
and built without his input. The engine was split into shared rules and a `Journey` that
supplies tables, numbers, text and hooks (docs/design/journeys-architecture.md); 1849
became the first journey.

- **1849 is unchanged, and three gates prove it**: the prototype parity fixture (D7), the
  balance simulation (D8), and `GoldenVoyageTests`, 300 seeded voyages hashed day by day,
  recorded BEFORE the split and never re-recorded.
- The one change to `SensibleBot` is the name of the call that leaves port.
- The save is version 2: it names its journey and stores weather and ailments whole. A
  version-1 save (only ever on Ryan's own devices) is dropped, as any unreadable save is.
- Saves and top tens are per journey; the files from before are read as 1849's.
- New journeys' balance is set by their own bots and bands
  (`HornEngineTests/<Name>Tests.swift`); none of it touches a 1849 number.
- 1849's reference screenshots are in `docs/reference/shots-1849/`.
