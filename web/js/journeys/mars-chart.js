// The Long Transfer's plot (AroundTheHorn/Journeys/MarsChart.swift): the inner solar system
// seen from above, on a 230×200 grid. The Sun is in the middle, Earth's orbit and Mars's are
// dotted circles, and the transfer arc is half an ellipse with the Sun at one focus, from
// Earth on the left (closest to the Sun) round under the Sun to Mars on the right
// (furthest), the way the planets go round. So the ship heads right on the plot, as she
// does in the scene. The cycler's loop is a fainter ellipse through the point where she
// meets it. An inset in the corner shows the Earth and the Moon, where the first three stops
// are too close together to tell apart at this scale. The route is given already projected.
//
// What the app reads off `MarsSkin.journey` (the arc's length, the stops) comes from the
// journey's tables `J`.

import { hex, opacity, white, jsRounded, Theme } from '../pixels.js';
import { routePosition } from '../drawing.js';
import { whereabouts } from './mars-scene.js';
import { millions, km } from './mars-skin.js';

/** Swift's `x.rounded()`: halves away from zero. */
const rounded = (x) => Math.sign(x) * Math.round(Math.abs(x));

/** A point, as the app's tuples are written. */
const P = (x, y) => ({ x, y });

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

const stopOf = (J, id) => J.stops.find((s) => s.id === id) ?? null;

export const w = 230.0, h = 200.0;
export const sun = { x: 128.0, y: 100.0 };
/** Pixels to an astronomical unit. */
export const scale = 58.0;
export const earthAU = 1.0, marsAU = 1.524;

/** The transfer ellipse: its semi-major axis and eccentricity, from the two orbits. */
export const a = (earthAU + marsAU) / 2;
export const e = (marsAU - earthAU) / (marsAU + earthAU);

/** Distance from the Sun, in AU, `theta` radians round from Earth. */
export function radius(theta) { return a * (1 - e * e) / (1 + e * Math.cos(theta)); }

/**
 * A point in AU from the Sun at `r` and position angle `phi` (counted the usual way, up the
 * page positive), on the canvas.
 */
export function project(r, phi) {
  return P(sun.x + scale * r * Math.cos(phi), sun.y - scale * r * Math.sin(phi));
}

/** The arc, `steps` pieces of equal angle, with the length run so far at each. */
export const samples = (() => {
  const steps = 360;
  const out = [{ theta: 0, length: 0 }];
  let run = 0.0;
  let last = project(radius(0), Math.PI);
  for (let k = 1; k <= steps; k++) {
    const th = Math.PI * k / steps;
    const q = project(radius(th), Math.PI + th);
    run += Math.hypot(q.x - last.x, q.y - last.y);
    last = q;
    out.push({ theta: th, length: run });
  }
  return out;
})();

/** How far round from Earth the ship is at `mile`, by the length of the arc. */
export function theta(J, mile) {
  const total = J.totalMiles;
  const want = Math.max(0, Math.min(1, mile / total)) * (samples[samples.length - 1]?.length ?? 1);
  for (let k = 1; k < samples.length; k++) {
    const p = samples[k - 1], q = samples[k];
    if (!(want <= q.length)) continue;
    const f = q.length === p.length ? 0 : (want - p.length) / (q.length - p.length);
    return p.theta + (q.theta - p.theta) * f;
  }
  return Math.PI;
}

/** The ship's distance from the Sun at `mile`, in AU: the scene sizes the Sun by it. */
export function au(J, mile) { return radius(theta(J, mile)); }

/**
 * The route: a point every two degrees round, each at the mile its share of the arc's
 * length makes it, the last at Jezero.
 */
export function route(J) {
  const total = J.totalMiles;
  const length = samples[samples.length - 1]?.length ?? 1;
  const out = [];
  samples.forEach((s, k) => {
    if (k % 4 !== 0) return;
    const q = project(radius(s.theta), Math.PI + s.theta);
    out.push({ x: q.x, y: q.y, mile: k === samples.length - 1 ? total : rounded(s.length / length * total) });
  });
  return out;
}

/**
 * The cycler's loop: an ellipse a little longer than the transfer's, turned so that it
 * passes through the point on the arc where the ship meets her.
 */
