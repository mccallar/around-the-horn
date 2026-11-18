// The Jet Stream, 1999: everything the shell says and draws for it
// (AroundTheHorn/Journeys/BalloonSkin.swift). The engine counts in four-hour watches and
// calls its two meters `hull` and `sails`; here they are lift and the burners, `timber` is
// ballast, `sailcloth` burner spares, `limes` CO2 scrubbers and `tackle` fishing line,
// counted in casts. The words are the app's, line for line; the art is in the files beside
// this one.
//
// `skin(J)` dresses the journey `J` (its tables, from the engine's `journeys()`). Every
// function of the voyage takes the bridge's view `v`: `v.state` is the GameState, and the
// rest is what the app reads off it (`v.dateText`, `v.healthLabel`, `v.region`, …), with
// what it asks the engine (`Balloon.goingDown`, `burnersOut`, `lastOfThePropane`,
// `relaunchRefusal`, `finale`, `shortfall`, and the chart's southern track) in
// `v.hooks.balloon`.

import { escape, formatNumber } from '../markup.js';
import * as scene from './balloon-scene.js';
import { chart } from './balloon-chart.js';
import { forage } from './balloon-forage.js';

export const id = 'balloon';

/** Watches to the day. */
export function perDay(J) {
  return Math.max(1, Math.trunc(24 / Math.max(1, J.rules.tickHours)));
}

/** "1 watch", "3 watches". */
export const watches = (n) => `${n} ${n === 1 ? 'watch' : 'watches'}`;

/** A count of watches as the menus write it: "3 watches", and the whole days a long one makes, "6 watches (1 day)". */
export function span(J, n) {
  const pd = perDay(J);
  if (!(n >= pd && n % pd === 0)) return watches(n);
  const d = n / pd;
  return `${watches(n)} (${d} ${d === 1 ? 'day' : 'days'})`;
}

/** Swift's `x.rounded()`: halves away from zero. */
const rounded = (x) => Math.sign(x) * Math.round(Math.abs(x));

/** A number to a tenth, without a trailing ".0": "2.5", "2". */
export function tenth(x) {
  const r = rounded(x * 10) / 10;
  return r === rounded(r) ? String(Math.trunc(r)) : String(r);
}

/** Pounds to a tenth: "2.5 lbs", "1 lb". */
export function pounds(x) {
  const n = tenth(x);
  return `${n} ${n === '1' ? 'lb' : 'lbs'}`;
}

/**
 * The altitude screen's first lines. Aloft: the height she flies at, and with no heat that
 * it changes nothing about the drift. On the ground: the height she will climb to, unless
 * the burners are dead and there is no climb (`Balloon.leaving`).
 */
export function paceNow(g, name, dead, dry) {
  if (g.atPort) {
    return `She is on the ground. When she goes up, she will climb to [amber]${name}[/amber].`
      + (dead ? ' [red]Not on dead burners: she can only go up on the helium, and drift.[/red]' : '');
  }
  return `You are flying at [amber]${name}[/amber].`
    + (dead || dry
      ? ' [red]With no heat for the cone, the height makes no difference to how far she drifts.[/red] It still sets how hard the air is on the crew.'
      : '');
}

