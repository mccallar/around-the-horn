// The Long Transfer's web skin (web/js/journeys/mars-*.js) against the app's (AroundTheHorn/
// Journeys/Mars*.swift) and on its own, as balloon-skin.mjs holds the Jet Stream's:
//
// - the port: every sentence, colour, sprite row, table and plot point of the Swift skin is
//   in the JS, function by function;
// - the words: for every role, near every stop, under way, at the stop and docked, sick,
//   alone, in every kind of trouble (D14), every screen, and every screen of a run in each
//   month with any answer, says nothing undefined, NaN or null, leaves no markup open, and
//   never uses another journey's word;
// - the drawings: the freighter in every weather over every stretch of the arc, idle and
//   burning, sound and worn, full, short and dry; at each stop and docked at each station;
//   on end at Turnover and tail first past it, tumbling, dark, aerobraking; at Jezero; in
//   two pieces and lost in the aerobrake; the gallery; the plot at every stop and every few
//   million km; the grapple frame by frame: each draws into a plain pixel buffer without
//   throwing, covers its canvas, and changes with what it shows.
//
//   node Tools/web-tests/mars-skin.mjs
import { readFileSync } from 'node:fs';
import path from 'node:path';
import { repo } from './lib.mjs';
import { portChecks, hexes } from './port.mjs';
import { Player, engine, lcg, describe, wordProblems, markupProblems, marsProblems, MARS_FOREIGN, FakeTimers } from './player.mjs';
import { Flow, MemoryStorage } from '../../web/js/flow.js';
import { BufferCanvas } from '../../web/js/pixels.js';
import { sceneFrame, drawChart, routePosition, SCENE_W, SCENE_H } from '../../web/js/drawing.js';
import { FishingModel, drawFishing, reward, popText } from '../../web/js/fishing.js';
import * as marsSkin from '../../web/js/journeys/mars-skin.js';
import * as marsScene from '../../web/js/journeys/mars-scene.js';
import * as marsChart from '../../web/js/journeys/mars-chart.js';
import * as marsForage from '../../web/js/journeys/mars-forage.js';

let passed = 0;
const failures = [];
function check(ok, what) {
  if (ok) passed += 1;
  else failures.push(what);
}

const read = (p) => readFileSync(path.join(repo, p), 'utf8');
const BAD = /undefined|NaN|\bnull\b|\[object/;
const FOREIGN = MARS_FOREIGN;

// MARK: - The port

const SW = (n) => `AroundTheHorn/Journeys/Mars${n}.swift`;
const JS = (n) => `web/js/journeys/mars-${n.toLowerCase()}.js`;
const NAMES = ['Scene', 'Chart', 'Forage', 'Skin'];
portChecks(check, NAMES.map(SW), NAMES.map(JS), new Set(['Fair Copy', 'Noor', 'Tomasz', 'Priya', 'Kenji', 'Lucía']));

for (const name of NAMES) {
  const sw = hexes(read(SW(name))).sort();
  const js = hexes(read(JS(name))).sort();
  check(JSON.stringify(sw) === JSON.stringify(js), `Mars${name}: the colours are the app's (${sw.length} and ${js.length})`);
}

/**
 * The numbers in a piece of either source. Comments and the Swift's type names hold no
 * data, nor do a closure's `$0`, a Swift tuple's `.0` or an index's `[0]`; a digit group's
 * `_` is the same number either side.
 */
const nums = (s) => [...s.replace(/\/\/[^\n]*/g, '').replace(/\/\*\*[\s\S]*?\*\//g, '').replace(/UInt32|Int\b/g, '')
  .replace(/radix: 16/g, '').replace(/(?<=\d)_(?=\d)/g, '')
  .replace(/\$\d/g, '').replace(/(?<=[A-Za-z_)\]])\.\d+\b/g, '').replace(/(?<=[A-Za-z_)\]])\[\d+\]/g, '')
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
    check(without(s, swExtra) === without(j, jsExtra), `${a}: the numbers are the app's (${s.length}: ${s.join(' ')} | ${j.length}: ${j.join(' ')})`);
  }
}

