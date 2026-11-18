// The Long Transfer's scene (AroundTheHorn/Journeys/MarsScene.swift): a transfer freighter
// in profile against black sky and fixed stars, nose to the right, where Mars is. Her drive
// glows behind her when she burns, longer the harder she burns; past Turnover she flies
// tail first, braking. Earth shrinks behind her over the first weeks and Mars grows ahead
// over the last; the Sun sits small at the top right edge, smaller the further out she is.
// Each stretch of the arc has its own sky (Earth's limb, the double star of Earth and the
// Moon, the ice streams' glitter, the zodiacal light, the Milky Way, the Sun between her and
// home, Mars and its moons), and each stop is drawn as itself: the yard at Gateway, the Moon
// going by, the edge of Earth's reach, the cycler's wheel, Turnover with the ship on end,
// Midway's tanks, the shadow, the approach, Phobos under Mars, the pad at Jezero. Space
// weather shows as what it is. Her wings lose panels as power falls and go dark at 0%; a
// dark or dry ship has no glow, and a dry one tumbles; a tired hull leaks.
//
// Every function takes the journey's tables `J` where the app's reads `MarsSkin.journey`,
// and the frame `f` from drawing.js `sceneFrame`: what the app asks of the engine beyond the
// state (`Mars.dark`, `Mars.coasting`) is the frame's `hooks.mars`, and the state's region
// is the frame's `region`, the bridge's answers.

import { hex, opacity, white } from '../pixels.js';
import { au } from './mars-chart.js';

/** Swift's `x.rounded()`: halves away from zero. */
const rounded = (x) => Math.sign(x) * Math.round(Math.abs(x));

/** A point, as the app's tuples are written. */
const P = (x, y) => ({ x, y });

/**
 * Swift's `stride(from:through:by:)` over Doubles (`to:`, short of the end, with
 * `through` false): each value worked out from the start, not added up.
 */
function* stride(from, end, by, through = true) {
  for (let i = 0; ; i++) {
    const x = from + i * by;
    if (by > 0 ? (through ? x > end : x >= end) : (through ? x < end : x <= end)) return;
    yield x;
  }
}

// MARK: The freighter

/**
 * 48 × 27, nose to the right: the two solar wings above and below the truss, the drive and
 * its bell at the left, radiators, two cargo cans, the habitat with its windows and stripe,
 * and a dish.
 */
export const ship = [
  '        fffffffffffff                           ',
  '        fppfppfppfppf                           ',
  '        fppfppfppfppf                           ',
  '        fffffffffffff                           ',
  '        fppfppfppfppf                           ',
  '        fppfppfppfppf                           ',
  '        fffffffffffff                  a a      ',
  '              m                        aaa      ',
  '              m                         k       ',
  '         rr   m   rr                    k       ',
  'n        rr   m   rr  CCCCCC CCCCCC HHHHHHHHHH  ',
  'nn  HHHHttttttttttttttcccccc cccccc hhhhhhhhhhH ',
  'nnnnkkkktt  tt  tt  ttcccccckcccccckhwhwhwhwhhhH',
  'nnnnkkkkt t t t t t t cccccckcccccckhhhhhhhhhhhH',
  'nnnnkkkkt  tt  tt  tt cccccckcccccckRRRRRRRRRRhH',
  'nn  kkkkttttttttttttttcccccc cccccc hhhhhhhhhhH ',
  'n        rr   m   rr  CCCCCC CCCCCC HHHHHHHHHH  ',
  '         rr   m   rr                            ',
  '              m                                 ',
  '              m                                 ',
  '        fffffffffffff                           ',
  '        fppfppfppfppf                           ',
  '        fppfppfppfppf                           ',
  '        fffffffffffff                           ',
  '        fppfppfppfppf                           ',
  '        fppfppfppfppf                           ',
  '        fffffffffffff                           ',
];

export const colors = {
  f: hex(0xB8962E), p: hex(0x2E4E8C), m: hex(0x8C939C), r: hex(0xECE4CF),
  t: hex(0x9AA1AA), n: hex(0x5A5F68), k: hex(0x3A3F47), H: hex(0xA7AEB7),
  h: hex(0xDCE1E6), w: hex(0xF2D16B), R: hex(0xD64545), C: hex(0x9C8A64),
  c: hex(0xC9B48A), a: hex(0xDCE3EA),
};

export const shipW = ship[0].length;
export const shipH = ship.length;
/** Her middle under way, and docked beside a station. */
export const flying = { x: 80.0, y: 40.0 };
export const docked = { x: 40.0, y: 40.0 };
/** The row of the drive's bell, where the glow comes out. */
export const driveRow = 13;

/** Which way she points, in the order of the app's `Facing` raw values. */
export const facings = ['ahead', 'down', 'astern', 'up'];

/** Where the sprite's (column, row) lands on the canvas, the sprite's middle at `c`. */
export function place(col, row, facing, c) {
  const w = shipW, h = shipH;
  switch (facing) {
    case 'ahead': return P(Math.floor(c.x - w / 2 + col), Math.floor(c.y - h / 2 + row));
    case 'astern': return P(Math.floor(c.x - w / 2 + w - 1 - col), Math.floor(c.y - h / 2 + row));
    case 'up': return P(Math.floor(c.x - h / 2 + row), Math.floor(c.y - w / 2 + w - 1 - col));
    case 'down': return P(Math.floor(c.x - h / 2 + h - 1 - row), Math.floor(c.y - w / 2 + col));
    default: throw new Error(`no facing ${facing}`);
  }
}

/**
 * The engine's key for how she was caught at Mars, held to it by `MarsSkinTests`: 1
 * aerobraking, 2 a full burn, 3 the tanks ran dry in the burn.
 */
export const captureKey = 'mars.capture';
/** The engine's key for a set piece reached in the dark and still waiting. */
export const heldKey = 'mars.held';

// MARK: Where she is

const currentStop = (J, g) => J.stops[g.stopIndex];
const isPort = (J, id) => J.ports.some((p) => p.id === id);

export function index(J, id) {
  const i = J.stops.findIndex((s) => s.id === id);
  return i < 0 ? 0 : i;
}

