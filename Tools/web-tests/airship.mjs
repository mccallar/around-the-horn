// Over the Pole in the web game's flow (web/js/flow.js, web/js/screens.js and the airship
// skin), played in Node through what the screens offer, as rail.mjs plays the Iron Road:
//
// - the picker offers it; its title card, learn pages, setup and top ten are its own, in
//   its own words (D11);
// - Rome's stores refuse empty tanks, and a flight saved in them comes back to them (D16);
//   a purse too thin for a step of petrol or provisions leaves dry and hungry (D22);
// - whole seeded flights: landings at Nome through every stop, and every other ending:
//   forced down on the ice, the sea and a field, grounded at a mast, the captain lost;
// - every kind of trouble (D14) and each way out of it: engines dead (spares aloft, or
//   drifting to a mast's mechanics), tanks dry (pilot balloons, or a mast's petrol), the
//   last of the petrol, going down (ballast, petrol, the ground crew at a mast, or nothing);
//   repairs and the trouble's choices in the condition box's order (D15);
// - leaving mid-trouble and coming back to the same screen and the same plight on a fresh
//   engine; and on every screen of every flight no other journey's word, no "undefined"
//   and no "NaN".
//
//   node Tools/web-tests/airship.mjs
import { Player, engine, lcg, describe, plain, foreignProblems } from './player.mjs';
import { MemoryStorage } from '../../web/js/flow.js';

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
const saveOf = (storage, id = 'airship') => JSON.parse(storage.getItem(`horn.save-${id}`) ?? 'null');
const screenWords = (f) => {
  const d = describe(f);
  return JSON.stringify(d.blocks.filter((b) => b.type !== 'scene')) + JSON.stringify(d.choices.map((c) => [c.label, c.enabled]));
};
const wordsOn = (d) => d.blocks.map((b) => plain(b.markup ?? b.text ?? b.label ?? '')).filter(Boolean).join(' ');

/** D11: the lines no journey may use. */
const D11 = /Many kinds of people|You may:|Find out the differences|\bBe an? [a-z]+ from\b|\bFilling\b|\bMeager\b|Bare bones|Attempt to trade/;

/** An airship player whose every look is also checked for other journeys' words and the banner. */
async function airPlayer(o = {}) {
  const p = await Player.make({ journey: 'airship', ...o });
  const look = p.look.bind(p);
  p.look = () => {
    const d = look();
    if (p.f.journey.id === 'airship' && p.screen !== 'picker') {
      p.problems.push(...foreignProblems(d, p.screen));
      const all = wordsOn(d) + ' ' + d.choices.map((c) => plain(c.label)).join(' ');
      const m = all.match(D11);
      if (m) p.problems.push(`${p.screen}: D11's "${m[0]}"`);
      if (d.banner !== 'OVER THE POLE · 1926') p.problems.push(`${p.screen}: the banner reads ${d.banner}`);
    }
    return d;
  };
  return p;
}

const noProblems = (p, what = 'no word went wrong') => check(p.problems.length === 0, `${what}: ${p.problems.slice(0, 3).join(' | ')}`);

/** The status box's rows by label: { value, color }. */
const statusRows = (p) => Object.fromEntries((p.look().blocks.find((b) => b.type === 'status')?.rows ?? [])
  .map((r) => [plain(r.label), { value: r.value, color: r.color }]));

/**
 * An airship from the debug start, 400 km short of `stop` (a watch's flying from anywhere),
 * with `set` applied to it, on its menu.
 */
async function shipAt(set, { stop = 3, seed = '9', storage = new MemoryStorage(), role = 'merchant' } = {}) {
  const p = await airPlayer({ engine: e1, storage, seeds: ['31'], random: lcg(31) });
  e1.start({ journey: 'airship', role, ship: 'Kittiwake', captain: 'Leif', crew: ['Rosa', 'Olav', 'Edith', 'Natale'],
    year: 1926, month: 4, seed });
  const s = e1.save([]);
  p.f.skin.debug.start(s, stop);
  s.mile = J0.stops[stop].mile - 400;
  set(s);
  p.f.loadForDebug(s);
  return p;
}
const J0 = (await airPlayer({ engine: e1 })).f.journey;
const stopIndex = (id) => J0.stops.findIndex((s) => s.id === id);
/** Over the mast at `id`, its arrival told, not moored. */
const overMast = (id) => (s) => Object.assign(s, { stopIndex: stopIndex(id), mile: J0.stops[stopIndex(id)].mile });
const choiceKey = (p) => (p.screen === 'choice' ? p.f.screen.event.kind?.custom?.key ?? null : null);
/** Presses through messages, gathering their words. */
const readOn = (p) => {
  let said = '';
  while (p.screen === 'message') {
    said += `${p.f.screen.text}\n`;
    p.press(1);
  }
  return said;
};

