// The Long Transfer, 2087: everything the shell says and draws for it
// (AroundTheHorn/Journeys/MarsSkin.swift). The engine counts in days and in units of 10,000
// km, and calls its two meters `hull` and `sails`; here they are the pressure hull and power
// & drive, `sailcloth` is array panels, `timber` hull patches, `limes` supplement packs and
// `tackle` tether cartridges, counted in shots. Propellant is stored in tenths of a tonne.
// The words are the app's, line for line; the art is in the files beside this one.
//
// `skin(J)` dresses the journey `J` (its tables, from the engine's `journeys()`). Every
// function of the voyage takes the bridge's view `v`: `v.state` is the GameState, and the
// rest is what the app reads off it (`v.dateText`, `v.healthLabel`, `v.region`, …), with
// what it asks the engine (`Mars.dark`, `coasting`, `lastOfThePropellant`, and what
// Gateway's purse still runs to, `gatewaySells`) in `v.hooks.mars`.

import { escape, formatNumber } from '../markup.js';
import * as scene from './mars-scene.js';
import { chart } from './mars-chart.js';
import { forage } from './mars-forage.js';

export const id = 'mars';

/** The engine's own figures, held to it by `MarsSkinTests`: the contract pays for every day under this, at this much a day. */
export const contractDays = 170;
export const bonusPerDay = 25;

/** Units of 10,000 km as millions of km, without the unit: 31,245 reads "312.45". */
export function millions(units) {
  const u = Math.abs(units);
  const part = u % 100;
  return `${units < 0 ? '-' : ''}${formatNumber(Math.trunc(u / 100))}.${part < 10 ? '0' : ''}${part}`;
}

/** "312.45 million km". */
export const km = (units) => `${millions(units)} million km`;

/** "1 day", "3 days". */
export const days = (n) => `${n} ${n === 1 ? 'day' : 'days'}`;

/** Swift's `x.rounded()`: halves away from zero. */
const rounded = (x) => Math.sign(x) * Math.round(Math.abs(x));

/** A number to a tenth, without a trailing ".0": "2.5", "4". */
export function tenth(x) {
  const r = rounded(x * 10) / 10;
  return r === rounded(r) ? String(Math.trunc(r)) : String(r);
}

