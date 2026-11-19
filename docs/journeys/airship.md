# Journey `airship` — Over the Pole: 1926

Content specification, following the template in `docs/design/journeys-brief.md`. Every number
an engineer needs is here; every sentence a player reads is written out in full. Text in
`“…”` blocks and in **Text:** lines is player-facing and uses the 1849 markup (`[red]…[/red]`,
`[green]`, `[amber]`, `[dim]`, `[i]`). `NAME`, `SHIP`, `N`, `DATE` etc. are substitutions;
player-entered names go through `TextMarkup.escape` exactly as in 1849.

Where this journey needs something the 1849 engine does not do, it is flagged **[NEW]** and
listed again in §20.

---

## 1. Pitch

**Title:** Over the Pole: 1926
**Top bar:** `OVER THE POLE · 1926`
**Title screen:** `OVER` / `THE POLE`, `~ 1926 ~`, and under it:
“Nine thousand six hundred kilometres from Rome to Nome, over the top of the world.”

**Premise.** It is the spring of 1926. Aeroplanes and airships have both crossed the
Atlantic, but nobody has crossed the top of the world. You have bought a small semi-rigid
airship from the works outside Rome, signed on a crew of five, and promised your backers you
will fly her north from mooring mast to mooring mast as far as Spitsbergen, then over the
North Pole and the unmapped ice beyond it to Nome, Alaska. Lift is precious. Petrol is
life. And between the last mast at Kings Bay and the first roof in Alaska
there are four thousand kilometres of ice.

| | |
|---|---|
| Period | April–July 1926 |
| Start | The Ciampino airship station, Rome |
| Destination | Nome, Alaska |
| Total distance | **9,600 km** (unit: kilometres, “km”) |
| Target length | median **~85 watches** (about 14 days); winning flights 65–105 watches |
| The “day” | **One watch of four hours** — see below |

**Why the turn is a watch, not a day [NEW].** An airship crosses in days what a ship crosses
in months: the real transpolar flight of 1926 took 72 hours from Spitsbergen to Alaska. With a
day as the turn, the whole journey would be about ten turns, and the systems that make the
1849 game (illness, consumption, weather, events) would never get going. Airship crews stood
four-hour watches, as ships' crews did, so the turn is one watch. Every per-day number in
1849 becomes a per-watch number here, re-tuned for a game of ~85 turns (§12, §18). The
calendar advances four hours a turn:

- Turn 0 is **08:00 on the 1st of the departure month**. After `t` turns the time is
  08:00 + 4t hours.
- The date line reads `May 3, 1926 · 1600` (the date, then the 24-hour time the current watch
  began, four digits). This replaces 1849's `dateText` wherever it appears.
- Seasonal rules use the month of the current date, as in 1849.
- Anywhere 1849 says “N days”, this journey says “N watches”. The finale gives both:
  “after N watches (D days) in the air”, where `D = round(N × 4 / 24)`.

**Departure months** (the month screen): April 1926, May 1926, June 1926, July 1926
(`(1926, 3)`, `(1926, 4)`, `(1926, 5)`, `(1926, 6)`, 0-based months).

---

## 2. Roles

| id | Menu label | Start money | Score × | Perk |
|---|---|---|---|---|
| `financier` | A New York financier | **$1,200** | ×1 | — |
| `engineer` | An engineer from the airship works at Rome | **$580** | ×2 | Repairs aloft: a bag of ballast restores **+35** lift (others +20); a box of engine spares restores **+40** engines (others +25) |
| `meteorologist` | A meteorologist trained at Bergen | **$470** | ×3 | Pilot balloons: hit padding **4** px (others 1.5); can use **900 kg** of winds per session (others 450) |

`title` (as in “Bonus for being a ___”, “an” before the engineer): `financier`, `engineer`, `meteorologist`.

