// What horn.wasm imports and exports, and whether web/engine.js's WASI shim answers
// exactly those imports: none missing (the module would not load) and none spare. Then
// what the shell imports in its turn: every module in web/js loads, with every name it
// imports from another; every engine call the flow and the screens make (and every yard
// question a skin asks) is one engine.js has; and every skin in journeys/skins.js answers
// every member the app's JourneySkin, TitleCard, Words, SceneSkin, ChartSkin, ForageSkin,
// ForageField and DebugSkin declare (AroundTheHorn/Journeys/JourneySkin.swift), and
// nothing they don't, as SkinContractTests holds the app's skins to them; and the hooks
// the bridge sends every journey are named in web/README.md.
//
//   node Tools/web-tests/imports.mjs
import { readFileSync, readdirSync } from 'node:fs';
import path from 'node:path';
import { pathToFileURL } from 'node:url';
import { repo } from './lib.mjs';
import { wasiImports } from '../../web/engine.js';

const mod = new WebAssembly.Module(readFileSync(path.join(repo, 'web/horn.wasm')));
const imports = WebAssembly.Module.imports(mod);
const exports = WebAssembly.Module.exports(mod).map((e) => e.name);
console.log(`imports (${imports.length}): ${imports.map((i) => `${i.module}.${i.name}`).join(' ')}`);
console.log(`exports: ${exports.join(' ')}`);

const shim = wasiImports(() => null);
const wanted = new Set(imports.map((i) => i.name));
const missing = imports.filter((i) => i.module !== 'wasi_snapshot_preview1' || !(i.name in shim));
const spare = Object.keys(shim).filter((n) => !wanted.has(n));
for (const e of ['memory', '_initialize', 'horn_alloc', 'horn_free', 'horn_call', 'horn_reply_len']) {
  if (!exports.includes(e)) missing.push({ module: 'export', name: e });
}
if (missing.length) console.log(`MISSING: ${missing.map((i) => `${i.module}.${i.name}`).join(' ')}`);
if (spare.length) console.log(`SPARE (the module never asks for these): ${spare.join(' ')}`);
const wasiOK = !missing.length && !spare.length;
console.log(wasiOK ? 'imports: the shim answers exactly what the module asks' : 'imports: the shim FAILED');

// MARK: - The shell's own imports

let passed = 0;
const failures = [];
function check(ok, what) {
  if (ok) passed += 1;
  else failures.push(what);
}

// Every module loads, and with it every name it imports (a missing one is a SyntaxError).
// main.js starts the game in a page, so it is read, not run.
const jsDir = path.join(repo, 'web/js');
const modules = readdirSync(jsDir, { recursive: true }).filter((f) => f.endsWith('.js') && f !== 'main.js').sort();
for (const f of modules) {
  try {
    await import(pathToFileURL(path.join(jsDir, f)).href);
    check(true, f);
  } catch (e) {
    check(false, `web/js/${f} does not load: ${e.message}`);
  }
}

const { engine } = await import('./player.mjs');
const { all } = await import('../../web/js/journeys/skins.js');
const e = await engine();

