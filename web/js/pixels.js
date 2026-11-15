// The pixel canvas every scene, chart and mini-game draws on (AroundTheHorn/UI/Scenes/
// PixelCanvas.swift), and the pieces scenes are made of. A drawing works on a logical grid
// (160×80 for a scene); each logical pixel is `scale` device pixels, every edge snapped to
// a whole one, as the app does it.
//
// Two surfaces: `ContextCanvas` paints a browser canvas; `BufferCanvas` paints a plain
// RGBA buffer, for Node, where there is nothing else to paint on.

import { jsRounded } from './markup.js';

/** A colour: channels 0–255, alpha 0–1. */
export function rgb(r, g, b, a = 1) {
  return { r, g, b, a, css: `rgba(${r},${g},${b},${a})` };
}

/** `Color(hex:)`. */
export function hex(n) {
  return rgb((n >> 16) & 255, (n >> 8) & 255, n & 255);
}

/** SwiftUI's `.opacity`: the alpha multiplied. */
export function opacity(c, a) {
  return rgb(c.r, c.g, c.b, c.a * a);
}

/** A `#RRGGBB` string, as the engine writes a quarry's colour. */
export function hexString(s) {
  return hex(parseInt(s.replace('#', ''), 16));
}

export const white = rgb(255, 255, 255);

/** The app's Theme colours that drawings use. */
export const Theme = {
  bg: hex(0x0A0E14),
  panel: hex(0x101722),
  ink: hex(0xECE4CF),
  dim: hex(0x8F8A7A),
  amber: hex(0xF2B632),
  teal: hex(0x56D6C4),
  red: hex(0xFF6B5B),
  green: hex(0x8FE388),
  line: hex(0x2A3547),
};

export { jsRounded };

export class PixelCanvas {
  constructor(w, h, scale = 1) {
    this.w = w;
    this.h = h;
    this.scale = scale;
    /** How many marks were made: a drawing that made none drew nothing. */
    this.marks = 0;
  }

  rect(x, y, w, h, color) {
    const s = this.scale;
    const x0 = Math.floor(x * s), y0 = Math.floor(y * s);
    const x1 = Math.floor((x + w) * s), y1 = Math.floor((y + h) * s);
    if (!(x1 > x0 && y1 > y0)) return;
    this.marks += 1;
    this.fill(x0, y0, x1, y1, color);
  }

  /** A filled outline through logical points, left unsnapped: a coastline. */
  polygon(points, color) {
    if (points.length <= 2) return;
    this.marks += 1;
    this.fillPolygon(points, color);
  }

  /** A straight line one logical pixel wide: a rope. */
  line(a, b, color) {
    this.marks += 1;
    this.strokeLine(a, b, color);
  }

  /** Words in the body font, `size` logical pixels tall, standing on (x, y). */
  text(s, x, y, size, color) {
    this.marks += 1;
    this.drawText(s, x, y, size, color);
  }

  /** How wide `s` is in the body font at `size`: VT323 is monospaced. */
  width(s, size) {
    return [...s].length * size * PixelCanvas.advance;
  }

  // MARK: What scenes are made of (numbers are the prototype's)

  /** The prototype's `mix`: a colour `t` of the way from `a` to `b`, rounded per channel. */
  static mix(a, b, t) {
    const ch = (s) => jsRounded(((a >> s) & 255) * (1 - t) + ((b >> s) & 255) * t);
    return rgb(ch(16), ch(8), ch(0));
  }

  /** JavaScript's `%`, which is what the app's `mod` is. */
  static mod(a, b) {
    return a % b;
  }

  /** The sky, graded from `top` to `bottom` in overlapping bands down to `horizon`. */
  sky(top, bottom, horizon, bands = 8) {
    const n = bands;
    for (let i = 0; i < bands; i++) {
      this.rect(0, Math.floor(i * horizon / n), this.w, Math.ceil(horizon / n) + 1, PixelCanvas.mix(top, bottom, i / (n - 1)));
    }
  }

  /** Flat bands of `each` pixels from `y` down, graded the same way: deep water, a cliff. */
  bands(top, bottom, y, each, count) {
    for (let i = 0; i < count; i++) {
      this.rect(0, y + i * each, this.w, each, PixelCanvas.mix(top, bottom, i / (count - 1)));
    }
  }

  /** The sun: an 11×11 disc with its corners off, its box's top-left at (x, y). */
  sun(x, y, color) {
    this.rect(x + 2, y, 7, 11, color);
    this.rect(x, y + 2, 11, 7, color);
    this.rect(x + 1, y + 1, 9, 9, color);
  }

  /** A crescent: the same disc with a bite of `sky` out of its right side. */
  moon(x, y, color, sky) {
    this.sun(x, y, color);
    this.sun(x + 4, y - 1, sky);
  }