**Role screen** (in this journey's own words, D11). Heading “Who are you?”, then:
“A flight to the Pole in 1926 took money, nerve or know-how, and seldom all three at once. Which
do you bring?” — the three roles, then *What does each one bring?*:

> **What each one brings**
> An airship burns money by the tonne, and only one of these three has much of it.
> [amber]Financier[/amber] — starts with $1,200.
> [amber]Airship engineer[/amber] — starts with $580. Gets far more out of every bag of ballast and every box of engine spares.
> [amber]Meteorologist[/amber] — starts with $470. Reads the winds aloft like a morning paper: a surer eye with a pilot balloon, and twice the petrol's worth of winds from every session.
> The leaner the purse, the more a landing at Nome is worth: the engineer's counts double, the meteorologist's triple.

Button: *Back*.

---

## 3. Crew

**First names (30)** — placeholders for the captain and four crew, and the stowaway pool:

Arne, Ingrid, Sigurd, Solveig, Olav, Astrid, Leif, Margit, Emilio, Rosa, Natale, Lucia,
Renato, Elena, Walter, Edith, Harold, Dorothy, Clarence, Mildred, Ellis, Hazel, Ruben, Greta,
Tor, Helga, Vittorio, Bianca, Finn, Karin

Stowaway fallback name (if every name is taken): `Finn`.

**Airship names (13):** Polar Star, Northern Light, Aurora, Snow Goose, Kittiwake,
Midnight Sun, Borealis, Silver Gull, Ice Petrel, True North, Northward, Fulmar, Skylark

**Names screen** labels: “Name your airship:”, “Your name, Captain:”, “Your four crew
members:”. Max lengths as 1849 (ship 22, people 16). Buttons *Use these names* / *Pick new
names for me*.

---

## 4. Vehicle

| Meter | Name | Role |
|---|---|---|
| Structural (0 ends the game) | **Lift** | Gas and trim. Leaks, ice and lost gas take it down; ballast and fresh gas bring it back. At 0 she is forced down. |
| Propulsion (low slows you) | **Engines** | Two engines (one car is drawn; its twin is behind it). Wear, ice and breakdowns take it down; spares and an overhaul bring it back. |

Status panel row: `Lift · Engines   82% · 64%` (replaces `Hull · Sails`). A new row
`Petrol   5,400 kg` sits under `Water` **[NEW]**.

Speed uses them exactly as 1849 uses hull and sails:
`× (0.45 + 0.55 × engines/100) × (0.75 + 0.25 × lift/100)`.

### Scene sprite (32 × 14 cells, nose to the right)

```
"  ff                            "
"  ffff     hhhhhhhhhhhhhhh      "
"   ffffhhhhhhhhhhhhhhhhhhhhhh   "
"   ffeeeeeeeeeeeeeeeeeeeeeeeeee "
"    eeeeeeeeeeeeeeeeeeeeeeeeeeen"
"fffrrrrrrrrrrrrrrrrrrrrrrrrrrrrn"
"    eeeeeeeeeeeeeeeeeeeeeeeeeeen"
"   ffeeeeeeeeeeeeeeeeeeeeeeeeee "
"   ffffdddddddddddddddddddddd   "
"  ffff     ddddddddddddddd      "
"  ff      p k k      k   k      "
"          pmmmmm   gwgwgwgwg    "
"          p mmm     ggggggg     "
"          p                     "
```

| char | colour | what |
|---|---|---|
| `h` | `#EEF1F4` | sunlit top of the envelope |
| `e` | `#C8CDD3` | envelope (doped fabric) |
| `d` | `#8C939C` | envelope underside, in shadow |
| `r` | `#D64545` | painted band along the envelope |
| `f` | `#A7AEB7` | tail fins |
| `n` | `#6B6F76` | nose cone and mooring fitting |
| `k` | `#4B4F55` | struts and suspension wires |
| `g` | `#6B4A2B` | control car (gondola) |
| `w` | `#F2D16B` | gondola windows |
| `m` | `#3A3F47` | engine car |
| `p` | `#DCE3EA` | pusher propeller (behind the engine car) |

**Placement.** Flying: x = 44, y = 14, bobbing with `sin(t)` as the 1849 ship does. The ship
**flies lower as lift falls** [NEW, art only]: add `round((100 − lift) / 10)` px to y (0–10 px).
At a mast: x = 98, y = 18, nose touching the mast head (§16).

**The “torn sails” of this vehicle.** When engines < 60, skip propeller (`p`) pixels where
`((col*7 + row*13) % 37) < (60 − engines)/2.2` — the propeller stutters. When engines < 40,
also draw a two-pixel grey puff (`#8F8A7A`) behind the engine car at (col 8, row 11), drifting
left 1 px per 0.3 s and fading after 6 px. When petrol is 0 (drifting), draw no propeller
pixels at all. In icing fog, draw every `h` pixel as `#FFFFFF` (rime).

---

## 5. Supplies

Nine items. Prices are at Rome; port price = `base × port.mult × (port.mod[item] ?? 1)`.

| key | engine role | name | unit (one) | step | per | base price | max held | description (shop) |
|---|---|---|---|---|---|---|---|---|
| `food` | food | Provisions | kg (kg) | 10 | 1 | $0.50 / kg | 300 | Pemmican, biscuit, chocolate, tinned soup. Each hand eats 0.1–0.3 kg a watch. |
| `water` | water | Drinking water | litres (litre) | 20 | 1 | $0.05 / litre | 300 | About 0.6 litre per person per watch, in cans along the keel. |
| `coffee` | deficiency preventive | Coffee & cocoa | tins (tin) | 1 | 1 | $4 | 20 | Kept hot in vacuum flasks, it keeps the watch awake. A tin lasts five people about ten watches. |
| `meds` | medicine | Medicine | kits (kit) | 1 | 1 | $15 | 10 | Aspirin, iodine, bandages, burn ointment. One kit per illness halves its harm. |
| `furs` | warmth | Fur flying suits | suits (suit) | 1 | 1 | $18 | 8 | Reindeer-skin suits and fur boots. One per soul aboard, or the polar cold will kill them. |
| `spares` | repair-propulsion | Engine spares | boxes (box) | 1 | 1 | $22 | 10 | Plugs, valves, magneto parts and a spare propeller blade, for repairs aloft. |
| `ballast` | repair-structure | Water ballast | bags (bag) | 1 | 1 | $8 | 16 | A hundred kilos of water and alcohol, so it won't freeze. Drop a bag and she rises. |
| `balloons` | forage | Pilot balloons | boxes (box) | 1 | **10** | $4 | 30 (300 balloons) | Small red balloons for reading the winds aloft. Each box is 10 balloons. |
| `fuel` | fuel [NEW] | Petrol | kg (kg) | 100 | 1 | $0.02 / kg | 8,000 | Airships reckon petrol by weight. Cruising, she burns 250 kg a watch. |

`coffee` is stored as a Double (fractional use), like citrus. `balloons` are stored as
balloons, like tackle is stored as throws (a box is 10).

**Trade values** (1849's `VAL`, per stored unit): food 0.7, water 0.06, coffee 4, meds 15,
furs 18, spares 22, ballast 8, balloons 0.4 (per balloon), fuel 0.025, money 1.
**Trade rounding:** food and water to 10s (min 10), balloons to 10s (min 10), petrol to 100s
(min 100), money to 5s (min 5), everything else whole units (min 1).

**`describe` strings:** “120 kg of provisions”, “40 litres of water”, “2 tins of coffee”,
“1 medicine kit” / “2 medicine kits”, “1 fur suit” / “2 fur suits”, “1 box of engine spares” /
“2 boxes of engine spares”, “1 bag of ballast” / “3 bags of ballast”, “2 boxes of pilot
balloons” (balloons ÷ 10, “box” when 10; a count that is not a whole number of boxes is
given in balloons: “85 pilot balloons”, “1 pilot balloon”), “400 kg of petrol”, “$45”.

**Shop extras.** Away from Rome: “Prices here are N% above Rome, more or less.” Leaving Rome
needs provisions and petrol aboard (§12).

---

## 6. Ports (mooring masts)

Five masts. Each visit: `tradesLeft = 3`, `talkIndex = 0`, as 1849.

| id | name (status / chart) | “You have reached ___” | shop name | mult | mods | disease risk |
|---|---|---|---|---|---|---|
| `rome` | Rome | — (start) | The stores at the Ciampino airship works | 1.00 | — | no |
| `pulham` | Pulham | the air station at Pulham, England | The air station stores at Pulham | 1.20 | petrol 0.9, furs 1.5, coffee 1.4 | no |
| `oslo` | Oslo | the Ekeberg mast at Oslo | A ship chandler below Ekeberg hill | 1.30 | furs 0.8 | no |
| `vadso` | Vadsø | the mast at Vadsø | The general store at Vadsø | 1.45 | furs 0.7, provisions 0.9, petrol 1.1 | no |
| `kingsbay` | Kings Bay | Kings Bay, Spitsbergen | The mining company store at Kings Bay | 1.70 | petrol 1.1, ballast 0.8 | **yes** (influenza in the camp) |

Resulting petrol price per kg: Rome $0.020, Pulham $0.0216, Oslo $0.026, Vadsø $0.0319,
Kings Bay $0.0374.

**Arrival prompt** (replaces 1849's): “You have reached NAME.\n[dim]DATE · watch N[/dim]”,
then the arrival paragraph, options *Moor at the mast and go ashore* / *Fly on without
stopping*. A stowaway leaving here adds: “\n\n[dim]NAME waves goodbye from the foot of the
mast.[/dim]”

### Rome — the Ciampino airship station (start; no arrival paragraph)
Talk:
1. A rigger coiling a trail rope: “Nothing north of here is cheaper than it is in Rome, so buy what you can before you go. And buy the fur suits. Whatever you think the cold is like up there, it's worse.”
2. An old balloonist on a bench outside the shed: “Leave in May. Before that the Arctic is iron-hard; after June the fog comes down on the ice and stays there. In May the sun never sets up north and you can see where you're going.”
3. The works doctor: “Coffee, Captain. Strong, hot, and every watch. Men who haven't slept in two days start making mistakes, and in an airship a mistake is a long way down.”

### Pulham, England
Arrival: “Two enormous sheds rise out of the flat Norfolk fields, and beside them stands a steel mast as tall as a church spire. A ground crew of two hundred men runs out across the grass to catch your ropes.”
Talk:
1. A ground-crew sergeant: “Petrol we've got, at a fair price. Coffee you'll pay through the nose for. This is tea country, Captain.”
2. A navigator from the station: “Over the North Sea the wind backs and freshens without warning. Watch your drift, and don't trust the coast of Norway to be where the chart says until you can see it.”
3. A rigger at the mast head: “Mind your gas when the sun's on her. She warms up, the gas swells, the valves let it go — and come evening you're heavy and wondering where it went.”

### Oslo — the Ekeberg mast
Arrival: “Half the city has climbed Ekeberg hill to see you. The mast stands on the heights above the fjord, and when the ship swings to the wind, the whole crowd sways with her.”
Talk:
1. A ski-maker in the crowd: “Buy your furs here, not in England. We have winter eight months of the year. We know what keeps a person warm.”
2. An old ice-pilot: “North of the Circle the fog lies on the sea like wool on a sheep. You'll fly blind for hours. Trust your compass and your clock, and nothing else.”
3. A newspaperman: “Every paper in Europe wants your story. We'll print it whether you tell it to us or not, so you may as well tell us and get the names right.”

### Vadsø
Arrival: “Vadsø is a fishing town of wooden houses on the Varanger Fjord, almost at the top of Norway. The mast stands alone on a bare island across the harbour, and the gulls have already claimed it.”
Talk:
1. The storekeeper: “Fill every tank you have. Petrol at Kings Bay comes by ship, and they charge you for the voyage.”
2. A reindeer herder selling skins: “Reindeer hide. The hairs are hollow — the cold can't get through. Your city wool is for summer.”
3. A fisherman mending nets: “Out over the Barents Sea the weather turns in an hour. If you see fog coming, climb over it — or be ready to wear it as ice.”

### Kings Bay, Spitsbergen
Arrival: “A coal-mining settlement at the edge of the world: a pier, a few dozen huts, a mountain of coal, and a hangar of timber and canvas thirty metres high. Ice still fills half the fjord. Beyond the glaciers there is nothing but the pack, all the way to Alaska.”
Talk:
1. A mechanic from an aeroplane party: “We'll fly to the Pole and back before your engines are warm. Of course, we have to come back. You don't.”
2. The camp doctor: “There's influenza in the bunkhouses. Don't let your crew sleep ashore any longer than they have to.”
3. The mast foreman: “Last mast between here and anywhere. Whatever you leave here, you'll do without until Alaska.”

---

## 7. Stops

| idx | id | type | km | short name | “You have reached ___” |
|---|---|---|---|---|---|
| 0 | `rome` | port | 0 | Rome | — |
| 1 | `rhone` | mark | 650 | Rhône Valley | the Rhône valley |
| 2 | `pulham` | port | 1,700 | Pulham | the air station at Pulham, England |
| 3 | `oslo` | port | 2,750 | Oslo | the Ekeberg mast at Oslo |
| 4 | `circle` | special (`line`) | 3,650 | Arctic Circle | the Arctic Circle |
| 5 | `vadso` | port | 4,200 | Vadsø | the mast at Vadsø |
| 6 | `bear` | mark | 4,800 | Bear Island | Bear Island |
| 7 | `kingsbay` | port | 5,300 | Kings Bay | Kings Bay, Spitsbergen |
| 8 | `pole` | fork | 6,550 | North Pole | the North Pole |
| 9 | `barrow` | special (`island`) | 8,600 | Point Barrow | Point Barrow |
| 10 | `wales` | mark | 9,430 | Cape Prince of Wales | Cape Prince of Wales |
| 11 | `nome` | end | 9,600 | Nome | Nome |

Kings Bay → Nome is 4,300 km with no mast: the polar leap. Point Barrow (8,600) is the only
help on the way.

---

## 8. Regions

By km, `to` exclusive. Weights are **ordered lists** (order is data, as in 1849). Flags:
`sea` (open water below — the steamer and the fishing boat can appear), `north` (seasonal
rules apply), `pack` (sea ice below, at least when it freezes: the fog-to-the-ice event), `superheat` (extra lift loss per flying watch), `iceMult` (multiplies icing
damage to lift), `ridges` (the per-watch hazard of §14).

| to | id | name | temp | flags | weights |
|---|---|---|---|---|---|
| 650 | `med` | Mediterranean | warm | sea | fair 35, tail 15, head 18, rain 12, fog 6, gale 6, storm 4 |
| 1,700 | `france` | France | cool | — | fair 28, head 22, tail 14, rain 18, fog 10, gale 5, storm 3 |
| 2,750 | `northSea` | North Sea | cool | sea | fair 20, head 20, tail 14, rain 14, fog 18, gale 14 |
| 4,200 | `scandinavia` | Scandinavia | cold | north | fair 26, head 16, tail 14, snow 18, fog 10, gale 10, ice 6 |
| 5,300 | `barents` | Barents Sea | cold | north, sea, pack | fog 24, fair 16, head 14, tail 10, snow 14, gale 12, ice 10 |
| 6,550 | `polarSea` | The Polar Sea | freezing | north, pack | fair 24, fog 20, tail 12, head 12, snow 12, ice 12, gale 8 |
| 8,600 | *(the fork's region — below)* | | | | |
| ∞ | `alaska` | Alaskan Coast | cold | north, pack | fog 20, gale 18, head 16, ice 10, snow 10, fair 16, tail 10 |

**The fork's regions** (6,550 ≤ km < 8,600, chosen at the Pole; 1849's Strait replacement
generalised to two routes):

| route | id | name | temp | flags | weights |
|---|---|---|---|---|---|
| high | `aboveFog` | Above the Fog | freezing | north, pack, superheat 0.6 | fair 26, tail 10, head 26, snow 6, fog 8, ice 4, gale 12 |
| low | `underFog` | Under the Fog | cold | north, pack, iceMult 1.5, ridges | fog 30, ice 20, fair 12, head 10, snow 10, tail 8, gale 8 |

(Until the fork is resolved, km 6,550 is never flown, so no default is needed; use
`aboveFog` if one is required.)

### Seasonal rules (month of the current date)

Weather adjustments, applied in this order (a key the region lacks is appended, as in 1849):

1. **April** (month 3), `north` regions: snow +12, gale +8, fog ×0.5, ice ×0.6.
2. **June** (month 5), `north` regions: fog +10, ice +6.
3. **July** (month 6), `north` regions: fog +18, ice +12, fair ×0.6, head +8, tail ×0.5.
4. **June–July**, Mediterranean and France: storm +4.
5. Cursed weather does not exist on this journey (no albatross).

Effective temperature (`tempAt`):
- **April**, `north` region with temp `cold` → `freezing` (the late-winter cold).
- **July**, `north` region with temp `freezing` → `cold` (the polar summer).
- No other changes. There is no extra hp penalty on top (1849's southern-winter −1 is not used).

Average weather speed (May), for reference: Mediterranean 0.87, France 0.85, North Sea 0.81,
Scandinavia 0.82, Barents 0.76, Polar Sea 0.80, Above the Fog 0.76, Under the Fog 0.73,
Alaskan Coast 0.74.

---

## 9. Weather

Nine kinds. `harsh` is hp lost per flying watch. “Lift extra” is added to the lift lost in
`wear()` (§12) on a flying watch.

| key | display | speed × | engine wear × | harsh | lift extra | note (teal) |
|---|---|---|---|---|---|---|
| `fair` | Fair & clear | 1.00 | 0.5 | 0 | — | — |
| `tail` | Following wind | 1.30 | 0.5 | 0 | — | — |
| `head` | Headwind | 0.60 | 1.0 | 0 | — | “The engines roar and the ground below barely moves.” |
| `rain` | Rain | 0.85 | 0.6 | 0 | — (rain is caught, §12) | — |
| `fog` | Fog | 0.70 | 0.3 | 0 | — | — |
| `snow` | Snow | 0.75 | 1.0 | 0 | `rnd(0, 0.5)` | — |
| `ice` | Icing fog | 0.55 | 1.8 | 0.6 | `rnd(1, 3) × pace factor × region iceMult` | “Ice is forming on the struts and the propellers.” |
| `gale` | Gale | 0.45 | 2.0 | 0.8 | `rnd(0, 0.8) × (full speed 1.5)` | — |
| `storm` | THUNDERSTORM | 0.35 | 3.0 | 1.5 | `rnd(1, 2.6) × pace factor` | — |

Pace factor: full speed 1.6, economical 0.7, cruising 1. `rough` = gale or storm (refusals,
events). The status panel shows the weather **red** for `storm` and `ice`.

### Scene palettes

The sky is 8 banded steps from `top` to `bottom` above the horizon (y = 58, §16). The ground
colours come from the region (§16); `ground ×` darkens them. `clouds` = cloud count, `cloud`
= cloud colour.

| key | top | bottom | ground × | clouds / colour | effects |
|---|---|---|---|---|---|
| fair | `#2D5F9A` | `#9FD0EE` | 1.00 | 1 / `#F4F7FA` | sun `#FFE27A` |
| tail | `#2A5C98` | `#A8D8F0` | 1.00 | 2 / `#F4F7FA` | sun; 4 wind streaks (`#E9F4FB`, 6×1 px) racing left at 3× scroll |
| head | `#3A5F8A` | `#9DB9D0` | 0.95 | 3 / `#E1E8EE` | clouds scroll at 2× (the ship labours) |
| rain | `#3E4A5A` | `#7D8A98` | 0.75 | 3 / `#6B7685` | rain |
| fog | `#8D969E` | `#C5CBD0` | 0.80 | 0 | fog overlay |
| snow | `#55606E` | `#A6B2BF` | 0.85 | 3 / `#8C97A3` | snow |
| ice | `#7F8C96` | `#B9C4CC` | 0.70 | 0 | fog overlay; rime on the sprite (§4) |
| gale | `#33404F` | `#6E7D8D` | 0.70 | 3 / `#55616F` | sprite bob ×2; ground detail jitters |
| storm | `#15191F` | `#3A434F` | 0.50 | 3 / `#2C333D` | rain; lightning flashes |

**Midnight sun.** In `north` regions, a sun is drawn low, at (126, 44), instead of high.

---

## 10. Pace & rations

| Pace | km / watch | hp / watch | engine wear × | petrol kg / watch | description |
|---|---|---|---|---|---|
| Economical | 190 | +0.5 | 0.6 | 150 | One engine turning. Easy on everything, and on the petrol. |
| Cruising (default) | 250 | 0 | 1 | 250 | Both engines at cruising revolutions. |
| Full speed | 310 | −1 | 2 | 420 | Both engines flat out. Fast, loud, thirsty and hard on the crew. |

Menu label: *Change speed (now: Cruising)*.

| Rations | kg / person / watch | hp / watch | description |
|---|---|---|---|
| Full rations (default) | 0.3 | +1 | 0.3 kg a watch. Soup, biscuit and chocolate. |
| Short rations | 0.2 | −0.3 | 0.2 kg a watch. Nobody is full. |
| Pemmican only | 0.1 | −2.2 | 0.1 kg a watch. Chew slowly. |

---

## 11. Ailments

Durations are in watches. Damage per watch; halved when treated.

| name (“NAME has ___.”) | dmg / watch | duration | cause of death (“died of ___”) |
|---|---|---|---|
| watch fatigue | 2.2 | until cured (deficiency) | exhaustion |
| frostbite | 2.5 | 5–9 | frostbite |
| pneumonia | 4.5 | 6–10 | pneumonia |
| influenza | 4.5 | 5–9 | influenza |
| a fever | 3 | 4–7 | a fever |
| fume sickness | 3.5 | 2–4 | fume poisoning |
| snow blindness | 1.2 | 6–12 | exposure |
| airsickness | 1.5 | 3–5 | exhaustion |
| a broken arm | 1.2 | 14–24 | an infected wound |

**Pools** (`sicken`): at Kings Bay (the disease mast): influenza, a fever, pneumonia.
Cold or freezing: frostbite, pneumonia, snow blindness, influenza, a broken arm.
Otherwise (warm, cool, hot): airsickness, fume sickness, a fever, influenza, a broken arm.

**Messages.** As 1849 (“NAME has AILMENT.”, “[dim]You open a medicine kit (N left).[/dim]”,
“NAME is well again.”), except the deficiency:
- Onset: “NAME has watch fatigue. [dim]Red eyes, slow hands, asleep on their feet. Hot coffee or a night at a mast will cure it.[/dim]” (no medicine kit is used, as with scurvy).
- Cure: “NAME is wide awake again.”

---

## 12. Daily rules (per watch)

Everything not listed runs exactly as 1849's `sailDay` / `consume` / `health` / `wear` /
`passDays`, with “day” read as “watch”. Modes: `sail` = flying, `sea` = **aloft with the
engines stopped** (rest, repairs, pilot balloons), `port` = moored at a mast.

### One flying watch (`sailDay`)
1. Clear `note`; watch += 1; roll the weather for the region.
2. **Petrol [NEW].** If petrol ≥ the pace's burn: petrol −= burn. If 0 < petrol < burn: the
   watch is still powered and petrol becomes 0. If petrol was already 0: **drifting**.
3. **Speed.** Powered: `pace.km × weather.speed × (0.45 + 0.55 × engines/100) × (0.75 + 0.25
   × lift/100) × crewFactor × rnd(0.85, 1.15)`, rounded with `jsRound`, min 0. crewFactor as
   1849 (≥4 → 1, 3 → .85, 2 → .65, 1 → .45). There is no route speed factor.
   Drifting: `60 × weather.speed × (0.75 + 0.25 × lift/100) × rnd(0.85, 1.15)` — no pace, no
   engines, no crew factor. (She rides whatever wind blows toward the coast; abstraction.)
   Clamp to the next stop and mark arrival, as 1849.
4. Notes: the weather's note (§9); drifting overrides it with “Engines silent. You are going
   where the wind goes.”; a rain catch overrides both.
5. `consume(.sail)`, `health(.sail)`; stop if over. `wear()`; stop if over.
6. If not arrived, at most one of, in order:
   - Under the Fog (`ridges`): **4%** (1% with the forecasts) the ridge strike (§14).
   - Else **15%** a random event (§13).
7. If arrived: stopIndex += 1, queue the arrival.

### Consumption (`consume`)
- Food: `n × rations.kg`. Short → food = 0, starving.
- Water: `n × 0.6` litres (`× 1.5` in a hot region — none on this route). Short → water = 0, thirst.
- Coffee: at a mast → `noCoffee = 0`. Else if coffee > 0 → coffee −= `n × 0.02`, `noCoffee = 0`. Else `noCoffee += 1`.
- Rain: not at a mast and weather is rain or storm, water below max → catch **6–18 litres**.
  Note: “Rain runs off the envelope into the water cans: N litres.”
- One-time warnings (re-armed as in 1849, “10 watches” for “10 days”):
  - out of food: “[red]The provisions are gone![/red] The crew is starving.”
  - food < 7 watches: “The steward warns you: provisions will last about a day.”
  - water dry: “[red]The water cans are dry![/red] Without water, the crew will not last long.”
  - water < 5 watches: “The water cans are nearly empty — a few watches left.”
  - coffee gone (not at a mast): “The last of the coffee is gone. Within a couple of days the crew will be asleep on their feet.” (re-armed when coffee > 1)
- **Petrol warnings [NEW]** (flying watches only; re-armed when petrol > 10 watches' burn):
  - petrol < 5 × burn: “[amber]The engineer chalks a number on the tank: petrol for about five more watches.[/amber]”
  - petrol reaches 0: “[red]The tanks are dry![/red] The engines cough and stop. She is a free balloon now, going where the wind goes.”

### Health (`health`) — differences from 1849
- Mode bonuses unchanged: aloft-resting +3, at a mast +6. Pace hp and weather harsh as §9–10.
- **Starving −4, thirst −6** per watch (1849: −7, −12 per day). A watch is a sixth of a day;
  the 1849 numbers would kill in eight hours. Thirst still kills in ~2–3 days.
- Cold: freezing → −(suit 1.4 / none 4.5); cold → −(suit 0 / none 2.2); hot → −0.4. No
  seasonal extra. “Suit” = `i < furs` among the living, as 1849's woolens.
- New illness: `p = 0.006 + (100 − hp) × 0.0005`; pemmican-only +0.005; starving +0.03;
  thirst +0.04; hot +0.003; cold or freezing without a suit and not at a mast +0.01; at
  Kings Bay +0.012; at any mast ×0.7.
- Deficiency: if not at a mast and `noCoffee > 12`, roll watch fatigue at
  `min(0.12, (noCoffee − 12) × 0.01)` (1849: >35 days, ×0.004).
- Watch fatigue cures with probability **0.35** per watch if coffee > 0, **0.6** at a mast.
- Other ailments: `ailDays −= (mast 2 / aloft-resting 1.5 / flying 1)`.
- Deaths as 1849. Captain's death → game over (§17). Others → burial (§17).

### Wear (`wear`) — flying watches only
- Engines: `engines −= pace.wear × weather.engineWear × rnd(0.6, 1.4)`; **no engine wear
  while drifting**.
- Lift: `lift −= 0.15` (gas seeps through the cells) **+ the weather's lift extra (§9) + the
  region's superheat (0.6 above the fog)**. Clamp at 0.
- **Heavy ship [NEW]** (replaces “seawater spoils provisions”): lift < 35 and petrol > 300 →
  6%: dump 100–250 kg of petrol. “She is too heavy to hold her height. The engineer opens
  the dump valve and N kg of petrol goes over the side to keep her up.”
- Warnings: lift < 30 (re-arm above 50): “[red]She is heavy and sinking by the stern.[/red]
  Drop ballast or find gas — soon.” Engines < 25 (re-arm above 50): “[red]The engines are
  failing.[/red] They miss, smoke and overheat. Fit spares if you have any.”
- Lift ≤ 0 → forced down (§17).

### Not flying (`passDays`)
As 1849: per watch, watch += 1; aloft the weather is rolled, at a mast it is fair; consume;
health. **No movement, no petrol, no wear, no events.** Each repair, mast job and pilot-balloon
session costs 1 watch. Rest choices aloft and at a mast: **1, 3, 6, 12 watches**
(“Stop the engines and rest” / “Rest at the mast”), message “After N watch(es) of rest, your
crew's health is HEALTH.”

### Repairs aloft (1849's “Make repairs”)
- *Drop a bag of ballast* (1 bag): lift += 20 (engineer 35), max 100; 1 watch.
  “The rigger slits a ballast bag and a hundred kilos of water rain down on the world below. She rises at once. [green](Lift now N%)[/green]”
- *Fit engine spares* (1 box): engines += 25 (engineer 40), max 100; 1 watch.
  “The mechanics work all watch, half out in the slipstream, with frozen fingers and a box of spares. [green](Engines now N%)[/green]”
- *Done*.

### At a mast (1849's shipyard: “Visit the gas plant and the mechanics”)
- *Top up the gas ($X)*: `ceil((100 − lift) × 3.0 × mult)`, lift → 100, 1 watch.
  “Hydrogen hisses in from the cylinders all watch. She rides high and light again.”
- *Overhaul the engines ($Y)*: `ceil((100 − engines) × 2.0 × mult)`, engines → 100, 1 watch.
  “The station mechanics strip both engines to the last nut and put them back better than new.”

### Departure from Rome
Requires provisions > 0 **and** petrol > 0. Refusals:
- “You can't cast off with no provisions! The storekeeper shakes his head and points you back inside.”
- “You can't cast off with empty tanks! The storekeeper shakes his head and points you back inside.”

Departure message: “On DATE, the [i]SHIP[/i] slips the mast at Ciampino. The ground crew lets go the lines, the engines take up their roar, and Rome shrinks to a smudge of domes and umbrella pines. Ahead lie nine thousand six hundred kilometres, most of them cold.”

---

## 13. Random events

Eligible list, weighted pick, as 1849. Rolled on 15% of flying watches (after the ridge
check). Names are escaped. “Healthy” = alive with no ailment.

| # | weight | condition | effect | text |
|---|---|---|---|---|
| 1 | 6 | food > 40 | food −= `jsRound(food × rnd(0.05, 0.14))` | “A crate of provisions slides off the catwalk and punches straight through the keel fabric. N kg of provisions are somewhere below you now.” |
| 2 | 5 | water > 40 | water −= 6–18 | “A water can has worked loose and split its seam on a girder. N litres drip away into the keel.” |
| 3 | 4 | `sea` region and weather fair, tail or head | food += 8–25 | “A fishing boat below hails you. You drop low and lower a line, and they send up a basket of fresh fish with their compliments. +N kg of provisions.” |
| 4 | 3 | always | 50%: spares +1. Else 60%: food +10–25. Else a nameboard (flavour; name = a random **1849 ship name** from `GameData.shipNames`) | spares: “Stowing the gear, the rigger finds a box of engine spares that someone had labelled SOAP. +1 box of engine spares.” · food: “A forgotten sack of biscuit and chocolate turns up behind the water cans. +N kg of provisions.” · flavour, `north`: “Far below, the hulk of an old ship lies frozen into the ice, her name still on her stern: [i]X[/i]. Nobody says much for the rest of the watch.” · flavour, elsewhere: “Far below, the hulk of an old ship lies abandoned on a beach, her name still on her stern: [i]X[/i]. Nobody says much for the rest of the watch.” |
| 5 | 6 | rough or headwind | engines −12…28 | “The port engine coughs, backfires and stops. A mechanic climbs out along the strut into the slipstream to coax it back to life. [red](Engines −N%)[/red]” |
| 6 | 4 | rough or icing fog | engines −15, lift −6; 50%: a random healthy crew member gets a broken arm (14–24 watches) and −10 hp; check forced down | “Ice builds on the propellers and flies off like shrapnel. A chunk rips through the envelope and into the gas cell behind it. [red](Engines −15%, Lift −6%)[/red]” + “\n\nNAME was struck by flying ice and has a broken arm.” |
| 7 | 4 | always | lift −8…18; check forced down | “A gas valve has stuck half open. By the time the rigger has climbed up inside the envelope and freed it, a great deal of gas has gone. [red](Lift −N%)[/red]” |
| 8 | 3 | rough, snow or icing fog | a random non-captain: 65% rescued (hp −25, min 1); else lost (grave cause “a fall”, epitaph “Lost from the ship. No grave but the sky.”) | rescued: “In the gusts, NAME loses footing on the ladder to the engine car! The safety line holds, and the crew hauls NAME back inside, shaking.” · lost: “In the gusts, NAME loses footing on the ladder to the engine car. [red]The safety line parts, and NAME is gone.[/red] There was no going back for them.” |
| 9 | 1.5 | always | lift −4, engines −6; check forced down | “Fire! A backfire sets oily rags alight in the engine car. The mechanic smothers it with a coat — and this close to the hydrogen, nobody breathes until it is out. [red](Lift −4%, Engines −6%)[/red]” |
| 10 | 2 | rain or storm | engines −18 | “A flash and a bang: lightning has struck the ship. By some mercy the hydrogen does not catch, but the magnetos on both engines are scorched. [red](Engines −18%)[/red]” |
| 11 | 2.5 | `sea` region | **Steamer** (choice) | below |
| 12 | 1.5 | not yet seen, watch < 9 | **Stowaway** (choice) | below |
| 13 | 2 | `north`, 4,200 ≤ km < 8,600, not yet seen | **Distress flares** (choice; 1849's albatross slot) | below |
| 14 | 5 | engines running (not drifting, petrol > 0), `pack` region, and temp freezing or 5,300 < km < 8,600 | **Fog to the ice** (choice; 1849's icebergs slot) | below |
| 15 | 2 | always | flavour | `north`: “A ring of light surrounds the sun, with two bright mock suns burning on either side of it. The crew crowds to the windows.” + meteorologist: “ You fill three pages of your notebook.” · `sea`: “Far below, a fishing fleet has stopped work to watch you pass. The crews wave their caps from every deck until you are out of sight.” · elsewhere: “Far below, a whole village has come out to watch you pass. Children run along the road beneath you, waving, until they are left behind.” |
| 16 | 1.5 | rough | `forceFair = 2` | “The barometer jumps five millibars in an hour. Your navigator grins: the worst of the blow is behind you.” |
| 17 | 4 | petrol > 500 and temp cold or freezing | petrol −150…400 | “A petrol line cracks in the cold. Petrol sprays along the keel before the mechanic can shut it off. N kg are lost. For once, nobody needs telling not to smoke.” |
| 18 | 2 | not yet seen, engines running (not drifting, petrol > 0) | **Newspaper** (choice) | below |

### Choice events

**Steamer.**
Prompt: “A steamer below is flashing her signal lamp at you: [amber]CAN TRADE. LOWER A LINE.[/amber]”
Options: *Drop low and lower a line* / *Fly on*.
- Line, 65%: `makeOffer()` → trade screen, intro “Her master sends up a list of what he'll swap.” If no offer: “She is a collier bound north with nothing to spare but good wishes. Her crew waves their caps as you climb away.”
- Line, 35%: lift −6…14, check forced down: “You drop too low. Hot air from her funnel throws the ship about, and the gondola dips into a wave top before you claw back up. [red](Lift −N%)[/red]”
- Fly on: “You fly on. Her lamp blinks something after you that the navigator declines to translate.”

**Stowaway** (random unused first name).
Prompt: “A pair of boots is sticking out from behind the petrol tanks. They belong to NAME, an apprentice from the ground crew at Rome, who wants to see the top of the world more than anything in it.”
Options: *Sign them on as a hand* / *Put them off at Pulham*.
- Sign on: new crew member at 85 hp; **lift −3** [NEW]: “NAME grins and gets to work. One more hand — and seventy kilos more to lift. [red](Lift −3%)[/red]”
- Put off: joins with `leaveAt = "pulham"`: “NAME will work for the ride as far as Pulham.” (Removed on arrival at Pulham, §6. As in 1849, the condition makes a later stowaway impossible.)

**Distress flares** (`flaresSeen = true` when raised).
Prompt: “Red flares rise from the ice ahead. A small expedition ship lies crushed between the floes, and her crew stands beside her on the ice, waving.”
Options: *Come down and drop what you can spare (1 watch)* / *Fly on*.
- Come down: one watch passes aloft (`sea` consume + health); food −15 (min 0); if meds > 0, meds −1; every living crew member hp +6 (max 100). Then 70%: `forceFair = 2`:
  “You lower a sack of provisions[ and a medicine kit] on a line. The castaways cheer, and their skipper chalks a message on a board and holds it up: GLASS RISING. CLEAR WEATHER AHEAD. Your crew climbs away grinning. [green](Crew spirits rise.)[/green]”
  Else 30%: lift −8, check forced down:
  “You lower a sack of provisions[ and a medicine kit] on a line. But hovering so low, a gust slams the ship down and the gondola bounces across a pressure ridge before you can climb. [red](Lift −8%)[/red] The castaways are still waving as you go.”
  (“[ and a medicine kit]” only when a kit was given.)
- Fly on: “You fly on. The flares fall behind you. Nobody aboard says anything for a long time.”

**Fog to the ice** (`murk` = weather is neither fog nor icing fog).
Prompt: “The fog has come right down to the ice. Somewhere below, pressure ridges stand as high as houses, and the trail rope is bumping over them.” (`murk`: “Low cloud has come right down to the ice. …” — same sentence otherwise.)
Options: *Climb out of it and wait for a clear patch* / *Hold your height and keep a sharp lookout*.
- Climb: watch += 1, petrol −= pace burn (min 0), `consume(.sail)`, `health(.sail)`; 10%: lift −6…12.
  “You lose a watch circling above the murk, and climbing in the cold has cost you gas. [red](Lift −N%)[/red]” / “You lose a watch circling above the murk, but find a clear patch and come down safely beyond it.” (Messages go first, as 1849's icebergs.) Check forced down.
- Hold: risk = (fog or icing fog 0.25 / else 0.12) + (full speed 0.15). Hit: lift −18…35, check forced down:
  “A jolt runs through the whole ship — the gondola has struck a pressure ridge! [red](Lift −N%)[/red]” Miss: “You hold on with your heart in your mouth. Grey shapes of ice slide past below, close enough to touch.”

**Newspaper** (`newsSeen = true` when raised). `$N` = 40–90 rounded to 5.
Prompt: “The wireless crackles. A newspaper in New York offers $N for photographs, if you will circle and take them.”
Options: *Circle for the photographs (2 watches)* / *Decline*.
- Circle: money += N; petrol −= 2 × pace burn (min 0); then `passDays(2, .sea)`.
  “You circle while the photographer leans out of the window with the camera. The paper wires its thanks, and $N. [red](Petrol −X kg)[/red]”
- Decline: “You decline. The paper wires back that it will print a drawing instead.”

---

## 14. Landmarks & fork

**Rhône valley** (mark, 650, where the Mediterranean ends):
“You cross the coast at the mouth of the Rhône and turn north up its valley. The mistral comes funnelling down between the hills to meet you, and the mechanics frown at their gauges.”

**Arctic Circle** (special, 1849's Equator, 3,650):
Prompt: “You are crossing the Arctic Circle!”
Detail: “Somewhere below, invisible among the forests, runs the line beyond which the midsummer sun never sets. By the custom of the air service, nobody crosses it for the first time without a toast and a speech.”
Options: *Hold a celebration (1 watch)* / *No time for speeches*.
- Celebrate: watch += 1 (no consume/health, as 1849), food −3 (min 0), every living crew member hp +8 (max 100):
  “The cook produces a cake from nowhere. There are speeches, a toast in hot cocoa, and a song nobody knows all the words to. Spirits are high. [green](Crew health improves.)[/green]”
- No time: “The old hands grumble, and fly on.”

**Bear Island** (mark, 4,800):
“Bear Island slides past to the west: a black wedge of cliffs streaked with snow, with a cloud of seabirds around it. After this there is nothing below but the Barents Sea, all the way to Spitsbergen.”

**The North Pole** (fork, 6,550):
Prompt: “You are at the North Pole!” + April: “ [red]The cold up here is iron-hard.[/red]” / July: “ [red]The summer fog lies thick on the ice ahead.[/red]”
Detail: “Every direction is south. The flags go over the side on their weighted staffs and stick upright in the snow. Ahead lie two thousand kilometres of ice that nobody has ever seen. You may [amber]climb above the fog[/amber] into clear, bitter air, or [amber]stay low under it[/amber], where it is warmer but the fog turns to ice on everything it touches.” In a month when
the two heights are equally cold (April, July) the last clause reads instead “where it is no
warmer at this time of year and the fog turns to ice on everything it touches.”
Options: *Climb above the fog* / *Stay low, under the fog* / *Ask the navigator's advice*.
- Above → `route = .high` (region `aboveFog`):
  “You climb into clear air. The fog lies below you like a white sea, and the sun circles the sky without setting. Up here the sun warms the gas by day and the cold takes it back by night.”
- Under → `route = .low` (region `underFog`), then the forecast offer (1849's pilot):
  Prompt: “The wireless station at Kings Bay offers to send you a forecast of the fog's height every watch, for $60.”
  Detail: “[dim]You have $X.[/dim]”
  Options: *Pay for the forecasts ($60)* (disabled if money < 60) / *Fly by your own eyes*.
  - Pay: money −60, `forecasts = true`: “The first report comes through within the hour: fog base one hundred and fifty metres, lowering. Your navigator pins it above the chart table.”
  - Own eyes: “You trust your lookouts and your trail rope. The fog closes over the top of the envelope.”
- Advice → message, then the fork again:
  “Your navigator taps the barometer: “Above the fog it's clear and cold, and the sun will cook a little gas out of her every watch — so carry ballast. Under it, it's warmer, but the fog freezes on everything, and there are ridges down there you won't see until you hit them. If you go low, pay for the forecasts.”” In April and July “Under it, it's warmer, but” reads
  “Under it, it's no warmer this time of year, and”.

**Ridge strike** (Under the Fog, 4% per flying watch, 1% with forecasts — 1849's aground):
lift −10…22; watch += 1 (no consume/health, as 1849); check forced down.
“Out of the fog a pressure ridge rears up under the bow. The trail rope snags, the gondola thumps across the ice, and it takes a whole watch to get her trimmed and aloft again. [red](Lift −N%)[/red]”

**Point Barrow** (special, 1849's Galápagos, 8,600):
Prompt: high route: “You let her down through the fog bank, and there below, at last, is land: you are over Point Barrow, the northernmost point of Alaska!” · low route: “The fog thins, the ice gives way to brown tundra, and there is land: you are over Point Barrow, the northernmost point of Alaska!”
Detail: “The whole village has run out onto the ice, waving. There is a trading post, and an aviators' camp with petrol hauled in by sled. If you come down low, they can hold the ship on her lines while you take on what they can spare.”
Options: *Come down and take on supplies (2 watches)* / *Fly on*.
- Come down: petrol +200–500, food +10–25, water +30–60 (each capped), `noCoffee = 0`, watch fatigue cured for everyone; then 15%: a healthy non-captain gets a broken arm (14–22 watches); then two watches aloft (`sea` consume + health, weather not rolled, as 1849's Galápagos).
  “The villagers take your lines and walk the ship down to the ice like a great kite. You take on P kg of petrol, F kg of dried fish and caribou meat, W litres of water, and a sack of coffee from the trading post. [green]Everyone has a hot drink and a few hours' sleep.[/green]”
  Injury: “NAME was dragged off their feet by a handling line and has a broken arm.”
- Fly on: nothing.

**Cape Prince of Wales** (mark, 9,430):
“Through a gap in the cloud you see two coasts at once: Cape Prince of Wales below you, the westernmost point of America, and far across the strait, blue in the distance, the hills of Asia. The wind is doing its best to push you over there.”

**Nome** (end, 9,600): the finale (§17).

---

## 15. Mini-game skin — “Reading the winds”

The meteorologist sends up pilot balloons and follows them with a theodolite to find the winds
aloft; the ship then climbs or sinks into the kindest of them and throttles back. Same
simulation as 1849's fishing; different skin, a different reward item, and **the canvas
flipped top to bottom** (the ship is below, the balloons rise) [NEW, skin only].

| | |
|---|---|
| Menu label | *Send up pilot balloons* |
| Consumes | 1 pilot balloon per throw (`balloons`) |
| Reward item | **petrol** (kg) [NEW: 1849's reward is food] |
| Time | 25 s |
| HUD | `Balloons N · Found N kg · Time N` |
| Per-role cap | meteorologist **900 kg**, others **450 kg**; also capped by tank room |
| Hit padding | meteorologist 4 px, others 1.5 px |

**Refusals:** no balloons — “You have no pilot balloons left.”; gale or thunderstorm — “The air is far too wild to read.”; fog or icing fog — “You can't follow a balloon into fog.”

**Canvas** (160 × 200, flipped): ten sky bands from `#1F4E86` (top) to `#BFE0F2` (bottom),
three faint cloud wisps (`#F4F7FA` at 20%) drifting right in place of the light shafts. The
gondola sits at the bottom centre (x 66–94, y 188–196, `#6B4A2B` with `#F2D16B` windows) with
the meteorologist standing on it (red scarf `#D64545`) beside a theodolite (`#ECE4CF`).
Tapping the sky (above y = 170) sends a balloon (3×3, `#D64545`) from (80, 172) toward the tap
at 150 px/s, trailing a dotted sight line (`#ECE4CF`) back to the theodolite. One balloon at a
time. Winds spawn every 0.5–1.1 s from either side at y 12–155 and drift with a sine wobble,
drawn as streaks of 2–3 rows of horizontal dashes in their colour.

| target | reward | w × h | speed px/s | weight | colour |
|---|---|---|---|---|---|
| a light air | 15 kg | 9 × 3 | 26–42 | 35 | `#CFE8F5` |
| a fair breeze | 45 kg | 12 × 4 | 30–48 | 26 | `#9FD0EE` |
| a steady westerly | 90 kg | 15 × 5 | 36–56 | 18 | `#F2D16B` |
| a strong current | 225 kg | 20 × 7 | 24–38 | 13 | `#E8EEF3` |
| a river of air | 450 kg | 28 × 7 | 38–58 | 8 | `#F2B632` (with a 6-px trailing streak) |

A hit shows a floating “+90 kg steady westerly”, plays the 1849 catch tune, light haptic.

**Result** (1849's `landCatch`), then one watch aloft (`sea`):
- `found > 0`: “You found winds worth [amber]N kg[/amber] of petrol.” else “The balloons found nothing you could use.”
- `found > cap`: “ The navigator can only plan so far ahead: CAP kg is all you can use.”
- `got > 0`: “ [green]+G kg of petrol.[/green]”
- always: “ [dim]A watch has passed.[/dim]”

---

## 16. Scene & chart

### Scene (160 × 80)
- Sky above the horizon at **y = 58** (1849: 46) — an airship's scene is mostly sky.
- **Ground** y 58–80, by region, darkened by the weather's `ground ×`, with 6 rows of
  scrolling detail dashes (1849's wave dashes) at `14 × weather.speed + 2` px/s while flying
  (drifting: `14 × 0.25 + 2`), 1.5 px/s otherwise:

| region | base | detail |
|---|---|---|
| Mediterranean | `#1D4E7A` | `#7FB8DE` wave dashes |
| France | `#4F6B3A` | `#3A5229` hedgerow dashes; every ~40 px a 3×2 village `#E9DFC8` |
| North Sea | `#24394E` | `#8AA0B4` wave dashes |
| Scandinavia | `#DDE6EC` | `#2F4A35` 1×2 pines |
| Barents Sea | `#1A2C3C` | `#E8EEF3` floes, 2–4 px |
| The Polar Sea, Under the Fog | `#E6EDF2` | `#9FB0BF` ridges; `#2A3C4F` 1-px leads |
| Above the Fog | `#D9DEE2` (the top of the fog) | `#F4F7FA` billows |
| Alaskan Coast | `#6B6A4F` | `#E6EDF2` snow patches |

- **At a mast** (the town of 1849): a lattice mooring mast at x 128–132 from the ground up to
  y 22 (`#6B6F76`, cross-bracing `#8C939C` every 4 px, a 7-px platform on top); the ship
  moored nose-on at x 98, y 18. Per mast, at the left: Rome — two umbrella pines (canopies
  `#2F4A35` on `#6B4A2B` trunks) at x 10–34; Pulham — a long shed `#8C939C` 40 × 14 at x 4;
  Oslo — a hill `#2F4A35` with five houses (`#E9DFC8`, roofs `#9A3B2E`); Vadsø — four small
  wooden houses (`#C9A27A`, roofs `#9A3B2E`) on the sea ground; Kings Bay — white peaks
  (`#F4F7FA` shaded `#8C939C`) on the horizon and a tall hangar `#B9A26C` 26 × 20 at x 6.
- Effects as 1849: rain streaks, snow dots, fog overlay, lightning; plus the wind streaks,
  the midnight sun and rime (§4, §9).
- VoiceOver: “Airship flying in fair & clear weather”, “Airship moored at the mast”,
  “Airship drifting, engines stopped”.

### Chart (230 × 210) — polar projection [NEW]
1849's equirectangular map fails near the Pole. This chart is an **azimuthal equidistant
projection centred on the North Pole, Europe at the bottom**:

```
r = 2.5 × (90 − lat)                 // px
x = 115 + r × sin(lon − 15°)
y = 79.5 + r × cos(lon − 15°)
```

Rome lands at (110, 200), the Pole at (115, 79.5), Nome at (115, 16).

- Ocean `#0D2A44`. Graticule dotted `#173B5C`: circles of latitude 80°, 70°, 60°, 50°, 40°,
  and meridians every 30°. The **Arctic Circle** (66.56°) dotted `#2F6A96` (1849's equator).
- Land `#B9A26C`. Fill in the order listed; polygons marked *(sea)* are filled in ocean
  colour **after** the land they cut. Polygons are `[lon, lat]`:

- **Europe**: [-9.5,38.7], [-9.3,43], [-1.8,43.4], [-1.2,46.2], [-4.6,48.4], [-1.6,49.6], [1.6,50.9], [4,51.5], [5,53.3], [8,53.6], [8.6,55.5], [8.2,57], [10.6,57.7], [10.5,56], [12.4,55.4], [12.8,56.6], [11.2,58.4], [10.6,59], [8,58.1], [5.5,58.8], [5,60.4], [5,62], [7.5,63.2], [10.5,64.6], [12.5,66], [14,67.5], [16,68.8], [18.5,69.8], [23,70.8], [25.8,71.1], [28.5,70.9], [31,70.4], [29.8,69.9], [33,69.4], [36.5,69], [41,67.7], [40,66.3], [35,66.2], [34.5,64.5], [37.5,63.9], [41,64.5], [44,66], [44.2,68.5], [53,68.8], [58,68.9], [60.5,69.8], [66,69.3], [68.5,68.2], [73,66.5], [73,40], [60,40], [50,40], [40,40], [30,40], [26,40], [26,36], [-6,36]
- **Mediterranean** *(sea)*: [-5.6,36], [-2,36.7], [0.2,38.7], [-0.3,39.4], [0.8,41], [3.2,41.9], [3.1,43.1], [6.5,43.1], [8.8,44.4], [10.5,42.9], [12.3,41.7], [14,40.8], [15.6,40], [15.7,38], [16.5,38.4], [17.2,39.4], [16.6,40.4], [18.5,40.2], [19.5,40.5], [20,39.5], [21.5,38.3], [22.5,36.4], [26.5,35], [26.5,30], [-6,30]
- **Adriatic** *(sea)*: [18.5,40.2], [16.2,41.3], [14,42.5], [12.3,44.2], [12.3,45.4], [13.7,45.7], [15,44.5], [17.5,43], [19.4,41.8], [19.5,40.5]
- **Aegean** *(sea)*: [22.5,36.4], [23,38.5], [22.6,40.5], [24,40.9], [26,40.8], [26.7,40], [26.5,35]
- **Black Sea** *(sea)*: [28,41.5], [28.5,43.5], [30,45.5], [33.5,46], [36.5,45.3], [39,47], [38,44.5], [41.5,41.5], [36,41.7], [31,41.2]
- **Caspian** *(sea)*: [47,45], [50,46.5], [53,47], [53,44], [51,41], [50,37.5], [49,38], [47.5,41], [47,43]
- **Baltic** *(sea)*: [10.8,54.4], [14,54], [19.6,54.5], [21.2,55.5], [21,57], [23.8,57.3], [24.3,58.2], [23.5,59.2], [28,59.5], [30.2,59.9], [29,60.2], [22.9,60], [21.4,60.7], [21.3,62.5], [22.4,63.8], [25.3,65], [25,65.7], [22.2,65.8], [21,64.5], [19,63.5], [17.6,62.5], [17.3,61], [18.8,60.2], [19,59], [17,58], [16.5,56.5], [14.4,55.6], [12.8,55.8], [12.6,54.5]
- **Britain**: [-5.7,50], [1.4,51.2], [1.7,52.7], [0.3,53.5], [-1.6,55.6], [-2,57.6], [-3,58.6], [-5,58.6], [-6.2,56.5], [-5,55], [-3,54], [-3.1,53.3], [-4.6,52.8], [-5.2,51.7], [-3,51.4]
- **Ireland**: [-6,52.2], [-6.2,54.2], [-7.5,55.3], [-10,54.2], [-10.2,51.6], [-8,51.6]
- **Iceland**: [-22.5,64], [-24,65.5], [-22,66.4], [-16,66.5], [-13.5,65.2], [-15,64.2], [-18.5,63.4]
- **Greenland**: [-43,59.8], [-50,62], [-52.5,64.5], [-53.5,66.9], [-54,70.5], [-56,72.5], [-58.5,75.5], [-66,76], [-73,78.3], [-65,80.6], [-60,81.8], [-50,82.3], [-33.4,83.65], [-22,82.6], [-12,81.6], [-18,77], [-19,74], [-22,70.5], [-29,68.2], [-34,66], [-40,65], [-42.5,61]
- **Spitsbergen**: [11,78.6], [10.9,79.7], [16,80], [22,79.8], [27,80.1], [27,79.3], [21,78.6], [18,77], [16.5,76.6], [13.5,77.6]
- **Franz Josef Land**: [44.5,80.2], [50,79.8], [62,80.4], [64.5,81.2], [58,81.8], [49,81.3]
- **Novaya Zemlya**: [52,71.5], [55.5,73.5], [58,75.5], [65,76.8], [69,77], [62,75], [57,72.5], [55,70.6]
- **Siberia**: [73,66.5], [72,69], [69,73], [73,73.5], [80,73.5], [87,74], [100,76.5], [104.3,77.7], [113,73.8], [128,73], [140,72.5], [150,71], [160,69.6], [170,70], [180,68.9], [-172,66.5], [-169.7,66.1], [-171.5,64.5], [-177,64.5], [-180,65], [178,64.5], [177,62.5], [170,60], [163,59.5], [162,56], [156.5,51], [156,57], [150,59.5], [143,59.3], [137,54], [141,52], [140,48], [135,43.5], [130,42.5], [128,40], [110,40], [90,40], [73,40]
- **Severnaya Zemlya**: [95,79], [105,79.5], [104,80.5], [97,81.2]
- **New Siberian Islands**: [137,75], [150,75.5], [148,76.2], [140,76.2]
- **North America**: [-168.1,65.6], [-164.5,66.6], [-162.6,66.9], [-164,67.8], [-166.8,68.35], [-166.2,68.9], [-163,69.9], [-160,70.6], [-156.5,71.4], [-152,70.8], [-145,70.1], [-141,69.6], [-135,69.5], [-129,70], [-125,69.4], [-117,68.8], [-108,68], [-98,67.8], [-95,68.5], [-89,68.8], [-82,69.5], [-81.5,67], [-87,64], [-94,61], [-92.5,57], [-82,55], [-79,51.5], [-77,55.5], [-78,62], [-73,62.3], [-69.5,59], [-64.5,60.3], [-61,56], [-56,52], [-60,50], [-65,49], [-65,45], [-80,45], [-90,45.5], [-100,45], [-112,46], [-125,48], [-131,54], [-137,58.5], [-145,60.3], [-152,58.8], [-158,56.5], [-162,58.5], [-162,60], [-165.4,61], [-164.8,63], [-161,64.3], [-163,64.6], [-165.4,64.5], [-166.5,65.2]
- **Victoria Island**: [-118,69], [-110,68.5], [-101.5,69.5], [-104,72.5], [-110,73], [-117,72.5], [-119,71]
- **Banks Island**: [-125,71.8], [-120,71.5], [-117.5,73.5], [-120,74.4], [-124.5,74]
- **Melville Island**: [-116,74.5], [-109,74.8], [-105,75.8], [-110,76.6], [-117,76.3]
- **Prince Patrick Island**: [-122,75.8], [-117,76.2], [-118.5,77.4], [-123,77]
- **Ellesmere Island**: [-80,76.3], [-75,78.5], [-68,80.5], [-62,82.5], [-70,83.1], [-86,81.5], [-90,79], [-90,77]
- **Axel Heiberg Island**: [-87,78], [-92,79], [-97,80.3], [-92,81.2], [-88,79.6]
- **Devon Island**: [-80,74.5], [-92,74.5], [-95,76], [-84,76.5]
- **Baffin Island**: [-80,73.7], [-70,70.5], [-66,67], [-62,66], [-66,62.5], [-73,64], [-78,64.5], [-73,67.5], [-84,70], [-89,72]
- Island blocks (3×2): Bear Island [19, 74.43]; Wrangel Island [-179.5, 71.2].

**Route** — one polyline for both fork routes (the fork changes altitude, not track). Vertices
`[lon, lat, km]`:

[12.59,41.8,0], [4.8,43.4,650], [4.84,45.76,900], [2.35,48.85,1290], [1.6,50.9,1530], [1.23,52.43,1700], [8,57.8,2430], [10.77,59.9,2750], [21.6,66.56,3650], [29.75,70.07,4200], [20.5,74.5,4800], [11.93,78.93,5300], [11.93,90,6550], [-156.48,90,6550], [-156.48,71.39,8600], [-160,70.64,8750], [-166.2,68.87,9060], [-166.78,68.35,9120], [-168.09,65.6,9430], [-165.41,64.5,9600]

- **Interpolate in projected (x, y) space** between projected vertices, not in lon/lat: at the
  Pole longitude is meaningless and lon/lat interpolation spirals. The Pole appears twice
  (same point, two longitudes) so each leg is a straight meridian.
- Full route dotted `#6D7F92` every 60 km; flown part dotted amber every 20 km; stop markers
  amber once passed; blinking red 5×5 ship marker. (Checked by rendering: the route runs up
  the middle of the map from Italy to the Bering Strait.)
- Footer: “X of 9,600 kilometres flown. Y to go.”

---

## 17. Ending & scoring

**Finale** (stop 11):
“Land ho! The [i]SHIP[/i] comes down over the roofs of Nome on DATE, after N watches (D days) in the air.”
Then: “The whole town turns out — miners, dog drivers, the schoolteacher and every child in Nome — to grab the handling lines and walk her down onto the beach. There is no mast here and no shed. Whatever happens to her next, she has crossed the top of the world.” + (more than one alive: “ Your crew is already asking for the telegraph office.” / alone: “ You climb down alone into the crowd, looking for the telegraph office.”)
Score table, “Bonus for being a TITLE ×M”, rank, graves. Buttons *Fly again* / *See the top ten*. After the top ten: “Thanks for flying.” and *Fly again*.

**Game over — captain dies:** title “You, Captain NAME, have died of CAUSE.” Body: “The crew brings the ship down at the first place they can and sends word home by wireless. The expedition is over.”

**Game over — forced down (lift 0):** title “The [i]SHIP[/i] has been forced down.” Body,
`north` region: “With no gas left to hold her and no ballast left to drop, she sank slowly onto the ice and would not rise again. The crew made camp beside the wreck of the gondola, and it was weeks before a ship found them. The expedition is over.” Elsewhere: “With no gas left to hold her and no ballast left to drop, she sank slowly into a field and would not rise again. The crew climbed out of the wreck of the gondola to find a farmer and his dog staring at them. The expedition is over.” A `sea` region that is not `north`: “With no gas left to hold her and no ballast left to drop, she sank slowly onto the sea and would not rise again. The crew clung to the wreck of the gondola until a fishing boat came alongside and hauled them aboard, soaked and very quiet. The expedition is over.”

Footer on both: “DATE · N kilometres from Rome.” Button *Try again*.

**Burial** (non-captain death): red death line; “The crew wraps NAME in a blanket and lays them gently in the keel, to be buried properly when the ship comes down.”; epitaph field placeholder **“Clear skies, shipmate.”** (max 70); button *Say a few words*.

**Score**

| line | points |
|---|---|
| “N aboard, health H” | good 500 / fair 400 / poor 300 / very poor 200 per survivor |
| Lift & engines | `round(lift × 2 + engines)` |
| Provisions, water & petrol | `floor(food / 2.5) + floor(water / 15) + floor(petrol / 50)` |
| Stores & spares | `floor(coffee) × 2 + meds × 5 + furs × 2 + spares × 4 + ballast × 4 + floor(balloons / 10)` |
| Cash | `floor(money / 5)` |

Total = subtotal × role multiplier.

**Ranks:** ≥ 7,000 **Commander** · ≥ 4,000 **Navigator** · ≥ 2,000 **Rigger** · otherwise
**Ballast**. Top-ten footer: “Commander 7,000+ · Navigator 4,000+ · Rigger 2,000+ · Ballast”.

**Default top ten:** Sigrun Aasland 7,600 · Edmund Grayle 6,450 · Lucia Benvenuti 5,900 ·
Olav Brekke 5,150 · Hazel Winthrop 4,400 · Renato Ferraris 3,750 · Margit Lunde 3,150 ·
Clarence Abbott 2,600 · Ellis Tremaine 1,950 · Astrid Vollan 1,300.

Simulated winning scores (§18): financier ~2,800 (Rigger), engineer ~5,400 (Navigator),
meteorologist ~6,600 (Navigator, often Commander) — the same shape as 1849.

---

## 18. Balance targets

**Bands** (the 1849 bands, the same ±15 pp tolerance): financier wins ≥ 85%; engineer
45–85%; meteorologist 15–50%; **median winning flight 70–100 watches**.

### Sensible bot policy (for `BalanceSimulationTests`)
- **Departure:** May or June 1926, alternating by seed (the game's advice).
- **Rations:** financier full; engineer and meteorologist short.
- **Speed:** financier cruising; the others economical. Any role drops to economical while
  petrol on hand < petrol needed to reach the next mast or Nome, estimated as
  `km ÷ (160 cruising | 125 economical) × burn`.
- **Shopping, at Rome and every mast.** Target = the next mast (or Nome); **at Vadsø the
  target is Nome** (stock the polar leap where it is cheaper). Let `km` = distance to the
  target, `W = km/165 + 3` watches (petrol), `C = km/120 + 6` watches (consumables). Buy, in
  this order while money lasts: provisions `n × ration × C`; water `n × 0.6 × C`; coffee
  `n × 0.02 × C`; fur suits to `n`; petrol — financier `W × 250`, others `W × 165/130 × 150`,
  **at Vadsø fill the tanks (8,000)**; medicine to 2; engine spares to 2; ballast to 3; pilot
  balloons to 60 for non-financiers. Medicine, spares and ballast are **skipped while money
  is below a reserve** for later petrol: before Vadsø, `(9,600 − target km) / 165 × 250` kg
  at Vadsø's petrol price. If the petrol bought falls short of the target, add the shortfall's
  drift time to `C` (`shortfall kg / 250 × 165 / 60` watches).
- **At a mast:** rest 6 watches if average hp < 70; top up the gas if lift < 70; overhaul the
  engines if engines < 70 — each only if money stays above the reserve plus $60, or the meter
  is below 45. Always go ashore. Decline trades.
- **Aloft:** drop ballast while lift < 40, fit spares while engines < 40. Non-financiers send
  up pilot balloons whenever petrol is short of the next mast (as above) and the weather
  allows: up to 15 balloons, each hitting (35%, meteorologist 55%) a wind drawn by the game's
  weights.
- **Choices:** steamer — fly on; stowaway — put off at Pulham; distress flares — come down and
  help; fog to the ice — climb out; newspaper — decline; Arctic Circle — always celebrate; the
  Pole — above or under at random, buying the forecasts when going under if affordable; Point
  Barrow — always come down.

### Worked check (by hand)

**Speeds and petrol per leg** (May weather, engines and lift ~85% on average):

| leg | km | weather × | cruising: km/watch → watches → petrol | economical: km/watch → watches → petrol |
|---|---|---|---|---|
| Rome → Pulham | 1,700 | 0.86 | 190 → 9.0 → 2,240 kg | 144 → 11.8 → 1,770 kg |
| Pulham → Oslo | 1,050 | 0.81 | 179 → 5.9 → 1,470 kg | 136 → 7.7 → 1,160 kg |
| Oslo → Vadsø | 1,450 | 0.82 | 181 → 8.0 → 2,000 kg | 138 → 10.5 → 1,580 kg |
| Vadsø → Kings Bay | 1,100 | 0.76 | 167 → 6.6 → 1,650 kg | 127 → 8.7 → 1,300 kg |
| Kings Bay → Nome | 4,300 | 0.78 | 172 → 25.0 → 6,260 kg | 131 → 32.9 → 4,940 kg |
| **Total** | 9,600 | | **54.5 flying watches, 13,600 kg** | **71.6 flying watches, 10,750 kg** |

Add ~10–20 watches of repairs, rests, pilot balloons, the Circle and Barrow: **~65–75 watches
at cruising, ~85–105 at economical**, matching the median target.

**The polar leap is the test.** Tanks hold 8,000 kg. Cruising needs ~6,260 kg for Kings Bay →
Nome (22% spare); economical ~4,940 kg (38% spare); **full speed** (310 km, 420 kg, ~213
km/watch) needs ~8,500 kg and **cannot make it** on one tank. Barrow can add 200–500 kg.

**Consumables against capacity** (five aboard): full rations 1.5 kg/watch, so 72 watches ≈
110 kg (cap 300); water 3 L/watch ≈ 215 L (cap 300, plus rain); coffee 0.1 tin/watch ≈ 7
tins (cap 20). The longest stretch, Kings Bay → Nome at economical (~40 watches with stops),
needs 60 kg of food on full rations, 120 L of water and 4 tins: all fit, so food and water
only bite if petrol runs out and she drifts (60 km/watch).

**Each role's outfit at Rome** (the bot's actual purchases; this check was worked with the
design's first purses, $650 and $425, and petrol at $0.02 — the shipped numbers are in
“As built”):

| | financier ($1,200) | engineer ($650) | meteorologist ($425) |
|---|---|---|---|
| Petrol | 3,400 kg — $68 | 2,600 kg — $52 | 2,600 kg — $52 |
| Provisions | 40 kg — $20 | 30 kg — $15 | 30 kg — $15 |
| Water | 80 L — $4 | 80 L — $4 | 80 L — $4 |
| Coffee | 3 tins — $12 | 3 tins — $12 | 3 tins — $12 |
| Fur suits | 5 — $90 | 5 — $90 | 5 — $90 |
| Medicine | 2 — $30 | 2 — $30 | — (reserve) |
| Engine spares | 2 — $44 | 2 — $44 | — (reserve) |
| Ballast | 3 — $24 | 3 — $24 | — (reserve) |
| Pilot balloons | — | 6 boxes — $24 | 6 boxes — $24 |
| **Spent / left** | **$292 / $908** | **$295 / $355** | **$197 / $228** |

**Whole-flight cost.** Petrol at cruising ≈ 13,600 kg ≈ $420 at the masts' mix of prices
(Kings Bay is $0.0374/kg, so filling at Vadsø saves ~15%); essentials ≈ $330; gas and
overhauls ≈ $90. The financier spends ~$860 of $1,200. The engineer, flying economical
(~10,750 kg ≈ $320) with essentials, has almost exactly enough: one bad gale, one big leak
or a slow polar leap tips the engineer into drifting or doing without the gas plant. The
meteorologist cannot buy the petrol, the spares and the ballast; pilot balloons (≈ 700 kg a
session at a 55% hit rate) close most of the petrol gap, and the commonest end is being
**forced down** for want of ballast.

**Why the bands are plausible.** A throwaway Python Monte Carlo of exactly these rules and
this bot (a line-for-line model of the 1849 engine with this journey's tables; six seed sets
of 30 flights per role) gave:

| | seeds ×6 | win % | band |
|---|---|---|---|
| financier | 30, 30, 30, 30, 30, 30 | 100% | ≥ 85% |
| engineer | 24, 18, 20, 21, 21, 20 | 69% | 45–85% |
| meteorologist | 7, 12, 5, 6, 13, 6 | 27% | 15–50% |
| median winning flight | 83 watches (10th pct 65, 90th 105) | | 70–100 |

By month (engineer / meteorologist): April 59% / 17%, **May 71% / 36%**, June 62% / 24%,
July 50% / 8% — May is best, as the advice says. By route: above the fog 69% / 29%, under it
72% / 21% — neither route dominates. Losses: engineer mostly thirst while drifting, illness,
a broken arm; meteorologist mostly forced down, thirst, pneumonia. The financier averages 1.9
illnesses and 0.1 deaths a flight; the poorer roles 4.6–5.3 illnesses and 1–1.5 deaths. The
Swift bot will not match this model exactly; the bands are the target, and any change to
them is Ryan's call (spec §0.5).

---

## 19. Learn pages

**Page 1 — The flight**
> In 1926 nobody had crossed the Arctic Ocean by air. An airship could stay up for days and carry tons, and moor to a mast instead of needing a field — but she was as delicate as a soap bubble, and every kilo counted.
> You are captain of a small airship with a crew of five. Fly north from Rome, mast by mast, to Spitsbergen, then over the North Pole to Nome, Alaska. Keep your crew alive, keep her in the air, and don't run out of petrol over the ice.
> Time passes in [amber]watches[/amber] of four hours, six to a day.

**Page 2 — Supplies**
> [amber]Petrol[/amber] drives the engines. When it runs out she drifts wherever the wind goes.
> [amber]Lift[/amber] keeps her up. Leaks and ice take it away; when it is gone she comes down for good. [amber]Ballast[/amber] gives some back at once — or top up the gas at a mast.
> [amber]Engines[/amber] wear out. Fit [amber]spares[/amber] aloft, or have them overhauled at a mast.
> [amber]Coffee[/amber] keeps the watch awake. [amber]Fur suits[/amber] keep the crew alive in the far north — one each. [amber]Pilot balloons[/amber] find kinder winds aloft and save petrol.

**Page 3 — The Pole**
> At the North Pole you must choose: climb [amber]above the fog[/amber] into clear, bitter air, where the sun cooks a little gas out of her every watch, or stay [amber]under the fog[/amber], where in May and June it is warmer, but the fog freezes on everything and hides the ice ridges below.
> Timing matters. In April the Arctic is iron-cold; by July the fog lies thick on the ice. May is best.
> Speed matters too. Full speed gets you there sooner, if the petrol lasts. It won't last over the Pole.

### Other screens' text

- **Title options:** *Fly for the Pole* · *Continue the flight of the [i]SHIP[/i]* · *Learn about the flight* · *See the top ten*.
- **Month screen:** “When will you cast off?” / “The masts are built, the hydrogen is waiting at Kings Bay, and the newspapers are impatient. When will you leave Rome?” Options: April 1926 · May 1926 · June 1926 · July 1926 · *Ask for advice* → “An old balloonist knocks out his pipe: “Go too early and the Arctic will freeze your crew in their seats. Go too late and the summer fog will freeze on your envelope instead. Leave in May, when the sun never sets up there and the air is clear. June will do. July is for fools.””
- **Outfit intro:** “You have [amber]$X[/amber] to fit out the [i]SHIP[/i]. The stores at the Ciampino works have what you need:”
  • **Petrol** — cruising, she burns 250 kg a watch and makes about 190 km in ordinary weather. Rome to Pulham is 1,700 km. The tanks hold 8,000 kg.
  • **Provisions & water** — on full rations, five people eat 1.5 kg and drink 3 litres a watch.
  • **Coffee** — without it, after two days the crew is asleep on their feet.
  • **Fur flying suits** — one per person, or the polar cold will kill them.
  • **Ballast & engine spares** — the only way to make repairs aloft.
  • **Medicine & pilot balloons**.
  Button *Enter the stores*.
- **Aloft menu** (1849's sea menu): Continue · Check supplies & crew · Look at the chart · Change speed (now: X) · Change rations (now: X) · Stop the engines and rest · Make repairs aloft · Send up pilot balloons. Travel button: *Stop the engines & take stock*.
- **Mast menu** (1849's port menu): Cast off · Check supplies & crew · Look at the chart · Change speed · Change rations · Rest at the mast · Barter with the ground crew · Talk to people · Buy supplies · Visit the gas plant and the mechanics.
- **Trading at a mast:** intro “A ground-crew foreman looks over your stores.”; none left “Nobody else at the mast wants to trade with you today.”; no offer “You walk the field, but nobody wants what you have.”; accepted “Done. Goods change hands.”
- **Supplies screen:** “Lift” and “Engines” bars; red “Not everyone aboard has a fur suit.” when furs < crew; red “N watches without coffee” when > 6.
- **Chart heading:** “Chart of the flight”.

---

## 20. Open questions — what the engine can't express yet

Everything below is general (a journey parameter or a small hook), and none of it changes a
bit of 1849 when 1849's values are used.

1. **Turn length.** `hoursPerTurn` (1849: 24; airship: 4) and a start hour (airship: 08:00)
   drive the calendar, the date text (with `· HHMM`), seasonal months and the finale's
   “N watches (D days)”. Rest choices become a journey list (1849: 1/2/3/5; airship:
   1/3/6/12).
2. **Fuel** (brief's sanctioned mechanic): a stock, burn per pace per flying turn, a drift
   speed when empty (`60 × weather.speed × lift factor`), no propulsion wear while drifting,
   the two petrol warnings, a status row, a score term, the departure check. The low-lift
   penalty dumps fuel instead of spoiling food.
3. **Per-journey constants** now hard-coded: event chance (0.11 → 0.15); illness base and
   slope (0.0035/0.00035 → 0.006/0.0005); starving/thirst (−7/−12 → −4/−6); deficiency onset
   and ramp (35/0.004 → 12/0.01); fatigue cure as scurvy's; water per person (1 → 0.6);
   rain catch (15–45 → 6–18); southern-winter hp extra (1 → 0); yard rates (2.5/1.8 →
   3.0/2.0); hull base wear (0.03 → 0.15).
4. **Weather table generalised.** Structural wear per weather (1849 hard-codes storm and
   gale), region `iceMult` and `superheat` (1849's Horn ×1.5 and Strait ×0.5 are the same
   idea), season rules as data (month ranges, region flag, weight bumps, temp shifts).
5. **The fork with two named routes**, each replacing a region over the same km range; the
   guide (here a wireless service, not a person) and the hazard rate generalised from the
   Strait's pilot/aground. The chart polyline does not change with the route.
6. **Event table as data**, including choice outcomes (stowaway's lift cost, flares'
   forceFair, newspaper money and petrol). The stowaway's `leaveAt` becomes a parameter
   (`"pulham"`) and its condition `watch < 9` (1849: `day < 30`).
7. **The special at Barrow** gives petrol, food, water and resets the deficiency counter —
   the Galápagos with a different item list. Its prompt depends on the route, like 1849's
   `pacific` mark.
8. **Mini-game:** reward item (petrol instead of food), refusals by weather list (adds fog
   and icing), and a flipped canvas. Per-role cap and padding already exist.
9. **Chart projection:** polar azimuthal equidistant (§16), with interpolation in projected
   space. 1849 keeps equirectangular.
10. **Scene:** horizon height, ground by region, the mast-and-ship port view, the sprite's
    lift-based height, propeller-stutter rule, rime and the midnight sun.
11. **Weight is not modelled.** Each item has its own cap; a real airship trades petrol
    against ballast against stores within one useful load. A shared weight budget would be
    the most airship-like mechanic and was left out on purpose (the brief asks for few new
    mechanics). Worth revisiting after the journey plays.
12. **Facts not verified**, used as flavour: influenza at the Kings Bay camp in 1926; the
    two-hundred-man ground crew at Pulham; a “custom of the air service” at the Arctic
    Circle (invented); petrol to spare at Barrow (an aviators' expedition was there in spring
    1926 and its fuel was hauled in by sled, but how much it could spare is invented).

### Facts relied on (checked 2026-11-09)

- The 1926 transpolar airship route: Rome (Ciampino) → Pulham → Oslo (Ekeberg) → (Gatchina)
  → Vadsø → Kings Bay/Ny-Ålesund → North Pole → Teller, Alaska, 10 April – 14 May 1926;
  Spitsbergen to Teller about 72 hours and ~5,460 km flown; landed at Teller instead of Nome
  in bad weather; flags dropped at the Pole; ice thrown from the propellers tore the fabric.
  This journey skips Gatchina and ends at Nome.
- Mooring masts at Ekeberg (Oslo), Vadsø (on Vadsøya island; it still stands) and
  Ny-Ålesund (35 m), and a hangar at Ny-Ålesund of 110 × 34 × 30 m covered in canvas; 4,800
  hydrogen cylinders shipped to Kings Bay; Kings Bay a coal-mining settlement.
- Great-circle distances (computed): Rome–Pulham via the Rhône and Paris ~1,690 km;
  Pulham–Oslo ~1,020; Oslo–Vadsø ~1,430 (crossing 66.56°N about 885 km out); Vadsø–Ny-Ålesund
  ~1,110; Ny-Ålesund–Pole ~1,230; Pole–Point Barrow ~2,070; Barrow–Cape Prince of Wales along
  the coast ~835; Wales–Nome ~175. Midnight sun at Ny-Ålesund from about 19 April.
- An aeroplane expedition flew from Kings Bay toward the Pole in May 1926; another
  (aeroplanes) worked out of Point Barrow in spring 1926, its fuel hauled in overland.
- Oslo carried that name from 1925. Millibars were in meteorological use from 1914; pilot
  balloons and theodolites were the standard way to measure winds aloft in the 1920s; the
  Bergen school of meteorology dates from 1917.

---

## As built

Engine files: `HornEngine/Journeys/Airship/` (`Airship.swift` tables, sentences and hooks;
`AirshipData.swift` the data namespace; `Airship+Masts.swift`; `Airship+Events.swift`;
`Airship+Choices.swift`). Tests: `HornEngineTests/AirshipTests.swift`. The numbers below are
the ones in the code, and the tests hold them. Everything not listed here was built as the
spec says.

### Stock roles

| Engine key | Over the Pole | Unit, base price at Rome |
|---|---|---|
| `food` | Provisions | kg, $0.50, holds 300 |
| `water` | Drinking water | litre, $0.05, holds 300 |
| `limes` | Coffee & cocoa (wards off watch fatigue) | tin, $4, holds 20 |
| `meds` | Medicine | kit, $15, holds 10 |
| `clothes` | Fur flying suits | suit, $18, holds 8 |
| `sailcloth` | Engine spares (mend `sails` = the engines) | box, $22, holds 10 |
| `timber` | Water ballast (mends `hull` = lift; lift 0 forces her down) | bag, $8, holds 16 |
| `tackle` | Pilot balloons, stored as balloons, 10 a box | box, $4, holds 30 boxes |
| `fuel` | Petrol | kg, **$0.015**, holds 8,000 |

### Numbers as shipped

- **Purses:** financier **$1,200**, engineer **$580**, meteorologist **$470** (the design's
  first figures were $650 and $425; §2's table and role text now show the shipped ones). Perks as the spec: the engineer's bag of ballast gives +35 lift and a box of spares
  +40 engines (others +20 / +25); the meteorologist keeps up to 900 kg of winds a session
  with 4 px of aim (others 450 kg, 1.5 px).
- **Petrol:** $0.015 a kg at Rome (spec $0.02). At the masts: Pulham $0.0162, Oslo $0.0195,
  Vadsø $0.0239, Kings Bay $0.0281.
- A turn is a four-hour watch from 08:00 on the 1st (`tickHours 4`, `startHour 8`). Rest
  menu 1, 3, 6, 12 watches.
- Paces 190 / 250 / 310 km a watch, burning 150 / 250 / 420 kg; rations 0.3 / 0.2 / 0.1 kg.
  Water 0.6 litre a head a watch; rain and thunderstorms catch 6–18 litres.
- Health: starving −4, thirst −6; freezing −1.4 with a suit, −4.5 without; cold −2.2
  without a suit. Illness `0.006 + (100 − hp) × 0.0005` a head a watch, plus the 1849
  extras. Watch fatigue after 12 watches without coffee at `(n − 12) × 0.01` (max 0.12),
  cured at 0.35 a watch with coffee and 0.6 at a mast.
- Lift: 0.15 a flying watch, plus snow `rnd(0, 0.5)`, icing `rnd(1, 3) × pace × iceMult`,
  gale `rnd(0, 0.8) × (1.5 at full speed)`, thunderstorm `rnd(1, 2.6) × pace`, and 0.6
  above the fog. Pace factor: full 1.6, cruising 1, economical 0.7. Under the fog `iceMult`
  is 1.5.
- July in the `north`: fog +18, ice +12, fair ×0.6, headwind +8, following wind ×0.5.
- Events on 15% of flying watches; under the fog a ridge strike first at 4% (1% with the
  $60 forecasts). Heavy ship: below 35% lift with more than 300 kg of petrol, 6% a watch
  to dump 100–250 kg.
- Gas plant $3 a point of lift, overhaul $2 a point of engines, times the mast's
  multiplier.
- Score as §17; ranks Commander 7,000, Navigator 4,000, Rigger 2,000, Ballast.

### Balance

`JourneyBot`, the policy in `AirshipTests.policy()`: cruising throughout; the financier on
full rations, the others on short; at every mast buy food, water and petrol for the run to
the next mast at 70% of cruising speed plus four watches, coffee to match, a fur suit each,
two medicine kits, two boxes of spares and three bags of ballast; balloons to 30
(financier), 60 (engineer) or 100 (meteorologist), sent up when the tanks hold under 4, 6 or
15 watches; spares and ballast below 60%; gas plant and overhaul at a mast below 55%; fly on
past steamers, put the stowaway off, decline the newspaper, help the castaways, celebrate
the Circle, climb out of the murk, come down at Barrow; at the Pole go above the fog on an
even watch and under it on an odd one, buying the forecasts.

Rates from 600 flights a role (seeds 100000 and 200000, 300 each), with the breakdown
rules of D14 (below, "Lift and engines at nothing"; the rates before them are in brackets):

| Departure | Financier | Engineer | Meteorologist | Median winning flight |
|---|---|---|---|---|
| April | 97% (98) | 44% (50) | 29% (32) | 78 watches |
| **May (recommended)** | **100% (100)** | **70% (76)** | **50% (52)** | **79 watches (78)** |
| June | 99% (100) | 59% (62) | 41% (44) | 80 watches |
| July | 92% (96) | 24% (30) | 19% (19) | 87 watches (86) |
| May, economical | 99% (100) | 93% (94) | 65% (65) | 94 watches |
| May, full speed | 80% (88) | 2% (4) | 0% (1) | 73 watches (70) |

May sits inside its bands (85–100 / 60–90 / 35–70%) and a winning flight takes about
thirteen days. Thirty flights are too few to check a band on: before D14, sixteen blocks of
thirty seeds put the May engineer anywhere from 17 to 27 wins (57–90%), and the
meteorologist from 10 to 21 (33–70%), both edges of their bands, and six blocks of 180
stayed within 69–81% and 46–53%. Since D14, ten blocks of thirty (seeds 12345, 1, 777,
4242, 9001, 31337, 55555, 86420, 100000, 200000) give the financier 30 every time, the
engineer 15 to 25 and the meteorologist 12 to 16; from seed 12345, 30 / 19 / 16 (it was
30 / 19 / 17). Median winning scores in May: financier ~2,840 (Rigger), engineer ~5,470
(Navigator), meteorologist ~6,750 (Navigator). Losses are spread across thirst and hunger
after the money runs out, watch fatigue (it kills as "exhaustion"), infected wounds,
pneumonia, influenza, frostbite and exposure.

The tests fly 180 flights a role from seed 12345, where May gives 179 / 121 / 88 (99 / 67 /
49%; before D14 180 / 131 / 93) and July 168 / 35 / 37 (93 / 19 / 21%; before, 169 / 46 /
45). They assert the May bands and a median of 70–100 watches, that July is at least 15
points harder for the two poorer roles (it is about 48 and 28 points harder), that full
speed (60 flights a role: 48 / 4 / 1, before 51 / 4 / 1) halves their chances, and that
losing flights end at least three ways.

### Departures from the spec, and why

1. **The bands.** This build was asked for 85–100 / 60–90 / 35–70%, not the spec's
   ≥85 / 45–85 / 15–50%. With the spec's prices and purses an early version of this bot won
   28 / 11 / 0 of 30 in May: what decides a flight is whether the money lasts to the Kings Bay leap, and the
   spec's engineer and meteorologist cannot pay for it. Petrol came down a quarter and the
   two poorer purses were reset to $580 and $470. The win rate is steep in the purse
   (600 flights a role, May): the engineer wins 72% at $575, 76% at $580 and 82% at $590;
   the meteorologist 37% at $460, 44% at $465, 52% at $470 and 57% at $475. An earlier
   tuning ($575 / $490) was read off thirty flights from one lucky seed.
2. **The bot.** `JourneyBot` flies one pace for every role and shops for the next stop with
   a mast, so it cannot do the spec's "economical when short" or "fill the tanks at Vadsø".
   Its policy is listed above; the departure table is what it gives.
3. **Drifting** is built from the shared rules: `noFuelSpeed` is 1, so the engine leaves
   the speed to `adjustSpeed`, which drifts a watch with no power at all at `60 × weather ×
   (0.75 + 0.25 × lift)`, and `propulsionWear` returns 0 (its jitter is still drawn). Since
   D14 the last of the petrol powers only its share of a watch, engines given out drift too,
   and a watch adrift costs gas (below, "Lift and engines at nothing").
4. **Two shared hooks**, both with defaults that leave 1849 and rail byte-identical (the three
   gates and the rail bands are green): `Journey.propulsionWear` (the drive's wear a turn)
   and `Journey.wreckedBody` (the paragraph under the wreck title, so being forced down
   reads "onto the ice" in a `pack` region (sea ice below), "onto the sea" in any other
   `sea` region, and "into a field" over land, Scandinavia's included: it is `north` but
   land).
5. **Heavy ship** is rolled in `tick`, after `wear` has said its warnings, not inside `wear`.
   The odds and amounts are the spec's.
6. **The date line** is the shared one for short turns ("May 3, 1926, 4 p.m."), as rail's
   is, not "May 3, 1926 · 1600". Changing it would change rail's.
7. **Leaving Rome** needs provisions only: the engine's `depart` has no fuel check, and with
   empty tanks she simply drifts. If the app wants the spec's second refusal ("You can't
   cast off with empty tanks!") it can check `fuel` itself.
8. **The stowaway** is only found before Pulham (as well as before watch 9): put off
   anywhere later, they could never leave.
9. **Point Barrow** also adds 2 tins of coffee: the message hands up "a sack of coffee", so
   it is real.
10. **The old hulls** seen from the air are named from this journey's own list
    (`AirshipData.wrecks`), not 1849's ship names.
11. **Weather skies**: the following wind and the headwind are both `.breeze`, icing fog is
    `.fog` and the gale `.gale`. The status panel turns red on `.storm` only, so icing fog
    is not red unless the skin draws it so.
12. **A fall from the ladder** records the grave directly with its fixed epitaph and shows no
    burial screen, as 1849's man overboard does. The broken arms from flying ice and the
    handling lines open no medicine kit, as 1849's Galápagos does not.
13. **The castaways' fair weather** is `forceFair = 2`, and the watch spent helping uses one
    of the two.
14. **The finale's lines** are `Airship.finale(_:)` in the engine, for the skin to show,
    because they carry the watch and day counts.
15. **July's winds.** July in the north also brings more headwinds (+8) and half the
    following winds. Fog and ice alone made July only 15–20 points harder for the poorer
    roles, which is too close to the line the tests draw; slower flying is what a short purse
    feels most.
16. **The bot's financier sends up pilot balloons** (30, below 4 watches of petrol), as a
    player would. Without them, a slower July left it drifting on the leap.
17. **Fog to the ice** needs ice below: a new `pack` tag on the Barents Sea, the Polar Sea,
    both heights beyond the Pole and the Alaskan coast (the Chukchi Sea is frozen in April).
    The spec's "temp freezing" would have put pressure ridges under the forests of Norway in
    April. It, and the newspaper, also need the engines running: a drifting ship cannot circle.
18. **Text that matched no rule:** the Rome rigger, the Kings Bay foreman and the blurb no
    longer warn that weight costs lift (there is no weight model, §20.11); the Pulham
    sergeant's petrol is "at a fair price", not cheap (it is 8% dearer than Rome's); the Oslo
    newspaperman no longer offers to pay for a story; the Pole's choice and the navigator call
    the low route warmer only in May and June; a sight below at sea is a fishing fleet, not a
    village; a broken box of pilot balloons is counted in balloons ("85 pilot balloons").
19. **Places:** the Rhône mark is at 650 km, where the Mediterranean now ends (the chart's
    coast crossing), not 800; Bear Island no longer says Norway is behind you (Svalbard was
    Norwegian from 1925).
20. The stops' "You have reached ___" names and the arrival line ("[dim]DATE · watch N[/dim]")
    are as the spec. The journey's `blurb` is drawn from the premise, which now reads "Lift is
    precious. Petrol is life." to match it.

### Lift and engines at nothing (D14)

Reported from play on the Iron Road ("you can go below 0 for the health of the train ... I
ran out of cord and it seemed to be still moving just fine"), and checked here
(`HornEngineTests/AirshipBreakdownTests.swift`). Before this, nothing was stored below 0 or
shown as "-0", and the crew's health was always floored, but:

- the damage reports gave the event's whole number at a meter already at nothing
  ("Engines −18%" with the engines at 0%, "Lift −6%" at 2%);
- engines at 0% drove her at 45% of her speed (the shared floor) and burnt full petrol;
- lift at 0% forced her down at once, with ballast aboard, though the ending says "no
  ballast left to drop"; and lift that showed 0% (under half a point) flew on as normal;
- the last few kilos of petrol powered a whole watch;
- adrift, she paid nothing but time, and the status panel said nothing; the stalling-engine,
  ice-off-the-propellers and engine-car-fire events could still come with the engines stopped.

The rules now (`Airship+Trouble.swift`):

- **A meter that shows 0% has given out**, as the status panel rounds it (`jsRound`), as on
  the Iron Road. Every lift and engine loss goes through `knock`: never past nought, and the
  red note gives the drop the panel will show, or nothing when it shows none.
- **Engines given out**: she is a free balloon. She drifts as with dry tanks, burns no
  petrol (`Journey.fuelBurn`, a shared hook added for this, whose default is the pace's burn,
  so 1849 and the Iron Road are byte for byte as they were) and wears no engine. The crew is
  told once: "[red]The engines have given out.[/red] The mechanics have both of them in
  pieces on the catwalk, and until a box of spares goes into them, or a mast's mechanics get
  at them, she is a free balloon, going where the wind goes." The note reads "Engines dead.
  You are going where the wind goes." A box of spares fitted aloft (+25, the engineer +40)
  or an overhaul at a mast puts her under power on the next watch. Drifting always makes some
  way, so there is no softlock: she reaches the next mast, or the crew runs out of food,
  water or coffee first.
- **Lift gone**: she is going down (`rules.wearWrecks` is false, so the shared wear no longer
  ends the flight). Before she flies another watch (`Journey.stalled`), or at once when the
  watch that took the last of it was flown, she is asked what goes over the side: "Drop a
  bag of ballast" (as the repair: +20, the engineer +35, one watch) or "Open the dump valves:
  300 kg of petrol" (+10 lift, one watch; dearer by the point than a bag, and it is range).
  Over a mast she has reached and not moored to, a third offer lets the ground crew walk her
  in to the mast, whose store sells ballast and whose gas plant fills her. With nothing to
  throw over and no mast, she is forced down as before, on the ice, the sea or in a field;
  over a mast without the price of a bag of ballast, the flight ends "Grounded at Oslo." (or
  wherever). Nothing else happens on a watch she is going down: no event, no heavy-ship
  dump. A set piece reached on that watch (the Circle, the Pole, Point Barrow, a landmark)
  comes after the question; a mast or Nome comes first, since the ground crew has her lines.
- **The last of the petrol** powers its share of a watch and she drifts the rest (100 kg at
  cruising is 0.4 of a powered watch and 0.6 of a drift). The engine's `rules.burnsPartLoad`
  is left false: its blend multiplies the powered speed by `noFuelSpeed`, and a drift is not
  a fraction of the powered speed, so `adjustSpeed` blends the two itself.
- **Adrift**: a whole watch without power costs 0.5 more lift (`AirshipData.driftGas`: with
  no engines to fly her nose-up she is held at her height by valving gas when the sun warms
  her). The tanks-dry message now ends "going where the wind goes and spending gas to hold
  her height." The stalling engine, the ice off the propellers and the fire in the engine
  car need the engines running, as the newspaper and the murk already did.
- **The status panel** has a red row (`Words.trouble`, "Airship"): "Going down", "Engines
  dead, adrift", "Engines dead, tanks dry", "Tanks dry, adrift" ("Tanks dry" when moored), or
  "Last of the petrol" (less than the pace burns in a watch); nothing before she leaves Rome.
  The supplies note adds "the engines are dead" and the speed screen "With the engines dead,
  it makes no difference."; the scene draws dead engines as it draws dry tanks, propellers
  still, and the learn page says what lift and the engines at nothing do.

Tuning: a headwind that held a drifting ship still (no headway at all) was tried and
dropped. With it and the rest, the May engineer won 115 of 180, and 17 of 30 from seed
12345, below the band; the drift keeps the spec's `60 × weather.speed`. Half a point of gas
a watch adrift and the part load together cost the May engineer about six points and the
meteorologist two (table above); the bands hold untouched.

### Things worth knowing

- Forced down is a rare ending for the bot because it always carries three bags of ballast
  and tops up the gas below 55%. A player who skips ballast and flies under the fog will meet
  it.
- Full speed cannot cross the ice on one tank, as the spec says; even the financier loses a
  few flights to it.
- The meteorologist's balloons are worth a great deal: a session of 15 at 55% finds ~800 kg
  of petrol for $6 of balloons. Its high median score is the ×3 on a flight that usually
  arrives with petrol in hand.

### The skin

The app's skin (`AroundTheHorn/Journeys/Airship*.swift`, docs/design/journeys-architecture.md
§2 "Airship skin, as built") follows §1–§19 except:

- Leaving Rome with empty tanks is refused by the app (`Words.departRefusal`): “You can't cast
  off with empty tanks! The storekeeper shakes his head and points you back to the petrol.”
  A flight saved before she left (the stores save as you leave them) comes back to Rome's
  stores, so she still leaves through both refusals and the departure sentence (D16).
  Both refusals hold only while the purse runs to a step of what is missing (100 kg of
  petrol, $1.50; 10 kg of provisions, $5). With less she leaves dry, hungry or both, and
  the departure sentence ends by saying so (D22).
- The departure sentence reads “On DATE, the [i]SHIP[/i] slips the mast at Ciampino. …”: the
  date line ends in “a.m.” or “p.m.”, and a full stop after it doubled.
- The role screen, its labels and the mast menu's trade row are in this journey's own words
  (D11), as §2 and §19 now show.
- The weather turns red in the status panel on the thunderstorm only (the shell's rule: the
  hardest weather by `harsh`), not on icing fog; the scene rimes the airship white instead.
- The rest menu reads “1 watch”, “3 watches”, “6 watches (1 day)”, “12 watches (2 days)”.
- The sun crosses the side of the sky away from the airship, and nights are dark, except
  where and when the sun does not set (north of the Circle, by latitude along the flight
  and the date: Kings Bay from about April 17, Vadsø from about May 16, the Circle a month
  round midsummer, Oslo and Nome never): there the midnight sun circles low, at (126, 44)
  at midnight.
- Places in sentences read “above the fog”, “over the North Sea”: the region names are
  headings. One pilot balloon is “1 balloon”; the winds' tally writes “1,350 kg”.
- Forced down, she is on the ice only where there is sea ice below (`pack`); over
  Scandinavia she comes down in a field, in the engine's ending and in the picture.
- At a mast she has reached and not moored to (the arrival's question, or flying on), the
  picture is the mast and its town, the ground crew waiting at its foot.
- The chart is §16's; its Mediterranean coast is crossed at about km 510, while the scene's
  sea (the region) runs to the Rhône stop at 650.
- Forced down, the scene puts her on the surface; at the end she comes down over Nome's roofs.
- The status panel's red row, the supplies note, the speed screen and the scene speak of
  engines given out and lift gone as "Lift and engines at nothing (D14)" above says.
