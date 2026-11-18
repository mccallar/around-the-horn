# Journey `klondike` — To the Klondike: 1898

Content specification for the gold-rush sequel to Around the Horn: 1849. It follows the
content template in `docs/design/journeys-brief.md` section by section. Every number an
engineer needs is here, and so is every line a player reads.

**Conventions used below**

- **Distances are stored in tenths of a mile** (an integer "unit"; 1 mile = 10 units).
  The status line, chart legend and every message show miles with one decimal
  ("1,136.5 of 1,700.0 miles"). The trail moves under a mile a day, so whole miles would
  round most days to zero. See §12 and §20.
- Markup is the 1849 markup: `[red]`, `[green]`, `[amber]`, `[dim]`, `[i]`, `[b]`.
- Placeholders in player text: `{name}` = a crew member's name, escaped as in 1849.
  `{boat}` = the boat name the player chose, always shown in `[i]…[/i]`. Also `{date}`,
  `{day}`, `{n}`, `{m}`, `{cost}`, and `{next}` = the next port's name. `{S}` = the
  structural meter's name and `{P}` = the propulsion meter's name, both from §4.
- "Camp" mode means 1849's `.sea` day mode: stopped, not in a town, weather rolled,
  +3 hp. "Town" mode is `.port`. "Travel" is `.sail`.
- `ri(a,b)` and `rnd(a,b)` are 1849's integer and uniform draws. They are drawn in the
  order written. Every random draw goes through `RandomSource`.
- The balance numbers here come from a prototype simulation (§18). It is a Python
  approximation of the engine, not the engine, so the Swift `SensibleBot` must
  re-confirm them.

---

## 1. Pitch

**Title:** *To the Klondike: 1898*. On the title screen it is set as `TO THE` / `KLONDIKE`,
with `~ 1898 ~` under it. The top bar reads `TO THE KLONDIKE · 1898`.

**Premise.** In July 1897 a steamer tied up in Seattle with a ton of gold aboard, and
within a week the whole country had the fever. The gold is on the Klondike River in
Canada's Yukon. Getting there takes three different journeys in a row. First a crowded
coastal steamer a thousand miles up the Inside Passage. Then a mountain pass climbed on
foot, carrying a year's supplies in relays, one load at a time. Then a boat you build
yourself, floated five hundred miles down lakes, a canyon and the Yukon River to
Dawson City. The Canadian police at the summit turn back anyone without a year's food.
That rule shapes every purchase you make in Seattle.

| | |
|---|---|
| Period | January–August 1898 |
| Start | Seattle, Washington |
| Destination | Dawson City, Yukon (end of the journey) |
| Total distance | **1,700.0 miles** (statute), stored as 17,000 units |
| Legs | Steamer 1,120 mi · Trail 33 mi · River 547 mi |
| Target length | 115–155 days for a winning journey; the sensible bot's median is ~134 |
| The day | A day is a day. |

**Why it is a sequel.** 1849 is a sea voyage shaped by one place, the Horn. This journey
is shaped by one rule (the police's year of food) and one date (the day the lake ice
breaks up). The year of food makes the outfit huge. The ice date decides how long you
wait at the lakes. Departure month does the job 1849's southern winter did. Leave too
early and you cross the pass in deep winter. Leave too late and you wade through spring
slush under the snowslides, and reach Dawson after the crowd.

### Historical basis (checked 2026-11-09 by web search unless marked)

| Fact relied on | Status |
|---|---|
| The rule: a year's supply at **3 lb of food a day**, so 1,095 lb a head; gear roughly doubled it, giving the "ton of goods". Enforced by the North-West Mounted Police, who also collected customs. | Verified (NPS "Ton of Goods") |
| The police flag was raised at the Chilkoot summit on **26 Feb 1898**, and customs collection there began that day. | Verified (Yukon Archives; Wikipedia) |
| Chilkoot Trail **Dyea → Lake Bennett, 33 mi**. The Scales lie about ¾ mi below the summit. The summit is at about 3,525 ft (sources differ: 3,525 or 3,759). | Verified (NPS) |
| **Palm Sunday avalanche, 3 April 1898**, between Sheep Camp and the Scales, killed over 65 people. | Verified (NPS). The game names no real victims. |
| White Pass: Skagway → Bennett **40–45 mi**, summit about **2,865 ft**. A wagon road reached White Pass City by April 1898. | Verified (several, they disagree on the length) |
| Lake Bennett's ice went out on **29 May 1898**, and some 7,000 boats left within days. About 10,000 people camped at Bennett and 10,000 at Lindeman. | Verified (Parks Canada; others) |
| Miles Canyon / White Horse Rapids: a few hundred boats were wrecked and about five people drowned before the police required **registered pilots**. A horse tramway charged $25 a boat and 3¢ a lb. | Verified (Yukon News; Wikipedia). The tramway is not used in the game. |
| Seattle → Skagway **975 nautical miles** (about 1,122 statute). | Verified (1919 source) |
| Whitehorse → Dawson about **460 river miles**. Bennett → Dawson is variously given as 500 to 608 miles; the game uses 547. | Partly verified. The 547 comes from river-km markers (Miles Canyon km 40, Five Fingers about km 385, Fort Selkirk km 477) plus about 100 mi of lakes. |
| Fort Selkirk had a trading post from about 1889–92 (Harper). The Yukon Field Force arrived later in 1898. | Verified for the post's founding. **Unverified** that the store was open in June 1898. |
| Juneau → Skagway about 90 nautical miles. | **Unverified** (from memory) |
| Police at Tagish numbered boats and recorded who was aboard (and next of kin). | Boat inspection below Tagish in June 1898 verified. The numbering and next-of-kin ledger are **unverified** (widely told). |
| Bonanza Creek strike August 1896; the steamer *Portland* reached Seattle 17 July 1897 with "a ton of gold". | **Unverified** in this session (well known). The game names no ship. |

