// The Iron Road, 1869: everything the shell says and draws for it
// (AroundTheHorn/Journeys/RailSkin.swift). The engine counts in turns of four hours and
// calls its two meters `sails` and `hull`; here they are days and hours, the engine and
// the running gear. The words are the app's, line for line; the art is in the files
// beside this one.
//
// `skin(J)` dresses the journey `J` (its tables, from the engine's `journeys()`). Every
// function of the voyage takes the bridge's view `v`: `v.state` is the GameState, and the
// rest is what the app reads off it (`v.dateText`, `v.healthLabel`, `v.region`, …).

import { escape, formatNumber, jsRounded } from '../markup.js';
import * as scene from './rail-scene.js';
import { chart } from './rail-chart.js';
import { forage } from './rail-forage.js';

export const id = 'rail';

/**
 * The freight is due this many turns out of Omaha: the engine's own figure (it pays for
 * every turn in hand), held to it by the tests.
 */
export const contractTurns = 72;

/** Turns to the day. */
export function perDay(J) {
  return Math.max(1, Math.trunc(24 / Math.max(1, J.rules.tickHours)));
}

/** A number of turns as the player reads it: "8 hours", "1 day", "11 days and 4 hours". */
export function span(J, turns) {
  const n = perDay(J);
  const d = Math.trunc(turns / n), h = (turns % n) * J.rules.tickHours;
  const days = `${d} day${d === 1 ? '' : 's'}`;
  if (d === 0) return `${h} hours`;
  return h === 0 ? days : `${days} and ${h} hours`;
}

export const card = {
  banner: 'THE IRON ROAD · 1869',
  title: 'THE IRON\nROAD',
  year: '~ 1869 ~',
  tagline: 'Seventeen hundred miles of new track from Omaha to Sacramento, and a freight due in twelve days.',
  start: 'Take the contract',
  /** `vessel` arrives escaped for markup. */
  resume: (vessel) => `Climb back aboard the [i]${vessel}[/i]`,
  learn: 'Learn about the road',
  learnPages: [
    {
      heading: 'The road',
      paragraphs: [
        "In May 1869 two railroads met in the Utah desert, and a crossing that took a wagon most of a year's good weather began to take a train a week or two. It is now possible to cross the continent sitting down.",
        'You are the conductor of a chartered freight: a wood-burning engine, her tender, a tank car, two boxcars and a caboose, with a crew of five counting yourself. The freight is due in Sacramento, 1,776 miles off, in twelve days. After sixteen the contract is torn up.',
      ],
    },
    {
      heading: 'Wood and water',
      paragraphs: [
        '[amber]Firewood[/amber] is what the engine eats: about a cord every four hours at timetable speed. The tender holds sixteen cords. Wood is cheap in Omaha, cheaper under the Sierra, and painful everywhere between.',
        'Where the line follows a river, driftwood can be hauled out with a [amber]grapnel line[/amber]. It costs four hours and a few casts.',
        'Trackside tanks keep the boiler full for nothing, except in the three deserts. There it drinks from your [amber]tank car[/amber], 80 gallons or more every four hours. Run dry and the engine crawls, and scorches her flues doing it.',
      ],
    },
    {
      heading: 'The hills and the calendar',
      paragraphs: [
        'Two long grades stand in the way: [amber]Sherman Hill[/amber] past Cheyenne, and the east slope of the [amber]Sierra[/amber] past Reno. A helper engine waits at the foot of each, for a fee. Without one you climb at about half speed.',
        'From Donner Summit the road runs downhill, and the brakes do the work. Come down slow, or find out how fast a freight train can go.',
        'The season matters. The deserts are hot in summer and the mountains fill with snow in winter. The engine and the running gear wear with every mile: carry [amber]boiler fittings[/amber] and [amber]car spares[/amber], or pay a roundhouse.',
      ],
    },
  ],
  roleHeading: 'Who are you?',
  roleIntro: 'Three kinds of people chartered a freight west in 1869. Pick yours:',
  differencesAction: 'How do they compare?',
  differencesHeading: 'How they compare',
  differences: [
    "A chartered train was a rich man's gamble or a poor man's last one.",
    '[amber]Freight contractor[/amber] — starts with $1,000.',
    '[amber]Boilermaker[/amber] — starts with $520. Gets far more out of every set of fittings and crate of spares.',
    '[amber]River hand[/amber] — starts with $350. Has a sure arm with a grapnel, and can stack six cords of driftwood at a time where the others manage four.',
    'The poorer you start, the more your arrival is worth: the boilermaker scores double, the river hand triple.',
  ],
  namesHeading: 'Train & crew',
  vesselPrompt: 'Name your engine:',
  vesselLabel: "Engine's name",
  leaderPrompt: 'Your name, Conductor:',
  leaderLabel: "Conductor's name",
  crewPrompt: 'Your four crew members:',
  crewLabel: 'Crew member',
  monthHeading: 'When will you leave?',
  monthIntro: 'The last spike went in at Promontory in May 1869, and the road is open from end to end. The freight is loaded and the consignee is counting days. When will you pull out of Omaha?',
  monthAdvice: 'The yardmaster looks at the sky, then at you. “Go in summer and the deserts will cook you while the boiler drinks your tank car dry. Go in winter and the Sierra will bury you: December and January are the worst of it. October. It is the one month this road is polite.”',
  outfitHeading: 'Outfitting',
  outfitIntro: (v) => `You have [amber]$${formatNumber(v.state.money)}[/amber] to stock the [i]${escape(v.state.ship)}[/i]. The outfitter by the Omaha yard has what you need:`,
  outfitBullets: [
    '• [b]Firewood[/b] — about a cord every four hours at timetable speed. The tender holds 16 cords, and wood costs more at every yard short of Reno.',
    '• [b]Tank water[/b] — for the three deserts, where the boiler drinks 80 gallons or more every four hours. The car holds 1,200 gallons.',
    '• [b]Provisions[/b] — five people eating well use 15 lbs a day. The run should take about twelve.',
    '• [b]Wool blankets[/b] — one apiece, or the mountain nights will find you.',
    '• [b]Boiler fittings & car spares[/b] — the only way to make repairs between yards.',
    '• [b]Medicine kits & grapnel line[/b] — a coil is good for 20 casts at driftwood.',
  ],
  enterShop: 'Enter the store',
  rankLegend: 'Superintendent of the Line 7,000+ · Master Conductor 4,000+ · Brakeman 2,000+ · Section Hand',
};

