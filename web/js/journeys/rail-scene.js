// The Iron Road's scene (AroundTheHorn/Journeys/RailScene.swift): a wood-burning 4-4-0,
// her tender, a tank car, two boxcars and a caboose, heading west (left) under nine
// weathers and through thirteen kinds of country. A yard at the stops, a trestle at Dale
// Creek, snowsheds in the Sierra, and wear that shows: a leaking, rusting engine, and cars
// with planks gone and a hot box.
//
// `draw(J, px, f)` and `label(J, f)` take the journey's tables (`J`) for what the Swift
// reads off `RailSkin.journey`: Dale Creek's mile and what the tender holds.

import { PixelCanvas, hex, opacity, white, jsRounded } from '../pixels.js';

export const horizon = 44;
/** The top of the rail the wheels stand on. */
export const rail = 62;

// MARK: Sky

/** By the kind of sky. A blizzard is snow that is hard on the crew. */
export function palette(w) {
  // What the weather does to the colour of the ground (`tint`), and how far (`amount`).
  const P = (o) => ({ sun: null, clouds: 0, cloud: 0xF4F7FA, tint: 0, amount: 0, water: 0x5C9BD0, ...o });
  switch (w.sky) {
    case 'clear':
    case 'still':
      return P({ top: 0x3A78B8, bot: 0xBFE0F2, sun: 0xFFE27A, clouds: 1 });
    case 'breeze':
      return P({ top: 0x3570B0, bot: 0xC6E4F4, sun: 0xFFE27A, clouds: 3, water: 0x5590C4 });
    case 'heat':
      return P({ top: 0xE07A3A, bot: 0xF8D27A, sun: 0xFFF6C8, tint: 0xE8B45A, amount: 0.18, water: 0x7FAFC0 });
    case 'rain':
    case 'gale':
      return P({ top: 0x3E4A5A, bot: 0x7D8A98, clouds: 3, cloud: 0x6B7685, tint: 0x2A3440, amount: 0.3, water: 0x4A6A86 });
    case 'fog':
      return P({ top: 0x8D969E, bot: 0xC5CBD0, tint: 0x9AA2A8, amount: 0.25, water: 0x7F97A8 });
    case 'snow':
      return w.harsh > 1
        ? P({ top: 0x6E7780, bot: 0xC4CCD4, tint: 0xEEF2F6, amount: 0.88, water: 0xB4C6D4 })
        : P({ top: 0x55606E, bot: 0xA6B2BF, clouds: 3, cloud: 0x8C97A3, tint: 0xE8EEF3, amount: 0.6, water: 0x8FA8BC });
    case 'storm':
      return P({ top: 0x15191F, bot: 0x3A434F, clouds: 3, cloud: 0x2C333D, tint: 0x1A2230, amount: 0.45, water: 0x2E4A64 });
    case 'dust':
      return P({ top: 0xB08A55, bot: 0xDCC090, sun: 0xF4E2B0, tint: 0xC9A27A, amount: 0.3, water: 0x8A9A90 });
    default:
      throw new Error(`no palette for the sky ${w.sky}`);
  }
}

// MARK: The train

export const engine = [
  '      kkkkkkk                   ',
  '      kkkkkkk                   ',
  '       kkkkk          oooooooooo',
  '        kkk     gg     ccccccccc',
  '   loo  kkk g  gggg    cwwccwwcc',
  '   loo  kkkggg gggg    cwwccwwcc',
  '    kkkkkkkkkkkkkkkkkkkccccccccc',
  '    kkkkkkkgkkkkkgkkkkkccccccccc',
  '    kkkkkkkgkkkkkgkkkkkccccccccc',
  '    kkkkkkkkkkkkkkkkkkkccccccccc',
  '  nnnnnnnnnnnnnRRRRnnnnRRRRnnnnn',
  '   ppkkkkk    RRRRRR  RRRRRR    ',
  '  pppkgkgk    RRhhRR  RRhhRR    ',
  ' pppp ddd ddd RRhhRR  RRhhRR    ',
  'ppppp ded ded RRRRRR  RRRRRR    ',
  'ppppp ddd ddd  RRRR    RRRR     ',
];

export const tender = [
  'ttttttttttttttttt',
  'ttttttttttttttttt',
  'tgggggggggggggggt',
  'ttttttttttttttttt',
  'ttttttttttttttttt',
  'ttttttttttttttttt',
  'nnnnnnnnnnnnnnnnn',
  'ddd ddd   ddd ddd',
  'ded ded   ded ded',
  'ddd ddd   ddd ddd',
];

