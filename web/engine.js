// The game's engine, in the browser or in Node.
//
// horn.wasm is the Swift engine (HornEngine) and its JSON bridge (HornWeb/Bridge.swift)
// compiled to WebAssembly. This file gives it the little of WASI it asks for (`wasi`
// below: no files, no arguments, a clock, the console and random bytes) and wraps the
// bridge in one method per call. The calls are GameEngine's, under the same names, so a
// flow written after the app's GameController reads the same.
//
//   import { loadEngine, newSeed, readInterrupt } from './engine.js';
//   const engine = await loadEngine();
//   const [horn] = engine.journeys();
//   let r = engine.start({ journey: horn.id, role: 'merchant', ship: 'Resolute', captain: 'Ezra',
//                          crew: ['Hannah', 'Silas', 'Mercy', 'Tobias'], year: 1849, month: 0,
//                          seed: newSeed() });
//   r.view.state.money   // the GameState, exactly as the app saves it
//
// Every voyage call returns the bridge's reply: `view` (the state and what the screens
// read off it) and, as the call has them, `interrupts`, `result`, `score`, `rank`,
// `pending`. A refused request throws an Error with the bridge's message.

const WASI_ERRNO = { SUCCESS: 0, BADF: 8, INVAL: 28, NOSYS: 52, NOTCAPABLE: 76 };

class ProcExit extends Error {
  constructor(code) {
    super(`horn.wasm exited with code ${code}`);
    this.code = code;
  }
}

/** A fresh seed for a voyage: 64 random bits, as the decimal string the bridge takes. */
export function newSeed() {
  const a = new BigUint64Array(1);
  globalThis.crypto.getRandomValues(a);
  return a[0].toString();
}

/**
 * The WASI preview 1 imports horn.wasm has (Tools/web-tests/imports.mjs lists them and
 * checks this covers exactly those). There is no file system: every path and descriptor
 * call answers "bad descriptor", so Foundation finds no files, as on a fresh device.
 * Output to stdout and stderr goes to the console.
 */
export function wasiImports(getMemory, log = console) {
  const view = () => new DataView(getMemory().buffer);
  const bytes = () => new Uint8Array(getMemory().buffer);
  const decoder = new TextDecoder();
  const lines = { 1: '', 2: '' };
  const bad = () => WASI_ERRNO.BADF;

  return {
    args_sizes_get(argc, bufSize) {
      view().setUint32(argc, 0, true);
      view().setUint32(bufSize, 0, true);
      return WASI_ERRNO.SUCCESS;
    },
    args_get() {
      return WASI_ERRNO.SUCCESS;
    },
    environ_sizes_get(count, bufSize) {
      view().setUint32(count, 0, true);
      view().setUint32(bufSize, 0, true);
      return WASI_ERRNO.SUCCESS;
    },
    environ_get() {
      return WASI_ERRNO.SUCCESS;
    },
    clock_res_get(id, out) {
      view().setBigUint64(out, 1000n, true);
      return WASI_ERRNO.SUCCESS;
    },
    clock_time_get(id, precision, out) {
      // 0 is the wall clock; the others are monotonic.
      const ms = id === 0 ? Date.now() : globalThis.performance.now();
      view().setBigUint64(out, BigInt(Math.round(ms * 1e6)), true);
      return WASI_ERRNO.SUCCESS;
    },
    random_get(buf, len) {
      // getRandomValues fills at most 65536 bytes at a time.
      for (let off = 0; off < len; off += 65536) {
        globalThis.crypto.getRandomValues(bytes().subarray(buf + off, buf + Math.min(len, off + 65536)));
      }
      return WASI_ERRNO.SUCCESS;
    },
    fd_write(fd, iovs, iovsLen, nwritten) {
      if (fd !== 1 && fd !== 2) return WASI_ERRNO.BADF;
      let total = 0;
      let text = '';
      for (let i = 0; i < iovsLen; i++) {
        const ptr = view().getUint32(iovs + i * 8, true);
        const len = view().getUint32(iovs + i * 8 + 4, true);
        text += decoder.decode(bytes().slice(ptr, ptr + len));
        total += len;
      }
      const all = lines[fd] + text;
      const parts = all.split('\n');
      lines[fd] = parts.pop();
      for (const p of parts) (fd === 1 ? log.log : log.error).call(log, p);
      view().setUint32(nwritten, total, true);
      return WASI_ERRNO.SUCCESS;
    },
    fd_read(fd, iovs, iovsLen, nread) {
      // stdin is empty; nothing else is open.
      if (fd !== 0) return WASI_ERRNO.BADF;
      view().setUint32(nread, 0, true);
      return WASI_ERRNO.SUCCESS;
    },
    fd_fdstat_get(fd, out) {
      if (fd > 2) return WASI_ERRNO.BADF;
      // A character device, no flags, every right.
      const v = view();
      v.setUint8(out, 2);
      v.setUint16(out + 2, 0, true);
      v.setBigUint64(out + 8, 0xffffffffffffffffn, true);
      v.setBigUint64(out + 16, 0xffffffffffffffffn, true);
      return WASI_ERRNO.SUCCESS;
    },
    fd_fdstat_set_flags: (fd) => (fd > 2 ? WASI_ERRNO.BADF : WASI_ERRNO.SUCCESS),
    fd_close: (fd) => (fd > 2 ? WASI_ERRNO.BADF : WASI_ERRNO.SUCCESS),
    fd_sync: (fd) => (fd > 2 ? WASI_ERRNO.BADF : WASI_ERRNO.SUCCESS),
    // No preopened directories: the module sees no file system at all.
    fd_prestat_get: bad,
    fd_prestat_dir_name: bad,
    fd_filestat_get: bad,
    fd_filestat_set_times: bad,
    fd_pread: bad,
    fd_readdir: bad,
    fd_seek: bad,
    path_create_directory: bad,
    path_filestat_get: bad,
    path_filestat_set_times: bad,
    path_link: bad,
    path_open: bad,
    path_readlink: bad,
    path_remove_directory: bad,
    path_rename: bad,
    path_symlink: bad,
    path_unlink_file: bad,
    poll_oneoff: () => WASI_ERRNO.NOSYS,
    proc_exit(code) {
      throw new ProcExit(code);
    },
  };
}

