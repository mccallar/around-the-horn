// The web game's flow (web/js/flow.js and web/js/screens.js), played in Node through what
// the screens offer: whole seeded voyages to a win and to a loss, setting out with nothing
// to eat, leaving mid-queue and coming back to it (D10), leaving the page while under way,
// the shop, the names, the top ten. No browser: the drawing is skin.mjs's.
//
//   node Tools/web-tests/play.mjs
import { Player, engine, lcg, describe, plain, wordProblems, SAFE } from './player.mjs';
import { MemoryStorage, kindOf } from '../../web/js/flow.js';

let passed = 0;
const failures = [];
function check(ok, what) {
  if (ok) passed += 1;
  else failures.push(what);
}
async function test(name, f) {
  try {
    await f();
  } catch (e) {
    failures.push(`${name}: ${e.stack}`);
  }
}

const e1 = await engine();
const e2 = await engine();
const saveOf = (storage) => JSON.parse(storage.getItem('horn.save-horn1849') ?? 'null');
const screenWords = (f) => {
  const d = describe(f);
  return JSON.stringify(d.blocks.filter((b) => b.type !== 'scene')) + JSON.stringify(d.choices.map((c) => [c.label, c.enabled]));
};

await test('a careful merchant reaches San Francisco', async () => {
  const storage = new MemoryStorage();
  const p = await Player.make({ engine: e1, storage, seeds: ['13'], random: lcg(13) });
  check(p.screen === 'title', 'opens on the title card');
  check(!p.labels().some((l) => l.startsWith('Continue the voyage')), 'no voyage to continue at first');
  p.setUp({ names: { ship: 'Sea Lark', captain: 'Ezra', crew0: 'Hannah', crew1: 'Silas', crew2: 'Mercy', crew3: 'Tobias' } });
  const end = p.voyage();
  check(end === 'finale', `the merchant's voyage ends at the finale (got ${end})`);
  check(p.caught > 0, `fishing landed something (${p.caught})`);
  for (const s of ['outfit', 'shop', 'depart', 'travel', 'message', 'choice', 'portMenu', 'seaMenu', 'fishing', 'finale']) {
    check(p.seen.has(s), `the voyage showed the ${s} screen`);
  }
  check(p.problems.length === 0, `no word went wrong: ${p.problems.slice(0, 3).join(' | ')}`);
  const d = p.look();
  const words = d.blocks.map((b) => plain(b.markup ?? b.text ?? b.label ?? '')).join(' ');
  check(words.includes('Land ho! The Sea Lark passes through the Golden Gate'), 'the finale names the ship');
  check(d.blocks.some((b) => b.type === 'row' && b.label === 'Final score'), 'the finale shows the final score');
  check(saveOf(storage) === null, 'the finished voyage leaves no save');
  const f = p.f.screen.finale;
  if (f.place != null) {
    const table = JSON.parse(storage.getItem('horn.topten-horn1849'));
    check(table[f.place].name === 'Ezra' && table[f.place].score === f.score.total, 'the captain is in the top ten');
  }
  p.press('See the top ten');
  check(p.screen === 'topTen', 'the top ten from the finale');
  const places = p.look().blocks.filter((b) => b.type === 'place');
  check(places.length === 10, 'ten places');
  if (f.place != null) check(places[f.place].highlight, 'the new place is lit');
  p.press('Back');
  check(p.screen === 'message' && p.f.screen.text === 'Thanks for sailing.', 'thanks for sailing');
  check(p.labels()[0] === 'Sail again', 'and the way on is "Sail again"');
  p.press('Sail again');
  check(p.screen === 'title', 'back on the title card');
});

