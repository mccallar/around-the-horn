# Around the Horn: 1849 — Native iOS Build Spec

> **For the implementer.** This document specifies a native iOS game written in Swift/SwiftUI. A working web prototype, `horn1849.html`, is supplied alongside this file. **The prototype is the reference implementation**: when this spec and the prototype disagree on a number, a formula or a line of text, follow the prototype. Read both before writing code.

---

## 0. How to use this spec (instructions to the implementer)

1. Read this whole file, then read `horn1849.html` (the `<script>` block is the game logic, about 700 lines of JS).
2. Work through the **Milestones** (§12) in order. Finish each milestone's acceptance checks before starting the next one. After each milestone, build with `xcodebuild` and run the tests.
3. Keep game logic **pure Swift and UI-free** (`Engine/` folder) so it can be unit-tested and simulated headlessly.
4. Do not add third-party dependencies. Use only Apple frameworks: SwiftUI, Observation, AVFoundation, CoreHaptics/UIKit feedback, XCTest/Swift Testing.
5. Ask the developer before changing game balance numbers. The values below were tuned by running the web version through a few hundred simulated voyages.

### Project setup
Preferred: the developer creates the project in Xcode first (*File › New › Project › iOS › App*, product name `AroundTheHorn`, Interface **SwiftUI**, Language **Swift**, storage **None**, tests **enabled**), then the implementer works from the project folder.

Fallback, if no project exists: generate one with **XcodeGen** (`brew install xcodegen`) from a `project.yml` you write, then run `xcodegen generate`.

- Deployment target: **iOS 17.0** (uses `@Observable`).
- Devices: iPhone (primary), iPad (supported, content column max ~540 pt wide, centered).
- Orientation: portrait on iPhone; any orientation on iPad.
- Swift 5.9+ (Swift 6 language mode fine if it compiles cleanly).

---

## 1. The game in one paragraph

A retro resource-management voyage in the spirit of the classic 1970s/80s trail games, but at sea and wholly original. It is 1849. Gold has been found in California. The player is a ship's captain sailing **14,000 nautical miles** from New York, south through the Atlantic, around Cape Horn (or through the Strait of Magellan), and north up the Pacific to San Francisco. The player picks a background, names the ship and four crew, chooses a departure month, buys supplies, then sails day by day. Along the way they handle weather, disease, scurvy, storms, ship damage, random events, ports, trading, a fishing mini-game, and a big route choice at the bottom of the world. A crew member who dies is buried at sea with an epitaph the player writes. If the captain dies or the ship sinks, the game is over. Reaching San Francisco produces a score and a top-ten entry.

**Aesthetic:** an Apple II–era terminal look with a modern touch: dark navy-black background, parchment text, amber highlights, pixel-art scenes, chunky numbered choice buttons, chiptune beeps. Phone-first.

**Originality:** all names, text and art are original. Do not use names, text, art, or iconic phrases from any existing commercial game.

---

## 2. Architecture

```
AroundTheHorn/
  App/
    AroundTheHornApp.swift        // @main, injects GameController
    RootView.swift                // switches on controller.screen
  Engine/                         // PURE SWIFT, no SwiftUI/UIKit imports
    GameState.swift               // Codable state (ship, crew, supplies, date…)
    GameData.swift                // static tables: items, ports, stops, regions, weather, ailments, roles
    GameEngine.swift              // day simulation, events, choices, scoring
    Interrupt.swift               // things that pause travel and need UI
    RNG.swift                     // RandomSource protocol + SeededRNG (SplitMix64)
    Trade.swift                   // offer generation
    Score.swift                   // scoring + top ten model
  UI/
    Theme.swift                   // colors, fonts, button styles
    Markup.swift                  // tiny [red]..[/red] → AttributedString parser
    Components/ChoiceList.swift   // numbered choice buttons
    Components/StatusPanel.swift
    Components/HealthBar.swift
    Scenes/SeaSceneView.swift     // pixel-art animated scene (Canvas + TimelineView)
    Scenes/ShipSprite.swift
    Screens/TitleView.swift, LearnView.swift, RoleView.swift, NamesView.swift,
            MonthView.swift, OutfitIntroView.swift, ShopView.swift, TravelView.swift,
            SeaMenuView.swift, PortMenuView.swift, MessageView.swift, ChoiceEventView.swift,
            BurialView.swift, SuppliesView.swift, ChartView.swift, FishingView.swift,
            PaceView.swift, RationsView.swift, RestView.swift, RepairView.swift,
            ShipyardView.swift, ForkView.swift, EndView.swift, GameOverView.swift, TopTenView.swift
  Services/
    GameController.swift          // @Observable; owns state, engine, screen stack, travel timer, interrupt queue
    Persistence.swift             // save/load JSON (Application Support), top ten, settings
    Audio.swift                   // AVAudioEngine square-wave synth (beeps + short tunes)
    Haptics.swift
  Resources/
    Fonts/VT323-Regular.ttf, PressStart2P-Regular.ttf   // SIL Open Font License — include OFL.txt
    Assets.xcassets (AppIcon, AccentColor)
AroundTheHornTests/
  EngineTests.swift
  BalanceSimulationTests.swift
```

