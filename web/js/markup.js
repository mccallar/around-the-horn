// The game's text markup and the little formatting the screens do, as the app does it.
//
// Markup (AroundTheHorn/UI/Markup.swift, spec §13): `[red]…[/red]`, `[green]`, `[amber]`,
// `[dim]`, `[teal]`, `[i]`, `[b]`, and `[[` for a literal "[". Anything else in brackets
// is plain text. Player-entered names arrive escaped, so they never turn into markup.

export const STYLES = ['red', 'green', 'amber', 'dim', 'teal', 'i', 'b'];
const COLORED = new Set(['red', 'green', 'amber', 'dim', 'teal']);

/** Markup.runs: the text in runs, each with the styles open over it, innermost last. */
export function runs(s) {
  const out = [];
  const stack = [];
  let buf = '';
  const flush = () => {
    if (buf) out.push({ text: buf, styles: [...stack] });
    buf = '';
  };
  let i = 0;
  while (i < s.length) {
    if (s.startsWith('[[', i)) {
      buf += '[';
      i += 2;
      continue;
    }
    if (s[i] === '[') {
      const close = s.indexOf(']', i);
      if (close >= 0) {
        const tag = s.slice(i + 1, close);
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
    buf += s[i];
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

/** TextMarkup.escape: a player's string made safe to put in markup. */
export function escape(s) {
  return String(s).replaceAll('[', '[[');
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