/** The freighter, row for row and colour for colour, and where she flies and docks. */
{
  const sw = read(SW('Scene'));
  const from = sw.indexOf('static let ship = [');
  const rows = [...sw.slice(from, sw.indexOf('].map(Array.init)', from)).matchAll(/"([^"]*)"/g)].map((m) => m[1]);
  check(rows.length === 27 && rows.every((r) => r.length === 48) && JSON.stringify(rows) === JSON.stringify(marsScene.ship),
    'the freighter is the app\'s, pixel for pixel, 48 by 27');
  const pairs = [...between(sw, 'static let colors', 'static var shipW').matchAll(/"(\w)": Color\(hex: 0x([0-9A-F]{6})\)/g)];
  check(pairs.length === 14 && pairs.every(([, k, h]) => {
    const c = marsScene.colors[k];
    return c && c.r === parseInt(h.slice(0, 2), 16) && c.g === parseInt(h.slice(2, 4), 16) && c.b === parseInt(h.slice(4), 16);
  }) && Object.keys(marsScene.colors).length === 14, 'each letter its colour');
  check(marsScene.shipW === 48 && marsScene.shipH === 27 && marsScene.flying.x === 80 && marsScene.flying.y === 40
    && marsScene.docked.x === 40 && marsScene.docked.y === 40 && marsScene.driveRow === 13
    && /static let flying = \(x: 80\.0, y: 40\.0\)\n    static let docked = \(x: 40\.0, y: 40\.0\)/.test(sw) && /static let driveRow = 13\n/.test(sw),
  'where she flies and docks, and the drive\'s row');
  check(/enum Facing: Int \{ case ahead, down, astern, up \}/.test(sw) && marsScene.facings.join() === 'ahead,down,astern,up', 'the four ways she points, in order');
  check(/static let captureKey = "mars\.capture"/.test(sw) && marsScene.captureKey === 'mars.capture'
    && /static let heldKey = "mars\.held"/.test(sw) && marsScene.heldKey === 'mars.held', 'the engine\'s two keys');
  const phrases = Object.fromEntries([...between(sw, 'static let phrases', 'static func phrase').matchAll(/"(\w+)": "([^"]+)"/g)]
    .map((m) => [m[1], m[2]]));
  check(JSON.stringify(phrases) === JSON.stringify(marsScene.phrases) && Object.keys(phrases).length === 9, 'every stretch of the arc in a sentence');
  check(/\(\(i &\+ 1\) &\* 2_654_435_761 >> 7\) & 0xFFFFF/.test(sw) && marsScene.scatter(0) === (2654435761 >>> 7) % 0x100000
    && marsScene.scatter(143) === (144 * 20737779) % 0x100000, 'the stars\' scatter, the shift before the multiplication as Swift binds it');
  const js = read(JS('Scene'));
  sameNumbers(sw, js, [
    ['static func place', '/// The engine\'s key', 'export function place', '/**\n * The engine'],
    // The JS's `findIndex` answers -1 where Swift's `firstIndex` answers nil.
    ['static func index', '// MARK: Drawing', 'export function index', '// MARK: Drawing', [0]],
    ['static func wrap', 'static func draw', 'export function wrap', 'export function draw'],
    ['static func draw', '// MARK: Sky', 'export function draw', '// MARK: Sky'],
    ['static func scatter', 'static func stars', 'export function scatter', '/** The same stars'],
    ['static func stars', 'static func disc', 'export function stars', '/**\n * A filled disc'],
    ['static func disc', '/// The Sun\'s size', 'export function disc', '/** The Sun\'s size'],
    ['static func sunRadius', 'static func sun(', 'export function sunRadius', 'export function sun('],
    ['static func sun(', '/// Earth\'s size', 'export function sun(', '/** Earth\'s size'],
    ['static func earthRadius', '/// Earth, its', 'export function earthRadius', '/** Earth, its'],
    ['static func earth(', '/// Mars\'s size', 'export function earth(', '/** Mars\'s size'],
    ['static func marsRadius', 'static func marsCentre', 'export function marsRadius', 'export function marsCentre'],
    ['static func marsCentre', '/// Mars: rust', 'export function marsCentre', '/** Mars: rust'],
    ['static func mars(', '/// What is in the sky', 'export function mars(', '/** What is in the sky'],
    ['static func backdrop', '/// The thin air', 'export function backdrop', '/** The thin air'],
    ['static func limb(', '/// The galaxy', 'export function limb(', '/** The galaxy'],
    ['static func milkyWay', '/// A comet', 'export function milkyWay', '/** A comet'],
    ['static func stream', '/// Near dust', 'export function stream', '/** Near dust'],
    ['static func specks', '// MARK: The freighter', 'export function specks', '// MARK: The freighter'],
    // Swift's `enumerated()` is the JS's count from 0, row and column.
    ['static func freighter', '/// How long', 'export function freighter', '/** How long', [0, 0]],
    ['static func glowLength', 'static func glow(', 'export function glowLength', 'export function glow('],
    ['static func glow(', '/// Small white puffs', 'export function glow(', '/** Small white puffs'],
    ['static func puffs', '/// The glow of the air', 'export function puffs', '/**\n * The glow of the air'],
    ['static func plasma', '/// The ground\'s circle', 'export function plasma', '/** The ground\'s circle'],
    ['static let limbCentre', '/// The rows', 'export const limbCentre', '/**\n * The rows'],
    ['static func limbRows', '/// Mars filling', 'export function limbRows', '/** Mars filling'],
    ['static func limbBelow', '// MARK: Stops', 'export function limbBelow', '// MARK: Stops'],
    ['static func stopScene', '// MARK: Stations', 'export function stopScene', '// MARK: Stations'],
    ['static func dockedScene', '/// Gateway Yard', 'export function dockedScene', '/** Gateway Yard'],
    ['static func gateway', '/// The cycler: an ice', 'export function gateway', '/**\n * The cycler: an ice'],
    ['static func cycler(', '/// Midway Depot', 'export function cycler(', '/** Midway Depot'],
    ['static func midway(', '/// Phobos, a lumpy', 'export function midway(', '/** Phobos, a lumpy'],
    ['static func phobosMoon', '/// Phobos Yard', 'export function phobosMoon', '/** Phobos Yard'],
    ['static func phobosYard', '// MARK: Jezero', 'export function phobosYard', '// MARK: Jezero'],
    // `enumerated()` again, for the three in suits.
    ['static func jezero', '// MARK: The end', 'export function jezero', '// MARK: The end'],
    ['static func wreck', '/// Lost in the aerobrake', 'export function wreck', '/** Lost in the aerobrake', [0, 0]],
    ['static func streak', '// MARK: Space weather', 'export function streak', '// MARK: Space weather'],
    ['static func noise', '/// What the weather', 'export function noise', '/** What the weather'],
    ['static func weather', '/// Particles', 'export function weather', '/** Particles'],
    ['static func hits', '// MARK: VoiceOver', 'export function hits', '// MARK: VoiceOver'],
    ['static func phrase(', 'static func whereabouts', 'export function phrase(', '/** For the plot'],
    ['static func whereabouts', 'static func label', 'export function whereabouts', 'export function label'],
    ['static func label', '\n}\n', 'export function label', '\n}\n']]);
}

/** The plot's numbers: the two orbits, the arc, the cycler's loop, the inset. */
{
  const sw = read(SW('Chart'));
  const js = read(JS('Chart'));
  sameNumbers(sw, js, [
    ['static let w = ', '/// The transfer ellipse', 'export const w = ', '/** The transfer ellipse'],
    ['static let a = ', 'static func radius', 'export const a = ', '/** Distance from'],
    ['static func radius', '/// A point in AU', 'export function radius', '/**\n * A point in AU'],
    ['static func project', '/// The arc,', 'export function project', '/** The arc,'],
    ['static let samples', '/// How far round', 'export const samples', '/** How far round'],
    // Swift's `samples.last` and `zip` with itself are the JS's last index and count from 1.
    ['static func theta', '/// The ship\'s distance', 'export function theta', '/** The ship\'s distance', [1, 1, 1]],
    ['static func au(', '/// The route', 'export function au(', '/**\n * The route'],
    ['static let route', '/// The cycler\'s loop', 'export function route', '/**\n * The cycler\'s loop', [1]],
    ['static let cyclerA', 'static func cyclerPoint', 'export const cyclerA', '/** A point on the cycler'],
    ['static func cyclerPoint', 'static let skin', 'export function cyclerPoint', '/** The ChartSkin'],
    ['static let skin', '// MARK: The inner', 'export function chart(J)', '// MARK: The inner'],
    ['static let space', 'static func dot', 'export const space', 'export function dot'],
    ['static func dot', 'static func background', 'export function dot', '/** The plot\'s sky'],
    ['static func background', '/// The stations ringed', 'export function background', '/**\n * The stations ringed'],
    ['static func marks', '/// The inset\'s box', 'export function marks', '/** The inset\'s box'],
    ['static let box', '/// Where `mile` falls', 'export const box', '/** Where `mile` falls'],
    // `marks.last` and `zip` again.
    ['static func insetX', 'static func inset(', 'export function insetX', 'export function inset(', [1, 1, 1]],
    // `firstIndex` answering nil, and the JS's -1.
    ['static func inset(', '\n}\n', 'export function inset(', '\n}\n', [0]]]);
  check(marsChart.w === 230 && marsChart.h === 200 && marsChart.sun.x === 128 && marsChart.sun.y === 100 && marsChart.scale === 58
    && marsChart.earthAU === 1 && marsChart.marsAU === 1.524 && marsChart.cyclerA === 1.3 && marsChart.cyclerE === 0.24, 'the plot\'s constants');
  check(/let r = \(90 - p\.lat\)/.test(sw) === false && /\(sun\.x \+ scale \* r \* cos\(phi\), sun\.y - scale \* r \* sin\(phi\)\)/.test(sw)
    && /P\(sun\.x \+ scale \* r \* Math\.cos\(phi\), sun\.y - scale \* r \* Math\.sin\(phi\)\)/.test(js), 'and so is the projection');
  const fs = read(SW('Forage')), fj = read(JS('Forage'));
  check(key(nums(between(fs, 'static let launcher', '/// Black sky')))
    === key([...nums(between(fj, 'export const launcher', '/**\n * Black sky')), ...nums(between(fj, 'export function forage', '/** A quarry'))]),
  'the field and the launcher, as the app has them');
  sameNumbers(fs, fj, [
    ['static func backdrop', '/// The grapple\'s head', 'export function backdrop', '/** The grapple\'s head'],
    ['static func grapple', '/// A chunk of ice', 'export function grapple', '/**\n * A chunk of ice'],
    ['static func ice', '\n}\n', 'export function ice', '/** The ForageSkin']]);
  const ss = read(SW('Skin')), sj = read(JS('Skin'));
  sameNumbers(ss, sj, [
    ['static let contractDays', '/// Units of', 'export const contractDays', '/** Units of'],
    ['static func millions', '/// "312.45', 'export function millions', '/** "312.45'],
    ['static func days', '/// A number to a tenth', 'export const days', '/** Swift\'s'],
    ['static func tenth', 'static let card', 'export function tenth', 'export const card'],
    ['static let card', '/// The ship\'s plight', 'export const card', '/**\n * The ship\'s plight'],
    ['static func trouble', '/// After the thrust', 'export function trouble', '/** After the thrust'],
    ['static func coast', '/// The contract row', 'export function coast', '/**\n * The contract row'],
    ['static func contract', 'static func words', 'export function contract', '/** What things are called'],
    // The title's first letter: Swift's `first`, the JS's length and `[0]`.
    ['static func words', 'static let debug', 'export function words', '/**\n * For tests and screenshots', [0]],
    ['static func fly', 'static func at(', 'export function fly', '/** Standing at'],
    ['static func at(', '\n}', 'export function at(', '/** How she was caught']]);
  check(key(nums(between(ss, 'static let debug', '/// Under way at'))) === key([...nums(between(sj, 'export function debugStart', '/** Under way at')),
    ...nums(between(sj, 'gallery: [', '],\n    },'))]), 'the debug start and the gallery');
  check(marsSkin.contractDays === 170 && marsSkin.bonusPerDay === 25, 'the contract\'s figures');
}

