// The Iron Road in the web game's flow (web/js/flow.js, web/js/screens.js and the rail
// skin), played in Node through what the screens offer, as play.mjs plays 1849:
//
// - the picker: a plain visit opens on it, the journey chosen is remembered, and each
//   journey has its own save and its own top ten, with two voyages in progress at once;
// - whole seeded runs: on time, late, and laid over until the contract is forfeit;
// - leaving mid-queue at Cheyenne's helper offer and at Donner Summit, and coming back to
//   the same screen on a fresh engine;
// - the menus, the clock, driftwood counted in cords, and on every screen of every run no
//   sailor's word, no "undefined" and no "NaN".
//
//   node Tools/web-tests/rail.mjs
import { Player, engine, lcg, describe, plain, sailorProblems } from './player.mjs';
import { MemoryStorage } from '../../web/js/flow.js';
import { APP_NAME } from '../../web/js/screens.js';
import { reward } from '../../web/js/fishing.js';

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
const saveOf = (storage, id = 'rail') => JSON.parse(storage.getItem(`horn.save-${id}`) ?? 'null');
const screenWords = (f) => {
  const d = describe(f);
  return JSON.stringify(d.blocks.filter((b) => b.type !== 'scene')) + JSON.stringify(d.choices.map((c) => [c.label, c.enabled]));
};
const wordsOn = (d) => d.blocks.map((b) => plain(b.markup ?? b.text ?? b.label ?? '')).filter(Boolean).join(' ');

/** A rail player whose every look is also checked for sailor's words and the rail banner. */
async function railPlayer(o = {}) {
  const p = await Player.make({ journey: 'rail', ...o });
  const look = p.look.bind(p);
  p.look = () => {
    const d = look();
    // The picker lists every journey, 1849's subtitle and all.
    if (p.f.journey.id === 'rail' && p.screen !== 'picker') {
      p.problems.push(...sailorProblems(d, p.screen));
      if (d.banner !== 'THE IRON ROAD · 1869') p.problems.push(`${p.screen}: the banner reads ${d.banner}`);
    }
    return d;
  };
  return p;
}

const noProblems = (p, what = 'no word went wrong') => check(p.problems.length === 0, `${what}: ${p.problems.slice(0, 3).join(' | ')}`);

// MARK: - The picker

await test('a plain visit opens on the picker, and the journey chosen is remembered', async () => {
  const storage = new MemoryStorage();
  const p = await railPlayer({ engine: e1, storage, journey: null });
  check(p.screen === 'picker', `opens on the picker (${p.screen})`);
  const d = p.look();
  check(d.banner === APP_NAME.toUpperCase(), `the picker's banner (${d.banner})`);
  check(d.blocks[0].text === 'Choose a journey', 'choose a journey');
  check(p.labels().join('/') === 'Around the Horn/The Iron Road', `both journeys, in the engine's order (${p.labels()})`);
  check(d.choices[1].detail === p.f.journeys[1].subtitle, 'each with its subtitle');
  p.press('The Iron Road');
  check(p.screen === 'title' && p.f.journey.id === 'rail', 'the Iron Road\'s title card');
  check(storage.getItem('horn.lastJourney') === 'rail', 'remembered');
  check(p.labels().join('/') === 'Take the contract/Learn about the road/See the top ten/Choose another journey',
    `the title card's rows (${p.labels().join('/')})`);
  const card = p.look().blocks.find((b) => b.type === 'title');
  check(card.text === 'THE IRON\nROAD' && card.label === 'The Iron Road', 'the title, on two lines');

  const q = await railPlayer({ engine: e2, storage, journey: null });
  check(q.screen === 'title' && q.f.journey.id === 'rail', 'the next visit opens on the journey last chosen');
  q.press('Choose another journey');
  check(q.screen === 'picker', 'and the picker is a row away');
  q.press('Around the Horn');
  check(q.f.journey.id === 'horn1849' && storage.getItem('horn.lastJourney') === 'horn1849', 'choosing again is remembered');
  const r = await railPlayer({ engine: e2, storage, journey: 'rail' });
  check(r.screen === 'title' && r.f.journey.id === 'rail', '?journey=rail opens on the Iron Road whatever was last chosen');
  noProblems(p);
});

