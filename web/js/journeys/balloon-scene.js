// The Jet Stream's scene (AroundTheHorn/Journeys/BalloonScene.swift): a Rozière balloon, a
// helium cell over a cone of hot air with a sealed capsule slung below, flying east (to the
// right) over sixteen kinds of country and sea under ten weathers. Three states, as 1849
// has sailing, hove to and at anchor: aloft (a watch being flown), loitering low (the
// menus, a rest, a question) and standing on a field. Each of the six fields is drawn with
// its hangar, fuel truck and crowd, and every other stop as itself. The burners blast while
// she flies and blip while she loiters; worn, they sputter orange and soot the cone; with no
// heat, dry tanks or dead burners, there is no flame at all; her crown sags as the lift
// goes. Nights fall by the local sun, worked out from where she is along the chart's route,
// not by the GMT the log keeps.
//
// Every function takes the journey's tables `J` where the app's reads
// `BalloonSkin.journey`, and the frame `f` from drawing.js `sceneFrame`: what the app asks
// of its GameState beyond the state itself (the month, `Balloon.burnersOut`, the chart's
// `onSouthTrack`, the region just short of the landfall) is the frame's `date` and
// `hooks.balloon`, the bridge's answers.

import { hex, opacity, white, jsRounded } from '../pixels.js';
import { north, south } from './balloon-chart.js';

export const aloftHorizon = 46.0;
export const lowHorizon = 40.0;

/** Swift's `x.rounded()`: halves away from zero. */
const rounded = (x) => Math.sign(x) * Math.round(Math.abs(x));

// MARK: Sky

/**
 * A palette's defaults: `deck` is the cloud deck that hides the ground aloft; `rough` is 0
 * in smooth air, and 2 and more sways her.
 */
export const paletteDefaults = { sun: null, bigSun: false, clouds: 0, cloud: 0xF4F7FA, deck: null, rough: 0.0,
  cirrus: false, still: false, shimmer: false, dust: false };

const P = (top, bot, o = {}) => ({ top, bot, ...paletteDefaults, ...o });

/**
 * By the kind of sky. A light wind and a steady one share a clear sky: the light wind is
 * the one that barely moves her (`speed` under 0.8), and its sky is paler.
 */
export function palette(w) {
  switch (w.sky) {
    case 'clear':
      return w.speed < 0.8 ? P(0x3A6AA2, 0xB6DCF0, { sun: 0xFFE27A, clouds: 1 })
        : P(0x2D5F9A, 0x9FD0EE, { sun: 0xFFE27A, clouds: 1 });
    case 'breeze':
      return P(0x1E4F8F, 0x8CC8EA, { sun: 0xFFE27A, cirrus: true });
    case 'still':
      return P(0xD9893F, 0xF6D78B, { sun: 0xFFF1B0, still: true });
    case 'heat':
      return P(0x3F7FC0, 0xE8F2F8, { sun: 0xFFFBE0, bigSun: true, shimmer: true });
    case 'fog':
      return P(0x8D969E, 0xC5CBD0, { deck: 0xC5CBD0 });
    case 'snow':
      return P(0x55606E, 0xA6B2BF, { clouds: 3, cloud: 0x8C97A3, deck: 0x8C97A3 });
    case 'gale':
      return P(0x33404F, 0x6E7D8D, { clouds: 3, cloud: 0x55616F, rough: 2 });
    case 'storm':
      return P(0x15191F, 0x3A434F, { clouds: 3, cloud: 0x2C333D, deck: 0x2C333D, rough: 3 });
    case 'dust':
      return P(0xB98A55, 0xE3C38E, { sun: 0xFFE9B0, dust: true });
    case 'rain':
      return P(0x3E4A5A, 0x7D8A98, { clouds: 3, cloud: 0x6B7685, rough: 1 });
    default:
      throw new Error(`no palette for the sky ${w.sky}`);
  }
}

// MARK: The balloon

/**
 * 18 × 20: the helium cell with its gold and red bands, the hot-air cone, the load cables,
 * the burner and its flame, and the capsule with its portholes and the propane cylinders
 * along its sides.
 */
export const balloon = [
  '       eeess      ',
  '     eeeeeesss    ',
  '    eeeeeeeesss   ',
  '   eeeeeeeeeesss  ',
  '  eeeeeeeeeeeesss ',
  '  eeeeeeeeeeeesss ',
  ' gggggggggggggggg ',
  ' rrrrrrrrrrrrrrrr ',
  ' eeeeeeeeeeeeesss ',
  '  eeeeeeeeeeeess  ',
  '   eeeeeeeeeess   ',
  '    kkkkkkkkkk    ',
  '     kkkkkkkk     ',
  '      kkkkkk      ',
  '      l oo l      ',
  '     l  ff  l     ',
  '    l  bbbb  l    ',
  '   tccccccccccct  ',
  '   tcwwcwwcwwcct  ',
  '    cccccccccc    ',
];

export const colors = {
  e: hex(0xE6E9EE), s: hex(0xB9C0CA), g: hex(0xD9A441), r: hex(0xD64545),
  k: hex(0xEFE6CC), l: hex(0x5A6270), o: hex(0xFF8A3D), f: hex(0xF2B632),
  b: hex(0x3A3F48), c: hex(0xECE4CF), w: hex(0x1A2533), t: hex(0x8A949E),
};