export const card = {
  banner: 'THE LONG TRANSFER · 2087',
  title: 'THE LONG\nTRANSFER',
  year: '~ 2087 ~',
  tagline: 'Four hundred and eighty million kilometres from Earth orbit to Mars, in a freighter that has seen better decades.',
  start: 'Take the charter',
  /** `vessel` arrives escaped for markup. */
  resume: (vessel) => `Rejoin the [i]${vessel}[/i]`,
  learn: 'Learn about the transfer',
  learnPages: [
    {
      heading: 'The transfer',
      paragraphs: [
        'Mars has four thousand people on it, and they need everything. Twice a decade the planets line up, and anything that can hold air leaves Earth orbit with cargo.',
        'You have chartered a second-hand transfer freighter, with a crew of five counting yourself, to deliver to the settlement at [amber]Jezero[/amber], 480 million km along the transfer arc. The contract pays a bonus for every day under 170. After that nothing is forfeit; a late ship is merely late.',
        'There are four places to tie up: Gateway Yard, where you start; the cycler [i]Perpetua[/i], passing through at 155 million km; Midway Depot at 300; and Phobos Yard, 7 million short of the landing.',
        "Time passes a day at a time. The ledger counts in thousands of dollars, so a $9 medical kit is nine thousand dollars' worth of very good dressings. Nobody aboard finds this funny any more.",
      ],
    },
    {
      heading: 'Supplies',
      paragraphs: [
        '[amber]Propellant[/amber] drives the ship: a tonne a day at cruise, 0.7 at an economy burn, 1.6 at a hard burn. The tanks hold 100 tonnes, which is not enough to reach Mars. Run them dry and she coasts at four tenths of her speed, turning slowly with nothing to hold her steady, and power & drive loses a point a day.',
        '[amber]Water[/amber] is the other thing that runs out. The recycler gives back most of it, but 2 litres a head a day are gone for good. In the two old comet streams, a [amber]tether cartridge[/amber] and the grapple turn ice into water for the price of a shot.',
        '[amber]Power & drive[/amber] is the solar wings and the thruster as one. It wears every day, faster far from the Sun, and it heats the cabin: under 40% the crew is cold, under 20% freezing, and [amber]thermal suits[/amber], one each, are all that stands between them and hypothermia.',
        'At 0% the array is dark: no drive, no recycler, twice the water lost. A spare [amber]array panel[/amber] puts it right in a day. Without one, two of the crew can always go out in suits and rewire what is left of the wings: two days, for 10 points of power.',
        'The [amber]pressure hull[/amber] keeps the air in. Pebbles hole it and storms beat on it, and [amber]hull patches[/amber] mend it. If it ever shows 0%, it lets go. [amber]Supplement packs[/amber] keep bones from thinning: a month without, and they start to.',
      ],
    },
    {
      heading: 'Turnover and capture',
      paragraphs: [
        'Halfway, at [amber]Turnover[/amber], the ship turns end for end and starts braking. Run on four more days first and you arrive about four days sooner, for 8 tonnes of propellant and a braking burn the drive may not enjoy.',
        'At Mars you must be caught. [amber]Aerobraking[/amber], dipping through the top of the atmosphere, is quick and free and very hard on the hull. A [amber]propulsive capture[/amber] costs 10 tonnes and two or three days, and leaves the hull alone.',
        'The cycler [i]Perpetua[/i] never stops: matching orbits to dock costs 6 tonnes. Wave her by and the next station is 145 million km on. The cycler, turnover and the capture all need a drive: reach one with the array dark, and it waits until there is power.',
        'Every launch in the window is on the 7th, August to December 2087. October has the shortest arc. Earlier is slow and calm; later is slow and stormy, because the Sun is building to a maximum next spring.',
      ],
    },
  ],
  roleHeading: 'Who are you?',
  roleIntro: 'Plenty of people want to haul cargo to Mars. Three kinds actually do it. Which are you?',
  differencesAction: 'Weigh them up',
  differencesHeading: 'How they weigh up',
  differences: [
    'Propellant, water and spares all come out of the purse, and only one of these three started with much in it.',
    '[amber]Charter captain[/amber] — starts with $1,500.',
    '[amber]Yard rigger[/amber] — starts with $850. Gets far more out of every array panel and hull patch.',
    '[amber]Ice hauler[/amber] — starts with $625. A dead eye with the grapple, and her melt tank takes 100 litres from an outing where the others manage 60.',
    "The thinner the purse, the more a delivery is worth: the rigger's counts double, the hauler's triple.",
  ],
  namesHeading: 'Freighter & crew',
  vesselPrompt: 'Name your freighter:',
  vesselLabel: "Freighter's name",
  leaderPrompt: 'Your name, Captain:',
  leaderLabel: "Captain's name",
  crewPrompt: 'Your four crew members:',
  crewLabel: 'Crew member',
  monthHeading: 'When will you launch?',
  monthIntro: 'The 2087 window opens in August and closes in December. Gateway has a launch slot on the 7th of every month in it, and the yard wants an answer. When will you go?',
  monthAdvice: "The yard boss looks up from her slate, which she almost never does. “August is calm, but the planets are badly placed and it's a long haul. December is just as long, and the Sun will hurl storms at you all the way. October is the window: the shortest arc there is this time round. September or November if you have to.”",
  outfitHeading: 'Fitting out',
  outfitIntro: (v) => `You have [amber]$${formatNumber(v.state.money)}[/amber] to fit out the [i]${escape(v.state.ship)}[/i]. The chandlery at Gateway Yard has what you need:`,
  outfitBullets: [
    '• [b]Propellant[/b] — a tonne a day at cruise. The tanks hold 100 tonnes; Gateway to the [i]Perpetua[/i] is 155 million km, about 42 days at cruise. Fill up again there and at Midway, where it is cheapest.',
    '• [b]Rations[/b] — five people on full rations eat 4 kg a day.',
    '• [b]Water[/b] — the recycler loses 2 litres a head a day, 10 a day for five of you. The tanks hold 800 litres.',
    '• [b]Supplement packs[/b] — a pack lasts one person 50 days. A month without, and bones start to thin.',
    '• [b]Thermal suits[/b] — one each. The heat runs off the same power as the drive.',
    '• [b]Array panels & hull patches[/b] — the only repairs you can make between stations.',
    '• [b]Medical kits & tether cartridges[/b] — a cartridge fires the grapple 20 times, at ice in the two comet streams.',
  ],
  enterShop: 'Enter the chandlery',
  rankLegend: 'Master of Transfer 8,000+ · Deep-space Hand 5,000+ · Orbit Hand 2,500+ · Groundling',
};