// MARK: - The picker, the title card, the setup

await test('the picker offers Over the Pole, and its title card, pages, setup and top ten are its own', async () => {
  const storage = new MemoryStorage();
  const p = await airPlayer({ engine: e1, storage, journey: null, seeds: ['4'], random: lcg(4) });
  check(p.screen === 'picker' && p.labels().includes('Over the Pole'), `the picker offers it (${p.labels()})`);
  p.press('Over the Pole');
  check(p.screen === 'title' && p.look().banner === 'OVER THE POLE · 1926', 'its title card');
  check(storage.getItem('horn.lastJourney') === 'airship', 'and remembers the choice');
  const q = await airPlayer({ engine: e2, storage, journey: null });
  check(q.screen === 'title' && q.f.journey.id === 'airship', 'a new visit opens on it');
  const r = await airPlayer({ engine: e2, journey: 'airship' });
  check(r.screen === 'title' && r.f.journey.id === 'airship', '?journey=airship opens on it');

  p.press('Learn about the flight');
  const headings = [];
  while (p.screen === 'learn') {
    headings.push(p.look().blocks[0].text);
    p.press(p.labels()[0]);
  }
  check(headings.join('/') === 'The flight/Petrol, lift and engines/The Pole', `three pages (${headings})`);
  p.press('See the top ten');
  const places = p.look().blocks.filter((b) => b.type === 'place');
  check(places.length === 10 && places[0].text === `1. ${J0.defaultTopTen[0].name}`,
    `the flight's own top ten (${places[0]?.text}, ${places[0]?.rank})`);
  p.press('Back');
  p.press('Fly for the Pole');
  check(p.labels().join('/') === `${J0.roles.map((x) => x.label).join('/')}/What does each one bring?/Back to the title`,
    `who are you? (${p.labels().join('/')})`);
  check(wordsOn(p.look()).includes('took money, nerve or know-how'), 'in its own words (D11)');
  p.press('What does each one bring?');
  check(wordsOn(p.look()).includes('Meteorologist — starts with $470.'), 'what each one brings');
  p.press('Back');
  p.press(J0.roles[2].label);
  const fields = p.look().blocks.filter((b) => b.type === 'field');
  check(fields[0].label === "Airship's name" && fields[1].label === "Captain's name" && fields[2].label === 'Crew member 1',
    'the airship, the captain and the crew');
  p.press('Use these names', { ship: 'Kittiwake', captain: 'Leif' });
  check(p.labels().join('/') === 'April 1926/May 1926/June 1926/July 1926/Ask for advice/Back to the title',
    `the months she can leave in (${p.labels().join('/')})`);
  p.press('Ask for advice');
  check(p.f.screen.text.startsWith('The old balloonist on the bench'), 'the old balloonist');
  p.press('Continue');
  p.press('July 1926');
  check(wordsOn(p.look()).startsWith('Fitting out You have $470 to fit out the Kittiwake.'), `fitting out the Kittiwake (${wordsOn(p.look()).slice(0, 60)})`);
  p.press('Back to the title');
  check(p.screen === 'title' && p.f.game === null, 'back to the title, nothing started');
  noProblems(p);
});

// MARK: - Rome's stores