export const x0 = 50.0;
export const aloftY = 8.0, loiterY = 18.0, groundY = 33.0;

// MARK: Where she is

const portOf = (J, id) => J.ports.find((p) => p.id === id) ?? null;
const currentStop = (J, g) => J.stops[g.stopIndex];

/** Whether the flight has taken the southern track: the engine's answer, as the app's chart asks it. */
const onSouthTrack = (f) => f.hooks.balloon.southTrack;

/** Standing on a field with its ground team: on the ground at a stop that has one. */
export function field(J, f) {
  const g = f.state;
  if (!f.atPort || !g || !portOf(J, currentStop(J, g).id)) return null;
  return currentStop(J, g).id;
}

/**
 * Down for good: the attempt is over and the lift is gone (never at the finish line, where
 * she lands as she means to).
 */
export function down(J, f) {
  const g = f.state;
  if (!g || !g.over || currentStop(J, g).type === 'end') return false;
  return jsRounded(g.hull) <= 0;
}

/**
 * The field she is over and has not landed at: its arrival's question on screen, or flying
 * on past, or grounded there for good. (Marrakech's is behind her as soon as she climbs
 * away.)
 */
export function overField(J, f) {
  const g = f.state;
  if (!g || field(J, f) !== null || !(g.stopIndex > 0)) return null;
  const stop = currentStop(J, g);
  return g.mile === stop.mile && portOf(J, stop.id) ? stop.id : null;
}

/**
 * The stop she is at, its arrival told, when it isn't a field: the High Atlas, the
 * Himalaya, the edge of the Pacific, the date line, the landfall, the Azores, and the
 * finish line, where she has come down.
 */
export function landmark(J, f) {
  const g = f.state;
  if (!g || field(J, f) !== null || !(g.stopIndex > 0)) return null;
  const stop = currentStop(J, g);
  if (!(stop.type !== 'port' && g.mile === stop.mile)) return null;
  if (down(J, f)) return null;
  return stop;
}

/** Climbing away from Marrakech: the launch said, no watch flown yet. */
export function launching(f) {
  const g = f.state;
  if (!g || f.moving || g.atPort || g.over) return false;
  return g.stopIndex === 0 && g.mile === 0 && g.day === 0;
}

/**
 * No heat for the cone, once the flight is under way: the tanks dry or the burners given
 * out. A flight not yet launched has bought nothing.
 */
export function cold(J, f) {
  const g = f.state;
  if (!g || !(g.day > 0) || field(J, f) !== null || down(J, f)) return false;
  return g.fuel <= 0 || f.hooks.balloon.burnersOut;
}

/** Whether she is low, loitering: aloft, not flying a watch. */
export function loitering(J, f) {
  if (!f.state || field(J, f) !== null || down(J, f) || launching(f) || landmark(J, f)?.type === 'end') return false;
  return !f.moving;
}

/**
 * The longitude under her, read along the chart's route, east of Greenwich: the southern
 * track's when `southTrack`.
 */
export function longitude(g, southTrack) {
  const track = southTrack ? south : north;
  const m = g.mile;
  for (let i = 1; i < track.length; i++) {
    const a = track[i - 1], b = track[i];
    if (!(m <= b[2])) continue;
    return m <= a[2] || b[2] === a[2] ? a[0] : a[0] + (b[0] - a[0]) * (m - a[2]) / (b[2] - a[2]);
  }
  return track.length ? track[track.length - 1][0] : 0;
}

/** The hour by the sun where she is: the log's GMT and four minutes for every degree of longitude. */
export function localHour(f) {
  const g = f.state;
  if (!g) return f.hour;
  const h = f.hour + longitude(g, onSouthTrack(f)) / 15;
  const m = h % 24;
  return m < 0 ? m + 24 : m;
}

/**
 * A winter night between about half past six in the evening and half past six in the
 * morning, local time. The title card is always by day.
 */
export function isNight(J, f) {
  if (!f.state || landmark(J, f)?.type === 'end') return false;
  const h = localHour(f);
  return h >= 18.5 || h < 6.5;
}

// MARK: Drawing

/** Swift's `truncatingRemainder`, brought into 0..<period. */
export function wrap(x, period) {
  const m = x % period;
  return m < 0 ? m + period : m;
}