await test('learn pages, the setup and its way back, the Iron Road\'s own top ten', async () => {
  const p = await railPlayer({ engine: e1, seeds: ['4'], random: lcg(4) });
  p.press('Learn about the road');
  const headings = [];
  while (p.screen === 'learn') {
    headings.push(p.look().blocks[0].text);
    p.press(p.labels()[0]);
  }
  check(headings.join('/') === 'The road/Wood and water/The hills and the calendar', `three pages (${headings})`);
  p.press('See the top ten');
  const places = p.look().blocks.filter((b) => b.type === 'place');
  check(places.length === 10 && places[0].text === '1. Hattie Corrigan' && places[0].score === '8,350'
    && places[0].rank === 'Superintendent of the Line', `the road's own top ten (${places[0].text}, ${places[0].rank})`);
  p.press('Back');
  p.press('Take the contract');
  check(p.labels().join('/') === 'A Chicago freight contractor/A Pittsburgh boilermaker/A St. Louis river hand/How do they compare?/Back to the title',
    `who are you? (${p.labels().join('/')})`);
  p.press('How do they compare?');
  check(wordsOn(p.look()).includes('River hand — starts with $350.'), 'how they compare');
  p.press('Back');
  p.press('A St. Louis river hand');
  const fields = p.look().blocks.filter((b) => b.type === 'field');
  check(fields[0].label === "Engine's name" && fields[1].label === "Conductor's name" && fields[2].label === 'Crew member 1',
    'the engine, the conductor and the crew');
  p.press('Use these names', { ship: 'Iron Duke', captain: 'Amos' });
  check(p.labels().join('/') === 'June 1869/August 1869/October 1869/December 1869/February 1870/Ask for advice/Back to the title',
    `the months a train can leave in (${p.labels().join('/')})`);
  p.press('Ask for advice');
  check(p.f.screen.text.startsWith('The yardmaster looks at the sky'), 'the yardmaster');
  p.press('Continue');
  p.press('February 1870');
  check(wordsOn(p.look()).startsWith('Outfitting You have $350 to stock the Iron Duke.'), 'outfitting the Iron Duke');
  p.press('Back to the title');
  check(p.screen === 'title' && p.f.game === null, 'back to the title, nothing started');
  noProblems(p);
});

// MARK: - The shop, the menus, the clock

await test('the store, the menus and the contract clock', async () => {
  const p = await railPlayer({ engine: e1, seeds: ['41'], random: lcg(41) });
  p.setUp();
  const item = (k) => p.look().blocks.find((b) => b.type === 'item' && b.key === k);
  check(p.look().blocks[0].text === 'Pruitt & Daughters, Railroad Outfitters', 'the Omaha store');
  check(item('fuel').price === '$4/cord' && item('fuel').have.startsWith('Have 0 cords.'), `firewood by the cord (${item('fuel').price})`);
  check(item('water').price === '$2/100 gallons', `tank water by the hundred gallons (${item('water').price})`);
  check(item('tackle').have.startsWith('Have 0 coils.'), 'grapnel line in coils in the store');
  item('fuel').more();
  check(item('fuel').qtyUnit === 'cord' && item('fuel').count === '1', 'one cord in the cart is a cord');
  while (item('fuel').more());
  check(item('fuel').qty === 16, `the tender holds 16 cords (${item('fuel').qty})`);
  p.topUp({ water: 1200, food: 300, clothes: 5, meds: 3, sailcloth: 3, timber: 3, tackle: 40 });
  p.press(1);
  check(p.screen === 'depart', `paid and ready (${p.screen})`);
  check(wordsOn(p.look()).includes('whistles off from the Omaha yard'), 'the departure');
  check(p.labels()[0] === 'Whistle off', 'whistle off');
  p.press('Whistle off');
  check(p.screen === 'travel' && p.labels()[0] === 'Stop the train & take stock', 'rolling');
  const status = p.look().blocks.find((b) => b.type === 'status');
  const rows = Object.fromEntries(status.rows.map((r) => [plain(r.label), r.value]));
  check(rows.Firewood === '16 cords' && rows['Tank car'] === '1,200 gallons', `the stores in the status box (${rows.Firewood}, ${rows['Tank car']})`);
  check(rows.Contract === '12 days left', `the contract clock (${rows.Contract})`);
  check(rows['Next: Grand Island'] === '154 miles' && rows.Covered === '0 of 1,776 miles', 'the next stop and the miles');
  check('Running gear · Engine' in rows, 'the running gear and the engine');
  p.timers.fire();
  if (p.screen === 'travel') {
    const now = Object.fromEntries(p.look().blocks.find((b) => b.type === 'status').rows.map((r) => [plain(r.label), r.value]));
    check(now.Contract === '11 days and 20 hours left', `four hours later (${now.Contract})`);
    check(now.Firewood === '15 cords' || /^1[45](\.\d)? cords$/.test(now.Firewood), `wood burnt, in cords and tenths (${now.Firewood})`);
    p.press(1);
  }
  while (!['seaMenu', 'portMenu'].includes(p.screen)) p.press(1);
  check(p.screen === 'seaMenu', 'stopped on the line');
  check(p.labels().join('/') === 'Continue down the line/Check supplies & crew/Look at the map/Change pace (Timetable)'
    + '/Change rations (Hearty)/Stop and rest/Make repairs/Haul driftwood/Save and return to the title', `the menu (${p.labels().join('/')})`);
  for (const [row, screen] of [['Check supplies', 'supplies'], ['Look at the map', 'chart'], ['Make repairs', 'repairs']]) {
    p.press(row);
    check(p.screen === screen, `${row} opens ${screen}`);
    if (screen === 'supplies') {
      const w = wordsOn(p.look());
      check(w.includes(`The ${p.f.game.ship}`), 'the train by name');
      check(/left on the contract/.test(w) && /Crew · health/.test(w), 'the note and the crew');
      check(p.look().blocks.some((b) => b.type === 'crew' && b.tag === ' (conductor)'), 'the conductor');
    }
    if (screen === 'chart') {
      const legend = p.look().blocks.find((b) => b.type === 'legend').items;
      check(legend[0].text === '✓ Omaha' && legend[1].text === '► Grand Island' && legend.length === 16, 'the map\'s legend');
      check(p.look().blocks[0].text === 'Map of the road', 'the map');
    }
    if (screen === 'repairs') {
      check(p.labels()[0].startsWith('Work on the engine — 1 set of boiler fittings (have 3)'), `the engine (${p.labels()[0]})`);
      check(p.labels()[1].startsWith('Mend the running gear — 1 crate of car spares (have 3)'), 'the running gear');
    }
    p.press(p.labels().at(-1));
    check(p.screen === 'seaMenu', `and back from ${screen}`);
  }
  p.press('Change pace');
  check(p.labels().join('/') === 'Easy/Timetable/Wide open', 'the paces');
  p.press('Wide open');
  check(p.labels()[3] === 'Change pace (Wide open)', 'the pace changed');
  p.press('Change rations');
  check(wordsOn(p.look()).includes("With 5 aboard, that's 15 lbs a day."), `a day's rations (${wordsOn(p.look())})`);
  p.press('Lean');
  p.press('Change rations');
  // Worked out to a tenth of a pound (10.5) and written as the engine writes a number,
  // rounded down: what the app says.
  check(wordsOn(p.look()).includes("With 5 aboard, that's 10 lbs a day."), `lean rations (${wordsOn(p.look())})`);
  p.press('Lean');
  p.press('Stop and rest');
  check(p.labels().join('/') === '4 hours/8 hours/12 hours/1 day/Never mind', `how long to stop (${p.labels().join('/')})`);
  const day = p.f.game.day;
  p.press('8 hours');
  while (p.screen === 'message' || p.screen === 'choice') p.look().choices.find((c) => c.enabled).act();
  check(p.f.game.day === day + 2 || p.screen === 'gameOver', 'eight hours is two turns');
  noProblems(p);
});

