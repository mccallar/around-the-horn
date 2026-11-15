// Around the Horn, 1849: everything the shell says and draws for it
// (AroundTheHorn/Journeys/Horn1849Skin.swift). The words are the app's, line for line;
// the art is in the files beside this one.
//
// `skin(J)` dresses the journey `J` (its tables, from the engine's `journeys()`). Every
// function of the voyage takes the bridge's view `v`: `v.state` is the GameState, and the
// rest is what the app reads off it (`v.dateText`, `v.healthLabel`, `v.region`, …).

import { escape, formatNumber } from '../markup.js';
import * as scene from './horn1849-scene.js';
import { chart } from './horn1849-chart.js';
import { forage } from './horn1849-forage.js';

export const id = 'horn1849';

export const card = {
  banner: 'AROUND THE HORN · 1849',
  title: 'AROUND\nTHE HORN',
  year: '~ 1849 ~',
  tagline: 'Fourteen thousand miles from New York to the gold fields of California, by sea.',
  start: 'Sail for California',
  /** `vessel` arrives escaped for markup. */
  resume: (vessel) => `Continue the voyage of the [i]${vessel}[/i]`,
  learn: 'Learn about the passage',
  learnPages: [
    {
      heading: 'The voyage',
      paragraphs: [
        'In 1849, news of gold in California emptied the seaports of the East. One road west went overland. The other went by sea — fourteen thousand miles south through the Atlantic, around the stormy tip of South America, and north up the Pacific.',
        'You are captain of a small ship with a crew of five. You must buy supplies, keep your crew alive, keep your ship afloat, and reach San Francisco.',
      ],
    },
    {
      heading: 'Supplies',
      paragraphs: [
        '[amber]Provisions[/amber] and [amber]water[/amber] run out fast. Restock at ports — at a price.',
        '[amber]Citrus[/amber] prevents scurvy. After a month without it, your crew will start to sicken.',
        '[amber]Woolens[/amber] keep sailors alive in the far south — one set per person.',
        '[amber]Sailcloth[/amber] and [amber]timber[/amber] repair your ship at sea. [amber]Tackle[/amber] lets you fish for food.',
      ],
    },
    {
      heading: 'The Horn',
      paragraphs: [
        'Off Tierra del Fuego you must choose: round [amber]Cape Horn[/amber] in open ocean, or thread the narrow, rocky [amber]Strait of Magellan[/amber].',
        'Timing matters. From May to September it is winter down there, and the seas are the worst on earth. Leave New York too late and you will pay for it.',
        'Pace and rations matter too: pushing hard gets you there faster, if anyone survives.',
      ],
    },
  ],
  roleHeading: 'Who are you?',
  roleIntro: 'Every sort of person sailed for California in 1849. Choose who you will be:',
  differencesAction: 'How do they compare?',
  differencesHeading: 'How they compare',
  differences: [
    'Passage to California was expensive, and not everyone who went was rich.',
    '[amber]Merchant[/amber] — starts with $1,500.',
    '[amber]Shipwright[/amber] — starts with $850. Gets far more out of every bolt of sailcloth and bundle of timber.',
    '[amber]Whaler[/amber] — starts with $500. Deadly with a harpoon and can salt a bigger catch.',
    'The poorer you start, the more your arrival is worth: the shipwright scores double, the whaler triple.',
  ],
  namesHeading: 'Ship & crew',
  vesselPrompt: 'Name your ship:',
  vesselLabel: "Ship's name",
  leaderPrompt: 'Your name, Captain:',
  leaderLabel: "Captain's name",
  crewPrompt: 'Your four crew members:',
  crewLabel: 'Crew member',
  monthHeading: 'When will you sail?',
  monthIntro: 'The news from California reached New York in December 1848. Ships are leaving every day. When will you weigh anchor?',
  monthAdvice: 'An old shipmaster scratches his beard: “Leave too early and the North Atlantic winter will batter you before you reach the trades. Leave too late and you will reach the Horn in the southern winter — and God help you then. December or January, if you can.”',
  outfitHeading: 'Outfitting',
  outfitIntro: (v) => `You have [amber]$${formatNumber(v.state.money)}[/amber] to fit out the [i]${escape(v.state.ship)}[/i]. The chandler on South Street has what you need:`,
  outfitBullets: [
    '• [b]Provisions[/b] — five people eating well use 15 lbs a day. The voyage may take five months. Ports sell more, at a markup.',
    '• [b]Water[/b] — about a gallon per person per day. Rain can be caught in the sails.',
    '• [b]Citrus[/b] — without it, scurvy sets in after a month.',
    '• [b]Oilskins & woolens[/b] — one set per person, or the cold will kill them.',
    '• [b]Sailcloth & timber[/b] — the only way to make repairs at sea.',
    '• [b]Medicine & fishing tackle[/b].',
  ],
  enterShop: 'Enter the shop',
  rankLegend: 'Master Mariner 7,000+ · Able Seaman 4,000+ · Ordinary Seaman 2,000+ · Greenhand',
};

