// The page itself (web/js/ui.js) in Node, on the small DOM in dom.mjs: what it writes is
// well-formed HTML, the buttons it makes carry the screens' words and do what they say,
// keys and taps work, the canvases are drawn, and a whole voyage can be played by clicking.
//
//   node Tools/web-tests/ui.mjs
import { FakeDocument, FakeWindow } from './dom.mjs';
import { Player, FakeTimers, engine, lcg, plain } from './player.mjs';
import { Flow, MemoryStorage } from '../../web/js/flow.js';
import { UI } from '../../web/js/ui.js';

let passed = 0;
const failures = [];
function check(ok, what) {
  if (ok) passed += 1;
  else failures.push(what);
}

const errors = [];
const realError = console.error;
console.error = (...a) => errors.push(a.map(String).join(' '));

/** A page: the flow, the UI and the elements it draws in. */
async function page({ seed = '13', storage = new MemoryStorage() } = {}) {
  const doc = new FakeDocument();
  const win = new FakeWindow();
  const app = doc.body.appendChild(doc.createElement('div'));
  const banner = app.appendChild(doc.createElement('span'));
  const sound = app.appendChild(doc.createElement('button'));
  const root = app.appendChild(doc.createElement('main'));
  const timers = new FakeTimers();
  const played = [];
  const flow = new Flow({ engine: await engine(), storage, timers, random: lcg(Number(seed)), seed: () => seed,
    sound: (c) => played.push(c) });
  const clicks = [];
  const ui = new UI(flow, { root, banner, sound, synth: { play: (c) => clicks.push(c) }, doc, win });
  const settle = () => ui.render();
  const buttons = () => root.querySelectorAll('button.choice');
  const label = (b) => b.innerText.replace(/^\d+\.\s/, '');
  const find = (start) => buttons().find((b) => label(b).startsWith(start));
  const click = (start) => {
    settle();
    const b = find(start);
    if (!b) throw new Error(`no button "${start}" on ${flow.screen.name}: ${buttons().map(label).join(' / ')}`);
    b.click();
    settle();
    return b;
  };
  return { doc, win, root, banner, sound, flow, ui, timers, storage, settle, buttons, label, click, find, played, clicks };
}

// MARK: - The title card, keys, the names