/** The bytes of horn.wasm: fetched beside this file in a browser, read from disk in Node. */
async function wasmSource(source) {
  if (source instanceof ArrayBuffer || ArrayBuffer.isView(source)) return source;
  const url = source ?? new URL('./horn.wasm', import.meta.url);
  if (typeof process !== 'undefined' && process.versions?.node && String(url).startsWith('file:')) {
    const { readFile } = await import('node:fs/promises');
    return readFile(url);
  }
  const res = await fetch(url);
  if (!res.ok) throw new Error(`could not load ${url}: ${res.status}`);
  return res.arrayBuffer();
}

/**
 * Loads horn.wasm and returns an Engine. `source` is a URL, or the module's bytes;
 * by default horn.wasm next to this file.
 */
export async function loadEngine(source) {
  const bytes = await wasmSource(source);
  let memory;
  const { instance } = await WebAssembly.instantiate(bytes, {
    wasi_snapshot_preview1: wasiImports(() => memory),
  });
  memory = instance.exports.memory;
  instance.exports._initialize();
  return new Engine(instance.exports);
}

/** One method per bridge call (HornWeb/Bridge.swift). */
export class Engine {
  constructor(exports) {
    this.x = exports;
    this.encoder = new TextEncoder();
    this.decoder = new TextDecoder();
  }

  /** Sends one request; returns the reply's fields, or throws the bridge's refusal. */
  request(req) {
    const x = this.x;
    const data = this.encoder.encode(JSON.stringify(req));
    const p = x.horn_alloc(data.length);
    new Uint8Array(x.memory.buffer, p, data.length).set(data);
    let text;
    try {
      const r = x.horn_call(p, data.length);
      const n = x.horn_reply_len();
      text = this.decoder.decode(new Uint8Array(x.memory.buffer, r, n).slice());
    } finally {
      x.horn_free(p);
    }
    const reply = JSON.parse(text);
    if (!reply.ok) throw new Error(reply.error);
    delete reply.ok;
    return reply;
  }

  // Tables and helpers: no voyage needed.