/**
 * The train's plight, for the status box: given out (the engine's rule, `Rail.brokenDown`:
 * a meter showing 0%), no wood, or less than the pace burns in a turn (`burn`), which runs
 * partly on fence posts.
 */
export function trouble(g, burn) {
  const broken = jsRounded(g.sails) <= 0 || jsRounded(g.hull) <= 0, dry = g.fuel <= 0;
  if (broken) return dry ? 'Broken down, no wood' : 'Broken down';
  return dry ? 'Out of wood' : g.fuel < burn ? 'Last of the wood' : null;
}

/** What things are called on the road, worked out for the voyage in hand. */
export function words(J, v) {
  const g = v.state;
  const pace = J.paces.find((p) => p.pace === g.pace);
  const rations = J.rations.find((r) => r.rations === g.rations);
  const role = J.roles.find((r) => r.role === g.role);
  const n = g.crew.filter((p) => p.alive).length;
  const left = contractTurns - g.day;
  // A turn's ration for everyone, over a day's turns, to a tenth of a pound.
  const daily = Math.round(n * rations.amount * perDay(J) * 10) / 10;
  const home = J.stops[0]?.name ?? '';
  const sp = (turns) => span(J, turns);
  return {
    setOut: 'Whistle off',
    halt: 'Stop the train & take stock',
    carryOn: 'Continue down the line',
    supplies: 'Check supplies & crew',
    chart: 'Look at the map',
    changePace: 'Change pace',
    changeRations: 'Change rations',
    rest: 'Stop and rest',
    repairs: 'Make repairs',
    forage: 'Haul driftwood',
    leavePort: 'Whistle off and roll on',
    restInPort: 'Lay over in the yard',
    trade: 'Look for a swap',
    talk: 'Talk to people',
    buy: 'Buy supplies',
    yard: 'Visit the roundhouse',
    statusNames: { water: 'Tank car' },
    travelled: 'Covered',
    distanceUnit: 'miles',
    distance: (m) => formatNumber(m),
    meters: ['Running gear', 'Engine'],
    // Late from the turn the engine calls it late, as the note and the score have it.
    clock: { label: 'Contract', value: left > 0 ? `${sp(left)} left` : left === 0 ? 'late' : `${sp(-left)} late` },
    trouble: trouble(g, pace.fuel) === null ? null : { label: 'Train', value: trouble(g, pace.fuel) },
    cash: 'Cash',
    currency: '$',
    storeNames: { clothes: 'Blankets' },
    looseUnits: { tackle: 'casts' },
    fractional: [],
    singular: true,
    lots: ['water'],
    vesselHeading: `The ${g.ship}`,
    suppliesNote: `Pace: ${pace.name} · Rations: ${rations.name} · `
      + (left > 0 ? `${sp(left)} left on the contract` : '[red]the freight is late[/red]'),
    crewHeading: `Crew · health ${v.healthLabel}`,
    leaderTag: 'conductor',
    clothesWarning: g.clothes < n ? `[red]Only ${g.clothes} of ${n} have a blanket.[/red]` : null,
    lostHeading: 'Lost on the road',
    paceHeading: 'Pace',
    paceNow: `The pace is currently [amber]${pace.name}[/amber].`,
    rationsHeading: 'Rations',
    rationsNow: `Rations are currently [amber]${rations.name}[/amber]. With ${n} aboard, that's ${formatNumber(daily)} lbs a day.`,
    restPrompt: g.atPort ? 'The crew can sleep in beds that stand still and eat at a table. How long will you lay over?'
      : 'You set the brakes and the crew sleeps where it falls. How long will you stop?',
    restChoice: (turns) => sp(turns),
    repairsHeading: 'Repairs',
    repairsNote: 'Each repair takes four hours.' + (g.role === 'shipwright' ? ' As a boilermaker, your repairs go much further.' : ''),
    mend: `Work on the engine — 1 set of boiler fittings [dim](have ${g.sailcloth})[/dim]`,
    patch: `Mend the running gear — 1 crate of car spares [dim](have ${g.timber})[/dim]`,
    yardHeading: 'Roundhouse',
    yardIntro: `You have [amber]$${formatNumber(g.money)}[/amber]. Each job takes four hours.`,
    yardHull: (cost) => `Send the cars through the car shop — $${cost}`,
    yardSails: (cost) => `Have the engine overhauled — $${cost}`,
    leaveYard: 'Leave the roundhouse',
    priceNote: (percent) => `Prices here run about ${percent}% above ${home}, give or take what the country grows.`,
    /** `name` arrives escaped for markup. */
    burial: (name) => `The crew digs a grave on a rise beside the track and marks it with a board from a crate, for ${name}. What words will you say?`,
    commit: 'Lay to rest',
    gameOverLine: `${v.dateText} · ${formatNumber(g.mile)} miles out of ${home}.`,
    arrival: `Sacramento! The [i]${escape(g.ship)}[/i] rolls into the yard by the river on ${v.dateText}, ${sp(g.day)} out of ${home}.`,
    // On time as the engine pays it: a turn in hand. At twelve days to the hour its own
    // message has already called the freight late.
    arrivalBody: (left > 0
      ? 'The consignee is on the platform with a watch in his hand, and puts it away looking faintly let down. The freight is on time. '
      : 'The consignee is on the platform with a watch in his hand and a good deal to say about the date. He signs for the freight anyway. ')
      + (n > 1 ? 'Your crew is asking where a person gets a bath and a beefsteak.'
        : 'You climb down alone and stand a while on ground that does not move.'),
    bonus: `Bonus for being a ${role.title}`,
    again: 'Run it again',
    thanks: 'Thanks for riding.',
  };
}