export const cyclerA = 1.30, cyclerE = 0.24;
export function cyclerTurn(J) {
  const mile = stopOf(J, 'cycler')?.mile ?? 0;
  const th = theta(J, mile);
  const r = radius(th), phi = Math.PI + th;
  const c = Math.max(-1, Math.min(1, (cyclerA * (1 - cyclerE * cyclerE) / r - 1) / cyclerE));
  return phi - Math.acos(c);
}

/** A point on the cycler's loop, the loop turned by `turn` (`cyclerTurn`). */
export function cyclerPoint(turn, phi) {
  return project(cyclerA * (1 - cyclerE * cyclerE) / (1 + cyclerE * Math.cos(phi - turn)), phi);
}

/** The ChartSkin, for the journey's tables `J`. Functions of the voyage take the bridge's view. */
export function chart(J) {
  const path = route(J);
  const turn = cyclerTurn(J);
  const skin = {
    w,
    h,
    title: 'Plot of the transfer',
    label: (v) => `Plot of the transfer arc round the Sun, from Earth orbit to Mars. You are ${whereabouts(J, v.state, v.region)}.`,
    footer: (v) => {
      const total = J.totalMiles;
      return `${millions(v.state.mile)} of ${km(total)} along the arc. `
        + `${millions(Math.max(0, total - v.state.mile))} to go. The ringed stops are stations; `
        + 'the inset is the Earth and the Moon, where the trip begins.';
    },
    background: (px) => background(px, turn),
    route: () => path,
    others: () => [],
    project: (x, y) => ({ x, y }),
    routeStep: 600,
    travelledStep: 200,
    routeColor: hex(0x6D7F92),
    overlay: (px, v, t) => marks(J, px, skin, v.state, t),
  };
  return skin;
}

// MARK: The inner solar system

export const space = 0x070B18;
export const earthBlue = 0x3C7CC4;
export const marsRust = 0xC0613A;

export function dot(px, q, color) {
  const x = jsRounded(q.x), y = jsRounded(q.y);
  if (!(x >= 0 && x < px.w && y >= 0 && y < px.h)) return;
  px.rect(x, y, 1, 1, color);
}

/** The plot's sky, its orbits and the Sun; `turn` is the cycler's loop's (`cyclerTurn`). */
export function background(px, turn) {
  px.rect(0, 0, px.w, px.h, hex(space));
  // A scatter of stars, the same every time.
  for (let i = 0; i < 70; i++) {
    const x = (i * 97 + 13) % Math.trunc(w), y = (i * 61 + 29) % Math.trunc(h);
    px.rect(x, y, 1, 1, opacity(white, i % 4 === 0 ? 0.55 : 0.22));
  }
  // The cycler's loop, faintly; then the two orbits.
  for (const k of stride(0.0, 360, 4, false)) {
    dot(px, cyclerPoint(turn, k * Math.PI / 180), hex(0x4B5566));
  }
  for (const k of stride(0.0, 360, 3, false)) {
    dot(px, project(earthAU, k * Math.PI / 180), opacity(hex(earthBlue), 0.8));
    dot(px, project(marsAU, k * Math.PI / 180), opacity(hex(marsRust), 0.8));
  }
  // The Sun, and its glow.
  const s = P(sun.x, sun.y);
  px.rect(s.x - 4, s.y - 1, 9, 3, opacity(hex(0xFFE27A), 0.35));
  px.rect(s.x - 1, s.y - 4, 3, 9, opacity(hex(0xFFE27A), 0.35));
  px.rect(s.x - 2, s.y - 2, 5, 5, hex(0xFFE27A));
  px.rect(s.x - 1, s.y - 3, 3, 7, hex(0xFFE27A));
  px.rect(s.x - 3, s.y - 1, 7, 3, hex(0xFFE27A));
  // Earth where the ship leaves it, Mars where she meets it.
  const earth = project(earthAU, Math.PI), mars = project(marsAU, 0);
  px.rect(jsRounded(earth.x) - 2, jsRounded(earth.y) - 2, 5, 5, hex(earthBlue));
  px.rect(jsRounded(mars.x) - 2, jsRounded(mars.y) - 2, 5, 5, hex(marsRust));
}

/**
 * The stations ringed, the three names, and the inset of the Earth and the Moon with the
 * first stops and, while she is there, the ship.
 */
