// To the Klondike's scene (AroundTheHorn/Journeys/KlondikeScene.swift; docs/journeys/
// klondike.md §4, §9, §16): a coastal steamer on the Inside Passage, a party hauling a sled
// over the pass, and a home-built boat on the lakes and the Yukon, under ten skies, over
// fourteen kinds of country, with every stop drawn as itself. Towns come up on the right as
// you near them and slide away behind; the sled tarp, the outfit, the sail and the hull show
// their wear.
//
// Every function takes the journey's tables `J` where the app's reads `KlondikeSkin.journey`,
// and the frame `f` from drawing.js `sceneFrame`: what the app asks of the engine beyond the
// state (`Klondike.legName`, `hasBoat`, `givenOut`) is the frame's `hooks.klondike`, the
// state's region is the frame's `region`, its date the frame's `date` and the town the
// engine finds for the way taken (`Journey.port(_:at:)`) the frame's `port`, the bridge's
// answers.

import { PixelCanvas, hex, opacity, rgb, white, jsRounded } from '../pixels.js';
import { boatKey, raft, onWhitePass, iceOut, dateOf } from './klondike-skin.js';

export const horizon = 46.0;

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

const { mod, mix } = PixelCanvas;
const { sin, cos, abs, min, max, floor, trunc } = Math;

// MARK: Sky

/**
 * §9's palettes, by the kind of sky: the sky's two ends, the water, the snow, and the dashes
 * on either; the sun, how many clouds and their colour, how rough, and how far the far
 * mountains fade into the sky.
 */
function P(top, bot, water, snow, accent, more = {}) {
  return { top, bot, water, snow, accent, sun: null, clouds: 0, cloud: 0xF4F7FA, rough: 1.0, haze: 0.0, ...more };
}

export function palette(w) {
  switch (w.sky) {
    case 'clear': return P(0x2F63A8, 0xBCDDF0, 0x23506E, 0xE9EFF4, 0xFFFFFF, { sun: 0xFFF1B8 });
    case 'breeze': return P(0x3A6CA6, 0xA9CFE6, 0x24557A, 0xDCE5EC, 0xCFE3F0, { sun: 0xFFE58A, clouds: 1 });
    case 'rain': return P(0x3F4A57, 0x7E8A97, 0x22384C, 0x8E9488, 0x93A5B6, { clouds: 3, cloud: 0x6B7584, haze: 0.3 });
    case 'fog': return P(0x8E979F, 0xC7CDD2, 0x5E6E7B, 0xC9CFD4, 0xB7C0C8, { haze: 0.65 });
    case 'snow': return P(0x5A6573, 0xA9B5C1, 0x2B3D50, 0xE4EAF0, 0xF4F7FA, { clouds: 3, cloud: 0x8E99A5, haze: 0.35 });
    case 'dust': return P(0x6F7E8C, 0xB9C4C9, 0x34505E, 0x9DA391, 0xC4CBC0, { clouds: 2, cloud: 0x8C969F, haze: 0.2 });
    case 'gale': return P(0x354251, 0x6F7E8E, 0x1F3346, 0xC8D2DC, 0xE6EDF3, { clouds: 3, cloud: 0x56626F, rough: 2, haze: 0.15 });
    case 'storm': return P(0x1B2028, 0x4A5360, 0x141F2B, 0xB5C0CB, 0xD8E0E8, { clouds: 3, cloud: 0x2C333D, rough: 3, haze: 0.7 });
    case 'still': return P(0x6C8FB0, 0xC9DDEA, 0x3D6378, 0xE0E8EE, 0xF2F7FA);
    case 'heat': return P(0xD98A3D, 0xF4D88C, 0x3C6A70, 0xD8D2B8, 0xA9CACC, { sun: 0xFFF4C2, haze: 0.15 });
    default: return P(0x2F63A8, 0xBCDDF0, 0x23506E, 0xE9EFF4, 0xFFFFFF, { sun: 0xFFF1B8 });
  }
}

// MARK: Sprites (§4)

/** Rows cut or padded with spaces to `width`. */
export function grid(rows, width) {
  return rows.map((r) => {
    const a = [...r];
    return a.length >= width ? a.slice(0, width).join('') : r + ' '.repeat(width - a.length);
  });
}

export const steamer = grid([
  '          oo              ',
  '         ooo     m        ',
  '          o      m        ',
  '         tt      m        ',
  '         ff      m        ',
  '         ff      m        ',
  '    wwwwwffwwwwwwwwww     ',
  '    wpwpwwwwpwpwpwpww     ',
  '  wwwwwwwwwwwwwwwwwwwwww  ',
  'kkkkkkkkkkkkkkkkkkkkkkkkkk',
  ' kkkkkkkkkkkkkkkkkkkkkkkk ',
  ' yyyyyyyyyyyyyyyyyyyyyyyy ',
  '  kkkkkkkkkkkkkkkkkkkkkk  ',
], 26);

export const steamerColors = {
  k: hex(0x23262B), y: hex(0x9E3B2F), w: hex(0xE6E0D0), p: hex(0xF2C14E),
  f: hex(0xA8452F), t: hex(0x23262B), m: hex(0x6B4A2B), o: hex(0x8F959C),
};

export const party = grid([
  '                 hh       hh   ',
  '                hhff     hhff  ',
  '  llllllll      kpp      kdd   ',
  ' llllrlllll     kppp     kddd  ',
  ' llllllllll  rr kppppr rrkdddd ',
  ' llrllllrlll r   pp       dd   ',
  'ssssssssssssr    pp       dd   ',
  'nnnnnnnnnnnn     p p      d d  ',
  '                b   b    b   b ',
], 31);

/** Rows 7 and 8 the other way, every other step. */
export const stride7 = grid(['nnnnnnnnnnnn      pp       dd   ', '                 b b       b b  '], 31);

export const partyColors = {
  h: hex(0x4A3222), f: hex(0xE6C29A), p: hex(0xB5432F), d: hex(0x3B3E4A),
  k: hex(0x6E5B3E), l: hex(0xCDBE94), r: hex(0x7A5A3A), s: hex(0x8B6A42),
  n: hex(0x2E3036), b: hex(0x2A2522),
};

/** The columns of the party sprite that are the sled and its load (0..<13); the rest are people. */
export const sledColumns = { lower: 0, upper: 13 };

export const boat = grid([
  '            rr            ',
  '            m             ',
  '       mmmmmmmmmmm        ',
  '       sssssssssss        ',
  '       sssssssssss        ',
  '       sssssssssss        ',
  '       sssssssssss        ',
  '       sssssssssss        ',
  '       sssssssssss        ',
  '  hh        m       hh    ',
  ' ohff  gggggmgggg   ff    ',
  'o pp   gggggmggggg  dd    ',
  'owwwwwwwwwwwwwwwwwwwwwwwww',
  ' wbbbbbbbbbbbbbbbbbbbbbbw ',
  '  wwwwwwwwwwwwwwwwwwwwww  ',
], 26);

/** A raft: a flat log deck and no pitched seam. */
export const raftBoat = [...boat.slice(0, 12), ...grid([
  'owwwwwwwwwwwwwwwwwwwwwwwww',
  'owwwwwwwwwwwwwwwwwwwwwwww ',
  '                          ',
], 26)];

export const boatColors = {
  s: hex(0xE8DFC4), m: hex(0x6B4A2B), r: hex(0xD64545), g: hex(0xB8A77A),
  o: hex(0x6B4A2B), p: hex(0xB5432F), d: hex(0x3B3E4A), f: hex(0xE6C29A),
  h: hex(0x4A3222), w: hex(0x9C7A4E), b: hex(0x3A2A1A),
};

