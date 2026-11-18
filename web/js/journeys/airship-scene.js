// Over the Pole's scene (AroundTheHorn/Journeys/AirshipScene.swift): a small semi-rigid
// airship, nose to the right, over nine kinds of country under nine weathers, an airship's
// scene being mostly sky. A mooring mast at each of the five masts, and the stops between
// drawn as what they are: the Rhône's mouth, the Circle, Bear Island, flags at the Pole,
// the village at Point Barrow, two coasts at Cape Prince of Wales, the roofs of Nome. She
// flies lower as her lift goes, her propeller stutters and smokes as the engines fail and
// stops altogether with the tanks dry, and icing fog rimes her white.
//
// Every function takes the journey's tables `J` where the app's reads
// `AirshipSkin.journey`, and the frame `f` from drawing.js `sceneFrame`: what the app asks
// of its GameState beyond the state itself (the date, `Airship.enginesOut`) is the frame's
// `date` and `hooks`, the bridge's answers.

import { PixelCanvas, hex, opacity, white, jsRounded } from '../pixels.js';
import { latitude } from './airship-chart.js';

export const horizon = 58;

// MARK: Sky

/**
 * By the kind of sky. The two winds share a sky, and so do the two fogs: a following wind
 * is the one that carries her (`speed` over 1), and icing fog is the fog that is hard on
 * the crew (`harsh`). `ground` is how much of its own colour the ground keeps under this
 * sky; `rough`, how hard she pitches: 1 in ordinary air.
 */
export function palette(w) {
  const P = (top, bot, o = {}) => ({ top, bot, ground: 1, clouds: 0, cloud: 0xF4F7FA, sun: false, rough: 1, ...o });
  switch (w.sky) {
    case 'clear': case 'still': case 'heat': case 'dust':
      return P(0x2D5F9A, 0x9FD0EE, { clouds: 1, sun: true });
    case 'breeze':
      return w.speed > 1
        ? P(0x2A5C98, 0xA8D8F0, { clouds: 2, sun: true })
        : P(0x3A5F8A, 0x9DB9D0, { ground: 0.95, clouds: 3, cloud: 0xE1E8EE });
    case 'rain':
      return P(0x3E4A5A, 0x7D8A98, { ground: 0.75, clouds: 3, cloud: 0x6B7685 });
    case 'fog':
      return w.harsh > 0 ? P(0x7F8C96, 0xB9C4CC, { ground: 0.7 })
        : P(0x8D969E, 0xC5CBD0, { ground: 0.8 });
    case 'snow':
      return P(0x55606E, 0xA6B2BF, { ground: 0.85, clouds: 3, cloud: 0x8C97A3 });
    case 'gale':
      return P(0x33404F, 0x6E7D8D, { ground: 0.7, clouds: 3, cloud: 0x55616F, rough: 2 });
    case 'storm':
      return P(0x15191F, 0x3A434F, { ground: 0.5, clouds: 3, cloud: 0x2C333D, rough: 3 });
    default:
      throw new Error(`no palette for the sky ${w.sky}`);
  }
}

export const following = (w) => w.sky === 'breeze' && w.speed > 1;
export const icing = (w) => w.sky === 'fog' && w.harsh > 0;

// MARK: The airship

/**
 * 32 × 14, nose to the right: the envelope with its painted band, the fins, the engine car
 * with its pusher propeller, and the control car.
 */
export const ship = [
  '  ff                            ',
  '  ffff     hhhhhhhhhhhhhhh      ',
  '   ffffhhhhhhhhhhhhhhhhhhhhhh   ',
  '   ffeeeeeeeeeeeeeeeeeeeeeeeeee ',
  '    eeeeeeeeeeeeeeeeeeeeeeeeeeen',
  'fffrrrrrrrrrrrrrrrrrrrrrrrrrrrrn',
  '    eeeeeeeeeeeeeeeeeeeeeeeeeeen',
  '   ffeeeeeeeeeeeeeeeeeeeeeeeeee ',
  '   ffffdddddddddddddddddddddd   ',
  '  ffff     ddddddddddddddd      ',
  '  ff      p k k      k   k      ',
  '          pmmmmm   gwgwgwgwg    ',
  '          p mmm     ggggggg     ',
  '          p                     ',
];

export const colors = {
  h: hex(0xEEF1F4), e: hex(0xC8CDD3), d: hex(0x8C939C), r: hex(0xD64545),
  f: hex(0xA7AEB7), n: hex(0x6B6F76), k: hex(0x4B4F55), g: hex(0x6B4A2B),
  w: hex(0xF2D16B), m: hex(0x3A3F47), p: hex(0xDCE3EA),
};