export const tankCar = [
  '       bbbb       ',
  '  aaaaaaaaaaaaaa  ',
  ' aabaaaabaaaabaaa ',
  ' aabaaaabaaaabaaa ',
  ' aabaaaabaaaabaaa ',
  ' aabaaaabaaaabaaa ',
  '  aaaaaaaaaaaaaa  ',
  'ffffffffffffffffff',
  'ddd ddd    ddd ddd',
  'ded ded    ded ded',
  'ddd ddd    ddd ddd',
];

export const boxcar = [
  '     yyyyyyyyyy     ',
  'oooooooooooooooooooo',
  'BBBBBBBBBBBBBBBBBBBB',
  'BBBBBBBDDDDDDBBBBBBB',
  'BBBBBBBDDDDDDBBBBBBB',
  'BBBBBBBDDDDDDBBBBBBB',
  'BBBBBBBDDDDDDBBBBBBB',
  'BBBBBBBDDDDDDBBBBBBB',
  'nnnnnnnnnnnnnnnnnnnn',
  ' ddd ddd    ddd ddd ',
  ' ded ded    ded ded ',
  ' ddd ddd    ddd ddd ',
];

export const caboose = [
  '      ooooo      ',
  '      CwCwC      ',
  'ooooooooooooooooo',
  ' CCCCCCCCCCCCCCC ',
  ' CCwwCCCCCCCwwCC ',
  ' CCwwCCCCCCCwwCC ',
  ' CCCCCCCCCCCCCCC ',
  ' CCCCCCCCCCCCCCC ',
  ' CCCCCCCCCCCCCCC ',
  'nnnnnnnnnnnnnnnnn',
  '  ddd       ddd  ',
  '  ded       ded  ',
  '  ddd       ddd  ',
];

export const colors = {
  k: hex(0x26262B), o: hex(0x4A2E1A), c: hex(0x7E2F24), w: hex(0x9FC6DE),
  g: hex(0xD9A441), l: hex(0xF2E3A6), n: hex(0x3A3A40), p: hex(0xB03A2E),
  d: hex(0x4A4A52), R: hex(0xA83A2C), h: hex(0x26262B), t: hex(0x2F4A3A),
  a: hex(0x9A7A4E), b: hex(0x4A4A52), f: hex(0x5A3F2A), y: hex(0x8A6A48),
  B: hex(0x8C4A32), D: hex(0x74391F), C: hex(0xB5382C), e: hex(0x9A9AA2),
};
/** The second boxcar is a different road's. */
export const ochre = { ...colors, B: hex(0xB8893C), D: hex(0x94692A) };

/** Where each car's left edge stands. */
export const engineX = 9, tenderX = 43, tankX = 62, box1X = 82, box2X = 104, cabooseX = 126;

// MARK: Drawing

export function wrap(x, period) {
  const m = x % period;
  return m < 0 ? m + period : m;
}

export function isNight(hour) {
  return hour >= 20 || hour < 5;
}

/**
 * On the Dale Creek trestle: from the stop, where the crossing is told, to the far end of
 * the gorge. Not on the way to it: the bridge is the stop's, and the train is not on it
 * until it has got there.
 */
export function onTrestle(J, f) {
  const g = f.state;
  if (!g || f.atPort) return false;
  const dale = J.stops.find((s) => s.id === 'dalecreek');
  if (!dale) return false;
  return J.stops[g.stopIndex]?.id === dale.id && g.mile >= dale.mile && g.mile <= dale.mile + 3;
}

