// To the Klondike, 1898: everything the shell says and draws for it
// (AroundTheHorn/Journeys/KlondikeSkin.swift). A turn is a day and distances are stored in
// tenths of a mile, written "1,136.5". The engine calls its two meters `hull` and `sails`:
// the outfit and its sleds until a boat is built at Lake Bennett, then the boat and its oars
// & sail. `water` is firewood, `sailcloth` rope & rawhide, `timber` canvas & pitch, `limes`
// lime juice and `tackle` hooks, counted in casts. The words are the app's, line for line;
// the art is in the files beside this one.
//
// `skin(J)` dresses the journey `J` (its tables, from the engine's `journeys()`). Every
// function of the voyage takes the bridge's view `v`: `v.state` is the GameState, and the
// rest is what the app reads off it (`v.dateText`, `v.healthLabel`, `v.region`, the town the
// engine finds for the way taken, `v.port`), with what it asks the engine (`Klondike.legName`,
// `hasBoat`, `givenOut`, `noFire`, `meterNames`, `shortName`, `shortOfGrubWarning`,
// `finale`, `burialText`) in `v.hooks.klondike`, and `Journey.departsUnfed` in
// `v.hooks.departsUnfed`.

import { formatNumber } from '../markup.js';
import * as scene from './klondike-scene.js';
import { chart } from './klondike-chart.js';
import { forage } from './klondike-forage.js';

export const id = 'klondike';

// MARK: What the engine keeps in `vars`

/** The engine's own keys (held to `KlondikeData` by `KlondikeSkinTests`). */
export const routeKey = 'klondike.route', boatKey = 'klondike.boat', breakupKey = 'klondike.breakup';
export const chilkoot = 1.0, whitePass = 2.0;
/** What `boatKey` holds for a raft: the fourth way of getting a boat. */
export const raft = 4.0;

/** Stored distance units in a mile (`Klondike.unitsPerMile`). */
export const unitsPerMile = 10;

export const onWhitePass = (g) => g.vars?.[routeKey] === whitePass;
/** The pass chosen, or null before the fork. */
export const pass = (g) => g.vars?.[routeKey] ?? null;

/** "1,136.5", from tenths (`Klondike.mileNumber`). */
export function mileNumber(tenths) {
  const t = Math.max(0, tenths);
  return `${formatNumber(Math.trunc(t / unitsPerMile))}.${t % unitsPerMile}`;
}

/** "1,136.5 miles", from tenths (`Klondike.miles`). */
export const miles = (tenths) => `${mileNumber(tenths)} miles`;

/**
 * The state's date, `[year, month from 0, day]`, as GameState works it out: the journey's
 * first day of the start month, and a turn's worth of time for each day gone. The views
 * carry it (`v.date`); this is for a state of the skin's own, before the engine has seen it.
 */
export function dateOf(J, g) {
  const r = J.rules;
  const start = Date.UTC(g.startYear, g.startMonth, r.startDay);
  const hours = r.tickHours === 24 && r.startHour === 0 ? g.day * 24 : r.startHour + g.day * r.tickHours;
  const d = new Date(start + hours * 3600 * 1000);
  return [d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate()];
}

/** Day of 1898, January 1 being 0, as the engine counts it for the ice and the crowd. */
export function dayOfYear([year, month, day]) {
  const before = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];
  return (year - 1898) * 365 + before[month] + day - 1;
}

/** May 28, when the ice goes out if nobody has yet seen Bennett to roll for it. */
export const usualBreakup = 147;

/** Whether the ice on Lake Bennett has gone out, on `date` (the state's). */
export function iceOut(g, date) {
  return dayOfYear(date) >= Math.trunc(g.vars?.[breakupKey] ?? usualBreakup);
}

export const days = (n) => `${n} ${n === 1 ? 'day' : 'days'}`;

// MARK: Title card

