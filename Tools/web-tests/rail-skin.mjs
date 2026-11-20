// The Iron Road's web skin (web/js/journeys/rail-*.js) against the app's (AroundTheHorn/
// Journeys/Rail*.swift) and on its own, as skin.mjs holds 1849's:
//
// - the port: every sentence, colour, sprite and map point of the Swift skin is in the JS;
// - the words: for every role, near every stop, under way and in the yard, sick, alone,
//   late and by night, every screen, and every screen of a run in each month with any
//   answer, says nothing undefined, NaN or null, leaves no markup open, and never uses a
//   sailor's word;
// - the drawings: the train in every weather through every region at every hour, moving
//   and still, sound and worn, full and empty, in the yards and on the trestle; the map at
//   every stop; the driftwood frame by frame: each draws into a plain pixel buffer without
//   throwing, covers its canvas, and changes with what it shows.
//
//   node Tools/web-tests/rail-skin.mjs
import { readFileSync } from 'node:fs';
import path from 'node:path';
import { repo } from './lib.mjs';
import { portChecks, sameColours, sameNumbers } from './port.mjs';
import { Player, engine, lcg, describe, wordProblems, markupProblems, sailorProblems, FakeTimers } from './player.mjs';
import { Flow, MemoryStorage } from '../../web/js/flow.js';
import { BufferCanvas } from '../../web/js/pixels.js';
import { sceneFrame, drawChart, SCENE_W, SCENE_H } from '../../web/js/drawing.js';
import { FishingModel, drawFishing, reward, popText } from '../../web/js/fishing.js';
import * as railSkin from '../../web/js/journeys/rail-skin.js';
import * as railScene from '../../web/js/journeys/rail-scene.js';
import * as railChart from '../../web/js/journeys/rail-chart.js';

let passed = 0;
const failures = [];
function check(ok, what) {
  if (ok) passed += 1;
  else failures.push(what);
}