{
  const p = await page();
  const { root, banner, flow, settle, buttons, label, click } = p;
  check(banner.textContent === 'AROUND THE HORN · 1849', 'the banner');
  check(p.sound.textContent === '♪ on' && p.sound.getAttribute('aria-label') === 'Sound on', 'the sound button');
  const h1 = root.querySelector('h1');
  check(h1 && h1.innerText === 'AROUND\nTHE HORN' && h1.getAttribute('aria-label') === 'Around the Horn', 'the title, on two lines');
  check(buttons().map(label).join('/') === 'Sail for California/Learn about the passage/See the top ten', 'the title card\'s choices');
  check(buttons()[0].querySelector('.num').textContent === '1.', 'numbered');
  const scene = root.querySelector('canvas');
  p.win.frame();
  check(scene && scene.width === 160 * 5 && scene.height === 80 * 5, `the scene, five device pixels to a pixel at 360 wide (${scene?.width})`);
  check(scene.ctx.ops.fillRect > 100, `the scene is drawn (${scene.ctx.ops.fillRect} rectangles)`);
  check(scene.getAttribute('aria-label') === 'A ship under sail', 'the scene says what it shows');

  p.doc.dispatch('keydown', { key: '2', target: p.doc.body });
  settle();
  check(flow.screen.name === 'learn' && root.querySelector('h2').textContent === 'The voyage', 'the 2 key opens the second choice');
  p.doc.dispatch('keydown', { key: 'Enter', target: p.doc.body });
  settle();
  check(root.querySelector('h2').textContent === 'Supplies', 'Return takes a lone choice');
  const amber = root.querySelector('p').querySelector('span.amber');
  check(amber && amber.textContent === 'Provisions', 'markup becomes colour');
  click('Next');
  click('Back to the start');
  check(flow.screen.name === 'title', 'and back');
  check(p.clicks.length === 4 && p.clicks.every((c) => c === 'click'), 'each press clicks, by key or by pointer');

  click('Sail for California');
  check(p.played.includes('title'), 'the title tune plays');
  check(flow.screen.name === 'role', 'who are you?');
  click('A Nantucket whaler');
  const fields = root.querySelectorAll('input[data-field]');
  check(fields.length === 6 && fields[0].maxLength === 22 && fields[1].maxLength === 16, 'six fields, with their limits');
  check(fields[0].placeholder === flow.suggestions.ship && fields[0].getAttribute('aria-label') === "Ship's name", 'placeholders and labels');
  p.doc.dispatch('keydown', { key: '1', target: fields[0] });
  settle();
  check(flow.screen.name === 'names', 'digits typed in a field stay in the field');
  p.doc.dispatch('keydown', { key: '1', target: p.doc.body });
  settle();
  check(flow.screen.name === 'names', 'and the names screen takes no number keys');
  fields[0].value = 'Persistence';
  fields[1].value = 'Obed';
  click('Use these names');
  check(flow.draftNames.ship === 'Persistence' && flow.draftNames.captain === 'Obed', 'what was typed is taken');
  click('Ask for advice');
  check(root.querySelector('.msg')?.innerText.startsWith('An old shipmaster'), 'advice in the message box');
  click('Continue');
  click('January 1849');
  check(root.querySelector('p').innerText.startsWith('You have $500 to fit out the Persistence.'), 'the outfitting, in italics for the ship');
  check(root.querySelector('p span.it')?.textContent === 'Persistence', 'the ship\'s name slanted');
  click('Enter the shop');

  // MARK: The shop: holding + repeats; the bill; paying.
  const plus = root.querySelectorAll('button[data-step]').find((b) => b.getAttribute('aria-label') === 'More Provisions');
  const minus = root.querySelectorAll('button[data-step]').find((b) => b.getAttribute('aria-label') === 'Less Provisions');
  plus.dispatch('pointerdown', { button: 0 });
  settle();
  check(flow.screen.cart.food === 100, 'a touch is one step');
  await new Promise((r) => setTimeout(r, 640));
  settle();
  const held = flow.screen.cart.food;
  check(held >= 300, `held, it keeps stepping (${held})`);
  check(plus.isConnected, 'and the button held is still the one on the page');
  plus.dispatch('pointerup', {});
  await new Promise((r) => setTimeout(r, 200));
  check(flow.screen.cart.food === held, 'let go, it stops');
  const row = plus.parentNode.parentNode;
  check(row.querySelector('.count').textContent === String(held), 'the count shows it');
  minus.click({ detail: 0 });
  settle();
  check(flow.screen.cart.food === held - 100, 'a key press on − is one step back');
  check(p.played.includes('shopUp') && p.played.includes('shopDown'), 'the shop beeps');
  const bill = root.querySelector('.box').innerText;
  check(bill === `Cash $500Bill $${((held - 100) * 0.1).toFixed(2)}`, `the bill (${bill})`);
  const pay = buttons()[0];
  check(label(pay).startsWith('Pay $') && pay.className.includes('primary'), 'pay is the primary choice');
  for (const k of ['Fresh water', 'Spare sailcloth', 'Spare timber', 'Oilskins & woolens', 'Citrus']) {
    const b = root.querySelectorAll('button[data-step]').find((x) => x.getAttribute('aria-label') === `More ${k}`);
    for (let i = 0; i < 5; i++) {
      b.dispatch('pointerdown', { button: 0 });
      b.dispatch('pointerup', {});
    }
  }
  settle();
  click('Pay');
  check(flow.screen.name === 'depart', 'paid and away');
  p.doc.dispatch('keydown', { key: 'Enter', target: p.doc.body });
  settle();
  check(flow.screen.name === 'travel', 'under way');

  // MARK: Under way: the status box changes, the button stays put.
  const halt = buttons()[0];
  const date0 = root.querySelector('.status .amber').innerText;
  p.timers.fire();
  settle();
  if (flow.screen.name === 'travel') {
    check(root.querySelector('.status .amber').innerText !== date0, 'a day passes on the status box');
    check(buttons()[0] === halt, 'the heave-to button is not remade by a tick, so a tap on it lands');
    check(root.querySelector('canvas').getAttribute('aria-label').startsWith('Ship sailing in'), 'the scene is moving');
  }
  while (flow.screen.name !== 'travel') click(buttons().find((b) => !b.disabled) ? label(buttons().find((b) => !b.disabled)) : '');
  p.doc.dispatch('visibilitychange', {});
  p.doc.visibilityState = 'hidden';
  p.doc.dispatch('visibilitychange', {});
  settle();
  check(flow.screen.name === 'seaMenu' && p.timers.running === 0, 'hiding the page stops the voyage on the menu');
  p.doc.visibilityState = 'visible';

  // MARK: The chart blinks; the supplies list; fishing by tapping.
  click('Look at the chart');
  const chart = root.querySelector('canvas');
  check(chart.width === 230 * Math.round(360 * 2 / 230), `the chart's canvas (${chart.width})`);
  p.win.frame(16);
  const shown = chart.ctx.ops.fillRect;
  check(shown > 500 && chart.ctx.ops.fill >= 4, 'the chart: dots, stops and four coasts');
  check(root.querySelectorAll('.legend span').length === flow.journey.stops.length, 'the legend lists every stop');
  click('Back');
  click('Check supplies');
  check(root.querySelectorAll('.crew').length === 5 && root.querySelectorAll('.crew .bar').length === 5, 'five crew, five bars');
  check(root.querySelector('.crew').innerText.startsWith('Obed (captain)'), 'the captain first');
  click('Back');
  click('Go fishing');
  if (flow.screen.name === 'fishing') {
    const sea = root.querySelector('canvas');
    check(sea.className.includes('fish') && sea.height === 200 * Math.round(720 / 160), 'the sea under the boat');
    const tackle0 = flow.game.tackle;
    for (let i = 0; i < 20; i++) p.win.frame(16);
    sea.click({ clientX: 180, clientY: 300 });
    check(flow.game.tackle === tackle0 - 1, 'a tap throws a harpoon');
    p.doc.dispatch('keydown', { key: ' ', target: p.doc.body });
    let frames = 0;
    while (flow.screen.name === 'fishing' && frames++ < 3000) {
      if (frames % 40 === 0) p.doc.dispatch('keydown', { key: ' ', target: p.doc.body });
      p.win.frame(16);
    }
    settle();
    check(flow.screen.name !== 'fishing', `the time runs out and the catch is landed (${frames} frames)`);
    check(p.played.includes('harpoon'), 'the harpoon whooshes');
  }
  p.click(label(buttons()[0]));
  check(p.sound.textContent === '♪ on', 'sound on');
  p.sound.click();
  settle();
  check(p.sound.textContent === '♪ off' && p.storage.getItem('horn.muted') === '1', 'the sound button mutes, and is remembered');
}

