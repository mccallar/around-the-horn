// Over the Pole's web skin (web/js/journeys/airship-*.js) against the app's (AroundTheHorn/
// Journeys/Airship*.swift) and on its own, as rail-skin.mjs holds the Iron Road's:
//
// - the port: every sentence, colour, sprite row, place and chart point of the Swift skin
//   is in the JS;
// - the words: for every role, near every stop, under way and at the mast, sick, alone, in
//   every kind of trouble (D14) and by night, every screen, and every screen of a run in
//   each month with any answer, says nothing undefined, NaN or null, leaves no markup open,
//   and never uses another journey's word;
// - the drawings: the airship in every weather over every kind of country at every hour,
//   moving and still, sound and worn, full and dry; at each mast, moored and passing; at
//   each stop between; forced down on the ice, the sea and a field; in the midnight sun;
//   the chart at every stop; the winds frame by frame: each draws into a plain pixel buffer
//   without throwing, covers its canvas, and changes with what it shows.
//
//   node Tools/web-tests/airship-skin.mjs
import { readFileSync } from 'node:fs';
import path from 'node:path';
import { repo } from './lib.mjs';
import { portChecks, hexes } from './port.mjs';
import { Player, engine, lcg, describe, texts, plain, wordProblems, markupProblems, FakeTimers } from './player.mjs';
import { Flow, MemoryStorage } from '../../web/js/flow.js';
import { BufferCanvas } from '../../web/js/pixels.js';
import { sceneFrame, drawChart, SCENE_W, SCENE_H } from '../../web/js/drawing.js';
import { FishingModel, drawFishing, reward, popText } from '../../web/js/fishing.js';
import * as airshipSkin from '../../web/js/journeys/airship-skin.js';
import * as airshipScene from '../../web/js/journeys/airship-scene.js';
import * as airshipChart from '../../web/js/journeys/airship-chart.js';

let passed = 0;
const failures = [];
function check(ok, what) {
  if (ok) passed += 1;
  else failures.push(what);
}

const read = (p) => readFileSync(path.join(repo, p), 'utf8');
const BAD = /undefined|NaN|\bnull\b|\[object/;

/**
 * Words of the other journeys that must never reach the airship: 1849's sea and the Iron
 * Road's rails. The airship has a captain and is a ship, the engine's Arctic has fishing
 * boats and dried fish, and Oslo's store is its "ship chandler".
 */
const FOREIGN = /\b(nm|sails?|sailed|sailing|sailors?|nautical|harpoons?|voyage|chandler|shipyard|anchor|cords?|train|conductor|tender|roundhouse|freight|miles?|lbs)\b/i;
const OWN = ['ship chandler'];
function foreignProblems(d, where) {
  const out = [];
  for (const { text } of texts(d)) {
    let t = plain(text);
    for (const o of OWN) t = t.split(o).join('');
    const m = t.match(FOREIGN);
    if (m) out.push(`${where}: "${m[0]}" in ${JSON.stringify(text)}`);
  }
  return out;
}

// MARK: - The port

const SW = (n) => `AroundTheHorn/Journeys/Airship${n}.swift`;
const JS = (n) => `web/js/journeys/airship-${n.toLowerCase()}.js`;
const NAMES = ['Scene', 'Chart', 'Forage', 'Skin'];
portChecks(check, NAMES.map(SW), NAMES.map(JS), new Set(['Kittiwake', 'Leif', 'Rosa', 'Olav', 'Edith', 'Natale']));

for (const name of NAMES) {
  const sw = hexes(read(SW(name))).sort();
  const js = hexes(read(JS(name))).sort();
  check(JSON.stringify(sw) === JSON.stringify(js), `Airship${name}: the colours are the app's (${sw.length} and ${js.length})`);
}

/**
 * The numbers in a piece of either source. Comments and the Swift's type names hold no
 * data, nor do a closure's `$0`, a Swift tuple's `.0` or an index's `[0]`.
 */
const nums = (s) => [...s.replace(/\/\/[^\n]*/g, '').replace(/\/\*\*[\s\S]*?\*\//g, '').replace(/UInt32|Int\b/g, '')
  .replace(/\$\d/g, '').replace(/(?<=[A-Za-z_)\]])\.\d+\b/g, '').replace(/(?<=[A-Za-z_)\]])\[\d+\]/g, '')
  .matchAll(/-?\d+(\.\d+)?/g)].map((m) => Number(m[0]));
const between = (s, a, b) => {
  const i = s.indexOf(a);
  return s.slice(i, s.indexOf(b, i));
};