const read = (p) => readFileSync(path.join(repo, p), 'utf8');
const BAD = /undefined|NaN|\bnull\b|\[object/;

// MARK: - The port

portChecks(check, ['AroundTheHorn/Journeys/RailSkin.swift', 'AroundTheHorn/Journeys/RailChart.swift',
  'AroundTheHorn/Journeys/RailForage.swift', 'AroundTheHorn/Journeys/RailScene.swift'],
['web/js/journeys/rail-skin.js', 'web/js/journeys/rail-chart.js', 'web/js/journeys/rail-forage.js',
  'web/js/journeys/rail-scene.js'], new Set(['Prairie Queen', 'Amos', 'Hattie', 'Lars', 'Clara', 'Otto']));

for (const name of ['Scene', 'Chart', 'Forage', 'Skin']) {
  sameColours(check, `AroundTheHorn/Journeys/Rail${name}.swift`, `web/js/journeys/rail-${name.toLowerCase()}.js`, `Rail${name}`);
}

/** The train's sprites, row for row as written in the Swift. */
{
  const sw = read('AroundTheHorn/Journeys/RailScene.swift');
  for (const name of ['engine', 'tender', 'tankCar', 'boxcar', 'caboose']) {
    const from = sw.indexOf(`static let ${name} = [`);
    const rows = [...sw.slice(from, sw.indexOf('].map(Array.init)', from)).matchAll(/"([^"]*)"/g)].map((m) => m[1]);
    check(rows.length > 9 && JSON.stringify(rows) === JSON.stringify(railScene[name]), `the ${name} is the app's, pixel for pixel`);
  }
  const at = (src, re) => Number(src.match(re)?.[1]);
  check(at(sw, /static let horizon = ([\d.]+)/) === railScene.horizon && at(sw, /static let rail = ([\d.]+)/) === railScene.rail,
    'the horizon and the rail');
  const places = [...sw.match(/static let engineX = ([^\n]+)/)[0].matchAll(/= ([\d.]+)/g)].map((m) => Number(m[1]));
  check(JSON.stringify(places) === JSON.stringify([railScene.engineX, railScene.tenderX, railScene.tankX, railScene.box1X,
    railScene.box2X, railScene.cabooseX]), 'where each car stands');
}

/**
 * The numbers each drawing is made of, function by function and in the app's order, so a
 * transposed pair fails. The JS keeps the palette's defaults in the function and the two
 * scatters in one helper of its own; what either side writes that the other does not is
 * named here.
 */
sameNumbers(check, 'AroundTheHorn/Journeys/RailScene.swift', 'web/js/journeys/rail-scene.js', [
  ['struct Palette', '// MARK: The train', 'export function palette', '// MARK: The train'],
  ['static func wrap', 'static func isNight', 'export function wrap', 'export function isNight'],
  ['static func isNight', 'static let daleCreek', 'export function isNight', 'export function onTrestle'],
  ['static func onTrestle', 'static func draw', 'export function onTrestle', 'export function draw'],
  ['static func draw', '// MARK: Country', 'export function draw', '// MARK: Country'],
  ['static func ground', 'static func far', 'export function ground', 'export function far'],
  // Swift's snow loop runs over the ridge's own range, the JS's counts from 0.
  ['static func far', 'static func middle', 'export function far', 'function scatterer', ['let i = 0']],
  // The Swift's scatter in each function defaults its seed to 0; the JS's always passes one.
  ['static func middle', 'static func near', 'function scatterer', 'export function near', [], ['seed: Double = 0']],
  ['static func near', 'static func pine', 'export function near', 'export function pine', [], [/func scatter\(.*\n.*\n.*\n.*\n.*\n.*\n/]],
  ['static func pine', 'static func oak', 'export function pine', 'export function oak'],
  ['static func oak', 'static func bush', 'export function oak', 'export function bush'],
  ['static func bush', 'static func roadbed', 'export function bush', 'export function roadbed'],
  ['static func roadbed', 'static func poles', 'export function roadbed', 'export function poles'],
  ['static func poles', 'static func yard', 'export function poles', 'export function yard'],
  ['static func yard', 'static func gorge', 'export function yard', 'export function gorge'],
  ['static func gorge', 'static let shedLength', 'export function gorge', 'export const shedLength'],
  ['static let shedLength', 'static func shedBack', 'export const shedLength', 'export function shedBack'],
  ['static func shedBack', 'static func shedFront', 'export function shedBack', 'export function shedFront'],
  ['static func shedFront', '// MARK: Train', 'export function shedFront', '// MARK: Train'],
  // The JS finds the wood's cap where Swift's `item(.fuel)` cannot miss.
  ['static func train', 'static func wisp', 'export function train', 'export function wisp', ['?? 0']],
  ['static func wisp', 'static func smoke', 'export function wisp', 'export function smoke'],
  ['static func smoke', 'static func lights', 'export function smoke', 'export function lights'],
  ['static func lights', 'static func wind', 'export function lights', 'export function wind'],
  ['static func wind', 'static func shimmer', 'export function wind', 'export function shimmer'],
  ['static func shimmer', '// MARK: VoiceOver', 'export function shimmer', '// MARK: VoiceOver'],
  ['static func label', '\n}\n', 'export function label', '\n}\n'],
]);

/** The map's numbers: the road, the coast, the lake, the rivers, the peaks and the deserts. */
{
  // Comments and the Swift's type names (`UInt32`) hold no data.
  const nums = (s) => [...s.replace(/\/\/[^\n]*/g, '').replace(/\/\*\*[\s\S]*?\*\//g, '').replace(/UInt32/g, '')
    .matchAll(/-?\d+(\.\d+)?/g)].map((m) => Number(m[0]));
  const sw = read('AroundTheHorn/Journeys/RailChart.swift');
  const js = read('web/js/journeys/rail-chart.js');
  const between = (s, a, b) => s.slice(s.indexOf(a), s.indexOf(b));
  check(JSON.stringify(nums(between(sw, 'static let road', 'static func project')))
    === JSON.stringify(nums(between(js, 'export const road', 'export function project'))), 'the road is the app\'s');
  check(JSON.stringify(nums(between(sw, 'static let coast', 'static func background')))
    === JSON.stringify(nums(between(js, 'export const coast', '/** Swift\'s'))), 'the country is the app\'s');
  check(/\(lon \+ 124\.6\) \* 7\.8, y: \(44\.7 - lat\) \* 10/.test(js) && /\(\(p\.lon \+ 124\.6\) \* 7\.8, \(44\.7 - p\.lat\) \* 10\)/.test(sw),
    'and so is the projection');
}

/** The contract: the skin's twelve days are the engine's. */
{
  const data = read('HornEngine/Journeys/Rail/RailData.swift');
  check(Number(data.match(/static let contractTurns = (\d+)/)[1]) === railSkin.contractTurns, 'the contract\'s turns are the engine\'s');
}

// MARK: - The words, everywhere

const e = await engine();
const flow = new Flow({ engine: e, storage: new MemoryStorage(), timers: new FakeTimers(), random: lcg(5), seed: () => '77',
  journey: 'rail' });
const J = flow.journey;
const sk = flow.skin;
check(J.id === 'rail' && sk.id === 'rail', 'the Iron Road, in its own skin');
let screensLooked = 0;

function look(where) {
  const d = describe(flow);
  screensLooked++;
  for (const p of [...wordProblems(d, where), ...sailorProblems(d, where)]) failures.push(p);
  if (flow.screen.name !== 'picker' && d.banner !== 'THE IRON ROAD · 1869') failures.push(`${where}: the banner ${d.banner}`);
  passed += 1;
  return d;
}

/** A fresh voyage's state, ready for the skin's debug start. */
function fresh(role = 'merchant', month = 9) {
  const dep = J.departures.find((d) => d.month === month) ?? J.departures[0];
  e.start({ journey: 'rail', role, ship: 'Prairie Queen', captain: 'Amos', crew: ['Hattie', 'Lars', 'Clara', 'Otto'],
    year: dep.year, month: dep.month, seed: '9' });
  return e.save([]);
}

/** A stocked train near a stop, changed by `tweak`, on its menu. */
function voyageAt(role, stop, tweak = () => {}, month = 9) {
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
  check(!/\b(ship|captain|sail|nm)\b/i.test(s), `the title card says no sailor's word: ${s.slice(0, 60)}`);
}

const blizzard = J.weathers.find((w) => w.sky === 'snow' && w.harsh > 1);
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
        s.graves = [{ name: 'Clara', cause: 'mountain fever', date: 'October 5, 1869', epitaph: 'Clear track ahead, friend.' }];
        s.clothes = 1;
        s.note = 'The tank car is dry.';
        s.weather = blizzard;
        s.hull = 12;
        s.sails = 8;
        s.fuel = 3;
      }],
      ['alone', (s) => {
        for (const p of s.crew.slice(1)) {
          p.alive = false;
          p.hp = 0;
        }
      }],
      ['late, by night', (s) => { s.day = 76; }],
      ['on the stroke of late', (s) => { s.day = 72; }],
    ];
    if (st.type === 'port') variants.push(['in the yard', (s) => {
      s.stopIndex = stop;
      s.mile = st.mile;
      s.atPort = true;
    }]);
    for (const [label, tweak] of variants) {
      const where = `${role} near ${st.short}, ${label}`;
      voyageAt(role, stop, tweak);
      const menu = flow.screen.name;
      check(menu === (label === 'in the yard' ? 'portMenu' : 'seaMenu'), `${where}: on the ${menu}`);
      look(`${where}, ${menu}`);
      const w = sk.words(flow.v);
      for (const [k, val] of Object.entries(w)) {
        if (typeof val === 'string') check(!BAD.test(val), `${where}: words.${k} = ${val}`);
      }
      check(!BAD.test(w.clock.value) && /left$|late$/.test(w.clock.value), `${where}: the clock (${w.clock.value})`);
      const fns = [w.distance(1234), ...J.rules.restChoices.map(w.restChoice), w.yardHull(120), w.yardSails(80),
        w.priceNote(35), w.burial('Lars'), sk.card.resume('Prairie Queen'), sk.card.outfitIntro(flow.v), sk.chart.label(flow.v),
        sk.chart.footer(flow.v), sk.forage.hint('4 cords'), sk.forage.label(4), sk.forage.pop('0.2', J.quarry[0]),
        sk.forage.pop('1', J.quarry[4])];
      for (const s of fns) {
        check(typeof s === 'string' && s.length && !BAD.test(s), `${where}: ${s}`);
        for (const p of markupProblems(s)) failures.push(`${where}: ${p}`);
      }
      for (const name of ['supplies', 'chart', 'pace', 'rations', 'rest', 'repairs', 'shipyard', 'travel']) {
        flow.show({ name });
        look(`${where}, ${name}`);
      }
      flow.backToMenu();
      if (label !== 'in the yard') {
        flow.goFishing();
        look(`${where}, ${flow.screen.name === 'fishing' ? 'driftwood' : 'no driftwood'}`);
        flow.backToMenu();
      }
      flow.showShop(() => flow.backToMenu());
      look(`${where}, store`);
      flow.show({ name: 'burial', crewID: flow.game.crew[0].id, cause: 'cholera' });
      look(`${where}, burial`);
      flow.show({ name: 'gameOver', title: 'The contract is forfeit.', body: 'The consignee has wired.' });
      look(`${where}, game over`);
      flow.show({ name: 'finale', finale: { score: { lines: [{ label: 'Days in hand on the contract', points: 300 }],
        subtotal: 300, multiplier: 3, total: 900 }, rank: 'Section Hand', place: stop % 2 ? 3 : null } });
      look(`${where}, finale`);
    }
  }
}
check(screensLooked > 1500, `looked at every screen everywhere (${screensLooked})`);

