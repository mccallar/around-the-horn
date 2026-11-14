# Journeys — how it is built

The app is a collection of journeys of one shape: outfit, travel turn by turn, keep five
people and a vehicle alive, arrive, score. `docs/design/journeys-brief.md` is what was
asked for; this is what was built and what a new journey has to supply.

| id | Title | Status |
|---|---|---|
| `horn1849` | Around the Horn: 1849 | the original; must never change |
| `rail` | The Iron Road: 1869 — Omaha to Sacramento on the new Pacific Railroad | spec `docs/journeys/rail.md` |
| `airship` | Over the Pole: 1926 — Rome to Nome | spec `docs/journeys/airship.md` |
| `balloon` | The Jet Stream: 1999 | spec `docs/journeys/balloon.md` |
| `klondike` | To the Klondike: 1898 | spec `docs/journeys/klondike.md` |
| `mars` | The Long Transfer: 2087 — Earth orbit to Mars | spec `docs/journeys/mars.md` |

## 1. The engine

One engine, one set of rules, in `HornEngine/`:

- `GameEngine` runs a turn (`sailDay`) in a fixed order: date, weather, speed, distance,
  consumption, fuel, health, sickness, deaths, wear, the journey's `tick`, the journey's
  events, arrival. The order and the order of random draws are 1849's and are frozen.