/** The airship, row for row and colour for colour, and where she flies and moors. */
{
  const sw = read(SW('Scene'));
  const from = sw.indexOf('static let ship = [');
  const rows = [...sw.slice(from, sw.indexOf('].map(Array.init)', from)).matchAll(/"([^"]*)"/g)].map((m) => m[1]);
  check(rows.length === 14 && rows.every((r) => r.length === 32) && JSON.stringify(rows) === JSON.stringify(airshipScene.ship),
    'the airship is the app\'s, pixel for pixel');
  const pairs = [...between(sw, 'static let colors', 'static let flyingX').matchAll(/"(\w)": Color\(hex: 0x([0-9A-F]{6})\)/g)];
  check(pairs.length === 11 && pairs.every(([, k, h]) => {
    const c = airshipScene.colors[k];
    return c && c.r === parseInt(h.slice(0, 2), 16) && c.g === parseInt(h.slice(2, 4), 16) && c.b === parseInt(h.slice(4), 16);
  }) && Object.keys(airshipScene.colors).length === 11, 'each letter her colour');
  const places = nums(between(sw, 'static let flyingX', '// MARK: When'));
  check(JSON.stringify(places) === JSON.stringify([airshipScene.flyingX, airshipScene.flyingY, airshipScene.mooredX,
    airshipScene.mooredY, airshipScene.mastX, airshipScene.mastTop]), `where she flies, moors and the mast stands (${places})`);
  check(Number(sw.match(/static let horizon = ([\d.]+)/)[1]) === airshipScene.horizon, 'the horizon');
  check(JSON.stringify(nums(between(sw, 'static let daysBefore', '\n'))) === JSON.stringify(airshipScene.daysBefore), 'the calendar');
  check(/var ground = 1\.0[\s\S]*var clouds = 0[\s\S]*var cloud: UInt32 = 0xF4F7FA[\s\S]*var sun = false[\s\S]*var rough = 1\.0/.test(sw)
    && JSON.stringify(airshipScene.paletteDefaults) === JSON.stringify({ ground: 1, clouds: 0, cloud: 0xF4F7FA, sun: false, rough: 1 }),
  'a palette\'s defaults');
  const where = Object.fromEntries([...between(sw, 'static let whereabouts:', 'static func whereabouts').matchAll(/"(\w+)": "([^"]+)"/g)]
    .map((m) => [m[1], m[2]]));
  check(JSON.stringify(where) === JSON.stringify(airshipScene.whereaboutsNames), 'every place in a sentence');
  // The numbers each drawing is made of, function by function.
  const js = read(JS('Scene'));
  for (const [a, b, c, d] of [['static func palette', 'static func following', 'export function palette', 'export const following'],
    ['static func midnightSun', 'static func moored', 'export function midnightSun', 'export function moored'],
    ['static func draw', 'static func sun', 'export function draw', 'export function sun'],
    ['static func sun', '// MARK: Country', 'export function sun', '// MARK: Country'],
    ['static func ground', 'static func base', 'export function ground', 'export function base'],
    ['static func base', 'static func far', 'export function base', 'export function far'],
    ['static func far', 'static func detail', 'export function far', 'export function detail'],
    ['static func detail', 'static func ceiling', 'export function detail', 'export function ceiling'],
    ['static func ceiling', 'static func streaks', 'export function ceiling', 'export function streaks'],
    ['static func streaks', '// MARK: Masts', 'export function streaks', '// MARK: Masts'],
    ['static func mast', '// MARK: Stops', 'export function mast', '// MARK: Stops'],
    ['static func landmark(_ px', '// MARK: Forced down', 'export function drawLandmark', '// MARK: Forced down'],
    ['static func camp', '// MARK: The airship', 'export function camp', '// MARK: The airship'],
    ['static func position', 'static func airship', 'export function position', 'export function airship'],
    ['static func airship', 'static func lights', 'export function airship', 'export function lights'],
    ['static func lights', '// MARK: VoiceOver', 'export function lights', '// MARK: VoiceOver']]) {
    const s = nums(between(sw, a, b)), j = nums(between(js, c, d));
    const key = (x) => JSON.stringify([...x].sort((p, q) => p - q));
    check(key(s) === key(j), `${a}: the numbers are the app's (${s.length}: ${s.join(' ')} | ${j.length}: ${j.join(' ')})`);
  }
}

/** The chart's numbers: the flight, every coast, the islets and the projection. */
{
  const sw = read(SW('Chart'));
  const js = read(JS('Chart'));
  check(JSON.stringify(nums(between(sw, 'static let flight', 'static func latitude')))
    === JSON.stringify(nums(between(js, 'export const flight', 'export function latitude'))), 'the flight is the app\'s');
  check(JSON.stringify(nums(between(sw, 'static let shapes', 'static let arcticCircle')))
    === JSON.stringify(nums(between(js, 'export const shapes', 'export const arcticCircle'))), 'the top of the world is the app\'s');
  check(/let r = scale \* \(90 - p\.lat\), a = \(p\.lon - 15\) \* \.pi \/ 180/.test(sw)
    && /const r = scale \* \(90 - lat\), a = \(lon - 15\) \* Math\.PI \/ 180/.test(js)
    && /\(pole\.x \+ r \* sin\(a\), pole\.y \+ r \* cos\(a\)\)/.test(sw)
    && /x: pole\.x \+ r \* Math\.sin\(a\), y: pole\.y \+ r \* Math\.cos\(a\)/.test(js), 'and so is the projection');
  check(airshipChart.pole.x === 115 && airshipChart.pole.y === 79.5 && airshipChart.scale === 2.5 && airshipChart.w === 230
    && airshipChart.h === 210 && airshipChart.arcticCircle === 66.56, 'the pole, the scale and the Circle');
  for (const [a, b, c, d] of [['static func background', 'static func dot', 'export function background', 'export function dot'],
    ['static func circle', 'static func names', 'export function circle', 'export function names'],
    ['static func names', '\n}', 'export function names', 'export function chart'],
    ['static let skin', '// MARK: The top', 'export function chart(J)', '\n}\n']]) {
    const key = (x) => JSON.stringify([...x].sort((p, q) => p - q));
    check(key(nums(between(sw, a, b))) === key(nums(between(js, c, d))), `${a}: the numbers are the app's`);
  }
  const fs = read(SW('Forage')), fj = read(JS('Forage'));
  const key0 = (x) => JSON.stringify([...x].sort((p, q) => p - q));
  check(key0(nums(between(fs, 'static let hand', 'static func backdrop')))
    === key0([...nums(between(fj, 'export const hand', 'export function backdrop')), ...nums(between(fj, 'export function forage', '\n}\n'))]),
  'the field and the hand, as the app has them');
  for (const [a, b, c, d] of [['static func backdrop', 'static func balloon', 'export function backdrop', 'export function balloon'],
    ['static func balloon', 'static func wind', 'export function balloon', 'export function wind'],
    ['static func wind', '\n}', 'export function wind', 'export function forage']]) {
    const key = (x) => JSON.stringify([...x].sort((p, q) => p - q));
    // The JS reads a quarry's colour in `colorOf`, with its radix.
    check(key(nums(between(fs, a, b).replace('radix: 16', ''))) === key(nums(between(fj, c, d))), `${a}: the numbers are the app's`);
  }
  const ss = read(SW('Skin')), sj = read(JS('Skin'));
  const key = (x) => JSON.stringify([...x].sort((p, q) => p - q));
  check(key(nums(between(ss, 'static let debug', 'static func at('))) === key([...nums(between(sj, 'export function debugStart', 'export function at(')),
    ...nums(between(sj, 'gallery: [', '],\n    },'))]), 'the debug start and the gallery');
  check(key(nums(between(ss, 'static func at(', '\n}'))) === key(nums(between(sj, 'export function at(', 'export function skin'))),
    'standing at a stop');
}

