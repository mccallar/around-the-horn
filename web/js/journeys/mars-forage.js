// The grapple (AroundTheHorn/Journeys/MarsForage.swift): 1849's field turned upside down. A
// rigger in a suit stands on the truss at the bottom of a 160×200 piece of sky, beside the
// grapple launcher, and fires a tethered grapple from (80, 182) at ice drifting across above
// in the three filaments of a comet's old stream, all of it going the same way. What is
// caught goes to the melt tank, in litres of water, counted by the shell (fishing.js
// `reward`).

import { PixelCanvas, hex, opacity, white, jsRounded } from '../pixels.js';
import { scatter, wrap } from './mars-scene.js';

export const launcher = { x: 80.0, y: 182.0 };

/** The grapple's field, as the app's `ForageField` gives it. */
export const field = { w: 160, h: 200, origin: launcher, upward: true, line: 172, lanes: [18, 150], speed: 150,
  oneWay: true, bands: 3 };

/**
 * Black sky and fixed stars, the stream's three filaments glittering faintly, and at the
 * bottom the truss, a wing's edge, the habitat can, the rigger and the launcher.
 */
export function backdrop(px, now) {
  px.bands(0x04060D, 0x0E1730, 0, 20, 10);
  for (let i = 0; i < 44; i++) {
    const h = scatter(i + 100);
    px.rect(h % 160, Math.trunc(h / 160) % 168, 1, 1, opacity(white, i % 3 === 0 ? 0.8 : 0.35));
  }
  const f = field;
  const each = (f.lanes[1] - f.lanes[0]) / f.bands;
  for (let k = 0; k < f.bands; k++) {
    const y = f.lanes[0] + each * (k + 0.5);
    px.rect(0, y - 9, 160, 18, opacity(hex(0xC9D6DF), 0.04));
    for (let i = 0; i < 9; i++) {
      const x = wrap(i * 19 + now * (8 + k * 3), 170) - 5;
      const flash = (i + k + Math.floor(now * 2)) % 5 === 0;
      px.rect(Math.floor(x), y - 8 + (i * 7 + k * 5) % 17, 1, 1, opacity(hex(0xD6E2EA), flash ? 0.9 : 0.3));
    }
  }
  // A wing's edge at the left, the habitat can at the right.
  for (let i = 0; i < 5; i++) {
    px.rect(i * 7, 189, 6, 5, hex(0x2E4E8C));
    px.rect(i * 7, 195, 6, 5, hex(0x2E4E8C));
  }
  px.rect(0, 188, 35, 1, hex(0xB8962E));
  px.rect(122, 184, 38, 16, hex(0xDCE1E6));
  px.rect(122, 184, 38, 1, hex(0xA7AEB7));
  for (const x of [128.0, 136, 144, 152]) px.rect(x, 189, 3, 3, hex(0xF2D16B));
  // The truss: two rails, uprights, braces.
  const truss = hex(0x9AA1AA);
  px.rect(30, 186, 92, 1, truss);
  px.rect(30, 196, 92, 1, truss);
  for (let x = 32.0; x < 120; x += 8) {
    px.rect(x, 186, 1, 10, truss);
    px.line({ x, y: 187 }, { x: x + 7, y: 195 }, hex(0x6B717A));
  }
  // The launcher on its mount, its reel of tether.
  px.rect(78, 183, 5, 3, hex(0x4B4F55));
  px.rect(79, 178, 3, 5, hex(0x5A5F68));
  px.rect(84, 182, 4, 4, hex(0xB8962E));
  px.rect(85, 183, 2, 2, hex(0x3A3F47));
  // The rigger in a white suit, gold visor, one hand on the launcher.
  const suit = hex(0xECEEF0);
  px.rect(70, 178, 5, 8, suit);
  px.rect(70, 174, 5, 4, suit);
  px.rect(71, 175, 3, 2, hex(0xF2B632));
  px.rect(75, 180, 3, 1, suit);
  px.rect(70, 186, 2, 1, suit);
  px.rect(73, 186, 2, 1, suit);
  px.rect(68, 179, 2, 5, hex(0xA7AEB7));
}

/** The grapple's head, three prongs open, and its tether back to the launcher. */
export function grapple(px, h) {
  const x = jsRounded(h.x), y = jsRounded(h.y);
  const dx = x - launcher.x, dy = y - (launcher.y - 4);
  const steps = Math.trunc(Math.hypot(dx, dy) / 2);
  for (let k = 1; k < Math.max(2, steps); k++) {
    const f = k / Math.max(2, steps);
    px.rect(jsRounded(launcher.x + dx * f), jsRounded(launcher.y - 4 + dy * f), 1, 1, opacity(hex(0xECE4CF), 0.55));
  }
  const steel = hex(0xC8CED6);
  px.rect(x - 1, y - 1, 2, 3, steel);
  px.rect(x - 3, y - 3, 1, 2, steel);
  px.rect(x + 2, y - 3, 1, 2, steel);
  px.rect(x - 2, y - 1, 1, 1, steel);
  px.rect(x + 1, y - 1, 1, 1, steel);
  px.rect(x, y - 4, 1, 3, steel);
}