await test('a crew with no water dies of thirst', async () => {
  const storage = new MemoryStorage();
  const p = await Player.make({ engine: e1, storage, seeds: ['21'], random: lcg(21) });
  p.setUp({ role: 'A Nantucket', month: 'April 1849' });
  p.shop({ food: 3 });
  p.press(1);
  check(p.screen === 'depart', 'sets out with 300 lbs and no water');
  const end = p.voyage({ targets: {}, fishOnce: false });
  check(end === 'gameOver', `the voyage ends in a game over (got ${end})`);
  check(p.seen.has('burial'), 'the dead are buried');
  check(p.problems.length === 0, `no word went wrong: ${p.problems.slice(0, 3).join(' | ')}`);
  const words = p.look().blocks.map((b) => plain(b.markup ?? b.text ?? '')).join(' ');
  check(/nautical miles from New York/.test(words), 'the game over says how far the ship got');
  check(saveOf(storage) === null, 'a lost voyage leaves no save');
  check(storage.getItem('horn.topten-horn1849') === null, 'and no top ten');
  p.press('Try again');
  check(p.screen === 'title', 'try again is the title card');
  check(!p.labels().some((l) => l.startsWith('Continue the voyage')), 'with nothing to continue');
});

await test('no provisions, no voyage', async () => {
  const p = await Player.make({ engine: e1, seeds: ['5'] });
  p.setUp();
  check(p.labels()[0] === 'Leave the shop' && p.labels().length === 1, 'an empty cart only leaves');
  p.press('Leave the shop');
  check(p.screen === 'message' && p.f.screen.text === p.f.journey.text.noProvisions, 'the chandler sends you back');
  p.press('Continue');
  check(p.screen === 'shop', 'back in the shop');
  p.shop({ food: 2 });
  check(p.labels()[0] === 'Pay $20.00 and leave', `the bill is on the button (${p.labels()[0]})`);
  check(p.labels()[1] === 'Leave without buying', 'and a way out without buying');
  p.press('Pay');
  check(p.screen === 'depart' && p.f.game.food === 200, 'paid, and away');
});

await test('the shop counts, caps and refuses', async () => {
  const p = await Player.make({ engine: e1, seeds: ['6'] });
  p.setUp({ role: 'A Nantucket' });
  const item = (k) => p.look().blocks.find((b) => b.type === 'item' && b.key === k);
  check(item('food').price === '$0.10/lb' && item('food').have.startsWith('Have 0 lbs.'), 'provisions priced and counted');
  check(item('tackle').have.startsWith('Have 0 boxes.'), 'tackle counted in boxes in the shop');
  check(!item('food').less(), 'nothing to take away');
  let n = 0;
  while (item('food').more()) n++;
  check(item('food').qty === 3000 && n === 30, `provisions stop at what fits (${item('food').qty})`);
  const d = p.look();
  check(d.blocks.find((b) => b.type === 'cash').bill === '$300.00', 'the bill adds up');
  while (item('clothes').more());
  while (item('meds').more());
  const over = p.look();
  check(over.blocks.find((b) => b.type === 'cash').over, 'more than the whaler has');
  check(plain(over.choices[0].label) === "You can't afford all that" && !over.choices[0].enabled, 'and the button says so');
  while (item('meds').less());
  while (item('clothes').less());
  check(p.look().choices[0].enabled, 'back within means');
});

await test('names: blanks take the suggestion, long ones are cut, brackets stay words', async () => {
  const p = await Player.make({ engine: e1, seeds: ['8'], random: lcg(8) });
  p.press('Sail for California');
  p.press('How do they compare?');
  check(p.screen === 'roleDifferences', 'the comparison');
  p.press('Back');
  p.press('A Mystic');
  const sg = p.f.suggestions;
  const fields = p.look().blocks.filter((b) => b.type === 'field');
  check(fields.length === 6 && fields[0].placeholder === sg.ship && fields[1].placeholder === sg.crew[0], 'six fields, the suggestions in them');
  p.press('Pick new names for me');
  check(p.screen === 'names', 'new names');
  const sg2 = p.f.suggestions;
  p.press('Use these names', { ship: '  [red]The Very Long Name of a Ship  ', captain: '', crew0: 'Hannah', crew1: ' ', crew2: 'X', crew3: 'Y' });
  const dn = p.f.draftNames;
  check(dn.ship === '[red]The Very Long Name of'.slice(0, 22), `the ship's name trimmed and cut to 22 (${dn.ship})`);
  check(dn.captain === sg2.crew[0] && dn.crew[1] === sg2.crew[2], 'blank fields take their suggestion');
  p.press('Ask for advice');
  check(p.screen === 'message' && p.f.screen.text.startsWith('An old shipmaster'), 'the old shipmaster');
  p.press('Continue');
  check(p.screen === 'month', 'back to the month');
  p.press('December 1848');
  const intro = p.look().blocks.find((b) => b.type === 'para').markup;
  check(intro.includes('[i][[red]The Very Long Nam[/i]'), `the name is escaped in markup (${intro})`);
  check(plain(intro).includes('fit out the [red]The Very Long Nam.'), 'and reads as typed');
  check(p.problems.length === 0, `no word went wrong: ${p.problems.slice(0, 3).join(' | ')}`);
});

