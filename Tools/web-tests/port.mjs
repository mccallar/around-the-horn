// Checking a web port against the app's Swift: every player-facing piece of every string
// literal in the Swift is in the JavaScript, and the colours are the same. Shared by the
// skin tests of each journey.
import { readFileSync } from 'node:fs';
import path from 'node:path';
import { repo } from './lib.mjs';

const read = (p) => readFileSync(path.join(repo, p), 'utf8');

/** A Swift file's string literals, each as the fixed pieces around its interpolations. */
export function swiftLiterals(src) {
  const out = [];
  // Comments go first: a doc comment can hold quotes.
  const code = src.replace(/\/\*[\s\S]*?\*\//g, '').replace(/\/\/[^\n]*/g, '');
  let i = 0;
  while (i < code.length) {
    if (code[i] !== '"') { i++; continue; }
    let j = i + 1;
    const pieces = [];
    let cur = '';
    while (j < code.length && code[j] !== '"') {
      if (code[j] === '\\' && code[j + 1] === '(') {
        pieces.push(cur);
        cur = '';
        let depth = 1;
        j += 2;
        while (j < code.length && depth > 0) {
          if (code[j] === '(') depth++;
          else if (code[j] === ')') depth--;
          else if (code[j] === '"') {
            // A literal inside the interpolation: skip it.
            j++;
            while (j < code.length && code[j] !== '"') j += code[j] === '\\' ? 2 : 1;
          }
          j++;
        }
        continue;
      }
      if (code[j] === '\\') {
        cur += code.slice(j, j + 2);
        j += 2;
        continue;
      }
      cur += code[j++];
    }
    pieces.push(cur);
    out.push(pieces);
    i = j + 1;
  }
  return out;
}

/**
 * `check(ok, what)` for every piece of every literal in `swiftFiles` that has a letter in
 * it: it must be somewhere in `jsFiles`. `ignore` holds whole literals that are not a
 * player's words (debug names, keys). With `allHaveWords`, each Swift file must have some.
 */
export function portChecks(check, swiftFiles, jsFiles, ignore = new Set(), { allHaveWords = true } = {}) {
  const js = jsFiles.map(read).join('\n');
  for (const f of swiftFiles) {
    let n = 0;
    for (const pieces of swiftLiterals(read(f))) {
      const whole = pieces.join('…');
      if (ignore.has(whole)) continue;
      for (const piece of pieces) {
        if (piece.trim().length < 2 || !/[A-Za-z]/.test(piece)) continue;
        n++;
        check(js.includes(piece), `${path.basename(f)}: "${piece}" (of "${whole}") is not in the web version`);
      }
    }
    if (allHaveWords) check(n > 0, `${f} has words to port`);
  }
}

/** Every 0x hex colour in a file, in order. */
export const hexes = (src) => [...src.matchAll(/0x([0-9A-Fa-f]{6})\b/g)].map((m) => m[1].toUpperCase());
