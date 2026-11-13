# Around the Horn: 1849

Read `docs/SPEC.md` and `docs/reference/horn1849.html` (the `<script>` block) before
writing game code. **The prototype is the reference implementation**: when the spec and
the prototype disagree on a number, a formula or a line of text, follow the prototype.
Departures from the spec are recorded in `docs/decisions.md`; add one there whenever you
make one.

## Rules

- Work the milestones in `docs/SPEC.md` §12 in order. Each milestone's acceptance
  checks pass, and the suites are green, before the next starts.
- **Never change a balance number without asking Ryan** (spec §0.5).
- Apple frameworks only. No SPM packages, no third-party code. The two fonts (VT323,
  Press Start 2P) are SIL OFL and ship with `OFL.txt`.
- `HornEngine` imports nothing UI. `PurityTests` reads the source to enforce it.
  All randomness goes through an injected `RandomSource`.
- Every sentence a player reads is original (spec §13). No names, text or art from any
  commercial game.
- Never edit `AroundTheHorn/Info.plist` or the `.xcodeproj` by hand: edit `project.yml`
  and run `xcodegen generate`. Declaring a scheme in `project.yml` turns off
  auto-generation, so every scheme must be listed there.

## Skins

The app's shell is shared by every journey. Anything that belongs to one journey (a word,
a number, a colour table, a drawing) lives in its skin under `AroundTheHorn/Journeys/`
and is reached through `c.skin` (`Skins.skin(journey.id)`); anything the rules know comes
from `c.journey`. Never put a ship, a captain, a sea, a day or a mile into a shared view:
add a member to `JourneySkin` (no defaults, so every skin must answer) and let
`SkinContractTests` hold it. Saves and top tens are per journey (`save-<id>.json`,
`topten-<id>.json`). See `docs/design/journeys-architecture.md` §2 "As built".

- **Amounts go through `Stores`.** The engine counts in stored units (`Item.per` to the
  unit sold). Never print `g[key]`, a `catchLimit` or a quarry's `lb` beside a unit:
  use `Stores.measure` / `count` / `have`, or `FishingView.reward` in the mini-game.
- A screen may only offer a way out to the title or the picker when `c.hasPicker`
  (`c.wayBack`, `c.wayOut`): with one journey 1849's screens have no extra rows.
- The journey in hand changes only in `GameController.select`, with its skin.
- `save.json` from the shipped build (save version 1) is read by `Horn1849LegacySave`.
  Never delete a save file the build could not read.
- UI tests always launch with `-journey <id>` (`LaunchUITests.horn`); a plain launch
  opens on the picker, or on the journey last chosen, once there are several.
- What one journey can't show is tested with `AroundTheHornTests/TestJourneys.swift`.

## Building and testing

- **Engine work: `swift test --disable-sandbox --scratch-path $TMPDIR/<unique>`** builds
  and tests HornEngine on the Mac (Package.swift), no simulator, ~1 min. Results are
  identical to the simulator's. Use a unique scratch path per checkout so several can
  test at once.

- `xcodegen generate` after adding or removing any file.
- `sh Tools/run_tests.sh HornEngine` / `AroundTheHornTests` / `AroundTheHornUITests`
  (`xcodebuild test` can't allocate a pty in the sandbox). One run per simulator at a
  time; use `SIM_NAME` / `SIMULATOR_UDID` to separate concurrent runs.
- `-disable-sandbox` is a build setting (`OTHER_SWIFT_FLAGS`), not an xcodebuild flag;
  `run_tests.sh` already passes it so `@Observable` macros expand.
