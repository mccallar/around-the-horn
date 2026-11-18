// Fishing the lakes and the river (AroundTheHorn/Journeys/KlondikeForage.swift): 1849's field
// under a northern sky. A small boat sits at the top of a 160×200 piece of green water with a
// spruce shore behind it, and a hook on a line is cast down from (80, 28) at grayling,
// whitefish, pike, lake trout and king salmon. What is caught is smoked and goes in with the
// provisions, counted by the shell (fishing.js `reward`).

import { PixelCanvas, hex, opacity, white, jsRounded } from '../pixels.js';
import { tree } from './klondike-scene.js';

export const rod = { x: 80.0, y: 28.0 };

/** The field, as the app's `ForageField` gives it. */
export const field = { w: 160, h: 200, origin: rod, upward: false, line: 30, lanes: [45, 188], speed: 150, oneWay: false };

/**
 * A strip of pale sky with the spruce shore along the bottom of it, the water going from
 * green to black with depth, shafts of light, ripples, and the boat with the fisher in a red
 * mackinaw.
 */
export function backdrop(px, now) {
  const ms = now * 1000;
  px.rect(0, 0, 160, 28, hex(0xBFD9E6));
  // Far hills under snow, then the shore's spruce: one every four pixels, 3 to 7 tall.
  px.hills(0, 160, 28, hex(0xE8EEF2), (x) => 9 + 4 * Math.sin(x * 0.05) + 2 * Math.sin(x * 0.17));
  px.rect(0, 26, 160, 2, hex(0x1F3A2A));
  for (let i = 0; i < 40; i++) {
    tree(px, i * 4 + 1, 27, 3 + (i * 7 + Math.trunc(i / 3)) % 5, hex(0x1F3A2A));
  }
  px.bands(0x3D7C78, 0x0A2422, 28, 18, 10);
  for (let i = 0; i < 4; i++) {
    px.rect(PixelCanvas.mod(i * 45 + ms / 80, 200) - 20, 28, 6, 172, opacity(white, 0.06));
  }
  for (let i = 0; i < 160; i += 6) {
    px.rect(i + jsRounded(Math.sin(ms / 400 + i)), 28, 3, 1, hex(0xCFE6DF));
  }
  // The boat: a double-ended skiff, its stem and stern turned up, an oar shipped.
  const wood = hex(0x9C7A4E), shade = hex(0x6B5132);
  px.rect(69, 24, 22, 3, wood);
  px.rect(71, 27, 18, 1, shade);
  px.rect(68, 23, 2, 2, wood);
  px.rect(90, 23, 2, 2, wood);
  px.rect(69, 25, 22, 1, shade);
  px.line({ x: 84, y: 23 }, { x: 93, y: 20 }, shade);
  // The fisher, in a red mackinaw and a dark cap, the rod out over the side.
  px.rect(77, 18, 3, 6, hex(0xB5432F));
  px.rect(77, 15, 3, 3, hex(0xEFD6B0));
  px.rect(77, 14, 3, 1, hex(0x3A2A1A));
  px.rect(80, 19, 1, 1, hex(0xB5432F));
  px.line({ x: 80.5, y: 19.5 }, { x: rod.x + 0.5, y: rod.y - 6.5 }, hex(0x3A2A1A));
}

/** The line from the rod's tip and the hook at the end of it. */
export function hook(px, h) {
  px.line({ x: rod.x + 0.5, y: rod.y - 6.5 }, { x: h.x, y: h.y }, opacity(hex(0xE9E3D2), 0.7));
  px.rect(jsRounded(h.x), jsRounded(h.y), 2, 2, hex(0xC9CED4));
}

/**
 * 1849's fish, in this water's kinds: the grayling with its tall back fin, the lake trout
 * spotted, the pike long and narrow in the snout.
 */
export function fish(px, f) {
  const x = jsRounded(f.x), y = jsRounded(f.y);
  const right = f.vx > 0;
  const w = f.kind.width, h = f.kind.height;
  const hw = Math.trunc(w / 2), hh = Math.trunc(h / 2);
  const rgb = colorOf(f.kind) ?? 0x9DB7C9;
  const c = hex(rgb);
  px.rect(x - hw, y - hh, w, h, c);
  px.rect(x - hw + 2, y - hh - 1, w - 4, 1, c);
  px.rect(x - hw + 2, y + hh + (h % 2), w - 4, 1, c);
  const tx = right ? x - hw - 3 : x + hw;
  px.rect(tx, y - hh - 1, 3, 2, c);
  px.rect(tx, y + hh, 3, 2, c);
  px.rect(right ? x - hw - 1 : x + hw, y - 1, 1, 2, c);
  switch (f.kind.name) {
    case 'grayling':
      // The sail of a fin, three pixels above the back.
      px.rect(x - 2, y - hh - 3, 4, 2, c);
      px.rect(x - 1, y - hh - 4, 2, 1, c);
      break;
    case 'lake trout':
      for (let i = 0; ; i++) {
        const k = 2.0 + i * 4;
        if (!(k < w - 2)) break;
        px.rect(x - hw + k, y - hh + 1 + (Math.trunc(k / 4) % 2) * 2, 1, 1, hex(0xD9D1B0));
      }
      break;
    case 'pike':
      // A long flat snout past the head.
      px.rect(right ? x + hw : x - hw - 2, y - hh + 1, 2, Math.max(1, h - 2), c);
      px.rect(x - hw + 3, y - hh, w - 6, 1, PixelCanvas.mix(rgb, 0x2A3A1A, 0.45));
      break;
    case 'king salmon':
      // A dark back and a pale belly.
      px.rect(x - hw + 1, y - hh, w - 2, 2, PixelCanvas.mix(rgb, 0x3A2A2A, 0.45));
      px.rect(x - hw + 2, y + hh, w - 4, 1, PixelCanvas.mix(rgb, 0xFFFFFF, 0.45));
      break;
    default:
      break;
  }
  px.rect(right ? x + hw - 3 : x - hw + 2, y - 1, 1, 1, hex(0x111111));
}

/** The ForageSkin, for the journey's tables `J` (what provisions are called). */
export function forage(J) {
  const food = J.items.find((i) => i.key === 'food');
  return {
    field,
    heading: 'Fishing',
    throwsLabel: 'Casts',
    caughtLabel: 'Caught',
    timeLabel: 'Time',
    grouped: false,
    hint: (limit) => `Tap the water to cast. Each cast uses a hook. You can smoke and keep up to ${limit}.`,
    label: (n) => `The water below the boat, with ${n} fish swimming`,
    actionHint: 'Double-tap to cast at the nearest fish',
    leave: 'Back to camp',
    pop: (n, f) => `+${n} ${n === '1' ? food.one : food.unit} ${f.name}`,
    backdrop,
    quarry: fish,
    thrown: hook,
  };
}

/** A quarry's `#RRGGBB` colour as a number, or null if it isn't one (Swift's `UInt32(_:radix:)`). */
function colorOf(kind) {
  return /^#[0-9A-Fa-f]{6}$/.test(kind.color) ? parseInt(kind.color.slice(1), 16) : null;
}