export function draw(J, px, f) {
  const s = palette(f.weather);
  const t = f.t, w = px.w, h = px.h, hz = horizon;
  const night = isNight(f.hour);
  const blizzard = f.weather.sky === 'snow' && f.weather.harsh > 1;
  const id = f.region?.id ?? 'platte';
  // How far the country has slid past, in pixels at the track.
  const scroll = f.moving ? t * 34 * Math.max(0.35, Math.min(1.2, f.weather.speed)) : 0;
  const tint = (c) => PixelCanvas.mix(c, s.tint, s.amount);
  const water = hex(s.water);

  px.sky(s.top, s.bot, hz);
  if (s.sun !== null && !night) {
    const across = Math.max(0, Math.min(14, f.hour - 5)) / 14;
    px.sun(138 - across * 122, 5 + Math.abs(f.hour - 12) * 2.2, hex(s.sun));
  }
  px.clouds(s.clouds * 2, hex(s.cloud), t, f.weather.sky === 'breeze' ? -3 : -0.5);

  const trestle = onTrestle(J, f);
  far(px, id, scroll * 0.12, tint);
  px.rect(0, hz, w, h - hz, tint(trestle ? 0x55634F : ground(id)));
  if (trestle) {
    gorge(px, scroll, tint, water);
  } else {
    middle(px, id, scroll * 0.35, tint, water);
    if (f.atPort) yard(px, tint);
    else poles(px, scroll);
    if (id === 'sierra' && !f.atPort) shedBack(px, scroll);
    roadbed(px, id, scroll, tint);
  }

  train(J, px, f, night);
  smoke(px, f, night);

  if (!trestle) {
    near(px, id, scroll * 1.5, tint, water);
    if (id === 'sierra' && !f.atPort) shedFront(px, scroll);
  }
  if (blizzard) {
    // Drifts over the rails and a second fall of snow, driven.
    for (let i = 0; i < 9; i++) {
      const x = wrap(i * 23 + scroll, w + 20) - 10;
      px.rect(Math.floor(x), rail - 1, 12, 2, hex(0xF4F7FA));
    }
    px.rect(0, 0, w, h, opacity(white, 0.22));
    px.snow(t * 2.3 + 40);
  }
  if (f.weather.sky === 'breeze') wind(px, t);
  if (f.weather.sky === 'heat') shimmer(px, t);
  px.air(f.weather.sky, t);

  if (night) {
    px.rect(0, 0, w, h, opacity(hex(0x070B1C), 0.62));
    lights(px, f, s.sun !== null);
  } else if (f.hour >= 17 && f.hour < 20) {
    px.rect(0, 0, w, h, opacity(hex(0xE0703A), 0.16));
  } else if (f.hour === 5) {
    px.rect(0, 0, w, h, opacity(hex(0xE8A0A8), 0.14));
  }
}

// MARK: Country

/** The ground at the track, by region. */
export function ground(id) {
  switch (id) {
    case 'platte': return 0x7C9A4A;
    case 'highplains': return 0xB4A45A;
    case 'sherman': return 0x8E8A64;
    case 'laramie': return 0x9AA05C;
    case 'reddesert': return 0xC07A4A;
    case 'wasatch': return 0x9A7A52;
    case 'saltdesert': return 0xE2DFD2;
    case 'humboldt': return 0x9A9A6C;
    case 'fortymile': return 0xD2C8A8;
    case 'truckee': return 0x74A050;
    case 'eastslope': return 0x6E8456;
    case 'sierra': return 0x8A9484;
    case 'valley': return 0x7DAA4C;
    default: return 0x7C9A4A;
  }
}

/** What stands on the horizon. */
export function far(px, id, scroll, tint) {
  const hz = horizon;
  const ridge = (color, snow, height) => {
    px.hills(0, px.w, hz, tint(color), (x) => height(x - scroll));
    if (snow == null) return;
    // Snow on whatever stands above the line.
    for (let i = 0; i < px.w; i++) {
      const hh = jsRounded(height(i - scroll));
      if (hh > snow) px.rect(i, hz - hh, 1, Math.min(4, hh - snow), hex(0xF4F7FA));
    }
  };
  const sin = Math.sin;
  switch (id) {
    case 'highplains':
      ridge(0x9C8F5E, null, (x) => (sin(x * 0.03) > 0.55 ? 5 : 1.5 + sin(x * 0.11)));
      break;
    case 'sherman':
      ridge(0x7D776E, null, (x) => 10 + 6 * sin(x * 0.07) + 3 * sin(x * 0.19));
      break;
    case 'laramie':
      ridge(0x6A7C96, 8, (x) => 7 + 4 * sin(x * 0.05) + 2 * sin(x * 0.13));
      break;
    case 'reddesert':
      ridge(0xA5553A, null, (x) => {
        const m = sin(x * 0.04);
        return m > 0.3 ? 10 : m > -0.2 ? 4 : 1;
      });
      break;
    case 'wasatch':
      ridge(0x9B4B33, null, (x) => 27 + 8 * sin(x * 0.05) + 4 * sin(x * 0.21));
      ridge(0x7E3A28, null, (x) => 15 + 6 * sin(x * 0.05 + 0.6) + 3 * sin(x * 0.21));
      break;
    case 'saltdesert':
      ridge(0x8C93B0, null, (x) => 4 + 2 * sin(x * 0.06) + sin(x * 0.17));
      break;
    case 'humboldt':
      ridge(0x8A7458, null, (x) => 7 + 4 * sin(x * 0.045) + 2 * sin(x * 0.17));
      break;
    case 'fortymile':
      ridge(0x6E6258, null, (x) => 5 + 3 * sin(x * 0.05) + sin(x * 0.21));
      break;
    case 'truckee':
      ridge(0x5E6E86, 22, (x) => 20 + 7 * sin(x * 0.045) + 4 * sin(x * 0.15));
      ridge(0x2F5A3A, null, (x) => 6 + 2 * sin(x * 0.12));
      break;
    case 'eastslope':
      ridge(0x77808C, 30, (x) => 28 + 8 * sin(x * 0.04 + 1) + 4 * sin(x * 0.17));
      ridge(0x2E5237, null, (x) => 17 + 7 * sin(x * 0.05) + 3 * sin(x * 0.23));
      break;
    case 'sierra':
      ridge(0x8A8F9A, 24, (x) => 28 + 9 * sin(x * 0.05) + 5 * sin(x * 0.19));
      ridge(0x34573E, null, (x) => 9 + 4 * sin(x * 0.08) + 2 * sin(x * 0.29));
      break;
    case 'valley':
      ridge(0x7C92A8, null, (x) => 4 + 2 * sin(x * 0.05) + sin(x * 0.13));
      break;
    default:
      ridge(0x6E8A5A, null, (x) => 2 + 1.5 * sin(x * 0.05));
  }
}

