# Journey `balloon` — The Jet Stream: 1999

Content specification for the hot-air (Rozière) balloon journey, written to the template
in `docs/design/journeys-brief.md`. Every number and every line a player reads is here.
Markup in quoted text is the engine's (`[red]…[/red]`, `[green]`, `[amber]`, `[dim]`,
`[i]`). `NAME`, `SHIP`, `DATE`, `N` etc. are substitutions; player-entered names go through
`TextMarkup.escape` as in 1849.

Engine-role mapping used throughout (1849 slot → this journey):

| 1849 | Balloon | Engine role |
|---|---|---|
| provisions (lb) | rations (lb) | food |
| fresh water (gal) | drinking water (gal) | water |
| citrus (crates) | CO2 scrubbers (canisters) | deficiency preventive |
| medicine | medical kits | medicine |
| oilskins & woolens | down suits | warmth |
| spare timber → hull | ballast → **Lift** | repair-structure |
| spare sailcloth → sails | burner spares → **Burners** | repair-propulsion |
| fishing tackle | fishing line | forage (mini-game) |
| — | propane (gal) | fuel |
| a day | a **watch** (4 hours) | one tick |

---

## 1. Pitch

**Title:** *The Jet Stream: 1999*. Top bar: `THE JET STREAM · 1999`. Journey-picker card:
"Round the world by balloon, riding the winter jet stream." Title screen line under the
title: "Eighteen thousand miles round the world, by balloon."

**Premise.** It is the winter of 1998–99, and nobody has yet flown a balloon around the
world. Teams have been trying for twenty years; many of them ended in the sea. Your sponsors
have built you a Rozière — a helium cell riding on a cone of hot air — with a sealed
capsule for five, and they don't care about record books: they want you home. You launch
from the desert outside Marrakech, climb into the subtropical jet stream and ride it east —
across the Sahara, Arabia, India, past the Himalaya, over China, across the whole Pacific
in one jump, over America and the Atlantic — until you cross the meridian of Marrakech
again from the west. Five landing fields along the way have a ground team waiting with
propane, helium and supplies. Every landing costs time and propane; between them you are
on your own. Propane is the clock: a balloon burns it every watch whether it is going
anywhere or not.

- **Period:** November 1998 – April 1999.
- **Start:** the launch field outside Marrakech, Morocco (31.6° N, 8.0° W).
- **Destination:** the finish line — the meridian of Marrakech, 8° W, crossed from the
  west — and a landing on the plain outside the city.
- **Total distance:** **18,300 nautical miles** (nm), eastbound. Both Pacific tracks are
  marked with the same distances; the southern track is really about 770 nm longer
  (6,430 nm against 5,670 from the fork to Albuquerque; over the ocean alone, 5,890 against
  the marked 4,800), which the journey expresses as slower winds (§8).
- **Target length:** a sensible flight takes **145–180 watches (24–30 days)**, landings
  included. (The real first nonstop circumnavigation, in March 1999, took 19 days 21 hours;
  a player who flies high and lands little can approach that.)
- **The "day": a watch of four hours.** Six watches make a day. Argued in §12.1: a real
  attempt lasts about three weeks, so one-day ticks would make a 20-tick game.

**Historical facts relied on** (checked with web search, 2026-11-09, unless marked):

| Fact | Status |
|---|---|
| First nonstop balloon circumnavigation: Rozière launched from Château-d'Oex, Switzerland, 1 March 1999; finish line 9°27′ W over Mauritania on 20 March; landed in Egypt 21 March; 19 days 21 h 47–55 min | verified (Wikipedia, Guinness, Smithsonian-sourced articles). Not named in game text. |
| A three-man round-the-world attempt launched from Marrakech on 18 December 1998 and came down in the sea off Oahu on 25 December 1998 after losing the jet stream | verified (Honolulu Star-Bulletin, virgin.com); sources disagree on the balloon's name. Not named in game text. |
| A solo round-the-world attempt was destroyed by a thunderstorm over the Coral Sea in August 1998 | verified. Inspires the southern-track thunderstorms. |
| Rozière balloons burn propane carried in cylinders along the capsule; a helium cell sits inside/above a hot-air cone | verified. |
| The first transatlantic balloon flight left Presque Isle, Maine, 11 August 1978, landing near Paris on 17 August; its three pilots were from Albuquerque | verified (Albuquerque talk line). |
| Albuquerque's balloon fiesta grew from a 1972 event and is held each October | verified. |
| Saga's balloon fiesta has been held on the Kase River since 1980, each autumn | verified. |
| Tourist balloons fly at dawn over Luxor's West Bank (Valley of the Kings, Colossi of Memnon) | verified for today. **That they flew in 1998–99: verified** (web search, 2026-11-10): a British company began tourist balloon rides at Luxor in 1988, and the first Egyptian balloon company followed in 1993 (Wikipedia, "Hot air ballooning in Luxor"; Egyptian Streets, April 2022). The arrival text still says only that they land there "every morning", not that you arrive at dawn. |
| First Flight Airport is beside the Wright Brothers National Memorial (a 60-ft granite pylon on Big Kill Devil Hill); the first powered flight was 17 Dec 1903 | verified. The strip is in Kill Devil Hills, a few miles south of the town of Kitty Hawk; history calls the site "Kitty Hawk", and so does the game. |
| The 1903 powered flights took off from level sand near the foot of Big Kill Devil Hill; the hill itself was used for the 1900–03 glider trials | general knowledge (raised in review, 2026-11-10); not looked up this session. The ranger's line says "the flat sand below that hill". |
| The Wrights' first flight lasted 12 seconds | general knowledge, not looked up this session. |
| Everest is about 29,000 ft (8,849 m) | general knowledge. At the Himalaya the player climbs to 30,000 ft, and Everest is "just below the porthole". |
| Many round-the-world attempts of 1997–99 came down on land (Algeria 1997, India 1997, Myanmar 1998, India 1998); some ditched (the Mediterranean 1997, the Coral Sea 1998, off Oahu 1998, off Japan 1999) | from review, 2026-11-10; not re-checked this session. The game says "many of them ended in the sea", not "most". |
| The winter jet stream is strongest over and just east of Japan | verified (JMA, AMS paper). |
| The jet weakens and shifts north in spring and is weaker in early winter | general meteorology, **not verified this session**. |
| Jodhpur's fort above the city; the Thar desert; snow on the High Atlas south of Marrakech in winter; Ponta Delgada on São Miguel, Azores | general knowledge, not looked up. |
| Great-circle distances of every route segment | computed from the vertex list in §16. |
| The southern track passes 385 nm north of Kauai, 430 nm north of Oahu and 550 nm north of the Big Island | computed from the vertex list in §16 (2026-11-10). It crosses the empty reefs of the Northwestern Hawaiian Islands (closest: Lisianski, 30 nm; Midway 155 nm to the north), none of which is a field with a ground team. |
| 1999 bulk propane about $0.45 a gallon, freeze-dried food about $3 a pound | **unverified**; game prices chosen for balance, in the right range. |

---

## 2. Roles

| id | Menu label | Start money | Score × | Perk |
|---|---|---|---|---|
| `chocolatier` | A Zurich chocolate maker | $15,000 | ×1 | none |
| `builder` | A Bristol balloon builder | $6,250 | ×2 | Repairs aloft: a sack of ballast gives **+30%** lift (others +20); a burner kit gives **+35%** burners (others +25) |
| `pilot` | An Alaska bush pilot | $5,000 | ×3 | Fishing: hit padding **4** (others 1.5); you can stow up to **60 lb** per outing (others 40) |

Role titles (for "Bonus for being a ___"): `chocolate maker`, `balloon builder`, `bush pilot`.

Note: the money ratio is 3 : 1.25 : 1, not 1849's 3 : 1.7 : 1. Here the builder's perk
replaces the riggers (the 1849 shipyard) for most of a flight: in the balance model she
pays the riggers $1,170 on average against the chocolate maker's $2,310 (§18.3). With more
money she wins too often: $7,000 → 85% and $6,500 → 78% of 180 flights, against 68% at
$6,250 (§18.4). The bush pilot at $5,500 won 47% — inside his band but at its top — and at
$5,000, 33%.

**Role screen** — heading "Who are you?", text: "Balloonists came from every walk of life."
then the three roles and "Compare the three".

**Comparison page** — heading "How they compare":
"Flying round the world is expensive, and not everyone who tried was rich."
"[amber]Chocolate maker[/amber] — starts with $15,000."
"[amber]Balloon builder[/amber] — starts with $6,250. Gets far more out of every sack of
ballast and every burner kit."
"[amber]Bush pilot[/amber] — starts with $5,000. Deadly with a fishing line, and can stow
a bigger catch."
"The poorer you start, the more your finish is worth: the builder scores double, the bush
pilot triple."
Button: "Back".

(1849's own role screen is not touched by this journey; see §20.14.)

---

## 3. Crew

**First names (32)**, an international 1990s mix of ordinary first names, none picked to
evoke a real balloonist:
Anna, Bruno, Claire, Dieter, Elena, Felix, Greta, Hugo, Ingrid, Jonas, Katrin, Luca,
Marta, Nils, Olga, Pascal, Rosa, Stefan, Tessa, Ulrich, Vera, Willem, Yuki, Zoe, Amir,
Bea, Conor, Dana, Erik, Fiona, Gus, Hana.

**Balloon names (14)** (none is a real record-attempt balloon): Westering, Trade Wind,
Long Shot, Cirrus Queen, High Hopes, Zephyr, Far Horizon, Silver Thread, Second Wind,
Equinox, Morning Glory, Skylark, Wanderlust, Daydreamer.

**Names screen** — heading "Balloon & crew"; fields "Name your balloon:" (max 22),
"Your name, Pilot:" (max 16), "Your four crew members:" (4 × max 16); buttons "Use these
names", "Pick new names for me".

---

## 4. Vehicle

**Structural meter: `Lift`** (0–100%). The balloon's margin of buoyancy: helium in the gas
cell, minus what leaks, minus ice, plus what dropping ballast wins back. At **0 the balloon
comes down** and the game is over (§17). Low lift also slows you (it can't hold the fast
winds high up): speed × (0.75 + 0.25 × lift/100), as 1849's hull.

**Propulsion meter: `Burners`** (0–100%). The burner system — jets, valves, igniters,
regulators. Fouled burners can't hold you in the fast winds: speed × (0.45 + 0.55 ×
burners/100), as 1849's sails, and worn every watch as sails are (§12.4).

Status-panel row: "Lift · Burners  64% · 81%".

**Scene sprite** — 18 × 20 cells, one character per colour, space = transparent:

```
       eeess      
     eeeeeesss    
    eeeeeeeesss   
   eeeeeeeeeesss  
  eeeeeeeeeeeesss 
  eeeeeeeeeeeesss 
 gggggggggggggggg 
 rrrrrrrrrrrrrrrr 
 eeeeeeeeeeeeesss 
  eeeeeeeeeeeess  
   eeeeeeeeeess   
    kkkkkkkkkk    
     kkkkkkkk     
      kkkkkk      
      l oo l      
     l  ff  l     
    l  bbbb  l    
   tccccccccccct  
   tcwwcwwcwwcct  
    cccccccccc    
```

| char | colour | part |
|---|---|---|
| `e` | `#E6E9EE` | envelope (helium cell) |
| `s` | `#B9C0CA` | envelope shade |
| `g` | `#D9A441` | gold band |
| `r` | `#D64545` | red band |
| `k` | `#EFE6CC` | hot-air cone |
| `l` | `#5A6270` | load cables |
| `o` | `#FF8A3D` | flame core |
| `f` | `#F2B632` | flame |
| `b` | `#3A3F48` | burner frame |
| `c` | `#ECE4CF` | capsule |
| `w` | `#1A2533` | portholes |
| `t` | `#8A949E` | propane cylinders |

Every row is 18 characters (rows have trailing spaces). Aloft, the sprite's top-left is at
(50, 8 + bob), bob = round(sin(t × (1.0 + rough × 0.5)) × (0.5 + rough × 0.5)); when
`rough ≥ 2` it also sways x ± round(sin(t × 1.3)). Loitering, the top-left is
(50, 18 + bob), same bob and sway (§16.1). On the ground at a port, the top-left is
(50, 33), no bob, no sway.

**The flame:** while travelling, flame pixels (`o`, `f`) are drawn only during the first
0.6 s of every 1.5 s (`t mod 1.5 < 0.6`, the burners "blasting"); otherwise they are left
out. Loitering (aloft, not travelling), they blip: drawn only while `t mod 3 < 0.4`
(§16.1). On the field, never drawn.

**What "torn sails" look like here — a sputtering burner:** when burners < 60, the blast
window shrinks to `0.6 × burners/60` s and `f` pixels are drawn in `#FF8A3D` (no yellow);
when burners < 40, three soot pixels `#3A3F48` appear on the cone at (row 12, col 7),
(row 12, col 10), (row 13, col 8). **Low lift:** when lift < 40, row 0 is not drawn and the
whole sprite sits 3 px lower (a sagging crown, a balloon struggling to hold height).

---

## 5. Supplies

Nine items, Marrakech base prices. Port price = base × port mult × item mod (1849 rule).
"Stored" units = bought units × per.

| # | key | name | unit (one) | step | per | base price | max (bought) | description | engine role |
|---|---|---|---|---|---|---|---|---|---|
| 1 | `food` | Rations | lbs (lb) | 10 | 1 | $3.00 / lb | 500 | Freeze-dried meals, cocoa and chocolate. Each of you eats 3–8 oz a watch. | food |
| 2 | `water` | Drinking water | gal (gal) | 10 | 1 | $0.50 / gal | 250 | About a fifth of a gallon each per watch — more in the heat. | water |
| 3 | `scrubbers` | CO2 scrubbers | canisters (canister) | 1 | 1 | $25 | 30 | Lithium canisters that keep the capsule air sweet. One lasts five of you ten watches. | preventive (stored fractional, like citrus) |
| 4 | `meds` | Medical kits | kits (kit) | 1 | 1 | $100 | 12 | Drugs, splints and oxygen masks. One kit per illness halves its harm. | medicine |
| 5 | `suits` | Down suits | suits (suit) | 1 | 1 | $80 | 10 | One per person. The capsule heater can't hold off the cold of the jet. | warmth |
| 6 | `ballast` | Ballast | sacks (sack) | 1 | 1 | $60 | 20 | Sealed sacks of dry sand. Drop one to win back lift you've lost. | repair-structure (Lift) |
| 7 | `spares` | Burner spares | kits (kit) | 1 | 1 | $140 | 20 | Jets, valves and igniters for servicing the burners aloft. | repair-propulsion (Burners) |
| 8 | `line` | Fishing line | spools (spool) | 1 | **20** | $30 | 30 | Line and lures for trailing from the hatch. Each spool is 20 casts. | forage (state stores casts) |
| 9 | `fuel` | Propane | gal (gal) | 50 | 1 | $0.45 / gal | **1,200** | Burns 12–16 gallons a watch, more in the cold. Run out and you sink. | fuel |

Trade values (the 1849 `VAL`, per stored unit): food 4.2, scrubbers 25,
meds 100, suits 80, ballast 60, spares 140, line 1.5 per cast, fuel 0.55, money 1.
**Water is not traded** (review, 2026-11-13): the jugs hold $150 of it at the 0.6 the
first draft gave it, under the $250 a trader wants, and the smallest trade ($200) is 330
gallons, more than the jugs hold. **No offer gives more than there is room for**: one that
would is cut to the room left, in whole trading units (10 lbs or gallons, a spool, a
kit), and what is wanted for it by the same share (`Journey.fitOffer`); not one unit of
room, no offer.

`describe` phrases: "N lbs of rations", "N gallons of water", "N scrubber canister(s)",
"N medical kit(s)", "N down suit(s)", "N sack(s) of ballast", "N burner kit(s)",
"N spool(s) of fishing line" (casts ÷ 20), "N gallons of propane", "$N".

Shop display: scrubbers show one decimal, like citrus. Away from Marrakech: "Prices here
are N% above Marrakech, more or less."

---

## 6. Ports (landing fields)

**What a port is.** There is nowhere to land for most of the flight — the Sahara, the
Himalaya and two oceans. A *port* is one of five fields where your ground team has
trucked in propane, helium and supplies and is waiting for you. Arriving offers "Land at
the field" (the port menu) or "Fly on without landing". Landing is a real decision:

- **Relaunching costs 25 gallons of propane** (inflating, heating and climbing back to
  cruising height). The first launch at Marrakech costs it too. With less than 25 gallons
  aboard:
  - if you could buy a 50-gallon step of propane here (money ≥ 50 × this field's propane
    price), the relaunch is **refused** (text in §16.4) — go and buy it;
  - otherwise the **ground team tops the tank up to 25 gallons on the sponsor's account**
    (once per landing; text in §16.4), and the climb burns all of it. You leave with an
    empty tank, so the propane-empty rules (§12.2, §12.5) apply from your first watch:
    drifting at 40 nm a watch and losing 5% lift a watch. It is a long shot, not a trap: a
    player with no money and no propane can always leave the field.
  At Marrakech the launch is still refused with no food or under 25 gallons (§16.4), but
  only while the purse runs to a step of what is missing (50 gallons, $22.50; 10 lbs of
  rations, $30). A crew that has spent below that leaves on the sponsor's climb, hungry if
  it has no rations, and the departure sentence says so (D22).
- Time on the ground (rest, the riggers) is time not flying; but the ground is the only
  place the crew heals fast (+6 hp/watch) and the only place to buy anything, and on the
  ground scrubbers aren't needed (the stale-air counter resets — as it also does when you
  open the hatch at the wave tops, fishing (§15) or meeting the boat at the Azores (§14)).
- **On the ground the field is its own place.** Every field but Saga sits exactly on a
  region boundary, and `to` is exclusive, so `state.region` there is the *next* leg's
  region. While on the ground (`atPort`), the engine uses the field's `temp` from the table
  below instead of the region's (it affects only the heat's extra water and illness, so
  with no field `hot` there are none), sickness comes from the ground pools (§11), and the
  status panel and chart caption show the field's short name ("Luxor"), not a region.

Arrival prompt: "You have reached NAME.\n[dim]DATE · day N of the flight[/dim]" + arrival
paragraph; options "Land at the field" / "Fly on without landing".

**Riggers** (the 1849 shipyard): "Top up the helium" → lift 100, costs
`ceil((100 − lift) × 20 × mult)`; "Overhaul the burners" → burners 100, costs
`ceil((100 − burners) × 15 × mult)`. Each takes 1 watch on the ground.

