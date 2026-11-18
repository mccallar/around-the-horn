// To the Klondike's web skin (web/js/journeys/klondike-*.js) against the app's (AroundTheHorn/
// Journeys/Klondike*.swift) and on its own, as mars-skin.mjs holds the Long Transfer's:
//
// - the port: every sentence, colour, sprite row, palette, table and map point of the Swift
//   skin is in the JS, and the numbers in each drawing are the app's, piece by piece;
// - the words: for every role, near every stop, under way, at the stop and in town, sick,
//   alone, in every kind of trouble (D14), every screen, and every screen of a trek in each
//   month with any answer, says nothing undefined, NaN or null, leaves no markup open, and
//   never uses another journey's word; the stops are named for the pass taken, the yard's row
//   asks about a boat only at Bennett without one, and Seattle warns only a party short of
//   grub that may leave (D21);
// - the drawings: the steamer, the party and the boat in every sky over every stretch of the
//   way, idle and moving, sound, worn and given out; at each stop and in each town on both
//   passes; Bennett frozen and open; the raft; the outfit ruined, turned back and the boat
//   broken up; the gallery; the map at every stop on both passes and before the fork, and
//   the inset; the fishing frame by frame: each draws into a plain pixel buffer without
//   throwing, covers its canvas, and changes with what it shows.
//
//   node Tools/web-tests/klondike-skin.mjs
import { readFileSync } from 'node:fs';
import path from 'node:path';
import { repo } from './lib.mjs';
import { portChecks, hexes } from './port.mjs';
import { Player, engine, lcg, describe, wordProblems, markupProblems, klondikeProblems, KLONDIKE_FOREIGN, KLONDIKE_FIGURES,
  FakeTimers, SAFE, plain } from './player.mjs';
import { Flow, MemoryStorage } from '../../web/js/flow.js';
import { BufferCanvas } from '../../web/js/pixels.js';
import { sceneFrame, drawChart, routePosition, SCENE_W, SCENE_H } from '../../web/js/drawing.js';
import { FishingModel, drawFishing, reward, popText } from '../../web/js/fishing.js';
import * as kSkin from '../../web/js/journeys/klondike-skin.js';
import * as kScene from '../../web/js/journeys/klondike-scene.js';
import * as kChart from '../../web/js/journeys/klondike-chart.js';
import * as kForage from '../../web/js/journeys/klondike-forage.js';

let passed = 0;
const failures = [];
function check(ok, what) {
  if (ok) passed += 1;
  else failures.push(what);
}

const read = (p) => readFileSync(path.join(repo, p), 'utf8');
const BAD = /undefined|NaN|\bnull\b|\[object/;
const foreign = (s) => {
  let said = plain(s);
  for (const f of KLONDIKE_FIGURES) said = said.split(f).join('');
  return KLONDIKE_FOREIGN.test(said);
};

// MARK: - The port

const SW = (n) => `AroundTheHorn/Journeys/Klondike${n}.swift`;
const JS = (n) => `web/js/journeys/klondike-${n.toLowerCase()}.js`;
const NAMES = ['Scene', 'Chart', 'Forage', 'Skin'];
portChecks(check, NAMES.map(SW), NAMES.map(JS), new Set(['Puget Belle', 'Gus', 'Martha', 'Lars', 'Ida', 'Homer']));

for (const name of NAMES) {
  const sw = hexes(read(SW(name))).sort();
  const js = hexes(read(JS(name))).sort();
  check(JSON.stringify(sw) === JSON.stringify(js), `Klondike${name}: the colours are the app's (${sw.length} and ${js.length}: ${sw.filter((h) => !js.includes(h))} | ${js.filter((h) => !sw.includes(h))})`);
}

/**
 * The numbers in a piece of either source. Comments and the Swift's type names hold no
 * data, nor do a closure's `$0`, a Swift tuple's `.0` or an index's `[0]`; a digit group's
 * `_` is the same number either side.
 */
const nums = (s) => [...s.replace(/\/\/[^\n]*/g, '').replace(/\/\*\*[\s\S]*?\*\//g, '').replace(/UInt32|Int\b/g, '')
  .replace(/radix: 16/g, '').replace(/(?<=\d)_(?=\d)/g, '')
  .replace(/\$\d/g, '').replace(/(?<=[A-Za-z_)\]])\.\d+\b/g, '').replace(/(?<=[A-Za-z_)\]?])\.?\[\d+\]/g, '')
  .matchAll(/-?\d+(\.\d+)?/g)].map((m) => Number(m[0]));
