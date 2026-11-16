# Journey `mars` — The Long Transfer: 2087

A compact specification. It fixes the shape, the names and the starting numbers; the
builder writes every remaining line of player text in the voice described in §1 and tunes
the numbers with `JourneyBot` until §18 holds. Where this and
`docs/design/journeys-architecture.md` disagree about how to build, the architecture
document wins. Section numbers follow the template in `docs/design/journeys-brief.md`.

## 1. Pitch

**Title:** *The Long Transfer: 2087*. Title card `THE LONG` / `TRANSFER`, `~ 2087 ~` under
it. Top bar `THE LONG TRANSFER · 2087`. Subtitle: "2087 · Earth orbit to Mars in a
chartered freighter".

**Premise.** Mars has four thousand people on it and they need everything. Twice a
decade the planets line up and anything that can hold air leaves Earth orbit with cargo.
You have chartered a second-hand transfer freighter, a crew of five counting yourself,
and a contract to deliver to the settlement at Jezero. It is 480 million kilometres along
the transfer arc. Nothing out there wants to kill you. It is only that nothing out there
will help.

| | |
|---|---|
| Period | 2087–88 |
| Start | Gateway Yard, high Earth orbit |
| End | Jezero Landing, Mars |
| Distance | 480 million km, stored as **48,000 units of 10,000 km**. Shown as millions of km with two decimals: 31,245 units reads "312.45 million km". |
| The turn | One day. `tickHours 24`. |
| Target length | A winning run is 140–180 days; the bot's median about 160. |

**Voice.** Understated near-future. Nobody says "space" more than they have to; the crew
talk like people who have done this before and would rather be asleep. Plain sentences, a
little dry. No technobabble: a thing is a pump, a seal, a panel, a tank. No brand names,
no real companies, no real agencies, no real people, no politics. Real places are fine
(the Moon, Phobos, Jezero crater). Hazards and death exist; no gore. Examples of the
register:

- "The recycler has started making a noise. Okonkwo says it has always made that noise.
  Nobody else remembers that noise."
- "Day 61. Earth is a bright star now, with a dimmer one beside it. Somebody has taped a
  note under the window: YOU ARE HERE, with an arrow pointing the wrong way."
- "A pebble the size of a lentil has gone in one side of the cargo bay and out the
  other. It did not stop to apologise."

## 2. Roles

| Role (engine case) | Menu line | Title | Money | Edge |
|---|---|---|---|---|
| `merchant` | "Be a charter captain backed by a freight consortium" | charter captain | 1500 | Money. |
| `shipwright` | "Be a yard rigger who bought the ship she used to fix" | yard rigger | 850 | `mend`/`patch` about 1.6× the others. |
| `whaler` | "Be an ice hauler from the lunar tugs" | ice hauler | 500 | Larger `catchLimit`, better `aim` at the grapple. |

Sums are the charter's ledger units; the learn page says once that a unit is a thousand
dollars and never mentions it again. Score multipliers are the engine's (1×, 2×, 3×).

## 3. Crew

Leader title "Captain". Four named crew, 20 first names from many countries (original
list; no famous astronauts). 12 vessel names in the manner of working ships: *Patient
Margin*, *Second Opinion*, *Late Arrival* and nine more of the builder's own.

## 4. Vehicle

A transfer freighter: a pressure hull, a truss, radiators, two solar wings and an
electric drive.

- `state.hull` = **Pressure hull**. At 0 the ship is lost ("The hull lets go…").
- `state.sails` = **Power & drive** (the wings and the thruster as one meter). Low power
  slows the ship as torn sails do in 1849, and makes the cabin cold (§12).

## 5. Supplies

| ItemKey | Name | Unit | Notes |
|---|---|---|---|
| `food` | Rations | kg | Crew eat by the ration setting. |
| `water` | Water | litres | The recycler returns most of it; the loss is the daily use. Ice caught on the tether tops it up. |
| `limes` | Supplement packs | packs | Prevent the deficiency ailment ("bone loss") after a month without. |
| `meds` | Medical kits | kits | |
| `clothes` | Thermal suits | suits | One each. Matter when the cabin is cold. |
| `sailcloth` | Array panels | panels | Spare for power & drive. |
| `timber` | Hull patches | patches | Spare for the pressure hull. |
| `tackle` | Tether cartridges | cartridges of 20 shots | The grapple mini-game. |
| `fuel` | Propellant | tonnes (store tenths; `per: 10`) | Burned by the drive at every thrust setting. Out of propellant the ship coasts at `noFuelSpeed`. |