/**
 * The ship's plight, for the status box (docs/journeys/mars.md, D14): the array dark, the
 * tanks dry, or less propellant than a day at this burn takes, which drives only part of
 * one. Nothing before she leaves Gateway. The hull needs no row: at 0% the run is over.
 */
export function trouble(v) {
  const g = v.state, m = v.hooks.mars;
  if (!(g.day > 0)) return null;
  const dark = m.dark, dry = g.fuel <= 0;
  const coasting = g.atPort ? '' : ', coasting';
  if (dark) return dry ? 'Array dark, tanks dry' : `Array dark${coasting}`;
  if (dry) return `Tanks dry${coasting}`;
  return m.lastOfThePropellant ? 'Last of the propellant' : null;
}

/** After the thrust setting, why it makes no way: under way she is coasting; docked, she will be once she undocks. */
export function coast(g, dark, dry) {
  if (!(dark || dry)) return '';
  const why = dark ? 'The array is dark' : 'The tanks are dry';
  return g.atPort ? ` [red]${why}: once she undocks, she will only coast.[/red]` : ` [red]${why}: she is only coasting.[/red]`;
}

/**
 * The contract row: days in hand, as the engine pays for them (one in hand at day 169), and
 * late from the day its own message says the date has passed.
 */
export function contract(g) {
  const left = contractDays - g.day;
  return left > 0 ? `${days(left)} in hand` : left === 0 ? 'late' : `${days(-left)} late`;
}

