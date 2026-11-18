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

- **Over the Pole (airship)**: engines at 0% drift as with dry tanks and burn no petrol (a
  new shared hook, `Journey.fuelBurn`, the pace's burn by default); lift at 0% asks what goes
  over the side before she flies on (a bag of ballast, 300 kg of petrol for 10%, or a mast's
  ground crew) and only then forces her down (`wearWrecks` false, `stalled`); the last
  petrol powers its share of a watch; a watch adrift costs 0.5 lift; damage reports what the
  meter had; a red status row. May's bands hold: 100 / 70 / 50% over 600 flights a role
  (docs/journeys/airship.md, "Lift and engines at nothing (D14)").
- **The Jet Stream (balloon)**: burners at 0% give the cone no heat, so she drifts and sinks
  as with dry tanks (40 nm, −5 lift a watch) and burns no propane (`Journey.fuelBurn`); lift
  at 0% asks what goes over the side before she flies on (a sack of ballast, a 50-gallon
  propane cylinder for 10%, or, over a field, its ground team) and only then brings her down
  (`wearWrecks` false, `stalled`), or grounds her at a field she cannot pay at; the last of
  the propane heats its share of a watch and every watch without heat costs its share of
  the 5; damage reports what the meter had; burner trouble needs burners. January's bands
  hold: 100 / 70 / 48% over 180 flights a role; the skin's red row is specified with the
  rest (docs/journeys/balloon.md, "Lift, burners and propane at nothing (D14)").
- **The Long Transfer (mars)**: power & drive at 0% is dark: she coasts as with dry tanks
  (0.28 of a powered day) and burns no propellant (`Journey.fuelBurn`), the recycler stops
  (4 L a head a day, not 2), and before every day in the dark (`stalled`) she is asked: a
  spare panel, rewiring what is left of the wings (always open: two days for 10 points and
  some health), a day's coast, or the menu; the cycler, turnover and the approach wait for
  power; a pressure hull that shows 0% lets go, as the spec has it (`wearWrecks` stays
  true); dry tanks burn their last share (`burnsPartLoad`) and cost a point of power a day;
  wing trouble needs power and a course trim the drive; damage reports what the meter had;
  accidents leave 1 health. October's bands hold: 30 / 22 / 16 of 30, median 155 days (it
  was 30 / 24 / 19); the skin's red row is specified with the rest (docs/journeys/mars.md,
  "Power, the hull and propellant at nothing (D14)").
- **To the Klondike (klondike)**: sleds, and afloat oars & sail, at 0% off the steamer have
  given out, and the party stays where it is (`stalled`) until they are mended: a coil of
  rope & rawhide, a coil bought off the next party along ($24), or two days making do for
  10 points (always open), or the menu; Miles Canyon and Five Fingers wait for a sweep, the
  police at the summit do not; an outfit or a boat that shows 0% is ruined or breaks up, as
  the spec has it (`wearWrecks` stays true), before another day; the steamer carries sleds
  at 0%. There is no vehicle fuel: no firewood still walks, at 12 health a head a day.
  Damage reports what the meter had; accidents already left 1 health. March's bands hold
  untouched: 30 / 24 / 15 of 30, median 119 days, as before; the skin's red row is
  specified with the rest (docs/journeys/klondike.md, "Sleds, oars, the outfit and the boat
  at nothing (D14)").

## D15 — Repairs are offered in the order the condition box lists them (2026-11-15)

The repairs screen showed the hull above the sails (rail: the running gear above the
engine; the airship: lift above the engines), then offered to mend the sails first and
the hull second, as the prototype does. Ryan found it backwards. Every journey's repairs
now come in the box's order, hull-role first, matching the shipyard and the status
panel; rail's breakdown question lists the running gear before the engine for the same
reason. Order only: no repair, cost or number changed.

## D16 — A flight saved before it left Rome comes back to the stores (2026-11-15)

Found in review of the airship skin: the first port's stores save as you leave them,
as the prototype's do, and the app saves whenever it goes to the background,
from the outfitting screen on. Continued, such a save found nothing waiting and opened the
port menu at the first port, whose way out (`startTravel`) never calls `depart`: so the
engine's refusal (no provisions), the airship's own (`Words.departRefusal`, empty tanks) and
the departure sentence were all skipped, and she drifted out of Rome with dry tanks.

The airship now comes back to Rome's stores instead (`Words.resumesInFirstShop`, asked
by `GameController.continueSavedVoyage` of a voyage still at its first port with no turn
taken), so she can only leave through `depart`. Nothing else about the save changes.

1849 and the Iron Road answer false and are exactly as they were: continued before they
left, they come back to the port menu and can set out with no food and no departure
sentence, as 1849's prototype does. That is left to be ruled on, not changed by this
decision; answering true in their skins is the whole change.

## D17 — The balloon's relaunch needs burners, and its date keeps GMT (2026-11-16)