/** The station she is docked at. */
export function dockedAt(J, f) {
  const g = f.state;
  if (!(f.atPort && g && !lost(f) && isPort(J, currentStop(J, g).id))) return null;
  return currentStop(J, g).id;
}

/** The hull has let go: the run is over and nothing holds the air. */
export function lost(f) {
  const g = f.state;
  if (!g) return false;
  return g.over && g.hull <= 0;
}

/** At Jezero, the cargo down. */
export function landed(J, f) {
  const g = f.state;
  if (!g || lost(f)) return false;
  return g.stopIndex === J.stops.length - 1 && g.mile >= currentStop(J, g).mile;
}

/** The stop she has reached and not docked at: its question on screen, or going on. */
export function atStop(J, f) {
  const g = f.state;
  if (!(g && dockedAt(J, f) === null && !lost(f) && !landed(J, f) && g.stopIndex > 0)) return null;
  const stop = currentStop(J, g);
  return g.mile === stop.mile ? stop : null;
}

/** Under way with no thrust: the array dark or the tanks dry, once she has left. */
export function coasting(J, f) {
  const g = f.state;
  if (!(g && dockedAt(J, f) === null && !lost(f) && !landed(J, f) && g.day > 0)) return false;
  return f.hooks.mars.coasting;
}

/** The array dark: every panel dead, docked or not. */
export function dark(f) {
  const g = f.state;
  if (!(g && g.day > 0)) return false;
  return f.hooks.mars.dark;
}

/** The tanks dry under way: nothing for the thrusters that keep her pointed. */
export function tumbling(J, f) {
  const g = f.state;
  if (!g) return false;
  return coasting(J, f) && g.fuel <= 0;
}

/** Turnover reached in the dark, and still waiting for power. */
export function turnoverWaits(J, g) {
  const held = g.vars?.[heldKey];
  return held !== undefined && held !== null && Math.trunc(held) === index(J, 'turnover');
}

/** Turned end for end: past Turnover, unless she reached it dark and it is still waiting for power. */
export function turned(J, g) {
  const i = index(J, 'turnover');
  if (turnoverWaits(J, g)) return false;
  return g.stopIndex > i || (g.stopIndex === i && g.mile > currentStop(J, g).mile);
}

/**
 * Dipping through the top of the Martian air, as the engine counts it: in the capture
 * region, short of Phobos, having chosen to aerobrake. `region` is the state's.
 */
export function aerobraking(J, g, region) {
  return region?.id === 'capture' && g.mile < (J.stops.find((s) => s.id === 'phobos')?.mile ?? 0) && g.vars?.[captureKey] === 1;
}

export function facing(J, f) {
  const g = f.state;
  if (!g) return 'ahead';
  if (dockedAt(J, f) !== null) return 'ahead';
  if (tumbling(J, f)) return facings[Math.floor(f.t / 1.6) % 4] ?? 'ahead';
  if (atStop(J, f)?.id === 'turnover' && !turnoverWaits(J, g)) return 'up';
  return turned(J, g) ? 'astern' : 'ahead';
}

// MARK: Drawing

/** Swift's `truncatingRemainder`, brought into 0..<period. */
export function wrap(x, period) {
  const m = x % period;
  return m < 0 ? m + period : m;
}

export function draw(J, px, f) {
  const g = f.state;
  const t = f.t;
  if (landed(J, f)) {
    jezero(px, t);
    weather(px, f, null);
    return;
  }
  const mile = g?.mile ?? 2000;
  if (lost(f) && g && aerobraking(J, g, f.region)) {
    px.bands(0x04060D, 0x0B1226, 0, 10, 8);
    stars(px);
    streak(px, t);
    weather(px, f, null);
    return;
  }
  const region = f.region?.id ?? 'departure';
  const stop = atStop(J, f);
  const station = dockedAt(J, f);

  px.bands(0x04060D, 0x0B1226, 0, 10, 8);
  stars(px);
  const skimming = g ? aerobraking(J, g, f.region) : false;
  backdrop(J, px, mile, region, stop?.id ?? null, station, t, skimming);

  if (station !== null) {
    dockedScene(px, station, t);
  } else if (stop) {
    stopScene(px, stop.id, f, t);
  }
  if (f.moving && station === null && !lost(f)) specks(px, t, coasting(J, f) ? 0.4 : 1);

  if (lost(f)) {
    wreck(px, f, t);
    weather(px, f, null);
    return;
  }
  const centre = station !== null ? docked : flying;
  const face = facing(J, f);
  if (skimming && station === null) plasma(px, t, true);
  freighter(J, px, f, centre, face);
  if (skimming && station === null) plasma(px, t, false);
  if (stop?.id === 'turnover' && face === 'up') puffs(px, centre, t);
  weather(px, f, { at: centre, facing: face });
}

// MARK: Sky

/**
 * A number that looks random and is the same every time, for placing stars. As in the
 * app, the shift binds before the multiplication.
 */
export function scatter(i) { return ((i + 1) * (2_654_435_761 >>> 7)) & 0xFFFFF; }

/** The same stars every time, a few of them tinted. */
export function stars(px) {
  for (let i = 0; i < 48; i++) {
    const h = scatter(i);
    const x = h % 160, y = Math.trunc(h / 160) % 80;
    const tint = i % 7 === 0 ? 0xFFD9A0 : i % 5 === 0 ? 0xA8C8FF : 0xFFFFFF;
    px.rect(x, y, 1, 1, opacity(hex(tint), i % 3 === 0 ? 0.85 : 0.4));
  }
}

/**
 * A filled disc, a row at a time, centred on the pixel at (cx, cy) and the same on both
 * sides of it, darker on the side away from the Sun (lower left). `upper` stops at the
 * middle row: a dome.
 */
export function disc(px, cx, cy, r, color, shade = null, upper = false) {
  if (!(r > 0)) return;
  const x = Math.floor(cx), y0 = Math.floor(cy);
  if (r < 1) return px.rect(x, y0, 1, 1, hex(color));
  const ri = Math.floor(r);
  for (let dy = -ri; dy <= (upper ? 0 : ri); dy++) {
    const y = dy;
    const hw = rounded(Math.sqrt(r * r - y * y));
    px.rect(x - hw, y0 + y, 2 * hw + 1, 1, hex(color));
    if (shade !== null && r >= 3) {
      const s = rounded(hw * (0.35 + 0.25 * Math.max(0, y) / r));
      if (s >= 1) px.rect(x - hw, y0 + y, s, 1, hex(shade));
    }
  }
}

