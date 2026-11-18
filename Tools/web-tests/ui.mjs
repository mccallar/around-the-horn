// The page itself (web/js/ui.js) in Node, on the small DOM in dom.mjs: what it writes is
// well-formed HTML, the buttons it makes carry the screens' words and do what they say,
// keys and taps work, the canvases are drawn, and a whole voyage can be played by clicking.
//
//   node Tools/web-tests/ui.mjs
import { readFileSync } from 'node:fs';
import { FakeDocument, FakeWindow } from './dom.mjs';
import { Player, FakeTimers, engine, lcg, plain } from './player.mjs';
import { Flow, MemoryStorage } from '../../web/js/flow.js';
import { UI } from '../../web/js/ui.js';
import * as horn1849 from '../../web/js/journeys/horn1849-skin.js';

let passed = 0;
const failures = [];
function check(ok, what) {
  if (ok) passed += 1;
  else failures.push(what);
}

const errors = [];
const realError = console.error;
console.error = (...a) => errors.push(a.map(String).join(' '));

/**
 * A page: the flow, the UI and the elements it draws in. `journey` opens on its title card
 * (`?journey=<id>`); null, as a plain visit does.
 */
async function page({ seed = '13', storage = new MemoryStorage(), journey = 'horn1849', skins } = {}) {
  const doc = new FakeDocument();
  const win = new FakeWindow();
  const app = doc.body.appendChild(doc.createElement('div'));
  const banner = app.appendChild(doc.createElement('span'));
  const sound = app.appendChild(doc.createElement('button'));
  const root = app.appendChild(doc.createElement('main'));
  const timers = new FakeTimers();
  const played = [];
  const flow = new Flow({ engine: await engine(), storage, timers, random: lcg(Number(seed)), seed: () => seed,
    sound: (c) => played.push(c), journey, skins });
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
  check(buttons().map(label).join('/') === 'Sail for California/Learn about the passage/See the top ten/Choose another journey',
    'the title card\'s choices');
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
  check(fields.length === 6 && fields.every((f) => !f.hasAttribute('maxlength')), 'six fields, with no maxlength of the browser\'s');
  // PixelField's limits count Characters, as Swift does: 22 for the ship, 16 for a person.
  const flag = '\u{1F1FA}\u{1F1F8}';
  const typed = (f, value, more = {}) => {
    f.value = value;
    f.dispatch('input', { isComposing: false, ...more });
    return f.value;
  };
  check(typed(fields[1], flag.repeat(10)) === flag.repeat(10), 'ten flags fit in a name, as in the app');
  check(typed(fields[1], flag.repeat(20)) === flag.repeat(16), 'twenty are cut to sixteen');
  check(typed(fields[0], 'x'.repeat(30)) === 'x'.repeat(22), 'a ship\'s name is cut to twenty-two');
  check(typed(fields[1], '\u{1F469}\u{200D}\u{1F680}'.repeat(17)) === '\u{1F469}\u{200D}\u{1F680}'.repeat(16), 'an astronaut is one character');
  check(typed(fields[2], '\u{3042}'.repeat(20), { isComposing: true }) === '\u{3042}'.repeat(20), 'nothing is cut while a word is being composed');
  fields[2].dispatch('compositionend');
  check(fields[2].value === '\u{3042}'.repeat(16), 'and it is cut when the word is done');
  for (const f of fields) f.value = '';
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
  check(row.querySelector('.count').textContent === held.toLocaleString('en-US'), 'the count shows it, grouped as the app does');
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

// MARK: - The picker and the Iron Road on the page

{
  const p = await page({ seed: '2', journey: null });
  const { root, banner, flow, buttons, label, click } = p;
  p.settle();
  check(flow.screen.name === 'picker' && banner.textContent === 'AROUND THE HORN', `a plain visit opens on the picker (${banner.textContent})`);
  check(root.querySelector('h2').textContent === 'Choose a journey', 'choose a journey');
  check(buttons().map((b) => b.querySelector('.detail')?.textContent).join('|') === flow.journeys.map((j) => j.subtitle).join('|'),
    'each row with its subtitle under it');
  click('The Iron Road');
  check(banner.textContent === 'THE IRON ROAD · 1869', 'the Iron Road\'s banner');
  const h1 = root.querySelector('h1');
  check(h1.innerText === 'THE IRON\nROAD' && h1.getAttribute('aria-label') === 'The Iron Road', 'its title, on two lines');
  p.win.frame();
  const scene = root.querySelector('canvas');
  check(scene.getAttribute('aria-label') === 'A wood-burning freight train on the prairie' && scene.ctx.ops.fillRect > 100,
    'the train on the title card');
  check(label(buttons().at(-1)) === 'Choose another journey', 'and the way back to the picker');

  const c = new Clicker(p);
  c.setUp();
  c.topUp({ fuel: 160, water: 1200, food: 300, clothes: 5, meds: 3, sailcloth: 3, timber: 3, tackle: 40 });
  click('Pay');
  click('Whistle off');
  p.timers.fire();
  p.settle();
  while (!['seaMenu', 'portMenu'].includes(flow.screen.name)) click(label(buttons().find((b) => !b.disabled)));
  click('Look at the map');
  const map = root.querySelector('canvas');
  p.win.frame(16);
  check(map.width === 240 * Math.round(360 * 2 / 240) && map.height === 104 * Math.round(360 * 2 / 240), `the map's canvas (${map.width}×${map.height})`);
  check(map.ctx.ops.fillRect > 300 && map.ctx.ops.fill >= 3 && map.ctx.ops.fillText === 2 * map.ctx.ops.clearRect,
    `the map: the country, the road, the two ends named (${JSON.stringify(map.ctx.ops)})`);
  check(map.getAttribute('aria-label').startsWith('Map of the railroad from Omaha to Sacramento.'), 'the map says what it shows');
  click('Back');
  check(flow.v.fishingRefusal == null, `the river can be worked here (${flow.v.fishingRefusal})`);
  if (flow.v.fishingRefusal == null) {
    click('Haul driftwood');
    const river = root.querySelector('canvas');
    check(river.className.includes('fish') && river.height === 200 * Math.round(720 / 160), 'the river from the bank');
    const casts = flow.game.tackle;
    river.click({ clientX: 180, clientY: 200 });
    check(flow.game.tackle === casts - 1, 'a tap on the river casts the grapnel');
    // The picture sits inside the canvas's 2px border: its corners are the field's.
    const model = flow.screen.model;
    const taps = [];
    model.throwAt = (x, y) => taps.push([x, y]);
    Object.assign(river, { clientLeft: 2, clientTop: 2, clientWidth: 356 });
    river.click({ clientX: 2, clientY: 2 });
    river.click({ clientX: 358, clientY: 2 + river.clientHeight });
    river.click({ clientX: 180, clientY: 2 + river.clientHeight / 2 });
    delete model.throwAt;
    river.clientLeft = river.clientTop = 0;
    river.clientWidth = 360;
    const { w, h } = model.field;
    check(JSON.stringify(taps) === JSON.stringify([[0, 0], [w, h], [w / 2, h / 2]]), `taps land in the drawing as the app's do: ${JSON.stringify(taps)}`);
    river.click({ clientX: 180, clientY: 690 });
    for (let i = 0; i < 3000 && flow.screen.name === 'fishing'; i++) {
      if (i % 40 === 0) p.doc.dispatch('keydown', { key: ' ', target: p.doc.body });
      p.win.frame(16);
    }
    p.settle();
    check(flow.screen.name !== 'fishing', 'the haul is landed');
  }
  while (!['seaMenu', 'portMenu'].includes(flow.screen.name)) click(label(buttons().find((b) => !b.disabled)));
  const end = c.voyage();
  check(end === 'finale', `the Iron Road, clicked through to Sacramento (${end})`);
  check(c.problems.length === 0, `the buttons read as the screens say: ${c.problems.slice(0, 3).join(' | ')}`);
  p.settle();
  check(root.querySelector('.msg').innerText.startsWith('Sacramento! The '), 'the arrival on the page');
}

// MARK: - The page opened from disk, where main.js never runs: index.html says why.
{
  const html = readFileSync(new URL('../../web/index.html', import.meta.url), 'utf8');
  const code = html.match(/<script>([\s\S]*?)<\/script>/)?.[1] ?? '';
  const handler = html.match(/<script type="module" src="js\/main\.js" onerror="([^"]*)"><\/script>/)?.[1];
  const visit = (protocol, readyState = 'interactive') => {
    const doc = new FakeDocument();
    const screen = doc.body.appendChild(doc.createElement('main'));
    screen.innerHTML = '<p class="amber blink" aria-hidden="true">▌</p>';
    doc.getElementById = (id) => (id === 'screen' ? screen : null);
    doc.readyState = readyState;
    const cannotStart = new Function('document', 'location', `${code}\nreturn cannotStart;`)(doc, { protocol });
    return { doc, screen, cannotStart };
  };
  const words = (screen) => screen.querySelector('p.failed')?.textContent ?? '';
  const disk = visit('file:');
  check(words(disk.screen).includes('python3 -m http.server -d web 8000') && words(disk.screen).includes('http://localhost:8000'),
    `opened from disk, the page says how to serve it: ${words(disk.screen)}`);
  check(!disk.screen.querySelector('.blink'), 'and the cursor gives way to it');
  const early = visit('file:', 'loading');
  check(words(early.screen) === '', 'while the page is still being read, the message waits');
  early.doc.dispatch('DOMContentLoaded');
  check(words(early.screen).startsWith('The game could not start'), 'and comes when it is read');
  const served = visit('http:');
  check(words(served.screen) === '' && served.screen.querySelector('.blink'), 'served, the page waits for the game');
  check(handler != null, 'the module script has a handler for code that does not load');
  new Function('cannotStart', handler ?? '')(served.cannotStart);
  check(words(served.screen) === 'The game could not start: its code did not load.', 'and it says so');
  check(readFileSync(new URL('../../web/js/main.js', import.meta.url), 'utf8').includes("if (location.protocol === 'file:') return;"),
    'main.js leaves the message alone where a browser runs it from disk');
}