/** Where she flies, and where she rides at a mast, nose to the mast head. */
export const flyingX = 44, flyingY = 14;
export const mooredX = 98, mooredY = 18;
export const mastX = 128, mastTop = 22;

// MARK: When and where

export const isNight = (hour) => hour >= 20 || hour < 5;

/** Days in 1926 before the first of each month. */
export const daysBefore = [0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334];

const portOf = (J, id) => J.ports.find((p) => p.id === id) ?? null;
const currentStop = (J, g) => J.stops[g.stopIndex];

/**
 * Whether the sun stays up all night where she is on this date: when the sun's declination
 * is more than 90° less her latitude, less 0.83° for refraction and its half-width. North
 * of the Circle, and later in the spring the nearer the Circle: Kings Bay from about April
 * 17, Vadsø from about May 16, the Circle itself only for a month round midsummer. Oslo,
 * Pulham and Nome never.
 */
export function midnightSun(f) {
  const g = f.state;
  if (!g) return false;
  const [, month, day] = f.date;
  const declination = 23.44 * Math.sin(2 * Math.PI * ((daysBefore[month] + day) - 80) / 365.24);
  return latitude(g.mile) + declination > 89.17;
}

/**
 * The mast she is moored to, if she is: in port at a stop that has one. (At the end of
 * the flight she is "in port" at Nome, which has no mast.)
 */
export function moored(J, f) {
  const g = f.state;
  if (!f.atPort || !g || !portOf(J, currentStop(J, g).id)) return null;
  return currentStop(J, g).id;
}

/** Forced down: the flight is over and her lift is gone. */
export function down(f) {
  const g = f.state;
  if (!g) return false;
  return g.over && g.hull <= 0;
}

/**
 * With the tanks dry or the engines given out, once the flight is under way: a fresh
 * voyage has bought nothing yet.
 */
export function drifting(J, f) {
  const g = f.state;
  if (!g || moored(J, f) !== null || down(f)) return false;
  return (g.fuel <= 0 || f.hooks.airship.enginesOut) && g.day > 0;
}

/**
 * The mast at the stop she has reached and is not moored to: its arrival's question on
 * screen, or flying on past it, or just cast off. (Rome's is behind her as soon as she
 * leaves.)
 */
export function passing(J, f) {
  const g = f.state;
  if (!g || moored(J, f) !== null || down(f) || !(g.stopIndex > 0)) return null;
  const stop = currentStop(J, g);
  return g.mile === stop.mile && portOf(J, stop.id) ? stop.id : null;
}

/** The stop she is standing at, its arrival told, when it isn't a mast she is moored to. */
export function landmark(J, f) {
  const g = f.state;
  if (!g || moored(J, f) !== null || down(f) || !(g.stopIndex > 0)) return null;
  const stop = currentStop(J, g);
  return stop.type !== 'port' && g.mile === stop.mile ? stop : null;
}

// MARK: Drawing

/** Swift's `truncatingRemainder`, brought into 0..<period. */
export function wrap(x, period) {
  const m = x % period;
  return m < 0 ? m + period : m;
}

export function draw(J, px, f) {
  const s = palette(f.weather);
  const t = f.t, w = px.w, h = px.h, hz = horizon;
  const region = f.region?.id ?? 'med';
  const sunUp = midnightSun(f);
  const dark = isNight(f.hour);
  const night = dark && !sunUp;
  const dry = drifting(J, f);
  const stop = landmark(J, f);
  const port = moored(J, f);
  const atMast = port ?? passing(J, f);
  const tint = (c) => PixelCanvas.mix(c, 0x000000, 1 - s.ground);
  // How fast the nearest country slides by, in pixels a second.
  const pace = f.moving ? 14 * (dry ? 0.25 : f.weather.speed) + 2 : 1.5;

  px.sky(s.top, s.bot, hz);
  if (s.sun && !night) sun(px, f, sunUp, port !== null);
  const drift = f.moving ? (f.weather.sky === 'breeze' && !following(f.weather) ? 3.2 : 1.6) : 0.4;
  px.clouds(s.clouds * 2, hex(s.cloud), t, drift);

  // The country: a mast's own ground, a stop's, or the region's.
  const country = atMast !== null ? 'mast-' + atMast : stop !== null ? ground(stop.id) : region;
  far(px, country, f.moving ? t * pace * 0.08 : 0, tint);
  px.rect(0, hz, w, h - hz, tint(base(country)));
  detail(px, country, t, pace, s.rough, tint);
  if (atMast !== null) mast(px, atMast, t, port !== null, tint);
  if (stop !== null) drawLandmark(px, stop.id, t, tint);
  if (down(f)) camp(px, f.region, t, tint);

  const at = position(J, f, s);
  airship(px, f, s, dry || down(f), at);

  if (region === 'underFog' && port === null && stop === null && !down(f)) ceiling(px, t);
  if (following(f.weather)) streaks(px, t, pace);
  px.air(f.weather.sky, t);

  if (night) {
    px.rect(0, 0, w, h, opacity(hex(0x070B1C), 0.6));
    lights(px, at, s.sun);
  } else if (dark) {
    // The midnight sun: low, gold light the whole night through.
    px.rect(0, 0, w, h, opacity(hex(0xE8A070), 0.14));
  }
}