/** The Sun's size: four and a half pixels across at Earth's distance, smaller further out. */
export function sunRadius(J, mile) { return 4.5 / au(J, mile); }

export function sun(px, x, y, r, corona) {
  if (corona) {
    const c = hex(0xFFF2C8);
    for (const [dx, dy, l] of [[1.0, 0.0, 16.0], [-1, 0, 12], [0, 1, 9], [0, -1, 10], [0.7, -0.7, 8], [-0.7, 0.7, 7]]) {
      for (const k of stride(r + 1, r + l, 1, false)) {
        px.rect(Math.floor(x + dx * k), Math.floor(y + dy * k), 1, 1, opacity(c, 0.5 * (1 - (k - r) / l)));
      }
    }
  }
  disc(px, x, y, r + 1, 0xC9A84A);
  disc(px, x, y, r, 0xFFF4C2);
  disc(px, x, y, Math.max(1, r - 2), 0xFFFFFF);
}

/** Earth's size behind her: filling the lower left at Gateway, a disc for the first weeks, then a point of light. */
export function earthRadius(mile) {
  const m = Math.max(0, mile);
  if (m <= 150) return 34 * (1 - m / 150 * 0.65);
  return Math.max(2, 11.9 * Math.pow(150 / m, 0.6));
}

/** Earth, its clouds and a continent, the Moon beside it. */
export function earth(px, r, moon = true) {
  const cx = 26 - r * 0.5, cy = 20 + r * 1.5;
  disc(px, cx, cy, r + 1, 0x7FB6F0);
  disc(px, cx, cy, r, 0x2E6FB5, 0x1B4778);
  if (r >= 5) {
    disc(px, cx + r * 0.25, cy - r * 0.3, r * 0.26, 0x5F8A4A);
    disc(px, cx + r * 0.05, cy - r * 0.05, r * 0.18, 0x5F8A4A);
    for (let k = 0; k < 3; k++) {
      const dk = k;
      px.rect(Math.floor(cx - r * 0.5 + dk * r * 0.3), Math.floor(cy - r * 0.55 + dk * r * 0.4),
        Math.max(2, rounded(r * 0.5)), 1, opacity(hex(0xEEF1F4), 0.85));
    }
  }
  if (!moon) return;
  const mr = Math.max(1, r * 0.27);
  disc(px, cx + r + 6, cy - r / 3 - 2, mr, 0xB8B8B0, 0x7F7F78);
}

/** Mars's size ahead: a red point from 300 million km, a disc on the approach, and most of the view in the capture. */
export function marsRadius(mile) {
  if (mile < 30_000) return 0;
  if (mile <= 46_000) return 1 + 6 * (mile - 30_000) / 16_000;
  const f = Math.min(1, (mile - 46_000) / 2000);
  return 7 * Math.pow(46.0 / 7, f);
}

export function marsCentre(r) {
  return r <= 7 ? P(140, 30) : P(140 + (r - 7) * 0.45, 30 + (r - 7) * 1.1);
}

/** Mars: rust, shaded away from the Sun, its dark country and a white cap once it is big enough to show them. */
export function mars(px, cx, cy, r) {
  if (r >= 6) disc(px, cx, cy, r + 1, 0xE2A06A);
  disc(px, cx, cy, r, 0xC0613A, 0x7E3A22);
  if (!(r >= 4)) return;
  for (const [dx, dy, s] of [[-0.1, 0.1, 0.32], [0.3, -0.2, 0.18], [0.15, 0.45, 0.22]]) {
    disc(px, cx + dx * r, cy + dy * r, Math.max(1, r * s), 0x8A4129);
  }
  // The northern cap: the top rows of the disc, a little narrower.
  const x = Math.floor(cx), top = Math.floor(cy) - Math.floor(r);
  for (let k = 0; k < Math.max(1, rounded(r * 0.16)); k++) {
    const y = Math.floor(r) - k;
    const hw = rounded(Math.sqrt(r * r - y * y) * 0.8);
    px.rect(x - hw, top + k, 2 * hw + 1, 1, hex(0xF4F1EA));
  }
}

/** What is in the sky for this stretch of the arc, this stop or this station. */
export function backdrop(J, px, mile, region, stop, station, t, skimming = false) {
  const behind = region === 'shadow' || stop === 'shadow';
  if (region === 'deep' || behind) milkyWay(px);
  if (region === 'inner') {
    px.polygon([P(146, 7), P(146, 11), P(0, 44), P(0, 4)], opacity(hex(0xFFF2C8), 0.035));
    px.polygon([P(146, 8), P(146, 10), P(0, 32), P(0, 16)], opacity(hex(0xFFF2C8), 0.035));
  }
  const rs = sunRadius(J, mile);
  if (behind) {
    sun(px, 18, 36, rs + 1, true);
  } else if (station !== 'phobos') {
    sun(px, 147, 9, rs, false);
  }
  if (station === 'gateway' || station === 'phobos' || stop === 'lunar') return;
  if (mile < 3000) {
    earth(px, earthRadius(mile));
  } else if (mile < 24_000) {
    // Earth and the Moon as a double star.
    px.rect(23, 19, 2, 2, hex(0x9CC8F2));
    px.rect(27, 20, 1, 1, hex(0xD8D8D0));
  }
  if (region === 'stream1' || region === 'stream2') stream(px, region === 'stream2', t);
  if (skimming) return limbBelow(px, t);
  const r = marsRadius(mile);
  if (r > 0 && stop !== 'phobos') {
    const c = marsCentre(r);
    mars(px, c.x, c.y, r);
    if (region === 'capture') limb(px, c, r);
    if (r >= 4 && r <= 12) {
      px.rect(Math.floor(c.x - r - 5), Math.floor(c.y - 3), 2, 1, hex(0x9C8F80));
      px.rect(Math.floor(c.x + r + 3), Math.floor(c.y + 4), 1, 1, hex(0xB0A595));
    }
  }
}

