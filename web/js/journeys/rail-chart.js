// The Iron Road's map (AroundTheHorn/Journeys/RailChart.swift): the West from the Missouri
// to the Pacific on a 240×104 grid, x = (lon + 124.6) × 7.8, y = (44.7 − lat) × 10. East is
// on the right, so the train runs right to left, as it does in the scene. The dotted road,
// the part covered, the stops and the blinking marker are the shell's (drawing.js).

import { hex, opacity, jsRounded } from '../pixels.js';
import { formatNumber } from '../markup.js';

/** The road: [lon, lat, mile]. Every stop of the journey is a point here, at its mile. */
export const road = [
  [-95.94, 41.26, 0], [-98.34, 40.92, 154], [-100.77, 41.13, 291], [-102.26, 40.99, 377],
  [-104.82, 41.14, 516], [-105.45, 41.1, 553], [-105.6, 41.31, 573], [-107.24, 41.79, 709],
  [-109.47, 41.53, 845], [-110.96, 41.27, 955], [-111.97, 41.22, 1032], [-112.55, 41.62, 1084],
  [-113.4, 41.75, 1130], [-114.96, 41.11, 1225], [-115.76, 40.83, 1305], [-117.74, 40.97, 1430],
  [-118.6, 40.0, 1530], [-119.81, 39.53, 1620], [-120.33, 39.32, 1669], [-120.95, 39.1, 1721],
  [-121.49, 38.58, 1776],
];

export function project(lon, lat) {
  return { x: (lon + 124.6) * 7.8, y: (44.7 - lat) * 10 };
}

/** Where the train is, for a screen reader: "the Platte Valley", "Sherman Hill". */
export function place(v) {
  const name = v.region.name;
  return name.startsWith('The ') ? 'the ' + name.slice(4) : name;
}

// MARK: The country

export const coast = [
  [-124.6, 44.7], [-124.1, 44.7], [-124.4, 42.8], [-124.2, 41.8], [-124.3, 40.4], [-123.8, 39.4], [-123.0, 38.2],
  [-122.5, 37.8], [-122.4, 37.2], [-121.9, 36.6], [-121.3, 35.7], [-120.6, 34.6], [-120.5, 34.2], [-124.6, 34.2],
];

export const saltLake = [
  [-112.9, 41.58], [-112.45, 41.45], [-112.0, 41.05], [-112.3, 40.7], [-112.8, 40.9], [-113.0, 41.3],
];

export const rivers = [
  // The Missouri.
  [[-97.4, 44.7], [-96.4, 42.7], [-95.9, 41.5], [-95.8, 40.6], [-95.0, 39.8], [-94.6, 39.1]],
  // The Platte, and its north and south forks.
  [[-95.9, 41.05], [-97.2, 41.3], [-98.4, 40.8], [-99.6, 40.7], [-100.75, 41.1]],
  [[-100.75, 41.1], [-102.6, 41.3], [-104.0, 41.9], [-105.5, 42.75], [-106.6, 42.5], [-106.9, 41.3]],
  [[-100.75, 41.1], [-102.3, 40.9], [-103.6, 40.3], [-104.8, 40.2], [-105.0, 39.6]],
  // The Green.
  [[-110.0, 43.2], [-109.9, 42.2], [-109.5, 41.5], [-109.6, 40.6], [-110.0, 39.3]],
  // The Bear and the Weber, into the lake.
  [[-110.9, 41.3], [-111.2, 42.0], [-111.9, 42.4], [-112.2, 41.7]],
  // The Humboldt, and its sink.
  [[-115.2, 41.2], [-115.8, 40.8], [-117.0, 40.65], [-117.75, 40.97], [-118.3, 40.5], [-118.6, 40.0]],
  // The Truckee.
  [[-120.05, 39.2], [-119.8, 39.5], [-119.55, 39.95]],
  // The Sacramento and the San Joaquin, to the bay.
  [[-122.3, 40.6], [-122.0, 39.6], [-121.5, 38.6], [-121.9, 38.05], [-122.4, 37.9]],
  [[-120.8, 36.9], [-121.3, 37.8], [-121.9, 38.05]],
];

/** The two ranges, as rows of peaks, and a few of the basin's lesser ones. */
export const rockies = [
  [-105.4, 42.3], [-105.3, 41.6], [-105.5, 40.7], [-105.7, 40.0], [-106.2, 39.3], [-106.4, 40.5], [-106.5, 41.2],
  [-105.9, 38.6], [-106.8, 38.0], [-107.6, 37.7], [-109.3, 43.2], [-109.0, 42.8], [-108.8, 42.4],
  [-110.3, 40.75], [-109.6, 40.75], [-110.9, 40.7], [-111.6, 40.5], [-111.7, 41.0], [-111.5, 41.6], [-111.6, 39.8],
  [-111.4, 42.2], [-110.8, 43.6], [-110.6, 44.2],
];

export const sierra = [
  [-121.5, 40.5], [-121.0, 40.0], [-120.6, 39.6], [-120.3, 39.3], [-120.1, 38.8], [-119.7, 38.3], [-119.3, 37.8],
  [-118.9, 37.3], [-118.6, 36.8], [-118.3, 36.4], [-118.2, 35.8], [-121.9, 41.3], [-122.2, 41.4],
];

export const basin = [
  [-115.4, 40.4], [-115.3, 39.7], [-116.9, 39.3], [-117.2, 38.8], [-114.3, 39.0], [-116.2, 41.5], [-117.6, 41.7],
  [-114.2, 40.2],
];

