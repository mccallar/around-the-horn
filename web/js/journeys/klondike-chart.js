// The stampede's map (AroundTheHorn/Journeys/KlondikeChart.swift): the coast from Puget Sound
// to the head of Lynn Canal and the river from Lake Bennett to Dawson, on a 230×210 grid,
// x = (lon + 148) × 8.5, y = (65 − lat) × 11.4. North is up, so the party goes up the page
// and to the left. The thirty-three miles over the passes, which take longer than the
// thousand before them, are four pixels at this scale, so an inset in the corner of the open
// sea shows them large: both trails until one is chosen, the stops along it and, while the
// party is on it, the party.
//
// What the app reads off `KlondikeSkin.journey` (the stops, the ports) comes from the
// journey's tables `J`; the chart's line under the legend (`Klondike.progress`) is the
// view's `hooks.klondike.progress`.

import { hex, jsRounded, Theme } from '../pixels.js';
import { routePosition } from '../drawing.js';
import { unitsPerMile, pass, onWhitePass } from './klondike-skin.js';

/** Swift's `x.rounded()`: halves away from zero. */
const rounded = (x) => Math.sign(x) * Math.round(Math.abs(x));

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

export const w = 230.0, h = 210.0;

/** A point given as [lon, lat], on the canvas. */
export function project([lon, lat]) {
  return { x: (lon + 148) * 8.5, y: (65 - lat) * 11.4 };
}

// MARK: The way: [lon, lat, miles]

/** By steamer, from Seattle to the head of Lynn Canal. */
export const steamer = [
  [-122.33, 47.61, 0], [-122.55, 48.15, 40], [-123.0, 48.6, 95], [-123.9, 49.3, 160],
  [-125.3, 50.1, 245], [-127.0, 50.9, 330], [-128.0, 51.6, 380], [-128.8, 52.8, 480],
  [-130.2, 54.0, 600], [-131.4, 55.2, 700], [-132.4, 56.4, 820], [-133.3, 57.0, 900],
  [-134.1, 57.9, 970], [-134.42, 58.30, 1020], [-134.9, 58.55, 1045], [-135.1, 59.0, 1080],
  [-135.35, 59.33, 1110],
];

/** From Dyea over the Chilkoot to Lake Bennett. */
export const chilkootTrail = [
  [-135.36, 59.51, 1120], [-135.33, 59.635, 1133], [-135.23, 59.70, 1136.5],
  [-135.17, 59.74, 1141], [-135.08, 59.79, 1146], [-134.99, 59.85, 1153],
];

/** From Skagway over the White Pass to Lake Bennett. */
export const whitePassTrail = [
  [-135.31, 59.46, 1120], [-135.22, 59.55, 1133], [-135.14, 59.62, 1136.5],
  [-135.05, 59.70, 1141], [-135.02, 59.76, 1146], [-134.99, 59.85, 1153],
];

/** Down the lakes and the river from Bennett to Dawson. */
export const river = [
  [-134.86, 60.05, 1166], [-134.71, 60.17, 1179], [-134.45, 60.20, 1192], [-134.27, 60.31, 1203],
  [-134.35, 60.50, 1222], [-134.60, 60.62, 1235], [-135.05, 60.67, 1253], [-135.06, 60.72, 1258],
  [-135.15, 60.95, 1275], [-135.00, 61.35, 1305], [-134.88, 61.58, 1340], [-134.90, 61.87, 1375],
  [-135.50, 62.15, 1410], [-136.29, 62.09, 1445], [-136.35, 62.27, 1467], [-137.38, 62.78, 1525],
  [-138.40, 63.00, 1585], [-139.50, 63.20, 1635], [-139.42, 63.28, 1645], [-139.30, 63.70, 1675],
  [-139.43, 64.06, 1700],
];

/**
 * The lakes on the way, by the miles they run between (closed ranges): Bennett to Caribou
 * Crossing, Tagish and Marsh, and Laberge.
 */
export const lakes = [[1153, 1179], [1203, 1235], [1275, 1305]];