/** `n` things spread along the line, each asked to draw itself at its x. */
function scatterer(px, scroll) {
  return (n, every, seed, put) => {
    for (let i = 0; i < n; i++) {
      const x = wrap(i * every + seed + scroll, px.w + 24) - 12;
      put(Math.floor(x), i);
    }
  };
}

/** Between the horizon and the track: rivers, trees, rock. */
export function middle(px, id, scroll, tint, water) {
  const hz = horizon, w = px.w;
  const scatter = scatterer(px, scroll);
  switch (id) {
    case 'highplains':
      scatter(9, 21, 5, (x, i) => px.rect(x, hz + 3 + (i % 4) * 3, 3, 1, tint(0xD8C878)));
      break;
    case 'sherman':
      scatter(5, 39, 8, (x, i) => {
        px.rect(x, hz + 4 + (i % 2) * 5, 6, 3, tint(0x9A948A));
        px.rect(x + 1, hz + 2 + (i % 2) * 5, 4, 2, tint(0xB0AAA0));
      });
      scatter(3, 61, 30, (x) => pine(px, x, hz + 4, tint));
      break;
    case 'laramie':
      scatter(8, 23, 3, (x, i) => px.rect(x, hz + 2 + (i % 5) * 3, 4, 1, tint(0xC8C070)));
      break;
    case 'reddesert':
      scatter(8, 23, 9, (x, i) => px.rect(x, hz + 3 + (i % 4) * 3, 2, 2, tint(0x7E8A66)));
      scatter(2, 92, 40, (x) => {
        px.rect(x, hz + 2, 9, 4, tint(0x9A4A32));
        px.rect(x + 2, hz, 5, 2, tint(0x9A4A32));
      });
      break;
    case 'wasatch':
      scatter(6, 31, 6, (x, i) => pine(px, x, hz + 3 + (i % 3) * 3, tint));
      break;
    case 'saltdesert':
      px.rect(0, hz + 1, w, 2, PixelCanvas.mix(0xB8D4E0, 0xE2DFD2, 0.25));
      scatter(10, 19, 2, (x, i) => px.rect(x, hz + 5 + (i % 4) * 3, 5, 1, hex(0xF6F4EC)));
      break;
    case 'fortymile':
      scatter(7, 27, 4, (x, i) => px.rect(x, hz + 3 + (i % 4) * 4, 7, 1, hex(0xEEE8D4)));
      scatter(4, 47, 19, (x, i) => px.rect(x, hz + 8 + (i % 2) * 5, 3, 2, tint(0x7A7064)));
      break;
    case 'truckee':
    case 'humboldt':
    case 'platte':
    case 'valley': {
      // A river running with the line, sandbars or willows along it.
      const y = id === 'humboldt' ? hz + 6 : hz + 3;
      const green = id === 'humboldt' ? 0x6E9450 : id === 'valley' ? 0x4E8A3E : 0x5E9048;
      px.rect(0, y - 1, w, 1, tint(green));
      px.rect(0, y, w, id === 'platte' ? 5 : 3, water);
      px.rect(0, y + (id === 'platte' ? 5 : 3), w, 1, tint(green));
      if (id === 'platte') {
        scatter(5, 41, 12, (x, i) => px.rect(x, y + 1 + (i % 3), 11, 1, tint(0xD8C690)));
      }
      scatter(id === 'humboldt' ? 6 : 4, id === 'humboldt' ? 33 : 47, 17, (x, i) => {
        if (id === 'valley') oak(px, x, y - 1, tint);
        else bush(px, x, y - (i % 2 === 0 ? 1 : -4), tint, green);
      });
      if (id === 'valley') {
        scatter(4, 46, 2, (x, i) => px.rect(x, hz + 10 + (i % 2) * 4, 22, 2, tint(0xD8B84A)));
      }
      if (id === 'truckee') {
        scatter(3, 63, 28, (x) => pine(px, x, hz + 11, tint));
      }
      break;
    }
    case 'eastslope':
    case 'sierra':
      scatter(7, 27, 5, (x, i) => pine(px, x, hz + 2 + (i % 3) * 4, tint));
      scatter(3, 67, 44, (x) => {
        px.rect(x, hz + 9, 7, 3, tint(0xA8A8AC));
        px.rect(x + 1, hz + 8, 4, 1, hex(0xF4F7FA));
      });
      break;
    default:
      break;
  }
}