// The words that change with the state, as the app writes them.
{
  voyageAt('shipwright', 4);
  const g = flow.game;
  const w = (tweak) => {
    const v = { ...flow.v, state: { ...g, ...tweak } };
    return sk.words(v);
  };
  check(railSkin.span(J, 1) === '4 hours' && railSkin.span(J, 6) === '1 day' && railSkin.span(J, 7) === '1 day and 4 hours'
    && railSkin.span(J, 67) === '11 days and 4 hours' && railSkin.span(J, 0) === '0 hours', 'spans of turns, as the player reads them');
  check(w({ day: 70 }).clock.value === '8 hours left' && w({ day: 72 }).clock.value === 'late'
    && w({ day: 74 }).clock.value === '8 hours late', 'the contract clock, either side of the twelfth day');
  check(w({ day: 72 }).suppliesNote.endsWith('[red]the freight is late[/red]'), 'the note goes red when the freight is late');
  check(w({ day: 10 }).arrivalBody.includes('The freight is on time.') && w({ day: 72 }).arrivalBody.includes('a good deal to say'),
    'on time as the engine pays it');
  check(w({}).repairsNote === 'Each repair takes four hours. As a boilermaker, your repairs go much further.', 'the boilermaker\'s repairs');
  check(w({ clothes: 2 }).clothesWarning === '[red]Only 2 of 5 have a blanket.[/red]' && w({ clothes: 5 }).clothesWarning === null,
    'blankets');
  check(w({ atPort: true }).restPrompt.startsWith('The crew can sleep in beds') && w({ atPort: false }).restPrompt.startsWith('You set the brakes'),
    'resting in the yard and on the line');
  check(w({}).priceNote(30) === 'Prices here run about 30% above Omaha, give or take what the country grows.', 'prices against Omaha');
}