await test('learn pages and the top ten from the title card', async () => {
  const p = await Player.make({ engine: e1 });
  p.press('Learn about the passage');
  const headings = [];
  while (p.screen === 'learn') {
    headings.push(p.look().blocks[0].text);
    p.press(p.labels()[0]);
  }
  check(headings.join('/') === 'The voyage/Supplies/The Horn', `three pages (${headings})`);
  check(p.screen === 'title', 'and back to the start');
  p.press('See the top ten');
  const places = p.look().blocks.filter((b) => b.type === 'place');
  check(places.length === 10 && places[0].text === '1. Josiah Whitcombe' && places[0].score === '7,650'
    && places[0].rank === 'Master Mariner', 'the journey\'s own top ten');
  p.press('Back');
  check(p.screen === 'title', 'back');
  check(p.problems.length === 0, `no word went wrong: ${p.problems.slice(0, 3).join(' | ')}`);
});

await test('leaving mid-queue comes back to the same screen and what was behind it (D10)', async () => {
  const storage = new MemoryStorage();
  // Seed 3's merchant has a day that raises a message with an arrival queued behind it.
  const a = await Player.make({ engine: e1, storage, seeds: ['3'], random: lcg(3) });
  a.setUp();
  let caughtAt = null;
  a.voyage({
    onScreen: (p) => {
      if (['message', 'choice', 'burial'].includes(p.screen) && p.f.pending.length >= 2 && p.f.after === 'travel') {
        caughtAt = p.screen;
        return 'stop';
      }
      return null;
    },
  });
  check(caughtAt !== null, 'a turn raised two things at once');
  const pending = a.f.pending;
  const save = saveOf(storage);
  check(save && Array.isArray(save.pending) && save.pending.length === pending.length,
    'the save holds the screen and the queue behind it');
  check(JSON.stringify(save.pending[0]) === JSON.stringify(a.f.showing), 'the one on screen first');
  const before = screenWords(a.f);

  // Another engine, as a new page would have; the same storage.
  const b = await Player.make({ engine: e2, storage, seeds: ['99'], random: lcg(99) });
  const resume = b.labels().find((l) => l.startsWith('Continue the voyage of the'));
  check(resume === `Continue the voyage of the ${a.f.game.ship}`, `the title card offers the voyage (${resume})`);
  b.press('Continue the voyage');
  check(screenWords(b.f) === before, 'the same screen comes back');
  // Both go through what was queued: the same words, until an answer draws on chance.
  for (let i = 0; i < pending.length; i++) {
    const kind = kindOf(pending[i]);
    check(screenWords(b.f) === screenWords(a.f), `queued item ${i + 1} (${kind}) is the same after coming back`);
    if (kind === 'choice' || kind === 'arrival' || kind === 'burial') break;
    a.press(1);
    b.press(1);
  }
  // Once the queue is done, a menu, not the loop.
  let guard = 0;
  while (['message', 'choice', 'burial'].includes(b.screen) && guard++ < 50) {
    if (b.screen === 'burial') b.press(1, {});
    else b.look().choices.find((c) => c.enabled).act();
  }
  check(['seaMenu', 'portMenu'].includes(b.screen) || b.screen === 'finale' || b.screen === 'gameOver',
    `after the queue, a menu (${b.screen})`);
  check(b.timers.running === 0, 'and the clock is not running');
  const atMenu = saveOf(storage);
  if (['seaMenu', 'portMenu'].includes(b.screen)) check(atMenu && !('pending' in atMenu), 'a save on a menu has nothing waiting');
  const end = b.voyage();
  check(end === 'finale' || end === 'gameOver', `the voyage can be played to its end after coming back (${end})`);
  check(b.problems.length === 0 && a.problems.length === 0, `no word went wrong: ${[...a.problems, ...b.problems].slice(0, 3).join(' | ')}`);
});

