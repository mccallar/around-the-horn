// Shared pieces of the web tests: the engine's generator, the golden voyages' hash, the
// two ways of reaching the bridge (horn.wasm, or the same bridge built for the Mac), and
// a bot that plays a voyage through either.
import { spawn, spawnSync } from 'node:child_process';
import { existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
import os from 'node:os';
import { loadEngine } from '../../web/engine.js';

export const repo = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');

const MASK = (1n << 64n) - 1n;

/** SeededRNG (HornEngine/RNG.swift): SplitMix64, the top 53 bits for a unit. */
export class SeededRNG {
  constructor(seed) { this.state = BigInt.asUintN(64, BigInt(seed)); }
  next() {
    this.state = (this.state + 0x9E3779B97F4A7C15n) & MASK;
    let z = this.state;
    z = ((z ^ (z >> 30n)) * 0xBF58476D1CE4E5B9n) & MASK;
    z = ((z ^ (z >> 27n)) * 0x94D049BB133111EBn) & MASK;
    return z ^ (z >> 31n);
  }
  nextUnit() { return Number(this.next() >> 11n) * 2 ** -53; }
  /** `int(a, b)`: both ends included. */
  int(a, b) { return a + Math.trunc(this.nextUnit() * (b - a + 1)); }
  chance(p) { return this.nextUnit() < p; }
}

/** A Double's bits in hex, as Swift's `String(x.bitPattern, radix: 16)`. */
const f64 = new DataView(new ArrayBuffer(8));
export function bits(x) {
  f64.setFloat64(0, x);
  return f64.getBigUint64(0).toString(16);
}

/**
 * FNV-1a, 64 bits, each string followed by a newline: GoldenBot.mix. Kept in two 32-bit
 * halves, since BigInt would make the 300 voyages crawl.
 */
export class Fnv {
  constructor() {
    this.hi = 0xcbf29ce4;
    this.lo = 0x84222325;
    this.enc = new TextEncoder();
  }
  byte(b) {
    // h ^= b; h *= 0x100000001b3, i.e. h * 0x1b3 + (h << 40), modulo 2^64.
    let lo = (this.lo ^ b) >>> 0;
    const hi = this.hi;
    const a = lo * 0x1b3;
    const loNew = a >>> 0;
    const carry = Math.floor(a / 0x100000000);
    const hiNew = (Math.imul(hi, 0x1b3) + carry + (lo << 8)) >>> 0;
    this.lo = loNew;
    this.hi = hiNew;
  }
  mix(s) {
    for (const b of this.enc.encode(s)) this.byte(b);
    this.byte(0x0a);
  }
  get hex() {
    return ((BigInt(this.hi) << 32n) | BigInt(this.lo)).toString(16);
  }
}

// MARK: - Backends

/** horn.wasm, through web/engine.js. */
export async function wasmBackend() {
  const engine = await loadEngine();
  return { name: 'wasm', call: async (req) => engine.request(req), close() {} };
}

/**
 * The same bridge built for the Mac with the Mac's Swift (HornWeb/main.swift), one JSON
 * request per line on stdin. HORN_NATIVE names a built binary; otherwise it is built here.
 */
export function nativeBinary() {
  if (process.env.HORN_NATIVE) return process.env.HORN_NATIVE;
  const scratch = path.join(process.env.TMPDIR || os.tmpdir(), 'horn-web-native');
  const r = spawnSync('swift', ['build', '--disable-sandbox', '--scratch-path', scratch, '--product', 'HornWeb'],
    { cwd: repo, encoding: 'utf8' });
  if (r.status !== 0) throw new Error(`swift build failed:\n${r.stdout}\n${r.stderr}`);
  const bin = path.join(scratch, 'debug', 'HornWeb');
  if (!existsSync(bin)) throw new Error(`no binary at ${bin}`);
  return bin;
}

export function nativeBackend(bin) {
  const child = spawn(bin, [], { stdio: ['pipe', 'pipe', 'inherit'] });
  const waiting = [];
  // Split on "\n" alone: readline would also split inside a string at U+2028 and U+2029,
  // which JSON leaves unescaped.
  let rest = '';
  child.stdout.setEncoding('utf8');
  child.stdout.on('data', (chunk) => {
    const parts = (rest + chunk).split('\n');
    rest = parts.pop();
    for (const l of parts) waiting.shift()(l);
  });
  return {
    name: 'native',
    call(req) {
      return new Promise((resolve, reject) => {
        waiting.push((l) => {
          const r = JSON.parse(l);
          if (!r.ok) return reject(new Error(r.error));
          delete r.ok;
          resolve(r);
        });
        child.stdin.write(JSON.stringify(req) + '\n');
      });
    },
    close() { child.stdin.end(); },
  };
}

// MARK: - Comparing

const UUID = /^[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}$/;

/**
 * Crew ids are random UUIDs on both sides (Foundation's own generator, not the game's),
 * so a trace names them by order of appearance instead.
 */
export class UUIDNames {
  constructor() { this.names = new Map(); }
  of(v) {
    if (typeof v === 'string' && UUID.test(v)) {
      if (!this.names.has(v)) this.names.set(v, `uuid#${this.names.size}`);
      return this.names.get(v);
    }
    if (Array.isArray(v)) return v.map((x) => this.of(x));
    if (v && typeof v === 'object') {
      const o = {};
      for (const k of Object.keys(v).sort()) o[k] = this.of(v[k]);
      return o;
    }
    return v;
  }
}

/** The first place two JSON values differ, or null. Numbers must be the same Double. */
export function firstDifference(a, b, at = '') {
  if (typeof a === 'number' && typeof b === 'number') {
    return Object.is(a, b) ? null : `${at}: ${a} vs ${b}`;
  }
  if (a === null || b === null || typeof a !== 'object' || typeof b !== 'object') {
    return a === b ? null : `${at}: ${JSON.stringify(a)} vs ${JSON.stringify(b)}`;
  }
  if (Array.isArray(a) !== Array.isArray(b)) return `${at}: array vs object`;
  const keys = [...new Set([...Object.keys(a), ...Object.keys(b)])].sort();
  for (const k of keys) {
    if (!(k in a) || !(k in b)) return `${at}.${k}: only in ${k in a ? 'the first' : 'the second'}`;
    const d = firstDifference(a[k], b[k], `${at}.${k}`);
    if (d) return d;
  }
  return null;
}

// MARK: - The bot

/** What the careful bots buy at every port, up to these stored amounts (GoldenBot.shopping). */
const SHOPPING = [['food', 1500], ['water', 600], ['limes', 10], ['clothes', 5], ['meds', 3],
  ['sailcloth', 3], ['timber', 3], ['tackle', 40]];

/**
 * GoldenBot (HornEngineTests/GoldenVoyageTests.swift), line for line, driving the bridge.
 * With 1849 it reproduces the golden fixture's hash. On another journey it shops from that
 * journey's items (and fills the tank, if it has one) and plays by the same rules.
 *
 * `trace`, if given, receives every request and reply, for comparing two backends.
 */
export class Bot {
  constructor({ backend, journey, role, seed, wild, names, trace, saveEvery = 0 }) {
    this.b = backend;
    this.j = journey;
    this.role = role;
    this.seed = BigInt(seed);
    this.wild = wild;
    this.names = names ?? { ship: 'Resolute', captain: 'Ezra', crew: ['Hannah', 'Silas', 'Mercy', 'Tobias'] };
    this.trace = trace;
    /** Every so many turns, save (with what's waiting) and load again, as leaving the app would. */
    this.saveEvery = saveEvery;
    this.d = new SeededRNG((this.seed * 0x9E3779B97F4A7C15n + 7n) & MASK);
    this.h = new Fnv();
    this.ticks = 0;
    this.rested = new Set();
    this.shopping = [...SHOPPING];
    const fuel = journey.items.find((i) => i.key === 'fuel');
    if (fuel) this.shopping.push(['fuel', fuel.cap]);
  }

  async call(req) {
    const r = await this.b.call(req);
    if (this.trace) this.trace.push({ req, r });
    if (r.view) this.v = r.view;
    return r;
  }

  get s() { return this.v.state; }
  mix(s) { this.h.mix(s); }

  mixState() {
    const s = this.s;
    const f = s.flags;
    this.mix(`S|${s.day}|${s.mile}|${bits(s.money)}|${bits(s.food)}|${bits(s.water)}|${bits(s.limes)}|${s.meds}|${s.clothes}`
      + `|${s.sailcloth}|${s.timber}|${s.tackle}|${bits(s.hull)}|${bits(s.sails)}|${s.weather.rawValue}|${s.stopIndex}`
      + `|${s.passage ?? '-'}|${s.pilot}|${s.noCitrus}|${s.badLuck}|${s.forceFair}|${s.tradesLeft}`
      + `|${s.talkIndex}|${s.atPort}|${s.over}|${s.note}|${s.albatrossSeen}|${s.stowawaySeen}|${s.starving}`
      + `|${s.thirst}|${s.pace}|${s.rations}|${this.v.dateText}|draws ${this.v.draws}`);
    this.mix(`W|${f.food}|${f.lowFood}|${f.water}|${f.lowWater}|${f.limes}|${f.hull}|${f.sails}`);
    for (const c of s.crew) {
      this.mix(`C|${c.name}|${bits(c.hp)}|${c.ailment?.rawValue ?? '-'}|${bits(c.ailDays)}|${c.treated}|${c.alive}`
        + `|${c.isCaptain}|${c.leaveAt ?? '-'}`);
    }
    for (const g of s.graves) this.mix(`G|${g.name}|${g.cause}|${g.date}|${g.epitaph}`);
  }

  async play() {
    const dep = this.j.departures[Number(this.seed % BigInt(this.j.departures.length))];
    await this.call({ op: 'start', journey: this.j.id, role: this.role, ...this.names,
      year: dep.year, month: dep.month, seed: this.seed.toString() });
    let ending = 'limit';
    await this.shop();
    if (this.s.food <= 0) {
      const r = await this.call({ op: 'depart' });
      if (r.result !== undefined && r.result !== null) throw new Error('departed with no food');
      this.mix('N|' + this.j.text.noProvisions);
      await this.call({ op: 'buy', cart: { food: Math.min(this.v.room.food, 4) } });
    }
    const dr = await this.call({ op: 'depart' });
    this.mix('D|' + (dr.result ?? 'refused'));
    if (!this.s.atPort) {
      loop: for (let n = 0; n < 3000; n++) {
        this.mixState();
        let route = await this.seaTurn();
        if (route.over) { ending = route.over; break loop; }
        this.ticks += 1;
        if (this.saveEvery && this.ticks % this.saveEvery === 0 && !this.s.over) await this.saveAndLoad([]);
        route = await this.process((await this.call({ op: 'sailDay' })).interrupts);
        if (route.port) {
          const p = await this.portVisit();
          if (p.over) { ending = p.over; break loop; }
        } else if (route.over) {
          ending = route.over;
          break loop;
        }
      }
    } else {
      ending = 'never-sailed';
    }
    this.mixState();
    return { ending, ticks: this.ticks, draws: this.v.draws, hash: this.h.hex };
  }

  /** Leaves and comes back: the save and the queue go out as JSON and come back in. */
  async saveAndLoad(pending) {
    const { save } = await this.call({ op: 'save', pending });
    const r = await this.call({ op: 'load', save: JSON.parse(JSON.stringify(save)), seed: this.v.rng });
    return r.pending;
  }

  async seaTurn() {
    const d = this.d;
    const wild = this.wild;
    if (wild > 0) {
      if (d.chance(0.05 * wild)) await this.call({ op: 'setPace', pace: ['easy', 'steady', 'full'][d.int(0, 2)] });
      if (d.chance(0.05 * wild)) await this.call({ op: 'setRations', rations: ['filling', 'meager', 'bare'][d.int(0, 2)] });
      if (d.chance(0.04 * wild)) {
        const r = await this.process((await this.call({ op: 'rest', days: d.int(1, 3) })).interrupts);
        if (r.over) return r;
      }
      if (d.chance(0.06 * wild)) {
        const no = this.v.fishingRefusal;
        if (no !== undefined && no !== null) {
          this.mix('N|' + no);
        } else {
          const throws = d.int(1, 12);
          for (let i = 0; i < throws; i++) this.mix(`H|${(await this.call({ op: 'throwHarpoon' })).result}`);
          const r = await this.process((await this.call({ op: 'landCatch', caught: d.int(0, 420) })).interrupts);
          if (r.over) return r;
        }
      }
    }
    for (let i = 0; i < 6; i++) {
      const s = this.s;
      let op;
      if (this.v.canMendSails && (s.sails < 45 || d.chance(0.03 * wild))) op = 'mendSails';
      else if (this.v.canPatchHull && (s.hull < 45 || d.chance(0.03 * wild))) op = 'patchHull';
      else break;
      const r = await this.process((await this.call({ op })).interrupts);
      if (r.over) return r;
    }
    if (wild === 0 && this.v.averageHP < 50 && !this.rested.has(this.s.stopIndex)) {
      this.rested.add(this.s.stopIndex);
      const r = await this.process((await this.call({ op: 'rest', days: 3 })).interrupts);
      if (r.over) return r;
    }
    await this.call({ op: 'setSail' });
    return {};
  }

  async portVisit() {
    const d = this.d;
    if (d.chance(0.6)) {
      const r = await this.process((await this.call({ op: 'rest', days: d.int(1, 3) })).interrupts);
      if (r.over) return r;
    }
    const asks = d.int(0, 5);
    for (let i = 0; i < asks; i++) {
      const r = await this.process((await this.call({ op: 'tradeAtPort' })).interrupts);
      if (r.over) return r;
    }
    const talks = d.int(0, 4);
    for (let i = 0; i < talks; i++) this.mix('T|' + (await this.call({ op: 'talk' })).result);
    const v = this.v;
    this.mix(`Y|${v.shipyardHullCost}|${v.shipyardSailsCost}|${v.canRepairHullAtYard}|${v.canRecutSailsAtYard}`);
    if (this.v.canRepairHullAtYard && d.chance(0.7)) {
      const r = await this.process((await this.call({ op: 'repairHullAtYard' })).interrupts);
      if (r.over) return r;
    }
    if (this.v.canRecutSailsAtYard && d.chance(0.7)) {
      const r = await this.process((await this.call({ op: 'recutSailsAtYard' })).interrupts);
      if (r.over) return r;
    }
    await this.shop();
    await this.call({ op: 'setSail' });
    return {};
  }

  async shop() {
    const v = this.v;
    if (v.currentPort === undefined || v.currentPort === null) return;
    const d = this.d;
    const items = this.j.items;
    const price = (k) => v.prices[k];
    const cart = {};
    let total = 0;
    if (this.wild >= 1) {
      for (const it of items) {
        const afford = Math.floor((this.s.money - total) / price(it.key));
        const most = Math.trunc(Math.max(0, Math.min(v.room[it.key], afford)) / it.step);
        const n = most > 0 ? d.int(0, most) * it.step : 0;
        cart[it.key] = n;
        total += n * price(it.key);
      }
    } else {
      for (const [k, target] of this.shopping) {
        const it = items.find((i) => i.key === k);
        if (!it) continue;
        let n = Math.min(v.room[k], Math.max(0, Math.ceil((target - this.s[k]) / it.per / it.step) * it.step));
        const p = price(k);
        while (n > 0 && total + n * p > this.s.money) n -= it.step;
        n = Math.max(0, n);
        cart[k] = n;
        total += n * p;
      }
    }
    this.mix('K|' + items.map((it) => `${it.key}=${cart[it.key] ?? 0}@${bits(price(it.key))}`).join(','));
    const bill = (await this.call({ op: 'bill', journey: this.j.id, port: v.currentPort, cart })).result;
    const bought = (await this.call({ op: 'buy', cart })).result;
    this.mix(`K|${bits(bill)}|${bought}`);
  }

  async process(initial) {
    const d = this.d;
    let q = [...initial];
    let asked = 0;
    while (q.length) {
      const i = q.shift();
      const [type] = Object.keys(i);
      const x = i[type];
      if (this.saveEvery && !this.s.over && type !== 'enterPort' && type !== 'finale' && type !== 'gameOver'
          && this.d.chance(0.02)) {
        // Leave with this on screen and the rest queued; come back to the same.
        q = await this.saveAndLoad([i, ...q]);
        continue;
      }
      if (type === 'message') {
        this.mix('M|' + x._0);
      } else if (type === 'choice') {
        const c = x._0;
        this.mix(`Q|${c.prompt}|${c.detail ?? '-'}|` + c.options.map((o) => `${o.label}:${o.enabled}`).join('/'));
        const open = c.options.map((o, n) => (o.enabled ? n : -1)).filter((n) => n >= 0);
        asked += 1;
        let pick = open[d.int(0, open.length - 1)];
        if ('fork' in c.kind) pick = d.int(0, asked > 40 ? 1 : 2);
        else if (this.wild === 0 || asked > 40) pick = open[0];
        this.mix(`A|${pick}`);
        q = [...(await this.call({ op: 'resolve', choice: c, option: pick })).interrupts, ...q];
      } else if (type === 'burial') {
        const who = this.s.crew.find((p) => p.id === x.crewID)?.name ?? '?';
        this.mix(`B|${who}|${x.cause}`);
        await this.call({ op: 'commitBurial', crewID: x.crewID, cause: x.cause,
          epitaph: d.chance(0.5) ? '' : `Rest easy, ${who}.` });
      } else if (type === 'arrival') {
        this.mix('R|' + x.stopID);
        q = [...(await this.call({ op: 'beginArrival', stopID: x.stopID })).interrupts, ...q];
      } else if (type === 'enterPort') {
        this.mix('P');
        return { port: true };
      } else if (type === 'gameOver') {
        this.mix(`X|${x.title}|${x.body}`);
        return { over: 'gameover' };
      } else if (type === 'finale') {
        const r = await this.call({ op: 'finish' });
        const sc = r.score;
        this.mix('F|' + sc.lines.map((l) => `${l.label}=${l.points}`).join('/')
          + `|${sc.subtotal}|${sc.multiplier}|${sc.total}`);
        return { over: 'finale' };
      } else {
        throw new Error(`unknown interrupt ${type}`);
      }
    }
    return {};
  }
}
