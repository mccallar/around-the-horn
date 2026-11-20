// A player for the web flow (web/js/flow.js) in Node: it reads each screen as screens.js
// describes it and presses its numbered choices, as a person would, with time and chance
// held still (fake timers, a seeded random, fixed seeds). Every screen it sees is checked
// for words that went wrong.
import { readFile } from 'node:fs/promises';
import { Engine, wasiImports } from '../../web/engine.js';
import { Flow, MemoryStorage } from '../../web/js/flow.js';
import { describe, texts } from '../../web/js/screens.js';
import { plain, STYLES } from '../../web/js/markup.js';

export { describe, texts, plain };

let wasm;
/** A fresh engine with its own voyage slot; horn.wasm is compiled once for them all. */
export async function engine() {
  if (!wasm) wasm = await WebAssembly.compile(await readFile(new URL('../../web/horn.wasm', import.meta.url)));
  let memory;
  const instance = await WebAssembly.instantiate(wasm, { wasi_snapshot_preview1: wasiImports(() => memory) });
  memory = instance.exports.memory;
  instance.exports._initialize();
  return new Engine(instance.exports);
}

/** Timers that only move when told. */
export class FakeTimers {
  constructor() { this.fns = new Set(); }
  every(ms, fn) {
    const entry = { fn };
    this.fns.add(entry);
    return { cancel: () => this.fns.delete(entry) };
  }
  fire() { for (const e of [...this.fns]) e.fn(); }
  get running() { return this.fns.size; }
}

/** A seeded [0, 1): the same game every run. */
export function lcg(seed) {
  let s = seed % 2147483647 || 1;
  return () => {
    s = (s * 48271) % 2147483647;
    return (s - 1) / 2147483646;
  };
}

