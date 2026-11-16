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

## D10 — The save keeps what is still waiting to be shown (2026-11-13)

The engine moves the voyage on before the player sees what a turn raised: a stop is
behind you before its arrival is offered. The spec saves after every turn and resumes on
a menu, so a voyage left with a warning on screen came back past the stop, its question
never asked, and at the last stop could never end. The controller now saves the queue
with the voyage, the interrupt on screen first, under a `pending` key that is written
only when something is waiting: a save with nothing waiting is the voyage alone, exactly
as before, and older saves read with nothing waiting. Continuing shows what was waiting,
then a menu (spec §2: a menu, not the loop). A save standing on the last stop with
nothing waiting, as older builds could leave one, is told of its arrival. Nothing 1849
says or shows changes.

## D11 — 1849's role, ration and trade lines in its own words (2026-11-14)

The role screen, the ration names and the trade row kept the prototype's wording, which
sat close to an older game's. Ryan ruled to reword them: the role intro now reads "Every
sort of person sailed for California in 1849. Choose who you will be:", the roles are "A
Boston merchant", "A Mystic shipwright" and "A Nantucket whaler", the differences are
"How do they compare?" / "How they compare", the rations are Full / Short / Scant, and the
port row is "Seek a trade". Words only: no number, formula or random draw changed, so the
prototype parity, balance and golden-voyage tests are untouched. The rail journey's
matching lines were reworded the same day. The reference screenshots of the screens that
show these lines are retaken with the next screenshot walk.

## D12 — The web version runs the engine itself, compiled to WebAssembly (2026-11-14)