await test('a save standing on the last stop is told of its arrival', async () => {
  const storage = new MemoryStorage();
  const p = await Player.make({ engine: e1, storage, seeds: ['3'] });
  p.setUp();
  p.topUp(SAFE.horn1849);
  p.press(1);
  const s = p.f.engine.save([]);
  const J = p.f.journey;
  Object.assign(s, { stopIndex: J.stops.length - 1, mile: J.totalMiles, atPort: false, day: 150 });
  storage.setItem('horn.save-horn1849', JSON.stringify(s));
  const q = await Player.make({ engine: e2, storage, seeds: ['4'] });
  q.press('Continue the voyage');
  let guard = 0;
  while (q.screen === 'message' && guard++ < 10) q.press(1);
  check(q.screen === 'finale', `the voyage ends (${q.screen})`);
});

await test('leaving the page under way stops the clock on a menu', async () => {
  const storage = new MemoryStorage();
  const p = await Player.make({ engine: e1, storage, seeds: ['31'] });
  p.setUp();
  p.topUp(SAFE.horn1849);
  p.press(1);
  p.press('Set sail');
  check(p.screen === 'travel' && p.timers.running === 1, 'under way, the clock running');
  const day0 = p.f.game.day;
  p.timers.fire();
  check(p.f.game.day > day0 || p.screen !== 'travel', 'a tick is a day');
  if (p.screen === 'travel') {
    p.f.background();
    check(p.screen === 'seaMenu' && p.timers.running === 0 && !p.f.traveling, 'left: on the menu, the clock stopped');
    const s = saveOf(storage);
    check(s && !('pending' in s) && s.day === p.f.game.day, 'and saved as it stands');
  }
});

await test('every menu row leads somewhere and back', async () => {
  const p = await Player.make({ engine: e1, seeds: ['41'], random: lcg(41) });
  p.setUp();
  p.topUp(SAFE.horn1849);
  p.press(1);
  p.press('Set sail');
  p.press('Heave to');
  check(p.screen === 'seaMenu', 'hove to');
  const rows = p.labels();
  check(rows.join('/') === 'Continue on your voyage/Check supplies & crew/Look at the chart/Change pace (Steady)'
    + '/Change rations (Full)/Heave to and rest/Make repairs/Go fishing/Save and return to the title',
    `the sea menu, with the way back to the picker's journeys (${rows.join('/')})`);
  for (const [row, screen] of [['Check supplies', 'supplies'], ['Look at the chart', 'chart'], ['Make repairs', 'repairs']]) {
    p.press(row);
    check(p.screen === screen, `${row} opens ${screen}`);
    if (screen === 'repairs') {
      const [first, second] = p.labels();
      check(first.startsWith('Patch the hull') && second.startsWith('Mend sails'),
        `the repairs in the condition box's order, hull then sails (${first} / ${second})`);
    }
    p.press(p.labels().at(-1));
    check(p.screen === 'seaMenu', `and comes back from ${screen}`);
  }
  p.press('Change pace');
  p.press('Full canvas');
  check(p.labels()[3] === 'Change pace (Full canvas)', 'the pace changed');
  p.press('Change rations');
  p.press('Short');
  check(p.labels()[4] === 'Change rations (Short)', 'the rations changed');
  p.press('Heave to and rest');
  check(p.labels().join('/') === '1 day/2 days/3 days/5 days/Never mind', 'how long to rest');
  p.press('Never mind');
  const chart = (p.press('Look at the chart'), p.look());
  const legend = chart.blocks.find((b) => b.type === 'legend').items;
  check(legend[0].text === '✓ New York' && legend[1].text === '► Gulf Stream' && legend[2].text === '· Cape Verde', 'the chart\'s legend');
  check(p.problems.length === 0, `no word went wrong: ${p.problems.slice(0, 3).join(' | ')}`);
});

console.log(`play: ${passed} checks passed, ${failures.length} failed`);
for (const f of failures) console.log(`FAILED ${f}`);
process.exit(failures.length ? 1 : 0);