export function marks(J, px, chart, g, t) {
  const ink = hex(0xECE4CF);
  const path = chart.route();
  for (const stop of J.stops) {
    if (!J.ports.some((p) => p.id === stop.id)) continue;
    const q = routePosition(path, stop.mile, chart);
    const x = jsRounded(q.x) - 3, y = jsRounded(q.y) - 3;
    px.rect(x + 1, y, 5, 1, ink);
    px.rect(x + 1, y + 6, 5, 1, ink);
    px.rect(x, y + 1, 1, 5, ink);
    px.rect(x + 6, y + 1, 1, 5, ink);
  }
  const dim = hex(0xB8B2A2);
  px.text('Sun', sun.x + 6, sun.y - 4, 8, dim);
  const earth = project(earthAU, Math.PI), mars = project(marsAU, 0);
  px.text('Earth', earth.x + 4, earth.y - 3, 8, dim);
  px.text('Mars', mars.x - 18, mars.y - 5, 8, dim);
  inset(J, px, g, t);
}

/** The inset's box, top left. */
export const box = { x: 3.0, y: 3.0, w: 50.0, h: 44.0 };
export const insetEarth = { x: 14.0, y: 25.0 };
/**
 * Pixels from the Earth's middle to Gateway Yard (high orbit), the Moon's distance and the
 * edge of Earth's reach, in the inset.
 */
export const insetRadius = { gateway: 5, lunar: 9, hill: 31 };

/** Where `mile` falls in the inset, out along the way the ship leaves. */
export function insetX(J, mile) {
  const marks = [];
  for (const id of ['gateway', 'lunar', 'hill']) {
    const stop = stopOf(J, id);
    if (stop) marks.push({ mile: stop.mile, r: insetRadius[id] ?? 0 });
  }
  const first = marks[0], last = marks[marks.length - 1];
  if (!first || !last) return insetEarth.x;
  if (mile <= first.mile) return insetEarth.x + first.r;
  for (let k = 1; k < marks.length; k++) {
    const p = marks[k - 1], q = marks[k];
    if (mile <= q.mile) return insetEarth.x + p.r + (q.r - p.r) * (mile - p.mile) / Math.max(1, q.mile - p.mile);
  }
  return insetEarth.x + last.r;
}

export function inset(J, px, g, t) {
  const b = box;
  const edge = hex(0x3A4A5E);
  px.rect(b.x, b.y, b.w, b.h, hex(0x0A1222));
  px.rect(b.x, b.y, b.w, 1, edge);
  px.rect(b.x, b.y + b.h - 1, b.w, 1, edge);
  px.rect(b.x, b.y, 1, b.h, edge);
  px.rect(b.x + b.w - 1, b.y, 1, b.h, edge);
  const c = insetEarth;
  // The Moon's orbit, and the edge of Earth's reach on the side she leaves by.
  for (const k of stride(0.0, 360, 20, false)) {
    const a = k * Math.PI / 180;
    dot(px, P(c.x + 9 * Math.cos(a), c.y + 9 * Math.sin(a)), hex(0x8F8F88));
  }
  for (const k of stride(-40.0, 40, 8)) {
    const a = k * Math.PI / 180;
    dot(px, P(c.x + 31 * Math.cos(a), c.y + 31 * Math.sin(a)), hex(0x6D7F92));
  }
  px.rect(c.x - 2, c.y - 2, 5, 5, hex(earthBlue));
  px.rect(c.x - 1, c.y - 3, 3, 7, hex(earthBlue));
  px.rect(c.x - 3, c.y - 1, 7, 3, hex(earthBlue));
  px.rect(c.x + 6, c.y - 7, 2, 2, hex(0xB8B8B0));
  // The first three stops on the way out, and the ship while she is among them.
  for (const id of ['gateway', 'lunar', 'hill']) {
    const i = J.stops.findIndex((s) => s.id === id);
    if (i < 0) continue;
    const x = jsRounded(insetX(J, J.stops[i].mile));
    px.rect(x - 1, c.y - 1, 3, 3, i <= g.stopIndex ? Theme.amber : Theme.ink);
  }
  const hill = stopOf(J, 'hill')?.mile ?? 0;
  if (g.mile <= hill && Math.floor(t * 2) % 2 === 0) {
    px.rect(jsRounded(insetX(J, g.mile)) - 2, c.y - 2, 5, 5, Theme.red);
  }
}