/** Runs in every month, each role, answering anything: every screen of the road's own text. */
{
  let runs = 0, screens = 0;
  const endings = new Set();
  for (const [i, month] of ['June 1869', 'August 1869', 'October 1869', 'December 1869', 'February 1870'].entries()) {
    for (const [k, role] of J.roles.entries()) {
      const seed = 100 + i * 7 + k;
      const p = await Player.make({ engine: e, seeds: [String(seed)], random: lcg(seed), journey: 'rail' });
      const look0 = p.look.bind(p);
      p.look = () => {
        const d = look0();
        screens++;
        p.problems.push(...sailorProblems(d, p.screen));
        return d;
      };
      const pick = lcg(seed * 3);
      p.setUp({ role: role.label, month });
      const end = p.voyage({
        layOver: k === 2 ? 1 : 0,
        onScreen: (q) => {
          // Any answer that is offered, not only the careful first one; but the careful
          // player pulls into every yard, to buy what it needs to get anywhere at all.
          if (q.screen !== 'choice' || 'portArrival' in q.f.screen.event.kind) return null;
          const open = q.look().choices.filter((c) => c.enabled);
          open[Math.floor(pick() * open.length)].act();
          return null;
        },
      });
      runs++;
      endings.add(end);
      check(end === 'finale' || end === 'gameOver', `${role.title} leaving in ${month}: the run ends (${end})`);
      for (const pr of p.problems.slice(0, 5)) failures.push(`${role.title} in ${month}: ${pr}`);
    }
  }
  check(runs === 15 && screens > 2000, `fifteen runs, every screen read (${screens})`);
  check(endings.has('finale') && endings.has('gameOver'), `runs that arrive and runs that don't (${[...endings]})`);
}