### Key design rules
- **`GameState` is a `Codable` struct** holding everything needed to resume. Store the date as `startYear`, `startMonth` (0-based, matching the JS) and `day` (days elapsed). Compute the calendar date with `Calendar(identifier: .gregorian)`, adding `day` days to the 1st of the start month.
- **`GameEngine` mutates state and returns `[Interrupt]`.** It never touches UI. All randomness goes through an injected `RandomSource` so tests can be deterministic.
- **`Interrupt`** (enum) replaces the JS "queue of screen functions":
  ```swift
  enum Interrupt: Codable, Equatable {
    case message(String)                       // markup text, "Continue"
    case choice(ChoiceEvent)                   // stranger sail, albatross, stowaway, icebergs, equator, galápagos, fork, port arrival
    case burial(crewID: UUID, cause: String)   // epitaph text field
    case arrival(stopID: String)               // dispatches to port/mark/line/fork/island/end
    case gameOver(title: String, body: String)
    case finale
  }
  ```
  `ChoiceEvent` has an `id` (e.g. `.stranger`, `.albatross`, `.stowaway(name)`, `.icebergs(fog: Bool)`, `.equator`, `.galapagos`, `.fork`, `.pilot(cost)`, `.portArrival(stopID)`, `.tradeOffer(Offer, intro)`), prompt text, and option labels. The UI calls `engine.resolve(event, optionIndex) -> [Interrupt]` and keeps processing the returned interrupts before resuming travel.
- **`GameController`** (`@MainActor @Observable`) holds the `screen` enum, the pending interrupt queue, and the travel `Task` that ticks one day every **0.7 s** while traveling. If a tick returns interrupts, it stops traveling, presents them in order, then resumes travel automatically, unless an interrupt routes elsewhere (port menu, game over, finale). This matches the prototype's `tick()` / `runQueue()`.
- **Auto-save** after every simulated day and on every menu screen, but never after game over or the finale. Delete the save on game over and on the finale.
- On `scenePhase == .background`: stop the travel timer and save. On return, show the sea menu (or port menu), not the travel loop.

---

## 3. Visual design

### Palette (match the prototype CSS variables)
| Token | Hex | Use |
|---|---|---|
| bg | `#0A0E14` | app background |
| panel | `#101722` | status boxes, message boxes |
| ink | `#ECE4CF` | body text |
| dim | `#8F8A7A` | secondary text |
| amber | `#F2B632` | headings, numbers on buttons, highlights, primary button border |
| teal | `#56D6C4` | notes (e.g. "Caught 30 gallons of rainwater"), epitaphs |
| red | `#FF6B5B` | danger, deaths, STORM |
| green | `#8FE388` | good health, improvements |
| line | `#2A3547` | 2-pt borders |

### Type
- Body: **VT323**, about 22 pt (scale with Dynamic Type via `relativeTo:`; cap at about 30 pt).
- Headings: **Press Start 2P**, about 13 pt (title 21 pt).
- Both fonts are SIL OFL; download from Google Fonts, add to the bundle, register in Info.plist (`UIAppFonts`), and include `OFL.txt`.

### Components
- **Choice buttons:** full width, left-aligned, 2-pt `line` border, square corners, min height 48 pt, label prefixed with amber `1.` `2.` …. Pressed state inverts (amber fill, black text). Primary = amber border. Disabled = 40% opacity. Light haptic + click beep on tap.
- **Message box:** 2-pt amber border, panel fill, slightly larger text.
- **Status panel:** date (amber) + region (dim, small) on top; rows of label/value pairs: Weather (red if STORM), Health (green/amber/red), Provisions, Water, Next stop + distance, Sailed `x of 14,000 nm`, Hull · Sails %, and a teal note line.
- **Scanlines:** a subtle overlay of 1-pt dark lines every 3 pt at about 16% opacity, non-interactive.
- **Top bar:** "AROUND THE HORN · 1849" (dim) and a sound toggle `♪ on` / `♪ off`.