Caps so that no outfit carries the whole trip's propellant and water: the two depots
matter.

## 6. Ports

| Stop id | Name | Unit mark | Character |
|---|---|---|---|
| `gateway` | Gateway Yard | 0 | The outfitters. Everything at list price. |
| `cycler` | The Cycler *Perpetua* | 15,500 | A station on a permanent loop between the planets, passing through. Food dear, panels and patches fair, water cheap (it carries ice as shielding). Docking is a choice (§14). |
| `midway` | Midway Depot | 30,000 | Three tanks and a habitat can, staffed by two people who have not seen a third in a year. Propellant cheap, everything else dear. |
| `phobos` | Phobos Yard | 47,300 | Mars's dockyard. Repairs cheap, food cheap (settlement surplus), propellant dear. |

Each port: an arrival paragraph and three or four talk lines that carry real hints (how
much propellant a day's cruise burns, where the ice streams are, when the solar storms
come, what aerobraking does to a tired hull).

## 7. Stops

| id | Name | Type | Unit mark |
|---|---|---|---|
| `gateway` | Gateway Yard | port | 0 |
| `lunar` | Lunar distance | landmark | 38 |
| `hill` | The edge of Earth's reach | landmark | 150 |
| `cycler` | The Cycler *Perpetua* | port | 15,500 |
| `turnover` | Turnover | landmark, set piece | 24,000 |
| `midway` | Midway Depot | port | 30,000 |
| `shadow` | Conjunction shadow | landmark | 38,000 |
| `approach` | Mars approach | fork | 46,000 |
| `phobos` | Phobos Yard | port | 47,300 |
| `jezero` | Jezero Landing | end | 48,000 |

Landmark lines are the builder's, one short paragraph each, in the voice of §1.

## 8. Regions

In their own namespace (`MarsData`). Tags drive the rules; weights are starting points.

| id | Runs to | Tags | Notes |
|---|---|---|---|
| `cislunar` | 150 | traffic | Busy, debris events more likely. |
| `departure` | 8,000 | — | Quiet. |
| `stream1` | 11,000 | ice | A comet's old debris stream: the grapple works; pebble hits likelier. |
| `inner` | 24,000 | — | |
| `deep` | 34,000 | far | Furthest from help. Sun is weaker: power wear matters more. |
| `stream2` | 37,000 | ice | |
| `shadow` | 41,000 | far, quiet | The Sun stands between ship and Earth: no forecasts (storm warnings arrive late or not at all). |
| `approach` | 46,000 | — | |
| `capture` | 48,001 | dust | Mars's neighbourhood; fork variants below. |

## 9. Weather

"Space weather". Each needs a `sky` the scene can use for its palette (the engine's
existing `Sky` cases; pick the nearest).

| Weather | Speed | Wear | Notes |
|---|---|---|---|
| Quiet | 1.0 | low | |
| Good tracking | 1.08 | low | A clean fix from Earth; the burn is trimmed. |
| Solar wind gusts | 1.0 | sails a little | |
| Pebble stream | 0.95 | hull high | `rough`. |
| Radio noise | 0.9 | low | Navigation is cautious. Fog's cousin. |
| Proton storm | 0.8 | sails high | `harsh`, `rough`; the crew are worn down unless sheltered. |
| Mass ejection | 0.6 | both high | The gale. Rare; commoner late in the calendar (§10 departures). |

`weatherWeights` scales the storm weights with the calendar: the Sun is building to a
maximum in early 2088, so storms are about 0.6× in August 2087 and rise to about 1.6× by
May 2088.

## 10. Thrust, rations, departure

| Pace (engine case) | Name | Speed/day | Propellant/day | Wear | Crew |
|---|---|---|---|---|---|
| `easy` | Economy burn | 250 | 0.7 t | low | +0.5 hp |
| `steady` | Cruise | 300 | 1.0 t | normal | 0 |
| `full` | Hard burn | 350 | 1.6 t | high | −1 hp (noise, heat, no sleep) |

Rations: Full / Lean / Short, as 1849's three.

**Departure** is the launch date inside the 2087 window: 12 Aug, 9 Sep, 7 Oct, 4 Nov,
2 Dec. The geometry is best on 7 Oct (recommended). `adjustSpeed` applies the window:
Aug ×0.86, Sep ×0.94, Oct ×1.0, Nov ×0.94, Dec ×0.86. So early is slow but calm and late
is slow and stormy; the middle is the sensible choice and the advice says so.