// MARK: - The words, everywhere

const e = await engine();
const flow = new Flow({ engine: e, storage: new MemoryStorage(), timers: new FakeTimers(), random: lcg(5), seed: () => '77',
  journey: 'airship' });
const J = flow.journey;
const sk = flow.skin;
check(J.id === 'airship' && sk.id === 'airship', 'Over the Pole, in its own skin');
let screensLooked = 0;

function look(where) {
  const d = describe(flow);
  screensLooked++;
  for (const p of [...wordProblems(d, where), ...foreignProblems(d, where)]) failures.push(p);
  if (flow.screen.name !== 'picker' && d.banner !== 'OVER THE POLE · 1926') failures.push(`${where}: the banner ${d.banner}`);
  passed += 1;
  return d;
}

/** A fresh flight's state, ready for the skin's debug start. */
function fresh(role = 'merchant', month = 4) {
  const dep = J.departures.find((d) => d.month === month) ?? J.departures[0];
  e.start({ journey: 'airship', role, ship: 'Kittiwake', captain: 'Leif', crew: ['Rosa', 'Olav', 'Edith', 'Natale'],
    year: dep.year, month: dep.month, seed: '9' });
  return e.save([]);
}

/** A stocked airship near a stop, changed by `tweak`, on its menu. */
function flightAt(role, stop, tweak = () => {}, month = 4) {
  const s = fresh(role, month);
  sk.debug.start(s, stop, month);
  tweak(s);
  flow.loadForDebug(s);
}

const cardStrings = [];
const walk = (x) => {
  if (typeof x === 'string') cardStrings.push(x);
  else if (Array.isArray(x)) x.forEach(walk);
  else if (x && typeof x === 'object') Object.values(x).forEach(walk);
};
walk(sk.card);
check(cardStrings.length > 30 && cardStrings.every((s) => s.trim().length), 'the title card\'s words are all there');
for (const s of cardStrings) {
  for (const p of markupProblems(s)) failures.push(`card: ${p}`);
  check(!FOREIGN.test(s), `the title card says no other journey's word: ${s.slice(0, 60)}`);
}

