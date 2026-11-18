// The Jet Stream's web skin (web/js/journeys/balloon-*.js) against the app's (AroundTheHorn/
// Journeys/Balloon*.swift) and on its own, as airship-skin.mjs holds Over the Pole's:
//
// - the port: every sentence, colour, sprite row, place, table and chart point of the
//   Swift skin is in the JS, function by function;
// - the words: for every role, near every stop, aloft, over a field and on the ground,
//   sick, alone, in every kind of trouble (D14) and by night, every screen, and every
//   screen of a run in each month with any answer, says nothing undefined, NaN or null,
//   leaves no markup open, and never uses another journey's word;
// - the drawings: the balloon in every weather over every kind of country at every hour,
//   loitering and flying, sound and worn, full and dry; on each field and over it; at each
//   stop between, both landfalls and the finish; climbing away; down in the sea, on land
//   and on a field; the gallery; the chart at every stop on both tracks; the line frame by
//   frame: each draws into a plain pixel buffer without throwing, covers its canvas, and
//   changes with what it shows.
//
//   node Tools/web-tests/balloon-skin.mjs
import { readFileSync } from 'node:fs';
import path from 'node:path';
import { repo } from './lib.mjs';
import { portChecks, hexes } from './port.mjs';
import { Player, engine, lcg, describe, plain, wordProblems, markupProblems, balloonProblems, BALLOON_FOREIGN, FakeTimers } from './player.mjs';
import { Flow, MemoryStorage } from '../../web/js/flow.js';
import { BufferCanvas } from '../../web/js/pixels.js';
import { sceneFrame, drawChart, routePosition, SCENE_W, SCENE_H } from '../../web/js/drawing.js';
import { FishingModel, drawFishing, reward, popText } from '../../web/js/fishing.js';
import * as balloonSkin from '../../web/js/journeys/balloon-skin.js';
import * as balloonScene from '../../web/js/journeys/balloon-scene.js';
import * as balloonChart from '../../web/js/journeys/balloon-chart.js';

let passed = 0;
const failures = [];
function check(ok, what) {
  if (ok) passed += 1;
  else failures.push(what);
}

const read = (p) => readFileSync(path.join(repo, p), 'utf8');
const BAD = /undefined|NaN|\bnull\b|\[object/;
const FOREIGN = BALLOON_FOREIGN;

// MARK: - The port

const SW = (n) => `AroundTheHorn/Journeys/Balloon${n}.swift`;
const JS = (n) => `web/js/journeys/balloon-${n.toLowerCase()}.js`;
const NAMES = ['Scene', 'Chart', 'Forage', 'Skin'];
portChecks(check, NAMES.map(SW), NAMES.map(JS), new Set(['Skylark', 'Greta', 'Hugo', 'Yuki', 'Conor', 'Rosa']));

for (const name of NAMES) {
  const sw = hexes(read(SW(name))).sort();
  const js = hexes(read(JS(name))).sort();
  check(JSON.stringify(sw) === JSON.stringify(js), `Balloon${name}: the colours are the app's (${sw.length} and ${js.length})`);
}

/**
 * The numbers in a piece of either source. Comments and the Swift's type names hold no
 * data, nor do a closure's `$0`, a Swift tuple's `.0` or an index's `[0]`; a Swift colour
 * written in fractions of 255 is the JS's `rgb` of the same three.
 */
const nums = (s) => [...s.replace(/\/\/[^\n]*/g, '').replace(/\/\*\*[\s\S]*?\*\//g, '').replace(/UInt32|Int\b/g, '')
  .replace(/ \/ 255/g, '').replace(/radix: 16/g, '')
  .replace(/\$\d/g, '').replace(/(?<=[A-Za-z_)\]])\.\d+\b/g, '').replace(/(?<=[A-Za-z_)\]])\[\d+\]/g, '')
  .matchAll(/-?\d+(\.\d+)?/g)].map((m) => Number(m[0]));
const between = (s, a, b) => {
  const i = s.indexOf(a);
  check(i >= 0, `the marker ${a} is in the source`);
  return s.slice(i, s.indexOf(b, i + a.length));
};
const key = (x) => JSON.stringify([...x].sort((p, q) => p - q));
/** The numbers of `a`, less one of each of `less`, as a sorted key. */
const without = (a, less) => {
  const out = [...a];
  for (const n of less) {
    const i = out.indexOf(n);
    if (i >= 0) out.splice(i, 1);
  }
  return key(out);
};