/** 1849's torn sails: a pixel goes where `((col*7 + row*13) % 37) < (60 − meter)/2.2`. */
export function torn(col, row, meter) {
  return meter < 60 && (col * 7 + row * 13) % 37 < (60 - meter) / 2.2;
}

// MARK: Drawing

/** The stop the state is at or past, by its index. */
const stopId = (J, g) => (g ? J.stops[g.stopIndex]?.id : undefined);

/** Everything one frame needs, worked out once. */
function makeScene(J, px, f) {
  const g = f.state;
  const reg = f.region ?? J.regions.find((r) => r.id === 'chilkootSummit');
  let leg = 'foot';
  if (g) {
    const l = f.hooks?.klondike?.leg;
    leg = l === 'steamer' ? 'steamer' : l === 'boat' ? 'boat' : 'foot';
  }
  const mile = g?.mile ?? J.stops[5].mile - 6;
  const p = palette(f.weather);
  const date = g ? (f.date ?? dateOf(J, g)) : null;
  const s = {
    J, px, f, g, p, leg, region: reg.id, t: f.t, mile,
    white: g ? onWhitePass(g) : false,
    hz: horizon,
    date,
    /** The month the scene is in: March with no voyage. */
    month: date ? date[1] : 2,
    /**
     * Where a thing standing at `stopMile` is drawn from: 0 at the stop, to the right ahead
     * of it and to the left behind, a day's travel being about 100 pixels.
     */
    dx(stopMile) {
      const perDay = leg === 'steamer' ? 2200 : leg === 'foot' ? 9 : 300;
      return jsRounded((stopMile - mile) * 100 / perDay);
    },
    c: (n) => hex(n),
    /** A far colour faded toward the sky's foot by the weather. */
    far: (n, more = 0) => mix(n, p.bot, min(0.9, p.haze + more)),
    rect: (x, y, w, h, color) => px.rect(x, y, w, h, color),
  };
  return s;
}

/** Whether the ice on Lake Bennett has gone out, on the scene's date. */
const iceGone = (s) => iceOut(s.g, s.date);

/** Givens from the engine's hooks. */
const givenOutOf = (s) => (s.g ? s.f.hooks?.klondike?.givenOut ?? false : false);
const hasBoatOf = (s) => (s.g ? s.f.hooks?.klondike?.hasBoat ?? false : false);

export function draw(J, px, f) {
  const s = makeScene(J, px, f);
  px.sky(s.p.top, s.p.bot, s.hz);
  if (s.p.sun !== null) px.sun(123, 8, hex(s.p.sun));
  px.clouds(s.p.clouds * 2, hex(s.p.cloud), f.t, f.moving ? 1.6 : 0.4);
  switch (s.leg) {
    case 'steamer': coast(s); break;
    case 'foot': mountains(s); break;
    default: riverBanks(s); break;
  }
  behind(s);
  switch (s.leg) {
    case 'steamer': sea(s); break;
    case 'foot': snowfield(s); break;
    default: river(s); break;
  }
  front(s);
  switch (s.leg) {
    case 'steamer': drawSteamer(s); break;
    case 'foot': drawParty(s); break;
    default: drawBoat(s); break;
  }
  air(s);
}

// MARK: The coast, from the steamer

function coast(s) {
  const px = s.px, hz = s.hz;
  const ox = s.mile * 0.01 + (s.f.moving ? s.t * 0.8 : 0);
  const scale = s.region === 'queenCharlotte' ? 0.45 : s.region === 'alaskaCoast' ? 1.5 : 1;
  const range = s.far(0x3B4A52), cap = s.far(0xE8EEF2);
  const start = s.region === 'queenCharlotte' ? 90 : 0;
  for (let i = start; i < 160; i++) {
    const x = i + ox;
    const h = jsRounded((6 + 4 * sin(x * 0.07) + 3 * sin(x * 0.19)) * scale);
    if (!(h > 0)) continue;
    px.rect(i, hz - h, 1, h, range);
    if (h > 8) px.rect(i, hz - h, 1, 2, cap);
    // Alaska's glaciers come down to the water.
    if (s.region === 'alaskaCoast' && mod(x, 47) < 3 && h > 10) {
      px.rect(i, hz - h + 2, 1, h - 3, s.far(0xD8E6EE));
    }
  }
  // Forested islands in the Passage and down the British Columbia coast.
  if (s.region === 'insidePassage' || s.region === 'bcCoast') {
    const isle = s.far(0x2C3F33, 0.1);
    for (let k = 0; k < 3; k++) {
      let x0 = mod(k * 67 + 20 - ox * 3, 220);
      if (x0 < 0) x0 += 220;
      x0 -= 30;
      const lo = trunc(max(0, x0)), hi = trunc(min(160, x0 + 34));
      if (!(lo < hi)) continue;
      px.hills(lo, hi, hz, isle, (x) => max(0, 5 - abs(x - x0 - 17) * 0.3));
    }
  }
}

function sea(s) {
  const px = s.px, hz = s.hz;
  px.rect(0, hz, px.w, px.h - hz, s.c(s.p.water));
  const spd = s.f.moving ? 14 * s.f.weather.speed + 2 : 1.5;
  waves(s, spd, s.p.rough + (s.region === 'queenCharlotte' ? 1 : 0));
  if (s.f.weather.sky === 'still') floes(s, spd);
}

/** 1849's wave dashes, eight rows of them. */
function waves(s, spd, rough, y0 = null) {
  const px = s.px, t = s.t;
  const wave = s.c(s.p.accent);
  for (let row = 0; row < 8; row++) {
    const y = (y0 ?? s.hz + 2) + row * 4;
    const rs = spd * (0.4 + row * 0.18) + 1;
    for (let i = 0; i < 7; i++) {
      let x = mod(i * 29 + row * 17 - t * rs, px.w);
      if (x < 0) x += px.w;
      const len = 2 + (i + row) % 3 + rough;
      const jitter = rough > 1 ? jsRounded(sin(t * 3 + (i + row))) : 0;
      px.rect(floor(x), y + jitter, len, 1, wave);
    }
  }
}

/** Cakes of ice going by with the water. */
function floes(s, speed) {
  for (let i = 0; i < 6; i++) {
    const rs = speed * (0.4 + i * 0.25) + 1;
    let x = mod(i * 31 + 7 - s.t * rs, 172);
    if (x < 0) x += 172;
    s.rect(floor(x - 6), s.hz + 4 + i * 5, 6, 2, s.c(0xF2F7FA));
  }
}

// MARK: The mountains, from the trail

/** Lindeman, Log Cabin, or camped at Bennett: the lakes beyond the trail. */
function atTheLakes(s) {
  return s.region === 'lindeman' || s.region === 'logCabin'
    || (stopId(s.J, s.g) === 'bennett' && s.mile >= s.J.stops[7].mile);
}