/**
 * Climbing and sinking across whichever side of the sky she isn't in; where it does not
 * set, the midnight sun, circling low.
 */
export function sun(px, f, circling, moored) {
  const color = hex(0xFFE27A);
  if (circling) {
    const a = f.hour / 24 * 2 * Math.PI;
    // Round the far side of her: at (126, 44) at midnight, highest and nearest at noon.
    px.sun(Math.floor(96 + 30 * Math.cos(a)), Math.floor(40 + 4 * Math.cos(a)), color);
  } else {
    const across = Math.max(0, Math.min(14, f.hour - 5)) / 14;
    const x = (moored ? 60 : 140) - across * 40;
    px.sun(Math.floor(x), Math.floor(5 + Math.abs(f.hour - 12) * 2.2), color);
  }
}

// MARK: Country

/**
 * What a stop stands on, when it isn't the region's ground: the ice at the Pole, the
 * strait at Cape Prince of Wales.
 */
export function ground(id) {
  switch (id) {
    case 'pole': return 'polarSea';
    case 'wales': return 'strait';
    case 'rhone': return 'france';
    case 'circle': return 'scandinavia';
    case 'bear': return 'barents';
    default: return 'alaska';
  }
}

export function base(id) {
  switch (id) {
    case 'med': return 0x1D4E7A;
    case 'france': return 0x4F6B3A;
    case 'northSea': case 'strait': return 0x24394E;
    case 'scandinavia': return 0xDDE6EC;
    case 'barents': return 0x1A2C3C;
    case 'polarSea': case 'underFog': return 0xE6EDF2;
    case 'aboveFog': return 0xD9DEE2;
    case 'alaska': return 0x6B6A4F;
    case 'mast-rome': return 0x8A8F4E;
    case 'mast-pulham': return 0x5E7A3E;
    case 'mast-oslo': return 0x4F6B3A;
    case 'mast-vadso': return 0x1A2C3C;
    case 'mast-kingsbay': return 0xE6EDF2;
    default: return 0x4F6B3A;
  }
}

/** What stands on the horizon. */
export function far(px, id, scroll, tint) {
  const hz = horizon;
  const all = [0, Math.trunc(px.w)];
  const ridge = (color, range, snow, height) => {
    const [from, to] = range ?? all;
    px.hills(from, to, hz, tint(color), (x) => height(x + scroll));
    if (snow === null) return;
    for (let i = from; i < to; i++) {
      const hh = jsRounded(height(i + scroll));
      if (hh > snow) px.rect(i, hz - hh, 1, Math.min(3, hh - snow), tint(0xF4F7FA));
    }
  };
  switch (id) {
    case 'med':
      ridge(0x4A6A7E, [112, 150], null, (x) => Math.max(0, 3 + 2 * Math.sin(x * 0.2) - Math.abs(x - 131) * 0.18));
      break;
    case 'france': case 'mast-rome':
      ridge(0x5E7A48, null, null, (x) => 2 + 1.5 * Math.sin(x * 0.06) + Math.sin(x * 0.17));
      break;
    case 'scandinavia': case 'mast-oslo':
      ridge(0x6E7C8A, null, 6, (x) => 6 + 4 * Math.sin(x * 0.05) + 2 * Math.sin(x * 0.17));
      break;
    case 'barents': case 'polarSea': case 'mast-vadso':
      // Ice blink: the pale sky over far-off ice.
      px.rect(0, hz - 1, px.w, 1, tint(0xC8D4DC));
      break;
    case 'aboveFog':
      ridge(0xF4F7FA, null, null, (x) => 2 + 1.5 * Math.sin(x * 0.09) + Math.sin(x * 0.23));
      break;
    case 'alaska':
      ridge(0x5A5A44, null, 4, (x) => 3 + 2 * Math.sin(x * 0.05) + Math.sin(x * 0.19));
      break;
    case 'mast-kingsbay':
      // White peaks beyond the fjord, grey where the snow has slid off.
      ridge(0xF4F7FA, null, null, (x) => 13 + 8 * Math.sin(x * 0.07) + 4 * Math.sin(x * 0.21));
      ridge(0x8C939C, null, null, (x) => Math.max(0, 6 + 6 * Math.sin(x * 0.07 + 0.8) + 2 * Math.sin(x * 0.33)));
      break;
    default:
      break;
  }
}