/** The balloon, row for row and colour for colour, and where she flies and stands. */
{
  const sw = read(SW('Scene'));
  const from = sw.indexOf('static let balloon = [');
  const rows = [...sw.slice(from, sw.indexOf('].map(Array.init)', from)).matchAll(/"([^"]*)"/g)].map((m) => m[1]);
  check(rows.length === 20 && rows.every((r) => r.length === 18) && JSON.stringify(rows) === JSON.stringify(balloonScene.balloon),
    'the balloon is the app\'s, pixel for pixel');
  const pairs = [...between(sw, 'static let colors', 'static let x0').matchAll(/"(\w)": Color\(hex: 0x([0-9A-F]{6})\)/g)];
  check(pairs.length === 12 && pairs.every(([, k, h]) => {
    const c = balloonScene.colors[k];
    return c && c.r === parseInt(h.slice(0, 2), 16) && c.g === parseInt(h.slice(2, 4), 16) && c.b === parseInt(h.slice(4), 16);
  }) && Object.keys(balloonScene.colors).length === 12, 'each letter its colour');
  // The 0 of the name `x0`, then the four places.
  check(JSON.stringify(nums(between(sw, 'static let x0', '// MARK: Where'))) === JSON.stringify([0, balloonScene.x0, balloonScene.aloftY,
    balloonScene.loiterY, balloonScene.groundY]), 'where she flies, loiters and stands');
  check(Number(sw.match(/static let aloftHorizon = ([\d.]+)/)[1]) === balloonScene.aloftHorizon
    && Number(sw.match(/static let lowHorizon = ([\d.]+)/)[1]) === balloonScene.lowHorizon, 'the two horizons');
  check(/var clouds = 0[\s\S]*var cloud: UInt32 = 0xF4F7FA[\s\S]*var rough = 0\.0/.test(sw)
    && JSON.stringify(balloonScene.paletteDefaults) === JSON.stringify({ sun: null, bigSun: false, clouds: 0, cloud: 0xF4F7FA, deck: null,
      rough: 0, cirrus: false, still: false, shimmer: false, dust: false }), 'a palette\'s defaults');
  const phrases = Object.fromEntries([...between(sw, 'static let regionPhrase', 'static func phrase').matchAll(/"(\w+)": "([^"]+)"/g)]
    .map((m) => [m[1], m[2]]));
  check(JSON.stringify(phrases) === JSON.stringify(balloonScene.regionPhrase) && Object.keys(phrases).length === 16, 'every kind of country in a sentence');
  const tables = (a, b) => nums(between(sw, a, b));
  check(key(tables('static let peakTable', 'static func range')) === key(balloonScene.peakTable.flatMap((p) => [p.c, p.w, p.h]))
    && key(tables('static let atlasTable', 'static func far')) === key(balloonScene.atlasTable.flatMap((p) => [p.c, p.w, p.h])),
  'the Himalaya and the Atlas, peak for peak');
  // The numbers each drawing is made of, function by function. The JS reads a frame's stop
  // and the chart's tracks through small helpers; what they add is named here.
  const js = read(JS('Scene'));
  for (const [a, b, c, d, jsExtra = [], swExtra = []] of [
    ['static func palette', '// MARK: The balloon', 'export function palette', '// MARK: The balloon'],
    ['static func field', 'static func down', 'export function field', 'export function down'],
    ['static func down', 'static func overField', 'export function down', 'export function overField'],
    ['static func overField', 'static func landmark', 'export function overField', 'export function landmark'],
    ['static func landmark(_ f', 'static func launching', 'export function landmark', 'export function launching'],
    ['static func launching', 'static func cold', 'export function launching', 'export function cold'],
    ['static func cold', 'static func loitering', 'export function cold', 'export function loitering'],
    // Swift zips the track with itself shifted by one where the JS counts from 1, and
    // reads the last point's longitude as `.0`.
    ['static func longitude', 'static func localHour', 'export function longitude', 'export function localHour', [1, 1, 1], [0]],
    ['static func localHour', 'static func isNight', 'export function localHour', 'export function isNight'],
    ['static func isNight', '// MARK: Drawing', 'export function isNight', '// MARK: Drawing'],
    ['static func wrap', 'static func draw', 'export function wrap', 'export function draw'],
    ['static func draw', 'static let sunrise', 'export function draw', 'export const sunrise'],
    ['static let sunrise', 'static func groundRegion', 'export const sunrise', 'export function groundRegion'],
    // The hook carries the region at the landfall's mile less one.
    ['static func groundRegion', 'static func sun', 'export function groundRegion', 'export function sun', [], [1]],
    ['static func sun', 'static func cirrus', 'export function sun', 'export function cirrus'],
    ['static func cirrus', 'static func stars', 'export function cirrus', 'export function stars'],
    ['static func stars', 'static func mixed', 'export function stars', 'export function mixed'],
    ['static func mixed', '// MARK: Country', 'export function mixed', '// MARK: Country'],
    ['static func ground(_', 'static func dashes', 'export function ground(', 'export function dashes'],
    ['static func dashes', 'static let peakTable', 'export function dashes', 'export const peakTable'],
    ['static func range', 'static let atlasTable', 'export function range', 'export const atlasTable'],
    ['static func far', '// MARK: Stops', 'export function far', '// MARK: Stops'],
    ['static func landmark(_ px', '// MARK: Fields', 'export function drawLandmark', '// MARK: Fields'],
    ['static func fieldGround', 'static func props', 'export function fieldGround', 'export function props'],
    ['static func props', 'static func hangarLight', 'export function props', 'export function hangarLight'],
    ['static func hangarLight', 'static func homeGround', 'export function hangarLight', 'export function homeGround'],
    ['static func homeGround', '// MARK: The balloon', 'export function homeGround', '// MARK: The balloon\n\n/**\n * Her'],
    ['static func position', 'static func flame', 'export function position', 'export function flame'],
    ['static func flame', 'static func sprite', 'export function flame', 'export function sprite'],
    ['static func sprite', '// MARK: Down', 'export function sprite', '// MARK: Down'],
    ['static func wreck', 'static func dust', 'export function wreck', 'export function dust'],
    ['static func dust', '// MARK: VoiceOver', 'export function dust', '// MARK: VoiceOver'],
    ['static func whereabouts', 'static func label', 'export function whereabouts', 'export function label'],
    ['static func label', '\n}\n', 'export function label', '\n}\n']]) {
    const s = nums(between(sw, a, b)), j = nums(between(js, c, d));
    check(without(s, swExtra) === without(j, jsExtra), `${a}: the numbers are the app's (${s.length}: ${s.join(' ')} | ${j.length}: ${j.join(' ')})`);
  }
}

