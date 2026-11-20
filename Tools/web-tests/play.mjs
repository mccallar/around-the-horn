// The web game's flow (web/js/flow.js and web/js/screens.js), played in Node through what
// the screens offer: whole seeded voyages to a win and to a loss, setting out with nothing
// to eat, leaving mid-queue and coming back to it (D10), leaving the page while under way,
// the shop, the names, the top ten. Then what the shell does with a skin's answers that
// 1849's own never gives, on 1849's skin with those words changed (as the app's
// TestJourneys stands in for a journey): a warning before departing and a refusal to, a
// refusal to leave a port, a port's hold on setting out, the yard's question, a voyage
// saved in the first stores coming back to them, the skin's place and stop names. No
// browser: the drawing is skin.mjs's.
//
//   node Tools/web-tests/play.mjs
import { Player, engine, lcg, describe, plain, wordProblems, SAFE } from './player.mjs';
import { MemoryStorage, kindOf } from '../../web/js/flow.js';
import * as horn1849 from '../../web/js/journeys/horn1849-skin.js';

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
const saveOf = (storage, id = 'horn1849') => JSON.parse(storage.getItem(`horn.save-${id}`) ?? 'null');
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

await test('the engine ends a voyage as it queues the ending: the screens ahead of it leave no save to come back to', async () => {
  // Seed 4's 1849 and seed 9's Iron Road, short of everything, each raise a message in
  // the same turn as their game over and ahead of it. A save left then would bring back
  // the turn before the end, to be played again.
  for (const [journey, seed] of [['horn1849', 4], ['rail', 9]]) {
    const storage = new MemoryStorage();
    const p = await Player.make({ journey, engine: e1, storage, seeds: [String(seed)], random: lcg(seed) });
    p.setUp();
    p.shop({ food: 1 });
    p.press(1);
    const ahead = [];
    const end = p.voyage({
      targets: {}, fishOnce: false,
      onScreen: (q) => {
        if (['message', 'choice', 'burial'].includes(q.screen) && q.f.game?.over) ahead.push(saveOf(storage, journey));
        return null;
      },
    });
    check(end === 'gameOver', `${journey}: the voyage ends in a game over (${end})`);
    check(ahead.length > 0 && ahead.every((x) => x === null),
      `${journey}: a screen ahead of the game over, and no save behind it (${ahead.length}, ${ahead.filter((x) => x !== null).length} saved)`);
  }
});