/** In front of the track. */
export function near(px, id, scroll, tint, water) {
  const w = px.w, h = px.h;
  const scatter = scatterer(px, scroll);
  switch (id) {
    case 'wasatch':
    case 'eastslope':
      // The river the grade was cut beside.
      px.rect(0, 71, w, h - 71, water);
      px.rect(0, 70, w, 1, tint(0x5E7A48));
      scatter(6, 31, 3, (x, i) => px.rect(x, 73 + (i % 3) * 2, 6, 1, opacity(white, 0.7)));
      scatter(3, 71, 20, (x) => px.rect(x, 71, 5, 2, tint(0x8A8378)));
      break;
    case 'saltdesert':
    case 'fortymile':
      scatter(6, 33, 7, (x, i) => px.rect(x, 68 + (i % 3) * 4, 9, 1, hex(0xF6F4EC)));
      break;
    case 'reddesert':
    case 'humboldt':
      scatter(7, 27, 5, (x, i) => {
        px.rect(x, 68 + (i % 3) * 4, 3, 2, tint(0x7E8A66));
        px.rect(x + 1, 67 + (i % 3) * 4, 1, 1, tint(0x98A47E));
      });
      break;
    case 'sherman':
    case 'sierra':
      scatter(4, 47, 9, (x, i) => {
        px.rect(x, 69 + (i % 2) * 5, 6, 3, tint(0x9A948A));
        px.rect(x + 1, 68 + (i % 2) * 5, 3, 1, tint(0xB8B2A8));
      });
      break;
    case 'valley':
      scatter(5, 37, 4, (x, i) => px.rect(x, 68 + (i % 2) * 6, 18, 2, tint(0xD8B84A)));
      scatter(8, 23, 11, (x, i) => px.rect(x, 72 + (i % 3) * 2, 1, 2, tint(0x4E8A3E)));
      break;
    default: {
      // Grass, in tufts.
      const blade = id === 'highplains' || id === 'laramie' ? 0xD8C878 : 0x4E7A36;
      scatter(11, 17, 6, (x, i) => {
        px.rect(x, 68 + (i % 4) * 3, 1, 2, tint(blade));
        px.rect(x + 2, 69 + (i % 4) * 3, 1, 1, tint(blade));
      });
    }
  }
}

export function pine(px, x, base, tint) {
  const c = tint(0x24482E);
  px.rect(x + 2, base - 8, 1, 2, c);
  px.rect(x + 1, base - 6, 3, 2, c);
  px.rect(x, base - 4, 5, 3, c);
  px.rect(x + 2, base - 1, 1, 1, hex(0x4A2E1A));
}

export function oak(px, x, base, tint) {
  const c = tint(0x3E6E34);
  px.rect(x + 1, base - 6, 5, 1, c);
  px.rect(x, base - 5, 7, 3, c);
  px.rect(x + 3, base - 2, 1, 2, hex(0x4A2E1A));
}

export function bush(px, x, base, tint, color) {
  px.rect(x + 1, base - 3, 4, 1, tint(color));
  px.rect(x, base - 2, 6, 2, tint(color));
}

/** Ballast, ties and the rail. */
export function roadbed(px, id, scroll, tint) {
  const w = px.w;
  px.rect(0, rail, w, 4, tint(0x8A8070));
  for (let i = 0; i < 28; i++) {
    const x = wrap(i * 6 + scroll, w + 6) - 3;
    px.rect(Math.floor(x), rail + 1, 2, 2, hex(0x4A3626));
  }
  px.rect(0, rail, w, 1, hex(0x2A2A30));
}