export const card = {
  banner: 'TO THE KLONDIKE · 1898',
  title: 'TO THE\nKLONDIKE',
  year: '~ 1898 ~',
  tagline: 'Seventeen hundred miles from Seattle to the gold fields of the Yukon — by steamer, on foot, and by boat.',
  start: 'Head for the Klondike',
  /** `vessel` arrives escaped for markup. */
  resume: (vessel) => `Continue the journey of the [i]${vessel}[/i]`,
  learn: 'Learn about the trail',
  learnPages: [
    {
      heading: 'The rush',
      paragraphs: [
        'In July 1897 a steamer tied up in Seattle with a ton of gold aboard, and by winter the whole country had the fever. The gold was on the Klondike River in Canada\'s Yukon, seventeen hundred miles north — up the coast by steamer, over the mountains on foot, and down the Yukon River by boat.',
        'You lead a party of five. Buy a year\'s outfit, get it over the pass, build a boat, and bring everyone to Dawson City alive.',
        'Time passes a day at a time. The steamer is quick; the thirty-three miles of trail are not, because everything you own goes up them a load at a time.',
      ],
    },
    {
      heading: 'The outfit',
      paragraphs: [
        '[amber]Provisions[/amber]: the police at the summit turn back anyone without a year\'s grub — 1,095 lbs a head. Bring more than that; you\'ll eat on the way up.',
        '[amber]Firewood[/amber] keeps you alive on top of the pass, where nothing grows. Below the trees you can gather your own. A day without a fire costs every one of you 12 health.',
        '[amber]Lime juice[/amber] holds off scurvy. [amber]Furs[/amber] — one set each — hold off the cold.',
        '[amber]Canvas & pitch[/amber] and [amber]rope & rawhide[/amber] patch your outfit on the trail and your boat on the river, and you\'ll need some to build the boat. [amber]Hooks & line[/amber] catch fish on the lakes and river.',
        'Sleds worn down to 0% give out, and nobody moves until they are mended: with a coil of rope & rawhide, with a coil bought off the next party along for $24, or with two days\' work making do. An outfit that ever shows 0% is ruined, and the trek is over.',
      ],
    },
    {
      heading: 'Pass, lakes, river',
      paragraphs: [
        'At the head of Lynn Canal choose your pass: the steep [amber]Chilkoot[/amber] or the gentler, slower [amber]White Pass[/amber]. Either way, you carry everything up a load at a time.',
        'At [amber]Lake Bennett[/amber] you build a boat and wait for the ice to go out, at the end of May. Then it\'s nearly five hundred and fifty miles of lakes, canyon and rapids to Dawson.',
        'Oars & sail at 0% leave the boat tied to the bank until they are re-rigged, and nobody takes a boat into Miles Canyon or through Five Fingers without a sweep. A boat that shows 0% breaks up.',
        'Leave too early and the pass will freeze you; too late and the snow turns to slush and slides, and the crowd beats you to Dawson. Every day you get there before August 1 is worth 20 points. Hard driving gets you there sooner, if it gets you there at all.',
      ],
    },
  ],
  roleHeading: 'Who are you?',
  roleIntro: 'In 1898 the fever took clerks and cooks, preachers and prospectors. Choose who you will be:',
  differencesAction: 'What does each one bring north?',
  differencesHeading: 'What each one brings north',
  differences: [
    'A Klondike outfit cost more than most people earned in a year.',
    '[amber]Storekeeper[/amber] — starts with $1,700.',
    '[amber]Boatbuilder[/amber] — starts with $1,000. Gets far more out of every bundle of canvas and coil of rope, and builds a better boat in less time.',
    '[amber]Miner[/amber] — starts with $720. A strong back: moves an outfit over the pass faster than anyone.',
    'The poorer you start, the more your arrival is worth: the boatbuilder scores double, the miner triple.',
  ],
  namesHeading: 'Boat & party',
  vesselPrompt: 'Name the boat you\'ll build at the lakes:',
  vesselLabel: 'Boat\'s name',
  leaderPrompt: 'Your name:',
  leaderLabel: 'Your name',
  crewPrompt: 'Your four partners:',
  crewLabel: 'Partner',
  monthHeading: 'When will you go?',
  monthIntro: 'The news reached Seattle last July. All winter the steamers have gone north crammed to the rails. When will you go?',
  monthAdvice: 'An old sourdough taps his pipe on the stove: “Go in January and the pass will freeze you solid. Go in May and you\'ll wade through slush under the snowslides, and every creek in the Klondike will be staked twice over before you get there. March is the month. February, if your purse can stand a cold trail. Be at the lakes when the ice goes out.”',
  outfitHeading: 'Outfitting',
  outfitIntro: (v) => `You have [amber]$${formatNumber(v.state.money)}[/amber] to outfit your party. The outfitters on First Avenue will sell you anything, and they all tell you the same things:`,
  outfitBullets: [
    '• [b]Provisions[/b] — the police won\'t let anyone over the summit without a year\'s grub: 1,095 lbs a head. Then you have to eat on the way.',
    '• [b]Firewood[/b] — nothing grows on top of the pass, and in the cold up there five of you burn 40 lbs of it a day.',
    '• [b]Lime juice[/b] — beans and bacon all winter bring on scurvy.',
    '• [b]Furs & mackinaws[/b] — one set a head, or the summit will take fingers and toes.',
    '• [b]Canvas & pitch, rope & rawhide[/b] — to patch the outfit on the trail, and to build a boat at the lakes.',
    '• [b]A medicine chest and hooks & line[/b].',
  ],
  enterShop: 'Enter the shop',
  rankLegend: 'Sourdough 7,000+ · Old Hand 4,000+ · Stampeder 2,000+ · Cheechako',
};

