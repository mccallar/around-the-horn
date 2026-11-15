// What horn.wasm imports and exports, and whether web/engine.js's WASI shim answers
// exactly those imports: none missing (the module would not load) and none spare.
//
//   node Tools/web-tests/imports.mjs
import { readFileSync } from 'node:fs';
import path from 'node:path';
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
console.log(missing.length || spare.length ? 'imports: FAILED' : 'imports: the shim answers exactly what the module asks');
process.exit(missing.length || spare.length ? 1 : 0);
