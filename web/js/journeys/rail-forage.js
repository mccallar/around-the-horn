// Hauling driftwood (AroundTheHorn/Journeys/RailForage.swift): a river going by from left
// to right on a 160×200 field, the crew on the near bank at the bottom with the track
// behind them, and a grapnel thrown up from (80, 172) at whatever the current is carrying.
// What a piece is worth is counted by the shell (fishing.js `reward`): in cords, from the
// tenths of a cord the engine stores.

import { PixelCanvas, Theme, hex, opacity, white, rgb, jsRounded } from '../pixels.js';

export const bank = 160;
export const hand = { x: 80, y: 172 };

/**
 * The far bank and its willows, the river darkening toward the near side, the current,
 * and the near bank: sand, grass, the one who throws, and the track.
 */
export function backdrop(px, now) {
  const w = 160;
  px.rect(0, 0, w, 10, hex(0x5E8A44));
  px.rect(0, 10, w, 4, hex(0xC8B080));
  for (let i = 0; i < 7; i++) {
    const x = i * 25 + 6;
    px.rect(x, 3, 9, 5, hex(0x3E6E34));
    px.rect(x + 2, 1, 5, 2, hex(0x3E6E34));
  }
  px.bands(0x5A9AB4, 0x2A5A76, 14, 21, 7);
  // The current: streaks and the odd fleck of foam, all going the one way.
  for (let i = 0; i < 16; i++) {
    const x = PixelCanvas.mod(i * 47 + now * (22 + PixelCanvas.mod(i * 7, 16)), w + 30) - 15;
    px.rect(Math.floor(x), 18 + PixelCanvas.mod(i * 37, 138), 8 + PixelCanvas.mod(i * 3, 7), 1, opacity(white, 0.14));
  }
  for (let i = 0; i < 5; i++) {
    const x = PixelCanvas.mod(i * 71 + now * 30, w + 10) - 5;
    px.rect(Math.floor(x), 30 + i * 27, 2, 1, opacity(white, 0.55));
  }
  // The water's edge, lapping.
  for (let i = 0; i < 160; i += 6) {
    px.rect(i + jsRounded(Math.sin(now * 2.5 + i)), bank - 1, 3, 1, hex(0xD8ECF7));
  }
  px.rect(0, bank, w, 5, hex(0xC8B080));
  px.rect(0, bank + 5, w, 40 - 5, hex(0x6E9A4A));
  for (let i = 0; i < 12; i++) {
    px.rect(i * 14 + 3, bank + 9 + (i * 5) % 14, 1, 2, hex(0x4E7A36));
  }
  // The track the train is standing on.
  px.rect(0, 188, w, 8, hex(0x8A8070));
  for (let i = 0; i < 20; i++) px.rect(i * 8 + 2, 188, 3, 8, hex(0x4A3626));
  px.rect(0, 189, w, 1, hex(0x2A2A30));
  px.rect(0, 194, w, 1, hex(0x2A2A30));
  // What has been hauled out so far, and the one hauling.
  px.rect(102, 170, 16, 2, hex(0x8C6B42));
  px.rect(103, 168, 14, 2, hex(0xB08A5A));
  px.rect(105, 166, 10, 2, hex(0x8C6B42));
  px.rect(78, 173, 5, 6, hex(0x3A5A8A));
  px.rect(78, 179, 2, 4, hex(0x4A3626));
  px.rect(81, 179, 2, 4, hex(0x4A3626));
  px.rect(79, 170, 3, 3, hex(0xEFD6B0));
  px.rect(77, 169, 7, 1, hex(0x4A2E1A));
  px.rect(79, 167, 3, 2, hex(0x4A2E1A));
  // The rest of the line, coiled at their feet.
  px.rect(70, 181, 5, 1, hex(0xD8C8A0));
  px.rect(69, 182, 7, 1, hex(0xD8C8A0));
  px.rect(70, 183, 5, 1, hex(0xD8C8A0));
}