export const card = {
  banner: 'THE JET STREAM · 1999',
  title: 'THE JET\nSTREAM',
  year: '~ 1999 ~',
  tagline: 'Eighteen thousand nautical miles round the world by balloon, riding the winter jet stream.',
  start: 'Fly round the world',
  /** `vessel` arrives escaped for markup. */
  resume: (vessel) => `Continue the flight of the [i]${vessel}[/i]`,
  learn: 'Learn about the flight',
  learnPages: [
    {
      heading: 'The flight',
      paragraphs: [
        'In the winter of 1998 nobody had yet flown a balloon around the world. Teams had been trying for twenty years, and many of them had ended up in the sea, which is a long way down from the jet stream.',
        'You command a balloon with a sealed capsule and a crew of five, counting yourself. Ride the jet stream east from Marrakech until you cross its meridian again from the west, 18,300 nautical miles later. Five fields along the way have a ground team waiting with propane and supplies, if you choose to land.',
        'Time passes in [amber]watches[/amber] of four hours, six to a day.',
      ],
    },
    {
      heading: 'Propane, lift and burners',
      paragraphs: [
        '[amber]Propane[/amber] keeps you up. You burn it every watch, flying or loitering, and more in the cold; climbing away from a field takes 25 gallons. When the tanks run dry the envelope cools, and you drift on the helium alone, sinking as you go.',
        '[amber]Lift[/amber] leaks away a little every watch, and hot sun, ice and storms take more. Drop a sack of [amber]ballast[/amber] to win it back, or have the riggers at a field top up the helium. When the lift is gone she starts down, and something heavy must go over the side: ballast, or a whole cylinder of propane. With neither, she comes down for good.',
        "[amber]Burners[/amber] wear, worst of all up in the jet and in rough air. Fit [amber]burner spares[/amber] aloft, or have a field's burner man overhaul them. Worn to nothing they give no heat at all, and she drifts and sinks as if the tanks were dry.",
      ],
    },
    {
      heading: 'Air, food and the cold',
      paragraphs: [
        '[amber]Food[/amber] and [amber]water[/amber] run out too. The fields sell more, at a price.',
        '[amber]CO2 scrubbers[/amber] keep the capsule air fit to breathe. Three days without them, and the crew starts to sicken.',
        '[amber]Down suits[/amber] keep the crew alive in the cold of the jet, one each. [amber]Fishing line[/amber] lets you catch food over the sea, at the wave tops, with the hatch open.',
      ],
    },
    {
      heading: 'The Pacific',
      paragraphs: [
        'From Saga to Albuquerque is 5,850 nautical miles with nowhere to land. In good winds the crossing burns some 600 gallons of propane; in poor ones, far more. Fill every tank at Saga. Off the coast of Japan you must choose: ride the bitter-cold [amber]northern track[/amber] in the core of the jet, or drop to the warmer, slower [amber]southern track[/amber], where the thunderstorms grow.',
        "Timing matters. The jet is strongest from December to February. Launch in November or March and you'll wallow.",
        "Height matters too: up in the jet you're fast and burn less propane for every mile, if your crew can stand it.",
      ],
    },
  ],
  roleHeading: 'Who are you?',
  roleIntro: 'Balloonists came from every walk of life, and with every size of bank balance. Which one are you?',
  differencesAction: 'Compare the three',
  differencesHeading: 'How they compare',
  differences: [
    'Flying round the world is expensive, and not everyone who tried it was rich.',
    '[amber]Chocolate maker[/amber] — starts with $15,000.',
    '[amber]Balloon builder[/amber] — starts with $7,250. Gets far more out of every sack of ballast and every burner kit.',
    '[amber]Bush pilot[/amber] — starts with $6,500. Deadly with a fishing line, and can stow half as much again of a catch.',
    "The poorer you start, the more your finish is worth: the builder's counts double, the bush pilot's triple.",
  ],
  namesHeading: 'Balloon & crew',
  vesselPrompt: 'Name your balloon:',
  vesselLabel: "Balloon's name",
  leaderPrompt: 'Your name, Pilot:',
  leaderLabel: "Pilot's name",
  crewPrompt: 'Your four crew members:',
  crewLabel: 'Crew member',
  monthHeading: 'When will you launch?',
  monthIntro: 'The winds that can carry a balloon round the world blow hardest in the dead of winter. Your balloon is ready in November 1998. When will you launch?',
  monthAdvice: "Your meteorologist taps the chart: “The jet is weak in November and starts breaking up in March. Launch in December, January or February, and you'll have it under you most of the way.”",
  outfitHeading: 'Outfitting',
  outfitIntro: (v) => `You have [amber]$${formatNumber(v.state.money)}[/amber] to fit out the [i]${escape(v.state.ship)}[/i]. The supply hangar at the launch field has what you need:`,
  outfitBullets: [
    '• [b]Propane[/b] — 12 to 16 gallons a watch, more in the cold, and 25 to climb away from any field. You can lift 1,200 gallons. There is nowhere to land between Saga and Albuquerque: fill every tank at Saga.',
    '• [b]Food[/b] — five of you on hot meals eat 2.5 lbs a watch, and the flight takes three or four weeks. The fields along the way sell more, at a markup.',
    '• [b]Water[/b] — a fifth of a gallon each a watch, more in the heat. In snow you can melt rime off the hatch rim.',
    '• [b]CO2 scrubbers[/b] — a canister lasts five of you ten watches. Without them the capsule air goes stale within three days.',
    '• [b]Down suits[/b] — one per person, or the cold of the jet will kill them.',
    '• [b]Ballast & burner spares[/b] — the only repairs you can make aloft.',
    '• [b]Medical kits & fishing line[/b] — a spool is 20 casts, trailed from the hatch at the wave tops.',
  ],
  enterShop: 'Enter the supply hangar',
  rankLegend: 'Master Aeronaut 7,000+ · Balloon Captain 4,000+ · Co-pilot 2,000+ · Ballast',
};