/** What things are called aboard, worked out for the voyage in hand. */
export function words(J, v) {
  const g = v.state, m = v.hooks.mars;
  const pace = J.paces.find((p) => p.pace === g.pace);
  const rations = J.rations.find((r) => r.rations === g.rations);
  const n = g.crew.filter((p) => p.alive).length;
  const home = J.stops[0]?.name ?? '';
  const title = J.roles.find((r) => r.role === g.role).title;
  const article = title.length > 0 && 'aeiou'.includes(title[0]) ? 'an' : 'a';
  const gone = g.day > 0;
  const dark = m.dark && gone, dry = g.fuel <= 0 && gone;
  const stop = J.stops[g.stopIndex];
  const docked = g.atPort && J.ports.some((p) => p.id === stop.id);
  const left = contractDays - g.day;
  const plight = trouble(v);
  return {
    setOut: 'Burn for Mars',
    halt: 'Cut the drive & take stock',
    carryOn: 'Continue the transfer',
    supplies: 'Check supplies & crew',
    chart: 'Look at the plot',
    changePace: 'Change thrust',
    changeRations: 'Change rations',
    rest: 'Idle the drive and rest',
    repairs: 'Make repairs',
    forage: 'Work the grapple',
    leavePort: 'Undock and burn on',
    restInPort: 'Rest aboard the station',
    trade: 'Trade along the docking ring',
    talk: 'Talk to people',
    buy: 'Buy supplies',
    yard: 'Visit the yard crew',
    yardQuestion: null,
    place: !docked ? null : stop.id === 'cycler' ? 'Aboard the Perpetua' : `Docked at ${stop.short}`,
    stopName: (s) => s.short,
    statusNames: {},
    travelled: 'Flown',
    distanceUnit: 'million km',
    distance: (mile) => millions(mile),
    meters: ['Hull', 'Power & drive'],
    clock: { label: 'Contract', value: contract(g) },
    trouble: plight === null ? null : { label: 'Ship', value: plight },
    cash: 'Cash',
    currency: '$',
    storeNames: {},
    looseUnits: { tackle: 'shots' },
    looseOne: { tackle: 'shot' },
    fractional: ['limes'],
    singular: true,
    lots: [],
    // While the purse runs to a step of propellant: past that, holding her would hold her
    // for good, and she leaves dry (D18, D19).
    departRefusal: g.fuel <= 0 && m.gatewaySells.fuel
      ? "Gateway's traffic office won't clear a ship to leave the yard with her tanks empty. The quartermaster points you back at the propellant."
      : null,
    departWarning: null,
    resumesInFirstShop: true,
    leaveRefusal: null,
    vesselHeading: `The ${g.ship}`,
    suppliesNote: `Thrust: ${pace.name} · Rations: ${rations.name}`
      + (g.noCitrus > Math.trunc(J.rules.deficiencyAfter / 2) ? ` · [red]${days(g.noCitrus)} without supplements[/red]` : '')
      + (dark ? ' · [red]the array is dark[/red]' : '')
      + (dry ? ' · [red]the tanks are dry[/red]' : ''),
    crewHeading: `Crew · health ${v.healthLabel}`,
    leaderTag: 'captain',
    clothesWarning: g.clothes < n ? `[red]Only ${g.clothes} of ${n} aboard have a thermal suit.[/red]` : null,
    lostHeading: 'Lost on the transfer',
    paceHeading: 'Thrust',
    paceNow: `The drive is set for [amber]${pace.name}[/amber].` + coast(g, dark, dry),
    rationsHeading: 'Rations',
    rationsNow: `The crew is on [amber]${rations.name}[/amber]. With ${n} aboard, that's ${tenth(n * rations.amount)} kg a day.`,
    restPrompt: g.atPort
      ? 'The station has bunks with curtains and a shower that runs for whole minutes. How long will you stay?'
      : 'You idle the drive, and the crew sleeps in shifts with the cabin lights down. How long will you rest?',
    restChoice: (turns) => days(turns),
    repairsHeading: 'Repairs',
    repairsNote: 'Each repair takes a day.' + (g.role === 'shipwright' ? ' As a yard rigger, your repairs go much further.' : ''),
    mend: `Fit a spare array panel — 1 panel [dim](have ${g.sailcloth})[/dim]`,
    patch: `Patch the pressure hull — 1 patch [dim](have ${g.timber})[/dim]`,
    yardHeading: 'The yard crew',
    yardIntro: `You have [amber]$${formatNumber(g.money)}[/amber]. Each job takes a day.`,
    yardHull: (cost) => `Reseal the pressure hull — $${formatNumber(cost)}`,
    yardSails: (cost) => `New panels and a rebuilt thruster grid — $${formatNumber(cost)}`,
    leaveYard: 'Back to the station',
    priceNote: (p) => (p >= 0
      ? `Prices here run about ${p}% above ${home}'s, give or take what is scarce.`
      : `Prices here run about ${-p}% below ${home}'s, give or take what is scarce.`),
    /** `name` arrives escaped for markup. */
    burial: (name) => `The crew gathers at the lock for ${name}. What words will you say?`,
    commit: 'Say a few words',
    gameOverLine: `${v.dateText} · ${km(g.mile)} out from ${home}.`,
    arrival: `Jezero Landing! The [i]${escape(g.ship)}[/i] sets her cargo down on ${v.dateText}, ${days(g.day)} out of ${home}.`,
    arrivalBody: (left > 0
      ? `The contract allowed 170 days, and you have ${days(left)} in hand. The settlement turns out in suits to watch the crates come down the ramp, and somebody has painted a banner, slightly misspelled. `
      : 'The contract date is behind you, and so is the bonus. The settlement turns out in suits all the same, and nobody mentions the date. ')
      + (n > 1 ? 'Your crew is asking where a person gets a hot shower that lasts more than four minutes.'
        : 'You walk down the ramp alone, and stand a while under a sky the colour of weak tea.'),
    bonus: `Bonus for being ${article} ${title}`,
    again: 'Take another charter',
    thanks: 'Thanks for hauling.',
  };
}

/**
 * For tests and screenshots: a well-stocked freighter ten units short of `J.stops[stop]`, on
 * the menu under way, launched in `month` if she can launch then and in October if not.
 * `s` is a fresh transfer's state (from `start`), changed in place as the app's
 * `debug.start` builds its own.
 */
export function debugStart(J, s, stop, month = s.startMonth) {
  // October unless the month asked for is one she can launch in.
  const d = J.departures.find((x) => x.month === month) ?? { year: 2087, month: 9 };
  s.startYear = d.year;
  s.startMonth = d.month;
  s.stopIndex = stop - 1;
  s.mile = J.stops[stop].mile - 10;
  s.day = Math.max(1, Math.trunc(s.mile / 330));
  Object.assign(s, { fuel: 600, water: 400, food: 300, limes: 6, meds: 3, clothes: 5, sailcloth: 3, timber: 3,
    tackle: 60, hull: 72, sails: 64, money: 400, atPort: false });
  return s;
}