// MARK: - The drawings

/** A canvas every pixel of which has something on it. */
const full = (px) => px.covered === px.pw * px.ph;

/** The engine's view of `s`: its region and hour worked out as the app works them. */
function viewOf(s) {
  try {
    return e.load(s, '1', 'rail').view;
  } finally {
    e.close();
  }
}

const base = fresh();
sk.debug.start(base, 3);
/** A view in each region, at each hour a turn can fall on, keyed by region id. */
const regionViews = new Map();
for (const reg of J.regions) {
  const from = J.regions.indexOf(reg) === 0 ? 0 : J.regions[J.regions.indexOf(reg) - 1].to;
  const mile = Math.min(J.totalMiles - 1, Math.floor((from + (reg.to ?? J.totalMiles)) / 2));
  const stopIndex = Math.max(0, J.stops.findLastIndex((st) => st.mile <= mile));
  const views = [0, 1, 2, 3, 4, 5].map((day) => viewOf({ ...base, mile, stopIndex, day }));
  check(views.every((v) => v.region.id === reg.id), `${reg.name}: mile ${mile} is in it`);
  regionViews.set(reg.id, views);
}
check(regionViews.size === 13, `thirteen kinds of country (${regionViews.size})`);
const hours = new Set([...regionViews.values()][0].map((v) => v.hour));
check([2, 6, 10, 14, 18, 22].every((h) => hours.has(h)), `every hour a turn falls on (${[...hours]})`);

