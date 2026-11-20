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
 * The text of a JS literal that builds the page's HTML: its tags, its attributes and its
 * CSS variables cut out, so what is left is what the player reads (or hears, from an
 * `aria-label`'s value, which is kept as a piece of its own).
 */
const textOf = (whole) => [
  ...whole.replace(/<\/?[a-z][a-z0-9]*(\s[^<>]*)?\/?>/gi, '…').replace(/<[a-z][a-z0-9]*(?=…|$)/gi, '…')
    .replace(/\s*[a-z-]+="[^"]*"/gi, '…').replace(/^[^<>"]*">|"[^<>"]*$/g, '…').replace(/var\(--[a-z-]+\)/g, '…')
    .split('…'),
  ...[...whole.matchAll(/aria-(?:label|description)="([^"]*)"/g)].flatMap((m) => m[1].split('…')),
];

/**
 * `check(ok, what)` for every piece of every literal in `swiftFiles` that has a letter in
 * it: it must be in a literal of `jsFiles` (not in a comment). With `bothWays`, the other
 * way too: every piece of a JS literal that may be words must be in a Swift literal, so
 * the web can't say more than the app; with `markup`, a JS literal's HTML is cut out first
 * (`textOf`). `ignore` holds whole literals, or pieces of the JS's, that are not a
 * player's words (debug names, keys, the DOM's own strings). With `allHaveWords`, each
 * Swift file must have some.
 */
export function portChecks(check, swiftFiles, jsFiles, ignore = new Set(), { allHaveWords = true, bothWays = true, markup = false } = {}) {
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
      for (const piece of markup ? textOf(whole) : pieces) {
        if (!mayBeWords(piece) || ignore.has(piece)) continue;
        check(swift.includes(piece), `${path.basename(f)}: "${piece}" (of "${whole}") is not in the app's Swift`);
      }
    }
  }
}

/** Every 0x hex colour in a file, in order. */
export const hexes = (src) => [...src.matchAll(/0x([0-9A-Fa-f]{6})\b/g)].map((m) => m[1].toUpperCase());

/**
 * `check` that a Swift file and its port use the same colours in the same order, so two
 * colours swapped between drawings fail. A chart's route colour is a field of its skin,
 * which the Swift writes first and the JavaScript last: it is compared on its own.
 */
export function sameColours(check, swiftFile, jsFile, label) {
  const route = /routeColor:\s*(?:Color\(hex:\s*|hex\()0x([0-9A-Fa-f]{6})\b/g;
  const sw = read(swiftFile), js = read(jsFile);
  const routes = (src) => [...src.matchAll(route)].map((m) => m[1].toUpperCase());
  const rest = (src) => hexes(src.replace(route, ''));
  const a = rest(sw), b = rest(js);
  let k = 0;
  while (k < a.length && a[k] === b[k]) k++;
  check(a.length === b.length && k === a.length,
    `${label}: the colours are the app's, in its order (${a.length} and ${b.length}; from the ${k + 1}th: ${a.slice(k, k + 3)} | ${b.slice(k, k + 3)})`);
  check(JSON.stringify(routes(sw)) === JSON.stringify(routes(js)), `${label}: the route's colour is the app's`);
}

/**
 * The numbers in a piece of either source, in order. Comments and the Swift's type names
 * hold no data, nor do a closure's `$0`, a Swift tuple's `.0` or an index's `[0]`; a digit
 * group's `_` is the same number either side, and a Swift colour written in fractions of
 * 255 is the JS's `rgb` of the same three.
 */
export const numbers = (s) => [...s.replace(/\/\/[^\n]*/g, '').replace(/\/\*\*?[\s\S]*?\*\//g, '').replace(/UInt32|Int\b/g, '')
  .replace(/ \/ 255/g, '').replace(/radix: 16/g, '').replace(/(?<=\d)_(?=\d)/g, '')
  .replace(/\$\d/g, '').replace(/(?<=[A-Za-z_)\]])\.\d+\b/g, '').replace(/(?<=[A-Za-z_)\]])\[\d+\]/g, '')
  .matchAll(/-?\d+(\.\d+)?/g)].map((m) => Number(m[0]));

/**
 * `check` that each Swift piece writes the same numbers as its JS piece, in the same order,
 * so a transposed pair (`x + 1, y + 2` for `x + 2, y + 1`) fails. Each of `pairs` is
 * `[swFrom, swTo, jsFrom, jsTo, jsExtra, swExtra]`: a piece runs from its first marker to
 * the next. An extra is what one side writes and the other does not: a string or a pattern
 * is cut from that side's text (once, and it must be there), a number drops the first of
 * it from that side's numbers.
 */
export function sameNumbers(check, swiftFile, jsFile, pairs) {
  const sw = read(swiftFile), js = read(jsFile);
  const between = (s, a, b, file) => {
    const i = s.indexOf(a), j = i < 0 ? -1 : s.indexOf(b, i + a.length);
    check(i >= 0 && j >= 0, `${file}: the markers ${JSON.stringify(a)} and ${JSON.stringify(b)} are there, in order`);
    return i >= 0 && j >= 0 ? s.slice(i, j) : '';
  };
  const less = (text, drop, file) => {
    for (const x of drop.filter((x) => typeof x !== 'number')) {
      const cut = text.replace(x, '');
      check(cut !== text, `${file}: ${x} is there to set aside`);
      text = cut;
    }
    const out = numbers(text);
    for (const n of drop.filter((x) => typeof x === 'number')) {
      const i = out.indexOf(n);
      check(i >= 0, `${file}: a ${n} is there to set aside`);
      if (i >= 0) out.splice(i, 1);
    }
    return out;
  };
  for (const [a, b, c, d, jsExtra = [], swExtra = []] of pairs) {
    const s = less(between(sw, a, b, swiftFile), swExtra, swiftFile), j = less(between(js, c, d, jsFile), jsExtra, jsFile);
    let k = 0;
    while (k < s.length && s[k] === j[k]) k++;
    check(s.length > 0 && s.length === j.length && k === s.length,
      `${a}: the numbers are the app's, in order (${s.length} and ${j.length}; from the ${k + 1}th: ${s.slice(k, k + 4).join(' ')} | ${j.slice(k, k + 4).join(' ')})`);
  }
}