// MARK: - The words, everywhere

const e = await engine();
const flow = new Flow({ engine: e, storage: new MemoryStorage(), timers: new FakeTimers(), random: lcg(5), seed: () => '77',
  journey: 'mars' });
const J = flow.journey;
const sk = flow.skin;
check(J.id === 'mars' && sk.id === 'mars', 'the Long Transfer, in its own skin');
let screensLooked = 0;

function look(where) {
  const d = describe(flow);
  screensLooked++;
  for (const p of [...wordProblems(d, where), ...marsProblems(d, where)]) failures.push(p);
  if (flow.screen.name !== 'picker' && d.banner !== 'THE LONG TRANSFER · 2087') failures.push(`${where}: the banner ${d.banner}`);
  passed += 1;
  return d;
}

/** A fresh transfer's state, ready for the skin's debug start. */
function fresh(role = 'merchant', month = 9) {
  const dep = J.departures.find((d) => d.month === month) ?? J.departures[0];
  e.start({ journey: 'mars', role, ship: 'Fair Copy', captain: 'Noor', crew: ['Tomasz', 'Priya', 'Kenji', 'Lucía'],
    year: dep.year, month: dep.month, seed: '9' });
  return e.save([]);
}

/** A stocked freighter near a stop, changed by `tweak`, on its menu. */
function shipAt(role, stop, tweak = () => {}, month = 9) {
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
const isStation = (st) => J.ports.some((p) => p.id === st.id);
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
        s.graves = [{ name: 'Priya', cause: 'decompression', date: 'November 9, 2087', epitaph: 'Clear skies.' }];
        s.clothes = 1;
        s.noCitrus = 16;
        s.note = 'The tanks are low.';
        s.weather = storm;
        s.hull = 12;
        s.sails = 8;
        s.fuel = 5;
      }],
      ['alone', (s) => {
        for (const p of s.crew.slice(1)) {
          p.alive = false;
          p.hp = 0;
        }
      }],
      ['array dark', (s) => { s.sails = 0.4; }],
      ['tanks dry', (s) => { s.fuel = 0; }],
      ['dark and dry', (s) => { s.sails = 0; s.fuel = 0; }],
      ['the last of the propellant', (s) => { s.fuel = 3; }],
      ['late', (s) => { s.day = 190; }],
    ];
    if (st.type !== 'end') variants.push(['at the stop', (s) => Object.assign(s, { stopIndex: stop, mile: st.mile })]);
    if (isStation(st)) {
      for (const [label, change] of [['docked', {}], ['docked, array dark', { sails: 0 }], ['docked, tanks dry', { fuel: 0 }]]) {
        variants.push([label, (s) => Object.assign(s, { stopIndex: stop, mile: st.mile, atPort: true, day: Math.max(1, s.day) }, change)]);
      }
    }
    for (const [label, tweak] of variants) {
      const where = `${role} near ${st.short}, ${label}`;
      shipAt(role, stop, tweak);
      const menu = flow.screen.name;
      check(menu === (label.startsWith('docked') ? 'portMenu' : 'seaMenu'), `${where}: on the ${menu}`);
      look(`${where}, ${menu}`);
      const w = sk.words(flow.v);
      for (const [k, val] of Object.entries(w)) {
        if (typeof val === 'string') check(!BAD.test(val), `${where}: words.${k} = ${val}`);
      }
      if (w.trouble) troubles.add(w.trouble.value);
      const fns = [w.distance(1234), ...J.rules.restChoices.map(w.restChoice), w.yardHull(1200), w.yardSails(80),
        w.priceNote(35), w.priceNote(-20), w.burial('Kenji'), sk.card.resume('Fair Copy'), sk.card.outfitIntro(flow.v), sk.chart.label(flow.v),
        sk.chart.footer(flow.v), sk.forage.hint('60 litres'), sk.forage.label(4), sk.forage.pop('1', J.quarry[0]),
        sk.forage.pop('12', J.quarry[4]), w.clock.value];
      for (const s of fns) {
        check(typeof s === 'string' && s.length && !BAD.test(s), `${where}: ${s}`);
        for (const p of markupProblems(s)) failures.push(`${where}: ${p}`);
      }
      for (const name of ['supplies', 'chart', 'pace', 'rations', 'rest', 'repairs', 'shipyard', 'travel']) {
        flow.show({ name });
        look(`${where}, ${name}`);
      }
      flow.backToMenu();
      if (!label.startsWith('docked')) {
        flow.goFishing();
        look(`${where}, ${flow.screen.name === 'fishing' ? 'the grapple' : 'no grapple'}`);
        flow.backToMenu();
      } else {
        flow.leavePort();
        look(`${where}, undocking`);
        flow.stopTravel?.();
        shipAt(role, stop, tweak);
      }
      flow.showShop(() => flow.backToMenu());
      look(`${where}, stores`);
      flow.show({ name: 'burial', crewID: flow.game.crew[0].id, cause: 'decompression' });
      look(`${where}, burial`);
      flow.show({ name: 'gameOver', title: 'The hull lets go.', body: 'A tug brings home what is left.' });
      look(`${where}, game over`);
      flow.show({ name: 'finale', finale: { score: { lines: [{ label: 'Propellant, rations & water', points: 300 }],
        subtotal: 300, multiplier: 3, total: 900 }, rank: 'Groundling', place: stop % 2 ? 3 : null } });
      look(`${where}, finale`);
    }
  }
}
check(screensLooked > 3000, `looked at every screen everywhere (${screensLooked})`);
check(['Array dark', 'Array dark, coasting', 'Array dark, tanks dry', 'Tanks dry', 'Tanks dry, coasting', 'Last of the propellant']
  .every((t) => troubles.has(t)), `every plight in the status box (${[...troubles]})`);

