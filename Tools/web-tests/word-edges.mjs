// The words each web skin shows at the edge of each condition that picks them, against the
// same expectations as the app's (AroundTheHornTests/Fixtures/word-edges.json, read by
// AroundTheHornTests/WordEdgeTests.swift): a `<` that became `<=` on either platform fails.
//
//   node Tools/web-tests/word-edges.mjs
import { readFileSync } from 'node:fs';
import path from 'node:path';
import { repo } from './lib.mjs';
import { engine } from './player.mjs';
import { all } from '../../web/js/journeys/skins.js';

let passed = 0;
const failures = [];
const check = (ok, what) => { if (ok) passed++; else failures.push(what); };

const fixture = JSON.parse(readFileSync(path.join(repo, 'AroundTheHornTests/Fixtures/word-edges.json'), 'utf8'));
const e = await engine();
const tables = e.journeys();
check(JSON.stringify(Object.keys(fixture.journeys).sort()) === JSON.stringify(tables.map((J) => J.id).sort()),
  'every journey has its edges');
const KNOWN = ['clothes', 'noCitrus', 'day', 'fuel', 'money'];
let cases = 0;
for (const [id, list] of Object.entries(fixture.journeys)) {
  const J = tables.find((x) => x.id === id);
  const sk = all.find((m) => m.id === id).skin(J);
  const d = J.departures[0];
  const merchant = J.roles.find((r) => r.role === 'merchant').role;
  e.start({ journey: id, role: merchant, ship: 'Wren', captain: 'Ada', crew: ['Bo', 'Cy', 'Di', 'Ed'], year: d.year, month: d.month, seed: '1' });
  const base = e.save([]);
  e.close();
  for (const c of list) {
    for (const k of Object.keys(c.set)) check(KNOWN.includes(k), `${id}: the fixture sets ${k}, which the app's test does not know`);
    let v;
    try {
      v = e.load({ ...base, ...c.set }, '1', id).view;
    } finally {
      e.close();
    }
    const what = `${id} ${JSON.stringify(c.set)} ${c.field}`;
    const words = sk.words(v);
    check(c.field in words, `${what}: no such field`);
    const got = words[c.field] ?? null;
    cases++;
    if ('is' in c) check(got === c.is, `${what}: ${JSON.stringify(got)}, not ${JSON.stringify(c.is)}`);
    if ('has' in c) check(got != null && got.includes(c.has), `${what}: ${JSON.stringify(got)} lacks ${JSON.stringify(c.has)}`);
    if ('lacks' in c) check(got == null || !got.includes(c.lacks), `${what}: ${JSON.stringify(got)} has ${JSON.stringify(c.lacks)}`);
  }
}
check(cases > 30, `the cases were read (${cases})`);
for (const f of failures) console.log(`FAILED ${f}`);
console.log(`word-edges: ${passed} checks passed, ${failures.length} failed`);
process.exit(failures.length ? 1 : 0);