const storm = J.weathers.find((w) => w.sky === 'storm');
const troubles = new Set();
for (const role of J.roles.map((r) => r.role)) {
  for (let stop = 1; stop < J.stops.length; stop++) {
    const st = J.stops[stop];
    const variants = [
      ['under way', () => {}],
      ['sick and short', (s) => {
        s.crew[1].ailment = J.ailments[0];
        s.crew[1].treated = true;
        s.crew[2].alive = false;
        s.crew[2].hp = 0;
        s.graves = [{ name: 'Edith', cause: 'frostbite', date: 'May 9, 1926', epitaph: 'Fair winds aloft.' }];
        s.clothes = 1;
        s.noCitrus = 13;
        s.note = 'The tanks are low.';
        s.weather = storm;
        s.hull = 12;
        s.sails = 8;
        s.fuel = 30;
      }],
      ['alone', (s) => {
        for (const p of s.crew.slice(1)) {
          p.alive = false;
          p.hp = 0;
        }
      }],
      ['engines dead', (s) => { s.sails = 0.4; }],
      ['tanks dry', (s) => { s.fuel = 0; }],
      ['engines dead, tanks dry', (s) => { s.sails = 0; s.fuel = 0; }],
      ['going down', (s) => { s.hull = 0.3; }],
      ['by night', (s) => { s.day = 5; }],
    ];
    if (J.ports.some((p) => p.id === st.id)) variants.push(['at the mast', (s) => {
      s.stopIndex = stop;
      s.mile = st.mile;
      s.atPort = true;
    }]);
    for (const [label, tweak] of variants) {
      const where = `${role} near ${st.short}, ${label}`;
      flightAt(role, stop, tweak);
      const menu = flow.screen.name;
      check(menu === (label === 'at the mast' ? 'portMenu' : 'seaMenu'), `${where}: on the ${menu}`);
      look(`${where}, ${menu}`);
      const w = sk.words(flow.v);
      for (const [k, val] of Object.entries(w)) {
        if (typeof val === 'string') check(!BAD.test(val), `${where}: words.${k} = ${val}`);
      }
      if (w.trouble) troubles.add(w.trouble.value);
      const fns = [w.distance(1234), ...J.rules.restChoices.map(w.restChoice), w.yardHull(120), w.yardSails(80),
        w.priceNote(35), w.burial('Olav'), sk.card.resume('Kittiwake'), sk.card.outfitIntro(flow.v), sk.chart.label(flow.v),
        sk.chart.footer(flow.v), sk.forage.hint('450 kg'), sk.forage.label(4), sk.forage.pop('1', J.quarry[0]),
        sk.forage.pop('1,350', J.quarry[4])];
      for (const s of fns) {
        check(typeof s === 'string' && s.length && !BAD.test(s), `${where}: ${s}`);
        for (const p of markupProblems(s)) failures.push(`${where}: ${p}`);
      }
      for (const name of ['supplies', 'chart', 'pace', 'rations', 'rest', 'repairs', 'shipyard', 'travel']) {
        flow.show({ name });
        look(`${where}, ${name}`);
      }
      flow.backToMenu();
      if (label !== 'at the mast') {
        flow.goFishing();
        look(`${where}, ${flow.screen.name === 'fishing' ? 'the winds' : 'no balloons'}`);
        flow.backToMenu();
      }
      flow.showShop(() => flow.backToMenu());
      look(`${where}, stores`);
      flow.show({ name: 'burial', crewID: flow.game.crew[0].id, cause: 'frostbite' });
      look(`${where}, burial`);
      flow.show({ name: 'gameOver', title: 'Down on the ice.', body: 'The crew walks south.' });
      look(`${where}, game over`);
      flow.show({ name: 'finale', finale: { score: { lines: [{ label: 'Petrol in hand', points: 300 }],
        subtotal: 300, multiplier: 3, total: 900 }, rank: 'Ballast', place: stop % 2 ? 3 : null } });
      look(`${where}, finale`);
    }
  }
}
check(screensLooked > 2500, `looked at every screen everywhere (${screensLooked})`);
check(['Going down', 'Engines dead, adrift', 'Tanks dry, adrift', 'Engines dead, tanks dry', 'Last of the petrol']
  .every((t) => troubles.has(t)), `every plight in the status box (${[...troubles]})`);

// The words that change with the state, as the app writes them.
{
  flightAt('shipwright', 4);
  const g = flow.game;
  /** The skin's words for `g` changed by `tweak`, with the engine's hooks for it. */
  const w = (tweak) => {
    const state = { ...g, ...tweak };
    return sk.words({ ...flow.v, state, hooks: e.hooks(state) });
  };
  check(airshipSkin.span(J, 1) === '1 watch' && airshipSkin.span(J, 3) === '3 watches' && airshipSkin.span(J, 6) === '6 watches (1 day)'
    && airshipSkin.span(J, 12) === '12 watches (2 days)' && airshipSkin.span(J, 8) === '8 watches', 'rests, as the menu offers them');
  check(airshipSkin.tenth(1.5) === '1.5' && airshipSkin.tenth(2) === '2' && airshipSkin.tenth(1.25) === '1.3'
    && airshipSkin.tenth(0.04) === '0' && airshipSkin.tenth(1.96) === '2', 'a tenth without a trailing .0');
  check(w({}).trouble === null && w({ fuel: 100 }).trouble.value === 'Last of the petrol'
    && w({ fuel: 0 }).trouble.value === 'Tanks dry, adrift' && w({ fuel: 0, atPort: true }).trouble.value === 'Tanks dry'
    && w({ sails: 0.4 }).trouble.value === 'Engines dead, adrift' && w({ sails: 0.4, atPort: true }).trouble.value === 'Engines dead'
    && w({ sails: 0, fuel: 0 }).trouble.value === 'Engines dead, tanks dry' && w({ hull: 0.2, sails: 0, fuel: 0 }).trouble.value === 'Going down'
    && w({ sails: 0.6 }).trouble === null && w({ fuel: 0, day: 0 }).trouble === null && w({ fuel: 0 }).trouble.label === 'Airship',
  'the airship\'s plight, as the engine judges a meter at 0%');
  check(w({ noCitrus: 7, fuel: 0, sails: 0 }).suppliesNote
    === 'Speed: Cruising · Rations: Full rations · [red]7 watches without coffee[/red] · [red]the tanks are dry[/red] · [red]the engines are dead[/red]'
    && w({ noCitrus: 6 }).suppliesNote === 'Speed: Cruising · Rations: Full rations', 'the supplies note');
  check(w({ sails: 0 }).paceNow.endsWith('[red]With the engines dead, it makes no difference.[/red]')
    && w({ fuel: 0 }).paceNow.endsWith('[red]With the tanks dry, it makes no difference.[/red]')
    && w({}).paceNow === 'The engines are set for [amber]Cruising[/amber].', 'the speed screen');
  check(w({}).repairsNote === 'Each repair takes a watch. As an airship engineer, your repairs go much further.', 'the engineer\'s repairs');
  check(w({}).bonus === 'Bonus for being an engineer' && w({ role: 'merchant' }).bonus === 'Bonus for being a financier'
    && w({ role: 'whaler' }).bonus === 'Bonus for being a meteorologist', 'a and an');
  check(w({ clothes: 2 }).clothesWarning === '[red]Only 2 of 5 aboard have a fur suit.[/red]' && w({ clothes: 5 }).clothesWarning === null,
    'fur suits');
  check(w({}).rationsNow === 'The crew is on [amber]Full rations[/amber]. With 5 aboard, that\'s 1.5 kg a watch.', 'a watch\'s rations');
  check(w({ atPort: true }).restPrompt.startsWith('The ground crew holds her') && w({ atPort: false }).restPrompt.startsWith('You stop the engines'),
    'resting at the mast and aloft');
  check(w({}).priceNote(30) === 'Everything here runs about 30% dearer than in Rome, give or take what had to come by ship.', 'prices against Rome');
  check(w({ fuel: 0 }).departRefusal.startsWith("You can't cast off with empty tanks!") && w({}).departRefusal === null
    && w({}).resumesInFirstShop === true, 'empty tanks are refused at Rome (D16)');
  const f1 = w({ day: 1 }), f2 = w({ day: 30, crew: g.crew.map((p, i) => ({ ...p, alive: i === 0 })) });
  check(f1.arrival.startsWith('Land ho! The [i]Kittiwake[/i] comes down over the roofs of Nome') && f1.arrival.includes('after 1 watch (0 days)')
    && f1.arrivalBody.startsWith('The whole town turns out') && f1.arrivalBody.endsWith('asking for the telegraph office.')
    && !f1.arrivalBody.includes('\n\n'), `the landing at Nome, as the engine tells it (${f1.arrival})`);
  check(f2.arrival.includes('after 30 watches (5 days)') && f2.arrivalBody.endsWith('looking for the telegraph office.'), 'and alone');
  check(w({}).gameOverLine.endsWith(` · ${g.mile.toLocaleString('en-US')} kilometres from Rome.`), 'the end of the flight');
}