  /** `count` clouds sliding left and coming round again, the far ones slower. */
  clouds(count, color, t, drift) {
    const w = this.w;
    for (let i = 0; i < count; i++) {
      let x = PixelCanvas.mod(i * 61 + 20 - t * (2 + i) * drift, w + 40);
      if (x < 0) x += w + 40;
      x = jsRounded(x - 20);
      const y = 5 + ((i * 13) % 24);
      this.rect(x, y, 16, 3, color);
      this.rect(x + 3, y - 2, 9, 2, color);
      this.rect(x + 2, y + 3, 12, 1, color);
    }
  }

  /** Ground one column at a time, standing on `base`; `height` is asked for each x. */
  hills(from, to, base, color, height) {
    for (let i = from; i < to; i++) {
      const hh = jsRounded(height(i));
      this.rect(i, base - hh, 1, hh, color);
    }
  }

  /**
   * Blits a sprite written as rows of characters, a space being clear, with its top-left
   * at (x, y). `skip` drops single pixels: torn sails, a holed envelope.
   */
  sprite(rows, x, y, colors, skip = () => false) {
    rows.forEach((row, r) => {
      [...row].forEach((ch, col) => {
        if (ch === ' ') return;
        const c = colors[ch];
        if (!c || skip(col, r, ch)) return;
        this.rect(x + col, y + r, 1, 1, c);
      });
    });
  }

  rain(t) {
    const c = opacity(rgb(200, 215, 230), 0.6);
    for (let i = 0; i < 45; i++) {
      this.rect(Math.floor(PixelCanvas.mod(i * 37 + t * 30, this.w)), Math.floor(PixelCanvas.mod(i * 53 + t * 150, this.h)), 1, 3, c);
    }
  }

  snow(t) {
    const w = this.w, h = this.h, mod = PixelCanvas.mod;
    for (let i = 0; i < 30; i++) {
      const x = mod(mod(i * 41 + t * 10 + Math.sin(t + i) * 4, w) + w, w);
      this.rect(Math.floor(x), Math.floor(mod(i * 29 + t * 16, h)), 1, 1, white);
    }
  }

  fog() {
    this.rect(0, 0, this.w, this.h, opacity(rgb(210, 215, 220), 0.38));
  }

  /** A flash now and then. */
  lightning(t) {
    if (Math.floor(t * 10) % 53 === 0) this.rect(0, 0, this.w, this.h, opacity(white, 0.55));
  }

  /** Grit blowing across, and a haze of the same colour. */
  dust(t, color) {
    const w = this.w, h = this.h, mod = PixelCanvas.mod;
    this.rect(0, 0, w, h, opacity(color, 0.3));
    for (let i = 0; i < 40; i++) {
      this.rect(Math.floor(mod(i * 43 + t * 90, w)), Math.floor(mod(i * 31 + Math.sin(t + i) * 3 + h, h)), 2, 1,
        opacity(color, 0.7));
    }
  }

  /** Whatever falls from or hangs in a sky of this kind, in the order the layers go on. */
  air(sky, t, dustColor = hex(0xC9A27A)) {
    switch (sky) {
      case 'rain': this.rain(t); break;
      case 'snow': this.snow(t); break;
      case 'fog': this.fog(); break;
      case 'storm':
        this.rain(t);
        this.lightning(t);
        break;
      case 'dust': this.dust(t, dustColor); break;
      default: break;
    }
  }
}

PixelCanvas.advance = 0.4;

/** Paints a browser canvas's 2D context, `scale` device pixels to the logical pixel. */
export class ContextCanvas extends PixelCanvas {
  constructor(ctx, w, h, scale) {
    super(w, h, scale);
    this.ctx = ctx;
    this.font = 'VT323';
  }

  fill(x0, y0, x1, y1, c) {
    this.ctx.fillStyle = c.css;
    this.ctx.fillRect(x0, y0, x1 - x0, y1 - y0);
  }

  fillPolygon(points, c) {
    const ctx = this.ctx, s = this.scale;
    ctx.beginPath();
    points.forEach((q, i) => (i === 0 ? ctx.moveTo(q.x * s, q.y * s) : ctx.lineTo(q.x * s, q.y * s)));
    ctx.closePath();
    ctx.fillStyle = c.css;
    ctx.fill();
  }

  strokeLine(a, b, c) {
    const ctx = this.ctx, s = this.scale;
    ctx.beginPath();
    ctx.moveTo(a.x * s, a.y * s);
    ctx.lineTo(b.x * s, b.y * s);
    ctx.strokeStyle = c.css;
    ctx.lineWidth = s;
    ctx.stroke();
  }

  drawText(str, x, y, size, c) {
    const ctx = this.ctx, s = this.scale;
    ctx.font = `${size * s}px ${this.font}`;
    ctx.textBaseline = 'bottom';
    ctx.textAlign = 'left';
    ctx.fillStyle = c.css;
    ctx.fillText(str, x * s, y * s);
  }

  width(str, size) {
    this.ctx.font = `${size * this.scale}px ${this.font}`;
    return this.ctx.measureText(str).width / this.scale;
  }
}

