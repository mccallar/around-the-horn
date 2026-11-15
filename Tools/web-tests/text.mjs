// The game's text as the app treats it, in horn.wasm and in the page: names and epitaphs
// trimmed as Foundation trims them, a player's "[" escaped as Foundation finds it, and
// markup read Character by Character, as the app's Markup.runs reads it. Every expected
// answer here is the Mac's: Foundation's, and the app's Markup.runs run there.
// parity.mjs holds horn.wasm to the Mac build of the bridge on every scalar.
//
//   node Tools/web-tests/text.mjs
import { engine } from './player.mjs';
import { escape, runs } from '../../web/js/markup.js';

let passed = 0;
const failures = [];
function check(ok, what) {
  if (ok) passed += 1;
  else failures.push(what);
}
/** A string with everything past printable ASCII written as \u{…}, for the report. */
const show = (s) => [...s].map((c) => (/^[\x20-\x7e]$/.test(c) ? c : `\\u{${c.codePointAt(0).toString(16).toUpperCase()}}`)).join('');
const same = (a, b) => JSON.stringify(a) === JSON.stringify(b);

const e = await engine();

// 1. Trimming: Apple's `.whitespacesAndNewlines` is Unicode's White_Space and U+200B.
const trims = [
  ['\u{200B}', ''],
  ['\u{200B}Ana\u{200B}', 'Ana'],
  [' \u{200B} Ana \u{200B} ', 'Ana'],
  ['\u{3000}Kenji\u{3000}', 'Kenji'],
  ['\u{200B}\u{301}Ana', '\u{301}Ana'],
  ['Zero\u{200B}width', 'Zero\u{200B}width'],
  ['\u{200C}\u{200D}\u{2060}\u{FEFF}Ana', '\u{200C}\u{200D}\u{2060}\u{FEFF}Ana'],
  ['\u{180E}Ana', '\u{180E}Ana'],
  ['\u{85}\u{A0}\u{1680}Ana\u{2028}\u{2029}\u{202F}\u{205F}', 'Ana'],
];
for (const [typed, want] of trims) {
  const got = e.name(typed, 'Hannah', 16);
  check(got === (want || 'Hannah'), `the name "${show(typed)}" is kept as "${show(want || 'Hannah')}" (got "${show(got)}")`);
}

const [j] = e.journeys();
const dep = j.departures[0];
const v = e.start({ journey: j.id, role: 'merchant', ship: 'Resolute', captain: 'Ezra', crew: ['Hannah', 'Silas', 'Mercy', 'Tobias'],
  year: dep.year, month: dep.month, seed: 1 }).view;
const who = v.state.crew[1].id;
for (const [typed, want] of [['\u{200B}', 'Fair winds, shipmate.'], [' \u{200B}Rest easy.\u{200B}\n', 'Rest easy.'], ...trims.slice(1)]) {
  const graves = e.commitBurial(who, 'scurvy', typed).view.state.graves;
  const got = graves[graves.length - 1].epitaph;
  check(got === (want || 'Fair winds, shipmate.'), `the epitaph "${show(typed)}" is "${show(want)}" (got "${show(got)}")`);
}

