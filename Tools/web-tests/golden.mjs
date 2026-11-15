// The 300 golden 1849 voyages (HornEngineTests/GoldenVoyageTests.swift), played through
// horn.wasm by the same bot, must hash exactly as the Mac recorded them: every Double of
// the state before every sailing day bit for bit, every sentence, every choice, burial and
// score line, and how many random numbers had been drawn.
//
//   node Tools/web-tests/golden.mjs
import { readFileSync } from 'node:fs';
import path from 'node:path';
import { Bot, repo, wasmBackend } from './lib.mjs';

const fixture = readFileSync(path.join(repo, 'HornEngineTests/Fixtures/golden-voyages.txt'), 'utf8')
  .split('\n').filter(Boolean).map((l) => {
    const [name, ending, ticks, draws, hash] = l.split(' ');
    return { name, ending, ticks: Number(ticks), draws: Number(draws), hash };
  });

const backend = await wasmBackend();
const journeys = (await backend.call({ op: 'journeys' })).journeys;
const horn = journeys.find((j) => j.id === 'horn1849');

const t0 = Date.now();
let failed = 0;
let n = 0;
for (const [r, role] of ['merchant', 'shipwright', 'whaler'].entries()) {
  for (let i = 0; i < 100; i++) {
    const name = `${role}-${i}`;
    const bot = new Bot({ backend, journey: horn, role, seed: 50000 + r * 1000 + i, wild: [0, 0.35, 1][i % 3] });
    const got = await bot.play();
    const want = fixture[n++];
    const line = `${name} ${got.ending} ${got.ticks} ${got.draws} ${got.hash}`;
    const wantLine = `${want.name} ${want.ending} ${want.ticks} ${want.draws} ${want.hash}`;
    if (line !== wantLine) {
      failed += 1;
      if (failed <= 5) console.log(`DIFFERS\n  wasm     ${line}\n  recorded ${wantLine}`);
    }
  }
}
const endings = fixture.reduce((m, f) => ({ ...m, [f.ending]: (m[f.ending] ?? 0) + 1 }), {});
console.log(`golden: ${n - failed}/${n} voyages identical to the Mac's record `
  + `(${JSON.stringify(endings)}) in ${((Date.now() - t0) / 1000).toFixed(1)} s`);
if (n !== fixture.length || n !== 300) { console.log('the fixture is not 300 voyages'); process.exit(1); }
process.exit(failed ? 1 : 0);