function mountains(s) {
  const px = s.px, hz = s.hz;
  const ox = s.mile * 0.6 + (s.f.moving ? s.t * 0.4 : 0);
  const rock = s.far(0x4E5C68), snowcap = s.far(0xF2F5F8);
  const summit = s.region === 'chilkootSummit' || s.region === 'whitePassSummit';
  const lakes = atTheLakes(s);
  for (let i = 0; i < 160; i++) {
    const x = i + ox;
    let h;
    if (s.region === 'chilkootSummit') {
      h = 20 + 9 * abs(sin(x * 0.08));
    } else if (s.region === 'whitePassSummit') {
      h = 15 + 6 * abs(sin(x * 0.09)) + 3 * sin(x * 0.23);
    } else {
      h = 14 + 7 * sin(x * 0.05) + 4 * sin(x * 0.17);
      if (s.white) h *= 0.85;
      if (lakes) h *= 0.7;
    }
    h = jsRounded(h);
    px.rect(i, hz - h, 1, h, rock);
    px.rect(i, hz - h, 1, summit ? 6 : 4, snowcap);
  }
  if (s.region === 'taiya' || s.region === 'skagwayValley' || s.region === 'lindeman') {
    spruceLine(s, s.region === 'lindeman' ? 5 : 7, 3, s.far(0x1F3A2A, 0.05), true);
  } else if (s.region === 'logCabin') {
    spruceLine(s, 3, 5, s.far(0x2A4430, 0.05), true);
  }
  if (lakes) frozenOrOpenLake(s);
}

/** A line of spruce along the horizon, scrolling a little with the ground. */
function spruceLine(s, tall, every, color, snowy, base = null, speed = 0) {
  const px = s.px, by = base ?? s.hz;
  const off = s.mile * (s.leg === 'foot' ? 1.5 : 0.1) + s.t * speed;
  // Snow sits on the trees from the first fall to break-up.
  const m = s.g ? s.month : 2;
  const snowOn = snowy && !(m >= 6 && m <= 8);
  const frost = opacity(s.c(0xE8EEF2), 0.8);
  let i = -every;
  while (i < 164) {
    const k = trunc(mod(i + off, 997));
    const seed = abs(trunc(k / max(1, every)));
    const h = max(2, tall - 2 + seed % 5);
    const x = i - mod(off, every);
    tree(px, x, by, h, color);
    if (snowOn) px.rect(x, by - h, 1, 1, frost);
    i += every;
  }
}

/** A spruce: a narrow spire, wider toward its foot. */
export function tree(px, x, base, h, color) {
  const n = max(0, trunc(h));
  for (let r = 0; r < n; r++) {
    const half = trunc(r / 3);
    px.rect(x - half, base - h + r, 1 + 2 * half, 1, color);
  }
}

/** The lakes beyond the trail: frozen white, or open water once summer comes. */
function frozenOrOpenLake(s) {
  let frozen;
  if (s.g) {
    frozen = stopId(s.J, s.g) === 'bennett' && s.mile === s.J.stops[7].mile
      ? !iceGone(s) : !(s.month >= 5 && s.month <= 9);
  } else {
    frozen = true;
  }
  const y = s.hz;
  if (frozen) {
    s.rect(0, y, 160, 5, mix(0xE8F0F5, s.p.snow, 0.3));
    for (const i of stride(3, 160, 11, false)) s.rect(i, y + 2, 4, 1, s.c(0xC9D8E2));
  } else {
    s.rect(0, y, 160, 5, s.c(s.p.water));
    for (const i of stride(5, 160, 13, false)) {
      s.rect(mod(i - s.t * 2, 160), y + 1 + i % 3, 3, 1, s.c(s.p.accent));
    }
  }
  s.rect(0, y + 5, 160, 1, opacity(s.c(0x6E7A82), 0.5));
}

function snowfield(s) {
  const px = s.px, t = s.t;
  const lakes = atTheLakes(s);
  const top = lakes ? s.hz + 6 : s.hz;
  px.rect(0, top, px.w, px.h - top, s.c(s.p.snow));
  const rough = s.p.rough;
  const moving = s.f.moving;
  const spd = moving ? (14 * s.f.weather.speed + 2) * 0.25 : 0;
  const dash = s.c(s.p.accent);
  for (let row = 0; row < 8; row++) {
    const y = s.hz + 2 + row * 4;
    if (!(y > top)) continue;
    const rs = spd * (0.4 + row * 0.18) + (moving ? 0.25 : 0);
    for (let i = 0; i < 7; i++) {
      let x = mod(i * 29 + row * 17 - t * rs, px.w);
      if (x < 0) x += px.w;
      const jitter = rough > 1 ? jsRounded(sin(t * 3 + (i + row))) : 0;
      px.rect(floor(x), y + jitter, 2 + (i + row) % 3, 1, dash);
    }
  }
  // The Skagway valley's wagon road.
  if (s.region === 'skagwayValley') {
    px.rect(0, s.hz + 12, px.w, 2, mix(0x6E5A44, s.p.snow, 0.45));
  }
  // Rock through the snow on the White Pass.
  if (s.region === 'whitePassSummit') {
    for (let i = 0; i < 6; i++) {
      const x = mod(i * 37 + 11 - (moving ? t * spd : 0) - s.mile * 3, 172) - 6;
      const y = s.hz + 3 + (i * 7) % 18;
      px.rect(floor(x), y, 5, 2, s.c(0x6B6E72));
      px.rect(floor(x) + 1, y - 1, 3, 1, s.c(0x85888C));
    }
  }
  // Trail poles every 24 pixels, going by with the ground.
  const pole = s.c(0x3A2A1A);
  const gs = spd * (0.4 + 2 * 0.18) + (moving ? 0.25 : 0);
  for (let i = 0; i < 8; i++) {
    let x = mod(i * 24 - t * gs - s.mile * 2, 192);
    if (x < 0) x += 192;
    px.rect(floor(x - 16), s.hz + 4, 1, 5, pole);
  }
}

// MARK: The river, from the boat

function riverBanks(s) {
  const px = s.px, hz = s.hz;
  const ox = s.mile * 0.05 + (s.f.moving ? s.t * 0.5 : 0);
  switch (s.region) {
    case 'upperLakes': {
      const rock = s.far(0x56636E), cap = s.far(0xF2F5F8);
      for (let i = 0; i < 160; i++) {
        const x = i + ox;
        const h = jsRounded(13 + 6 * sin(x * 0.04) + 3 * sin(x * 0.13));
        px.rect(i, hz - h, 1, h, rock);
        px.rect(i, hz - h, 1, 3, cap);
      }
      break;
    }
    case 'laberge': {
      const hill = s.far(0x8D8C84);
      px.hills(0, 160, hz, hill, (x) => 9 + 5 * sin((x + ox) * 0.06) + 2 * sin((x + ox) * 0.2));
      break;
    }
    case 'yukon': {
      const hill = s.far(0x4C5A4A);
      px.hills(0, 160, hz, hill, (x) => 8 + 4 * sin((x + ox) * 0.05) + 2 * sin((x + ox) * 0.21));
      break;
    }
    default:
      break;
  }
  const spd = s.f.moving ? 10 * s.f.weather.speed + 3 : 3;
  const lake = s.region === 'upperLakes' || s.region === 'laberge';
  if (s.region === 'yukon' || s.region === 'fiftyMile') {
    // The cutbank under the trees.
    px.rect(0, hz - 2, 160, 2, s.far(0xB59A6A, 0.1));
    spruceLine(s, s.region === 'fiftyMile' ? 9 : 7, 3, s.far(0x1F3A2A), false, hz - 2, spd * 0.3);
  } else {
    spruceLine(s, lake ? 4 : 7, 3, s.far(0x1F3A2A, 0.05), false, null, spd * 0.3);
  }
}

