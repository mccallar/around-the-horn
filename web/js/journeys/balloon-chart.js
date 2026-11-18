// The Jet Stream's chart (AroundTheHorn/Journeys/BalloonChart.swift): the northern
// hemisphere looked down on from above the Pole, on a 230×210 grid, out to 12° N. Greenwich
// points down, Asia is on the right, the Pacific at the top and America on the left, so the
// flight goes round the page anticlockwise and comes back to where it began. A
// round-the-world flight doesn't fit a strip map. The route is given already projected, so
// the shell (drawing.js) moves the marker in straight lines on the page between points a
// few hundred miles apart.
//
// Which track she is on is the engine's answer (`v.hooks.balloon.southTrack`), as the app's
// `onSouthTrack` asks the engine's regions.

import { hex, opacity, jsRounded } from '../pixels.js';
import { formatNumber } from '../markup.js';
import { routePosition } from '../drawing.js';
import { whereabouts } from './balloon-scene.js';

export const w = 230, h = 210;
export const centre = { x: 115, y: 105 };

/** Pixels to a degree of latitude. */
export const scale = 1.25;

/** The map's rim: nothing south of it is drawn. */
export const rim = 12;

/**
 * Longitudes east of 180° are written past it (190 for 170° W), so the route never jumps
 * across the date line.
 */
export function project(lon, lat) {
  const r = (90 - lat) * scale, a = lon * Math.PI / 180;
  return { x: centre.x + r * Math.sin(a), y: centre.y + r * Math.cos(a) };
}

/** The northern track: [lon, lat, nm]. Every stop is a point at its mile. */
export const north = [
  [-8, 31.63, 0], [-6, 31.4, 100], [-1, 30.4, 370], [5, 29, 690], [12, 27.6, 1080],
  [20, 26.6, 1510], [27, 26, 1890], [32.64, 25.69, 2200], [37, 25.2, 2440], [43, 24.8, 2760],
  [48, 24.4, 3030], [53.5, 24.2, 3330], [57.5, 24.6, 3550], [62, 25.2, 3800], [67, 25, 4070],
  [73.02, 26.24, 4400], [77.2, 28.6, 4660], [81, 28.3, 4860], [84.5, 27.7, 5050],
  [88, 26.8, 5250], [92, 26.3, 5460], [97, 25.5, 5740], [103, 25, 6070], [110, 25.3, 6450],
  [117, 26.5, 6840], [122, 28.3, 7130], [127, 31, 7430], [130.3, 33.25, 7650],
  [133.5, 33.3, 7800], [140, 35.5, 8150], [150, 38.5, 8660], [160, 40.5, 9140],
  [170, 41.5, 9600], [180, 42, 10050], [190, 42, 10490], [200, 41.5, 10940],
  [210, 41, 11390], [220, 40, 11850], [230, 39, 12310], [236.2, 39.4, 12600],
  [242, 37.5, 12910], [248, 36.5, 13210], [253.35, 35.08, 13500], [260, 35.5, 13820],
  [270, 35.5, 14310], [278, 36, 14700], [284.3, 36.02, 15000], [295, 37.5, 15520],
  [310, 38.5, 16220], [322, 38.5, 16770], [334.3, 37.75, 17350], [345, 35, 17890],
  [350.2, 32.3, 18200], [352, 31.63, 18300],
];

/**
 * The southern track, where it leaves the northern one off Japan and until it meets it
 * again over Albuquerque.
 */
export const southern = [
  [140, 31, 8120], [150, 28, 8600], [160, 26, 9090], [170, 25, 9570], [180, 24.5, 10050],
  [190, 28, 10490], [200, 28.5, 10900], [210, 29, 11300], [220, 30, 11700], [230, 31, 12100],
  [242.8, 32.7, 12600], [248, 33.5, 13040],
];

export const south = [...north.filter((p) => p[2] <= 7800), ...southern, ...north.filter((p) => p[2] >= 13500)];

export function projected(track) {
  return track.map(([lon, lat, mile]) => {
    const q = project(lon, lat);
    return { x: q.x, y: q.y, mile };
  });
}

export const northRoute = projected(north);
export const southRoute = projected(south);

/** Whether the flight has taken the southern track, as the engine's own regions say. */
export const onSouthTrack = (v) => v.hooks.balloon.southTrack;

/** Where the tracks part: until it is behind her, the southern track is still open. */
export function forkIndex(J) {
  const i = J.stops.findIndex((s) => s.type === 'fork');
  return i < 0 ? 0 : i;
}