/** Under way at `mile`, past the stops behind it, with propellant aboard. */
export function fly(J, s, mile) {
  s.mile = mile;
  s.stopIndex = Math.max(0, J.stops.findLastIndex((st) => st.mile < mile));
  s.day = Math.max(1, Math.trunc(mile / 330));
  s.fuel = 600;
}

/** Standing at a stop, its arrival told: docked, if it is a station and `port` says so. */
export function at(J, s, stopId, port = false) {
  const i = J.stops.findIndex((st) => st.id === stopId);
  if (!J.stops[i]) return;
  s.stopIndex = i;
  s.mile = J.stops[i].mile;
  s.day = Math.max(1, Math.trunc(s.mile / 330));
  if (s.fuel <= 0) s.fuel = 600;
  s.atPort = port;
}

/** How she was caught at Mars, as the engine keys it (`MarsScene.captureKey`). */
const caught = (s, how) => { s.vars = { ...s.vars, [scene.captureKey]: how }; };

/** The JourneySkin for the Long Transfer, given its tables from the engine. */
export function skin(J) {
  const here = (stopId, port = false) => (s) => at(J, s, stopId, port);
  const flying = (mile) => (s) => fly(J, s, mile);
  return {
    id,
    card,
    words: (v) => words(J, v),
    scene: { draw: (px, f) => scene.draw(J, px, f), label: (f) => scene.label(J, f) },
    chart: chart(J),
    forage: forage(J),
    debug: {
      start: (s, stop, month) => debugStart(J, s, stop, month),
      gallery: [
        { name: 'Gateway Yard', moving: false, set: (s) => { s.atPort = true; } },
        { name: 'Lunar distance', moving: false, set: here('lunar') },
        { name: "Earth's reach", moving: false, set: here('hill') },
        { name: 'The Perpetua, docked', moving: false, set: here('cycler', true) },
        { name: 'The Perpetua, passing', moving: false, set: here('cycler') },
        { name: 'Turnover', moving: false, set: here('turnover') },
        { name: 'Midway Depot', moving: false, set: here('midway', true) },
        { name: 'Conjunction shadow', moving: false, set: here('shadow') },
        { name: 'Mars approach', moving: false, set: here('approach') },
        { name: 'Phobos Yard', moving: false, set: here('phobos', true) },
        { name: 'Jezero Landing', moving: false, set: (s) => { at(J, s, 'jezero'); s.atPort = true; } },
        { name: 'Cislunar space', moving: true, set: flying(120) },
        { name: 'Departure leg', moving: true, set: flying(1500) },
        { name: 'First ice stream', moving: true, set: flying(9500) },
        { name: 'Inner arc', moving: true, set: flying(20000) },
        { name: 'Deep space, braking', moving: true, set: flying(30500) },
        { name: 'Second ice stream', moving: true, set: flying(35500) },
        { name: 'Shadow', moving: true, set: flying(39000) },
        { name: 'Approach', moving: true, set: flying(44000) },
        { name: 'Aerobraking', moving: true, set: (s) => { fly(J, s, 46800); caught(s, 1); } },
        { name: 'Burning into orbit', moving: true, set: (s) => { fly(J, s, 46800); caught(s, 2); } },
        { name: 'Hard burn', moving: true, set: (s) => { fly(J, s, 20000); s.pace = 'full'; } },
        { name: 'Array dark', moving: true, set: (s) => { fly(J, s, 30500); s.sails = 0; } },
        { name: 'Tanks dry, tumbling', moving: true, set: (s) => { fly(J, s, 20000); s.fuel = 0; } },
        { name: 'Power 15%', moving: true, set: (s) => { fly(J, s, 20000); s.sails = 15; } },
        { name: 'Hull 15%', moving: true, set: (s) => { fly(J, s, 20000); s.hull = 15; } },
        { name: 'The hull lets go', moving: false, set: (s) => { fly(J, s, 20000); s.hull = 0; s.over = true; } },
        { name: 'Lost aerobraking', moving: false, set: (s) => { fly(J, s, 46800); caught(s, 1); s.hull = 0; s.over = true; } },
      ],
    },
  };
}