const wear = [[100, 100, 160], [59, 45, 70], [25, 10, 2], [8, 28, 0]];
const pictures = new Map();
let drawn = 0, turn = 0;
for (const weather of J.weathers) {
  for (const [id, views] of regionViews) {
    // Every hour in fair weather (and dawn, which a turn never lands on); in the others,
    // day, dusk and night.
    const all = [...views, { ...views[1], hour: 5 }];
    for (const v0 of weather.rawValue === 'fair' ? all : all.filter((v) => [10, 18, 22].includes(v.hour))) {
      for (const moving of [false, true]) {
        // Still at the start of the clock; under way at moments taken in turn.
        for (const t of moving ? [[0.37, 5.3, 1000.1][turn++ % 3]] : [0]) {
          for (const [k, [hull, sails, fuel]] of wear.entries()) {
            const v = { ...v0, state: { ...v0.state, weather, hull, sails, fuel } };
            const px = new BufferCanvas(SCENE_W, SCENE_H);
            const f = sceneFrame(J, v, moving, t);
            try {
              sk.scene.draw(px, f);
            } catch (err) {
              failures.push(`scene, ${weather.name} in ${id} at ${v.hour}: ${err.stack}`);
              continue;
            }
            drawn++;
            if (!full(px)) failures.push(`scene, ${weather.name} in ${id} at ${v.hour}: ${px.covered} of ${px.pw * px.ph} pixels`);
            if (t === 0 && !moving) pictures.set(`${weather.rawValue}|${id}|${v.hour}|${k}`, px.picture);
            const label = sk.scene.label(f);
            if (!label || BAD.test(label) || /ship|sail/i.test(label)) failures.push(`scene label: ${label}`);
          }
        }
      }
    }
  }
}
check(drawn === (J.weathers.length * 3 + 4) * 13 * 2 * 4, `the train drawn everywhere (${drawn})`);
{
  const p = (w, id, h = 10, k = 0) => pictures.get(`${w}|${id}|${h}|${k}`);
  const regions = [...regionViews.keys()];
  check(new Set(regions.map((id) => p('fair', id))).size === regions.length, 'each kind of country draws its own picture');
  const skies = J.weathers.map((w) => w.rawValue);
  check(new Set(skies.map((w) => p(w, 'platte'))).size === skies.length, `each weather draws its own picture (${skies})`);
  check(p('fair', 'platte', 22) !== p('fair', 'platte', 10) && p('fair', 'platte', 2) === p('fair', 'platte', 22),
    'night is dark, the whole night through');
  check(p('rain', 'platte', 22) !== p('fair', 'platte', 22), 'a moon and stars only in a clear sky');
  check(new Set([6, 10, 14].map((h) => p('fair', 'platte', h))).size === 3, 'the sun goes over');
  check(p('fair', 'platte', 18) !== p('fair', 'platte', 14) && p('fair', 'platte', 5) !== p('fair', 'platte', 6), 'dusk and dawn');
  check(new Set([0, 1, 2, 3].map((k) => p('fair', 'humboldt', 10, k))).size === 4, 'wear and the woodpile show');
  const v = regionViews.get('platte')[1];
  const at = (s, moving = false, t = 0) => {
    const px = new BufferCanvas(SCENE_W, SCENE_H);
    sk.scene.draw(px, sceneFrame(J, { ...v, state: { ...v.state, ...s } }, moving, t));
    return px;
  };
  check(at({}, true, 1).picture !== at({}, true, 1.5).picture, 'the country slides past under way');
  check(at({ sails: 100 }, true, 1).picture !== at({ sails: 100 }, false, 1).picture, 'the smoke streams back under way');
  const fuels = new Set([160, 80, 30, 2, 0].map((fuel) => at({ fuel }).picture));
  check(fuels.size === 4, `cordwood on the tender, as much as is left (${fuels.size} pictures for five amounts)`);

  // The title card: no voyage yet.
  const title = new BufferCanvas(SCENE_W, SCENE_H);
  sk.scene.draw(title, sceneFrame(J, null, false, 0));
  check(full(title) && sk.scene.label(sceneFrame(J, null, false, 0)) === 'A wood-burning freight train on the prairie',
    'the title card\'s train');
  const big = new BufferCanvas(SCENE_W, SCENE_H, 3);
  sk.scene.draw(big, sceneFrame(J, v, true, 2.5));
  check(full(big), 'the scene at three device pixels a pixel still covers its canvas');
}