/** The thin air over Mars, a pale band on its edge. */
export function limb(px, c, r) {
  for (const k of stride(0.0, 360, 3, false)) {
    const a = k * Math.PI / 180;
    px.rect(Math.floor(c.x + (r + 1.5) * Math.cos(a)), Math.floor(c.y + (r + 1.5) * Math.sin(a)), 1, 1,
      opacity(hex(0xF0C8A0), 0.5));
  }
}

/** The galaxy edge-on: a band of faint stars from lower left to upper right. */
export function milkyWay(px) {
  px.polygon([P(0, 60), P(0, 74), P(160, 18), P(160, 4)], opacity(hex(0xC8D2F0), 0.05));
  for (let i = 0; i < 70; i++) {
    const s = i / 70;
    const x = Math.floor(160 * s + (i * 37) % 11 - 5);
    const y = Math.floor(67 - 56 * s + (i * 53) % 15 - 7);
    px.rect(x, y, 1, 1, opacity(white, i % 4 === 0 ? 0.5 : 0.22));
  }
}

/** A comet's old debris stream across the sky, glittering as it turns; the second is bluer, sparser and coarser. */
export function stream(px, second, t) {
  const n = second ? 30 : 46;
  const base = second ? 0x9DB8D6 : 0xD6E2EA;
  px.polygon([P(0, 8), P(0, 22), P(160, 42), P(160, 28)], opacity(hex(base), 0.05));
  for (let i = 0; i < n; i++) {
    const di = i;
    const x = wrap(di * 23 + 7 - t * (1 + i % 3), 170) - 5;
    const y = 15 + x * 0.125 + (i * 17) % 13 - 6;
    const flash = (i + Math.floor(t * 3)) % 9 === 0;
    const size = second && i % 4 === 0 ? 2 : 1;
    px.rect(Math.floor(x), Math.floor(y), size, size, opacity(hex(flash ? 0xFFFFFF : base), flash ? 0.95 : 0.6));
  }
}

/** Near dust going by: how fast she is moving, whether or not the drive is lit. */
export function specks(px, t, fast) {
  for (let i = 0; i < 7; i++) {
    const di = i;
    const x = wrap(di * 47 - t * (30 + di * 6) * fast, 170) - 5;
    px.rect(Math.floor(x), (i * 31 + 9) % 76 + 2, 1, 1, opacity(hex(0x8C939C), 0.7));
  }
}

// MARK: The freighter

export function freighter(J, px, f, c, facing) {
  const t = f.t;
  const isDark = dark(f);
  const power = Math.max(0, Math.min(100, f.sails)), hull = Math.max(0, Math.min(100, f.hull));
  const gusting = f.weather.sky === 'breeze';
  const col = { ...colors };
  if (isDark) {
    col.p = hex(0x23262E);
    col.f = hex(0x6E5C2A);
    col.w = hex(0x3A3F47);
  }
  const missing = hex(0x10141C), dent = hex(0x8C939C);
  for (let r = 0; r < ship.length; r++) {
    const row = ship[r];
    for (let k = 0; k < row.length; k++) {
      const ch = row[k];
      if (ch === ' ') continue;
      let color = col[ch];
      if (!color) continue;
      // Panels fall dark cell by cell as power goes.
      if (ch === 'p' && !isDark) {
        const cell = (Math.trunc(k / 3) * 37 + Math.trunc(r / 3) * 61) % 100;
        if (cell >= power + 12) color = missing;
      }
      // Dents, and later bare plate, as the hull wears.
      if ((ch === 'h' || ch === 'c') && hull < 60 && (k * 5 + r * 3) % 9 === 0) color = dent;
      let y = r;
      if (gusting && (ch === 'f' || ch === 'p')) {
        y += (Math.sin(t * 7 + k * 0.9) > 0.55) ? (r < 10 ? -1 : 1) : 0;
      }
      const q = place(k, y, facing, c);
      px.rect(q.x, q.y, 1, 1, color);
    }
  }
  if (hull < 35) {
    // Silver patches, and air going out of a seam.
    for (const [k, r] of [[24.0, 12.0], [39, 14], [31, 13]]) {
      const q = place(k, r, facing, c);
      px.rect(q.x, q.y, 2, 2, hex(0xC8CED6));
    }
    for (let i = 0; i < 4; i++) {
      const d = wrap(t * 6 + i * 2.5, 10);
      const q = place(38 - d * 0.6, 17 + d, facing, c);
      px.rect(q.x, q.y, 1, 1, opacity(white, Math.max(0.1, 0.8 - d / 12)));
    }
  }
  if ((f.moving || f.state === null) && dockedAt(J, f) === null && !coasting(J, f)) {
    glow(px, f, c, facing);
  }
}

/** How long the drive's glow is, by thrust: a faint one at an economy burn. */
export function glowLength(pace) {
  switch (pace) {
    case 'easy': return 4;
    case 'steady': return 6;
    case 'full': return 10;
    default: throw new Error(`no pace ${pace}`);
  }
}

export function glow(px, f, c, facing) {
  const len = glowLength(f.state?.pace ?? 'steady') + (Math.floor(f.t * 9) % 3 === 0 ? 1 : 0);
  const core = hex(0xEAF2FF), mid = hex(0x8FB0FF), outer = hex(0x5368D0);
  for (let d = 1; d <= len; d++) {
    const fade = 1 - d / (len + 1);
    const spread = d > 2 ? 2 : 1;
    for (let dr = -spread; dr <= spread; dr++) {
      const q = place(-d, driveRow + dr, facing, c);
      const color = dr === 0 ? (d <= 2 ? core : mid) : outer;
      px.rect(q.x, q.y, 1, 1, opacity(color, 0.35 + 0.6 * fade));
    }
  }
}

/** Small white puffs at both ends: the thrusters turning her end for end. */
export function puffs(px, c, t) {
  const p = wrap(t * 3, 4);
  for (const [k, r] of [[-2.0 - p, 11.0], [49 + p, 15]]) {
    const q = place(k, r, 'up', c);
    px.rect(q.x, q.y, 2, 2, opacity(white, 0.8 - p * 0.15));
  }
}