await test('the fishing tally groups a thousand throws as the app does: "Throws: 1,000"', async () => {
  const p = await Player.make({ engine: e1, seeds: ['13'], random: lcg(13) });
  p.setUp();
  p.shop({ food: 10, water: 10, tackle: 50 });
  p.press('Pay');
  p.press(1);
  check(p.f.game.tackle === 1000, `a thousand throws aboard (${p.f.game.tackle})`);
  let tally = null;
  for (let i = 0; i < 40 && tally == null; i++) {
    if (p.screen === 'travel') p.press(1);
    else if (p.screen === 'seaMenu' && p.labels().includes('Go fishing') && p.look().choices.find((c) => plain(c.label) === 'Go fishing').enabled) {
      p.press('Go fishing');
      if (p.screen === 'fishing') tally = p.look().blocks.find((b) => b.type === 'tally');
      else p.press(1);
    } else if (p.screen === 'seaMenu') p.press(1);
    else p.look().choices.find((c) => c.enabled).act();
  }
  check(tally != null && tally.items[0] === `${p.f.skin.forage.throwsLabel}: 1,000`, `the throws grouped (${tally?.items[0]})`);
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

await test('a purse too thin for a step of provisions, and none aboard: the ship sails hungry, and says so (D23)', async () => {
  const p = await Player.make({ engine: e1, seeds: ['8'], random: lcg(8) });
  p.setUp({ role: 'A Nantucket' });
  check(p.f.game.money === 500, `a whaler's purse (${p.f.game.money})`);
  p.shop({ sailcloth: 20, timber: 20 });
  check(p.f.bill === 500, `the whole purse on sailcloth and timber (${p.f.bill})`);
  p.press('Pay');
  check(p.f.game.money === 0 && p.f.game.food === 0, 'nothing left, and nothing to eat');
  check(p.f.v.hooks.departsUnfed === true, 'the engine lets her sail hungry');
  check(p.screen === 'depart' && p.f.screen.text.endsWith("Ahead lie fourteen thousand miles of ocean. There isn't a biscuit in the bread room, and the purse won't stretch to a hundredweight of salt beef, so the crew puts to sea hungry and must live on whatever the sea or the next port gives them."),
    `away from New York, hungry, not back to the chandler (${p.screen}: ${p.f.screen.text?.slice(-120)})`);
  const end = p.voyage({ targets: {}, fishOnce: false });
  check(end === 'gameOver' || end === 'finale', `and the voyage ends, never a loop (got ${end})`);
  check(p.problems.length === 0, `no word went wrong: ${p.problems.slice(0, 3).join(' | ')}`);
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

// MARK: - What a skin may answer that 1849's does not

/** 1849's skin with words of the test's own over its own (`over(view)`), for the flow. */
const testSkin = (over) => [{
  id: 'horn1849',
  skin: (J) => {
    const base = horn1849.skin(J);
    return { ...base, words: (v) => ({ ...base.words(v), ...over(v) }) };
  },
}];

/** An engine whose `setSail` first answers with `holds`, one a call, as `Journey.holdInPort` does. */
function holding(e, holds, sails = false) {
  return new Proxy(e, {
    get(t, k) {
      if (k === 'setSail') {
        return () => {
          if (!holds.length) return t.setSail();
          const r = sails ? t.setSail() : { ok: true, view: t.view(), interrupts: [] };
          return { ...r, interrupts: [holds.shift()] };
        };
      }
      const x = t[k];
      return typeof x === 'function' ? x.bind(t) : x;
    },
  });
}

/** On the port menu at 1849's first port after New York, from a debug start. */
function inPort(p) {
  const f = p.f, J = f.journey;
  f.engine.start({ journey: 'horn1849', role: 'merchant', ship: 'Resolute', captain: 'Ezra',
    crew: ['Hannah', 'Silas', 'Mercy', 'Tobias'], year: 1849, month: 0, seed: '9' });
  const s = f.engine.save([]);
  const i = J.stops.findIndex((st, k) => k > 0 && J.ports.some((x) => x.id === st.id));
  f.skin.debug.start(s, i);
  Object.assign(s, { stopIndex: i, mile: J.stops[i].mile, atPort: true });
  f.loadForDebug(s);
  return J.stops[i];
}

await test('a skin\'s warning before departing may be heeded or waved off; its refusal sends you back to the stores', async () => {
  const cues = [];
  let refuse = true;
  const skins = testSkin((v) => ({
    departRefusal: refuse ? 'The harbour master wants to see your [amber]papers[/amber] first.' : null,
    departWarning: v.state.limes < 10 ? { text: 'There is [red]hardly any citrus[/red] aboard.', back: 'Back to the chandler',
      go: 'Sail without it' } : null,
  }));
  const p = await Player.make({ engine: e1, seeds: ['5'], skins, sound: (c) => cues.push(c) });
  p.setUp();
  p.shop({ food: 2 });
  p.press('Pay');
  check(p.screen === 'message' && plain(p.f.screen.text) === 'The harbour master wants to see your papers first.',
    `the skin's refusal comes first (${p.screen})`);
  check(p.f.game.food === 200 && p.f.game.day === 0, 'paid for, and still in port');
  p.press('Continue');
  check(p.screen === 'shop', `the refusal goes back to the stores (${p.screen})`);
  refuse = false;
  p.press('Leave the shop');
  check(p.screen === 'ask', `then the warning (${p.screen})`);
  const d = p.look();
  check(d.blocks.map((b) => b.type).join('/') === 'scene/message' && plain(d.blocks[1].markup) === 'There is hardly any citrus aboard.',
    'the warning: the scene and the words, in a message box');
  check(p.labels().join('/') === 'Back to the chandler/Sail without it' && d.choices[0].primary && !d.choices[1].primary,
    `its answers, the way back first (${p.labels().join('/')})`);
  check(cues.at(-1) === 'message', `the warning sounds as a message does (${cues.at(-1)})`);
  check(p.f.game.day === 0 && p.f.game.atPort, 'nothing has happened yet');
  p.press('Back to the chandler');
  check(p.screen === 'shop', `heeded: back to the stores (${p.screen})`);
  p.press('Leave the shop');
  check(p.screen === 'ask', 'asked again on the way out');
  p.press('Sail without it');
  check(p.screen === 'depart' && p.f.screen.text.length > 0, `waved off: the departure (${p.screen})`);
  p.press('Set sail');
  check(p.screen === 'travel' && !p.f.game.atPort, 'and away');
  p.f.stopTravel();

  // With what the warning wants aboard, no warning.
  const q = await Player.make({ engine: e2, seeds: ['5'], skins });
  q.setUp();
  q.topUp({ food: 200, limes: 10 });
  q.press('Pay');
  check(q.screen === 'depart', `stocked: straight to the departure (${q.screen})`);
  check(q.problems.length === 0 && p.problems.length === 0, `no word went wrong: ${p.problems.concat(q.problems).slice(0, 3).join(' | ')}`);
});

await test('a skin\'s refusal to leave a port keeps you there; a port\'s hold says why, then the queue decides', async () => {
  let refuse = true;
  const skins = testSkin(() => ({ leaveRefusal: refuse ? 'The pilot will not take you out in [red]this fog[/red].' : null }));
  const storage = new MemoryStorage();
  const holds = [{ message: { _0: 'The harbour is closed until the tide turns.' } }];
  const p = await Player.make({ engine: holding(e1, holds), storage, seeds: ['9'], skins });
  const stop = inPort(p);
  check(p.screen === 'portMenu', `in port at ${stop.id} (${p.screen})`);
  const day = p.f.game.day;
  p.press(plain(p.words.leavePort));
  check(p.screen === 'message' && plain(p.f.screen.text) === 'The pilot will not take you out in this fog.', 'the skin\'s refusal');
  p.press('Continue');
  check(p.screen === 'portMenu' && p.f.game.atPort && p.f.game.day === day, `still in port, no time gone (${p.screen})`);
  refuse = false;
  p.press(plain(p.words.leavePort));
  check(p.screen === 'message' && p.f.screen.text === 'The harbour is closed until the tide turns.', `the port's hold (${p.screen})`);
  check(!p.f.traveling, 'not under way');
  const save = saveOf(storage);
  check(save?.pending?.length === 1 && save.pending[0].message?._0 === 'The harbour is closed until the tide turns.',
    'the hold is saved on screen (D10)');
  p.press('Continue');
  check(p.screen === 'portMenu' && p.f.game.atPort, `held: back to the port menu (${p.screen})`);
  check((saveOf(storage)?.pending ?? []).length === 0, 'and nothing left waiting');
  p.press(plain(p.words.leavePort));
  check(p.screen === 'travel' && p.f.traveling && !p.f.game.atPort, `let go: under way (${p.screen})`);
  p.f.stopTravel();

  // A hold whose answer lets the party go: under way once it is dealt with.
  const r = await Player.make({ engine: holding(e2, [{ message: { _0: 'The ice is going out.' } }], true), seeds: ['9'] });
  inPort(r);
  r.press(plain(r.words.leavePort));
  check(r.screen === 'message' && r.f.after === 'leaving', `the hold, then where the queue goes (${r.f.after})`);
  r.press('Continue');
  check(r.screen === 'travel' && r.f.traveling, `under way after it (${r.screen})`);
  r.f.stopTravel();
});

await test('the yard\'s row asks the skin\'s question where it has one, and opens the yard where it has none', async () => {
  const plainP = await Player.make({ engine: e1, seeds: ['9'] });
  inPort(plainP);
  plainP.press(plain(plainP.words.yard));
  check(plainP.screen === 'shipyard', `1849's yard row opens the yard (${plainP.screen})`);

  // A stand-in question: the engine's own trade, asked from the yard's row.
  const p = await Player.make({ engine: e2, seeds: ['9'], skins: testSkin(() => ({ yardQuestion: 'tradeAtPort' })) });
  inPort(p);
  p.press(plain(p.words.yard));
  check(['message', 'choice'].includes(p.screen) && p.f.after === 'portMenu', `the question instead (${p.screen}, ${p.f.after})`);
  for (let n = 0; n < 6 && p.screen !== 'portMenu'; n++) p.press(p.look().choices.findIndex((c) => c.enabled) + 1);
  check(p.screen === 'portMenu', `and back to the port menu (${p.screen})`);
});

await test('a voyage saved in the first stores comes back to them if the skin says so, to the port menu if not (D16)', async () => {
  for (const back of [true, false]) {
    const storage = new MemoryStorage();
    const skins = back ? testSkin(() => ({ resumesInFirstShop: true })) : undefined;
    const a = await Player.make({ engine: e1, storage, seeds: ['5'], skins });
    a.setUp();
    a.shop({ food: 2 });
    // The stores save as you leave them; the page is closed on the departure's words.
    a.press('Pay');
    check(a.screen === 'depart' && saveOf(storage)?.atPort && saveOf(storage)?.day === 0 && saveOf(storage)?.food === 200,
      'saved in the stores, paid for, not yet away');
    const b = await Player.make({ engine: e2, storage, seeds: ['6'], skins });
    b.press('Continue the voyage');
    check(b.screen === (back ? 'shop' : 'portMenu'), `${back ? 'the stores' : '1849\'s port menu'} (${b.screen})`);
    if (back) {
      b.press('Leave the shop');
      check(b.screen === 'depart', `and out through the departure (${b.screen})`);
    } else {
      b.press(plain(b.words.leavePort));
      check(b.screen === 'travel' && !b.f.game.atPort, `and the port menu's way out sets off with neither (${b.screen})`);
      b.f.stopTravel();
    }
  }
});

await test('the status box and the chart take the skin\'s place and stop names', async () => {
  const p = await Player.make({ engine: e1, seeds: ['9'], skins: testSkin(() => ({ place: 'At the pier', stopName: (st) => `${st.short}!` })) });
  const stop = inPort(p);
  const box = p.look().blocks.find((b) => b.type === 'status');
  check(box.region === 'At the pier', `the place after the date (${box.region})`);
  const next = p.f.journey.stops.find((st) => st.id === p.f.v.nextStop);
  check(box.rows.some((r) => r.label === `Next: ${next.short}!`), `the next stop by the skin's name (${box.rows.map((r) => r.label)})`);
  p.press(plain(p.words.chart));
  const legend = p.look().blocks.find((b) => b.type === 'legend').items;
  check(legend.every((x, i) => x.text.endsWith(`${p.f.journey.stops[i].short}!`) && x.label.startsWith(`${p.f.journey.stops[i].short}!, `)),
    'every stop in the legend by the skin\'s name');
  check(legend.find((x) => x.text === `✓ ${stop.short}!`), 'passed');

  const q = await Player.make({ engine: e2, seeds: ['9'] });
  inPort(q);
  const own = q.look().blocks.find((b) => b.type === 'status');
  check(own.region === q.f.v.region.name, `1849 writes the region even in port (${own.region})`);
  check(q.look().blocks.find((b) => b.type === 'heading').text === q.f.v.port.name, 'the port menu is headed by the port the engine finds');
});

console.log(`play: ${passed} checks passed, ${failures.length} failed`);
for (const f of failures) console.log(`FAILED ${f}`);
process.exit(failures.length ? 1 : 0);
