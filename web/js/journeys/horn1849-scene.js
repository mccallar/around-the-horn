// 1849's scene (AroundTheHorn/Journeys/Horn1849Scene.swift), a port of the prototype's
// `drawScene`: a ship on the sea under ten skies, a hillside town in port, sails that
// tear as they wear.

import { PixelCanvas, hex, jsRounded } from '../pixels.js';

export const horizon = 46;

/**
 * The prototype's `SKY`, by the kind of sky. Light airs and a dead calm are both `still`;
 * the calm is the one that all but stops the ship.
 */
export function palette(w) {
  const P = (o) => ({ sun: null, clouds: 0, cloud: 0xF4F7FA, still: false, rough: 1, ...o });
  switch (w.sky) {
    case 'clear': return P({ top: 0x2D5F9A, bot: 0x9FD0EE, sea: 0x1D4E7A, wave: 0x7FB8DE, sun: 0xFFE27A, clouds: 1 });
    case 'breeze': return P({ top: 0x2A5C98, bot: 0xA8D8F0, sea: 0x1A4A78, wave: 0xE9F4FB, sun: 0xFFE27A, clouds: 2 });
    case 'still':
      return w.speed < 0.1
        ? P({ top: 0xD9893F, bot: 0xF6D78B, sea: 0x3C6F88, wave: 0x9FC6CF, sun: 0xFFF1B0, still: true })
        : P({ top: 0x3A6AA2, bot: 0xB6DCF0, sea: 0x22557F, wave: 0x8CC0E0, sun: 0xFFE27A, clouds: 1 });
    case 'heat': return P({ top: 0xE07A3A, bot: 0xF8D27A, sea: 0x3C6F88, wave: 0xA7CBD0, sun: 0xFFF6C8, still: true });
    case 'rain': return P({ top: 0x3E4A5A, bot: 0x7D8A98, sea: 0x24394E, wave: 0x8AA0B4, clouds: 3, cloud: 0x6B7685 });
    case 'fog': return P({ top: 0x8D969E, bot: 0xC5CBD0, sea: 0x5F6F7C, wave: 0xB5BEC6 });
    case 'snow': return P({ top: 0x55606E, bot: 0xA6B2BF, sea: 0x2A3C4F, wave: 0xDFE8F0, clouds: 3, cloud: 0x8C97A3 });
    case 'gale': return P({ top: 0x33404F, bot: 0x6E7D8D, sea: 0x1F3346, wave: 0xE8EEF3, clouds: 3, cloud: 0x55616F, rough: 2 });
    case 'storm': return P({ top: 0x15191F, bot: 0x3A434F, sea: 0x121D29, wave: 0xC9D3DC, clouds: 3, cloud: 0x2C333D, rough: 3 });
    case 'dust': return P({ top: 0x2D5F9A, bot: 0x9FD0EE, sea: 0x1D4E7A, wave: 0x7FB8DE, sun: 0xFFE27A, clouds: 1 });
    default: throw new Error(`no palette for the sky ${w.sky}`);
  }
}

/** The prototype's `SHIP_SPR`, 26 wide. */
export const ship = [
  '           r              ',
  '           rrr            ',
  '    m      m       m      ',
  '   sss    sssss    ss     ',
  '  sssss  sssssss  ssss    ',
  '    m      m       m      ',
  '  sssss  sssssss  sssss   ',
  ' ssssss sssssssss ssssss  ',
  ' ssssss sssssssss ssssss  ',
  '    m      m       m      ',
  ' ssssss sssssssss sssssss ',
  ' ssssss sssssssss sssssss b',
  '    m      m       m    bb',
  'hh  m      m       m   hhh',
  'hhhhhhhhhhhhhhhhhhhhhhhhhh',
  ' hyyyyyyyyyyyyyyyyyyyyyyh ',
  '  hhhhhhhhhhhhhhhhhhhhhh  ',
  '   hhhhhhhhhhhhhhhhhhhh   ',
];

export const shipColors = {
  s: hex(0xEFE6CC), m: hex(0x6B4A2B), h: hex(0x4A2E1A),
  y: hex(0xD9A441), r: hex(0xD64545), b: hex(0x6B4A2B),
};

export function draw(px, f) {
  const s = palette(f.weather);
  const t = f.t, w = px.w, h = px.h, hz = horizon;
  px.sky(s.top, s.bot, hz);
  if (s.sun !== null) px.sun(123, 8, hex(s.sun));
  const spd = f.moving ? 14 * f.weather.speed + 2 : 1.5;
  px.clouds(s.clouds * 2, hex(s.cloud), t, f.moving ? 1.6 : 0.4);
  if (f.atPort) town(px);
  px.rect(0, hz, w, h - hz, hex(s.sea));
  const rough = s.rough;
  const wave = hex(s.wave);
  for (let row = 0; row < 8; row++) {
    const y = hz + 2 + row * 4;
    const rs = spd * (0.4 + row * 0.18) + (s.still ? 0 : 1);
    for (let i = 0; i < 7; i++) {
      let x = PixelCanvas.mod(i * 29 + row * 17 - t * rs, w);
      if (x < 0) x += w;
      const len = s.still ? 1 : 2 + ((i + row) % 3) + rough;
      const jitter = rough > 1 ? jsRounded(Math.sin(t * 3 + (i + row))) : 0;
      px.rect(Math.floor(x), y + jitter, len, 1, wave);
    }
  }
  const bob = jsRounded(Math.sin(t * (1.4 + rough * 0.7)) * (0.5 + rough * 0.5));
  px.sprite(ship, 44, hz - 14 + bob, shipColors,
    (col, r, ch) => ch === 's' && f.sails < 60 && ((col * 7 + r * 13) % 37) < (60 - f.sails) / 2.2);
  if (f.moving && !s.still) {
    for (let i = 0; i < 4; i++) {
      px.rect(66 + ((i * 5 + Math.floor(t * 8)) % 10), hz + 3 + (i % 2), 2, 1, wave);
    }
  }
  px.air(f.weather.sky, t);
}

/** The hillside and its seven houses, in port. */
export function town(px) {
  const hz = horizon;
  px.hills(92, 160, hz, hex(0x2F4A35), (x) => 11 + 7 * Math.sin(x * 0.09) + 4 * Math.sin(x * 0.23));
  for (let i = 0; i < 7; i++) {
    const bx = 104 + i * 8, bh = 3 + ((i * 5) % 4);
    px.rect(bx, hz - bh - 1, 5, bh + 1, hex(0xE9DFC8));
    px.rect(bx, hz - bh - 2, 5, 1, hex(0x9A3B2E));
  }
}

/** What the picture shows, for a screen reader. */
export function label(f) {
  if (!f.state) return 'A ship under sail';
  const w = f.weather.sky === 'storm' ? 'a storm' : f.weather.name.toLowerCase();
  if (f.atPort) return 'Ship at anchor below a hillside town';
  return f.moving ? `Ship sailing in ${w}` : `Ship hove to in ${w}`;
}