/**
 * Paints a plain RGBA buffer (`data`, `w × scale` by `h × scale` pixels), blending by
 * alpha. Outlines are filled where they cover a pixel's centre; words have no font here,
 * so they are only counted.
 */
export class BufferCanvas extends PixelCanvas {
  constructor(w, h, scale = 1) {
    super(w, h, scale);
    this.pw = Math.round(w * scale);
    this.ph = Math.round(h * scale);
    this.data = new Uint8ClampedArray(this.pw * this.ph * 4);
    /** Everything drawn, for a test to tell two drawings apart. */
    this.log = [];
  }

  blend(px, py, c) {
    if (px < 0 || py < 0 || px >= this.pw || py >= this.ph) return;
    for (const v of [c.r, c.g, c.b, c.a]) {
      if (!Number.isFinite(v)) throw new Error(`a colour that isn't a number: ${JSON.stringify(c)}`);
    }
    const i = (py * this.pw + px) * 4, d = this.data, a = c.a;
    d[i] = c.r * a + d[i] * (1 - a);
    d[i + 1] = c.g * a + d[i + 1] * (1 - a);
    d[i + 2] = c.b * a + d[i + 2] * (1 - a);
    d[i + 3] = 255 * a + d[i + 3] * (1 - a);
  }

  fill(x0, y0, x1, y1, c) {
    for (const v of [x0, y0, x1, y1]) {
      if (!Number.isFinite(v)) throw new Error(`a rectangle that isn't a number: ${[x0, y0, x1, y1]}`);
    }
    this.log.push(`r${x0},${y0},${x1},${y1},${c.css}`);
    for (let y = Math.max(0, y0); y < Math.min(this.ph, y1); y++) {
      for (let x = Math.max(0, x0); x < Math.min(this.pw, x1); x++) this.blend(x, y, c);
    }
  }

  fillPolygon(points, c) {
    const s = this.scale;
    const pts = points.map((q) => ({ x: q.x * s, y: q.y * s }));
    for (const q of pts) if (!Number.isFinite(q.x) || !Number.isFinite(q.y)) throw new Error('a point that isn\'t a number');
    this.log.push(`p${pts.map((q) => `${q.x},${q.y}`).join(' ')},${c.css}`);
    // Non-zero winding at each pixel's centre, a row at a time.
    for (let py = 0; py < this.ph; py++) {
      const cy = py + 0.5;
      const crossings = [];
      for (let i = 0; i < pts.length; i++) {
        const a = pts[i], b = pts[(i + 1) % pts.length];
        if ((a.y <= cy && b.y > cy) || (b.y <= cy && a.y > cy)) {
          crossings.push({ x: a.x + (cy - a.y) / (b.y - a.y) * (b.x - a.x), dir: b.y > a.y ? 1 : -1 });
        }
      }
      crossings.sort((p, q) => p.x - q.x);
      let wind = 0;
      for (let k = 0; k < crossings.length - 1; k++) {
        wind += crossings[k].dir;
        if (wind === 0) continue;
        for (let px = Math.max(0, Math.ceil(crossings[k].x - 0.5)); px < Math.min(this.pw, Math.ceil(crossings[k + 1].x - 0.5)); px++) {
          this.blend(px, py, c);
        }
      }
    }
  }

  strokeLine(a, b, c) {
    const s = this.scale;
    for (const v of [a.x, a.y, b.x, b.y]) if (!Number.isFinite(v)) throw new Error('a line that isn\'t a number');
    this.log.push(`l${a.x},${a.y},${b.x},${b.y},${c.css}`);
    const x0 = a.x * s, y0 = a.y * s, x1 = b.x * s, y1 = b.y * s;
    const n = Math.max(1, Math.ceil(Math.max(Math.abs(x1 - x0), Math.abs(y1 - y0))));
    for (let i = 0; i <= n; i++) {
      this.blend(Math.floor(x0 + (x1 - x0) * i / n), Math.floor(y0 + (y1 - y0) * i / n), c);
    }
  }

  drawText(str, x, y, size, c) {
    for (const v of [x, y, size]) if (!Number.isFinite(v)) throw new Error('words placed at a spot that isn\'t a number');
    this.log.push(`t${str},${x},${y},${size},${c.css}`);
  }

  /** A short fingerprint of what was drawn: the same drawing gives the same one. */
  get picture() {
    let h = 0x811c9dc5;
    for (const line of this.log) {
      for (let i = 0; i < line.length; i++) h = Math.imul(h ^ line.charCodeAt(i), 0x01000193);
      h = Math.imul(h ^ 10, 0x01000193);
    }
    return (h >>> 0).toString(16);
  }

  /** How many device pixels have anything on them. */
  get covered() {
    let n = 0;
    for (let i = 3; i < this.data.length; i += 4) if (this.data[i] > 0) n++;
    return n;
  }
}