/** The telegraph, which came west with the rails. */
export function poles(px, scroll) {
  const c = hex(0x5A4632);
  for (let i = 0; i < 3; i++) {
    const x = Math.floor(wrap(i * 72 + 30 + scroll, px.w + 56) - 28);
    px.rect(x, 37, 1, 25, c);
    px.rect(x - 2, 38, 5, 1, c);
  }
}

/** A yard: the water tank ahead of the engine, the depot behind the cars, cordwood. */
export function yard(px, tint) {
  const wood = hex(0x8A6A48), dark = hex(0x4A2E1A);
  // The depot: board walls, a wide roof, a chimney, a signboard.
  px.rect(96, 36, 50, 26, tint(0xC8B080));
  px.rect(92, 31, 58, 5, tint(0x7A3A2A));
  px.rect(96, 29, 50, 2, tint(0x7A3A2A));
  px.rect(134, 24, 4, 6, tint(0x8A8378));
  px.rect(112, 38, 18, 5, hex(0xF0E8D0));
  px.rect(114, 40, 14, 1, dark);
  for (let i = 0; i < 4; i++) px.rect(100 + i * 12, 44, 6, 5, hex(0x4A6A86));
  px.rect(88, 60, 66, 2, wood);
  // The tank: a tub on legs behind the engine, its spout swung down over the tender.
  px.polygon([{ x: 23, y: 18 }, { x: 30, y: 14 }, { x: 31, y: 14 }, { x: 38, y: 18 }], dark);
  px.rect(22, 18, 17, 14, wood);
  for (let i = 0; i < 3; i++) px.rect(22, 21 + i * 4, 17, 1, dark);
  for (const x of [24, 30, 36]) px.rect(x, 32, 1, 30, dark);
  px.line({ x: 24, y: 34 }, { x: 36, y: 44 }, dark);
  px.line({ x: 36, y: 34 }, { x: 24, y: 44 }, dark);
  px.line({ x: 39, y: 29 }, { x: 48, y: 41 }, dark);
  px.rect(47, 41, 2, 3, dark);
  // Cordwood, stacked for sale.
  for (let r = 0; r < 3; r++) {
    px.rect(137 + r, 73 - r * 2, 18 - r * 2, 2, r % 2 === 0 ? wood : dark);
  }
  px.rect(134, 75, 24, 1, dark);
}

/** The Dale Creek trestle: timber bents down to a creek a long way below. */
export function gorge(px, scroll, tint, water) {
  const w = px.w, h = px.h;
  const timber = hex(0x6B4A2B), dark = hex(0x4A2E1A);
  px.hills(0, w, h, tint(0x6E7466), (x) => 9 + 5 * Math.sin((x - scroll * 0.3) * 0.06));
  px.rect(0, h - 4, w, 4, water);
  for (let i = 0; i < 5; i++) {
    const x = wrap(i * 37 + 5 + scroll * 0.3, w + 20) - 10;
    px.rect(Math.floor(x), h - 4, 5, 2, tint(0x8A8378));
  }
  for (let i = 0; i < 9; i++) {
    const x = Math.floor(wrap(i * 20 + scroll, w + 20) - 10);
    px.rect(x, rail + 3, 1, h - rail - 5, timber);
    px.rect(x + 5, rail + 3, 1, h - rail - 5, timber);
    px.line({ x, y: rail + 4 }, { x: x + 6, y: rail + 10 }, dark);
    px.line({ x: x + 6, y: rail + 4 }, { x, y: rail + 10 }, dark);
    px.rect(x - 1, rail + 10, 8, 1, timber);
  }
  px.rect(0, rail + 6, w, 1, dark);
  px.rect(0, rail, w, 3, timber);
  px.rect(0, rail, w, 1, hex(0x2A2A30));
}

export const shedLength = 74;

export function shedX(scroll) {
  return Math.floor(wrap(150 + scroll, 250) - 80);
}

/** A snowshed's far wall, behind the train. */
export function shedBack(px, scroll) {
  const x = shedX(scroll);
  px.rect(x, 45, shedLength, rail - 45, hex(0x4A3626));
  for (let i = 0; i < 9; i++) px.rect(x + 4 + i * 8, 45, 1, rail - 45, hex(0x3A2A1E));
}

