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
  them on the road, a roundhouse does it for money.

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

Rations: Filling 0.5 lb a head a turn (+1), Meager 0.35 (−0.3), Bare bones 0.2 (−2.2).

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

## Balance, as built

`JourneyBot`, 30 seeded runs a role, seed 500, the policy in `RailTests.policy()`: fill
the tank car at every yard, carry two of each spare, fish for driftwood when the tender
runs low, hire a helper only with $100 to spare beyond the fee.

| Departure | Contractor | Boilermaker | River hand | Median winning run |
|---|---|---|---|---|
| June | 30/30 | 26/30 | 14/30 | 74 turns |
| August | 30/30 | 28/30 | 18/30 | 73 turns |
| **October** | **30/30** | **27/30** | **15/30** | **75 turns** |
| December | 30/30 | 12/30 | 1/30 | 77 turns |
| February | 30/30 | 13/30 | 6/30 | 74 turns |

October is inside the bands (85–100 / 60–90 / 35–70%), and a winning run takes about the
twelve days of the contract, so the bonus is in doubt to the end. Losing runs are spread
across the forfeit, hunger, exhaustion, mountain fever and infected wounds and scalds.

Things worth knowing:

- No bot run ends in a wreck, because the bot always carries spares. A player who skips
  them can put the train in the ditch.
- A river hand leaving in December wins one run in thirty. That is the intent ("leave in
  midwinter and pay for it"), and the title card says so, but it is close to a wall.
- The economy is steep around purse size: a few dollars either way moves the poorer
  roles a long way. Difficulty was tuned with wear and season, not prices.

The tests assert the October bands and median, that December is at least 20 points
harder for the two poorer roles, and that losses end at least three ways.
