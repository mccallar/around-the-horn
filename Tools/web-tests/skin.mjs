// 1849's web skin (web/js/journeys/horn1849-*.js) against the app's (AroundTheHorn/
// Journeys/Horn1849*.swift) and on its own:
//
// - the port: every sentence, colour, sprite and map point of the Swift skin is in the JS
//   one, every player-facing literal of the app's screens is in screens.js, flow.js or
//   ui.js, and every word those three say (ui.js's HTML cut out) is in the app's;
// - the words: for every role, at every stop, at sea and in port, sick and well, no screen
//   says "undefined", "NaN" or "null", and no markup is left open;
// - the drawings: every scene in every weather at every stop, moving and still, at sea and
//   in port, the chart at every stop by either passage, and the fishing field frame by
//   frame, draw into a plain pixel buffer without throwing and cover their canvas.
//
//   node Tools/web-tests/skin.mjs
import { readFileSync } from 'node:fs';
import path from 'node:path';
import { repo } from './lib.mjs';
import { portChecks, sameColours, sameNumbers } from './port.mjs';
import { engine, lcg, describe, wordProblems, markupProblems, FakeTimers } from './player.mjs';
import { Flow, MemoryStorage } from '../../web/js/flow.js';
import { BufferCanvas } from '../../web/js/pixels.js';
import { sceneFrame, drawChart, SCENE_W, SCENE_H } from '../../web/js/drawing.js';
import { FishingModel, drawFishing, reward, popText } from '../../web/js/fishing.js';
import * as skin1849 from '../../web/js/journeys/horn1849-skin.js';
import * as stores from '../../web/js/stores.js';
import { fixed2, formatNumber } from '../../web/js/markup.js';

let passed = 0;
const failures = [];
function check(ok, what) {
  if (ok) passed += 1;
  else failures.push(what);
}

const read = (p) => readFileSync(path.join(repo, p), 'utf8');
const portCheck = (swiftFiles, jsFiles, ignore, o) => portChecks(check, swiftFiles, jsFiles, ignore, o);

// MARK: - The port

// The skin, word for word. The Swift's lone key names and debug names are not player words.
portCheck(['AroundTheHorn/Journeys/Horn1849Skin.swift', 'AroundTheHorn/Journeys/Horn1849Chart.swift',
  'AroundTheHorn/Journeys/Horn1849Forage.swift', 'AroundTheHorn/Journeys/Horn1849Scene.swift'],
['web/js/journeys/horn1849-skin.js', 'web/js/journeys/horn1849-chart.js', 'web/js/journeys/horn1849-forage.js',
  'web/js/journeys/horn1849-scene.js'], new Set(['Resolute', 'Ezra', 'Hannah', 'Silas', 'Mercy', 'Tobias']));

// The shell's words: what the app's screens say themselves.
portCheck(['AroundTheHorn/UI/Screens/SetupScreens.swift', 'AroundTheHorn/UI/Screens/VoyageScreens.swift',
  'AroundTheHorn/UI/Screens/ShopView.swift', 'AroundTheHorn/UI/Components/StatusPanel.swift',
  'AroundTheHorn/UI/Scenes/ChartView.swift', 'AroundTheHorn/UI/Screens/FishingView.swift',
  'AroundTheHorn/Services/GameController.swift', 'AroundTheHorn/App/RootView.swift', 'AroundTheHorn/App/AppInfo.swift',
  'AroundTheHorn/UI/Theme.swift'],
['web/js/screens.js', 'web/js/flow.js', 'web/js/ui.js'],
new Set([
  // Code, not words: an accessibility id, the font's file name, a format, SwiftUI's own.
  'title', '%.2f', 'VT323-Regular', 'PressStart2P-Regular',
  // The page's own: the storage keys, a console message, and what is left of the DOM's
  // strings once ui.js's HTML is cut out (a media query, selectors, attribute and tag
  // names, a key, the canvas's context). Anything else the shell's JS says must be the app's.
  'horn.save-', 'horn.topten-', 'horn.muted', 'horn.lastJourney', 'save failed:',
  '(prefers-reduced-motion: reduce)', 'input[data-field]', 'button[data-step]', '.qty', '.count', '.have',
  'aria-label', 'aria-description', 'INPUT', 'BUTTON', 'Enter', '2d',
]), { allHaveWords: false, markup: true });

for (const name of ['Scene', 'Chart', 'Forage']) {
  sameColours(check, `AroundTheHorn/Journeys/Horn1849${name}.swift`, `web/js/journeys/horn1849-${name.toLowerCase()}.js`, `Horn1849${name}`);
}