await test('Rome\'s stores refuse empty tanks, and a flight saved in them comes back to them (D16)', async () => {
  const storage = new MemoryStorage();
  const a = await airPlayer({ engine: e1, storage, seeds: ['5'], random: lcg(5) });
  a.setUp();
  check(a.screen === 'shop' && a.f.game.fuel === 0, 'in the stores with empty tanks');
  a.shop({ food: 10 });
  a.press('Pay');
  check(a.screen === 'message' && a.f.screen.text === "You can't cast off with empty tanks! The storekeeper shakes his head and points you back to the petrol.",
    `empty tanks are refused (${a.f.screen.text})`);
  a.press(1);
  check(a.screen === 'shop', 'and it is back to the stores');
  check(saveOf(storage)?.atPort && saveOf(storage).day === 0 && saveOf(storage).food === 100, 'the provisions bought, saved in the stores');
  const b = await airPlayer({ engine: e2, storage, seeds: ['6'], random: lcg(6) });
  check(b.labels()[1] === `Continue the flight of the ${saveOf(storage).ship}`, `the title card offers the flight (${b.labels()[1]})`);
  b.press('Continue the flight');
  check(b.screen === 'shop', `back in Rome's stores (${b.screen})`);
  b.topUp({ fuel: 8000, water: 300, limes: 10, clothes: 5, sailcloth: 3, timber: 3, tackle: 40 });
  b.press('Pay');
  check(b.screen === 'depart' && b.f.screen.text.includes('slips the mast at Ciampino'), `and out through the departure (${b.f.screen.text?.slice(0, 80)})`);
  b.press('Head north');
  check(b.screen === 'travel', 'under way');
  b.f.stopTravel();
  noProblems(a);
  noProblems(b);
});

await test('a purse too thin for a step of petrol or provisions, and neither aboard: she leaves dry and hungry, and says so (D22)', async () => {
  const p = await airPlayer({ engine: e1, seeds: ['7'], random: lcg(7) });
  p.setUp({ role: J0.roles[1].label });
  check(p.f.game.money === 580, `an engineer's purse (${p.f.game.money})`);
  p.shop({ sailcloth: 10, meds: 10, clothes: 8, timber: 8, water: 1 });
  check(p.f.game.money - p.f.bill === 1, `a dollar left, under a step of petrol ($1.50) or provisions ($5) (${p.f.game.money - p.f.bill})`);
  p.press('Pay');
  check(p.f.v.hooks.firstPortSells.fuel === false && p.f.v.hooks.departsUnfed === true, 'the purse runs to neither');
  check(p.screen === 'depart' && p.f.screen.text.includes(' Her tanks are empty, so she leaves on the wind alone')
    && p.f.screen.text.endsWith('so the crew will go hungry until somebody sells you food.'),
  `away from Rome, dry and hungry (${p.screen}: ${p.f.screen.text?.slice(-160)})`);
  p.press(1);
  for (let i = 0; i < 3000 && p.screen !== 'gameOver' && p.screen !== 'finale'; i++) {
    if (p.screen === 'travel') p.timers.fire();
    else p.look().choices.find((c) => c.enabled).act();
  }
  check(p.screen === 'gameOver' || p.screen === 'finale', `and it ends, never a loop (${p.screen})`);
  noProblems(p);
});

// MARK: - Whole flights

await test('careful flights land at Nome, through every stop on the way', async () => {
  let landed = 0;
  const stopsSeen = new Set();
  for (const [seed, role, month] of [['3', 0, 'May 1926'], ['11', 1, 'May 1926'], ['17', 2, 'June 1926'], ['23', 0, 'June 1926']]) {
    const storage = new MemoryStorage();
    const p = await airPlayer({ engine: e1, storage, seeds: [seed], random: lcg(Number(seed)) });
    p.setUp({ role: J0.roles[role].label, month });
    const seen = new Set();
    const end = p.voyage({ onScreen: (q) => { if (q.f.game) seen.add(q.f.game.stopIndex); return null; } });
    if (end === 'finale') {
      landed += 1;
      for (const i of seen) stopsSeen.add(i);
      const words = wordsOn(p.look());
      check(words.includes('Land ho!') && words.includes('over the roofs of Nome') && words.includes('The whole town turns out'),
        `the landing, as the engine tells it (${words.slice(0, 80)})`);
      check(saveOf(storage) === null, 'the save goes with the landing');
      check(JSON.parse(storage.getItem('horn.topten-airship') ?? '[]').length === 10 && storage.getItem('horn.topten-rail') === null,
        'into the flight\'s own top ten');
      check(seen.size === J0.stops.length, `${J0.roles[role].title} from seed ${seed}: every stop (${[...seen].join(',')})`);
    }
    noProblems(p, `seed ${seed}`);
  }
  check(landed >= 2, `careful flights land (${landed} of 4)`);
  check(stopsSeen.size === J0.stops.length, `every stop seen (${stopsSeen.size} of ${J0.stops.length})`);
});