- `Journey` (HornEngine/Journey.swift) is a class holding one journey's tables
  (items, stops, regions, ports, weathers, ailments, roles, paces, rations, names), its
  numbers (`Rules`, whose defaults are 1849's), every sentence the shared rules say
  (`JourneyText`, no defaults: a new journey writes all of them), and overridable hooks
  for whatever is its own.
- `Journeys.all` is the list. A journey is **a folder under `HornEngine/Journeys/` plus
  one entry in that list**. Journeys live inside the engine module so they can use its
  internal helpers.
- `GameState.journey` names the journey; `GameState.vars` holds a journey's own numbers.
  A save is version 2; a save for a journey the build doesn't have is not offered.

Three gates prove 1849 is unchanged and are never re-recorded: `PrototypeParityTests`,
`BalanceSimulationTests`, `GoldenVoyageTests` (300 voyages hashed day by day).

### The hooks

| Hook | Default | Override when |
|---|---|---|
| `region(_:at:)` | first region whose `to` is past the mile | a fork changes the country you cross |
| `temperature(_:in:)` | the region's | seasons change it |
| `harshSeason(_:)` | false | freezing is worse in a season |
| `weatherWeights(_:_:cursed:)` | the region's | seasons or the journey's state shift the odds (use `bump`) |
| `crewFactor(_:)` | 1 / 0.85 / 0.65 / 0.45 for 4+ / 3 / 2 / 1 hands | the vehicle needs fewer or more |
| `adjustSpeed(_:_:_:)` | nothing | grades, currents, head winds, a hired helper |
| `paceHP(_:)` | the pace's `hp` | the pace costs more in some places (hauling on foot against rowing) |
| `waterNeed(_:_:)` | `rules.water`, `hotWater` when hot | the need scales with the cold, or stops on some legs (the Klondike's firewood) |
| `structureDamage(_:_:)` | creep + rough weather × pace | the structure wears differently |
| `propulsionWear(_:)` | pace × weather × jitter | the drive rests while moving (an airship adrift) |
| `wreckedTitle(_:)`, `wreckedBody(_:)`, `leaderDiedBody(_:)` | `text.wrecked`, `text.wreckedBody`, `text.leaderDiedBody` | where it happens, or who is left, changes the ending |
| `mayDepart(_:)` | true | leaving the first port needs more than food (`text.noProvisions` says why) |
| `leaving(_:)` | nothing | leaving the ground costs something (a balloon's climb) |
| `holdInPort(_:)` | nil: you leave | leaving a port along the way needs something first (Bennett's boat and ice). `setSail()` then returns what happens instead and you stay ashore until `state.atPort` is cleared |
| `port(_:at:)` | the table's port at that stop | a fork changes who keeps the store (Dyea or Skagway) |
| `repaired(_:_:)` | `text.mended`, `patched`, `yardHull`, `yardSails` | what is mended changes on the way (an outfit, then a boat) |
| `foraged(_:)` | nothing | a foraging outing does more than stow its catch |
| `tick(_:_:_:_:)` | nothing | a per-turn rule of its own, in every mode |
| `dayEvents(_:_:_:)` | `eventChance` → one of `events` | several event tables |
| `events(_:_:)` | none | always: this is the journey's event list |
| `sickPool(_:_:_:)` | `ailments` | the pool depends on climate or port |
| `arrive(_:_:)` | mark → note, port → offer to stop, end → finale, else `special` | rarely |
| `special(_:_:)` | nothing | `.line`, `.fork`, `.island` stops: the set pieces |
| `resolve(_:_:_:_:)` | nothing | always: answers to `GameEngine.ask(key, args, …)` |
| `forageRefusal(_:)` | no gear; rough weather | foraging needs a place or a state |
| `tradeValue`, `roundTrade`, `describe` | from the item table | odd units |
| `tradeKeys` | every stocked item | a good nobody trades (the balloon's water) |
| `fitOffer(_:_:)` | the offer as drawn | an offer must fit the room left (the balloon cuts it, and its price) |
| `score(_:)`, `rank(_:)` | five generic lines; `Rules.rankCuts` | a bonus of its own |

### Rules of authorship

1. **Never touch 1849's numbers, text or draw order.** Run the three gates.
2. **Own namespace.** 1849's weathers, ailments and region ids are extensions on the
   shared types (`Weather.gale`, `Ailment.scurvy`). A new journey keeps its own in an enum
   of its own (`RailData.blizzard`), never as an extension of `Weather`, `Ailment`,
   `RegionID`, `Role`, `Pace`, `Rations` or `GameData`. Raw values only need to be unique
   within the journey.
3. **Order is data.** Only arrays are walked. Never iterate a `Dictionary` or a `Set`;
   never draw a random number in an order that depends on one.
4. **Every random number comes from the engine** (`e.rnd`, `e.ri`, `e.chance`, `e.pick`,
   `e.weightedPick`).
5. **Stock roles are fixed; names are the journey's.** `food`; `water`; `limes` = what
   wards off the slow sickness; `meds`; `clothes` = warmth, one per person; `sailcloth` =
   spare for what drives the vehicle (`state.sails`); `timber` = spare for what holds it
   together (`state.hull`, zero ends the game); `tackle` = what the foraging game spends,
   counted in throws; `fuel` = burned per turn by `PaceInfo.fuel`. A journey that doesn't
   carry one leaves it out of `items`. No water: `rules.water = 0; rules.hotWater = 0`.
6. **Choices** are raised with `e.ask("key", args, prompt:, detail:, options:)` and
   answered in `resolve`. Every choice needs at least one option that is always enabled.
7. **Markup** in messages: `[red] [green] [amber] [dim] [teal] [i] [b]`, each closed. A
   player's name goes through `TextMarkup.escape`.
8. **Voice and content**: every sentence original; real places and history are fine; no
   real company or brand names, no names or text from any game or book; hazards and
   death but no gore; no cruelty to animals as a mechanic; no politics.
9. **Tests per journey** (`HornEngineTests/<Name>Tests.swift`): the contract tests run
   over every journey automatically; add the journey's own rules (unit tests with
   `ScriptedRNG`) and a balance test with `JourneyBot.survey` that asserts win-rate bands
   for the three backgrounds and a median length. Bands are part of the design: the
   richest background should usually arrive, the poorest should lose more often than not
   only if played carelessly — aim for roughly 85–100% / 60–90% / 35–70% with the
   sensible bot, and a spread of endings (not one cause for every loss).

`JourneyBot` (HornEngineTests/JourneyBot.swift) is the sensible player: it shops for the
run to the next port from the journey's own tables, mends, rests, forages, and takes the
first enabled option unless the journey's test says otherwise.

## 2. The app

The shell is 1849's and is shared: dark navy, parchment text, the two pixel fonts,
numbered choices, a 160×80 pixel scene, a chart, a tap mini-game. What differs per journey
is a **skin**: `AroundTheHorn/Journeys/<Name>Skin.swift`, registered in one list, keyed by
`Journey.id`. A view never contains a word, a number, a colour table or a drawing that
belongs to one journey: it asks the engine's `Journey` for anything the rules know (item
names, units, pace names, stops, the rest menu's lengths, whether it burns fuel) and the
skin for the rest.

A skin supplies:

1. **Title card and setup copy**: title lines, tagline, the start and learn actions, the
   learn pages, the background intro and differences, the names prompts, the departure
   intro and advice, the outfitting intro and bullets, the first shop's heading, the rank
   legend, the finale and game-over wording that isn't the engine's.
2. **Words**: what the vehicle, the leader, the crew, the two meters, the distance unit,
   the menu actions (set out, rest, mend, patch, yard, trade, talk, forage) are called.
3. **Status panel rows**: labels and units for food and water (a journey with no water
   has no water row), a fuel row when `journey.burnsFuel`, the distance to the next stop
   and "of N", the two meters. Weather turns red when `weather.sky == .storm`.
4. **The scene**: a draw function over the 160×80 `PixelCanvas`, given time, weather,
   whether moving, whether in port, both meters, the region, the hour and the journey
   state. Shared helpers (sky bands, sun and moon, clouds, rain, snow, fog, lightning,
   dust, hills, a sprite blit, colour mixing) live in one place; a journey picks palettes
   by `weather.sky`, never by a weather's name. Plus the scene's accessibility sentence.
5. **The chart**: canvas size, title, accessibility text, a background draw, and the
   route as points with a mile at each (a function of the state, because a fork changes
   it). The dotted route, the travelled part, the stop marks, the blinking marker and the
   legend are shared and come from `journey.stops`.
6. **The mini-game**: `FishingModel` generalised: which way up the canvas is, where the
   throw starts, the backdrop draw, how the quarry and the thrown thing are drawn, the
   heading, hint, tally and accessibility text, the unit of what's caught. Quarry and
   duration come from `journey.quarry` and `journey.forageSeconds`; the reward is
   `journey.forageReward`.

Also shared and journey-aware:

- **Picker**: with more than one journey the app opens on a list (title, subtitle, a mark
  on one with a voyage in progress); choosing one shows its title card, which has a way
  back. Launch argument `-journey <id>` goes straight to a title card (UI tests).
- **Saves and top tens are per journey**: `save-<id>.json`, `topten-<id>.json`. The files
  from before journeys (`save.json`, `topten.json`) are 1849's and are read as such.
- **A contract test** over `Journeys.all`: every journey has a skin, every skin's copy is
  non-empty, every skin's draws run without trapping for every weather and stop.

**1849 must look and read exactly as it did.** The reference is the 38 screenshots taken
before this work (`docs/reference/shots-1849/`).

## 3. Adding a journey

1. Spec in `docs/journeys/<id>.md` (the brief's 20-section template, or compact).
2. `HornEngine/Journeys/<Name>/<Name>.swift` (tables, text, rules, hooks) and
   `<Name>+Events.swift`; a data namespace enum; one entry in `Journeys.all`.
3. `HornEngineTests/<Name>Tests.swift`: rules and balance.
4. `AroundTheHorn/Journeys/<Name>Skin.swift` and one entry in the skin list.
5. `xcodegen generate`; `swift test`; the app and UI suites; screenshots of the title,
   the first shop, travelling, a port, the chart and the mini-game.
6. Append "As built" to the spec: what differs from it and the bot's numbers.
