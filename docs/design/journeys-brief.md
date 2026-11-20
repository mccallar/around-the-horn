# Journeys — design brief

The owner's ask (2026-11-09): "Come up with variations on the game like rails, blimps, hot air
balloons — plan and build without my input. Do a futuristic trip to another planet, etc."

The app becomes a **collection of journeys**. The title screen offers a choice of
journey; each is a complete game of the same shape as Around the Horn: 1849 — outfit,
travel day by day, keep a crew and a vehicle alive, reach the destination, score.

This brief is the input to every design agent. Read it whole.

## Hard constraints

1. **Around the Horn: 1849 must not change by one bit.** `PrototypeParityTests` (the
   engine replays 16 voyages of the web prototype day by day and must match EXACTLY) and
   `BalanceSimulationTests` (fixed seeds → 30/30, 28/30, 17/30, median 165 days) must stay
   green with identical results after any refactor. Every engine function draws random
   numbers in the prototype's order; a generalisation must preserve that order for 1849.
2. **The engine stays pure Swift** (`HornEngine` framework, Foundation only, no UI
   imports — `PurityTests` reads the source). All randomness through `RandomSource`.
3. **Apple frameworks only**, no third-party code, all persistence local.
4. **Every sentence a player reads is original.** No names, text or art from any
   commercial game or book. Real places, real history and generic nouns are fine
   ("airship", "zeppelin" as a generic word, "Trans-Siberian", "Chilkoot Pass").
   No real company or brand names. Family-friendly: hazards and death exist (as in 1849),
   but no gore, no cruelty to animals as a mechanic, no real-world politics.
5. **Period voice**, plain and a little wry, for each journey's own period. The Mars
   journey's voice is understated near-future, not space-opera.
6. The UI stays the 1849 shell: dark navy, parchment text, pixel fonts, numbered choices,
   a 160×80 pixel scene, a chart, a tap mini-game. Journeys may change the scene's art and
   palette of the scene, the chart's map, the mini-game's skin and all labels — not the
   shell.

## The journeys (IDs are fixed)

| id | Theme | Direction (designers fill in the details) |
|---|---|---|
| `horn1849` | Sea, sailing ship | Existing. New York → San Francisco round Cape Horn. |
| `rail` | Rails | A long private-train expedition in the age of steam (designer chooses: e.g. a Trans-Siberian run c. 1903, or an American transcontinental c. 1870s). Coal and water for the locomotive are the new pressure. |
| `airship` | Blimp / airship | An airship expedition c. 1920s–30s (e.g. an Arctic crossing, or a long-haul pioneering route). Lifting gas, ballast and engine fuel. |
| `balloon` | Hot-air balloon | A long-distance hot-air balloon attempt (e.g. a round-the-world try c. 1990s–2000s, or a great continental crossing). Burner fuel and altitude are the levers. |
| `mars` | Another planet | A crewed transfer from Earth to Mars, late 21st century. Propellant, oxygen, radiation. |
| `klondike` | "etc." — the gold-rush sequel | North to the Klondike, 1897–98: steamer to the coast, over a mountain pass on foot, build a boat at the lakes, run the Yukon to Dawson. A natural sequel to 1849. |

## What the 1849 engine already does (the mechanics a journey can use)

- Crew of five (captain + four), each with hp 0–100, one ailment at a time (damage/day,
  duration, treatable by a medicine kit at half damage), death → burial with an epitaph,
  captain's death → game over.
- Rations (lb/person/day, hp effect) and pace (distance/day, hp effect, wear effect).
- Daily consumption of food and water; running out starves / parches the crew.
- A deficiency disease from going N days without a preventive item (scurvy/citrus).
- Cold regions hurt crew without warm gear (one set per person); hot regions cost extra
  water and hp.
- Two vehicle-condition meters (hull and sails), worn daily by pace × weather, repaired at
  sea with two spare items (one each) or at a yard in port for money. Either meter low
  slows you; the structural meter at 0 ends the game.
- Weather rolled daily from per-region weighted tables, with seasonal adjustments; weather
  sets speed, wear and harshness, and drives the scene's sky.