const WRONG = /undefined|NaN|\[object|\bnull\b|Infinity/;
/** Real companies' and brands' names, which no word on a screen may use. */
const MARKS = /\b(Aspirin|Thermos|Primus|Vaseline|Band-Aid|Kleenex|Velcro|Jeep)\b/i;

/** The tags a piece of markup leaves open, and any bracket that looks like a tag but isn't one. */
export function markupProblems(s) {
  const out = [];
  const stack = [];
  let i = 0;
  while (i < s.length) {
    if (s.startsWith('[[', i)) { i += 2; continue; }
    if (s[i] === '[') {
      const close = s.indexOf(']', i);
      if (close < 0) { out.push(`an unclosed "[" in ${JSON.stringify(s)}`); break; }
      const tag = s.slice(i + 1, close);
      const name = tag.replace(/^\//, '');
      if (!STYLES.includes(name)) {
        out.push(`"[${tag}]" is not a tag, in ${JSON.stringify(s)}`);
      } else if (tag.startsWith('/')) {
        const at = stack.lastIndexOf(name);
        if (at < 0) out.push(`"[/${name}]" closes nothing, in ${JSON.stringify(s)}`);
        else stack.splice(at, 1);
      } else {
        stack.push(name);
      }
      i = close + 1;
      continue;
    }
    i += 1;
  }
  for (const t of stack) out.push(`"[${t}]" is never closed, in ${JSON.stringify(s)}`);
  return out;
}

/** Everything wrong with the words on a described screen. */
export function wordProblems(d, where = '') {
  const out = [];
  for (const { text, markup } of texts(d)) {
    if (typeof text !== 'string') { out.push(`${where}: not a string: ${text}`); continue; }
    if (WRONG.test(text)) out.push(`${where}: ${JSON.stringify(text)}`);
    if (MARKS.test(text)) out.push(`${where}: a trademark in ${JSON.stringify(text)}`);
    if (markup) out.push(...markupProblems(text).map((p) => `${where}: ${p}`));
  }
  for (const c of d.choices) if (!plain(c.label).trim()) out.push(`${where}: a blank choice`);
  return out;
}

/**
 * 1849's words that must never reach the Iron Road. The engine's one simile ("sways under
 * you like a ship at a dock", crossing Dale Creek in a wind) is the road's own sentence.
 */
const SAILOR = /\b(ships?|captain|captains|nm|sails?|sailed|sailing|sailors?|nautical|harpoons?|fishing|fish|voyage|chandler|shipyard|anchor)\b/i;
const OWN = ['like a ship at a dock'];

export function sailorProblems(d, where) {
  const out = [];
  for (const { text } of texts(d)) {
    let t = plain(text);
    for (const o of OWN) t = t.split(o).join('');
    const m = t.match(SAILOR);
    if (m) out.push(`${where}: "${m[0]}" in ${JSON.stringify(text)}`);
  }
  return out;
}

/**
 * Words of the other journeys that must never reach the airship: 1849's sea and the Iron
 * Road's rails. The airship has a captain and is a ship, the engine's Arctic has fishing
 * boats and dried fish, and Oslo's store is its "ship chandler".
 */
export const AIRSHIP_FOREIGN = /\b(nm|sails?|sailed|sailing|sailors?|nautical|harpoons?|voyage|chandler|shipyard|anchor|cords?|train|conductor|tender|roundhouse|miles?|lbs)\b/i;
const AIRSHIP_OWN = ['ship chandler'];

export function foreignProblems(d, where) {
  const out = [];
  for (const { text } of texts(d)) {
    let t = plain(text);
    for (const o of AIRSHIP_OWN) t = t.split(o).join('');
    const m = t.match(AIRSHIP_FOREIGN);
    if (m) out.push(`${where}: "${m[0]}" in ${JSON.stringify(text)}`);
  }
  return out;
}

/**
 * Words of the other journeys that must never reach the balloon: 1849's sea, the Iron
 * Road's rails, the airship's kilometres and petrol, and the engine's own names for the
 * stores and meters. The balloon has nautical miles, pounds, fishing and a captain of its
 * own; a freighter has a radio mast.
 */
export const BALLOON_FOREIGN = /\b(sails?|sailed|sailing|sailors?|harpoons?|voyage|chandler|shipyard|anchor|cords?|train|conductor|tender|roundhouse|km|kilometres?|petrol|mast|tackle|timber|sailcloth|limes|hull)\b/i;
const BALLOON_OWN = ['radio mast'];

export function balloonProblems(d, where) {
  const out = [];
  for (const { text } of texts(d)) {
    let t = plain(text);
    for (const o of BALLOON_OWN) t = t.split(o).join('');
    const m = t.match(BALLOON_FOREIGN);
    if (m) out.push(`${where}: "${m[0]}" in ${JSON.stringify(text)}`);
  }
  return out;
}

/**
 * Words of the other journeys that must never reach the freighter: 1849's sea, the Iron
 * Road's rails, the airship's petrol and masts, the balloon's propane, gallons and nautical
 * miles, pounds and fishing, and the engine's own names for the stores and the meter the
 * transfer calls power & drive. The freighter has a pressure hull and a chandlery of its own.
 */
export const MARS_FOREIGN = /\b(sails?|sailed|sailing|sailors?|harpoons?|voyage|chandler|shipyard|anchor|cords?|train|conductor|tender|roundhouse|petrol|mast|tackle|timber|sailcloth|limes|propane|gallons?|nautical|nm|miles?|lbs?|balloon|fish|fishing)\b/i;

export function marsProblems(d, where) {
  const out = [];
  for (const { text } of texts(d)) {
    const m = plain(text).match(MARS_FOREIGN);
    if (m) out.push(`${where}: "${m[0]}" in ${JSON.stringify(text)}`);
  }
  return out;
}

export class Player {
  constructor({ flow, timers, log = false }) {
    this.f = flow;
    this.timers = timers;
    this.log = log;
    this.problems = [];
    this.seen = new Set();
    this.screens = [];
  }

  /**
   * `journey` opens on that journey's title card, as the app's UI tests launch with
   * `-journey <id>`; null opens as a plain launch does, on the picker or the journey last
   * chosen. `skins` stands in for journeys/skins.js's (a test's own skin, as the app's
   * TestJourneys stands in for a journey).
   */
  static async make({ engine: e, storage = new MemoryStorage(), seeds = ['1'], random = lcg(7), log,
    journey = 'horn1849', skins, sound } = {}) {
    const timers = new FakeTimers();
    let n = 0;
    const flow = new Flow({ engine: e ?? await engine(), storage, timers, random, seed: () => seeds[n++ % seeds.length],
      journey, skins, sound });
    return new Player({ flow, timers, log });
  }

  get screen() { return this.f.screen.name; }

  /** The screen as a player sees it, checked. */
  look() {
    const d = describe(this.f);
    this.seen.add(this.screen);
    this.problems.push(...wordProblems(d, this.screen));
    return d;
  }

  labels() { return this.look().choices.map((c) => plain(c.label)); }

  /** The skin's words for the voyage in hand. */
  get words() { return this.f.skin.words(this.f.v); }

  /** Presses the choice that reads as the skin's `markup` does, as far as it goes. */
  say(markup, input) {
    this.press(plain(markup), input);
  }

  /** Presses the choice whose words start with `start` (or the n-th, 1-based). */
  press(start, input) {
    const d = this.look();
    const c = typeof start === 'number' ? d.choices[start - 1] : d.choices.find((x) => plain(x.label).startsWith(start));
    if (!c) throw new Error(`no "${start}" on ${this.screen}: ${d.choices.map((x) => plain(x.label)).join(' / ')}`);
    if (!c.enabled) throw new Error(`"${start}" is not offered on ${this.screen}`);
    if (this.log) console.log(`  [${this.screen}] ${plain(c.label)}`);
    c.act(input);
  }

  /** Fills the cart: `want` is units the shop sells, per item, as many as fit and can be paid for. */
  shop(want) {
    for (const [key, n] of Object.entries(want)) {
      const d = this.look();
      const item = d.blocks.find((b) => b.type === 'item' && b.key === key);
      if (!item) continue;
      for (let i = 0; i < n; i++) {
        const now = this.look().blocks.find((b) => b.type === 'item' && b.key === key);
        const before = this.f.bill;
        if (!now.more()) break;
        if (this.f.bill > this.f.game.money) {
          this.look().blocks.find((b) => b.type === 'item' && b.key === key).less();
          break;
        }
        if (this.f.bill === before) break;
      }
    }
  }

  /** From the title card to the first shop: the journey's first role and usual month by default. */
  setUp({ role, month, names = {} } = {}) {
    const J = this.f.journey, card = this.f.skin.card;
    this.say(card.start);
    this.press(role ?? J.roles[0].label);
    this.press('Use these names', names);
    this.press(month ?? MONTHS[J.id]);
    this.say(card.enterShop);
  }

  /** What to buy to bring each store up to `targets` (stored units), as shop presses. */
  topUp(targets) {
    const g = this.f.game, J = this.f.journey;
    const want = {};
    for (const [key, target] of Object.entries(targets)) {
      const it = J.items.find((i) => i.key === key);
      if (!it) continue;
      const short = target - g[key];
      if (short > 0) want[key] = Math.ceil(short / it.per / it.step);
    }
    this.shop(want);
  }

  /** Lands whatever the mini-game brings, throwing at the nearest fish now and then. */
  fish() {
    const s = this.f.screen;
    let t = 0;
    while (this.screen === 'fishing' && t < 60) {
      this.look();
      if (Math.round(t * 20) % 6 === 0) s.model.aimAtNearest();
      this.f.fishingStep(0.05);
      t += 0.05;
    }
    return s.model.caught;
  }

  /**
   * Plays to the end, carefully: tops up at every port, mends and patches, rests a sick
   * crew once a stop, takes the first answer offered, forages once. Stops every few turns
   * to look after the vessel. `layOver` more rests of the longest kind at every port, as a
   * player in no hurry takes them. The ending's screen name, or 'limit'. Every row it
   * presses is the skin's own words, so it plays any journey.
   */
  voyage({ targets = SAFE[this.f.journey.id], heaveEvery = 4, fishOnce = true, maxSteps = 20000, layOver = 0,
    onScreen = () => {} } = {}) {
    let ticks = 0, fished = !fishOnce;
    const rested = new Set(), shopped = new Set(), laid = new Map();
    let restFor = 3;
    this.caught = null;
    for (let n = 0; n < maxSteps; n++) {
      const name = this.screen;
      if (onScreen(this) === 'stop') return 'stopped';
      const d = this.look();
      const g = this.f.game, v = this.f.v;
      const w = g ? this.words : null;
      switch (name) {
        case 'finale':
        case 'gameOver':
          return name;
        case 'travel':
          if (ticks > 0 && ticks % heaveEvery === 0) {
            ticks += 1;
            this.press(1);
          } else {
            ticks += 1;
            this.timers.fire();
          }
          break;
        case 'depart':
        case 'message':
          this.press(1);
          break;
        case 'choice':
          d.choices.find((c) => c.enabled).act();
          break;
        case 'burial':
          this.press(1, { epitaph: n % 2 ? '' : 'Rest easy.' });
          break;
        case 'shop':
          this.topUp(targets);
          this.press(1);
          break;
        case 'portMenu': {
          const key = `${g.stopIndex}`;
          if (!shopped.has(key)) {
            shopped.add(key);
            this.say(w.buy);
          } else if ((laid.get(key) ?? 0) < layOver) {
            laid.set(key, (laid.get(key) ?? 0) + 1);
            restFor = Math.max(...this.f.journey.rules.restChoices);
            this.say(w.restInPort);
          } else if (v.canRepairHullAtYard && g.hull < 70) {
            this.say(w.yard);
          } else {
            this.say(w.leavePort);
          }
          break;
        }
        case 'shipyard':
          if (v.canRepairHullAtYard && g.hull < 70) this.say(w.yardHull(v.shipyardHullCost));
          else if (v.canRecutSailsAtYard && g.sails < 70) this.say(w.yardSails(v.shipyardSailsCost));
          else this.say(w.leaveYard);
          break;
        case 'seaMenu':
          if ((g.sails < 45 && v.canMendSails) || (g.hull < 45 && v.canPatchHull)) {
            this.say(w.repairs);
          } else if (v.averageHP < 50 && !rested.has(g.stopIndex)) {
            rested.add(g.stopIndex);
            restFor = 3;
            this.say(w.rest);
          } else if (!fished && g.tackle > 0 && v.fishingRefusal == null) {
            fished = true;
            this.say(w.forage);
            if (this.screen === 'fishing') this.caught = this.fish();
          } else {
            this.say(w.carryOn);
          }
          break;
        case 'rest':
          this.say(w.restChoice(restFor));
          break;
        case 'repairs':
          if (g.sails < 45 && v.canMendSails) this.say(w.mend);
          else if (g.hull < 45 && v.canPatchHull) this.say(w.patch);
          else this.press('Done');
          break;
        default:
          throw new Error(`the player doesn't know the ${name} screen`);
      }
    }
    return 'limit';
  }
}

/**
 * Words from the other journeys' worlds that must never reach the Klondike, as the app's
 * `KlondikeSkinTests.elsewhere` sieves them: an 1849 ship at sea (and her crew's dysentery,
 * which the trek calls the flux), a train, an airship, a balloon, a freighter in space. A stampeder has a steamer, a boat with oars & sail,
 * firewood, lime juice, fish and miles, so those stay; and the steamer anchors off Dyea,
 * the White Pass has a wagon road at its foot, the lake fills with sails and rapids throw
 * spray (`KLONDIKE_FIGURES`, taken out before the sieve).
 */
export const KLONDIKE_FOREIGN = new RegExp('\\b(sails|sailing|sailors?|sailcloth|shipwrights?|anchor(s|ed)?|harpoons?|tackle|throws?|voyages?|'
  + 'nm|nautical|knots?|citrus|limes|whal(e|er|ers|ing)|galley|dysentery|'
  + 'trains?|railroad|railway|locomotive|conductor|caboose|boxcars?|cords?|wagons?|oxen|'
  + 'petrol|gondola|hydrogen|propane|burners?|ballast|gallons?|helium|'
  + 'propellant|tonnes?|litres?|kilomet(re|er)s?|km|thrusters?|airlock|orbits?)\\b', 'i');
export const KLONDIKE_FIGURES = ['anchor off Dyea', 'wagon road', 'full of sails', 'throw spray'];

export function klondikeProblems(d, where) {
  const out = [];
  for (const { text } of texts(d)) {
    let said = plain(text);
    for (const f of KLONDIKE_FIGURES) said = said.split(f).join('');
    const m = said.match(KLONDIKE_FOREIGN);
    if (m) out.push(`${where}: "${m[0]}" in ${JSON.stringify(text)}`);
  }
  return out;
}

/**
 * What the careful player keeps aboard, in stored units, by journey: for 1849 the golden
 * voyages' bot's list; on the Iron Road a full tender and tank car, and the rest likewise;
 * over the Pole full tanks, full stores and three bags of ballast; on the jet stream every tank
 * full, and four sacks; on the transfer full tanks and lockers, ten supplement packs and two
 * tether cartridges; on the trail a year's grub for five and two months' eating besides, a full
 * load of firewood for the pass, and the canvas and rope to build a boat and mend on the river.
 */
export const SAFE = {
  horn1849: { food: 1500, water: 600, limes: 10, clothes: 5, meds: 3, sailcloth: 3, timber: 3, tackle: 40 },
  rail: { fuel: 160, water: 1200, food: 300, clothes: 5, meds: 3, sailcloth: 3, timber: 3, tackle: 40 },
  airship: { fuel: 8000, water: 300, food: 300, limes: 10, clothes: 5, meds: 3, sailcloth: 3, timber: 3, tackle: 40 },
  balloon: { fuel: 1200, water: 200, food: 400, limes: 12, clothes: 5, meds: 3, sailcloth: 3, timber: 4, tackle: 40 },
  mars: { fuel: 1000, water: 800, food: 450, limes: 10, clothes: 5, meds: 3, sailcloth: 3, timber: 3, tackle: 40 },
  klondike: { food: 7500, water: 2000, limes: 10, clothes: 5, meds: 6, sailcloth: 4, timber: 5, tackle: 40 },
};

/** The month each journey's careful player leaves in. */
export const MONTHS = { horn1849: 'January 1849', rail: 'October 1869', airship: 'May 1926', balloon: 'January 1999', mars: 'October 2087', klondike: 'March 1898' };
