# The Iron Road: 1869

Journey id `rail`. Omaha to Sacramento on the new Pacific Railroad: 1,776 miles with a
chartered freight, a wood-burning engine and five people, a few weeks after the last
spike. Engine files: `HornEngine/Journeys/Rail/`. Tests: `HornEngineTests/RailTests.swift`.

This is the as-built record. Rail was written straight into code as the journey that
proves the shared engine; the numbers below are the ones in `Rail.swift` and
`RailData.swift`, and the tests hold them.

## What it is about

A turn is **four hours**, six to a day. The contract pays best inside **twelve days**
(72 turns) and is torn up at **sixteen** (96 turns), which ends the game.

- **Firewood.** The tender holds 16 cords; timetable speed burns a cord a turn. Wood is
  cheap in Omaha and under the Sierra and dear everywhere between. Every river carries
  driftwood, and the mini-game hauls it out for nothing but grapnel line and four hours.
  Run out and she crawls on fence posts and sagebrush (see "Out of wood").
- **Boiler water.** Three deserts have no water a boiler can use: the Red Desert (136
  miles), the Salt Desert (218 miles) and the Forty-Mile (60 miles). The engine draws
  80, 80 and 100 gallons a turn from the tank car while crossing. Run short and she
  crawls at half speed and scorches her flues.
- **Two grades.** Sherman Hill and the east slope of the Sierra are climbed at 45% speed
  unless the helper engine at Cheyenne ($30) or Reno ($40) is hired.
- **The descent.** At Donner Summit: set the retainers (60% speed, 40% of the brake wear)
  or let her roll (a 25–55% chance the train gets away from you).
- **The season.** Summer deserts are hot; winter mountains freeze and blizzards stop the
  road. December and February departures are much harder.
- **Wear.** The engine and the running gear wear every turn; fittings and car spares mend
  them on the road, a roundhouse does it for money. When either shows 0% the train breaks
  down and stands where she is until she is mended (see "Breakdowns").

## Stock roles

| Engine key | On the Iron Road | Unit, base price |
|---|---|---|
| `fuel` | Firewood, stored in tenths of a cord | cord, $4, tender holds 16 |
| `water` | Tank car, less 60 gal of drinking kegs | 100 gal, $2, holds 1,200 |
| `food` | Provisions | lb, $0.12 |
| `clothes` | Blankets | each, $4 |
| `meds` | Medicine kits | each, $9 |
| `sailcloth` | Boiler fittings (mends `sails` = the engine) | each, $14 |
| `timber` | Car spares (mends `hull` = the running gear) | each, $11 |
| `tackle` | Grapnel line, 20 casts a coil | coil, $2 |

No preventive item (`limes`) is stocked: there is no scurvy on a twelve-day run.

## Roles

| Role | Purse | Mend / patch | Driftwood |
|---|---|---|---|
| Freight contractor from Chicago (×1) | $1,000 | 25 / 20 | 4 cords a session, aim 1.5 |
| Boilermaker from Pittsburgh (×2) | $520 | 40 / 35 | 4 cords, aim 1.5 |
| River hand from St. Louis (×3) | $350 | 25 / 20 | 6 cords, aim 4 |

## Paces and rations

| Pace | Miles a turn | Wood a turn | Engine wear | Health |
|---|---|---|---|---|
| Easy | 32 | 0.7 cord | 1.3 | +0.5 |
| Timetable | 42 | 1 cord | 2.6 | 0 |
| Wide open | 54 | 1.5 cords | 4.4 | −1 |

Rations: Hearty 0.5 lb a head a turn (+1), Lean 0.35 (−0.3), Scraps 0.2 (−2.2).

## The road

Yards (shops, talk, rest, repairs): Omaha 0, North Platte 291, Cheyenne 516, Green River
845, Ogden 1032, Elko 1305, Reno 1620. Set pieces: the Dale Creek trestle at 553 (wait
out a crosswind or risk the cars) and Donner Summit at 1669. End: Sacramento, 1776.

Regions, in order: Platte Valley (river), High Plains, Sherman Hill (grade), Laramie
Plains, Red Desert (dry), the Wasatch (river, slow track), Salt Desert (dry), the Humboldt
(river), Forty-Mile Desert (dry), Truckee Meadows (river), East Slope (grade, river),
Sierra Nevada (descent), Sacramento Valley.

Weather: fair, headwind, heat, rain, thunderstorm, fog, dust, snow, blizzard,
weighted by region and scaled by season.

Departures: June, August, **October (recommended)**, December 1869, February 1870.

## Rules of its own

- The crew's drinking water is the last 60 gallons aboard; the boiler never touches it.
- Beside a river, or in snow, the crew refills the drinking kegs for nothing. Nobody dies
  of thirst next to the Platte. The boiler still needs the tank car.
- Driftwood needs a river that is running: no river, no cast; a frozen river, no cast.
- Three ailments come with the country: sunstroke in heat, a chill on the lungs in cold,
  alkali sickness in the dry regions. Four more can happen anywhere.
