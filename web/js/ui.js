// Draws the screens screens.js describes, in the page, and turns taps and keys into the
// flow's actions. The app's shell (RootView.swift): the top bar with the sound toggle, a
// column at most 540 wide, numbered choices, pixel canvases scaled up crisply.

import { describe } from './screens.js';
import { toHTML, html } from './markup.js';
import { ContextCanvas } from './pixels.js';
import { SCENE_W, SCENE_H, sceneFrame, drawChart } from './drawing.js';
import { drawFishing } from './fishing.js';

/** A health or condition bar's colour: green above 60, amber above 30, else red. */
const barColor = (v) => (v > 60 ? 'var(--green)' : v > 30 ? 'var(--amber)' : 'var(--red)');

const cls = (...names) => names.filter(Boolean).join(' ');

/** One block as HTML. Canvases and fields are made once per screen and kept. */
function blockHTML(b) {
  switch (b.type) {
    case 'heading': return `<h2>${html(b.text)}</h2>`;
    case 'para': return `<p class="${cls('mk', b.size === 18 && 'small', b.color)}">${toHTML(b.markup)}</p>`;
    case 'message': return `<div class="msg mk">${toHTML(b.markup)}</div>`;
    case 'title': return `<h1 aria-label="${html(b.label)}">${b.text.split('\n').map(html).join('<br>')}</h1>`;
    case 'center': return `<p class="${cls('center', b.color)}">${html(b.text)}</p>`;
    case 'row': return `<div class="${cls('row', b.total && 'total')}"><span class="mk">${toHTML(b.label)}</span>`
      + `<span${b.color ? ` class="${b.color}"` : ''}>${html(b.value)}</span></div>`;
    case 'bar': return `<div class="bar" role="img" aria-label="${Math.round(b.value)} percent">`
      + `<i style="width:${Math.min(100, Math.max(0, b.value))}%;background:${barColor(b.value)}"></i></div>`;
    case 'box': return `<div class="box">${b.blocks.map(blockHTML).join('')}</div>`;
    case 'status':
      return `<div class="status"><div class="amber">${html(b.date)} <span class="dim small">· ${html(b.region)}</span></div>`
        + b.rows.map(blockHTML).join('') + `<div class="note">${html(b.note)}</div></div>`;
    case 'fieldLabel': return `<label class="fld">${html(b.text)}</label>`;
    case 'cash':
      return `<div class="box row"><span>${html(b.cash)}</span><span>Bill <span class="${b.over ? 'red' : 'amber'}">`
        + `${html(b.bill)}</span></span></div>`;
    case 'item':
      return `<div class="item"><div><div>${html(b.name)} <span class="dim small">${html(b.price)}</span></div>`
        + `<div class="dim small have">${html(b.have)}</div></div>`
        + `<div class="qty" aria-label="${html(`${b.qty} ${b.qtyUnit} in the cart`)}">`
        + `<button type="button" data-step="-1" aria-label="${html(`Less ${b.name}`)}">−</button>`
        + `<span class="count" aria-hidden="true">${b.qty}</span>`
        + `<button type="button" data-step="1" aria-label="${html(`More ${b.name}`)}">+</button></div></div>`;
    case 'place':
      return `<div class="${cls('place', b.highlight && 'amber')}"><span class="who">${html(b.text)}</span>`
        + `<span class="dim small">${html(b.rank)}</span><span class="score">${html(b.score)}</span></div>`;
    case 'crew':
      return `<div class="crew"><div class="row"><span>${html(b.name)}<span class="dim small">${html(b.tag)}</span></span>`
        + `<span class="${cls('small', b.ailing ? 'red' : 'dim')}">${html(b.condition)}</span></div>`
        + blockHTML({ type: 'bar', value: b.hp }) + '</div>';
    case 'small': return `<div class="small dim">${html(b.text)}</div>`;
    case 'grave':
      return `<div class="grave"><div>${html(b.name)}<span class="dim small">${html(b.rest)}</span></div>`
        + `<div class="small teal">${html(b.epitaph)}</div></div>`;
    case 'legend':
      return `<div class="legend">${b.items.map((x) => `<span${x.color ? ` class="${x.color}"` : ''} aria-label="${html(x.label)}">`
        + `${html(x.text)}</span>`).join('')}</div>`;
    case 'tally': return `<div class="row small tally">${b.items.map((x) => `<span>${html(x)}</span>`).join('')}</div>`;
    case 'rule': return '<div class="rule"></div>';
    default: throw new Error(`no way to draw a ${b.type}`);
  }
}