/** The chart's numbers: both tracks, every coast, the islets, the projection and the rings. */
{
  const sw = read(SW('Chart'));
  const js = read(JS('Chart'));
  for (const [a, b, c, d] of [['static let north', '/// The southern', 'export const north', '/**\n * The southern'],
    ['static let southern', 'static let south:', 'export const southern', 'export const south ='],
    ['static let shapes', '/// Islands', 'export const shapes', '/** Islands'],
    ['static let islets', '/// An outline', 'export const islets', '/**\n * An outline']]) {
    check(JSON.stringify(nums(between(sw, a, b))) === JSON.stringify(nums(between(js, c, d))), `${a}: point for point the app's`);
  }
  check(balloonChart.shapes.length === 24 && balloonChart.shapes.filter((x) => x.sea).length === 3 && balloonChart.islets.length === 8,
    'twenty-one coasts, three seas and eight islets');
  check(/north\.filter \{ \$0\.2 <= 7800 \} \+ southern \+ north\.filter \{ \$0\.2 >= 13500 \}/.test(sw)
    && balloonChart.south.length === balloonChart.north.filter((p) => p[2] <= 7800 || p[2] >= 13500).length + balloonChart.southern.length,
  'the southern track joins the northern off Japan and over Albuquerque');
  check(/let r = \(90 - p\.lat\) \* scale, a = p\.lon \* \.pi \/ 180/.test(sw) && /const r = \(90 - lat\) \* scale, a = lon \* Math\.PI \/ 180/.test(js)
    && /\(centre\.x \+ r \* sin\(a\), centre\.y \+ r \* cos\(a\)\)/.test(sw)
    && /x: centre\.x \+ r \* Math\.sin\(a\), y: centre\.y \+ r \* Math\.cos\(a\)/.test(js), 'and so is the projection');
  check(balloonChart.centre.x === 115 && balloonChart.centre.y === 105 && balloonChart.scale === 1.25 && balloonChart.w === 230
    && balloonChart.h === 210 && balloonChart.rim === 12, 'the centre, the scale and the rim');
  // The rim's polygon: Swift maps `0..<180`, the JS makes 180 points from nothing.
  check(without(nums(between(sw, 'static func background', 'static func dot')), [0])
    === key(nums(between(js, 'export function background', 'export function dot'))), 'static func background: the numbers are the app\'s');
  for (const [a, b, c, d] of [['static func outline', 'static func background', 'export function outline', '/**\n * Swift\'s `stride'],
    ['static func dot', 'static func marks', 'export function dot', 'export function marks'],
    ['static func marks', '\n}\n', 'export function marks', '/** The ChartSkin'],
    ['static let skin', '// MARK: The northern', 'export function chart(J)', '\n}\n']]) {
    check(key(nums(between(sw, a, b))) === key(nums(between(js, c, d))), `${a}: the numbers are the app's`);
  }
  const fs = read(SW('Forage')), fj = read(JS('Forage'));
  check(key(nums(between(fs, 'static let hatch', 'static func backdrop')))
    === key([...nums(between(fj, 'export const hatch', '/**\n * A strip')), ...nums(between(fj, 'export function forage', '/** A quarry'))]),
  'the field and the hatch, as the app has them');
  for (const [a, b, c, d] of [['static func backdrop', 'static func lure', 'export function backdrop', '/** The line back'],
    ['static func lure', 'static func fish', 'export function lure', '/** 1849\'s fish'],
    ['static func fish', '\n}\n', 'export function fish', '/** The ForageSkin']]) {
    check(key(nums(between(fs, a, b))) === key(nums(between(fj, c, d))), `${a}: the numbers are the app's`);
  }
  const ss = read(SW('Skin')), sj = read(JS('Skin'));
  // Three of the app's cells set the southern track's flag to 1; the JS's `south` does.
  check(without(nums(between(ss, 'static let debug', 'static func daytime')), [1, 1, 1]) === key([...nums(between(sj, 'export function debugStart', '/**\n * A watch that')),
    ...nums(between(sj, 'gallery: [', '],\n    },'))]) && /const south = \(s\) => \{ s\.vars = \{ \.\.\.s\.vars, 'balloon\.south': 1 \}; \};/.test(sj),
  'the debug start and the gallery');
  check(key(nums(between(ss, 'static func daytime', 'static func fly'))) === key(nums(between(sj, 'export function daytime', '/** Flying at'))),
    'a watch by day');
  check(key(nums(between(ss, 'static func fly', 'static func at('))) === key(nums(between(sj, 'export function fly', '/** Standing at'))),
    'flying at a mile');
  check(key(nums(between(ss, 'static func at(', '\n}'))) === key(nums(between(sj, 'export function at(', '/** On the southern'))),
    'standing at a stop');
  // The finale's paragraphs after the first: Swift's `dropFirst()`, the JS's `slice(1)`.
  check(key(nums(between(ss, 'static func words', 'static let debug'))) === without(nums(between(sj, 'export function words', '/**\n * Whether a state')), [1]),
    'the words\' numbers');
}

// MARK: - The words, everywhere

const e = await engine();
const flow = new Flow({ engine: e, storage: new MemoryStorage(), timers: new FakeTimers(), random: lcg(5), seed: () => '77',
  journey: 'balloon' });
const J = flow.journey;
const sk = flow.skin;
check(J.id === 'balloon' && sk.id === 'balloon', 'the Jet Stream, in its own skin');
let screensLooked = 0;

function look(where) {
  const d = describe(flow);
  screensLooked++;
  for (const p of [...wordProblems(d, where), ...balloonProblems(d, where)]) failures.push(p);
  if (flow.screen.name !== 'picker' && d.banner !== 'THE JET STREAM · 1999') failures.push(`${where}: the banner ${d.banner}`);
  passed += 1;
  return d;
}

/** A fresh flight's state, ready for the skin's debug start. */
function fresh(role = 'merchant', month = 0) {
  const dep = J.departures.find((d) => d.month === month) ?? J.departures[0];
  e.start({ journey: 'balloon', role, ship: 'Skylark', captain: 'Greta', crew: ['Hugo', 'Yuki', 'Conor', 'Rosa'],
    year: dep.year, month: dep.month, seed: '9' });
  return e.save([]);
}

