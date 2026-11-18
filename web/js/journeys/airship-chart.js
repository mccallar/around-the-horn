// Over the Pole's chart (AroundTheHorn/Journeys/AirshipChart.swift): the top of the world on
// a 230×210 grid, an azimuthal equidistant projection centred on the North Pole with Europe
// at the bottom, so the flight runs up the middle of the map from Rome to the Pole and on up
// to the Bering Strait. A straight chart fails near the Pole, where every meridian meets;
// this one keeps distances from the Pole true. The route is given already projected, so the
// shell (drawing.js) moves the marker in straight lines on the page: at the Pole longitude
// means nothing.

import { hex, opacity, jsRounded } from '../pixels.js';
import { formatNumber } from '../markup.js';
import { whereabouts } from './airship-scene.js';

export const w = 230, h = 210;
export const pole = { x: 115, y: 79.5 };

/** Pixels to a degree of latitude. */
export const scale = 2.5;

export function project(lon, lat) {
  const r = scale * (90 - lat), a = (lon - 15) * Math.PI / 180;
  return { x: pole.x + r * Math.sin(a), y: pole.y + r * Math.cos(a) };
}

/**
 * The flight: [lon, lat, km]. Every stop is a point here at its kilometre, and the Pole
 * twice (one point, two meridians) so each leg across the ice is a straight line. Both
 * heights beyond the Pole fly the same track.
 */
export const flight = [
  [12.59, 41.8, 0], [4.8, 43.4, 650], [4.84, 45.76, 900], [2.35, 48.85, 1290], [1.6, 50.9, 1530],
  [1.23, 52.43, 1700], [8, 57.8, 2430], [10.77, 59.9, 2750], [21.6, 66.56, 3650], [29.75, 70.07, 4200],
  [20.5, 74.5, 4800], [11.93, 78.93, 5300], [11.93, 90, 6550], [-156.48, 90, 6550], [-156.48, 71.39, 8600],
  [-160, 70.64, 8750], [-166.2, 68.87, 9060], [-166.78, 68.35, 9120], [-168.09, 65.6, 9430],
  [-165.41, 64.5, 9600],
];

/** The latitude `km` along the flight, straight between the points above. */
export function latitude(km) {
  for (let i = 1; i < flight.length; i++) {
    const a = flight[i - 1], b = flight[i];
    if (km <= b[2]) return km <= a[2] || b[2] === a[2] ? a[1] : a[1] + (b[1] - a[1]) * (km - a[2]) / (b[2] - a[2]);
  }
  return flight.length ? flight[flight.length - 1][1] : 0;
}

export const route = flight.map(([lon, lat, km]) => {
  const q = project(lon, lat);
  return { x: q.x, y: q.y, mile: km };
});

// MARK: The top of the world

export const ocean = 0x0D2A44;
export const land = 0xB9A26C;