const KEPT = new Set(['scene', 'chart', 'fishing', 'field']);

export class UI {
  /**
   * `root`: the element the screen goes in; `bar`: the top bar's banner and sound button.
   * `synth`: plays the button click (the flow plays the rest).
   */
  constructor(flow, { root, banner, sound, synth, doc = document, win = window }) {
    this.flow = flow;
    this.root = root;
    this.banner = banner;
    this.soundButton = sound;
    this.synth = synth;
    this.doc = doc;
    this.win = win;
    this.renderedID = -1;
    this.cache = [];
    this.canvases = [];
    this.scheduled = false;
    this.start = win.performance.now();
    this.reduceMotion = win.matchMedia?.('(prefers-reduced-motion: reduce)').matches ?? false;
    this.lastFrame = null;

    flow.subscribe(() => this.schedule());
    sound.addEventListener('click', () => flow.setMuted(!flow.muted));
    doc.addEventListener('keydown', (e) => this.key(e));
    doc.addEventListener('visibilitychange', () => {
      if (doc.visibilityState === 'hidden') flow.background();
    });
    win.addEventListener('pagehide', () => flow.background());
    this.render();
    win.requestAnimationFrame((t) => this.frame(t));
  }

  schedule() {
    if (this.scheduled) return;
    this.scheduled = true;
    queueMicrotask(() => {
      this.scheduled = false;
      this.render();
    });
  }

  /** What the screen's text fields say, by id. */
  input() {
    const out = {};
    for (const el of this.root.querySelectorAll('input[data-field]')) out[el.dataset.field] = el.value;
    return out;
  }

  press(c) {
    if (!c || !c.enabled) return;
    if (!this.flow.muted) this.synth.play('click');
    c.act(this.input());
  }

  render() {
    const f = this.flow;
    let d;
    try {
      d = describe(f);
    } catch (e) {
      console.error(e);
      return;
    }
    this.d = d;
    this.banner.textContent = d.banner;
    this.soundButton.textContent = f.muted ? '♪ off' : '♪ on';
    this.soundButton.setAttribute('aria-label', f.muted ? 'Sound off' : 'Sound on');
    this.soundButton.title = 'Toggles sound';
    if (f.screenID !== this.renderedID) this.build(d);
    else this.update(d);
  }

  /** A new screen: everything made afresh, scrolled to the top. */
  build(d) {
    this.renderedID = this.flow.screenID;
    this.root.textContent = '';
    this.canvases = [];
    this.cache = [];
    d.blocks.forEach((b, i) => {
      const el = this.make(b);
      this.root.appendChild(el);
      this.cache[i] = { el, html: KEPT.has(b.type) ? null : blockHTML(b), type: b.type };
    });
    const list = this.doc.createElement('div');
    list.className = 'choices';
    this.root.appendChild(list);
    this.choiceList = list;
    this.choiceHTML = [];
    this.updateChoices(d);
    this.win.scrollTo(0, 0);
    this.paint();
  }