/**
 * The glow of the air she is pushing through: a bright bow round the end she leads with,
 * and streaks of hot air trailing back past her.
 */
export function plasma(px, t, trail) {
  const c = flying, front = c.x + shipW / 2 + 2;
  if (trail) {
    for (let k = 0; k < 5; k++) {
      const dy = (k - 2) * 4, len = 50 + (k * 13) % 20;
      const flick = 0.25 + 0.15 * Math.sin(t * 13 + k);
      px.rect(front - len, c.y + dy, len, 1, opacity(hex(0xFF9A50), flick));
    }
    return;
  }
  for (const k of stride(-70.0, 70, 7)) {
    const a = k * Math.PI / 180;
    const x = front + 4 * Math.cos(a), y = c.y + 13 * Math.sin(a);
    px.rect(Math.floor(x), Math.floor(y), 2, 2, hex(Math.abs(k) < 40 ? 0xFFF0D0 : 0xFFB070));
  }
}

/** The ground's circle in `limbBelow`, and how much deeper its air is. */
export const limbCentre = { x: 80.0, y: 250.0 }, limbRadius = 196.0, airDepth = 4.0;
export const air = 0xF0C8A0;

/**
 * The rows `limbBelow` fills, in order: the air's circle, a few pixels wider than the
 * ground's, then the ground over it, so the air shows as a pale band along the edge, over
 * the top and down the sides.
 */
export function limbRows() {
  const c = limbCentre;
  const rows = [];
  for (const [r, ground] of [[limbRadius + airDepth, false], [limbRadius, true]]) {
    for (const y of stride(40.0, 80, 1, false)) {
      const d = r * r - (c.y - y) * (c.y - y);
      if (!(d > 0)) continue;
      const half = Math.sqrt(d);
      const color = !ground ? air : y < 58 ? 0xD98A5A : 0xB5562D;
      rows.push({ y, x: Math.floor(c.x - half), w: rounded(2 * half), color });
    }
  }
  return rows;
}

/** Mars filling the bottom of the view, its thin air a pale band along the edge, the way it looks from the top of that air. */
export function limbBelow(px, t) {
  const c = limbCentre, r = limbRadius;
  for (const row of limbRows()) {
    if (row.w > 0) px.rect(row.x, row.y, row.w, 1, hex(row.color));
  }
  // Dark country going by below, kept inside the planet's edge.
  for (const [x, y, w] of [[20.0, 66.0, 18.0], [70, 72, 26], [118, 64, 14], [40, 77, 20]]) {
    const half = Math.sqrt(r * r - (c.y - y) * (c.y - y));
    const a = Math.max(c.x - half + 2, wrap(x - t * 3, 200) - 20), b = Math.min(c.x + half - 2, a + w);
    if (b > a) px.rect(Math.floor(a), y, rounded(b - a), 2, hex(0x8A4129));
  }
}

// MARK: Stops

export function stopScene(px, id, f, t) {
  switch (id) {
    case 'lunar':
      earth(px, earthRadius(f.state?.mile ?? 38), false);
      disc(px, 134, 62, 26, 0xBDBDB4, 0x84847C);
      for (const [dx, dy, r] of [[-8.0, -10.0, 4.0], [6, -2, 6], [-2, 9, 3], [12, 12, 2], [-14, 4, 2]]) {
        disc(px, 134 + dx, 62 + dy, r, 0x9A9A92);
        px.rect(134 + dx - r + 1, 62 + dy - r, Math.max(1, r), 1, hex(0x6F6F68));
      }
      break;
    case 'hill':
      // The edge of Earth's reach: a line nobody can see, dotted anyway.
      for (const y of stride(0.0, 80, 3, false)) {
        const x = 44 + 6 * Math.sin(y / 80 * Math.PI);
        px.rect(Math.floor(x), y, 1, 1, opacity(hex(0x6D9CC8), 0.6));
      }
      break;
    case 'cycler':
      cycler(px, P(116, 15), 0.45, t);
      break;
    case 'midway':
      midway(px, P(112, 8), 0.4);
      break;
    case 'shadow':
      // Earth at the Sun's edge, about to go behind it.
      px.rect(23, 33, 1, 1, hex(0x9CC8F2));
      noise(px, t, 18);
      break;
    case 'approach':
      // The way in: a dashed line from her bow down round the planet's edge.
      for (const k of stride(0.0, 1, 0.06, false)) {
        const x = 106 + 30 * k, y = 40 - 14 * k * (1 - k) + 2 * k;
        px.rect(Math.floor(x), Math.floor(y), 2, 1, opacity(hex(0xF2D16B), 0.6));
      }
      break;
    case 'phobos':
      mars(px, 150, 70, 40);
      limb(px, P(150, 70), 40);
      phobosMoon(px, 122, 18, 9);
      break;
    default:
      break;
  }
}

// MARK: Stations

export function dockedScene(px, id, t) {
  // The arm she is docked by.
  const arm = hex(0x8C939C);
  switch (id) {
    case 'gateway':
      gateway(px, t);
      px.rect(64, 39, 22, 2, arm);
      break;
    case 'cycler':
      px.rect(64, 39, 8, 2, arm);
      cycler(px, P(126, 40), 1, t);
      break;
    case 'midway':
      px.rect(64, 39, 22, 2, arm);
      midway(px, P(100, 6), 1);
      break;
    case 'phobos':
      mars(px, 118, -70, 100);
      phobosYard(px, t);
      px.rect(64, 39, 12, 2, arm);
      px.rect(74, 39, 3, 24, hex(0x6B717A));
      break;
    default:
      break;
  }
}