/** Six rows of country sliding by under her, the nearer rows faster. */
export function detail(px, id, t, pace, rough, tint) {
  const w = px.w, hz = horizon;
  for (let row = 0; row < 6; row++) {
    const y = Math.floor(hz + 2 + row * 3.4);
    const rs = pace * (0.4 + row * 0.18);
    for (let i = 0; i < 7; i++) {
      // Spread along the row, each nudged its own way, so no two rows line up.
      const spot = i * 25 + (row * 41) % 25 + (i * 13 + row * 29) % 11;
      const x = Math.floor(wrap(spot - t * rs, w + 12) - 6);
      const k = (i + row) % 3;
      const jitter = rough > 1 ? jsRounded(Math.sin(t * 3 + (i + row))) : 0;
      switch (id) {
        case 'med': case 'northSea': case 'strait': case 'mast-vadso': {
          const wave = id === 'med' ? 0x7FB8DE : 0x8AA0B4;
          px.rect(x, y + jitter, 2 + k + rough - 1, 1, tint(wave));
          break;
        }
        case 'france': case 'mast-rome': case 'mast-pulham': case 'mast-oslo':
          // Hedgerows, and every so often a village.
          px.rect(x, y + jitter, 4 + k, 1, tint(0x3A5229));
          if (id === 'france' && (row === 1 || row === 4) && i % 3 === 0) {
            px.rect(x + 8, y - 1, 3, 2, tint(0xE9DFC8));
            px.rect(x + 8, y - 2, 3, 1, tint(0x9A3B2E));
          }
          break;
        case 'scandinavia':
          // Pines.
          px.rect(x, y - 1, 1, 2, tint(0x2F4A35));
          px.rect(x + 2 + k, y, 1, 2, tint(0x2F4A35));
          break;
        case 'barents':
          // Floes, two to four pixels.
          px.rect(x, y + jitter, 2 + k, 1, tint(0xE8EEF3));
          break;
        case 'polarSea': case 'underFog': case 'mast-kingsbay':
          // Pressure ridges, and now and then a lead of open water.
          px.rect(x, y + jitter, 3 + k, 1, tint(0x9FB0BF));
          if (i % 4 === 1) px.rect(x + 7, y + 1, 9 + k * 3, 1, tint(0x2A3C4F));
          break;
        case 'aboveFog':
          // The top of the fog, billowing.
          px.rect(x, y, 6, 2, tint(0xF4F7FA));
          px.rect(x + 1, y - 1, 4, 1, tint(0xF4F7FA));
          break;
        case 'alaska':
          // Snow lying in patches on the tundra.
          px.rect(x, y + jitter, 3 + k, k === 2 ? 2 : 1, tint(0xE6EDF2));
          break;
        default:
          break;
      }
    }
  }
}

/** Under the fog: its underside just over the envelope. */
export function ceiling(px, t) {
  const c = opacity(hex(0xB9C1C8), 0.9);
  px.rect(0, 0, px.w, 8, c);
  for (let i = 0; i < 12; i++) {
    const x = Math.floor(wrap(i * 14 - t * 4, px.w + 14) - 7);
    px.rect(x, 8, 9, 2, c);
    px.rect(x + 2, 10, 5, 1, opacity(c, 0.7));
  }
}

/** A following wind: streaks racing past her, faster than the country. */
export function streaks(px, t, pace) {
  for (let i = 0; i < 4; i++) {
    const x = Math.floor(wrap(i * 47 - t * pace * 3, px.w + 12) - 6);
    px.rect(x, 8 + i * 11, 6, 1, hex(0xE9F4FB));
  }
}

// MARK: Masts

/**
 * The town beside each mast, the lattice mast itself, and the ground crew: on her handling
 * lines when she is moored (`lines`), waiting at the foot of the mast when not.
 */