## 11. Ailments

Radiation sickness (after storms unsheltered), decompression injury, bad air (a scrubber
fault), a fracture (weakened bones; commoner when the deficiency counter is high), low
spirits, infection, a burn. Deficiency: "bone loss", prevented by supplement packs.
Burial wording belongs to the skin: the crew gathers at the lock; no description beyond
that.

## 12. Daily rules

- Water: 2 L a head a day is lost for good; 3 when the cabin is hot (never, here) — set
  `hotWater` equal to `water`.
- **Cabin temperature follows the power meter.** `temperature` returns `.freezing` when
  power & drive is under 20, `.cold` under 40, otherwise mild. Thermal suits protect as
  woolens do. This is the journey's main coupling: neglect the wings and the crew
  suffers.
- In `far` regions power wear is 1.3×.
- The grapple (§15) works only in `ice` regions; elsewhere `forageRefusal` says there is
  nothing out there to catch.
- No rain catch.
- A deadline: the contract pays a bonus for every day under 170 (`score` adds a line as
  rail's does) and nothing is forfeit; a late ship is merely late.

## 13. Events

About one day in six. At least 22, original, in four groups. Starting list:

*The ship:* pebble puncture (hull); a wing actuator sticks (power); coolant leak (power,
maybe a burn); scrubber fault (bad air); recycler fouling (water lost); galley freezer
fails (food lost); a navigation update that will not install (a day lost); thruster grid
erosion at hard burn (power).

*Choices:* **flare warning** (shelter in the core for a day, or work on: chance of
radiation sickness for one or two); **a drifting cargo pod** (match and take it:
propellant cost, a random useful find, small chance it is empty; or leave it);
**a ship in trouble** asking for water or a hull patch (give: lose the item, gain a
grateful message and a little money wired later; decline: nothing, and the crew are quiet
at supper); **a hitch-hiker** at a depot's edge, a technician bound for the next port
(the stowaway pattern: one more pair of hands and one more mouth, leaves at the next
port); **a pedlar's drone** selling one overpriced medical kit; **a hull creak** (inspect
now: a day and a patch; or note it in the log: chance of a worse breach).

*Luck:* a supply cache left at a marker buoy; a perfect tracking fix (distance gained);
an unexpected ice chunk on the truss (water); a message home gets through (hp).

*Sights:* Earth and Moon as a double star; the first disc of Mars; a comet's tail; the
Milky Way with the cabin lights off; a birthday. Each +2 hp.

No cruelty, nothing gory, nobody named after a real person.

## 14. Set pieces and the fork

- **The Cycler** (`arrive` hook, as rail's helper offer): matching orbits to dock costs
  propellant (start at 6 t). "Match and dock" / "Wave as she goes by". Declining skips
  the port entirely.
- **Turnover.** Halfway, the ship turns end for end and thrusts the other way. "Turn on
  schedule" (nothing happens, and that is the point) / "Run on four more days and brake
  hard" (gain distance worth about four days; propellant −8 t; 30% the drive takes
  damage; worse at low power).
- **Mars approach, the fork.** *Aerobrake*: dip into the atmosphere to shed speed.
  Shorter and costs no propellant, but the hull takes a beating (a few rough days of high
  hull wear; a tired hull may fail), the Strait of Magellan of this journey.
  *Propulsive capture*: burn into orbit. Safe for the hull; costs propellant (about
  10 t) and is two or three days longer. Short of propellant, the burn is partial and the
  approach drags on at coasting speed.

## 15. Mini-game — "The grapple"

`forageReward = .water`. The shooter is at the bottom centre on the truss; ice chunks
drift across above in three lanes; a tap fires a tethered grapple at the tap's bearing.
Quarry in five sizes (litres): grit 4, cobble 9, boulder 18, berg 35 and, rarely, a lost
water bladder 60. 25 seconds. The ice hauler's `catchLimit` and `aim` are the better ones.
Heading "The grapple"; tally "Shots / Caught (L) / Time".

## 16. Scene and chart

Scene (160×80): a black sky with fixed stars, the freighter in profile mid-frame (hull
cans, a truss, two wings that lose panels as power falls, a faint drive glow when
moving, scaled by pace), and the Sun small at one edge. Earth shrinks behind over the
first weeks; Mars grows ahead over the last. Weather shows as what it is: streaks for a
pebble stream, a pale wash for proton storms, a bright front for a mass ejection, static
flecks for radio noise. In port, the station's structure stands beside the ship.