/** Runs in every month, each role, answering anything: every screen of the flight's own text. */
{
  let runs = 0, screens = 0;
  const endings = new Set();
  for (const [i, month] of ['April 1926', 'May 1926', 'June 1926', 'July 1926'].entries()) {
    for (const [k, role] of J.roles.entries()) {
      const seed = 100 + i * 7 + k;
      const p = await Player.make({ engine: e, seeds: [String(seed)], random: lcg(seed), journey: 'airship' });
      const look0 = p.look.bind(p);
      p.look = () => {
        const d = look0();
        screens++;
        p.problems.push(...foreignProblems(d, p.screen));
        return d;
      };
      const pick = lcg(seed * 3);
      p.setUp({ role: role.label, month });
      const end = p.voyage({
        layOver: k === 2 ? 1 : 0,
        onScreen: (q) => {
          // Any answer that is offered, not only the careful first one; but the careful
          // player moors at every mast, to buy what it needs to get anywhere at all.
          if (q.screen !== 'choice' || 'portArrival' in q.f.screen.event.kind) return null;
          const open = q.look().choices.filter((c) => c.enabled);
          open[Math.floor(pick() * open.length)].act();
          return null;
        },
      });
      runs++;
      endings.add(end);
      check(end === 'finale' || end === 'gameOver', `${role.title} leaving in ${month}: the flight ends (${end})`);
      for (const pr of p.problems.slice(0, 5)) failures.push(`${role.title} in ${month}: ${pr}`);
    }
  }
  check(runs === 12 && screens > 1500, `twelve runs, every screen read (${screens})`);
  check(endings.has('finale') && endings.has('gameOver'), `flights that land and flights that don't (${[...endings]})`);
}

// MARK: - The drawings

/** A canvas every pixel of which has something on it. */
const full = (px) => px.covered === px.pw * px.ph;

/** The engine's view of `s`: its region, hour, date and hooks worked out as the app works them. */
function viewOf(s) {
  try {
    return e.load(s, '1', 'airship').view;
  } finally {
    e.close();
  }
}
/** `v` with its state changed, and the hooks the engine has for the change. */
const withState = (v, change) => {
  const state = { ...v.state, ...change };
  return { ...v, state, hooks: e.hooks(state) };
};
const picture = (v, moving = false, t = 0) => {
  const px = new BufferCanvas(SCENE_W, SCENE_H);
  sk.scene.draw(px, sceneFrame(J, v, moving, t));
  check(full(px), 'covers its canvas');
  return px.picture;
};
const labelOf = (v, moving = false, t = 0) => sk.scene.label(sceneFrame(J, v, moving, t));

const base = fresh();
sk.debug.start(base, 3);
const LOW = { 'airship.route': 2 };
/** A view in each kind of country, at each hour a watch can fall on, keyed by region id. */
const regionViews = new Map();
const regionList = [...J.regions.map((reg, i) => ({ id: reg.id, from: i === 0 ? 0 : J.regions[i - 1].to, to: reg.to ?? J.totalMiles })),
  { id: 'underFog', from: 6550, to: 8600, vars: LOW }];
for (const reg of regionList) {
  const mile = Math.min(J.totalMiles - 1, Math.floor((reg.from + reg.to) / 2));
  const stopIndex = Math.max(0, J.stops.findLastIndex((st) => st.mile <= mile));
  const views = [1, 2, 3, 4, 5, 6].map((day) => viewOf({ ...base, mile, stopIndex, day, vars: { ...base.vars, ...reg.vars } }));
  check(views.every((v) => v.region.id === reg.id), `${reg.id}: kilometre ${mile} is in it (${views[0].region.id})`);
  regionViews.set(reg.id, views);
}
check(regionViews.size === 9, `nine kinds of country (${regionViews.size})`);
const hours = new Set([...regionViews.values()][0].map((v) => v.hour));
check(hours.size === 6, `every hour a watch falls on (${[...hours]})`);