export function mast(px, id, t, lines, tint) {
  const hz = horizon;
  const roof = tint(0x9A3B2E);
  switch (id) {
    case 'rome':
      // Two umbrella pines.
      for (const x of [10, 24]) {
        px.rect(x + 5, hz - 14, 1, 14, tint(0x6B4A2B));
        px.rect(x, hz - 18, 12, 3, tint(0x2F4A35));
        px.rect(x + 2, hz - 20, 8, 2, tint(0x2F4A35));
        px.rect(x + 1, hz - 15, 10, 1, tint(0x24402C));
      }
      break;
    case 'pulham':
      // A long airship shed, its doors open.
      px.rect(4, hz - 14, 40, 14, tint(0x8C939C));
      px.rect(6, hz - 16, 36, 2, tint(0x8C939C));
      px.rect(10, hz - 17, 28, 1, tint(0x8C939C));
      px.rect(38, hz - 12, 6, 12, tint(0x2A2D33));
      for (let i = 0; i < 5; i++) px.rect(8 + i * 6, hz - 13, 1, 13, tint(0x7A818A));
      break;
    case 'oslo':
      // Ekeberg hill and its houses.
      px.hills(0, 64, hz, tint(0x2F4A35), (x) => Math.max(0, 12 + 5 * Math.sin(x * 0.08) - Math.abs(x - 30) * 0.25));
      for (let i = 0; i < 5; i++) {
        const x = 8 + i * 9, bh = 3 + (i * 5) % 3;
        const top = hz - Math.max(0, 12 + 5 * Math.sin(x * 0.08) - Math.abs(x - 30) * 0.25) + 2;
        px.rect(x, top - bh, 5, bh, tint(0xE9DFC8));
        px.rect(x, top - bh - 1, 5, 1, roof);
      }
      break;
    case 'vadso':
      // A strip of shore with four wooden houses, and the mast's bare island.
      px.rect(0, hz, 50, 4, tint(0x6E6A5E));
      for (let i = 0; i < 4; i++) {
        const x = 4 + i * 11;
        px.rect(x, hz - 4, 6, 4, tint(0xC9A27A));
        px.rect(x, hz - 5, 6, 1, roof);
        px.rect(x + 2, hz - 3, 1, 1, tint(0x3A2A1E));
      }
      px.rect(116, hz, 24, 3, tint(0x6E6A5E));
      px.rect(119, hz - 1, 18, 1, tint(0x6E6A5E));
      break;
    case 'kingsbay':
      // The tall hangar of timber and canvas, and a heap of coal.
      px.rect(6, hz - 20, 26, 20, tint(0xB9A26C));
      px.rect(8, hz - 22, 22, 2, tint(0xB9A26C));
      for (let i = 0; i < 4; i++) px.rect(9 + i * 6, hz - 19, 1, 19, tint(0x9A845A));
      px.rect(28, hz - 16, 4, 16, tint(0x3A3226));
      px.polygon([{ x: 40, y: hz }, { x: 47, y: hz - 6 }, { x: 54, y: hz }], tint(0x26262B));
      break;
    default:
      break;
  }
  // The mast: two steel legs braced every four pixels, a platform and the mast head.
  const steel = tint(0x6B6F76), brace = tint(0x8C939C);
  px.rect(mastX, mastTop, 1, hz - mastTop, steel);
  px.rect(mastX + 4, mastTop, 1, hz - mastTop, steel);
  for (let y = mastTop + 2; y < hz - 3; y += 4) {
    px.line({ x: mastX, y }, { x: mastX + 4, y: y + 4 }, brace);
    px.rect(mastX, y, 5, 1, brace);
  }
  px.rect(mastX - 1, mastTop - 1, 7, 1, steel);
  px.rect(mastX + 1, mastTop - 3, 3, 2, steel);
  // The ground crew, on her handling lines.
  const rope = opacity(hex(0xD8C8A0), 0.8);
  for (const [from, to] of [[[mooredX + 19, mooredY + 12], [108, hz - 2]], [[mooredX + 25, mooredY + 12], [119, hz - 2]]]) {
    if (lines) px.line({ x: from[0], y: from[1] }, { x: to[0], y: to[1] }, rope);
    const sway = jsRounded(Math.sin(t * 1.3 + to[0]));
    px.rect(to[0] + sway, hz - 3, 1, 3, hex(0x2A2A30));
    px.rect(to[0] + sway, hz - 4, 1, 1, hex(0xEFD6B0));
  }
}

// MARK: Stops