Chart: the Sun at centre, the orbits of Earth and Mars as dotted circles, the transfer
arc from one to the other as the route, stops marked along it, the cycler's loop faintly.
Legend in millions of km.

## 17. Ending and scoring

Arrival text for Jezero; the default score lines plus "Days in hand on the contract"
(days under 170 × a bonus). Ranks: "Master of Transfer", "Deep-space Hand", "Orbit Hand",
"Groundling" (cut-offs set after the bot's score spread is known).

## 18. Balance targets

With `JourneyBot` on the recommended launch date: charter captain 85–100%, yard rigger
60–90%, ice hauler 35–70%; median winning run 140–180 days; losses a spread (hull,
hunger, thirst, sickness, cold), not one cause; August and December launches measurably
harder than October for the two poorer roles.

## 19. Learn pages

Three: "The transfer" (what the trip is; a unit of money is a thousand dollars),
"Supplies" (what each thing is for; propellant and water are the two that run out),
"Turnover and capture" (the two decisions, and why the launch date matters).

## 20. Open questions

None the engine cannot express: every rule above maps onto a hook rail already uses
(`adjustSpeed`, `structureDamage`, `tick`, `temperature`, `weatherWeights`, `arrive`,
`special`, `resolve`, `forageRefusal`, `score`).

## As built

Engine files: `HornEngine/Journeys/Mars/` (`Mars.swift` rules, sentences and hooks,
`MarsData.swift` tables, `Mars+Ports.swift` the four stations and the cycler's offer,
`Mars+Events.swift` the 23 events, `Mars+Choices.swift` turnover, capture and every
answer, `Mars+Trouble.swift` the array dark, the hull at 0% and the tanks dry, D14), one
entry in `Journeys.all`. Tests: `HornEngineTests/MarsTests.swift` (30 rule tests, 4 balance
tests) and `HornEngineTests/MarsBreakdownTests.swift` (18, D14); `JourneyContractTests` runs over it with no special case. The
title card, setup and outfit copy, learn pages, burial wording, status labels, scene,
chart and the grapple's drawing (§1's card, §15's canvas, §16, §19) belong to the skin,
which is not built yet. No shared engine code changed. The test bot `JourneyBot` gained
one knob, `stockFactorHere` (off by default), described below.

### The numbers as shipped

**Roles.** Charter captain $1,500, mend 25 / patch 20, catch 60 L, aim 1.5. Yard rigger
$850, mend 40 / patch 32. **Ice hauler $625** (spec $500), mend 25 / patch 20, catch
100 L, aim 4. Score × 1 / 2 / 3.

**Paces** (per day): Economy burn 310 units, 0.7 t, wear 1.2, +0.5 hp; **Cruise 370**,
1.0 t, wear 2, 0; Hard burn 430, 1.6 t, wear 3.4, −1 hp. Rations: Full 0.8 kg a head
(+1), Lean 0.55 (−0.3), Short 0.35 (−2.2).

**Stock** (Gateway price per bought unit, most aboard):

| Key | Name | Unit | Price | Max |
|---|---|---|---|---|
| `food` | Rations | kg (step 25) | 0.18 | 450 |
| `water` | Water | litres (step 50) | 0.23 | 800 |
| `fuel` | Propellant | tonnes, stored in tenths (step 5) | 0.74 | 100 |
| `limes` | Supplement packs | packs | 2.3 | 20 |
| `meds` | Medical kits | kits | 9 | 8 |
| `clothes` | Thermal suits | suits | 5.5 | 10 |
| `sailcloth` | Array panels | panels | 13 | 8 |
| `timber` | Hull patches | patches | 11 | 8 |
| `tackle` | Tether cartridges | 20 shots | 2.75 | 10 |

**Stations** (multiplier; item mods): Gateway 1; the cycler *Perpetua* 1.1 (rations 1.6,
water 0.4); Midway 1.4 (propellant 0.4); Phobos 0.8 (rations 0.7, propellant 2.2, water
1.2). Yards cost 1.2 a point of hull and 1.0 a point of power × the multiplier, so Phobos
is the cheapest yard and Midway the dearest.

**Rules** (`Rules`): turn 24 h from the 7th of the launch month; speed × (0.7 + 0.3 ×
power) and the hull never slows the ship (`hullFloor 1`, `hullSpan 0`); no propellant ×
0.4, the last of it driving its share of the day (`burnsPartLoad`, D14); water 2 L a head a day, hot or not; a month (30 days) without supplement packs
before bone loss can start; hull creep 0.05 a day; below 35 hull the freezer can spoil
10–30 kg; one event on 17% of days; trades wanted at $20 of a good or $40 cash, worth
$15–45; rank cuts 8,000 / 5,000 / 2,500. Everything else is the shared default.

**Space weather** (speed, power wear, crew harm a day, hull hit up to): Quiet 1, 0.3;
Good tracking 1.08, 0.25; Solar wind gusts 1, 0.7; Pebble stream 0.95, 0.4, hull 5;
Radio noise 0.9, 0.3; Proton storm 0.8, 1.4, 1.5 hp, hull 1; Mass ejection 0.6, 1.8, 2
hp, hull 4. A hull hit is × 1.5 at a hard burn and × 0.7 at economy. Proton storms and
mass ejections are × (0.6 + months since 1 August 2087 ÷ 9), held between 0.6 and 1.6.
Skies: clear, still, breeze, dust, fog, storm, gale.

**The arc.** Regions and stops as §7–§8, with the shadow landmark at 37,000 and the
approach and capture tagged `far` (departures 12 and 13). Power wears 1.3× in `far`
regions, everything past 240 million km: deep space, the second ice stream, the shadow,
the approach and the capture. The shadow has no Good tracking weather and nothing from
Earth: no flare warning, tracking fix, navigation update or mail from home. Earth and the
Moon show as a double star only between 30 and 240 million km.

**Set pieces.** The cycler: dock for 6 t (disabled under 6 t) and you are aboard with her shop
open, with no second offer to dock; wave
and she is not a port at all. Turnover: on schedule, nothing; run on (8 t, disabled
under 8 t) gains 1,400 units, four days at cruise, with a 30% chance (50% under 50%
power) of 10–20 points off power. Approach: aerobrake (speed × 1.5 and 4–10 hull a day
until Phobos, then nothing) or burn into orbit (10 t, speed × 0.75 until Phobos); short
of 10 t the burn takes what is left and the ship coasts on the shared no-propellant rule.

**Ailments.** Anywhere: bad air (2 a day, 3–6 days), low spirits (1, 5–10), an infection
(3, 6–12), a fracture (1.2, 12–20; a second chance in the pool after 15 days without
supplements). Under way in a proton storm or mass ejection, radiation sickness (4, 6–12)
twice in the pool; in a cold or freezing cabin, hypothermia (3, 4–8) twice. Events give
decompression injuries (2.5, 4–8), burns (1.5, 10–18), bad air and radiation sickness.
Bone loss does 2 a day until supplements or a port cure it.

**Contract.** A score line of 25 points a day under 170; a message on day 170; nothing
forfeit.

### The bot, by departure

`JourneyBot` with `MarsTests.policy()`: shop each leg for the run at three quarters of
cruise speed (times the window's factor) plus ten days, a fifth extra propellant; two
each of kits, panels and patches; supplies first, then the yard below 70%; mend under
45%. The ice hauler eats lean, carries 80 tether shots, buys water only half-way when an
ice stream lies before the next station (at Gateway and Midway), and grapples whenever
the tanks have room in an ice stream (hit 55%); the others carry 40 shots and grapple
only below 25 days of water (hit 35%). It docks with the cycler, shelters from flares,
runs on at turnover when it holds 8 t plus a fifth over what reaching Midway needs,
aerobrakes on a hull of 60% or better and burns into orbit below it.

Thirty runs a role from seed 500 (what the tests assert), then 90 a role over seeds 500,
1999 and 50000:

| Launch | Charter captain | Yard rigger | Ice hauler | Median winning run |
|---|---|---|---|---|
| 7 August 2087 | 30/30 · 88/90 | 1/30 · 15/90 | 1/30 · 6/90 | 180 days |
| 7 September | 28/30 · 88/90 | 14/30 · 46/90 | 9/30 · 19/90 | 163–164 |
| **7 October (tested)** | **30/30 · 89/90** | **22/30 · 63/90** | **16/30 · 52/90** | **155** |
| 7 November | 30/30 · 90/90 | 10/30 · 38/90 | 10/30 · 23/90 | 165–166 |
| 7 December | 29/30 · 88/90 | 0/30 · 5/90 | 1/30 · 1/90 | 181 |

These are after D14 (power, the hull and propellant at nothing, below). Before it the
October row was 30/30 · 89/90, 24/30 · 67/90, 19/30 · 58/90, and September's ice hauler
won 29 of 90: the poorer roles' arrays run down late in the trip, and a dead array no
longer drives the ship at 70%.

October median scores: charter captain 3,353 (Orbit Hand), yard rigger 6,272 (Deep-space
Hand), ice hauler 7,920 (Deep-space Hand). How October's 90 a role are lost: thirst 28,
bone loss 13, a fracture 10, infection 5, hypothermia 3, bad air 2, hunger 2, a long
decline 2, and a decompression injury.

Choices and play, October, 60 runs a role (seeds 500 and 1999; captain / rigger /
hauler, median):

| Played as | Wins | Median |
|---|---|---|
| the bot | 60 / 41 / 35 | 155 |
| always aerobrake | 60 / 44 / 40 (5 hulls lost) | 154 |
| always burn into orbit | 60 / 40 / 32 | 156 |
| never run on at turnover | 60 / 38 / 34 | 159 |
| work through every flare | 60 / 47 / 35 (1 hull lost) | 153 |
| hard burn all the way | 59 / 39 / 6 | 139 |
| economy burn all the way | 59 / 24 / 22 | 181 |
| full rations for the ice hauler | 60 / 41 / 12 | 154 |
| no grapple | 60 / 46 / 0 | 153 |
| wave the cycler by | 0 / 0 / 0 | — |

The tests assert the October bands (85–100 / 60–90 / 35–70%) and a median winning run of
140–180 days; that August and December are each at least 20 points harder for the two
poorer roles and at least 10 days longer; that an ice hauler without the grapple wins at
least 30 points less, and on a hard burn at least 20 points less and faster; and that
the two poorer roles' losses end at least three ways.

### Departures from the spec, and why

1. **Launch dates.** The engine has one start day per journey (`Rules.startDay`), so all
   five launches are on the 7th: 7 August, 7 September, 7 October, 7 November,
   7 December, not 12 Aug / 9 Sep / 7 Oct / 4 Nov / 2 Dec. October is unchanged; the
   others move by at most five days, which the storm calendar barely notices. The skin's
   departure screen must use these dates. The window factors are §10's (0.86 / 0.94 /
   1 / 0.94 / 0.86), keyed on the launch month.
2. **Pace speeds** 310 / 370 / 430 units a day, not 250 / 300 / 350. At §10's speeds the
   bot's median winning run was 194 days, past §1's 140–180: power wear, space weather
   and station days take about a sixth off the table speed. Propellant per day is §10's,
   so a kilometre at a hard burn still costs more propellant than at cruise.
3. **Power slows the ship less, and the hull not at all**: speed × (0.7 + 0.3 × power),
   not 1849's 0.45 + 0.55 and 0.75 + 0.25 for the hull. A leaking cabin does not slow a
   ship in vacuum; low power still does (and chills the crew, §12).
4. **The ice hauler's purse is $625, not $500.** The economy is a cliff: a role whose
   purse covers the legs nearly always arrives, and one a little short dies of thirst.
   With §2's $850 and $500 no price level put both poorer roles in their bands (at the
   level where the yard rigger fell under 90%, the ice hauler won 0–5%). Prices were cut
   until the rigger sat mid-band at $850, and the hauler's purse raised until it did too.
   During tuning (seeds 500 and 1999, prices within a few percent of these) the hauler won
   about 37% at $600 and 72% at $650.