// The words that change with the state, as the app writes them.
{
  shipAt('shipwright', 5);
  const g = flow.game;
  /** The skin's words for `g` changed by `tweak`, with the engine's hooks for it. */
  const w = (tweak) => {
    const state = { ...g, ...tweak };
    return sk.words({ ...flow.v, state, hooks: e.hooks(state) });
  };
  const mid = J.stops.findIndex((s) => s.id === 'midway'), cyc = J.stops.findIndex((s) => s.id === 'cycler');
  const docked = (t = {}) => w({ stopIndex: mid, mile: J.stops[mid].mile, atPort: true, ...t });
  check(marsSkin.millions(31245) === '312.45' && marsSkin.millions(48000) === '480.00' && marsSkin.millions(7) === '0.07'
    && marsSkin.millions(-1234) === '-12.34' && marsSkin.millions(123456) === '1,234.56' && marsSkin.km(15500) === '155.00 million km',
  'millions of km to the hundredth');
  check(marsSkin.days(1) === '1 day' && marsSkin.days(3) === '3 days' && marsSkin.tenth(2.5) === '2.5' && marsSkin.tenth(4) === '4'
    && marsSkin.tenth(1.25) === '1.3' && marsSkin.tenth(3.96) === '4', 'days, and a tenth without a trailing .0');
  check(marsSkin.contract({ day: 0 }) === '170 days in hand' && marsSkin.contract({ day: 169 }) === '1 day in hand'
    && marsSkin.contract({ day: 170 }) === 'late' && marsSkin.contract({ day: 171 }) === '1 day late' && marsSkin.contract({ day: 175 }) === '5 days late',
  'the contract row, in hand and late');
  check(w({}).clock.label === 'Contract' && w({ day: 100 }).clock.value === '70 days in hand', 'the contract in the box');
  check(w({}).trouble === null && w({ fuel: 3 }).trouble.value === 'Last of the propellant'
    && w({ fuel: 0 }).trouble.value === 'Tanks dry, coasting' && docked({ fuel: 0 }).trouble.value === 'Tanks dry'
    && w({ sails: 0.4 }).trouble.value === 'Array dark, coasting' && docked({ sails: 0.4 }).trouble.value === 'Array dark'
    && w({ sails: 0, fuel: 0 }).trouble.value === 'Array dark, tanks dry' && docked({ sails: 0, fuel: 0 }).trouble.value === 'Array dark, tanks dry'
    && w({ sails: 0.6 }).trouble === null && w({ fuel: 0, day: 0 }).trouble === null && w({ sails: 0, day: 0 }).trouble === null
    && w({ fuel: 0 }).trouble.label === 'Ship' && w({ pace: 'full', fuel: 12 }).trouble.value === 'Last of the propellant'
    && w({ pace: 'easy', fuel: 8 }).trouble === null, 'the ship\'s plight, as the engine judges a meter at 0% and a day\'s burn');
  check(w({ noCitrus: 16, fuel: 0, sails: 0 }).suppliesNote
    === 'Thrust: Cruise · Rations: Full · [red]16 days without supplements[/red] · [red]the array is dark[/red] · [red]the tanks are dry[/red]'
    && w({ noCitrus: 15 }).suppliesNote === 'Thrust: Cruise · Rations: Full' && w({ fuel: 0, day: 0 }).suppliesNote === 'Thrust: Cruise · Rations: Full',
  `the supplies note, from half the deficiency's days (${w({ noCitrus: 16 }).suppliesNote})`);
  check(w({}).paceNow === 'The drive is set for [amber]Cruise[/amber].'
    && w({ sails: 0 }).paceNow === 'The drive is set for [amber]Cruise[/amber]. [red]The array is dark: she is only coasting.[/red]'
    && w({ fuel: 0 }).paceNow === 'The drive is set for [amber]Cruise[/amber]. [red]The tanks are dry: she is only coasting.[/red]'
    && docked({ fuel: 0 }).paceNow.endsWith(' [red]The tanks are dry: once she undocks, she will only coast.[/red]')
    && w({ sails: 0, fuel: 0 }).paceNow.includes('The array is dark:'), 'the thrust screen');
  check(w({}).repairsNote === 'Each repair takes a day. As a yard rigger, your repairs go much further.'
    && w({ role: 'merchant' }).repairsNote === 'Each repair takes a day.', 'the rigger\'s repairs');
  check(w({}).bonus === 'Bonus for being a yard rigger' && w({ role: 'merchant' }).bonus === 'Bonus for being a charter captain'
    && w({ role: 'whaler' }).bonus === 'Bonus for being an ice hauler', 'the bonus, and an ice hauler');
  check(w({ clothes: 2 }).clothesWarning === '[red]Only 2 of 5 aboard have a thermal suit.[/red]' && w({ clothes: 5 }).clothesWarning === null,
    'thermal suits');
  check(w({}).rationsNow === 'The crew is on [amber]Full[/amber]. With 5 aboard, that\'s 4 kg a day.'
    && w({ rations: J.rations[2].rations, crew: g.crew.map((p, i) => ({ ...p, alive: i < 3 })) }).rationsNow
      === `The crew is on [amber]${J.rations[2].name}[/amber]. With 3 aboard, that's ${marsSkin.tenth(3 * J.rations[2].amount)} kg a day.`,
  `a day's rations (${w({}).rationsNow})`);
  check(docked().restPrompt.startsWith('The station has bunks with curtains') && w({}).restPrompt.startsWith('You idle the drive'),
    'resting aboard the station and under way');
  check(w({}).restChoice(1) === '1 day' && w({}).restChoice(5) === '5 days', 'rest a day or days');
  check(w({}).priceNote(30) === 'Prices here run about 30% above Gateway Yard\'s, give or take what is scarce.'
    && w({}).priceNote(-20) === 'Prices here run about 20% below Gateway Yard\'s, give or take what is scarce.', 'prices against Gateway\'s');
  check(w({}).yardHull(1234) === 'Reseal the pressure hull — $1,234' && w({}).yardSails(80) === 'New panels and a rebuilt thruster grid — $80',
    'the yard crew\'s prices');
  check(w({}).burial('Kenji') === 'The crew gathers at the lock for Kenji. What words will you say?' && w({}).commit === 'Say a few words', 'a burial');
  check(docked().place === 'Docked at Midway' && w({ stopIndex: cyc, mile: J.stops[cyc].mile, atPort: true }).place === 'Aboard the Perpetua'
    && w({}).place === null && w({ stopIndex: mid, mile: J.stops[mid].mile }).place === null, 'the station in the status box');
  const gate = (t) => w({ stopIndex: 0, mile: 0, day: 0, atPort: true, ...t });
  check(gate({ fuel: 0 }).departRefusal.startsWith("Gateway's traffic office won't clear a ship to leave the yard with her tanks empty.")
    && gate({ fuel: 0, money: 3.6 }).departRefusal === null && gate({ fuel: 0, money: 3.7 }).departRefusal !== null
    && gate({ fuel: 5 }).departRefusal === null && w({}).departWarning === null && w({}).resumesInFirstShop === true && w({}).leaveRefusal === null,
  'Gateway refuses empty tanks while the purse runs to five tonnes (D18, D19)');
  const a1 = w({ day: 150 }), a2 = w({ day: 180, crew: g.crew.map((p, i) => ({ ...p, alive: i === 0 })) });
  check(a1.arrival === `Jezero Landing! The [i]Fair Copy[/i] sets her cargo down on ${flow.v.dateText}, 150 days out of Gateway Yard.`
    && a1.arrivalBody.startsWith('The contract allowed 170 days, and you have 20 days in hand.') && a1.arrivalBody.endsWith('more than four minutes.'),
  `the landing in hand (${a1.arrival})`);
  check(a2.arrivalBody === 'The contract date is behind you, and so is the bonus. The settlement turns out in suits all the same, and nobody mentions the date. You walk down the ramp alone, and stand a while under a sky the colour of weak tea.',
    `late and alone (${a2.arrivalBody})`);
  check(w({ ship: 'A [b] ship' }).arrival.includes('The [i]A [[b] ship[/i]'), 'the ship\'s name escaped in the landing');
  check(w({}).gameOverLine === `${flow.v.dateText} · ${marsSkin.km(g.mile)} out from Gateway Yard.`, `the end of the transfer (${w({}).gameOverLine})`);
}