// MARK: - Driftwood

await test('driftwood is hauled where the line follows a river, and counted in cords', async () => {
  for (const [role, limit] of [['merchant', '4 cords'], ['whaler', '6 cords']]) {
    const p = await railPlayer({ engine: e1, seeds: ['17'], random: lcg(17) });
    const f = p.f;
    e1.start({ journey: 'rail', role, ship: 'Prairie Queen', captain: 'Amos', crew: ['Hattie', 'Lars', 'Clara', 'Otto'],
      year: 1869, month: 9, seed: '9' });
    const s = e1.save([]);
    f.skin.debug.start(s, 2);
    s.fuel = 20;
    f.loadForDebug(s);
    check(p.screen === 'seaMenu' && f.v.region.id === 'platte', `on the Platte (${f.v.region.id})`);
    p.press('Haul driftwood');
    check(p.screen === 'fishing', `the river (${p.screen})`);
    const d = p.look();
    check(d.blocks[0].text === 'Driftwood', 'driftwood');
    check(d.blocks[1].items.join('|') === 'Casts: 60|Hauled: 0 cords|Time: 25', `the tally (${d.blocks[1].items.join('|')})`);
    const hint = plain(d.blocks.find((b) => b.type === 'para').markup);
    check(hint.endsWith(`The crew can cut and stack up to ${limit} at one stop.`), `the limit (${hint})`);
    check(p.labels().join('/') === 'Back to the train', 'and the way back');
    const pops = [];
    const m = f.screen.model;
    const onCatch = m.onCatch;
    m.onCatch = (k) => {
      pops.push(m.pops.at(-1).text);
      onCatch(k);
    };
    const caught = p.fish();
    check(caught > 0 && pops.length > 0, `pieces hauled out (${caught})`);
    check(pops.every((t) => /^\+\d+(\.\d)? cords?, [a-z ]+$/.test(t)), `what floats up is in cords (${pops.slice(0, 3).join(' | ')})`);
    check(pops.every((t) => !/^\+1 cords/.test(t) && !/^\+(?!1,)\d+(\.\d)? cord,/.test(t)), 'one cord, and two cords');
    check(p.screen === 'message', `the haul is reported (${p.screen})`);
    const kept = Math.min(caught, f.journey.roles.find((r) => r.role === role).catchLimit);
    check(f.game.fuel === 20 + kept, `the tender takes it: ${f.game.fuel} for ${kept} more tenths`);
    const rw = reward(f.journey, p.words);
    check(rw.measure(15) === '1.5 cords' && rw.measure(10) === '1 cord' && rw.measure(160) === '16 cords', 'cords as the app writes them');
    noProblems(p);
  }
  const p = await railPlayer({ engine: e1, seeds: ['18'] });
  e1.start({ journey: 'rail', role: 'merchant', ship: 'Prairie Queen', captain: 'Amos', crew: ['Hattie', 'Lars', 'Clara', 'Otto'],
    year: 1869, month: 9, seed: '9' });
  const s = e1.save([]);
  p.f.skin.debug.start(s, 7);
  p.f.loadForDebug(s);
  check(p.f.v.region.id === 'laramie' || p.f.v.region.id === 'reddesert', `away from any river (${p.f.v.region.id})`);
  p.press('Haul driftwood');
  check(p.screen === 'message' && p.f.screen.text === 'There is no river by the line here, and nothing afloat in the ditches.',
    `no river, no driftwood (${p.f.screen.text})`);
  p.press('Continue');
  check(p.screen === 'seaMenu', 'and back');
  noProblems(p);
});

