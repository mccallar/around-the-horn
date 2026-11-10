# Digest — Proposal B: one protocol per journey, shared day loop, hooks

Source: journal record line 10 of `wf_da0c2e51-23c` (an earlier design run). This digest
keeps the declarations, mapping, steps, UI plan and risks; prose is cut. Judging notes in
*italics* are this run's, checked against the engine on `journeys`.

## Idea

`GameEngine` keeps ONE day loop (sailDay, passDays, consume, health, sicken, deaths, wear,
checkSink, arrivals, shop, trade, repairs, yard, fishing, score). Wherever v1 applies a
1849-only rule, the loop calls one of **14 hooks** on `journey: any Journey`. A journey is
a type in its own folder: `JourneyData` (tables), `JourneyText` (every engine sentence),
hook methods, an events file.

Principles:
- **P1 Move, don't rewrite** — 1849's rule bodies are cut-and-pasted into `Horn1849` hooks
  called at the line they came from.
- **P2 Same expression shape** — literals may become table fields of equal value; nothing
  merged/regrouped. Measured: `d -= (1.4 + 1)` → `d -= 1.4; d -= 1` differs on 5.9% of
  inputs; `base*mult*mod` → `base*(mult*mod)` differs on 28.6% of prices; ×1.0 / ±0.0 never
  differs.
- **P3 Only arrays carry order** — never iterate a Dictionary or Set (Swift seeds hashing
  per process; a probe listed the 8 item keys in different orders on two runs).
- **P4 No silent defaults** — every hook is a requirement with no default; standard
  behaviour is a library `Standard.*` a journey calls explicitly.
- **P5 Parity gate never moves** — `PrototypeParityTests.swift`, its fixture and
  `Tools/prototype-diff/` byte-identical; `Interrupt` keeps 7 cases (the parity file
  switches exhaustively).
- **P6** After step 8 a journey adds a folder + one registry line; no `Core/` edits.

## Key declarations

```swift
public struct ID<Tag>: RawRepresentable, Hashable, Codable, CodingKeyRepresentable,
                       ExpressibleByStringLiteral { public let rawValue: String
    public init?(rawValue: String) … }          // encodes as a bare string, like v1 enums
typealias JourneyID/ItemID/RoleID/PaceID/RationsID/WeatherID/AilmentID/RegionID/RegionFlag/PassageID = ID<…Tag>
public enum Temp { cool, warm, hot, cold, freezing }
public enum StopType { port, mark, special, fork, end }     // v1 line/island → special
public enum Meter { structure, propulsion }

public protocol JourneyDefinition { var id: JourneyID; var data: JourneyData; var text: JourneyText }
protocol Journey: JourneyDefinition {          // internal; NO default implementations
    // pure queries
    func temperature(_ s: GameState, in reg: Region) -> Temp
    func weatherWeights(_ s: GameState, _ reg: Region, cursed: Bool) -> [(WeatherID, Double)]
    func adjustSpeed(_ s: GameState, _ sp: inout Double, preMove reg: Region)
    func coldDamage(_ s: GameState, _ temp: Temp, warm: Bool) -> Double?
    func forkPrompt(_ s: GameState) -> String
    func score(_ s: GameState) -> Score
    // effects (may draw), each called at exactly one point
    func structureWear(_ e: GameEngine, preMove reg: Region) -> Double
    func hazards(_ e: GameEngine, preMove reg: Region) -> [Hazard]
    func randomEvents(_ e: GameEngine, preMove reg: Region) -> [RandomEvent]
    func dailyEffects(_ e: GameEngine, _ q: inout [Interrupt], _ mode: GameEngine.DayMode)
    func specialChoice(_ e: GameEngine, at stop: Stop) -> ChoiceEvent
    func resolveSpecial(_ e: GameEngine, stopID: String, option: Int) -> [Interrupt]
    func eventChoice(_ e: GameEngine, id: String, args: ChoiceArgs) -> ChoiceEvent
    func resolveEvent(_ e: GameEngine, id: String, args: ChoiceArgs, option: Int) -> [Interrupt]
}
struct Hazard { let applies: Bool; let probability: Double; let run: (inout [Interrupt]) -> Void }
struct RandomEvent { let weight: Double; let ok: Bool; let run: (inout [Interrupt]) -> Void }
enum Standard { temperature, weatherWeights, adjustSpeed, coldDamage, structureWear, forkPrompt, score }
```