export function draw(J, px, f) {
  const onField = field(J, f);
  const over = overField(J, f);
  const launch = launching(f);
  const isDown = down(J, f);
  const stop = landmark(J, f);
  const finish = stop?.type === 'end';
  // The finish is the next sunrise; everywhere else the sky is the weather's.
  const s = finish ? sunrise : palette(f.weather);
  const low = loitering(J, f) && over === null;
  const hz = low ? lowHorizon : aloftHorizon;
  const t = f.t;
  const night = isNight(J, f);
  const region = groundRegion(J, f);
  const still = s.still || isDown || finish || onField !== null;
  const heat = !cold(J, f);
  // How fast the ground slides by, row by row.
  const v = (r) => {
    if (still || launch) return 0;
    if (f.moving) return 4 * f.weather.speed * (heat ? 1 : 0.3) + 1;
    return 0.5 + 0.25 * r;
  };

  px.sky(s.top, s.bot, hz);
  if (s.sun !== null && !night) sun(px, hex(s.sun), s.bigSun);
  const drift = f.moving && !still ? 1.6 : 0.4;
  if (s.clouds > 0) px.clouds(s.clouds * 2, hex(s.cloud), t, drift);
  if (s.cirrus) cirrus(px, t, drift);

  const fieldID = onField ?? over ?? (launch ? J.stops[0]?.id ?? null : null);
  const deck = f.moving && fieldID === null && !isDown && stop === null ? s.deck : null;
  if (fieldID !== null) {
    fieldGround(px, fieldID, aloftHorizon);
  } else if (finish) {
    homeGround(px, t);
  } else if (deck !== null) {
    px.rect(0, hz, px.w, px.h - hz, hex(deck));
    dashes(px, hz, 8, s.bot, v, t, false);
  } else {
    if (region === 'himalaya') range(px, hz, t * v(0) / 4);
    far(px, region, hz, t * v(0) / 6);
    let [fill, dash] = ground(region, f.state ? f.date[1] : 0);
    if (s.dust) {
      fill = mixed(fill, 0xC9A36B);
      dash = mixed(dash, 0xC9A36B);
    }
    px.rect(0, hz, px.w, px.h - hz, hex(fill));
    dashes(px, hz, low ? 9 : 8, dash, v, t, s.shimmer);
    if (stop !== null) drawLandmark(px, stop.id, f, hz, t);
  }
  if (fieldID !== null) props(px, fieldID, t, onField === null);
  if (isDown && f.state) {
    wreck(J, px, f, f.state, t);
  } else {
    sprite(J, px, f, position(J, f, s, hz), false);
  }

  // The weather's own layers, in 1849's order. The finish is a fair morning.
  if (!finish) {
    if (f.weather.sky === 'storm') px.rain(t);
    if (f.weather.sky === 'snow') px.snow(t);
    if (s.dust) dust(px, t, f.moving);
    if (f.weather.sky === 'fog') px.fog();
    if (f.weather.sky === 'storm') px.lightning(t);
  }

  if (night) {
    px.rect(0, 0, px.w, px.h, opacity(hex(0x070B1C), 0.6));
    if (s.sun !== null) stars(px, hz);
    if (!isDown) {
      // The burner's light on the cone and the capsule's lit portholes.
      sprite(J, px, f, position(J, f, s, hz), true);
    }
    if (fieldID !== null) hangarLight(px, fieldID);
  }
}

/** The sky she comes down in at the finish: the next sunrise, gold low in the east. */
export const sunrise = P(0x2D5F9A, 0xF6C98B, { clouds: 1, cloud: 0xF6E3C0 });

/**
 * The country under her: the region's, except at the landfall, where the coast is drawn
 * over the ocean she is leaving.
 */
export function groundRegion(J, f) {
  if (!f.state) return 'sahara';
  const stop = landmark(J, f);
  if (stop && stop.id === 'landfall') return f.hooks.balloon.offLandfall;
  return f.region?.id ?? 'sahara';
}

/** 1849's sun, high on the right; in a hot sun one pixel bigger all round. */
export function sun(px, c, big) {
  if (big) {
    px.rect(126, 7, 9, 13, c);
    px.rect(124, 9, 13, 9, c);
    px.rect(125, 8, 11, 11, c);
  } else {
    px.sun(125, 8, c);
  }
}

/** The jet's cirrus: three long streaks, three times as fast as the clouds would go. */
export function cirrus(px, t, drift) {
  for (let i = 0; i < 3; i++) {
    const x = Math.floor(wrap(i * 67 + 10 - t * 3 * (2 + i) * drift, 200) - 20);
    px.rect(x, 6 + 7 * i, 20, 1, opacity(hex(0xF4F7FA), 0.6));
  }
}

export function stars(px, hz) {
  for (let i = 0; i < 18; i++) {
    px.rect((i * 37 + 11) % 160, (i * 23 + 5) % Math.trunc(hz - 4), 1, 1,
      opacity(white, i % 3 === 0 ? 0.9 : 0.55));
  }
  px.moon(124, 6, hex(0xF2EED8), hex(0x141B33));
}

export function mixed(a, b) {
  const ch = (s) => jsRounded((((a >> s) & 255) + ((b >> s) & 255)) / 2);
  return (ch(16) << 16) | (ch(8) << 8) | ch(0);
}

// MARK: Country

/**
 * The region's ground and the colour of its texture. The Great Plains lie under snow from
 * December to February.
 */
export function ground(id, month) {
  switch (id) {
    case 'sahara': return [0xC99A5B, 0xE0B877];
    case 'arabia': return [0xD2A86A, 0xEBC98F];
    case 'oman': return [0x1D4E7A, 0x7FB8DE];
    case 'thar': return [0xBF915E, 0xDDB585];
    case 'india': return [0x7A8B4E, 0xA3A86B];
    case 'himalaya': return [0x5E6B5A, 0x8C9A86];
    case 'eastchina': return [0x22557F, 0x8CC0E0];
    case 'npacific': return [0x1F3346, 0xE8EEF3];
    case 'nepacific': return [0x24394E, 0x8AA0B4];
    case 'southtrack': return [0x1A5A8A, 0x9FD4EE];
    case 'subtropic': return [0x1B6A94, 0xA8E0F2];
    case 'southwest': return [0xB5754A, 0xD9A06F];
    case 'plains': return month === 11 || month <= 1 ? [0xDDE4EA, 0xB8C3CC] : [0x9C9A6A, 0xC2BE8E];
    case 'atlantic': return [0x1D4E7A, 0xE9F4FB];
    case 'azores': return [0x1A4A78, 0x7FB8DE];
    case 'morocco': return [0xC49A62, 0xE2BD86];
    default: return [0xC99A5B, 0xE0B877];
  }
}