const wear = [[100, 100, 8000], [45, 35, 3000], [10, 10, 100], [0.3, 0.2, 0]];
const pictures = new Map();
let drawn = 0, turn = 0;
for (const weather of J.weathers) {
  for (const [id, views] of regionViews) {
    // Every hour in fair weather; in the others, noon and midnight.
    for (const v0 of weather.rawValue === 'fair' ? views : views.filter((v) => v.hour === 12 || v.hour === 0)) {
      for (const moving of [false, true]) {
        const t = moving ? [0.37, 5.3, 1000.1][turn++ % 3] : 0;
        for (const [k, [hull, sails, fuel]] of wear.entries()) {
          const v = withState(v0, { weather, hull, sails, fuel });
          const px = new BufferCanvas(SCENE_W, SCENE_H);
          const f = sceneFrame(J, v, moving, t);
          try {
            sk.scene.draw(px, f);
          } catch (err) {
            failures.push(`scene, ${weather.name} over ${id} at ${v.hour}: ${err.stack}`);
            continue;
          }
          drawn++;
          if (!full(px)) failures.push(`scene, ${weather.name} over ${id} at ${v.hour}: ${px.covered} of ${px.pw * px.ph} pixels`);
          if (!moving) pictures.set(`${weather.rawValue}|${id}|${v.hour}|${k}`, px.picture);
          const label = sk.scene.label(f);
          if (!label || BAD.test(label) || FOREIGN.test(label)) failures.push(`scene label: ${label}`);
        }
      }
    }
  }
}
check(drawn === (6 + 8 * 2) * 9 * 2 * 4, `the airship drawn everywhere (${drawn})`);
{
  const p = (w, id, h = 12, k = 0) => pictures.get(`${w}|${id}|${h}|${k}`);
  const regions = [...regionViews.keys()];
  check(new Set(regions.map((id) => p('fair', id))).size === regions.length, 'each kind of country draws its own picture');
  const skies = J.weathers.map((w) => w.rawValue);
  check(new Set(skies.map((w) => p(w, 'france'))).size === skies.length, `each weather draws its own picture (${skies})`);
  check(p('fair', 'france', 0) !== p('fair', 'france', 12) && p('fair', 'france', 0) === p('fair', 'france', 20),
    'night over France is dark, the whole night through');
  check(p('rain', 'france', 0) !== p('fair', 'france', 0), 'a moon and stars only in a clear sky');
  check(new Set([8, 12, 16].map((h) => p('fair', 'france', h))).size === 3, 'the sun goes over');
  check(new Set([0, 1, 2, 3].map((k) => p('fair', 'barents', 12, k))).size === 4, 'wear and dry tanks show');
  check(p('ice', 'france') !== p('fog', 'france'), 'icing fog rimes her');

  const v = regionViews.get('france').find((x) => x.hour === 12);
  check(picture(v, true, 1) !== picture(v, true, 1.5), 'the country slides past under way');
  check(picture(withState(v, { sails: 100 }), true, 1) !== picture(withState(v, { sails: 100 }), false, 1), 'the propeller turns under way');
  check(picture(withState(v, { sails: 30 }), true, 0.1) !== picture(withState(v, { sails: 100 }), true, 0.1), 'a failing engine smokes');
  check(new Set([100, 80, 60, 40, 20].map((hull) => picture(withState(v, { hull })))).size === 5, 'she flies lower as the lift goes');
  check(labelOf(withState(v, { fuel: 0 }), true) === 'Airship drifting over France, engines stopped. Weather: fair & clear'
    && labelOf(withState(v, { sails: 0.4 }), true) === 'Airship drifting over France, engines stopped. Weather: fair & clear'
    && labelOf(withState(v, { sails: 0.6 }), true) === 'Airship flying over France. Weather: fair & clear', 'adrift, as the engine judges the engines');
  check(picture(withState(v, { sails: 0.4 }), true, 2) === picture(withState(v, { fuel: 0 }), true, 2)
    && picture(withState(v, { sails: 0.4 }), true, 2) !== picture(withState(v, { sails: 0.6 }), true, 2),
  'dead engines are drawn as dry tanks are, propellers still');
  check(labelOf(withState(v, { fuel: 0, day: 0 }), true) === 'Airship flying over France. Weather: fair & clear', 'not adrift before she has flown');

  // The title card: no flight yet.
  const title = new BufferCanvas(SCENE_W, SCENE_H);
  sk.scene.draw(title, sceneFrame(J, null, false, 0));
  check(full(title) && sk.scene.label(sceneFrame(J, null, false, 0)) === 'An airship flying north in clear weather', 'the title card\'s airship');
  const big = new BufferCanvas(SCENE_W, SCENE_H, 3);
  sk.scene.draw(big, sceneFrame(J, v, true, 2.5));
  check(full(big), 'the scene at three device pixels a pixel still covers its canvas');
}