### Sea scene (`SeaSceneView`)
Draw at a **logical 160×80 pixel grid**, scaled up with nearest-neighbour (each logical pixel is a filled rect at `scale = width/160`; snap to whole points). Use `TimelineView(.animation)` + `Canvas`. Port the prototype's `drawScene(t)` exactly:
- 8 banded sky gradient steps from `top` to `bot` colors per weather (table in the prototype's `SKY` constant), horizon at y = 46.
- A pixel sun when the weather has one; drifting pixel clouds (count by weather); a hillside town on the right when `atPort`.
- Sea fill with 8 rows of scrolling wave dashes. Scroll speed = `14 × weather.speed + 2` while traveling, otherwise 1.5. In a gale or storm the dashes jitter vertically.
- The **ship sprite** (the `SHIP_SPR` string grid in the prototype, 26×18 cells; `s`=sail `#EFE6CC`, `m`/`b`=mast/bowsprit `#6B4A2B`, `h`=hull `#4A2E1A`, `y`=stripe `#D9A441`, `r`=flag `#D64545`) at x = 44, bobbing with `sin(t)`. When sails < 60%, skip sail pixels where `((col*7 + row*13) % 37) < (60 − sails)/2.2`, so torn sails show holes.
- Rain streaks, snow dots, fog overlay, and random lightning flashes for storm.

---

## 4. Static game data

Copy every table below from the prototype (`ROLES`, `ITEMS`, `PORTS`, `STOPS`, `REGIONS`, `MAGELLAN`, `WEATHER`, `PACE`, `RATIONS`, `AIL`, `FISH`, `ROUTE`, `ROUTE_M`, `LAND`, `SHIPS`, `FIRST`, `DEFAULT_TOP`) into Swift enums/structs. The values are summarized here.

### Roles
| id | Menu label | Start cash | Score multiplier | Perk |
|---|---|---|---|---|
| merchant | Be a merchant from Boston | $1,500 | ×1 | — |
| shipwright | Be a shipwright from Mystic | $850 | ×2 | Repairs: sailcloth +40% (others +25), timber +35% (others +20) |
| whaler | Be a whaler from Nantucket | $500 | ×3 | Fishing: hit padding 4 (others 1.5); can keep 300 lb per outing (others 200) |

### Items (New York base prices)
| key | name | unit | step per tap | base price | max held | notes |
|---|---|---|---|---|---|---|
| food | Provisions | lbs | 100 | $0.10 / lb | 3000 | |
| water | Fresh water | gal | 100 | $0.04 / gal | 1000 | |
| limes | Citrus | crates | 1 | $4 | 40 | stored as a Double (fractional use) |
| meds | Medicine | kits | 1 | $12 | 12 | |
| clothes | Oilskins & woolens | sets | 1 | $9 | 12 | |
| sailcloth | Spare sailcloth | bolts | 1 | $14 | 20 | |
| timber | Spare timber | bundles | 1 | $11 | 20 | |
| tackle | Fishing tackle | boxes | 1 | $3 | 600 throws | 1 box = **20 throws**; state stores throws |

Port price = `base × port.mult × (port.mod[item] ?? 1)`.

### Ports
| id | Name | mult | mods | fever |
|---|---|---|---|---|
| ny | New York | 1.0 | — | no |
| cv | Porto Praia, Cape Verde | 1.3 | limes .55, water .6, clothes 1.4, timber 1.4 | no |
| rio | Rio de Janeiro | 1.45 | limes .5 | **yes** |
| falk | Port Stanley, Falklands | 2.0 | clothes .9, timber 1.2 | no |
| valp | Valparaíso | 1.6 | — | no |
| callao | Callao, Peru | 1.75 | limes .7 | **yes** |

Each port has a shop name, an arrival paragraph, and **three "talk" lines** (cycled in order). Copy them verbatim from `PORTS`.

### Stops along the route (by nautical-mile marker)
| idx | id | type | mile | short name |
|---|---|---|---|---|
| 0 | ny | port | 0 | New York |
| 1 | gulf | mark | 300 | Gulf Stream |
| 2 | cv | port | 2900 | Cape Verde |
| 3 | line | line | 3850 | Equator |
| 4 | rio | port | 5200 | Rio de Janeiro |
| 5 | falk | port | 7000 | Falklands |
| 6 | tdf | fork | 7350 | Tierra del Fuego |
| 7 | pacific | mark | 7800 | The Pacific |
| 8 | valp | port | 8900 | Valparaíso |
| 9 | callao | port | 10200 | Callao |
| 10 | gal | island | 11300 | Galápagos |
| 11 | sf | end | 14000 | San Francisco |

### Ocean regions (by mile, `to` is exclusive)
| to | name | temp | flags | weather weights |
|---|---|---|---|---|
| 2000 | North Atlantic | cool | — | fair 30, fresh 22, rain 14, gale 14, fog 8, storm 5, light 7 |
| 3450 | Northeast Trades | warm | — | fair 35, fresh 40, rain 10, light 10, gale 5 |
| 4300 | The Doldrums | hot | — | calm 32, light 25, hot 18, rain 20, fair 5 |
| 6000 | Southeast Trades | warm | — | fair 35, fresh 35, rain 12, light 12, gale 6 |
| 7350 | Roaring Forties | cold | south | fresh 22, gale 30, storm 12, rain 14, fog 10, cold 12 |
| 7800 | Cape Horn | freezing | south, horn | gale 35, storm 28, cold 22, fog 8, fresh 7 |
| 9600 | Humboldt Current | cold | south | fair 30, fresh 25, fog 22, light 10, gale 13 |
| 11800 | Tropical Pacific | hot | — | fair 35, fresh 20, light 20, calm 10, rain 10, hot 5 |
| ∞ | North Pacific | cool | — | fair 22, fresh 22, gale 18, fog 18, rain 15, storm 5 |

**Strait of Magellan** replaces the region for miles 7350–7799 when `passage == .magellan`: temp freezing, flags south + strait, weights fresh 12, gale 25, storm 8, cold 25, fog 20, rain 10.

**Effective temperature** `tempAt(region)`: the North Atlantic becomes `cold` in Nov–Mar. A `south` region with temp `cold` becomes `freezing` during southern winter (May–Sep, i.e. months 4…8).

### Weather
| key | display | speed × | sail wear × | harsh (hp/day) |
|---|---|---|---|---|
| fair | Fair winds | 1.0 | .25 | 0 |
| fresh | Fresh breeze | 1.18 | .4 | 0 |
| light | Light airs | .5 | .1 | 0 |
| calm | Becalmed | .06 | .03 | 0 |
| hot | Hot & still | .35 | .05 | 0 |
| rain | Rain squalls | .9 | .3 | 0 |
| fog | Thick fog | .6 | .15 | 0 |
| cold | Sleet & snow | .8 | .6 | 0 |
| gale | Gale | .75 | 1.2 | .6 |
| storm | STORM | .35 | 2.5 | 1.5 |

**Weather roll** (`rollWeather`), in this order:
1. If `forceFair > 0`: decrement it and return `fair`.
2. Start from the region weights.
3. Southern winter in a `south` region: gale +20; storm +30 at the Horn, otherwise +18; cold +15; fair ×0.5; fresh ×0.6.
4. North Atlantic in Dec/Jan/Feb: gale +8, storm +5.
5. `badLuck > 0` (the albatross was shot): decrement it; gale +20, storm +15, calm +10.
6. Weighted random pick.

### Pace & rations
| Pace | base nm/day | hp/day | sail wear × | description |
|---|---|---|---|---|
| Easy sail | 100 | +0.5 | 0.6 | Reefed sails. Gentle on ship and crew. |
| Steady (default) | 135 | 0 | 1 | A sensible spread of canvas. |
| Full canvas | 170 | −1 | 2 | Every sail set. Fast, but hard on sails and sailors. |

| Rations | lb/person/day | hp/day |
|---|---|---|
| Filling (default) | 3 | +1 |
| Meager | 2 | −0.3 |
| Bare bones | 1 | −2.2 |

### Ailments
| name | hp/day | duration (days) |
|---|---|---|
| scurvy | 2.2 | until cured |
| ship fever | 4.5 | 6–11 |
| dysentery | 4.5 | 5–9 |
| yellow fever | 6.5 | 5–8 |
| a fever | 3 | 4–7 |
| pneumonia | 4.5 | 6–10 |
| frostbite | 2.5 | 5–9 |
| a broken arm | 1.2 | 14–24 (named "an infected wound" if it kills) |
| exhaustion | 1.5 | 3–5 |

---

## 5. Simulation rules (port these exactly)

### 5.1 One day under sail — `sailDay()`
1. Clear `note`. `day += 1`. Roll the weather for the current region.
2. **Speed:** `sp = pace.speed × weather.speed`
   `× (0.45 + 0.55 × sails/100)`
   `× (0.75 + 0.25 × hull/100)`
   `× crewFactor` (living ≥4 → 1, 3 → .85, 2 → .65, 1 → .45)
   `× 0.5` if in the Strait
   `× 0.6` if (Horn region or Strait) during southern winter
   `× random(0.85…1.15)`, rounded, min 0.
   If `mile + sp ≥ nextStop.mile`, clamp to the stop and mark `arrived`.
3. If calm, note: "Not a breath of wind. The sails hang slack."
4. `consume(mode: .sail)` then `health(mode: .sail)`. Stop here if the game ended.
5. `wear()`. Stop here if the game ended.
6. If not arrived, check in priority order (at most one):
   - In the Strait: aground chance **5.5%** (1.2% with pilot) → hull −12…28, an extra day lost, message; check sinking.
   - Else in the Horn region: **1.2%** man-overboard.
   - Else **11%** chance of a random sea event (§5.6).
7. If arrived: `stopIdx += 1` and queue `.arrival(stop)`.
8. Save.

### 5.2 Consumption — `consume(mode)`
- `n` = living crew. Food need = `n × rations.lb`. If short: food = 0, `starving = true`.
- Water need = `n × (hot ? 1.5 : 1)`. If short: water = 0, `thirst = true`.
- Citrus: in port → `noCitrus = 0`. Else if limes > 0 → limes −= `n × 0.02`, `noCitrus = 0`. Else `noCitrus += 1`.
- Not in port and weather is rain or storm → catch 15–45 gal of rain (capped at max). Note: "Caught N gallons of rainwater in the sails."
- One-time warning flags (reset when the stock recovers above 10 days):
  - out of food
  - about a week of food left (< 7 days)
  - water dry
  - water < 5 days
  - out of citrus (reset when limes > 1)

### 5.3 Health — `health(mode)` (mode ∈ sail / sea-rest / port-rest)
For each living crew member `i` (0 = captain), with `warm = i < clothes`:
- `d = rations.hp`
- sail: `+ pace.hp − weather.harsh`. Sea rest: +3. Port rest: +6.
- starving −7; thirst −12.
- Not in port: freezing → `−(warm ? 1.4 : 4.5) − (southernWinter ? 1 : 0)`; cold → `−(warm ? 0 : 2.2)`; hot → −0.4.
- **If ailing:** `d −= ailment.dmg × (treated ? 0.5 : 1)`.
  - Scurvy: cured with probability .35/day if limes > 0 (.6/day in port), with a message.
  - Other ailments: `ailDays −= (port 2 / sea 1.5 / sail 1)`; when ≤ 0, cured with the message "NAME is well again."
- **If not ailing:** `d += 1` (natural recovery).
- `hp = clamp(hp + d, 0, 100)`.
- **New illness** (if not ailing and hp > 0):
  - `p = .0035 + (100 − hp) × .00035`
  - bare rations +.005; starving +.03; thirst +.04; hot +.003
  - cold or freezing without woolens and not in port +.01
  - at a fever port +.012
  - in port the total ×.7
  - Roll `p`. Otherwise, if not in port and `noCitrus > 35`, roll scurvy at `min(.12, (noCitrus − 35) × .004)`.
- **Sicken:** pick from a pool (fever port: yellow fever/a fever/dysentery; hot: a fever/dysentery/exhaustion/yellow fever/ship fever; cold/freezing: pneumonia/frostbite/a fever/ship fever/a broken arm; otherwise ship fever/dysentery/a fever/a broken arm/exhaustion). Set the duration. If not scurvy and meds > 0: use one kit and set `treated` ("You open a medicine kit (N left)."). Queue the message.
- **Deaths:** hp ≤ 0 → dead. Cause = ailment (with the death-name mapping) or thirst / starvation / exhaustion. Captain → `.gameOver("You, Captain NAME, have died of CAUSE.", "The crew sails the ship into the nearest port and scatters. The voyage is over.")`. Anyone else → `.burial`.

### 5.4 Ship wear — `wear()`
- `sails −= pace.wear × weather.wear × random(.6…1.4)`.
- Hull loses 0.03/day.
  - Storm: additional `random(1…2.6)` × (full 1.6 / easy .7 / steady 1) × (Horn 1.5) × (Strait .5).
  - Gale: additional `random(0…0.8)` × (full 1.5).
- Hull < 35 and food > 50: 6% chance seawater spoils 20–60 lb.
- Warnings: hull < 30 (resets above 50), sails < 25 (resets above 50).
- Hull ≤ 0 → `.gameOver("The SHIP has foundered.", "Her seams opened faster than the pumps could keep up. She went down by the head, taking everything with her.")`.

### 5.5 Resting / fishing / repairs: `passDays(n, mode)`
For each day: `day += 1`; at sea roll the weather (in port it's fair); `consume`; `health`. No movement, no wear, no events. Each repair or shipyard job and each fishing trip costs 1 day.

### 5.6 Random sea events
Build the eligible list, then do a weighted pick:

| weight | condition | effect |
|---|---|---|
| 6 | food > 150 | Rats: lose 5–14% food |
| 5 | water > 120 | Foul cask: lose 40–120 gal |
| 4 | temp hot/warm | Flying fish: +8–30 food |
| 3 | always | Wreckage: 50% +1–2 timber; else 60% +60–120 food (salt pork); else a drifting nameboard (flavor) |
| 6 | gale/storm/fresh | Split sail: sails −12…28 |
| 4 | gale/storm | Topmast carried away: sails −15, hull −6, 50% a random healthy crew member gets a broken arm (−10 hp) |
| 4 | always | Leak: hull −8…18 |
| 3 | gale/storm/cold | Man overboard (non-captain): 65% rescued −25 hp; else lost (grave "drowned", epitaph "Lost overboard. No grave but the sea.") |
| 1.5 | food > 100 | Galley fire: −8% food, hull −4 |
| 2 | rain/storm | Lightning: sails −18 |
| 2.5 | not Horn/Strait | **Strange sail** (choice) |
| 2 | south region, not yet seen | **Albatross** (choice) |
| 1.5 | not yet seen, day < 30 | **Stowaway** (choice) |
| 5 | freezing, or south and 6400 < mile < 8300 | **Icebergs** (choice) |
| 2 | always | Whales (flavor; whaler gets an extra line) |
| 1.5 | gale/storm | St. Elmo's fire: `forceFair = 2` |

**Choice events** (exact text in the prototype):
- **Strange sail.** *Hail her*: 65% a trader → `makeOffer()` trade screen (or a whaler with news if there's no offer); 35% privateers. *Run*: sails −5…12; 75% escape; else privateers. **Privateers** take $40–140 and 60–200 lb food (capped at what you have); 35% injure a healthy non-captain (broken arm, −20 hp).
- **Albatross.** *Let it be* (approving nods) or *Shoot it*: +12 food, `badLuck = 25`, the crew goes quiet.
- **Stowaway** (random unused first name). *Sign on as cabin hand* → new crew member at 85 hp. *Put ashore at Cape Verde* → joins with `leaveAt = "cv"`, removed on arrival at CV ("NAME waves goodbye from the quay.").
- **Icebergs.** *Shorten sail* → lose a day (consume + health), 10% hull −6…12. *Hold course* → risk = (fog .25 / else .12) + (full .15): hull −18…35.

### 5.7 Landmarks — `arrival(stop)`
- **mark** gulf: Gulf Stream text. **mark** pacific: "rounded Cape Horn" or "threaded the Strait" text depending on `passage`.
- **port:** reset `tradesLeft = 3`, `talkIdx = 0`; remove crew with `leaveAt == stop`; show the arrival paragraph and date/day → *Drop anchor and go ashore* (port menu) or *Sail on without stopping*.
- **line (Equator):** *Hold the ceremony (1 day)* → day +1, food −20, everyone +8 hp. Or *No time for foolishness*.
- **fork (Tierra del Fuego):** warn in red if southern winter. Options:
  - *Round Cape Horn* → `passage = .horn`.
  - *Take the Strait of Magellan* → `passage = .magellan`, then the pilot offer at Punta Arenas: $75 (disabled if you can't afford it) → `pilot = true`, or navigate yourself.
  - *Ask the first mate's advice* → message, then back to the fork.
- **island (Galápagos):** *Send a party ashore (2 days)* → +150–250 water, +40–100 food, `noCitrus = 0`, scurvy cured for all, 15% a healthy non-captain breaks an arm; simulate 2 sea-rest days. Or *Sail on*.
- **end:** finale (§7).

### 5.8 Trading — `makeOffer()`
Values: food .14, water .05, limes 4, meds 12, clothes 9, sailcloth 14, timber 11, tackle .15/throw, money 1.
- `want` = random item you hold at least $25 of (or money if ≥ $30).
- `give` = a random different item you hold less than 80% of max of.
- `V = random(25…70)`.
- `wantAmt = round(min(held × .6, V × random(1…1.35) / value))`.
- `giveAmt = round(V × random(.8…1.1) / value)`.
- Rounding: food/water to 10s (min 10), tackle to 20s, money to 5s, else integers ≥ 1. No offer if `wantAmt > held`.

Ports allow 3 trade attempts per visit ("Nobody else on the waterfront wants to trade with you today.").

---

## 6. Screens & flow

```
Title ─┬─ Sail for California → Role → Names → Month → Outfit intro → Shop(ny) → Depart → TRAVEL
       ├─ Continue the voyage of the <ship>   (only if a save exists → Sea menu / Port menu)
       ├─ Learn about the passage (3 pages)
       └─ See the top ten

TRAVEL (scene + live status + "Heave to & take stock")
   ├─ tick every 0.7 s → interrupts → Message / Choice / Burial / Arrival / GameOver / Finale
   └─ Heave to → SEA MENU

SEA MENU: Continue · Check supplies & crew · Look at the chart · Change pace (shows current) ·
          Change rations (shows current) · Heave to and rest (1/2/3/5 days) · Make repairs · Go fishing
PORT MENU: Weigh anchor · Check supplies & crew · Chart · Pace · Rations · Rest ashore (1/2/3/5) ·
           Attempt to trade · Talk to people · Buy supplies · Visit the shipyard
```

Screen details (copy all copy text from the prototype functions of the same name):
- **Role:** three roles plus *Find out the differences*.
- **Names:** ship name + captain + 4 crew. The placeholders are random suggestions from `FIRST`/`SHIPS`; an empty field takes its placeholder. Offer *Pick new names for me*. Max length 16 (ship 22).
- **Month:** Dec 1848, Jan–Apr 1849, plus *Ask for advice*.
- **Outfit intro:** a bullet list of what to buy and why.
- **Shop:** a header showing cash and the running bill (red if over budget). Each item row shows name, unit price, "Have N", description, and a − / qty / + stepper. The + is capped so held + cart ≤ max. Buttons: *Pay $X and leave* (disabled if over budget) / *Leave without buying* (when the bill > 0). Away from New York, show "Prices here are N% above New York, more or less." **Long-press on +/− should auto-repeat** (an iOS improvement over the prototype).
- **Depart:** you can't leave New York with 0 food.
- **Supplies:** an inventory table; ship hull/sails bars; pace/rations line (red "N days without citrus" if > 20); crew list with hp bars and status (ailment / healthy / weary / very weak); a red warning if woolens < crew; a "Lost" list.
- **Repairs (sea):** *Mend sails* (1 bolt) / *Patch the hull* (1 bundle). Each takes 1 day, shows the result, and returns to Repairs. *Done* → sea menu.
- **Shipyard (port):** hull cost `ceil((100 − hull) × 2.5 × mult)`, sails cost `ceil((100 − sails) × 1.8 × mult)`. Each restores to 100 and takes 1 day.
- **Rest:** 1/2/3/5 days, then "your crew's health is X".
- **Burial:** red death line; "The crew sews NAME into a sailcloth shroud…"; an epitaph `TextField` (max 70, placeholder "Fair winds, shipmate."); *Commit to the deep*. Store the grave (name, cause, date, epitaph).
- **Chart:** see §8.
- **Fishing:** see §9.

**Health label** from the crew's average hp: ≥ 75 good (green), ≥ 50 fair (amber), ≥ 28 poor (red), otherwise very poor (red).

**Keyboard** (iPad/hardware keyboard): number keys 1–9 trigger choices; Return/Space triggers a lone choice. Implement with `.keyboardShortcut` or `onKeyPress`.

---

## 7. Endings & scoring

**Finale** (stop index 11): "Land ho! The SHIP passes through the Golden Gate on DATE, after N days at sea." + the abandoned-ships paragraph + the score table + rank + graves list. Buttons: *Sail again*, *See the top ten*.

**Score**
| line | points |
|---|---|
| survivors × health | good 500 / fair 400 / poor 300 / very poor 200 per survivor |
| Hull & sails | `round(hull × 2 + sails)` |
| Provisions & water | `food/25 + water/50` (floored) |
| Stores & spares | `limes×2 + meds×5 + clothes×2 + sailcloth×4 + timber×4 + tackle/20` |
| Cash | `money / 5` |
Total = subtotal × role multiplier.

**Ranks:** ≥ 7000 Master Mariner · ≥ 4000 Able Seaman · ≥ 2000 Ordinary Seaman · otherwise Greenhand.

**Top ten:** seeded with `DEFAULT_TOP` (10 invented names, 7650 down to 1250). Insert the captain's name if the score beats #10, highlight the new row, and persist.

**Game over** screen: red title, body, "DATE · N nautical miles from New York", graves list, *Try again*.

---

## 8. Chart

Logical canvas **230×210**, equirectangular projection: `x = (lon + 130) × 2`, `y = (45 − lat) × 2`.
- Ocean `#0D2A44`; dotted graticule every 15° (`#173B5C`); dotted equator `#2F6A96`.
- Land polygons (`LAND` in the prototype: North & Central America, South America, West Africa, Cuba) filled `#B9A26C`, plus little island blocks (Cape Verde, Falklands, Galápagos).
- Route polyline from `ROUTE` (or `ROUTE_M` once the Strait is chosen). Each vertex is `[lon, lat, mile]`; interpolate the position by mile.
- Full route dotted grey; the sailed portion dotted amber; stop markers (amber once passed); a blinking red 5×5 ship marker.
- Below the chart: a 2-column legend of stops (✓ passed, ► next, · later) and "X of 14,000 nautical miles sailed. Y to go."

## 9. Fishing mini-game

- Not allowed with 0 tackle ("You have no fishing tackle left.") or in a gale/storm ("The seas are far too rough to fish.").
- Logical **160×200** canvas: sky above y = 28, then water in 10 gradient bands `#1F6B96` → `#061A2B`, faint moving light shafts, and a small boat at the top center with a red-shirted fisher.
- **25-second timer**. HUD: Throws / Caught lbs / Time.
- Tap the water (below y = 30) → a harpoon flies from (80, 28) toward the tap at 150 px/s with a rope line. One harpoon in flight at a time; each throw costs 1 tackle.
- Fish spawn every 0.5–1.1 s from either side, at y 45–188, and swim with a sine wobble. Weighted types:

| fish | lb | w×h | speed px/s | weight | color |
|---|---|---|---|---|---|
| mackerel | 4 | 9×3 | 26–42 | 35 | `#7FD6C9` |
| bonito | 12 | 12×4 | 30–48 | 26 | `#6F9DE0` |
| dorado | 25 | 15×5 | 36–56 | 18 | `#E8C547` |
| tuna | 60 | 20×7 | 24–38 | 13 | `#46689A` |
| shark | 120 | 28×7 | 38–58 | 8 | `#8A949E` (+ dorsal fin) |

- A hit adds the fish's lb, shows a floating "+25 lb dorado", plays a tune, and gives a light haptic.
- Ends when time runs out, tackle hits 0 with nothing in flight, or *Back to the ship*. Keep `min(caught, 200 or 300 for whaler)`, also capped by food max. Message → 1 sea-rest day → sea menu.
- Use `TimelineView(.animation)` + `Canvas`; keep the simulation in a small `@Observable` model with a `dt` step clamped to ≤ 0.05 s.

## 10. Audio & haptics

- Implement a tiny square-wave synth with `AVAudioEngine` + `AVAudioSourceNode` (or pre-render short PCM buffers). Volume is low (≈ 0.03 amplitude) with an exponential decay per note.
- Sounds: click (520 Hz, 30 ms); message (240 Hz, 70 ms); shop +/− (880/440 Hz); harpoon (320 Hz sawtooth). Tunes are `[(Hz, seconds)]` lists from the prototype: `T_TITLE` (on starting a new game), `T_ARRIVE`, `T_DEATH`, `T_WIN`, plus the fish hit `[(660,.06),(880,.1)]`.
- Use `AVAudioSession` category `.ambient` so the player's music isn't interrupted. Respect the mute toggle (persisted).
- Haptics: light impact on choice taps, success on a catch or arrival, warning on a death or storm damage.

## 11. Persistence

- **Save:** encode `GameState` as JSON to `Application Support/save.json` after each day and on menu screens. The title screen shows *Continue…* when a valid save exists. Delete the save on game over and the finale.
- **Top ten:** `topten.json` (or `UserDefaults`).
- **Settings:** mute flag in `UserDefaults`.
- Version the save (`saveVersion: Int`). Discard incompatible saves gracefully.

---

## 12. Milestones (build in this order)

**M1 — Engine & data (no UI).** All tables, `GameState`, `RNG`, `GameEngine.sailDay/passDays/consume/health/wear/events/resolve`, trading, and scoring.
*Accept:* unit tests cover:
- consumption math
- scurvy onset after 35 citrus-free days
- medicine halving damage
- captain death → gameOver
- hull 0 → gameOver
- arrival exactly at stop miles
- Strait region selection
- southern-winter weather weights
- offer rounding
- score arithmetic

**M2 — Balance harness.** A headless "sensible player" bot in tests (mirrors `test/bot.js` behavior described below). It runs 30 seeded voyages per role.
*Accept*, with tolerance ±15 percentage points:
- merchant wins ≥ 85%
- shipwright wins 45–85%
- whaler wins 15–50%
- median voyage length 150–200 days

Bot policy:
- Buys sensibly at New York and at each port for `(distance to the next port)/85 + 10` days of food, water and citrus.
- Keeps woolens ≥ crew.
- Rests 3 days in port if average hp < 70.
- Uses the shipyard if hull < 70.
- Mends at sea if sails or hull < 40.
- Non-merchants use meager rations and fish (simulated catch) when food is under 12 days.
- Takes the Horn or the Strait at random; always holds the Equator ceremony; always lands at the Galápagos.

**M3 — Theme & shell.** Fonts, palette, `ChoiceList`, message box, status panel, top bar with mute, scanline overlay, `GameController` screen routing, Title/Learn/Role/Names/Month/Outfit screens.

**M4 — Shop & travel loop.** `ShopView` with long-press repeat, departure, `TravelView` with a 0.7 s ticking `Task`, interrupt presentation (message, choice, burial), the sea menu and all its sub-screens.

**M5 — Sea scene.** Pixel `SeaSceneView` matching the prototype: weather palettes, ship sprite with torn sails, port town, rain/snow/fog/lightning.

**M6 — Ports & landmarks.** Port menu, shop at port prices, trade, talk, shipyard, rest ashore, stowaway drop-off, Equator, fork + pilot, Galápagos, Pacific/Gulf marks.

**M7 — Chart & fishing.** As in §8 and §9.

**M8 — Endings, persistence, audio, haptics.** Finale with score and top ten, game over, save/continue, background handling, synth sounds, haptics.

**M9 — Polish.**
- App icon: a pixel ship on navy. Generate a 1024×1024 PNG programmatically or draw it in a script.
- Launch screen in the background color.
- VoiceOver labels on the scene ("Ship sailing in fair winds"), choice buttons, and bars.
- Dynamic Type sanity check; iPad centered column; landscape on iPad.
- Make sure no text is cut off on iPhone SE (375 pt wide).

**Definition of done:** a full voyage is playable on device from title to finale and from title to game over, with no crashes, the balance tests pass, and save/resume works after force-quitting mid-voyage.

---

## 13. Text style rules

- Messages use a minimal markup: `[red]…[/red]`, `[green]…[/green]`, `[amber]…[/amber]`, `[dim]…[/dim]`, `[i]…[/i]`, rendered via `AttributedString`. Convert the prototype's `<span class="red">` and `<i>` to this markup.
- Escape player-entered names (they are plain text in SwiftUI anyway; never interpret markup inside names).
- Keep the period voice: plain, salty, a little wry. No modern slang.
- Every sentence a player reads must be original.