await test('every other ending: forced down on the ice, the sea and a field, grounded at a mast, the captain lost', async () => {
  const downAt = async (mile, where) => {
    const stop = J0.stops.findIndex((s) => s.mile > mile);
    const p = await shipAt((s) => Object.assign(s, { mile, stopIndex: stop - 1, hull: 0.3, timber: 0, fuel: 100 }), { stop });
    p.press('Continue the flight');
    p.timers.fire();
    check(p.screen === 'gameOver' && p.f.screen.title === 'The [i]Kittiwake[/i] has been forced down.',
      `forced down over ${where} (${p.screen}: ${p.f.screen.title})`);
    const words = wordsOn(p.look());
    check(p.look().blocks.some((b) => b.type === 'scene') && p.f.v.state.over, 'the scene shows where she came down');
    noProblems(p);
    return words;
  };
  const ice = await downAt(6000, 'the Polar Sea'), sea = await downAt(2200, 'the North Sea'), field = await downAt(3300, 'Scandinavia');
  check(/ice/.test(ice) && /fishing boat/.test(sea) && sea !== field && ice !== field, 'each where it happens');

  const g = await shipAt(overMast('oslo'), {});
  Object.assign(g.f.game, {});
  const p = await shipAt((s) => { overMast('oslo')(s); Object.assign(s, { hull: 0.3, money: 5, timber: 0, fuel: 100 }); });
  p.press('Continue the flight');
  p.timers.fire();
  check(p.screen === 'gameOver' && p.f.screen.title === 'Grounded at Oslo.', `grounded at Oslo (${p.f.screen.title})`);
  check(wordsOn(p.look()).includes('walked into the shed at Oslo'), 'walked into the shed');
  noProblems(p);
  noProblems(g);

  const c = await shipAt((s) => {
    s.crew[0].hp = 1;
    s.crew[0].ailment = J0.ailments.reduce((a, b) => (b.damage > a.damage ? b : a));
    s.meds = 0;
  });
  c.press('Continue the flight');
  for (let i = 0; i < 60 && c.screen !== 'gameOver'; i++) {
    if (c.screen === 'travel') c.timers.fire();
    else c.look().choices.find((x) => x.enabled).act();
  }
  check(c.screen === 'gameOver' && /^You, Captain Leif, have died of /.test(c.f.screen.title), `the captain lost (${c.f.screen.title})`);
  noProblems(c);
});

// MARK: - Trouble (D14) and the order of repairs (D15)

await test('worn to nothing with nothing to mend with: no meter below 0%, and she drifts, then goes down', async () => {
  const p = await shipAt((s) => Object.assign(s, { sails: 3, hull: 4, fuel: 300, sailcloth: 0, timber: 0, money: 0 }));
  p.press('Continue the flight');
  const meters = [], troubles = [];
  for (let i = 0; i < 80 && p.screen !== 'gameOver'; i++) {
    if (p.screen !== 'travel') {
      p.look().choices.find((c) => c.enabled).act();
      continue;
    }
    const rows = statusRows(p);
    meters.push(rows['Lift · Engines'].value);
    if (rows.Airship) troubles.push(`${rows.Airship.value}/${rows.Airship.color}`);
    p.timers.fire();
  }
  check(meters.length > 1 && !meters.some((m) => m.includes('-')), `no meter below 0 (${[...new Set(meters)].slice(-4).join(' | ')})`);
  check(troubles.every((t) => t.endsWith('/red')) && troubles.some((t) => t.startsWith('Engines dead') || t.startsWith('Tanks dry')),
    `the box says what is wrong, in red (${[...new Set(troubles)]})`);
  check(p.screen === 'gameOver', `with nothing to throw over the side she comes down (${p.screen}: ${p.f.screen.title})`);
  noProblems(p);
});