function river(s) {
  const px = s.px, hz = s.hz;
  const g = s.g;
  if (g && g.mile === s.J.stops[7].mile && !iceGone(s)) {
    // A boat built at Bennett before break-up waits on the ice: white from shore to shore,
    // with a few grey cracks.
    s.rect(0, hz, px.w, px.h - hz, mix(0xE8F0F5, s.p.snow, 0.3));
    for (const i of stride(3, 160, 11, false)) s.rect(i, hz + 3 + (i % 4) * 4, 5, 1, s.c(0xC9D8E2));
  } else {
    const water = mix(s.p.water, 0x2E5A4E, 0.5);
    px.rect(0, hz, px.w, px.h - hz, water);
    const spd = s.f.moving ? 10 * s.f.weather.speed + 3 : 3;
    waves(s, spd, s.p.rough);
    if (s.f.weather.sky === 'still') floes(s, spd);
  }
  // The near bank.
  const pulledIn = !s.f.moving || givenOutOf(s);
  const top = pulledIn ? 74.0 : 78.0;
  px.rect(0, top, px.w, px.h - top, s.c(0x6B5A3A));
  if (pulledIn) {
    for (const i of stride(2, 160, 7, false)) px.rect(i, top + 1 + i % 3, 2, 1, s.c(0x8A7A5A));
  }
}

// MARK: Places

/** How far from a stop the scene is drawn, or null when it is too far to show. */
function nearOf(s) {
  return (id) => {
    const st = s.J.stops.find((x) => x.id === id);
    if (!st) return null;
    const d = s.dx(st.mile);
    return abs(d) < 230 ? d : null;
  };
}

/** Whatever stands at a stop and behind the horizon line: hills, a town's far side. */
function behind(s) {
  const near = nearOf(s);
  let d;
  if ((d = near('seattle')) !== null) seattleHills(s, d);
  // Juneau is ninety miles astern by the head of Lynn Canal: gone the day after.
  if ((d = near('juneau')) !== null && d > -30) juneauHills(s, d);
  if ((d = near('lynn')) !== null && s.leg === 'steamer') fjord(s, d);
  if (s.leg === 'foot' && s.region === 'chilkootSummit' && s.g?.over !== true) {
    const e = s.dx(11360);
    if (abs(e) < 230) goldenStairs(s, e);
  }
  if ((d = near('canyon')) !== null && s.leg === 'boat') canyonWalls(s, d);
  if ((d = near('selkirk')) !== null && s.leg === 'boat') selkirkBench(s, d);
  if ((d = near('dawson')) !== null && s.leg === 'boat') dawsonHill(s, d);
}

/** Whatever stands on the near side of the horizon: tents, buildings, the frames of boats. */
function front(s) {
  const near = nearOf(s);
  let d;
  if ((d = near('seattle')) !== null && d > -40 && s.leg === 'steamer') wharf(s, d, true);
  if ((d = near('juneau')) !== null && d > -30 && s.leg === 'steamer') wharf(s, d, false);
  if ((d = near('landing')) !== null && s.leg === 'foot') { if (s.white) skagway(s, d); else dyea(s, d); }
  if ((d = near('camp')) !== null && s.leg === 'foot') { if (s.white) whitePassCity(s, d); else sheepCamp(s, d); }
  if ((d = near('summit')) !== null && s.leg === 'foot') { if (s.white) whitePassSummit(s, d); else chilkootSummit(s, d); }
  if ((d = near('lakes')) !== null && s.leg === 'foot') { if (s.white) logCabin(s, d); else lindeman(s, d); }
  // Not from the steamer: at the steamer's scale Bennett is a day past Lynn Canal.
  if ((d = near('bennett')) !== null && s.leg !== 'steamer') bennett(s, d);
  if ((d = near('tagish')) !== null && s.leg === 'boat') tagish(s, d);
  if ((d = near('canyon')) !== null && s.leg === 'boat') canyonWater(s, d);
  if ((d = near('fivefinger')) !== null && s.leg === 'boat') fiveFingers(s, d);
  if ((d = near('selkirk')) !== null && s.leg === 'boat') selkirk(s, d);
  if ((d = near('dawson')) !== null && s.leg === 'boat') dawson(s, d);
}

// Small pieces.

/** §16's tent: a 6×4 triangle-roofed block, a stovepipe, and a puff of smoke. */
function tent(s, x, y, smoke = true) {
  const canvas = s.c(0xE9E3D2);
  s.rect(x + 2, y, 2, 1, canvas);
  s.rect(x + 1, y + 1, 4, 1, canvas);
  s.rect(x, y + 2, 6, 2, canvas);
  s.rect(x + 2, y + 3, 1, 1, s.c(0x6E6458));
  s.rect(x + 4, y - 2, 1, 3, s.c(0x555555));
  if (smoke) {
    const k = floor(mod(s.t * 2 + x, 4));
    s.rect(x + 4 - (k > 1 ? 1 : 0), y - 3 - k, 1, 1, opacity(s.c(0xC8CCD0), 0.85));
  }
}

/** A log building: walls, darker courses, a roof line, a door. */
function cabin(s, x, y, w, h, roof = 0x4A3222) {
  s.rect(x, y, w, h, s.c(0x6B4A2B));
  for (const r of stride(1.0, h, 2, false)) s.rect(x, y + r, w, 1, s.c(0x5A3D24));
  s.rect(x - 1, y - 1, w + 2, 1, s.c(roof));
  s.rect(x + 1, y - 2, w - 2, 1, s.c(roof));
  s.rect(x + floor(w / 2), y + h - 3, 2, 3, s.c(0x2A1E14));
}

/** A false-fronted store with two lit windows. */
function storefront(s, x, y, w, h, wood) {
  s.rect(x, y, w, h, s.c(wood));
  s.rect(x, y - 2, w, 2, mix(wood, 0x2A1E14, 0.35));
  s.rect(x + 1, y + 2, 2, 2, s.c(0xF2C14E));
  s.rect(x + w - 3, y + 2, 2, 2, s.c(0xF2C14E));
  s.rect(x + floor(w / 2) - 1, y + h - 3, 2, 3, s.c(0x2A1E14));
}

/** A flag on a pole: the red ensign at the border posts, its corner fluttering. */
function flag(s, x, base, height = 12, red = 0xC8102E) {
  s.rect(x, base - height, 1, height, s.c(0x8F8A7A));
  const lift = trunc(floor(s.t * 2)) % 2 === 0 ? 0.0 : 1.0;
  s.rect(x + 1, base - height, 5, 3, s.c(red));
  s.rect(x + 1, base - height, 2, 2, s.c(0x2B3F7A));
  s.rect(x + 2, base - height, 1, 1, s.c(0xE8E8E8));
  s.rect(x + 1, base - height + 1, 1, 1, s.c(0xE8E8E8));
  s.rect(x + 6, base - height + lift, 1, 2, s.c(red));
}

/** Somebody standing about: a head and a coat. */
function person(s, x, y, coat) {
  s.rect(x, y, 1, 1, s.c(0xE6C29A));
  s.rect(x, y + 1, 1, 2, s.c(coat));
}

/** Crates and sacks of somebody's outfit, stacked. */
function goods(s, x, y) {
  s.rect(x, y, 3, 2, s.c(0x8B6A42));
  s.rect(x + 3, y + 1, 2, 1, s.c(0xCDBE94));
  s.rect(x + 1, y - 1, 2, 1, s.c(0xA8845A));
}

/** The ribs of a boat on the stocks. */
function frame(s, x, y) {
  const rib = s.c(0x9C7A4E);
  s.rect(x, y + 4, 12, 1, rib);
  for (let k = 0; k < 5; k++) {
    const rx = x + 1 + k * 2 + (k > 2 ? 1 : 0);
    const h = 4 - abs(k - 2) * 0.5;
    s.rect(rx, y + 4 - floor(h), 1, floor(h), rib);
  }
  s.rect(x - 1, y + 5, 2, 1, s.c(0x6B4A2B));
  s.rect(x + 11, y + 5, 2, 1, s.c(0x6B4A2B));
}