/** Coasts, filled in this order; the seas are cut out of the land after it. */
export const shapes = [
  { sea: false, points: [[-9.5, 38.7], [-9.3, 43], [-1.8, 43.4], [-1.2, 46.2], [-4.6, 48.4], [-1.6, 49.6], [1.6, 50.9], [4, 51.5],
    [5, 53.3], [8, 53.6], [8.6, 55.5], [8.2, 57], [10.6, 57.7], [10.5, 56], [12.4, 55.4], [12.8, 56.6],
    [11.2, 58.4], [10.6, 59], [8, 58.1], [5.5, 58.8], [5, 60.4], [5, 62], [7.5, 63.2], [10.5, 64.6],
    [12.5, 66], [14, 67.5], [16, 68.8], [18.5, 69.8], [23, 70.8], [25.8, 71.1], [28.5, 70.9], [31, 70.4],
    [29.8, 69.9], [33, 69.4], [36.5, 69], [41, 67.7], [40, 66.3], [35, 66.2], [34.5, 64.5], [37.5, 63.9],
    [41, 64.5], [44, 66], [44.2, 68.5], [53, 68.8], [58, 68.9], [60.5, 69.8], [66, 69.3], [68.5, 68.2],
    [73, 66.5], [73, 40], [60, 40], [50, 40], [40, 40], [30, 40], [26, 40], [26, 36], [-6, 36]] },
  // The Mediterranean, the Adriatic, the Aegean, the Black Sea, the Caspian, the Baltic.
  { sea: true, points: [[-5.6, 36], [-2, 36.7], [0.2, 38.7], [-0.3, 39.4], [0.8, 41], [3.2, 41.9], [3.1, 43.1], [6.5, 43.1],
    [8.8, 44.4], [10.5, 42.9], [12.3, 41.7], [14, 40.8], [15.6, 40], [15.7, 38], [16.5, 38.4], [17.2, 39.4],
    [16.6, 40.4], [18.5, 40.2], [19.5, 40.5], [20, 39.5], [21.5, 38.3], [22.5, 36.4], [26.5, 35], [26.5, 30],
    [-6, 30]] },
  { sea: true, points: [[18.5, 40.2], [16.2, 41.3], [14, 42.5], [12.3, 44.2], [12.3, 45.4], [13.7, 45.7], [15, 44.5], [17.5, 43],
    [19.4, 41.8], [19.5, 40.5]] },
  { sea: true, points: [[22.5, 36.4], [23, 38.5], [22.6, 40.5], [24, 40.9], [26, 40.8], [26.7, 40], [26.5, 35]] },
  { sea: true, points: [[28, 41.5], [28.5, 43.5], [30, 45.5], [33.5, 46], [36.5, 45.3], [39, 47], [38, 44.5], [41.5, 41.5],
    [36, 41.7], [31, 41.2]] },
  { sea: true, points: [[47, 45], [50, 46.5], [53, 47], [53, 44], [51, 41], [50, 37.5], [49, 38], [47.5, 41], [47, 43]] },
  { sea: true, points: [[10.8, 54.4], [14, 54], [19.6, 54.5], [21.2, 55.5], [21, 57], [23.8, 57.3], [24.3, 58.2], [23.5, 59.2],
    [28, 59.5], [30.2, 59.9], [29, 60.2], [22.9, 60], [21.4, 60.7], [21.3, 62.5], [22.4, 63.8], [25.3, 65],
    [25, 65.7], [22.2, 65.8], [21, 64.5], [19, 63.5], [17.6, 62.5], [17.3, 61], [18.8, 60.2], [19, 59],
    [17, 58], [16.5, 56.5], [14.4, 55.6], [12.8, 55.8], [12.6, 54.5]] },
  // Britain and Ireland, Iceland, Greenland.
  { sea: false, points: [[-5.7, 50], [1.4, 51.2], [1.7, 52.7], [0.3, 53.5], [-1.6, 55.6], [-2, 57.6], [-3, 58.6], [-5, 58.6],
    [-6.2, 56.5], [-5, 55], [-3, 54], [-3.1, 53.3], [-4.6, 52.8], [-5.2, 51.7], [-3, 51.4]] },
  { sea: false, points: [[-6, 52.2], [-6.2, 54.2], [-7.5, 55.3], [-10, 54.2], [-10.2, 51.6], [-8, 51.6]] },
  { sea: false, points: [[-22.5, 64], [-24, 65.5], [-22, 66.4], [-16, 66.5], [-13.5, 65.2], [-15, 64.2], [-18.5, 63.4]] },
  { sea: false, points: [[-43, 59.8], [-50, 62], [-52.5, 64.5], [-53.5, 66.9], [-54, 70.5], [-56, 72.5], [-58.5, 75.5],
    [-66, 76], [-73, 78.3], [-65, 80.6], [-60, 81.8], [-50, 82.3], [-33.4, 83.65], [-22, 82.6],
    [-12, 81.6], [-18, 77], [-19, 74], [-22, 70.5], [-29, 68.2], [-34, 66], [-40, 65], [-42.5, 61]] },
  // Spitsbergen, Franz Josef Land, Novaya Zemlya.
  { sea: false, points: [[11, 78.6], [10.9, 79.7], [16, 80], [22, 79.8], [27, 80.1], [27, 79.3], [21, 78.6], [18, 77],
    [16.5, 76.6], [13.5, 77.6]] },
  { sea: false, points: [[44.5, 80.2], [50, 79.8], [62, 80.4], [64.5, 81.2], [58, 81.8], [49, 81.3]] },
  { sea: false, points: [[52, 71.5], [55.5, 73.5], [58, 75.5], [65, 76.8], [69, 77], [62, 75], [57, 72.5], [55, 70.6]] },
  // Siberia and its islands.
  { sea: false, points: [[73, 66.5], [72, 69], [69, 73], [73, 73.5], [80, 73.5], [87, 74], [100, 76.5], [104.3, 77.7],
    [113, 73.8], [128, 73], [140, 72.5], [150, 71], [160, 69.6], [170, 70], [180, 68.9], [-172, 66.5],
    [-169.7, 66.1], [-171.5, 64.5], [-177, 64.5], [-180, 65], [178, 64.5], [177, 62.5], [170, 60],
    [163, 59.5], [162, 56], [156.5, 51], [156, 57], [150, 59.5], [143, 59.3], [137, 54], [141, 52],
    [140, 48], [135, 43.5], [130, 42.5], [128, 40], [110, 40], [90, 40], [73, 40]] },
  { sea: false, points: [[95, 79], [105, 79.5], [104, 80.5], [97, 81.2]] },
  { sea: false, points: [[137, 75], [150, 75.5], [148, 76.2], [140, 76.2]] },
  // North America and the Canadian islands.
  { sea: false, points: [[-168.1, 65.6], [-164.5, 66.6], [-162.6, 66.9], [-164, 67.8], [-166.8, 68.35], [-166.2, 68.9],
    [-163, 69.9], [-160, 70.6], [-156.5, 71.4], [-152, 70.8], [-145, 70.1], [-141, 69.6], [-135, 69.5],
    [-129, 70], [-125, 69.4], [-117, 68.8], [-108, 68], [-98, 67.8], [-95, 68.5], [-89, 68.8],
    [-82, 69.5], [-81.5, 67], [-87, 64], [-94, 61], [-92.5, 57], [-82, 55], [-79, 51.5], [-77, 55.5],
    [-78, 62], [-73, 62.3], [-69.5, 59], [-64.5, 60.3], [-61, 56], [-56, 52], [-60, 50], [-65, 49],
    [-65, 45], [-80, 45], [-90, 45.5], [-100, 45], [-112, 46], [-125, 48], [-131, 54], [-137, 58.5],
    [-145, 60.3], [-152, 58.8], [-158, 56.5], [-162, 58.5], [-162, 60], [-165.4, 61], [-164.8, 63],
    [-161, 64.3], [-163, 64.6], [-165.4, 64.5], [-166.5, 65.2]] },
  { sea: false, points: [[-118, 69], [-110, 68.5], [-101.5, 69.5], [-104, 72.5], [-110, 73], [-117, 72.5], [-119, 71]] },
  { sea: false, points: [[-125, 71.8], [-120, 71.5], [-117.5, 73.5], [-120, 74.4], [-124.5, 74]] },
  { sea: false, points: [[-116, 74.5], [-109, 74.8], [-105, 75.8], [-110, 76.6], [-117, 76.3]] },
  { sea: false, points: [[-122, 75.8], [-117, 76.2], [-118.5, 77.4], [-123, 77]] },
  { sea: false, points: [[-80, 76.3], [-75, 78.5], [-68, 80.5], [-62, 82.5], [-70, 83.1], [-86, 81.5], [-90, 79], [-90, 77]] },
  { sea: false, points: [[-87, 78], [-92, 79], [-97, 80.3], [-92, 81.2], [-88, 79.6]] },
  { sea: false, points: [[-80, 74.5], [-92, 74.5], [-95, 76], [-84, 76.5]] },
  { sea: false, points: [[-80, 73.7], [-70, 70.5], [-66, 67], [-62, 66], [-66, 62.5], [-73, 64], [-78, 64.5], [-73, 67.5],
    [-84, 70], [-89, 72]] },
];