/** Runs in every month, each role, answering anything: every screen of the transfer's own text. */
{
  let runs = 0, screens = 0;
  const endings = new Set(), keys = new Set();
  for (const [i, month] of ['August 2087', 'September 2087', 'October 2087', 'November 2087', 'December 2087'].entries()) {
    for (const [k, role] of J.roles.entries()) {
      const seed = 100 + i * 7 + k;
      const p = await Player.make({ engine: e, seeds: [String(seed)], random: lcg(seed), journey: 'mars' });
      const look0 = p.look.bind(p);
      p.look = () => {
        const d = look0();
        screens++;
        p.problems.push(...marsProblems(d, p.screen));
        return d;
      };
      const pick = lcg(seed * 3);
      p.setUp({ role: role.label, month });
      const end = p.voyage({
        layOver: k === 2 ? 1 : 0,
        onScreen: (q) => {
          // Any answer that is offered, not only the careful first one; but the careful
          // player docks at every station, to buy what it needs to get anywhere at all.
          if (q.screen !== 'choice' || 'portArrival' in q.f.screen.event.kind) return null;
          const key = q.f.screen.event.kind?.custom?.key;
          if (key === 'cycler') return null;
          const open = q.look().choices.filter((c) => c.enabled);
          const c = open[Math.floor(pick() * open.length)];
          if (key) keys.add(key);
          c.act();
          return null;
        },
      });
      runs++;
      endings.add(end);
      check(end === 'finale' || end === 'gameOver', `${role.title} launching in ${month}: the transfer ends (${end})`);
      for (const pr of p.problems.slice(0, 5)) failures.push(`${role.title} in ${month}: ${pr}`);
    }
  }
  check(runs === 15 && screens > 2000, `fifteen runs, every screen read (${screens})`);
  check(endings.has('finale'), `transfers that land (${[...endings]})`);
  check(['turnover', 'capture'].every((x) => keys.has(x)), `the set pieces answered any way (${[...keys]})`);
}

// MARK: - The drawings

/** A canvas every pixel of which has something on it. */
const full = (px) => px.covered === px.pw * px.ph;

