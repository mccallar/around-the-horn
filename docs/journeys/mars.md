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