/**
 * The three deserts the boiler cannot drink in: [west, east, south, north, colour]. East
 * and west are where the road enters and leaves each dry region (Rawlins to Green River,
 * Ogden to past Promontory, the Sink to the Truckee), so the stipple is under the marker
 * exactly while the tank car is being drunk from.
 */
export const deserts = [
  [-109.46, -107.25, 41.35, 42.3, 0xB5673F],
  [-115.2, -111.98, 40.3, 41.9, 0xE2DFD2],
  [-119.39, -118.62, 39.55, 40.0, 0xD2C8A8],
];

/** Swift's `x.rounded()`: halves away from zero. */
const rounded = (x) => Math.sign(x) * Math.round(Math.abs(x));

export function background(px) {
  const w = px.w, h = px.h;
  const P = (lon, lat) => project(lon, lat);
  // The mountain West, the plains east of it, and the sea.
  px.rect(0, 0, w, h, hex(0x2E3A2C));
  px.polygon([P(-104.6, 44.7), { x: w, y: 0 }, { x: w, y: h }, P(-103.6, 34.2), P(-104.2, 38), P(-104.9, 41)], hex(0x3D4A2E));
  px.polygon([P(-123.0, 40.3), P(-121.6, 40.2), P(-120.4, 37.4), P(-119.0, 35.2), P(-119.8, 35.0), P(-121.8, 37.4)],
    hex(0x3D4A2E));
  px.polygon(coast.map(([lon, lat]) => P(lon, lat)), hex(0x0D2A44));
  const grid = hex(0x384636);
  for (let lon = -120; lon <= -100; lon += 5) px.rect(Math.floor(P(lon, 0).x), 0, 1, h, grid);
  for (let lat = 36; lat <= 44; lat += 2) px.rect(0, Math.floor(P(0, lat).y), w, 1, grid);

  for (const d of deserts) {
    const a = P(d[0], d[3]), b = P(d[1], d[2]);
    const x0 = rounded(a.x), x1 = rounded(b.x), y0 = rounded(a.y), y1 = rounded(b.y);
    for (let y = y0; y <= y1; y++) {
      for (let x = x0; x <= x1; x++) {
        if ((x + y * 2) % 3 === 0) px.rect(x, y, 1, 1, opacity(hex(d[4]), 0.75));
      }
    }
  }

  const water = hex(0x4A8AB8);
  for (const river of rivers) {
    for (let i = 1; i < river.length; i++) {
      px.line(P(river[i - 1][0], river[i - 1][1]), P(river[i][0], river[i][1]), water);
    }
  }
  px.polygon(saltLake.map(([lon, lat]) => P(lon, lat)), water);
  for (const [lon, lat] of [[-120.05, 39.1], [-119.55, 40.05], [-111.75, 40.2]]) {
    const q = P(lon, lat);
    px.rect(Math.floor(q.x), Math.floor(q.y) - 1, 2, 3, water);
  }

  const peaks = (at, rock, snow) => {
    for (const [lon, lat] of at) {
      const q = project(lon, lat);
      const x = Math.floor(q.x), y = Math.floor(q.y);
      px.rect(x - 2, y + 1, 5, 1, hex(rock));
      px.rect(x - 1, y, 3, 1, hex(rock));
      px.rect(x, y - 1, 1, 1, snow ? hex(0xF4F7FA) : hex(rock));
    }
  };
  peaks(basin, 0x5E6656, false);
  peaks(rockies, 0x8A8F84, true);
  peaks(sierra, 0x9AA0A6, true);
}

/** The yards ringed, and the two ends named. */
export function names(px, J) {
  const ink = hex(0xD8D0B8);
  for (const stop of J.stops) {
    if (stop.type !== 'port') continue;
    const at = road.find((r) => Math.trunc(r[2]) === stop.mile);
    if (!at) continue;
    const q = project(at[0], at[1]);
    const x = jsRounded(q.x) - 3, y = jsRounded(q.y) - 3;
    px.rect(x + 1, y, 5, 1, ink);
    px.rect(x + 1, y + 6, 5, 1, ink);
    px.rect(x, y + 1, 1, 5, ink);
    px.rect(x + 6, y + 1, 1, 5, ink);
  }
  const east = project(road[0][0], road[0][1]), west = project(road[road.length - 1][0], road[road.length - 1][1]);
  px.text('OMAHA', east.x - 22, east.y - 4, 8, ink);
  px.text('SACRAMENTO', west.x - 4, west.y + 12, 8, ink);
}

/** The ChartSkin, for the journey's tables `J`. Functions of the voyage take the bridge's view. */
export function chart(J) {
  return {
    w: 240,
    h: 104,
    title: 'Map of the road',
    label: (v) => `Map of the railroad from Omaha to Sacramento. You are in ${place(v)}.`,
    footer: (v) => {
      const total = J.totalMiles, mile = v.state.mile;
      return `${formatNumber(mile)} of ${formatNumber(total)} miles covered. `
        + `${formatNumber(Math.max(0, total - mile))} to go. The ringed stops have a yard.`;
    },
    background: (px) => background(px),
    route: () => road.map(([x, y, mile]) => ({ x, y, mile })),
    others: () => [],
    project: (x, y) => project(x, y),
    routeStep: 16,
    travelledStep: 6,
    routeColor: hex(0x8A7F6A),
    overlay: (px) => names(px, J),
  };
}
