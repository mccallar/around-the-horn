// Over the Pole, 1926: everything the shell says and draws for it
// (AroundTheHorn/Journeys/AirshipSkin.swift). The engine counts in four-hour watches and
// calls its two meters `hull` and `sails`; here they are lift and the engines, `timber` is
// water ballast and `sailcloth` engine spares. The words are the app's, line for line; the
// art is in the files beside this one.
//
// `skin(J)` dresses the journey `J` (its tables, from the engine's `journeys()`). Every
// function of the voyage takes the bridge's view `v`: `v.state` is the GameState, and the
// rest is what the app reads off it (`v.dateText`, `v.healthLabel`, `v.region`, …), with
// what it asks the engine (`Airship.goingDown`, `enginesOut`, `finale`) in
// `v.hooks.airship`, and `Journey.firstPortSells` in `v.hooks.firstPortSells`.

import { escape, formatNumber } from '../markup.js';
import * as scene from './airship-scene.js';
import { chart } from './airship-chart.js';
import { forage } from './airship-forage.js';

export const id = 'airship';

/** Watches to the day. */
export function perDay(J) {
  return Math.max(1, Math.trunc(24 / Math.max(1, J.rules.tickHours)));
}

/** "1 watch", "3 watches". */
export const watches = (n) => `${n} ${n === 1 ? 'watch' : 'watches'}`;

/** A rest as the menu offers it: "3 watches", and the whole days a long one makes, "6 watches (1 day)". */
export function span(J, n) {
  const pd = perDay(J);
  if (!(n >= pd && n % pd === 0)) return watches(n);
  const d = n / pd;
  return `${watches(n)} (${d} ${d === 1 ? 'day' : 'days'})`;
}

/** Swift's `x.rounded()`: halves away from zero. */
const rounded = (x) => Math.sign(x) * Math.round(Math.abs(x));

/** A number to a tenth, without a trailing ".0": "1.5", "2". */
export function tenth(x) {
  const r = rounded(x * 10) / 10;
  return r === rounded(r) ? String(Math.trunc(r)) : String(r);
}