const between = (s, a, b) => {
  const i = s.indexOf(a);
  check(i >= 0, `the marker ${a} is in the source`);
  const j = s.indexOf(b, i + a.length);
  check(j >= 0, `the marker ${JSON.stringify(b)} follows ${a}`);
  return s.slice(i, j);
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
/** Each Swift piece against its JS piece: `[swFrom, swTo, jsFrom, jsTo, jsExtra, swExtra]`. */
function sameNumbers(sw, js, pairs) {
  for (const [a, b, c, d, jsExtra = [], swExtra = []] of pairs) {
    const s = nums(between(sw, a, b)), j = nums(between(js, c, d));
    const ok = without(s, swExtra) === without(j, jsExtra);
    if (!ok) {
      const sl = [...s], jl = [...j];
      for (const n of [...sl]) {
        const k = jl.indexOf(n);
        if (k >= 0) { jl.splice(k, 1); sl.splice(sl.indexOf(n), 1); }
      }
      check(false, `${a}: the numbers are the app's (only in Swift: ${sl.join(' ')} | only in JS: ${jl.join(' ')})`);
    } else {
      check(true, a);
    }
  }
}

/** A Swift `grid([...], width)` of rows, by the name it is given. */
function swiftGrid(sw, name) {
  const from = sw.indexOf(`static let ${name} = `);
  const to = sw.indexOf('], ', from);
  const width = Number(sw.slice(to + 3).match(/^\d+/)[0]);
  const rows = [...sw.slice(from, to).matchAll(/"([^"]*)"/g)].map((m) => m[1]);
  return kScene.grid(rows, width);
}
/** A Swift `[Character: Color]` table, as `{ letter: 'RRGGBB' }`. */
function swiftColors(sw, name) {
  const from = sw.indexOf(`static let ${name}`);
  const to = sw.indexOf(']', sw.indexOf('[', sw.indexOf('=', from)) + 1);
  return Object.fromEntries([...sw.slice(from, to).matchAll(/"(\w)": Color\(hex: 0x([0-9A-F]{6})\)/g)].map((m) => [m[1], m[2]]));
}
const asHex = (c) => [c.r, c.g, c.b].map((x) => x.toString(16).padStart(2, '0')).join('').toUpperCase();

{
  const sw = read(SW('Scene'));
  for (const name of ['steamer', 'party', 'boat']) {
    check(JSON.stringify(swiftGrid(sw, name)) === JSON.stringify(kScene[name]), `the ${name}, row for row`);
  }
  const s7 = sw.slice(sw.indexOf('static let stride7'));
  check(JSON.stringify(kScene.grid([...s7.slice(0, s7.indexOf('\n')).matchAll(/"([^"]*)"/g)].map((m) => m[1]), 31)) === JSON.stringify(kScene.stride7),
    'the party\'s other stride');
  const raft = sw.slice(sw.indexOf('static let raftBoat'), sw.indexOf('static let boatColors'));
  check(/Array\(boat\.prefix\(12\)\)/.test(raft) && JSON.stringify([...kScene.boat.slice(0, 12),
    ...kScene.grid([...raft.matchAll(/"([^"]*)"/g)].map((m) => m[1]), 26)]) === JSON.stringify(kScene.raftBoat), 'the raft: the boat\'s top and a log deck');
  for (const name of ['steamerColors', 'partyColors', 'boatColors']) {
    const want = swiftColors(sw, name);
    const got = Object.fromEntries(Object.entries(kScene[name]).map(([k, c]) => [k, asHex(c)]));
    check(Object.keys(want).length > 7 && JSON.stringify(Object.entries(want).sort()) === JSON.stringify(Object.entries(got).sort()), `${name}: each letter its colour`);
  }
  check(/static let sledColumns = 0\.\.<13/.test(sw) && kScene.sledColumns.lower === 0 && kScene.sledColumns.upper === 13, 'the sled\'s columns');
  check(/static let horizon = 46\.0/.test(sw) && kScene.horizon === 46, 'the horizon');
  check(/static let canyonSpan = \(from: 20\.0, to: 90\.0, ahead: 60\.0\)/.test(sw)
    && JSON.stringify(kScene.canyonSpan) === JSON.stringify({ from: 20, to: 90, ahead: 60 }), 'where Miles Canyon runs');
  // Each sky's palette, field for field.
  const pal = between(sw, 'static func palette', '// MARK: Sprites');
  let skies = 0;
  for (const m of pal.matchAll(/case \.(\w+):\n\s+return Palette\(([^)]*)\)/g)) {
    skies++;
    const f = Object.fromEntries([...m[2].matchAll(/(\w+): (0x[0-9A-F]+|[\d.]+)/g)].map((x) => [x[1], Number(x[2])]));
    const p = kScene.palette({ sky: m[1] });
    const want = { sun: null, clouds: 0, cloud: 0xF4F7FA, rough: 1, haze: 0, ...f };
    check(Object.keys(want).every((k) => p[k] === want[k]) && Object.keys(p).length === Object.keys(want).length,
      `the ${m[1]} sky's palette (${JSON.stringify(want)} | ${JSON.stringify(p)})`);
  }
  check(skies === 10, `ten skies (${skies})`);
  // A pixel of 1849's torn sails.
  check(kScene.torn(3, 2, 10) === ((3 * 7 + 2 * 13) % 37 < 50 / 2.2) && !kScene.torn(3, 2, 60) && /meter < 60 && Double\(\(col \* 7 \+ row \* 13\) % 37\) < \(60 - meter\) \/ 2\.2/.test(sw),
    'torn as 1849\'s sails are');
  const words = [...between(sw, 'static func phrase', 'static func label').matchAll(/case \.(\w+): return "([^"]+)"/g)];
  check(words.length === 10 && words.every(([, sky, s]) => kScene.phrase(sky) === s), 'every sky in a sentence');

  const js = read(JS('Scene'));
  sameNumbers(sw, js, [
    ['// MARK: The coast, from the steamer', '// MARK: The mountains', '// MARK: The coast, from the steamer', '// MARK: The mountains'],
    ['static func mountains', '// MARK: The river', 'function mountains', '// MARK: The river'],
    ['// MARK: The river', '// MARK: Places', '// MARK: The river', '// MARK: Places'],
    // The app's `near` is written out in both `behind` and `front`.
    ['static func behind', '// Small pieces.', 'function behind', '// Small pieces.', [], [230, 230]],
    ['// Small pieces.', '// MARK: The steamer, the party', '// Small pieces.', '// MARK: The steamer, the party'],
    ['// MARK: The steamer, the party', '// MARK: What the weather', '// MARK: The steamer, the party', '// MARK: What the weather'],
    // Swift's `Color(red: 200 / 255, …)` is the JS's `rgb(200, …)`.
    ['// MARK: What the weather', '// MARK: What VoiceOver', '// MARK: What the weather', '// MARK: What VoiceOver', [], [255, 255, 255, 255, 255, 255]],
    // The JS keeps the month the scene is in, March with no voyage, beside the frame.
    ['struct Scene {', '// MARK: The coast', 'function makeScene', '// MARK: The coast', [2]],
  ]);
}

{
  const sw = read(SW('Chart'));
  const table = (name) => [...between(sw, `static let ${name}:`, ']\n').matchAll(/\((-?[\d.]+), (-?[\d.]+)(?:, (-?[\d.]+))?\)/g)]
    .map((m) => m.slice(1).filter((x) => x !== undefined).map(Number));
  for (const name of ['steamer', 'chilkootTrail', 'whitePassTrail', 'river', 'sea', 'island']) {
    const want = table(name);
    check(want.length > 4 && JSON.stringify(want) === JSON.stringify(kChart[name]), `the map's ${name}, point for point (${want.length})`);
  }
  check(/static let lakes: \[ClosedRange<Double>\] = \[1153\.\.\.1179, 1203\.\.\.1235, 1275\.\.\.1305\]/.test(sw)
    && JSON.stringify(kChart.lakes) === '[[1153,1179],[1203,1235],[1275,1305]]', 'the lakes along the way');
  check(/static let box = \(x: 6\.0, y: 134\.0, w: 70\.0, h: 70\.0\)/.test(sw) && JSON.stringify(kChart.box) === '{"x":6,"y":134,"w":70,"h":70}', 'the inset\'s box');
  check(/static let far = \["seattle", "juneau", "selkirk"\]/.test(sw) && kChart.far.join() === 'seattle,juneau,selkirk', 'the towns ringed on the map');
  check(/static let w = 230\.0, h = 210\.0/.test(sw) && kChart.w === 230 && kChart.h === 210, 'the map\'s size');
  check(/routeStep: 30, travelledStep: 10, routeColor: Color\(hex: 0x6D7F92\)/.test(sw), 'the route\'s dots, in the Swift');
  check(kChart.land === 0xB9A26C && kChart.ocean === 0x0D2A44 && kChart.fresh === 0x2F6A96, 'land, sea and fresh water');
  const js = read(JS('Chart'));
  sameNumbers(sw, js, [
    ['static func project', '// MARK: The way', 'export function project', '// MARK: The way'],
    // A Swift tuple's `$0.0` is the JS's destructured `[x, y, m]`.
    ['static func points', 'static let chilkootRoute', 'export function points', 'let made', [], [0, 1, 2]],
    ['static func place', 'static let skin', 'export function place', '// MARK: The country'],
    // The JS walks pairs by index where Swift zips, and reads [lon, lat] where Swift reads `$0.0, $0.1`.
    ['static func dot', '// MARK: Over the top', 'export function dot', '// MARK: Over the top', [], [0, 0, 1, 2, 0, 1]],
    ['// MARK: Over the top', '// MARK: The passes', '// MARK: Over the top', '// MARK: The passes', [], [1]],
    ['static func insetPoint', 'static func inset(', 'export function insetPoint', 'export function inset(', [1, 1, 1]],
    ['static func inset(', '\n}\n', 'export function inset(', '/** The ChartSkin', [1]],
  ]);
}

{
  const sw = read(SW('Forage'));
  check(/static let rod = \(x: 80\.0, y: 28\.0\)/.test(sw) && kForage.rod.x === 80 && kForage.rod.y === 28, 'the rod\'s tip');
  check(/ForageField\(w: 160, h: 200, origin: rod, upward: false, line: 30, lanes: 45\.\.\.188, speed: 150, oneWay: false\)/.test(sw)
    && JSON.stringify(kForage.field) === JSON.stringify({ w: 160, h: 200, origin: { x: 80, y: 28 }, upward: false, line: 30, lanes: [45, 188], speed: 150, oneWay: false }),
  'the field');
  const js = read(JS('Forage'));
  sameNumbers(sw, js, [
    ['static func backdrop', 'static func hook', 'export function backdrop', 'export function hook'],
    ['static func hook', 'static func fish', 'export function hook', 'export function fish'],
    ['static func fish', '\n}\n', 'export function fish', '/** The ForageSkin', [0]],
  ]);
}

{
  const sw = read(SW('Skin'));
  check(/static let routeKey = "klondike\.route", boatKey = "klondike\.boat", breakupKey = "klondike\.breakup"/.test(sw)
    && kSkin.routeKey === 'klondike.route' && kSkin.boatKey === 'klondike.boat' && kSkin.breakupKey === 'klondike.breakup', 'the engine\'s keys');
  check(/static let chilkoot = 1\.0, whitePass = 2\.0/.test(sw) && kSkin.chilkoot === 1 && kSkin.whitePass === 2
    && /static let raft = 4\.0/.test(sw) && kSkin.raft === 4, 'the passes and the raft as the engine keeps them');
  check(/static let usualBreakup = 147/.test(sw) && kSkin.usualBreakup === 147, 'the usual break-up');
  check(/static let trailDays = \[0, 5, 6, 7, 16, 22, 30, 38\]/.test(sw) && kSkin.trailDays.join() === '0,5,6,7,16,22,30,38', 'days on the trail');
  check(/static let riverDates = \[8: 153, 9: 156, 10: 164, 11: 166, 12: 171\]/.test(sw)
    && JSON.stringify(kSkin.riverDates) === '{"8":153,"9":156,"10":164,"11":166,"12":171}', 'days on the river');
  check(kSkin.dayOfYear([1898, 4, 28]) === 147 && kSkin.dayOfYear([1898, 0, 1]) === 0 && kSkin.dayOfYear([1899, 0, 1]) === 365, 'the day of 1898');
  check(kSkin.mileNumber(11365) === '1,136.5' && kSkin.mileNumber(-4) === '0.0' && kSkin.miles(17000) === '1,700.0 miles', 'miles in tenths');
  const js = read(JS('Skin'));
  sameNumbers(sw, js, [
    ['static func trouble', '// MARK: Debug starts', 'export function trouble', '// MARK: Debug starts'],
    ['static func fresh', 'static func settle', 'export function fresh', 'export function settle', [0, 0, 0]],
    ['static func settle', 'static func at(', 'export function settle', 'export function debugStart'],
    ['gallery: [', '])\n', 'gallery: [', '],\n    },'],
  ]);
}

// MARK: - The words, everywhere

const e = await engine();
const flow = new Flow({ engine: e, storage: new MemoryStorage(), timers: new FakeTimers(), random: lcg(5), seed: () => '77',
  journey: 'klondike' });
const J = flow.journey;
const sk = flow.skin;
check(J.id === 'klondike' && sk.id === 'klondike', 'the Klondike, in its own skin');
let screensLooked = 0;

function look(where) {
  const d = describe(flow);
  screensLooked++;
  for (const p of [...wordProblems(d, where), ...klondikeProblems(d, where)]) failures.push(p);
  if (flow.screen.name !== 'picker' && d.banner !== 'TO THE KLONDIKE · 1898') failures.push(`${where}: the banner ${d.banner}`);
  passed += 1;
  return d;
}

/** A fresh trek's state, ready for the skin's debug start. */
function fresh(role = 'merchant', month = 2) {
  e.start({ journey: 'klondike', role, ship: 'Puget Belle', captain: 'Gus', crew: ['Martha', 'Lars', 'Ida', 'Homer'],
    year: 1898, month, seed: '9' });
  return e.save([]);
}

/** A stocked party near a stop, changed by `tweak`, on its menu. */
function partyAt(role, stop, tweak = () => {}, month = 2) {
  const s = fresh(role, month);
  sk.debug.start(s, stop, month);
  s.role = role;
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
  check(!foreign(s), `the title card says no other journey's word: ${s.slice(0, 60)}`);
}

const storm = J.weathers.find((w) => w.sky === 'storm');
const troubles = new Set(), yardRows = new Set(), stopNames = new Set();
const isTown = (st) => J.ports.some((p) => p.id === st.id);
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
        s.graves = [{ name: 'Lars', cause: 'scurvy', date: 'April 9, 1898', epitaph: 'Gone north.' }];
        s.clothes = 1;
        s.noCitrus = 26;
        s.note = 'The grub is low.';
        s.weather = storm;
        s.hull = 12;
        s.sails = 8;
      }],
      ['alone', (s) => {
        for (const p of s.crew.slice(1)) {
          p.alive = false;
          p.hp = 0;
        }
      }],
      ['given out', (s) => { s.sails = 0; }],
      ['no firewood', (s) => { s.water = 0; }],
      ['given out, no firewood', (s) => { s.sails = 0; s.water = 0; }],
      ['on the White Pass', (s) => { if (s.vars[kSkin.routeKey]) s.vars = { ...s.vars, [kSkin.routeKey]: kSkin.whitePass }; }],
    ];
    if (st.type !== 'end') variants.push(['at the stop', (s) => Object.assign(s, { stopIndex: stop, mile: st.mile })]);
    if (isTown(st)) {
      for (const [label, change] of [['in town', {}], ['in town, given out', { sails: 0 }], ['in town, no firewood', { water: 0 }]]) {
        variants.push([label, (s) => Object.assign(s, { stopIndex: stop, mile: st.mile, atPort: true }, change)]);
      }
      if (st.id === 'landing' || st.id === 'camp') {
        variants.push(['in town on the White Pass', (s) => Object.assign(s, { stopIndex: stop, mile: st.mile, atPort: true,
          vars: { ...s.vars, [kSkin.routeKey]: kSkin.whitePass } })]);
      }
    }
    for (const [label, tweak] of variants) {
      const where = `${role} near ${st.short}, ${label}`;
      partyAt(role, stop, tweak);
      const menu = flow.screen.name;
      check(menu === (label.startsWith('in town') ? 'portMenu' : 'seaMenu'), `${where}: on the ${menu}`);
      look(`${where}, ${menu}`);
      const v = flow.v, w = sk.words(v);
      for (const [k, val] of Object.entries(w)) {
        if (typeof val === 'string') check(!BAD.test(val), `${where}: words.${k} = ${val}`);
      }
      if (w.trouble) troubles.add(w.trouble.value);
      yardRows.add(`${w.yard}|${w.yardQuestion}`);
      for (const s2 of J.stops) stopNames.add(w.stopName(s2));
      const bennett = v.state.atPort && st.id === 'bennett' && !v.hooks.klondike.hasBoat;
      check(w.yardQuestion === (bennett ? 'boatChoice' : null) && (w.yard === 'See about a boat') === bennett, `${where}: the yard's row (${w.yard})`);
      check(w.place === (v.state.atPort ? v.port.name : null), `${where}: the place (${w.place})`);
      const fns = [w.distance(11365), ...J.rules.restChoices.map(w.restChoice), w.yardHull(1200), w.yardSails(80),
        w.priceNote(35), w.priceNote(-20), w.burial('Ida'), sk.card.resume('Puget Belle'), sk.card.outfitIntro(v), sk.chart.label(v),
        sk.chart.footer(v), sk.forage.hint('60 lbs'), sk.forage.label(4), sk.forage.pop('1', J.quarry[0]),
        sk.forage.pop('12', J.quarry[J.quarry.length - 1]), w.stopName(J.stops[3])];
      for (const s of fns) {
        check(typeof s === 'string' && s.length && !BAD.test(s), `${where}: ${s}`);
        for (const p of markupProblems(s)) failures.push(`${where}: ${p}`);
        check(!foreign(s), `${where}: no other journey's word in ${s}`);
      }
      for (const name of ['supplies', 'chart', 'pace', 'rations', 'rest', 'repairs', 'shipyard', 'travel']) {
        flow.show({ name });
        look(`${where}, ${name}`);
      }
    }
  }
}
check([...troubles].sort().join('/') === 'No firewood/Oars & sail given out/Oars given out, no firewood/Sleds given out/Sleds given out, no firewood',
  `every kind of trouble in the box (${[...troubles].join('/')})`);
check(yardRows.has('See about a boat|boatChoice') && yardRows.has('Visit the boatwrights|null') && yardRows.has("Visit the outfitters' yard|null"),
  `the yard's three rows (${[...yardRows].join('/')})`);
for (const n of ['Dyea · Skagway', 'Dyea', 'Skagway', 'Sheep Camp', 'White Pass City', 'Chilkoot summit', 'White Pass summit', 'Lindeman', 'Log Cabin']) {
  check(stopNames.has(n) || (n === 'Dyea · Skagway' && [...stopNames].some((x) => x.includes('·'))), `the stops named on the way taken: ${n} (${[...stopNames].join('/')})`);
}

// Seattle: the warning only for a party short of grub that may go (D21).
{
  const at = (change) => {
    const s = fresh('merchant');
    Object.assign(s, change);
    flow.loadForDebug(s);
    return sk.words(flow.v).departWarning;
  };
  const short = at({ food: 4000 });
  check(short?.back === 'Back to the shop' && short.go === 'Leave anyway' && short.text.startsWith('You have [amber]4,000 lbs[/amber] of provisions.'),
    `short of grub, warned (${short?.text})`);
  check(at({ food: 6000 }) === null, 'a year\'s grub for everyone: no warning');
  check(at({ food: 0 }) === null, 'none, with a purse that runs to some: the outfitter\'s refusal, not a warning');
  check(at({ food: 0, money: 10 })?.go === 'Leave anyway', 'none, with no purse for it: warned, and may go (D21)');
}

// Every screen of a trek in each month a party can leave in, with any answer.
for (const d of J.departures) {
  const month = `${['January', 'February', 'March', 'April', 'May'][d.month]} 1898`;
  for (const seed of [2, 8]) {
    const p = await Player.make({ engine: e, journey: 'klondike', seeds: [String(seed)], random: lcg(seed) });
    const rnd = lcg(seed * 13);
    p.setUp({ role: J.roles[seed % 3].label, month });
    const end = p.voyage({
      targets: SAFE.klondike,
      onScreen: (q) => {
        const dd = q.look();
        for (const x of klondikeProblems(dd, q.screen)) failures.push(`${month}, seed ${seed}: ${x}`);
        screensLooked++;
        if (q.screen === 'choice' || q.screen === 'ask') {
          const open = dd.choices.filter((c) => c.enabled);
          open[Math.floor(rnd() * open.length)].act();
        }
        return null;
      },
    });
    check(end === 'finale' || end === 'gameOver', `${month}, seed ${seed}: an ending (${end})`);
    for (const x of p.problems) failures.push(`${month}, seed ${seed}: ${x}`);
  }
}
check(screensLooked > 2000, `every screen looked at (${screensLooked})`);

// MARK: - The drawings

const full = (px) => px.covered === px.pw * px.ph;

/** The engine's view of `s`: its region, date, port and hooks worked out as the app works them. */
function viewOf(s) {
  try {
    return e.load(s, '1', 'klondike').view;
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

// The title card's: the party on the pass.
{
  const px = new BufferCanvas(SCENE_W, SCENE_H);
  sk.scene.draw(px, sceneFrame(J, null, true, 0.4));
  check(full(px) && sk.scene.label(sceneFrame(J, null, true, 0)) === 'A party hauling a loaded sled up a snowy mountain pass', 'the title card\'s scene');
}

// The gallery the app shows for screenshots: each one draws, and shows what it is named for.
const gallery = new Map();
{
  const labels = {};
  for (const g of sk.debug.gallery) {
    const s = fresh('merchant', J.departures[0].month);
    s.atPort = false;
    g.set(s);
    const over = s.over;
    const v0 = viewOf({ ...s, over: false });
    const v = { ...v0, state: { ...v0.state, over } };
    gallery.set(g.name, { v, moving: g.moving });
    const px = new BufferCanvas(SCENE_W, SCENE_H);
    sk.scene.draw(px, sceneFrame(J, v, g.moving, 1.5));
    labels[g.name] = labelOf(v, g.moving, 1.5);
    check(full(px) && !BAD.test(labels[g.name]), `the gallery's ${g.name}`);
  }
  check(sk.debug.gallery.length === 41, `the whole gallery (${sk.debug.gallery.length})`);
  const has = (name, text) => check(labels[name]?.startsWith(text), `${name}: ${labels[name]}`);
  has('Seattle, the waterfront', 'The steamer tied up at Seattle, ');
  has('Leaving Seattle', 'A crowded steamer heading north ');
  has('Juneau', 'The steamer tied up at Juneau, ');
  has('Dyea', 'Your party in camp at Dyea, ');
  has('Skagway', 'Your party in camp at Skagway, ');
  has('Sheep Camp', 'Your party in camp at Sheep Camp, ');
  has('White Pass City', 'Your party in camp at White Pass City, ');
  has('The Golden Stairs', 'Your party hauling sleds ');
  has('Lake Bennett, the ice in', 'Your party in camp at Lake Bennett, ');
  has('Lake Bennett, a boat built', 'Your boat tied up at Lake Bennett, ');
  has('Fort Selkirk', 'Your boat tied up at Fort Selkirk, ');
  has('The upper lakes', 'Your boat on the river ');
  has('Miles Canyon', 'Your boat pulled in to the bank ');
  has('Sleds given out', 'Your party beside sleds that have given out, ');
  has('Oars given out, tied up', 'Your boat tied to the bank with no oars or sail, ');
  has('The outfit ruined', 'Your outfit lies ruined in the snow, ');
  has('Turned back at the summit', 'Your party turning back from the summit, ');
  has('The boat broken up', 'The wreck of your boat going down the river, ');
  // Each place drawn as itself.
  const pics = new Map([...gallery].map(([n, { v, moving }]) => [n, picture(v, moving, 1.5)]));
  check(new Set(pics.values()).size === pics.size, `every cell of the gallery a picture of its own (${new Set(pics.values()).size} of ${pics.size})`);
  check(pics.get('Dyea') !== pics.get('Skagway') && pics.get('Sheep Camp') !== pics.get('White Pass City')
    && pics.get('The Chilkoot summit') !== pics.get('The White Pass summit') && pics.get('Lake Lindeman, frozen') !== pics.get('Log Cabin'),
  'each pass\'s towns its own');
  check(pics.get('A raft') !== picture(withState(gallery.get('A raft').v, { vars: { ...gallery.get('A raft').v.state.vars, [kSkin.boatKey]: 1 } }), true, 1.5),
    'a raft is not a boat');
}

// Every sky over every kind of country, idle and moving, sound and worn.
{
  const places = ['Leaving Seattle', 'Queen Charlotte Sound', 'The British Columbia coast', 'The Alaska coast', 'The Taiya valley',
    'The Skagway valley', 'The Golden Stairs', 'The White Pass summit', 'Lake Lindeman, frozen', 'Log Cabin', 'The upper lakes',
    'The Fifty Mile River', 'Lake Laberge', 'The Yukon in July'];
  const skies = new Set(J.weathers.map((w) => w.sky));
  for (const name of places) {
    const { v } = gallery.get(name);
    const byWeather = new Set(J.weathers.map((w) => picture(withState(v, { weather: w }), true, 0.7)));
    check(byWeather.size >= skies.size - 1, `${name}: each sky its own (${byWeather.size} of ${skies.size})`);
    for (const w of J.weathers) {
      const x = withState(v, { weather: w });
      check(!BAD.test(labelOf(x, true)) && labelOf(x, true).endsWith(kScene.phrase(w.sky)) || labelOf(x, true).includes(kScene.phrase(w.sky)),
        `${name} in ${w.name}: ${labelOf(x, true)}`);
      check(picture(x, true, 0.2) !== picture(x, true, 1.9) || w.sky === 'clear' || w.sky === 'still' || w.sky === 'breeze' || w.sky === 'fog' || w.sky === 'heat',
        `${name} in ${w.name}: moving, it moves`);
    }
    check(picture(withState(v, { hull: 20 }), true, 0.5) !== picture(withState(v, { hull: 80 }), true, 0.5)
      || name.includes('Seattle') || name.includes('coast') || name.includes('Sound'), `${name}: wear shows`);
  }
  // The frozen lake and the open one, at Bennett with a boat.
  const { v } = gallery.get('Lake Bennett, a boat built');
  const open = withState(v, { vars: { ...v.state.vars, [kSkin.breakupKey]: 40 } });
  check(picture(v) !== picture(open), 'Bennett frozen, and Bennett open and full of sails');
  check(kSkin.iceOut(open.state, open.date) && !kSkin.iceOut(v.state, v.date), 'the ice as the engine keeps it');
}

// The map at every stop on both passes and before the fork, and the inset.
{
  const pictures = new Set();
  for (const white of [false, true]) {
    for (let i = 0; i < J.stops.length; i++) {
      const s = fresh();
      kSkin.at(J, s, J.stops[i].id, false, white);
      const v = viewOf(s);
      const px = new BufferCanvas(sk.chart.w, sk.chart.h);
      drawChart(px, sk.chart, J, v, 0);
      check(full(px), `the map at ${J.stops[i].short}${white ? ', White Pass' : ''}`);
      pictures.add(px.picture);
      const label = sk.chart.label(v), footer = sk.chart.footer(v);
      check(/^Map of the route from Seattle to Dawson City\. You are in [A-Za-z& ]+\.$/.test(label) && !/You are in The /.test(label), `the map's label (${label})`);
      check(/^[\d,]+\.\d of 1,700\.0 miles traveled\. [\d,]+\.\d to go\. The ringed stops are towns; the inset is the two passes, where a month's hauling is too short to show\.$/.test(footer),
        `the map's footer (${footer})`);
    }
  }
  check(pictures.size >= J.stops.length + 4, `the map changes with where the party is (${pictures.size})`);
  const before = viewOf(fresh());
  check(sk.chart.others(before).length === 1 && sk.chart.others(viewOf((() => { const s = fresh(); kSkin.at(J, s, 'camp'); return s; })())).length === 0,
    'both ways until the pass is chosen');
  const chilkootInset = kChart.insetPosition(kChart.chilkootTrail, J.stops.find((s) => s.id === 'summit').mile);
  const whiteInset = kChart.insetPosition(kChart.whitePassTrail, J.stops.find((s) => s.id === 'summit').mile);
  check(chilkootInset && whiteInset && (chilkootInset.x !== whiteInset.x || chilkootInset.y !== whiteInset.y), 'each summit in the inset');
  check(kChart.insetPosition(kChart.chilkootTrail, 5000) === null && kChart.insetPosition(kChart.chilkootTrail, 14000) === null,
    'nothing in the inset at sea or down the river');
  const route = kChart.route(before.state);
  const q = routePosition(route, 0, sk.chart);
  check(Math.abs(q.x - (-122.33 + 148) * 8.5) < 1e-9 && Math.abs(q.y - (65 - 47.61) * 11.4) < 1e-9, 'Seattle where the map puts it');
}

// Fishing, frame by frame.
for (const role of J.roles) {
  const { v: v0 } = gallery.get('The Yukon in July');
  const v = { ...v0, state: { ...v0.state, role: role.role, tackle: 200 } };
  const w = sk.words(v);
  const rw = reward(J, w, sk.forage.grouped);
  check(rw.item.key === 'food' && rw.measure(60) === '60 lbs', `a catch is provisions, in pounds (${rw.measure(60)})`);
  let tackle = 200;
  const random = lcg(17);
  const m = new FishingModel({ field: sk.forage.field, quarry: J.quarry, seconds: J.forageSeconds, padding: role.aim,
    pop: popText(sk.forage, rw), random, useTackle: () => tackle-- > 0, tackleLeft: () => tackle });
  const before = tackle;
  m.throwAt(80, 20);
  check(tackle === before && m.harpoon === null, 'a tap on the boat casts nothing');
  m.throwAt(80, 120);
  check(tackle === before - 1 && m.harpoon && m.harpoon.vy > 0, 'a tap on the water casts down');
  const kinds = new Set(), pops = new Set();
  let frames = 0;
  while (!m.ended && frames < 2000) {
    if (frames % 7 === 0) m.aimAtNearest();
    if (frames % 11 === 0) m.throwAt(random() * 160, 50 + random() * 130);
    m.step(1 / 60 + (frames % 3) * 0.02);
    for (const f of m.fish) kinds.add(f.kind.name);
    for (const p of m.pops) pops.add(p.text);
    const px = new BufferCanvas(sk.forage.field.w, sk.forage.field.h);
    try {
      drawFishing(px, sk.forage, m, frames / 60);
    } catch (err) {
      failures.push(`fishing frame ${frames}: ${err.stack}`);
      break;
    }
    if (!full(px)) failures.push(`fishing frame ${frames} leaves pixels bare`);
    frames++;
  }
  passed += 1;
  check(m.ended, `the fishing ends when time is up (${frames} frames)`);
  check(m.caught > 0, `fish are caught (${rw.measure(m.caught)})`);
  check(kinds.size === J.quarry.length, `every kind of fish swims by (${[...kinds].join(', ')})`);
  check([...pops].every((t) => /^\+(1 lb|\d+ lbs) [a-z ]+$/.test(t)), `what the line brings is pounds of fish (${[...pops].slice(0, 4)})`);
}
{
  const kinds = new Map();
  for (const q of J.quarry) {
    const c = new BufferCanvas(40, 30);
    sk.forage.quarry(c, { x: 20, y: 15, vx: 1, t: 0, kind: q });
    const d = new BufferCanvas(40, 30);
    sk.forage.quarry(d, { x: 20, y: 15, vx: -1, t: 0, kind: q });
    check(c.picture !== d.picture, `the ${q.name} faces the way it swims`);
    kinds.set(q.name, c.picture);
  }
  check(new Set(kinds.values()).size === J.quarry.length, `each kind of fish drawn as itself (${J.quarry.map((q) => q.name)})`);
  const px = new BufferCanvas(160, 200);
  sk.forage.backdrop(px, 0.5);
  check(full(px), 'the water below the boat covers its field');
  const later = new BufferCanvas(160, 200);
  sk.forage.backdrop(later, 2.5);
  check(later.picture !== px.picture, 'and its light moves');
  const h = new BufferCanvas(160, 200);
  sk.forage.thrown(h, { x: 90, y: 120, vx: 1, vy: 2 });
  check(h.covered > 3, `the line and the hook (${h.covered})`);
  check(sk.forage.label(3) === 'The water below the boat, with 3 fish swimming' && sk.forage.leave === 'Back to camp', 'what the water shows');
  check(sk.forage.pop('1', J.quarry[0]) === `+1 lb ${J.quarry[0].name}`, `one pound (${sk.forage.pop('1', J.quarry[0])})`);
}

console.log(`klondike-skin: ${passed} checks passed, ${failures.length} failed`);
for (const f of failures.slice(0, 40)) console.log(`FAILED ${f.slice(0, 600)}`);
process.exit(failures.length ? 1 : 0);