/** Gateway Yard: Earth's curve below, and the yard's open frame with a crane and lights. */
export function gateway(px, t) {
  for (const y of stride(58.0, 80, 1, false)) {
    const half = Math.sqrt(220.0 * 220 - (276 - y) * (276 - y));
    const x0 = 70 - half;
    px.rect(Math.floor(x0), y, rounded(2 * half), 1, hex(y < 60 ? 0x7FB6F0 : 0x2E6FB5));
  }
  for (const [x, y, w] of [[10.0, 64.0, 18.0], [60, 68, 26], [110, 63, 14], [130, 72, 22], [30, 75, 16]]) {
    px.rect(x, y, w, 2, opacity(hex(0xEEF1F4), 0.75));
  }
  px.rect(96, 66, 14, 4, hex(0x5F8A4A));
  const frame = hex(0x9AA1AA), dim = hex(0x6B717A);
  px.rect(86, 10, 70, 2, frame);
  px.rect(86, 54, 70, 2, frame);
  px.rect(86, 10, 2, 46, frame);
  px.rect(154, 10, 2, 46, frame);
  for (const k of stride(0.0, 66, 11, false)) {
    px.line(P(88 + k, 12), P(99 + k, 54), dim);
    px.rect(88 + k, 12, 1, 42, dim);
  }
  // The crane, its arm over a cargo can.
  px.rect(120, 4, 2, 8, frame);
  px.rect(104, 4, 26, 2, frame);
  px.rect(105, 6, 1, 14, hex(0x4B4F55));
  px.rect(100, 20, 12, 7, hex(0xC9B48A));
  px.rect(100, 20, 12, 1, hex(0x9C8A64));
  // A habitat ring segment with lit windows, and work lights blinking.
  px.rect(126, 30, 22, 10, hex(0xDCE1E6));
  for (let k = 0; k < 5; k++) px.rect(128 + k * 4, 34, 2, 2, hex(0xF2D16B));
  const on = Math.floor(t * 2) % 2 === 0;
  for (const [x, y] of [[86.0, 9.0], [155, 9], [86, 55], [155, 55]]) {
    px.rect(x, y, 2, 2, hex(on ? 0xFFB347 : 0x7A5A2A));
  }
}

/**
 * The cycler: an ice shield like a dirty snowball, a spine of tanks, and a wheel turning
 * round its hub with lit windows on the rim.
 */
export function cycler(px, c, s, t) {
  const spine = hex(0xA7AEB7);
  disc(px, c.x + 26 * s, c.y, 12 * s, 0x8E8A84, 0x5E5A56);
  for (const [dx, dy] of [[-3.0, -4.0], [4, 3], [1, -8], [-6, 5]]) {
    px.rect(Math.floor(c.x + (26 + dx) * s), Math.floor(c.y + dy * s), Math.max(1, 2 * s), Math.max(1, 2 * s),
      hex(0xDAD6CC));
  }
  px.rect(Math.floor(c.x - 56 * s), Math.floor(c.y - 2 * s), Math.max(2, 70 * s), Math.max(1, 4 * s), spine);
  for (let k = 0; k < 3; k++) {
    px.rect(Math.floor(c.x - (50 - k * 14) * s), Math.floor(c.y - 4 * s), Math.max(2, 10 * s), Math.max(2, 8 * s),
      hex(0xDCE1E6));
  }
  const r = 15 * s;
  const turn = t * 0.6;
  for (let k = 0; k < 4; k++) {
    const a = turn + k * Math.PI / 2;
    px.line(P(c.x, c.y), P(c.x + r * Math.cos(a), c.y + r * Math.sin(a)), spine);
  }
  for (const k of stride(0.0, 360, s < 1 ? 20 : 10, false)) {
    const a = k * Math.PI / 180;
    px.rect(Math.floor(c.x + r * Math.cos(a)), Math.floor(c.y + r * Math.sin(a)), Math.max(1, 2 * s), Math.max(1, 2 * s),
      hex(0xC8CDD3));
  }
  for (let k = 0; k < 8; k++) {
    const a = turn + k * Math.PI / 4 + 0.3;
    px.rect(Math.floor(c.x + r * Math.cos(a)), Math.floor(c.y + r * Math.sin(a)), 1, 1, hex(0xFFE27A));
  }
  disc(px, c.x, c.y, Math.max(1, 3 * s), 0x8C939C);
}

/** Midway Depot: three tanks, a habitat can, and a light in one window. */
export function midway(px, o, s) {
  const r = (x, y, w, h, c) => {
    px.rect(Math.floor(o.x + x * s), Math.floor(o.y + y * s), Math.max(1, rounded(w * s)), Math.max(1, rounded(h * s)),
      hex(c));
  };
  for (let k = 0; k < 3; k++) {
    const x = k * 18;
    r(x, 6, 14, 52, 0xD9D4C8);
    r(x, 4, 14, 2, 0xA7A196);
    r(x, 58, 14, 2, 0xA7A196);
    r(x, 22, 14, 4, 0xA65A32);
    r(x + 2, 8, 2, 48, 0xEFEBE2);
  }
  r(-14, 30, 62, 3, 0x8C939C);
  r(10, 34, 34, 14, 0xDCE1E6);
  r(10, 34, 34, 2, 0xA7AEB7);
  r(16, 39, 3, 3, 0x3A3F47);
  r(24, 39, 3, 3, 0xF2D16B);
  r(32, 39, 3, 3, 0x3A3F47);
}

/** Phobos, a lumpy grey potato, from a distance. */
export function phobosMoon(px, cx, cy, r) {
  disc(px, cx, cy, r, 0x7A6E64, 0x4E453E);
  disc(px, cx + r * 0.5, cy - r * 0.3, r * 0.6, 0x7A6E64);
  disc(px, cx - r * 0.2, cy + r * 0.1, Math.max(1, r * 0.3), 0x5E544B);
}

/** Phobos Yard: the moon's ground close below, the yard dug into it, Mars overhead. */
export function phobosYard(px, t) {
  px.hills(0, 160, 80, hex(0x6E6259), (x) => 20 + 3 * Math.sin(x / 13) + 2 * Math.sin(x / 5 + 1));
  for (const [x, y, r] of [[20.0, 70.0, 4.0], [60, 74, 3], [140, 72, 5], [95, 76, 2]]) {
    disc(px, x, y, r, 0x564B43);
  }
  // The hangar mouth and its lights, and a crane over it.
  px.rect(104, 58, 34, 14, hex(0x1E1B19));
  px.rect(102, 56, 38, 2, hex(0x9AA1AA));
  const on = Math.floor(t * 2) % 2 === 0;
  for (let k = 0; k < 5; k++) px.rect(107 + k * 7, 62, 2, 2, hex(k % 2 === (on ? 0 : 1) ? 0xFFB347 : 0xF2D16B));
  px.rect(146, 34, 2, 26, hex(0x9AA1AA));
  px.rect(126, 34, 22, 2, hex(0x9AA1AA));
  px.rect(128, 36, 1, 10, hex(0x4B4F55));
}