// MARK: Words

/**
 * The party's plight, for the status box (docs/journeys/klondike.md, D14): sleds or oars
 * given out, no firewood, or both. Nothing before it leaves Seattle; the outfit and the boat
 * need no row, since at 0% the trek is over.
 */
export function trouble(v) {
  const g = v.state, k = v.hooks.klondike;
  if (!(g.day > 0)) return null;
  const out = k.givenOut, cold = k.noFire, boat = k.hasBoat;
  if (out && cold) return boat ? 'Oars given out, no firewood' : 'Sleds given out, no firewood';
  if (out) return boat ? 'Oars & sail given out' : 'Sleds given out';
  if (cold) return 'No firewood';
  return null;
}

/** Where the bridge's burial line (`hooks.klondike.burial`) has the name (`Hooks.burialMark`). */
export const burialMark = '\u0001NAME\u0001';

/**
 * The burial line by where it happens, in the engine's words, with the name as the shell
 * hands it over (already escaped).
 */
export function burial(v, name) {
  return v.hooks.klondike.burial.split(burialMark).join(name);
}

/** What things are called on the trail, worked out for the trek in hand. */
export function words(J, v) {
  const g = v.state, k = v.hooks.klondike;
  const pace = J.paces.find((p) => p.pace === g.pace);
  const rations = J.rations.find((r) => r.rations === g.rations);
  const n = g.crew.filter((p) => p.alive).length;
  const leg = k.leg;
  const boat = k.hasBoat;
  const gone = g.day > 0;
  const givenOut = gone && k.givenOut, cold = gone && k.noFire;
  const title = J.roles.find((r) => r.role === g.role).title;
  const here = J.stops[g.stopIndex];
  const town = g.atPort ? v.port : null;
  const bennett = here.id === 'bennett' && g.atPort;
  const meters = k.meters;
  const home = J.stops[0]?.name ?? '';
  const finale = k.finale;
  const plight = trouble(v);
  const warning = k.shortOfGrubWarning;
  return {
    setOut: 'Steam north',
    halt: 'Stop & take stock',
    carryOn: 'Continue on your journey',
    supplies: 'Check supplies & party',
    chart: 'Look at the map',
    changePace: 'Change pace',
    changeRations: 'Change rations',
    rest: leg === 'steamer' ? 'Rest in your bunk' : 'Make camp and rest',
    repairs: 'Make repairs',
    forage: 'Go fishing',
    leavePort: leg === 'boat' || here.id === 'bennett' ? 'Push off and float on'
      : leg === 'steamer' ? 'Back aboard and steam on' : 'Shoulder your packs and move on',
    restInPort: 'Rest in town',
    trade: 'Look for a trade',
    talk: 'Talk to people',
    buy: 'Buy supplies',
    yard: boat ? 'Visit the boatwrights' : bennett ? 'See about a boat' : "Visit the outfitters' yard",
    // The engine call that asks it (`Klondike.boatChoice`).
    yardQuestion: bennett && !boat ? 'boatChoice' : null,
    place: town?.name ?? null,
    stopName: (s) => {
      const i = J.stops.findIndex((x) => x.id === s.id);
      return k.stops[i]?.short ?? s.short;
    },
    statusNames: {},
    travelled: 'Traveled',
    distanceUnit: 'mi',
    distance: (mile) => mileNumber(mile),
    meters: [meters.structure, meters.drive],
    clock: null,
    trouble: plight === null ? null : { label: 'Party', value: plight },
    cash: 'Cash',
    currency: '$',
    storeNames: { meds: 'Medicine', clothes: 'Furs' },
    looseUnits: { tackle: 'casts' },
    looseOne: { tackle: 'cast' },
    fractional: ['limes'],
    singular: true,
    lots: ['water'],
    departRefusal: null,
    // Less grub than the police will want: a warning, which may be waved off. With none at
    // all the engine's own refusal comes first, while the purse runs to a step of it; with
    // less, the party may go hungry, warned (D21).
    departWarning: (g.food > 0 || v.hooks.departsUnfed) && warning != null
      ? { text: warning, back: 'Back to the shop', go: 'Leave anyway' } : null,
    resumesInFirstShop: true,
    leaveRefusal: null,
    vesselHeading: boat ? `The ${g.ship}` : 'Your outfit',
    suppliesNote: `Pace: ${pace.name} · Rations: ${rations.name}`
      + (g.noCitrus > 20 ? ` · [red]${g.noCitrus} days without lime juice[/red]` : '')
      + (givenOut ? (boat ? ' · [red]the oars & sail have given out[/red]' : ' · [red]the sleds have given out[/red]') : '')
      + (cold ? ' · [red]no firewood[/red]' : ''),
    crewHeading: `Party · health ${v.healthLabel}`,
    leaderTag: 'you',
    clothesWarning: g.clothes < n ? `[red]Only ${g.clothes} of ${n} have furs.[/red]` : null,
    lostHeading: 'Lost on the trail',
    paceHeading: 'Pace',
    paceNow: `The pace is [amber]${pace.name}[/amber].`
      + (leg === 'steamer' ? ' [dim]Aboard the steamer, the captain sets the pace. It will matter on the trail.[/dim]' : '')
      + (givenOut ? (boat ? ' [red]The oars & sail have given out: she stays tied to the bank until they are re-rigged.[/red]'
        : ' [red]The sleds have given out: nobody moves until they are mended.[/red]') : ''),
    rationsHeading: 'Rations',
    rationsNow: `Rations are currently [amber]${rations.name}[/amber]. With ${n} in the party, that's ${formatNumber(n * rations.amount)} lbs a day.`,
    restPrompt: g.atPort ? 'Your party can sleep under a roof, eat a cooked meal and recover. How many days?'
      : leg === 'steamer' ? 'You keep to your bunk. How many days?'
        : 'You make camp and the party rests. How many days?',
    restChoice: (turns) => days(turns),
    repairsHeading: 'Repairs',
    repairsNote: 'Each repair takes a day.' + (g.role === 'shipwright' ? ' As a boatbuilder, your repairs go much further.' : ''),
    mend: boat ? `Re-rig oars & sail — 1 coil of rope & rawhide [dim](have ${g.sailcloth})[/dim]`
      : `Mend sleds & straps — 1 coil of rope & rawhide [dim](have ${g.sailcloth})[/dim]`,
    patch: boat ? `Patch the hull — 1 bundle of canvas & pitch [dim](have ${g.timber})[/dim]`
      : `Patch the outfit — 1 bundle of canvas & pitch [dim](have ${g.timber})[/dim]`,
    yardHeading: boat ? 'The boatwrights' : "The outfitters' yard",
    yardIntro: `You have [amber]$${formatNumber(g.money)}[/amber]. Each job takes a day.`,
    yardHull: (cost) => (boat ? `Have her hauled out and recaulked — $${formatNumber(cost)}`
      : `Have the outfit re-sacked and re-tarped — $${formatNumber(cost)}`),
    yardSails: (cost) => (boat ? `Have new oars and a sail made — $${formatNumber(cost)}`
      : `Have the sleds and harness made good — $${formatNumber(cost)}`),
    leaveYard: boat ? 'Leave the boatwrights' : 'Leave the yard',
    priceNote: (p) => (p >= 0 ? `Prices here are ${p}% above ${home}, more or less.` : `Prices here are ${-p}% below ${home}, more or less.`),
    /** `name` arrives escaped for markup. */
    burial: (name) => burial(v, name),
    commit: 'Lay them to rest',
    gameOverLine: `${v.dateText} · ${miles(g.mile)} from ${home}.`,
    arrival: finale.title,
    arrivalBody: finale.body,
    bonus: `Bonus for being a ${title}`,
    again: 'Head north again',
    thanks: 'Thanks for coming north.',
  };
}