/** A track in the engine's own distances (tenths of a mile), in map space. */
export function points(track) {
  return track.map(([x, y, m]) => ({ x, y, mile: rounded(m * unitsPerMile) }));
}

let made = null;
/**
 * The two ways in map space, and the White Pass as far as the lake, for showing beside the
 * Chilkoot while both are open: worked out on first use, since the skin this reads its unit
 * from imports this file in turn.
 */
export function routes() {
  made ??= {
    chilkootRoute: points([...steamer, ...chilkootTrail, ...river]),
    whitePassRoute: points([...steamer, ...whitePassTrail, ...river]),
    whitePassOpen: points([...steamer, ...whitePassTrail]),
  };
  return made;
}

export function route(g) {
  return onWhitePass(g) ? routes().whitePassRoute : routes().chilkootRoute;
}

/** "the Inside Passage", "Lake Laberge": a region's name as it reads inside a sentence. */
export function place(v) {
  const name = v.region.name;
  return name.startsWith('The ') ? 'the ' + name.slice(4) : name;
}

// MARK: The country

export const land = 0xB9A26C;
export const ocean = 0x0D2A44;
export const fresh = 0x2F6A96;

/** The Pacific and the Gulf of Alaska, clockwise from the bottom left. */
export const sea = [
  [-148, 47], [-124.7, 47], [-124.7, 48.4], [-125.5, 48.9], [-127.0, 49.9],
  [-128.4, 50.8], [-127.8, 51.5], [-128.5, 52.5], [-130.0, 54.0], [-130.6, 54.7],
  [-133.5, 55.0], [-134.3, 56.0], [-135.5, 57.0], [-136.4, 57.9], [-137.0, 58.4],
  [-138.0, 58.7], [-139.7, 59.5], [-142.0, 60.0], [-145.0, 60.2], [-148.0, 60.4],
];

/** The big islands off the northern coast. */
export const island = [[-131.0, 52.0], [-132.2, 53.0], [-133.0, 54.1], [-132.0, 54.0], [-131.6, 53.2]];

export function dot(px, q, color) {
  const x = jsRounded(q.x), y = jsRounded(q.y);
  if (!(x >= 0 && x < px.w && y >= 0 && y < px.h)) return;
  px.rect(x, y, 1, 1, color);
}

/** A line `width` pixels thick through canvas points: a channel, a river, a lake. */
export function stroke(px, pts, width, color) {
  const half = Math.floor((width - 1) / 2);
  for (let i = 1; i < pts.length; i++) {
    const a = pts[i - 1], b = pts[i];
    const steps = Math.max(1, Math.trunc(Math.ceil(Math.max(Math.abs(b.x - a.x), Math.abs(b.y - a.y)) * 2)));
    for (let k = 0; k <= steps; k++) {
      const f = k / steps;
      px.rect(jsRounded(a.x + (b.x - a.x) * f) - half, jsRounded(a.y + (b.y - a.y) * f) - half, width, width, color);
    }
  }
}

/** Whether [lon, lat] is in the open sea, by the sea's outline. */
export function atSea([lon, lat]) {
  let inside = false;
  for (let i = 0; i < sea.length; i++) {
    const [alon, alat] = sea[i], [blon, blat] = sea[(i + 1) % sea.length];
    if ((alat > lat) === (blat > lat)) continue;
    if (lon < alon + (blon - alon) * (lat - alat) / (blat - alat)) inside = !inside;
  }
  return inside;
}

