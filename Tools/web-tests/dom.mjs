// Just enough of a browser's DOM for web/js/ui.js to run in Node: elements, a strict
// parser for the HTML ui.js writes (a tag closed out of order is an error), simple
// selectors, events, a canvas whose 2D context counts what is drawn on it, and a window
// whose clock and animation frames move only when told.

const VOID = new Set(['br', 'input', 'img', 'meta', 'link']);
const ENTITIES = { amp: '&', lt: '<', gt: '>', quot: '"', '#39': "'", apos: "'", nbsp: ' ' };

function decode(s) {
  return s.replace(/&(#?\w+);/g, (m, e) => {
    if (e in ENTITIES) return ENTITIES[e];
    if (/^#\d+$/.test(e)) return String.fromCodePoint(Number(e.slice(1)));
    throw new Error(`an unknown entity ${m}`);
  });
}

const escapeText = (s) => s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
const escapeAttr = (s) => escapeText(s).replace(/"/g, '&quot;');

export class TextNode {
  constructor(data) {
    this.nodeType = 3;
    this.data = data;
    this.parentNode = null;
  }
  get textContent() { return this.data; }
  get outerHTML() { return escapeText(this.data); }
}

class ClassList {
  constructor(el) { this.el = el; }
  get list() { return (this.el.getAttribute('class') ?? '').split(/\s+/).filter(Boolean); }
  contains(c) { return this.list.includes(c); }
  add(c) { if (!this.contains(c)) this.el.setAttribute('class', [...this.list, c].join(' ')); }
  remove(c) { this.el.setAttribute('class', this.list.filter((x) => x !== c).join(' ')); }
}

export class FakeContext2D {
  constructor(canvas) {
    this.canvas = canvas;
    this.ops = { fillRect: 0, fill: 0, stroke: 0, fillText: 0, clearRect: 0 };
    this.fillStyle = '#000';
    this.strokeStyle = '#000';
    this.font = '10px sans-serif';
  }
  fillRect(x, y, w, h) {
    for (const v of [x, y, w, h]) if (!Number.isFinite(v)) throw new Error('fillRect with a number that isn\'t one');
    if (!/^rgba\(\d+(\.\d+)?,\d+(\.\d+)?,\d+(\.\d+)?,[\d.]+\)$/.test(this.fillStyle)) throw new Error(`a bad colour ${this.fillStyle}`);
    this.ops.fillRect++;
  }
  clearRect() { this.ops.clearRect++; }
  beginPath() {}
  moveTo(x, y) { if (!Number.isFinite(x + y)) throw new Error('moveTo NaN'); }
  lineTo(x, y) { if (!Number.isFinite(x + y)) throw new Error('lineTo NaN'); }
  closePath() {}
  fill() { this.ops.fill++; }
  stroke() { this.ops.stroke++; }
  fillText(s, x, y) {
    if (!Number.isFinite(x + y)) throw new Error('fillText NaN');
    this.ops.fillText++;
    this.lastText = s;
  }
  measureText(s) {
    const px = Number(/(\d+(\.\d+)?)px/.exec(this.font)?.[1] ?? 10);
    return { width: [...s].length * px * 0.4 };
  }
}

export class Element {
  constructor(tag, doc) {
    this.tagName = tag.toUpperCase();
    this.nodeType = 1;
    this.ownerDocument = doc;
    this.attrs = new Map();
    this.childNodes = [];
    this.parentNode = null;
    this.listeners = new Map();
    this.classList = new ClassList(this);
    this.value = '';
    this.disabled = false;
    this.hidden = false;
    this.width = 300;
    this.height = 150;
    this.clientWidth = 360;
    this.clientLeft = 0;
    this.clientTop = 0;
    const el = this;
    this.dataset = new Proxy({}, {
      get: (_, k) => el.getAttribute(`data-${String(k).replace(/[A-Z]/g, (c) => `-${c.toLowerCase()}`)}`) ?? undefined,
      set: (_, k, v) => {
        el.setAttribute(`data-${String(k).replace(/[A-Z]/g, (c) => `-${c.toLowerCase()}`)}`, String(v));
        return true;
      },
    });
  }

  setAttribute(k, v) { this.attrs.set(k, String(v)); }
  getAttribute(k) { return this.attrs.has(k) ? this.attrs.get(k) : null; }
  removeAttribute(k) { this.attrs.delete(k); }
  hasAttribute(k) { return this.attrs.has(k); }
  get className() { return this.getAttribute('class') ?? ''; }
  set className(v) { this.setAttribute('class', v); }
  get id() { return this.getAttribute('id') ?? ''; }
  set title(v) { this.setAttribute('title', v); }
  get title() { return this.getAttribute('title') ?? ''; }
  set placeholder(v) { this.setAttribute('placeholder', v); }
  get placeholder() { return this.getAttribute('placeholder') ?? ''; }
  set maxLength(v) { this.setAttribute('maxlength', v); }
  get maxLength() { return Number(this.getAttribute('maxlength') ?? -1); }
  set type(v) { this.setAttribute('type', v); }
  get type() { return this.getAttribute('type') ?? ''; }
  set tabIndex(v) { this.setAttribute('tabindex', v); }

  get children() { return this.childNodes.filter((n) => n.nodeType === 1); }
  get firstElementChild() { return this.children[0] ?? null; }
  get firstChild() { return this.childNodes[0] ?? null; }

  appendChild(n) {
    n.parentNode?.removeChildNode?.(n);
    n.parentNode = this;
    this.childNodes.push(n);
    return n;
  }

  removeChildNode(n) {
    this.childNodes = this.childNodes.filter((x) => x !== n);
    n.parentNode = null;
  }

  replaceWith(n) {
    const p = this.parentNode;
    if (!p) throw new Error('replaceWith on an element with no parent');
    n.parentNode?.removeChildNode?.(n);
    const i = p.childNodes.indexOf(this);
    p.childNodes[i] = n;
    n.parentNode = p;
    this.parentNode = null;
  }

  get isConnected() {
    let n = this;
    while (n.parentNode) n = n.parentNode;
    return n === this.ownerDocument?.documentElement;
  }

  get textContent() { return this.childNodes.map((n) => n.textContent).join(''); }
  set textContent(v) {
    for (const n of this.childNodes) n.parentNode = null;
    this.childNodes = v === '' ? [] : [new TextNode(String(v))];
    for (const n of this.childNodes) n.parentNode = this;
  }

  /** The words a person sees: text, with a line break for <br>. */
  get innerText() {
    return this.childNodes.map((n) => (n.nodeType === 3 ? n.data : n.tagName === 'BR' ? '\n' : n.innerText)).join('');
  }

  get innerHTML() { return this.childNodes.map((n) => n.outerHTML).join(''); }
  set innerHTML(html) {
    for (const n of this.childNodes) n.parentNode = null;
    this.childNodes = [];
    for (const n of parse(html, this.ownerDocument)) this.appendChild(n);
  }

  get outerHTML() {
    const tag = this.tagName.toLowerCase();
    const attrs = [...this.attrs].map(([k, v]) => ` ${k}="${escapeAttr(v)}"`).join('');
    if (VOID.has(tag)) return `<${tag}${attrs}>`;
    return `<${tag}${attrs}>${this.innerHTML}</${tag}>`;
  }

  matches(sel) {
    const m = /^([a-z0-9]*)((?:\.[\w-]+)*)((?:\[[\w-]+(?:="[^"]*")?\])*)$/i.exec(sel.trim());
    if (!m) throw new Error(`a selector this DOM can't read: ${sel}`);
    const [, tag, classes, attrs] = m;
    if (tag && this.tagName !== tag.toUpperCase()) return false;
    for (const c of classes.split('.').filter(Boolean)) if (!this.classList.contains(c)) return false;
    for (const a of attrs.match(/\[[^\]]+\]/g) ?? []) {
      const [, k, v] = /^\[([\w-]+)(?:="([^"]*)")?\]$/.exec(a);
      if (!this.hasAttribute(k) || (v !== undefined && this.getAttribute(k) !== v)) return false;
    }
    return true;
  }

  /** Compound selectors, and descendants of them: "p span.it". */
  querySelectorAll(sel) {
    const parts = sel.trim().split(/\s+/);
    const last = parts.pop();
    const within = (el) => {
      let k = parts.length - 1;
      for (let a = el.parentNode; a && k >= 0; a = a === this ? null : a.parentNode) {
        if (a.nodeType === 1 && a.matches(parts[k])) k--;
      }
      return k < 0;
    };
    const out = [];
    const walk = (el) => {
      for (const c of el.children) {
        if (c.matches(last) && within(c)) out.push(c);
        walk(c);
      }
    };
    walk(this);
    return out;
  }

  querySelector(sel) { return this.querySelectorAll(sel)[0] ?? null; }

  addEventListener(type, fn) {
    if (!this.listeners.has(type)) this.listeners.set(type, []);
    this.listeners.get(type).push(fn);
  }

  dispatch(type, props = {}) {
    const e = { type, target: this, defaultPrevented: false, preventDefault() { this.defaultPrevented = true; }, ...props };
    for (const fn of this.listeners.get(type) ?? []) fn(e);
    return e;
  }

  click(props = {}) {
    if (this.disabled) return null;
    return this.dispatch('click', { detail: 1, button: 0, ...props });
  }

  /** A canvas's content box keeps the picture's shape, as `width: 100%` makes it. */
  get clientHeight() { return this.clientWidth * this.height / this.width; }

  /** The border box: the content box and a border of clientLeft by clientTop around it. */
  getBoundingClientRect() {
    const w = this.clientWidth + 2 * this.clientLeft;
    const h = this.clientHeight + 2 * this.clientTop;
    return { left: 0, top: 0, width: w, height: h, right: w, bottom: h };
  }

  getContext(kind) {
    if (this.tagName !== 'CANVAS' || kind !== '2d') throw new Error('getContext on something that is not a canvas');
    this.ctx ??= new FakeContext2D(this);
    return this.ctx;
  }
}

class TemplateElement extends Element {
  get content() { return { firstElementChild: this.firstElementChild, childNodes: this.childNodes }; }
}

/** HTML as ui.js writes it: attributes quoted, entities escaped. Anything else is an error. */
export function parse(html, doc) {
  const root = new Element('#root', doc);
  const stack = [root];
  let i = 0;
  while (i < html.length) {
    if (html[i] === '<') {
      if (html[i + 1] === '/') {
        const end = html.indexOf('>', i);
        const tag = html.slice(i + 2, end).trim().toLowerCase();
        const top = stack.pop();
        if (!top || top.tagName.toLowerCase() !== tag) throw new Error(`</${tag}> closes <${top?.tagName.toLowerCase()}> in ${html}`);
        i = end + 1;
        continue;
      }
      const m = /^<([a-z][a-z0-9]*)((?:\s+[\w-]+(?:="[^"]*")?)*)\s*(\/?)>/i.exec(html.slice(i));
      if (!m) throw new Error(`a tag this parser can't read at ${JSON.stringify(html.slice(i, i + 40))}`);
      const el = doc.createElement(m[1].toLowerCase());
      for (const a of m[2].matchAll(/([\w-]+)(?:="([^"]*)")?/g)) el.setAttribute(a[1], decode(a[2] ?? ''));
      if (el.hasAttribute('disabled')) el.disabled = true;
      stack[stack.length - 1].appendChild(el);
      if (!VOID.has(el.tagName.toLowerCase()) && !m[3]) stack.push(el);
      i += m[0].length;
      continue;
    }
    const next = html.indexOf('<', i);
    const text = html.slice(i, next < 0 ? html.length : next);
    if (text.includes('>')) throw new Error(`a stray ">" in ${JSON.stringify(text)}`);
    stack[stack.length - 1].appendChild(new TextNode(decode(text)));
    i = next < 0 ? html.length : next;
  }
  if (stack.length !== 1) throw new Error(`<${stack.at(-1).tagName.toLowerCase()}> is never closed in ${html}`);
  const nodes = root.childNodes;
  for (const n of nodes) n.parentNode = null;
  return nodes;
}

export class FakeDocument {
  constructor() {
    this.listeners = new Map();
    this.visibilityState = 'visible';
    this.documentElement = new Element('html', this);
    this.body = this.documentElement.appendChild(new Element('body', this));
  }
  createElement(tag) { return tag === 'template' ? new TemplateElement(tag, this) : new Element(tag, this); }
  addEventListener(type, fn) {
    if (!this.listeners.has(type)) this.listeners.set(type, []);
    this.listeners.get(type).push(fn);
  }
  dispatch(type, props = {}) {
    const e = { type, defaultPrevented: false, preventDefault() { this.defaultPrevented = true; }, ...props };
    for (const fn of this.listeners.get(type) ?? []) fn(e);
    return e;
  }
}

export class FakeWindow {
  constructor() {
    this.now = 0;
    this.frames = [];
    this.listeners = new Map();
    this.devicePixelRatio = 2;
    this.scrolledTo = null;
    this.performance = { now: () => this.now };
  }
  matchMedia() { return { matches: false }; }
  requestAnimationFrame(cb) { this.frames.push(cb); }
  scrollTo(x, y) { this.scrolledTo = [x, y]; }
  addEventListener(type, fn) {
    if (!this.listeners.has(type)) this.listeners.set(type, []);
    this.listeners.get(type).push(fn);
  }
  /** Moves the clock on `ms` and runs one animation frame. */
  frame(ms = 16) {
    this.now += ms;
    const fs = this.frames;
    this.frames = [];
    for (const f of fs) f(this.now);
  }
}