function tentCity(s, x0, count = 7, y = null) {
  const base = y ?? s.hz - 2;
  for (let i = 0; i < count; i++) {
    const x = x0 + i * 9;
    const up = (i * 3) % 4;
    tent(s, x, base - up);
  }
}

// Seattle.

function seattleHills(s, d) {
  const px = s.px, hz = s.hz;
  // Gone astern within the first day out.
  const lo = trunc(max(0, 84 + d)), hi = trunc(min(160, 160 + d));
  if (!(lo < hi && d > -40)) return;
  px.hills(lo, hi, hz, s.far(0x3E5242), (x) => 10 + 6 * sin((x - d) * 0.08) + 3 * sin((x - d) * 0.2));
  for (let i = 0; i < 9; i++) {
    const bx = 92 + d + i * 8, bh = 3 + (i * 5) % 4;
    const ground = jsRounded(10 + 6 * sin((bx + 2 - d) * 0.08) + 3 * sin((bx + 2 - d) * 0.2));
    s.rect(bx, hz - ground - bh + 2, 5, bh, s.c(0xE9DFC8));
    s.rect(bx, hz - ground - bh + 1, 5, 1, s.c(0x9A3B2E));
  }
  // A church spire above the roofs.
  s.rect(124 + d, hz - 24, 1, 6, s.c(0xE9DFC8));
}

function wharf(s, d, crowd) {
  const x0 = 76 + d;
  s.rect(x0, s.hz - 1, 90, 2, s.c(0x5A4030));
  for (const k of stride(0.0, 90, 6, false)) s.rect(x0 + k, s.hz + 1, 1, 3, s.c(0x3A2A1A));
  if (crowd) {
    for (let k = 0; k < 8; k++) person(s, x0 + 8 + k * 4 + k % 2, s.hz - 4, k % 3 === 0 ? 0xB5432F : 0x3B3E4A);
  }
  if (s.f.atPort && s.leg === 'steamer' && abs(d) < 1) {
    // The gangway down to the wharf.
    s.px.line({ x: 66, y: s.hz - 3 }, { x: x0, y: s.hz - 1 }, s.c(0x8B6A42));
  }
}

// Juneau: 1849's hillside town, under its mountain.

function juneauHills(s, d) {
  const px = s.px, hz = s.hz;
  const lo = trunc(max(0, 92 + d)), hi = trunc(min(160, 175 + d));
  if (!(lo < hi)) return;
  const rock = s.far(0x46545C), cap = s.far(0xE8EEF2);
  for (let i = lo; i < hi; i++) {
    const off = abs(i - d - 132);
    const h = jsRounded(max(0, 34 - off * 0.9));
    if (!(h > 0)) continue;
    px.rect(i, hz - h, 1, h, rock);
    if (h > 18) px.rect(i, hz - h, 1, h - 18, cap);
  }
  px.hills(lo, hi, hz, s.c(0x2F4A35), (x) => {
    const u = x - d;
    return 11 + 7 * sin(u * 0.09) + 4 * sin(u * 0.23);
  });
  for (let i = 0; i < 7; i++) {
    const bx = 104 + d + i * 8, bh = 3 + (i * 5) % 4;
    s.rect(bx, hz - bh - 1, 5, bh + 1, s.c(0xE9DFC8));
    s.rect(bx, hz - bh - 2, 5, 1, s.c(0x9A3B2E));
  }
}

// The head of Lynn Canal: mountains straight up into the cloud on either hand. Coming up the
// canal the left-hand wall is a peak ahead, not a cliff over everything astern.

function fjord(s, d) {
  const px = s.px, hz = s.hz;
  const wall = s.far(0x3B4A52, -0.1), streak = s.far(0xE8EEF2);
  // Rising out of the sea over the last day's steaming.
  const rise = min(1, max(0, (60 - d) / 60));
  if (!(rise > 0)) return;
  for (let i = 0; i < 160; i++) {
    const x = i - d;
    const left = (48 - abs(x) * 1.4) * rise, right = (x - 112) * 1.3 * rise;
    const h = jsRounded(min(hz, max(0, max(left, right))));
    if (!(h > 0)) continue;
    px.rect(i, hz - h, 1, h, wall);
    if (trunc(x) % 9 < 2) px.rect(i, hz - h + 3, 1, max(0, h - 10), streak);
  }
  // The cloud the walls go up into.
  px.rect(0, 7, 160, 7, opacity(s.c(0xC9CED4), 0.75 * rise));
  px.rect(10, 5, 60, 2, opacity(s.c(0xC9CED4), 0.6 * rise));
}

// The landing: Dyea's tent flats, Skagway's false fronts.

function dyea(s, d) {
  // Lynn Canal behind, the tide flats grey in front of the tents.
  s.rect(0 + d, s.hz - 2, 70, 2, s.c(s.p.water));
  s.rect(80 + d, s.hz + 1, 90, 3, mix(0x8A8470, s.p.snow, 0.35));
  tentCity(s, 98 + d, 7, s.hz - 3);
  for (let k = 0; k < 5; k++) goods(s, 84 + d + k * 15, s.hz + 6 + (k % 2) * 3);
  // A lighter left on the flats.
  s.rect(84 + d, s.hz + 2, 10, 2, s.c(0x4A3A2A));
  s.rect(85 + d, s.hz + 4, 8, 1, s.c(0x3A2A1A));
}

function skagway(s, d) {
  // The long wharf out into the canal, and the muddy street.
  s.rect(0 + d, s.hz - 2, 70, 2, s.c(s.p.water));
  s.rect(4 + d, s.hz - 3, 60, 1, s.c(0x5A4030));
  s.rect(90 + d, s.hz + 1, 80, 3, mix(0x6E5A44, s.p.snow, 0.4));
  const woods = [0x8C6A48, 0xA8845A, 0x6E5A44, 0x9A7A56, 0x7E6448];
  for (let i = 0; i < 5; i++) {
    const w = 9 + (i % 2) * 2, h = 8 + (i * 3) % 5;
    storefront(s, 96 + d + i * 12, s.hz - h + 1, w, h, woods[i]);
  }
  tent(s, 154 + d, s.hz - 3);
}

// The camps below the summit.

function sheepCamp(s, d) {
  const green = s.c(0x1F3A2A);
  for (let k = 0; k < 5; k++) tree(s.px, 92 + d + k * 15, s.hz + 1, 8 + (k * 3) % 4, green);
  tentCity(s, 96 + d, 7, s.hz - 1);
  for (let k = 0; k < 4; k++) goods(s, 90 + d + k * 17, s.hz + 6 + (k % 2) * 2);
}

function whitePassCity(s, d) {
  for (let k = 0; k < 3; k++) cabin(s, 98 + d + k * 16, s.hz - 5, 9, 6);
  for (let k = 0; k < 4; k++) tent(s, 106 + d + k * 16, s.hz - 1);
  // Where the wagon road gives out.
  s.rect(60 + d, s.hz + 12, 40, 2, mix(0x6E5A44, s.p.snow, 0.45));
}

// The summit: the Golden Stairs below it, the border at the top.