/** What things are called on a voyage, worked out for the voyage in hand. */
export function words(J, v) {
  const g = v.state;
  const pace = J.paces.find((p) => p.pace === g.pace);
  const rations = J.rations.find((r) => r.rations === g.rations);
  const role = J.roles.find((r) => r.role === g.role);
  const n = g.crew.filter((p) => p.alive).length;
  return {
    setOut: 'Set sail',
    halt: 'Heave to & take stock',
    carryOn: 'Continue on your voyage',
    supplies: 'Check supplies & crew',
    chart: 'Look at the chart',
    changePace: 'Change pace',
    changeRations: 'Change rations',
    rest: 'Heave to and rest',
    repairs: 'Make repairs',
    forage: 'Go fishing',
    leavePort: 'Weigh anchor and sail on',
    restInPort: 'Rest ashore',
    trade: 'Seek a trade',
    talk: 'Talk to people',
    buy: 'Buy supplies',
    yard: 'Visit the shipyard',
    statusNames: { water: 'Water' },
    travelled: 'Sailed',
    distanceUnit: 'nm',
    distance: (m) => formatNumber(m),
    meters: ['Hull', 'Sails'],
    clock: null,
    cash: 'Cash',
    currency: '$',
    storeNames: { clothes: 'Woolens', sailcloth: 'Sailcloth', timber: 'Timber' },
    looseUnits: { tackle: 'throws' },
    fractional: ['limes'],
    singular: false,
    lots: [],
    vesselHeading: `The ${g.ship}`,
    suppliesNote: `Pace: ${pace.name} · Rations: ${rations.name}`
      + (g.noCitrus > 20 ? ` · [red]${g.noCitrus} days without citrus[/red]` : ''),
    crewHeading: `Crew · health ${v.healthLabel}`,
    leaderTag: 'captain',
    clothesWarning: g.clothes < n ? `[red]Only ${g.clothes} of ${n} have woolens.[/red]` : null,
    lostHeading: 'Lost on the voyage',
    paceHeading: 'Pace',
    paceNow: `The pace is currently [amber]${pace.name}[/amber].`,
    rationsHeading: 'Rations',
    rationsNow: `Rations are currently [amber]${rations.name}[/amber]. With ${n} aboard, that's ${n * Math.trunc(rations.amount)} lbs a day.`,
    restPrompt: g.atPort ? 'Your crew can sleep ashore, eat fresh food and recover. How many days?'
      : 'You heave to, and the crew rests below. How many days?',
    restChoice: (d) => `${d} day${d > 1 ? 's' : ''}`,
    repairsHeading: 'Repairs',
    repairsNote: 'Each repair takes a day.' + (g.role === 'shipwright' ? ' As a shipwright, your repairs go much further.' : ''),
    mend: `Mend sails — 1 bolt of sailcloth [dim](have ${g.sailcloth})[/dim]`,
    patch: `Patch the hull — 1 bundle of timber [dim](have ${g.timber})[/dim]`,
    yardHeading: 'Shipyard',
    yardIntro: `You have [amber]$${formatNumber(g.money)}[/amber]. Each job takes a day.`,
    yardHull: (cost) => `Haul out and repair the hull — $${cost}`,
    yardSails: (cost) => `Have new sails cut — $${cost}`,
    leaveYard: 'Leave the shipyard',
    priceNote: (percent) => `Prices here are ${percent}% above New York, more or less.`,
    /** `name` arrives escaped for markup. */
    burial: (name) => `The crew sews ${name} into a sailcloth shroud, weighted with a cannonball. What words will you say?`,
    commit: 'Commit to the deep',
    gameOverLine: `${v.dateText} · ${formatNumber(g.mile)} nautical miles from New York.`,
    arrival: `Land ho! The [i]${escape(g.ship)}[/i] passes through the Golden Gate on ${v.dateText}, after ${g.day} days at sea.`,
    arrivalBody: 'San Francisco Bay is a forest of masts — hundreds of ships abandoned by crews who ran for the gold fields the moment the anchor dropped. '
      + (n > 1 ? 'Your crew is already eyeing the hills.' : 'You stand alone on the deck, looking at the hills.'),
    bonus: `Bonus for being a ${role.title}`,
    again: 'Sail again',
    thanks: 'Thanks for sailing.',
  };
}

/**
 * For tests and screenshots: a well-stocked voyage ten miles short of `J.stops[stop]`,
 * on the menu under way. `s` is a fresh voyage's state (from `start`), changed in place
 * as the app's `debug.start` builds its own.
 */
export function debugStart(J, s, stop) {
  s.stopIndex = stop - 1;
  s.mile = J.stops[stop].mile - 10;
  s.day = Math.trunc(s.mile / 110);
  Object.assign(s, { food: 1500, water: 600, limes: 10, meds: 3, clothes: 5, sailcloth: 3, timber: 3, tackle: 60,
    hull: 72, sails: 64, money: 600, atPort: false });
  if (s.mile > 7800) s.passage = 'horn';
  return s;
}

/** The JourneySkin for 1849, given its tables from the engine. */
export function skin(J) {
  return {
    id,
    card,
    words: (v) => words(J, v),
    scene: { draw: scene.draw, label: scene.label },
    chart,
    forage,
    debug: {
      start: (s, stop) => debugStart(J, s, stop),
      gallery: [
        { name: 'At port', moving: false, set: (s) => { s.atPort = true; } },
        {
          name: 'Sails 10%',
          moving: true,
          set: (s) => {
            s.weather = J.weathers.find((w) => w.sky === 'gale') ?? s.weather;
            s.sails = 10;
          },
        },
      ],
    },
  };
}