/**
 * A chunk of ice as it tumbles past: a scatter of grit, a pale lump with a dark side, a big
 * berg with a crack in it; and now and then somebody's lost water bladder, orange, with its
 * strap and a beacon blinking.
 */
export function ice(px, f) {
  const x = jsRounded(f.x), y = jsRounded(f.y);
  const w = f.kind.width, h = f.kind.height;
  const hw = Math.trunc(w / 2), hh = Math.trunc(h / 2);
  const rgb = colorOf(f.kind) ?? 0xC9D6DF;
  const c = hex(rgb), dark = PixelCanvas.mix(rgb, 0x1A2533, 0.45), bright = PixelCanvas.mix(rgb, 0xFFFFFF, 0.5);
  const left = x - hw, top = y - hh;
  switch (f.kind.name) {
    case 'grit':
      for (const [dx, dy] of [[0.0, 1.0], [2, 0], [3, 2], [5, 1], [1, 2]]) {
        if (dx < w) px.rect(left + dx, top + dy, 1, 1, c);
      }
      break;
    case 'lost water bladder':
      px.rect(left + 1, top, w - 2, h, hex(rgb));
      px.rect(left, top + 1, w, h - 2, hex(rgb));
      px.rect(left + 1, top + h - 2, w - 2, 1, PixelCanvas.mix(rgb, 0x000000, 0.3));
      px.rect(left + 4, top, 2, h, hex(0xECEEF0));
      px.rect(left + w - 4, top + 2, 2, 2, hex(0x2E6FB5));
      if (Math.floor(f.t * 2) % 2 === 0) px.rect(left + w - 2, top - 1, 1, 1, hex(0xFF5A4A));
      break;
    default: {
      // A lump with a ragged edge: each row set in by its own amount, the top lit, the
      // underside in shadow, and on the bigger ones dark pits; the berg has a crack.
      const ragged = [2, 1, 0, 1, 0, 0, 1, 0, 2, 1, 0];
      const seed = Math.trunc(w) % ragged.length;
      for (let r = 0; r < Math.trunc(h); r++) {
        const inL = r === 0 || r === Math.trunc(h) - 1 ? 2 : ragged[(r + seed) % ragged.length];
        const inR = r === 0 || r === Math.trunc(h) - 1 ? 1 : ragged[(r * 3 + seed + 4) % ragged.length];
        const color = r === 0 ? bright : r >= Math.trunc(h) - 2 ? dark : c;
        px.rect(left + inL, top + r, Math.max(1, w - inL - inR), 1, color);
      }
      px.rect(left + w - 3, top + 1, 1, Math.max(1, h - 3), dark);
      if (w >= 13) {
        px.rect(left + 3, top + 2, 2, 2, dark);
        px.rect(left + w / 2, top + h / 2, 2, 1, dark);
      }
      if (w >= 20) {
        px.line({ x: left + 9, y: top + 1 }, { x: left + 13, y: top + h - 3 }, dark);
        px.rect(left + 4, top + 1, 4, 1, white);
      }
    }
  }
}

/** The ForageSkin, for the journey's tables `J` (what water is called). */
export function forage(J) {
  const water = J.items.find((i) => i.key === 'water');
  return {
    field,
    heading: 'The grapple',
    throwsLabel: 'Shots',
    caughtLabel: 'Caught',
    timeLabel: 'Time',
    grouped: false,
    hint: (limit) => `Tap the dark to fire the grapple at a chunk going by. Each shot spends tether. The melt tank takes up to ${limit} from one outing.`,
    label: (n) => `The ice stream beyond the truss, with ${n} ${n === 1 ? 'chunk' : 'chunks'} drifting by`,
    actionHint: 'Double-tap to fire the grapple at the nearest chunk',
    leave: 'Back inside',
    pop: (n, chunk) => `+${n} ${n === '1' ? water.one : water.unit}, ${chunk.name}`,
    backdrop,
    quarry: ice,
    thrown: grapple,
  };
}

/** A quarry's `#RRGGBB` colour as a number, or null if it isn't one (Swift's `UInt32(_:radix:)`). */
function colorOf(kind) {
  return /^#[0-9A-Fa-f]{6}$/.test(kind.color) ? parseInt(kind.color.slice(1), 16) : null;
}