function goldenStairs(s, d) {
  const px = s.px, hz = s.hz;
  const lo = trunc(max(0, 96 + d)), hi = trunc(min(160, 200 + d));
  if (!(lo < hi)) return;
  const slope = mix(0xF2F5F8, s.p.snow, 0.4);
  px.hills(lo, hi, hz + 3, slope, (x) => min(hz - 2, (x - 96 - d) * 0.7));
  // The line of climbers, one step at a time.
  const climb = floor(s.t * 0.8);
  for (let k = 0; k < 14; k++) {
    const along = mod(k * 5 + climb, 70);
    const x = 98 + d + along;
    if (!(x >= 0 && x < 160)) continue;
    const y = hz + 3 - min(hz - 2, along * 0.7) - 2;
    s.rect(x, y, 1, 2, s.c(0x2A2522));
  }
  // The Scales at the foot: outfits waiting to be weighed.
  for (let k = 0; k < 3; k++) goods(s, 90 + d + k * 5, hz + 4);
}

function chilkootSummit(s, d) {
  // A log hut half buried in snow, the flag, and the police.
  cabin(s, 112 + d, s.hz - 4, 13, 6);
  s.rect(108 + d, s.hz - 1, 22, 3, s.c(s.p.snow));
  s.rect(110 + d, s.hz - 2, 18, 1, s.c(s.p.snow));
  flag(s, 132 + d, s.hz);
  person(s, 128 + d, s.hz - 3, 0x3A2A1E);
  s.rect(127 + d, s.hz - 1, 3, 1, s.c(0x3A2A1E));
  // The scale, and the outfits waiting for it.
  s.rect(140 + d, s.hz - 6, 1, 6, s.c(0x6B4A2B));
  s.rect(138 + d, s.hz - 6, 5, 1, s.c(0x6B4A2B));
  s.rect(138 + d, s.hz - 4, 1, 2, s.c(0x8F8A7A));
  for (let k = 0; k < 3; k++) goods(s, 144 + d + k * 5, s.hz + 2 + k % 2);
}

function whitePassSummit(s, d) {
  for (let k = 0; k < 3; k++) tent(s, 112 + d + k * 8, s.hz - 2 - k % 2);
  flag(s, 140 + d, s.hz);
  person(s, 136 + d, s.hz - 3, 0x3A2A1E);
  for (let k = 0; k < 3; k++) goods(s, 146 + d + k * 4, s.hz + 2);
}

// The lakes: Lindeman's whipsaws, Log Cabin's huts.

function lindeman(s, d) {
  tentCity(s, 102 + d, 6, s.hz - 3);
  // A whipsaw pit: a log up on a frame, one sawyer above and one below.
  const wood = s.c(0x6B4A2B);
  s.px.line({ x: 88 + d, y: s.hz + 10 }, { x: 92 + d, y: s.hz + 2 }, wood);
  s.px.line({ x: 100 + d, y: s.hz + 10 }, { x: 96 + d, y: s.hz + 2 }, wood);
  s.rect(86 + d, s.hz + 2, 16, 2, s.c(0x8B6A42));
  person(s, 93 + d, s.hz - 1, 0xB5432F);
  person(s, 94 + d, s.hz + 5, 0x3B3E4A);
  const saw = trunc(floor(s.t * 3)) % 2 === 0 ? 0.0 : 1.0;
  s.rect(94 + d, s.hz + 1 + saw, 1, 4, s.c(0xA0A4A8));
}

function logCabin(s, d) {
  const pine = s.c(0x2A4430);
  for (let k = 0; k < 4; k++) tree(s.px, 96 + d + k * 17, s.hz + 2, 4 + k % 2, pine);
  for (let k = 0; k < 3; k++) cabin(s, 100 + d + k * 17, s.hz - 3, 7, 4);
}

// Lake Bennett: the tent city, boats on the stocks, the lake frozen or full of sails.

function bennett(s, d) {
  if (!(abs(d) < 200)) return;
  tentCity(s, 98 + d, 7, s.hz - 3);
  const built = hasBoatOf(s);
  const frames = built ? 3 : 4;
  for (let k = 0; k < frames; k++) {
    const x = 2 + d + k * 9;
    frame(s, x, s.leg === 'boat' ? s.hz - 8 : s.hz + 8 + (k % 2) * 3);
  }
  if (s.leg === 'boat' && s.g && iceGone(s)) {
    // The lake full of sails, going north.
    for (let k = 0; k < 6; k++) {
      let x = mod(k * 27 + s.t * 1.5, 170);
      if (x < 0) x += 170;
      s.rect(x - 5, s.hz + 1 + k % 3, 2, 3, s.c(0xE8DFC4));
      s.rect(x - 6, s.hz + 4 + k % 3, 4, 1, s.c(0x6B4A2B));
    }
  }
}

// The river's stops.

function tagish(s, d) {
  cabin(s, 110 + d, s.hz - 6, 16, 6);
  flag(s, 130 + d, s.hz - 1, 14);
  person(s, 106 + d, s.hz - 3, 0xB5432F);
  // Boats tied up waiting to be numbered.
  for (let k = 0; k < 3; k++) {
    s.rect(92 + d + k * 9, s.hz + 1, 7, 2, s.c(0x9C7A4E));
    s.rect(95 + d + k * 9, s.hz - 3, 1, 4, s.c(0x6B4A2B));
  }
}

/**
 * Where the slot runs, from the stop: ahead of the boat on the morning she reaches it (not
 * across the upper lakes), around her at it, and behind her within the day, before Lake
 * Laberge opens out.
 */
export const canyonSpan = { from: 20.0, to: 90.0, ahead: 60.0 };

function canyonWalls(s, d) {
  const px = s.px;
  const rock = s.c(0x2B2B30), lit = s.c(0x4A4A52);
  const lo = trunc(max(0, d + canyonSpan.from)), hi = trunc(min(160, d + canyonSpan.to));
  if (!(lo < hi && d < canyonSpan.ahead)) return;
  for (let i = lo; i < hi; i++) {
    const x = i - d;
    const h = jsRounded(26 + 4 * sin(x * 0.3) + 2 * sin(x * 0.9));
    px.rect(i, s.hz - h, 1, h + 2, rock);
    if (trunc(x) % 6 === 0) px.rect(i, s.hz - h + 2, 1, h - 6, lit);
  }
  // Spruce along the rim.
  for (let k = lo; k < hi; k += 5) {
    const x = k - d;
    const h = jsRounded(26 + 4 * sin(x * 0.3) + 2 * sin(x * 0.9));
    tree(px, k, s.hz - h, 4, s.c(0x1F3A2A));
  }
}

function canyonWater(s, d) {
  const px = s.px;
  const lo = max(0, d + canyonSpan.from), hi = min(160, d + canyonSpan.to);
  if (!(lo < hi && d < canyonSpan.ahead)) return;
  // White water the length of the slot, and the near wall's foot.
  const foam = s.c(0xEEF3F5);
  for (let k = 0; k < 22; k++) {
    let x = mod(k * 23 - s.t * 40, hi - lo + 10) + lo;
    if (x < lo) x += hi - lo;
    px.rect(floor(x), s.hz + 1 + (k * 5) % 24, 3 + k % 3, 1, foam);
  }
  px.rect(lo, 75, hi - lo, 5, s.c(0x2B2B30));
  px.rect(lo, 74, hi - lo, 1, s.c(0x4A4A52));
}

