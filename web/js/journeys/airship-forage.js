// Reading the winds (AroundTheHorn/Journeys/AirshipForage.swift): the field is upside down
// from 1849's. The meteorologist stands on the roof hatch of the control car at the bottom
// of a 160×200 sky, beside a theodolite, and sends pilot balloons up from (80, 172) at the
// winds crossing overhead. What a balloon finds is petrol the ship need not burn, counted by
// the shell (fishing.js `reward`).

import { PixelCanvas, Theme, hex, opacity, jsRounded } from '../pixels.js';

export const hand = { x: 80, y: 172 };
/** Where the theodolite's eyepiece is: the sight line runs from here to the balloon. */
export const eyepiece = { x: 86, y: 181 };

/**
 * The sky darkening upward, thin wisps of cloud, and at the bottom the roof of the
 * control car, the meteorologist in a red scarf, and the theodolite on its tripod.
 */
export function backdrop(px, now) {
  const w = 160;
  px.bands(0x1F4E86, 0xBFE0F2, 0, 20, 10);
  for (let i = 0; i < 3; i++) {
    const x = PixelCanvas.mod(i * 61 + now * (4 + i * 2), w + 40) - 30;
    const y = 30 + i * 47;
    px.rect(Math.floor(x), y, 26, 2, opacity(hex(0xF4F7FA), 0.2));
    px.rect(Math.floor(x + 6), y - 1, 12, 1, opacity(hex(0xF4F7FA), 0.2));
  }
  // The control car's roof and its windows.
  px.rect(66, 188, 29, 8, hex(0x6B4A2B));
  px.rect(64, 187, 33, 1, hex(0x4A2E1A));
  for (let i = 0; i < 5; i++) px.rect(68 + i * 6, 191, 3, 3, hex(0xF2D16B));
  // The meteorologist, one arm up to let the balloon go.
  const coat = hex(0x3A4A5E);
  px.rect(78, 178, 4, 9, coat);
  px.rect(78, 187, 1, 1, coat);
  px.rect(81, 187, 1, 1, coat);
  px.rect(78, 177, 4, 1, hex(0xD64545));
  px.rect(79, 174, 3, 3, hex(0xEFD6B0));
  px.rect(78, 173, 5, 1, hex(0x5A4632));
  px.rect(79, 172, 3, 1, hex(0x5A4632));
  px.rect(77, 175, 1, 4, coat);
  // The theodolite on its tripod.
  const brass = hex(0xECE4CF);
  px.rect(84, 180, 5, 3, brass);
  px.rect(88, 181, 2, 1, brass);
  px.line({ x: 86, y: 183 }, { x: 83, y: 187 }, brass);
  px.line({ x: 86, y: 183 }, { x: 89, y: 187 }, brass);
  px.rect(86, 183, 1, 4, brass);
}

/** The red balloon, its string, and the dotted sight line back to the theodolite. */
export function balloon(px, b) {
  const x = jsRounded(b.x), y = jsRounded(b.y);
  const dx = x - eyepiece.x, dy = y - eyepiece.y;
  const steps = Math.trunc(Math.hypot(dx, dy) / 3);
  for (let k = 1; k < Math.max(2, steps); k++) {
    const f = k / Math.max(2, steps);
    px.rect(jsRounded(eyepiece.x + dx * f), jsRounded(eyepiece.y + dy * f), 1, 1, opacity(Theme.ink, 0.6));
  }
  const red = hex(0xD64545);
  px.rect(x - 1, y - 1, 3, 3, red);
  px.rect(x, y - 2, 1, 1, red);
  px.rect(x - 1, y - 1, 1, 1, hex(0xF08A7A));
  px.rect(x, y + 2, 1, 2, opacity(Theme.ink, 0.7));
}

/**
 * A wind as the theodolite shows it: two or three rows of dashes in its colour, running
 * the way it blows; the widest, a river of air, trails a long streak behind it.
 */
export function wind(px, f) {
  const x = jsRounded(f.x), y = jsRounded(f.y);
  const w = f.kind.width, h = f.kind.height;
  const hw = Math.trunc(w / 2), hh = Math.trunc(h / 2);
  const parsed = /^#[0-9A-Fa-f]{6}$/.test(f.kind.color) ? parseInt(f.kind.color.slice(1), 16) : null;
  const color = parsed ?? 0xCFE8F5;
  const c = hex(color);
  const left = x - hw, top = y - hh;
  const rows = h >= 5 ? 3 : 2;
  const gap = rows === 3 ? (h - 1) / 2 : h - 1;
  const right = f.vx > 0;
  // The dashes shuffle along as it goes, so a wind reads as moving air.
  const phase = Math.trunc(PixelCanvas.mod(Math.abs(f.x) / 2, 4));
  for (let r = 0; r < rows; r++) {
    const ry = Math.floor(top + r * gap);
    const inset = (r * 3 + phase) % 4;
    let dx = inset;
    while (dx < w) {
      const len = Math.min(3 + (r % 2), w - dx);
      px.rect(left + dx, ry, len, 1, c);
      dx += len + 2;
    }
  }
  // Its leading edge, a little brighter.
  const lead = right ? left + w - 1 : left;
  px.rect(lead, top + gap / 2, 1, Math.max(1, gap), PixelCanvas.mix(color, 0xFFFFFF, 0.4));
  if (w >= 28) {
    const tail = right ? left - 6 : left + w;
    px.rect(tail, y, 6, 1, opacity(c, 0.6));
  }
}

/** The ForageSkin, for the journey's tables `J` (what petrol is called). */
export function forage(J) {
  const petrol = J.items.find((i) => i.key === 'fuel');
  return {
    field: { w: 160, h: 200, origin: hand, upward: true, line: 170, lanes: [12, 155], speed: 150, oneWay: false },
    heading: 'Reading the winds',
    throwsLabel: 'Balloons',
    caughtLabel: 'Found',
    timeLabel: 'Time',
    grouped: true,
    hint: (limit) => `Tap the sky to send up a pilot balloon and follow it through the theodolite. Each one goes for good. The navigator can plan around winds worth up to ${limit} of petrol in one session.`,
    label: (n) => `The sky above the control car, with ${n} ${n === 1 ? 'wind' : 'winds'} crossing it`,
    actionHint: 'Double-tap to send a balloon up at the nearest wind',
    leave: 'Back to the chart table',
    pop: (n, w) => `+${n} ${n === '1' ? petrol.one : petrol.unit}, ${w.name}`,
    backdrop,
    quarry: wind,
    thrown: balloon,
  };
}