export function background(px) {
  px.rect(0, 0, px.w, px.h, hex(land));
  px.polygon(sea.map(project), hex(ocean));
  px.polygon(island.map(project), hex(land));
  // The graticule every five degrees: blue on the water, a darker tan on the land.
  const onSea = hex(0x173B5C), onLand = hex(0xA38D5A);
  for (const lon of stride(-145.0, -125, 5)) {
    for (const lat of stride(47.0, 65, 0.25)) {
      dot(px, project([lon, lat]), atSea([lon, lat]) ? onSea : onLand);
    }
  }
  for (const lat of [50.0, 55, 60]) {
    for (const lon of stride(-148.0, -121, 0.35)) {
      dot(px, project([lon, lat]), atSea([lon, lat]) ? onSea : onLand);
    }
  }
  // The 141st meridian, north of the coast mountains.
  for (const lat of stride(60.3, 65, 0.25)) dot(px, project([-141, lat]), hex(0x8F8A7A));
  // The inside waters the steamers keep to, and the canal up to the two landings.
  stroke(px, steamer.map(project), 3, hex(ocean));
  stroke(px, [steamer[steamer.length - 1], chilkootTrail[0]].map(project), 2, hex(ocean));
  // The river, and the lakes along it.
  const water = [chilkootTrail[chilkootTrail.length - 1], ...river];
  stroke(px, water.map(project), 2, hex(fresh));
  for (const [lo, hi] of lakes) {
    stroke(px, water.filter((p) => p[2] >= lo && p[2] <= hi).map(project), 4, hex(fresh));
  }
}

// MARK: Over the top

export function ring(px, q, color) {
  const x = jsRounded(q.x) - 3, y = jsRounded(q.y) - 3;
  px.rect(x + 1, y, 5, 1, color);
  px.rect(x + 1, y + 6, 5, 1, color);
  px.rect(x, y + 1, 1, 5, color);
  px.rect(x + 6, y + 1, 1, 5, color);
}

/** The towns too far apart to need the inset: ringed, and the two ends and Juneau named. */
export const far = ['seattle', 'juneau', 'selkirk'];

export function marks(J, px, chart, g, t) {
  const way = route(g);
  const pale = hex(0xECE4CF), dark = hex(0x3A2A1A);
  const stop = (id) => J.stops.find((s) => s.id === id) ?? null;
  for (const id of far) {
    const s = stop(id);
    if (!s) continue;
    ring(px, routePosition(way, s.mile, chart), dark);
  }
  const seattle = project(steamer[0]);
  const juneau = routePosition(way, stop('juneau')?.mile ?? 0, chart);
  const dawson = project(river[river.length - 1]);
  px.text('SEATTLE', seattle.x - 46, seattle.y + 6, 8, pale);
  px.text('JUNEAU', juneau.x + 6, juneau.y + 4, 8, dark);
  px.text('DAWSON', dawson.x + 6, dawson.y + 4, 8, dark);
  inset(J, px, g, t);
}

// MARK: The passes

export const box = { x: 6.0, y: 134.0, w: 70.0, h: 70.0 };

export function insetPoint([lon, lat]) {
  return { x: box.x + (lon + 135.45) * 127, y: box.y + (59.88 - lat) * 152 };
}

/**
 * Where `mile` (in the engine's distances) falls in the inset on a trail, or null when the
 * party is not on it: at sea below the landing, or away down the lakes.
 */
export function insetPosition(trail, mile) {
  const m = mile / unitsPerMile;
  const track = [steamer[steamer.length - 1], ...trail];
  const first = track[0], last = track[track.length - 1];
  if (!(m >= first[2] && m <= last[2])) return null;
  for (let i = 1; i < track.length; i++) {
    const a = track[i - 1], b = track[i];
    if (!(m <= b[2])) continue;
    const f = b[2] === a[2] ? 0 : (m - a[2]) / (b[2] - a[2]);
    const q = insetPoint([a[0] + (b[0] - a[0]) * f, a[1] + (b[1] - a[1]) * f]);
    const inside = q.x >= box.x + 3 && q.x <= box.x + box.w - 4 && q.y >= box.y + 3 && q.y <= box.y + box.h - 4;
    return inside ? q : null;
  }
  return null;
}