- Nineteen road events (hot box, burst flue, bison on the line, a washed-out culvert, the
  express wanting the main, a grass fire, a snowdrift, a tramp, a patent-medicine
  drummer, and so on), seven of them choices. No event harms an animal.
- Score adds 40 points for every turn in hand on the twelve days.

## Breakdowns

When the engine or the running gear shows 0% (a meter under half a point, as the status
box rounds it), the train has given out (`Rail.brokenDown`). She stands where she is: the
turn she would have taken is not taken (no time passes, no number is drawn), and the
status box carries a red row, **Train: Broken down**. Every time the player tries to go
on, the road asks, in red, what to do:

| Option | Offered | What it does |
|---|---|---|
| Work on the engine | the engine at 0% | 1 set of boiler fittings and four hours: the role's mend (25 / 40 / 25) |
| Mend the running gear | the running gear at 0% | 1 crate of car spares and four hours: the role's patch (20 / 35 / 20) |
| Send the fittest hand walking for a mechanic | always; enabled with $45 | $45 and 3–6 turns (twelve hours to a day) laid up; every part at 0% comes back at 40%; the walker loses 4–10 health and comes back ailing 3 times in 10 |
| Climb down and take stock first | always | the menu under way; nothing changes |

The conductor walks when nobody else is left. With no spare for a part that is out and
less than $45, the run ends there: **Stranded at mile N**. A train that gives out standing
in a yard (she gave out on the turn she reached it, or took the main line through) is put
back in the yard for its roundhouse and its store; if she can pay for none of them and
has no spare, she is stranded there too.

Worn-out running gear no longer wrecks the train (`rules.wearWrecks = false`): it is a
breakdown like the engine's. The three violent moments still can put her in the ditch:
the trestle crossed in a crosswind, a culvert crept across, and a runaway off Donner
Summit, when they take the running gear to nothing. A train that has just given out has
no road event that turn. Damage is reported as the status box will show it ("Engine −3%"
when 3% was all there was, never "−13%" at 0%), and a road accident leaves a crew member
at 1 health or more; the next turn's health can still kill.

## Out of wood

A turn begun with less wood than the pace burns runs at a fifth of the speed
(`rules.noFuelSpeed` 0.2: about 7 miles in four hours at timetable speed, instead of 42)
and takes 0.5–1.5 points off the engine for what goes into the firebox. The status box
says **Train: Out of wood** (or **Broken down, no wood**), the note under it says what the
fireman is burning, and the warning when the woodpile goes says "You are barely moving".
The ways out: driftwood wherever there is a river, the next yard's woodpile, the culled
ties beside the track. Burning the last cord is a turn at full speed; only a turn begun
short of wood crawls. Left long enough, the fence posts wear the engine to nothing and she
breaks down as well.

## Balance, as built

`JourneyBot`, 30 seeded runs a role, seed 500, the policy in `RailTests.policy()`: fill
the tank car at every yard, carry two of each spare, fish for driftwood when the tender
runs low, hire a helper only with $100 to spare beyond the fee.

| Departure | Contractor | Boilermaker | River hand | Median winning run |
|---|---|---|---|---|
| June | 30/30 | 25/30 | 11/30 | 74 turns |
| August | 30/30 | 27/30 | 18/30 | 72 turns |
| **October** | **30/30** | **24/30** | **13/30** | **76 turns** |
| December | 30/30 | 7/30 | 1/30 | 77 turns |
| February | 30/30 | 10/30 | 6/30 | 73 turns |

Before breakdowns and the crawl on no wood (D14) the same runs read June 30/26/14, August
30/28/18, October 30/27/15, December 30/12/1 and February 30/13/6. Of the new numbers,
only the crawl moves the table: the mechanic's fee, time and repair made no difference to
the bot in a sweep from $0 to $45, and the speed on no wood was chosen from 0.12, 0.15 and
0.2 as the one that keeps every month nearest where it was.

October is inside the bands (85–100 / 60–90 / 35–70%), and a winning run takes about the
twelve days of the contract, so the bonus is in doubt to the end. Losing runs are spread
across the forfeit, hunger, exhaustion, mountain fever, infected wounds and scalds, and
now and then a train stranded with nothing to mend her.

Things worth knowing:

- No bot run ends in a wreck, because the bot always carries spares. A player who skips
  them breaks down instead, and pays the mechanic or is stranded; the ditch is for the
  trestle, the culvert and the runaway.
- A river hand leaving in December now usually loses in the Salt Desert: the tank car
  runs dry, the boiler scorches the engine to nothing, and there is no money left for a
  mechanic. Before D14 she limped through at 45% speed with a dead engine.
- A river hand leaving in December wins one run in thirty. That is the intent ("leave in
  midwinter and pay for it"), and the title card says so, but it is close to a wall.
- The economy is steep around purse size: a few dollars either way moves the poorer
  roles a long way. Difficulty was tuned with wear and season, not prices.

The tests assert the October bands and median, that December is at least 20 points
harder for the two poorer roles, and that losses end at least three ways.