/**
 * Texture under her, one pixel tall: aloft every row at the same pace, there being no
 * parallax from that height; loitering, the nearer rows faster.
 */
export function dashes(px, hz, rows, color, v, t, shimmer) {
  const c = hex(color);
  const flick = Math.floor(t / 0.5) % 2 === 0;
  for (let r = 0; r < rows; r++) {
    const y = hz + 2 + 4 * r;
    if (!(y < px.h)) break;
    const nudge = shimmer && r % 2 === 1 && flick ? 1.0 : 0;
    for (let i = 0; i < 7; i++) {
      const x = Math.floor(wrap(i * 29 + r * 17 - t * v(r), px.w)) + nudge;
      px.rect(x, y, 2 + (i + r) % 3, 1, c);
    }
  }
}

/** The Himalaya's band of peaks on the horizon, snow-capped, wrapping round. */
export const peakTable = [
  { c: 8, w: 6, h: 5 }, { c: 26, w: 8, h: 8 }, { c: 41, w: 5, h: 4 }, { c: 59, w: 9, h: 9 }, { c: 77, w: 6, h: 6 },
  { c: 92, w: 7, h: 7 }, { c: 110, w: 8, h: 9 }, { c: 128, w: 5, h: 3 }, { c: 146, w: 7, h: 6 },
];

/**
 * A band of peaks standing on the horizon, a third of each snow, wrapping round as she
 * flies: the Himalaya's by default, or another range's table and colours.
 */
export function range(px, hz, scroll, { big = 1, table = peakTable, rock = 0x6E7480, snow = 0xEEF3F7, wraps = true } = {}) {
  const shift = wrap(scroll, 160);
  for (const p of table) {
    const h = rounded(p.h * big), w = rounded(p.w * big);
    for (const copy of wraps ? [0.0, 160] : [0.0]) {
      const c = p.c - shift + copy;
      for (let j = 0; j < Math.trunc(h); j++) {
        const half = Math.floor(w * (j + 1) / h);
        const isSnow = j < Math.ceil(h / 3);
        px.rect(c - half, hz - h + j, 2 * half + 1, 1, hex(isSnow ? snow : rock));
      }
    }
  }
}

/** The High Atlas, south of Marrakech: lower than the Himalaya, and browner. */
export const atlasTable = [
  { c: 6, w: 9, h: 6 }, { c: 22, w: 10, h: 9 }, { c: 38, w: 7, h: 5 }, { c: 55, w: 11, h: 8 }, { c: 74, w: 8, h: 6 },
  { c: 90, w: 12, h: 10 }, { c: 110, w: 8, h: 5 }, { c: 126, w: 10, h: 8 }, { c: 146, w: 9, h: 6 },
];

/** What stands on the far horizon of some of the country: dunes, the Atlas, mesas. */
export function far(px, id, hz, scroll) {
  switch (id) {
    case 'sahara':
      px.hills(0, 160, hz, hex(0xB4884E), (x) => {
        const u = x + scroll;
        return Math.max(0, 2 + 1.5 * Math.sin(u * 0.09) + Math.sin(u * 0.23));
      });
      break;
    case 'southwest':
      // Mesas, flat-topped, the colour of rust.
      for (const [x, w, h] of [[14.0, 18.0, 5.0], [70, 26, 7], [122, 14, 4]]) {
        const left = wrap(x - scroll, 180) - 10;
        px.rect(Math.floor(left), hz - h, w, h, hex(0x8E5634));
        px.rect(Math.floor(left + 2), hz - h - 1, w - 4, 1, hex(0x8E5634));
      }
      break;
    case 'morocco': case 'thar':
      if (id === 'morocco') {
        // The Atlas, white along the top, far off to the south.
        range(px, hz, scroll, { big: 0.7, table: atlasTable, rock: 0x8A7A68 });
      } else {
        // Scrub, in tufts.
        for (let i = 0; i < 9; i++) {
          const x = Math.floor(wrap(i * 19 - scroll, 160));
          px.rect(x, hz - 1, 2, 1, hex(0x8C8A55));
        }
      }
      break;
    case 'india':
      // Fields in patches beyond the haze.
      for (let i = 0; i < 6; i++) {
        const x = Math.floor(wrap(i * 31 - scroll, 170)) - 5;
        px.rect(x, hz - 1, 12, 1, hex(0x5E7040));
      }
      break;
    default:
      break;
  }
}

// MARK: Stops

