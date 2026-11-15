// 1849's chart (AroundTheHorn/Journeys/Horn1849Chart.swift, spec §8): a 230×210
// equirectangular map, x = (lon + 130) × 2, y = (45 − lat) × 2. The route, the sailed
// part, the stops and the blinking ship are the shell's (chart.js).

import { hex, jsRounded } from '../pixels.js';
import { formatNumber } from '../markup.js';

/** The prototype's `ROUTE`: [lon, lat, mile]. */
export const horn = [
  [-74, 40.7, 0], [-70, 37, 300], [-55, 30, 1300], [-38, 21, 2200], [-23.5, 15, 2900], [-28, 0, 3850],
  [-35, -10, 4500], [-43.2, -22.9, 5200], [-48, -33, 6000], [-57.9, -51.7, 7000], [-64, -55, 7350],
  [-67.3, -56.6, 7550], [-75.5, -53, 7800], [-74, -45, 8200], [-71.6, -33, 8900], [-77.1, -12, 10200],
  [-89.6, -0.9, 11300], [-110, 12, 12300], [-126, 28, 13300], [-122.4, 37.8, 14000],
];

/** The prototype's `ROUTE_M`, through the Strait. */
export const magellan = [
  [-74, 40.7, 0], [-70, 37, 300], [-55, 30, 1300], [-38, 21, 2200], [-23.5, 15, 2900], [-28, 0, 3850],
  [-35, -10, 4500], [-43.2, -22.9, 5200], [-48, -33, 6000], [-57.9, -51.7, 7000], [-64, -54, 7200],
  [-68.4, -52.4, 7350], [-70.9, -53.3, 7550], [-74.5, -52.7, 7800], [-74, -45, 8200], [-71.6, -33, 8900],
  [-77.1, -12, 10200], [-89.6, -0.9, 11300], [-110, 12, 12300], [-126, 28, 13300], [-122.4, 37.8, 14000],
];

/** The prototype's `LAND`: North & Central America, South America, West Africa, Cuba. */
export const land = [
  [[-124.5, 46], [-124.5, 45], [-124, 42], [-122.5, 37.8], [-120.5, 34.5], [-117, 32.5], [-114, 30], [-110, 23],
    [-105, 20], [-97, 16], [-92, 14.5], [-87.5, 13], [-85.7, 10], [-83, 8.2], [-80, 7.5], [-77.5, 8.5],
    [-79.5, 9.6], [-83.5, 11], [-83.5, 15], [-88, 15.8], [-87.5, 21.5], [-90.5, 21], [-91, 18.5], [-94.5, 18.3],
    [-97.5, 22], [-97, 27.8], [-94, 29.7], [-89, 30], [-84, 30], [-82.5, 27.5], [-81, 25.2], [-80.1, 26.8],
    [-81.2, 31], [-76, 35], [-75.5, 38.5], [-74, 40.5], [-70, 41.5], [-70, 43.5], [-67, 45], [-66, 46]],
  [[-77.5, 8.5], [-72, 12], [-63, 10.7], [-60, 8.5], [-52, 5], [-50, 0], [-44, -2.5], [-35, -5.5], [-35, -9],
    [-39, -13], [-39.5, -18], [-41, -22], [-44, -23], [-48.5, -27], [-51, -31], [-53.5, -34], [-58, -34.5],
    [-57, -37], [-62, -39], [-65, -42], [-67.5, -46], [-69, -50], [-68.5, -52.5], [-67, -55], [-68.5, -55.6],
    [-72, -54], [-75, -50], [-74, -45], [-73.5, -41], [-73.5, -37], [-71.6, -33], [-71.5, -28], [-70.3, -18.5],
    [-71.5, -17], [-76, -14], [-77.1, -12], [-79, -8], [-81.3, -5], [-80.5, -1], [-80, 1], [-78.8, 2], [-77.5, 7]],
  [[-17.5, 14.7], [-16.7, 12.5], [-13, 9], [-11, 6.5], [-7.5, 4.4], [0, 5], [0, 40], [-6, 36], [-9.5, 33],
    [-10, 30], [-13, 27.5], [-16, 23.5], [-17, 21], [-16, 18]],
  [[-85, 22], [-80, 23.2], [-75, 20], [-77.5, 19.8], [-82, 21.5]],
];

/** Cape Verde, the Falklands and the Galápagos, as little blocks. */
export const islands = [[-23.5, 15], [-24.5, 16.5], [-59, -51.7], [-60.5, -51.5], [-90.5, -0.6], [-91, -0.2]];

export function route(passage) {
  return passage === 'magellan' ? magellan : horn;
}

export function project(lon, lat) {
  return { x: (lon + 130) * 2, y: (45 - lat) * 2 };
}

/** Sea, graticule, the equator, and the land the prototype drew. */
export function background(px) {
  const w = px.w, h = px.h;
  px.rect(0, 0, w, h, hex(0x0D2A44));
  const grid = hex(0x173B5C);
  for (let lon = -120; lon <= -15; lon += 15) {
    for (let y = 0; y < h; y += 3) px.rect(project(lon, 0).x, y, 1, 1, grid);
  }
  for (let lat = 30; lat >= -60; lat -= 15) {
    for (let x = 0; x < w; x += 3) px.rect(x, project(0, lat).y, 1, 1, grid);
  }
  for (let x = 0; x < w; x += 2) px.rect(x, project(0, 0).y, 1, 1, hex(0x2F6A96));
  const landColor = hex(0xB9A26C);
  for (const poly of land) px.polygon(poly.map(([lon, lat]) => project(lon, lat)), landColor);
  for (const [lon, lat] of islands) {
    const q = project(lon, lat);
    px.rect(jsRounded(q.x) - 1, jsRounded(q.y) - 1, 3, 2, landColor);
  }
}

/** The ChartSkin. Functions of the voyage take the bridge's view (`v.state` the state). */
export const chart = {
  w: 230,
  h: 210,
  title: 'Chart of the voyage',
  label: (v) => `Chart of the route from New York to San Francisco. You are near ${v.region.name}.`,
  footer: (v) => `${formatNumber(v.state.mile)} of 14,000 nautical miles sailed. ${formatNumber(14000 - v.state.mile)} to go.`,
  background: (px) => background(px),
  route: (v) => route(v.state.passage).map(([x, y, mile]) => ({ x, y, mile })),
  others: () => [],
  project: (x, y) => project(x, y),
  routeStep: 90,
  travelledStep: 25,
  routeColor: hex(0x6D7F92),
  overlay: () => {},
};
