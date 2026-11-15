// The mini-game (AroundTheHorn/UI/Screens/FishingView.swift): its simulation, stepped with
// dt ≤ 0.05 s, what a catch is worth as the player reads it, and its drawing. No DOM.
//
// The field (its size, where a throw starts, which way it goes) is the skin's; the quarry
// and how long there is are the journey's. In 1849 that is fish under a boat.

import { Theme, opacity } from './pixels.js';
import * as Stores from './stores.js';

export class FishingModel {
  /**
   * `useTackle` spends one throw and says whether there was one; `tackleLeft` counts what
   * is left; `pop(fish)` is what floats up from a hit; `random` gives [0, 1).
   */
  constructor({ field, quarry, seconds, padding, pop = (f) => `+${f.lb}`, random = Math.random, useTackle, tackleLeft }) {
    this.field = field;
    this.quarry = quarry;
    this.time = seconds;
    this.padding = padding;
    this.pop = pop;
    this.random = random;
    this.useTackle = useTackle;
    this.tackleLeft = tackleLeft;
    this.fish = [];
    this.harpoon = null;
    this.pops = [];
    this.caught = 0;
    this.ended = false;
    this.spawnTimer = 0;
    this.onCatch = () => {};
    if (!quarry.length) return;
    for (let i = 0; i < 4; i++) {
      this.spawn();
      this.fish[i].x = this.rnd(20, field.w - 20);
    }
  }

  rnd(a, b) {
    return a + this.random() * (b - a);
  }

  spawn() {
    if (!this.quarry.length) return;
    let kind = this.quarry[0];
    const total = this.quarry.reduce((s, f) => s + f.weight, 0);
    let r = this.random() * total;
    for (const f of this.quarry) {
      r -= f.weight;
      if (r <= 0) {
        kind = f;
        break;
      }
    }
    const flip = this.random() < 0.5;
    const dir = this.field.oneWay || flip ? 1 : -1;
    const s = {
      kind,
      x: dir > 0 ? -kind.width : this.field.w + kind.width,
      y0: this.rnd(this.field.lanes[0], this.field.lanes[1]),
      y: 0,
      vx: dir * this.rnd(kind.speed[0], kind.speed[1]),
      t: this.rnd(0, 6),
      wf: this.rnd(1.5, 3),
      wa: this.rnd(1, 4),
    };
    // The prototype sets y on the first frame, before anything can be tapped.
    s.y = s.y0 + Math.sin(s.t * s.wf) * s.wa;
    this.fish.push(s);
  }

  inReach(y) {
    return this.field.upward ? y <= this.field.line : y >= this.field.line;
  }

  /** A tap on the field at logical (x, y). One throw in flight at a time. */
  throwAt(x, y) {
    if (this.harpoon || this.ended || !this.inReach(y) || !(this.tackleLeft() > 0) || !this.useTackle()) return;
    const o = this.field.origin;
    const dx = x - o.x, dy = y - o.y;
    const l = Math.max(Math.hypot(dx, dy), 1);
    this.harpoon = { x: o.x, y: o.y, vx: dx / l * this.field.speed, vy: dy / l * this.field.speed };
  }

  /** Screen readers can't aim, so their throw goes at whatever is nearest the thrower. */
  aimAtNearest() {
    const f = this.field;
    const near = this.fish.filter((q) => q.x > 0 && q.x < f.w);
    if (!near.length) return;
    const q = near.reduce((a, b) => (Math.abs(b.x - f.origin.x) < Math.abs(a.x - f.origin.x) ? b : a));
    this.throwAt(q.x, q.y);
  }

  step(rawDt) {
    if (this.ended) return;
    const dt = Math.min(0.05, Math.max(0, rawDt));
    this.time -= dt;
    this.spawnTimer -= dt;
    if (this.spawnTimer <= 0) {
      this.spawnTimer = this.rnd(0.5, 1.1);
      this.spawn();
    }
    for (const f of this.fish) {
      f.x += f.vx * dt;
      f.t += dt;
      f.y = f.y0 + Math.sin(f.t * f.wf) * f.wa;
    }
    this.fish = this.fish.filter((f) => !(f.x <= -40 || f.x >= this.field.w + 40));
    for (const p of this.pops) {
      p.t -= dt * 0.8;
      p.y -= dt * 12;
    }
    this.pops = this.pops.filter((p) => !(p.t <= 0));
    const h = this.harpoon;
    if (h) {
      h.x += h.vx * dt;
      h.y += h.vy * dt;
      const i = this.fish.findIndex((f) => Math.abs(h.x - f.x) < f.kind.width / 2 + this.padding
        && Math.abs(h.y - f.y) < f.kind.height / 2 + this.padding);
      if (i >= 0) {
        const [f] = this.fish.splice(i, 1);
        this.caught += f.kind.lb;
        this.pops.push({ x: f.x, y: f.y, t: 1, text: this.pop(f.kind) });
        this.harpoon = null;
        this.onCatch(f.kind);
      } else if (h.x < -5 || h.x > this.field.w + 5 || h.y > this.field.h + 5 || h.y < -5) {
        this.harpoon = null;
      }
    }
    if (this.time <= 0 || (this.tackleLeft() <= 0 && !this.harpoon)) this.ended = true;
  }

  stop() {
    this.ended = true;
  }
}

/**
 * What a catch is stowed as, and how the skin has that item counted: the one place the
 * model's amounts, a role's `catchLimit` and a quarry's `lb` (all stored units) are
 * turned into what the player reads.
 */
export function reward(J, words) {
  const item = J.items.find((i) => i.key === J.forageReward);
  const how = Stores.counting(item, words);
  return {
    item,
    how,
    /** With its unit: "12 lbs". */
    measure: (stored) => Stores.measure(stored, item, how),
    /** The bare number: "12". */
    count: (stored) => Stores.count(stored, item, how),
  };
}

/** What floats up from a hit: the skin's words round the shell's number. */
export function popText(forage, rw) {
  return (f) => forage.pop(rw.count(f.lb), f);
}

/** Where a pop `width` wide starts, for a hit at `x`, kept inside the field. */
export function popX(x, width, field) {
  return Math.max(0, Math.min(x - 6, field - 1 - width));
}

/** The skin's backdrop, quarry and throw; what floats up from a hit is the shell's. */
export function drawFishing(px, forage, m, now) {
  forage.backdrop(px, now);
  for (const f of m.fish) forage.quarry(px, f);
  if (m.harpoon) forage.thrown(px, m.harpoon);
  for (const p of m.pops) {
    const x = popX(p.x, px.width(p.text, 8), px.w);
    px.text(p.text, x, p.y, 8, opacity(Theme.amber, p.t));
  }
}
