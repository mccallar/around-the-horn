// The engine in horn.wasm against the same engine built for the Mac, request for request.
//
// The bridge (HornWeb) is built twice: to WebAssembly (web/horn.wasm, as the browser runs
// it) and for the Mac with the Mac's own Swift and Foundation (the build the app's engine
// tests run on). The same bot plays the same seeded voyages of every journey through each,
// saving and reloading along the way, and every reply must be the same JSON: the whole
// GameState with every Double bit for bit, the dates, every sentence, every choice. Crew
// ids are random on both sides, so they are compared by order of appearance.
//
//   node Tools/web-tests/parity.mjs            (builds the Mac side with `swift build`)
//   HORN_NATIVE=<built HornWeb> node Tools/web-tests/parity.mjs
//   VOYAGES=60 node Tools/web-tests/parity.mjs (per role and journey; default 20)
import { Bot, UUIDNames, firstDifference, nativeBackend, nativeBinary, wasmBackend } from './lib.mjs';

const perRole = Number(process.env.VOYAGES ?? 20);
const wasm = await wasmBackend();
const native = nativeBackend(nativeBinary());
let failures = 0;

function fail(what) {
  failures += 1;
  console.log(`DIFFERS ${what}`);
}

/** The same requests to both; the replies compared. */
async function both(req) {
  const [a, b] = await Promise.all([wasm.call(req), native.call(req)]);
  const d = firstDifference(a, b);
  if (d) fail(`${JSON.stringify(req).slice(0, 120)}: ${d}`);
  return a;
}

// 1. The tables every screen reads.
const journeys = (await both({ op: 'journeys' })).journeys;

// 2. The helpers. (An Int is 32 bits in WebAssembly; the bridge refuses a number past that.)
for (const n of [1e15, -(2 ** 40), 2 ** 31]) {
  for (const b of [wasm, native]) {
    if (await b.call({ op: 'formatNumber', n }).then(() => true, () => false)) fail(`${b.name} formatted ${n}`);
  }
}
for (const n of [0, -0.5, 0.999, 1, 999.99, 1000, -1234.5, 1234567.89, 2147483646.5, -2147483646.9, 7.000000000000001]) {
  await both({ op: 'formatNumber', n });
}
const awkward = ['', 'Ezra', 'Ez[ra', '[[b]]', '[red]x[/red]', 'Zoë', 'Zoë', '[́', 'ナオミ', 'Ana[\u0301]', ' \u0301Ana', '\u0301 Ana \u0301', '👩‍🚀 Ada',
  '  spaced  ', ' Ana ', '　Kenji　', '\tTab\n', ' Line ', 'Zero​width',
  'A very long name that goes on and on past the limit'];
for (const text of awkward) {
  await both({ op: 'escape', text });
  for (const max of [16, 22]) await both({ op: 'name', typed: text, suggested: 'Hannah', max });
}
for (const j of journeys) {
  for (const score of [-1, 0, 1999, 2000, 3999, 4000, 6999, 7000, 123456]) await both({ op: 'rank', journey: j.id, score });
  for (const score of [0, 500, 2500, 9000, 99999]) await both({ op: 'topTen', journey: j.id, name: 'Ezra', score });
  for (const p of j.ports) {
    const cart = Object.fromEntries(j.items.map((it, i) => [it.key, (i * 7) % 13]));
    await both({ op: 'bill', journey: j.id, port: p.id, cart });
  }
}

// 3. Voyages, through each backend on its own, then the two traces side by side.
const crews = [
  { ship: 'Resolute', captain: 'Ezra', crew: ['Hannah', 'Silas', 'Mercy', 'Tobias'] },
  { ship: 'Zoë [II]', captain: 'Ez[ra', crew: ['ナオミ', '👩‍🚀 Ada', 'Zoë', '[b]Bold[/b]'] },
];
let voyages = 0;
let requests = 0;
const t0 = Date.now();
for (const j of journeys) {
  const endings = {};
  for (const [r, role] of ['merchant', 'shipwright', 'whaler'].entries()) {
    for (let i = 0; i < perRole; i++) {
      const seed = 70000 + r * 1000 + i + (j.id === 'horn1849' ? 0 : 100000);
      const opts = { journey: j, role, seed, wild: [0, 0.35, 1][i % 3], names: crews[i % 2], saveEvery: i % 4 === 3 ? 0 : 17 + i };
      const ta = [];
      const tb = [];
      const a = await new Bot({ ...opts, backend: wasm, trace: ta }).play();
      const b = await new Bot({ ...opts, backend: native, trace: tb }).play();
      voyages += 1;
      requests += ta.length;
      endings[a.ending] = (endings[a.ending] ?? 0) + 1;
      const na = new UUIDNames();
      const nb = new UUIDNames();
      let diff = ta.length === tb.length ? null : `${ta.length} requests vs ${tb.length}`;
      for (let k = 0; k < Math.min(ta.length, tb.length) && !diff; k++) {
        const d = firstDifference(na.of(ta[k]), nb.of(tb[k]));
        if (d) diff = `request ${k} (${ta[k].req.op}): ${d}`;
      }
      if (a.hash !== b.hash && !diff) diff = 'hash differs';
      if (diff) fail(`${j.id} ${role}-${i}: ${diff}`);
    }
  }
  console.log(`${j.id}: ${3 * perRole} voyages, endings ${JSON.stringify(endings)}`);
}
native.close();
console.log(`parity: ${voyages} voyages, ${requests} requests each way, `
  + `${failures ? `${failures} DIFFERENCES` : 'every reply identical'} (${((Date.now() - t0) / 1000).toFixed(1)} s)`);
process.exit(failures ? 1 : 0);
