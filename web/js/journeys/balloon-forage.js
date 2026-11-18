// Trailing a line (AroundTheHorn/Journeys/BalloonForage.swift): 1849's sea, seen from a
// capsule hanging just above the wave tops. The field is 1849's way up: the underside of
// the capsule at the top of a 160×200 sea, a crew member at the open hatch, and lures cast
// down from (80.5, 27.5) at whatever swims below. What is caught is pounds of rations,
// counted by the shell (fishing.js `reward`).

import { PixelCanvas, hex, opacity, rgb, white, jsRounded } from '../pixels.js';

export const hatch = { x: 80.5, y: 27.5 };

/**
 * A strip of gold sky, the underside of the capsule hanging from its cables with a crew
 * member at the open hatch, and below it 1849's water: darker with depth, shafts of light,
 * ripples at the top.
 */
export function backdrop(px, now) {
  const ms = now * 1000;
  px.rect(0, 0, 160, 28, hex(0xF6D78B));
  px.bands(0x1F6B96, 0x061A2B, 28, 18, 10);
  for (let i = 0; i < 4; i++) {
    px.rect(PixelCanvas.mod(i * 45 + ms / 80, 200) - 20, 28, 6, 172, opacity(white, 0.06));
  }
  for (let i = 0; i < 160; i += 6) {
    px.rect(i + jsRounded(Math.sin(ms / 400 + i)), 28, 3, 1, hex(0xD8ECF7));
  }
  // The load cables, the capsule and its portholes, and the hatch in its floor.
  const cable = hex(0x5A6270);
  px.line({ x: 68, y: 0 }, { x: 70, y: 8 }, cable);
  px.line({ x: 90, y: 0 }, { x: 92, y: 8 }, cable);
  px.rect(66, 8, 29, 14, hex(0xECE4CF));
  for (const x of [70.0, 76, 84, 90]) px.rect(x, 14, 2, 2, hex(0x1A2533));
  px.rect(78, 22, 5, 2, hex(0x3A3F48));
  // Whoever is fishing: a red suit through the hatch, face down to the water.
  px.rect(79, 22, 2, 4, hex(0xD64545));
  px.rect(79, 26, 2, 2, hex(0xEFD6B0));
}

/** The line back to the hatch, a pale trail behind the lure, and the lure's gold head. */
export function lure(px, h) {
  px.line({ x: hatch.x, y: hatch.y }, { x: h.x, y: h.y }, opacity(rgb(236, 228, 207), 0.5));
  const a = Math.atan2(h.vy, h.vx);
  for (let k = 0; k < 6; k++) {
    px.rect(jsRounded(h.x - Math.cos(a) * k), jsRounded(h.y - Math.sin(a) * k), 1, 1, hex(0xECE4CF));
  }
  px.rect(jsRounded(h.x), jsRounded(h.y), 2, 2, hex(0xF2B632));
}

/** 1849's fish in the Pacific's colours; the yellowfin carries a gold dorsal fin. */
export function fish(px, f) {
  const x = jsRounded(f.x), y = jsRounded(f.y);
  const right = f.vx > 0;
  const w = f.kind.width, h = f.kind.height;
  const hw = Math.trunc(w / 2), hh = Math.trunc(h / 2);
  const c = hex(colorOf(f.kind) ?? 0x9FC9E8);
  px.rect(x - hw, y - hh, w, h, c);
  px.rect(x - hw + 2, y - hh - 1, w - 4, 1, c);
  px.rect(x - hw + 2, y + hh + (h % 2), w - 4, 1, c);
  const tx = right ? x - hw - 3 : x + hw;
  px.rect(tx, y - hh - 1, 3, 2, c);
  px.rect(tx, y + hh, 3, 2, c);
  px.rect(right ? x - hw - 1 : x + hw, y - 1, 1, 2, c);
  if (f.kind.name === 'yellowfin') {
    const fin = hex(0xF2D04B);
    px.rect(x - 2, y - hh - 4, 4, 3, fin);
    px.rect(x - 1, y - hh - 5, 2, 1, fin);
  }
  if (f.kind.name === 'flying fish') {
    // Its long fins, folded back along the body.
    px.rect(right ? x - 2 : x - 1, y - hh - 2, 4, 1, PixelCanvas.mix(0x9FC9E8, 0xFFFFFF, 0.4));
  }
  px.rect(right ? x + hw - 3 : x - hw + 2, y - 1, 1, 1, hex(0x111111));
}

/** The ForageSkin, for the journey's tables `J` (what food is called). */
export function forage(J) {
  const food = J.items.find((i) => i.key === 'food');
  return {
    field: { w: 160, h: 200, origin: hatch, upward: false, line: 30, lanes: [45, 188], speed: 150, oneWay: false },
    heading: 'Trailing a line',
    throwsLabel: 'Casts',
    caughtLabel: 'Caught',
    timeLabel: 'Time',
    grouped: false,
    hint: (limit) => `Tap the water to cast a lure. Each cast uses line. You can stow up to ${limit}.`,
    label: (n) => `The sea below the capsule, with ${n} fish swimming`,
    actionHint: 'Double-tap to cast a lure at the nearest fish',
    leave: 'Back to the capsule',
    pop: (n, f) => `+${n} ${n === '1' ? food.one : food.unit} ${f.name}`,
    backdrop,
    quarry: fish,
    thrown: lure,
  };
}

/** A quarry's `#RRGGBB` colour as a number, or null if it isn't one (Swift's `UInt32(_:radix:)`). */
function colorOf(kind) {
  return /^#[0-9A-Fa-f]{6}$/.test(kind.color) ? parseInt(kind.color.slice(1), 16) : null;
}