/** The engine's view of `s`: its region, date and hooks worked out as the app works them. */
function viewOf(s) {
  try {
    return e.load(s, '1', 'mars').view;
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
const idx = (id) => J.stops.findIndex((s) => s.id === id);

const base = fresh();
sk.debug.start(base, 3);
/** A view in each stretch of the arc, keyed by region id. */
const regionViews = new Map();
for (const [i, reg] of J.regions.entries()) {
  const from = i === 0 ? 0 : J.regions[i - 1].to, to = Math.min(reg.to ?? J.totalMiles, J.totalMiles);
  let mile = Math.floor((from + to) / 2);
  if (J.stops.some((st) => st.mile === mile)) mile += 7;
  const stopIndex = Math.max(0, J.stops.findLastIndex((st) => st.mile < mile));
  const v = viewOf({ ...base, mile, stopIndex, day: Math.max(1, Math.trunc(mile / 330)) });
  check(v.region.id === reg.id, `${reg.id}: mile ${mile} is in it (${v.region.id})`);
  regionViews.set(reg.id, v);
}
check(regionViews.size === 9, `nine stretches of the arc (${regionViews.size})`);

const wear = [[100, 100, 600], [45, 30, 300], [20, 10, 5], [0.3, 0.2, 0]];
const pictures = new Map();
let drawn = 0, turn = 0;
for (const weather of J.weathers) {
  for (const [id, v0] of regionViews) {
    for (const moving of [false, true]) {
      const t = moving ? [0.37, 5.3, 1000.1][turn++ % 3] : 0;
      for (const [k, [hull, sails, fuel]] of wear.entries()) {
        for (const pace of moving ? J.paces.map((p) => p.pace) : [v0.state.pace]) {
          const v = withState(v0, { weather, hull, sails, fuel, pace });
          const px = new BufferCanvas(SCENE_W, SCENE_H);
          const f = sceneFrame(J, v, moving, t);
          try {
            sk.scene.draw(px, f);
          } catch (err) {
            failures.push(`scene, ${weather.name} in ${id}: ${err.stack}`);
            continue;
          }
          drawn++;
          if (!full(px)) failures.push(`scene, ${weather.name} in ${id}: ${px.covered} of ${px.pw * px.ph} pixels`);
          if (!moving) pictures.set(`${weather.rawValue}|${id}|${k}`, px.picture);
          const label = sk.scene.label(f);
          if (!label || BAD.test(label) || FOREIGN.test(label)) failures.push(`scene label: ${label}`);
        }
      }
    }
  }
}
check(drawn === J.weathers.length * 9 * 4 * (1 + J.paces.length), `the freighter drawn everywhere (${drawn})`);
{
  const quiet = J.fairWeather;
  const sky = `Weather: ${quiet.name.toLowerCase()}`;
  const regions = [...regionViews.keys()];
  const fair = (id) => withState(regionViews.get(id), { weather: quiet });
  check(new Set(regions.map((id) => picture(fair(id)))).size === regions.length, 'each stretch of the arc draws its own sky');
  check(new Set(J.weathers.map((w) => picture(withState(fair('inner'), { weather: w })))).size === J.weathers.length,
    `each kind of space weather draws its own picture (${J.weathers.map((w) => w.sky)})`);
  check(new Set([0, 1, 2, 3].map((k) => pictures.get(`quiet|deep|${k}`))).size === 4, 'wear, panels gone and dents show');
  const v = fair('inner');
  check(labelOf(v, true) === `The freighter burning on the inner arc. ${sky}` && labelOf(v) === `The freighter on the inner arc, her drive idle. ${sky}`,
    `burning and idle (${labelOf(v, true)})`);
  check(picture(v, true, 1) !== picture(v, true, 1.5), 'the dust goes by under way');
  check(picture(v, true, 0.1) !== picture(v, false, 0.1), 'the drive glows when she burns');
  check(new Set(J.paces.map((p) => picture(withState(v, { pace: p.pace }), true, 0.2))).size === J.paces.length, 'longer the harder she burns');
  check(picture(withState(v, { sails: 0.4 }), true, 0.2) === picture(withState(v, { sails: 0.4, pace: 'full' }), true, 0.2)
    && picture(withState(v, { sails: 0.4 }), true, 0.2) !== picture(withState(v, { sails: 0.6 }), true, 0.2), 'dark, no glow at any thrust, the wings dark');
  check(picture(withState(v, { hull: 34 }), false, 0.2) !== picture(withState(v, { hull: 36 }), false, 0.2), 'a tired hull leaks below 35%');
  const dry = withState(v, { fuel: 0 });
  check(picture(dry, true, 0) !== picture(dry, true, 1.7) && labelOf(dry, true) === `The freighter tumbling slowly, her tanks dry, on the inner arc. ${sky}`,
    `dry, she tumbles (${labelOf(dry, true)})`);
  check(labelOf(withState(v, { sails: 0 }), true) === `The freighter coasting with her array dark, on the inner arc. ${sky}`
    && labelOf(withState(v, { sails: 0, fuel: 0 }), true) === `The freighter tumbling slowly, her tanks dry, on the inner arc, her array dark. ${sky}`,
  'dark, and dark and dry');
  const deep = fair('deep');
  check(labelOf(deep, true) === `The freighter braking tail first in deep space. ${sky}` && picture(deep) !== picture(withState(deep, { stopIndex: idx('turnover') - 1 })),
    `tail first past Turnover (${labelOf(deep, true)})`);
  const capture = fair('capture');
  const aero = withState(capture, { vars: { ...capture.state.vars, 'mars.capture': 1 } });
  check(labelOf(aero, true) === `The freighter skimming the top of the Martian air, glowing. ${sky}` && picture(aero, true, 0.5) !== picture(capture, true, 0.5),
    `aerobraking (${labelOf(aero, true)})`);
  check(labelOf(withState(capture, { vars: { ...capture.state.vars, 'mars.capture': 2 } }), true) === `The freighter braking tail first close to Mars. ${sky}`,
    'burning into orbit');

  // The title card: no transfer yet.
  const title = new BufferCanvas(SCENE_W, SCENE_H);
  sk.scene.draw(title, sceneFrame(J, null, false, 0));
  check(full(title) && sk.scene.label(sceneFrame(J, null, false, 0)) === 'A transfer freighter burning out from Earth, her solar wings spread',
    'the title card\'s freighter');
  const big = new BufferCanvas(SCENE_W, SCENE_H, 3);
  sk.scene.draw(big, sceneFrame(J, v, true, 2.5));
  check(full(big), 'the scene at three device pixels a pixel still covers its canvas');
}

// The stops, the stations, Turnover, Jezero, and the end of her.
{
  const quiet = J.fairWeather;
  const sky = `Weather: ${quiet.name.toLowerCase()}`;
  const at = (i, change = {}) => viewOf({ ...base, stopIndex: i, mile: J.stops[i].mile, day: Math.max(1, Math.trunc(J.stops[i].mile / 330)),
    weather: quiet, fuel: 600, ...change });
  const stopLabel = (id, change = {}) => labelOf(at(idx(id), change));
  check(stopLabel('lunar') === `The freighter passing the Moon, close enough to see its craters. ${sky}`
    && stopLabel('hill') === `The freighter crossing the edge of Earth's reach, Earth and the Moon behind her. ${sky}`
    && stopLabel('cycler') === `The freighter coming up on the cycler Perpetua, lit like a town at night. ${sky}`
    && stopLabel('turnover') === `The freighter standing on end at Turnover, halfway through turning round. ${sky}`
    && stopLabel('midway') === `The freighter coming up on Midway Depot's three tanks. ${sky}`
    && stopLabel('shadow') === `The freighter entering the conjunction shadow, Earth sliding behind the Sun. ${sky}`
    && stopLabel('approach') === `The freighter on the approach, Mars and its two moons ahead. ${sky}`
    && stopLabel('phobos') === `The freighter coming up on Phobos, Mars filling half the sky. ${sky}`, 'each stop as itself');
  check(stopLabel('turnover', { sails: 0, vars: { ...base.vars, 'mars.held': idx('turnover') } }) === `The freighter, coasting with her array dark, at Turnover, waiting for the power to turn round. ${sky}`
    && stopLabel('cycler', { fuel: 0 }) === `The freighter, tumbling slowly, her tanks dry, coming up on the cycler Perpetua, lit like a town at night. ${sky}`,
  'at a stop in trouble');
  for (const [i, st] of J.stops.entries()) {
    if (i === 0 || st.type === 'end') continue;
    const v = at(i);
    check(picture(v) !== picture(at(i, { mile: st.mile - 30 })), `${st.short} is its own picture`);
  }
  const turnover = at(idx('turnover'));
  check(picture(turnover, false, 0) !== picture(turnover, false, 0.5), 'the thrusters puff as she turns end for end');
  check(picture(turnover) !== picture(at(idx('turnover'), { vars: { ...base.vars, 'mars.held': idx('turnover') } })), 'waiting for power, she does not turn');
  const labels = {
    gateway: "The freighter docked at Gateway Yard, Earth's blue curve below", cycler: 'The freighter docked alongside the cycler Perpetua, her wheel turning',
    midway: 'The freighter docked at Midway Depot, beside its three tanks', phobos: 'The freighter docked at Phobos Yard, Mars overhead' };
  const docks = new Set();
  for (const p of J.ports) {
    const i = idx(p.id);
    const v = at(i, { atPort: true, day: Math.max(1, Math.trunc(J.stops[i].mile / 330)) });
    check(labelOf(v) === labels[p.id] && labelOf(withState(v, { sails: 0 })) === `${labels[p.id]}, her array dark`, `docked at ${p.name} (${labelOf(v)})`);
    docks.add(picture(v));
    if (i > 0) check(picture(v) !== picture(at(i)), `docked at ${p.name} and coming up on it are two pictures`);
  }
  check(docks.size === 4, 'each station drawn as itself');
  const gate = viewOf({ ...base, stopIndex: 0, mile: 0, day: 0, atPort: true });
  check(labelOf(gate) === labels.gateway && picture(gate, false, 0) !== picture(gate, false, 0.6), 'Gateway\'s work lights blink');

  const jezero = withState(at(idx('jezero') - 1, { mile: J.stops[idx('jezero')].mile - 5 }), { stopIndex: idx('jezero'), mile: J.stops[idx('jezero')].mile, atPort: true });
  check(labelOf(jezero) === "The cargo lander on the pad at Jezero Landing, the settlement's domes beyond and the crater rim on the horizon"
    && picture(jezero, false, 0) !== picture(jezero, false, 3), 'the pad at Jezero, the freighter a moving star');
  check(sk.chart.label(jezero).endsWith('You are at Jezero Landing.'), 'and the plot says so');
  // The end of her: the engine won't load a transfer that is over, so it is the view of the day before.
  const lost = (mile, change = {}) => withState(viewOf({ ...base, stopIndex: Math.max(0, J.stops.findLastIndex((st) => st.mile < mile)), mile, day: 60,
    hull: 5, weather: quiet, ...change }), { hull: 0, over: true });
  const apart = lost(20000), aero = lost(46800, { vars: { ...base.vars, 'mars.capture': 1 } });
  check(labelOf(apart) === 'The freighter in two pieces, drifting apart among her own debris. The pressure hull has let go'
    && picture(apart, false, 0) !== picture(apart, false, 4), 'in two pieces, drifting apart');
  check(labelOf(aero) === 'A short bright line across the top of the Martian sky, where the freighter was'
    && picture(aero, false, 0) !== picture(aero, false, 1) && picture(aero) !== picture(apart), 'lost in the aerobrake');
}

// The gallery the app shows for screenshots (SceneGallery.swift `state`: a fresh transfer in
// the first month she can launch in, not docked, and then the cell's own changes): each one
// draws, and shows what it is named for.
{
  const labels = {};
  for (const g of sk.debug.gallery) {
    const s = fresh('merchant', J.departures[0].month);
    s.atPort = false;
    g.set(s);
    const over = s.over;
    const v = withState(viewOf({ ...s, over: false }), { over });
    const px = new BufferCanvas(SCENE_W, SCENE_H);
    sk.scene.draw(px, sceneFrame(J, v, g.moving, 1.5));
    labels[g.name] = labelOf(v, g.moving, 1.5);
    check(full(px) && !BAD.test(labels[g.name]), `the gallery's ${g.name}`);
  }
  check(sk.debug.gallery.length === 28, 'the whole gallery');
  const has = (name, text) => check(labels[name]?.includes(text), `${name}: ${labels[name]}`);
  has('Gateway Yard', 'docked at Gateway Yard');
  has('Lunar distance', 'passing the Moon');
  has("Earth's reach", "crossing the edge of Earth's reach");
  has('The Perpetua, docked', 'docked alongside the cycler Perpetua');
  has('The Perpetua, passing', 'coming up on the cycler Perpetua');
  has('Turnover', 'standing on end at Turnover');
  has('Midway Depot', 'docked at Midway Depot');
  has('Conjunction shadow', 'entering the conjunction shadow');
  has('Mars approach', 'on the approach, Mars and its two moons ahead');
  has('Phobos Yard', 'docked at Phobos Yard');
  has('Jezero Landing', 'The cargo lander on the pad at Jezero Landing');
  has('Cislunar space', 'burning in cislunar space');
  has('First ice stream', 'in the first ice stream');
  has('Deep space, braking', 'braking tail first in deep space');
  has('Second ice stream', 'in the second ice stream');
  has('Aerobraking', 'skimming the top of the Martian air');
  has('Burning into orbit', 'braking tail first close to Mars');
  has('Array dark', 'coasting with her array dark');
  has('Tanks dry, tumbling', 'tumbling slowly, her tanks dry');
  has('The hull lets go', 'The freighter in two pieces');
  has('Lost aerobraking', 'A short bright line across the top of the Martian sky');
}

// The plot.
{
  const seen = new Set();
  const route = sk.chart.route();
  check(route.length === 91 && route[0].mile === 0 && route[route.length - 1].mile === J.totalMiles
    && route.every((p, i) => i === 0 || p.mile > route[i - 1].mile), 'a point every two degrees round, from Gateway to Jezero');
  check(marsChart.theta(J, 0) === 0 && Math.abs(marsChart.theta(J, J.totalMiles) - Math.PI) < 1e-12
    && Math.abs(marsChart.au(J, 0) - 1) < 1e-12 && Math.abs(marsChart.au(J, J.totalMiles) - 1.524) < 1e-12, 'from Earth\'s orbit to Mars\'s');
  const turn = marsChart.cyclerTurn(J);
  const th = marsChart.theta(J, J.stops[idx('cycler')].mile);
  const meet = marsChart.project(marsChart.radius(th), Math.PI + th), loop = marsChart.cyclerPoint(turn, Math.PI + th);
  check(Math.hypot(meet.x - loop.x, meet.y - loop.y) < 1e-9, 'the cycler\'s loop passes where she meets it');
  check(marsChart.insetX(J, 0) === 19 && marsChart.insetX(J, 38) === 23 && marsChart.insetX(J, 150) === 45 && marsChart.insetX(J, 9000) === 45
    && marsChart.insetX(J, 94) === 34, 'the inset\'s first stops, out along the way she leaves');
  for (const [i, st] of J.stops.entries()) {
    for (const t of [0, 0.6]) {
      const v = viewOf({ ...base, stopIndex: i, mile: st.mile, day: 1 });
      const px = new BufferCanvas(sk.chart.w, sk.chart.h);
      try {
        drawChart(px, sk.chart, J, v, t);
      } catch (err) {
        failures.push(`plot at ${st.short}: ${err.stack}`);
        continue;
      }
      passed += 1;
      check(full(px), `the plot covers its canvas at ${st.short}`);
      seen.add(px.picture);
      const label = sk.chart.label(v), footer = sk.chart.footer(v);
      check(!BAD.test(label) && label === `Plot of the transfer arc round the Sun, from Earth orbit to Mars. You are ${marsScene.whereabouts(J, v.state, v.region)}.`,
        `the plot's label (${label})`);
      check(footer.endsWith('to go. The ringed stops are stations; the inset is the Earth and the Moon, where the trip begins.') && !BAD.test(footer), `the footer (${footer})`);
      if (i === J.stops.length - 1) check(footer.startsWith('480.00 of 480.00 million km along the arc. 0.00 to go.'), `at the end (${footer})`);
    }
  }
  check(seen.size === J.stops.length * 2, `the plot moves with the ship and her marker blinks (${seen.size})`);
  // In the inset she blinks while she is among its stops: Gateway, the Moon, Earth's reach.
  const insetAt = (mile, t) => {
    const px = new BufferCanvas(sk.chart.w, sk.chart.h);
    marsChart.inset(J, px, { ...base, mile, stopIndex: Math.max(0, J.stops.findLastIndex((st) => st.mile <= mile)) }, t);
    return px.picture;
  };
  check(insetAt(38, 0) !== insetAt(38, 0.6) && insetAt(150, 0) !== insetAt(150, 0.6) && insetAt(151, 0) === insetAt(151, 0.6)
    && insetAt(15500, 0) === insetAt(15500, 0.6) && insetAt(38, 0) !== insetAt(150, 0), 'the ship in the inset, blinking, while she is among its stops');
  for (let mile = 0; mile <= J.totalMiles; mile += 1337) {
    const px = new BufferCanvas(sk.chart.w, sk.chart.h);
    drawChart(px, sk.chart, J, viewOf({ ...base, stopIndex: Math.max(0, J.stops.findLastIndex((st) => st.mile <= mile)), mile }), 0);
    check(full(px), `the plot at ${marsSkin.km(mile)}`);
  }
  const v = viewOf({ ...base, stopIndex: idx('midway'), mile: J.stops[idx('midway')].mile, atPort: true });
  check(sk.chart.label(v).endsWith('You are docked at Midway Depot.')
    && sk.chart.label(viewOf({ ...base, stopIndex: idx('cycler'), mile: J.stops[idx('cycler')].mile, atPort: true })).endsWith('You are docked at the cycler Perpetua.')
    && sk.chart.label(viewOf({ ...base, stopIndex: idx('midway'), mile: J.stops[idx('midway')].mile })).endsWith('You are in deep space.'),
  'docked and passing');
  const rings = new BufferCanvas(sk.chart.w, sk.chart.h);
  marsChart.marks(J, rings, sk.chart, v.state, 0);
  check(J.ports.length === 4 && J.ports.every((p) => {
    const q = routePosition(route, J.stops.find((s) => s.id === p.id).mile, sk.chart);
    return rings.log.some((l) => l.startsWith(`r${Math.round(q.x) - 2},${Math.round(q.y) - 3},`));
  }), 'a ring round each station');
}

// The grapple, frame by frame.
for (const role of J.roles) {
  const v = { ...regionViews.get('stream1') };
  v.state = { ...v.state, role: role.role, tackle: 200 };
  const w = sk.words(v);
  const rw = reward(J, w, sk.forage.grouped);
  check(rw.item.key === 'water' && rw.measure(60) === '60 litres' && rw.measure(1) === '1 litre', 'a catch is water, in litres');
  let tackle = 200;
  const random = lcg(17);
  const m = new FishingModel({ field: sk.forage.field, quarry: J.quarry, seconds: J.forageSeconds, padding: role.aim,
    pop: popText(sk.forage, rw), random, useTackle: () => tackle-- > 0, tackleLeft: () => tackle });
  const before = tackle;
  m.throwAt(80, 190);
  check(tackle === before && m.harpoon === null, 'a tap on the truss fires nothing');
  m.throwAt(80, 60);
  check(tackle === before - 1 && m.harpoon && m.harpoon.vy < 0, 'a tap on the dark fires the grapple up');
  const kinds = new Set(), pops = new Set(), ways = new Set();
  let frames = 0;
  while (!m.ended && frames < 2000) {
    if (frames % 7 === 0) m.aimAtNearest();
    if (frames % 11 === 0) m.throwAt(random() * 160, 20 + random() * 130);
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
      failures.push(`grapple frame ${frames}: ${err.stack}`);
      break;
    }
    if (!full(px)) failures.push(`grapple frame ${frames} leaves pixels bare`);
    frames++;
  }
  passed += 1;
  check(m.ended && m.time <= 0, `the outing ends when time is up (${frames} frames)`);
  check(m.caught > 0, `the grapple catches ice (${rw.measure(m.caught)})`);
  check(kinds.size === J.quarry.length, `every kind of ice goes by (${[...kinds].join(', ')})`);
  check(ways.size === 1, 'all of it going the same way');
  check([...pops].every((t) => /^\+(1 litre|\d+ litres), [a-z ]+$/.test(t)), `what the grapple brings is litres of water (${[...pops].slice(0, 4)})`);
  check(m.fish.every((f) => f.y >= sk.forage.field.lanes[0] - 9 && f.y <= sk.forage.field.lanes[1] + 9), 'and stays in the stream');
  const hint = sk.forage.hint(rw.measure(role.catchLimit));
  check(hint === `Tap the dark to fire the grapple at a chunk going by. Each shot spends tether. The melt tank takes up to ${role.catchLimit} litres from one outing.`,
    `the hint (${hint})`);
  check(sk.forage.label(3) === 'The ice stream beyond the truss, with 3 chunks drifting by' && sk.forage.label(1).endsWith('with 1 chunk drifting by'),
    'what the stream shows');
}
check(sk.forage.pop('1', J.quarry[0]) === '+1 litre, grit' && sk.forage.pop('12', J.quarry[4]) === '+12 litres, lost water bladder',
  'one litre, and a lost water bladder');
{
  const px = new BufferCanvas(160, 200);
  const kinds = new Map();
  for (const q of J.quarry) {
    const c = new BufferCanvas(40, 30);
    sk.forage.quarry(c, { x: 20, y: 15, vx: 1, t: 0, kind: q });
    kinds.set(q.name, c.picture);
  }
  check(new Set(kinds.values()).size === J.quarry.length, 'each kind of ice drawn as itself');
  const blink = (t) => {
    const c = new BufferCanvas(40, 30);
    sk.forage.quarry(c, { x: 20, y: 15, vx: 1, t, kind: J.quarry.find((q) => q.name === 'lost water bladder') });
    return c.picture;
  };
  check(blink(0) !== blink(0.6), 'the bladder\'s beacon blinks');
  sk.forage.backdrop(px, 0.5);
  check(full(px), 'the stream beyond the truss covers its field');
  const later = new BufferCanvas(160, 200);
  sk.forage.backdrop(later, 2.5);
  check(later.picture !== px.picture, 'and its filaments glitter as they turn');
  check(marsForage.field.bands === 3 && marsForage.field.oneWay === true, 'three filaments, one way');
}

console.log(`mars-skin: ${passed} checks passed, ${failures.length} failed`);
for (const f of failures.slice(0, 40)) console.log(`FAILED ${f.slice(0, 600)}`);
process.exit(failures.length ? 1 : 0);