// MARK: - Whole runs

await test('a careful contractor brings the freight in on time', async () => {
  const storage = new MemoryStorage();
  const p = await railPlayer({ engine: e1, storage, seeds: ['2'], random: lcg(2) });
  check(p.screen === 'title' && !p.labels().some((l) => l.startsWith('Climb back aboard')), 'nothing to climb back aboard');
  p.setUp({ names: { ship: 'Prairie Queen', captain: 'Amos', crew0: 'Hattie', crew1: 'Lars', crew2: 'Clara', crew3: 'Otto' } });
  let helper = null, donner = null, trestle = null;
  const end = p.voyage({
    onScreen: (q) => {
      if (q.screen !== 'choice' && q.screen !== 'message') return null;
      const s = q.f.screen;
      const key = s.event?.kind?.custom?.key;
      if (key === 'helper' && s.event.kind.custom.args[0] === 'cheyenne') helper = plain(s.event.prompt);
      if (key === 'donner') donner = plain(s.event.prompt);
      const text = s.event ? s.event.prompt : s.text;
      if (/Dale Creek trestle/.test(text)) trestle = q.f.game.mile;
      return null;
    },
  });
  check(end === 'finale', `the freight arrives (${end})`);
  check(p.f.game.day < 72, `inside twelve days (${p.f.game.day} turns)`);
  check(helper === 'A helper engine is steaming on the siding at Cheyenne, at the foot of Sherman Hill.', `the helper at Cheyenne (${helper})`);
  check(donner?.startsWith('Donner Summit, 7,000 feet up.'), 'the summit');
  check(trestle !== null, 'the trestle');
  check(p.caught > 0, `driftwood hauled (${p.caught})`);
  for (const s of ['outfit', 'shop', 'depart', 'travel', 'message', 'choice', 'portMenu', 'seaMenu', 'fishing', 'finale']) {
    check(p.seen.has(s), `the run showed the ${s} screen`);
  }
  const d = p.look();
  const words = wordsOn(d);
  check(/^Sacramento! The Prairie Queen rolls into the yard by the river on October \d+, 1869, .+, \d+ days( and \d+ hours)? out of Omaha\./.test(words),
    `the arrival (${words.slice(0, 140)})`);
  check(words.includes('The freight is on time.') && words.includes('a bath and a beefsteak'), 'on time, and the crew wants a bath');
  const sc = p.f.screen.finale.score;
  const early = sc.lines.find((l) => l.label === 'Days in hand on the contract');
  check(early && early.points > 0, `paid for the turns in hand (${early?.points})`);
  check(d.blocks.some((b) => b.type === 'row' && b.label === 'Bonus for being a freight contractor'), 'the bonus row');
  check(saveOf(storage) === null, 'the finished run leaves no save');
  const f = p.f.screen.finale;
  check(storage.getItem('horn.topten-horn1849') === null, '1849\'s top ten is untouched');
  if (f.place != null) {
    const table = JSON.parse(storage.getItem('horn.topten-rail'));
    check(table[f.place].name === 'Amos' && table[f.place].score === sc.total, 'the conductor is in the Iron Road\'s top ten');
  }
  check(p.labels().join('/') === 'Run it again/See the top ten', 'run it again');
  p.press('See the top ten');
  const places = p.look().blocks.filter((b) => b.type === 'place');
  check(places.length === 10 && places.every((x) => ['Superintendent of the Line', 'Master Conductor', 'Brakeman', 'Section Hand'].includes(x.rank)),
    'the road\'s ranks');
  p.press('Back');
  check(p.screen === 'message' && p.f.screen.text === 'Thanks for riding.' && p.labels()[0] === 'Run it again', 'thanks for riding');
  p.press('Run it again');
  check(p.screen === 'title' && p.f.journey.id === 'rail', 'back on the Iron Road\'s title card');
  noProblems(p);
});