// MARK: - A whole voyage, by clicking

/** The careful player of player.mjs, pressing the page's buttons instead of the descriptions. */
class Clicker extends Player {
  constructor(pg) {
    super({ flow: pg.flow, timers: pg.timers });
    this.pg = pg;
  }

  press(start, input = {}) {
    const pg = this.pg;
    pg.settle();
    for (const [k, v] of Object.entries(input)) {
      const el = pg.root.querySelector(`input[data-field="${k}"]`);
      if (el) el.value = v;
    }
    const b = typeof start === 'number' ? pg.buttons()[start - 1] : pg.find(start);
    if (!b) throw new Error(`no "${start}" on the page (${this.screen}): ${pg.buttons().map(pg.label).join(' / ')}`);
    if (b.disabled) throw new Error(`"${start}" is greyed out`);
    const d = this.look();
    const n = pg.buttons().indexOf(b);
    if (plain(d.choices[n].label) !== pg.label(b)) this.problems.push(`button ${n + 1} reads "${pg.label(b)}"`);
    b.click();
    pg.settle();
    pg.win.frame(16);
  }
}

for (const [seed, role, want] of [['13', 'A Boston', 'finale'], ['11', 'A Nantucket', 'gameOver']]) {
  const pg = await page({ seed });
  const c = new Clicker(pg);
  c.setUp({ role });
  const end = c.voyage();
  check(end === want, `${role}, seed ${seed}: clicked through to the ${want} (${end})`);
  check(c.problems.length === 0, `the buttons read as the screens say: ${c.problems.slice(0, 3).join(' | ')}`);
  pg.settle();
  check(pg.root.querySelector('.msg') !== null && pg.buttons().length >= 1, 'the ending is on the page');
}

console.error = realError;
check(errors.length === 0, `nothing went to the console's errors: ${errors.slice(0, 3).join(' | ')}`);
console.log(`ui: ${passed} checks passed, ${failures.length} failed`);
for (const f of failures) console.log(`FAILED ${f}`);
process.exit(failures.length ? 1 : 0);