// MARK: The northern hemisphere

export const space = 0x0A0E14;
export const ocean = 0x0D2A44;
export const land = 0xB9A26C;

/** Coasts, filled in this order; the seas after them are cut out of the land. */
export const shapes = [
  // North Africa.
  { sea: false, points: [[-17.5, 14.7], [-16.8, 12], [0, 12], [15, 12], [30, 12], [43, 12], [42.5, 14], [39.5, 15.5], [37.2, 19],
    [35.5, 23.9], [33.5, 27.5], [32.5, 29.9], [32.3, 31.2], [30, 31.3], [25, 31.6], [20, 30.8], [19, 30.3],
    [15, 32.4], [11, 33.5], [10.5, 36.9], [8, 37], [3, 36.8], [-1, 35.7], [-5.4, 35.9], [-6.8, 34],
    [-9.8, 31.5], [-9.6, 30.4], [-11.5, 28], [-13, 27.5], [-16, 23.7], [-17, 21], [-16, 18], [-16.5, 16]] },
  // Eurasia.
  { sea: false, points: [[-9, 43], [-9.5, 39], [-9, 37], [-6, 36.2], [-5.4, 36.1], [-2, 36.8], [0, 38.7], [3, 42], [3.2, 43.2],
    [6, 43], [8.5, 44.4], [10.5, 43.6], [12.5, 41.8], [15.6, 40.1], [16, 38], [17.1, 39], [18.5, 40.2],
    [16, 41.5], [13.5, 43.6], [12.3, 45.4], [13.7, 45.6], [19.4, 41.9], [21, 40], [22.9, 36.4], [24, 38],
    [26, 40.3], [29, 41], [27.2, 37], [30.5, 36.8], [36, 36.6], [35.6, 34.6], [34.5, 31.5], [32.3, 31.2],
    [32.5, 29.9], [34.5, 28], [35, 29.5], [36.5, 26], [39, 21.5], [42.7, 16.5], [43.4, 12.7], [45, 12.8],
    [49, 14.5], [52.2, 15.6], [55, 17], [57.7, 18.9], [59.8, 22.5], [58.6, 23.6], [56.4, 26.3], [55.4, 25.3],
    [52, 24], [51.5, 25.8], [50.2, 26.2], [48, 29.4], [50, 30], [54, 27], [56.4, 27.1], [61.5, 25.2],
    [66.8, 24.8], [68.5, 23.4], [70, 22.5], [72.7, 21.2], [72.8, 19], [73.7, 15.5], [74.6, 12.9], [74.9, 12],
    [80, 12], [80.3, 13.1], [82.3, 17], [85.8, 19.8], [87, 21.6], [88.5, 22], [90.5, 22.5], [92, 21.3],
    [94.2, 18], [94.4, 16], [95.5, 15.8], [97.6, 16.5], [98.6, 12], [100, 12], [100, 13.4], [100.9, 12.7],
    [102.5, 12], [109.2, 12], [109.3, 13.8], [108.8, 15.5], [106.5, 17.5], [105.8, 19], [106.7, 20.7],
    [108, 21.5], [110.3, 21], [111.5, 21.6], [113.5, 22.2], [117, 23.5], [119.5, 26], [121.9, 30.9],
    [120.5, 33.5], [119.2, 35], [122.6, 37.4], [119, 37.2], [117.7, 38.9], [121.5, 40.9], [121.3, 38.8],
    [124.3, 40], [125.2, 37.7], [126.5, 34.5], [129.3, 35.1], [129.5, 37], [128.3, 38.7], [129.8, 41],
    [130.7, 42.3], [133, 42.8], [135.5, 43.9], [138, 46.5], [140.4, 48.5], [141.4, 52.2], [140, 54],
    [137, 54], [143, 59.3], [151, 59.5], [155, 59], [156.5, 57.5], [156.7, 51], [160, 53], [162.5, 56],
    [163.5, 59.8], [170, 60], [177, 62.5], [180, 65], [190, 66], [190.3, 66.1], [180, 69], [160, 70],
    [140, 72.5], [113, 73.7], [104, 77.5], [80, 73.5], [70, 73], [68, 68.5], [60, 69.5], [44, 68.5],
    [33, 69.3], [20, 70], [15, 68.5], [5.5, 62], [5.5, 58.5], [8, 58], [10.5, 59.4], [12, 56], [8.5, 57],
    [8.6, 55], [8.6, 53.6], [4.8, 52.9], [2, 51], [-1.5, 49.7], [-4.6, 48.5], [-1.2, 46], [-1.6, 43.4]] },
  // North America.
  { sea: false, points: [[-86.8, 12], [-83.7, 12], [-83.4, 15], [-88, 15.8], [-87.5, 21.5], [-90.5, 21], [-91, 18.5],
    [-94.5, 18.3], [-97.5, 22], [-97, 27.8], [-94, 29.7], [-89, 30], [-84, 30], [-82.5, 27.5], [-81, 25.2],
    [-80.1, 26.8], [-81.2, 31], [-76, 35], [-75.5, 38.5], [-74, 40.5], [-70, 41.5], [-70, 43.5],
    [-66, 44.5], [-65.5, 43.5], [-60, 46], [-64.5, 48.5], [-59, 48], [-56, 52], [-60, 55.5], [-64.5, 60.3],
    [-70, 61], [-78, 62.5], [-77, 60], [-78, 55], [-80, 51.5], [-82.5, 53], [-87.5, 55.5], [-94.5, 59],
    [-94, 61.5], [-88, 64], [-87, 67], [-95, 68], [-110, 68], [-125, 69.5], [-135, 69], [-141, 69.7],
    [-156.5, 71.3], [-166, 68.8], [-165, 66], [-168, 65.6], [-165, 64.5], [-162, 60], [-158, 58.5],
    [-163, 55], [-158, 56.5], [-152, 59], [-150, 61], [-146, 60.5], [-140, 59.8], [-136, 58.3], [-133, 55],
    [-130, 54], [-128, 51], [-124.5, 48.5], [-124.5, 46], [-124, 42], [-122.5, 37.8], [-120.5, 34.5],
    [-117.1, 32.5], [-115.8, 30.4], [-114.1, 28], [-112.2, 24.8], [-109.9, 22.9], [-110.3, 24.2],
    [-112.5, 27.5], [-114.8, 31.5], [-112.2, 29.6], [-109.5, 26], [-106.4, 23.2], [-105.3, 20.4],
    [-103, 18.2], [-99.9, 16.8], [-96, 15.7], [-94.2, 16.1], [-92.2, 14.5], [-89.8, 13.5], [-87.6, 13.1]] },
  // Greenland, Iceland, Great Britain, Ireland.
  { sea: false, points: [[-73, 78], [-60, 82], [-30, 83.5], [-12, 81.5], [-18.5, 76.5], [-22, 70.5], [-32, 68], [-40, 65],
    [-43.3, 60], [-48, 61], [-53, 66], [-54, 70], [-58, 75.5], [-68, 76.5]] },
  { sea: false, points: [[-24, 65.5], [-22, 66.4], [-16, 66.5], [-13.5, 65.2], [-15, 64.2], [-18.5, 63.4], [-22.5, 63.8]] },
  { sea: false, points: [[-5.7, 50], [1.4, 51.2], [1.7, 52.7], [0, 53.5], [-1.6, 55.6], [-2, 57.7], [-4, 58.6], [-5, 58.6],
    [-6.2, 56.7], [-4.9, 55], [-3, 53.3], [-4.7, 52.8], [-5.3, 51.9], [-3.2, 51.4]] },
  { sea: false, points: [[-10, 51.6], [-6, 52.2], [-6, 54.2], [-7.5, 55.3], [-10, 54.2]] },
  // Japan, Taiwan, Hainan, Luzon, Cuba, Hispaniola.
  { sea: false, points: [[129.6, 33.2], [130.5, 31], [131.7, 31.6], [132, 33.7], [133.5, 33.2], [134.7, 33.9], [136.9, 34.2],
    [139, 34.6], [140.9, 35.7], [141, 38.3], [142, 39.5], [141.4, 41.4], [141, 41.8], [143.3, 41.9],
    [145.5, 43.3], [145.3, 44.3], [141.8, 45.5], [140.4, 43.3], [140, 41.5], [140, 40], [139.5, 38.2],
    [136.8, 37.3], [135.4, 35.7], [132.5, 35.4], [130.9, 34.1]] },
  { sea: false, points: [[120.1, 23], [121, 25.2], [121.9, 25], [121, 22]] },
  { sea: false, points: [[108.7, 19.3], [110.6, 20.1], [111, 19.6], [109.5, 18.2]] },
  { sea: false, points: [[120, 14.5], [120.6, 18.5], [122.2, 18.5], [121.6, 15.5], [124, 13.5], [121, 13.6]] },
  { sea: false, points: [[-85, 22], [-80, 23.2], [-75, 20], [-77.5, 19.8], [-82, 21.5]] },
  { sea: false, points: [[-74.4, 19.8], [-68.4, 19], [-68.6, 18.2], [-74.5, 18.3]] },
  // The Canadian Arctic: Baffin, Devon, Ellesmere, Victoria and Banks Islands.
  { sea: false, points: [[-64.5, 61.9], [-65.5, 62.9], [-62, 66.5], [-63.5, 67.5], [-67.5, 69.5], [-70, 70.6], [-75, 72],
    [-80, 73.5], [-86, 73.5], [-89, 72.5], [-85, 70], [-81.5, 69.5], [-82, 68.5], [-75, 67.2], [-73, 66.2],
    [-77.5, 64.9], [-74, 64.4], [-71, 62.8], [-68, 62.2]] },
  { sea: false, points: [[-80, 74.6], [-91, 74.6], [-92.5, 75.6], [-89, 76.6], [-80, 76.3]] },
  { sea: false, points: [[-79, 76.3], [-74, 78.3], [-70, 80], [-62, 82], [-64, 83], [-75, 83], [-90, 82], [-95, 81], [-93, 79.5],
    [-87, 78.5], [-89, 77], [-82, 76.5]] },
  { sea: false, points: [[-101, 69], [-105, 68.8], [-110, 68.6], [-114, 69.3], [-117.5, 70.5], [-118.5, 71.5], [-114, 73.3],
    [-108, 73.5], [-105, 72.6], [-102, 71.5], [-100.5, 70]] },
  { sea: false, points: [[-125.5, 72], [-123, 71.2], [-120, 71.6], [-119.5, 72.6], [-120, 74.2], [-124, 74.3], [-125.5, 73.3]] },
  // Svalbard, Novaya Zemlya, Sakhalin.
  { sea: false, points: [[11, 78.8], [13.5, 77.6], [16.5, 76.6], [17.5, 77.4], [21, 77.8], [23, 78.4], [27.5, 79.8], [25, 80.4],
    [20, 80.5], [17, 79.9], [15, 79.7], [11, 79.7]] },
  { sea: false, points: [[52, 71.4], [53.5, 70.8], [57, 70.6], [55.5, 72.5], [57, 73.8], [60, 75], [64, 76.2], [68.5, 76.9],
    [66, 77], [61, 76.2], [58, 75.5], [55, 74.3], [54, 73], [53, 72.2]] },
  { sea: false, points: [[141.9, 46], [143.5, 46.5], [143, 47.5], [143.5, 49.3], [144.5, 49], [143.2, 51], [143.3, 52.5],
    [142.8, 54.3], [142.2, 54.2], [141.7, 53.4], [142.1, 51.5], [141.8, 48.5], [142.1, 47.2]] },
  // The Black Sea, the Caspian, and the Baltic with its gulfs.
  { sea: true, points: [[28, 41.5], [28.5, 43.5], [30.5, 46.5], [33.5, 46], [36.6, 45.3], [39.5, 44], [41.5, 41.5], [36, 41.7],
    [32, 41.2]] },
  { sea: true, points: [[47.5, 45.5], [49.5, 46.5], [52.5, 45.5], [51, 43.5], [53, 41.5], [53.5, 39], [54, 37.3], [50.5, 37],
    [49, 38.5], [49.5, 40.5], [47.5, 43]] },
  { sea: true, points: [[12.6, 56], [14.2, 55.4], [18, 54.8], [21, 55.2], [21.2, 56.8], [24, 57.2], [22, 58.5], [23.5, 59.2],
    [28, 59.7], [30, 60], [28, 60.5], [24, 60.2], [22.5, 60.2], [21.5, 61], [21.3, 63], [24.5, 64.8],
    [25.5, 65.3], [22.5, 65.9], [21.4, 64.6], [19.5, 63.5], [17.5, 62.3], [17.2, 61], [18.8, 60], [18.5, 59.4],
    [16.5, 57.8], [16, 56.2], [14.4, 56.1], [12.8, 56.6]] },
];