await test('a freight that arrives on the twelfth day is late, and is told so', async () => {
  const p = await railPlayer({ engine: e1, seeds: ['31'], random: lcg(31) });
  p.setUp();
  let warned = false;
  const end = p.voyage({
    onScreen: (q) => {
      if (q.screen === 'message' && q.f.screen.text.startsWith('[amber]Twelve days out. The freight is now late.[/amber]')) warned = true;
      return null;
    },
  });
  check(end === 'finale', `it arrives (${end})`);
  check(p.f.game.day >= 72 && warned, `late, and warned (${p.f.game.day})`);
  const words = wordsOn(p.look());
  check(words.includes('a good deal to say about the date'), 'the consignee has words');
  noProblems(p);
});

await test('laid over at every yard, the contract is forfeit', async () => {
  const storage = new MemoryStorage();
  const p = await railPlayer({ engine: e1, storage, seeds: ['3'], random: lcg(3) });
  p.setUp();
  let saw = false;
  const end = p.voyage({
    layOver: 3,
    onScreen: (q) => {
      if (q.screen === 'travel' && q.f.game.day >= 72) {
        const rows = q.look().blocks.find((b) => b.type === 'status').rows;
        const clock = rows.find((r) => r.label === 'Contract').value;
        if (/^(late|\d+ (hours|days?( and \d+ hours)?) late)$/.test(clock)) saw = true;
      }
      return null;
    },
  });
  check(end === 'gameOver', `the run ends (${end})`);
  check(saw, 'the clock counts the hours late');
  const d = p.look();
  check(plain(d.blocks.find((b) => b.type === 'message').markup) === 'The contract is forfeit.', 'forfeit');
  const words = wordsOn(d);
  check(/Sixteen days out of Omaha and not yet in Sacramento\./.test(words), 'the consignee has wired');
  check(/miles out of Omaha\./.test(words), `how far the train got (${words.slice(-90)})`);
  check(saveOf(storage) === null && storage.getItem('horn.topten-rail') === null, 'no save and no top ten');
  p.press('Try again');
  check(p.screen === 'title' && !p.labels().some((l) => l.startsWith('Climb back aboard')), 'nothing to climb back aboard');
  noProblems(p);
});

// MARK: - Leaving mid-queue

/**
 * Plays seed 2's careful contractor until `stopAt` holds, leaves, and comes back on a
 * fresh engine. Returns both players, the one who stayed (`a`) and the one who came back
 * (`b`), on the same screen.
 */
async function leaveAt(stopAt, what) {
  const storage = new MemoryStorage();
  const a = await railPlayer({ engine: e1, storage, seeds: ['2'], random: lcg(2) });
  a.setUp();
  const end = a.voyage({ onScreen: (q) => (stopAt(q) ? 'stop' : null) });
  check(end === 'stopped', `the run reaches ${what} (${end})`);
  const save = saveOf(storage);
  check(save && Array.isArray(save.pending) && JSON.stringify(save.pending[0]) === JSON.stringify(a.f.showing),
    `the save holds ${what}, on screen`);
  check(save.journey === 'rail' && storage.getItem('horn.save-horn1849') === null, 'in the Iron Road\'s own save');
  const before = screenWords(a.f);
  const b = await railPlayer({ engine: e2, storage, seeds: ['99'], random: lcg(99) });
  const resume = b.labels().find((l) => l.startsWith('Climb back aboard the'));
  check(resume === `Climb back aboard the ${a.f.game.ship}`, `the title card offers the train (${resume})`);
  b.press('Climb back aboard');
  check(screenWords(b.f) === before, `${what} comes back as it was`);
  check(JSON.stringify(b.f.pending) === JSON.stringify(a.f.pending), 'with the same queue behind it');
  return { a, b, storage };
}

const choiceKey = (q) => (q.screen === 'choice' ? q.f.screen.event.kind?.custom ?? null : null);