| id | Name ("You have reached ___") | Shop name | mult | item mods | disease risk | ground temp |
|---|---|---|---|---|---|---|
| `mar` | Marrakech | The supply hangar at the launch field | 1.00 | — | no | warm |
| `lux` | Luxor | A balloon outfitter on the West Bank | 1.30 | fuel 0.8, water 0.7, suits 1.4, spares 1.3 | no | warm |
| `jod` | Jodhpur | A gas depot by the old airfield | 1.35 | food 0.7, water 0.8, fuel 1.1, spares 1.4, ballast 0.4 | no | warm |
| `saga` | Saga, on the island of Kyushu | The fiesta grounds by the Kase River | 1.60 | spares 0.8, food 1.2, scrubbers 0.9 | **yes** (winter flu) | cool |
| `abq` | Albuquerque | A balloon works on the north side of town | 1.25 | spares 0.6, ballast 0.7, fuel 0.9 | no | cool |
| `kh` | Kitty Hawk | The hangar beside the Wright memorial | 1.45 | fuel 1.1, suits 0.9 | **yes** (winter flu) | cool |

"Disease risk" is 1849's `fever` flag: +0.012 illness chance on the ground, and the
sickness pool is the flu-field pool (§11). Fields without it use the ground pool.

Propane is cheapest at Luxor of every field after Marrakech: Luxor 1.04×, Albuquerque
1.13×, Jodhpur 1.49×, Kitty Hawk 1.60×, Saga 1.60× the Marrakech price.

### Marrakech (launch; nobody arrives here)
Talk:
1. A rigger coiling a load tape: "Every team that's tried this came down early. The ones that planned for the cold came down later. Buy the down suits."
2. Your meteorologist, pinning a chart to the tent wall: "December to February, the jet is a river. In November it hasn't filled, and by March it's a creek. Don't be on it in March."
3. A retired airline captain who has come out to watch: "Scrubbers. Everybody forgets the scrubbers. Five people in a sealed can make a great deal of bad air."

### Luxor
Arrival: "Below you is the dusty field on the West Bank where the little tourist balloons land every morning, with the temples on one side and the Nile on the other. Half the village is already walking out to watch."
Talk:
1. A tourist-balloon pilot: "We fly one hour every morning and call ourselves brave. Mind the haze over the Red Sea — it's thick as soup."
2. Your ground-team driver, beating dust off his cap: "Propane's cheaper here than at any field ahead of you. Fill every tank you've got."
3. A guide in a white robe: "People have watched the sky over this valley for four thousand years. You are the first I have seen arrive from Morocco."

### Jodhpur
Arrival: "The field is a dry plain below the great fort, and the red dust is already blowing across it. Half the city is out to watch, and somebody has brought tea."
Talk:
1. A schoolteacher: "Beyond us, the Himalaya. Beyond them, China, and then the sea. There is a great deal of 'beyond' in your plans."
2. Your ground-team chief: "Sand for ballast is the one thing the Thar has plenty of. Buy all you can lift."
3. A mechanic from the airfield: "Your burners will ice up over the mountains. Carry spares, and somebody who can fit them wearing gloves."

### Saga
Arrival: "Below you is the wide gravel bed of the Kase River, where the city holds its balloon fiesta every autumn. A crowd is already lining the bank, waving paper flags."
Talk:
1. A fiesta organiser: "From here the jet runs straight out over the ocean, faster than any ship. The next land is America. There is nothing in between."
2. A balloon maker: "Last winter a team left here with half-full tanks. A fishing boat found them near Midway, sitting on their capsule. Fill your tanks."
3. A doctor at the field: "The winter flu is everywhere this month. Wash your hands, and don't linger."

### Albuquerque
Arrival: "Below you is the great dusty field where the city holds its balloon fiesta. A dozen local pilots are waiting on it, and every one of them has advice."
Talk:
1. An old balloonist in a feed-store cap: "Three fellows from this town were the first to fly the Atlantic in a balloon, back in '78. You're carrying their luck. Don't waste it."
2. A burner mechanic: "Best burner parts in the country, and the cheapest. Stock up. The Atlantic doesn't sell spares."
3. A television reporter: "The whole country's watching. Can you say something about the Pacific? Anything. Thirty seconds."

### Kitty Hawk
Arrival: "Below you is the little airstrip beside the Wright Brothers memorial, its granite pylon standing on top of its dune. The wind is whipping sand across the runway."
Talk:
1. A park ranger: "The first airplane flew from the flat sand below that hill in 1903, for twelve seconds. You've been up for weeks. Mind the difference."
2. Your ground-team chief: "From here it's the Atlantic and nothing else. No more fields, no more trucks. Whatever you'll need, buy it now."
3. A fisherman on the beach road: "There's flu all down the Outer Banks this winter. Keep away from the crowd."

---

## 7. Stops

| idx | id | type | name ("You have reached ___") | short | nm |
|---|---|---|---|---|---|
| 0 | `mar` | port | Marrakech | Marrakech | 0 |
| 1 | `atlas` | mark | the High Atlas | High Atlas | 100 |
| 2 | `lux` | port | Luxor | Luxor | 2,200 |
| 3 | `jod` | port | Jodhpur | Jodhpur | 4,400 |
| 4 | `him` | special | the Himalaya | Himalaya | 5,050 |
| 5 | `saga` | port | Saga, on the island of Kyushu | Saga | 7,650 |
| 6 | `pacific` | fork | the edge of the Pacific | Off Japan | 7,800 |
| 7 | `dateline` | special | the date line | Date line | 10,050 |
| 8 | `landfall` | mark | the American coast | Landfall | 12,600 |
| 9 | `abq` | port | Albuquerque | Albuquerque | 13,500 |
| 10 | `kh` | port | Kitty Hawk | Kitty Hawk | 15,000 |
| 11 | `azores` | special | the Azores | Azores | 17,350 |
| 12 | `finish` | end | the finish line | Finish line | 18,300 |

Port-to-port legs: 2,200 · 2,200 · 3,250 · **5,850 (the Pacific)** · 1,500 · 3,300.

---

## 8. Regions

`to` is exclusive. Flags: `sea` (over water: fishing allowed, game-over text, freighter
event), `jet` (affected by the jet-season rules), `high` (cold becomes freezing in
Dec–Feb), `ice` (north-Pacific hazard roll, storm lift ×1.5, rime costs lift),
`storms` (southern-track thunderstorm roll), `atlantic` (North Atlantic winter rules).
Weather weights are **ordered lists** (1849 rule: order is data).

| to (nm) | name | temp | flags | weights, in order |
|---|---|---|---|---|
| 2,200 | The Sahara | warm | — | steady 32, jet 18, light 14, sun 14, dust 12, shear 6, stalled 4 |
| 3,500 | Arabia | hot | — | steady 30, sun 22, light 16, dust 14, jet 10, stalled 6, shear 2 |
| 3,800 | The Gulf of Oman | warm | sea | steady 34, light 18, jet 14, cloud 12, sun 10, stalled 8, storm 4 |
| 4,400 | The Indus & the Thar | warm | — | steady 30, sun 22, light 16, dust 14, jet 10, stalled 6, shear 2 |
| 5,050 | Northern India | cool | jet | steady 34, jet 24, light 14, cloud 12, shear 8, stalled 6, dust 2 |
| 7,350 | The Himalaya & China | cold | jet, high | jet 30, steady 20, shear 18, snow 12, cloud 10, storm 5, light 5 |
| 7,800 | The East China Sea | cool | sea, jet | jet 26, steady 24, cloud 16, shear 12, snow 8, light 8, storm 6 |
| 10,050 | The North Pacific | cold | sea, jet, high, ice | jet 32, shear 22, snow 14, storm 14, steady 10, cloud 8 |
| 12,600 | The Northeast Pacific | cold | sea, jet | jet 26, steady 20, shear 16, cloud 16, snow 12, storm 6, light 4 |
| 13,500 | The American Southwest | cool | jet | steady 30, jet 22, light 14, shear 12, dust 10, cloud 8, stalled 4 |
| 15,000 | The Great Plains | cold | jet | jet 26, steady 24, shear 16, cloud 12, snow 10, storm 6, light 6 |
| 17,350 | The North Atlantic | cool | sea, atlantic | steady 26, jet 22, cloud 16, shear 16, storm 8, snow 6, light 6 |
| 18,225 | Past the Azores | warm | sea | steady 34, light 18, jet 14, cloud 14, sun 8, stalled 8, shear 4 |
| ∞ | Morocco & home | warm | — | steady 34, light 18, jet 14, sun 12, dust 8, stalled 8, shear 6 |

**Southern track** (replaces nm 7,800–12,599 when `passage == .south`; the northern
track is the default list above, as the Horn is in 1849):

| to (nm) | name | temp | flags | weights, in order |
|---|---|---|---|---|
| 10,050 | The southern track | warm | sea, jet, storms | steady 32, jet 20, light 14, cloud 12, storm 10, sun 6, stalled 6 |
| 12,600 | The subtropical Pacific | hot | sea, jet, storms | steady 32, jet 18, light 16, sun 10, cloud 10, storm 8, stalled 6 |