/** Islands too small to draw an outline of: Bear Island and Wrangel Island. */
export const islets = [[19, 74.43], [-179.5, 71.2]];

/** The midsummer sun's line, the chart's own equator. */
export const arcticCircle = 66.56;

/** Swift's `x.rounded()`: halves away from zero. */
const rounded = (x) => Math.sign(x) * Math.round(Math.abs(x));

export function background(px) {
  px.rect(0, 0, px.w, px.h, hex(ocean));
  // Circles of latitude every ten degrees and meridians every thirty, dotted.
  const grid = hex(0x173B5C);
  for (let lat = 80; lat >= 40; lat -= 10) circle(px, lat, 3, grid);
  for (let lon = -180; lon < 180; lon += 30) {
    for (let i = 0; 89 - i * 1.2 >= 37; i++) dot(px, project(lon, 89 - i * 1.2), grid);
  }
  for (const shape of shapes) {
    px.polygon(shape.points.map(([lon, lat]) => project(lon, lat)), hex(shape.sea ? ocean : land));
  }
  for (const [lon, lat] of islets) {
    const q = project(lon, lat);
    px.rect(jsRounded(q.x) - 1, jsRounded(q.y) - 1, 3, 2, hex(land));
  }
  circle(px, arcticCircle, 2, hex(0x2F6A96));
}