/** Islands too small to draw an outline of: Hawaii, the Azores, the Canaries. */
export const islets = [[-155.5, 19.6], [-157.9, 21.4], [-159.5, 22.1], [-25.7, 37.75], [-28, 38.6], [-31.2, 39.5], [-15.5, 28.1], [-17, 28.4]];

/**
 * An outline in canvas pixels. Where it runs along the rim, two points a long way apart on
 * it, the rim's arc is filled in, two degrees at a time, so the land meets the edge of the
 * map rather than cutting a chord across the sea.
 */
export function outline(points) {
  const out = [];
  points.forEach((p, i) => {
    out.push(project(p[0], p[1]));
    const q = points[(i + 1) % points.length];
    if (!(p[1] === rim && q[1] === rim && Math.abs(q[0] - p[0]) > 2)) return;
    const n = Math.trunc(Math.abs(q[0] - p[0]) / 2);
    for (let k = 1; k < Math.max(2, n); k++) {
      out.push(project(p[0] + (q[0] - p[0]) * k / n, rim));
    }
  });
  return out;
}

/**
 * Swift's `stride(from:through:by:)` over Doubles (`to:`, short of the end, with `through`
 * false): each value worked out from the start, not added up.
 */
function* stride(from, end, by, through = true) {
  for (let i = 0; ; i++) {
    const x = from + i * by;
    if (through ? x > end : x >= end) return;
    yield x;
  }
}

