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
| `fuelBurn(_:_:)` | the pace's `fuel` | the drive can stand idle with fuel aboard (the airship's engines, given out, burn none) |
| `paceHP(_:)` | the pace's `hp` | the pace costs more in some places (hauling on foot against rowing) |
| `waterNeed(_:_:)` | `rules.water`, `hotWater` when hot | the need scales with the cold, or stops on some legs (the Klondike's firewood) |
| `stalled(_:)` | nil: the vehicle can move | it cannot, or has something to meet first (rail: broken down; a set piece held while she was); what is shown instead of the turn, which then takes no time and draws nothing |
| `structureDamage(_:_:)` | creep + rough weather × pace | the structure wears differently |
| `propulsionWear(_:)` | pace × weather × jitter | the drive rests while moving (an airship adrift) |
| `wreckedTitle(_:)`, `wreckedBody(_:)`, `leaderDiedBody(_:)` | `text.wrecked`, `text.wreckedBody`, `text.leaderDiedBody` | where it happens, or who is left, changes the ending |
| `mayDepart(_:)` | true | leaving the first port needs more than food (`text.noProvisions` says why) |
| `leaving(_:)` | nothing | leaving the ground costs something (a balloon's climb) |
| `holdInPort(_:)` | nil: you leave | leaving a port along the way needs something first (Bennett's boat and ice). `setSail()` then returns what happens instead and you stay ashore until `state.atPort` is cleared; `sailDay()` called while still ashore returns the same hold and passes no day |
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
   together (`state.hull`, zero ends the game unless the journey sets
   `rules.wearWrecks = false`, when it breaks down instead: rail); `tackle` = what the foraging game spends,
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
   and "of N", the two meters. Weather turns red when it is the journey's hardest by
   the rules' own figure (`Weather.harsh`), whatever its sky.
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
   heading, hint, tally and accessibility text. Quarry and duration come from
   `journey.quarry` and `journey.forageSeconds`; the reward is `journey.forageReward`,
   and the shell writes every amount of it (see "Amounts" below).

Also shared and journey-aware:

- **Picker**: with more than one journey the app opens on a list (title, subtitle, a mark
  on one with a voyage in progress); choosing one shows its title card, which has a way
  back. Launch argument `-journey <id>` goes straight to a title card (UI tests).
- **Saves and top tens are per journey**: `save-<id>.json`, `topten-<id>.json`. The files
  from before journeys (`save.json`, `topten.json`) are 1849's and are read as such.
  A save also keeps, under `pending`, whatever the last turn raised that the player has
  not yet answered (D10), so a voyage left mid-queue comes back to it.
- **A contract test** over `Journeys.all`: every journey has a skin, every skin's copy is
  non-empty, every skin's draws run without trapping for every weather and stop.

**1849 must look and read exactly as it did.** The reference is the 38 screenshots taken
before this work (`docs/reference/shots-1849/`).

### As built

The skin is one value, `JourneySkin` (`AroundTheHorn/Journeys/JourneySkin.swift`), found
by `Skins.skin(journey.id)`; the controller hands views `c.journey` and `c.skin`.

```swift
struct JourneySkin {
    let id: String                    // Journey.id
    let card: TitleCard               // banner, title, tagline, learn pages, setup copy
    let words: (GameState) -> Words   // menus, status and supplies names, meters, endings
    let scene: SceneSkin              // draw(PixelCanvas, SceneFrame), label(SceneFrame)
    let chart: ChartSkin              // size, background, route(state), others, project, overlay
    let forage: ForageSkin            // ForageField + copy + backdrop, quarry and thrown draws
    let debug: DebugSkin              // start(stop, month), extra gallery cells
}
```

- No member has a default, so a skin that leaves something out does not compile.
  `Words` is worked out from the state in hand, so a name can change along the way.
- `ForageField` says how the mini-game lies: canvas size, where a throw starts, `upward`
  (thrower at the bottom), the line taps must be beyond, the lanes the quarry crosses and
  its speed. `FishingModel` takes the field; nothing in it knows which way is up.
- `ChartSkin.route` gives points in the skin's own map space with a mile at each;
  `project` turns map space into canvas pixels. The shell draws the dots, the stops, the
  marker and the legend.
- Units the engine doesn't hold are in `Words`: `distanceUnit` and `distance`, `currency`,
  `looseUnits` (a box of tackle is 20 throws), `fractional` (items counted in tenths
  though stored whole) and `singular` (whether one of a thing takes `Item.one`).
  The rest menu is `rules.restChoices` through `words.restChoice`, so a turn need not be
  a day.
- **Amounts.** The engine counts in stored units, `Item.per` of them to the unit the shop
  sells. Only `Stores` (in `StatusPanel.swift`) turns a stored count into what a player
  reads, and the shop, the supplies list, the status box and the mini-game all go
  through it: `Stores.measure` ("1,500 lbs", "9.5 crates", "1.4 cords", "60 throws"),
  `Stores.count` (the bare number) and `Stores.have` (the shop's units). An item stored in
  parts of its unit is counted in tenths unless the skin counts it loose. The mini-game's
  tally, its limit and what floats up from a hit come from `FishingView.reward`, so
  `ForageSkin` has no unit of its own: `hint` is handed the limit written out and `pop`
  the bare number a hit is worth. Never write `g[key]`, a `catchLimit` or a quarry's `lb`
  beside a unit's name.
- 1849's skin is four files and a line: `Horn1849Skin` (copy and words), `Horn1849Scene`,
  `Horn1849Chart`, `Horn1849Forage`, and its entry in `Skins.all`. They are the old view
  code moved, not rewritten.

**A new skin must supply** every member above for its `Journey.id`, add itself to
`Skins.all`, and pass `SkinContractTests` unchanged: nothing a player reads is blank for a
fresh voyage or at any stop, for any role; the scene leaves marks for every weather,
moving and stopped, at every stop; the chart and the mini-game draw; `debug.start` gives a
playable state short of every stop. Files are `save-<id>.json` and `topten-<id>.json`
(`JourneyFilesTests`); only 1849 reads the two old unnamed files.

What the contract test can tell about a drawing: with nothing to paint on, `PixelCanvas`
notes each mark, so two drawings can be told apart (`tally.picture`) and the ground one
covers measured (`tally.bounds`). The scene must fill its canvas, draw a different
picture for each sky the journey has and for the worst weather, and a different one in
port; the chart must be more than the shell's dots (a map under them, the marker moving
with the voyage); a throw that lands in the mini-game must add the quarry's worth to the
catch. Every store row must change with its own item and no other. What one journey
cannot show (a second row in the picker, an item stored in tenths, a worst weather that
is not a storm) is tested with the stand-ins in `AroundTheHornTests/TestJourneys.swift`.

**The picker, as built.** Only journeys that have a skin are offered; the journey and its
skin are set together in one place (`GameController.select`), and a state from a journey
not on offer is refused. With several journeys the app opens on the picker, or on the
title card of `-journey <id>`, or failing that of the journey last chosen
(`Persistence.lastJourney`); an id that names nothing on offer is ignored. Every setup
screen then ends with "Back to the title" and both menus with "Save and return to the
title" (`wayBack`, `wayOut`); with one journey none of these rows exist and 1849 is as it
was. The picker's "in progress" marks are read once when it is shown, not while drawing.

**The save from before journeys.** The shipped build wrote save version 1 to `save.json`,
with the weather and each ailment as a name alone. `Horn1849LegacySave` reads it into this
version (`LegacySaveTests` holds a file that build wrote). It is offered on 1849's title
card, moves to `save-horn1849.json` on the next save, and goes when that voyage ends. An
old file this build cannot read is never deleted.

**Screenshots.** `ScreenshotUITests` does nothing unless told where to write:

```sh
SIMCTL_CHILD_HORN_SHOTS="$TMPDIR/shots-<id>" sh Tools/run_tests.sh AroundTheHornUITests ScreenshotUITests
```

Its walk taps 1849's own buttons, so a new journey wants its own walk beside it (same
helper, its own labels). The launch arguments that get it anywhere quickly are
`-journey <id>` (straight to that title card), `-HornDebugStart <stop id>` with
`-HornDebugMonth <n>` (the skin's `debug.start`; add `-HornDebugAtStop YES` to stand at
the stop itself, its arrival already told), and `-HornSceneGallery YES` (every
weather and the skin's extra cells on one screen). The walk is not seeded: crew names,
weather and wear differ from run to run, so compare two runs by eye or by the regions
that cannot move, not by whole-image equality.

**What the shell still assumes** (the engine would have to say otherwise): a leader and
four others, and the three backgrounds of `Role` (`Rules` has no party size and
`Journey.role` answers only for those three); two meters, stored as `hull` and `sails`; money written as a sign before a
number; the mini-game spends `tackle`; a journey has water exactly when its items include
`.water`.

### Rail skin, as built

The Iron Road (`rail`) is the second skin: `RailSkin` (copy, words, debug starts),
`RailScene`, `RailChart`, `RailForage`, and its entry in `Skins.all`. The engine's rules,
numbers and text are untouched, and so is everything 1849 shows.

**What a second skin taught us.**

- The shell needed three more members, each with an answer that leaves 1849 as it was:
  `Words.clock` (a row under the meters for a count the date does not show, here the
  contract; 1849 answers `nil`), `Words.lots` (items the shop prices by the lot,
  "$2/100 gallons", where one alone costs pennies; 1849 answers `[]`) and
  `ForageField.oneWay` (all the quarry crosses the same way, wood on a current; 1849
  answers `false`). Nothing else in the shared views changed. Later, `Words.trouble` (a
  red row under those for a plight the meters don't say: "Train: Broken down", "Out of
  wood", "Last of the wood"; 1849 answers `nil`), decision D14.
- A turn need not be a day. Rail's is four hours, so the skin has one function, `span`,
  that turns a count of turns into "8 hours" or "7 days and 4 hours", and uses it for the
  rest menu, the contract row and the endings. The date with its hour is the engine's.
- The engine's names are only names. `hull` and `sails` are the running gear and the
  engine, `sailcloth` and `timber` are boiler fittings and car spares, the shipwright is
  a boilermaker, and the player never sees the difference. All of it is in `Words` and
  the engine's own item names; no view asks which journey it is.
- A number in a sentence goes stale silently. Every figure the card states (twelve days,
  sixteen, 1,776 miles, 16 cords, 80 gallons, 20 casts, the three purses, the rank
  thresholds, the worst months) is held to the engine's tables by `RailSkinTests`.
  "On time" is the engine's test (a turn in hand), not the skin's own arithmetic.
- The contract test cannot tell one journey's vocabulary from another's.
  `RailSkinTests` walks every string the skin can say and fails on a sailor's word; it
  is shown to bite by running the same sieve over 1849's.
- Two real journeys at once are a different test from one journey and a stand-in:
  each keeps its own save and its own top ten, and an ending in one leaves the other
  under way (the four two-voyage tests in `RailSkinTests`).
- The map and the scene must agree on which way is forward. Rail runs east to west, so
  east is on the right of the map and the train faces left in the scene.
- The simulator keeps the app's files between runs. Uninstall the app before a
  reference walk, or the top ten shows earlier runs and the picker marks journeys the
  walk never started.
- A walk across random country needs patience written down: `RailScreenshotUITests`
  has a list of the answers that cost least and a `roll(until:)` that gives them until
  the screen it wants turns up.

**What the next skin's author should copy.** The four files' layout; `RailSkin.span` if
a turn is not a day; a `<Name>SkinTests` beside `RailSkinTests` (numbers held to the
tables, the vocabulary sieve, a whole run from the title card to an ending); a walk
subclassing `ScreenshotWalk` with its own `journeyArgs`, numbered like
`RailScreenshotUITests`; and a reference set like the 55 in `docs/reference/shots-rail/`:

```sh
SIMCTL_CHILD_HORN_SHOTS="$TMPDIR/shots-rail" sh Tools/run_tests.sh AroundTheHornUITests RailScreenshotUITests
```

Look at every one. A new shell member is the last resort: add it with no default, give
every existing skin the answer that changes nothing, and say so here.

### Airship skin, as built

Over the Pole (`airship`) is the third skin: `AirshipSkin` (copy, words, debug starts),
`AirshipScene`, `AirshipChart`, `AirshipForage`, and its entry in `Skins.all`. 1849 and the
Iron Road look, read and play as they did.

- **Four new shell members**, each with an answer that leaves 1849 and rail as they were:
  - `Words.departRefusal`: why the first port won't let the vessel go beyond the engine's
    own refusal (nothing to eat). The airship answers "empty tanks" when there is no
    petrol aboard, as its spec asked and its engine left to the app (As built 7); 1849
    and rail answer `nil`. `GameController.depart` asks it first.
  - `Words.resumesInFirstShop`: a voyage saved at the first port before it left (the
    stores save as you leave them) comes back to those stores, so it still leaves through
    `depart` and both refusals (decision D15). The airship answers true; 1849 and rail
    false, and come back to the port menu as before.
  - `Words.looseOne`: what one of a loose thing is called, "1 balloon". 1849 and rail
    answer `[:]` and still write "1 throws" and "1 casts".
  - `ForageSkin.grouped`: the tally and the hint write thousands with a comma, "Found:
    1,350 kg", as the airship's catch report does. 1849's prototype wrote "Caught: 1050
    lbs", so 1849 answers false; rail counts in tenths of a cord and answers false.
- **One debug launch argument**, `-HornDebugHull <n>` with `-HornDebugStart`: the vessel's
  structure down to `n`%, so a walk can reach a wreck. Debug builds only; nothing reads it
  otherwise.
- **The engine's text, three changes, no numbers**: the role labels in this journey's own
  words (D11: "A New York financier", "An engineer from the airship works at Rome", "A
  meteorologist trained at Bergen"), and the departure sentence, which put a full stop
  after "a.m." ("On May 1, 1926, 8 a.m., the ... slips the mast at Ciampino.").
- **Two weathers can share a sky.** The following wind and the headwind are both
  `.breeze`, fog and icing fog both `.fog`; the scene tells them apart by the rules' own
  figures (`speed > 1` carries her, `harsh > 0` is the icing), never by a name.
- **At the end the engine leaves her `atPort`** at Nome, which has no mast. The scene asks
  `journey.port(stop)` before drawing a mast (`AirshipScene.moored`); a stop with none is
  drawn as the stop.
- **A curved chart gives its route already projected** (`AirshipChart.route`, with
  `project` the identity), so the marker moves in straight lines on the page through the
  Pole, where longitude means nothing. The chart's Mediterranean coast is crossed at about
  km 510; the scene's sea runs to the Rhône stop at 650.
- **What the scene shows** for every place: the region's ground under nine skies, a mast
  and its town at each of the five masts (moored or not: with its arrival's question on
  screen, or flying on past it, she flies by the mast and the ground crew waits at its
  foot), and every other stop drawn as itself (the
  Rhône's mouth, a line nobody can see at the Circle, Bear Island's cliffs, flags at the
  Pole, the village at Point Barrow, two coasts at Cape Prince of Wales, the roofs of
  Nome). She flies up to ten pixels lower as her lift goes, her fabric creases, her
  propeller stutters and smokes as the engines fail and stops with the tanks dry, icing
  fog rimes her; forced down, she lies on the ice beside a camp where there is sea ice
  below (`pack`, as the engine's ending says), on the sea with a boat alongside, or in a
  field, Scandinavia's included. The sun crosses the side of the sky she isn't in and
  nights are dark, except where and when it does not set: the midnight sun circles low
  when the sun's declination on the day exceeds 90° less her latitude (less 0.83° for
  refraction), the latitude read along the chart's own flight (`AirshipChart.latitude`).
  So never at Oslo, Pulham or Nome; at the Circle a month round midsummer; Vadsø from
  about May 16, Kings Bay from about April 17, the Pole all spring.
- **Places in sentences** come from `AirshipScene.whereabouts`, not the engine's region
  names, which are headings: "above the fog", "over the North Sea", "over France".
- `AirshipSkinTests` holds every figure the card states to the tables, sieves everything
  the skin and the engine can say for a sailor's or a railroader's word, tells every
  weather, region, mast and stop apart, checks the chart and the winds, and flies seeded
  flights from the title card to an ending; `ResumeTests` resumes at the Pole, its
  forecasts, Kings Bay, Point Barrow and Nome.
- **Trouble** (decision D14, docs/journeys/airship.md "Lift and engines at nothing"): the
  airship answers `Words.trouble` with "Airship: Going down", "Engines dead, adrift",
  "Engines dead, tanks dry", "Tanks dry, adrift" (moored, "Tanks dry") or "Last of the
  petrol", from the engine's own `Airship.goingDown` and `Airship.enginesOut`; dead engines
  are drawn and labelled as dry tanks are, drifting. `ResumeTests` resumes a ship going
  down over the Oslo mast.
- `AirshipScreenshotUITests` walks it. Its patience leaves out the masts' "Fly on without
  stopping" and the Circle's "No time for speeches" while rolling toward them (they race
  the button it is waiting for), and its setup test is named to run first, so the title
  card has no voyage to resume on a freshly installed app. It quits in the stores and comes
  back to them, and comes down in a field past the Circle. Its reference set is the 25 in
  `docs/reference/shots-airship/`.

## 3. Adding a journey

1. Spec in `docs/journeys/<id>.md` (the brief's 20-section template, or compact).
2. `HornEngine/Journeys/<Name>/<Name>.swift` (tables, text, rules, hooks) and
   `<Name>+Events.swift`; a data namespace enum; one entry in `Journeys.all`.
3. `HornEngineTests/<Name>Tests.swift`: rules and balance.
4. `AroundTheHorn/Journeys/<Name>Skin.swift` and one entry in the skin list.
5. `xcodegen generate`; `swift test`; the app and UI suites; screenshots of the title,
   the first shop, travelling, a port, the chart and the mini-game.
6. Append "As built" to the spec: what differs from it and the bot's numbers.
