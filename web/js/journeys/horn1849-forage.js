// 1849's fishing (AroundTheHorn/Journeys/Horn1849Forage.swift, spec §9): a boat at the top
// of a 160×200 sea, harpoons thrown down from (80, 28) at whatever swims below.

import { PixelCanvas, Theme, hex, hexString, opacity, rgb, white, jsRounded } from '../pixels.js';

/** A strip of sky, the water darkening with depth, shafts of light, ripples, and the boat. */
export function backdrop(px, now) {
  const ms = now * 1000;
  px.rect(0, 0, 160, 28, hex(0x9FD0EE));
  px.bands(0x1F6B96, 0x061A2B, 28, 18, 10);
  for (let i = 0; i < 4; i++) {
    px.rect(PixelCanvas.mod(i * 45 + ms / 80, 200) - 20, 28, 6, 172, opacity(white, 0.06));
  }
  for (let i = 0; i < 160; i += 6) {
    px.rect(i + jsRounded(Math.sin(ms / 400 + i)), 28, 3, 1, hex(0xD8ECF7));
  }
  px.rect(70, 24, 20, 4, hex(0x4A2E1A));
  px.rect(72, 28, 16, 1, hex(0x4A2E1A));
  px.rect(79, 18, 2, 6, hex(0xD64545));
  px.rect(79, 16, 2, 2, hex(0xEFD6B0));
}

/** The line back to the fisher's hand, the shaft, and the head. */
export function harpoon(px, h) {
  px.line({ x: 80.5, y: 24.5 }, { x: h.x, y: h.y }, opacity(rgb(236, 228, 207), 0.5));
  const a = Math.atan2(h.vy, h.vx);
  for (let k = 0; k < 6; k++) {
    px.rect(jsRounded(h.x - Math.cos(a) * k), jsRounded(h.y - Math.sin(a) * k), 1, 1, Theme.ink);
  }
  px.rect(jsRounded(h.x), jsRounded(h.y), 2, 2, Theme.amber);
}

export function fish(px, f) {
  const x = jsRounded(f.x), y = jsRounded(f.y);
  const right = f.vx > 0;
  const w = f.kind.width, h = f.kind.height;
  const hw = Math.trunc(w / 2), hh = Math.trunc(h / 2);
  const c = hexString(f.kind.color);
  px.rect(x - hw, y - hh, w, h, c);
  px.rect(x - hw + 2, y - hh - 1, w - 4, 1, c);
  px.rect(x - hw + 2, y + hh + (h % 2), w - 4, 1, c);
  const tx = right ? x - hw - 3 : x + hw;
  px.rect(tx, y - hh - 1, 3, 2, c);
  px.rect(tx, y + hh, 3, 2, c);
  px.rect(right ? x - hw - 1 : x + hw, y - 1, 1, 2, c);
  if (f.kind.name === 'shark') {
    px.rect(x - 2, y - hh - 4, 4, 3, c);
    px.rect(x - 1, y - hh - 5, 2, 1, c);
  }
  px.rect(right ? x + hw - 3 : x - hw + 2, y - 1, 1, 1, hex(0x111111));
}

export const forage = {
  field: { w: 160, h: 200, origin: { x: 80, y: 28 }, upward: false, line: 30, lanes: [45, 188], speed: 150, oneWay: false },
  heading: 'Fishing',
  throwsLabel: 'Throws',
  caughtLabel: 'Caught',
  timeLabel: 'Time',
  hint: (limit) => `Tap the water to throw a harpoon. Each throw uses tackle. You can salt and keep up to ${limit}.`,
  label: (n) => `The sea below the boat, with ${n} fish swimming`,
  actionHint: 'Double-tap to throw a harpoon at the nearest fish',
  leave: 'Back to the ship',
  pop: (worth, f) => `+${worth} lb ${f.name}`,
  backdrop,
  quarry: fish,
  thrown: harpoon,
};