export function dot(px, q, color) {
  const x = jsRounded(q.x), y = jsRounded(q.y);
  if (!(x >= 0 && x < px.w && y >= 0 && y < px.h)) return;
  px.rect(x, y, 1, 1, color);
}

/** A circle of latitude, a dot every `every` pixels round it. */
export function circle(px, lat, every, color) {
  const r = scale * (90 - lat);
  const n = Math.max(12, Math.trunc(rounded(2 * Math.PI * r / every)));
  for (let i = 0; i < n; i++) {
    const a = i / n * 2 * Math.PI;
    dot(px, { x: pole.x + r * Math.sin(a), y: pole.y + r * Math.cos(a) }, color);
  }
}

/** The masts ringed, a cross at the Pole, and the two ends named. */
export function names(px, J) {
  const ink = hex(0xECE4CF);
  for (const stop of J.stops) {
    if (!J.ports.some((p) => p.id === stop.id)) continue;
    const at = route.find((r) => Math.trunc(r.mile) === stop.mile);
    if (!at) continue;
    const x = jsRounded(at.x) - 3, y = jsRounded(at.y) - 3;
    px.rect(x + 1, y, 5, 1, ink);
    px.rect(x + 1, y + 6, 5, 1, ink);
    px.rect(x, y + 1, 1, 5, ink);
    px.rect(x + 6, y + 1, 1, 5, ink);
  }
  px.rect(pole.x - 3, pole.y, 7, 1, opacity(ink, 0.6));
  px.rect(pole.x, pole.y - 3, 1, 7, opacity(ink, 0.6));
  const start = route[0], end = route[route.length - 1];
  px.text('ROME', start.x + 6, start.y + 4, 8, ink);
  px.text('NOME', end.x + 6, end.y + 4, 8, ink);
  px.text('POLE', pole.x + 5, pole.y - 2, 8, ink);
}

/** The ChartSkin, for the journey's tables `J`. Functions of the voyage take the bridge's view. */
export function chart(J) {
  return {
    w,
    h,
    title: 'Chart of the flight',
    label: (v) => `Polar chart of the flight from Rome over the North Pole to Nome. You are ${whereabouts(v.region)}.`,
    footer: (v) => {
      const total = J.totalMiles, mile = v.state.mile;
      return `${formatNumber(mile)} of ${formatNumber(total)} kilometres flown. `
        + `${formatNumber(Math.max(0, total - mile))} to go. The ringed stops have a mast.`;
    },
    background: (px) => background(px),
    route: () => route,
    others: () => [],
    project: (x, y) => ({ x, y }),
    routeStep: 60,
    travelledStep: 20,
    routeColor: hex(0x6D7F92),
    overlay: (px) => names(px, J),
  };
}