/** A stocked balloon near a stop, changed by `tweak`, on its menu. */
function flightAt(role, stop, tweak = () => {}, month = 0) {
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
const isField = (st) => J.ports.some((p) => p.id === st.id);
for (const role of J.roles.map((r) => r.role)) {
  for (let stop = 1; stop < J.stops.length; stop++) {
    const st = J.stops[stop];
    const variants = [
      ['aloft', () => {}],
      ['sick and short', (s) => {
        s.crew[1].ailment = J.ailments[0];
        s.crew[1].treated = true;
        s.crew[2].alive = false;
        s.crew[2].hp = 0;
        s.graves = [{ name: 'Yuki', cause: 'frostbite', date: 'January 9, 1999, 0800 GMT', epitaph: 'Blue skies.' }];
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
      ['burners dead', (s) => { s.sails = 0.4; }],
      ['tanks dry', (s) => { s.fuel = 0; }],
      ['burners dead, tanks dry', (s) => { s.sails = 0; s.fuel = 0; }],
      ['the last of the propane', (s) => { s.fuel = 3; }],
      ['going down', (s) => { s.hull = 0.3; }],
      ['by night', (s) => { s.day += 3; }],
    ];
    if (st.type !== 'end') variants.push(['at the stop', (s) => Object.assign(s, { stopIndex: stop, mile: st.mile })]);
    if (isField(st)) {
      for (const [label, change] of [['on the ground', {}], ['on the ground, burners dead', { sails: 0 }],
        ['on the ground, tanks dry', { fuel: 0 }], ['on the ground, no lift', { hull: 0.2, timber: 0 }]]) {
        variants.push([label, (s) => Object.assign(s, { stopIndex: stop, mile: st.mile, atPort: true, day: Math.max(1, s.day) }, change)]);
      }
    }
    for (const [label, tweak] of variants) {
      const where = `${role} near ${st.short}, ${label}`;
      flightAt(role, stop, tweak);
      const menu = flow.screen.name;
      check(menu === (label.startsWith('on the ground') ? 'portMenu' : 'seaMenu'), `${where}: on the ${menu}`);
      look(`${where}, ${menu}`);
      const w = sk.words(flow.v);
      for (const [k, val] of Object.entries(w)) {
        if (typeof val === 'string') check(!BAD.test(val), `${where}: words.${k} = ${val}`);
      }
      if (w.trouble) troubles.add(w.trouble.value);
      const fns = [w.distance(1234), ...J.rules.restChoices.map(w.restChoice), w.yardHull(1200), w.yardSails(80),
        w.priceNote(35), w.burial('Conor'), sk.card.resume('Skylark'), sk.card.outfitIntro(flow.v), sk.chart.label(flow.v),
        sk.chart.footer(flow.v), sk.forage.hint('40 lbs'), sk.forage.label(4), sk.forage.pop('1', J.quarry[0]),
        sk.forage.pop('12', J.quarry[4])];
      for (const s of fns) {
        check(typeof s === 'string' && s.length && !BAD.test(s), `${where}: ${s}`);
        for (const p of markupProblems(s)) failures.push(`${where}: ${p}`);
      }
      for (const name of ['supplies', 'chart', 'pace', 'rations', 'rest', 'repairs', 'shipyard', 'travel']) {
        flow.show({ name });
        look(`${where}, ${name}`);
      }
      flow.backToMenu();
      if (!label.startsWith('on the ground')) {
        flow.goFishing();
        look(`${where}, ${flow.screen.name === 'fishing' ? 'the line' : 'no fishing'}`);
        flow.backToMenu();
      } else {
        flow.leavePort();
        look(`${where}, relaunching`);
        flow.stopTravel?.();
        flightAt(role, stop, tweak);
      }
      flow.showShop(() => flow.backToMenu());
      look(`${where}, stores`);
      flow.show({ name: 'burial', crewID: flow.game.crew[0].id, cause: 'frostbite' });
      look(`${where}, burial`);
      flow.show({ name: 'gameOver', title: 'Down in the sea.', body: 'A freighter takes everyone aboard.' });
      look(`${where}, game over`);
      flow.show({ name: 'finale', finale: { score: { lines: [{ label: 'Propane, food & water', points: 300 }],
        subtotal: 300, multiplier: 3, total: 900 }, rank: 'Ballast', place: stop % 2 ? 3 : null } });
      look(`${where}, finale`);
    }
  }
}
check(screensLooked > 5000, `looked at every screen everywhere (${screensLooked})`);
check(['Going down', 'No lift', 'Burners dead', 'Burners dead, sinking', 'Burners dead, tanks dry', 'Tanks dry', 'Tanks dry, sinking',
  'Last of the propane'].every((t) => troubles.has(t)), `every plight in the status box (${[...troubles]})`);

// The words that change with the state, as the app writes them.
{
  flightAt('shipwright', 4);
  const g = flow.game;
  /** The skin's words for `g` changed by `tweak`, with the engine's hooks for it. */
  const w = (tweak) => {
    const state = { ...g, ...tweak };
    return sk.words({ ...flow.v, state, hooks: e.hooks(state) });
  };
  const jod = J.stops.findIndex((s) => s.id === 'jod'), mar = 0;
  const ground = (t = {}) => w({ stopIndex: jod, mile: J.stops[jod].mile, atPort: true, ...t });
  check(balloonSkin.span(J, 1) === '1 watch' && balloonSkin.span(J, 3) === '3 watches' && balloonSkin.span(J, 6) === '6 watches (1 day)'
    && balloonSkin.span(J, 12) === '12 watches (2 days)' && balloonSkin.span(J, 5) === '5 watches', 'watches, as the menu offers them');
  check(balloonSkin.tenth(2.5) === '2.5' && balloonSkin.tenth(2) === '2' && balloonSkin.tenth(1.25) === '1.3'
    && balloonSkin.tenth(0.04) === '0' && balloonSkin.tenth(1.96) === '2', 'a tenth without a trailing .0');
  check(balloonSkin.pounds(2.5) === '2.5 lbs' && balloonSkin.pounds(1) === '1 lb' && balloonSkin.pounds(0.96) === '1 lb'
    && balloonSkin.pounds(1.5) === '1.5 lbs', 'pounds, and one pound');
  check(w({}).trouble === null && w({ fuel: 3 }).trouble.value === 'Last of the propane'
    && w({ fuel: 0 }).trouble.value === 'Tanks dry, sinking' && ground({ fuel: 0 }).trouble.value === 'Tanks dry'
    && w({ sails: 0.4 }).trouble.value === 'Burners dead, sinking' && ground({ sails: 0.4 }).trouble.value === 'Burners dead'
    && w({ sails: 0, fuel: 0 }).trouble.value === 'Burners dead, tanks dry' && w({ hull: 0.2, sails: 0, fuel: 0 }).trouble.value === 'Going down'
    && ground({ hull: 0.2 }).trouble.value === 'No lift' && w({ sails: 0.6 }).trouble === null && w({ fuel: 0, day: 0 }).trouble === null
    && w({ fuel: 0 }).trouble.label === 'Balloon', 'the balloon\'s plight, as the engine judges a meter at 0%');
  check(w({ noCitrus: 13, fuel: 0, sails: 0 }).suppliesNote
    === 'Altitude: Middle air · Rations: Hot meals · [red]13 watches without scrubbers[/red] · [red]the tanks are dry[/red] · [red]the burners are dead[/red]'
    && w({ noCitrus: 12 }).suppliesNote === 'Altitude: Middle air · Rations: Hot meals', 'the supplies note');
  check(w({}).paceNow === 'You are flying at [amber]Middle air[/amber].'
    && w({ sails: 0 }).paceNow.endsWith('[red]With no heat for the cone, the height makes no difference to how far she drifts.[/red] It still sets how hard the air is on the crew.')
    && w({ fuel: 0 }).paceNow === w({ sails: 0 }).paceNow
    && ground().paceNow === 'She is on the ground. When she goes up, she will climb to [amber]Middle air[/amber].'
    && ground({ sails: 0 }).paceNow.endsWith(' [red]Not on dead burners: she can only go up on the helium, and drift.[/red]'), 'the altitude screen');
  check(w({}).repairsNote === 'Each repair takes a watch. As a balloon builder, your repairs go much further.'
    && w({ role: 'merchant' }).repairsNote === 'Each repair takes a watch.', 'the builder\'s repairs');
  check(w({}).bonus === 'Bonus for being a balloon builder' && w({ role: 'merchant' }).bonus === 'Bonus for being a chocolate maker'
    && w({ role: 'whaler' }).bonus === 'Bonus for being a bush pilot', 'the bonus');
  check(w({ clothes: 2 }).clothesWarning === '[red]Only 2 of 5 aboard have a down suit.[/red]' && w({ clothes: 5 }).clothesWarning === null,
    'down suits');
  check(w({}).rationsNow === 'The crew is on [amber]Hot meals[/amber]. With 5 aboard, that\'s 2.5 lbs a watch.'
    && w({ rations: J.rations[2].rations, crew: g.crew.map((p, i) => ({ ...p, alive: i < 4 })) }).rationsNow.endsWith('that\'s 0.8 lbs a watch.'),
  'a watch\'s rations');
  check(ground().restPrompt.startsWith('The ground team pitches tents') && w({}).restPrompt.startsWith('You drop into slow, low air'),
    'resting on the ground and loitering aloft');
  check(ground().restChoice(6) === 'Rest 6 watches (1 day)' && w({}).restChoice(3) === 'Loiter 3 watches', 'rest or loiter');
  check(w({}).priceNote(30) === 'Prices here are 30% above Marrakech, more or less.', 'prices against Marrakech');
  check(w({}).yardHull(1234) === 'Top up the helium — $1,234' && w({}).yardSails(80) === 'Overhaul the burners — $80', 'the riggers\' prices');
  check(ground().burial('Hugo') === 'The ground team will take Hugo home. What words will you say?' && ground().commit === 'Say goodbye'
    && w({}).burial('Hugo').startsWith('There is nowhere to bury anyone up here. The crew wraps Hugo in a sleeping bag') && w({}).commit === 'Carry them home',
  'a burial on the ground and aloft');
  check(w({}).leavePort === 'Relaunch [dim](25 gallons)[/dim]' && ground({ sails: 0 }).leavePort === 'Relaunch [dim](on the helium alone)[/dim]',
    'the relaunch\'s cost');
  check(ground().place === 'Jodhpur' && w({}).place === null && w({ atPort: true, stopIndex: 1, mile: J.stops[1].mile }).place === null,
    'the field in the status box');
  check(ground({ fuel: 0 }).leaveRefusal === 'You need at least 25 gallons of propane to relaunch. The ground crew points at the fuel truck.'
    && ground({ fuel: 0, money: 0 }).leaveRefusal === null && ground({ sails: 0, money: 9000 }).leaveRefusal.includes('dead burners')
    && ground({ sails: 0, money: 0 }).leaveRefusal === null && ground({ hull: 0.2, timber: 0 }).leaveRefusal.includes('no lift in her')
    && ground({ hull: 0.2, timber: 0, sails: 0, money: 9000 }).leaveRefusal.includes('no lift in her') && ground({ hull: 0.2, timber: 1 }).leaveRefusal === null
    && w({ fuel: 0 }).leaveRefusal === null && ground({ fuel: 0, over: true }).leaveRefusal === null
    && w({ stopIndex: mar, mile: 0, atPort: true, fuel: 0 }).leaveRefusal === null && e.hooks({ ...g, stopIndex: mar, mile: 0, atPort: true, fuel: 0 }).balloon.relaunchRefusal,
  'the relaunch refused for what the field can mend, lift first (D15, D17), never at Marrakech, aloft or once it is over');
  check(w({}).departRefusal === null && w({}).departWarning === null && w({}).resumesInFirstShop === true, 'Marrakech\'s refusal is the engine\'s (D16)');
  const f1 = w({ day: 1 }), f2 = w({ day: 30, crew: g.crew.map((p, i) => ({ ...p, alive: i === 0 })) });
  check(f1.arrival.startsWith('Finish line! The [i]Skylark[/i] crosses eight degrees west') && f1.arrivalBody.startsWith('At the next sunrise')
    && !f1.arrivalBody.includes('\n\n') && f1.arrivalBody.includes('Children run out from a village'), `the finish, as the engine tells it (${f1.arrivalBody})`);
  check(f2.arrivalBody !== f1.arrivalBody, `and alone (${f2.arrivalBody})`);
  check(w({}).gameOverLine === `${flow.v.dateText} · ${g.mile.toLocaleString('en-US')} nautical miles flown, ${(18300 - g.mile).toLocaleString('en-US')} short of the finish line.`
    && flow.v.dateText.endsWith(' GMT'), `the end of the flight (${w({}).gameOverLine})`);
}

/** Runs in every month, each role, answering anything: every screen of the flight's own text. */
{
  let runs = 0, screens = 0;
  const endings = new Set(), forks = new Set();
  for (const [i, month] of ['November 1998', 'December 1998', 'January 1999', 'February 1999', 'March 1999'].entries()) {
    for (const [k, role] of J.roles.entries()) {
      const seed = 100 + i * 7 + k;
      const p = await Player.make({ engine: e, seeds: [String(seed)], random: lcg(seed), journey: 'balloon' });
      const look0 = p.look.bind(p);
      p.look = () => {
        const d = look0();
        screens++;
        p.problems.push(...balloonProblems(d, p.screen));
        return d;
      };
      const pick = lcg(seed * 3);
      p.setUp({ role: role.label, month });
      const end = p.voyage({
        layOver: k === 2 ? 1 : 0,
        onScreen: (q) => {
          // Any answer that is offered, not only the careful first one; but the careful
          // player lands at every field, to buy what it needs to get anywhere at all.
          if (q.screen !== 'choice' || 'portArrival' in q.f.screen.event.kind) return null;
          const open = q.look().choices.filter((c) => c.enabled);
          const c = open[Math.floor(pick() * open.length)];
          if (q.f.screen.event.kind?.custom?.key === 'fork') forks.add(plain(c.label));
          c.act();
          return null;
        },
      });
      runs++;
      endings.add(end);
      check(end === 'finale' || end === 'gameOver', `${role.title} launching in ${month}: the flight ends (${end})`);
      for (const pr of p.problems.slice(0, 5)) failures.push(`${role.title} in ${month}: ${pr}`);
    }
  }
  check(runs === 15 && screens > 2000, `fifteen runs, every screen read (${screens})`);
  // Any answer at all still gets round: the careful player buys at every field. The
  // endings short of the finish are balloon.mjs's.
  check(endings.has('finale'), `flights that finish (${[...endings]})`);
  check(forks.size >= 2, `the fork answered more than one way (${[...forks]})`);
}

// MARK: - The drawings

/** A canvas every pixel of which has something on it. */
const full = (px) => px.covered === px.pw * px.ph;

/** The engine's view of `s`: its region, hour, date and hooks worked out as the app works them. */
function viewOf(s) {
  try {
    return e.load(s, '1', 'balloon').view;
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
const SOUTH = { 'balloon.south': 1 };
/** A view in each kind of country, at each hour a watch can fall on, keyed by region id. */
const regionViews = new Map();
const regionList = [...J.regions.map((reg, i) => ({ id: reg.id, from: i === 0 ? 0 : J.regions[i - 1].to, to: Math.min(reg.to ?? J.totalMiles, J.totalMiles) })),
  { id: 'southtrack', from: 8800, to: 9200, vars: SOUTH }, { id: 'subtropic', from: 11300, to: 11700, vars: SOUTH }];
for (const reg of regionList) {
  const mile = Math.min(J.totalMiles - 1, Math.floor((reg.from + reg.to) / 2));
  const stopIndex = Math.max(0, J.stops.findLastIndex((st) => st.mile < mile));
  const views = [10, 11, 12, 13, 14, 15].map((day) => viewOf({ ...base, mile, stopIndex, day, vars: { ...base.vars, ...reg.vars } }));
  check(views.every((v) => v.region.id === reg.id), `${reg.id}: mile ${mile} is in it (${views[0].region.id})`);
  regionViews.set(reg.id, views);
}
check(regionViews.size === 16, `sixteen kinds of country (${regionViews.size})`);
const hours = new Set([...regionViews.values()][0].map((v) => v.hour));
check(hours.size === 6, `every hour a watch falls on (${[...hours]})`);

const wear = [[100, 100, 900], [45, 35, 300], [10, 10, 5], [0.3, 0.2, 0]];
const pictures = new Map();
let drawn = 0, turn = 0;
for (const weather of J.weathers) {
  for (const [id, views] of regionViews) {
    // Every hour in a steady wind; in the others, two hours twelve apart.
    for (const v0 of weather.rawValue === 'steady' ? views : views.filter((v) => v.hour === views[0].hour || v.hour === (views[0].hour + 12) % 24)) {
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
check(drawn === (6 + 9 * 2) * 16 * 2 * 4, `the balloon drawn everywhere (${drawn})`);
{
  const sahara = regionViews.get('sahara');
  // By the sun at Marrakech's longitude, a morning hour and a night one.
  const day = sahara.find((v) => !balloonScene.isNight(J, sceneFrame(J, v, false, 0)));
  const night = sahara.find((v) => balloonScene.isNight(J, sceneFrame(J, v, false, 0)));
  check(day && night, `day and night over the Sahara (${sahara.map((v) => v.hour)})`);
  const p = (w, id, h = day.hour, k = 0) => pictures.get(`${w}|${id}|${h}|${k}`);
  const regions = [...regionViews.keys()];
  const noon = (id) => regionViews.get(id).find((v) => !balloonScene.isNight(J, sceneFrame(J, v, false, 0)));
  check(regions.every((id) => noon(id)), 'every kind of country has a watch by day');
  check(new Set(regions.map((id) => picture(withState(noon(id), { weather: J.fairWeather })))).size === regions.length, 'each kind of country draws its own picture');
  const skies = J.weathers.map((w) => w.rawValue);
  check(new Set(J.weathers.map((w) => picture(withState(day, { weather: w })))).size === skies.length, `each weather draws its own picture (${skies})`);
  check(p('steady', 'sahara', night.hour) !== p('steady', 'sahara', day.hour), 'night over the Sahara is dark');
  check(labelOf(night).includes(' by night') && !labelOf(day).includes(' by night'), 'and says so');
  check(new Set([0, 1, 2, 3].map((k) => p('steady', 'arabia', regionViews.get('arabia').find((v) => !balloonScene.isNight(J, sceneFrame(J, v, false, 0))).hour, k))).size === 4,
    'wear and dry tanks show');
  const v = withState(day, { weather: J.fairWeather });
  check(picture(v, true, 1) !== picture(v, true, 1.5), 'the country slides past under way');
  check(picture(v, true, 0.1) !== picture(v, true, 1.0), 'the burners blast and rest');
  check(picture(withState(v, { sails: 30 }), true, 0.1) !== picture(withState(v, { sails: 100 }), true, 0.1), 'worn burners sputter orange');
  check(picture(withState(v, { hull: 39 })) !== picture(withState(v, { hull: 41 })), 'her crown sags below 40% lift');
  const fog = withState(v, { weather: J.weathers.find((w) => w.sky === 'fog') });
  check(picture(fog, true, 1) !== picture(fog, false, 1), 'in cloud the ground is hidden aloft');
  const plains = (month) => withState(viewOf({ ...base, startMonth: month, startYear: month >= 10 ? 1998 : 1999, mile: 14300, stopIndex: J.stops.findLastIndex((st) => st.mile < 14300), day: 120 }), {});
  check(picture(plains(0)) !== picture(plains(2)), 'the Great Plains under snow in winter');
  check(labelOf(withState(v, { fuel: 0 }), true) === `Balloon drifting over the Sahara, burners cold, sinking. Weather: ${J.fairWeather.name.toLowerCase()}`
    && labelOf(withState(v, { sails: 0.4 }), true) === `Balloon drifting over the Sahara, burners dead, sinking. Weather: ${J.fairWeather.name.toLowerCase()}`
    && labelOf(withState(v, { sails: 0.6 }), true) === `Balloon flying over the Sahara. Weather: ${J.fairWeather.name.toLowerCase()}`
    && labelOf(v) === `Balloon loitering low over the Sahara, the burners blipping. Weather: ${J.fairWeather.name.toLowerCase()}`,
  'cold, as the engine judges the burners');
  check(picture(withState(v, { sails: 0.4 }), true, 0.1) === picture(withState(v, { sails: 0.4, fuel: 0 }), true, 0.1)
    && picture(withState(v, { sails: 0.4 }), true, 0.1) !== picture(withState(v, { sails: 0.6 }), true, 0.1),
  'dead burners are drawn as dry tanks are, no flame');

  // The title card: no flight yet.
  const title = new BufferCanvas(SCENE_W, SCENE_H);
  sk.scene.draw(title, sceneFrame(J, null, false, 0));
  check(full(title) && sk.scene.label(sceneFrame(J, null, false, 0)) === 'A balloon flying east under a clear sky', 'the title card\'s balloon');
  const big = new BufferCanvas(SCENE_W, SCENE_H, 3);
  sk.scene.draw(big, sceneFrame(J, v, true, 2.5));
  check(full(big), 'the scene at three device pixels a pixel still covers its canvas');
}

// The fields, the stops between, the launch, the finish, and down for good.
{
  const steady = J.fairWeather;
  const at = (i, change = {}) => viewOf({ ...base, stopIndex: i, mile: J.stops[i].mile, day: Math.max(1, Math.trunc(J.stops[i].mile / 115)),
    weather: steady, fuel: 900, ...change });
  const sky = `Weather: ${steady.name.toLowerCase()}`;
  const plainDay = (v) => labelOf(v).replace(' by night', '');
  for (const [i, st] of J.stops.entries()) {
    const port = J.ports.find((p) => p.id === st.id);
    if (port) {
      const ground = at(i, { atPort: true }), over = at(i, { atPort: false });
      check(plainDay(ground) === `Balloon standing on the field at ${port.name}, its ground team beside it`, `on the field at ${port.name} (${labelOf(ground)})`);
      check(picture(ground) !== picture(over), `on the field and over it at ${port.name} are two pictures`);
      if (i > 0) {
        check(plainDay(over) === `Balloon low over the field at ${port.name}, the ground team waiting below. ${sky}`
          && labelOf(over, true).replace(' by night', '') === `Balloon flying over the field at ${port.name}. ${sky}`
          && labelOf(withState(over, { fuel: 0 }), true) === `Balloon drifting over the field at ${port.name}, burners cold. ${sky}`
          && labelOf(withState(over, { sails: 0 }), true) === `Balloon drifting over the field at ${port.name}, burners dead. ${sky}`,
        `over the field at ${port.name} (${labelOf(over)})`);
        check(picture(at(i, { atPort: true, day: ground.state.day + 3 })) !== picture(ground), `night falls on the field at ${port.name}`);
      }
    } else {
      const v = at(i);
      const label = labelOf(v);
      check(!BAD.test(label) && label !== labelOf(at(i, { mile: st.mile - 30 })), `at ${st.short}: ${label}`);
      check(picture(v) !== picture(at(i, { mile: st.mile - 30 })), `${st.short} is its own picture`);
    }
  }
  const idx = (id) => J.stops.findIndex((s) => s.id === id);
  const stopLabel = (id, change = {}) => plainDay(at(idx(id), change));
  check(stopLabel('atlas') === `Balloon crossing the High Atlas, snowfields below. ${sky}`
    && stopLabel('him') === `Balloon passing the Himalaya, Everest on the horizon. ${sky}`
    && stopLabel('pacific') === `Balloon leaving the coast of Japan, the open Pacific ahead. ${sky}`
    && stopLabel('dateline') === `Balloon crossing the date line over the Pacific. ${sky}`
    && stopLabel('azores') === `Balloon over the Azores, a fishing boat waiting below. ${sky}`, 'the stops between, each as itself');
  const north = at(idx('landfall')), south = at(idx('landfall'), { vars: SOUTH });
  check(plainDay(north) === `Balloon crossing the coast of California, the redwoods ahead. ${sky}`
    && plainDay(south) === `Balloon crossing the coast at San Diego, brown hills ahead. ${sky}`
    && north.hooks.balloon.offLandfall === 'nepacific' && south.hooks.balloon.offLandfall === 'subtropic' && picture(north) !== picture(south),
  'two landfalls, over the sea each track leaves');
  const finish = withState(at(idx('finish'), { atPort: false }), { atPort: true, over: true });
  check(labelOf(finish) === 'The balloon down on a stony plain outside Marrakech, children running out from a village'
    && picture(finish, false, 0) !== picture(finish, false, 0.4), 'the finish at sunrise, the children running');
  // Climbing away from Marrakech: launched, no watch flown.
  const launch = withState(viewOf({ ...base, stopIndex: 0, mile: 0, day: 0 }), { atPort: false });
  check(labelOf(launch) === `Balloon climbing away from the launch field at Marrakech, the crowd waving. ${sky}`, `climbing away (${labelOf(launch)})`);
  check(picture(launch) !== picture(withState(launch, { atPort: true })), 'climbing away is not standing on the field');

  // Down for good, on what is below her.
  const down = (mile, change = {}) => {
    const stopIndex = Math.max(0, J.stops.findLastIndex((st) => st.mile < mile));
    // The engine won't load a flight that is over: it is the view of the watch before.
    return withState(viewOf({ ...base, stopIndex, mile, day: 60, hull: 5, weather: steady, ...change }), { hull: 0, over: true });
  };
  const sea = down(9000), land = down(4800), field = down(J.stops[idx('lux')].mile, { stopIndex: idx('lux') });
  check(labelOf(sea) === 'The balloon down in the sea, its envelope folded over the capsule, a freighter coming', `down in the sea (${labelOf(sea)})`);
  check(labelOf(land) === 'The balloon down on open ground, its envelope torn and spread out in the dust', 'down on land');
  check(labelOf(field) === 'The balloon down for good on the field at Luxor, its envelope laid out flat', `down on the field (${labelOf(field)})`);
  check(new Set([sea, land, field].map((v) => picture(v))).size === 3, 'each down for good its own picture');
  check(picture(sea, false, 0) !== picture(sea, false, 0.8), 'the capsule bobs on the swell');
}

// The gallery the app shows for screenshots (SceneGallery.swift `state`: a fresh flight in
// the first month she can launch in, not on the ground, and then the cell's own changes):
// each one draws, by day where it is flying, and shows what it is named for.
{
  const labels = {};
  for (const g of sk.debug.gallery) {
    const s = fresh('merchant', J.departures[0].month);
    s.atPort = false;
    g.set(s);
    // The engine won't load a flight that is over: it is the view of the watch before.
    const over = s.over;
    const v = withState(viewOf({ ...s, over: false }), { over });
    const px = new BufferCanvas(SCENE_W, SCENE_H);
    sk.scene.draw(px, sceneFrame(J, v, g.moving, 1.5));
    labels[g.name] = labelOf(v, g.moving, 1.5);
    check(full(px) && !BAD.test(labels[g.name]), `the gallery's ${g.name}`);
  }
  check(sk.debug.gallery.length === 40, 'the whole gallery');
  for (const name of ['Luxor', 'Jodhpur', 'Saga', 'Albuquerque', 'Kitty Hawk']) {
    check(labels[name] === `Balloon standing on the field at ${name}, its ground team beside it`, `${name}: ${labels[name]}`);
  }
  check(labels.Marrakech.startsWith('Balloon standing on the field at Marrakech') && labels['Climbing away'].startsWith('Balloon climbing away'),
    `Marrakech, and climbing away (${labels.Marrakech} | ${labels['Climbing away']})`);
  check(labels['By night over the Sahara'].includes('over the Sahara by night'), `night over the Sahara (${labels['By night over the Sahara']})`);
  const byDay = Object.entries(labels).filter(([n]) => n !== 'By night over the Sahara').every(([, l]) => !l.includes('by night'));
  check(byDay, `the rest by day (${Object.entries(labels).filter(([, l]) => l.includes('by night')).map(([n]) => n)})`);
  check(labels['Over the Luxor field'].startsWith('Balloon low over the field at Luxor') && labels['Landfall, south'].includes('San Diego')
    && labels['Landfall, north'].includes('California') && labels['Southern track'].includes('on the southern track')
    && labels['Subtropical Pacific'].includes('over the subtropical Pacific') && labels['Finish line'].startsWith('The balloon down on a stony plain'),
  'the stops between and both tracks');
  check(labels['Tanks dry'].includes('burners cold, sinking') && labels['Going down'].startsWith('Balloon loitering low')
    && labels['Down in the sea'].startsWith('The balloon down in the sea') && labels['Down on land'].startsWith('The balloon down on open ground'),
  `in trouble, and down (${labels['Tanks dry']} | ${labels['Going down']})`);
}

// The chart.
{
  const seen = new Set();
  const forkAt = J.stops.findIndex((s) => s.type === 'fork');
  check(balloonChart.forkIndex(J) === forkAt && forkAt > 0, 'the fork off Japan');
  for (const [i, st] of J.stops.entries()) {
    check(balloonChart.northRoute.some((r) => r.mile === st.mile) && balloonChart.southRoute.some((r) => r.mile === st.mile),
      `${st.short} is on both tracks at its mile`);
    for (const vars of i > forkAt ? [{}, SOUTH] : [{}]) {
      for (const t of [0, 0.6]) {
        const v = viewOf({ ...base, stopIndex: i, mile: st.mile, day: 1, vars });
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
        const label = sk.chart.label(v), footer = sk.chart.footer(v);
        check(!BAD.test(label) && label === `Polar chart of the flight round the world, east from Marrakech and back. You are ${balloonScene.whereabouts(J, v.state, v.region)}.`,
          `the chart's label (${label})`);
        check(footer.endsWith('to go. The ringed stops are landing fields.') && !BAD.test(footer), `the footer (${footer})`);
        if (i === J.stops.length - 1) check(footer.startsWith('18,300 of 18,300 nautical miles flown. 0 to go.'), `at the end (${footer})`);
        check(sk.chart.route(v) === (vars['balloon.south'] ? balloonChart.southRoute : balloonChart.northRoute)
          && sk.chart.others(v).length === (i < forkAt ? 1 : 0), `${st.short}: the track flown, and the other while it is still open`);
      }
    }
  }
  check(seen.size === (J.stops.length + J.stops.length - forkAt - 1) * 2, `the chart moves with the balloon and the marker blinks (${seen.size})`);
  for (let mile = 0; mile <= J.totalMiles; mile += 317) {
    for (const vars of [{}, SOUTH]) {
      const px = new BufferCanvas(sk.chart.w, sk.chart.h);
      drawChart(px, sk.chart, J, viewOf({ ...base, stopIndex: Math.max(0, J.stops.findLastIndex((st) => st.mile <= mile)), mile, vars }), 0);
      check(full(px), `the chart at mile ${mile}`);
    }
  }
  const v = viewOf({ ...base, stopIndex: 2, mile: J.stops[2].mile, atPort: true });
  check(sk.chart.label(v).endsWith('You are on the ground at Luxor.')
    && sk.chart.label(viewOf({ ...base, stopIndex: 2, mile: J.stops[2].mile })).endsWith('You are over the field at Luxor.'), 'on a field and over it');
  const rings = new BufferCanvas(sk.chart.w, sk.chart.h);
  balloonChart.marks(rings, J, sk.chart, v);
  check(rings.log.filter((l) => l.startsWith('r')).length === 4 * J.ports.length + 2 && J.ports.length === 6, 'a ring on every field, and the Pole crossed');
  check(J.ports.every((p) => {
    const q = routePosition(balloonChart.northRoute, J.stops.find((s) => s.id === p.id).mile, sk.chart);
    return rings.log.some((l) => l.startsWith(`r${Math.round(q.x) - 2},${Math.round(q.y) - 3},`));
  }), 'each ring round its field');
  check(balloonScene.longitude({ mile: 0 }, false) === -8 && balloonScene.longitude({ mile: 18300 }, false) === 352
    && Math.abs(balloonScene.longitude({ mile: 50 }, false) - -7) < 1e-9 && balloonScene.longitude({ mile: 9000 }, true) !== balloonScene.longitude({ mile: 9000 }, false)
    && balloonScene.longitude({ mile: 99999 }, true) === 352, 'the longitude along each track');
}

// The line, frame by frame.
for (const role of J.roles) {
  const v = { ...regionViews.get('npacific')[2] };
  v.state = { ...v.state, role: role.role, tackle: 300 };
  const w = sk.words(v);
  const rw = reward(J, w, sk.forage.grouped);
  check(rw.item.key === 'food' && rw.measure(1050) === '1050 lbs' && rw.measure(1) === '1 lb', 'a catch is rations, in pounds');
  let tackle = 300;
  const random = lcg(17);
  const m = new FishingModel({ field: sk.forage.field, quarry: J.quarry, seconds: J.forageSeconds, padding: role.aim,
    pop: popText(sk.forage, rw), random, useTackle: () => tackle-- > 0, tackleLeft: () => tackle });
  const before = tackle;
  m.throwAt(80, 10);
  check(tackle === before && m.harpoon === null, 'a tap on the capsule casts nothing');
  m.throwAt(80, 120);
  check(tackle === before - 1 && m.harpoon && m.harpoon.vy > 0, 'a tap on the water casts a lure down');
  const kinds = new Set(), pops = new Set(), ways = new Set();
  let frames = 0;
  while (!m.ended && frames < 2000) {
    if (frames % 7 === 0) m.aimAtNearest();
    if (frames % 11 === 0) m.throwAt(random() * 160, 50 + random() * 140);
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
      failures.push(`line frame ${frames}: ${err.stack}`);
      break;
    }
    if (!full(px)) failures.push(`line frame ${frames} leaves pixels bare`);
    frames++;
  }
  passed += 1;
  check(m.ended && m.time <= 0, `the session ends when time is up (${frames} frames)`);
  check(m.caught > 0, `lures catch fish (${rw.measure(m.caught)})`);
  check(kinds.size === J.quarry.length, `every kind of fish swims by (${[...kinds].join(', ')})`);
  check(ways.size === 2, 'fish swim both ways');
  check([...pops].every((t) => /^\+(1 lb|\d+ lbs) [a-z -]+$/.test(t)), `what a lure brings is in pounds (${[...pops].slice(0, 4)})`);
  check(m.fish.every((f) => f.y >= sk.forage.field.lanes[0] - 5 && f.y <= sk.forage.field.lanes[1] + 5), 'and stays in the sea');
  const hint = sk.forage.hint(rw.measure(role.catchLimit));
  check(hint === `Tap the water to cast a lure. Each cast uses line. You can stow up to ${role.catchLimit} lbs.`, `the hint (${hint})`);
  check(sk.forage.label(3) === 'The sea below the capsule, with 3 fish swimming', 'what the sea shows');
}
check(sk.forage.pop('1', J.quarry[0]) === '+1 lb flying fish' && sk.forage.pop('12', J.quarry[4]) === '+12 lbs yellowfin', 'one pound, and a yellowfin');
{
  const px = new BufferCanvas(160, 200);
  const kinds = new Map();
  for (const q of J.quarry) {
    const c = new BufferCanvas(40, 30);
    sk.forage.quarry(c, { x: 20, y: 15, vx: 1, kind: q });
    kinds.set(q.name, c.picture);
  }
  check(new Set(kinds.values()).size === J.quarry.length, 'each fish drawn as itself');
  sk.forage.backdrop(px, 0.5);
  check(full(px), 'the sea below the capsule covers its field');
}

console.log(`balloon-skin: ${passed} checks passed, ${failures.length} failed`);
for (const f of failures.slice(0, 40)) console.log(`FAILED ${f.slice(0, 600)}`);
process.exit(failures.length ? 1 : 0);
