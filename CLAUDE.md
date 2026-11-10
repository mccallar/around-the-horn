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