export function drawLandmark(px, id, t, tint) {
  const hz = horizon, w = px.w;
  const P = (x, y) => ({ x, y });
  switch (id) {
    case 'rhone':
      // The coast behind her, and the river winding up its valley between the hills.
      px.polygon([P(0, hz), P(30, hz), P(16, 80), P(0, 80)], tint(0x1D4E7A));
      for (let i = 0; i < 4; i++) px.rect(2 + (i % 2) * 6, 61 + i * 4, 3, 1, tint(0x7FB8DE));
      px.hills(30, 160, hz, tint(0x6E7C5A), (x) => 6 + 3 * Math.sin(x * 0.07) + 2 * Math.sin(x * 0.19));
      for (let x = 22; x < w; x += 1) {
        const y = 68 + 4 * Math.sin(x * 0.06) - (x - 22) * 0.06;
        px.rect(x, Math.floor(y), 1, 2, tint(0x7FB8DE));
      }
      break;
    case 'circle':
      // The line nobody can see, drawn anyway.
      for (let x = 0; x < w; x += 6) {
        px.rect(x, 69, 3, 1, opacity(hex(0xF2D16B), 0.75));
      }
      break;
    case 'bear':
      // A black wedge of cliffs to the west, streaked with snow, and its birds.
      px.polygon([P(2, hz), P(10, 47), P(20, 43), P(31, 46), P(44, hz)], tint(0x2A2D33));
      for (const [x, y, l] of [[12, 48, 4], [19, 45, 5], [26, 47, 3], [33, 51, 4]]) {
        px.rect(x, y, 1, l, tint(0xE8EEF3));
      }
      for (let i = 0; i < 7; i++) {
        const a = t * 0.9 + i * 0.9;
        const x = Math.floor(24 + 16 * Math.cos(a)), y = Math.floor(34 + 5 * Math.sin(a * 1.3));
        px.rect(x, y, 1, 1, hex(0xECE4CF));
        px.rect(x + 1, y - 1, 1, 1, hex(0xECE4CF));
        px.rect(x - 1, y - 1, 1, 1, hex(0xECE4CF));
      }
      break;
    case 'pole':
      // Flags on weighted staffs, standing in the snow below her.
      for (const [x, y, c] of [[62, 66, 0xD64545], [75, 70, 0x2E6FB0], [88, 65, 0xF2D16B]]) {
        px.rect(x, y - 8, 1, 8, tint(0x4B4F55));
        const flap = jsRounded(Math.sin(t * 4 + x));
        px.rect(x + 1, y - 8, 4, 2, tint(c));
        px.rect(x + 1, y - 6, 3 + flap, 1, tint(c));
        px.rect(x - 1, y, 3, 1, tint(0xF4F7FA));
      }
      break;
    case 'barrow':
      // The village out on the shore ice, the trading post, the aviators' tent and their
      // petrol drums, and everyone waving.
      px.rect(0, 70, w, 10, tint(0xE6EDF2));
      for (let i = 0; i < 4; i++) {
        const x = 6 + i * 10;
        px.rect(x, hz - 4, 6, 5, tint(0x8A6A48));
        px.rect(x, hz - 5, 6, 1, tint(0xE6EDF2));
      }
      px.rect(48, hz - 6, 11, 7, tint(0x9A7A52));
      px.rect(48, hz - 7, 11, 1, tint(0x6B4A2B));
      px.rect(51, hz - 5, 5, 1, tint(0xF0E8D0));
      px.polygon([P(98, hz + 1), P(104, hz - 6), P(110, hz + 1)], tint(0xD9C9A0));
      for (let i = 0; i < 5; i++) px.rect(114 + i * 3, hz - 1, 2, 2, tint(0x6B4A2B));
      for (let i = 0; i < 9; i++) {
        const x = 20 + i * 9, wave = jsRounded(Math.sin(t * 5 + i)) < 0 ? 1 : 0;
        px.rect(x, 63, 1, 3, hex(0x2A2A30));
        px.rect(x, 62, 1, 1, hex(0xEFD6B0));
        px.rect(x + 1, 62 - wave, 1, 1, hex(0x2A2A30));
      }
      break;
    case 'wales':
      // The cape below her, and across the strait the blue hills of Asia.
      px.polygon([P(0, hz), P(28, hz), P(48, 80), P(0, 80)], tint(0x4A4A3A));
      for (const [x, y] of [[6, 62], [14, 66], [9, 71], [22, 74]]) px.rect(x, y, 4, 1, tint(0xE6EDF2));
      px.hills(104, 160, hz, tint(0x6E86A8), (x) => Math.max(0, 5 + 3 * Math.sin(x * 0.11) - Math.abs(x - 134) * 0.06));
      break;
    case 'nome':
      // The beach, the roofs of Nome, and the whole town turned out.
      px.rect(0, 64, w, 4, tint(0xC8B98A));
      px.rect(0, 68, w, 12, tint(0x24394E));
      for (let i = 0; i < 10; i++) {
        const x = 92 + i * 7, bh = 4 + (i * 7) % 5;
        const wall = [0xA88A62, 0xC9A27A, 0x8C6A48][i % 3];
        px.rect(x, hz - bh, 6, bh + 1, tint(wall));
        px.rect(x, hz - bh - 1, 6, 1, tint(i % 2 === 0 ? 0x6B4A2B : 0x9A3B2E));
      }
      for (let i = 0; i < 16; i++) {
        const x = 40 + i * 6 + jsRounded(Math.sin(t * 2 + i));
        px.rect(x, 61, 1, 3, hex(0x2A2A30));
        px.rect(x, 60, 1, 1, hex(0xEFD6B0));
      }
      break;
    default:
      break;
  }
}