/**
 * For tests and screenshots: a well-stocked train ten miles short of `J.stops[stop]`, on
 * the menu under way, leaving in `month` if a train can leave then and in October if not.
 * `s` is a fresh voyage's state (from `start`), changed in place as the app's
 * `debug.start` builds its own.
 */
export function debugStart(J, s, stop, month = s.startMonth) {
  const d = J.departures.find((x) => x.month === month) ?? { year: 1869, month: 9 };
  s.startYear = d.year;
  s.startMonth = d.month;
  s.stopIndex = stop - 1;
  s.mile = J.stops[stop].mile - 10;
  s.day = Math.trunc(s.mile / 42);
  Object.assign(s, { fuel: 120, water: 900, food: 250, meds: 3, clothes: 5, sailcloth: 3, timber: 3, tackle: 60,
    hull: 72, sails: 64, money: 400, atPort: false });
  return s;
}

/** The JourneySkin for the Iron Road, given its tables from the engine. */
export function skin(J) {
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
        { name: 'Night', moving: true, set: (s) => { s.day = 4; } },
        { name: 'In the yard', moving: false, set: (s) => { s.atPort = true; } },
        { name: 'Dale Creek', moving: true, set: (s) => { s.mile = 550; } },
        { name: 'Red Desert', moving: true, set: (s) => { s.mile = 780; } },
        { name: 'The Wasatch', moving: true, set: (s) => { s.mile = 950; } },
        { name: 'Salt Desert', moving: true, set: (s) => { s.mile = 1150; } },
        { name: 'The Humboldt', moving: true, set: (s) => { s.mile = 1400; } },
        { name: 'Snowsheds', moving: true, set: (s) => { s.mile = 1700; } },
        { name: 'Sacramento Valley', moving: true, set: (s) => { s.mile = 1760; } },
        { name: 'Engine 10%', moving: true, set: (s) => { s.sails = 10; } },
        { name: 'Running gear 10%', moving: true, set: (s) => { s.hull = 10; } },
      ],
    },
  };
}