// MARK: Debug starts and the gallery

/** Days from leaving Seattle to just short of each stop on the coast and the trail, as a March party might take them. */
export const trailDays = [0, 5, 6, 7, 16, 22, 30, 38];
/** The day of 1898 a party might be just short of each stop on the river, the ice gone. */
export const riverDates = { 8: 153, 9: 156, 10: 164, 11: 166, 12: 171 };

/**
 * The app's `fresh(month:)`: a storekeeper's party with its own names and a well-stocked
 * outfit, setting out from Seattle in `month` of 1898. `s` is a fresh trek's state (from
 * `start`), changed in place as the app builds its own.
 */
export function fresh(s, month) {
  s.role = 'merchant';
  s.ship = 'Puget Belle';
  ['Gus', 'Martha', 'Lars', 'Ida', 'Homer'].forEach((name, i) => { if (s.crew[i]) s.crew[i].name = name; });
  s.startYear = 1898;
  s.startMonth = month;
  s.vars = {};
  s.day = 0;
  s.mile = 0;
  s.stopIndex = 0;
  s.over = false;
  Object.assign(s, { food: 6000, water: 600, limes: 8, meds: 3, clothes: 5, sailcloth: 3, timber: 4, tackle: 60,
    hull: 72, sails: 64, money: 400 });
  return s;
}