// MARK: Jezero

/**
 * The pad at Jezero: a sky the colour of weak tea, the crater rim on the horizon, the
 * settlement's domes, and the cargo lander on the pad with people in suits about it.
 */
export function jezero(px, t) {
  px.sky(0xB98457, 0xE6B98A, 60);
  // The freighter, a moving star in orbit.
  px.rect(Math.floor(wrap(30 + t * 2, 160)), 8, 1, 1, white);
  px.hills(0, 160, 58, hex(0x9A5A3A), (x) => 4 + 3 * Math.sin(x / 17) + 2 * Math.sin(x / 7));
  px.rect(0, 58, 160, 22, hex(0xA65A32));
  for (const [x, y] of [[8.0, 66.0], [30, 74], [90, 70], [140, 76], [120, 64], [64, 77]]) {
    px.rect(x, y, 3, 2, hex(0x7E3A22));
  }
  // Domes.
  for (const [x, r] of [[112.0, 9.0], [131, 12.0], [148, 7.0]]) {
    disc(px, x, 60, r, 0xE4DDD0, 0xB9B0A2, true);
    px.rect(x - 1, 56, 2, 2, hex(0xF2D16B));
  }
  // The pad, the lander on its legs, its ramp down, and three people in suits.
  px.rect(30, 62, 46, 3, hex(0x8C8378));
  const shell = hex(0xDCE1E6);
  px.polygon([P(44, 58), P(62, 58), P(58, 40), P(48, 40)], shell);
  px.rect(48, 38, 10, 2, hex(0xA7AEB7));
  px.rect(50, 46, 6, 2, hex(0xF2D16B));
  px.line(P(45, 58), P(40, 62), hex(0x8C939C));
  px.line(P(61, 58), P(66, 62), hex(0x8C939C));
  px.polygon([P(58, 56), P(70, 61), P(70, 62), P(58, 58)], hex(0x8C939C));
  [70.0, 76, 82].forEach((x, k) => {
    px.rect(x, 57 + k % 2, 2, 4, white);
    px.rect(x, 57 + k % 2, 2, 1, hex(0xF2B632));
  });
}

// MARK: The end of her

/** The hull has let go: two pieces going apart, and what was inside them. */
export function wreck(px, f, t) {
  const d = 3 + Math.min(8, t * 0.4);
  const c = flying;
  for (let r = 0; r < ship.length; r++) {
    const row = ship[r];
    for (let k = 0; k < row.length; k++) {
      const ch = row[k];
      if (ch === ' ') continue;
      const color = colors[ch];
      if (!color) continue;
      const fore = k >= 28;
      const x = c.x - shipW / 2 + k + (fore ? d : -d);
      const y = c.y - shipH / 2 + r + (fore ? -d / 3 : d / 2);
      px.rect(Math.floor(x), Math.floor(y), 1, 1, fore ? color : opacity(color, 0.85));
    }
  }
  for (let i = 0; i < 16; i++) {
    const a = i * 2.4, s = d * (0.8 + (i % 5) * 0.35);
    px.rect(Math.floor(c.x + 4 + s * Math.cos(a)), Math.floor(c.y + s * Math.sin(a) * 0.7), 1, 1,
      opacity(hex(i % 3 === 0 ? 0xF2D16B : 0xDCE1E6), 0.85));
  }
}

/** Lost in the aerobrake: Mars's edge below, and a short bright line across the top of its air. */
export function streak(px, t) {
  limbBelow(px, t);
  const x = 40 + wrap(t * 20, 90);
  // Down through the air's top rows (51 to 54 over the middle of the ground).
  px.line(P(x - 24, 47), P(x, 53), hex(0xFFE2B0));
  px.line(P(x - 24, 48), P(x, 54), opacity(hex(0xFF9A50), 0.7));
  px.rect(Math.floor(x), 53, 2, 2, white);
}

// MARK: Space weather

/** Interference on the picture. */
export function noise(px, t, count) {
  const frame = Math.floor(t * 10);
  for (let i = 0; i < count; i++) {
    const h = (i * 7919 + frame * 104_729) & 0xFFFF;
    px.rect(h % 160, Math.trunc(h / 160) % 80, 1, 1, opacity(white, i % 2 === 0 ? 0.55 : 0.3));
  }
}

/** What the weather looks like out here, over everything. The kind of sky picks it. */
export function weather(px, f, ship) {
  const t = f.t;
  switch (f.weather.sky) {
    case 'clear': case 'heat': case 'rain': case 'snow':
      break;
    case 'still': {
      // A clean fix: Earth's signal reaching her dish, a pulse along it.
      if (!ship) break;
      const dish = place(40, 6, ship.facing, ship.at);
      const from = P(0.0, 16.0);
      const n = 30.0;
      for (const k of stride(0.0, n, 1, false)) {
        const x = from.x + (dish.x - from.x) * k / n, y = from.y + (dish.y - from.y) * k / n;
        px.rect(Math.floor(x), Math.floor(y), 1, 1, opacity(hex(0x9FE8B0), 0.35));
      }
      const p = wrap(t * 0.8, 1);
      px.rect(Math.floor(from.x + (dish.x - from.x) * p), Math.floor(from.y + (dish.y - from.y) * p), 2, 2,
        hex(0xC8FFD4));
      break;
    }
    case 'breeze':
      // The solar wind, streaming away from the Sun.
      for (let i = 0; i < 10; i++) {
        const di = i;
        const x = wrap(150 - t * (50 + di * 7) + di * 31, 180) - 10;
        px.rect(Math.floor(x), (i * 23 + 5) % 74 + 3, 9, 1, opacity(hex(0xF2D16B), 0.22));
      }
      break;
    case 'dust':
      // Pebbles going by, and now and then one hitting her.
      for (let i = 0; i < 14; i++) {
        const di = i;
        const p = wrap(t * (90 + di * 9) + di * 41, 200);
        const x = 170 - p, y = (i * 19) % 60 + p * 0.18 - 10;
        px.line(P(x, y), P(x + 4, y - 1), opacity(hex(0xD9C9A8), 0.8));
      }
      if (ship && Math.floor(t * 1.3) % 3 === 0) {
        const q = place(30, 11, ship.facing, ship.at);
        px.rect(q.x, q.y, 2, 2, white);
      }
      break;
    case 'fog': {
      // Radio noise: static over the picture.
      px.rect(0, 0, 160, 80, opacity(hex(0x8A93A0), 0.1));
      noise(px, t, 70);
      const band = wrap(t * 25, 90) - 5;
      px.rect(0, Math.floor(band), 160, 1, opacity(white, 0.12));
      break;
    }
    case 'storm':
      // A proton storm: a pale wash, and hits flickering on the picture.
      px.rect(0, 0, 160, 80, opacity(hex(0xDDEBD9), 0.16));
      hits(px, t, 14);
      break;
    case 'gale': {
      // A mass ejection: a bright front going through, and everything lit by it.
      px.rect(0, 0, 160, 80, opacity(hex(0xFFB070), 0.12));
      const x0 = 160 - wrap(t * 45, 260);
      for (let k = 0; k < 40; k++) {
        const x = x0 + k * 2;
        if (!(x > -2 && x < 160)) continue;
        px.rect(Math.floor(x), 0, 2, 80, opacity(hex(0xFFE2B8), 0.5 * (1 - k / 40)));
      }
      hits(px, t, 20);
      break;
    }
    default:
      throw new Error(`no weather for the sky ${f.weather.sky}`);
  }
}