// 2. Escaping: Foundation's search doubles a "[" unless the scalar after it makes it
// another character; a Prepend before it does not (Swift's Character would).
const escapes = [
  ['\u{600}[red]Queen', '\u{600}[[red]Queen'],
  ['\u{600}[[b]x', '\u{600}[[[[b]x'],
  ['[\u{301}x', '[\u{301}x'],
  ['a[\u{200D}b', 'a[[\u{200D}b'],
  ['[\u{903}x', '[[\u{903}x'],
  ['[\u{1F3FB}', '[\u{1F3FB}'],
  ['[\u{FE0F}', '[\u{FE0F}'],
  ['[\u{E0020}', '[\u{E0020}'],
  ['[\u{200C}x', '[\u{200C}x'],
  ['Ez[ra', 'Ez[[ra'],
  ['[[b]]', '[[[[b]]'],
  ['\u{600}[', '\u{600}[['],
];
for (const [text, want] of escapes) {
  const got = e.escape(text);
  check(got === want, `the engine escapes "${show(text)}" as "${show(want)}" (got "${show(got)}")`);
  check(escape(text) === want, `the page escapes "${show(text)}" as "${show(want)}" (got "${show(escape(text))}")`);
}
// The page's escape (the skins' lines with a ship's name in them) and the engine's agree on
// "[" beside every scalar there is, after it and before it.
let differ = 0;
for (let plane = 0; plane <= 0x10; plane++) {
  let text = '';
  for (let c = plane * 0x10000; c < (plane + 1) * 0x10000; c++) {
    if (c >= 0xd800 && c <= 0xdfff) continue;
    const x = String.fromCodePoint(c);
    text += `${x}[${x}\u{1}`;
  }
  const a = e.escape(text);
  const b = escape(text);
  if (a !== b) {
    differ += 1;
    const at = [...a].findIndex((ch, i) => ch !== [...b][i]);
    failures.push(`plane ${plane}: the page and the engine escape differently near "${show([...a].slice(Math.max(0, at - 3), at + 3).join(''))}"`);
  }
}
check(differ === 0, 'the page escapes as the engine does, beside every scalar');

// 3. Markup, by Character: the app's Markup.runs, as run on a Mac.
const R = (text, ...styles) => ({ text, styles });
const markups = [
  ['\u{600}[[red]Q', [R('\u{600}['), R('Q', 'red')]],
  ['[red]\u{301}x[/red]', [R('[red]\u{301}x[/red]')]],
  ['[\u{301}red]q', [R('[\u{301}red]q')]],
  ['[[\u{301}red]q', [R('[[\u{301}red]q')]],
  ['a\u{903}[red]b[/red]', [R('a\u{903}'), R('b', 'red')]],
  ['a[[\u{200D}red]b', [R('a[[\u{200D}red]b')]],
  ['[red]a[b]b[/red]c[/b]', [R('a', 'red'), R('b', 'red', 'b'), R('c', 'b')]],
  ['[[red]x[/red]', [R('[red]x[/red]')]],
  ['[red][/red]', []],
  ['[i]x[/b]y[/i]', [R('x[/b]y', 'i')]],
  ['x]\u{301}[red]y', [R('x]\u{301}'), R('y', 'red')]],
  ['The [i]\u{600}[[red]Queen[/i] whistles off', [R('The '), R('\u{600}[', 'i'), R('Queen', 'i', 'red'), R(' whistles off', 'red')]],
  ['The [i]\u{600}[[[[b]x[/i] whistles off', [R('The '), R('\u{600}[[', 'i'), R('x', 'i', 'b'), R(' whistles off', 'b')]],
  ['The [i]Ez[[ra[/i] whistles off', [R('The '), R('Ez[ra', 'i'), R(' whistles off')]],
  ['The [i]a[[\u{200D}red]b[/i] whistles off', [R('The '), R('a[[\u{200D}red]b', 'i'), R(' whistles off')]],
  ['The [i]Ana[\u{301}red][/i] whistles off', [R('The '), R('Ana[\u{301}red]', 'i'), R(' whistles off')]],
  ['plain', [R('plain')]],
  ['', []],
];
for (const [text, want] of markups) {
  const got = runs(text);
  check(same(got, want), `"${show(text)}" reads as the app reads it: ${JSON.stringify(got.map((r) => [show(r.text), ...r.styles]))}`);
}
// The engine's own departure line, with such a name in it, is the one above.
const rail = e.journeys().find((x) => x.id === 'rail');
e.start({ journey: 'rail', role: 'merchant', ship: '\u{600}[red]Queen', captain: 'Ezra', crew: ['Hannah', 'Silas', 'Mercy', 'Tobias'],
  year: rail.departures[0].year, month: rail.departures[0].month, seed: 2 });
e.buy({ food: 200 });
const line = e.depart().result ?? '';
check(line.startsWith('The [i]\u{600}[[red]Queen[/i] whistles off from the Omaha yard'),
  `the engine writes the name into its line as Foundation escapes it: "${show(line.slice(0, 40))}"`);

console.log(`text: ${passed} passed, ${failures.length} failed`);
for (const f of failures.slice(0, 20)) console.log(`FAILED ${f}`);
process.exit(failures.length ? 1 : 0);