/**
 * The pass chosen past the fork, a boat past Bennett, and a day that fits: on the coast and
 * the trail as long as a March party takes, on the river after the ice has gone.
 */
export function settle(J, s, toward, white = false) {
  if (s.mile > J.stops[2].mile) s.vars = { ...s.vars, [routeKey]: white ? whitePass : chilkoot };
  const bennett = J.stops[7].mile;
  if (s.mile > bennett) {
    s.vars = { ...s.vars, [boatKey]: 1, [breakupKey]: usualBreakup };
    s.food = Math.min(s.food, 4000);
  }
  const date = riverDates[toward];
  if (date !== undefined) {
    const start = { ...s, day: 0 };
    s.day = Math.max(1, date - dayOfYear(dateOf(J, start)));
  } else {
    s.day = trailDays[Math.min(toward, trailDays.length - 1)];
  }
  if (s.mile > J.stops[5].mile) s.food = Math.min(s.food, 4000);
}

/**
 * For tests and screenshots: a well-stocked party short of `J.stops[stop]` (by half the way
 * from the stop before, at most ten miles), on the menu under way, setting out in `month`
 * if a party can leave then and in March if not.
 */
export function debugStart(J, s, stop, month = s.startMonth) {
  // March unless the month asked for is one a party can leave in.
  const m = J.departures.some((d) => d.month === month) ? month : 2;
  fresh(s, m);
  const here = J.stops[stop], before = J.stops[stop - 1];
  s.stopIndex = stop - 1;
  s.mile = here.mile - Math.min(100, Math.trunc((here.mile - before.mile) / 2));
  settle(J, s, stop);
  s.atPort = false;
  return s;
}

/** Standing at a stop, its arrival told; in town if `port`. On the trail in March, on the river in June. */
export function at(J, s, stopId, port = false, white = false) {
  const i = J.stops.findIndex((st) => st.id === stopId);
  if (i < 0) return;
  fresh(s, 2);
  s.stopIndex = i;
  s.mile = J.stops[i].mile;
  settle(J, s, i, white);
  s.atPort = port;
}

/** Under way at `mile`, past the stops behind it. */
export function go(J, s, mile, white = false) {
  fresh(s, 2);
  s.mile = mile;
  s.stopIndex = Math.max(0, J.stops.findLastIndex((st) => st.mile < mile));
  settle(J, s, s.stopIndex + 1, white);
  s.atPort = false;
}