Sources: [NPS — Ton of Goods](https://home.nps.gov/klgo/learn/historyculture/tonofgoods.htm),
[NPS — The Historic Chilkoot Trail](https://www.nps.gov/klgo/learn/historyculture/historic-chilkoot-trail.htm),
[Wikipedia — Chilkoot Pass](https://en.wikipedia.org/wiki/Chilkoot_Pass),
[Yukon Archives — Klondike exhibit](https://archives-ftp.gov.yk.ca/exhibits/klondike/en/fever/05.html),
[Parks Canada — Boat building](https://parks.canada.ca/lhn-nhs/yt/chilkoot/culture/bateau-boat),
[Yukon News — tramway](https://www.yukon-news.com/news/where-theres-a-will-theres-a-tramway/),
[Wikipedia — Canyon City, Yukon](https://en.wikipedia.org/wiki/Canyon_City,_Yukon),
[White Pass & Yukon Route — history](https://wpyr.com/history/the-white-pass-story/),
[Maritime History of the Great Lakes (Seattle–Skagway 975 nm)](https://images.maritimehistoryofthegreatlakes.ca/126636/page/117),
[sightsandsites.ca — Yukon River km markers](https://sightsandsites.ca/rivers/site/fort-selkirk),
[The Canadian Encyclopedia — Fort Selkirk](https://thecanadianencyclopedia.ca/en/article/fort-selkirk).

---

## 2. Roles

| id | Menu label | Start money | Score × | Perk |
|---|---|---|---|---|
| `storekeeper` | A Seattle storekeeper | **$1,700** | ×1 | None. |
| `boatbuilder` | A Port Townsend boatbuilder | **$1,050** | ×2 | Repairs go further: canvas & pitch **+35** (others +20) and rope & rawhide **+40** (others +25), the same numbers as 1849's shipwright. Builds at Bennett in less time, and the quick boat comes out stouter (§14). |
| `miner` | A hard-rock miner out of Leadville | **$720** | ×3 | **A strong back:** on foot legs his party's travel speed is ×**1.15**. This is the only new perk type. |

`title` (as in "Bonus for being a ___"): `storekeeper`, `boatbuilder`, `miner`.

The miner's perk is new because the fishing perk would be worthless here. Food is never
short after the police check, so a catch perk buys nothing. The trail is the hard part,
so a trail perk is the one that matters. It is a single multiplier in the speed formula
(§12), applied only on foot legs. The bot needs nothing extra to play it. Fishing hit
padding is 1.5 and the catch cap is 150 lb for **all** roles.

**Role screen text**

- Heading: `Who are you?`
- Intro: `In 1898 the fever took clerks and cooks, preachers and prospectors. Choose who you will be:`
- Extra choice: `What does each one bring north?`
- Comparison page (heading `What each one brings north`), paragraphs:
  1. `A Klondike outfit cost more than most people earned in a year.`
  2. `[amber]Storekeeper[/amber] — starts with $1,700.`
  3. `[amber]Boatbuilder[/amber] — starts with $1,050. Gets far more out of every bundle of canvas and coil of rope, and builds a better boat in less time.`
  4. `[amber]Miner[/amber] — starts with $720. A strong back: moves an outfit over the pass faster than anyone.`
  5. `The poorer you start, the more your arrival is worth: the boatbuilder scores double, the miner triple.`
  - Button: `Back`

---

## 3. Crew

**First names (32)**, in this order. These are names common in 1890s Seattle and the West,
with some Scandinavian ones for Puget Sound:

Will, Martha, Gus, Clara, Ed, Nellie, Frank, Ida, Hiram, Belle, Oscar, Mae, Walter,
Lottie, Arne, Signe, Jack, Bess, Charlie, Effie, Sam, Hattie, Otto, Pearl, Lars, Edna,
Ben, Josie, Homer, Minnie, Fred, Ruby

**Boat names (14)**, used for the player's boat placeholder and for wrecks and abandoned
sleds seen on the way:

Klondike Belle, Yukon Lass, Last Chance, Never Sweat, Bonanza Bound, Hope On, Puget Belle,
Two Partners, Sourdough Sal, North Star, Polly Ann, Golden Fleece, Pay Dirt, Ton of Grub

**Names screen** (1849's "Ship & crew")

- Heading: `Boat & party`
- `Name the boat you'll build at the lakes:` (max 22, placeholder: a random boat name)
- `Your name:` (max 16)
- `Your four partners:` (4 fields, max 16)
- Buttons: `Use these names` · `Pick new names for me`

The boat is named at the start, as the 1849 ship is, even though it is not built until
Bennett. Before Bennett, texts talk about "your party" or "your outfit"; only `{boat}`
messages after Bennett use the name. The title screen's resume button reads
`Continue the journey of the [i]{boat}[/i]`.

---

## 4. Vehicle

The vehicle changes once, at Lake Bennett. The two meters keep their engine roles
throughout: **structural** (0 ends the game; small daily wear; a leak-style spoilage
roll below 35) and **propulsion** (slows you; worn daily by pace × weather). What they
*represent* changes when the boat is launched. That one change is the whole case for
"change meaning by leg":

| Vehicle state | When | Structural `{S}` | Propulsion `{P}` | Status-panel label |
|---|---|---|---|---|
| `outfit` | From Seattle until the boat is built at Bennett | **Outfit**: sacks, crates, tarps, tent and stove, the goods themselves | **Sleds**: sleds, pack boards, straps, harness | `Outfit · Sleds` |
| `boat` | From the moment a boat is built or bought at Bennett | **Boat**: the hull | **Oars & sail**: oars, steering sweep, square sail | `Boat · Oars` |

**Why not "Boat"/"Packs" all the way?** No boat exists for the first 1,153 miles, and the
boat's condition is decided at Bennett by how you build it. That build is the journey's
best moment, and it needs a fresh meter to set. The two meters also mean different
things on foot and afloat. On foot, what can actually end the trek is the *outfit* being
ruined. Stampeders turned back when their goods were soaked, stolen or buried, not when
a sled broke. What slows the relay is worn sleds and straps. Afloat it is the 1849 pair
again: hull and rigging. The repair items (§5) are named so that each one works in both
states.

- **At Bennett** the outfit meters are discarded. The boat meters are set by the build
  choice (§14): Boat 35–100, Oars & sail 50–100.
- **On the steamer** both outfit meters exist (the goods are in the hold), but nothing
  wears them day to day. Only events can.
- **Ending at 0:** Outfit 0 → "Your outfit is ruined." Boat 0 → "The {boat} has broken
  up." (§17)

### Scene sprites (one per leg)

Each grid is drawn like 1849's `SHIP_SPR`, one logical pixel per cell, facing right,
bobbing with `sin(t)`. Space = transparent.

**Steamer**: 26 × 13, at x = 44, top at horizon − 9. On steamer legs only.

```
          oo              
         ooo     m        
          o      m        
         tt      m        
         ff      m        
         ff      m        
    wwwwwffwwwwwwwwww     
    wpwpwwwwpwpwpwpww     
  wwwwwwwwwwwwwwwwwwwwww  
kkkkkkkkkkkkkkkkkkkkkkkkkk
 kkkkkkkkkkkkkkkkkkkkkkkk 
 yyyyyyyyyyyyyyyyyyyyyyyy 
  kkkkkkkkkkkkkkkkkkkkkk  
```

| char | colour | | char | colour |
|---|---|---|---|---|
| `k` hull | `#23262B` | | `f` funnel | `#A8452F` |
| `y` boot-top stripe | `#9E3B2F` | | `t` funnel cap | `#23262B` |
| `w` deckhouse | `#E6E0D0` | | `m` mast | `#6B4A2B` |
| `p` lit window | `#F2C14E` | | `o` smoke | `#8F959C` (drift the three top rows left 1 px every 0.4 s, wrapping) |

**Party with sled**: 31 × 9, at x = 40, feet on the ground line at horizon + 10. On foot
legs.

```
                 hh       hh   
                hhff     hhff  
  llllllll      kpp      kdd   
 llllrlllll     kppp     kddd  
 llllllllll  rr kppppr rrkdddd 
 llrllllrlll r   pp       dd   
ssssssssssssr    pp       dd   
nnnnnnnnnnnn     p p      d d  
                b   b    b   b 
```

| char | colour | | char | colour |
|---|---|---|---|---|
| `h` hat | `#4A3222` | | `l` load tarp | `#CDBE94` |
| `f` face | `#E6C29A` | | `r` rope | `#7A5A3A` |
| `p` red mackinaw | `#B5432F` | | `s` sled slats | `#8B6A42` |
| `d` dark coat | `#3B3E4A` | | `n` runners | `#2E3036` |
| `k` pack | `#6E5B3E` | | `b` boots | `#2A2522` |

Walking animation: while travelling, swap rows 7–8 every 0.35 s with
`"nnnnnnnnnnnn      pp       dd   "` / `"                 b b       b b  "`.

**Boat**: 26 × 15, at x = 44, top at horizon − 10. On boat legs, and at Bennett once a
boat exists.

```
            rr            
            m             
       mmmmmmmmmmm        
       sssssssssss        
       sssssssssss        
       sssssssssss        
       sssssssssss        
       sssssssssss        
       sssssssssss        
  hh        m       hh    
 ohff  gggggmgggg   ff    
o pp   gggggmggggg  dd    
owwwwwwwwwwwwwwwwwwwwwwwww
 wbbbbbbbbbbbbbbbbbbbbbbw 
  wwwwwwwwwwwwwwwwwwwwww  
```

| char | colour | | char | colour |
|---|---|---|---|---|
| `s` sail (flour-sack duck) | `#E8DFC4` | | `p` / `d` people | `#B5432F` / `#3B3E4A` |
| `m` mast & yard | `#6B4A2B` | | `f` faces / `h` hats | `#E6C29A` / `#4A3222` |
| `r` pennant | `#D64545` | | `w` raw planks | `#9C7A4E` |
| `g` cargo tarp | `#B8A77A` | | `b` pitched seam | `#3A2A1A` |
| `o` steering sweep | `#6B4A2B` | | | |

A **raft** (§14) uses the same grid with rows 12–14 replaced by
`"owwwwwwwwwwwwwwwwwwwwwwwww"`, `"owwwwwwwwwwwwwwwwwwwwwwww "`, `"                          "`.
That gives a flat log deck and no pitched seam.

### What "torn sails" looks like

1849's rule is reused unchanged: when the propulsion meter is below 60, skip a pixel
where `((col*7 + row*13) % 37) < (60 − meter)/2.2`.

- **Sleds:** apply it to `l` (load tarp) and `s` (sled slats) pixels. The tarp gets holes
  and the sled shows gaps.
- **Oars & sail:** apply it to `s` (sail) pixels, exactly as 1849.
- **Steamer:** no meter is shown on the sprite.

---

## 5. Supplies

8 items. The journey has **no vehicle fuel**: the brief's optional Fuel mechanic is not
used. Firewood takes the engine's **water** role: a per-person daily need with a
temperature multiplier, a free top-up in some places, and a −12 hp/day penalty when it
runs out (§12).

| key (engine role) | Name | unit / one | step | per | Seattle price | max (bought units) | Description (shop) |
|---|---|---|---|---|---|---|---|
| `food` (food) | Provisions | lbs / lb | 250 | 1 | $0.10 | 9,000 | `Flour, bacon, beans, sugar, tea. Each of you eats 1–3 lbs a day, and the police want a year's worth.` |
| `water` (water → **firewood**) | Firewood | lbs / lb | 100 | 1 | $0.02 | 2,000 | `Stove wood. Two to eight lbs a head a day — and nothing grows on top of the pass.` |
| `limes` (deficiency preventive) | Lime juice | jugs / jug | 1 | 1 | $4 | 40 | `Against scurvy, the winter sickness. A jug lasts five people about ten days.` |
| `meds` (medicine) | Medicine chest | kits / kit | 1 | 1 | $12 | 12 | `Liniment, quinine, carbolic salve. One kit per illness halves its harm.` |
| `clothes` (warmth) | Furs & mackinaws | sets / set | 1 | 1 | $12 | 12 | `Mackinaw, mitts, moccasins, fur cap. One set a head, or the summit takes fingers and toes.` |
| `sailcloth` (repair-propulsion) | Rope & rawhide | coils / coil | 1 | 1 | $8 | 20 | `Mends sleds and straps on the trail; re-rigs oars and sail on the river. Boatbuilding takes some.` |
| `timber` (repair-structure) | Canvas & pitch | bundles / bundle | 1 | 1 | $10 | 20 | `Patches a soaked outfit on the trail or a holed boat on the river. Boatbuilding takes some.` |
| `tackle` (forage) | Hooks & line | boxes / box | 1 | 20 | $3 | 600 (12,000 casts) | `Hooks, line and a spoon lure. Each box is 20 casts.` |

- Lime juice is stored fractionally, like citrus (0.02 jug per person per day).
- Repairs at camp: canvas & pitch restores the **structural** meter by 20 (boatbuilder
  35). Rope & rawhide restores the **propulsion** meter by 25 (boatbuilder 40).
- Boatbuilding at Bennett *consumes* canvas & pitch and rope & rawhide (§14).

**Trade values** (1849's `VAL`): food 0.14 · firewood 0.03 · lime juice 4 · medicine 12 ·
furs 12 · rope & rawhide 8 · canvas & pitch 10 · hooks 0.15 per cast · money 1.

**`describe()` strings:** `{n} lbs of provisions`, `{n} lbs of firewood`,
`{n} jug(s) of lime juice`, `{n} medicine kit(s)`, `{n} set(s) of furs`,
`{n} coil(s) of rope & rawhide`, `{n} bundle(s) of canvas & pitch`,
`{n} box(es) of hooks & line`, `${n}`.

**Supplies screen rows:** Cash `$n` · Provisions `n lbs` · Firewood `n lbs` · Lime juice
`n jugs` (tenths shown as in 1849) · Medicine `n kits` · Furs `n sets` · Rope & rawhide
`n coils` · Canvas & pitch `n bundles` · Hooks & line `n casts`.

---

## 6. Ports / depots / stations

Six port slots. Two of them have a version for each pass, chosen at the fork (§14), so
there are eight port records. Price = `base × mult × (mod ?? 1)`. The shop's note:
`Prices here are {n}% above Seattle, more or less.` (`n = round((mult − 1) × 100)`).
Every port has a yard (§12). "Fever" means 1849's fever-port rules: +0.012 illness
chance and the fever pool.

| id | Name | Shop name | mult | mods | fever |
|---|---|---|---|---|---|
| `seattle` | Seattle | An outfitter on First Avenue | 1.0 | — | no |
| `juneau` | Juneau | A general store on Front Street | 1.25 | firewood 1.5, furs 0.9 | no |
| `dyea` (Chilkoot) | Dyea | A tent store above the tide flats | 1.4 | firewood 0.8 | **yes** |
| `skagway` (White Pass) | Skagway | A false-front store on Broadway | 1.35 | firewood 0.8 | **yes** |
| `sheepcamp` (Chilkoot) | Sheep Camp | A canvas store at Sheep Camp | 1.9 | firewood 2.5, lime juice 1.2 | no |
| `whitepasscity` (White Pass) | White Pass City | A log store at White Pass City | 1.8 | firewood 2.0 | no |
| `bennett` | Lake Bennett | The sawmill store at Bennett | 2.2 | firewood 0.25, canvas & pitch 0.8 | no |
| `selkirk` | Fort Selkirk | The trading post at Fort Selkirk | 2.6 | firewood 0.25 | no |

**Resulting prices** (per bought unit; hooks per box):

| | Prov. | Firewood | Lime | Meds | Furs | Rope | Canvas | Hooks |
|---|---|---|---|---|---|---|---|---|
| Seattle | 0.10 | 0.020 | 4.00 | 12.00 | 12.00 | 8.00 | 10.00 | 3.00 |
| Juneau | 0.125 | 0.0375 | 5.00 | 15.00 | 13.50 | 10.00 | 12.50 | 3.75 |
| Dyea | 0.14 | 0.0224 | 5.60 | 16.80 | 16.80 | 11.20 | 14.00 | 4.20 |
| Skagway | 0.135 | 0.0216 | 5.40 | 16.20 | 16.20 | 10.80 | 13.50 | 4.05 |
| Sheep Camp | 0.19 | 0.095 | 9.12 | 22.80 | 22.80 | 15.20 | 19.00 | 5.70 |
| White Pass City | 0.18 | 0.072 | 7.20 | 21.60 | 21.60 | 14.40 | 18.00 | 5.40 |
| Bennett | 0.22 | 0.011 | 8.80 | 26.40 | 26.40 | 17.60 | 17.60 | 6.60 |
| Fort Selkirk | 0.26 | 0.013 | 10.40 | 31.20 | 31.20 | 20.80 | 26.00 | 7.80 |

### Seattle (start; no arrival paragraph)

Talk lines:
1. `An outfitter with a pencil behind his ear: “The Canadians won't let you over the summit without a year's grub — three pounds a head a day. Don't argue with me about it. Argue with the mounted police.”`
2. `A man back from the North, thin as a rail: “Go in March. You'll cross while there's still snow for the sleds, and be at the lakes when the ice goes out. Go sooner and the pass will freeze you; later and you'll wade.”`
3. `A doctor on the dock: “Take lime juice. A winter on beans and bacon and your gums go soft and your old cuts open up again. I saw it all last year in Circle City.”`

### Juneau

Arrival: `Juneau is a mining town wedged between the water and a mountain. The steamer stops for coal and mail, and half the passengers go ashore to buy what they forgot in Seattle.`

Talk lines:
1. `A clerk at the mining office: “They say there are more people on the trail than there's grub in the whole Yukon. That's why the police make you carry your own.”`
2. `A deckhand coiling a line: “Fill up your woodpile at the landing. There's nothing to burn up on the pass, and they'll charge you like it's gold.”`
3. `The storekeeper: “Furs are cheaper here than in Seattle. The trappers bring them to us.”`

### Dyea (Chilkoot route)

Arrival: `Dyea is a tide flat, a river and a forest of tents. Your outfit comes ashore in a lighter and is dumped on the beach just above the tide line. The tide here comes in fast, and nobody waits for it.`

Talk lines:
1. `A packer resting on his load: “Fifty pounds a trip and you'll make forty trips. Sixty and you'll make thirty, and hate every one of them.”`
2. `A woman selling bread from a tent: “A dollar a loaf. You'll think it was cheap when you're up at the Scales.”`
3. `A man wrapped in a blanket: “There's fever in these tents. Don't drink from the river below the camp.”`

### Skagway (White Pass route)

Arrival: `Skagway is a few months old and already has a dozen saloons, a newspaper and a reputation. The street is ankle-deep in mud, and every second man has something to sell you.`

Talk lines:
1. `A storekeeper behind a plank counter: “Keep your money in your boot. There are men in this town who can find it anywhere else.”`
2. `A teamster: “The White Pass was a swamp last fall. Frozen, it's not so bad. Just long.”`
3. `A newsboy: “Extra! Another strike on the Klondike! Only a nickel!”`

### Sheep Camp (Chilkoot route)

Arrival: `Sheep Camp is the last place with trees: a mile of tents, cook-fires and stacked outfits in the snow. Above it the valley climbs into bare white country, and every scrap of wood up there has been carried up on somebody's back.`

Talk lines:
1. `A woman selling firewood by the armload: “Buy it here, dear. Above the timber it's packed up on somebody's back, and they charge like it.”`
2. `A packer: “At the Scales they weigh it again and the price goes up. Then it's the Golden Stairs — steps cut in the snow, straight up. You'll climb them thirty times.”`
3. `An old-timer cleaning his pipe: “When the snow on the mountain starts to talk, get off the trail. I mean it.”`

### White Pass City (White Pass route)

Arrival: `White Pass City is a camp of tents and log shanties where the wagon road gives out. From here the trail climbs over rock and ice to the summit.`

Talk lines:
1. `A blacksmith: “Bring your sled to me before the summit, not after. There's no smith on the other side.”`
2. `A cook ladling beans: “Fifty cents a plate. The coffee's free if you'll listen to me complain.”`
3. `A tired stampeder: “Last fall this trail was mud to your knees, and worse. Be glad it's frozen.”`

### Lake Bennett

Arrival: `Lake Bennett is a city of tents on the shore of a long, narrow lake. Every tree for miles has been cut, and the whipsaws never stop. Half-built boats stand everywhere.`
If the ice is still in, add `\n\n[dim]The lake is still frozen. The old-timers say the ice goes out at the end of May.[/dim]`.

Talk lines:
1. `A boatbuilder with pitch to the elbows: “Plank her thick at the bow and pitch every seam twice. The river finds any seam you skipped.”`
2. `A mounted policeman: “We'll stop you at Tagish to number your boat. And nobody runs Miles Canyon now without a pilot.”`
3. `An old-timer: “The ice goes out the end of May, near enough. Sit tight till then. People who try the ice early end up walking.”`

### Fort Selkirk

Arrival: `Fort Selkirk is a trading post and a few cabins on a flat above the river, where the Pelly comes in from the east. After weeks on the river, a counter with tinned goods on it looks like a palace.`

Talk lines:
1. `The trader: “Dawson's a week's float, less if you keep at it. Everything costs more there than here, and here costs plenty.”`
2. `A man going out: “Every creek worth a dollar was staked before you left home. But there's wages, if you'll work.”`
3. `A woman at the counter: “Lime juice is dear, but scurvy is dearer. Half of Dawson had it last winter.”`

**Port arrival choice** (1849's "Drop anchor"): prompt as in 1849
(`You have reached {name}.\n[dim]{date} · day {day}[/dim]`), then the arrival paragraph.
Options by leg:

- Steamer: `Go ashore while the steamer takes on coal` / `Stay aboard`
- Foot: `Stop and make camp here` / `Keep moving`
- Boat: `Tie up and go ashore` / `Float on past`
- Bennett: one option only, `Make camp at the lakes`. You must stop to get a boat (§14).

**Partner drop-off line** (1849's stowaway goodbye):
`[dim]{name} waves goodbye and goes off to look for work.[/dim]`

---

## 7. Stops

13 stops. `mile` is shown, and `units` = mile × 10 is what the engine stores. Before the
fork, the route-variant names show as "A / B" in the legend.

| # | id | type | name ("You have reached ___") | short (legend) | mile | units |
|---|---|---|---|---|---|---|
| 0 | `seattle` | port | Seattle | Seattle | 0.0 | 0 |
| 1 | `juneau` | port | Juneau | Juneau | 1,020.0 | 10,200 |
| 2 | `lynn` | fork | the head of Lynn Canal | Lynn Canal | 1,110.0 | 11,100 |
| 3 | `landing` | port (variant) | Dyea · Skagway | Dyea · Skagway | 1,120.0 | 11,200 |
| 4 | `camp` | port (variant) | Sheep Camp · White Pass City | Sheep Camp · White Pass City | 1,133.0 | 11,330 |
| 5 | `summit` | special: police | the summit of the Chilkoot Pass · the summit of the White Pass | Chilkoot summit · White Pass summit | 1,136.5 | 11,365 |
| 6 | `lakes` | mark (variant) | Lake Lindeman · Log Cabin | Lindeman · Log Cabin | 1,146.0 | 11,460 |
| 7 | `bennett` | special: boat + port | Lake Bennett | Lake Bennett | 1,153.0 | 11,530 |
| 8 | `tagish` | mark | the police post at Tagish | Tagish Post | 1,203.0 | 12,030 |
| 9 | `canyon` | special | Miles Canyon | Miles Canyon | 1,253.0 | 12,530 |
| 10 | `fivefinger` | special | Five Finger Rapids | Five Fingers | 1,467.0 | 14,670 |
| 11 | `selkirk` | port | Fort Selkirk | Fort Selkirk | 1,525.0 | 15,250 |
| 12 | `dawson` | end | Dawson City | Dawson | 1,700.0 | 17,000 |

Both passes use the same mile markers between the fork and Bennett. The White Pass's
real extra length (about 42 miles against 33) is handled by its regions' speed factor
0.9 (§8), not by extra miles. The chart draws the real two trails (§16).

---

## 8. Regions

**Seasons** (by the month of the current date, 0-based like 1849):
**W** (winter) = Nov–Mar (10, 11, 0, 1, 2) · **Sp** (spring) = Apr–May (3, 4) ·
**Su** (summer) = Jun–Oct (5–9). **Deep winter** = Dec, Jan, Feb (11, 0, 1).

Each region has a **leg** (`steamer`, `foot` or `boat`), a temperature per season, flags
and a speed factor. `to` is exclusive. The fork replaces the three foot regions with the
White Pass set.

| id | name (status panel) | to (mi) | leg | temp W / Sp / Su | flags | speed × |
|---|---|---|---|---|---|---|
| `insidePassage` | The Inside Passage | 300 | steamer | cool / cool / cool | — | — |
| `queenCharlotte` | Queen Charlotte Sound | 360 | steamer | cool / cool / cool | open | — |
| `alaskaCoast` | The Alaska coast | 1,120 | steamer | cool / cool / cool | — | — |
| `taiya` | The Taiya valley | 1,133 | foot | cold / cool / cool | timber | 1.0 |
| `chilkootSummit` | The Chilkoot summit | 1,146 | foot | freezing / cold / cool | slides (major) | 1.0 |
| `lindeman` | Lindeman & the lakes | 1,153 | foot | freezing / cold / cool | timber, fishable, lakeIce | 1.0 |
| `upperLakes` | The upper lakes | 1,245 | boat | freezing / cold / cool | timber, fishable | 1.0 |
| `fiftyMile` | The Fifty Mile River | 1,270 | boat | freezing / cold / cool | timber, fishable, snags | 1.0 |
| `laberge` | Lake Laberge | 1,305 | boat | freezing / cold / cool | timber, fishable | 1.0 |
| `yukon` | The Yukon | ∞ | boat | freezing / cool / warm | timber, fishable, snags | 1.0 |
| *White Pass:* `skagwayValley` | The Skagway valley | 1,133 | foot | cold / cool / cool | timber, gentle | 0.9 |
| *White Pass:* `whitePassSummit` | The White Pass summit | 1,146 | foot | freezing / cold / cool | slides (minor), gentle | 0.9 |
| *White Pass:* `logCabin` | Log Cabin & the lakes | 1,153 | foot | freezing / cold / cool | timber, fishable, lakeIce, gentle | 0.9 |

Flags:
- **timber**: deadwood can be gathered (§12).
- **fishable**: fishing allowed.
- **lakeIce**: the thin-ice event.
- **slides**: daily snowslide hazard and the snowslide event (§12, §13).
- **snags**: daily gravel-bar hazard.
- **open**: seasickness weighting.
- **gentle**: the foot exertion term is ×0.75 (§10).

Steamer regions are always `cool` because passengers are below decks. Their legs ignore
temperature damage anyway (§12).

### Weather weights (ordered lists; order is data, as in 1849)

| region | W | Sp | Su |
|---|---|---|---|
| insidePassage | fair 30, rain 21, fog 15, wind 18, snow 16, clear 5 | fair 30, rain 30, fog 15, wind 12, snow 8, clear 5 | = Sp |
| queenCharlotte | wind 40, rain 25, fair 15, fog 15, snow 10, blizzard 11 | wind 30, rain 25, fair 15, fog 15, snow 10, blizzard 5 | = Sp |
| alaskaCoast | rain 28, fair 22, fog 14, snow 24, wind 20, clear 8, blizzard 4 | rain 28, fair 22, fog 14, snow 14, wind 14, clear 8 | = Sp |
| taiya | clear 28, snow 26, fair 16, wind 12, fog 8, blizzard 6, rain 4 | thaw 28, rain 20, fair 20, snow 10, fog 10, clear 8, wind 4 | thaw 30, rain 30, fair 20, fog 10, clear 10 |
| chilkootSummit | snow 24, wind 22, clear 18, blizzard 14, fog 14, fair 8 | thaw 22, snow 20, fog 16, wind 14, clear 12, blizzard 8, fair 8 | fog 25, rain 25, thaw 20, wind 15, fair 10, snow 5 |
| lindeman | clear 26, snow 24, wind 18, fair 14, blizzard 10, fog 8 | thaw 22, fair 22, snow 16, clear 16, wind 14, fog 10 | thaw 25, rain 25, fair 25, wind 15, fog 10 |
| skagwayValley | clear 26, snow 24, fair 16, wind 14, fog 8, rain 6, blizzard 6 | thaw 34, rain 24, fair 16, snow 8, fog 8, clear 6, wind 4 | thaw 34, rain 30, fair 16, fog 10, clear 10 |
| whitePassSummit | snow 24, wind 24, clear 18, fog 16, blizzard 10, fair 8 | thaw 26, snow 18, fog 18, wind 14, clear 10, fair 10, blizzard 4 | rain 30, fog 25, thaw 20, wind 15, fair 10 |
| logCabin | = lindeman W | = lindeman Sp | = lindeman Su |
| upperLakes | clear 26, snow 24, wind 18, fair 14, blizzard 10, fog 8 | ice 30, wind 22, fair 18, clear 12, rain 10, fog 8 | fair 30, wind 26, rain 14, clear 14, fog 8, ice 8 |
| fiftyMile | snow 50, clear 50 | ice 25, fair 25, clear 15, rain 15, wind 12, fog 8 | fair 34, clear 20, rain 16, wind 14, fog 8, ice 8 |
| laberge | snow 50, clear 50 | ice 45, wind 20, fair 15, fog 10, clear 10 | fair 26, wind 26, ice 18, rain 12, fog 10, clear 8 |
| yukon | snow 50, clear 50 | fair 25, ice 20, clear 15, rain 15, wind 12, fog 13 | fair 32, clear 20, hot 16, rain 16, wind 8, fog 8 |

### Seasonal and month rules (applied in this order, after picking the season's list)

1. **Ice finishes in July:** on boat legs, from July on (month ≥ 6) remove `ice` from
   the list. Lake Laberge's ice lasting into June is the June `ice 18`.
2. **Spring slide season:** `slides` regions use the higher daily hazard in Sp (§12).
3. The boat-leg W lists exist only for completeness. The ice gate (§14) means no boat
   travels before late May.
4. `forceFair` (from the sundogs event) forces **clear**, not fair.

Neither the albatross's curse nor 1849's North Atlantic or southern-winter bumps exist
here.

---

## 9. Weather

10 kinds. "Rough" (no fishing; drives the gale and storm style wear) = **wind**,
**blizzard**. `harsh` is hp lost per travel day.

| key | Display | speed × | wear × | harsh | Daily note when travelling |
|---|---|---|---|---|---|
| `clear` | Clear skies | 1.15 | 0.3 | 0 | — |
| `fair` | Fair | 1.0 | 0.25 | 0 | — |
| `rain` | Rain | 0.8 | 0.5 | 0 | — |
| `fog` | Low cloud | 0.6 | 0.15 | 0 | — |
| `snow` | Snowfall | 0.7 | 0.5 | 0 | — |
| `thaw` | Slush & mud | 0.55 | 0.9 | 0 | — |
| `wind` | High wind | 0.7 | 1.1 | 0.6 | — |
| `blizzard` | BLIZZARD (red, like STORM) | 0.2 | 2.2 | 1.5 | foot: `Snow so thick you can't see the trail poles.` |
| `ice` | Ice running | 0.35 | 1.2 | 0 | boat: `You pole your way between grinding cakes of ice.` |
| `hot` | Hot & buggy | 0.9 | 0.15 | 0.5 | `The mosquitoes come off the river in clouds.` |

`clear` at 1.15 is packed snow that sleds run on; on the river it is simply good going.
`hot` gets harsh 0.5 because the mosquitoes are a real misery; it is the only
non-rough weather with harsh.

### Scene palettes

Sky is 8 bands from `top` to `bottom` (horizon y = 46, as 1849). The ground below the
horizon is **water** on steamer and boat legs and **snow** on foot legs.

| key | top | bottom | water | snow | accent (wave/ripple dashes) | effects |
|---|---|---|---|---|---|---|
| clear | `#2F63A8` | `#BCDDF0` | `#23506E` | `#E9EFF4` | `#FFFFFF` | sun `#FFF1B8` |
| fair | `#3A6CA6` | `#A9CFE6` | `#24557A` | `#DCE5EC` | `#CFE3F0` | sun `#FFE58A`, clouds 1 |
| rain | `#3F4A57` | `#7E8A97` | `#22384C` | `#8E9488` | `#93A5B6` | rain, clouds 3 `#6B7584` |
| fog | `#8E979F` | `#C7CDD2` | `#5E6E7B` | `#C9CFD4` | `#B7C0C8` | fog overlay (1849's) |
| snow | `#5A6573` | `#A9B5C1` | `#2B3D50` | `#E4EAF0` | `#F4F7FA` | snow, clouds 3 `#8E99A5` |
| thaw | `#6F7E8C` | `#B9C4C9` | `#34505E` | `#9DA391` | `#C4CBC0` | light rain (20 streaks), clouds 2 `#8C969F` |
| wind | `#354251` | `#6F7E8E` | `#1F3346` | `#C8D2DC` | `#E6EDF3` | rough 2, clouds 3 `#56626F`; on foot, **blowing snow**: 24 white 3×1 streaks moving left at 90 px/s |
| blizzard | `#1B2028` | `#4A5360` | `#141F2B` | `#B5C0CB` | `#D8E0E8` | rough 3, heavy snow (60 flakes, drifting left 40 px/s), whiteout overlay `rgba(220,228,235,.25)` |
| ice | `#6C8FB0` | `#C9DDEA` | `#3D6378` | `#E0E8EE` | `#F2F7FA` | **ice floes**: 6 white `#F2F7FA` 6×2 slabs drifting with the water dashes |
| hot | `#D98A3D` | `#F4D88C` | `#3C6A70` | `#D8D2B8` | `#A9CACC` | sun `#FFF4C2`, still, **mosquitoes**: 12 `#2A2A2A` 1×1 specks jittering ±1 px |

The northern-lights event (§13) may tint the sky bands with a green `#6FE3A0` ribbon at
y 6–14 for as long as its message is shown. This is optional polish.

---

## 10. Pace & rations

### Pace

| key | Name | speed factor | hp/day: foot | hp/day: boat | hp/day: steamer | wear × | Description |
|---|---|---|---|---|---|---|---|
| `easy` | Easy going | 0.75 | −0.4 | +0.5 | 0 | 0.6 | `Light loads and early camps; on the river, let the current do the work. Gentle on gear and people.` |
| `steady` (default) | Steady | 1.0 | −1.4 | 0 | 0 | 1 | `A fair day's work, trail or river.` |
| `full` | Hard driving | 1.3 | −2.8 | −1 | 0 | 2 | `Heavy packs, long days, oars always in the water. Fast, but hard on sleds, boats and backs.` |

**Foot exertion is new: 1849's pace hp is per leg here.** Hauling a ton over a pass, a
load at a time, wears people down in a way sailing never did. Without that cost the
trail would be only cold and time. With it, the poor roles' meager rations really hurt
(§18). On `gentle` (White Pass) regions the foot value is ×0.75.

**Base speed per leg** (units per day at speed factor 1, before weather):

| leg | base | Easy | Steady | Full | notes |
|---|---|---|---|---|---|
| steamer | 2,200 | 2,200 | 2,200 | 2,200 | Passenger: pace is ignored. |
| foot | 9 | 6.75 | 9 | 11.7 | 0.9 mi a day: relaying the whole outfit |
| boat | 300 | 225 | 300 | 390 | 30 mi a day |

On the steamer, the pace screen adds
`[dim]Aboard the steamer, the captain sets the pace. It will matter on the trail.[/dim]`

### Rations (the 1849 numbers, new text)

| key | Name | lb/person/day | hp/day | Description |
|---|---|---|---|---|
| `filling` (default) | Square meals | 3 | +1 | `3 lbs a day. Flapjacks, bacon and beans, three times over.` |
| `meager` | Short commons | 2 | −0.3 | `2 lbs a day. Two small meals and a lot of tea.` |
| `bare` | Scraping by | 1 | −2.2 | `1 lb a day. A biscuit and a strip of bacon.` |

Rations screen: `Rations are currently [amber]{name}[/amber]. With {n} in the party, that's {lbs} lbs a day.`

---

## 11. Ailments

| ailment ("NAME has ___") | dmg/day | duration | cause of death ("died of ___") |
|---|---|---|---|
| scurvy | 2.2 | until cured | scurvy |
| pneumonia | 4.5 | 6–10 | pneumonia |
| typhoid fever | 5.5 | 7–12 | typhoid fever |
| a fever | 3 | 4–7 | a fever |
| dysentery | 4.5 | 5–9 | dysentery |
| frostbite | 2.5 | 5–9 | frostbite |
| snow blindness | 1.0 | 2–4 | a fall on the ice |
| a broken leg | 1.2 | 14–24 | an infected wound |
| exhaustion | 1.5 | 3–5 | exhaustion |

**Sickness pools** (1849's `sicken` structure):
- **Fever port** (Dyea, Skagway): typhoid fever, a fever, dysentery.
- **hot**: a fever, dysentery, exhaustion, typhoid fever, a broken leg. No region is
  `hot`; this pool is kept for completeness.
- **cold / freezing**: pneumonia, frostbite, snow blindness, a fever, a broken leg.
- **otherwise** (cool, warm): a fever, dysentery, a broken leg, exhaustion, pneumonia.

**Messages:**
- `{name} has {ailment}.`
- Scurvy adds ` [dim]Soft gums, and old bruises that won't fade. Lime juice or a stay in town will cure it.[/dim]`
- A treated illness adds ` [dim]You open the medicine chest ({n} kits left).[/dim]`
- Recovery: `{name} is well again.` · `{name} is recovering from scurvy.`

Deaths with no ailment: `exposure` if out of firewood, else `starvation`, else
`exhaustion`. This is 1849's thirst / starvation / exhaustion, with "exposure" in
place of thirst.

---

## 12. Daily rules

What changes from 1849 is listed; anything not mentioned is 1849's rule unchanged.

### One travel day (`sailDay`)

1. Clear the note. Day += 1. Roll the weather for the region (§8).
2. **Speed.**
   - Steamer leg: `sp = 2200 × weather.speed × rnd(0.85, 1.15)`, with nothing else.
   - Foot and boat legs:
     `sp = legBase × pace.factor × weather.speed`
     `× (0.45 + 0.55 × prop/100) × (0.75 + 0.25 × struct/100) × crewFactor` (1849's)
     `× region.speed` (White Pass 0.9)
     `× (foot leg: role trail ×1.15 for the miner)`
     `× (foot leg, packers hired, mile < 1,136.5: ×1.4)`
     `× rnd(0.85, 1.15)`.
   - `d = max(0, jsRound(sp))` units. Clamp to the next stop as 1849.
3. Daily note (§9) where the weather has one.
4. `consume(.travel)`, `health(.travel)`; stop if over. `wear()`; stop if over.
5. If not arrived, check at most one of these, in this order (1849's Strait / Horn / event
   chain):
   - **Snowslide** in a `slides` region: daily chance **2%** on the Chilkoot summit in
     Sp, otherwise **0.5%**. On the White Pass summit **0.5%** in Sp, otherwise
     **0.2%**. Effect in §13 (H1).
   - else **Snag** in a `snags` region: **2.5%** (Easy ×0.6, Full ×1.6). Effect in §13 (H2).
   - else **11%** random event (§13).
6. If arrived: stopIndex += 1 and queue the arrival.

### Consumption (`consume`)

- **Food:** `n × rations.lb`. Unchanged.
- **Firewood (the water role):** `need = n × 4 × tempFactor`, with tempFactor
  freezing 2 · cold 1.5 · cool 1 · warm 0.5 · hot 0.5. On **steamer** legs `need = 0`.
  If short: firewood = 0 and the out-of-firewood flag (1849's `thirst`) is set.
- **Lime juice:** 1849's citrus rule (town resets `noLime`; else 0.02 × n a day).
  **Onset day 35**, as 1849.
- **Deadwood (replaces the rain catch):** if not in town, the region has `timber`, the
  weather is not blizzard, and firewood is below capacity, add `ri(20, 50)` lbs.
  Note: `The party gathers {n} lbs of deadwood.`
- **Warnings** (1849's flags and thresholds):
  - `[red]The grub is gone![/red] Your party is starving.`
  - `The cook warns you: provisions will last about a week.`
  - `[red]The woodpile is gone![/red] Without a fire, the cold will kill you within days.`
  - `The woodpile is nearly gone — a few days left.` (below 5 days of need; no warning
    while need is 0)
  - `The last of the lime juice is gone. Scurvy will follow within a few weeks unless you find fresh food.`

### Health (`health`) — differences from 1849

- Pace hp comes from the leg table (§10). Steamer: 0.
- Out of firewood: **−12** and **+0.04** illness, exactly where 1849 applies thirst.
- Temperature (not in town): freezing `−(warm ? 1.4 : 4.5) − (deep winter ? 1 : 0)`.
  Cold and hot are as 1849. **Steamer legs take no temperature damage.**
- Everything else (camp +3, town +6, ailments, natural +1, illness formula, fever port,
  scurvy roll) is 1849's.

### Wear (`wear`) — foot and boat legs only (none on the steamer)

- Propulsion: `−= pace.wear × weather.wear × rnd(0.6, 1.4)`.
- Structural: `0.03`, plus:
  - in a **blizzard** (1849's storm): `rnd(1, 2.6) × (full 1.6 / easy 0.7 / steady 1) × (slides region ×1.5)`;
  - in **wind** (1849's gale): `rnd(0, 0.8) × (full 1.5)`;
  - in **ice**: `rnd(0, 1.2) × (full 1.5)`.
- Structural below 35 and food above 50: a 6% chance of losing `ri(20, 60)` lbs.
  - Outfit: `Meltwater has gotten into a cache. {n} lbs of provisions are spoiled.`
  - Boat: `The bilge is full and the grub is in it. {n} lbs of provisions are spoiled.`
- Warnings at the 1849 thresholds:
  - Outfit below 30: `[red]Your outfit is falling apart.[/red] Sacks split, tarps in rags — patch it before you lose it.`
  - Boat below 30: `[red]She's leaking like a basket.[/red] Somebody bails day and night. Patch her — soon.`
  - Sleds below 25: `[red]Your sleds are wrecks and your straps are knotted string.[/red] Every load takes twice as long. Mend them if you can.`
  - Oars below 25: `[red]The sail is in rags and you're down to one good oar.[/red] She barely answers the sweep. Mend them if you can.`

### Days without travel (`passDays`)

As 1849: in town the weather is fair. Camp days roll weather, consume (deadwood
gathering included) and apply health. There is no wear and no events.

### Repairs in camp ("Make repairs")

Screen heading `Repairs`.
Intro: `Each repair takes a day.`, plus for the boatbuilder ` As a boatbuilder, your repairs go much further.`

| vehicle | choice | message (then 1 camp day) |
|---|---|---|
| outfit | `Patch the outfit — 1 bundle of canvas & pitch [dim](have {n})[/dim]` | `You spend the day re-sacking split flour and lashing new tarps over the caches. [green](Outfit now {n}%)[/green]` |
| outfit | `Mend sleds & straps — 1 coil of rope & rawhide [dim](have {n})[/dim]` | `A day of splicing, lacing and shaving new runners. [green](Sleds now {n}%)[/green]` |
| boat | `Patch the hull — 1 bundle of canvas & pitch [dim](have {n})[/dim]` | `You haul her up on the gravel, tack canvas over the worst seams and pay them with hot pitch. [green](Boat now {n}%)[/green]` |
| boat | `Re-rig oars & sail — 1 coil of rope & rawhide [dim](have {n})[/dim]` | `You shave a new oar from a spruce and lace up the sail. [green](Oars & sail now {n}%)[/green]` |
| — | `Done` | — |

### The yard (1849's shipyard)

Costs are 1849's: structural `ceil((100 − s) × 2.5 × mult)`, propulsion
`ceil((100 − p) × 1.8 × mult)`. Each job restores the meter to 100 and takes 1 town day.
Intro: `You have [amber]${n}[/amber]. Each job takes a day.`

| vehicle | menu label | structural job → message | propulsion job → message | leave |
|---|---|---|---|---|
| outfit | `Visit the outfitters' yard` | `Have the outfit re-sacked and re-tarped — ${cost}` → `A crew re-sacks, re-crates and re-tarps the lot. Your outfit is as good as new.` | `Have the sleds and harness made good — ${cost}` → `The sled maker fits new runners and fresh harness.` | `Leave the yard` |
| boat | `Visit the boatwrights` | `Have her hauled out and recaulked — ${cost}` → `The boatwrights haul her out and recaulk every seam. She's tight.` | `Have new oars and a sail made — ${cost}` → `New oars, a new sweep, and a sail sewn from good duck.` | `Leave the boatwrights` |

At Bennett before a boat exists, this slot is `See about a boat` (§14).

### Departure from Seattle

- No food: `You can't go north with no provisions! The outfitter laughs and points you back inside.`
- **New:** if provisions are below 1,095 × the party size, warn first:
  `You have [amber]{n} lbs[/amber] of provisions. The police at the summit will want [amber]{m}[/amber] — a year's worth for every one of you.`
  Options: `Back to the shop` / `Leave anyway`.
- Message: `Your steamer backs away from the Seattle waterfront on {date}, so crowded that people are sleeping on the freight. Behind you the city's hills sink into the rain. Ahead lie a thousand miles of coast, a mountain pass and a river.`
  Button: `Steam north`.

### Shell labels that change with the leg

- **Travel button** (1849's "Heave to & take stock"): `Stop & take stock`.
- **Status panel rows:**
  - `Weather` (BLIZZARD in red)
  - `Health`
  - `Provisions` `{n} lbs`
  - `Firewood` `{n} lbs`
  - `Next: {short}` `{n} mi`
  - `Traveled` `{x} of 1,700.0 mi`
  - `Outfit · Sleds` or `Boat · Oars` `{s}% · {p}%`
  - the teal note line.
- **Away-from-town menu:**
  - `Continue on your journey`
  - `Check supplies & party`
  - `Look at the map`
  - `Change pace [dim]({pace})[/dim]`
  - `Change rations [dim]({rations})[/dim]`
  - rest: `Rest in your bunk` on the steamer, `Make camp and rest` on foot or boat
  - `Make repairs`
  - `Go fishing`
- **Rest prompts:**
  - Camp: `You make camp and the party rests. How many days?`
  - Steamer: `You keep to your bunk. How many days?`
  - Town: `Your party can sleep under a roof, eat a cooked meal and recover. How many days?`
  - Result: `After {n} day(s) of rest, your party's health is [{c}]{label}[/{c}].`
  - Cancel: `Never mind`.
- **Town menu, first choice:**
  - Steamer port: `Back aboard and steam on`
  - Foot port: `Shoulder your packs and move on`
  - Bennett and Selkirk: `Push off and float on`
- **Town menu, other choices:** `Check supplies & party` · `Look at the map` · pace ·
  rations · `Rest in town` · `Look for a trade` · `Talk to people` · `Buy supplies` ·
  the yard label.
- **Trade:**
  - Intro: `A packer outside the store looks over your goods.`
  - Nothing to offer: `You ask around, but nobody wants what you have.`
  - No trades left: `Nobody else in camp wants to trade with you today.`
  - Done: `Done. Goods change hands.`
  - Port trades per visit: 3, as 1849.
- **Supplies screen:**
  - Heading `Supplies`; then `Your outfit` (outfit state) or `The [i]{boat}[/i]` (boat).
  - Meter rows `Outfit`/`Sleds` or `Boat`/`Oars & sail`.
  - Below the meters: `Pace: … · Rations: …`, adding `· [red]{n} days without lime juice[/red]` when over 20.
  - Then `Party · health {label}`, `[red]Only {n} of {m} have furs.[/red]`, and `Lost`.

---

## 13. Random events

**Eligible-list weights, conditions and effects.** "Leg" is the current region's leg.
"Healthy" means alive with no ailment. Order is data: build the list in this order.

| # | weight | condition | effect |
|---|---|---|---|
| E1 | 6 | food > 150 | food −= `ri(100, 300)` |
| E2 | 5 | firewood > 120, leg ≠ steamer | firewood −= `ri(40, 120)` (min 0) |
| E3 | 4 | leg = boat, temp cool/warm/hot | food += `ri(15, 40)` |
| E4 | 3 | leg ≠ steamer | 50%: canvas & pitch += `ri(1, 2)`; else 60%: food += `ri(60, 120)`; else flavor (`{other}` = a random boat name other than the player's, as 1849's nameboard) |
| E5 | 6 | (foot and weather wind/blizzard/thaw/snow) or (boat and weather wind/ice) | propulsion −= `ri(12, 28)` |
| E6 | 4 | (foot and rough) or (boat and weather wind/ice) | propulsion −15, structural −6, then 50%: a random healthy member gets a broken leg (`ri(14, 24)` days, −10 hp); check ruin |
| E7 | 4 | always | structural −= `ri(8, 18)`; check ruin |
| E8 | 3 | (foot, temp cold/freezing, weather wind/blizzard/thaw) or (boat, weather wind/ice) | 1849 overboard roll on a non-captain: 65% −25 hp (min 1), else lost |
| E9 | 1.5 | food > 100, leg ≠ steamer | food −= `ri(60, 180)`, structural −4; check ruin |
| E10 | 3 | leg = steamer and (rough or rain or region `open`) | every living member −4 hp (min 1) |
| E11 | 2.5 | leg ≠ steamer | **Quitters** (choice) |
| E12 | 1.5 | not yet seen, mile < 1,133.0 | **A partner** (choice), the stowaway analog |
| E13 | 5 (Chilkoot) / 2 (White Pass) | `slides` region and (weather snow/thaw/blizzard or month Mar/Apr) | **Snowslide warning** (choice) |
| E14 | 3 | `lakeIce` region, temp cold/freezing, season ≠ Su | **Thin ice** (choice), the icebergs analog |
| E15 | 2 | leg = boat, not yet seen | **Gold rumour** (choice) |
| E16 | 2 | temp cold/freezing, month Sep–Apr | flavor |
| E17 | 1.5 | rough | `forceFair = 2` (forces **clear**) |
| E18 | 3 | `timber` region, `noLime` > 5 | `noLime = 0` |

### Message texts

- **E1** `Damp has gotten into the flour sacks. {n} lbs of provisions have gone sour and moldy.`
- **E2** `The woodpile has been soaked through. {n} lbs of firewood will only hiss and smoke.`
- **E3** `A family drying salmon at a camp on the bank trades you fresh fish for a little tea and sugar. +{n} lbs of provisions.`
- **E4**
  - foot, canvas: `Someone has given up and left an outfit by the trail. Your party salvages {describe}.`
  - boat, canvas: `A wrecked boat lies on a gravel bar. Your party salvages {describe}.`
  - foot, food: `A sack of beans and a side of bacon lie beside the trail, abandoned and still sound. +{n} lbs of provisions.`
  - boat, food: `A crate of tinned goods bobs against the bank, still sealed. +{n} lbs of provisions.`
  - foot, flavor: `You pass an abandoned sled with a name burned into the crossbar: [i]{other}[/i]. Nobody says much for the rest of the day.`
  - boat, flavor: `You pass a broken boat on a sandbar with a name painted on her bow: [i]{other}[/i]. Nobody says much for the rest of the day.`
- **E5**
  - foot: `A sled runner splits on a hidden rock, and a pack strap goes with it. [red](Sleds −{n}%)[/red]`
  - boat in ice: `A cake of ice catches the steering sweep and snaps it like a match. [red](Oars & sail −{n}%)[/red]`
  - boat in wind: `A gust splits the sail from yard to foot with a bang. [red](Oars & sail −{n}%)[/red]`
- **E6**
  - foot: `A loaded sled gets away on the steep pitch and runs wild down the slope, spilling sacks the length of the hill. [red](Sleds −15%, Outfit −6%)[/red]`
  - boat: `A squall comes down the water and swamps her to the gunwales before you can reach the shore. [red](Oars & sail −15%, Boat −6%)[/red]`
  - injury (both): `\n\n{name} was in the way, and has a broken leg.`
- **E7**
  - steamer: `The steamer rolls hard all night and the freight shifts. Crates of your outfit are smashed. [red](Outfit −{n}%)[/red]`
  - foot: `Water has gotten under the tarps at your cache. Sacks are splitting and crates coming apart. [red](Outfit −{n}%)[/red]`
  - boat: `She grinds over a hidden rock and a plank starts. [red](Boat −{n}%)[/red]`
- **E8** (grave cause `drowned`)
  - foot, saved: `{name} breaks through the ice at a creek crossing! The others haul {name} out, soaked and blue with cold.`
  - foot, lost: `{name} breaks through the ice at a creek crossing, and the current takes {name} under. [red]{name} is gone.[/red] There was nothing anyone could do.` Epitaph: `Lost through the ice. No grave but the creek.`
  - boat, saved: `The boat lurches in fast water and {name} goes over the side! You get an oar to {name} and haul {name} back aboard, half-drowned.`
  - boat, lost: `The boat lurches in fast water and {name} goes over the side. [red]{name} is gone.[/red] In that current, there was no going back.` Epitaph: `Lost to the river. No grave but the Yukon.`
- **E9** `The stovepipe sets the tent roof alight! You beat it out, but {n} lbs of provisions are scorched and ruined. [red]({S} −4%)[/red]`
- **E10** `The steamer pitches and rolls for a day and a night. Half the passengers are seasick, and your party is in the worse half. [red](Health suffers.)[/red]`
- **E16** `The northern lights hang over the mountains all night, green curtains folding and unfolding. Nobody wants to go to sleep.`
- **E17** `Bright sundogs blaze on either side of the sun. The old-timers say the blow is breaking up.`
- **E18** `An old-timer shows you how to brew tea from spruce tips. It tastes like the inside of a turpentine barrel, but everyone drinks it. [green](Good against scurvy.)[/green]`

### Daily hazards (from §12 step 5)

- **H1 Snowslide** (no choice):
  - 50%, cache: structural −`ri(10, 25)`, food −`ri(100, 300)`; check ruin.
    `A slide comes down off the mountain in the night and buries part of your cache. [red]({S} −{n}%, {m} lbs of provisions lost)[/red]`
  - 50%, a person, picked from **all** living members, captain included (unlike 1849's
    overboard): 60% −30 hp (min 1), else lost.
    - Saved: `A roar, a white wall — and {name} is under the snow. You dig with your hands and pull {name} out, alive and half-frozen.`
    - Lost: `A roar, a white wall — and {name} is under the snow. You dig until dark. [red]{name} is gone.[/red]` Grave cause `a snowslide`, epitaph `Under the snow on the pass.`
  - If the captain is lost: game over with title `You, {name}, have been lost in a snowslide.` and the captain-death body (§17).
- **H2 Snag:** structural −`ri(8, 20)`, day += 1; check ruin.
  `She runs hard onto a gravel bar hidden under the brown water. It takes a full day of wading and prying to get her off. [red](Boat −{n}%)[/red]`

### Choice events (exact text)

**E11 Quitters** (the strange-sail analog).
- Prompt, foot: `A party coming back down the trail hails you. They're done with the North and want to sell out before they go home.`
- Prompt, boat: `A boat is tied up at the bank, and the people in it wave you over. They've had enough, and want to sell out before they turn back.`
- Options: `Hear them out` / `Keep going`
- **Hear them out:** 65%: `makeOffer()` → trade screen, intro `They're sick of the North and want to trade.`
  - If there is no offer: `They have nothing you need. They wish you luck and go on toward the coast.`
  - 35% swindle: lose `min(floor(money), ri(40, 140))`. `It's a crooked game of chance, and the "quitters" are partners in it. By the time you see the trick, ${n} of yours has changed hands.`
- **Keep going:** `You wave and keep moving. Behind you, someone laughs.` No cost; the
  risk is all on the other side.

**E12 A partner** (the stowaway analog). Name = a random unused first name. `{next}` =
the next port's name.
- Prompt, steamer: `Two days out, the purser finds a youngster hiding among the freight with no ticket, no outfit and no money — only a great wish to see the Klondike. The name is {name}.`
- Prompt, foot: `A young stampeder is sitting on a sack beside the trail. {name}'s partners quit and went home, and took the outfit with them.`
- Options: `Take {name} on as a partner` / `Feed {name} and send them on to {next}`
- Partner: joins at 85 hp. `{name} shakes your hand and picks up a pack. One more back on the trail — and one more year's grub the police will want to see.`
- Send on: joins at 85 hp with `leaveAt` = the next port's stop id. `{name} will travel with you as far as {next}.`
- The mile < 1,133.0 condition means the next port is always before the summit, so a
  sent-on partner never counts at the police check. A kept one does.

**E13 Snowslide warning** (the second icebergs analog).
- Prompt: `The snow on the slope above the trail is booming and cracking. The packers ahead of you have stopped and are looking up.`
- Options: `Wait in camp until it settles (2 days)` / `Push on`
- **Wait:** 2 camp days. `You wait two days in camp while the mountain grumbles. On the third morning it is quiet, and you go on.`
- **Push on:** risk = 0.15 + (thaw 0.15) + (Full pace 0.10). On a slide, use H1's
  effects and texts. Otherwise: `You push on under the slope, nobody speaking. The mountain holds.`

**E14 Thin ice** (the icebergs analog).
- Prompt: `The trail runs straight across the frozen lake — but the ice is grey, and in places you can see water moving under it.`
- Options: `Go round by the shore (lose a day)` / `Cross on the ice`
- **Go round:** one travel day of consume and health, no distance. Then 10%: structural
  −`ri(4, 10)`, `An extra day around by the shore, and a sled overturns on the rocks. [red](Outfit −{n}%)[/red]`. Else `It takes an extra day to haul around by the shore, over rocks and drifts, but you all get there.`
- **Cross:** risk = 0.12 + (thaw 0.15) + (Full 0.15). On a break-through: structural
  −`ri(5, 15)`, `With a crack like a rifle shot, the ice gives way under a loaded sled! [red](Outfit −{n}%)[/red]`, then E8's foot overboard roll and texts. Otherwise: `You spread out and cross fast, listening to the ice tick and groan. Nobody goes through.`

**E15 Gold rumour.**
- Prompt: `At a camp on the bank, a man is shouting that there's gold in a creek just up the valley — coarse gold, right on the bedrock — and half the camp is already running.`
- Options: `Join the stampede (3 days)` / `Stay with the boat`
- **Join:** 3 camp days, then 15%: money += `ri(40, 160)`, `Three days of bog and mosquitoes, and at the end of it — color in the pan! You stake a claim and, back at the river, sell it to a speculator for ${n}.`
  - Else: `Three days of bog and mosquitoes, and at the end of it a creek staked from end to end by people who got there yesterday. You come back to the boat empty-handed and bitten all over.`
- **Stay:** `You let them run. By nightfall the first of them are trickling back, saying nothing.`

---

## 14. Landmarks & fork

### Stop 2 — the head of Lynn Canal (fork)

- Prompt: `Your steamer noses up the head of Lynn Canal between mountains that go straight up into the cloud.`
  In Sp add ` [red]The snow on the passes is going rotten. It's slide season.[/red]`
- Detail: `Two landings lie a few miles apart. From [amber]Dyea[/amber] the trail goes over the [amber]Chilkoot Pass[/amber]: short, steep, too steep for anything but people. From [amber]Skagway[/amber] it goes over the [amber]White Pass[/amber]: lower and longer, and a bog whenever it isn't frozen.`
- Options: `Land at Dyea for the Chilkoot` · `Land at Skagway for the White Pass` · `Ask the purser's advice`

**Routes.** The **Chilkoot** keeps `taiya`, `chilkootSummit`, `lindeman`, and uses the
Dyea, Sheep Camp, Chilkoot-summit and Lindeman stop variants. The **White Pass** swaps
in `skagwayValley`, `whitePassSummit` and `logCabin` (speed 0.9, gentle grade,
fewer slides). It uses the Skagway, White Pass City, White Pass summit and Log Cabin
variants. Both rejoin at Bennett.

- **Chilkoot:** `passage = chilkoot`. Then the guide offer:
  - Prompt: `As you anchor off Dyea, a man rows out in a skiff. His crew of packers will carry a share of your outfit to the summit, so your own relays go faster — for $90.`
  - Detail: `[dim]You have ${money}.[/dim]`
  - Options: `Hire the packers ($90)` (disabled if money < 90) / `Pack it all yourselves`
  - **Hire:** money −90, `packers = true` (foot speed ×1.4 until mile 1,136.5).
    `The head packer weighs your sacks on a spring scale, names a load for each of his crew, and they set off up the valley at a pace that makes you tired just watching.`
  - **Yourselves:** `You look at the mountains, then at your sacks, then at each other. Nobody says anything. You start sorting loads.`
- **White Pass:** `passage = whitePass`. `You make for Skagway, where the wharf is long, the street is mud, and everyone seems to have something to sell you.`
- **Advice** (then back to the fork): `The purser leans on the rail: “The Chilkoot's shorter, and the steps up the last pitch will break your heart and nothing else. The White Pass is easier going and ten miles longer, and when it thaws it's a swamp. In the cold months, take the Chilkoot — and if you can pay for packers, so much the better. Come slide season, I'd want the White Pass.”`

### Stop 5 — the summit (police check)

`req = 1,095 × living members`.

- Prompt, Chilkoot: `You have reached the summit of the Chilkoot Pass — and the border. A British flag snaps over a log hut half buried in snow, and a mounted policeman in a buffalo coat is weighing outfits.`
- Prompt, White Pass: `You have reached the summit of the White Pass — and the border. A British flag flies over a cluster of tents, and the mounted police are checking every outfit that comes up the trail.`
- **Food ≥ req:**
  - Detail: `“A year's grub for each of you, that's the rule. Three pounds a head a day.” He looks over your sacks and nods. “You'll do. Welcome to Canada.”`
  - Option: `Carry on to the lakes`
- **Food < req:**
  - Detail: `“A year's grub for each of you. That's [amber]{req} lbs[/amber], and you have [amber]{food}[/amber].” He folds his arms. “Nobody goes into the Yukon to starve on my watch.”`
  - Options:
    1. `Buy the difference from the traders at the summit (${a})`, with `a = ceil(short × 0.30)`; disabled if money < a.
       → food += short, money −a.
       `A trader with a sled full of flour is delighted to see you. [amber](+{short} lbs of provisions)[/amber] The constable waves you through.`
    2. `Go back down to {camp} for more (6 days, ${b})`, with `back = short + n × rations.lb × 6` lbs and `b = ceil(back × {camp's food price})` ($0.19 Sheep Camp, $0.18 White Pass City); disabled if money < b.
       → money −b, 6 camp days in the current region, then food += back.
       - Chilkoot: `Six days down the Golden Stairs and back up again, with sacks on your backs. The constable remembers you, and this time he waves you through.`
       - White Pass: `Six days down to White Pass City and back up again, with sacks on your backs. The constable remembers you, and this time he waves you through.`
    3. `Turn back for home` → game over (§17, "turned back").
  - If neither 1 nor 2 is affordable, 3 is the only enabled option.

### Stop 6 — Lindeman / Log Cabin (mark)

- Chilkoot: `The trail drops out of the rocks to Lake Lindeman. There are trees again, and tents, and the rasp of whipsaws in every direction. Some parties build their boats right here, but Bennett is only a few miles on, and the timber is better there.`
- White Pass: `At Log Cabin the trail comes down into stunted pines and a few huts. The worst of the pass is behind you. From here it's a long, flat haul to Lake Bennett, where everybody is building boats.`

### Stop 7 — Lake Bennett (special: boat + port)

**Arrival:** port arrival with the single option `Make camp at the lakes`, then the
town menu. The **breakup date** is rolled on arrival: `May 24, 1898 + ri(0, 8)` days
(May 24 – June 1; historically May 29). Until a boat exists, the yard slot reads
`See about a boat`.

**See about a boat** — prompt `Lumber, pitch and know-how make a boat. You can saw your own, buy one, or make do.` Options:

| option | needs | days | result (Boat / Oars & sail) | boatbuilder |
|---|---|---|---|---|
| `Whipsaw lumber and build her properly — 3 weeks [dim](3 canvas & pitch, 2 rope)[/dim]` | 3 canvas, 2 rope | 21 camp days | 100 / 100 | 14 days (label `— 2 weeks`) |
| `Knock a scow together in a hurry — 9 days [dim](2 canvas & pitch, 1 rope)[/dim]` | 2 canvas, 1 rope | 9 camp days | `60 + ri(0, 15)` / 80 | 6 days, `85 + ri(0, 10)` / 95 |
| `Buy a boat from the sawmill crew — $220` | $220 | 2 town days | `90 + ri(0, 10)` / 100 | same |
| `Lash a raft together from green logs — 5 days` | nothing | 5 camp days | `35 + ri(0, 10)` / 50 | 4 days, `45 + ri(0, 10)` / 50 |
| `Not yet` | | | | |

Options with missing stores or money are disabled. The days pass first (with their
messages). Then the meters switch to the boat state (§4), followed by the message:

- Proper: `Two of you on the whipsaw, one above the log and one below, from first light to dark. It takes {three weeks|two weeks} and most of your good humor, but she's a real boat — ribbed, planked, caulked and pitched, with a square sail sewn from flour sacks. You paint [i]{boat}[/i] on her bow.`
- Scow: `Green planks, too few nails and a great deal of pitch. She's ugly and she leaks a little, but she floats. You paint [i]{boat}[/i] on her bow anyway.`
- Bought: `The sawmill crew has a boat that a party of quitters left behind. You haggle, pay, and paint [i]{boat}[/i] over the old name.`
- Raft: `Logs, rope, a sweep at each end and a prayer. The old-timers shake their heads, but a raft is a raft. You carve [i]{boat}[/i] into the front log.`
- Each is followed by `[dim](Boat {s}% · Oars & sail {p}%)[/dim]`.

**Pushing off** (town menu `Push off and float on`):
- No boat: `You can't float to Dawson on a sled. See about a boat first.`
- **Ice gate:** if today is before the breakup date:
  - Prompt: `Lake Bennett is still white from shore to shore. Nobody is going anywhere until the ice goes out.`
  - Options: `Wait in camp for the ice to go out` / `Not yet`
  - **Wait:** camp days until the breakup date (weather, consume, health; deadwood is
    gathered). Then `On {date} the ice goes out with a long groan and a crack like a rifle shot. By noon the lake is full of sails. You push off with the rest.` Travel resumes.
- If the ice is already out, departure is immediate.

Waiting in town (`Rest in town`) is allowed: +6 hp a day and scurvy resets, but no
gathering, so firewood must be bought. Firewood at Bennett costs $0.011/lb.

### Stop 8 — Tagish (mark)

`At the police post at Tagish every boat is stopped. A constable paints a number on your bow and writes down everyone aboard — and the name of someone to write to if you never turn up in Dawson. Nobody talks much for the next few miles.`

### Stop 9 — Miles Canyon (special)

- Prompt: `Below Marsh Lake the river narrows and quickens, and then you hear it: Miles Canyon, a slot of black rock a few boat-lengths wide, with the White Horse Rapids roaring below it. Wrecked boats and split sacks line the shore.`
- Detail: `A mounted policeman at the head of the canyon has the say here now: any boat going through takes a registered pilot. You can pay one, or unload, carry your outfit around on your backs and let the empty boat down on ropes.`
- Options: `Hire a pilot to run her through ($25)` (disabled if money < 25) · `Portage the outfit and line her down (4 days)` · `Ask the constable's advice`
- **Pilot:** money −25. 6% chance of Boat −`ri(5, 15)`:
  `Even a pilot can't miss every rock. She shudders, slews round and comes through with a plank stove in. [red](Boat −{n}%)[/red]`
  Else: `A pilot steps aboard, takes the sweep, and says nothing at all for six of the longest minutes of your life. Then you're through, soaked and laughing, in the slack water below the rapids.`
- **Portage:** 4 camp days, then a chance of 15% (+10% if Boat < 50) of Boat −`ri(10, 25)`:
  `Halfway down, a line parts. She bangs from rock to rock before you catch her in an eddy. [red](Boat −{n}%)[/red]`
  Else: `Four days of hauling sacks along the rim and paying out rope from rock to rock. Your hands are raw, but she's down, and so is everything you own.`
- **Advice** (then back): `The constable takes his pipe out of his mouth: “Five drowned and a couple of hundred boats smashed before we made the rule. The pilots know the water. If you line her down, keep a hand on every rope — she'll try to get away from you at the bottom.”`
- Check ruin after any damage.

### Stop 10 — Five Finger Rapids (special)

- Prompt: `Four great towers of rock stand across the river like fingers, and the Yukon pours between them through five channels.`
- Detail: `The right-hand channel is the one the steamboats use. Run it straight and fast, or let her down along the right bank on ropes.`
- Options: `Run the right-hand channel` · `Line her down along the bank (2 days)`
- **Run:** risk = 0.12 + (Full 0.10) + (Boat < 40: 0.10). On a hit: Boat −`ri(12, 30)`,
  `The current shoves you at the rock. She strikes hard, swings, and comes off through the gap half full of water. [red](Boat −{n}%)[/red]`. Then 30%: E8's boat overboard roll and texts, with the lost-at-sea epitaph `Taken by the river at Five Fingers.`
  Else: `You aim for the right-hand gap, the rock slides by close enough to touch, and the standing waves throw spray over everyone. Then the river widens and goes quiet. Rink Rapids, a little below, is nothing after that.`
- **Line:** 2 camp days, then a chance of 5% (+10% if Boat < 50) of Boat −`ri(8, 20)`:
  `A rope slips and she grinds along the rocks before you check her. [red](Boat −{n}%)[/red]`
  Else: `Two days of easing her down from rock to rock along the right bank. Slow, wet and safe.`

### Stop 12 — Dawson City (end) → finale (§17).

---

## 15. Mini-game skin — Fishing

- **Allowed** only in `fishable` regions (the Lindeman / Log Cabin lakes on foot; every
  boat region) and not in rough weather. Refusals:
  - `You have no hooks and line left.`
  - `The wind's far too high to fish.` (rough)
  - `There's nothing to fish in up here but snow.` (foot, not fishable)
  - `The steamer won't stop so you can fish.` (steamer)
- **Screen:**
  - Heading `Fishing`; HUD `Casts: {n}` · `Caught: {n} lbs` · `Time: {n}` (25 s, as 1849).
  - Hint: `Tap the water to cast. Each cast uses a hook. You can smoke and keep up to 150 lbs.`
  - Button: `Back to camp`.
  - Accessibility: `The water below the boat, with {n} fish swimming`; hint `Double-tap to cast at the nearest fish`.
- **What flies:** a hook on a line, from (80, 28) toward the tap at 150 px/s. The 1849
  harpoon code is unchanged; draw the head as a 2×2 `#C9CED4` hook with a `#E9E3D2` line.
- **Targets** (in this order; the spawn weights are 1849's):

| name | lb | w×h | speed px/s | weight | colour | sprite note |
|---|---|---|---|---|---|---|
| grayling | 3 | 8×3 | 30–46 | 35 | `#9DB7C9` | tall dorsal fin, 3 px above the body (like the shark's) |
| whitefish | 6 | 10×4 | 24–38 | 26 | `#D9DDE0` | — |
| pike | 12 | 16×4 | 36–56 | 18 | `#6E8B3D` | — |
| lake trout | 25 | 20×6 | 22–36 | 13 | `#8C7A5B` | `#D9D1B0` 1-px spots every 4 px |
| king salmon | 45 | 26×7 | 34–52 | 8 | `#C0605A` | — |

- **Backdrop:** sky above y = 28 `#BFD9E6`, with a dark spruce shoreline. 1-px-wide
  triangles of height 3–7 in `#1F3A2A` along y 20–28, every 4 px. Water in 10 bands from
  `#3D7C78` to `#0A2422`, with 1849's light shafts. At top centre the small boat
  (`#9C7A4E`) with a red-mackinaw fisher (`#B5432F`).
- **Reward:** Provisions. **Cap: 150 lbs for every role**, also capped by food space.
  Padding 1.5 for all.
- **End message:**
  `You caught [amber]{n} lbs[/amber] of fish.` / `You caught nothing.`, then if over
  the cap ` You can only smoke and keep 150 lbs before the rest spoils.`, then
  ` [green]+{n} lbs of provisions.[/green]` and ` [dim]A day has passed.[/dim]`. Then 1
  camp day.

Fishing matters less than in 1849, and that is on purpose: after the summit you carry
most of a year's food. It is the poor party's way to stretch food *before* the summit
(the lakes are after it), and on the river.

---

## 16. Scene & chart

### Scene (160 × 80, 1849's renderer)

- **Steamer legs:** 1849's sea with the steamer sprite. Behind the horizon draw a far
  coast range: a silhouette `#3B4A52` of height `6 + 4·sin(x·0.07) + 3·sin(x·0.19)`,
  capped with `#E8EEF2` on the top 2 px of each column taller than 8.
  - **Juneau in town:** 1849's hillside town, with the hill colour `#2F4A35` and a snow
    peak `#E8EEF2` behind it at x 100–160.
- **Foot legs:** no sea. Below the horizon fill with the weather's `snow` colour. 8
  rows of "ripple" dashes in the accent colour scroll left at 1849's wave speed (×0.25,
  because the relay is slow), with no vertical jitter except in wind and blizzard.
  - Behind the horizon, mountains: height `14 + 7·sin(x·0.05) + 4·sin(x·0.17)` in
    `#4E5C68` with snow `#F2F5F8` on the top 4 px. In the summit regions use a
    taller, jagged profile, `20 + 9·|sin(x·0.08)|`.
  - Trail poles: every 24 px a 1×5 `#3A2A1A` pole scrolling with the ground.
  - **A foot-leg town** (Dyea / Skagway / Sheep Camp / White Pass City) is a tent city on
    the right: 7 tents, each a 6×4 `#E9E3D2` triangle-roofed block with a 1×3 `#555`
    stovepipe and a 1-px smoke puff.
- **Boat legs:** water in a river green (`water` blended 50% with `#2E5A4E`). The far
  bank is a spruce line of 1-px triangles of height 4–9 in `#1F3A2A` along the horizon,
  scrolling at 0.3× the wave speed. The near bank is a 2-px `#6B5A3A` gravel line at
  y 78.
  - **Bennett and Selkirk in town:** a tent city (as above) with 3 half-built boat
    frames (`#9C7A4E` ribs) on the left.
- **Bennett before the boat** uses the foot ground with the party sprite and the tent
  city, plus 4 boat frames. When the boat exists, it uses the boat scene and sprite.
- **VoiceOver labels:**
  - `Steamer heading north in {weather}`
  - `Your party hauling sleds in {weather}`
  - `Your boat on the river in {weather}`
  - in town: `… at {place}`

### Chart (230 × 210)

**Projection:** `x = (lon + 148) × 8.5`, `y = (65 − lat) × 11.4`. That puts Seattle at
about (218, 198) and Dawson at about (73, 11). The horizontal scale is about 0.75 of the
vertical, a compromise for 47–64°N.

- **Fill the canvas with land** `#B9A26C`, then draw the ocean polygon `#0D2A44`, then
  the islands as land.
- **Ocean polygon** (lon, lat), clockwise from the bottom left:
  (−148, 47), (−124.7, 47), (−124.7, 48.4), (−125.5, 48.9), (−127.0, 49.9),
  (−128.4, 50.8), (−127.8, 51.5), (−128.5, 52.5), (−130.0, 54.0), (−130.6, 54.7),
  (−133.5, 55.0), (−134.3, 56.0), (−135.5, 57.0), (−136.4, 57.9), (−137.0, 58.4),
  (−138.0, 58.7), (−139.7, 59.5), (−142.0, 60.0), (−145.0, 60.2), (−148.0, 60.4).
- **Island polygon** (Haida Gwaii): (−131.0, 52.0), (−132.2, 53.0), (−133.0, 54.1),
  (−132.0, 54.0), (−131.6, 53.2).
- **Inside waters:** draw the steamer route polyline (vertices 0 → Lynn Canal below) 3 px
  wide in the ocean colour *before* the route dots, so the Inside Passage reads as water
  between the islands and the mainland.
- **Lakes and river:** the river route polyline (Bennett → Dawson) 2 px wide in
  `#2F6A96`, and 4 px wide for the lake spans (Bennett–Caribou Crossing,
  Tagish–Marsh outlet, Laberge head–foot).
- **Graticule:** dotted `#173B5C` every 5° (lon −145, −140, −135, −130, −125; lat 50,
  55, 60). **Border:** a dotted `#8F8A7A` line along the 141st meridian from 60.3°N to
  65°N. The panhandle border was in dispute in 1898 and is not drawn.
- The **route** is drawn exactly like 1849's: grey dots every 3 mi (every 0.3 mi on the
  trail). The traveled part is amber, the stops are 3×3 markers, and the party is a
  blinking red 5×5 marker. Before the fork, draw **both** trail polylines grey. After
  it, draw only the chosen one.
- **Inset — "the passes":** a 70×70 box at (6, 134)–(76, 204) with a 1-px `#2A3547`
  border, filled with land.
  - Mapping: `x = 6 + (lon + 135.45) × 127`, `y = 134 + (59.88 − lat) × 152`.
  - It shows both trail polylines with their stop markers and, while on the trail, the
    party marker. That makes the slow trail progress visible.
  - Lynn Canal water in the inset is a 3-px ocean-colour line from (−135.33, 59.42) to
    (−135.36, 59.51), and to (−135.31, 59.46).
- **Below the chart:** a 2-column legend of the stops (✓ / ► / ·, as 1849) and
  `{x} of 1,700.0 miles traveled. {y} to go.`
  - Heading `Map of the journey`, button `Back`.
  - VoiceOver: `Map of the route from Seattle to Dawson City. You are in {region}.`

**Route vertices** `[lon, lat, mile]` (approximate; interpolate by mile as 1849):

Steamer, shared:
```
[-122.33,47.61,0] [-122.55,48.15,40] [-123.0,48.6,95] [-123.9,49.3,160]
[-125.3,50.1,245] [-127.0,50.9,330] [-128.0,51.6,380] [-128.8,52.8,480]
[-130.2,54.0,600] [-131.4,55.2,700] [-132.4,56.4,820] [-133.3,57.0,900]
[-134.1,57.9,970] [-134.42,58.30,1020] [-134.9,58.55,1045] [-135.1,59.0,1080]
[-135.35,59.33,1110]
```
Chilkoot:
```
[-135.36,59.51,1120] [-135.33,59.635,1133] [-135.23,59.70,1136.5]
[-135.17,59.74,1141] [-135.08,59.79,1146] [-134.99,59.85,1153]
```
White Pass:
```
[-135.31,59.46,1120] [-135.22,59.55,1133] [-135.14,59.62,1136.5]
[-135.05,59.70,1141] [-135.02,59.76,1146] [-134.99,59.85,1153]
```
River, shared:
```
[-134.86,60.05,1166] [-134.71,60.17,1179] [-134.45,60.20,1192] [-134.27,60.31,1203]
[-134.35,60.50,1222] [-134.60,60.62,1235] [-135.05,60.67,1253] [-135.06,60.72,1258]
[-135.15,60.95,1275] [-135.00,61.35,1305] [-134.88,61.58,1340] [-134.90,61.87,1375]
[-135.50,62.15,1410] [-136.29,62.09,1445] [-136.35,62.27,1467] [-137.38,62.78,1525]
[-138.40,63.00,1585] [-139.50,63.20,1635] [-139.42,63.28,1645] [-139.30,63.70,1675]
[-139.43,64.06,1700]
```
The coordinates of the named places (Seattle, Juneau, Skagway, Dyea, the Chilkoot and
White Pass summits, Bennett, Carcross, Tagish, Whitehorse, Five Finger Rapids, Fort
Selkirk, the Stewart mouth, Dawson) are from memory to about 0.05°. The vertices between
them are rough. Check them against a map before shipping (§20).

---

## 17. Ending & scoring

### Finale (stop 12)

- Message: `The [i]{boat}[/i] noses into the mud below Dawson City on {date}, {day} days after you left Seattle.`
- Paragraph: `The bank is lined three deep with boats, and the town behind them is a sprawl of tents, saloons and fresh-sawn lumber. Every creek for miles was staked before you left home — but there is work at wages nobody in Seattle would believe, and you have most of a year's grub to live on while you look.` then, if more than one is alive, ` Your partners are already asking the way to the creeks.` or, if only you are left, ` You stand alone on the bank, asking the way to the creeks.`
- Then `Your score`, the table, `Subtotal`, `Bonus for being a {title}` ×m, `Final score`,
  `Rank: {rank}` (+ ` · #{n} in the top ten!`), and `Lost on the trail` with the graves.
- Buttons: `Head north again` (primary) · `See the top ten`. After the top ten:
  `Thanks for coming north.` with `Head north again`.

### Game over

The screen is 1849's: red title, body, footer `{date} · {x} miles from Seattle.`,
graves, and the button `Try again`.

| cause | title | body |
|---|---|---|
| Leader dies | `You, {name}, have died of {cause}.` (snowslide: `You, {name}, have been lost in a snowslide.`) | `Your partners split up the outfit. One or two go on to Dawson; the rest turn for home. The journey is over.` |
| Outfit 0 | `Your outfit is ruined.` | `Split sacks, sodden flour, a stove with no pipe. There's nothing left worth carrying and nothing to show the police. You sell the scraps for a ticket home.` |
| Boat 0 | `The [i]{boat}[/i] has broken up.` | `Her planks sprang one after another, and the river took her and everything in her. You stand on a gravel bar with the clothes on your back. The Klondike will have to wait for another year.` |
| Turned back | `The police have turned you back.` | `There's no arguing with the rule, and no living in the Yukon without a year's grub. You sell what you have to somebody with more of it, and take the next steamer south.` |

### Burial (1849's burial screen)

| leg | text |
|---|---|
| steamer | `The purser has {name} carried ashore at the next landing and buried on a hill above the water. What words will you say?` |
| foot | `Your partners lay {name} to rest beside the trail under a cairn of stones, with a cross cut from a packing crate. What words will you say?` |
| boat | `You bury {name} on a bluff above the river, where the boats going by can see the cross. What words will you say?` |

Epitaph placeholder `Rest easy, partner.` (max 70). Button `Lay them to rest`.

### Score

| line | points |
|---|---|
| `{n} in the party, health {label}` | survivors × (good 500 / fair 400 / poor 300 / very poor 200) |
| `Boat & oars` | `round(boat × 2 + oars & sail)` |
| `Provisions & firewood` | `floor(food/25) + floor(firewood/50)` |
| `Stores & spares` | `floor(lime)×2 + meds×5 + furs×2 + rope×4 + canvas×4 + floor(hooks/20)` |
| `Cash` | `floor(money/5)` |
| **`Ahead of the crowd`** (new) | `20 × max(0, days from the arrival date to August 1, 1898)` |

Total = subtotal × role multiplier.

**Why "Ahead of the crowd"?** The real Klondike reward for speed was being early. Without
this line, the safest departure (April or May) would also score best. With it, a party
in by June 20 earns about 840 and one in on August 1 earns nothing. That is what makes
February/March the right advice (§18).

### Ranks

| rank | threshold |
|---|---|
| Sourdough | ≥ 7,000 |
| Old Hand | ≥ 4,000 |
| Stampeder | ≥ 2,000 |
| Cheechako | below 2,000 |

Legend: `Sourdough 7,000+ · Old Hand 4,000+ · Stampeder 2,000+ · Cheechako`.

"Sourdough" and "cheechako" are period northern slang for an old-timer and a newcomer;
they are generic words.

### Default top ten (invented)

| # | name | score |
|---|---|---|
| 1 | Amos Tolliver | 7,800 |
| 2 | Nora Halvorsen | 6,600 |
| 3 | Jasper Quill | 5,900 |
| 4 | Ada Brightwater | 5,100 |
| 5 | Elmer Stroud | 4,450 |
| 6 | Hattie Lindqvist | 3,800 |
| 7 | Cyrus Pettibone | 3,150 |
| 8 | Minnie Garvey | 2,600 |
| 9 | Otto Sundberg | 1,950 |
| 10 | Floyd Ashcombe | 1,300 |

Prototype sim scores for winning journeys (100 voyages a role):
- storekeeper: median 3,836 (p90 3,956), a Stampeder.
- boatbuilder: median 6,708 (max 7,856), an Old Hand.
- miner: median 7,952 (max ~10,100), a Sourdough.

So the default table is beatable by good play in every role, as 1849's is.

---

## 18. Balance targets

| | target band (±15 pp tolerance, as 1849) | prototype sim result (see below) |
|---|---|---|
| storekeeper wins | ≥ 85% | 30/30 · 30/30 · 30/30 · 100/100 · 100/100 |
| boatbuilder wins | 45–85% | 22/30 · 20/30 · 21/30 · 64/100 · 71/100 |
| miner wins | 15–50% | 15/30 · 11/30 · 13/30 · 38/100 · 37/100 |
| median winning journey | 115–155 days | 132 · 133 · 135.5 · 134.5 · 132.5 |

The seed sets are, in order, 30 voyages per role from bases 1898, 50000 and 90000, then
100 from 20000 and 100 from 60000. Each role's seeds are `base + 1000 × multiplier + i`,
as `BalanceSimulationTests`.

### Sensible bot policy (for the journey's `SensibleBot`)

This mirrors 1849's bot. Where 1849 had no equivalent, it makes the cautious choice.

- **Departs February or March 1898**, alternating by seed (the game's advice).
- **Rations:** storekeeper Square meals; boatbuilder and miner Short commons (as 1849's bot). Pace
  always Steady.
- **Shops** at Seattle and at every port it enters. Each item's target is rounded up to
  the item's step, capped by room, and cut back one step at a time while money is
  short. Items are bought in this order:
  1. **food**:
     - before the summit: `1,095 × n + n × lb × (estDays(here → summit) + 15)`;
     - after it: `n × lb × (estDays(here → next port or end) + 10 + wait)`.
  2. **firewood**: `n × 4 × 1.5 × 10`, plus (before Bennett) `n × 4 × 2 × 1.5 × treelessDays(here → Bennett)`, plus (at Bennett with no boat) `10 × days until May 28`.
  3. **lime juice**: `n × 0.02 × (estDays(here → next port or end) + 10 + wait)`.
  4. **furs**: n.
  5. **medicine**: 2.
  6. **rope & rawhide**: 3 before the boat, 2 after.
  7. **canvas & pitch**: 4 before the boat, 2 after.
  8. **hooks & line**: 60 casts for non-storekeepers.
  - Before the summit, items 3 and 5–8 are bought only while at least **$60** stays
    in hand (the "summit reserve").
- **estDays** (the bot's planning speeds): steamer 170 mi/day; foot 0.6 mi/day ×
  region speed × role trail factor; boat 24 mi/day. `treelessDays` counts only foot
  regions without `timber`. `wait` = days from the estimated Bennett arrival to May 28,
  if positive.
- **At every port:** shop; then rest 3 days in town if average hp < 70; then the yard
  if a meter is below 70 and affordable; then shop again.
  - At Bennett, instead of the yard, it builds:
    1. **properly** if `May 28 − today ≥ build days` and it has the stores;
    2. else the storekeeper **buys** ($220);
    3. else the **scow**, if it has the stores;
    4. else **buys**, if it has $220;
    5. else the **raft**.
  - Then it waits in camp for the ice.
- **Before each travel day:** mend propulsion below 40 with rope & rawhide and
  structural below 40 with canvas & pitch, a day each, while it has them. Non-storekeepers
  fish (the 1849 simulated catch: up to 15 casts at 35% each, weighted fish) when food is
  under 12 days and fishing is allowed. It does **not** rest in camp otherwise (as 1849).
- **Choices:**
  - Fork: Chilkoot or White Pass at random (50/50).
  - Packers: hired if money ≥ $240 ($90 plus a $150 reserve).
  - Quitters: keep going. Partner: send them on.
  - Snowslide warning: wait 2 days. Thin ice: go round. Gold rumour: stay.
  - Police short: the cheaper affordable remedy, else turn back.
  - Miles Canyon: a pilot if it can pay, else portage. Five Fingers: always line.
  - Ports: always go ashore. Trades: decline.

### Worked balance check

**1. The Seattle outfit for each role** (what the bot buys; February and March are the
same):

| | Prov. | Firewood | Lime | Meds | Furs | Rope | Canvas | Hooks | **Spent** | **Left** |
|---|---|---|---|---|---|---|---|---|---|---|
| storekeeper ($1,700) | 6,250 lb $625 | 1,600 lb $32 | 2 $8 | 2 $24 | 5 $60 | 3 $24 | 4 $40 | — | **$813** | **$887** |
| boatbuilder ($1,050) | 6,000 lb $600 | 1,600 lb $32 | 2 $8 | 2 $24 | 5 $60 | 3 $24 | 4 $40 | 3 boxes $9 | **$797** | **$253** |
| miner ($720) | 6,000 lb $600 | 1,500 lb $30 | 2 $8 | 0 | 5 $60 | 0 | 0 | — | **$698** | **$22** |

The police requirement is 5 × 1,095 = **5,475 lb** ($547.50 at Seattle prices). That is
**76%** of the miner's money before he has eaten a pound. 1849's whaler starts with about
91% of a sensible outfit's cost. The miner can afford the requirement, furs and fuel. He
cannot afford medicine, boat stores, a pilot, or a real margin over the police.

- **The storekeeper** keeps $887 for packers ($90), a bought boat when late ($220), the
  pilot ($25) and port top-ups. He reaches Dawson with ~$480 (a cash line of ~96).
- **The boatbuilder** spends his $253 on packers, the pilot and the Bennett wait, and
  arrives nearly broke.
- **The miner** builds a raft (19–23 of 30 games) unless he salvages canvas, lines the
  canyon, and has no medicine all journey.

**2. The police margin.** Food at the summit is what was bought, minus what was eaten
(~8 steamer days + ~25–28 trail days), minus losses.
- storekeeper: 6,250 − 36 × 15 ≈ 5,710, about +235 over the rule;
- boatbuilder: 6,000 − 36 × 10 ≈ 5,640, about +165;
- miner: 6,000 − 34 × 10 ≈ 5,660, about +185, with no cash to top up.

Before the summit, a spoiled-flour event (100–300 lb), a tent fire (60–180) or, in
spring, a buried cache (100–300) is roughly a coin flip. The richer roles top up at the
landing and the mid-trail store, or pay a remedy at the summit. The miner often cannot:
he is **turned back in 21–32%** of journeys. That is his main loss, and the journey's
signature one.

**3. Days per leg from the speeds.**

- **Steamer:** 2,200 × average weather speed (Inside Passage 0.83, Queen Charlotte Sound
  0.70, coast 0.80) ≈ 1,750 units (175 mi) a day. 1,120 mi takes ~6.4 days, plus
  Juneau and the fork, so landing is on about day 8. *Sim: day 8.*
- **Trail:** 9 × weather (winter valley 0.84, winter summit 0.72, spring ~0.68) × meter
  terms (~0.9 × 0.97) ≈ 5–6.5 units a day. 330 units takes ~53–64 days. The miner's ×1.15
  and the packers' ×1.4 shorten it. *Sim, winners' medians: storekeeper 57–59, boatbuilder
  62–64, miner 53.*
- **Bennett:** the build (21 days properly, 9 for the scow, 2 bought) plus the wait for
  breakup (May 24 – June 1). February parties arrive about April 4–15 and stay 42–55
  days. March parties arrive about May 1–10 and stay 19–26. *Sim: as stated.*
- **River:** 300 × weather (late-May lakes with ice ~0.66, June lakes 0.85, Yukon 0.93)
  × meters ≈ 230–270 units a day for a good boat. 5,470 units takes ~22 days, plus the
  canyon (0–4 days), Five Fingers (2), snags and Selkirk. *Sim: 27–33 days.*
  - A raft (Boat ~40, Oars & sail 50) runs at ×0.85 × 0.725 ≈ 0.62 of that, and takes
    more snags and longer linings. *Sim: 46–50 days.*
- **Totals:** February ≈ 144–167 days, March ≈ 115–134. Dawson is reached about June
  24 – July 18. The bot's median is ~134, inside the 115–155 band.

**4. Consumption against capacity and resupply.**

- **Provisions:** you carry ~6,000 of a 9,000 cap. After the summit about 5,500 lb face
  only ~95 days at 10–15 lb/day (the Bennett wait plus the river), so 950–1,400 lb. You
  arrive with ~4,000 lb, about 160 points: the winter's grub the police had in mind. No
  one in the sim starved after the summit. Food pressure lives in Seattle (money) and at
  the summit (the rule).
- **Firewood:** the treeless summit stretch is 13 mi at ~0.55 mi/day, about 24 days. At
  5 × 4 × 2 (freezing) that is 40 lb/day, ~960 lb, or 720 at the spring "cold" rate.
  - In timber, gathering (`ri(20, 50)`, average 35) beats the cold-rate need (30). It
    roughly matches the freezing need at the lakes (40).
  - The bot buys 1,500–1,600 lb (cap 2,000) and never froze in the final runs. A
    player who buys only Seattle's "about a week" will run out on the summit, which is
    this journey's Doldrums.
  - The steamer burns none; on the river (cool/warm) gathering exceeds the need.
- **Lime juice:** 0.1 jug a day for five. Town visits reset it, but **Sheep Camp →
  Bennett (~35–40 days) and the Bennett camp wait (20–55 days) have no town**. Scurvy
  onset is 35 days. The bot buys 4 jugs at the mid-trail store and 2–6 at Bennett, out of
  a cap of 40. The miner, buying them late and dear, is where the sim's scurvy deaths are.
- **Health:** parties on square meals reach Bennett at a median of 94 hp. On short commons they reach it
  at **39–43** (minimum near 1), because trail exertion (−1.4) plus short commons (−0.3) cancels
  natural recovery (+1), and freezing adds −1.4 to −2.4. The camp wait at Bennett (+3
  camp, +1, −0.3, about +3.7 a day) heals them. That is why February parties, despite a
  colder trail, survive on longer waits, and why March is safest.

**5. Why the bands are plausible.**

- **Storekeeper ≥ 85% (sim 100%).** Money buys square meals (+1.3 hp/day over short commons
  on a 55-day grind), packers, a bought boat when late, the pilot and every top-up. His
  risks are a captain-killing snowslide or illness, under 2% in the sim. The same is
  true of 1849's merchant.
- **Boatbuilder 45–85% (sim 64–73%).** He has the same food rule and a small purse, so
  Short commons and the trail wear his party down to ~40 hp by Bennett. His losses are
  exhaustion, broken legs and pneumonia on the trail (one crew member dies on average).
  His perk pays off afterwards: a stout boat and cheap repairs make his river leg the
  safest of the three.
- **Miner 15–50% (sim 37–50%).** He can pass the police only with nothing to spare. He
  has no medicine and floats a raft. His losses spread across turned back (21–32%),
  wrecks (6–11%), exhaustion, scurvy and untreated illness. His trail perk is what keeps
  him above 15%. Without it, the sim drops him to the low 20s.
- **Departure month** (40 voyages a role and month):

  | | Jan | Feb | Mar | Apr | May |
  |---|---|---|---|---|---|
  | storekeeper | 33/40 | 40/40 | 38/40 | 39/40 | 39/40 |
  | boatbuilder | 0/40 | 12/40 | 36/40 | 37/40 | 40/40 |
  | miner | 0/40 | 8/40 | 21/40 | 22/40 | 22/40 |

  January is the trap, as April is in 1849. February is hard for the poor. March is
  both safe and early. April and May are safe but reach Dawson in July or August, costing
  300–800 "Ahead of the crowd" points. Hence the advice: *February or March* for score,
  *March* for safety.
- **The passes** (200 voyages a role) are balanced within noise:

  | | White Pass | Chilkoot |
  |---|---|---|
  | storekeeper | 95/95 | 103/105 |
  | boatbuilder | 72/95 | 61/105 |
  | miner | 38/95 | 45/105 |

  The Chilkoot is faster, especially with packers, but has six to ten times the
  snowslides. The White Pass is slower (×0.9) and gentler (exertion ×0.75).

**How these numbers were produced.** A Python prototype of the day loop, run with the
tables above and the bot policy above. It ports 1849's `consume`, `health`, `wear`,
`sicken`, `passDays` and the event roll, with this journey's changes. It is an
approximation of the engine, written to tune the tables, so the draw order and the
details of the trade and fishing code differ. The Swift `SensibleBot` must re-run these
bands; small differences of a few points are expected. The script was kept outside the
repo (`$TMPDIR/klondike-sim/sim.py`).

---

## 19. Learn pages

Title-screen choice: `Learn about the trail`. Buttons `Next` / `Back to the start`.

**1. The rush**
- `In July 1897 a steamer tied up in Seattle with a ton of gold aboard, and by winter the whole country had the fever. The gold was on the Klondike River in Canada's Yukon, seventeen hundred miles north — up the coast by steamer, over the mountains on foot, and down the Yukon River by boat.`
- `You lead a party of five. Buy a year's outfit, get it over the pass, build a boat, and bring everyone to Dawson City alive.`

**2. The outfit**
- `[amber]Provisions[/amber]: the police at the summit turn back anyone without a year's grub — 1,095 lbs a head. Bring more than that; you'll eat on the way up.`
- `[amber]Firewood[/amber] keeps you alive on top of the pass, where nothing grows. Below the trees you can gather your own.`
- `[amber]Lime juice[/amber] holds off scurvy. [amber]Furs[/amber] — one set each — hold off the cold.`
- `[amber]Canvas & pitch[/amber] and [amber]rope & rawhide[/amber] patch your outfit on the trail and your boat on the river, and you'll need some to build the boat. [amber]Hooks & line[/amber] catch fish on the lakes and river.`

**3. Pass, lakes, river**
- `At the head of Lynn Canal choose your pass: the short, steep [amber]Chilkoot[/amber] or the longer, lower [amber]White Pass[/amber]. Either way, you carry everything up a load at a time.`
- `At [amber]Lake Bennett[/amber] you build a boat and wait for the ice to go out, at the end of May. Then it's five hundred miles of lakes, canyon and rapids to Dawson.`
- `Leave too early and the pass will freeze you; too late and the snow turns to slush and slides, and the crowd beats you to Dawson. Hard driving and short rations get you there sooner, if they get you there at all.`

### Other setup text

- **Title:** `TO THE` / `KLONDIKE`, then `~ 1898 ~`.
  - Tagline: `Seventeen hundred miles from Seattle to the gold fields of the Yukon — by steamer, on foot, and by boat.`
  - Choices: `Head for the Klondike` · `Continue the journey of the [i]{boat}[/i]` (only when saved) · `Learn about the trail` · `See the top ten`.
- **Month screen:**
  - Heading `When will you go?`
  - Intro: `The news reached Seattle last July. All winter the steamers have gone north crammed to the rails. When will you go?`
  - Options: `January 1898` · `February 1898` · `March 1898` · `April 1898` · `May 1898` · `Ask for advice`.
  - Advice: `An old sourdough taps his pipe on the stove: “Go in January and the pass will freeze you solid. Go in April and you'll wade through slush under the snowslides, and every creek in the Klondike will be staked twice over before you get there. February or March. Be at the lakes when the ice goes out.”`
- **Outfit intro:**
  - Heading `Outfitting`
  - Intro: `You have [amber]${money}[/amber] to outfit your party. The outfitters on First Avenue will sell you anything, and they all tell you the same things:`
  - Bullets:
    - `• [b]Provisions[/b] — the police won't let anyone over the summit without a year's grub: 1,095 lbs a head. Then you have to eat on the way.`
    - `• [b]Firewood[/b] — nothing grows on top of the pass. Carry enough to keep a stove going for three weeks up there.`
    - `• [b]Lime juice[/b] — beans and bacon all winter bring on scurvy.`
    - `• [b]Furs & mackinaws[/b] — one set a head, or the summit will take fingers and toes.`
    - `• [b]Canvas & pitch, rope & rawhide[/b] — to patch the outfit on the trail, and to build a boat at the lakes.`
    - `• [b]A medicine chest and hooks & line[/b].`
  - Button `Enter the shop`.

---

## 20. Open questions

**Engine generalisations this journey needs.** Each one must leave 1849's draws and
results identical: `PrototypeParityTests` and `BalanceSimulationTests` must stay green.

1. **Legs.** Each region has a leg with a base speed, and the steamer is a *passenger*
   leg: pace, meters and crew factor are ignored in the speed, there is no wear, no pace
   hp and no temperature damage, and firewood need is 0. Pace hp is per leg. 1849 is
   one leg (`sea`) with today's numbers.
2. **Distance scale.** Integer units = tenths of a mile, with display divided by 10 to one
   decimal. 1849 uses a scale of 1. Mars may want this too.
3. **Fork swaps a run of regions and stop variants.** 1849 swaps one region and varies one
   mark's text. Here three regions are swapped, and four stops have per-route names,
   texts and *port records* (Dyea/Skagway, Sheep Camp/White Pass City).
4. **The water role, parameterised.** Name, per-person rate, a temperature multiplier
   table (1849: hot ×1.5, others ×1 → here freezing 2 … warm 0.5), "zero on passenger
   legs", the free top-up rule (1849: rain/storm, 15–45 → here timber region, not
   blizzard, 20–50), and the out-of-stock death cause ("thirst" → "exposure").
5. **Vehicle switch.** Meter names and values change at Bennett. Messages and the yard
   take `{S}`/`{P}`, and the sprite changes.
6. **Ice gate.** A stop whose departure is held until a rolled date, with a "wait" option
   that passes camp days.
7. **Police check.** A stop that compares food with a per-head requirement and offers two
   paid remedies or a game over.
8. **Daily regional hazards** in place of the hard-coded Strait aground and Horn
   overboard: here snowslides and snags.
9. **Season tables.** Region weather weights and temperatures by season (W/Sp/Su), and
   the "deep winter" months for the freezing extra. These replace 1849's hard-coded
   `tempAt` and southern-winter bumps for this journey only.
10. **Score line** `Ahead of the crowd`, which is date-based.
11. **Role perk** "foot-leg speed ×1.15".
12. **Fishable flag** and the extra refusals.
13. **Per-weather harsh, rough set and wear extras** as data (`hot` has harsh but is not
    rough; `ice` has gale-style structural wear).
14. **Burial text per leg**, and the departure warning when food is under the
    requirement.

**Facts that are unverified or bent for play**

- Juneau → Skagway (~90 nm), the river vertex miles between named places, and the
  Bennett → Dawson total (547; sources give 500–608).
- The White Pass is compressed to the Chilkoot's 33 trail miles, with speed ×0.9 standing
  in for the extra ~9 miles.
- The police summit posts flew the flag from 26 Feb 1898. January and early-February
  departures reach the summit before that date, and the game applies the rule anyway.
  Decide whether that matters; it could be moved to Tagish for arrivals before Feb 26.
- A Fort Selkirk store open in June 1898 is plausible but unconfirmed.
- The boat numbering at Tagish, with next of kin, is a well-known story but unconfirmed.
- Sheep Camp sits on the region boundary, so resting there counts as the treeless summit
  region (no gathering, freezing need). It is harmless, but the boundary could move to
  1,133.1 mi.

**Design calls to confirm**

- **Animals:** none anywhere. The White Pass's real horse deaths are left out on purpose,
  and there are no dog teams, no hunting and no pack animals.
- **The Dyea packers** were largely Tlingit in 1897–98. The game says only "a crew of
  packers", so it does not put words in anyone's mouth. Indigenous people otherwise
  appear only as "a family drying salmon at a camp on the bank". Decide whether you want
  more historical acknowledgement in a learn page.
- **"Turned back" is the miner's main loss** (21–32%). That is thematic, but if it feels
  like a cliff, the cheapest fix is raising the miner to $760 (sim: about 44% wins,
  turned back about 15%).
- **The bot keeps 1849's short rations for the poor roles.** A human who eats square meals on
  the trail (it costs only ~250 lb, about $25) does much better than the bot. The learn
  page hints at it.
- **The Quitters' "Keep going" option is free**, unlike 1849's costly "run". Decide
  whether the safe option should cost a little (for example, a day).
- **The steamer leg is short** (~8 days, about 7% of the journey). It is there for the
  landing choice, Juneau and the Seattle-cheap outfit, not for its own dangers. It has
  only three events, and they are mild.
- **The canyon pilot rule** is applied from the start of the river season. Historically
  it came in during the first days of June 1898, after the worst wrecks.

---

## As built

Engine files: `HornEngine/Journeys/Klondike/` (`Klondike.swift` tables, text and hooks;
`KlondikeData.swift` the data enum; `Klondike+Towns.swift` the ports, Bennett's boat and
ice; `Klondike+Events.swift` hazards and events; `Klondike+Choices.swift` set pieces and
answers; `Klondike+Trouble.swift` sleds, oars, the outfit and the boat at 0%). Tests:
`HornEngineTests/KlondikeTests.swift` (42 rule tests, 5 balance tests) and
`HornEngineTests/KlondikeBreakdownTests.swift` (17, D14).
`Journeys.all` lists it between the balloon and Mars.

App skin: `AroundTheHorn/Journeys/` (`KlondikeSkin.swift` the card, the words and the debug
starts; `KlondikeScene.swift` §16's scene; `KlondikeChart.swift` the map; `KlondikeForage.swift`
§15's fishing), registered in `Skins.all`. Tests: `AroundTheHornTests/KlondikeSkinTests.swift`,
the Klondike cases in `ResumeTests.swift`, and the screenshot walk
`AroundTheHornUITests/KlondikeScreenshotUITests.swift`. The shell members it added and how
it answers the others are in `docs/design/journeys-architecture.md` §2, "Klondike skin, as
built".

**The scene as built**, beyond §16: every stop is drawn as itself (the Seattle and Juneau
waterfronts, Lynn Canal's walls going up into the cloud, Dyea's tide flats and Skagway's
false fronts, Sheep Camp and White Pass City, the Golden Stairs and both summits with the
police flag, Lindeman and Log Cabin, Bennett's tent city and boat frames, the Tagish post,
Miles Canyon's walls and white water, the five towers of Five Fingers, Fort Selkirk and
Dawson under its hill). A boat built at Bennett before the ice goes out sits on the ice,
tied to the bank: §16's "boat scene" with the lake still white. Lynn Canal's walls rise
over the last day's steaming and Juneau is gone the day after it; Miles Canyon's walls
stand around the boat at the canyon and are behind her within the day.

### The numbers as shipped

Everything in §2–§17 is as written, except the departures listed below. In short:

- Distances in tenths of a mile: Seattle 0, Juneau 10,200, Lynn Canal 11,100, Dyea ·
  Skagway 11,200, Sheep Camp · White Pass City 11,330, the summit 11,365, Lindeman · Log
  Cabin 11,460, Bennett 11,530, Tagish 12,030, Miles Canyon 12,530, Five Fingers 14,670,
  Fort Selkirk 15,250, Dawson 17,000.
- Speed a day: steamer 2,200 × weather × jitter (nothing else counts); foot 9 and boat 300,
  × pace factor (0.75 / 1 / 1.3) × weather × the shared meter and crew terms × region speed
  (White Pass 0.9) × the miner's 1.15 on foot × packers' 1.4 below the summit × jitter.
- Pace health a day: steamer 0; boat +0.5 / 0 / −1; **foot −0.5 / −1.7 / −3.4** (×0.75 on
  the White Pass).
- Firewood (the water role): 4 lbs a head × 2 freezing / 1.5 cold / 1 cool / 0.5 warm or
  hot; none on the steamer. Out of firewood is the shared thirst: −12 health a day, +0.04
  illness, death by "exposure". Deadwood 20–50 lbs a day out of town in timber regions,
  not in a blizzard.
- Juneau sells furs at 0.75 of its markup: $11.25 a set against Seattle's $12 (§6's
  table has $13.50; see departure 16).
- Purses: storekeeper $1,700, **boatbuilder $1,000**, miner $720. Repairs 25/20, the
  boatbuilder 40/35. Catch limit 150 lbs and aim 1.5 for everyone.
- Police: 1,095 lbs a head at the summit; the traders' price 30¢ a lb short; the trip down
  costs the short amount plus six days' eating at the mid-trail store's food price.
- Bennett: the ice goes out on May 24 + 0–8 days, rolled on arrival. Builds: properly 21
  days (14 for the boatbuilder) for 3 canvas & pitch and 2 rope, 100/100; scow 9 (6) days
  for 2 and 1, 60–75/80 (85–95/95); bought $220, 2 town days, 90–100/100; raft 5 (4) days,
  35–45/50 (45–55/50).
- Score: 1849's five lines in this journey's words, plus "Ahead of the crowd", 20 points a
  day before August 1, 1898. Ranks Sourdough 7,000 / Old Hand 4,000 / Stampeder 2,000 /
  Cheechako.

### The bot

`KlondikeTests.policy()`: the spec's §18 policy as `JourneyBot` runs it. It shops by the
spec's targets (a year of grub plus the run to the summit, firewood for the bare summit,
lime juice for the run plus the wait at the lakes, spares kept only while $60 stays in hand
before the summit); storekeeper Square meals, the others Short commons; pace Steady; fork at random;
packers with $240 in hand; waits out slides, goes round thin ice, lines Five Fingers, pays
a pilot when it can; at the police the cheaper remedy; at Bennett builds properly when
there is time before May 28, else the storekeeper buys, else a scow, else buys, else a
raft; waits for the ice. It rests three days in town under 70 health, then shops, then
uses the yard under 70 (never on the outfit at Bennett).

30 runs a role, seed 1898 (seeds `1898 + 1000 × multiplier + i`), after D14:

| Departure | Storekeeper | Boatbuilder | Miner | Median winning run |
|---|---|---|---|---|
| January | 27/30 | 0/30 | 0/30 | 175 days |
| February | 30/30 | 6/30 | 0/30 | 144 days |
| **March** | **30/30** | **24/30** | **15/30** | **119 days** |
| April | 30/30 | 27/30 | 15/30 | 111 days |
| May | 30/30 | 29/30 | 10/30 | 106 days |

March over 100 runs a role (seed 20000): 98 / 80 / 42%, median 118 days. March winners
reach Dawson around June 24 (storekeeper), June 28 (boatbuilder) and July 16 (miner);
median scores 3,843 / 7,181 / 7,863.

By choice, March: the Chilkoot 29 / 21 / 9 and the White Pass 30 / 26 / 12 (balanced
within noise; the Chilkoot's losses include more snowslides). Hard driving all the way:
28 / 5 / 3, nearly all of the difference exhaustion on the trail.

Losses in March are spread: the miner is turned back by the police (his main loss, about
a third of his runs over 100), wrecks his raft or scow, or dies of wounds, pneumonia,
frostbite, a fall on the ice or a fever; the boatbuilder loses to exhaustion, pneumonia,
infected wounds and snowslides.

The tests assert March's bands (85–100 / 60–90 / 35–70%) and a median of 115–140 days
(the spec's lower bound); that a bot taking every risky answer is within 20 points of the
careful one for each role;
that January is at least 30 points worse for the boatbuilder and miner and 30 days
longer; that hard driving is at least 30 points worse for both; and that the miner's
losses end at least three ways, the police among them.

### Departures from the spec, and why

1. **Bands.** The task this was built for set 85–100 / 60–90 / 35–70%, not the spec's
   §18 45–85 / 15–50. The journey was tuned to those.
2. **Foot exertion ×1.2** (−0.5 / −1.7 / −3.4 against −0.4 / −1.4 / −2.8). With the
   spec's numbers the March boatbuilder won 89% over 100 runs and the miner 52%: too
   easy for the middle band. At ×1.2 they are 80% and 46%.
3. **The boatbuilder starts with $1,000, not $1,050.** With $1,050 he leaves Seattle with
   $253 and the bot's "$240 in hand" rule hires the packers, which put him at 86–89%.
   Fifty dollars less keeps him at the poorer roles' pace. The skin's comparison page
   must say $1,000.
4. **The valley regions end at 1,133.1 mi**, not 1,133.0 (§20's suggestion): Sheep Camp
   and White Pass City are the last places with trees, so a stay there counts as the
   cold valley, not the freezing summit.
5. **Two port records per landing.** `ports` holds the Chilkoot's towns; the White Pass's
   Skagway and White Pass City are `Klondike.whitePassTowns`, chosen by the new
   `port(_:at:)` hook once the pass is chosen. Stop names stay "Dyea · Skagway" in the
   table; `Klondike.name` and `shortName` give the pass's own once it is chosen ("the
   landing at Lynn Canal" in a sentence before the fork).
6. **Bennett.** Pushing off without a boat says the spec's line and offers "See about a
   boat" at once (the skin can also offer `Klondike.boatChoice` from the yard slot).
   Building passes its days and leaves the party in camp, so it can shop again; pushing
   off with a boat before the ice goes out asks the ice question, and waiting passes camp
   days to the breakup and lets the party go. The engine's way of holding a party ashore
   is the new `holdInPort` hook: `setSail()` now returns interrupts, and the app must show
   them and stay on the town menu while `state.atPort` is still true. `sailDay()` enforces
   it too: called while the party is still ashore where it is held, it passes no day and
   returns the same hold, so no app can float a party out of Bennett without a boat.
7. **Sundogs force clear skies** through a counter in `vars` that `weatherWeights` reads
   and `tick` counts down; the shared `forceFair` would have forced "Fair".
8. **Deadwood is gathered in `tick`**, after the day's burn, not before it in `consume`;
   the numbers are the spec's. The shared rain catch is off (no weather is wet).
9. **Spoilage and the two wear warnings run in `tick`** (the shared ones are switched off
   with −1 thresholds) so they speak of the outfit or the boat. The repair and yard lines
   come from the new `repaired` hook for the same reason.
10. **Going round thin ice** costs a day of eating and travel-mode health with no miles and
    no weather roll; a snag adds a day to the count and nothing else, as written.
11. **Weather's sky slots**, for the skin's palettes: clear `.clear`, fair `.breeze`, rain
    `.rain`, fog `.fog`, snow `.snow`, thaw `.dust`, wind `.gale`, blizzard `.storm` (red),
    ice `.still`, hot `.heat`. The blizzard's trail line is cleared off the trail.
12. **A swindle on an empty purse** says so instead of "$0 of yours has changed hands".
13. **The police rule applies from January** (§20's open question): the game's rule, not
    the calendar's. The canyon pilot rule applies all river season, as written.
14. **For the skin**, public helpers on `Klondike`: `hasBoat`, `meterNames`, `legName`,
    `name`/`shortName`, `requirement` and `shortOfGrubWarning` (the Seattle warning),
    `finale` (the finale's two paragraphs), `burialText` (by leg), `boatChoice`, and for
    distances, which are stored in tenths: `unitsPerMile` (10), `mileNumber` ("1,136.5"),
    `miles` ("1,136.5 miles") and `progress` (the line under the legend).
15. `PaceInfo.speed` is the pace's factor (0.75 / 1 / 1.3), not a distance; the leg sets
    the distance. Scurvy's duration in the table is nominal (it lasts until cured).
16. **Juneau's furs are cheaper than Seattle's** (mod 0.75, $11.25), so the storekeeper's
    line (“Furs are cheaper here than in Seattle”) is true; §6's 0.9 made them $13.50.
17. **The coast is split at Dixon Entrance** (mile 650): `bcCoast`, "The British Columbia
    coast", 360–650, then `alaskaCoast` 650–1,120, with the same temperatures and weather
    lists, so no draw changes.
18. **Hauling off the route is work, not rest.** The trip back down for grub (6 days), the
    canyon portage (4) and the stampede (3) pass their days as the trail does: the foot
    leg's exertion at the party's pace and the weather's harshness, no rest bonus, ailments
    mending a day a day; no miles and no wear. Waiting out a slide, building a boat and
    lining Five Fingers are still camp days.
19. **Bennett before the boat is the foot leg** for `legName` and `burialText` (the town
    stands where the boat leg's country begins), and no "Ice running" weather is drawn there
    while the lake is frozen. Deadwood is still gathered: the arrival paragraph says the
    good trees are gone but the offcuts and slash keep the stoves going.
20. **Words changed to match the tables:** the White Pass is "easier going but slower" (both
    passes are 33 miles in the table; the 0.9 is a speed), not "ten miles longer"; the
    White Pass City smith says the next smith is at Bennett; the stowaway is no longer
    "two days out" (the event can come any steamer day); a break-through on a frozen lake
    has lines and an epitaph of its own instead of E8's creek; a ruined outfit past the
    summit no longer mentions the police; waiting out a slide says "you go on" after the
    two days, and not at all if the party did not live.
21. **The role and ration lines in D11's shape** (text only, no number changed): the roles
    are "A Seattle storekeeper", "A Port Townsend boatbuilder" and "A hard-rock miner out
    of Leadville"; the rations are "Square meals", "Short commons" and "Scraping by" (the
    descriptions are unchanged). The role screen, the comparison page and the trade row in
    §2 and §12 are reworded to match, for the skin.
22. **Sleds, oars, the outfit and the boat at 0%** (D14): see the next section.

### Sleds, oars, the outfit and the boat at nothing (D14)

Reported from play on the Iron Road ("you can go below 0 for the health of the train ... I
ran out of cord and it seemed to be still moving just fine"), and checked here
(`HornEngineTests/KlondikeBreakdownTests.swift`). Before this nothing was stored below 0 or
shown as "-0", and accidents already left a crew member at 1 health at least, but:

- sleds at 0%, or afloat oars & sail at 0%, carried the party on at 45% of its pace (the
  shared floor, `propFloor`), with nothing on the status panel to say so: the March miner's
  bot did so for 21 days in two runs of 30;
- an outfit or a boat under half a point showed 0% and went on: the shared wreck waits for
  nothing at all;
- the damage reports gave the event's whole number past what the meter had (three times in
  the miner's 30 March runs).

The rules now (`Klondike+Trouble.swift`):

- **A meter that shows 0% is at nothing**, as the status panel rounds it (`jsRound`), as on
  the other journeys. Every outfit, boat, sled and oar loss goes through `knock`: never past
  nought, and the red note gives the drop the panel will show, or nothing when it shows
  none ("A sled runner splits on a hidden rock, and a pack strap goes with it." with no red
  note at all on sleds already at 0%).
- **Sleds or oars at 0% have given out** (`Klondike.givenOut`): there is no moving a ton of
  outfit along the trail without them, and a boat with no sweep is tied to the bank. On the
  day they give out nothing else happens (no hazard, no event). Before every day after it
  (`Journey.stalled`, which takes no time and draws nothing) the party is asked: "[red]Your
  sleds have given out.[/red] Split runners, knotted straps, harness in pieces: there is no
  moving a ton of outfit along the trail until they are mended." (afloat: "[red]The oars and
  sail have given out.[/red] With no sweep to steer by, the *Klondike Belle* goes wherever
  the water likes, so you work her into the bank and tie up. She stays there until she is
  re-rigged."). The offers:

  - "Mend the sleds" / "Re-rig the oars & sail: 1 coil of rope & rawhide (have n)": the
    shared repair, +25 (the boatbuilder +40), a camp day.
  - "Buy a coil off the next party along ($24)" ("boat" afloat), offered only with no rope
    aboard: $24, three times the Seattle price, then the same repair. The trail and the
    river were never empty in 1898.
  - "Lash up pack boards from empty crates and sacking (2 days)" / "Cut a sweep and oars
    from a spruce on the bank (2 days)", always open: two days of hard work as the trail
    counts it (`haulDays`: eaten, no miles, the foot leg's exertion, no rest), then the
    sleds or the oars at +10.
  - "Take stock first": the menu under way (rest, repairs, fishing, the supplies).

  The making-do is always open, so there is no softlock. A boat drifting on with the current
  was considered and not offered: a steerless boat on the lakes goes nowhere, and on the
  river the gravel bars and the canyon are what the sweep is for.
- **Miles Canyon and Five Fingers wait for a sweep.** Reached on the day the oars give out,
  each is held (`klondike.held`): "The *Klondike Belle* comes down to Miles Canyon with no
  sweep to steer by, and you tie her up to the bank above the fast water. Nobody takes a
  boat into Miles Canyon without a sweep." (Five Fingers: "Nobody takes a boat through Five
  Fingers without a sweep."). The question then ends with that line, and the set piece comes,
  taking no time, once she is re-rigged. The police at the summit weigh grub, not sleds, and
  are met as usual; towns and Dawson take a party in as usual.
- **The steamer carries the party whatever its sleds are like**: aboard, nothing is asked
  (and nothing aboard can wear the sleds in any case).
- **An outfit or a boat at 0% is lost**, as §4 has always had it ("Your outfit is ruined."
  or "The *Klondike Belle* has broken up.", with §17's paragraphs). The end now comes at a
  shown 0%, not only at nothing: a day's wear or an event that would leave less than half a
  point takes the rest (even aboard the steamer, where nothing wears it), and a save
  standing at 0% ends before another day. There is no way out to offer: stampeders whose goods
  were soaked, stolen or buried turned back (§4), and patches go on from the stores long
  before.
  `rules.wearWrecks` stays true.
- **No firewood**: this journey has no vehicle fuel (§5), and firewood is for the people, not
  the sleds, so a party without it still walks or rows at its pace. It is a crisis all the
  same, and was before: −12 health a head a day and +0.04 on the chance of illness, death
  by "exposure", and the red warning "[red]The woodpile is gone![/red] Without a fire, the
  cold will kill you within days." What it lacked was a row on the status panel
  (`Klondike.noFire`: no firewood anywhere but aboard the steamer).
- **Crew health**: snowslides, falls through the ice, the runaway sled's broken leg and the
  seasick steamer already left a crew member at 1 health at least; what kills is the day
  that follows, as the shared rules count it. Tested.

**What the skin shows** (built; `KlondikeSkinTests` holds each, and the walk shows them):

- the red status row, `Words.trouble` = ("Party", …): "Sleds given out" on foot and "Oars &
  sail given out" afloat (`Klondike.givenOut`); "No firewood" (`Klondike.noFire`); both at
  once, "Sleds given out, no firewood" / "Oars given out, no firewood"; nothing before the
  party leaves Seattle. The outfit and the boat need no row: at 0% the run is over.
- the supplies screen's note adds "the sleds have given out" / "the oars & sail have given
  out" and "no firewood";
- the scene needs nothing new: §4's holes in the tarp, the slats and the sail are at their
  worst at 0%;
- the learn pages ("The outfit", "Pass, lakes, river") say that sleds or oars at 0% stop the party
  until they are mended, the three ways to mend them, that Miles Canyon and Five Fingers
  wait for a sweep, that an outfit or a boat at 0% ends the trek, and that a day without
  firewood costs every one of you 12 health;
- the role screen, the comparison page, the rations and the trade row in D11's shape (§2,
  §10, §12; the engine's role and ration lines already are).

Tuning: none was needed. The March bands hold untouched and identical: 30 / 24 / 15 of 30,
median 119 days, as before; the tables above are after D14 (February's miner 1 → 0, April's
16 → 15, March over 100 runs 43 → 42%, the Chilkoot's miner 10 → 9). The March miner's bot
still meets given-out sleds or oars in two runs of 30, for a day each, and mends them.

### Worth knowing

- **New shared hooks**, each with a default that leaves every other journey unchanged
  (the three 1849 gates and the other journeys' tests are green): `port(_:at:)`,
  `paceHP(_:)`, `waterNeed(_:_:)`, `holdInPort(_:)` with `setSail()` returning
  `[Interrupt]`, and `repaired(_:_:)`. `JourneyBot` gained `shopHere`, `useYard` and a
  loop that answers a hold until the party leaves.
- The set-piece risks (slides, thin ice, Five Fingers) are rare enough that a bot that
  always takes the risky answer wins about as often as a careful one (March: 29 / 24 / 16
  against 30 / 24 / 15). What decides a
  run is money at Seattle, the police margin, the pace and rations on the trail, and the
  date.
- April is a little safer than March for the boatbuilder and no worse for the miner, but
  arrives later; the score's crowd line is what makes March the advice.
- February is harder than the spec's sim found (6/30 and 0/30 for the poorer roles):
  February parties spend their trail in deep cold on short commons.