await test('the condition box, the repairs and the yard list the lift first (D15)', async () => {
  const p = await shipAt((s) => Object.assign(s, { hull: 30, sails: 30 }));
  check(Object.keys(statusRows(p)).includes('Lift · Engines') && statusRows(p)['Lift · Engines'].value === '30% · 30%', 'lift, then the engines');
  p.press('Make repairs aloft');
  check(p.labels().join('/') === 'Drop a bag of ballast (have 3)/Fit engine spares — 1 box (have 3)/Done', `repairs aloft (${p.labels().join('/')})`);
  p.press('Drop a bag of ballast');
  check(p.f.game.timber === 2 && p.f.game.hull === 50, `a bag of ballast lifts her (${p.f.game.hull})`);
  const y = await shipAt((s) => Object.assign(s, { stopIndex: stopIndex('oslo'), mile: J0.stops[stopIndex('oslo')].mile, atPort: true, hull: 40, sails: 40 }));
  y.say(y.words.yard);
  check(/^Top up the gas — \$\d+\/Overhaul the engines — \$\d+\/Back to the mast$/.test(y.labels().join('/')), `the gas plant and the mechanics (${y.labels().join('/')})`);
  noProblems(p);
  noProblems(y);
});

await test('engines dead: she drifts, the box says so, and a box of spares gets her under power', async () => {
  const p = await shipAt((s) => Object.assign(s, { sails: 0.4, sailcloth: 1 }));
  check(statusRows(p).Airship?.value === 'Engines dead, adrift' && statusRows(p).Airship.color === 'red', 'the box says so, in red');
  check(statusRows(p)['Lift · Engines'].value === '72% · 0%', `the engines at 0%, never below (${statusRows(p)['Lift · Engines'].value})`);
  p.say(p.words.supplies);
  check(wordsOn(p.look()).includes('the engines are dead'), 'the supplies note');
  p.f.backToMenu();
  p.say(p.words.changePace);
  check(wordsOn(p.look()).includes('With the engines dead, it makes no difference.'), 'the speed screen');
  p.f.backToMenu();
  const { mile, fuel } = p.f.game;
  p.press('Continue the flight');
  p.timers.fire();
  const said = readOn(p);
  check(said.includes('The engines have given out.') && said.includes('she is a free balloon, going where the wind goes'), `told once (${said.slice(0, 120)})`);
  check(p.f.game.fuel === fuel && p.f.game.mile > mile && p.f.game.mile - mile < 100, `adrift: no petrol burnt, and some way made (${p.f.game.mile - mile} km)`);
  if (p.screen === 'travel') p.press(1);
  p.press('Make repairs aloft');
  p.press('Fit engine spares');
  check(p.f.game.sails > 0.4 && p.f.game.sailcloth === 0, `spares fitted (${p.f.game.sails})`);
  if (p.screen === 'message') readOn(p);
  if (p.screen === 'repairs') p.press('Done');
  check(p.screen === 'seaMenu' && !statusRows(p).Airship, `and nothing wrong in the box (${p.screen}: ${JSON.stringify(statusRows(p).Airship)})`);
  const m2 = p.f.game.mile, f2 = p.f.game.fuel;
  p.press('Continue the flight');
  p.timers.fire();
  check(p.f.game.fuel < f2 && p.f.game.mile > m2, `under power again (${p.f.game.mile - m2} km on ${f2 - p.f.game.fuel} kg)`);
  noProblems(p);
});

await test('engines dead with no spares: she drifts on to the next mast, and its mechanics overhaul them', async () => {
  const p = await shipAt((s) => Object.assign(s, { sails: 0, sailcloth: 0, mile: J0.stops[3].mile - 150 }));
  p.press('Continue the flight');
  let watches = 0;
  for (let i = 0; i < 80 && p.screen !== 'portMenu'; i++) {
    if (p.screen === 'travel') {
      p.timers.fire();
      watches += 1;
    } else if (p.screen === 'choice' && 'portArrival' in p.f.screen.event.kind) {
      p.press(1);
    } else {
      p.look().choices.find((c) => c.enabled).act();
    }
  }
  check(p.screen === 'portMenu' && p.f.v.currentStop === 'oslo' && watches > 1, `drifted in to Oslo (${p.screen}, ${watches} watches)`);
  check(statusRows(p).Airship?.value === 'Engines dead', `moored, the box says engines dead (${statusRows(p).Airship?.value})`);
  p.say(p.words.yard);
  p.press('Overhaul the engines');
  readOn(p);
  check(p.f.game.sails > 0 && !statusRows(p).Airship, `overhauled (${p.f.game.sails})`);
  noProblems(p);
});