function fiveFingers(s, d) {
  for (let k = 0; k < 4; k++) {
    const x = 96 + d + k * 15, h = 18 + (k * 5) % 7;
    s.rect(x, s.hz - h, 7, h + 2, s.c(0x4A4038));
    s.rect(x + 1, s.hz - h + 1, 1, h - 2, s.c(0x6A5E52));
    tree(s.px, x + 2, s.hz - h, 4, s.c(0x1F3A2A));
    tree(s.px, x + 5, s.hz - h, 3, s.c(0x1F3A2A));
    // The water piling white between them.
    const surge = floor(mod(s.t * 6 + k * 2, 4));
    s.rect(x + 7, s.hz + 1 + surge, 8, 1, s.c(0xEEF3F5));
    s.rect(x - 1, s.hz + 2, 9, 1, s.c(0xEEF3F5));
  }
}

function selkirkBench(s, d) {
  // The flat above the river, and the Pelly coming in from the east.
  s.rect(78 + d, s.hz - 6, 100, 6, s.far(0x6E7350));
  s.rect(78 + d, s.hz - 7, 100, 1, s.far(0x8A8A5E));
  s.rect(96 + d, s.hz - 6, 5, 6, mix(s.p.water, 0x2E5A4E, 0.5));
}

function selkirk(s, d) {
  cabin(s, 110 + d, s.hz - 13, 16, 7);
  s.rect(112 + d, s.hz - 15, 12, 1, s.c(0xE9DFC8));
  for (let k = 0; k < 3; k++) cabin(s, 130 + d + k * 9, s.hz - 11, 6, 5);
  tent(s, 102 + d, s.hz - 10);
  flag(s, 106 + d, s.hz - 6, 12, 0xB5432F);
}

function dawsonHill(s, d) {
  const px = s.px, hz = s.hz;
  const lo = trunc(max(0, 40 + d)), hi = trunc(min(160, 230 + d));
  if (!(lo < hi)) return;
  px.hills(lo, hi, hz, s.far(0x3E4A3A), (x) => 22 + 6 * sin((x - d) * 0.05) + 2 * sin((x - d) * 0.3));
  // The old slide's scar on the hill behind the town.
  for (let r = 0; r < 14; r++) {
    const w = 2 + trunc(r / 2);
    px.rect(132 + d - w / 2, hz - 30 + r, w, 1, s.far(0xA59C88));
  }
}

function dawson(s, d) {
  const lumber = [0xC9A06A, 0xB08850, 0xD8B47E];
  for (let i = 0; i < 8; i++) {
    const x = 56 + d + i * 13, h = 6 + (i * 5) % 5;
    if (i % 3 === 1) {
      tent(s, x, s.hz - 5);
    } else {
      storefront(s, x, s.hz - h, 9, h, lumber[i % 3]);
    }
  }
  // Boats along the bank, three deep.
  for (let row = 0; row < 3; row++) {
    for (let k = 0; k < 12; k++) {
      const x = 38 + d + k * 10 + row * 4;
      const y = s.hz + 1 + row * 2;
      s.rect(x, y, 7, 2, s.c(row === 1 ? 0x8C6A42 : 0x9C7A4E));
      s.rect(x + 3, y - 3, 1, 3, s.c(0x6B4A2B));
    }
  }
}

// MARK: The steamer, the party and the boat

function drawSteamer(s) {
  const hz = s.hz, t = s.t;
  const rough = s.p.rough + (s.region === 'queenCharlotte' ? 1 : 0);
  const docked = s.f.atPort;
  const bob = docked ? 0 : jsRounded(sin(t * (1.4 + rough * 0.7)) * (0.5 + rough * 0.5));
  const top = hz - 9 + bob;
  // Smoke streams back from the funnel (rises straight at the wharf).
  s.px.sprite(steamer.slice(3), 44, top + 3, steamerColors);
  const smoke = s.c(0x8F959C);
  for (let k = 0; k < 4; k++) {
    const age = mod(t * 2.5 + k * 5, 20);
    const x = docked ? 54 + jsRounded(sin(t + k)) : 54 - age;
    const y = top + 2 - (docked ? age * 0.6 : age * 0.25);
    s.rect(floor(x), floor(y), 2 + (age > 10 ? 1 : 0), 1, opacity(smoke, 1 - age / 25));
  }
  if (s.f.moving) {
    const wave = s.c(s.p.accent);
    for (let i = 0; i < 5; i++) {
      s.rect(70 + (i * 5 + trunc(floor(t * 8))) % 12, hz + 3 + i % 2, 2, 1, wave);
    }
  }
}

/** The party and its sled, worn as the meters say; or, the trek over, what is left. */
function drawParty(s) {
  const px = s.px, hz = s.hz, t = s.t;
  const g = s.g;
  const sails = s.f.sails, hull = s.f.hull;
  const over = g?.over ?? false;
  const givenOut = givenOutOf(s);
  const ruined = over && hull < 0.5;
  const turnedBack = over && !ruined && stopId(s.J, g) === 'summit' && (g?.crew?.[0]?.alive ?? false);
  const walking = s.f.moving && !givenOut && !over;
  const rows = [...party];
  if (walking && trunc(floor(t / 0.35)) % 2 === 1) {
    rows[7] = stride7[0];
    rows[8] = stride7[1];
  }
  const x = 40.0, y = hz + 2;
  const inTown = s.f.atPort;
  // Your own camp, pitched off the trail.
  if (!s.f.moving && !inTown && !over) {
    tent(s, 80, hz + 1, (g?.water ?? 1) > 0);
  }
  if (turnedBack) {
    // Facing home, down the pass.
    px.sprite(rows.map((r) => [...r].reverse().join('')), x, y, partyColors);
    return;
  }
  const people = sledColumns.upper;
  if (ruined) {
    // No load left on the sled: split sacks and flour in the snow.
    px.sprite(rows, x, y, partyColors, (col, _row, ch) => ch === 'l' || (ch === 'r' && col >= sledColumns.lower && col < people));
    for (let k = 0; k < 9; k++) {
      s.rect(x - 24 + k * 4, hz + 8 + k % 3, 2, 1, s.c(0xF2EEE2));
      if (k % 3 === 0) s.rect(x - 22 + k * 4, hz + 6, 3, 2, s.c(0xCDBE94));
    }
    return;
  }
  // In town the sled is left at the edge and the party walks in among the tents.
  px.sprite(rows, x, y, partyColors, (col, row, ch) => {
    if (inTown && col >= people) return true;
    if (givenOut && ch === 'n' && col % 3 === 0) return true;
    if (givenOut && row === 6 && col < 5) return true;
    return (ch === 'l' || ch === 's') && torn(col, row, sails);
  });
  if (inTown) {
    const walkers = rows.map((r) => r.slice(people));
    px.sprite(walkers, x + 34, y, partyColors);
  }
  if (givenOut) {
    // A split runner and a broken slat lying in the snow.
    s.rect(x - 4, hz + 9, 5, 1, s.c(0x8B6A42));
    s.rect(x - 7, hz + 10, 4, 1, s.c(0x2E3036));
  }
  // The outfit itself: patched tarps, then flour leaking out behind.
  if (hull < 60) {
    s.rect(x + 3, y + 3, 2, 1, s.c(0x9E8E64));
    s.rect(x + 7, y + 2, 1, 2, s.c(0x9E8E64));
  }
  if (hull < 35) {
    s.rect(x + 9, y + 5, 2, 2, s.c(0xCDBE94));
    const drift = walking ? mod(t * 3, 6) : 0;
    for (let k = 0; k < 5; k++) s.rect(x - 3 - k * 5 - drift, hz + 9 + k % 2, 1, 1, s.c(0xF2EEE2));
  }
}