// The yards, the trestle and the snowsheds.
{
  const draw = (v, moving = false, t = 0) => {
    const px = new BufferCanvas(SCENE_W, SCENE_H);
    sk.scene.draw(px, sceneFrame(J, v, moving, t));
    check(full(px), 'covers its canvas');
    return px;
  };
  for (const [i, st] of J.stops.entries()) {
    if (st.type !== 'port') continue;
    const v = viewOf({ ...base, stopIndex: i, mile: st.mile, atPort: true, day: 1 });
    const yard = draw(v), line = draw({ ...v, state: { ...v.state, atPort: false } });
    check(yard.picture !== line.picture, `the yard at ${st.short}`);
    check(sk.scene.label(sceneFrame(J, v, false, 0)) === 'The train standing in the yard, by the water tank and the depot',
      `the yard's label at ${st.short}`);
    const night = viewOf({ ...base, stopIndex: i, mile: st.mile, atPort: true, day: 4 });
    check(draw(night).picture !== yard.picture, `lamplight in the depot at ${st.short}`);
  }
  const di = J.stops.findIndex((st) => st.id === 'dalecreek');
  const dale = J.stops[di];
  for (const mile of [dale.mile, dale.mile + 3]) {
    const v = viewOf({ ...base, stopIndex: di, mile, day: 1 });
    for (const weather of J.weathers) {
      const on = { ...v, state: { ...v.state, weather } };
      const f = sceneFrame(J, on, true, 3.3);
      check(railScene.onTrestle(J, f), `on the trestle at mile ${mile}`);
      check(sk.scene.label(f) === `The train on the Dale Creek trestle. Weather: ${weather.name.toLowerCase()}`, `the trestle's label (${weather.name})`);
      draw(on, true, 3.3);
    }
  }
  const before = viewOf({ ...base, stopIndex: di - 1, mile: dale.mile - 2, day: 1 });
  check(!railScene.onTrestle(J, sceneFrame(J, before, true, 0)), 'not on the bridge before reaching it');
  const after = viewOf({ ...base, stopIndex: di, mile: dale.mile + 4, day: 1 });
  check(!railScene.onTrestle(J, sceneFrame(J, after, true, 0)), 'nor once past the gorge');
  const onIt = viewOf({ ...base, stopIndex: di, mile: dale.mile + 1, day: 1 });
  check(draw(onIt, true, 2).picture !== draw(after, true, 2).picture, 'the gorge is its own picture');

  const sierra = regionViews.get('sierra')[1];
  const sheds = new Set([0, 1, 2, 3, 4, 5, 6, 7].map((t) => draw(sierra, true, t * 1.7).picture));
  check(sheds.size === 8, 'the snowsheds go by');
  check(sk.scene.label(sceneFrame(J, sierra, true, 0)) === 'The train rolling through the Sierra Nevada. Weather: fair', 'the Sierra');
  const night = regionViews.get('platte')[4];
  check(sk.scene.label(sceneFrame(J, night, false, 0)) === 'The train stopped in the Platte Valley by night. Weather: fair', 'by night');
}

// The gallery the app shows for screenshots: each one draws.
for (const g of sk.debug.gallery) {
  const s = fresh();
  sk.debug.start(s, 5);
  g.set(s);
  const v = viewOf(s);
  const px = new BufferCanvas(SCENE_W, SCENE_H);
  sk.scene.draw(px, sceneFrame(J, v, g.moving, 1.5));
  check(full(px), `the gallery's ${g.name}`);
}

// The map.
{
  const seen = new Set();
  const total = J.totalMiles;
  for (const [i, st] of J.stops.entries()) {
    check(railChart.road.some((r) => r[2] === st.mile), `${st.short} is on the road at its mile`);
    for (const t of [0, 0.6]) {
      const v = viewOf({ ...base, stopIndex: i, mile: st.mile, day: 1 });
      const px = new BufferCanvas(sk.chart.w, sk.chart.h);
      try {
        drawChart(px, sk.chart, J, v, t);
      } catch (err) {
        failures.push(`map at ${st.short}: ${err.stack}`);
        continue;
      }
      passed += 1;
      check(full(px), `the map covers its canvas at ${st.short}`);
      seen.add(px.picture);
      const words = px.log.filter((l) => l.startsWith('t')).map((l) => l.slice(1).split(',')[0]);
      check(words.join('/') === 'OMAHA/SACRAMENTO', `the two ends named (${words})`);
      const label = sk.chart.label(v), footer = sk.chart.footer(v);
      check(!BAD.test(label) && label.startsWith('Map of the railroad from Omaha to Sacramento. You are in '), `the map's label (${label})`);
      check(footer.endsWith('to go. The ringed stops have a yard.') && !BAD.test(footer), `the footer (${footer})`);
      if (i === J.stops.length - 1) check(footer.startsWith(`1,776 of 1,776 miles covered. 0 to go.`), `at the end (${footer})`);
    }
  }
  check(seen.size === J.stops.length * 2, `the map moves with the train and the marker blinks (${seen.size})`);
  // Between the stops too, and every ring on a yard.
  for (let mile = 0; mile <= total; mile += 37) {
    const px = new BufferCanvas(sk.chart.w, sk.chart.h);
    drawChart(px, sk.chart, J, viewOf({ ...base, stopIndex: Math.max(0, J.stops.findLastIndex((st) => st.mile <= mile)), mile }), 0);
    check(full(px), `the map at mile ${mile}`);
  }
  const rings = new BufferCanvas(sk.chart.w, sk.chart.h);
  railChart.names(rings, J);
  check(rings.log.filter((l) => l.startsWith('r')).length === 4 * J.stops.filter((st) => st.type === 'port').length,
    'a ring on every yard');
}