Found in review of the balloon skin. On the ground at a field with the burners at 0%, the
relaunch met no refusal and burned the climb's 25 gallons through burners the rules say
burn nothing (D14); the first watch's note saying so was overwritten by the sinking note,
so the player was never told. Now the climb needs burners, as the Himalaya's and the
icing climb's already did: while the riggers' overhaul is in the purse,
`Balloon.relaunchRefusal` sends her to them (after the lift's refusal, in the condition
box's order, D15); without it she goes up on the helium alone, burning nothing, and the
first watch begins by saying so. Burner kits stay a repair made aloft, so a crew with a
kit fits it on that first watch. No number or random draw changed, and the bot's flights
are as they were.

The status box showed the log's GMT hour as "8 a.m.", which reads as the time where she
is, while the scene darkens by the local sun (at Albuquerque, "8 a.m." over a night sky);
the launch and the finale already wrote the hour as "0800 GMT". The balloon's date is
now "January 8, 1999, 0800 GMT" in the box, the arrivals, the graves and the game-over
footer, through a new engine hook, `Journey.hourText`, whose default ("8 a.m.") rail and
the airship keep. 1849's date has no hour, so the three gates are untouched.

## D18 — Gateway won't clear a ship with her tanks empty (2026-11-16)

Found in building the transfer's skin: the engine lets a freighter leave Gateway Yard with
no propellant at all, and she then coasts the whole way at four tenths of her speed,
tumbling and wearing her array a point a day, which no player means to do and nothing on
the outfitting screen warns of. As the airship's skin does for petrol, the transfer's skin
answers `Words.departRefusal` while the tanks are empty ("Gateway's traffic office won't
clear a ship to leave the yard with her tanks empty"), and `resumesInFirstShop` is true, so
a transfer saved in the chandlery comes back to it and leaves only through `depart` (D16).
Any propellant at all clears her. A ship that runs dry later, or leaves a station dry, still
coasts as the engine says. No engine rule, number or sentence changed, and the bot (which
always buys propellant) is unaffected.

## D19 — Gateway holds a ship only for what her purse can still buy (2026-11-16)

Found in review of the transfer's skin. D18 sent a ship with empty tanks back to Gateway's
chandlery, and the engine sends back a ship with no rations, as every journey's first port
does. The chandlery sells nothing back and its only ways out lead to the departure, so a
captain who had spent the purse below the smallest step of what was missing (an ice
hauler can spend $621.75 of her $625 without a tonne of propellant; five tonnes cost
$3.70) went round the same refusal for good, and with `resumesInFirstShop` (D16) a
relaunch came back to the same chandlery.

Now each refusal holds only while the purse runs to one step of what it asks for, as
the shop bills it (`Mars.gatewaySells`: five tonnes of propellant, $3.70; 25 kg of
rations, $4.50). With less, the traffic office clears her: dry, she coasts; with no
rations, the crew goes hungry; and the departure sentence says which, in place of the
betting pool. Propellant is the skin's refusal (`Words.departRefusal`); rations are the
engine's, so the engine has a new hook, `Journey.departsUnfed`, false by default (every
other journey still refuses a ship with no food, whatever her purse, exactly as before)
and answered by the transfer alone. No number, price or random draw changed, and the bot
(which always buys both) is unaffected.

The airship's petrol refusal at Rome has the same shape (step 100 kg, $1.50) and is left
as it was.

## D20 — A boat at Lake Bennett waits on the ice (2026-11-18)

Found on the Klondike's screenshot walk. The spec (klondike.md §16) draws Bennett before
the boat on the foot leg's snow and, once a boat exists, with "the boat scene and
sprite": river-green water with waves. A party that builds or buys its boat in February
or March then saw it afloat on open water while the engine, and the hold that keeps it
in camp, said the lake was white from shore to shore until the end of May.

Now, at Bennett with a boat and the ice still in (`KlondikeSkin.iceOut`), the boat leg's
water is drawn as ice instead: white, a few grey cracks, no waves, the boat tied to the
bank on it. The sprite, the leg, the words and every rule are the spec's; the day the ice
goes out, the lake is water again and full of sails, as before.

Fishing is unchanged: the spec allows it on the Lindeman and Log Cabin lakes on foot, and
its one backdrop (§15) is a skiff on open water whatever the month.

## D21 — Seattle holds a party only for grub its purse can still buy (2026-11-18)

Found in review of the Klondike's skin, the same shape as D19. The engine sends a party
with no provisions back to the Seattle outfitter, the outfitter buys nothing back, and
`resumesInFirstShop` (D16) brings a relaunch back to the same stores. A miner starts with
$720 and can spend all but $2 on everything else (lime juice, medicine, furs, rope,
canvas and firewood at their limits), below the smallest step of provisions (250 lbs,
$25), and then went round the same refusal for good.

Now the refusal holds only while the purse runs to one step of provisions, as the
outfitter bills it (`Klondike.outfitterSells`). With less, `Klondike.departsUnfed` lets
the party go: the warning before Seattle still says how short it is, and the departure
sentence ends by saying the outfit has no grub and the police at the summit will turn it
back without its year's supply. Their check, which always offers "Turn back for home", is
then an ending, not a loop. No number, price or random draw changed; the storekeeper and
the boatbuilder can't spend that low without grub, and the bot always buys it.