/** Its roof and the posts of the open side, in front. */
export function shedFront(px, scroll) {
  const x = shedX(scroll);
  const timber = hex(0x7A5A38);
  px.polygon([{ x: x - 3, y: 46 }, { x: x + 4, y: 41 }, { x: x + shedLength - 4, y: 41 }, { x: x + shedLength + 3, y: 46 }],
    timber);
  px.rect(x, 40, shedLength, 2, hex(0xF4F7FA));
  px.rect(x - 2, 45, shedLength + 4, 2, hex(0x5A4028));
  for (let i = 0; i < 8; i++) px.rect(x + 1 + i * 10.3, 47, 2, rail - 46, timber);
}

// MARK: Train, smoke, lights

export function train(J, px, f, night) {
  const t = f.t;
  // Boards go missing as the running gear wears, each broken off part way down, and the
  // dark of the car shows through.
  const gaps = Math.max(0, 60 - f.hull) / 13;
  const holed = (col, r, ch) => (ch === 'B' || ch === 'D' || ch === 'C') && ((col * 7) % 13) < gaps && r >= 3 + (col * 5) % 4;
  const inside = hex(0x1E1612);
  const stand = (rows, x, { sag = 0, c = colors, skip = () => false } = {}) => {
    px.sprite(rows, x, rail - rows.length + sag, c, skip);
  };
  // Couplings.
  for (const x of [tenderX, tankX, box1X, box2X, cabooseX]) px.rect(x - 3, rail - 4, 4, 1, hex(0x26262B));

  px.rect(box1X, rail - 10, 20, 6, inside);
  px.rect(box2X, rail - 10, 20, 6, inside);
  px.rect(cabooseX + 1, rail - 10, 15, 6, inside);
  stand(caboose, cabooseX, { sag: f.hull < 30 ? 1 : 0, skip: holed });
  stand(boxcar, box2X, { c: ochre, skip: holed });
  stand(boxcar, box1X, { skip: holed });
  stand(tankCar, tankX);
  stand(tender, tenderX);
  // Cordwood on the tender, as much as is left.
  const cap = J.items.find((i) => i.key === 'fuel')?.cap ?? 0;
  const stock = f.state ? (cap > 0 ? f.state.fuel / cap : 1) : 1;
  const rows = stock > 0.6 ? 3 : stock > 0.3 ? 2 : stock > 0.03 ? 1 : 0;
  for (let r = 0; r < rows; r++) {
    const inset = r;
    px.rect(tenderX + 1 + inset, rail - 11 - r, 15 - inset * 2, 1, hex(r % 2 === 0 ? 0xB08A5A : 0x8C6B42));
  }
  stand(engine, engineX);
  // Rust on the boiler as the engine wears.
  const rust = Math.max(0, 60 - f.sails) / 2.4;
  if (rust > 0) {
    px.sprite(engine, engineX, rail - engine.length, { k: hex(0x7A4A2A) },
      (col, r) => r < 6 || ((col * 11 + r * 17) % 37) >= rust);
  }
  // The rods, going round.
  const turn = f.moving ? Math.floor(t * 7) % 2 : 0;
  px.rect(engineX + 10, rail - 4 + turn, 16, 1, hex(0xC8C8D0));

  if (f.hull < 60) {
    // A hot box: a journal glowing under the first boxcar, and more as it worsens.
    const glow = hex(Math.floor(t * 5) % 2 === 0 ? 0xFF9A3A : 0xFFD27A);
    px.rect(box1X + 17, rail - 2, 1, 1, glow);
    wisp(px, box1X + 17, rail - 4, t, hex(0x6A6A70));
    if (f.hull < 30) {
      px.rect(box2X + 2, rail - 2, 1, 1, glow);
      wisp(px, box2X + 2, rail - 4, t + 1.7, hex(0x6A6A70));
    }
  }
  if (f.sails < 60) {
    // Steam getting out where it should not.
    const steam = hex(0xF4F7FA);
    wisp(px, engineX + 17, rail - 14, t * 1.3, steam);
    px.rect(engineX + 3, rail - 4, 2, 1, opacity(steam, 0.8));
    if (f.sails < 30) {
      wisp(px, engineX + 12, rail - 12, t * 1.3 + 0.9, steam);
      wisp(px, engineX + 6, rail - 6, t * 1.1 + 2.1, steam);
    }
  }
}