/** The line back to the hand, and the hooks. */
export function grapnel(px, h) {
  px.line({ x: hand.x + 0.5, y: hand.y }, { x: h.x, y: h.y }, opacity(hex(0xD8C8A0), 0.8));
  const x = jsRounded(h.x), y = jsRounded(h.y);
  const iron = hex(0xE4E4EA);
  px.rect(x - 2, y - 1, 5, 1, iron);
  px.rect(x - 2, y, 1, 2, iron);
  px.rect(x + 2, y, 1, 2, iron);
  px.rect(x, y - 1, 1, 4, Theme.amber);
}

/**
 * One piece of driftwood, by its size: a branch, a rail, a forked limb, a log with its
 * sawn end showing, a raft of ties.
 */
export function wood(px, f) {
  const x = jsRounded(f.x), y = jsRounded(f.y);
  const w = f.kind.width, h = f.kind.height;
  const hw = Math.trunc(w / 2), hh = Math.trunc(h / 2);
  const parsed = /^#[0-9A-Fa-f]{6}$/.test(f.kind.color) ? parseInt(f.kind.color.slice(1), 16) : null;
  const color = parsed ?? 0x8C6B42;
  const c = hex(color);
  const light = PixelCanvas.mix(color, 0xFFFFFF, 0.3), dark = PixelCanvas.mix(color, 0x000000, 0.4);
  const left = x - hw, top = y - hh;
  // The water it pushes aside.
  const lead = f.vx > 0 ? left + w : left - 3;
  px.rect(lead, y, 3, 1, opacity(white, 0.4));
  px.rect(left + 1, top + h, w - 2, 1, opacity(rgb(0, 0, 0), 0.18));
  if (h >= 7) {
    // Ties lashed side by side.
    for (let row = 0; row < h; row++) px.rect(left, top + row, w, 1, row % 2 === 0 ? c : dark);
    px.rect(left + 5, top, 1, h, light);
    px.rect(left + w - 6, top, 1, h, light);
  } else if (h >= 6) {
    px.rect(left, top, w, h, c);
    px.rect(left + 1, top, w - 2, 1, light);
    px.rect(left, top + h - 1, w, 1, dark);
    const end = f.vx > 0 ? left + w - 3 : left;
    px.rect(end, top + 1, 3, h - 2, light);
    px.rect(end + 1, top + 2, 1, h - 4, dark);
  } else if (h >= 4) {
    px.rect(left, top + 1, w, h - 2, c);
    px.rect(left, top + 1, w, 1, light);
    px.rect(left + 4, top, 1, 1, c);
    px.rect(left + 5, top - 1, 3, 1, c);
    px.rect(left + w - 5, top + h - 1, 3, 1, c);
    px.rect(left + w - 3, top + h, 2, 1, dark);
  } else if (w >= 12) {
    px.rect(left, top, w, 2, c);
    px.rect(left, top, w, 1, light);
    px.rect(left + 3, top, 1, 2, dark);
    px.rect(left + w - 4, top, 1, 2, dark);
  } else {
    px.rect(left, top + 1, w, 1, c);
    px.rect(left + 2, top, 2, 1, c);
    px.rect(left + w - 4, top + 2, 3, 1, c);
    px.rect(left + w - 1, top, 1, 1, light);
  }
}

/** The ForageSkin, for the journey's tables `J` (what a cord is called). */
export function forage(J) {
  const cord = J.items.find((i) => i.key === 'fuel');
  return {
    field: { w: 160, h: 200, origin: hand, upward: true, line: 156, lanes: [26, 146], speed: 150, oneWay: true },
    heading: 'Driftwood',
    throwsLabel: 'Casts',
    caughtLabel: 'Hauled',
    timeLabel: 'Time',
    hint: (limit) => `Tap the river to cast the grapnel. Each cast uses up line. The crew can cut and stack up to ${limit} at one stop.`,
    label: (n) => `The river from the bank, with ${n} pieces of driftwood going by`,
    actionHint: 'Double-tap to cast the grapnel at the nearest driftwood',
    leave: 'Back to the train',
    pop: (n, piece) => `+${n} ${n === '1' ? cord.one : cord.unit}, ${piece.name}`,
    backdrop,
    quarry: wood,
    thrown: grapnel,
  };
}