export function drawLandmark(px, id, f, hz, t) {
  const w = px.w;
  switch (id) {
    case 'atlas':
      // Snowfields close below and the white range across the horizon, mule tracks
      // running along the slopes.
      range(px, hz, 0, { big: 1.4, table: atlasTable, rock: 0x8A7A68 });
      px.rect(0, hz, w, 14, hex(0xE6EDF2));
      for (let i = 0; i < 14; i++) {
        const x = i * 11 + (i % 3) * 3;
        px.rect(x, hz + 5 + (i % 3) * 3, 3, 1, hex(0x8A7A68));
      }
      break;
    case 'him': {
      // The whole range, a white wall standing up out of the haze, and Everest with snow
      // streaming east off its summit.
      range(px, hz, 0, { big: 1.8 });
      const ex = 96.0;
      for (let j = 0; j < 20; j++) {
        const half = Math.floor((j + 1) * 10 / 20);
        px.rect(ex - half, hz - 20 + j, 2 * half + 1, 1, hex(j < 7 ? 0xF4F7FA : 0x6E7480));
      }
      for (let k = 0; k < 4; k++) {
        const p = Math.floor(wrap(t * 6 + k * 5, 20));
        px.rect(ex + 1 + p, hz - 21 + (k % 2), 3, 1, opacity(white, Math.max(0.2, 0.8 - p / 25)));
      }
      break;
    }
    case 'pacific':
      // The coast of Japan falling behind on the left, a white cone among its hills;
      // ahead, nothing but sea.
      px.polygon([{ x: 0, y: hz }, { x: 0, y: hz - 7 }, { x: 12, y: hz - 9 }, { x: 26, y: hz - 4 }, { x: 40, y: hz },
        { x: 34, y: hz + 6 }, { x: 0, y: hz + 10 }], hex(0x4F6B3A));
      px.polygon([{ x: 8, y: hz - 8 }, { x: 16, y: hz - 18 }, { x: 24, y: hz - 7 }], hex(0x6E7480));
      px.polygon([{ x: 13, y: hz - 14 }, { x: 16, y: hz - 18 }, { x: 19, y: hz - 14 }], hex(0xF4F7FA));
      px.rect(0, hz + 10, 30, 1, hex(0xE8EEF3));
      break;
    case 'dateline':
      // The line nobody can see, drawn anyway, running north across the sea.
      for (let k = 0; k < 9; k++) {
        const y = hz + 1 + k * 4;
        if (!(y < px.h)) break;
        const x = 104 + k * 1.5;
        px.rect(Math.floor(x), y, 1, 2, opacity(hex(0xF2D16B), 0.85));
      }
      px.rect(103, hz - 1, 3, 1, opacity(hex(0xF2D16B), 0.6));
      break;
    case 'landfall': {
      const southTrack = f.state ? onSouthTrack(f) : false;
      // The coast ahead: a white line of surf, then the dark of the redwoods, or San
      // Diego's brown hills and the desert.
      const land = southTrack ? 0x9A7A52 : 0x2E4A2E;
      px.polygon([{ x: 96, y: hz }, { x: w, y: hz }, { x: w, y: px.h }, { x: 70, y: px.h }], hex(land));
      px.line({ x: 96, y: hz }, { x: 70, y: px.h }, hex(0xF4F7FA));
      px.line({ x: 98, y: hz }, { x: 73, y: px.h }, opacity(hex(0xF4F7FA), 0.6));
      if (southTrack) {
        px.hills(100, 160, hz, hex(0x8A6A48), (x) => Math.max(0, 4 + 3 * Math.sin(x * 0.13)));
        for (const [x, y] of [[110.0, 58.0], [128, 64], [146, 55], [136, 72]]) px.rect(x, y, 3, 1, hex(0xC9A36B));
      } else {
        for (let i = 0; i < 12; i++) {
          const x = 100 + i * 5, top = hz - 3 - (i * 7) % 4;
          px.rect(x, top, 2, hz - top + 1, hex(0x1E3A24));
          px.rect(x - 1, top + 2, 4, 2, hex(0x1E3A24));
        }
      }
      break;
    }
    case 'azores': {
      // A green volcanic island on the horizon, its white town at the shore, a smaller one
      // beyond, and the fishing boat waiting out from Ponta Delgada.
      px.polygon([{ x: 86, y: hz }, { x: 100, y: hz - 9 }, { x: 108, y: hz - 11 }, { x: 118, y: hz - 6 }, { x: 132, y: hz }],
        hex(0x4F7A3A));
      px.polygon([{ x: 140, y: hz }, { x: 147, y: hz - 4 }, { x: 156, y: hz }], hex(0x5E8A48));
      for (const x of [94.0, 98, 102, 121, 125]) px.rect(x, hz - 2, 2, 2, hex(0xF4F1E6));
      const bob = jsRounded(Math.sin(t * 2));
      px.rect(70, 66 + bob, 14, 3, hex(0x2E6FB0));
      px.rect(72, 69 + bob, 10, 1, hex(0x1A2533));
      px.rect(78, 62 + bob, 3, 4, hex(0xECE4CF));
      px.rect(75, 59 + bob, 1, 7, hex(0x4A2E1A));
      break;
    }
    default:
      break;
  }
}

// MARK: Fields