export const card = {
  banner: 'OVER THE POLE · 1926',
  title: 'OVER\nTHE POLE',
  year: '~ 1926 ~',
  tagline: 'Nine thousand six hundred kilometres from Rome to Nome, the short way: over the top of the world.',
  start: 'Fly for the Pole',
  /** `vessel` arrives escaped for markup. */
  resume: (vessel) => `Continue the flight of the [i]${vessel}[/i]`,
  learn: 'Learn about the flight',
  learnPages: [
    {
      heading: 'The flight',
      paragraphs: [
        'In the spring of 1926 nobody had crossed the Arctic Ocean by air. An airship could stay up for days and tie up to a mast instead of needing a field, which made her the likeliest thing to try it. She was also a bag of hydrogen with engines hung underneath, which made the trying interesting.',
        'You command a small airship with a crew of five, counting yourself. Fly north from Rome, mast by mast, as far as Kings Bay on Spitsbergen. Then cross the North Pole and 4,300 kilometres of ice with no mast at all, to Nome in Alaska.',
        'Time passes in [amber]watches[/amber] of four hours, six to a day.',
      ],
    },
    {
      heading: 'Petrol, lift and engines',
      paragraphs: [
        '[amber]Petrol[/amber] turns the engines. When the tanks run dry she becomes a free balloon and goes wherever the wind is going, which is seldom where you are, spending gas every watch to hold her height.',
        '[amber]Lift[/amber] keeps her up. Gas seeps away every watch, and snow, ice and storms take more. Drop a bag of [amber]water ballast[/amber] and she rises at once, or top up the gas at a mast. When the lift is gone she starts down, and something heavy must go over the side: ballast, or petrol at a ruinous rate. With neither, she comes down for good.',
        '[amber]Engines[/amber] wear, worst of all at full speed and in foul weather. Fit [amber]engine spares[/amber] aloft, or have the mechanics at a mast overhaul them. Worn to nothing, they stop, and she drifts like a free balloon until they are mended.',
        '[amber]Coffee & cocoa[/amber] keeps the watch awake: two days without it and the crew is asleep on its feet. [amber]Fur flying suits[/amber], one each, keep them alive in the far north. [amber]Pilot balloons[/amber] find kinder winds aloft, and kinder winds save petrol.',
      ],
    },
    {
      heading: 'The Pole',
      paragraphs: [
        'At the North Pole you must choose your height. Climb [amber]above the fog[/amber] into clear, bitter air, where the sun bakes a little gas out of her every watch, or stay [amber]under it[/amber], where in May and June it is warmer, but the fog freezes on everything and hides pressure ridges as tall as houses.',
        'The calendar matters. Leave Rome in April and the Arctic is still iron-cold; leave in July and the summer fog has settled on the ice. May is the month.',
        "Speed matters too. Full speed gets you there sooner, if the petrol lasts. Over the ice, on one tankful, it usually doesn't.",
      ],
    },
  ],
  roleHeading: 'Who are you?',
  roleIntro: 'A flight to the Pole in 1926 took money, nerve or know-how, and seldom all three at once. Which do you bring?',
  differencesAction: 'What does each one bring?',
  differencesHeading: 'What each one brings',
  differences: [
    'An airship burns money by the tonne, and only one of these three has much of it.',
    '[amber]Financier[/amber] — starts with $1,200.',
    '[amber]Airship engineer[/amber] — starts with $580. Gets far more out of every bag of ballast and every box of engine spares.',
    "[amber]Meteorologist[/amber] — starts with $470. Reads the winds aloft like a morning paper: a surer eye with a pilot balloon, and twice the petrol's worth of winds from every session.",
    "The leaner the purse, the more a landing at Nome is worth: the engineer's counts double, the meteorologist's triple.",
  ],
  namesHeading: 'Airship & crew',
  vesselPrompt: 'Name your airship:',
  vesselLabel: "Airship's name",
  leaderPrompt: 'Your name, Captain:',
  leaderLabel: "Captain's name",
  crewPrompt: 'Your four crew members:',
  crewLabel: 'Crew member',
  monthHeading: 'When will you cast off?',
  monthIntro: 'Five mooring masts stand ready between Rome and Spitsbergen, the hydrogen cylinders are stacked at Kings Bay, and the newspapers are running out of patience. When will you leave?',
  monthAdvice: 'The old balloonist on the bench outside the shed knocks out his pipe. “Go in April and the cold up there will freeze your crew to their seats. Go in July and the summer fog will freeze to your envelope instead. Go in May, when the sun never sets up north and the air is clear. June, if you must. Any later and you may be walking home.”',
  outfitHeading: 'Fitting out',
  outfitIntro: (v) => `You have [amber]$${formatNumber(v.state.money)}[/amber] to fit out the [i]${escape(v.state.ship)}[/i]. The stores at the Ciampino works have what you need:`,
  outfitBullets: [
    '• [b]Petrol[/b] — cruising, she burns 250 kg a watch and covers up to 250 km on it in still air, less against the wind. Rome to Pulham is 1,700 km. The tanks hold 8,000 kg, and petrol costs more at every mast north of here.',
    '• [b]Provisions & drinking water[/b] — on full rations, five people eat 1.5 kg and drink 3 litres a watch.',
    '• [b]Coffee & cocoa[/b] — a tin lasts five people ten watches. Two days without it and the crew is asleep on its feet.',
    '• [b]Fur flying suits[/b] — one per person, or the polar cold will kill them.',
    '• [b]Water ballast & engine spares[/b] — the only way to make repairs aloft.',
    '• [b]Medicine & pilot balloons[/b] — a box holds ten balloons, each one a look at the winds aloft.',
  ],
  enterShop: 'Enter the stores',
  rankLegend: 'Commander 7,000+ · Navigator 4,000+ · Rigger 2,000+ · Ballast',
};

/**
 * The airship's plight, for the status box: going down (the engine's own rule), adrift
 * with the engines dead or the tanks dry, or less petrol than a watch burns, which powers
 * only part of one. Nothing before she leaves Rome.
 */
export function trouble(J, v) {
  const g = v.state, a = v.hooks.airship;
  if (!(g.day > 0)) return null;
  if (a.goingDown) return 'Going down';
  const dead = a.enginesOut, dry = g.fuel <= 0;
  const adrift = g.atPort ? '' : ', adrift';
  if (dead) return dry ? 'Engines dead, tanks dry' : `Engines dead${adrift}`;
  if (dry) return `Tanks dry${adrift}`;
  return g.fuel < J.paces.find((p) => p.pace === g.pace).fuel ? 'Last of the petrol' : null;
}