await test('tanks dry: adrift, pilot balloons find petrol, and a mast sells it', async () => {
  const fair = J0.weathers.find((w) => w.rawValue === 'fair');
  const p = await shipAt((s) => Object.assign(s, { fuel: 0, tackle: 60, weather: fair }), { role: 'whaler' });
  check(statusRows(p).Airship?.value === 'Tanks dry, adrift' && statusRows(p).Petrol.value === '0 kg', 'the box says tanks dry');
  check(p.f.skin.words(p.f.v).suppliesNote.includes('the tanks are dry'), 'and the supplies note');
  p.say(p.words.forage);
  check(p.screen === 'fishing', `the winds (${p.screen})`);
  const found = p.fish();
  const limit = J0.roles.find((r) => r.role === 'whaler').catchLimit;
  while (p.screen === 'fishing') p.press(1);
  const report = readOn(p);
  check(report.includes(`${Math.min(found, limit).toLocaleString('en-US')} kg`), `the session's report (${report.slice(0, 120)})`);
  // What is kept goes in the tanks, and the session's watch burns some of it.
  check(found > 0 && p.f.game.fuel > 0 && p.f.game.fuel <= Math.min(found, limit), `pilot balloons find petrol (${found} kg, ${p.f.game.fuel} left)`);
  check(statusRows(p).Airship?.value !== 'Tanks dry, adrift', `no longer dry (${statusRows(p).Airship?.value})`);

  // One voyage in hand per engine: the next flight starts once this one is done with.
  const a = await shipAt((s) => Object.assign(s, { fuel: 0 }));
  const mile = a.f.game.mile, hull = a.f.game.hull;
  a.press('Continue the flight');
  a.timers.fire();
  const said = readOn(a);
  check(said.includes('The tanks are dry!'), `the crisis is told (${said.slice(0, 80)})`);
  check(a.f.game.mile > mile && a.f.game.hull < hull, `adrift, spending gas (${a.f.game.mile - mile} km, lift ${a.f.game.hull})`);
  noProblems(a);

  const m = await shipAt((s) => Object.assign(s, { fuel: 0, stopIndex: stopIndex('pulham'), mile: J0.stops[stopIndex('pulham')].mile, atPort: true }));
  check(statusRows(m).Airship?.value === 'Tanks dry', 'moored, the box says tanks dry');
  m.say(m.words.leavePort);
  check(m.screen === 'travel' || m.screen === 'message', `the mast lets her go (${m.screen})`);
  if (m.screen === 'travel') m.f.stopTravel();
  const b = await shipAt((s) => Object.assign(s, { fuel: 0, stopIndex: stopIndex('pulham'), mile: J0.stops[stopIndex('pulham')].mile, atPort: true }));
  b.say(b.words.buy);
  b.topUp({ fuel: 2000 });
  b.press('Pay');
  check(b.f.game.fuel === 2000 && !statusRows(b).Airship, `petrol bought at Pulham (${b.f.game.fuel})`);
  noProblems(p);
  noProblems(m);
  noProblems(b);
});

await test('the last of the petrol powers its share of a watch', async () => {
  const p = await shipAt((s) => Object.assign(s, { fuel: 100 }));
  check(statusRows(p).Airship?.value === 'Last of the petrol', 'the box says so');
  const mile = p.f.game.mile;
  p.press('Continue the flight');
  p.timers.fire();
  const part = p.f.game.mile - mile;
  check(p.f.game.fuel === 0, 'it is all burnt');
  const q = await shipAt((s) => Object.assign(s, { fuel: 3000 }));
  const from = q.f.game.mile;
  q.press('Continue the flight');
  q.timers.fire();
  check(part > 0 && part < q.f.game.mile - from, `and goes less far than a full watch (${part} km, ${q.f.game.mile - from})`);
  readOn(p);
  noProblems(p);
  noProblems(q);
});