// Every engine call the shell makes is one engine.js has.
const shell = ['flow.js', 'screens.js', 'ui.js', 'fishing.js'].map((f) => readFileSync(path.join(jsDir, f), 'utf8')).join('\n');
const calls = new Set([...shell.matchAll(/\bthis\.run\('(\w+)'/g), ...shell.matchAll(/\b(?:this|c|flow|f)\.engine\.(\w+)\(/g),
  ...shell.matchAll(/\bengine\.(\w+)\(/g)].map((m) => m[1]));
check(calls.has('setSail') && calls.has('rank') && calls.size > 20, `the shell's engine calls are found (${calls.size})`);
for (const m of calls) check(typeof e[m] === 'function', `the shell calls engine.${m}, which engine.js does not have`);

// Every skin answers the app's skin contract, member for member.
const swift = readFileSync(path.join(repo, 'AroundTheHorn/Journeys/JourneySkin.swift'), 'utf8');
const readme = readFileSync(path.join(repo, 'web/README.md'), 'utf8');
/** A Swift struct's members that every skin must answer: its `let`s (a `var` has a default). */
function members(name) {
  const body = swift.match(new RegExp(`\\nstruct ${name} \\{([\\s\\S]*?)\\n\\}`))?.[1] ?? '';
  return { lets: [...body.matchAll(/^ {4}let (\w+):/gm)].map((x) => x[1]),
    vars: [...body.matchAll(/^ {4}var (\w+)\b/gm)].map((x) => x[1]) };
}
const tables = e.journeys();
// Both ways: a journey the engine has with no web skin would be left off the web's picker
// without a word.
for (const J of tables) check(all.some((mod) => mod.id === J.id), `the web has a skin for the engine's journey ${J.id}`);
check(tables.length === all.length, `as many skins as journeys (${all.length}, ${tables.length})`);
for (const mod of all) {
  const J = tables.find((j) => j.id === mod.id);
  check(!!J, `the engine has a journey for the skin ${mod.id}`);
  if (!J) continue;
  const sk = mod.skin(J);
  const dep = J.departures[0];
  e.start({ journey: J.id, role: J.roles[0].role, ship: 'Test', captain: 'Ana', crew: ['Bo', 'Cy', 'Di', 'Ed'],
    year: dep.year, month: dep.month, seed: '1' });
  const v = e.view();
  const words = sk.words(v);
  const parts = { JourneySkin: sk, TitleCard: sk.card, Words: words, SceneSkin: sk.scene, ChartSkin: sk.chart,
    ForageSkin: sk.forage, ForageField: sk.forage.field, DebugSkin: sk.debug };
  for (const [name, o] of Object.entries(parts)) {
    const { lets, vars } = members(name);
    check(lets.length > 0, `${name} has members in the Swift`);
    const have = Object.keys(o);
    const lacking = lets.filter((k) => !have.includes(k)), extra = have.filter((k) => !lets.includes(k) && !vars.includes(k));
    check(!lacking.length, `${mod.id}'s ${name} does not answer ${lacking.join(', ')}`);
    check(!extra.length, `${mod.id}'s ${name} has members the app's has not: ${extra.join(', ')}`);
  }
  // What the shell does with the new members' answers.
  check(typeof words.stopName === 'function' && J.stops.every((st) => typeof words.stopName(st) === 'string'),
    `${mod.id}'s stopName names every stop`);
  check(words.place === null || typeof words.place === 'string', `${mod.id}'s place is a name or nothing`);
  check(typeof words.resumesInFirstShop === 'boolean', `${mod.id}'s resumesInFirstShop is yes or no`);
  check(typeof sk.forage.grouped === 'boolean', `${mod.id}'s forage says whether it groups the thousands`);
  for (const k of ['departRefusal', 'leaveRefusal']) {
    check(words[k] === null || typeof words[k] === 'string', `${mod.id}'s ${k} is a sentence or nothing`);
  }
  const w = words.departWarning;
  check(w === null || ['text', 'back', 'go'].every((k) => typeof w[k] === 'string'), `${mod.id}'s departWarning has its text and answers`);
  check(words.yardQuestion === null || typeof e[words.yardQuestion] === 'function',
    `${mod.id}'s yard question is an engine call engine.js has (${words.yardQuestion})`);
  check(Object.values(words.looseOne ?? {}).every((x) => typeof x === 'string'), `${mod.id}'s looseOne names`);
  // The hooks every journey has (not under a journey's id) are each named in the README,
  // so a skin's author can find what the bridge answers (D19, D21, D22).
  for (const k of Object.keys(v.hooks).filter((k) => !tables.some((j) => j.id === k))) {
    check(new RegExp(`\`(hooks\\.)?${k}\``).test(readme), `web/README names the bridge's shared hook ${k}`);
  }
  e.close();
}

console.log(`imports: ${passed} shell checks passed, ${failures.length} failed`);
for (const f of failures) console.log(`FAILED ${f}`);
process.exit(wasiOK && !failures.length ? 0 : 1);