5. **Water is the dear good**, at 0.23 a litre (the cycler sells it at 0.10): the ice
   hauler's grapple is what makes her trip affordable. Only she grapples whenever there
   is room.
6. **Hypothermia** is added: a cold or freezing cabin puts it in the sickness pool, so
   §18's "cold" is a cause of death of its own and not only "exhaustion".
7. **Turnover gains 1,400 units**, four days at the new cruise speed, not 1,200.
8. **Aerobraking and capture** as above: §14 gave the shape but no numbers. The capture
   region's `dust` tag is kept for the skin but no rule reads it.
9. **The hitch-hiker** is offered only within 1,500 units (15 million km) after Gateway
   or Midway, and only if you went aboard there, and is always bound for Midway or
   Phobos, never the cycler, which the player may wave by. A survey ship in trouble
   calls only while a station lies ahead, and her grateful transfer ($15–30) is paid when
   you reach that station, whether you dock or keep going.
10. **Money** reads "$" in engine text, as the shop shows it; §2's thousand-dollar unit is
    the learn page's business.
11. **The spec's sample lines** are used where they fit (the recycler, the window note, the
    lentil), with the recycler's crew member left unnamed.
12. **The shadow landmark is at 37,000**, not §7's 38,000: that is where §8's shadow
    region, and the silence from Earth, begin, and where Midway's keeper says it starts.