- Stops by distance: ports (shop with port price multipliers, trade 3×, talk lines, yard,
  rest), marks (a message), special landmarks with a choice (Equator ceremony, Galápagos
  landing), one fork (two routes with different regions; a guide/pilot offer on one), end.
- Random daily events (weighted, conditional on weather/region/stock), including choice
  events (strange sail, albatross, stowaway, icebergs), losses, finds, injuries.
- A tap mini-game (fishing) that turns tackle into food; roles with different start money,
  score multipliers and perks; a score and a top ten.

## New mechanics a journey MAY use (keep them few and general)

- **Fuel**: a stock burned per unit of distance (and/or per day), scaled by pace; empty
  fuel drops speed to a fallback (drift, walking pace) — designers say what.
- Anything else must be argued for in the design: what it adds, why the existing
  mechanics can't express it, and how a balance bot plays it.

## Content template — `docs/journeys/<id>.md` (every section required)

1. **Pitch** — title (e.g. "The Iron Road: 1903"), one-paragraph premise, period, start,
   destination, total distance and its unit (miles, km, versts, million km…), target
   length in days, the "day" (a day is a day unless argued otherwise).
2. **Roles** — three, each: menu label, start money, score multiplier (1/2/3), perk.
3. **Crew** — 28+ original period-appropriate first names; 12+ vehicle names.
4. **Vehicle** — what the two condition meters are called (structural meter whose 0 ends
   the game; propulsion meter that slows you), the scene sprite as a string grid (≤ 32×20
   cells, one character per colour, with the colour table), and what "torn sails" looks
   like for this vehicle.
5. **Supplies** — 8 items (9 with fuel): key, name, unit, step per tap, base price, max,
   one-line description; which item plays each engine role (food, water, deficiency
   preventive, medicine, warmth, repair-structure, repair-propulsion, forage, fuel).
6. **Ports / depots / stations** — 4–6, each: name, shop name, price multiplier, per-item
   modifiers, any disease risk, an arrival paragraph, three talk lines.
7. **Stops** — 10–13 in order by distance, each with type (port, mark, special, fork,
   end), short name, distance.
8. **Regions** — by distance, each with temperature class (cool/warm/hot/cold/freezing),
   flags, and weather weights; seasonal rules (what month ranges change what).
9. **Weather** — up to 10 kinds: display name, speed ×, wear ×, harshness (hp/day), and
   the scene's sky palette (top, bottom, ground/sea, accent) and effects (rain, snow, fog,
   dust, lightning, stars, etc.).
10. **Pace & rations** — three each with numbers.
11. **Ailments** — up to 9: name, damage/day, duration range, the cause-of-death phrase.
12. **Daily rules** — consumption numbers (food/person/day by ration, water/person/day and
    its hot multiplier, preventive use and the deficiency onset day, fuel burn), any
    differences from 1849's rules and why.
13. **Random events** — 14–18, each: weight, condition, effect (numbers), and the exact
    message text. At least four are choice events with options and outcomes (exact text).
14. **Landmarks & fork** — every mark/special stop's text and choices; the fork's two
    routes (regions they swap in), the guide offer and its price, and the advice text.
15. **Mini-game skin** — what you're catching, the targets (name, reward, size, speed,
    weight, colour), the backdrop, the reward item, the per-role cap, and refusals.
16. **Scene & chart** — scene backdrop description (ground/sea/space, horizon, town at a
    port), the chart's map (real-world polylines in lon/lat for Earth journeys, or a
    schematic for Mars), and the route vertices with their distance markers.
17. **Ending & scoring** — finale text, game-over texts, score lines and points, ranks
    (four names, thresholds), ten invented top-ten names and scores.
18. **Balance targets** — role win-rate bands for a sensible bot, median length band, and
    the sensible bot's policy for this journey (as specific as 1849's).
19. **Learn pages** — three short pages of how-to-play text for this journey.
20. **Open questions** — anything the engine can't express yet.

Numbers must be complete enough that an engineer can build the journey without asking.