await test('left at Cheyenne with the helper engine asking, the offer is there to come back to', async () => {
  const { a, b } = await leaveAt((q) => choiceKey(q)?.key === 'helper' && choiceKey(q).args[0] === 'cheyenne', 'the helper offer');
  check(b.labels()[0] === 'Hire the helper ($30)' && b.labels()[1] === 'Take the hill on your own steam', `the offer (${b.labels()})`);
  const money = b.f.game.money;
  a.press('Hire the helper');
  b.press('Hire the helper');
  check(b.f.game.money === money - 30 && b.f.game.vars['rail.helper.sherman'] === 1, 'hired, and paid for');
  check(screenWords(b.f) === screenWords(a.f), 'the same answer after coming back');
  check(b.screen === 'message' && b.f.screen.text.startsWith('Money changes hands.'), 'money changes hands');
  let guard = 0;
  while (b.screen !== 'portMenu' && guard++ < 10) {
    b.look().choices.find((c) => c.enabled).act();
  }
  check(b.screen === 'portMenu' && b.f.v.currentStop === 'cheyenne', `then the yard at Cheyenne (${b.screen})`);
  check(b.timers.running === 0, 'with the clock stopped');
  check(!('pending' in saveOf(a.f.persistence.storage)), 'a save on a menu has nothing waiting');
  const end = b.voyage();
  check(end === 'finale' || end === 'gameOver', `the run goes on to its end (${end})`);
  noProblems(a);
  noProblems(b);
});

await test('left at Donner Summit, the descent is there to come back to', async () => {
  const { a, b } = await leaveAt((q) => choiceKey(q)?.key === 'donner', 'the summit');
  check(b.labels().join('/') === 'Set the retainers and come down slow/Let her roll', `the two ways down (${b.labels().join('/')})`);
  check(wordsOn(b.look()).includes('Set the retainers and the train comes down slow and easy on her brakes.'), 'the detail');
  a.press('Set the retainers');
  b.press('Set the retainers');
  check(b.f.game.vars['rail.retainers'] === 1, 'the retainers are set');
  check(screenWords(b.f) === screenWords(a.f), 'the same answer after coming back');
  const end = b.voyage();
  check(end === 'finale', `down the mountain and in (${end})`);
  noProblems(a);
  noProblems(b);
});

// MARK: - Breakdowns

/** A train on the Platte from the debug start (stop 2), with `set` applied to it. */
async function trainAt(set, seed = '9', storage = new MemoryStorage()) {
  const p = await railPlayer({ engine: e1, storage, seeds: ['31'], random: lcg(31) });
  e1.start({ journey: 'rail', role: 'merchant', ship: 'Prairie Queen', captain: 'Amos', crew: ['Hattie', 'Lars', 'Clara', 'Otto'],
    year: 1869, month: 9, seed });
  const s = e1.save([]);
  p.f.skin.debug.start(s, 2);
  set(s);
  p.f.loadForDebug(s);
  return p;
}

/** The status box's rows by label: { value, color }. */
const statusRows = (p) => Object.fromEntries((p.look().blocks.find((b) => b.type === 'status')?.rows ?? [])
  .map((r) => [plain(r.label), { value: r.value, color: r.color }]));

await test('the report from play: an engine run down to nothing, no wood, nothing to mend with', async () => {
  const p = await trainAt((s) => Object.assign(s, { sails: 3, fuel: 0, sailcloth: 0, timber: 0, money: 0 }));
  p.press('Continue down the line');
  const meters = [], troubles = [], movedAtZero = [];
  for (let i = 0; i < 60 && p.screen !== 'gameOver'; i++) {
    if (p.screen !== 'travel') {
      p.look().choices.find((c) => c.enabled).act();
      continue;
    }
    const rows = statusRows(p);
    meters.push(rows['Running gear · Engine'].value);
    if (rows.Train) troubles.push(`${rows.Train.value}/${rows.Train.color}`);
    const g = p.f.game, mile = g.mile, zero = Math.round(g.sails) <= 0 || Math.round(g.hull) <= 0;
    p.timers.fire();
    if (zero) movedAtZero.push(p.f.game.mile - mile);
  }
  check(!meters.some((m) => m.includes('-')), `no meter below 0 (${[...new Set(meters)].slice(-4).join(' | ')})`);
  check(troubles.some((t) => t === 'Out of wood/red'), `the status box says the wood is gone (${[...new Set(troubles)]})`);
  check(movedAtZero.every((d) => d === 0), `a train at 0% does not move (${movedAtZero.join(',')})`);
  check(p.screen === 'gameOver', `with nothing to mend her and no money the run ends (${p.screen})`);
  noProblems(p);
});

const breakdownKey = (p) => p.screen === 'choice' && p.f.screen.event.kind?.custom?.key === 'breakdown';