// The driftwood, frame by frame.
for (const role of J.roles) {
  const v = { ...regionViews.get('platte')[1] };
  v.state = { ...v.state, role: role.role, tackle: 400 };
  const w = sk.words(v);
  const rw = reward(J, w);
  check(rw.item.key === 'fuel' && rw.how.tenths && !rw.how.loose, 'driftwood goes on the tender, counted in tenths of a cord');
  let tackle = 400;
  const random = lcg(17);
  const m = new FishingModel({ field: sk.forage.field, quarry: J.quarry, seconds: J.forageSeconds, padding: role.aim,
    pop: popText(sk.forage, rw), random, useTackle: () => tackle-- > 0, tackleLeft: () => tackle });
  const before = tackle;
  m.throwAt(80, 170);
  check(tackle === before && m.harpoon === null, 'a tap on the near bank casts nothing');
  m.throwAt(80, 100);
  check(tackle === before - 1 && m.harpoon && m.harpoon.vy < 0, 'a tap on the river casts up it');
  check(m.fish.every((f) => f.vx > 0), 'everything floats the same way, left to right');
  const kinds = new Set();
  const pops = new Set();
  let frames = 0;
  while (!m.ended && frames < 2000) {
    if (frames % 7 === 0) m.aimAtNearest();
    if (frames % 11 === 0) m.throwAt(random() * 160, 20 + random() * 136);
    m.step(1 / 60 + (frames % 3) * 0.02);
    for (const f of m.fish) kinds.add(f.kind.name);
    for (const p of m.pops) pops.add(p.text);
    const px = new BufferCanvas(sk.forage.field.w, sk.forage.field.h);
    try {
      drawFishing(px, sk.forage, m, frames / 60);
    } catch (err) {
      failures.push(`driftwood frame ${frames}: ${err.stack}`);
      break;
    }
    if (!full(px)) failures.push(`driftwood frame ${frames} leaves pixels bare`);
    frames++;
  }
  passed += 1;
  check(m.ended && m.time <= 0, `the haul ends when time is up (${frames} frames)`);
  check(m.caught > 0, `casts land (${rw.measure(m.caught)})`);
  check(kinds.size === J.quarry.length, `every kind of driftwood goes by (${[...kinds].join(', ')})`);
  check([...pops].every((t) => /^\+(1 cord|(?!1,)\d+(\.\d)? cords), [a-z ]+$/.test(t)), `what floats up is in cords (${[...pops].slice(0, 4)})`);
  check(m.fish.every((f) => f.y >= sk.forage.field.lanes[0] - 5 && f.y <= sk.forage.field.lanes[1] + 5), 'and stays in the river');
  const hint = sk.forage.hint(rw.measure(role.catchLimit));
  check(hint.endsWith(`up to ${role.role === 'whaler' ? 6 : 4} cords at one stop.`), `the hint (${hint})`);
  check(sk.forage.label(3) === 'The river from the bank, with 3 pieces of driftwood going by', 'what the river shows');
}
check(sk.forage.pop('1', J.quarry[3]) === '+1 cord, saw log' && sk.forage.pop('0.4', J.quarry[1]) === '+0.4 cords, fence rail',
  'one cord, and tenths of one');

console.log(`rail-skin: ${passed} checks passed, ${failures.length} failed`);
for (const f of failures.slice(0, 40)) console.log(`FAILED ${f}`);
process.exit(failures.length ? 1 : 0);