`JourneyData` (one struct): title, contentVersion, playable, totalDistance, unit,
calendar (ticksPerDay), departures, roles, handsAtStart, firstNames, vehicleNames, items
(ordered), `ItemSlots{food, water, medicine?, warmth?}`, paces, rations, stops, ports,
regions, routeRegions, fork, weather, fairWeather, seasons, curseBumps, ailments,
`SicknessPools{feverPort, hot, cold, normal}`, `HealthRules` (every v1 health constant
as a field: baseRisk 0.0035, riskPerLostHP 0.00035, starving 0.03, thirst 0.04, hot 0.003,
unwarmCold 0.01, feverPort 0.012, portFactor 0.7, seaRest 3, portRest 6, starvingHP 7,
thirstHP 12, recovery 1, treated 0.5, recovery 1/1.5/2), `ConsumptionRules`,
`Deficiency{ailment,item,0.02,35,0.004,0.12,0.35,0.6}`, `SpeedRules{0.45,0.55,0.75,0.25,
crew:[0.45,0.45,0.65,0.85,1], jitter 0.85…1.15, eventChance 0.11}`, `WearRules{jitter
0.6…1.4, spoilage, warn thresholds}`, repairs `[RepairDef{item, meter, amount, label,
done}]`, `YardRules{2.5, 1.8}`, fuels `[FuelRule]`, rainCatch, trade, minigame, scoring,
ranks, defaultTopTen. Lookups by linear search.

`ItemDef` adds `integral`, `tradeValue`, `tradeStep` (10/20/1), `phrase(one, many)`,
`shortName`, `storedUnit`. `PortDef.price = basePrice * mult * (mods[key] ?? 1)` (same
order). `JourneyText` holds ~35 sentences/closures (outOfFood, lowFood, wellAgain,
fellIll, medicineUsed, captainDied, structureFailed, warnings, spoiled, reached,
departure, rested, trade lines, defaultEpitaph …).

**GameState v2**: `journey`, `contentVersion`, `role: RoleID`, `vehicle`, `distance`,
`stock: Stock` (a non-Sequence wrapper over `[ItemID: Double]`), `structure`, `propulsion`,
`guide`, `withoutPreventive`, `curseDays`, `fairDays`, `seen: Set<String>`,
`counters: [String: Double]`, `flags` (+ fuelEmpty/fuelLow sets). v1 Int stocks become
Double with `rounded(.towardZero)` on write. Save at `saves/<journey>.json`; versioning
= `saveVersion` 2 + per-journey `contentVersion` + load-time validation; `GameStateV1`
decodes old saves and upgrades; old `save.json`/`topten.json` migrated to horn1849.

**Day loop** (shape): rollWeather (fairDays → fairWeather; hook weights; curse countdown;
one weightedPick) → speed = `baseSpeed(w)` (fuel fallback or `pace.speed*w.speed`) ×
propulsion × structure × crew table → `adjustSpeed` hook → jitter → move → `burnFuel`
(empty loop for 1849) → `w.travelNote` → consume → health → wear (propulsion draw, then
`structureWear` hook, then spoilage) → `dailyEffects` (`{}` for 1849) → if not arrived:
`for h in hazards where h.applies { if chance(p) { run; break } }` else `chance(0.11)` →
`randomEvent` (one weightedPick over eligible).

**Choices**: `Interrupt` unchanged. `ChoiceEvent.Kind` = `.portArrival, .tradeOffer,
.fork, .guide(cost), .special(stopID), .event(id, ChoiceArgs{name?, flag, amount?})`; an
`alert` flag replaces the `.stranger` sound match. Fork/guide/arrival/trade resolved by
the core; special/event by hooks. `ForkDef{routes:[ForkRoute{passage,label,chosen,guide}],
adviceLabel, advice, detail}`, `GuideOffer{cost 75, prompt, labels, hired, declined}`,
`RouteRegion{passage, from, to, region}`, `MarkDef{text, byPassage}`.