/**
 * On the ground at a field, short of what the climb needs or with no lift, when the field
 * sells the remedy (`Balloon.relaunchRefusal`). Marrakech's launch is the engine's own
 * refusal, through `depart`.
 */
export function relaunchRefusal(v) {
  const g = v.state;
  if (!(g.atPort && g.stopIndex > 0 && !g.over)) return null;
  return v.hooks.balloon.relaunchRefusal ?? null;
}

/**
 * The balloon's plight, for the status box: going down (the engine's own rule), no heat
 * with the burners dead or the tanks dry, or less propane than a watch flown here burns,
 * which heats only part of one. Nothing before the launch.
 */
export function trouble(v) {
  const g = v.state, a = v.hooks.balloon;
  if (!(g.day > 0)) return null;
  if (a.goingDown) return g.atPort ? 'No lift' : 'Going down';
  const dead = a.burnersOut, dry = g.fuel <= 0;
  if (dead) return dry ? 'Burners dead, tanks dry' : g.atPort ? 'Burners dead' : 'Burners dead, sinking';
  if (dry) return g.atPort ? 'Tanks dry' : 'Tanks dry, sinking';
  return a.lastOfThePropane ? 'Last of the propane' : null;
}

/** What things are called aloft, worked out for the voyage in hand. */
export function words(J, v) {
  const g = v.state, a = v.hooks.balloon;
  const pace = J.paces.find((p) => p.pace === g.pace);
  const rations = J.rations.find((r) => r.rations === g.rations);
  const n = g.crew.filter((p) => p.alive).length;
  const home = J.stops[0]?.name ?? '';
  const title = J.roles.find((r) => r.role === g.role).title;
  // The engine's finale: the crossing, then the landing and who climbs out.
  const finale = a.finale.split('\n\n');
  const dry = g.fuel <= 0 && g.day > 0;
  const dead = a.burnersOut;
  const stop = J.stops[g.stopIndex];
  const field = g.atPort && J.ports.some((p) => p.id === stop.id);
  const plight = trouble(v);
  return {
    setOut: 'Climb away',
    halt: 'Hold & take stock',
    carryOn: 'Continue the flight',
    supplies: 'Check supplies & crew',
    chart: 'Look at the chart',
    changePace: 'Change altitude',
    changeRations: 'Change rations',
    rest: 'Loiter low and rest',
    repairs: 'Make repairs',
    forage: 'Trail a fishing line',
    // On dead burners there is no climb to burn propane on (`Balloon.leaving`).
    leavePort: `Relaunch [dim](${dead ? 'on the helium alone' : '25 gallons'})[/dim]`,
    restInPort: 'Rest on the ground',
    trade: "See who'll trade",
    talk: 'Ask around the field',
    buy: 'Buy supplies',
    yard: 'Visit the riggers',
    yardQuestion: null,
    place: field ? stop.short : null,
    stopName: (s) => s.short,
    statusNames: { water: 'Water' },
    travelled: 'Flown',
    distanceUnit: 'nm',
    distance: (m) => formatNumber(m),
    meters: ['Lift', 'Burners'],
    clock: null,
    trouble: plight === null ? null : { label: 'Balloon', value: plight },
    cash: 'Cash',
    currency: '$',
    storeNames: {},
    looseUnits: { tackle: 'casts' },
    looseOne: { tackle: 'cast' },
    fractional: ['limes'],
    singular: true,
    lots: ['water', 'fuel'],
    departRefusal: null,
    departWarning: null,
    resumesInFirstShop: true,
    leaveRefusal: relaunchRefusal(v),
    vesselHeading: `The ${g.ship}`,
    suppliesNote: `Altitude: ${pace.name} · Rations: ${rations.name}`
      + (g.noCitrus > 12 ? ` · [red]${watches(g.noCitrus)} without scrubbers[/red]` : '')
      + (dry ? ' · [red]the tanks are dry[/red]' : '')
      + (dead ? ' · [red]the burners are dead[/red]' : ''),
    crewHeading: `Crew · health ${v.healthLabel}`,
    leaderTag: 'pilot',
    clothesWarning: g.clothes < n ? `[red]Only ${g.clothes} of ${n} aboard have a down suit.[/red]` : null,
    lostHeading: 'Lost on the flight',
    paceHeading: 'Altitude',
    paceNow: paceNow(g, pace.name, dead, dry),
    rationsHeading: 'Rations',
    rationsNow: `The crew is on [amber]${rations.name}[/amber]. With ${n} aboard, that's ${pounds(n * rations.amount)} a watch.`,
    restPrompt: g.atPort
      ? 'The ground team pitches tents beside the field, and everyone sleeps on ground that keeps still. How long will you stay?'
      : 'You drop into slow, low air and let the crew sleep in turns. You make no headway east, and the burners still want about 10 gallons a watch. How long will you loiter?',
    restChoice: (turns) => `${g.atPort ? 'Rest' : 'Loiter'} ${span(J, turns)}`,
    repairsHeading: 'Repairs aloft',
    repairsNote: 'Each repair takes a watch.' + (g.role === 'shipwright' ? ' As a balloon builder, your repairs go much further.' : ''),
    mend: `Service the burners — 1 kit [dim](have ${g.sailcloth})[/dim]`,
    patch: `Drop a sack of ballast [dim](have ${g.timber})[/dim]`,
    yardHeading: 'The riggers',
    yardIntro: `You have [amber]$${formatNumber(g.money)}[/amber]. Each job takes a watch on the ground.`,
    yardHull: (cost) => `Top up the helium — $${formatNumber(cost)}`,
    yardSails: (cost) => `Overhaul the burners — $${formatNumber(cost)}`,
    leaveYard: 'Back to the field',
    priceNote: (percent) => `Prices here are ${percent}% above ${home}, more or less.`,
    /** `name` arrives escaped for markup. */
    burial: (name) => (g.atPort
      ? `The ground team will take ${name} home. What words will you say?`
      : `There is nowhere to bury anyone up here. The crew wraps ${name} in a sleeping bag and settles them in the quietest corner of the capsule, to be carried home. What words will you say?`),
    commit: g.atPort ? 'Say goodbye' : 'Carry them home',
    gameOverLine: a.shortfall,
    arrival: finale[0] ?? '',
    arrivalBody: finale.slice(1).join('\n\n'),
    bonus: `Bonus for being a ${title}`,
    again: 'Fly again',
    thanks: 'Thanks for flying.',
  };
}