/** Particles striking the camera: single bright pixels, somewhere new each moment. */
export function hits(px, t, count) {
  const frame = Math.floor(t * 8);
  for (let i = 0; i < count; i++) {
    const h = (i * 2971 + frame * 7703) & 0x3FFF;
    px.rect(h % 160, Math.trunc(h / 160) % 80, 1, 1, opacity(white, 0.9));
  }
}

// MARK: VoiceOver

/**
 * Where she is, as a sentence says it after a verb: "in the first ice stream", "on the
 * approach to Mars". The engine's region names are headings.
 */
export const phrases = {
  cislunar: 'in cislunar space, between the Earth and the Moon',
  departure: 'on the departure leg, Earth and the Moon behind her',
  stream1: 'in the first ice stream',
  inner: 'on the inner arc',
  deep: 'in deep space',
  stream2: 'in the second ice stream',
  shadow: 'in the conjunction shadow, the Sun between her and Earth',
  approach: 'on the approach to Mars',
  capture: 'close to Mars',
};

export function phrase(region) {
  if (!region) return 'out along the arc';
  return phrases[region.id] ?? 'out along the arc';
}

/** For the plot's label: docked somewhere, or out on the arc. `region` is the state's. */
export function whereabouts(J, g, region) {
  // The stop's name, which reads in a sentence: "the cycler Perpetua".
  if (g.atPort && isPort(J, currentStop(J, g).id)) return `docked at ${currentStop(J, g).name}`;
  if (g.stopIndex === J.stops.length - 1 && g.mile >= currentStop(J, g).mile) return 'at Jezero Landing';
  return phrase(region);
}

export function label(J, f) {
  const g = f.state;
  if (!g) return 'A transfer freighter burning out from Earth, her solar wings spread';
  const weather = `Weather: ${f.weather.name.toLowerCase()}`;
  if (lost(f)) {
    return aerobraking(J, g, f.region) ? 'A short bright line across the top of the Martian sky, where the freighter was'
      : 'The freighter in two pieces, drifting apart among her own debris. The pressure hull has let go';
  }
  if (landed(J, f)) return "The cargo lander on the pad at Jezero Landing, the settlement's domes beyond and the crater rim on the horizon";
  const wings = dark(f) ? ', her array dark' : '';
  const id = dockedAt(J, f);
  if (id !== null) {
    switch (id) {
      case 'gateway': return `The freighter docked at Gateway Yard, Earth's blue curve below${wings}`;
      case 'cycler': return `The freighter docked alongside the cycler Perpetua, her wheel turning${wings}`;
      case 'midway': return `The freighter docked at Midway Depot, beside its three tanks${wings}`;
      default: return `The freighter docked at Phobos Yard, Mars overhead${wings}`;
    }
  }
  const how = tumbling(J, f) ? 'tumbling slowly, her tanks dry,' : coasting(J, f) ? 'coasting with her array dark,' : '';
  const stop = atStop(J, f);
  if (stop) {
    const lead = how === '' ? 'The freighter' : `The freighter, ${how}`;
    switch (stop.id) {
      case 'lunar': return `${lead} passing the Moon, close enough to see its craters. ${weather}`;
      case 'hill': return `${lead} crossing the edge of Earth's reach, Earth and the Moon behind her. ${weather}`;
      case 'cycler': return `${lead} coming up on the cycler Perpetua, lit like a town at night. ${weather}`;
      case 'turnover':
        return turnoverWaits(J, g) ? `${lead} at Turnover, waiting for the power to turn round. ${weather}`
          : `${lead} standing on end at Turnover, halfway through turning round. ${weather}`;
      case 'midway': return `${lead} coming up on Midway Depot's three tanks. ${weather}`;
      case 'shadow': return `${lead} entering the conjunction shadow, Earth sliding behind the Sun. ${weather}`;
      case 'approach': return `${lead} on the approach, Mars and its two moons ahead. ${weather}`;
      case 'phobos': return `${lead} coming up on Phobos, Mars filling half the sky. ${weather}`;
      default: return `${lead} at ${stop.name}. ${weather}`;
    }
  }
  const place = phrase(f.region);
  if (how !== '') return `The freighter ${how} ${place}${dark(f) && tumbling(J, f) ? ', her array dark' : ''}. ${weather}`;
  if (!f.moving) return `The freighter ${place}, her drive idle${wings}. ${weather}`;
  if (aerobraking(J, g, f.region)) return `The freighter skimming the top of the Martian air, glowing. ${weather}`;
  const verb = turned(J, g) ? 'braking tail first' : 'burning';
  return `The freighter ${verb} ${place}. ${weather}`;
}
