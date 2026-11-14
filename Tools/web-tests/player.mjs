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
    if (markup) out.push(...markupProblems(text).map((p) => `${where}: ${p}`));
  }
  for (const c of d.choices) if (!plain(c.label).trim()) out.push(`${where}: a blank choice`);
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

  static async make({ engine: e, storage = new MemoryStorage(), seeds = ['1'], random = lcg(7), log } = {}) {
    const timers = new FakeTimers();
    let n = 0;
    const flow = new Flow({ engine: e ?? await engine(), storage, timers, random, seed: () => seeds[n++ % seeds.length] });
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

  /** From the title card to the first shop. */
  setUp({ role = 'A Boston', month = 'January 1849', names = {} } = {}) {
    this.press('Sail for California');
    this.press(role);
    this.press('Use these names', names);
    this.press(month);
    this.press('Enter the shop');
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
   * crew once a stop, takes the first answer offered, fishes once. Heaves to every few
   * days to look after the ship. The ending's screen name, or 'limit'.
   */
  voyage({ targets = SAFE, heaveEvery = 4, fishOnce = true, maxSteps = 20000, onScreen = () => {} } = {}) {
    let ticks = 0, fished = !fishOnce;
    const rested = new Set(), shopped = new Set();
    this.caught = null;
    for (let n = 0; n < maxSteps; n++) {
      const name = this.screen;
      if (onScreen(this) === 'stop') return 'stopped';
      const d = this.look();
      const g = this.f.game;
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
            this.press('Buy supplies');
          } else if (this.f.v.canRepairHullAtYard && g.hull < 70) {
            this.press('Visit the shipyard');
          } else {
            this.press('Weigh anchor');
          }
          break;
        }
        case 'shipyard':
          if (this.f.v.canRepairHullAtYard && g.hull < 70) this.press('Haul out');
          else if (this.f.v.canRecutSailsAtYard && g.sails < 70) this.press('Have new sails');
          else this.press('Leave the shipyard');
          break;
        case 'seaMenu':
          if ((g.sails < 45 && this.f.v.canMendSails) || (g.hull < 45 && this.f.v.canPatchHull)) {
            this.press('Make repairs');
          } else if (this.f.v.averageHP < 50 && !rested.has(g.stopIndex)) {
            rested.add(g.stopIndex);
            this.press('Heave to and rest');
          } else if (!fished && g.tackle > 0) {
            fished = true;
            this.press('Go fishing');
            if (this.screen === 'fishing') this.caught = this.fish();
          } else {
            this.press('Continue on your voyage');
          }
          break;
        case 'rest':
          this.press('3 days');
          break;
        case 'repairs':
          if (g.sails < 45 && this.f.v.canMendSails) this.press('Mend sails');
          else if (g.hull < 45 && this.f.v.canPatchHull) this.press('Patch the hull');
          else this.press('Done');
          break;
        default:
          throw new Error(`the player doesn't know the ${name} screen`);
      }
    }
    return 'limit';
  }
}

/** What the careful player keeps aboard, in stored units (the golden voyages' bot's list). */
export const SAFE = { food: 1500, water: 600, limes: 10, clothes: 5, meds: 3, sailcloth: 3, timber: 3, tackle: 40 };