/**
 * Whether a state the debug start builds has taken the southern track. The app's
 * `daytime` asks the engine's regions (`BalloonChart.onSouthTrack`); a debug state has not
 * been through the engine yet, so this reads the flag those regions read, which at 9,000 nm
 * is the same answer.
 */
const debugSouth = (s) => s.vars?.['balloon.south'] === 1;

/**
 * For tests and screenshots: a well-stocked balloon ten nautical miles short of
 * `J.stops[stop]`, by day, on the menu aloft, launched in `month` if she can launch then
 * and in January 1999 if not. `s` is a fresh flight's state (from `start`), changed in
 * place as the app's `debug.start` builds its own.
 */
export function debugStart(J, s, stop, month = s.startMonth) {
  // January 1999 unless the month asked for is one she can launch in.
  const d = J.departures.find((x) => x.month === month) ?? { year: 1999, month: 0 };
  s.startYear = d.year;
  s.startMonth = d.month;
  s.stopIndex = stop - 1;
  s.mile = J.stops[stop].mile - 10;
  daytime(J, s);
  Object.assign(s, { fuel: 900, water: 150, food: 200, limes: 8, meds: 3, clothes: 5, sailcloth: 3, timber: 4,
    tackle: 60, hull: 72, sails: 64, money: 2000, atPort: false });
  return s;
}

/**
 * A watch that falls in the morning where she is, between about half past six and half
 * past ten by the sun, at or a little after the day her miles suggest: so a debug start or
 * a gallery cell is by day, and stays so for the watch or two a walk flies on.
 */
export function daytime(J, s) {
  const start = J.rules.startHour, each = J.rules.tickHours;
  const target = (8.5 - scene.longitude(s, debugSouth(s)) / 15) % 24;
  const off = (d) => {
    const x = Math.abs((start + each * d) % 24 - (target < 0 ? target + 24 : target));
    return Math.min(x, 24 - x);
  };
  const base = Math.max(1, Math.trunc(s.mile / 115));
  let best = base;
  for (let d = base; d < base + Math.trunc(24 / Math.max(1, each)); d++) {
    if (off(d) < off(best)) best = d;
  }
  s.day = best;
}