await test('given out: she stands, the box says so, and fittings or a mechanic get her rolling', async () => {
  const storage = new MemoryStorage();
  const p = await trainAt((s) => Object.assign(s, { sails: 0, sailcloth: 1, money: 100 }), '9', storage);
  check(statusRows(p).Train?.value === 'Broken down' && statusRows(p).Train.color === 'red', 'the box says broken down, in red');
  const mile = p.f.game.mile, day = p.f.game.day;
  p.press('Continue down the line');
  p.timers.fire();
  check(breakdownKey(p), `the breakdown is asked (${p.screen})`);
  const d = p.look();
  check(wordsOn(d).startsWith('The engine has given out. The Prairie Queen stands dead on the line at mile 281'), `in red, plainly (${wordsOn(d).slice(0, 90)})`);
  check(d.blocks.some((b) => b.markup?.startsWith('[red]The engine has given out.[/red]')), 'the first words in red');
  check(p.labels().join('/') === 'Work on the engine: 1 set of boiler fittings (have 1)/Send Hattie walking for a mechanic ($45)/Climb down and take stock first',
    `what can be done (${p.labels().join('/')})`);
  check(p.f.game.mile === mile && p.f.game.day === day, 'no mile and no hour for asking');

  // Left on the question, it is there to come back to.
  const q = await railPlayer({ engine: e2, storage, seeds: ['99'], random: lcg(99) });
  q.press('Climb back aboard');
  check(screenWords(q.f) === screenWords(p.f), 'the breakdown comes back as it was');
  q.press('Climb down and take stock first');
  check(q.screen === 'seaMenu' && q.f.game.mile === mile, `taking stock, on the menu, where she stands (${q.screen})`);
  check(statusRows(q).Train?.value === 'Broken down', 'still broken down');
  q.press('Continue down the line');
  q.timers.fire();
  check(breakdownKey(q), 'and asked again on the way out');
  q.press('Work on the engine');
  check(q.screen === 'message' && q.f.screen.text.endsWith('[green](Engine now 25%)[/green]'), `mended (${q.f.screen.text})`);
  q.press('Continue');
  check(q.screen === 'travel' && !statusRows(q).Train, `rolling, with nothing wrong in the box (${q.screen})`);
  q.timers.fire();
  check(q.f.game.mile > mile, 'and moving');
  noProblems(p);
  noProblems(q);
});

await test('with no fittings, somebody walks for a mechanic; with no money either, stranded', async () => {
  const p = await trainAt((s) => Object.assign(s, { hull: 0, sails: 0, sailcloth: 0, timber: 0, money: 100 }));
  p.press('Continue down the line');
  p.timers.fire();
  check(breakdownKey(p) && wordsOn(p.look()).startsWith('The engine and the running gear have both given out.'), 'both');
  check(p.look().choices.map((c) => c.enabled).join() === 'false,false,true,true', 'nothing to mend with: walk or take stock');
  const day = p.f.game.day;
  p.press('Send Hattie walking');
  check(p.f.screen.text.startsWith('Hattie sets off down the ties'), `off she goes (${p.f.screen.text})`);
  let said = '';
  while (p.screen === 'message') {
    said += p.f.screen.text;
    p.press(1);
  }
  check(said.includes('A handcar comes clacking up the line') && said.includes('[green](Engine 40%, Running gear 40%)[/green]'), 'the mechanic comes');
  check(p.f.game.money === 55 && p.f.game.day >= day + 3 && p.f.game.day <= day + 6, `$45 and twelve hours to a day (${p.f.game.money}, ${p.f.game.day - day})`);
  check(p.screen === 'travel', `and on down the line (${p.screen})`);
  noProblems(p);

  const r = await trainAt((s) => Object.assign(s, { hull: 0, sailcloth: 3, timber: 0, money: 44 }));
  r.press('Continue down the line');
  r.timers.fire();
  check(r.screen === 'gameOver' && r.f.screen.title === 'Stranded at mile 281.', `stranded (${r.screen}: ${r.f.screen.title})`);
  check(wordsOn(r.look()).includes('There is nothing aboard to mend her with'), 'and why');
  noProblems(r);
});

await test('out of wood she crawls, the box says so, and wood puts her right', async () => {
  const p = await trainAt((s) => Object.assign(s, { fuel: 0 }));
  check(statusRows(p).Train?.value === 'Out of wood' && statusRows(p).Train.color === 'red', 'the box says out of wood');
  const mile = p.f.game.mile, sails = p.f.game.sails;
  p.press('Continue down the line');
  p.timers.fire();
  check(p.screen === 'message' && p.f.screen.text.includes('You are barely moving'), `the woodpile is gone (${p.f.screen.text})`);
  const crawl = p.f.game.mile - mile;
  check(crawl > 0 && crawl <= 10, `crawling (${crawl} miles in four hours)`);
  check(p.f.game.sails < sails - 0.4, 'and the fence posts wear the engine');
  p.press('Continue');
  p.press('Stop the train');
  // Wood again, as a yard or the river would give it, and North Platte not yet in sight.
  const s = e1.save([]);
  s.fuel = 50;
  s.mile = 200;
  p.f.loadForDebug(s);
  check(p.screen === 'seaMenu' && !statusRows(p).Train, `wood again, and nothing wrong in the box (${p.f.game.fuel})`);
  const m2 = p.f.game.mile;
  p.press('Continue down the line');
  p.timers.fire();
  check(p.f.game.mile - m2 > 20, `and full speed (${p.f.game.mile - m2} miles)`);
  noProblems(p);
});