await test('going down: ballast, petrol, or the ground crew at a mast, in that order', async () => {
  const p = await shipAt((s) => Object.assign(s, { hull: 0.3 }));
  check(statusRows(p).Airship?.value === 'Going down' && statusRows(p).Airship.color === 'red', 'the box says going down');
  const mile = p.f.game.mile;
  p.press('Continue the flight');
  p.timers.fire();
  check(choiceKey(p) === 'sinking' && p.f.game.mile === mile, `asked before another watch is flown (${p.screen})`);
  check(p.labels().join('/') === 'Drop a bag of ballast (have 3)/Open the dump valves: 300 kg of petrol (have 5,000 kg)',
    `ballast first, then petrol (${p.labels().join('/')})`);
  check(wordsOn(p.look()).startsWith('She is going down.') && p.look().blocks.some((b) => b.markup?.startsWith('[red]She is going down.[/red]')), 'in red');
  p.press('Drop a bag of ballast');
  check(p.f.game.timber === 2 && Math.round(p.f.game.hull) > 0, `ballast over the side (${p.f.game.hull})`);
  noProblems(p);

  const d = await shipAt((s) => Object.assign(s, { hull: 0.3 }));
  d.press('Continue the flight');
  d.timers.fire();
  d.press('Open the dump valves');
  const said = readOn(d);
  check(d.f.game.fuel <= 4700 && said.includes('300 kg of petrol go over the side'), `petrol over the side (${d.f.game.fuel})`);
  noProblems(d);

  const m = await shipAt((s) => { overMast('oslo')(s); s.hull = 0.3; });
  m.press('Continue the flight');
  m.timers.fire();
  check(choiceKey(m) === 'sinking' && m.labels()[2] === 'Let the ground crew walk her in to the mast', `the mast's third answer (${m.labels().join('/')})`);
  check(wordsOn(m.look()).includes('below the mast at Oslo'), 'over the mast at Oslo');
  m.press('Let the ground crew walk her in');
  readOn(m);
  check(m.screen === 'portMenu' && m.f.game.atPort, `walked in to the mast (${m.screen})`);
  check(statusRows(m).Airship?.value === 'Going down', 'still with no lift');
  m.say(m.words.yard);
  m.press('Top up the gas');
  readOn(m);
  check(m.f.game.hull > 50 && !statusRows(m).Airship, `the gas topped up (${m.f.game.hull})`);
  noProblems(m);

  const n = await shipAt((s) => Object.assign(s, { hull: 0.3, timber: 0 }));
  n.press('Continue the flight');
  n.timers.fire();
  check(n.look().choices.map((c) => c.enabled).join() === 'false,true', 'with no ballast, only petrol');
  noProblems(n);
});

// MARK: - Leaving mid-trouble

await test('left on the question going down, the question and the plight come back', async () => {
  const storage = new MemoryStorage();
  const p = await shipAt((s) => Object.assign(s, { hull: 0.3 }), { storage });
  p.press('Continue the flight');
  p.timers.fire();
  check(choiceKey(p) === 'sinking', 'going down');
  const save = saveOf(storage);
  check(save && Array.isArray(save.pending) && JSON.stringify(save.pending[0]) === JSON.stringify(p.f.showing), 'saved with the question on screen');
  const q = await airPlayer({ engine: e2, storage, seeds: ['99'], random: lcg(99) });
  q.press('Continue the flight of the');
  check(screenWords(q.f) === screenWords(p.f), 'the question comes back as it was');
  q.press('Open the dump valves');
  p.press('Open the dump valves');
  check(screenWords(q.f) === screenWords(p.f), 'the same answer after coming back');
  noProblems(p);
  noProblems(q);
});

await test('left with the engines dead and the tanks dry, the plight comes back with the flight', async () => {
  const storage = new MemoryStorage();
  const p = await shipAt((s) => Object.assign(s, { sails: 0, fuel: 0 }), { storage });
  check(statusRows(p).Airship?.value === 'Engines dead, tanks dry', 'both');
  p.press('Continue the flight');
  p.timers.fire();
  readOn(p);
  if (p.screen === 'travel') p.press(1);
  const { mile, day } = p.f.game;
  p.press('Save and return to the title');
  const q = await airPlayer({ engine: e2, storage, seeds: ['98'], random: lcg(98) });
  q.press('Continue the flight of the');
  check(q.screen === 'seaMenu' && q.f.game.mile === mile && q.f.game.day === day, 'where she was');
  check(statusRows(q).Airship?.value === 'Engines dead, tanks dry', `and as she was (${statusRows(q).Airship?.value})`);
  check(storage.getItem('horn.save-rail') === null && storage.getItem('horn.save-horn1849') === null, 'in the flight\'s own save');
  noProblems(p);
  noProblems(q);
});

console.log(`airship: ${passed} checks passed, ${failures.length} failed`);
for (const f of failures) console.log(`FAILED ${f}`);
process.exit(failures.length ? 1 : 0);
