// What the shell draws around a skin's art: the scene's frame (ScenePicture.swift) and
// the chart's route, stops and marker (ChartView.swift). No DOM: these draw on any
// PixelCanvas (pixels.js).

import { Theme, jsRounded } from './pixels.js';

export const SCENE_W = 160;
export const SCENE_H = 80;

/**
 * What a skin's scene is asked to draw. With no voyage yet (the title card) it is the
 * journey's fair weather and a sound vessel. `v` is the bridge's view, or null. `date`
 * (`[year, month from 0, day]`) and `hooks` are what the view says of the state, for a
 * skin whose scene asks what the app's asks of its GameState: the date, the journey's rule
 * for its trouble.
 */
export function sceneFrame(J, v, moving, t) {
  const g = v?.state ?? null;
  return {
    t,
    weather: g?.weather ?? J.fairWeather,
    moving,
    atPort: g?.atPort ?? false,
    hull: g?.hull ?? 100,
    sails: g?.sails ?? 100,
    region: v?.region ?? null,
    hour: v?.hour ?? J.rules.startHour,
    state: g,
    date: v?.date ?? null,
    hooks: v?.hooks ?? null,
  };
}

/**
 * Where mile `m` falls on a route, in canvas pixels: straight between the two points
 * either side of it, worked out in the skin's map space and then projected.
 */
export function routePosition(route, m, chart) {
  if (!route.length) return { x: 0, y: 0 };
  for (let i = 1; i < route.length; i++) {
    if (m <= route[i].mile) {
      const a = route[i - 1], b = route[i];
      const span = b.mile - a.mile;
      const t = (m - a.mile) / (span === 0 ? 1 : span);
      return chart.project(a.x + (b.x - a.x) * t, a.y + (b.y - a.y) * t);
    }
  }
  const last = route[route.length - 1];
  return chart.project(last.x, last.y);
}

/** Swift's `stride(from: 0, through: end, by: step)`. */
function* through(end, step) {
  for (let i = 0; ; i++) {
    const m = i * step;
    if (m > end) return;
    yield m;
  }
}

/** ChartView.draw: the skin's map, the dotted route, the part travelled, stops, marker. */
export function drawChart(px, chart, J, v, t) {
  const g = v.state;
  chart.background(px, v, t);
  const dots = (route, end, step, color) => {
    if (!(step > 0)) return;
    for (const m of through(end, step)) {
      const q = routePosition(route, m, chart);
      px.rect(jsRounded(q.x), jsRounded(q.y), 1, 1, color);
    }
  };
  const route = chart.route(v);
  const total = J.totalMiles;
  for (const other of chart.others(v)) {
    dots(other, other.length ? other[other.length - 1].mile : total, chart.routeStep * 2, chart.routeColor);
  }
  dots(route, total, chart.routeStep, chart.routeColor);
  dots(route, g.mile, chart.travelledStep, Theme.amber);
  J.stops.forEach((s, i) => {
    const q = routePosition(route, s.mile, chart);
    px.rect(jsRounded(q.x) - 1, jsRounded(q.y) - 1, 3, 3, i <= g.stopIndex ? Theme.amber : Theme.ink);
  });
  if (Math.floor(t * 2) % 2 === 0) {
    const q = routePosition(route, g.mile, chart);
    px.rect(jsRounded(q.x) - 2, jsRounded(q.y) - 2, 5, 5, Theme.red);
  }
  chart.overlay(px, v, t);
}