// MARK: Forced down

/**
 * Beside her where she came down, as the engine tells it (`Airship.wreckedBody`): a camp
 * on the ice where there is sea ice below, a fishing boat on open sea, or a farmer and his
 * dog in a field, Scandinavia's included.
 */
export function camp(px, region, t, tint) {
  const hz = horizon;
  const ink = hex(0x2A2A30), face = hex(0xEFD6B0);
  const P = (x, y) => ({ x, y });
  if (region?.tags.includes('pack')) {
    // The floe she came down on, and the camp beside the gondola.
    px.polygon([P(40, hz + 1), P(146, hz + 1), P(152, hz + 6), P(142, hz + 10), P(48, hz + 9), P(36, hz + 5)], tint(0xE6EDF2));
    px.rect(48, hz + 9, 94, 1, tint(0x9FB0BF));
    px.polygon([P(104, hz + 6), P(111, hz - 2), P(118, hz + 6)], tint(0xD9C9A0));
    px.rect(110, hz + 2, 2, 4, tint(0x6B4A2B));
    [122, 127, 131].forEach((x, i) => {
      px.rect(x, hz + 2, 1, 3, ink);
      px.rect(x, hz + 1, 1, 1, face);
      if (i === 1 && Math.trunc(t * 2) % 2 === 0) px.rect(x + 1, hz, 1, 1, ink);
    });
  } else if (region?.tags.includes('sea')) {
    const bob = jsRounded(Math.sin(t * 2));
    px.rect(112, hz + 6 + bob, 16, 3, tint(0x6B4A2B));
    px.rect(114, hz + 9 + bob, 12, 1, tint(0x4A2E1A));
    px.rect(121, hz - 4 + bob, 1, 10, tint(0x4A2E1A));
    px.rect(122, hz - 3 + bob, 4, 3, tint(0xD9C9A0));
    px.rect(116, hz + 4 + bob, 1, 2, ink);
  } else {
    px.rect(112, hz + 4, 1, 4, ink);
    px.rect(112, hz + 3, 1, 1, face);
    px.rect(111, hz + 2, 3, 1, tint(0x6B4A2B));
    const wag = Math.trunc(t * 4) % 2 === 0 ? 1 : 0;
    px.rect(116, hz + 6, 4, 2, tint(0x8A6A48));
    px.rect(119, hz + 5, 2, 1, tint(0x8A6A48));
    px.rect(115, hz + 5 - wag, 1, 1, tint(0x8A6A48));
  }
}

// MARK: The airship

/**
 * Where her top-left corner is: on the mast, coming down at Nome, or flying, lower as the
 * gas goes and pitching with the air.
 */
export function position(J, f, s) {
  if (moored(J, f) !== null) return { x: mooredX, y: mooredY };
  if (down(f)) return { x: flyingX + 8, y: horizon - 10 };
  if (landmark(J, f)?.id === J.stops[J.stops.length - 1]?.id) return { x: flyingX + 20, y: 30 };
  const drop = jsRounded((100 - Math.max(0, Math.min(100, f.hull))) / 10);
  const bob = jsRounded(Math.sin(f.t * (1.4 + s.rough * 0.7)) * (0.5 + s.rough * 0.5));
  return { x: flyingX, y: flyingY + drop + bob };
}

export function airship(px, f, s, dry, at) {
  const t = f.t;
  const running = f.moving && !dry;
  const x = at.x, y = at.y;
  const c = { ...colors };
  if (icing(f.weather)) {
    // Rime on the envelope's top and on every strut.
    c.h = white;
    c.k = hex(0xDDE6EC);
  }
  const frame = Math.floor(t * 12);
  const stutter = Math.max(0, 60 - f.sails) / 2.2;
  px.sprite(ship, x, y, c, (col, row, ch) => {
    if (ch !== 'p') return false;
    if (dry) return true;
    if ((col * 7 + row * 13) % 37 < stutter) return true;
    // A turning propeller shows half its blade at a time.
    return running && (row + frame) % 2 === 0;
  });
  // Slack, creased fabric as the lift goes.
  if (f.hull < 50) {
    const crease = hex(0xA9AFB7);
    px.sprite(ship, x, y, { e: crease }, (col, row) => (col * 5 + row * 3) % 11 !== 0 || col > 4 + (50 - f.hull) / 2);
  }
  if (icing(f.weather)) {
    // Icicles under the cars.
    for (const [cx, l] of [[12, 2], [14, 1], [20, 2], [23, 1], [26, 2]]) {
      px.rect(x + cx, y + 13, 1, l, hex(0xEEF4F8));
    }
  }
  if (f.sails < 40 && running) {
    // A failing engine: grey puffs going back from the engine car, fading as they go.
    const grey = hex(0x8F8A7A);
    for (let k = 0; k < 2; k++) {
      const p = Math.floor(wrap(t / 0.3 + k * 3.5, 7));
      px.rect(x + 8 - p, y + 11 - k, 2, 1, opacity(grey, Math.max(0.15, 1 - p / 6)));
    }
  }
}