// MARK: - Two voyages at once

await test('a voyage on each journey, in progress at once, each with its own save', async () => {
  const storage = new MemoryStorage();
  const p = await railPlayer({ engine: e1, storage, seeds: ['7', '8'], random: lcg(7), journey: null });
  p.press('Around the Horn');
  p.setUp({ names: { ship: 'Sea Lark' } });
  p.topUp({ food: 1500, water: 600, limes: 10, clothes: 5, meds: 3, sailcloth: 3, timber: 3, tackle: 40 });
  p.press(1);
  p.press('Set sail');
  for (let i = 0; i < 3 && p.screen === 'travel'; i++) p.timers.fire();
  while (!['seaMenu', 'portMenu'].includes(p.screen)) p.press(1);
  const horn = { day: p.f.game.day, mile: p.f.game.mile };
  p.press('Save and return to the title');
  check(p.screen === 'title' && p.timers.running === 0, 'saved and on the title card');
  check(p.labels()[1] === 'Continue the voyage of the Sea Lark', `1849's title card offers it (${p.labels()[1]})`);
  p.press('Choose another journey');
  check(p.labels().join('/') === 'Around the Horn · in progress/The Iron Road', `the picker marks it (${p.labels().join('/')})`);
  p.press('The Iron Road');
  check(!p.labels().some((l) => l.startsWith('Climb back aboard')), 'the Iron Road has nothing to climb back aboard');
  p.setUp({ names: { ship: 'Iron Duke' } });
  p.topUp({ fuel: 160, water: 1200, food: 300, clothes: 5, tackle: 20 });
  p.press(1);
  p.press('Whistle off');
  for (let i = 0; i < 2 && p.screen === 'travel'; i++) p.timers.fire();
  while (!['seaMenu', 'portMenu'].includes(p.screen)) p.press(1);
  const rail = { day: p.f.game.day, mile: p.f.game.mile };
  p.press('Save and return to the title');
  check(p.labels()[1] === 'Climb back aboard the Iron Duke', 'the Iron Road\'s title card offers its own');
  const sh = saveOf(storage, 'horn1849'), sr = saveOf(storage, 'rail');
  check(sh?.journey === 'horn1849' && sh.ship === 'Sea Lark' && sh.day === horn.day, 'the voyage around the Horn, saved as it stood');
  check(sr?.journey === 'rail' && sr.ship === 'Iron Duke' && sr.day === rail.day, 'the train, saved as it stood');
  p.press('Choose another journey');
  check(p.labels().join('/') === 'Around the Horn · in progress/The Iron Road · in progress', `both in progress (${p.labels().join('/')})`);

  // A new visit, another engine: each comes back as it was left.
  const q = await railPlayer({ engine: e2, storage, seeds: ['9'], random: lcg(9), journey: null });
  check(q.screen === 'title' && q.f.journey.id === 'rail', 'the visit opens on the journey last chosen');
  q.press('Climb back aboard');
  check(q.screen === 'seaMenu' && q.f.game.ship === 'Iron Duke' && q.f.game.mile === rail.mile && q.f.game.day === rail.day,
    'the train, where it stopped');
  q.press('Save and return to the title');
  q.press('Choose another journey');
  q.press('Around the Horn');
  q.press('Continue the voyage');
  check(q.f.journey.id === 'horn1849' && q.f.game.ship === 'Sea Lark' && q.f.game.mile === horn.mile, 'the ship, where it hove to');
  check(q.look().banner === 'AROUND THE HORN · 1849', '1849 in its own dress');
  const end = q.voyage({ targets: { food: 1500, water: 600, limes: 10, clothes: 5, meds: 3, sailcloth: 3, timber: 3, tackle: 40 } });
  check(end === 'finale' || end === 'gameOver', `1849's voyage ends (${end})`);
  check(saveOf(storage, 'horn1849') === null, 'its save goes with it');
  check(saveOf(storage, 'rail')?.ship === 'Iron Duke', 'the train\'s is still there');
  check(storage.getItem('horn.topten-rail') === null, 'and the Iron Road\'s top ten is untouched');
  q.press(1);
  q.press('Choose another journey');
  check(q.labels().join('/') === 'Around the Horn/The Iron Road · in progress', `one left in progress (${q.labels().join('/')})`);
  noProblems(p);
  noProblems(q);
});

console.log(`rail: ${passed} checks passed, ${failures.length} failed`);
for (const f of failures) console.log(`FAILED ${f}`);
process.exit(failures.length ? 1 : 0);