/** Flying at `mile`, past the stops behind it, with propane aboard, by day. */
export function fly(J, s, mile) {
  s.mile = mile;
  s.stopIndex = Math.max(0, J.stops.findLastIndex((st) => st.mile < mile));
  s.fuel = 900;
  daytime(J, s);
}

/** Standing at a stop, its arrival told: on the ground, if it is a field and `port` says so. */
export function at(J, s, stopId, port = false) {
  const i = J.stops.findIndex((st) => st.id === stopId);
  if (!J.stops[i]) return;
  s.stopIndex = i;
  s.mile = J.stops[i].mile;
  if (s.fuel <= 0) s.fuel = 900;
  daytime(J, s);
  s.atPort = port;
}

/** On the southern track, as the fork's question sets it. */
const south = (s) => { s.vars = { ...s.vars, 'balloon.south': 1 }; };

/** The JourneySkin for the Jet Stream, given its tables from the engine. */
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
        { name: 'By night over the Sahara', moving: true, set: (s) => { fly(J, s, 1200); s.day = 3; } },
        { name: 'Marrakech', moving: false, set: (s) => { s.atPort = true; } },
        { name: 'Climbing away', moving: false, set: (s) => { s.fuel = 900; } },
        { name: 'Luxor', moving: false, set: here('lux', true) },
        { name: 'Jodhpur', moving: false, set: here('jod', true) },
        { name: 'Saga', moving: false, set: here('saga', true) },
        { name: 'Albuquerque', moving: false, set: here('abq', true) },
        { name: 'Kitty Hawk', moving: false, set: here('kh', true) },
        { name: 'Over the Luxor field', moving: false, set: here('lux') },
        { name: 'High Atlas', moving: false, set: here('atlas') },
        { name: 'Himalaya', moving: false, set: here('him') },
        { name: 'Off Japan', moving: false, set: here('pacific') },
        { name: 'Date line', moving: false, set: here('dateline') },
        { name: 'Landfall, north', moving: false, set: here('landfall') },
        { name: 'Landfall, south', moving: false, set: (s) => { south(s); at(J, s, 'landfall'); } },
        { name: 'Azores', moving: false, set: here('azores') },
        { name: 'Finish line', moving: false, set: (s) => { at(J, s, 'finish'); s.atPort = true; s.over = true; } },
        { name: 'Sahara', moving: true, set: flying(1200) },
        { name: 'Arabia', moving: true, set: flying(3000) },
        { name: 'Gulf of Oman', moving: true, set: flying(3650) },
        { name: 'Indus & Thar', moving: true, set: flying(4200) },
        { name: 'Northern India', moving: true, set: flying(4800) },
        { name: 'Himalaya & China', moving: true, set: flying(6200) },
        { name: 'East China Sea', moving: true, set: flying(7700) },
        { name: 'North Pacific', moving: true, set: flying(9000) },
        { name: 'Northeast Pacific', moving: true, set: flying(11500) },
        { name: 'Southern track', moving: true, set: (s) => { south(s); fly(J, s, 9000); } },
        { name: 'Subtropical Pacific', moving: true, set: (s) => { south(s); fly(J, s, 11500); } },
        { name: 'American Southwest', moving: true, set: flying(13000) },
        { name: 'Great Plains, January', moving: true, set: (s) => { s.startYear = 1999; s.startMonth = 0; fly(J, s, 14300); } },
        { name: 'North Atlantic', moving: true, set: flying(16300) },
        { name: 'Past the Azores', moving: true, set: flying(17800) },
        { name: 'Morocco', moving: true, set: flying(18260) },
        { name: 'Loitering', moving: false, set: flying(9000) },
        { name: 'Tanks dry', moving: true, set: (s) => { fly(J, s, 9000); s.fuel = 0; } },
        { name: 'Burners 10%', moving: true, set: (s) => { fly(J, s, 9000); s.sails = 10; } },
        { name: 'Lift 10%', moving: true, set: (s) => { fly(J, s, 9000); s.hull = 10; } },
        { name: 'Going down', moving: false, set: (s) => { fly(J, s, 9000); s.hull = 0; } },
        { name: 'Down in the sea', moving: false, set: (s) => { fly(J, s, 9000); s.hull = 0; s.over = true; } },
        { name: 'Down on land', moving: false, set: (s) => { fly(J, s, 4800); s.hull = 0; s.over = true; } },
      ],
    },
  };
}