export function background(px) {
  px.rect(0, 0, px.w, px.h, hex(space));
  px.polygon(Array.from({ length: 180 }, (_, i) => project(i * 2, rim)), hex(ocean));
  const grid = hex(0x173B5C);
  for (const lat of [30.0, 60]) {
    for (const lon of stride(0.0, 360, 2, false)) dot(px, project(lon, lat), grid);
  }
  for (const lon of stride(0.0, 360, 30, false)) {
    for (const lat of stride(rim + 2, 88, 2)) dot(px, project(lon, lat), grid);
  }
  for (const shape of shapes) {
    px.polygon(outline(shape.points), hex(shape.sea ? ocean : land));
  }
  for (const [lon, lat] of islets) {
    const q = project(lon, lat);
    px.rect(jsRounded(q.x) - 1, jsRounded(q.y) - 1, 3, 2, hex(land));
  }
  for (const lon of stride(0.0, 360, 2, false)) dot(px, project(lon, rim), hex(0x2F6A96));
}

export function dot(px, q, color) {
  const x = jsRounded(q.x), y = jsRounded(q.y);
  if (!(x >= 0 && x < px.w && y >= 0 && y < px.h)) return;
  px.rect(x, y, 1, 1, color);
}

/** The landing fields ringed, on the way being flown, and a cross at the Pole. */
export function marks(px, J, chart, v) {
  const ink = hex(0xECE4CF);
  const route = chart.route(v);
  for (const stop of J.stops) {
    if (!J.ports.some((p) => p.id === stop.id)) continue;
    const q = routePosition(route, stop.mile, chart);
    const x = jsRounded(q.x) - 3, y = jsRounded(q.y) - 3;
    px.rect(x + 1, y, 5, 1, ink);
    px.rect(x + 1, y + 6, 5, 1, ink);
    px.rect(x, y + 1, 1, 5, ink);
    px.rect(x + 6, y + 1, 1, 5, ink);
  }
  px.rect(centre.x - 2, centre.y, 5, 1, opacity(ink, 0.6));
  px.rect(centre.x, centre.y - 2, 1, 5, opacity(ink, 0.6));
}

/** The ChartSkin, for the journey's tables `J`. Functions of the voyage take the bridge's view. */
export function chart(J) {
  const skin = {
    w,
    h,
    title: 'Chart of the flight',
    label: (v) => `Polar chart of the flight round the world, east from Marrakech and back. You are ${whereabouts(J, v.state, v.region)}.`,
    footer: (v) => {
      const total = J.totalMiles, mile = v.state.mile;
      return `${formatNumber(mile)} of ${formatNumber(total)} nautical miles flown. `
        + `${formatNumber(Math.max(0, total - mile))} to go. The ringed stops are landing fields.`;
    },
    background: (px) => background(px),
    route: (v) => (onSouthTrack(v) ? southRoute : northRoute),
    others: (v) => (v.state.stopIndex < forkIndex(J) && !onSouthTrack(v) ? [southRoute] : []),
    project: (x, y) => ({ x, y }),
    routeStep: 60,
    travelledStep: 25,
    routeColor: hex(0x6D7F92),
    overlay: (px, v) => marks(px, J, skin, v),
  };
  return skin;
}