/** What things are called aloft, worked out for the voyage in hand. */
export function words(J, v) {
  const g = v.state, a = v.hooks.airship;
  const pace = J.paces.find((p) => p.pace === g.pace);
  const rations = J.rations.find((r) => r.rations === g.rations);
  const n = g.crew.filter((p) => p.alive).length;
  const home = J.stops[0]?.name ?? '';
  const title = J.roles.find((r) => r.role === g.role).title;
  const article = title.length && 'aeiou'.includes(title[0]) ? 'an' : 'a';
  // The engine's finale: the landing, then the town and who climbs down.
  const finale = a.finale.split('\n\n');
  const dry = g.fuel <= 0 && g.day > 0;
  const dead = a.enginesOut;
  const plight = trouble(J, v);
  return {
    setOut: 'Head north',
    halt: 'Stop the engines & take stock',
    carryOn: 'Continue the flight',
    supplies: 'Check supplies & crew',
    chart: 'Look at the chart',
    changePace: 'Change speed',
    changeRations: 'Change rations',
    rest: 'Stop the engines and rest',
    repairs: 'Make repairs aloft',
    forage: 'Send up pilot balloons',
    leavePort: 'Cast off',
    restInPort: 'Rest at the mast',
    trade: 'Barter with the ground crew',
    talk: 'Talk to people',
    buy: 'Buy supplies',
    yard: 'Visit the gas plant and the mechanics',
    yardQuestion: null,
    place: null,
    stopName: (stop) => stop.short,
    statusNames: { water: 'Water' },
    travelled: 'Flown',
    distanceUnit: 'km',
    distance: (m) => formatNumber(m),
    meters: ['Lift', 'Engines'],
    clock: null,
    trouble: plight === null ? null : { label: 'Airship', value: plight },
    cash: 'Cash',
    currency: '$',
    storeNames: { clothes: 'Fur suits' },
    looseUnits: { tackle: 'balloons' },
    looseOne: { tackle: 'balloon' },
    fractional: ['limes'],
    singular: true,
    lots: ['water', 'fuel'],
    // Held only while the purse runs to a step of petrol: with less, she goes (D22).
    departRefusal: g.fuel <= 0 && v.hooks.firstPortSells.fuel
      ? "You can't cast off with empty tanks! The storekeeper shakes his head and points you back to the petrol."
      : null,
    departWarning: null,
    resumesInFirstShop: true,
    leaveRefusal: null,
    vesselHeading: `The ${g.ship}`,
    suppliesNote: `Speed: ${pace.name} · Rations: ${rations.name}`
      + (g.noCitrus > 6 ? ` · [red]${watches(g.noCitrus)} without coffee[/red]` : '')
      + (dry ? ' · [red]the tanks are dry[/red]' : '')
      + (dead ? ' · [red]the engines are dead[/red]' : ''),
    crewHeading: `Crew · health ${v.healthLabel}`,
    leaderTag: 'captain',
    clothesWarning: g.clothes < n ? `[red]Only ${g.clothes} of ${n} aboard have a fur suit.[/red]` : null,
    lostHeading: 'Lost on the flight',
    paceHeading: 'Speed',
    paceNow: `The engines are set for [amber]${pace.name}[/amber].`
      + (dead ? ' [red]With the engines dead, it makes no difference.[/red]'
        : dry ? ' [red]With the tanks dry, it makes no difference.[/red]' : ''),
    rationsHeading: 'Rations',
    rationsNow: `The crew is on [amber]${rations.name}[/amber]. With ${n} aboard, that's ${tenth(n * rations.amount)} kg a watch.`,
    restPrompt: g.atPort ? 'The ground crew holds her on the mast while your people sleep in beds that keep still. How long will you stay?'
      : 'You stop the engines and the crew sleeps in turns, wrapped in everything they own. How long will you rest?',
    restChoice: (turns) => span(J, turns),
    repairsHeading: 'Repairs aloft',
    repairsNote: 'Each repair takes a watch.' + (g.role === 'shipwright' ? ' As an airship engineer, your repairs go much further.' : ''),
    mend: `Fit engine spares — 1 box [dim](have ${g.sailcloth})[/dim]`,
    patch: `Drop a bag of ballast [dim](have ${g.timber})[/dim]`,
    yardHeading: 'Gas plant & mechanics',
    yardIntro: `You have [amber]$${formatNumber(g.money)}[/amber]. Each job takes a watch.`,
    yardHull: (cost) => `Top up the gas — $${cost}`,
    yardSails: (cost) => `Overhaul the engines — $${cost}`,
    leaveYard: 'Back to the mast',
    priceNote: (percent) => `Everything here runs about ${percent}% dearer than in ${home}, give or take what had to come by ship.`,
    /** `name` arrives escaped for markup. */
    burial: (name) => `The crew wraps ${name} in a blanket and lays them gently along the keel, to be buried properly when the ship comes down. What words will you say?`,
    commit: 'Say a few words',
    gameOverLine: `${v.dateText} · ${formatNumber(g.mile)} kilometres from ${home}.`,
    arrival: finale[0] ?? '',
    arrivalBody: finale.slice(1).join('\n\n'),
    bonus: `Bonus for being ${article} ${title}`,
    again: 'Fly again',
    thanks: 'Thanks for flying.',
  };
}