**Fuel**: `FuelRule{item, perDistance, perDay, perRestDay, paceScaled, whenEmpty:
.speed(x) | .structureLoss(x), lowDays, texts}`; `PaceDef.fuel`; `Perks.fuelBurn`.
**Roles**: `RoleDef{id,label,title,money,mult,perks{repair:[ItemID:Double], catchLimit,
hitPadding, fuelBurn, tags}, note}`. **Trade**: `TradeRules` constants; `roundTrade(step:)`.
**Score**: `ScoreRules` (perSurvivor, condition weights 2/1, supplies divisors 25/50,
stores parts, cash 5); `RankDef`; per-journey top ten. **Registry**: `Journeys.rules`
array in title order; `playable` filter.

## 1849 mapping (summary)

Equator, Galápagos → `.special` stops + `Horn1849.specialChoice/resolveSpecial` verbatim.
Gulf/Pacific → `MarkDef` (Pacific `byPassage[.magellan]`). Fork → `ForkDef` + winter text
in `forkPrompt`. Strait → `RouteRegion(7350..<7800)`. Pilot → `GuideOffer(75)`; aground
→ `hazards[0]` (`applies: s.inStrait`, p `guide ? 0.012 : 0.055`); Horn overboard →
`hazards[1]` (`reg.horn`, 0.012). Strait ×0.5 and Horn/Strait winter ×0.6 →
`adjustSpeed`. Winter and North-Atlantic bumps, curse bumps → `weatherWeights` verbatim.
Temperatures → `temperature` verbatim. +1 freezing in winter → `coldDamage`. Albatross
→ event sets `curseDays = 25`; St Elmo → `fairDays = 2`; stowaway → `leaveAt: "cv"`
handled by generic port arrival. Port fever, rain catch, scurvy, woolens → data.
Icebergs, privateers, 16 sea events → `Horn1849Events` verbatim, same order. Storm/gale
hull → `structureWear`. Fishing → `MinigameDef`. Perks → `RoleDef.perks`. Trade values
→ `ItemDef`. Yard, score, ranks, top ten → data.