function drawBoat(s) {
  const px = s.px, hz = s.hz, t = s.t;
  const g = s.g;
  const hull = s.f.hull, sails = s.f.sails;
  const over = g?.over ?? false;
  if (over && hull < 0.5) {
    // Broken up: planks going downriver, the party on a gravel bar.
    for (let k = 0; k < 7; k++) {
      let x = mod(k * 23 - t * 6, 170);
      if (x < 0) x += 170;
      s.rect(x - 6, hz + 3 + (k * 5) % 20, 5, 1, s.c(0x9C7A4E));
    }
    s.rect(36, 62, 52, 4, s.c(0x8A7A5A));
    s.rect(40, 61, 44, 1, s.c(0x9E8E6A));
    const people = sledColumns.upper;
    const walkers = party.map((r) => r.slice(people));
    px.sprite(walkers, 46, 52, partyColors);
    return;
  }
  const isRaft = g?.vars?.[boatKey] === raft;
  const givenOut = givenOutOf(s);
  const tied = s.f.atPort || givenOut;
  const rough = s.p.rough;
  const bob = tied ? 0 : jsRounded(sin(t * (1.4 + rough * 0.7)) * (0.5 + rough * 0.5));
  const low = hull < 35 ? 1.0 : 0;
  const top = hz - 10 + bob + low;
  const ashore = s.f.atPort;
  const patched = hull < 60;
  px.sprite(isRaft ? raftBoat : boat, 44, top, boatColors, (col, row, ch) => {
    if (givenOut && (ch === 's' || ch === 'o')) return true;
    if (ashore && 'phfd'.includes(ch)) return true;
    if (ch === 's') return torn(col, row, sails);
    return false;
  });
  if (patched) {
    s.rect(52, top + 12, 3, 1, s.c(0xC9BC94));
    s.rect(61, top + 13, 2, 1, s.c(0xC9BC94));
  }
  if (givenOut) {
    // Furled sail on the yard, and a line to a stake on the bank.
    s.rect(51, top + 2, 11, 1, s.c(0xD8CFB4));
  }
  if (tied) {
    px.line({ x: 69.5, y: top + 12.5 }, { x: 88, y: 75 }, s.c(0x7A5A3A));
    s.rect(88, 73, 1, 3, s.c(0x5A4030));
  }
  if (ashore) {
    // The party stretching its legs on the bank.
    for (let k = 0; k < 4; k++) person(s, 96 + k * 5, 71, k % 2 === 0 ? 0xB5432F : 0x3B3E4A);
  }
  if (hull < 35 && !tied) {
    // Somebody bailing over the side.
    const phase = mod(t * 1.6, 1);
    const drop = s.c(0x9FC6DE);
    s.rect(48 + phase * 4, top + 10 - sin(phase * Math.PI) * 4, 1, 1, drop);
    s.rect(47 + phase * 5, top + 11 - sin(phase * Math.PI) * 3, 1, 1, drop);
  }
  // A fire on the bank where the party has pulled in for the night.
  if (!s.f.moving && !s.f.atPort && !givenOut && (g?.water ?? 1) > 0) {
    const flick = trunc(floor(t * 6)) % 2 === 0 ? 0xF2A03A : 0xE36A2A;
    s.rect(104, 75, 2, 1, s.c(flick));
    s.rect(103, 76, 4, 1, s.c(0x5A4030));
    const k = floor(mod(t * 2, 5));
    s.rect(105, 73 - k, 1, 1, opacity(s.c(0xC8CCD0), 0.8));
  }
}

// MARK: What the weather is doing

function air(s) {
  const px = s.px, t = s.t;
  switch (s.f.weather.sky) {
    case 'rain': px.rain(t); break;
    case 'snow': px.snow(t); break;
    case 'fog': px.fog(); break;
    case 'dust': {
      // Thaw: a thin rain over the slush.
      const c = opacity(rgb(200, 215, 230), 0.55);
      for (let i = 0; i < 20; i++) {
        px.rect(floor(mod(i * 37 + t * 24, px.w)), floor(mod(i * 53 + t * 120, px.h)), 1, 2, c);
      }
      break;
    }
    case 'gale':
      if (s.leg === 'foot') {
        // Snow blowing off the ground.
        for (let i = 0; i < 24; i++) {
          let x = mod(i * 41 - t * 90, 170);
          if (x < 0) x += 170;
          px.rect(floor(x - 5), 4 + (i * 23) % 72, 3, 1, opacity(white, 0.85));
        }
      }
      break;
    case 'storm':
      for (let i = 0; i < 60; i++) {
        let x = mod(i * 37 - t * 40 + sin(t + i) * 2, 165);
        if (x < 0) x += 165;
        px.rect(floor(x), floor(mod(i * 29 + t * 24, px.h)), 1, 1, white);
      }
      px.rect(0, 0, px.w, px.h, opacity(rgb(220, 228, 235), 0.25));
      break;
    case 'heat':
      // Mosquitoes, in clouds.
      for (let i = 0; i < 12; i++) {
        const jx = jsRounded(sin(t * 9 + i * 1.7)), jy = jsRounded(cos(t * 11 + i));
        px.rect(50 + (i * 13) % 40 + jx, s.hz - 16 + (i * 7) % 14 + jy, 1, 1, hex(0x2A2A2A));
      }
      break;
    case 'still':
      // Rime in the air over the ice.
      if (s.leg === 'foot') {
        for (let i = 0; i < 10; i++) {
          const on = trunc(floor(t * 3) + i) % 3 === 0;
          if (on) px.rect((i * 31) % 160, (i * 17) % 40 + 4, 1, 1, opacity(white, 0.9));
        }
      }
      break;
    default:
      break;
  }
}

// MARK: What VoiceOver says

export function phrase(sky) {
  switch (sky) {
    case 'clear': return 'under clear skies';
    case 'breeze': return 'in fair weather';
    case 'rain': return 'in the rain';
    case 'fog': return 'under low cloud';
    case 'snow': return 'in falling snow';
    case 'dust': return 'in slush and mud';
    case 'gale': return 'in a high wind';
    case 'storm': return 'in a blizzard';
    case 'still': return 'among cakes of running ice';
    case 'heat': return 'in the heat, under clouds of mosquitoes';
    default: return 'under clear skies';
  }
}

export function label(J, f) {
  const g = f.state;
  if (!g) return 'A party hauling a loaded sled up a snowy mountain pass';
  const w = phrase(f.weather.sky);
  const town = f.atPort ? f.port?.name ?? null : null;
  const k = f.hooks?.klondike ?? {};
  const boatBuilt = k.hasBoat ?? false;
  const here = stopId(J, g);
  switch (k.leg) {
    case 'steamer':
      if (town !== null) return `The steamer tied up at ${town}, ${w}`;
      return f.moving ? `A crowded steamer heading north ${w}` : `A crowded steamer lying to ${w}`;
    case 'foot':
      if (g.over && f.hull < 0.5) return `Your outfit lies ruined in the snow, ${w}`;
      if (g.over && here === 'summit') return `Your party turning back from the summit, ${w}`;
      if (k.givenOut) return `Your party beside sleds that have given out, ${w}`;
      if (town !== null) return `Your party in camp at ${town}, ${w}`;
      return f.moving ? `Your party hauling sleds ${w}` : `Your party camped beside the trail ${w}`;
    default: {
      if (g.over && f.hull < 0.5) return `The wreck of your boat going down the river, ${w}`;
      if (k.givenOut) return `Your boat tied to the bank with no oars or sail, ${w}`;
      if (town !== null) return `Your boat tied up at ${town}, ${w}`;
      const what = boatBuilt ? 'Your boat' : 'A boat';
      return f.moving ? `${what} on the river ${w}` : `${what} pulled in to the bank ${w}`;
    }
  }
}
