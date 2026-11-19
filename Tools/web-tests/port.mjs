// Checking a web port against the app's Swift: every player-facing piece of every string
// literal in the Swift is in the JavaScript's literals, every one in the JavaScript that
// may be words is in the Swift's, and the colours are the same. Shared by the
// skin tests of each journey.
import { readFileSync } from 'node:fs';
import path from 'node:path';
import { repo } from './lib.mjs';

const read = (p) => readFileSync(path.join(repo, p), 'utf8');

/**
 * A Swift file's string literals, each as the fixed pieces around its interpolations (a
 * literal inside an interpolation is one of its own).
 */
export function swiftLiterals(src) {
  const out = [];
  // Comments go first: a doc comment can hold quotes.
  const code = src.replace(/\/\*[\s\S]*?\*\//g, '').replace(/\/\/[^\n]*/g, '');
  // The literal opening at `i`, pushed to `out`; the index after it.
  const literal = (i) => {
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
          else if (code[j] === '"') { j = literal(j); continue; }
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
    return j + 1;
  };
  let i = 0;
  while (i < code.length) {
    if (code[i] === '"') i = literal(i);
    else i++;
  }
  return out;
}

/**
 * A JavaScript file's string and template literals, each as the fixed pieces around its
 * `${…}` interpolations (a literal inside an interpolation is one of its own), with
 * comments left out: a ported comment may quote old words. With `errors: false`, the
 * messages of `new Error(…)`, which no player reads, are left out too.
 */
export function jsLiterals(src, { errors = true } = {}) {
  const out = [];
  const n = src.length;
  // The literal opening at `i`, pushed to `out` (unless `keep` is false); the index after it.
  const literal = (i, keep = true) => {
    const q = src[i];
    let j = i + 1, cur = '';
    const pieces = [];
    while (j < n && src[j] !== q) {
      if (src[j] === '\\') { cur += src.slice(j, j + 2); j += 2; continue; }
      if (q === '`' && src[j] === '$' && src[j + 1] === '{') {
        pieces.push(cur);
        cur = '';
        let depth = 1;
        j += 2;
        while (j < n && depth > 0) {
          if (src[j] === '{') depth++;
          else if (src[j] === '}') depth--;
          else if (src[j] === "'" || src[j] === '"' || src[j] === '`') { j = literal(j, keep); continue; }
          j++;
        }
        continue;
      }
      cur += src[j++];
    }
    pieces.push(cur);
    if (keep) out.push(pieces);
    return j + 1;
  };
  let i = 0;
  while (i < n) {
    const c = src[i];
    if (c === '/' && src[i + 1] === '/') { while (i < n && src[i] !== '\n') i++; continue; }
    if (c === '/' && src[i + 1] === '*') { i = src.indexOf('*/', i + 2) + 2; continue; }
    if (!errors && src.startsWith('new Error(', i)) {
      const j = i + 'new Error('.length;
      if (src[j] === "'" || src[j] === '"' || src[j] === '`') { i = literal(j, false); continue; }
    }
    if (c === '"' || c === "'" || c === '`') { i = literal(i); continue; }
    i++;
  }
  return out;
}

/** A piece of a literal that may be words: a letter in it, and not a lone key or a path. */
const mayBeWords = (piece) => piece.trim().length >= 2 && /[A-Za-z]/.test(piece)
  && !/^[a-z][\w$]*$/.test(piece) && !/^\.{0,2}\/[\w./-]+$/.test(piece);

/**
 * `check(ok, what)` for every piece of every literal in `swiftFiles` that has a letter in
 * it: it must be in a literal of `jsFiles` (not in a comment). With `bothWays`, the other
 * way too: every piece of a JS literal that may be words must be in a Swift literal, so
 * the web can't say more than the app. `ignore` holds whole literals that are not a
 * player's words (debug names, keys). With `allHaveWords`, each Swift file must have some.
 */
export function portChecks(check, swiftFiles, jsFiles, ignore = new Set(), { allHaveWords = true, bothWays = true } = {}) {
  const js = jsFiles.flatMap((f) => jsLiterals(read(f)).flat()).join('\u0000');
  const swiftPieces = [];
  for (const f of swiftFiles) {
    let n = 0;
    for (const pieces of swiftLiterals(read(f))) {
      swiftPieces.push(...pieces);
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
  if (!bothWays) return;
  const swift = swiftPieces.join('\u0000');
  for (const f of jsFiles) {
    for (const pieces of jsLiterals(read(f), { errors: false })) {
      const whole = pieces.join('…');
      if (ignore.has(whole)) continue;
      for (const piece of pieces) {
        if (!mayBeWords(piece) || ignore.has(piece)) continue;
        check(swift.includes(piece), `${path.basename(f)}: "${piece}" (of "${whole}") is not in the app's Swift`);
      }
    }
  }
}

/** Every 0x hex colour in a file, in order. */
export const hexes = (src) => [...src.matchAll(/0x([0-9A-Fa-f]{6})\b/g)].map((m) => m[1].toUpperCase());