/** A field seen from the ground: its own fill, and what each place has beyond it. */
export function fieldGround(px, id, hz) {
  let fill;
  switch (id) {
    case 'mar': fill = 0xC99A5B; break;
    case 'lux': fill = 0xC9A36B; break;
    case 'jod': fill = 0xB5754A; break;
    case 'saga': fill = 0x7C8F5A; break;
    case 'abq': fill = 0xA88A5E; break;
    case 'kh': fill = 0xD9C79A; break;
    default: fill = 0xC99A5B; break;
  }
  // Beyond the field, on the left.
  switch (id) {
    case 'mar':
      // The Atlas, white to the south.
      range(px, hz, 0, { table: [{ c: 8, w: 8, h: 6 }, { c: 22, w: 10, h: 9 }, { c: 37, w: 8, h: 6 }], rock: 0x8A7A68, wraps: false });
      break;
    case 'lux':
      // Temple columns across the river.
      px.rect(6, hz - 3, 34, 3, hex(0xC9A36B));
      for (let i = 0; i < 6; i++) px.rect(9 + i * 5, hz - 9, 2, 6, hex(0xD9C79A));
      px.rect(7, hz - 10, 32, 1, hex(0xD9C79A));
      break;
    case 'jod':
      // The great fort on its rock above the city.
      px.polygon([{ x: 0, y: hz }, { x: 8, y: hz - 6 }, { x: 36, y: hz - 7 }, { x: 46, y: hz }], hex(0x8E5634));
      px.rect(10, hz - 13, 24, 6, hex(0xB5754A));
      for (let i = 0; i < 5; i++) px.rect(11 + i * 5, hz - 15, 3, 2, hex(0xB5754A));
      for (let i = 0; i < 6; i++) px.rect(4 + i * 7, hz - 2, 4, 2, hex(0x6FA3D0));
      break;
    case 'saga':
      // Green hills behind the river.
      px.hills(0, 48, hz, hex(0x4F6B3A), (x) => Math.max(0, 6 + 3 * Math.sin(x * 0.12) + 1.5 * Math.sin(x * 0.31)));
      break;
    case 'abq':
      // The long mountain east of town.
      px.hills(0, 48, hz, hex(0x7A6A7A), (x) => Math.max(0, 10 - Math.abs(x - 20) * 0.35 + Math.sin(x * 0.4)));
      break;
    case 'kh':
      // The memorial's pylon on its dune.
      px.polygon([{ x: 2, y: hz }, { x: 18, y: hz - 6 }, { x: 34, y: hz }], hex(0xC9B98A));
      px.rect(16, hz - 14, 4, 8, hex(0xD5D7D9));
      px.rect(17, hz - 15, 2, 1, hex(0xD5D7D9));
      break;
    default:
      break;
  }
  px.rect(0, hz, px.w, px.h - hz, hex(fill));
  switch (id) {
    case 'lux': px.rect(0, 56, px.w, 3, hex(0x2F6A96)); break;
    case 'saga': px.rect(0, 60, px.w, 2, hex(0x2F6A96)); break;
    case 'kh': px.rect(0, 46, px.w, 3, hex(0x1D4E7A)); break;
    default: break;
  }
}

/**
 * The hangar, the windsock streaming east, the fuel truck and the crowd. Flown over
 * (`flown`), the crowd looks up and waves.
 */
export function props(px, id, t, flown) {
  px.rect(112, 36, 34, 10, hex(0x8A949E));
  px.rect(114, 34, 30, 1, hex(0x6E7480));
  px.rect(112, 35, 34, 1, hex(0x6E7480));
  px.rect(121, 38, 16, 8, hex(0x3A3F48));
  px.rect(128, 38, 1, 8, hex(0x5A6270));
  px.rect(104, 30, 1, 16, hex(0xECE4CF));
  const flutter = Math.floor(t * 4) % 2 === 0 ? 1.0 : 0;
  for (const [i, x] of [105.0, 106, 107, 108, 109].entries()) {
    px.rect(x, 30 + (i === 4 ? flutter : 0), 1, 2, hex(i % 2 === 0 ? 0xF2B632 : 0xD64545));
  }
  px.rect(20, 48, 10, 4, hex(0xECE4CF));
  px.rect(30, 49, 4, 3, hex(0xD64545));
  px.rect(32, 49, 2, 1, hex(0x9FD0EE));
  px.rect(20, 52, 14, 1, hex(0x3A3F48));
  for (const x of [21.0, 26, 31]) px.rect(x, 53, 2, 1, hex(0x1A2533));
  const crowd = [0x2C333D, 0xD64545, 0xF2B632];
  for (let i = 0; i < 12; i++) {
    const x = 70 + Math.floor(30 * i / 11);
    const wave = flown && (Math.floor(t * 3) + i) % 3 === 0 ? 1.0 : 0;
    px.rect(x, 50 - wave, 1, 2 + wave, hex(crowd[i % 3]));
    px.rect(x, 49 - wave, 1, 1, hex(0xEFD6B0));
  }
}

export function hangarLight(px, id) {
  px.rect(122, 39, 14, 7, opacity(hex(0xFFE27A), 0.7));
  px.rect(33, 50, 1, 1, hex(0xFFE27A));
}

/**
 * The finish: a stony plain outside Marrakech, a white village, and its children running
 * out to see what has fallen out of the sky.
 */