Draw-order argument given per function (rollWeather, sailDay, consume, health, sicken,
wear, passDays, events, overboard/pirates/aground, resolve, makeOffer, buy, repairs,
score, the bot's own draws). Compat names (`Horn1849Compat.swift`): typealiases
`ItemKey/Role/Weather/Pace/Rations/Ailment/Passage`, a `GameData` facade, the old
`GameState` init and property names (Int where Int), `WarningFlags.limes/hull/sails`,
`Region.south/horn/strait`, engine `mendSails/patchHull/yard/departNewYork/
fishingRefusal/throwHarpoon`, `RoleID.allCases/scoreMultiplier/sailMend…`,
`RationsID.lb`. Public until the app moves off (S8), then internal.

## Migration (15 steps; gate V = swift test + balance printout 30/28/17/165 + golden + byte-diff of parity file/fixture/tool)

- **S0** Golden harness first: `GoldenVoyageTests` (106 voyages, a `TappedRNG` folds draw
  index + RNG state + canonical state projection into FNV-1a before every draw;
  checkpoint every 64 draws; bot voyages also fold all interrupt text); `save-v1.json`
  fixture; app `SceneSnapshotTests` pixel hashes. Tag `journeys-base`.
- **S1** `git mv` engine to `HornEngine/Core/`; make `PurityTests` recursive (it lists only
  the top folder today and would fail).
- **S2** Typed IDs, one commit per type (V ×2 — two runs catch hash-order leaks).
- **S3** `JourneyData` + `Horn1849Data.make()`; `GameData` becomes a facade.
- **S4** GameState v2 with compat computed properties; `GameStateV1.upgraded()`.
- **S5** Protocol + registry; hooks forward to code still in the engine.
- **S6a–g** Move, one area per commit: temperature/weights; speed; wear; consume/health;
  hazards/events; choices (**the one edit to `BalanceSimulationTests.decide`**, same
  answers, same `e.chance(0.5)`); trade/repairs/yard/minigame/score + `CoreIsJourneyFreeTests`
  (greps `Core/` for 1849 words).
- **S7** New capabilities (fuel, ticks, dailyEffects, counters, PortServices, SeasonRule,
  Standard.*) exercised only by a test-only `TestJourney`; `HookEquivalenceTests` prove
  `Standard.*` fed 1849's SeasonRules equals the hand-written hooks bit for bit.
- **S8** App on the abstraction, 1849 only (per-journey Persistence, skins, `HornScene`
  = `SeaScene` moved verbatim, `EarthChart`, `CatchSkin`); compat names → internal.
- **S9** Journey picker (shown only when >1 playable), per-journey top tens, gallery.
- **S10–S14** One journey each, parallel; `playable: false` until lint, bands, soak pass.
- **S15** decisions.md D9–D12.

## UI plan

Picker (when >1 playable) → parameterised TitleView → unchanged flow. `JourneySkin {
copy: JourneyCopy, scene: SceneRenderer, chart: ChartRenderer, catchSkin, tunes }`;
`JourneyCopy` holds every app-side string (top bar, title, learn, roles, names, month,
outfit, menu labels, status labels, meter labels per state, rest, yard, burial,
game-over "where", finale, rank legend, VoiceOver scene label). `SceneFrame{t, weather,
weatherSpeed, moving, atPort, portID, structure, propulsion, progress, state}`;
`HornScene` = v1 verbatim; `LayeredScene{horizon, sky:[WeatherID:SkyPalette], ground
(.sea/.rails/.landBelow/.space/.river/.snowfield), vehicle sprite per frame, town}`;
`SpriteDamage` generalises the torn-sail rule. `ChartRenderer`: `EarthChart`
(projection, land, routes keyed by passage) and `SchematicChart` (Mars). `CatchModel`
with v1 physics; `CatchSkin` (heading, HUD, backdrop, thrower, projectile); fin flag
replaces `name == "shark"`; reward is a `TradeGood`. `Persistence` per journey,
`lastJourney`, legacy migration; `GameController.journeyID`, `def`, `skin`.

## Tests

Gates (parity frozen, golden, balance). `TestJourney` generic tests (fuel, ticks,
deficiency, fork/guide, leaveAt, counters, trade rounding, score, saves). `Horn1849Tests`
(moved EngineTests). `HookEquivalenceTests`. `JourneyLintTests` (template counts,
ascending stops, region coverage, every ID resolves, every event resolvable, markup
parses, brand block-list). `BotPolicy` protocol + `JourneyBot` (1849's bot not
converted) with `BalanceBands`. `JourneySoakTests` (300 random voyages, invariants after
every call). App: persistence migration, scene/chart hashes, sprite lint, copy lint,
skin registry, picker UI test.

## Risks named

Hidden draw/float change (P1/P2, golden per-draw); mistyped override (P4); hash-order
iteration (P3, ×2 runs); compat names spreading (internal + confinement test); PurityTests
non-recursive; save migration; text drift (golden folds text); existential-call speed
(budget 2×); Standard.* wrong (equivalence tests); incomplete content docs (lint);
parallel-agent collisions; 1849 UI regressions (pixel hashes); Klondike vehicle change
(skin per stretch, `adjustSpeed` per stretch, a landmark resets meters).

## Judging notes (verified against the code)

- *Correct:* the hazard loop reproduces v1's `if inStrait && chance … else if reg.horn &&
  chance … else if chance(0.11)` short-circuit, provided `applies` is computed after the
  move (`inStrait` reads the post-move mile in v1, `reg` is pre-move). `state.inStrait`
  before the move equals `reg.strait` (both = Magellan region), so moving the two speed
  lines is safe. Crew table `[0.45,0.45,0.65,0.85,1][min(n,4)]` matches v1 for every n.
- *Correct:* the parity file switches over `Interrupt` exhaustively and the bot's `decide`
  switches over `ChoiceEvent.Kind` exhaustively, so any new case forces a test edit; B
  confines it to one edit. (`if case .fork = c.kind` would still match a `.fork` with a
  payload; the no-payload constraint is stronger than needed.)
- *Correct:* `PurityTests` uses `contentsOfDirectory` (not recursive).
- *Weak:* 14 mandatory hooks per journey, ~35 `JourneyText` closures and a large
  `JourneyData` make each new journey heavy; 1849 keeps hand-written hooks while new
  journeys use `Standard.*`, so two implementations of seasons/weights exist (mitigated by
  equivalence tests). Klondike's mode changes are pushed into the skin and `adjustSpeed`,
  with no engine notion of a leg — meters, pace names and fuel can't change per leg in
  data. Mars oxygen squeezed into the water slot.
