// The game's text markup and the little formatting the screens do, as the app does it.
//
// Markup (AroundTheHorn/UI/Markup.swift, spec §13): `[red]…[/red]`, `[green]`, `[amber]`,
// `[dim]`, `[teal]`, `[i]`, `[b]`, and `[[` for a literal "[". Anything else in brackets
// is plain text. Player-entered names arrive escaped, so they never turn into markup.

export const STYLES = ['red', 'green', 'amber', 'dim', 'teal', 'i', 'b'];
const COLORED = new Set(['red', 'green', 'amber', 'dim', 'teal']);

// Swift's Characters: the app's Markup.runs reads text Character by Character, and a "["
// or a "]" another character joins (a combining mark after it, a Prepend before it) is
// that other character, not a bracket. Intl.Segmenter's graphemes are the same clusters.
const GRAPHEMES = typeof Intl === 'object' && typeof Intl.Segmenter === 'function'
  ? new Intl.Segmenter('en', { granularity: 'grapheme' }) : null;

/** The text as Swift's Characters (by code point where a browser can't segment). */
export function characters(s) {
  return GRAPHEMES ? Array.from(GRAPHEMES.segment(s), (g) => g.segment) : Array.from(s);
}

/** Markup.runs: the text in runs, each with the styles open over it, innermost last. */
export function runs(s) {
  if (!s.includes('[')) return s ? [{ text: s, styles: [] }] : [];
  const c = characters(s);
  const out = [];
  const stack = [];
  let buf = '';
  const flush = () => {
    if (buf) out.push({ text: buf, styles: [...stack] });
    buf = '';
  };
  let i = 0;
  while (i < c.length) {
    if (c[i] === '[' && c[i + 1] === '[') {
      buf += '[';
      i += 2;
      continue;
    }
    if (c[i] === '[') {
      const close = c.indexOf(']', i);
      if (close >= 0) {
        const tag = c.slice(i + 1, close).join('');
        if (tag.startsWith('/')) {
          const st = tag.slice(1);
          const at = STYLES.includes(st) ? stack.lastIndexOf(st) : -1;
          if (at >= 0) {
            flush();
            stack.splice(at, 1);
            i = close + 1;
            continue;
          }
        } else if (STYLES.includes(tag)) {
          flush();
          stack.push(tag);
          i = close + 1;
          continue;
        }
      }
    }
    buf += c[i];
    i += 1;
  }
  flush();
  return out;
}

/** Markup.plain: every tag removed. */
export function plain(s) {
  return runs(s).map((r) => r.text).join('');
}

const HTML = { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' };

/** Text made safe to put in HTML. */
export function html(s) {
  return String(s).replace(/[&<>"']/g, (c) => HTML[c]);
}

/**
 * Markup as HTML: each run a span. The colour is the innermost coloured style's, and [b]
 * with no colour is amber (neither pixel font has a bold face); [i] is slanted.
 */
export function toHTML(s) {
  return runs(s).map((r) => {
    const color = [...r.styles].reverse().find((st) => COLORED.has(st)) ?? (r.styles.includes('b') ? 'amber' : null);
    const cls = [color, r.styles.includes('i') ? 'it' : null].filter(Boolean);
    return cls.length ? `<span class="${cls.join(' ')}">${html(r.text)}</span>` : html(r.text);
  }).join('');
}

/**
 * TextMarkup.escape, as Foundation finds "[" on Apple platforms: every "[" doubled, unless
 * the scalar after it makes it another character (a combining mark, anything
 * Grapheme_Extend, an emoji skin tone). A Prepend before it does not, unlike a Character.
 */
const LONE_BRACKET = /\[(?![\p{Grapheme_Extend}\p{Emoji_Modifier}])/gu;
export function escape(s) {
  return String(s).replace(LONE_BRACKET, '[[');
}

/** The engine's `formatNumber`: floor, then thousands separators. */
export function formatNumber(n) {
  const v = Math.floor(n);
  const digits = String(Math.abs(v));
  let out = '';
  for (let i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 === 0) out += ',';
    out += digits[i];
  }
  return (v < 0 ? '-' : '') + out;
}

/** `Math.round`, as the app's `jsRounded`: halves go up. */
export function jsRounded(x) {
  const f = Math.floor(x);
  return x - f >= 0.5 ? f + 1 : f;
}

/**
 * Swift's `String(format: "%.2f", x)`. `toFixed` rounds the exact value as printf does,
 * except at an exact tie (only an eighth can be one), which printf gives to the even cent.
 */
export function fixed2(x) {
  const t = x * 100;
  if (Number.isInteger(x * 8) && Math.abs(t - Math.trunc(t)) === 0.5) {
    const f = Math.floor(t);
    return ((f % 2 === 0 ? f : f + 1) / 100).toFixed(2);
  }
  return x.toFixed(2);
}

export const monthNames = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September',
  'October', 'November', 'December'];