/** A thin thread of smoke or steam rising from a point. */
export function wisp(px, x, y, t, color) {
  for (let i = 0; i < 4; i++) {
    const p = wrap(t * 0.9 + i * 0.25, 1);
    px.rect(Math.floor(x + Math.sin(t * 2 + i) * 1.5 + p * 3), Math.floor(y - p * 7), 1 + (p > 0.5 ? 1 : 0), 1,
      opacity(color, 0.9 - p * 0.7));
  }
}

/**
 * Wood smoke from the balloon stack: streaming back over the cars under way, standing
 * straight up at rest, thin and dark from an engine in a bad way.
 */
export function smoke(px, f, night) {
  const t = f.t;
  const x0 = engineX + 9, y0 = rail - engine.length - 1;
  const sick = f.sails < 30;
  const color = sick ? 0x4A4A50 : 0xE4E4E0;
  const puffs = sick ? 5 : 8;
  // A head wind lays it flat.
  const lift = f.weather.sky === 'breeze' ? 7 : 15;
  for (let i = 0; i < puffs; i++) {
    const p = wrap(t * (f.moving ? 0.55 : 0.3) + i / puffs, 1);
    const size = Math.floor(2 + p * 5);
    const back = f.moving ? p * 78 : p * 6 + Math.sin(t + i) * 1.5;
    const x = Math.floor(x0 + back - size / 2), y = Math.floor(y0 - p * lift - size / 2);
    px.rect(x, y, size, Math.max(2, size - 1), opacity(hex(color), 0.85 - p * 0.65));
  }
}

/**
 * What shows in the dark: stars, a moon in a clear sky, the headlamp and its beam,
 * lamplight in the cab and the caboose, the fire.
 */
export function lights(px, f, clear) {
  const lamp = hex(0xFFE27A);
  if (clear) {
    for (let i = 0; i < 16; i++) {
      px.rect((i * 37 + 11) % 160, (i * 23 + 5) % 38, 1, 1, opacity(white, i % 3 === 0 ? 0.9 : 0.55));
    }
    px.moon(124, 7, hex(0xF2EED8), hex(0x141B33));
  }
  const top = rail - engine.length;
  px.polygon([{ x: engineX + 4, y: top + 4 }, { x: 0, y: top - 4 }, { x: 0, y: rail + 2 }, { x: engineX + 4, y: top + 6 }],
    opacity(lamp, 0.22));
  px.rect(engineX + 3, top + 4, 2, 2, lamp);
  for (const x of [engineX + 24, engineX + 28]) px.rect(x, top + 4, 2, 2, lamp);
  px.rect(engineX + 20, rail - 5, 2, 1, hex(0xFF8A3A));
  const c = rail - caboose.length + (f.hull < 30 ? 1 : 0);
  for (const x of [cabooseX + 3, cabooseX + 12]) px.rect(x, c + 4, 2, 2, lamp);
  px.rect(cabooseX + 7, c + 1, 1, 1, lamp);
  px.rect(cabooseX + 9, c + 1, 1, 1, lamp);
  if (f.atPort) {
    for (let i = 0; i < 4; i++) px.rect(100 + i * 12, 44, 6, 5, opacity(lamp, 0.85));
  }
}

/** A head wind: streaks coming down the train. */
export function wind(px, t) {
  for (let i = 0; i < 9; i++) {
    const x = wrap(i * 47 + t * (120 + i * 9), px.w + 30) - 15;
    px.rect(Math.floor(x), 8 + PixelCanvas.mod(i * 23, 62), 9 + PixelCanvas.mod(i * 5, 8), 1, opacity(white, 0.35));
  }
}

/** Heat coming off the ground. */
export function shimmer(px, t) {
  for (let i = 0; i < 10; i++) {
    const x = wrap(i * 31 + Math.sin(t * 1.3 + i) * 4, px.w);
    px.rect(Math.floor(x), horizon - 1 + PixelCanvas.mod(i * 7, 5), 10, 1, opacity(hex(0xFFF6C8), 0.3));
  }
}

// MARK: VoiceOver

/** What the picture shows, for a screen reader. */
export function label(J, f) {
  if (!f.state) return 'A wood-burning freight train on the prairie';
  if (f.atPort) return 'The train standing in the yard, by the water tank and the depot';
  const weather = f.weather.name.toLowerCase();
  if (onTrestle(J, f)) return `The train on the Dale Creek trestle. Weather: ${weather}`;
  let country = f.region?.name ?? 'open country';
  if (country.startsWith('The ')) country = 'the ' + country.slice(4);
  const hour = isNight(f.hour) ? ' by night' : '';
  return `The train ${f.moving ? 'rolling through' : 'stopped in'} ${country}${hour}. Weather: ${weather}`;
}