/** The ship's rows, as written in the Swift. */
{
  const sw = read('AroundTheHorn/Journeys/Horn1849Scene.swift');
  const rows = [...sw.slice(sw.indexOf('static let ship = ['), sw.indexOf('].map(Array.init)')).matchAll(/"([^"]*)"/g)].map((m) => m[1]);
  const scene = await import('../../web/js/journeys/horn1849-scene.js');
  check(rows.length === 18 && JSON.stringify(rows) === JSON.stringify(scene.ship), 'the ship is the app\'s, pixel for pixel');
}

/**
 * The numbers each drawing is made of, function by function and in the app's order, so a
 * transposed pair fails: the horizon and the skies, the sea and the ship, the town.
 */
sameNumbers(check, 'AroundTheHorn/Journeys/Horn1849Scene.swift', 'web/js/journeys/horn1849-scene.js', [
  ['static let horizon', 'static let ship', 'export const horizon', 'export const ship'],
  ['static func draw', 'static func town', 'export function draw', 'export function town'],
  ['static func town', 'static func label', 'export function town', 'export function label'],
]);

/** The chart's numbers: the routes, the land and the islands. */
{
  const nums = (s) => [...s.matchAll(/-?\d+(\.\d+)?/g)].map((m) => Number(m[0]));
  const sw = read('AroundTheHorn/Journeys/Horn1849Chart.swift');
  const swData = sw.slice(sw.indexOf('static let horn'), sw.indexOf('static func route'));
  const js = read('web/js/journeys/horn1849-chart.js');
  const jsData = js.slice(js.indexOf('export const horn'), js.indexOf('export function route'));
  // The Swift's doc comments hold no numbers but the prototype's names; strip comments both sides.
  const strip = (s) => s.replace(/\/\/[^\n]*/g, '').replace(/\/\*\*[\s\S]*?\*\//g, '');
  check(JSON.stringify(nums(strip(swData))) === JSON.stringify(nums(strip(jsData))), 'the chart\'s routes, land and islands are the app\'s');
}

// MARK: - The words, everywhere

const e = await engine();
const timers = new FakeTimers();
const flow = new Flow({ engine: e, storage: new MemoryStorage(), timers, random: lcg(5), seed: () => '77', journey: 'horn1849' });
const J = flow.journey;
const sk = flow.skin;
let screensLooked = 0;

function look(where) {
  const d = describe(flow);
  screensLooked++;
  for (const p of wordProblems(d, where)) failures.push(p);
  passed += 1;
  return d;
}

/** A stocked voyage at a stop, changed by `tweak`, on its menu. */
function voyageAt(role, stop, tweak = () => {}) {
  e.start({ journey: J.id, role, ship: 'Resolute', captain: 'Ezra', crew: ['Hannah', 'Silas', 'Mercy', 'Tobias'],
    year: 1849, month: 0, seed: '9' });
  const s = e.save([]);
  sk.debug.start(s, stop);
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
for (const s of cardStrings) for (const p of markupProblems(s)) failures.push(`card: ${p}`);

const roles = J.roles.map((r) => r.role);
for (const role of roles) {
  for (let stop = 1; stop < J.stops.length; stop++) {
    const st = J.stops[stop];
    const variants = [
      ['at sea', () => {}],
      ['sick and short', (s) => {
        s.crew[1].ailment = J.ailments[0];
        s.crew[1].treated = true;
        s.crew[2].alive = false;
        s.crew[2].hp = 0;
        s.graves = [{ name: 'Mercy', cause: 'scurvy', date: 'March 3, 1849', epitaph: 'Fair winds, shipmate.' }];
        s.noCitrus = 31;
        s.clothes = 1;
        s.note = 'Caught 30 gallons of rain.';
        s.weather = J.weathers[J.weathers.length - 1];
      }],
      ['alone', (s) => {
        for (const p of s.crew.slice(1)) {
          p.alive = false;
          p.hp = 0;
        }
      }],
    ];
    if (st.type === 'port') variants.push(['in port', (s) => {
      s.stopIndex = stop;
      s.mile = st.mile;
      s.atPort = true;
    }]);
    for (const [label, tweak] of variants) {
      const where = `${role} near ${st.short}, ${label}`;
      voyageAt(role, stop, tweak);
      const menu = flow.screen.name;
      check(menu === (label === 'in port' ? 'portMenu' : 'seaMenu'), `${where}: on the ${menu}`);
      look(`${where}, ${menu}`);
      const w = sk.words(flow.v);
      for (const [k, val] of Object.entries(w)) {
        if (typeof val === 'string') check(!/undefined|NaN|null/.test(val), `${where}: words.${k} = ${val}`);
      }
      const fns = [w.distance(1234), w.restChoice(1), w.restChoice(5), w.yardHull(120), w.yardSails(80), w.priceNote(35),
        w.burial('Silas'), sk.card.resume('Resolute'), sk.card.outfitIntro(flow.v), sk.chart.label(flow.v), sk.chart.footer(flow.v),
        sk.forage.hint('200 lbs'), sk.forage.label(4), sk.forage.pop('12', J.quarry[0])];
      for (const s of fns) {
        check(typeof s === 'string' && s.length && !/undefined|NaN|null/.test(s), `${where}: ${s}`);
        for (const p of markupProblems(s)) failures.push(`${where}: ${p}`);
      }
      for (const name of ['supplies', 'chart', 'pace', 'rations', 'rest', 'repairs', 'shipyard']) {
        flow.show({ name });
        look(`${where}, ${name}`);
      }
      flow.backToMenu();
      if (label !== 'in port') {
        flow.goFishing();
        look(`${where}, fishing`);
      }
      flow.showShop(() => flow.backToMenu());
      look(`${where}, shop`);
      flow.show({ name: 'burial', crewID: flow.game.crew[0].id, cause: 'ship fever' });
      look(`${where}, burial`);
      flow.show({ name: 'gameOver', title: 'Lost', body: 'The voyage is over.' });
      look(`${where}, game over`);
      flow.show({ name: 'finale', finale: { score: { lines: [{ label: 'Survivors', points: 500 }], subtotal: 500, multiplier: 2,
        total: 1000 }, rank: 'Greenhand', place: stop % 2 ? 3 : null } });
      look(`${where}, finale`);
    }
  }
}
check(screensLooked > 500, `looked at every screen everywhere (${screensLooked})`);

// Amounts are written the way the app writes them.
{
  const it = (k) => J.items.find((i) => i.key === k);
  const w = sk.words({ ...flow.v, state: { ...flow.v.state, alive: true } });
  const how = (k) => stores.counting(it(k), w);
  check(stores.measure(1500, it('food'), how('food'), true) === '1,500 lbs', 'provisions: 1,500 lbs');
  check(stores.measure(9.5, it('limes'), how('limes'), true) === '9.5 crates', 'citrus to a tenth: 9.5 crates');
  check(stores.measure(60, it('tackle'), how('tackle'), true) === '60 throws', 'tackle loose aboard: 60 throws');
  check(stores.have(60, it('tackle'), how('tackle')) === '3', 'and three boxes in the shop');
  check(stores.priceText(0.04, '$') === '$0.04' && stores.priceText(4, '$') === '$4' && stores.priceText(5.2, '$') === '$5.20',
    'prices as the prototype wrote them');
  check(fixed2(0.125) === '0.12' && fixed2(0.375) === '0.38' && fixed2(2.675) === '2.67' && fixed2(1.005) === '1.00',
    'two places, rounded as printf rounds');
  for (const n of [0, 7, 999, 1000, 14000, 123456789, -5, 3.99, -1234.5]) {
    check(formatNumber(n) === e.formatNumber(n), `formatNumber(${n}) is the engine's (${formatNumber(n)})`);
  }
}

// MARK: - The drawings

/** A canvas every pixel of which has something on it. */
const full = (px) => px.covered === px.pw * px.ph;

const pictures = new Map();
const base = (() => {
  voyageAt('merchant', 3);
  return flow.v;
})();
for (const weather of J.weathers) {
  for (let stop = 0; stop < J.stops.length; stop++) {
    for (const atPort of [false, true]) {
      for (const moving of [false, true]) {
        for (const t of [0, 0.37, 5.3, 1000.1]) {
          for (const sails of [100, 59, 10]) {
            const v = { ...base, state: { ...base.state, weather, atPort, sails, hull: 40, stopIndex: stop, mile: J.stops[stop].mile } };
            const px = new BufferCanvas(SCENE_W, SCENE_H);
            try {
              sk.scene.draw(px, sceneFrame(J, v, moving, t));
            } catch (err) {
              failures.push(`scene, ${weather.name} at ${J.stops[stop].short}${atPort ? ' in port' : ''}: ${err.message}`);
              continue;
            }
            passed += 1;
            if (!full(px)) failures.push(`scene, ${weather.name}${atPort ? ' in port' : ''}: ${px.covered} of ${px.pw * px.ph} pixels`);
            if (t === 0 && !moving && sails === 100 && stop === 1) pictures.set(`${weather.sky}${weather.speed < 0.1 ? '-calm' : ''}|${atPort}`, px.picture);
            const label = sk.scene.label(sceneFrame(J, v, moving, t));
            check(label && !/undefined|NaN/.test(label), `scene label: ${label}`);
          }
        }
      }
    }
  }
}
{
  const skies = [...pictures.keys()].filter((k) => k.endsWith('|false'));
  const distinct = new Set(skies.filter((k) => !k.startsWith('dust')).map((k) => pictures.get(k)));
  check(distinct.size === skies.filter((k) => !k.startsWith('dust')).length, `each sky draws its own picture (${skies.join(', ')})`);
  check(skies.every((k) => pictures.get(k) !== pictures.get(k.replace('|false', '|true'))), 'in port is another picture');
  const title = new BufferCanvas(SCENE_W, SCENE_H);
  sk.scene.draw(title, sceneFrame(J, null, false, 0));
  check(full(title) && sk.scene.label(sceneFrame(J, null, false, 0)) === 'A ship under sail', 'the title card\'s scene');
  const big = new BufferCanvas(SCENE_W, SCENE_H, 3);
  sk.scene.draw(big, sceneFrame(J, base, true, 2.5));
  check(full(big), 'the scene at three device pixels a pixel still covers its canvas');
}

for (const passage of [undefined, 'horn', 'magellan']) {
  const seen = new Set();
  for (let stop = 0; stop < J.stops.length; stop++) {
    for (const t of [0, 0.6]) {
      const v = { ...base, state: { ...base.state, passage, stopIndex: stop, mile: J.stops[stop].mile } };
      const px = new BufferCanvas(sk.chart.w, sk.chart.h);
      try {
        drawChart(px, sk.chart, J, v, t);
      } catch (err) {
        failures.push(`chart at ${J.stops[stop].short}: ${err.message}`);
        continue;
      }
      passed += 1;
      check(full(px), `the chart covers its canvas at ${J.stops[stop].short}`);
      seen.add(px.picture);
    }
  }
  check(seen.size === J.stops.length * 2, `the chart moves with the voyage and the marker blinks (${passage ?? 'no passage yet'})`);
}

{
  const v = { ...base, state: { ...base.state, tackle: 400 } };
  const w = sk.words(v);
  const rw = reward(J, w);
  let tackle = 400;
  const random = lcg(17);
  const m = new FishingModel({ field: sk.forage.field, quarry: J.quarry, seconds: J.forageSeconds, padding: 4,
    pop: popText(sk.forage, rw), random, useTackle: () => tackle-- > 0, tackleLeft: () => tackle });
  const kinds = new Set();
  let frames = 0, texts = 0;
  while (!m.ended && frames < 2000) {
    if (frames % 7 === 0) m.aimAtNearest();
    if (frames % 11 === 0) m.throwAt(random() * 160, 30 + random() * 170);
    m.step(1 / 60 + (frames % 3) * 0.02);
    for (const f of m.fish) kinds.add(f.kind.name);
    const px = new BufferCanvas(sk.forage.field.w, sk.forage.field.h);
    try {
      drawFishing(px, sk.forage, m, frames / 60);
    } catch (err) {
      failures.push(`fishing frame ${frames}: ${err.message}`);
      break;
    }
    if (!full(px)) failures.push(`fishing frame ${frames} leaves pixels bare`);
    texts += px.log.filter((l) => l.startsWith('t')).length;
    frames++;
  }
  passed += 1;
  check(m.ended && m.time <= 0, `the mini-game ends when time is up (${frames} frames)`);
  check(m.caught > 0, `throws land (${rw.measure(m.caught)})`);
  check(texts > 0, 'what a hit is worth floats up');
  check(kinds.size === J.quarry.length, `every kind of fish swims by (${[...kinds].join(', ')})`);
  const hint = sk.forage.hint(rw.measure(J.roles[0].catchLimit));
  check(hint.endsWith('keep up to 200 lbs.'), `the hint (${hint})`);
}

console.log(`skin: ${passed} checks passed, ${failures.length} failed`);
for (const f of failures.slice(0, 40)) console.log(`FAILED ${f}`);
process.exit(failures.length ? 1 : 0);