// The masts, the stops between, the midnight sun, and forced down.
{
  const fair = J.weathers.find((w) => w.rawValue === 'fair');
  const at = (i, change = {}) => viewOf({ ...base, stopIndex: i, mile: J.stops[i].mile, day: Math.max(1, Math.trunc(J.stops[i].mile / 190)),
    weather: fair, fuel: 3000, ...change });
  for (const [i, st] of J.stops.entries()) {
    const port = J.ports.find((p) => p.id === st.id);
    if (port) {
      const moored = at(i, { atPort: true }), over = at(i, { atPort: false });
      check(labelOf(moored) === `Airship moored at the mast at ${port.name}`, `moored at ${port.name} (${labelOf(moored)})`);
      check(picture(moored) !== picture(over), `moored and over the mast at ${port.name} are two pictures`);
      if (i > 0) {
        check(labelOf(over) === `Airship over the mast at ${port.name}, the ground crew waiting below. Weather: fair & clear`
          && labelOf(over, true) === `Airship flying past the mast at ${port.name}. Weather: fair & clear`
          && labelOf(withState(over, { fuel: 0 }), true) === `Airship drifting past the mast at ${port.name}, engines stopped. Weather: fair & clear`,
        `passing the mast at ${port.name}`);
      }
    } else {
      const v = at(i);
      const label = labelOf(v);
      check(!BAD.test(label) && label !== labelOf(at(i, { mile: st.mile - 30 })), `at ${st.short}: ${label}`);
      check(picture(v) !== picture(at(i, { mile: st.mile - 30 })), `${st.short} is its own picture`);
    }
  }
  const nome = J.stops.length - 1;
  check(labelOf(at(nome)) === 'Airship coming down over the roofs of Nome, the town on the beach', 'Nome');
  check(labelOf(at(nome, { atPort: true })) === 'Airship coming down over the roofs of Nome, the town on the beach', 'Nome has no mast');
  check(labelOf(at(J.stops.findIndex((s) => s.id === 'pole')), true) === 'Airship over the North Pole, flags standing in the snow below. Weather: fair & clear', 'the Pole');

  // Forced down, on what is below her.
  const down = (mile) => {
    const stopIndex = Math.max(0, J.stops.findLastIndex((st) => st.mile < mile));
    // The engine won't load a flight that is over: it is the view of the watch before.
    return withState(viewOf({ ...base, stopIndex, mile, day: 30, hull: 5, weather: fair }), { hull: 0, over: true });
  };
  const ice = down(6000), sea = down(2200), field = down(3300), france = down(1200);
  check(labelOf(ice) === 'The airship down on the ice, her crew camped beside the gondola', `down on the ice (${labelOf(ice)})`);
  check(labelOf(sea) === 'The airship down on the sea, a fishing boat coming alongside', 'down on the sea');
  check(labelOf(field) === 'The airship down in a field, a farmer and his dog looking her over'
    && labelOf(france) === labelOf(field), 'down in a field, Scandinavia\'s included');
  check(new Set([ice, sea, field].map((v) => picture(v))).size === 3, 'each forced down its own picture');
  check(picture(ice, false, 0) !== picture(ice, false, 0.6) || picture(ice, false, 0) !== picture(ice, false, 0.3), 'the camp keeps moving');

  // The midnight sun: north of the Circle, later in the spring the nearer the Circle.
  const night = (mile, month, day) => {
    const s = fresh('merchant', month);
    sk.debug.start(s, 1, month);
    Object.assign(s, { mile, stopIndex: Math.max(0, J.stops.findLastIndex((st) => st.mile <= mile)), weather: fair });
    for (let d = 0; d < 400; d++) {
      const v = viewOf({ ...s, day: d });
      if (v.hour === 0 && v.date[2] >= day) return v;
    }
    throw new Error('no midnight');
  };
  const kings = night(5200, 4, 20), oslo = night(2700, 5, 20), circleApril = night(3640, 3, 2);
  check(labelOf(kings, true) === 'Airship flying over the Barents Sea in the midnight sun. Weather: fair & clear', `Kings Bay in May (${labelOf(kings, true)})`);
  check(labelOf(oslo, true) === 'Airship flying over the North Sea by night. Weather: fair & clear', `Oslo never (${labelOf(oslo, true)})`);
  check(labelOf(circleApril, true).endsWith('by night. Weather: fair & clear'), `the Circle in early April (${labelOf(circleApril, true)})`);
  check(picture(kings) !== picture(oslo), 'the midnight sun is not the night');
}

// The gallery the app shows for screenshots: each one draws.
for (const g of sk.debug.gallery) {
  const s = fresh();
  sk.debug.start(s, 5);
  g.set(s);
  const v = viewOf(s);
  const px = new BufferCanvas(SCENE_W, SCENE_H);
  sk.scene.draw(px, sceneFrame(J, v, g.moving, 1.5));
  check(full(px) && !BAD.test(labelOf(v, g.moving, 1.5)), `the gallery's ${g.name}`);
}
check(sk.debug.gallery.length === 24, 'the whole gallery');