13. **The approach and the capture are `far` too.** §8 tags only deep space and the
    shadow, but the transfer arc only gets further from the Sun until Mars, and the
    cycler's engineer says the wings wear faster past 240 million km. The bot's October
    results stayed in their bands.
14. **The role lines** read "A charter captain backed by a freight consortium", "A yard
    rigger who bought the ship she used to fix" and "An ice hauler off the lunar tugs",
    not §2's "Be a …" (D11: no journey's roles are offered in that shape). Text only.

### Power, the hull and propellant at nothing (D14)

Reported from play on the Iron Road ("you can go below 0 for the health of the train ... I
ran out of cord and it seemed to be still moving just fine"), and checked here
(`HornEngineTests/MarsBreakdownTests.swift`). Before this nothing showed "-0" and the
meters were never stored below 0, but:

- power & drive at 0% drove the ship at 70% of her speed (the power floor, `propFloor`
  0.7) on a full day's propellant, with only the cold cabin to show for it; the bot's
  poorer roles flew like that for days at a time;
- a pressure hull under half a point showed 0% and flew on: the shared wreck waits for
  nothing at all;
- the damage reports gave the event's whole number past what the meter had ("Power &
  drive −9%" with 3% left, "Pressure hull −12%" from 4%);
- three accidents (the pebble's decompression, the coolant line's burn, working through a
  flare) took 6, 5 or 8 health with no floor, so a crew member could stand at −5 until the
  next day buried them;
- the last of the propellant, less than a day's burn, was thrown away for nothing, and a
  dry ship coasted at 0.4 with nothing else to pay and nothing on the status panel;
- with power at 0% a good tracking fix still trimmed up to 3 million km off the arc.

The rules now (`Mars+Trouble.swift`):

- **A meter that shows 0% has given out**, as the status panel rounds it (`jsRound`), as on
  the other journeys. Every hull and power loss goes through `knock`: never past nought,
  and the red note gives the drop the panel will show, or nothing when it shows none.
- **The pressure hull at 0% lets go**, as §4 has always had it, and the run ends ("The
  hull of the *Fair Copy* lets go.", or the aerobrake's ending in the Martian sky). The
  wreck now comes at a shown 0%, not only at nothing: a day's wear or an event that would
  leave less than half a point takes the rest, and a save standing at 0% lets go before
  another day. There is no way out to offer: nobody out there can help, and patches go on
  from the stores long before. `rules.wearWrecks` stays true.
- **Power & drive at 0% is dark.** The drive has nothing to run on, so she coasts along the
  arc as she does with the tanks dry (the shared `noFuelSpeed`, 0.4, on top of the power
  floor's 0.7: 0.28 of a day at full power) and burns no propellant (`Journey.fuelBurn`
  answers 0). The recycler stops, so the water lost each day is 4 litres a head, not 2
  (`waterNeed`; docked, the station's recycler does the work). The cabin is freezing, as
  under 20%. Before every day in the dark (`Journey.stalled`) she is asked: "[red]The array
  has gone dark.[/red] The drive is dead, the recycler has stopped and the cabin is getting
  colder by the hour. The *Fair Copy* coasts on along the arc at the speed she had, which
  is not much." The offers:

  - "Fit a spare array panel (have n)": the repair, +25 (the yard rigger +40), a day.
  - "Rewire what is left of the wings: two days in suits", always open. The two fittest
    hands go out (the captain makes up two, or goes alone); two days pass in the dark;
    power comes back by 10 points; each who went out loses 3 to 8 health (never below 1)
    and has a 15% chance of a decompression injury. Ten points run the drive and the
    recycler but not the heating: the cabin is freezing until 20.
  - "Coast on in the dark for a day": that day is a coast, and the next is asked about
    again (`mars.coast` holds the day chosen for, so a rest in between asks again).
  - "Take stock first": the menu under way.

  The rewire is always open and a coast always makes way, so there is no softlock. Wing
  trouble (the actuator, the coolant line) needs power; the thruster grid and a course
  trimmed on a good tracking fix need the drive running (power and propellant); the pod
  cannot be matched in the dark.
- **A set piece that needs the drive waits for power.** Reaching the cycler, turnover or
  the Mars approach dark (on the day the array went, or on a day's coast), it is held
  (`mars.held`): "The *Fair Copy* reaches Turnover with her array dark. Turnover is due,
  and nobody turns a ship end for end without a drive." (the cycler: "The Perpetua is
  holding her docking window open, and there is no meeting her without a drive."; the
  approach: "Mars is coming up, and nobody meets a planet without a drive."). The dark
  question is then asked without the coast, and the set piece comes, taking no time, once
  there is power. The cycler still pays what a grateful ship wired on arrival. Midway and
  Phobos take a dark ship in as usual: they have tugs.
- **Dry tanks**: she coasts at the shared 0.4, and the last of the propellant now drives its
  share of the day (`rules.burnsPartLoad`: 0.4 t of cruise's tonne makes 0.64 of a powered
  day). With nothing for the thrusters that keep her pointed she tumbles, and power & drive
  loses 1 point a day dry (`tumbleWear`, for the dry share of a day), so a long coast ends
  with the array dark as well. The warning says so: "[red]The propellant tanks are
  dry.[/red] The drive coughs once and goes quiet, and so do the thrusters that keep her
  pointed. She coasts on along the arc at the speed she had, turning slowly, and the wings
  wear themselves out chasing the Sun." Dry tanks alone ask nothing: she is coasting, not
  stuck, and a station's propellant is the cure.
- **The travel note** says so, unless the weather has a note of its own: "The array is dark.
  She is coasting.", "The tanks are dry. She is coasting.", "The drive sputters out partway
  through the day. She is coasting."
- **Crew health**: accidents leave a crew member at 1 health at least (`hurt`); what kills
  is the day that follows, as the shared rules count it.

**What the skin must show** (none is built yet; the airship's is the model):

- the red status row, `Words.trouble` = ("Ship", …): "Array dark, tanks dry"; "Array dark,
  coasting" under way and "Array dark" docked (`Mars.dark`); "Tanks dry, coasting" under
  way and "Tanks dry" docked; "Last of the propellant" (`Mars.lastOfThePropellant`: less
  than a day at this burn); nothing before she leaves Gateway. The hull needs no row: at 0%
  the run is over.
- the supplies note adds "the array is dark" and "the tanks are dry";
- the scene draws a dark array as wings with every panel dark (§16 already drops panels as
  power falls) and a coasting ship (`Mars.coasting`) with no drive glow, whatever the pace;
- the learn pages ("Supplies", "Turnover and capture") say what a dark array and dry tanks
  do, that a rewire is always there, and that the cycler, turnover and the capture wait for
  power.

Tuning: none was needed. The bands hold untouched: October 30 / 22 / 16 of 30 (it was
30 / 24 / 19), median 155 days, and the tables above are after D14. With the tumble taken
out the October row would be 30 / 24 / 17 of 30 (89 / 66 / 54 of 90): the dark array is
most of what moved.

### Things worth knowing

- Waving the cycler by is a trap unless planned for: the next station is 145 million km
  on, past what the water tanks (80 days) and the propellant tanks (100 t) hold without
  the first ice stream. The bot, which shops one leg at a time, never survives it.
- August and December are close to a wall for the two poorer roles (a rigger wins one
  launch in six or fewer, a hauler one in twelve or fewer) while the charter captain barely
  notices. That is §10's "early is slow, late is slow and stormy", and the advice says
  so, but it is steep.
- Thirst is the commonest death: a slow leg, a station short of money, and water at 0.23
  a litre. A player who watches the tanks and grapples in the streams avoids most of it.
- Sheltering from a flare and working through it come out about even for the bot: a
  day's rations and water against a 75% chance of radiation sickness for one or two.
- Losing the ship is rare for the bot: three runs in 1,350, and five in 180 when it
  aerobrakes whatever the hull.
- The poorer roles' arrays run down: in October 19 of the yard rigger's 90 runs and 42 of
  the ice hauler's go dark at least once (29 and 84 rewirings), and 32 and 37 run the
  tanks dry; the charter captain, who can pay the yards, never does.
- On a coast (tanks dry or the array dark) the thrust setting still counts in the shared
  rules: a hard burn coasts at 430 × 0.4 a day and still wears the drive and the crew as
  a hard burn does. Nothing in the game says so; the bot never coasts long enough for it to
  matter.