export function inset(J, px, g, t) {
  const b = box;
  const edge = hex(0x2A3547);
  px.rect(b.x, b.y, b.w, b.h, hex(land));
  // Lynn Canal, to Dyea and to Skagway, and Lake Bennett at the top of both trails.
  const foot = [-135.33, 59.42];
  stroke(px, [foot, chilkootTrail[0]].map(insetPoint), 3, hex(ocean));
  stroke(px, [foot, whitePassTrail[0]].map(insetPoint), 3, hex(ocean));
  const lake = insetPoint(chilkootTrail[chilkootTrail.length - 1]);
  stroke(px, [{ x: lake.x, y: lake.y }, { x: lake.x + 4, y: lake.y - 3 }], 3, hex(fresh));
  px.rect(b.x, b.y, b.w, 1, edge);
  px.rect(b.x, b.y + b.h - 1, b.w, 1, edge);
  px.rect(b.x, b.y, 1, b.h, edge);
  px.rect(b.x + b.w - 1, b.y, 1, b.h, edge);

  const chosen = pass(g);
  const white = onWhitePass(g);
  const dark = hex(0x3A2A1A), faint = hex(0x8F7B4E);
  const trail = (track, color) => {
    for (let i = 1; i < track.length; i++) {
      const a = insetPoint(track[i - 1]), z = insetPoint(track[i]);
      const steps = Math.max(1, Math.trunc(rounded(Math.hypot(z.x - a.x, z.y - a.y) / 2)));
      for (let k = 0; k <= steps; k++) {
        const f = k / steps;
        dot(px, { x: a.x + (z.x - a.x) * f, y: a.y + (z.y - a.y) * f }, color);
      }
    }
  };
  // Both ways while both are open; afterwards the one not taken fades.
  const mine = white ? whitePassTrail : chilkootTrail;
  const other = white ? chilkootTrail : whitePassTrail;
  trail(other, chosen == null ? dark : faint);
  trail(mine, dark);
  // The part hauled so far, in the shell's amber.
  if (chosen != null) {
    const done = g.mile / unitsPerMile;
    for (const m of stride(mine[0][2], Math.min(done, mine[mine.length - 1][2]), 0.25)) {
      const q = insetPosition(mine, m * unitsPerMile);
      if (q) dot(px, q, Theme.amber);
    }
  }
  // The stops along it, the towns ringed, on both trails while both are open.
  J.stops.forEach((stop, i) => {
    const m = stop.mile;
    for (const track of chosen == null ? [chilkootTrail, whitePassTrail] : [mine]) {
      const q = insetPosition(track, m);
      if (!(q && m >= track[0][2] * unitsPerMile)) continue;
      px.rect(jsRounded(q.x) - 1, jsRounded(q.y) - 1, 3, 3, i <= g.stopIndex ? Theme.amber : Theme.ink);
      if (J.ports.some((p) => p.id === stop.id)) ring(px, q, dark);
    }
  });
  px.text('THE PASSES', b.x + 3, b.y + 10, 8, dark);
  if (chosen == null) {
    px.text('Chilkoot', b.x + 3, b.y + 22, 8, dark);
    px.text('White Pass', b.x + 36, b.y + 58, 8, dark);
  }
  const q = insetPosition(mine, g.mile);
  if (q && Math.floor(t * 2) % 2 === 0) {
    px.rect(jsRounded(q.x) - 2, jsRounded(q.y) - 2, 5, 5, Theme.red);
  }
}

/** The ChartSkin, for the journey's tables `J`. Functions of the voyage take the bridge's view. */
export function chart(J) {
  const skin = {
    w,
    h,
    title: 'Map of the journey',
    label: (v) => `Map of the route from Seattle to Dawson City. You are in ${place(v)}.`,
    footer: (v) => `${v.hooks.klondike.progress} The ringed stops are towns; the inset is the two passes, `
      + "where a month's hauling is too short to show.",
    background: (px) => background(px),
    route: (v) => route(v.state),
    others: (v) => (pass(v.state) == null ? [routes().whitePassOpen] : []),
    project: (x, y) => project([x, y]),
    routeStep: 30,
    travelledStep: 10,
    routeColor: hex(0x6D7F92),
    overlay: (px, v, t) => marks(J, px, skin, v.state, t),
  };
  return skin;
}