  /** Every journey's tables, in the picker's order. */
  journeys() { return this.request({ op: 'journeys' }).journeys; }
  rank(journey, score) { return this.request({ op: 'rank', journey, score }).result; }
  /** TopTen.inserting: `{ table, place }`, place null when the score didn't make it. */
  topTen(journey, name, score, table) { return this.request({ op: 'topTen', journey, name, score, table }); }
  bill(journey, port, cart) { return this.request({ op: 'bill', journey, port, cart }).result; }
  formatNumber(n) { return this.request({ op: 'formatNumber', n }).result; }
  escape(text) { return this.request({ op: 'escape', text }).result; }
  /** One name as the names screen keeps it: trimmed, the suggestion if blank, cut to `max`. */
  name(typed, suggested, max) { return this.request({ op: 'name', typed, suggested, max }).result; }

  // The voyage in hand.

  /** GameController.chooseDeparture. `seed`: newSeed(), or a fixed one to replay a voyage. */
  start({ journey, role, ship, captain, crew, year, month, seed }) {
    return this.request({ op: 'start', journey, role, ship, captain, crew, year, month, seed: String(seed) });
  }
  /** A save from `save()`; the reply's `pending` is what was waiting on screen. */
  load(save, seed, journey) { return this.request({ op: 'load', save, seed: String(seed), journey }); }
  /** The save file, as the app writes it: the GameState's keys and `pending` beside them. */
  save(pending = []) { return this.request({ op: 'save', pending }).save; }
  view() { return this.request({ op: 'view' }).view; }
  close() { return this.request({ op: 'close' }); }

  buy(cart) { return this.request({ op: 'buy', cart }); }
  depart() { return this.request({ op: 'depart' }); }
  setSail() { return this.request({ op: 'setSail' }); }
  sailDay() { return this.request({ op: 'sailDay' }); }
  rest(days) { return this.request({ op: 'rest', days }); }
  mendSails() { return this.request({ op: 'mendSails' }); }
  patchHull() { return this.request({ op: 'patchHull' }); }
  repairHullAtYard() { return this.request({ op: 'repairHullAtYard' }); }
  recutSailsAtYard() { return this.request({ op: 'recutSailsAtYard' }); }
  tradeAtPort() { return this.request({ op: 'tradeAtPort' }); }
  talk() { return this.request({ op: 'talk' }); }
  throwHarpoon() { return this.request({ op: 'throwHarpoon' }); }
  landCatch(caught) { return this.request({ op: 'landCatch', caught }); }
  beginArrival(stopID) { return this.request({ op: 'beginArrival', stopID }); }
  /** `choice` is the ChoiceEvent exactly as an interrupt carried it. */
  resolve(choice, option) { return this.request({ op: 'resolve', choice, option }); }
  commitBurial(crewID, cause, epitaph) { return this.request({ op: 'commitBurial', crewID, cause, epitaph }); }
  finish() { return this.request({ op: 'finish' }); }
  setPace(pace) { return this.request({ op: 'setPace', pace }); }
  setRations(rations) { return this.request({ op: 'setRations', rations }); }
}

/**
 * An interrupt as Swift's Codable writes it (`{"message":{"_0":"…"}}`), read into
 * `{ type, … }`: message {text}, choice {choice}, burial {crewID, cause}, arrival {stopID},
 * enterPort, gameOver {title, body}, finale. Hand the original back to the engine (save,
 * resolve), never this.
 */
export function readInterrupt(i) {
  const [type] = Object.keys(i);
  const v = i[type] ?? {};
  switch (type) {
    case 'message': return { type, text: v._0 };
    case 'choice': return { type, choice: v._0 };
    case 'burial': return { type, crewID: v.crewID, cause: v.cause };
    case 'arrival': return { type, stopID: v.stopID };
    case 'gameOver': return { type, title: v.title, body: v.body };
    default: return { type };
  }
}

/** A ChoiceEvent's kind, read the same way: `{ type, … }` (`custom` has key and args). */
export function readChoiceKind(kind) {
  const [type] = Object.keys(kind);
  const v = kind[type] ?? {};
  return { type, ...('_0' in v ? { value: v._0 } : v) };
}