Where the route runs (from the chart's vertices, §16.2): from 3,500 to 3,800 nm it crosses
the Gulf of Oman (56.6°–62° E); at 3,800 it reaches the Makran coast near Gwadar, follows it
to Karachi (4,070) and crosses Sindh and the Thar to Jodhpur. So only 3,500–3,800 is sea:
the old single "Arabian Sea" region (to 4,400, flagged `sea`) let a player fish over the
desert, meet a container ship there and "come down in the sea" over Rajasthan. The Indus &
the Thar takes Arabia's weights (dry, sunny and dusty in winter) at `warm`. The same holds
at the other end: the route reaches the Moroccan coast between Safi and Essaouira at about
18,225 nm, and the finish line is 75 nm inland, so the last stretch is land (review,
2026-11-13).

Expected weather speed factor (Σ weight × speed ÷ Σ weight, before seasons): Sahara 0.93,
Arabia 0.84, Gulf of Oman 0.84, Indus & Thar 0.84, N. India 0.98, Himalaya & China 1.07,
East China Sea 1.02, North Pacific 1.05, NE Pacific 1.04, Southwest 0.99, Plains 1.04,
N. Atlantic 1.01, Past the Azores 0.87, Morocco & home 0.86; southern track 0.88 and 0.86.

The southern track is longer than marked (§1), so its winds are slower: over the ocean
(7,800–12,600 nm) its expected speed is 0.869 against the north's 1.046, a ratio of 0.83,
against a true length ratio of 4,800 ÷ 5,890 = 0.82. (Moving the southern vertices north,
clear of Hawaii, shortened it by about 130 nm; the weights still fit and are unchanged.)

**Seasonal rules** (months 0-based; applied in this order, keys a rule adds that the
region lacks go on the end, as in 1849):

1. **Early winter** — November (10), `jet` regions: jet × 0.6; storm + 6. ("The jet
   hasn't filled.")
2. **Breakup** — March–April (2, 3), `jet` regions: jet × 0.5; light + 12; stalled + 8;
   storm + 6.
3. **Atlantic winter** — December–February (11, 0, 1), `atlantic` region: shear + 8;
   storm + 5 (1849's North Atlantic numbers).
4. **Bad luck** (mascot dropped, `badLuck > 0`): shear + 20; storm + 15; stalled + 10.

**Effective temperature:** a `high` region with temp `cold` becomes `freezing` in
December–February (11, 0, 1). The `atlantic` region becomes `cold` in November–March
(10, 11, 0, 1, 2). Nothing else changes with the season.

So December–February is the fast season *and* the freezing season: the jet is strongest
exactly when the high regions are coldest. November and March are milder and slower.

**Departure months** (year, 0-based month): (1998, 10), (1998, 11), (1999, 0), (1999, 1),
(1999, 2) — "November 1998" … "March 1999".

---

## 9. Weather

Ten kinds. `speed ×` multiplies the day's distance; `wear ×` multiplies burner wear;
`harsh` is hp lost per watch aloft; `lift damage` is lost per watch in addition to the
0.08 leak (§12.4).

| key | display | speed × | wear × | harsh | lift damage per watch | rough? |
|---|---|---|---|---|---|---|
| `steady` | Steady wind | 1.00 | 0.20 | 0 | — | no |
| `jet` | Jet streak | 1.45 | 0.35 | 0 | — | no |
| `light` | Light wind | 0.55 | 0.10 | 0 | — | no |
| `stalled` | Stalled | 0.10 | 0.03 | 0 | — | no |
| `sun` | Hot sun | 0.70 | 0.05 | 0 | random(0, 0.4) — the gas swells and you vent | no |
| `cloud` | In cloud | 0.85 | 0.15 | 0 | — | no |
| `snow` | Snow & rime | 0.80 | 0.60 | 0 | random(0.5, 1.5) **only in `ice` regions** | no |
| `shear` | Rough air | 1.15 | 1.20 | 0.6 | random(0, 0.8) × (The jet 1.5) | **yes** |
| `storm` | THUNDERSTORM | 0.40 | 2.50 | 1.5 | random(1, 2.6) × (The jet 1.6 / Low & slow 0.7 / Middle air 1) × (`ice` region 1.5) | **yes** |
| `dust` | Dust haze | 0.85 | 0.30 | 0 | — | no |

`stalled` sets the note "Not a breath of wind. The balloon hangs over the same patch of
earth." `snow` aloft (not on the ground) melts rime: +2–6 gal water (to cap) with the note
"Melted N gallons of rime off the hatch rim." (This replaces 1849's rain catch.)
"THUNDERSTORM" shows in red in the status panel, as STORM does.

**Sky palettes and effects** (scene §16; `top`/`bot` = 8-band sky gradient; `accent` =
sun or cloud colour; `deck` = a cloud deck that hides the ground below the horizon):

| key | top | bot | accent | effects |
|---|---|---|---|---|
| steady | `#2D5F9A` | `#9FD0EE` | sun `#FFE27A`; cloud `#F4F7FA` ×1 | — |
| jet | `#1E4F8F` | `#8CC8EA` | sun `#FFE27A`; cirrus `#F4F7FA` | 3 cirrus streaks (20 × 1 px, 60% alpha) moving at 3× cloud speed |
| light | `#3A6AA2` | `#B6DCF0` | sun `#FFE27A`; cloud ×1 | — |
| stalled | `#D9893F` | `#F6D78B` | sun `#FFF1B0` | still: no ground scroll, no bob |
| sun | `#3F7FC0` | `#E8F2F8` | sun `#FFFBE0`, drawn 2 px larger | shimmer: alternate ground rows offset 1 px on a 0.5 s cycle |
| cloud | `#8D969E` | `#C5CBD0` | — | fog overlay rgba(210,215,220,.38); deck `#C5CBD0` |
| snow | `#55606E` | `#A6B2BF` | cloud `#8C97A3` ×3 | snow; deck `#8C97A3` |
| shear | `#33404F` | `#6E7D8D` | cloud `#55616F` ×3 | rough 2 (sway) |
| storm | `#15191F` | `#3A434F` | cloud `#2C333D` ×3 | rain, lightning, rough 3; deck `#2C333D` |
| dust | `#B98A55` | `#E3C38E` | sun `#FFE9B0` | 40 dust specks `#D9B07A` drifting; ground mixed 50% with `#C9A36B` |

---

## 10. Pace & rations

**Pace is altitude.** Screen heading "Change altitude"; status/menu label "Altitude".

| key | name | base nm / watch | hp / watch | burner wear × | propane / watch | desc |
|---|---|---|---|---|---|---|
| `low` | Low & slow | 110 | +0.5 | 0.6 | 12 | Around 10,000 feet. Slow winds, gentle on burners and crew. |
| `middle` (default) | Middle air | 150 | 0 | 1 | 14 | Around 20,000 feet. A sensible height. |
| `high` | The jet | 185 | −1 | 2 | 16 | Around 33,000 feet, in the jet stream. Fast and frugal, but bitter cold and hard on everything. |

Propane per nautical mile: 0.109 low, 0.093 middle, 0.086 high — **the fast winds are
also the cheapest per mile**; what they cost is crew health and burners.

| key | name | lb / person / watch | hp / watch | desc |
|---|---|---|---|---|
| `hot` (default) | Hot meals | 0.5 | +1 | 8 oz a watch, heated on the burner ring. |
| `half` | Half portions | 0.3 | −0.3 | About 5 oz a watch. Nobody is ever quite full. |
| `crackers` | Crackers & cocoa | 0.2 | −2.2 | About 3 oz a watch, and a mug of something warm. |

(The keys replace 1849's `filling` / `meager` / `bare` for this journey only; the engine
maps them to the same three ration slots in the same order, and every rule that names
`bare` in 1849 — the +0.005 illness chance — reads `crackers` here.)

---

## 11. Ailments

Damage is hp per watch, halved when treated with a medical kit. Duration is in watches,
both ends included.

| name ("NAME has ___.") | damage | duration | cause of death ("died of ___") |
|---|---|---|---|
| stale-air sickness | 2.2 | until cured | carbon dioxide poisoning |
| altitude sickness | 3.0 | 4–8 | altitude sickness |
| hypothermia | 4.5 | 5–9 | hypothermia |
| frostbite | 2.5 | 6–12 | frostbite |
| influenza | 4.5 | 6–11 | influenza |
| food poisoning | 4.5 | 4–8 | food poisoning |
| a fever | 3.0 | 4–7 | a fever |
| a broken arm | 1.2 | 14–24 | an infected wound |
| exhaustion | 1.5 | 3–5 | exhaustion |

Deaths without an ailment: "thirst", "starvation", "exhaustion" (as 1849).

**Sickness pools** (uniform pick, in this order):
- on the ground at a disease-risk field (Saga, Kitty Hawk): influenza, a fever, food poisoning
- on the ground at any other field: influenza, food poisoning, a fever, a broken arm,
  exhaustion (**new:** 1849 falls through to the region's pool in a fever-free port; here
  the region under a field is the next leg's, §6, and a crew resting at Albuquerque must
  not catch frostbite or altitude sickness)
- hot region: a fever, food poisoning, exhaustion, influenza, altitude sickness
- cold or freezing region: hypothermia, frostbite, altitude sickness, influenza, a broken arm
- otherwise: influenza, food poisoning, a fever, a broken arm, exhaustion

**Stale-air sickness** (the scurvy slot): message "NAME has stale-air sickness. [dim]Pounding
headache, short of breath. Fresh scrubbers or a landing will clear it.[/dim]"; cured with
chance 0.35/watch aloft while scrubbers > 0, 0.6/watch on the ground; cure message "NAME is
breathing easier." Medical kits are not used on it (1849 rule). Other cures: "NAME is well
again." Kit message: " [dim]You open a medical kit (N left).[/dim]"

---

## 12. Daily rules (per watch)

### 12.1 The watch (new mechanic — argued)

- **What:** one tick = 4 hours. Watch 0 is **08:00 GMT on the 1st** of the departure
  month; each tick adds 4 hours. `dateText` = "January 5, 1999 · 1600 GMT" (status panel,
  arrival prompts, graves, game-over footer). **`dateOnlyText`** = "January 5, 1999" (1849's
  `dateText` format) for the two lines that print the hour themselves: the launch ("at 0800
  GMT on DATE", §16.4) and the finale ("at HHMM GMT on DATE", §17), where `DATE` is
  `dateOnlyText`. "Day N of the flight" = ⌊watches ÷ 6⌋ + 1. Finale and game-over
  durations: D = ⌊watches ÷ 6⌋ days, H = (watches mod 6) × 4 hours.
- **Time of day in text.** The hour on screen is GMT, and local time along the route runs
  from GMT − 7 h (Albuquerque) to GMT + 9 h (Saga), so no line a player reads may assume
  dawn, dusk, daylight or dark (review found "at dawn", "the last light", "out of the
  dark", "in the dark", "in the night" and "into blinding sunshine"; this revision removed
  them all). Two exceptions, both safe: the finale says "at the next sunrise" — a landing
  the crew chooses to wait for; and the High Atlas mark (100 nm, snowfields and mule
  tracks) is reached on the first or second watch after the 0800 GMT launch, about 0730–
  1530 local time at Marrakech, unless the wind stalls for hours. Choosing variants by
  local solar time is left as a cosmetic option (§20.12).
- **Why the engine can't already:** the calendar adds `day` days. A real attempt lasts
  about 20 days; with day ticks the game would be ~25 ticks (17 s of travel at 0.7 s) with
  2–3 events. Four-hour watches give ~160 ticks, the same rhythm as 1849's ~165 days, and
  every per-tick number in this file is chosen on that basis (they are close to 1849's
  per-day numbers on purpose).
- **Engine change:** a journey parameter `hoursPerTick` (24 for 1849, 4 here) and a start
  hour (0 for 1849, 8 here); `date` adds `day × hoursPerTick` hours. 1849 is unchanged.
- **Bot:** nothing to do; it counts ticks.

### 12.2 Consumption — `consume(mode)`

`n` = living crew. `temp` = effective temperature of the current region (§8) — or, on the
ground, the field's `ground temp` (§6).

- **Food:** need = n × rations lb (0.5 / 0.3 / 0.2). Short → food 0, starving.
- **Water:** need = n × 0.2 × (hot ? 1.5 : 1) gal. Short → water 0, thirst.
- **Scrubbers (preventive):** on the ground → `noScrubbers = 0`. Aloft with scrubbers > 0
  → scrubbers −= n × 0.02, `noScrubbers = 0`. Otherwise `noScrubbers += 1`.
- **Rime:** aloft and weather `snow` and water < cap → +ri(2, 6) gal, note as §9.
- **Propane** (aloft only — `sail` and `sea` modes; nothing on the ground):
  burn = (sail ? altitude propane : 10) × temperature factor, factor = hot 0.85, warm
  0.95, cool 1.0, cold 1.1, freezing 1.2. If propane > 0: propane −= min(burn, propane).
  If propane was already 0 at the start of this watch: **lift −5** (the envelope cools, you
  sink and can't climb back), then check for coming down (§12.4). This makes `consume` the
  first function that can end the game, so `sailDay` and `passDays` must return (stop) on
  `state.over` after `consume`, before `health` (§20.22).
- **Warnings** (one-time, re-armed as 1849; thresholds in watches of current need):
  - out of food: "[red]The food lockers are empty![/red] The crew is going hungry."
    (re-arm when food > 18 watches)
  - low food (< 12 watches): "The flight engineer reckons there's food for about two days."
  - out of water: "[red]The water jugs are empty![/red] Without water, the crew won't last long."
    (re-arm when water > 12 watches)
  - low water (< 6 watches): "The water is nearly gone — about a day's worth."
  - out of scrubbers (aloft, scrubbers ≤ 0): "The last scrubber canister is spent. The air
    will turn stale in a few days unless you land." (re-arm when scrubbers > 1)
  - low propane (< 6 watches of current burn): "The flight engineer taps the gauge:
    propane for about a day." (re-arm when > 12 watches)
  - out of propane: "[red]The last propane tank sputters dry![/red] Without the burners you
    sink, and keep sinking. Drop ballast and make for a field."

### 12.3 Health — `health(mode)`

Exactly 1849's formula per watch, with these numbers:
- d = rations hp; aloft travelling + altitude hp − weather harsh; loitering (sea) +3; on the
  ground +6; starving −7; thirst −12.
- Temperature, aloft only (`warm` = index < suits): freezing −(warm ? **1.6** : **4.5**),
  **no seasonal extra** (1849 adds 1 in southern winter; here the freezing season is the
  good season, so the extra is folded into 1.6); cold −(warm ? 0 : 2.2); hot −0.4.
- Ailing / not ailing, cures, new-illness probability (0.0035 + (100 − hp) × 0.00035, +
  crackers 0.005, starving 0.03, thirst 0.04, hot 0.003, cold/freezing without a suit aloft
  0.01, disease-risk field 0.012, ×0.7 on the ground): unchanged from 1849. On the ground
  `temp` is the field's (§6), and the pool is a ground pool (§11).
- **Stale air:** if not ill, aloft, and `noScrubbers > 18`: chance
  min(0.12, (noScrubbers − 18) × 0.006) of stale-air sickness. (1849: onset 35 days, slope
  0.004. Here onset 18 watches = 3 days: stale air is quicker than scurvy.)

### 12.4 Balloon wear — `wear()`

- Burners −= altitude wear × weather wear × random(0.6, 1.4).
- Lift −= 0.08 (helium seeps through the cell, every watch aloft and travelling) + the
  weather's lift damage (§9).
- Lift < 35 and food > 20: 6% chance — "You're sinking. Over the side go N lbs of rations
  to keep you up." (N = ri(5, 15); 1849's spoiled-provisions slot).
- Warnings: lift < 30 (re-arm > 50): "[red]The balloon won't hold its height.[/red] You
  need lift — drop ballast, and soon." Burners < 25 (re-arm > 50): "[red]The burners cough
  and spit.[/red] She can barely climb. Service them if you can."
- **Lift ≤ 0 → the balloon comes down** (game over, §17); lift may dip below 0 for an
  instant as in 1849's `checkSink`.

### 12.5 One watch travelling — `sailDay()`

As 1849, with:
- speed = altitude base nm (**40 if propane was 0 at the start of the watch** — drifting on
  the helium alone) × weather speed × (0.45 + 0.55 × burners/100) × (0.75 + 0.25 ×
  lift/100) × crew factor × random(0.85, 1.15), rounded (jsRound), min 0.
- **Crew factor:** living ≥ 3 → 1; 2 → 0.9; 1 → 0.75. (A balloon can be flown by one
  person; fewer hands mean fewer burner watches, not fewer sails trimmed.)
- No Strait ×0.5 and no Horn-winter ×0.6.
- After consume / health / wear, if not arrived, in priority order (at most one):
  1. In a `storms` region: **thunderstorm strike** 3.5% (**0.8%** with the forecasters,
     §14) → lift −ri(15, 35); one extra watch passes (day + 1) and burns one watch of
     propane, min(propane, altitude burn × temperature factor of the current region)
     (nothing else consumed, as 1849's grounding); **the weather becomes `storm`** for that
     watch (the status panel shows THUNDERSTORM and the scene its sky, whatever the watch
     rolled — the strike can follow a "Hot sun" roll);
     message: "A thunderstorm boils up beneath you without warning. The updraft flings the
     balloon two miles up and the downdraft drops it three. It takes a whole watch to fight
     clear. [red](Lift −N%)[/red]" Check coming down.
  2. Else in an `ice` region: **roof accident** 2% (§13 event 8's function).
  3. Else 11% random event (§13).

### 12.6 Days without travelling — `passDays(n, mode)`

As 1849, plus the stop on `state.over` after `consume` (§12.2). Sea mode is
**loitering**: "you drop into slow, low air and make no real headway east" — no movement,
no wear, the weather rolls, propane burns at 10 × temperature factor. Ground mode: weather
`steady`, no propane. Rest options: 1, 2, 3, 5 watches.

### 12.7 Differences from 1849, and why

| 1849 | Balloon | Why |
|---|---|---|
| day tick | 4-hour watch | §12.1 |
| no fuel | propane per watch by altitude × temperature; 10/watch loitering; 25 per launch; empty → speed base 40 and lift −5/watch | the brief's fuel mechanic; a balloon burns to stay up, not to move, so the burn is per watch, not per mile; the temperature factor is how cold costs propane in real Rozières |
| hull loses 0.03/day; storm/gale damage hard-coded | lift leaks 0.08/watch; per-weather lift damage table (§9) | data instead of code; ice and sun cost lift too |
| rain catch 15–45 gal in rain/storm | rime melt 2–6 gal in snow | no rain falls into a capsule at 20,000 ft |
| freezing −1.4 / −4.5, +1 in southern winter | −1.6 / −4.5, no seasonal extra | winter is the good season here |
| scurvy onset 35 days, slope 0.004 | stale air onset 18 watches, slope 0.006 | CO2 builds faster than scurvy |
| crew factor 1 / .85 / .65 / .45 | 1 (≥3) / .9 / .75 | §12.5 |
| Strait ×0.5, aground roll; Horn overboard roll | `storms` thunderstorm roll; `ice` roof-accident roll | the same two hooks, re-skinned and re-numbered |
| money constants (trade $25–70, yard 2.5/1.8, cash ÷5) | ×10 economy: trade $250–700, riggers 20/15, cash ÷50 (§17, §20) | a 1999 expedition budget |
| in port: the region's temperature; a fever-free port uses the region's sickness pool | on the ground: the field's temperature and the ground pool (§6, §11) | five of six fields sit on a region boundary, where the region is the next leg's |
| spoil when hull < 35 and food > 50; low-stock warnings at 7 / 5 days | sink-and-dump when lift < 35 and food > 20; warnings at 12 / 6 watches (§12.2) | per-journey thresholds (§20.19) |

---

## 13. Random events

Rolled with 11% chance per travelling watch (after the region hazard rolls), weighted
among the eligible, as 1849. `rough` = shear or storm.

| # | weight | condition | effect |
|---|---|---|---|
| 1 | 6 | food > 40 | food −= round(food × random(0.05, 0.14)) |
| 2 | 5 | water > 30 and region not hot | water −= ri(6, 20) |
| 3 | 4 | always | food += ri(3, 8) |
| 4 | 3 | always | 50%: spares +1; else 60%: food += ri(10, 25); else flavour |
| 5 | 6 | rough or jet | burners −= ri(12, 28) |
| 6 | 4 | rough | burners −15, lift −6; 50%: a healthy crew member gets a broken arm (14–24) and −10 hp; check down |
| 7 | 4 | always | lift −= ri(8, 18); check down |
| 8 | 3 | rough or snow | roof accident (below) |
| 9 | 1.5 | propane > 100 | propane −= round(propane × 0.08) |
| 10 | 2 | storm | burners −18 |
| 11 | 2.5 | `sea` region and not rough | **choice: the freighter** |
| 12 | 2 | cold or freezing region, not yet seen | **choice: the mascot** |
| 13 | 5 | warm or hot region, or a `storms` region | **choice: thunderheads** |
| 14 | 4 | cold or freezing region, weather snow or cloud | **choice: ice on the envelope** |
| 15 | 2 | not a `sea` region, not rough, not at The jet | **choice: the camera plane** |
| 16 | 2 | not rough | flavour (a quiet watch) |
| 17 | 1.5 | rough | forceFair = 2 (`steady` for two watches) |

"Region not hot" and "cold or freezing region" read the region's effective temperature
(§8), as 1849's events do.

Messages:

1. "Condensation has been dripping into a food locker for hours. N lbs of rations are soaked and ruined."
2. "A water jug left against the cold capsule wall has frozen solid and split down the side. N gallons are now a sheet of ice under the floor panels."
3. "Behind the radio rack, someone finds a bag of chocolate bars and a note from the ground crew: “For emergencies. This counts.” +N lbs of rations."
4. Spares: "Under a bunk you find a burner kit that was never on the manifest." Food: "A case of rations turns up behind the oxygen bottles, still sealed. +N lbs of rations." Flavour (OTHER = a random balloon name not yours): "Mission Control reads you the news: the [i]OTHER[/i] has come down in the sea, and her crew is safe aboard a freighter. Nobody says much for the rest of the watch."
5. "Number two burner coughs, flares yellow and dies. It takes an hour of coaxing to bring it back. [red](Burners −N%)[/red]"
6. "A load cable parts with a bang like a rifle shot, and the capsule lurches on the rest. [red](Burners −15%, Lift −6%)[/red]" + with the injury: "\n\nNAME was thrown against the burner frame and has a broken arm."
7. "The gas cell is leaking. Somewhere up near the crown a seam has opened, and nobody can reach it. [red](Lift −N%)[/red]"
8. **Roof accident** (also the `ice` region's 2% roll; a random living non-captain; nobody if none):
   - 65%: hp −25 (min 1): "NAME climbs out of the top hatch with an ice axe to knock the ice off the burners, and comes back an hour later with fingers like frozen sausages."
   - 35%: hp −20; if not already ill, a broken arm (14–24): "NAME slips on the iced roof of the capsule. The harness holds, but NAME has a broken arm."
9. "A valve on the tank rack outside has frozen open, and before you can close it, N gallons have vented away."
10. "Lightning cracks past close enough to taste. A burner valve is welded shut. [red](Burners −18%)[/red]"
16. "For a whole watch the air is smooth, the burners are quiet and the radio has nothing to say. You can hear the envelope creak above you. Nobody speaks for a while." Bush pilot adds: " It is as quiet as a lake in Alaska with the floatplane's engine off."
17. "Mission Control radios: you've dropped out of the rough air into a steady stream, and the next two watches should be easy. The capsule stops shaking for the first time in a day."

### Choice events

**11 — The freighter** (the 1849 strange sail; the trade engine's mid-flight door).
Prompt: "A container ship's captain radios up from the sea far below. She'll trade, if you'll come down low enough to pass a line."
Options: "Drop down to meet her (1 watch)" / "Wave and fly on".
- Drop down: `passDays(1, .sea)` first, then:
  - 75%: `makeOffer(excluding: [fuel, ballast])` → trade choice with intro "Her bosun ties a sack to your trail line and shouts up what's in it." If no offer: "She has nothing you need. Her cook sends up a bag of oranges anyway, and the football scores."
    **The freighter never trades propane or ballast**, either way: an offer's 250–700
    dollars of value would be 450–1,400 gallons of propane or 4–12 sacks of sand, tons on
    a trail line. (Water, heavier still, is not traded anywhere: §5.) Both are left out of `wantable` and of the `give` candidates before the
    picks are drawn (so the draw order is 1849's: same picks, smaller lists). The fields'
    traders (§16.3) keep all nine items; trucks can carry anything.
  - 25%: burners −10: "The line snags on her radio mast as she rolls. It parts before it can drag you down, but the jolt rattles every burner. [red](Burners −10%)[/red]"
- Fly on: "You blip the burners at her by way of a wave. She sounds her horn, faint and far below."

**12 — The mascot** (the 1849 albatross).
Prompt: "The mascot — a knitted bear in a flying helmet, made by a schoolgirl in Marrakech — has ridden on the instrument panel since launch. Your flight engineer eyes it: “Every ounce counts.”"
Options: "Keep the bear" / "Drop it over the side (Lift +1%)".
- Keep: "The bear stays where it is. Nobody says so, but everyone is relieved."
- Drop: lift +1 (max 100), `badLuck = 25` watches: "The bear tumbles away into the cloud. The balloon doesn't notice the difference. The crew does. [dim](Lift +1%)[/dim]"

**13 — Thunderheads** (the 1849 icebergs). `cloudy` = current weather is `cloud`.
Prompt: "A line of thunderheads stands across your track, their tops higher than you can fly. There's a gap between two of them — narrowing." (if cloudy: "…stands across your track, half hidden in the murk. There may be a gap between two of them.")
Options: "Descend and go around (lose a watch)" / "Hold your course through the gap".
- Go around: day + 1, `consume(.sail)`, `health(.sail)` (propane burns at the current altitude); 10%: lift −ri(6, 12): "You lose a watch detouring round the cells, and still catch the edge of one. [red](Lift −N%)[/red]"; else "You lose a watch detouring round the cells, but come out the other side unharmed." Check down.
- Hold: risk = (cloudy ? 0.25 : 0.12) + (The jet ? 0.15 : 0); hit → lift −ri(18, 35): "The gap closes. For ten minutes the balloon is flung up and down like a toy, and hail hammers on the capsule. [red](Lift −N%)[/red]" (check down); miss: "You hold your course with your heart in your mouth. Lightning walks the cloud walls on either side — and then you're through."

**14 — Ice on the envelope** (new).
Prompt: "Ice is building on top of the envelope. You can't see it, but you can feel it: the balloon is getting heavy and slow to answer."
Options: "Climb above the cloud to melt it (40 gal)" (enabled only if propane ≥ 40) / "Ride it out".
- Climb: propane −40: "You burn hard and climb out of the cloud into clear, dry air. Within the hour the ice is sliding off the envelope in sheets and tumbling away below."
- Ride: lift −ri(5, 15): "You ride it out. By the time the cloud thins, the balloon is carrying a ton of ice and sagging like a wet tent. [red](Lift −N%)[/red]" Check down.

**15 — The camera plane** (new). Not at The jet's altitude, which no small plane reaches.
Prompt: "A small plane full of television cameras climbs up to circle you. Its pilot comes on the radio: closer, they want closer."
Options: "Wave them in close" / "Wave them off".
- Close, 50%: money += 50 × ri(6, 16) ($300–$800): "The pictures go out on the news around the world. Your sponsors are delighted, and wire you a bonus. [green](+$N)[/green]"
- Close, 50%: lift −8, burners −12: "The plane cuts across in front of you, and its wash sets the whole balloon swinging. [red](Lift −8%, Burners −12%)[/red]" Check down.
- Off: "They circle twice, film the envelope against the sky, and drone away home."

Why these numbers: at the review's 65/35 and −4/−8 the bonus was worth ~$350 against ~$70
of damage, and taking it every time lifted the builder from 97 to 102 wins in 120 and the
pilot from 44 to 51 — not a choice. At 50/50 and −8/−12 the expected bonus ($275) is about
what the damage costs a poor crew in sacks, kits, speed and risk: in the balance model a
bot that waves them in whenever lift and burners are both ≥ 50 wins 123 of 180 flights with
the builder (123 waving off) and 55 with the bush pilot (60 waving off). For the chocolate
maker the money is worth nothing and the damage costs score. So the bot waves them off
(§18.2), and that is how the bands are measured.

(1849's stowaway and privateers have no counterpart: nobody can hide in a sealed capsule,
and nobody can board a balloon.)

---

## 14. Landmarks & fork

**Mark — the High Atlas (100 nm):** "You are crossing the High Atlas. Snowfields slide by below, close enough to see the tracks of mule trains, then fall away to the stony desert. Mission Control comes on the radio: you're on your way."

**Special — the Himalaya (5,050 nm):**
Prompt: "You are passing the Himalaya."
Detail: "The whole range stands up out of the haze to the north, a white wall two hundred miles long. Mission Control says the jet is running hard right over the summits — if you can stand the cold."
Options: "Climb over the range into the jet (35 gal)", or at The jet already "Hold the jet over the range (35 gal)" (disabled if propane < 35) / "Stay south of the range".
- Climb: propane −35; mile += 200, but never beyond `nextStop.mile − 1`; every living crew member hp −3, and each one without a down suit (index ≥ suits) a further −10; 25%: burners −10. Text: "You burn hard and climb up over the summits into the jet, and it takes you like a leaf in a gutter." (at The jet: "You burn hard to hold your height over the summits, and the jet takes you like a leaf in a gutter.") + " For an hour Everest stands just below the porthole, close enough to see the snow streaming off the summit. You've gained two hundred miles. The cold has gained on all of you. [red](Crew health falls.)[/red]" + if burners hit: " Ice forms in a burner valve over the range. [red](Burners −10%)[/red]". Deaths are checked (1849 `deaths`).
- Stay: "You keep to the warm side of the mountains. The peaks slide past to the north, one white summit after another."

**Fork — the edge of the Pacific (7,800 nm):**
Prompt: "You are leaving the coast of Japan. Ahead lies the Pacific: five thousand miles with nowhere to land." + if month is November, March or April: " [red]The jet is weak this time of year.[/red]"
Detail: "You may ride the [amber]northern track[/amber] in the core of the jet — fast, and bitter cold — or drop south to the [amber]southern track[/amber], warmer and slower, where the thunderstorms grow."
Options: "Ride the northern track" / "Take the southern track" / "Ask Mission Control's advice".
- North: `passage = .north` (default regions): "You climb into the jet, and the Pacific starts to slide by faster than any ship could cross it. Everyone puts on a second pair of socks."
- South: `passage = .south` (southern regions for 7,800–12,599), then the guide offer.
- Advice (message, then the fork again): "Mission Control's chief meteorologist comes on the radio: “The north is quicker if the jet holds, and it's brutal cold up there — nobody without a down suit should go. The south is warmer and slower, and it's thunderstorm country. If you go south and can spare the money, buy the storm plots.”"

**Guide offer — the forecasters ($250):**
Prompt: "Mission Control says a forecasting service in Honolulu will radio you a storm plot every watch, all the way across, for $250."
Detail: "Hawaii lies far to the south, out of reach of this wind. [dim]You have $N.[/dim]"
Options: "Hire the forecasters ($250)" (disabled if money < 250) / "Trust your own eyes".
- Hire: money −250, `forecasters = true` (thunderstorm strike 3.5% → 0.8%): "The first plot comes over the fax an hour later, dense with red blobs. A note at the bottom says: “Stay out of the red. Always out of the red.”"
- Decline: "You'll read the clouds yourselves. To the south the sky is already stacking up in towers."

What they are worth: about 40 watches in the `storms` regions, so they save about 1.1
strikes — ~28 lift (1.4 sacks of ballast, ~$135 at Saga) and a watch of propane and time —
plus the tail risk of a 35-point strike when lift is already low. At $500 that was a bad
buy for anyone short of money (in the balance model's forced southern crossings, 120 per
role: builder 71 wins with them, 84 without; bush pilot 11 with, 43 without). At $250 they
are worth it when money is no object (chocolate maker: 117 with, 108 without) and roughly
even for the builder (82 with, 84 without); for the bush pilot, whose every dollar goes on
the last tank at Kitty Hawk, they still cost wins (34 with, 43 without). That is the choice
the advice describes. The bot hires them only with more than $1,500 in hand (§18.2).

**Special — the date line (10,050 nm)** (the 1849 Equator):
Prompt: "You are crossing the date line!"
Detail: "Half a world from Greenwich, the calendar below you jumps back a day. Mission Control keeps Greenwich time, so nothing changes aboard — but somebody has kept a cake in the freezer since Marrakech for exactly this moment."
Options: "Hold a party (1 watch)" / "Keep to the watch schedule".
- Party: day + 1, propane −15 and food −3 (neither below 0), every living crew member hp +8 (max 100): "There is cake, cocoa, a paper hat for everyone and a crackly telephone call from home. Spirits climb higher than the balloon. [green](Crew health improves.)[/green]"
- Schedule: "You note the moment in the log and keep the watch schedule. Somebody eats the cake anyway, quietly, at three in the morning."

**Mark — landfall (12,600 nm)**, by passage:
- North: "Landfall! The coast of California slides in under you north of San Francisco — a white line of surf, then the dark of the redwoods. The Pacific is behind you. Everyone talks at once."
- South: "Landfall! San Diego slides in under you, and then the brown hills and the desert. The Pacific is behind you. Everyone talks at once."

**Special — the Azores (17,350 nm)** (the 1849 Galápagos):
Prompt: "You are passing over the Azores."
Detail: "Green volcanic islands in the middle of the Atlantic. A fishing boat out of Ponta Delgada has heard you on the radio, and offers to meet you off the coast with fresh water and bread if you'll come down to the wave tops." + in rough air (`shear`, `storm`): " [red]But the air is far too rough to come down that low today.[/red]"
Options: "Drop down to meet her (2 watches)" (disabled in rough air, as fishing is) / "Fly on".
- Drop: water += ri(20, 40), food += ri(10, 25), `noScrubbers = 0`, stale-air sickness cured for everyone; message "Her crew passes up water jugs, bread, cheese and oranges in a net on the end of your trail line. With the hatch open at sea level, the capsule fills with real air for the first time in days. (+W gallons of water, +F lbs of rations.)"; then 15%: a healthy living non-captain gets a broken arm (14–22): "NAME caught a hand in the line hauling the net up, and has a broken arm."; then two watches of `consume(.sea)` + `health(.sea)` **without** the weather roll (as 1849's Galápagos), propane at the loiter rate.
- Fly on: nothing.

**Finish (18,300 nm):** finale (§17).

---

## 15. Mini-game skin — trailing a line

Sea-menu label: "Trail a fishing line". You drop to the wave tops and cast lures from the
open hatch. Opening the hatch at sea level airs the capsule: when the outing ends, **before**
the watch passes, `noScrubbers = 0` (as at the Azores; it does not cure stale-air sickness,
which the Azores' longer stop does). Then one watch passes (`passDays(1, .sea)`). Balance:
the bot fishes about once a flight (0.8 outings for the builder, 1.0 for the bush pilot) and
buys scrubbers leg by leg, so the reset changed no result in the model; a human can use it
to stretch a short supply of scrubbers over the oceans, at a watch and a spool's casts each
time.

**Refusals** (checked in this order):
1. "You have no fishing line left." (line = 0)
2. "There's no sea below you to fish in." (current region lacks `sea`) — **new condition**
3. "The air is far too rough to come down that low." (weather rough)

**Targets** (in this order; same spawn, wobble and hit rules as 1849):

| name | lb | w × h | speed px/s | weight | colour |
|---|---|---|---|---|---|
| flying fish | 1 | 9 × 3 | 26–42 | 35 | `#9FC9E8` |
| mackerel | 2 | 12 × 4 | 30–48 | 26 | `#7FD6C9` |
| mahi-mahi | 5 | 15 × 5 | 36–56 | 18 | `#E8C547` |
| skipjack | 12 | 20 × 7 | 24–38 | 13 | `#46689A` |
| yellowfin | 24 | 28 × 7 | 38–58 | 8 | `#5B7BB0`, dorsal fin (1849 shark-fin pixels) in `#F2D04B` |

Average fish 5.25 lb. **Reward item:** food (lbs). **Per-role cap:** 40 lb per outing,
bush pilot 60; also capped by room under the food max. Each cast costs 1 cast of line.
25-second timer.

**Backdrop** (160 × 200): above y = 28, a pale gold sky `#F6D78B`; hanging from the top centre,
the underside of the capsule — body `#ECE4CF` at x 66–94, y 8–22, a row of portholes
`#1A2533` at y 14 (x 70, 76, 84, 90; 2 × 2 each), load cables `#5A6270` from (68, 0)–(70, 8)
and (90, 0)–(92, 8), an open hatch `#3A3F48` at x 78–82, y 22–24, and a crew member in a red
suit `#D64545` at x 79–80, y 22–26 with a face `#EFD6B0` at y 26–27. Water: 1849's ten bands
`#1F6B96` → `#061A2B`, light shafts and surface dashes. The cast is a lure on a line from
(80.5, 27.5): line rgba(236,228,207,.5), lure head 2 × 2 `#F2B632` with a 6-px trail
`#ECE4CF` (the 1849 harpoon drawing, recoloured).

**Copy:** heading "Trailing a line"; HUD "Casts: N" · "Caught: N lbs" · "Time: N"; help
"Tap the water to cast a lure. Each cast uses line. You can stow up to N lbs.";
button "Back to the capsule".
Result: "You caught [amber]N lbs[/amber] of fish." or "You caught nothing."; if over the
cap: " The cool box holds N lbs before the rest goes bad."; if any kept: "
[green]+N lbs of rations.[/green]"; always " [dim]The capsule is aired out. A watch has
passed.[/dim]"

---

## 16. Scene & chart

### 16.1 Scene (160 × 80, horizon y = 46)

Three states, chosen as 1849 chooses "sailing", "hove to" and "at anchor": **aloft**
(`moving`: a watch is being flown), **loitering** (aloft, not moving: the sea menu, rest,
repairs, fishing) and **on the field** (`atPort`). `hz` is the horizon: 46 aloft and on
the field, **40 loitering** (you are low, so more ground shows). `t` is seconds on the
shared scene clock; `mod` is 1849's `mod` with negative results wrapped up by the modulus;
every x and y is rounded down before drawing. Draw order (1849's, with the new layers
slotted in): sky bands → sun → clouds → cirrus → peaks → ground fill → ground dashes →
field props → balloon → rain → snow → dust → fog → lightning.

- **Sky:** 1849's 8 bands from y 0 to `hz` (band i at ⌊i × hz / 8⌋, height ⌈hz / 8⌉ + 1,
  colour mix(top, bot, i / 7)). Sun as 1849 at (125, 8) when the weather has one (`sun`
  weather: each of the three sun rects 1 px larger on every side). Clouds exactly as 1849
  (count × 2, x = mod(i × 61 + 20 − t × (2 + i) × (moving ? 1.6 : 0.4), 200) − 20,
  y = 5 + (13i mod 24), 1849's shape and its jsRound), which already move right to left
  (you travel east, to the right).
- **Cirrus** (`jet`): 3 streaks, 20 × 1 px, `#F4F7FA` at 60% opacity; streak i (0, 1, 2) at
  y = 6 + 7i (6, 13, 20), x = mod(i × 67 + 10 − t × 3 × (2 + i) × (moving ? 1.6 : 0.4),
  200) − 20 — three times the matching cloud's speed.
- **Ground:** the region's fill (table below) from `hz` to 80, then texture dashes, 1 px tall:
  rows r = 0…7 at y = hz + 2 + 4r aloft (48…76), r = 0…8 at y = hz + 2 + 4r loitering
  (42…74); 7 dashes a row, dash i at x = mod(i × 29 + r × 17 − t × v_r, 160), length
  2 + ((i + r) mod 3). Aloft v_r = 4 × weather speed + 1 for every row (from that height
  there is no parallax); loitering v_r = 0.5 + 0.25r (slow drift, nearer rows faster);
  `stalled` → 0 in both. On the field: no dashes.
- **Cloud deck:** aloft in `cloud`, `snow` and `storm`, the ground fill and dashes are
  replaced by the weather's deck colour (§9) with dashes in the sky `bot` colour. Loitering
  you are under the deck: the region's ground shows, with the weather's effects on top.
- **Peaks** (The Himalaya & China, aloft and loitering): 9 peaks per 160 px, standing on the
  horizon. Peak k (0…8): centre c = 8, 26, 41, 59, 77, 92, 110, 128, 146; half-width
  w = 6, 8, 5, 9, 6, 7, 8, 5, 7; height h = 5, 8, 4, 9, 6, 7, 9, 3, 6. Row j = 0…h − 1
  (apex first) is at y = hz − h + j and runs from x = c′ − ⌊w (j + 1) / h⌋ to
  c′ + ⌊w (j + 1) / h⌋ inclusive, `#EEF3F7` for j < ⌈h / 3⌉ (the snow cap), else
  `#6E7480`. c′ = c − mod(t × v / 4, 160), drawn again at c′ + 160 so the band wraps; v is
  the row-0 dash speed.
- **Dust** (`dust`): 40 specks `#D9B07A`, 1 × 1; speck i at x = mod(i × 37 − t × (6 + i mod
  5) × (moving ? 1 : 0.3), 160), y = (i × 53 mod 78) + round(sin(t × 0.7 + i)). The ground
  fill and dash colours are mixed 50% with `#C9A36B`.
- **Balloon:** sprite §4. Aloft, top-left (50, 8 + bob) as §4. **Loitering**, top-left
  (50, 18 + bob) — its lowest row at y 37, just above the horizon at 40 — with the same bob
  and sway rules and the low-lift sag; the flame blips while loitering, drawn when
  `t mod 3 < 0.4` (the burners holding height). On the field (50, 33), no bob, no flame.

| region | ground fill | dash colour | extra |
|---|---|---|---|
| The Sahara | `#C99A5B` | `#E0B877` | — |
| Arabia | `#D2A86A` | `#EBC98F` | — |
| The Gulf of Oman | `#1D4E7A` | `#7FB8DE` | — |
| The Indus & the Thar | `#BF915E` | `#DDB585` | — |
| Northern India | `#7A8B4E` | `#A3A86B` | — |
| The Himalaya & China | `#5E6B5A` | `#8C9A86` | the band of peaks (above) |
| The East China Sea | `#22557F` | `#8CC0E0` | — |
| The North Pacific | `#1F3346` | `#E8EEF3` | — |
| The Northeast Pacific | `#24394E` | `#8AA0B4` | — |
| The southern track | `#1A5A8A` | `#9FD4EE` | — |
| The subtropical Pacific | `#1B6A94` | `#A8E0F2` | — |
| The American Southwest | `#B5754A` | `#D9A06F` | — |
| The Great Plains | `#9C9A6A` (Dec–Feb: `#DDE4EA`) | `#C2BE8E` (Dec–Feb: `#B8C3CC`) | — |
| The North Atlantic | `#1D4E7A` | `#E9F4FB` | — |
| Past the Azores | `#1A4A78` | `#7FB8DE` | — |
| Morocco & home | `#C49A62` | `#E2BD86` | — |

**On the field:** weather fair (`steady` sky), the field fill from y 46 to 80, the balloon
standing on it (sprite at (50, 33)). Props, as rects (x, y, w, h), in this order:
- **Hangar:** body (112, 36, 34, 10) `#8A949E`; rounded roof (114, 34, 30, 1) and
  (112, 35, 34, 1) `#6E7480`; door (121, 38, 16, 8) `#3A3F48` with a seam (128, 38, 1, 8)
  `#5A6270`.
- **Windsock:** pole (104, 30, 1, 16) `#ECE4CF`; sock 5 × 2 at (105, 30), columns x 105,
  107, 109 `#F2B632` and x 106, 108 `#D64545` (it streams east, to the right).
- **Fuel truck:** tank (20, 48, 10, 4) `#ECE4CF`; cab (30, 49, 4, 3) `#D64545` with a
  windscreen (32, 49, 2, 1) `#9FD0EE`; chassis (20, 52, 14, 1) `#3A3F48`; wheels (21, 53,
  2, 1), (26, 53, 2, 1), (31, 53, 2, 1) `#1A2533`.
- **Crowd:** 12 figures, figure i (0…11) a 1 × 2 rect at (70 + ⌊30i / 11⌋, 50) — x 70, 72,
  75, 78, 80, 83, 86, 89, 91, 94, 97, 100 — coloured `#2C333D`, `#D64545`, `#F2B632` by
  i mod 3.

Field fill: Marrakech `#C99A5B`; Luxor `#C9A36B` with a Nile strip `#2F6A96` at y 56–58;
Jodhpur `#B5754A`; Saga `#7C8F5A` with a river strip `#2F6A96` at y 60–61; Albuquerque
`#A88A5E`; Kitty Hawk `#D9C79A` with sea `#1D4E7A` from y 46 to 48.

**VoiceOver labels:** aloft travelling "Balloon flying in WEATHER" (a thunderstorm:
"Balloon flying in a thunderstorm"); loitering "Balloon loitering low in WEATHER"; port
"Balloon standing on the field at NAME". Weather names lower-cased.

### 16.2 Chart — a polar map

A round-the-world flight doesn't fit 1849's equirectangular strip, so the chart looks
down on the North Pole. Canvas 230 × 210 (as 1849). Projection, with **unwrapped**
longitudes (east of 180° written as 180+, e.g. 190 for 170° W, so the route never jumps):

```
r = (90 − lat) × 1.25
x = 115 + r × sin(lon°)
y = 105 + r × cos(lon°)
```

Greenwich points down, Asia is on the right, the Pacific at the top, America on the left;
the flight goes counter-clockwise. Map only inside the circle r ≤ 97.5 (latitude ≥ 12° N);
outside it, the app background `#0A0E14`. Ocean `#0D2A44`; dotted graticule `#173B5C`
(circles at 30° N and 60° N, a dot every 2° of longitude; meridians every 30°, a dot every
2° of latitude); the 12° N edge dotted `#2F6A96` (1849's equator line); land `#B9A26C`
(polygons below, clipped to the circle, in the order listed); the Black Sea, the Caspian
and the Baltic drawn over the land in ocean colour; islands as 3 × 2 blocks. Route dots: full route `#6D7F92` every 60 nm, flown
portion `#F2B632` every 25 nm, stop markers 3 × 3 (amber once passed, `#ECE4CF` ahead), the
balloon a blinking 5 × 5 `#FF6B5B` marker (1849 rules). Position by nm: linear between
vertices (1849 `posAt`).

Legend (two columns, ✓ ► · as 1849) of the stop short names, then "X of 18,300 nautical
miles flown. Y to go." Heading "Chart of the flight".

**Route, northern track — [lon, lat, nm]** (default; vertices computed from great-circle
lengths and scaled so each stop falls on its nm):

```
(-8, 31.63, 0), (-6, 31.4, 100), (-1, 30.4, 370), (5, 29, 690), (12, 27.6, 1080),
(20, 26.6, 1510), (27, 26, 1890), (32.64, 25.69, 2200), (37, 25.2, 2440), (43, 24.8, 2760),
(48, 24.4, 3030), (53.5, 24.2, 3330), (57.5, 24.6, 3550), (62, 25.2, 3800), (67, 25, 4070),
(73.02, 26.24, 4400), (77.2, 28.6, 4660), (81, 28.3, 4860), (84.5, 27.7, 5050),
(88, 26.8, 5250), (92, 26.3, 5460), (97, 25.5, 5740), (103, 25, 6070), (110, 25.3, 6450),
(117, 26.5, 6840), (122, 28.3, 7130), (127, 31, 7430), (130.3, 33.25, 7650),
(133.5, 33.3, 7800), (140, 35.5, 8150), (150, 38.5, 8660), (160, 40.5, 9140),
(170, 41.5, 9600), (180, 42, 10050), (190, 42, 10490), (200, 41.5, 10940),
(210, 41, 11390), (220, 40, 11850), (230, 39, 12310), (236.2, 39.4, 12600),
(242, 37.5, 12910), (248, 36.5, 13210), (253.35, 35.08, 13500), (260, 35.5, 13820),
(270, 35.5, 14310), (278, 36, 14700), (284.3, 36.02, 15000), (295, 37.5, 15520),
(310, 38.5, 16220), (322, 38.5, 16770), (334.3, 37.75, 17350), (345, 35, 17890),
(350.2, 32.3, 18200), (352, 31.63, 18300)
```

**Route, southern track** — identical to the northern list up to (133.5, 33.3, 7800) and
from (253.35, 35.08, 13500) on; between them:

```
(140, 31, 8120), (150, 28, 8600), (160, 26, 9090), (170, 25, 9570), (180, 24.5, 10050),
(190, 28, 10490), (200, 28.5, 10900), (210, 29, 11300), (220, 30, 11700), (230, 31, 12100),
(242.8, 32.7, 12600), (248, 33.5, 13040)
```

East of the date line the southern track runs at 28–31° N (it ran at 23–26° N in the first
draft, 57 nm from Kauai and 1.2 px from its island block on the chart). It now passes
385 nm north of Kauai and 430 nm north of Oahu; on the chart the route dots run about 9 px
inside (north of) the Hawaii blocks. The nm markers between 10,050 and 12,600 were rescaled
from the new great-circle lengths (the leg is 3,340 nm of real distance marked as 2,550).

**Land polygons** ([lon, lat]; checked by rendering, 2026-11-09; the Canadian Arctic,
Svalbard, Novaya Zemlya, Sakhalin and the Baltic added and checked by rendering,
2026-11-10):

```
// North Africa (clipped at 12° N)
(-17.5,14.7),(-16.8,12),(0,12),(15,12),(30,12),(43,12),(42.5,14),(39.5,15.5),(37.2,19),
(35.5,23.9),(33.5,27.5),(32.5,29.9),(32.3,31.2),(30,31.3),(25,31.6),(20,30.8),(19,30.3),
(15,32.4),(11,33.5),(10.5,36.9),(8,37),(3,36.8),(-1,35.7),(-5.4,35.9),(-6.8,34),
(-9.8,31.5),(-9.6,30.4),(-11.5,28),(-13,27.5),(-16,23.7),(-17,21),(-16,18),(-16.5,16)

// Eurasia (clipped at 12° N; longitudes past 180 unwrapped)
(-9,43),(-9.5,39),(-9,37),(-6,36.2),(-5.4,36.1),(-2,36.8),(0,38.7),(3,42),(3.2,43.2),
(6,43),(8.5,44.4),(10.5,43.6),(12.5,41.8),(15.6,40.1),(16,38),(17.1,39),(18.5,40.2),
(16,41.5),(13.5,43.6),(12.3,45.4),(13.7,45.6),(19.4,41.9),(21,40),(22.9,36.4),(24,38),
(26,40.3),(29,41),(27.2,37),(30.5,36.8),(36,36.6),(35.6,34.6),(34.5,31.5),(32.3,31.2),
(32.5,29.9),(34.5,28),(35,29.5),(36.5,26),(39,21.5),(42.7,16.5),(43.4,12.7),(45,12.8),
(49,14.5),(52.2,15.6),(55,17),(57.7,18.9),(59.8,22.5),(58.6,23.6),(56.4,26.3),(55.4,25.3),
(52,24),(51.5,25.8),(50.2,26.2),(48,29.4),(50,30),(54,27),(56.4,27.1),(61.5,25.2),
(66.8,24.8),(68.5,23.4),(70,22.5),(72.7,21.2),(72.8,19),(73.7,15.5),(74.6,12.9),(74.9,12),
(80,12),(80.3,13.1),(82.3,17),(85.8,19.8),(87,21.6),(88.5,22),(90.5,22.5),(92,21.3),
(94.2,18),(94.4,16),(95.5,15.8),(97.6,16.5),(98.6,12),(100,12),(100,13.4),(100.9,12.7),
(102.5,12),(109.2,12),(109.3,13.8),(108.8,15.5),(106.5,17.5),(105.8,19),(106.7,20.7),
(108,21.5),(110.3,21),(111.5,21.6),(113.5,22.2),(117,23.5),(119.5,26),(121.9,30.9),
(120.5,33.5),(119.2,35),(122.6,37.4),(119,37.2),(117.7,38.9),(121.5,40.9),(121.3,38.8),
(124.3,40),(125.2,37.7),(126.5,34.5),(129.3,35.1),(129.5,37),(128.3,38.7),(129.8,41),
(130.7,42.3),(133,42.8),(135.5,43.9),(138,46.5),(140.4,48.5),(141.4,52.2),(140,54),
(137,54),(143,59.3),(151,59.5),(155,59),(156.5,57.5),(156.7,51),(160,53),(162.5,56),
(163.5,59.8),(170,60),(177,62.5),(180,65),(190,66),(190.3,66.1),(180,69),(160,70),
(140,72.5),(113,73.7),(104,77.5),(80,73.5),(70,73),(68,68.5),(60,69.5),(44,68.5),
(33,69.3),(20,70),(15,68.5),(5.5,62),(5.5,58.5),(8,58),(10.5,59.4),(12,56),(8.5,57),
(8.6,55),(8.6,53.6),(4.8,52.9),(2,51),(-1.5,49.7),(-4.6,48.5),(-1.2,46),(-1.6,43.4)

// North America (clipped at 12° N)
(-86.8,12),(-83.7,12),(-83.4,15),(-88,15.8),(-87.5,21.5),(-90.5,21),(-91,18.5),
(-94.5,18.3),(-97.5,22),(-97,27.8),(-94,29.7),(-89,30),(-84,30),(-82.5,27.5),(-81,25.2),
(-80.1,26.8),(-81.2,31),(-76,35),(-75.5,38.5),(-74,40.5),(-70,41.5),(-70,43.5),
(-66,44.5),(-65.5,43.5),(-60,46),(-64.5,48.5),(-59,48),(-56,52),(-60,55.5),(-64.5,60.3),
(-70,61),(-78,62.5),(-77,60),(-78,55),(-80,51.5),(-82.5,53),(-87.5,55.5),(-94.5,59),
(-94,61.5),(-88,64),(-87,67),(-95,68),(-110,68),(-125,69.5),(-135,69),(-141,69.7),
(-156.5,71.3),(-166,68.8),(-165,66),(-168,65.6),(-165,64.5),(-162,60),(-158,58.5),
(-163,55),(-158,56.5),(-152,59),(-150,61),(-146,60.5),(-140,59.8),(-136,58.3),(-133,55),
(-130,54),(-128,51),(-124.5,48.5),(-124.5,46),(-124,42),(-122.5,37.8),(-120.5,34.5),
(-117.1,32.5),(-115.8,30.4),(-114.1,28),(-112.2,24.8),(-109.9,22.9),(-110.3,24.2),
(-112.5,27.5),(-114.8,31.5),(-112.2,29.6),(-109.5,26),(-106.4,23.2),(-105.3,20.4),
(-103,18.2),(-99.9,16.8),(-96,15.7),(-94.2,16.1),(-92.2,14.5),(-89.8,13.5),(-87.6,13.1)

// Greenland
(-73,78),(-60,82),(-30,83.5),(-12,81.5),(-18.5,76.5),(-22,70.5),(-32,68),(-40,65),
(-43.3,60),(-48,61),(-53,66),(-54,70),(-58,75.5),(-68,76.5)
// Iceland
(-24,65.5),(-22,66.4),(-16,66.5),(-13.5,65.2),(-15,64.2),(-18.5,63.4),(-22.5,63.8)
// Great Britain
(-5.7,50),(1.4,51.2),(1.7,52.7),(0,53.5),(-1.6,55.6),(-2,57.7),(-4,58.6),(-5,58.6),
(-6.2,56.7),(-4.9,55),(-3,53.3),(-4.7,52.8),(-5.3,51.9),(-3.2,51.4)
// Ireland
(-10,51.6),(-6,52.2),(-6,54.2),(-7.5,55.3),(-10,54.2)
// Japan
(129.6,33.2),(130.5,31),(131.7,31.6),(132,33.7),(133.5,33.2),(134.7,33.9),(136.9,34.2),
(139,34.6),(140.9,35.7),(141,38.3),(142,39.5),(141.4,41.4),(141,41.8),(143.3,41.9),
(145.5,43.3),(145.3,44.3),(141.8,45.5),(140.4,43.3),(140,41.5),(140,40),(139.5,38.2),
(136.8,37.3),(135.4,35.7),(132.5,35.4),(130.9,34.1)
// Taiwan · Hainan · Luzon · Cuba · Hispaniola
(120.1,23),(121,25.2),(121.9,25),(121,22)
(108.7,19.3),(110.6,20.1),(111,19.6),(109.5,18.2)
(120,14.5),(120.6,18.5),(122.2,18.5),(121.6,15.5),(124,13.5),(121,13.6)
(-85,22),(-80,23.2),(-75,20),(-77.5,19.8),(-82,21.5)
(-74.4,19.8),(-68.4,19),(-68.6,18.2),(-74.5,18.3)

// Canadian Arctic: Baffin Island · Devon Island · Ellesmere Island · Victoria Island · Banks Island
(-64.5,61.9),(-65.5,62.9),(-62,66.5),(-63.5,67.5),(-67.5,69.5),(-70,70.6),(-75,72),(-80,73.5),
(-86,73.5),(-89,72.5),(-85,70),(-81.5,69.5),(-82,68.5),(-75,67.2),(-73,66.2),(-77.5,64.9),
(-74,64.4),(-71,62.8),(-68,62.2)
(-80,74.6),(-91,74.6),(-92.5,75.6),(-89,76.6),(-80,76.3)
(-79,76.3),(-74,78.3),(-70,80),(-62,82),(-64,83),(-75,83),(-90,82),(-95,81),(-93,79.5),
(-87,78.5),(-89,77),(-82,76.5)
(-101,69),(-105,68.8),(-110,68.6),(-114,69.3),(-117.5,70.5),(-118.5,71.5),(-114,73.3),
(-108,73.5),(-105,72.6),(-102,71.5),(-100.5,70)
(-125.5,72),(-123,71.2),(-120,71.6),(-119.5,72.6),(-120,74.2),(-124,74.3),(-125.5,73.3)
// Svalbard · Novaya Zemlya · Sakhalin
(11,78.8),(13.5,77.6),(16.5,76.6),(17.5,77.4),(21,77.8),(23,78.4),(27.5,79.8),(25,80.4),
(20,80.5),(17,79.9),(15,79.7),(11,79.7)
(52,71.4),(53.5,70.8),(57,70.6),(55.5,72.5),(57,73.8),(60,75),(64,76.2),(68.5,76.9),(66,77),
(61,76.2),(58,75.5),(55,74.3),(54,73),(53,72.2)
(141.9,46),(143.5,46.5),(143,47.5),(143.5,49.3),(144.5,49),(143.2,51),(143.3,52.5),
(142.8,54.3),(142.2,54.2),(141.7,53.4),(142.1,51.5),(141.8,48.5),(142.1,47.2)

// Water drawn over land: Black Sea, Caspian, Baltic (with the Gulfs of Bothnia, Finland and Riga)
(28,41.5),(28.5,43.5),(30.5,46.5),(33.5,46),(36.6,45.3),(39.5,44),(41.5,41.5),(36,41.7),(32,41.2)
(47.5,45.5),(49.5,46.5),(52.5,45.5),(51,43.5),(53,41.5),(53.5,39),(54,37.3),(50.5,37),
(49,38.5),(49.5,40.5),(47.5,43)
(12.6,56),(14.2,55.4),(18,54.8),(21,55.2),(21.2,56.8),(24,57.2),(22,58.5),(23.5,59.2),(28,59.7),
(30,60),(28,60.5),(24,60.2),(22.5,60.2),(21.5,61),(21.3,63),(24.5,64.8),(25.5,65.3),(22.5,65.9),
(21.4,64.6),(19.5,63.5),(17.5,62.3),(17.2,61),(18.8,60),(18.5,59.4),(16.5,57.8),(16,56.2),
(14.4,56.1),(12.8,56.6)

// Island blocks: Hawaii ×3, Azores ×3, Canaries ×2
(-155.5,19.6),(-157.9,21.4),(-159.5,22.1),(-25.7,37.75),(-28,38.6),(-31.2,39.5),
(-15.5,28.1),(-17,28.4)
```

### 16.3 Shell labels and fixed copy

| where | 1849 | balloon |
|---|---|---|
| title buttons | Sail for California · Continue the voyage of the SHIP · Learn about the passage · See the top ten | Fly round the world · Continue the flight of the [i]SHIP[/i] · Learn about the flight · See the top ten |
| month screen | When will you sail? | "When will you launch?" — "The winds that can carry a balloon round the world blow hardest in the dead of winter. Your balloon is ready in November 1998. When will you launch?" + the five months + "Ask for advice" → "Your meteorologist taps the chart: “The jet is weak in November and starts breaking up in March. Launch in December, January or February, and you'll have it under you most of the way.”" |
| outfit intro | Outfitting | §16.4 |
| travel button | Heave to & take stock | Hold & take stock |
| sea menu | Continue · Check supplies & crew · Look at the chart · Change pace · Change rations · Heave to and rest · Make repairs · Go fishing | Continue the flight · Check supplies & crew · Look at the chart · Change altitude (now: X) · Change rations (now: X) · Loiter low and rest · Make repairs · Trail a fishing line |
| port menu | Weigh anchor · … · Rest ashore · Seek a trade · Talk to people · Buy supplies · Visit the shipyard | Relaunch (25 gal) · Check supplies & crew · Look at the chart · Change altitude · Change rations · Rest on the ground · See who'll trade · Ask around the field · Buy supplies · Visit the riggers |
| rest | 1/2/3/5 days | "Loiter 1 watch" / "2 watches" / "3 watches" / "5 watches" (on the ground: "Rest 1 watch" …); result "After N watch(es) of rest, your crew's health is X." |
| repairs | Mend sails · Patch the hull · Done | "Drop a sack of ballast" → "You cut away a sack of ballast and let the balloon settle at its new height. [green](Lift now N%)[/green]"; "Service the burners" → "The flight engineer strips and cleans the burners one at a time, wearing gloves. [green](Burners now N%)[/green]"; "Done" |
| riggers | shipyard | heading "The riggers"; "Top up the helium ($N)" → "The riggers run a hose from the helium trucks for a whole watch. She stands up tall and tight again."; "Overhaul the burners ($N)" → "A burner man from the ground team fits new jets and valves all round. They roar like new."; "Back" |
| trade | quay | intro "Someone at the edge of the field looks over your stores."; "Nobody else at the field wants to trade with you today."; "You walk the field, but nobody wants what you have."; accept "Done. Goods change hands." |
| supplies screen | | "Altitude: X · Rations: Y" + red "N watches without scrubbers" when > 12; red "Only N of M have down suits."; headings "Crew · health X", "Lost" |
| burial | | red "NAME has died of CAUSE."; **aloft** (flying or loitering): "There is nowhere to bury anyone up here. The crew zips NAME into a sleeping bag and lays it in the coldest corner of the capsule, to carry home."; button "Carry NAME home"; **on the ground at a field**: "The ground team takes NAME home."; button "Say goodbye". Epitaph placeholder "Blue skies, friend." (max 70) in both |
| status panel | | date · region (on the ground: the field's short name, §6) · Weather · Health · Food · Water · Propane · Next stop + nm · "Flown X of 18,300 nm" · "Lift · Burners" · note |

The port menu's "See who'll trade" and "Ask around the field" replace 1849's "Attempt to
trade" and "Talk to people" (review, 2026-11-10: those two, like 1849's ration names and
role screen, sit very close to a famous commercial game's wording). "Talk to the ground
team" was suggested, but only three of the eighteen talk lines (§6) come from your ground
team (four with your meteorologist at Marrakech); the rest are a rigger, a retired airline
captain, a tourist-balloon pilot, a guide, a schoolteacher, two mechanics, a fiesta
organiser, a balloon maker, a doctor, an old balloonist, a reporter, a ranger and a
fisherman — people you meet at the field.

### 16.4 Launch and outfit copy

**Outfit intro** — heading "Outfitting"; "You have [amber]$N[/amber] to fit out the [i]SHIP[/i]. The supply hangar at the launch field has what you need:"
- • [b]Propane[/b] — 12 to 16 gallons a watch, more in the cold. You can lift 1,200 gallons; the Pacific alone can take 900 or more — fill every tank at Saga.
- • [b]Food[/b] — five of you eating well get through 2½ lbs a watch. The flight may take four weeks. The fields along the way sell more, at a markup.
- • [b]Water[/b] — a fifth of a gallon each per watch. In snow you can melt rime off the hatch.
- • [b]CO2 scrubbers[/b] — without them, the air in the capsule goes stale within three days.
- • [b]Down suits[/b] — one per person, or the cold of the jet will kill them.
- • [b]Ballast & burner spares[/b] — the only repairs you can make aloft.
- • [b]Medical kits & fishing line[/b].

Button "Enter the supply hangar". (`[b]` as in the 1849 list in `Copy.swift`.)

**Launch refusal** (food 0 or propane < 25): "The launch director won't let you go: you need food aboard and at least 25 gallons of propane to climb out."

**Launch** (burns 25 gal; `DATE` = `dateOnlyText`, §12.1): "The [i]SHIP[/i] lifts off from the launch field outside Marrakech at 0800 GMT on DATE. The crowd shrinks to a scatter of dots, and the Atlas rises white to the south. Ahead lie eighteen thousand miles of sky." Button "Climb away".

**Relaunch refusal** (on the ground, propane < 25 **and** money ≥ 50 × this field's propane price, §6): "You need at least 25 gallons of propane to relaunch. The ground crew points at the fuel truck."
**Sponsor's top-up** (propane < 25 and money below that; once per landing; propane := 25, then the relaunch burns it): message "The ground-team chief looks at your gauges, then at your wallet, and waves the fuel truck over. “On the sponsor's account,” he says. “Just enough to get you off the ground. After that you're drifting.” [dim](+N gallons.)[/dim]" (N to a tenth: "+0.7 gallons", "+1 gallon") — then the relaunch note, then the out-of-propane warning (§12.2) on the first watch.
**Relaunch** note line: "Relaunched. The climb back to cruising height burned 25 gallons."

---

## 17. Ending & scoring

**Finale** (finish line):
"Finish line! The [i]SHIP[/i] crosses eight degrees west, the meridian of Marrakech, at HHMM GMT on DATE — D days and H hours after you lifted off." (" and H hours" left out when H is 0; `DATE` = `dateOnlyText`, §12.1; HHMM is the watch's GMT time.)
"At the next sunrise you come down on a stony plain outside the city, bounce twice, and stop. Children run out from a village to see what has fallen out of the sky." + (living > 1) "Your crew climbs out, stiff and blinking, and stands on the ground as if it might move." / (one left) "You climb out alone and stand on the ground as if it might move."
Then the score table, rank, "Lost on the flight" list. Buttons "Fly again" / "See the top ten". After the top ten: "Thanks for flying." + "Fly again".

**Game over — lift reaches 0:**
- over a `sea` region: title "The [i]SHIP[/i] has come down in the sea." body "With no lift left, the capsule settles onto the swell and the envelope folds over it like a tent. A freighter answers your mayday and takes everyone aboard. The balloon is lost, and so is the attempt."
- over land: title "The [i]SHIP[/i] has come down." body "With no lift left, you pick the emptiest ground in sight and come down hard in a cloud of dust and torn fabric. Everyone climbs out. The attempt is over."

**Game over — the pilot dies** (title "You, NAME, have died of CAUSE." in every case):
- aloft, with crew still alive: body "Your co-pilot brings the balloon down at the first safe place, and the ground team flies everyone home. The attempt is over."
- aloft, with nobody else left alive (or with health left: whoever the same watch takes is still marked alive when the pilot dies): body "With nobody at the burners, the balloon drifts on alone until it settles, far from anywhere. A search plane finds it two days later. The attempt is over."
- on the ground at a field: body "The ground team packs up the balloon and flies everyone home. The attempt is over."

Game-over footer: "DATE · N nautical miles flown, M short of the finish line." (N = `mile`,
M = 18,300 − `mile`; on a round-the-world route the distance from Marrakech is no measure:
at 17,000 nm flown you are ~1,300 nm from it.) Button "Try again".

**Score** (× role multiplier):

| line | points |
|---|---|
| "N aboard, health X" | survivors × (good 500 / fair 400 / poor 300 / very poor 200) |
| "Lift & burners" | round(lift × 2 + burners) |
| "Propane, food & water" | ⌊propane ÷ 50⌋ + ⌊food ÷ 10⌋ + ⌊water ÷ 50⌋ |
| "Stores & spares" | ⌊scrubbers⌋ + meds × 5 + suits × 2 + spares × 4 + ballast × 3 + ⌊casts ÷ 20⌋ |
| "Cash" | ⌊money ÷ 50⌋ |
| "Bonus for being a ROLE" | ×1 / ×2 / ×3 |

**Stores against cash.** The best last purchase must not be score. At Kitty Hawk, the last
field, one point costs $50 of cash and, of each store: propane (0.45 × 1.45 × 1.1 =
$0.72/gal) $36; food ($4.35/lb) $44; water ($0.73/gal) $36; scrubbers $36; medical kits
$29; down suits $52; burner kits $51; ballast $29; a spool of line $44 — so a dollar spent
on stores there scores 0.96–1.7 times what it scores kept as cash (propane, food and water
1.15–1.4×). 1849 at Callao, its last port: food $4.38 and water $3.50 a point against $5 of
cash (1.1–1.4×), stores 0.6–2.0×. (The first
draft's ÷10 / ÷5 / ÷5 made a point of water cost $3.60 and of propane $7.20, 7–14 times
cheaper than cash: spending leftover money on water at Kitty Hawk padded a chocolate
maker's score by ~4%. Scrubbers ×2 and ballast ×4 were 2.8× and 2.3×; now ×1 and ×3.)

A typical good finish (balance-model winners, §18.4): 2,500 + ~230 + ~15 + ~35 + (chocolate
maker ~135) ≈ 2,920 → chocolate maker ≈ 2,900 (model median 2,918), builder ≈ 4,500 (4,502),
bush pilot ≈ 6,600 (6,588). The spread is 1849's; the ranks below sit on it.

**Ranks:** ≥ 7,000 **Master Aeronaut** · ≥ 4,000 **Balloon Captain** · ≥ 2,000
**Co-pilot** · otherwise **Ballast**. Line under the top ten: "Master Aeronaut 7,000+ ·
Balloon Captain 4,000+ · Co-pilot 2,000+ · Ballast".

**Default top ten** (invented):

| # | name | score |
|---|---|---|
| 1 | Margit Velde | 7,700 |
| 2 | Anselm Kroll | 6,450 |
| 3 | Dolores Quiñones | 5,900 |
| 4 | Tobias Hartnell | 5,150 |
| 5 | Yuki Morisaki | 4,400 |
| 6 | Colm Ferriter | 3,800 |
| 7 | Elodie Marchetti | 3,200 |
| 8 | Rafael Ostrowski | 2,650 |
| 9 | Bettina Lund | 2,000 |
| 10 | Hank Pruett | 1,300 |

---

## 18. Balance targets

### 18.1 Targets (30 seeded flights per role, ±15 pp tolerance as 1849)

| | band |
|---|---|
| chocolate maker | ≥ 85% |
| balloon builder | 45–85% |
| bush pilot | 15–50% |
| median winning flight | 145–180 watches (24–30 days) |

The model (§18.4) puts each role inside its band **without** the tolerance, with room on
both sides, measured over 180 flights per role: chocolate maker 100%, builder 68%, bush
pilot 33%, median 162 watches.

### 18.2 The sensible bot

- **Departure:** December, January or February, by `seed % 3` (the game's own advice).
- **Altitude:** the chocolate maker always Middle air. Builder and bush pilot fly The jet
  when the crew's average hp ≥ 75, the current region is not freezing and propane > 0;
  otherwise Middle air.
- **Rations:** the chocolate maker Hot meals; the others Half portions.
- **Shopping** (Marrakech and every port, after any rest): with W = (nm to the next port or
  the finish) ÷ 90 + 12 watches and n = living crew, buy in this order while money lasts —
  propane to W × 15 + 65 gal (25 relaunch + 40 reserve; capped at 1,200), food to
  n × ration × W, water to n × 0.2 × 1.3 × W, scrubbers to n × 0.02 × W, suits to n,
  meds to 2, burner kits to 2, ballast to 2, and (not the chocolate maker) line to 60 casts.
  Each target rounds up to the item's step, is capped by room, and drops a step at a time
  while over budget (the 1849 bot's rule). At Saga the propane target is 1,200 (W = 77).
- **At a port:** rest 3 watches on the ground if average hp < 70; shop; **then** use the
  riggers if lift < 70 (top up) and if burners < 70 (overhaul), each only if affordable.
  (1849's bot uses the yard before shopping; here supplies come first, because a poor crew
  can patch aloft but can't buy propane aloft.)
- **Relaunch:** always. If, after shopping, propane is under 25 gallons, the bot has
  already bought every step it can afford (the shopping rule drops a step only when it
  can't pay for it), so the relaunch is never refused and the ground team's top-up (§6)
  applies: the bot leaves with an empty tank and flies on under the propane-empty rules.
  (In the model this happened once in 540 flights, to a bush pilot at Kitty Hawk.)
- **Aloft, before each watch:** drop ballast while lift < 40 and ballast remains; then
  service the burners while burners < 40 and kits remain (each one a loitering watch).
- **Fishing:** not the chocolate maker; when food < 12 watches' worth, the region is `sea`,
  the weather isn't rough and line remains: up to 15 casts, each hitting 35% (bush pilot
  55%) a fish drawn by the targets' weights.
- **Always lands** at every port. **Fork:** north or south at random; on the south, hires
  the forecasters only with **more than $1,500** in hand (after shopping at Saga, the fork
  being the next stop). **Himalaya:** stays south. **Date line:** holds the party.
  **Azores:** drops down to meet the boat.
- **Choices:** freighter — fly on; mascot — keep it; thunderheads — go around; ice on the
  envelope — climb (if propane ≥ 40, else ride it out); camera plane — wave off (§13: it
  is no better than that for a poor crew, and worth nothing to the chocolate maker);
  trades — decline.

### 18.3 Worked balance check

**Opening outfit at Marrakech** (leg 1 is 2,200 nm, so W = 2,200 ÷ 90 + 12 = 36.4 watches):

| item | target | bought | chocolate maker | builder / pilot |
|---|---|---|---|---|
| propane | 36.4 × 15 + 65 = 611 | 650 gal | $292.50 | $292.50 |
| food | 5 × 0.5 × 36.4 = 91 (hot meals); 5 × 0.3 × 36.4 = 55 (half) | 100 / 60 lb | $300.00 | $180.00 |
| water | 5 × 0.2 × 1.3 × 36.4 = 47 | 50 gal | $25.00 | $25.00 |
| scrubbers | 5 × 0.02 × 36.4 = 3.6 | 4 | $100.00 | $100.00 |
| down suits | 5 | 5 | $400.00 | $400.00 |
| medical kits | 2 | 2 | $200.00 | $200.00 |
| burner kits | 2 | 2 | $280.00 | $280.00 |
| ballast | 2 | 2 | $120.00 | $120.00 |
| fishing line | 60 casts | 3 spools | — | $90.00 |
| **total** | | | **$1,717.50** | **$1,687.50** |
| **left** | | | **$13,282.50** | builder **$4,562.50**, pilot **$3,312.50** |

The launch burns 25 gal, leaving 625 aboard for a leg that takes about 225.

**Watches and propane per leg** — the balance model's medians (§18.4) for the chocolate
maker, who always flies Middle air: 120 flights (the four standard seed sets 1999, 50000,
90000, 123456), from each relaunch (its 25 gal included) to the next field or the finish:

| leg | nm | region mix (weather factor, §8) | watches (p90) | propane, gal (p90) |
|---|---|---|---|---|
| Marrakech → Luxor | 2,200 | Sahara 0.93 (warm) | 17 (20) | 225 (270) |
| Luxor → Jodhpur | 2,200 | Arabia 0.84 (hot) + Gulf of Oman 0.84 + Indus & Thar 0.84 (warm) | 20 (23) | 250 (291) |
| Jodhpur → Saga | 3,250 | N. India 0.98 + Himalaya 1.07 (freezing) + E. China Sea 1.02 | 24 (28) | 395 (456) |
| Saga → Albuquerque, north | 5,850 | N. Pacific 1.05 (freezing) + NE Pacific 1.04 (cold) + Southwest 0.99 | 54 (62) | 855 (986) |
| Saga → Albuquerque, south | 5,850 | southern 0.88 (warm) + subtropical 0.86 (hot) + Southwest 0.99 | 60 (68) | 799 (936) |
| Albuquerque → Kitty Hawk | 1,500 | Plains 1.04 (cold) | 11 (12) | 169 (200) |
| Kitty Hawk → finish | 3,300 | N. Atlantic 1.01 (cold) + Azores 0.87, and 2 Azores watches | 30 (35) | 435 (500) |
| **total aloft (north)** | 18,300 | | **≈ 156** | **≈ 2,330** (150 of it relaunches) |

Cross-check: watches ≈ nm ÷ (150 × weather factor × condition factor), where the condition
factor is (0.45 + 0.55 × burners/100) × (0.75 + 0.25 × lift/100). Its mean while flying is
**0.82** (0.81 over all roles, 0.86 for the chocolate maker, who pays the riggers at every
field) — not the 0.9 the first draft assumed — and it is lowest exactly where it matters:
**0.75 on the northern Pacific and 0.78 on the southern**, where the jet's rough air wears
the burners and lift fastest. 5,850 ÷ (150 × 1.03 × 0.75) = 50 flying watches, plus the
date-line party and the watches spent dropping ballast and servicing burners ≈ 54. The
first leg gives 2,200 ÷ (150 × 0.93 × 0.86) = 18, against the model's 17.

With ground time (rests, riggers) a whole flight comes to about **155–170 watches**; the
model's median winning flight is 162 (161 for the chocolate maker, 159 for the builder,
169 for the bush pilot).

**The Pacific — the journey's Cape Horn.** Saga → Albuquerque, all roles, the four
standard seed sets (344 crossings; relaunch at Saga included):

| | median | p90 | worst | reserve left in a full 1,200-gal tank (median / p90 / worst) |
|---|---|---|---|---|
| north | 875 gal | 1,000 | 1,108 | 27% / 17% / 8% |
| south | 823 gal | 959 | 1,094 | 31% / 20% / 9% |
| both | 848 gal | 986 | 1,108 | **29% / 18% / 8%** |

A full tank leaves a reserve of about **27% at the median on the northern track and 18% at
the p90** of all crossings; a short fill kills you. A chocolate maker who fills to only 800
gallons at Saga comes down before Albuquerque in 44 of 120 flights; to 700, in 94; to 900,
in 12; to 1,000, in 2; to 1,200, in none. Hence the outfit line "the Pacific alone can take
900 or more — fill every tank at Saga" (§16.4).

**Consumption against capacity and resupply** (chocolate maker, ~160 watches):
- **Propane** ≈ 2,330 gal adding up the leg medians above; the median whole winning flight
  burns 2,460 (chocolate maker), 2,540 (builder) and 2,690 (bush pilot, who flies the jet
  in the cold and loses more watches to repairs). Against a 1,200-gal tank, at least one
  refill is unavoidable, and nonstop is impossible.
- **Food** 2.5 lb/watch × 160 = 400 lb on hot meals (240 lb on half portions) against a
  500-lb cap; bought leg by leg it never comes near the cap.
- **Water** ≈ 1.0 gal/watch × 160 ≈ 160 gal (hot regions add ~20) against a 250-gal cap.
- **Scrubbers** 0.1 canister/watch × ~150 aloft = 15 against 30.
- **Lift** loses ~0.08 × 150 = 12 to leakage and ~67 in all over a winning flight. On the
  Pacific alone: median **28**, p90 **61** for the chocolate maker; over all roles median
  34, p90 76 (north 27 / 48, south 44 / 82 — the south's thunderstorms). Two sacks of
  ballast (40, or 60 for the builder), the sacks bought at Saga and a top-up at Albuquerque
  cover the median; the p90 needs every sack aboard.
- **Burners** wear ~0.5%/watch at Middle air (1%/watch in the jet, far more in rough air);
  20–25 points a leg and more on the Pacific's shear and storms, serviced at ~40%.

**Money over the whole flight** (balance-model means over 180 flights per role, all
flights, the six seed sets of §18.4):

| | chocolate maker | builder | bush pilot |
|---|---|---|---|
| start | 15,000 | 6,250 | 5,000 |
| propane | 1,738 | 1,612 | 1,535 |
| food | 1,915 | 961 | 917 |
| water | 128 | 117 | 116 |
| scrubbers | 594 | 475 | 457 |
| suits | 400 | 400 | 400 |
| medical kits | 534 | 775 | 695 |
| burner kits | 310 | 315 | 320 |
| ballast | 133 | 141 | 141 |
| line | 0 | 91 | 90 |
| riggers: helium | 1,178 | 578 | 62 |
| riggers: burners | 1,136 | 595 | 182 |
| forecasters | 122 | 68 | 0 |
| **spent** | **8,188** | **6,127** | **4,915** |
| left at the finish (winners) | ~6,800 | ~70 | ~10 |

**Why these bands are plausible:**
- The **chocolate maker** never runs short of money, so only bad luck could kill him (his
  own illness, a run of strikes on the southern track); the model never lost one in
  180 flights: ~95–100%.
- The **builder** spends ~$6,130 of a $6,250 purse. Her perk makes ballast and burner kits
  do much of the riggers' work, so she skips about half the rigger bills; she loses when a
  slow Pacific crossing or a rigger bill leaves too little for the last tank of propane at
  Kitty Hawk. In the model 41 of her 57 losses are exactly that — coming down over the
  North Atlantic or off the Azores, out of propane; 14 are the pilot's death and 2 a
  balloon brought down by lift: 68%.
- The **bush pilot** spends ~$4,900 of $5,000 with no margin at all: a rigger bill at Saga
  or a slow southern crossing leaves him unable to fill up for the Atlantic (92 of his 120
  losses are on the last leg, out of propane; 8 are lift lost, 6 of them to the southern
  track's thunderstorms; 2 are propane run dry before Kitty Hawk; 18 are the pilot's
  death). His fishing helps only over the sea, and the bot rarely needs it (1.0 outing a
  flight): 33%. A human who fishes the Pacific and skips the riggers does better.
- **Season:** November costs the builder 10 wins in 60 and the bush pilot 15; March costs
  the chocolate maker 15, the builder 18 and the bush pilot 16 (weak jet → slower → more of
  everything). December–February are identical.
- **Fork:** the north is faster; the south burns slightly less propane (799 gal median
  against 855 for the chocolate maker — the warm air needs less heat) but costs food, water
  and time (60 watches against 54), and its thunderstorms cost lift. With the forecasters,
  the south is nearly as safe as the north for a rich crew (117 of 120 against 120).

### 18.4 Balance-model results

**The model lives in the repository: `Tools/journey-models/balloon_sim.py`** (about 820 lines of
Python, standard library only). `python3 Tools/journey-models/balloon_sim.py report`
prints every table in §18.3–§18.4 in about 30 s; `rates --builder 6500` and similar try
other numbers. It restates §5–§15 and the bot of §18.2 — the 1849 engine's `sailDay` /
`consume` / `health` / `wear` / events / specials / fork, ports and riggers — on a real
calendar (watch 0 = 08:00 GMT on the 1st). The freighter and trades are not taken, as the
bot declines them. Seeds are `base + 1000 × multiplier + i`. Python's random numbers are
not the engine's, so no single flight here matches an engine flight; only the rates should.

Corrected since the first draft (whose model lived in a temporary folder and differed from
the spec in five places): the stash event gives ri(3, 8) lb, not ri(2, 6); the date-line
party burns its 15 gallons; the Azores charges its two loitering watches once (the first
model burned 20 gal and then the loiter rate again); the thunderstorm strike's extra watch
burns at the region's temperature factor; and a relaunch short of 25 gallons follows §6
(the first model let propane go negative). It also now follows every change in this
revision: the Gulf of Oman / Indus & Thar split, the field's ground temperature and ground
sickness pool, the event 2 and 16 conditions, the camera plane's odds, the $250
forecasters and the bot's $1,500 rule, fishing airing the capsule, and the new score.

Win rates, 30 flights per role per seed set:

| | 1999 | 50000 | 90000 | 123456 | 777777 | 31337 | all 180 | band |
|---|---|---|---|---|---|---|---|---|
| chocolate maker | 30/30 | 30/30 | 30/30 | 30/30 | 30/30 | 30/30 | **100%** | ≥ 85% |
| builder | 21/30 | 20/30 | 22/30 | 18/30 | 21/30 | 21/30 | **68%** | 45–85% |
| bush pilot | 10/30 | 9/30 | 11/30 | 10/30 | 9/30 | 11/30 | **33%** | 15–50% |
| median winning flight | 163 w | 164 w | 160 w | 162 w | 160.5 w | 162 w | **162 w** | 145–180 w |

At 30 flights a set, sampling alone moves a rate by about ±8 points (the builder ranges
60–73% here), so the start purses are set from all 180 flights, not one set. Builder purse
(180 flights): $6,000 → 61%, **$6,250 → 68%**, $6,500 → 78%, $7,000 → 85%. Bush pilot:
**$5,000 → 33%**, $5,250 → 44%, $5,500 → 47%. At $6,250 the builder's set-to-set range
(18–22 of 30, 60–73%) stays inside 45–85% untolerated, so this journey should not repeat
1849's D8 (a role above its band, passing only on the tolerance). If the real engine still
puts her above 85%, $6,000 is the next step down.

By departure month (60 flights per role, seeds 777 + i):

| | November | December | January | February | March |
|---|---|---|---|---|---|
| chocolate maker | 60/60 | 60/60 | 60/60 | 60/60 | 45/60 |
| builder | 32/60 | 42/60 | 42/60 | 42/60 | 24/60 |
| bush pilot | 2/60 | 17/60 | 17/60 | 17/60 | 1/60 |

(December, January and February are identical because they share every seasonal rule and
a February flight of the median length lands before March.)

By Pacific track (120 flights per role, seeds 4242 + i, December/January/February in turn,
track forced):

| | north | south, always hires the forecasters | south, never hires | south, bot rule (> $1,500) |
|---|---|---|---|---|
| chocolate maker | 120 | 117 | 108 | 117 |
| builder | 90 | 82 | 84 | 89 |
| bush pilot | 50 | 34 | 43 | 43 |

With the forecasters at the first draft's $500, the "always hires" column was builder 71
and bush pilot 11.

These are a model, not the engine: the real `BalanceSimulationTests` for this journey are
the authority, and these numbers are evidence that the tables are in the right place.

---

## 19. Learn pages

**1. The flight** — heading "The flight"
"In the winter of 1998, nobody had yet flown a balloon around the world. Teams had been trying for twenty years, and many of them ended up in the sea."
"You command a balloon with a sealed capsule and a crew of five. You must buy supplies, keep your crew alive, keep the balloon in the air, and ride the jet stream east until you cross the meridian of Marrakech again. Five fields along the way have a ground team waiting for you, if you choose to land."

**2. Supplies** — heading "Supplies"
"[amber]Propane[/amber] keeps you up. You burn it every watch, flying or not, and more in the cold. Run out, and you sink."
"[amber]Food[/amber] and [amber]water[/amber] run out too. The fields sell more — at a price."
"[amber]CO2 scrubbers[/amber] keep the capsule air fit to breathe. Without them, your crew sickens within days."
"[amber]Down suits[/amber] keep your crew alive in the cold of the jet — one per person."
"[amber]Ballast[/amber] wins back lost lift, and [amber]burner spares[/amber] keep the burners healthy. [amber]Fishing line[/amber] lets you catch food over the sea."

**3. The Pacific** — heading "The Pacific"
"From Japan to America there is nowhere to land, and the crossing can burn 900 gallons of propane. Fill every tank at Saga. Off the coast you must choose: ride the bitter-cold [amber]northern track[/amber] in the core of the jet, or drop to the warmer, slower [amber]southern track[/amber], where the thunderstorms grow."
"Timing matters. The jet is strongest from December to February. Launch in November or March and you'll wallow."
"Height matters too: up in the jet you're fast and save propane, if your crew can stand it."
Button on the last page: "Back to the start"; on the others "Next".

---

## 20. Open questions — what the engine can't express yet

Every generalisation below must leave Around the Horn: 1849 bit-for-bit as it is: each new
parameter has a stated 1849 default, and none adds, removes or reorders a random draw for
1849 (`PrototypeParityTests` and `BalanceSimulationTests` must not move). Where a rule draws
only under a condition (`cond && chance(p)`), the condition is checked first, as in 1849,
so a journey that never meets it never draws.

1. **Watches** (§12.1): `hoursPerTick` (1849: 24) and a start hour (1849: 0) on the
   journey; `dateText` with a GMT time (1849: none) and `dateOnlyText` (1849's `dateText`
   format) for the launch and finale lines; "day N of the flight"; finale/game-over "D days
   and H hours". Rest labels in watches.
2. **Fuel** (the brief's mechanic, specified here): per-watch burn by altitude ×
   temperature factor; loiter burn 10 in `.sea` mode; no burn on the ground; 25 per launch
   and relaunch; the relaunch refusal only when a step of propane is affordable, otherwise
   the sponsor's top-up to 25 (§6, §16.4), so a field can never trap a player; empty →
   speed base 40 and lift −5/watch; two warning flags; the "Climb above the cloud" and
   Himalaya options spend propane; score line includes it. 1849: no fuel item, no relaunch
   cost.
3. **Passage replaces a range of two regions** (7,800–12,599) instead of 1849's single
   Strait region; the landfall mark's text depends on the passage (as 1849's Pacific mark).
4. **Region hazard rolls generalised:** 1849 hard-codes `inStrait` → aground (5.5% / 1.2%
   with pilot) and `horn` → overboard (1.2%). This journey needs `storms` → thunderstorm
   strike (3.5% / 0.8% with forecasters; sets the weather to `storm` for its extra watch)
   and `ice` → roof accident (2%), with their own effects. Proposal: a per-region optional
   hazard {chance, chance with guide, effect id}, checked in region order; the chance is
   drawn only when the region has a hazard, which keeps 1849's draws (`inStrait && chance`,
   then `horn && chance`, then the 11% event) exactly.
5. **Region `sea` flag:** fishing refusal, game-over text, the freighter and camera-plane
   conditions. 1849: every region is sea; its fishing refusal list has no region check.
6. **Per-weather lift damage table** (§9) replaces 1849's code for storm/gale hull damage;
   the altitude and `ice` multipliers are part of it. 1849's table: storm rnd(1, 2.6) ×
   pace (1.6 / 0.7 / 1) × horn 1.5 × strait 0.5; gale rnd(0, 0.8) × (full 1.5) — the same
   draws in the same order.
7. **Money scale:** engine money constants become journey parameters — trade value range
   250–700 (1849: 25–70), "wantable" threshold $250 held value and money ≥ $300 (1849: 25 /
   30), money rounded to 50s with min 50 (1849: 5s), fuel rounded to 10s like food/water,
   line to 20s like tackle; riggers 20 and 15 per point (1849: 2.5 and 1.8); score cash ÷50
   (1849: ÷5), propane ÷50, food ÷10, water ÷50 (1849: food ÷25, water ÷50), scrubbers ×1
   and ballast ×3 (1849: citrus ×2, timber ×4); guide price $250 (1849: $75).
8. **Special-stop effects** beyond 1849's two: a mile jump clamped below the next stop
   (Himalaya), a crew-wide hp change split by suit (Himalaya), a ceremony that also burns
   propane (date line), a landing that resets the preventive counter as 1849's Galápagos
   does (Azores).
9. **Choice-event effects** new to the engine: a choice option disabled by a stock
   (ice-on-the-envelope needs 40 gal), money gained from an event (camera plane), a trade
   offer behind a `passDays` (freighter) with an exclusion list (item 25).
10. **Unused 1849 paths:** stowaway, strange sail/privateers, man-overboard death, the
    Strait pilot (re-skinned as the forecasters). Nobody dies falling out of a balloon in
    this journey; deaths are illness, cold, hunger and thirst.
11. **The bush pilot's perk is barely exercised by the bot** (1.0 outing a flight): it buys
    food leg by leg, so food rarely drops below 12 watches. If the real engine shows the
    pilot below 15%, either let non-chocolate-makers fish whenever they're over the sea in
    fishable weather and food < 24 watches, or raise the pilot's start money to $5,250 or
    $5,500 (model: 44% and 47%). Balance changes are the owner's call.
12. **Time of day (cosmetic, optional):** every line a player reads is now free of dawn,
    dusk, daylight and dark (§12.1). A later pass could choose variants, and a night sky
    (stars, the envelope lit by the burner), by local solar time = GMT hour + longitude ÷
    15, the longitude interpolated from the chart's route (§16.2) — a table the engine would
    then need, which is why this revision removed the words instead.
13. **Spelling of "CO2"**: written without a subscript because the pixel fonts may not have
    "₂". If they do, "CO₂" everywhere.
14. **Role screen, rations and port menu wording.** Every journey writes these in its own
    words, 1849 included (its role screen, ration names and trade row were reworded on
    2026-11-14); this journey's are in §2, §10 and §16.3.
15. **Seasonal weather rules as data.** 1849 hard-codes two rules in `weatherWeights`:
    `south` regions in the southern winter (May–Sep): gale +20, storm +(horn ? 30 : 18),
    cold +15, fair ×0.5, fresh ×0.6; and the North Atlantic (by region id) in Dec–Feb:
    gale +8, storm +5; then the cursed rule (gale +20, storm +15, calm +10). Proposal: a
    journey list of {months, region flag, ordered bumps (key, op, value, optional
    second-flag override)} applied in list order, then the cursed rule from journey data
    (1849: gale/storm/calm; balloon: shear/storm/stalled). 1849's list reproduces its two
    rules, in its order, with the `horn` override for the storm bump; no draws involved.
    This journey's rules (§8) key on the `jet` and `atlantic` flags.
16. **Temperature rules as data.** 1849's `temperature(in:)` hard-codes North Atlantic →
    cold in Nov–Mar and `south` cold → freezing in May–Sep. Proposal: a list of {region
    flag, months, from (optional), to}. 1849: [(northAtlantic, 10–2, any, cold), (south,
    4–8, cold, freezing)] in that order. Balloon: [(`high`, 11–1, cold, freezing),
    (`atlantic`, 10–2, any, cold)]. The southern-winter freezing extra (+1 hp) becomes a
    journey number (1849: 1 when `southernWinter`; balloon: 0).
17. **The weather catch** replaces 1849's rain catch as data: {weathers, ri range, item,
    note}. 1849: {rain, storm}, ri(15, 45) water, "Caught N gallons of rainwater in the
    sails." Balloon: {snow}, ri(2, 6) water, the rime note (§9). It stays in `consume` at
    the same point and draws only when the weather matches and the item is under its cap,
    as 1849's does.
18. **Crew-factor table.** 1849: [≥ 4: 1, 3: 0.85, 2: 0.65, 1: 0.45]; balloon [≥ 3: 1,
    2: 0.9, 1: 0.75]. No draws.
19. **Per-journey thresholds.** Low-food warning and re-arm (1849: 7 and 10 days of need;
    balloon 12 and 18 watches), low water (1849: 5 and 10; balloon 6 and 12), the
    preventive warning's re-arm (1849: > 1 crate; balloon > 1 canister), the spoil roll
    (1849: hull < 35 and food > 50, ri(20, 60) lb; balloon: lift < 35 and food > 20,
    ri(5, 15) lb), and their message texts. The spoil roll's `chance(0.06)` is drawn only
    after both conditions hold, as in 1849.
20. **The polar chart** (§16.2) is app-side only: the chart needs a projection per journey
    (1849: its equirectangular strip; balloon: pole-centred, r = (90 − lat) × 1.25),
    polylines with unwrapped longitudes, water polygons drawn over land, and a route per
    passage. The engine never reads it.
21. **Status text for the place** (§6): when `atPort`, the status panel's region slot and
    the chart's accessibility caption show the field's short name. 1849 shows the region
    even in port (e.g. "Southeast Trades" at Rio) and keeps doing so: a journey flag,
    off for 1849.
22. **`over` after `consume`.** This journey's `consume` can end the game (empty propane,
    lift −5 → 0), so `sailDay` returns, and `passDays` stops, on `state.over` right after
    `consume`, before `health`. 1849's `consume` never sets `over`, so for 1849 the check
    is always false and changes nothing.
23. **The ground is the field** (§6, §11): an optional `Port.temp` (1849: nil → the
    region's temperature, as now) and an optional ground sickness pool for fever-free
    fields (1849: nil → the region's pool, as now). Same single `pick` draw either way.
24. **Relaunch** (§6, §16.4): the port's "leave" action gains a cost and a refusal, and the
    sponsor's top-up. 1849's "Weigh anchor" has neither (journey parameters 0 / off).
25. **`makeOffer(excluding:)`** for the freighter (§13): fuel and ballast are removed from
    both the wantable list and the give candidates before the two picks. 1849 passes an
    empty list: same lists, same draws.
26. **Fishing airs the capsule** (§15): a journey flag that sets the preventive counter to
    0 when an outing ends (1849: off; a fishing trip doesn't cure scurvy).
27. **Death texts by place** (§16.3, §17): the burial text and button, and the
    captain's-death game-over body, choose by on-the-ground / aloft and (for the game over)
    whether anyone else is alive. 1849 has one of each and keeps it.
28. **Event conditions that read the role** for flavour only (event 16's bush pilot
    sentence, as 1849's whaler sentence on the whales): already supported.
29. **Luxor's propane price** stays at mod 0.8 (1.04× Marrakech): the driver's line was
    reworded to "cheaper here than at any field ahead of you", which is true (§6), instead
    of cutting the price to 0.7, which would have moved the balance.

---

## As built

Engine files: `HornEngine/Journeys/Balloon/` (`Balloon.swift` rules and sentences,
`BalloonData.swift` tables, `Balloon+Fields.swift` the six fields, `Balloon+Events.swift`
the region rolls and the seventeen events, `Balloon+Choices.swift` set pieces and answers,
`Balloon+Trouble.swift` lift, burners and propane at nothing). Tests:
`HornEngineTests/BalloonTests.swift` (38 rule tests, 4 balance tests) and
`BalloonBreakdownTests.swift` (16, D14). The title
card, setup, outfit, burial, status and chart copy (§2, §3, §12.1's labels, §15's game,
§16, §19) belong to the skin: `AroundTheHorn/Journeys/BalloonSkin.swift` and the three files
beside it (docs/design/journeys-architecture.md §2, "Balloon skin, as built"). The role
labels are in D11's shape, as 1849's and the other journeys' are: "A Zurich chocolate
maker", "A Bristol balloon builder", "An Alaska bush pilot" (§2's table; text only). The
fields' arrivals (§6) describe the field below her, since "Land at the field" is asked
after them, and the catch report says "1 lb" (text only).

### The numbers as shipped

Everything in §4–§15 and §17 is as written above, with these exceptions:

- **Purses:** chocolate maker $15,000, **balloon builder $7,250** (spec $6,250), **bush
  pilot $6,500** (spec $5,000). The skin's comparison page must say so.
- **Warnings re-arm** at 18 watches of need for food, water and propane alike (the engine
  has one `rearmTicks`; the spec has 18 / 12 / 12).

The rest, as engine `Rules`: watch 4 h from 0800 on the 1st; water 0.2 (0.3 hot); rime
2–6 gal in snow; low food 12, low water 6, low propane 6 watches; freezing −1.6 / −4.5
with no seasonal extra; stale air after 18 watches at 0.006 a watch over, up to 0.12;
lift leak 0.08 a watch flown; sink-and-dump below 35 lift with food over 20, 5–15 lb at
6%; riggers $20 a point of lift and $15 of burners × the field's multiplier; trades $250–700,
wanted at $250 of a good or $300 cash; 11% event chance; rank cuts 7,000 / 4,000 / 2,000.
Propane: altitude 12 / 14 / 16 × temperature 0.85 / 0.95 / 1 / 1.1 / 1.2; 10 × temperature
loitering; nothing on the ground; 25 a launch; a watch without heat (dry, or the burners
given out) → 40 nm base and −5 lift, and the last of the propane heats its share of one
(D14, below).

### The bot, by departure

`JourneyBot` with `BalloonTests.policy()`: the chocolate maker in the middle air and the
other two in the jet while the crew's average health is 75+, the air is not freezing and
the tanks are not dry (else the middle air); hot meals for the chocolate maker, half
portions for the others; at every field, food, half again the table's water, propane at
the altitude's rate and scrubbers, in that order, for nm ÷ (the altitude's speed × 0.6) +
12 watches, where the altitude is the one last flown before landing: nm ÷ 90 + 12 in the
middle air, but nm ÷ 111 + 12 in the jet, which is where a builder or bush pilot usually
lands from after Marrakech (at Saga, for the 5,850 nm to Albuquerque, about 65 watches of
food, scrubbers and propane at 16 gallons, not 77); then five suits,
two each of medical kits, burner kits and ballast, and 60 casts of line for the two
poorer roles; supplies first, then the riggers below 70% if affordable; ballast and
burner kits aloft below 40%; fishing below 12 watches of food over the sea. North or south
at random; the forecasters only with more than $1,500; stays south of the Himalaya, holds
the party, meets the Azores boat, flies on from the freighter, keeps the bear, goes round
thunderheads, climbs out of icing, waves the camera plane off.

Thirty flights a role from seed 500 (the test), then 180 a role over six seed sets (500,
1999, 50000, 90000, 123456, 777777):

| Departure | Chocolate maker | Builder | Bush pilot | Median winning flight |
|---|---|---|---|---|
| November 1998 | 28/30 · 175/180 | 18/30 · 90/180 | 7/30 · 46/180 | 168 watches |
| December 1998 | 30/30 · 180/180 | 24/30 · 126/180 | 17/30 · 87/180 | 160 |
| **January 1999 (tested)** | **30/30 · 180/180 (100%)** | **24/30 · 126/180 (70%)** | **17/30 · 87/180 (48%)** | **160** |
| February 1999 | 30/30 · 180/180 | 24/30 · 126/180 | 17/30 · 87/180 | 160 |
| March 1999 | 23/30 · 144/180 | 11/30 · 62/180 | 2/30 · 27/180 | 181 |

Measured again after D14 (lift, burners and propane at nothing, below): the bush pilot's
January went from 86 to 87 of 180 (16 to 17 of 30 from seed 500), and every other cell
moved by two flights or fewer; the bands held and no number was re-tuned. Before D14 the
table read November 176 / 89 / 46, December to February 180 / 126 / 86, March 146 / 63 /
28.

Measured again after the 2026-11-13 review fixes (offers cut to fit, no water trades, the
Azores boat only in calm air, no camera plane at The jet, the Moroccan coast as land);
the January rates fell from 131 and 90 of 180 to 126 and 86, inside the bands, so no
number was re-tuned.

December, January and February are identical, as §18.4 found: they share every seasonal
rule and a flight ends before March.

Choices, January, 180 flights a role (chocolate maker / builder / bush pilot, median):

| Flown as | Wins | Median |
|---|---|---|
| the bot | 180 / 126 / 87 | 160 |
| always the northern track | 179 / 136 / 94 | 156 |
| always the southern track, forecasters by the $1,500 rule | 179 / 127 / 94 | 164 |
| always the southern track, never the forecasters | 171 / 123 / 84 | 166 |
| middle air all the way | 180 / 136 / 97 | 164 |
| the jet all the way | 180 / 105 / 67 | 140 |
| low and slow all the way | 178 / 65 / 21 | 217 |
| never the riggers | 178 / 163 / 157 | 175 |

(After D14. The southern track without the forecasters gained most, 165 to 171 for the
chocolate maker: a thunderstorm that takes the last of the lift now asks for a propane
cylinder instead of ending the flight.)

How the January losses end (180 a role, after D14): builder 43 down in the sea, 11 the
pilot's death (an infected wound, influenza, hypothermia, frostbite, exhaustion); bush
pilot 74 down in the sea, 3 down on land, 16 the pilot's death (exhaustion, influenza, an
infected wound, hypothermia, a fever, altitude sickness). No bot flight is grounded at a
field: it lands with ballast to buy.
Coming down in the sea is nearly always the Atlantic with dry tanks and no money left
at Kitty Hawk, as §18.3 predicted.

The tests assert the January bands (85–100 / 60–90 / 35–70%) and a median winning flight
of 145–180 watches; that November is at least 10 points and March at least 30 points
harder for the two poorer roles, and March at least 10 watches longer; that flying low
all the way is at least 20 points worse for them; and that the losses of the two poorer
roles end at least three ways, at least one of them coming down and at least two of them
the pilot's death by different causes.

### Departures from the spec, and why

1. **The bands.** This build was asked for 85–100 / 60–90 / 35–70%, not §18.1's ≥85 /
   45–85 / 15–50%. At the spec's purses the engine's bot (in the middle air) won 30, 15
   and 4 of 30 January flights; the purses were raised until the 180-flight rates sat
   mid-band. The rate
   moves about 3 points per $100 for both poorer roles (builder $7,000 → 71%, $7,500 → 83%;
   pilot $6,000 → 38%, $7,000 → 67%, measured with the middle-air bot).
2. **The bot** is the shared `JourneyBot`, which gained three knobs, each off by default so
   rail and the airship fly exactly as before: `yardAfterShop` (§18.2's supplies before the
   riggers), `stockFactor` (water × 1.5 for the hot legs; buying only the table's ration
   left crews dying of thirst on the southern track) and `choosePace` (§18.2's altitude rule). It flies one
   departure (January) rather than December–February by seed; it buys propane for the
   leg's watches at the altitude's rate rather than W × 15 + 65, and has no special 1,200 at
   Saga (W is 77 there, which buys about 1,080). It buys in the shared bot's order, food,
   water, propane, scrubbers, not §18.2's propane first; and it works W out from the
   altitude it last flew, so a crew landing from the jet stocks for nm ÷ 111 + 12 watches,
   not nm ÷ 90 + 12. The bands above were measured with the bot as coded.
3. **Propane** is built on the shared fuel rule. `noFuelSpeed` is 1; `adjustSpeed` records
   the tank at the start of the watch, sets the 40-nm drift when it is dry, and otherwise
   leaves the tank holding what makes the shared deduction come out at the altitude's
   gallons × the temperature factor (or empty, when the watch empties it). Loitering burns
   in `tick`. The dry-tank lift loss is taken in `tick`, after health and wear, not inside
   `consume` before health, so the shared `consume` needs no change. The two propane
   warnings come from the shared rule and are said only on a watch flown, not loitering.
4. **Launch and relaunch** use two new shared hooks, no-ops by default: `mayDepart` (the
   launch director's refusal reads `text.noProvisions`, which names both food and the 25
   gallons) and `leaving` (called by `depart`, and by `setSail` only when leaving the
   ground; the app also calls `setSail` to resume between fields, which costs nothing).
   `setSail` cannot refuse, so the relaunch refusal is `Balloon.relaunchRefusal(_:)`,
   for the app to ask before relaunching; without it the ground team's top-up applies.
   The relaunch note and the ground team's words are said on the first watch after.
   On dead burners there is no climb (D17): `leaving` burns nothing and puts nothing in,
   and the first watch begins with "[red]She goes up on dead burners.[/red] The ground team
   walks her into the wind and lets go, and she rises off the field on the helium alone,
   burning nothing. She will climb no higher than that, and she is already sinking." (and,
   with a burner kit aboard, "The crew can fit a burner kit now that she is up.").
5. **Coming down** has its title by place through a new hook, `Journey.wreckedTitle`
   ("…has come down in the sea." / "…has come down."), and the pilot's death its body by
   place and company through `Journey.leaderDiedBody`. Both default to the old text.
6. **Fishing airs the capsule** through a new hook, `Journey.foraged`, called when the
   catch is stowed and before the watch passes.
7. **The freighter's offer** uses `makeOffer(excluding:)`, the shared offer with goods left
   out before the draws (§20.25); an empty list is the old offer.
8. **The date line** keeps the log's GMT: "January 5, 1999, 1600 GMT" (the shared date
   with a comma, not §12.1's "·"), through the shared hook `Journey.hourText`, whose
   default ("4 p.m.") rail and the airship keep. It was first built with the shared
   "4 p.m.", which read as the time where she was while the scene darkens by the local
   sun (at Albuquerque, "8 a.m." over a night sky); D17. The status box, the arrivals
   ("You have reached …"), the graves and the game-over footer all write it so. The
   launch and the finale print the hour themselves, "0800 GMT" and "HHMM GMT", as written.
   The finale's lines and the game-over footer are `Balloon.finale(_:)` and
   `Balloon.shortfall(_:)`, for the skin.
9. **Stop types:** the Himalaya and the date line are `.line`, the edge of the Pacific
   `.fork`, the Azores `.island`; the landfall is a mark whose sentence `arrive` chooses
   by track.
10. **Injuries** from a parted load cable, the iced roof and the Azores net open no medical
    kit (as 1849's Galápagos does not), and the roof leaves anyone at 1 health at worst.
11. **Two event messages say what was found**: "+1 burner kit." and "+N lbs of rations."
    in green.
12. **Going round the thunderheads with dry tanks** costs the 5 lift a consumed watch
    would.
13. **Skies:** jet streak `.breeze`, stalled `.still`, hot sun `.heat`, in cloud `.fog`,
    rough air `.gale`, snow `.snow`, thunderstorm `.storm`, dust `.dust`. Only the stalled
    air has a status note, as §9 gives only that one.
14. **Trades fit the room** (review, 2026-11-13). A new shared hook, `Journey.fitOffer`,
    has the last word on a drawn offer after every draw; its default returns the offer as
    drawn, so 1849, rail and the airship trade as before. The balloon's cuts an offer that
    gives more than there is room for down to the room left, in whole trading units, and
    what is wanted by the same share (never more than first asked); no room for one unit,
    no offer. Water is left out of `tradeKeys` altogether (§5), which also settles the
    freighter: no ton of water comes up a trail line.
15. **Morocco is land** (review, 2026-11-13): the last region, "The Azores & home", is
    split at the coast, 18,225 nm, into "Past the Azores" (sea) and "Morocco & home" (no
    tags), so nothing over Morocco fishes, meets the freighter or comes down in the sea.
16. **Smaller review fixes, 2026-11-13:** `relaunchRefusal` is nil aloft (the app also
    calls `setSail` to resume between fields); the sponsor's top-up counts gallons to a
    tenth; when the pilot's death comes in a watch that also leaves everyone else at 0
    health, nobody is left to land the balloon (the shared `deaths` stops at the pilot, so
    `leaderDiedBody` asks who still has health); the finale leaves out "and 0 hours"; the
    Azores boat needs calm air; the camera plane does not come at The jet; the Himalaya
    set piece holds the jet rather than climbing into it when you are already there; and no
    sentence promises a hundred knots (the fastest watch the tables allow is 308 nm, about
    77 knots).

### Lift, burners and propane at nothing (D14)

Reported from play on the Iron Road ("you can go below 0 for the health of the train ... I
ran out of cord and it seemed to be still moving just fine"), and checked here
(`HornEngineTests/BalloonBreakdownTests.swift`). Before this, nothing was stored below 0 or
shown as "-0" (the Himalaya's cold took health below 0 for an instant, clamped before the
deaths were counted), and dry tanks were already a crisis (§12.2: a 40-nm drift and −5 lift
a watch), but:

- the damage reports gave the event's whole number past what the meter had ("Lift −35%"
  from a storm at 12%, "Burners −18%" with the burners at 3%);
- burners at 0% drove her at 45% of her speed (the shared floor) and burnt full propane;
- lift that showed 0% (under half a point) flew on as normal, and lift at nothing brought
  her down at once with ballast aboard, though the ending says "no lift left";
- the last gallon of propane flew a whole watch, and cost no lift;
- a burner could cough and die with the tanks dry or the burners dead, and the climbs over
  the Himalaya and out of icing cloud could be made on dead burners.

The rules now (`Balloon+Trouble.swift`):

- **A meter that shows 0% has given out**, as the status panel rounds it (`jsRound`), as on
  the Iron Road and Over the Pole. Every lift and burner loss goes through `knock`: never
  past nought, and the red note gives the drop the panel will show, or nothing when it
  shows none.
- **Burners given out**: no heat for the cone. She drifts and sinks exactly as with dry
  tanks (40 nm base × the weather, burners, lift and crew; −5 lift a watch, flying or
  loitering) and burns no propane (`Journey.fuelBurn` answers 0). The crew is told once:
  "[red]The burners have given out.[/red] Every jet is fouled and every igniter dead. Until
  a burner kit goes into them, or a field's burner man gets at them, there is no heat for
  the cone: the balloon drifts on the helium alone, and sinks." The watch's note reads "The
  burners are dead. The balloon is sinking." A burner kit aloft (+25, the builder +35, one
  watch) or the field's burner man puts her right for the next watch. A drift makes some
  way, and the sinking always ends in the question below, so there is no softlock.
- **The last of the propane** heats its share of the watch (5 gallons of a warm watch's
  13.3 in the middle air: 0.38 of it) and she drifts and sinks the rest: the speed is that
  share of a powered watch and the rest of a drift, the lift loss the rest of 5, and the
  note "The burners sputter out partway through the watch. The balloon is sinking." The
  engine's `rules.burnsPartLoad` is left false (its blend is of the powered speed and
  `noFuelSpeed`, and a drift is not a fraction of the powered speed), so `adjustSpeed`
  blends the two itself. Every other watch that burns goes the same way: loitering, the
  storm's lost watch, the detour round the thunderheads and the date-line party each cost
  their unheated share of 5 lift (the storm's watch and the party cost nothing dry before).
- **Lift gone**: she is going down (`rules.wearWrecks` is false, so the shared wear no
  longer ends the flight). Before she flies another watch (`Journey.stalled`), or at once
  when the watch, event or answer that took the last of it is done, she is asked what goes
  over the side: "Cut away a sack of ballast" (as the repair: +20, the builder +30, one
  watch) or "Cut away a propane cylinder: 50 gallons" (+10 lift, one watch, dropped over
  empty sea or empty country; what it costs is three or four watches of propane later).
  Over a field she has reached and not landed at, a third offer, "Come down on the field at
  Saga" (or wherever), lands her to its ground team, whose store sells ballast and whose
  riggers sell helium. With nothing to cut away and no field she comes down for good, as
  §17 has it (both bodies now begin "With no lift left and nothing more to throw over the
  side"); over a field without the price of a sack the attempt ends "Grounded at Saga."
  Nothing else happens on a watch she is going down: no event, no storm. A set piece
  reached on that watch (the Himalaya, the fork, the date line, the Azores, a mark) comes
  after the question; a field or the finish comes first. A rest that takes the last of the
  lift asks once, and the rest of the rest passes as asked (`passDays` cannot stop early
  without a shared change). On the ground with no lift and no ballast aboard,
  `Balloon.relaunchRefusal` answers "The launch director won't let you go up with no lift
  in her. A sack of ballast from the store, or the riggers' helium, first." when she can
  pay for a sack there; when she cannot, she goes up, is asked, and is grounded.
- **Burner trouble needs burners**: number two burner coughing needs them lit (not given
  out, and propane aboard), the lightning-welded valve needs them not given out, and so do
  the climb over the Himalaya and the climb out of icing cloud, besides their propane.
- **The relaunch needs burners too** (D17): on the ground with the burners given out,
  `Balloon.relaunchRefusal` answers "The launch director won't let you go up on dead
  burners. The riggers' burner man can overhaul them first." when she can pay the riggers'
  overhaul there (lift comes first, as the condition box lists it, D15). When she cannot,
  she goes up on the helium alone: `leaving` burns none of the 25 gallons and the ground
  team puts none in, and the first watch begins by saying so, before the drift's note
  ("The burners are dead. The balloon is sinking."). Burner kits stay a repair made aloft,
  as the outfitting list says, so a crew with a kit and short of the overhaul fits it on
  the first watch up. Before this, the relaunch burned its 25 gallons through dead burners
  and the note saying so was overwritten by the sinking note. The bot's flights are as
  they were (the tables above).
- **Crew health**: the Himalaya's cold is floored at 0 as it is taken; nothing else here
  takes health without a floor (`hurt` leaves 1).

**What the skin must show** (all of it is built: `BalloonSkin.trouble`, the supplies note
and the altitude screen, `BalloonScene.flame` and `cold`, the learn page "Propane, lift
and burners", and `Words.leaveRefusal`, which the port menu's way out asks):

- the red status row, `Words.trouble` = ("Balloon", …): "Going down" aloft and "No lift"
  on the ground, where she has come down to a field's ground team (`Balloon.goingDown`);
  "Burners dead, tanks dry", or "Burners dead, sinking" aloft and
  "Burners dead" on the ground (`Balloon.burnersOut`); "Tanks dry, sinking" aloft and
  "Tanks dry" on the ground; "Last of the propane" (`Balloon.lastOfThePropane`: less than
  `Balloon.watchBurn`, a watch flown at this altitude in this air); nothing before the
  launch;
- the supplies note adds "the burners are dead" and "the tanks are dry", and the altitude
  screen, aloft, says that with no heat the height makes no difference to how far she
  drifts (it still sets the cold and the crew's health). On the ground it says what she
  will climb to, and on dead burners that she cannot ("She is on the ground. When she goes
  up, she will climb to Middle air. Not on dead burners: she can only go up on the helium,
  and drift."); the relaunch row reads "Relaunch (on the helium alone)" then, not "(25
  gallons)";
- the scene draws dead burners as it draws dry tanks, with no flame (§4's blast window,
  0.6 × burners/60 s, is already nothing at 0%), and the low-lift sag (lift below 40)
  already covers going down;
- the learn page says what lift and the burners at nothing do;
- before relaunching from a field, ask `Balloon.relaunchRefusal` (it now refuses for lift
  and for dead burners as well as for propane).

Tuning: none was needed; the bands hold untouched (the bot tables above are after D14).

### Things worth knowing

- **The riggers are a trap for a poor crew.** Ballast at $60 a sack gives 20 or 30 points
  of lift; the riggers charge $20–32 a point. A builder or bush pilot who never hires them
  wins 91% and 87% of January flights; the bands above are measured with the spec's bot,
  which hires them below 70% when it can pay. If that is too generous to a careful player,
  the rigger prices, not the purses, are the lever. With the riggers kept for money to
  spare (a $1,000 reserve), the bush pilot's rate is very steep in his purse: $5,000 → 20%,
  $5,500 → 63%.
- **The southern track is no worse for a poor crew** in the engine: its warm air burns less
  propane, which is what a short purse runs out of. Without the forecasters the chocolate
  maker loses a few flights to its thunderstorms.
- **The jet all the way** is the fastest flight (140 watches) and the worst for the
  poorer roles: the cold and the −1 health a watch kill pilots.
- Seed 500's builder wins 24 of 30; over 180 flights it is 70%.