  /** The same screen, changed: only the blocks and buttons whose words changed are redrawn. */
  update(d) {
    const same = d.blocks.length === this.cache.length && d.blocks.every((b, i) => this.cache[i].type === b.type);
    if (!same) return this.build(d);
    d.blocks.forEach((b, i) => {
      const old = this.cache[i];
      if (KEPT.has(b.type)) {
        if (b.type === 'scene') old.el.setAttribute('aria-label', this.sceneLabel(b));
        else if (b.type !== 'field') old.el.setAttribute('aria-label', b.label);
        return;
      }
      const next = blockHTML(b);
      if (next === old.html) return;
      old.html = next;
      if (b.type === 'item') {
        // Patched, not replaced: a + held down must stay the same button.
        old.el.querySelector('.qty').setAttribute('aria-label', `${b.qty} ${b.qtyUnit} in the cart`);
        old.el.querySelector('.count').textContent = String(b.qty);
        old.el.querySelector('.have').textContent = b.have;
        return;
      }
      const el = this.make(b);
      old.el.replaceWith(el);
      old.el = el;
    });
    this.updateChoices(d);
    if (this.reduceMotion) this.paint();
  }

  make(b) {
    const t = this.doc.createElement('template');
    if (b.type === 'scene' || b.type === 'chart' || b.type === 'fishing') {
      const size = b.type === 'scene' ? [SCENE_W, SCENE_H]
        : b.type === 'chart' ? [this.flow.skin.chart.w, this.flow.skin.chart.h]
          : [this.flow.skin.forage.field.w, this.flow.skin.forage.field.h];
      const c = this.doc.createElement('canvas');
      c.className = cls('pix', b.type === 'fishing' && 'fish');
      c.width = size[0];
      c.height = size[1];
      c.setAttribute('role', 'img');
      c.setAttribute('aria-label', b.type === 'scene' ? this.sceneLabel(b) : b.label);
      const entry = { el: c, kind: b.type, w: size[0], h: size[1], moving: b.moving, shown: this.win.performance.now() };
      if (b.type === 'fishing') this.fishing(c, b);
      this.canvases.push(entry);
      return c;
    }
    if (b.type === 'field') {
      const i = this.doc.createElement('input');
      i.className = 'txt';
      i.type = 'text';
      i.dataset.field = b.id;
      i.maxLength = b.maxLength;
      i.placeholder = b.placeholder;
      i.setAttribute('aria-label', b.label);
      i.autocomplete = 'off';
      i.spellcheck = false;
      i.setAttribute('autocapitalize', b.sentences ? 'sentences' : 'words');
      i.setAttribute('autocorrect', 'off');
      return i;
    }
    t.innerHTML = blockHTML(b);
    const el = t.content.firstElementChild;
    if (b.type === 'item') this.repeaters(el, b);
    return el;
  }

  sceneLabel(b) {
    const f = this.flow;
    return f.skin.scene.label(sceneFrame(f.journey, f.v, b.moving, 0));
  }

  updateChoices(d) {
    const list = this.choiceList;
    const htmls = d.choices.map((c, i) => `<span class="num">${i + 1}.</span> ${toHTML(c.label)}`
      + (c.detail != null ? `<span class="detail mk">${toHTML(c.detail)}</span>` : ''));
    if (list.children.length !== d.choices.length) {
      list.textContent = '';
      this.choiceHTML = [];
      d.choices.forEach((c, i) => {
        const b = this.doc.createElement('button');
        b.type = 'button';
        b.addEventListener('click', () => this.press(this.d.choices[i]));
        list.appendChild(b);
      });
    }
    d.choices.forEach((c, i) => {
      const b = list.children[i];
      if (this.choiceHTML[i] !== htmls[i]) {
        b.innerHTML = htmls[i];
        this.choiceHTML[i] = htmls[i];
      }
      b.className = cls('choice', c.primary && 'primary');
      b.disabled = !c.enabled;
    });
  }