export function homeGround(px, t) {
  const hz = aloftHorizon;
  // The sun rising in the east, the bottom of it still behind the hills.
  px.sun(122, hz - 13, hex(0xFFD27A));
  px.hills(0, 160, hz, hex(0x8A7A68), (x) => Math.max(0, 6 + 3 * Math.sin(x * 0.05) + 1.5 * Math.sin(x * 0.17)));
  px.rect(0, hz, px.w, px.h - hz, hex(0xC49A62));
  for (let i = 0; i < 22; i++) {
    px.rect((i * 37 + 5) % 160, hz + 3 + (i * 13) % 30, 2, 1, hex(0x9A7A52));
  }
  for (let i = 0; i < 5; i++) {
    const x = 112 + i * 9, h = 4 + (i * 3) % 3;
    px.rect(x, hz - h + 2, 7, h, hex(0xF4F1E6));
    px.rect(x + 2, hz - h + 4, 2, 2, hex(0x6B4A2B));
  }
  for (let i = 0; i < 6; i++) {
    const run = wrap(t * 6 + i * 7, 30);
    const x = Math.floor(108 - run - i * 2);
    const hop = (Math.floor(t * 6) + i) % 2 === 0 ? 1.0 : 0;
    px.rect(x, 52 - hop, 1, 2, hex([0xD64545, 0x2E6FB0, 0xF2B632][i % 3]));
    px.rect(x, 51 - hop, 1, 1, hex(0x9A6A48));
  }
}

// MARK: The balloon

/**
 * Her top-left corner: aloft or loitering, bobbing with the air and swaying when it is
 * rough, three pixels lower with the crown sagging below 40% lift; standing on a field or
 * at the finish, still.
 */
export function position(J, f, s, hz) {
  if (field(J, f) !== null || landmark(J, f)?.type === 'end') return { x: x0, y: groundY };
  if (launching(f)) return { x: x0, y: 20 };
  const base = loitering(J, f) ? loiterY : aloftY;
  const sag = f.hull < 40 ? 3.0 : 0;
  if (s.still) return { x: x0, y: base + sag };
  const bob = jsRounded(Math.sin(f.t * (1.0 + s.rough * 0.5)) * (0.5 + s.rough * 0.5));
  const sway = s.rough >= 2 ? jsRounded(Math.sin(f.t * 1.3)) : 0;
  return { x: x0 + sway, y: base + bob + sag };
}

/**
 * The flame shows while the burners blast, 0.6 s in every 1.5 flying, less as they wear;
 * loitering they blip, 0.4 s in every 3; on the ground, and with no heat, never.
 */
export function flame(J, f) {
  if (field(J, f) !== null || landmark(J, f)?.type === 'end' || cold(J, f)) return false;
  if (f.moving || launching(f)) {
    const window = f.sails < 60 ? 0.6 * Math.max(0, f.sails) / 60 : 0.6;
    return wrap(f.t, 1.5) < window;
  }
  return wrap(f.t, 3) < 0.4;
}

/**
 * The sprite, or at night only what shows in the dark: the flame and the cone it lights,
 * and the lit portholes.
 */
export function sprite(J, px, f, at, night) {
  const lit = flame(J, f);
  const sag = f.hull < 40;
  let c = { ...colors };
  if (f.sails < 60) c.f = hex(0xFF8A3D);
  if (night) {
    c = { w: hex(0xFFE27A) };
    if (lit) {
      c.o = colors.o;
      c.f = f.sails < 60 ? hex(0xFF8A3D) : colors.f;
      c.k = opacity(hex(0xF7C98A), 0.85);
    }
  }
  px.sprite(balloon, at.x, at.y, c, (_, row, ch) => {
    if (sag && row === 0) return true;
    if (ch === 'o' || ch === 'f') return !lit;
    return false;
  });
  if (f.sails < 40 && !night) {
    const soot = hex(0x3A3F48);
    for (const [row, col] of [[12.0, 7.0], [12, 10], [13, 8]]) px.rect(at.x + col, at.y + row, 1, 1, soot);
  }
}

// MARK: Down

/**
 * Where she came down, as the engine tells it: in the sea, the envelope folded over the
 * capsule like a tent and a freighter coming; on land, in a cloud of dust and torn fabric;
 * or on a field, laid out flat for the trucks.
 */
export function wreck(J, px, f, g, t) {
  const hz = aloftHorizon;
  const cell = hex(0xE6E9EE), shade = hex(0xB9C0CA);
  if (overField(J, f) !== null) {
    px.rect(44, 54, 56, 3, cell);
    px.rect(44, 57, 56, 1, shade);
    px.rect(60, 54, 3, 4, hex(0xD9A441));
    px.rect(64, 54, 3, 4, hex(0xD64545));
    px.rect(36, 52, 9, 5, hex(0xECE4CF));
    return;
  }
  if (f.region?.tags.includes('sea') === true) {
    const bob = jsRounded(Math.sin(t * 2));
    px.rect(54, 56 + bob, 13, 4, hex(0xECE4CF));
    px.polygon([{ x: 48, y: 57 + bob }, { x: 60, y: 47 + bob }, { x: 73, y: 57 + bob }], cell);
    px.polygon([{ x: 60, y: 47 + bob }, { x: 73, y: 57 + bob }, { x: 66, y: 57 + bob }], shade);
    px.rect(52, 52 + bob, 17, 1, hex(0xD64545));
    // The freighter, coming.
    px.rect(118, hz - 3, 22, 3, hex(0x3A3F48));
    px.rect(134, hz - 7, 5, 4, hex(0xECE4CF));
    px.rect(122, hz - 5, 8, 2, hex(0xD64545));
    px.rect(136, hz - 9, 1, 2, hex(0x3A3F48));
  } else {
    px.rect(46, 54, 11, 6, hex(0xECE4CF));
    px.rect(48, 56, 2, 2, hex(0x1A2533));
    px.polygon([{ x: 57, y: 58 }, { x: 66, y: 53 }, { x: 98, y: 55 }, { x: 112, y: 60 }, { x: 70, y: 61 }], cell);
    px.rect(76, 55, 3, 5, hex(0xD9A441));
    px.rect(80, 55, 3, 5, hex(0xD64545));
    for (let k = 0; k < 5; k++) {
      const p = wrap(t * 3 + k * 2, 10);
      px.rect(44 + k * 14, 52 - p / 2, 4, 2, opacity(hex(0xD9B07A), Math.max(0.1, 0.6 - p / 18)));
    }
  }
}