// The chart.
{
  const seen = new Set();
  for (const [i, st] of J.stops.entries()) {
    check(airshipChart.route.some((r) => r.mile === st.mile), `${st.short} is on the flight at its kilometre`);
    for (const t of [0, 0.6]) {
      const v = viewOf({ ...base, stopIndex: i, mile: st.mile, day: 1 });
      const px = new BufferCanvas(sk.chart.w, sk.chart.h);
      try {
        drawChart(px, sk.chart, J, v, t);
      } catch (err) {
        failures.push(`chart at ${st.short}: ${err.stack}`);
        continue;
      }
      passed += 1;
      check(full(px), `the chart covers its canvas at ${st.short}`);
      seen.add(px.picture);
      const words = px.log.filter((l) => l.startsWith('t')).map((l) => l.slice(1).split(',')[0]);
      check(words.join('/') === 'ROME/NOME/POLE', `the two ends and the Pole named (${words})`);
      const label = sk.chart.label(v), footer = sk.chart.footer(v);
      check(!BAD.test(label) && label === `Polar chart of the flight from Rome over the North Pole to Nome. You are ${airshipScene.whereabouts(v.region)}.`,
        `the chart's label (${label})`);
      check(footer.endsWith('to go. The ringed stops have a mast.') && !BAD.test(footer), `the footer (${footer})`);
      if (i === J.stops.length - 1) check(footer.startsWith('9,600 of 9,600 kilometres flown. 0 to go.'), `at the end (${footer})`);
    }
  }
  check(seen.size === J.stops.length * 2, `the chart moves with the airship and the marker blinks (${seen.size})`);
  for (let mile = 0; mile <= J.totalMiles; mile += 173) {
    const px = new BufferCanvas(sk.chart.w, sk.chart.h);
    drawChart(px, sk.chart, J, viewOf({ ...base, stopIndex: Math.max(0, J.stops.findLastIndex((st) => st.mile <= mile)), mile }), 0);
    check(full(px), `the chart at kilometre ${mile}`);
  }
  const rings = new BufferCanvas(sk.chart.w, sk.chart.h);
  airshipChart.names(rings, J);
  check(rings.log.filter((l) => l.startsWith('r')).length === 4 * J.ports.length + 2 && J.ports.length === 5, 'a ring on every mast, and the Pole crossed');
  check(airshipChart.latitude(0) === 41.8 && airshipChart.latitude(5300) === 78.93 && Math.abs(airshipChart.latitude(6550) - 90) < 1e-9
    && Math.abs(airshipChart.latitude(6551) - (90 - 18.61 / 2050)) < 1e-9 && airshipChart.latitude(9600) === 64.5 && airshipChart.latitude(99999) === 64.5 && Math.abs(airshipChart.latitude(325) - 42.6) < 1e-9,
  'the latitude along the flight');
}

// The winds, frame by frame.
for (const role of J.roles) {
  const v = { ...regionViews.get('france')[2] };
  v.state = { ...v.state, role: role.role, tackle: 300 };
  const w = sk.words(v);
  const rw = reward(J, w, sk.forage.grouped);
  check(rw.item.key === 'fuel' && rw.measure(1350) === '1,350 kg' && rw.measure(1) === '1 kg', 'winds are petrol saved, in kilograms');
  let tackle = 300;
  const random = lcg(17);
  const m = new FishingModel({ field: sk.forage.field, quarry: J.quarry, seconds: J.forageSeconds, padding: role.aim,
    pop: popText(sk.forage, rw), random, useTackle: () => tackle-- > 0, tackleLeft: () => tackle });
  const before = tackle;
  m.throwAt(80, 185);
  check(tackle === before && m.harpoon === null, 'a tap on the control car sends nothing up');
  m.throwAt(80, 100);
  check(tackle === before - 1 && m.harpoon && m.harpoon.vy < 0, 'a tap on the sky sends a balloon up');
  const kinds = new Set(), pops = new Set(), ways = new Set();
  let frames = 0;
  while (!m.ended && frames < 2000) {
    if (frames % 7 === 0) m.aimAtNearest();
    if (frames % 11 === 0) m.throwAt(random() * 160, 15 + random() * 140);
    m.step(1 / 60 + (frames % 3) * 0.02);
    for (const f of m.fish) {
      kinds.add(f.kind.name);
      ways.add(Math.sign(f.vx));
    }
    for (const p of m.pops) pops.add(p.text);
    const px = new BufferCanvas(sk.forage.field.w, sk.forage.field.h);
    try {
      drawFishing(px, sk.forage, m, frames / 60);
    } catch (err) {
      failures.push(`winds frame ${frames}: ${err.stack}`);
      break;
    }
    if (!full(px)) failures.push(`winds frame ${frames} leaves pixels bare`);
    frames++;
  }
  passed += 1;
  check(m.ended && m.time <= 0, `the session ends when time is up (${frames} frames)`);
  check(m.caught > 0, `balloons find winds (${rw.measure(m.caught)})`);
  check(kinds.size === J.quarry.length, `every kind of wind goes by (${[...kinds].join(', ')})`);
  check(ways.size === 2, 'winds blow both ways');
  check([...pops].every((t) => /^\+(1 kg|(?!1,)[\d,]+ kg), [a-z ]+$/.test(t)), `what a balloon finds is in kilograms (${[...pops].slice(0, 4)})`);
  check(m.fish.every((f) => f.y >= sk.forage.field.lanes[0] - 5 && f.y <= sk.forage.field.lanes[1] + 5), 'and stays in the sky');
  const hint = sk.forage.hint(rw.measure(role.catchLimit));
  check(hint.endsWith(`worth up to ${role.role === 'whaler' ? '900' : '450'} kg of petrol in one session.`), `the hint (${hint})`);
  check(sk.forage.label(3) === 'The sky above the control car, with 3 winds crossing it' && sk.forage.label(1).endsWith('with 1 wind crossing it'),
    'what the sky shows');
}
check(sk.forage.pop('1', J.quarry[3]) === '+1 kg, strong current' && sk.forage.pop('1,350', J.quarry[4]) === '+1,350 kg, river of air',
  'one kilogram, and a river of air');

console.log(`airship-skin: ${passed} checks passed, ${failures.length} failed`);
for (const f of failures.slice(0, 40)) console.log(`FAILED ${f}`);
process.exit(failures.length ? 1 : 0);