  /** The shop's − and +: one step on touch, and on while held. */
  repeaters(el, b) {
    for (const btn of el.querySelectorAll('button[data-step]')) {
      const dir = Number(btn.dataset.step);
      const step = () => {
        const item = this.d.blocks.find((x) => x.type === 'item' && x.key === b.key);
        return item ? (dir < 0 ? item.less() : item.more()) : false;
      };
      let timer = null;
      const stop = () => {
        btn.classList.remove('down');
        clearTimeout(timer);
        timer = null;
      };
      btn.addEventListener('pointerdown', (e) => {
        if (e.button !== 0) return;
        e.preventDefault();
        btn.classList.add('down');
        step();
        const again = (wait) => {
          timer = setTimeout(() => {
            if (step()) again(70);
            else stop();
          }, wait);
        };
        again(400);
      });
      for (const ev of ['pointerup', 'pointerleave', 'pointercancel']) btn.addEventListener(ev, stop);
      // A key press on a focused button (no pointer) is one step.
      btn.addEventListener('click', (e) => {
        if (e.detail === 0) step();
      });
    }
  }

  /** Taps on the sea throw a harpoon there. */
  fishing(c, b) {
    c.tabIndex = 0;
    c.setAttribute('aria-description', b.hint);
    c.addEventListener('click', (e) => {
      const s = this.flow.screen;
      if (s.name !== 'fishing') return;
      const r = c.getBoundingClientRect();
      const field = s.model.field;
      s.model.throwAt((e.clientX - r.left) / r.width * field.w, (e.clientY - r.top) / r.height * field.h);
    });
  }

  key(e) {
    if (e.ctrlKey || e.metaKey || e.altKey || e.repeat) return;
    const d = this.d;
    if (!d) return;
    const typing = e.target?.tagName === 'INPUT';
    if (typing || !d.keys) return;
    if (/^[1-9]$/.test(e.key)) {
      const c = d.choices[Number(e.key) - 1];
      if (c) {
        e.preventDefault();
        this.press(c);
      }
    } else if (e.key === 'Enter' && d.choices.length === 1 && e.target?.tagName !== 'BUTTON') {
      e.preventDefault();
      this.press(d.choices[0]);
    } else if (e.key === ' ' && this.flow.screen.name === 'fishing') {
      // No aiming from the keyboard: at whatever is nearest, as for a screen reader.
      e.preventDefault();
      this.flow.screen.model.aimAtNearest();
    }
  }

  /** The scene's clock, shared by every scene so the clouds don't jump between screens. */
  get sceneTime() {
    return (this.win.performance.now() - this.start) / 1000;
  }

  frame(now) {
    const dt = this.lastFrame == null ? 0 : (now - this.lastFrame) / 1000;
    this.lastFrame = now;
    const s = this.flow.screen;
    if (s.name === 'fishing' && !s.landed) this.flow.fishingStep(dt);
    if (!this.reduceMotion || s.name === 'fishing') this.paint();
    this.win.requestAnimationFrame((t) => this.frame(t));
  }

  /** Draws every canvas on the screen, each logical pixel a whole number of device pixels. */
  paint() {
    const f = this.flow;
    const dpr = this.win.devicePixelRatio || 1;
    for (const c of this.canvases) {
      if (!c.el.isConnected) continue;
      const k = Math.max(1, Math.round((c.el.clientWidth || c.w) * dpr / c.w));
      if (c.el.width !== c.w * k) {
        c.el.width = c.w * k;
        c.el.height = c.h * k;
      }
      const ctx = c.el.getContext('2d');
      ctx.clearRect(0, 0, c.el.width, c.el.height);
      const px = new ContextCanvas(ctx, c.w, c.h, k);
      try {
        if (c.kind === 'scene') {
          const t = this.reduceMotion ? 0 : this.sceneTime;
          f.skin.scene.draw(px, sceneFrame(f.journey, f.v, c.moving, t));
        } else if (c.kind === 'chart' && f.v) {
          const t = this.reduceMotion ? 0 : (this.win.performance.now() - c.shown) / 1000;
          drawChart(px, f.skin.chart, f.journey, f.v, t);
        } else if (c.kind === 'fishing' && f.screen.name === 'fishing') {
          drawFishing(px, f.skin.forage, f.screen.model, f.screen.now);
        }
      } catch (e) {
        console.error(e);
      }
    }
  }
}