It was ruled that the browser runs the exact Swift engine, not a second copy of the rules.
`HornWeb/` is a JSON bridge over the engine's public calls (GameController's, one for
one), built by `Tools/build_web.sh` into the committed `web/horn.wasm` (web/README.md).
Under WASI the engine imports FoundationEssentials instead of Foundation: the full
Foundation brings ICU's data and made the file 62 MB, Essentials 13 MB. Essentials lacks
the two String methods the engine uses (`trimmingCharacters`, `replacingOccurrences`), so
Text.swift has them behind `#if os(WASI)`, answering as Apple's Foundation does: the trim
takes Unicode's White_Space and U+200B, scalar by scalar, and the escape doubles a "["
unless the scalar after it extends it (Grapheme_Extend, an emoji skin tone). That is not
Swift's Character: a Prepend before the "[" (U+0600, say) does not stop it, and the app's
Markup, which reads by Character, then takes what follows for a tag, so a name such as
"؀[red]Queen" colours the rest of a line in the app. The web reads markup by Character too
and does the same; a fix belongs to the engine's escape or the app's Markup. On Apple
platforms nothing changes: the `#if` keeps `import Foundation`, and the three gates are
untouched. `Tools/web-tests/golden.mjs` replays the 300 golden voyages
through horn.wasm against the Mac's fixture, and `parity.mjs` compares every reply of
seeded 1849 and rail voyages between horn.wasm and the bridge built for the Mac, and the
escape beside every scalar (the marks new in Unicode 17.0 aside, which Swift's tables know
and macOS 15's Foundation does not). An Int is 32 bits in WebAssembly; no amount in the
game comes near 2^31. The build leaves out the per-object LLVM module hash, which covered
the checkout's paths, so horn.wasm is the same byte for byte wherever it is built.

## D13 — The web game is the app's shell, ported file for file (2026-11-14)

The browser game (web/README.md) plays 1849 and the Iron Road through `horn.wasm` with
the app's own flow, words and pictures: `web/js/flow.js` is GameController line for line
(the picker, the queue, the 0.7 s turn, the save that keeps what is waiting), and each
journey's four skin files are its Swift skin's, function for function.
`Tools/web-tests/skin.mjs` and `rail-skin.mjs` check every literal, colour, sprite row and
map point against the Swift source. `?journey=<id>` and `horn.lastJourney` stand for the
app's `-journey` launch argument and the journey it remembers. What the web has that the app
does not, or lacks: saves in `localStorage` (`horn.save-<id>`, `horn.topten-<id>`); Space
throws at the nearest fish, as VoiceOver's double-tap does in the app; no haptics; text
sizes fixed at the app's defaults rather than following Dynamic Type; canvases drawn a
whole number of device pixels to the logical pixel and scaled by the browser. No rule,
number or sentence of the game changed.

## D14 — On the Iron Road a train at 0% breaks down, and no wood is a crisis (2026-11-15)

Reported from play on the Iron Road: the train's health went below 0, and with no cord
left she still moved just fine. Reproduced (`RailBreakdownTests`, and the web flow in
`rail.mjs`):
nothing was ever stored below 0 or shown as "-0" (Swift's `Int(...)` and JavaScript's
template strings both write a negative zero as "0", and no meter could hold one), but the
road kept reporting damage at a meter already at 0% ("Engine −13%" with the engine at
0%); an engine at 0% ran on at 45% of her speed, the shared floor 1849 takes from the
prototype; with no wood she ran at a quarter, with nothing on the status box to say so;
and a road accident could leave a crew member's health at −6 until the next turn.

Ruled for rail only (docs/journeys/rail.md, "Breakdowns" and "Out of wood"): a train whose
engine or running gear shows 0% has given out and stands where she is until she is
mended (fittings, car spares, a mechanic someone walks down the line for at $45 and
twelve hours to a day, or, in a yard, a spare from its store or its roundhouse); with
nothing to mend her and no money she is stranded, which ends the run. A set piece she
reached as she gave out waits until she is mended. Worn running gear breaks down rather
than wrecks; the trestle, the culvert and the runaway still wreck. With no wood she
crawls at 0.22 of her speed and the fence posts wear the engine; a part cord burns for
its share of the turn, and nothing on the road burns wood that is not aboard. Damage is reported as
the status box will show it, and road accidents leave a crew member at 1 health at least.
The status box gets a red row for it (`Words.trouble`, in the app and on the web).

Shared, with defaults that leave 1849 byte for byte as it was (the three gates are
unedited and green): `Journey.stalled`, nil unless a journey says its vehicle cannot move,
called before a turn draws anything; `Rules.wearWrecks`, true, under which wear that
takes the hull to nothing founders the ship as before; `Rules.burnsPartLoad`, false, under
which a part load is thrown away and the whole turn runs on `noFuelSpeed` (1849 burns
nothing, so never reaches it). `.enterPort` under way, as rail's "take stock" sends it,
is the menu under way. The October bands hold without being touched: 30/26/15 of 30,
median 74 turns (it was 30/27/15, 75), and inside them at all ten seed bases surveyed
(docs/journeys/rail.md, "Balance, as built").

1849 has the same three things, and they are the prototype's rules, so nothing changed:
her sails at 0% still drive her at 45%; a split topsail or a lost topmast can report
"Sails −28%" or "Sails −15%" with the sails at 2%; and two of her events
(Horn1849+Events: the topmast's broken arm and the privateers') take 10 and 20 health
without a floor, so a crew member's health can stand below
0 until the next day's health clamps it and buries them. Two more were found in review:
the galley fire takes 4 from the hull and, unlike the leak and the topmast, never asks
whether she sinks, so a ship at 4% or less is left at 0% (not over), can be patched
back up from there, and otherwise sails one more day at the hull's speed floor before
that day's wear founders her; and lightning reports "Sails −18%" whatever the sails had
left. None of these is shown as a negative number (the supplies screen draws health as
a bar, clamped). They are left to be ruled on, not changed by this decision.

## D15 — Repairs are offered in the order the condition box lists them (2026-11-15)

The repairs screen showed the hull above the sails (rail: the running gear above the
engine; the airship: lift above the engines), then offered to mend the sails first and
the hull second, as the prototype does. Ryan found it backwards. Every journey's repairs
now come in the box's order, hull-role first, matching the shipyard and the status
panel; rail's breakdown question lists the running gear before the engine for the same
reason. Order only: no repair, cost or number changed.