/** The JourneySkin for the Klondike, given its tables from the engine. */
export function skin(J) {
  const here = (stopId, port = false, white = false) => (s) => at(J, s, stopId, port, white);
  const going = (mile, white = false) => (s) => go(J, s, mile, white);
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
        { name: 'Seattle, the waterfront', moving: false, set: here('seattle', true) },
        { name: 'Leaving Seattle', moving: true, set: going(150) },
        { name: 'Queen Charlotte Sound', moving: true, set: going(3300) },
        { name: 'The British Columbia coast', moving: true, set: going(5200) },
        { name: 'Juneau', moving: false, set: here('juneau', true) },
        { name: 'The Alaska coast', moving: true, set: going(10600) },
        { name: 'The head of Lynn Canal', moving: false, set: here('lynn') },
        { name: 'Dyea', moving: false, set: here('landing', true) },
        { name: 'Skagway', moving: false, set: here('landing', true, true) },
        { name: 'The Taiya valley', moving: true, set: going(11265) },
        { name: 'The Skagway valley', moving: true, set: going(11265, true) },
        { name: 'Sheep Camp', moving: false, set: here('camp', true) },
        { name: 'White Pass City', moving: false, set: here('camp', true, true) },
        { name: 'The Golden Stairs', moving: true, set: going(11356) },
        { name: 'The Chilkoot summit', moving: false, set: here('summit') },
        { name: 'The White Pass summit', moving: false, set: here('summit', false, true) },
        { name: 'Lake Lindeman, frozen', moving: false, set: here('lakes') },
        { name: 'Log Cabin', moving: false, set: here('lakes', false, true) },
        { name: 'Lake Bennett, the ice in', moving: false, set: here('bennett', true) },
        { name: 'Lake Bennett, a boat built', moving: false, set: (s) => {
          at(J, s, 'bennett', true);
          s.vars = { ...s.vars, [boatKey]: 1 };
          s.hull = 100;
          s.sails = 100;
        } },
        { name: 'The upper lakes', moving: true, set: going(12250) },
        { name: 'Tagish Post', moving: false, set: here('tagish') },
        { name: 'Miles Canyon', moving: false, set: here('canyon') },
        { name: 'The Fifty Mile River', moving: true, set: going(12600) },
        { name: 'Lake Laberge', moving: true, set: going(12900) },
        { name: 'Five Finger Rapids', moving: false, set: here('fivefinger') },
        { name: 'Fort Selkirk', moving: false, set: here('selkirk', true) },
        { name: 'The Yukon in July', moving: true, set: (s) => { go(J, s, 16000); s.day += 25; } },
        { name: 'Dawson City', moving: false, set: here('dawson') },
        { name: 'A raft', moving: true, set: (s) => { go(J, s, 13600); s.vars = { ...s.vars, [boatKey]: raft }; } },
        { name: 'Camped on the trail', moving: false, set: going(11280) },
        { name: 'Sleds 15%', moving: true, set: (s) => { go(J, s, 11280); s.sails = 15; } },
        { name: 'Sleds given out', moving: false, set: (s) => { go(J, s, 11280); s.sails = 0; } },
        { name: 'Outfit 20%', moving: true, set: (s) => { go(J, s, 11280); s.hull = 20; } },
        { name: 'No firewood', moving: false, set: (s) => { go(J, s, 11400); s.water = 0; } },
        { name: 'Boat 20%, bailing', moving: true, set: (s) => { go(J, s, 14000); s.hull = 20; } },
        { name: 'Sail 15%', moving: true, set: (s) => { go(J, s, 14000); s.sails = 15; } },
        { name: 'Oars given out, tied up', moving: false, set: (s) => { go(J, s, 14000); s.sails = 0; } },
        { name: 'The outfit ruined', moving: false, set: (s) => { go(J, s, 11300); s.hull = 0; s.over = true; } },
        { name: 'Turned back at the summit', moving: false, set: (s) => { at(J, s, 'summit'); s.over = true; } },
        { name: 'The boat broken up', moving: false, set: (s) => { go(J, s, 14000); s.hull = 0; s.over = true; } },
      ],
    },
  };
}