/** Dust haze: forty specks drifting across, a little slower loitering. */
export function dust(px, t, moving) {
  const c = hex(0xD9B07A);
  for (let i = 0; i < 40; i++) {
    const x = Math.floor(wrap(i * 37 - t * (6 + i % 5) * (moving ? 1 : 0.3), 160));
    const y = (i * 53) % 78 + jsRounded(Math.sin(t * 0.7 + i));
    px.rect(x, y, 1, 1, c);
  }
}

// MARK: VoiceOver

/**
 * Where she is, as a sentence says it after a verb. The engine's names are headings ("The
 * Indus & the Thar", "Past the Azores").
 */
export const regionPhrase = {
  sahara: 'over the Sahara', arabia: 'over Arabia', oman: 'over the Gulf of Oman',
  thar: 'over the Indus and the Thar desert', india: 'over northern India',
  himalaya: 'over the Himalaya and China', eastchina: 'over the East China Sea',
  npacific: 'over the North Pacific', nepacific: 'over the northeast Pacific',
  southtrack: 'over the Pacific on the southern track', subtropic: 'over the subtropical Pacific',
  southwest: 'over the American Southwest', plains: 'over the Great Plains',
  atlantic: 'over the North Atlantic', azores: 'over the Atlantic past the Azores',
  morocco: 'over Morocco',
};

export function phrase(region) {
  if (!region) return 'over open country';
  return regionPhrase[region.id] ?? `over ${region.name}`;
}

/** For the chart's caption: on a field, over one, or over the country (`region`, the view's). */
export function whereabouts(J, g, region) {
  const stop = currentStop(J, g);
  const port = portOf(J, stop.id);
  if (port) {
    if (g.atPort) return `on the ground at ${port.name}`;
    if (g.mile === stop.mile && g.stopIndex > 0) return `over the field at ${port.name}`;
  }
  return phrase(region);
}

export function label(J, f) {
  const g = f.state;
  if (!g) return 'A balloon flying east under a clear sky';
  const night = isNight(J, f) ? ' by night' : '';
  const id = field(J, f);
  if (id !== null) {
    return `Balloon standing on the field at ${portOf(J, id)?.name ?? currentStop(J, g).short}${night}, its ground team beside it`;
  }
  if (down(J, f)) {
    const over = overField(J, f);
    if (over !== null) {
      return `The balloon down for good on the field at ${portOf(J, over)?.name ?? currentStop(J, g).short}, its envelope laid out flat`;
    }
    return f.region?.tags.includes('sea') === true
      ? 'The balloon down in the sea, its envelope folded over the capsule, a freighter coming'
      : 'The balloon down on open ground, its envelope torn and spread out in the dust';
  }
  const weather = f.weather.name.toLowerCase();
  if (launching(f)) {
    return `Balloon climbing away from the launch field at Marrakech, the crowd waving. Weather: ${weather}`;
  }
  const burners = f.hooks.balloon.burnersOut ? 'burners dead' : 'burners cold';
  const over = overField(J, f);
  if (over !== null) {
    const name = portOf(J, over)?.name ?? currentStop(J, g).short;
    if (cold(J, f)) return `Balloon drifting over the field at ${name}, ${burners}. Weather: ${weather}`;
    return f.moving ? `Balloon flying over the field at ${name}${night}. Weather: ${weather}`
      : `Balloon low over the field at ${name}${night}, the ground team waiting below. Weather: ${weather}`;
  }
  const stop = landmark(J, f);
  if (stop !== null) {
    switch (stop.id) {
      case 'atlas': return `Balloon crossing the High Atlas, snowfields below${night}. Weather: ${weather}`;
      case 'him': return `Balloon passing the Himalaya, Everest on the horizon${night}. Weather: ${weather}`;
      case 'pacific': return `Balloon leaving the coast of Japan, the open Pacific ahead${night}. Weather: ${weather}`;
      case 'dateline': return `Balloon crossing the date line over the Pacific${night}. Weather: ${weather}`;
      case 'landfall':
        return onSouthTrack(f)
          ? `Balloon crossing the coast at San Diego, brown hills ahead${night}. Weather: ${weather}`
          : `Balloon crossing the coast of California, the redwoods ahead${night}. Weather: ${weather}`;
      case 'azores': return `Balloon over the Azores, a fishing boat waiting below${night}. Weather: ${weather}`;
      case 'finish': return 'The balloon down on a stony plain outside Marrakech, children running out from a village';
      default: return `Balloon over ${stop.name}${night}. Weather: ${weather}`;
    }
  }
  const where = phrase(f.region);
  if (cold(J, f)) return `Balloon drifting ${where}${night}, ${burners}, sinking. Weather: ${weather}`;
  return f.moving ? `Balloon flying ${where}${night}. Weather: ${weather}`
    : `Balloon loitering low ${where}${night}, the burners blipping. Weather: ${weather}`;
}