/**
 * For tests and screenshots: a well-stocked airship ten kilometres short of
 * `J.stops[stop]`, on the menu under way, leaving in `month` if she can leave then and in
 * May if not. `s` is a fresh voyage's state (from `start`), changed in place as the app's
 * `debug.start` builds its own.
 */
export function debugStart(J, s, stop, month = s.startMonth) {
  const d = J.departures.find((x) => x.month === month) ?? { year: 1926, month: 4 };
  s.startYear = d.year;
  s.startMonth = d.month;
  s.stopIndex = stop - 1;
  s.mile = J.stops[stop].mile - 10;
  s.day = Math.trunc(s.mile / 190);
  Object.assign(s, { fuel: 5000, water: 200, food: 150, limes: 6, meds: 3, clothes: 5, sailcloth: 3, timber: 3,
    tackle: 60, hull: 72, sails: 64, money: 400, atPort: false });
  return s;
}

/** Standing at a stop, its arrival told: moored, if it has a mast and `port` says so. */
export function at(J, s, stopId, port = false) {
  const i = J.stops.findIndex((st) => st.id === stopId);
  if (!J.stops[i]) return;
  s.stopIndex = i;
  s.mile = J.stops[i].mile;
  s.day = Math.max(1, Math.trunc(s.mile / 190));
  s.fuel = 3000;
  s.atPort = port;
}

/** The JourneySkin for Over the Pole, given its tables from the engine. */
export function skin(J) {
  const here = (stopId, port = false) => (s) => at(J, s, stopId, port);
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
        { name: 'France by night', moving: true, set: (s) => { s.mile = 1200; s.day = 3; s.fuel = 3000; } },
        { name: 'Midnight sun', moving: true, set: (s) => { s.mile = 6000; s.day = 4; s.fuel = 3000; } },
        { name: 'Rome', moving: false, set: (s) => { s.atPort = true; } },
        { name: 'Pulham', moving: false, set: here('pulham', true) },
        { name: 'Oslo', moving: false, set: here('oslo', true) },
        { name: 'Vadsø', moving: false, set: here('vadso', true) },
        { name: 'Kings Bay', moving: false, set: here('kingsbay', true) },
        { name: 'Rhône valley', moving: false, set: here('rhone') },
        { name: 'Arctic Circle', moving: false, set: here('circle') },
        { name: 'Bear Island', moving: false, set: here('bear') },
        { name: 'North Pole', moving: false, set: here('pole') },
        { name: 'Point Barrow', moving: false, set: here('barrow') },
        { name: 'Cape Prince of Wales', moving: false, set: here('wales') },
        { name: 'Nome', moving: false, set: here('nome') },
        { name: 'France', moving: true, set: (s) => { s.mile = 1200; s.fuel = 3000; } },
        { name: 'North Sea', moving: true, set: (s) => { s.mile = 2200; s.fuel = 3000; } },
        { name: 'Scandinavia', moving: true, set: (s) => { s.mile = 3300; s.fuel = 3000; } },
        { name: 'Barents Sea', moving: true, set: (s) => { s.mile = 4700; s.fuel = 3000; } },
        { name: 'Polar Sea', moving: true, set: (s) => { s.mile = 6000; s.fuel = 3000; } },
        { name: 'Above the fog', moving: true, set: (s) => { s.mile = 7500; s.fuel = 3000; } },
        { name: 'Alaskan coast', moving: true, set: (s) => { s.mile = 9000; s.fuel = 3000; } },
        { name: 'Drifting', moving: true, set: (s) => { s.mile = 2200; s.day = 9; } },
        { name: 'Engines 10%', moving: true, set: (s) => { s.sails = 10; s.fuel = 3000; } },
        { name: 'Lift 10%', moving: true, set: (s) => { s.hull = 10; s.fuel = 3000; } },
      ],
    },
  };
}