/**
 * What shows in the dark: stars, a moon in a clear sky, the lit windows of the control car
 * and the riding lights.
 */
export function lights(px, at, clear) {
  if (clear) {
    for (let i = 0; i < 16; i++) {
      px.rect((i * 37 + 11) % 160, (i * 23 + 5) % 50, 1, 1, opacity(white, i % 3 === 0 ? 0.9 : 0.55));
    }
    px.moon(128, 6, hex(0xF2EED8), hex(0x141B33));
  }
  const x = at.x, y = at.y;
  px.sprite(ship, x, y, { w: hex(0xFFE27A) });
  px.rect(x + 31, y + 5, 1, 1, white);
  px.rect(x, y + 5, 1, 1, hex(0xFF5A4A));
}

// MARK: VoiceOver

/**
 * Where she is, as a sentence says it after a verb: "over the North Sea", "above the fog".
 * The engine's names are headings ("Mediterranean", "Under the Fog").
 */
export const whereaboutsNames = {
  med: 'over the Mediterranean', france: 'over France', northSea: 'over the North Sea',
  scandinavia: 'over Scandinavia', barents: 'over the Barents Sea', polarSea: 'over the Polar Sea',
  aboveFog: 'above the fog', underFog: 'under the fog', alaska: 'over the Alaskan coast',
};

export function whereabouts(region) {
  if (!region) return 'over open country';
  return whereaboutsNames[region.id] ?? `over ${region.name}`;
}

export function label(J, f) {
  const g = f.state;
  if (!g) return 'An airship flying north in clear weather';
  const id = moored(J, f);
  if (id !== null) {
    return `Airship moored at the mast at ${portOf(J, id)?.name ?? currentStop(J, g).short}`;
  }
  if (down(f)) {
    const r = f.region;
    return r?.tags.includes('pack') ? 'The airship down on the ice, her crew camped beside the gondola'
      : r?.tags.includes('sea') ? 'The airship down on the sea, a fishing boat coming alongside'
        : 'The airship down in a field, a farmer and his dog looking her over';
  }
  const weather = f.weather.name.toLowerCase();
  const by = passing(J, f);
  if (by !== null) {
    const name = portOf(J, by)?.name ?? currentStop(J, g).short;
    if (drifting(J, f)) return `Airship drifting past the mast at ${name}, engines stopped. Weather: ${weather}`;
    return f.moving ? `Airship flying past the mast at ${name}. Weather: ${weather}`
      : `Airship over the mast at ${name}, the ground crew waiting below. Weather: ${weather}`;
  }
  const stop = landmark(J, f);
  if (stop !== null) {
    switch (stop.id) {
      case 'rhone': return `Airship over the mouth of the Rhône, the coast behind her. Weather: ${weather}`;
      case 'circle': return `Airship crossing the Arctic Circle above the forests. Weather: ${weather}`;
      case 'bear': return `Airship passing Bear Island, its cliffs to the west. Weather: ${weather}`;
      case 'pole': return `Airship over the North Pole, flags standing in the snow below. Weather: ${weather}`;
      case 'barrow': return `Airship low over Point Barrow, the village out on the ice. Weather: ${weather}`;
      case 'wales': return `Airship over Cape Prince of Wales, the hills of Asia across the strait. Weather: ${weather}`;
      case 'nome': return 'Airship coming down over the roofs of Nome, the town on the beach';
      default: return `Airship over ${stop.name}. Weather: ${weather}`;
    }
  }
  const over = whereabouts(f.region);
  if (drifting(J, f)) return `Airship drifting ${over}, engines stopped. Weather: ${weather}`;
  const time = isNight(f.hour) ? (midnightSun(f) ? ' in the midnight sun' : ' by night') : '';
  return f.moving ? `Airship flying ${over}${time}. Weather: ${weather}`
    : `Airship ${over}${time}, engines stopped. Weather: ${weather}`;
}