// MARK: - What a skin may answer that 1849's does not, in the page

{
  // 1849's skin with a warning before departing and a place of its own.
  const skins = [{
    id: 'horn1849',
    skin: (J) => {
      const base = horn1849.skin(J);
      return { ...base, words: (v) => ({ ...base.words(v), place: 'At the pier',
        departWarning: v.state.limes < 10 ? { text: 'There is [red]hardly any citrus[/red] aboard.', back: 'Back to the chandler',
          go: 'Sail without it' } : null }) };
    },
  }];
  const p = await page({ skins });
  const { root, flow, settle, buttons, label, click } = p;
  click('Sail for California');
  click('A Boston merchant');
  click('Use these names');
  click('January 1849');
  click('Enter the shop');
  const more = root.querySelectorAll('button[data-step]').find((b) => b.getAttribute('aria-label') === 'More Provisions');
  for (let i = 0; i < 2; i++) {
    more.click({ detail: 0 });
    settle();
  }
  check(flow.screen.cart.food === 200, `provisions in the cart (${flow.screen.cart.food})`);
  click('Pay');
  check(flow.screen.name === 'ask', `the warning before departing (${flow.screen.name})`);
  const box = root.querySelector('div.msg');
  check(box && box.innerText === 'There is hardly any citrus aboard.' && box.querySelector('span.red')?.textContent === 'hardly any citrus',
    `the warning in a message box, its markup in colour (${box?.innerText})`);
  check(root.querySelector('canvas') != null, 'under the scene');
  check(buttons().map(label).join('/') === 'Back to the chandler/Sail without it', `its two answers (${buttons().map(label).join('/')})`);
  check(buttons()[0].className.includes('primary') && !buttons()[1].className.includes('primary'), 'the way back is the primary one');
  check(p.played.at(-1) === 'message', `and it sounds as a message does (${p.played.at(-1)})`);
  p.doc.dispatch('keydown', { key: '1', target: p.doc.body });
  settle();
  check(flow.screen.name === 'shop', `the 1 key heeds it: back to the stores (${flow.screen.name})`);
  click('Leave the shop');
  p.doc.dispatch('keydown', { key: '2', target: p.doc.body });
  settle();
  check(flow.screen.name === 'depart', `the 2 key waves it off: the departure (${flow.screen.name})`);
  click('Set sail');
  click('Heave to');
  const status = root.querySelector('div.status');
  check(status?.querySelector('span.dim')?.textContent === '· At the pier', `the skin's place after the date (${status?.querySelector('span.dim')?.textContent})`);
  flow.stopTravel();
}

console.error = realError;
check(errors.length === 0, `nothing went to the console's errors: ${errors.slice(0, 3).join(' | ')}`);
console.log(`ui: ${passed} checks passed, ${failures.length} failed`);
for (const f of failures) console.log(`FAILED ${f}`);
process.exit(failures.length ? 1 : 0);
