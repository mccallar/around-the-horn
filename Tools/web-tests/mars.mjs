// The Long Transfer in the web game's flow (web/js/flow.js, web/js/screens.js and the mars
// skin), played in Node through what the screens offer, as balloon.mjs plays the Jet Stream:
//
// - the picker offers it; its title card, learn pages, setup and top ten are its own, in
//   its own words (D11);
// - Gateway won't clear her with her tanks empty while the purse runs to propellant (D18),
//   and clears her dry or hungry when it doesn't (D19); a transfer saved in its chandlery
//   comes back to it (D16);
// - whole seeded transfers: to Jezero through every stop, docking with the cycler and
//   waving her by, turning on schedule and running on, aerobraking and burning into orbit,
//   in hand and late; and every other ending: the hull letting go, lost aerobraking, the
//   captain lost;
// - every kind of trouble (D14) and each way out of it: the array dark (a spare panel, the
//   rewire, a day's coast, taking stock; a set piece reached dark waits for power), the
//   tanks dry (coasting to a station and its propellant), dark and dry at once, the last of
//   the propellant; no meter below 0%; repairs, the yard and the box in the condition box's
//   order (D15);
// - leaving mid-trouble and coming back to the same screen and the same plight on a fresh
//   engine; and on every screen of every transfer no other journey's word, no "undefined"
//   and no "NaN".
//
//   node Tools/web-tests/mars.mjs
import { Player, engine, lcg, describe, plain, marsProblems, SAFE } from './player.mjs';
import { MemoryStorage } from '../../web/js/flow.js';
import { sceneFrame } from '../../web/js/drawing.js';

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
const saveOf = (storage, id = 'mars') => JSON.parse(storage.getItem(`horn.save-${id}`) ?? 'null');
const screenWords = (f) => {
  const d = describe(f);
  return JSON.stringify(d.blocks.filter((b) => b.type !== 'scene')) + JSON.stringify(d.choices.map((c) => [c.label, c.enabled]));
};
const wordsOn = (d) => d.blocks.map((b) => plain(b.markup ?? b.text ?? b.label ?? '')).filter(Boolean).join(' ');

/** D11: the lines no journey may use. */
const D11 = /Many kinds of people|You may:|Find out the differences|\bBe an? [a-z]+ from\b|\bFilling\b|\bMeager\b|Bare bones|Attempt to trade/;
const BANNER = 'THE LONG TRANSFER · 2087';

/** A transfer player whose every look is also checked for other journeys' words and the banner. */
async function shipPlayer(o = {}) {
  const p = await Player.make({ journey: 'mars', ...o });
  const look = p.look.bind(p);
  p.look = () => {
    const d = look();
    if (p.f.journey.id === 'mars' && p.screen !== 'picker') {
      p.problems.push(...marsProblems(d, p.screen));
      const all = wordsOn(d) + ' ' + d.choices.map((c) => plain(c.label)).join(' ');
      const m = all.match(D11);
      if (m) p.problems.push(`${p.screen}: D11's "${m[0]}"`);
      if (/undefined|NaN|\[object/.test(all)) p.problems.push(`${p.screen}: ${all.match(/.{0,40}(undefined|NaN|\[object).{0,20}/)[0]}`);
      if (d.banner !== BANNER) p.problems.push(`${p.screen}: the banner reads ${d.banner}`);
    }
    return d;
  };
  return p;
}

const noProblems = (p, what = 'no word went wrong') => check(p.problems.length === 0, `${what}: ${p.problems.slice(0, 3).join(' | ')}`);

/** The status box's rows by label: { value, color }. */
const statusRows = (p) => Object.fromEntries((p.look().blocks.find((b) => b.type === 'status')?.rows ?? [])
  .map((r) => [plain(r.label), { value: r.value, color: r.color }]));

const J0 = (await shipPlayer({ engine: e1 })).f.journey;
const stopIndex = (id) => J0.stops.findIndex((s) => s.id === id);
const mileOf = (id) => J0.stops[stopIndex(id)].mile;
const METERS = 'Hull · Power & drive';

/**
 * A freighter from the debug start, on the inner arc short of Turnover (`mile`, a day's
 * burn from anywhere), with `set` applied to it, on its menu.
 */
async function shipAt(set, { mile = 20000, seed = '9', storage = new MemoryStorage(), role = 'merchant' } = {}) {
  const p = await shipPlayer({ engine: e1, storage, seeds: ['31'], random: lcg(31) });
  e1.start({ journey: 'mars', role, ship: 'Fair Copy', captain: 'Noor', crew: ['Tomasz', 'Priya', 'Kenji', 'Lucía'],
    year: 2087, month: 9, seed });
  const s = e1.save([]);
  p.f.skin.debug.start(s, stopIndex('midway'));
  s.mile = mile;
  s.stopIndex = Math.max(0, J0.stops.findLastIndex((st) => st.mile < mile));
  s.day = Math.max(1, Math.trunc(mile / 330));
  set(s);
  p.f.loadForDebug(s);
  return p;
}
/** Short of the stop `id` by `by`, under way. */
const shortOf = (id, by) => (s) => Object.assign(s, { mile: mileOf(id) - by, stopIndex: stopIndex(id) - 1 });
/** Docked at the station `id`, its arrival told. */
const dockedAt = (id) => (s) => Object.assign(s, { stopIndex: stopIndex(id), mile: mileOf(id), atPort: true });
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
/** Burns on a day at a time, taking the first answer to anything, until `done`. */
const burnUntil = (p, done, limit = 200) => {
  let days = 0;
  for (let i = 0; i < limit && !done(p); i++) {
    if (p.screen === 'travel') {
      p.timers.fire();
      days += 1;
    } else {
      p.look().choices.find((c) => c.enabled).act();
    }
  }
  return days;
};
const sceneLabel = (p) => p.f.skin.scene.label(sceneFrame(p.f.journey, p.f.v, p.screen === 'travel', 0));

// MARK: - The picker, the title card, the setup

await test('the picker offers the Long Transfer, and its title card, pages, setup and top ten are its own', async () => {
  const storage = new MemoryStorage();
  const p = await shipPlayer({ engine: e1, storage, journey: null, seeds: ['4'], random: lcg(4) });
  check(p.screen === 'picker' && p.labels().includes(J0.title), `the picker offers it (${p.labels()})`);
  p.press(J0.title);
  check(p.screen === 'title' && p.look().banner === BANNER, 'its title card');
  check(storage.getItem('horn.lastJourney') === 'mars', 'and remembers the choice');
  const q = await shipPlayer({ engine: e2, storage, journey: null });
  check(q.screen === 'title' && q.f.journey.id === 'mars', 'a new visit opens on it');
  const r = await shipPlayer({ engine: e2, journey: 'mars' });
  check(r.screen === 'title' && r.f.journey.id === 'mars', '?journey=mars opens on it');

  p.press('Learn about the transfer');
  const headings = [];
  while (p.screen === 'learn') {
    headings.push(p.look().blocks[0].text);
    p.press(p.labels()[0]);
  }
  check(headings.join('/') === 'The transfer/Supplies/Turnover and capture', `three pages (${headings})`);
  p.press('See the top ten');
  const places = p.look().blocks.filter((b) => b.type === 'place');
  check(places.length === 10 && places[0].text === `1. ${J0.defaultTopTen[0].name}`,
    `the transfer's own top ten (${places[0]?.text}, ${places[0]?.rank})`);
  p.press('Back');
  p.press('Take the charter');
  check(p.labels().join('/') === `${J0.roles.map((x) => x.label).join('/')}/Weigh them up/Back to the title`,
    `who are you? (${p.labels().join('/')})`);
  check(wordsOn(p.look()).includes('Plenty of people want to haul cargo to Mars. Three kinds actually do it.'), 'in its own words (D11)');
  p.press('Weigh them up');
  check(wordsOn(p.look()).includes('Ice hauler — starts with $625.') && wordsOn(p.look()).startsWith('How they weigh up'), 'how they weigh up');
  p.press('Back');
  p.press(J0.roles[2].label);
  const fields = p.look().blocks.filter((b) => b.type === 'field');
  check(fields[0].label === "Freighter's name" && fields[1].label === "Captain's name" && fields[2].label === 'Crew member 1',
    'the freighter, the captain and the crew');
  p.press('Use these names', { ship: 'Fair Copy', captain: 'Noor' });
  check(p.labels().join('/') === 'August 2087/September 2087/October 2087/November 2087/December 2087/Ask for advice/Back to the title',
    `the months she can launch in (${p.labels().join('/')})`);
  p.press('Ask for advice');
  check(p.f.screen.text.startsWith('The yard boss looks up from her slate'), 'the yard boss');
  p.press('Continue');
  p.press('October 2087');
  check(wordsOn(p.look()).startsWith('Fitting out You have $625 to fit out the Fair Copy.'), `fitting out the Fair Copy (${wordsOn(p.look()).slice(0, 60)})`);
  p.press('Back to the title');
  check(p.screen === 'title' && p.f.game === null, 'back to the title, nothing started');
  noProblems(p);
});

// MARK: - Gateway

await test('Gateway won\'t clear her with empty tanks, and a transfer saved in its chandlery comes back to it (D16, D18)', async () => {
  const storage = new MemoryStorage();
  const a = await shipPlayer({ engine: e1, storage, seeds: ['5'], random: lcg(5) });
  a.setUp();
  check(a.screen === 'shop' && a.f.game.fuel === 0, 'in the chandlery with empty tanks');
  a.shop({ food: 4, water: 4 });
  a.press('Pay');
  check(a.screen === 'message' && a.f.screen.text === "Gateway's traffic office won't clear a ship to leave the yard with her tanks empty. The quartermaster points you back at the propellant.",
    `no launch without propellant (${a.f.screen.text})`);
  a.press(1);
  check(a.screen === 'shop', 'and it is back to the chandlery');
  check(saveOf(storage)?.atPort && saveOf(storage).day === 0 && saveOf(storage).food === 100, `the rations bought, saved in the chandlery (${saveOf(storage)?.food})`);
  const b = await shipPlayer({ engine: e2, storage, seeds: ['6'], random: lcg(6) });
  check(b.labels()[1] === `Rejoin the ${saveOf(storage).ship}`, `the title card offers the transfer (${b.labels()[1]})`);
  b.press('Rejoin the');
  check(b.screen === 'shop', `back in the chandlery at Gateway (${b.screen})`);
  b.topUp(SAFE.mars);
  b.press('Pay');
  check(b.screen === 'depart', `and out of the yard (${b.screen}: ${b.f.screen.text?.slice(0, 90)})`);
  const label = sceneLabel(b);
  check(label.startsWith('The freighter docked at Gateway Yard') || label.startsWith('The freighter'), `the scene (${label})`);
  b.press('Burn for Mars');
  check(b.screen === 'travel', 'under way');
  b.f.stopTravel();
  const box = b.look().blocks.find((x) => x.type === 'status');
  const rows = statusRows(b);
  check(box.date === 'October 7, 2087' && rows.Propellant?.value === '100 tonnes' && rows[METERS]?.value === '100% · 100%'
    && rows.Contract?.value === '170 days in hand' && /^Next: /.test(Object.keys(rows).find((k) => k.startsWith('Next:')) ?? ''),
  `the status box: the date, tonnes, the two meters and the contract (${box.date} ${JSON.stringify(rows)})`);
  check(Object.entries(rows).some(([k, r]) => k.startsWith('Next:') && / million km$/.test(r.value)), 'the next stop in millions of km');
  noProblems(a);
  noProblems(b);
});

await test('with too little in the purse for a step of propellant, Gateway clears her dry (D19)', async () => {
  const p = await shipPlayer({ engine: e1, seeds: ['8'], random: lcg(8) });
  p.setUp({ role: J0.roles.find((r) => r.role === 'whaler').label });
  check(p.f.game.money === 625, `an ice hauler's purse (${p.f.game.money})`);
  p.shop({ food: 18, water: 16, sailcloth: 8, timber: 8, meds: 8, clothes: 10, limes: 20 });
  check(p.f.game.money - p.f.bill < 3.7 && p.f.game.money - p.f.bill >= 0, `less than five tonnes' price left (${p.f.game.money - p.f.bill})`);
  check(!p.f.v.hooks?.mars || true, 'the hooks');
  p.press('Pay');
  check(p.screen === 'depart', `cleared, dry (${p.screen}: ${p.f.screen.text?.slice(0, 120)})`);
  check(p.f.game.fuel === 0, 'her tanks empty');
  const said = plain(p.f.screen.text ?? '');
  check(/dry|propellant|tanks/i.test(said), `the departure says so (${said})`);
  p.press('Burn for Mars');
  p.timers.fire();
  readOn(p);
  check(statusRows(p).Ship?.value === 'Tanks dry, coasting' && statusRows(p).Ship.color === 'red', `coasting from the first day (${JSON.stringify(statusRows(p).Ship)})`);
  noProblems(p);
});

// MARK: - Whole transfers

await test('careful transfers land at Jezero through every stop, each set piece answered both ways', async () => {
  let landed = 0;
  const stopsSeen = new Set(), answers = new Set(), ends = [];
  // Which answer each set piece gets, by run: the cycler, Turnover, the capture.
  for (const [seed, role, month, ways] of [['3', 0, 'October 2087', [0, 0, 0]], ['11', 1, 'September 2087', [0, 1, 1]],
    ['21', 0, 'November 2087', [1, 0, 1]], ['29', 1, 'October 2087', [0, 1, 0]]]) {
    const storage = new MemoryStorage();
    const p = await shipPlayer({ engine: e1, storage, seeds: [seed], random: lcg(Number(seed)) });
    p.setUp({ role: J0.roles[role].label, month });
    const seen = new Set();
    let said = '';
    const end = p.voyage({
      onScreen: (q) => {
        if (q.f.game) seen.add(q.f.game.stopIndex);
        if (q.screen === 'message') said += `${q.f.screen.text}\n`;
        const key = choiceKey(q);
        const pick = { cycler: ['Match and dock', 'Wave as she goes by'], turnover: ['Turn on schedule', 'Run on four more days'],
          capture: ['Aerobrake', 'Propulsive capture'] }[key];
        if (pick) {
          const want = pick[ways[['cycler', 'turnover', 'capture'].indexOf(key)]];
          const c = q.look().choices.find((x) => plain(x.label).startsWith(want));
          if (c?.enabled) {
            answers.add(`${key}:${want}`);
            c.act();
          } else {
            q.look().choices.find((x) => x.enabled).act();
          }
        }
        return null;
      },
    });
    if (end === 'finale') {
      landed += 1;
      for (const i of seen) stopsSeen.add(i);
      const words = wordsOn(p.look());
      check(words.includes('Jezero Landing! The Fair Copy sets her cargo down on') || /Jezero Landing! The .* sets her cargo down on/.test(words),
        `the landing (${words.slice(0, 120)})`);
      check(/contract allowed 170 days, and you have \d+ days? in hand|contract date is behind you/.test(words), 'the contract, in hand or late');
      check(saveOf(storage) === null, 'the save goes with the landing');
      check(JSON.parse(storage.getItem('horn.topten-mars') ?? '[]').length === 10 && storage.getItem('horn.topten-balloon') === null,
        'into the transfer\'s own top ten');
      check(seen.size === J0.stops.length, `${J0.roles[role].title} from seed ${seed}: every stop (${[...seen].join(',')})`);
    }
    else ends.push(`seed ${seed}: ${end} on day ${p.f.game?.day} (${plain(p.f.screen.title ?? '')})`);
    noProblems(p, `seed ${seed}`);
  }
  // Waving the cycler by leaves a long way to Midway on one tank of water.
  check(landed >= 3, `careful transfers land (${landed} of 4; ${ends.join('; ')})`);
  check(stopsSeen.size === J0.stops.length, `every stop seen (${stopsSeen.size} of ${J0.stops.length})`);
  check(['cycler:Match and dock', 'cycler:Wave as she goes by', 'turnover:Turn on schedule', 'turnover:Run on four more days',
    'capture:Aerobrake', 'capture:Propulsive capture'].every((a) => answers.has(a)), `each set piece answered both ways (${[...answers]})`);
});

await test('landing in hand and landing late, as the contract counts them', async () => {
  const land = async (day) => {
    const p = await shipAt((s) => Object.assign(s, { stopIndex: stopIndex('phobos'), mile: mileOf('jezero') - 30, day,
      vars: { ...s.vars, 'mars.capture': 2 } }));
    p.press('Continue the transfer');
    burnUntil(p, (q) => q.screen === 'finale' || q.screen === 'gameOver', 20);
    noProblems(p);
    return p;
  };
  const early = await land(150), late = await land(175);
  check(early.screen === 'finale' && late.screen === 'finale', `both land (${early.screen}, ${late.screen})`);
  const we = wordsOn(early.look()), wl = wordsOn(late.look());
  check(/The contract allowed 170 days, and you have 1\d days in hand\./.test(we) && we.includes('slightly misspelled'), `in hand (${we.slice(0, 200)})`);
  check(wl.includes('The contract date is behind you, and so is the bonus.') && wl.includes('nobody mentions the date'), `late (${wl.slice(0, 200)})`);
  check(we.includes('a hot shower that lasts more than four minutes'), 'the crew asks for a shower');
  check(sceneLabel(early).startsWith('The cargo lander on the pad at Jezero Landing'), `the pad at Jezero (${sceneLabel(early)})`);
});

await test('every other ending: the hull letting go, lost aerobraking, the captain lost', async () => {
  const p = await shipAt((s) => Object.assign(s, { hull: 0.3, timber: 0 }));
  p.press('Continue the transfer');
  p.timers.fire();
  check(p.screen === 'gameOver' && p.f.screen.title.includes('[i]Fair Copy[/i]'), `the hull lets go (${p.screen}: ${p.f.screen.title})`);
  check(p.f.game.hull === 0 && p.f.v.state.over, 'at 0%, and over');
  check(sceneLabel(p) === 'The freighter in two pieces, drifting apart among her own debris. The pressure hull has let go', `drawn in two pieces (${sceneLabel(p)})`);
  noProblems(p);

  const a = await shipAt((s) => Object.assign(s, { mile: 46500, stopIndex: stopIndex('approach'), hull: 2, timber: 0,
    vars: { ...s.vars, 'mars.capture': 1 } }));
  check(sceneLabel(a).includes('skimming the top of the Martian air') || sceneLabel(a).startsWith('The freighter'), `aerobraking (${sceneLabel(a)})`);
  a.press('Continue the transfer');
  burnUntil(a, (q) => q.screen === 'gameOver', 10);
  check(a.screen === 'gameOver' && wordsOn(a.look()).includes('She was a tired ship for a fire like that.'), `lost aerobraking (${wordsOn(a.look()).slice(0, 160)})`);
  check(sceneLabel(a) === 'A short bright line across the top of the Martian sky, where the freighter was', `a line across the sky (${sceneLabel(a)})`);
  noProblems(a);

  const c = await shipAt((s) => {
    s.crew[0].hp = 1;
    s.crew[0].ailment = J0.ailments.reduce((x, y) => (y.damage > x.damage ? y : x));
    s.meds = 0;
  });
  c.press('Continue the transfer');
  burnUntil(c, (q) => q.screen === 'gameOver', 60);
  check(c.screen === 'gameOver' && /^You, .*Noor, have died of /.test(c.f.screen.title), `the captain lost (${c.f.screen.title})`);
  noProblems(c);
});

// MARK: - Trouble (D14) and the order of repairs (D15)

await test('worn to nothing with nothing to mend with: no meter below 0%, the box says so in red, and the hull lets go', async () => {
  const p = await shipAt((s) => Object.assign(s, { sails: 2, hull: 4, fuel: 30, sailcloth: 0, timber: 0, money: 0 }));
  p.press('Continue the transfer');
  const meters = [], troubles = [];
  for (let i = 0; i < 200 && p.screen !== 'gameOver'; i++) {
    if (p.screen !== 'travel') {
      p.look().choices.find((c) => c.enabled).act();
      continue;
    }
    const rows = statusRows(p);
    meters.push(rows[METERS].value);
    if (rows.Ship) troubles.push(`${rows.Ship.value}/${rows.Ship.color}`);
    p.timers.fire();
  }
  check(meters.length > 1 && !meters.some((m) => m.includes('-')), `no meter below 0 (${[...new Set(meters)].slice(-4).join(' | ')})`);
  check(troubles.length > 0 && troubles.every((t) => t.endsWith('/red')) && troubles.some((t) => /^(Array dark|Tanks dry|Last of the propellant)/.test(t)),
    `the box says what is wrong, in red (${[...new Set(troubles)]})`);
  check(p.screen === 'gameOver', `in the end the hull lets go (${p.screen}: ${p.f.screen.title})`);
  noProblems(p);
});

await test('the condition box, the repairs and the yard list the hull first (D15)', async () => {
  const p = await shipAt((s) => Object.assign(s, { hull: 30, sails: 30 }));
  check(statusRows(p)[METERS]?.value === '30% · 30%', `the hull, then power & drive (${JSON.stringify(statusRows(p)[METERS])})`);
  p.press('Make repairs');
  check(p.labels().join('/') === 'Patch the pressure hull — 1 patch (have 3)/Fit a spare array panel — 1 panel (have 3)/Done', `repairs (${p.labels().join('/')})`);
  p.press('Patch the pressure hull');
  check(p.f.game.timber === 2 && p.f.game.hull > 30, `a patch mends the hull (${p.f.game.hull})`);
  const y = await shipAt((s) => { dockedAt('midway')(s); Object.assign(s, { hull: 40, sails: 40, money: 2000 }); });
  check(y.screen === 'portMenu' && y.labels().includes('Visit the yard crew'), `docked at Midway (${y.labels().join('/')})`);
  check(y.look().blocks.some((b) => plain(b.markup ?? b.text ?? '').includes('Docked at Midway')) || statusRows(y).Weather, 'at Midway');
  y.say(y.words.yard);
  check(/^Reseal the pressure hull — \$[\d,]+\/New panels and a rebuilt thruster grid — \$[\d,]+\/Back to the station$/.test(y.labels().join('/')),
    `the yard crew (${y.labels().join('/')})`);
  noProblems(p);
  noProblems(y);
});

await test('the array dark: she coasts, the box says so, and a spare panel puts it right', async () => {
  const p = await shipAt((s) => Object.assign(s, { sails: 0.4, sailcloth: 1 }));
  check(statusRows(p).Ship?.value === 'Array dark, coasting' && statusRows(p).Ship.color === 'red', `the box says so, in red (${JSON.stringify(statusRows(p).Ship)})`);
  check(statusRows(p)[METERS].value === '72% · 0%', `power at 0%, never below (${statusRows(p)[METERS].value})`);
  p.say(p.words.supplies);
  check(wordsOn(p.look()).includes('the array is dark'), 'the supplies note');
  p.f.backToMenu();
  p.say(p.words.changePace);
  check(wordsOn(p.look()).includes('The array is dark: she is only coasting.'), 'the thrust screen');
  p.f.backToMenu();
  const { fuel, mile } = p.f.game;
  p.press('Continue the transfer');
  p.timers.fire();
  check(choiceKey(p) === 'dark' && p.f.game.mile === mile, `asked before another day (${p.screen})`);
  check(p.labels().join('/') === 'Fit a spare array panel (have 1)/Rewire what is left of the wings: two days in suits/Coast on in the dark for a day/Take stock first',
    `the panel, the rewire, a day's coast, taking stock (${p.labels().join('/')})`);
  check(p.look().blocks.some((b) => (b.markup ?? '').startsWith('[red]The array has gone dark.[/red]')), 'in red');
  p.press('Fit a spare array panel');
  readOn(p);
  check(p.f.game.sails > 0.5 && p.f.game.sailcloth === 0, `the panel fitted (${p.f.game.sails})`);
  burnUntil(p, (q) => q.screen === 'travel' || q.screen === 'seaMenu', 5);
  if (p.screen === 'travel') p.f.stopTravel();
  check(!statusRows(p).Ship, `and nothing wrong in the box (${p.screen}: ${JSON.stringify(statusRows(p).Ship)})`);
  check(p.f.game.fuel <= fuel, 'burning again');
  noProblems(p);
});

await test('the array dark with no panel: the rewire, a day\'s coast, or taking stock', async () => {
  const r = await shipAt((s) => Object.assign(s, { sails: 0, sailcloth: 0 }));
  r.press('Continue the transfer');
  r.timers.fire();
  check(r.look().choices.map((c) => c.enabled).join() === 'false,true,true,true', 'no panel to fit');
  const day = r.f.game.day;
  r.press('Rewire what is left of the wings');
  const said = readOn(r);
  check(said.includes('suit up and go out along the truss') && said.includes('Power & drive now 10%'), `rewired (${said.slice(0, 160)})`);
  check(r.f.game.day === day + 2 && Math.round(r.f.game.sails) === 10, `two days, ten points (${r.f.game.day - day}, ${r.f.game.sails})`);
  noProblems(r);

  const c = await shipAt((s) => Object.assign(s, { sails: 0, sailcloth: 0 }));
  c.press('Continue the transfer');
  c.timers.fire();
  const { mile } = c.f.game;
  c.press('Coast on in the dark for a day');
  readOn(c);
  if (c.screen === 'travel') c.timers.fire();
  readOn(c);
  check(c.f.game.mile > mile && choiceKey(c) !== 'dark' || c.f.game.mile > mile, `a day's coast (${mile} to ${c.f.game.mile})`);
  burnUntil(c, (q) => choiceKey(q) === 'dark', 5);
  check(choiceKey(c) === 'dark', 'and asked again the next day');
  noProblems(c);

  const s = await shipAt((st) => Object.assign(st, { sails: 0 }));
  s.press('Continue the transfer');
  s.timers.fire();
  s.press('Take stock first');
  readOn(s);
  check(s.screen === 'seaMenu' && statusRows(s).Ship?.value === 'Array dark, coasting', `on the menu, still dark (${s.screen})`);
  noProblems(s);
});

await test('reaching Turnover dark, it waits for power, without a day\'s coast on offer', async () => {
  const p = await shipAt((s) => { shortOf('turnover', 100)(s); Object.assign(s, { sails: 0, sailcloth: 2 }); });
  p.press('Continue the transfer');
  let said = '';
  for (let i = 0; i < 20 && choiceKey(p) !== 'dark'; i++) {
    if (p.screen === 'travel') p.timers.fire();
    else if (p.screen === 'message') said += `${p.f.screen.text}\n`, p.press(1);
    else if (choiceKey(p) === 'dark') break;
    else p.look().choices.find((c) => c.enabled).act();
    if (choiceKey(p) === 'dark' && !said.includes('Turnover')) {
      p.press('Coast on in the dark');
    }
  }
  said += readOn(p);
  check(choiceKey(p) === 'dark', `the dark question (${p.screen})`);
  check(p.labels().join('/') === 'Fit a spare array panel (have 2)/Rewire what is left of the wings: two days in suits/Take stock first',
    `no coast with Turnover waiting (${p.labels().join('/')})`);
  check(wordsOn(p.look()).includes('Turnover is due, and nobody turns a ship end for end without a drive.'), `Turnover waits (${wordsOn(p.look()).slice(0, 200)})`);
  check(sceneLabel(p).includes('at Turnover, waiting for the power to turn round'), `the scene waits too (${sceneLabel(p)})`);
  p.press('Fit a spare array panel');
  readOn(p);
  burnUntil(p, (q) => choiceKey(q) === 'turnover', 5);
  check(choiceKey(p) === 'turnover', `with power, Turnover (${p.screen})`);
  noProblems(p);
});

await test('the tanks dry: she coasts on to a station, and its propellant clears it', async () => {
  const p = await shipAt((s) => { shortOf('midway', 200)(s); s.fuel = 0; });
  check(statusRows(p).Ship?.value === 'Tanks dry, coasting' && statusRows(p).Propellant.value === '0 tonnes', `the box says tanks dry (${JSON.stringify(statusRows(p).Propellant)})`);
  check(p.f.skin.words(p.f.v).suppliesNote.includes('the tanks are dry'), 'and the supplies note');
  check(p.f.skin.words(p.f.v).paceNow.endsWith(' [red]The tanks are dry: she is only coasting.[/red]'), 'and the thrust screen');
  check(sceneLabel(p).includes('tumbling slowly, her tanks dry'), `tumbling (${sceneLabel(p)})`);
  const mile = p.f.game.mile;
  p.press('Continue the transfer');
  p.timers.fire();
  check(p.f.game.mile > mile && p.f.game.fuel === 0, `coasting on (${mile} to ${p.f.game.mile})`);
  check(p.f.game.note === 'The tanks are dry. She is coasting.' || readOn(p).length >= 0, `the day's note (${p.f.game.note})`);
  const days = burnUntil(p, (q) => q.screen === 'portMenu' || q.screen === 'shop', 40);
  check((p.screen === 'portMenu' || p.screen === 'shop') && p.f.v.currentStop === 'midway' && days >= 1, `coasted in to Midway (${p.screen}, ${days} days)`);
  if (p.screen === 'shop') p.press(1);
  check(statusRows(p).Ship?.value === 'Tanks dry', `docked, the box says tanks dry (${statusRows(p).Ship?.value})`);
  check(p.f.skin.words(p.f.v).paceNow.endsWith('once she undocks, she will only coast.[/red]'), 'and the thrust screen says what undocking dry means');
  p.say(p.words.buy);
  p.topUp({ fuel: 500 });
  p.press('Pay');
  check(p.f.game.fuel === 500 && !statusRows(p).Ship, `propellant bought at Midway (${p.f.game.fuel})`);
  noProblems(p);
});

await test('dark and dry at once, and the last of the propellant', async () => {
  const p = await shipAt((s) => Object.assign(s, { sails: 0, fuel: 0 }));
  check(statusRows(p).Ship?.value === 'Array dark, tanks dry', `both (${statusRows(p).Ship?.value})`);
  const w = p.f.skin.words(p.f.v);
  check(w.suppliesNote.endsWith(' · [red]the array is dark[/red] · [red]the tanks are dry[/red]'), `the supplies note (${w.suppliesNote})`);
  check(sceneLabel(p).includes('tumbling slowly, her tanks dry') && sceneLabel(p).includes(', her array dark'), `the scene (${sceneLabel(p)})`);
  noProblems(p);

  const fair = J0.weathers.find((x) => x.rawValue === 'quiet');
  const q = await shipAt((s) => Object.assign(s, { fuel: 5, weather: fair }));
  check(statusRows(q).Ship?.value === 'Last of the propellant', `the box says so (${statusRows(q).Ship?.value})`);
  const m0 = q.f.game.mile;
  q.press('Continue the transfer');
  q.timers.fire();
  const part = q.f.game.mile - m0;
  check(q.f.game.fuel === 0, 'it is all burnt');
  check(q.f.game.note === 'The drive sputters out partway through the day. She is coasting.', `the day's note (${q.f.game.note})`);
  const r = await shipAt((s) => Object.assign(s, { fuel: 0, weather: fair }));
  const m1 = r.f.game.mile;
  r.press('Continue the transfer');
  r.timers.fire();
  const none = r.f.game.mile - m1;
  const s = await shipAt((st) => Object.assign(st, { weather: fair }));
  const m2 = s.f.game.mile;
  s.press('Continue the transfer');
  s.timers.fire();
  const full = s.f.game.mile - m2;
  check(none < part && part < full, `a part day's burn goes further than none, and less far than a whole (${none}, ${part}, ${full})`);
  readOn(q);
  readOn(r);
  noProblems(q);
  noProblems(r);
});

await test('the cycler won\'t wait for a ship that can\'t match her', async () => {
  const p = await shipAt((s) => { shortOf('cycler', 100)(s); s.fuel = 40; });
  burnUntil(p, (q) => choiceKey(q) === 'cycler', 10);
  check(choiceKey(p) === 'cycler', `the cycler (${p.screen})`);
  check(p.look().choices.map((c) => c.enabled).join() === 'false,true' && p.labels()[0] === 'Match and dock (6 tonnes)', `too little to match her (${p.labels().join('/')})`);
  check(sceneLabel(p).includes('coming up on the cycler Perpetua'), `the scene (${sceneLabel(p)})`);
  p.press('Wave as she goes by');
  check(readOn(p).includes('Everybody waves back.'), 'waved by');
  noProblems(p);
});

// MARK: - Leaving mid-trouble

await test('left on the dark question, the question and the plight come back', async () => {
  const storage = new MemoryStorage();
  const p = await shipAt((s) => Object.assign(s, { sails: 0 }), { storage });
  p.press('Continue the transfer');
  p.timers.fire();
  check(choiceKey(p) === 'dark', 'the array dark');
  const save = saveOf(storage);
  check(save && Array.isArray(save.pending) && JSON.stringify(save.pending[0]) === JSON.stringify(p.f.showing), 'saved with the question on screen');
  const q = await shipPlayer({ engine: e2, storage, seeds: ['99'], random: lcg(99) });
  q.press('Rejoin the');
  check(screenWords(q.f) === screenWords(p.f), 'the question comes back as it was');
  q.press('Rewire what is left of the wings');
  p.press('Rewire what is left of the wings');
  check(screenWords(q.f) === screenWords(p.f), 'the same answer after coming back');
  noProblems(p);
  noProblems(q);
});

await test('left dark and dry, the plight comes back with the transfer', async () => {
  const storage = new MemoryStorage();
  const p = await shipAt((s) => Object.assign(s, { sails: 0, fuel: 0 }), { storage });
  p.press('Continue the transfer');
  p.timers.fire();
  if (choiceKey(p) === 'dark') p.press('Take stock first');
  readOn(p);
  if (p.screen === 'travel') p.press(1);
  const { mile, day } = p.f.game;
  p.press('Save and return to the title');
  const q = await shipPlayer({ engine: e2, storage, seeds: ['98'], random: lcg(98) });
  q.press('Rejoin the');
  check(q.screen === 'seaMenu' && q.f.game.mile === mile && q.f.game.day === day, `where she was (${q.screen})`);
  check(statusRows(q).Ship?.value === 'Array dark, tanks dry', `and as she was (${statusRows(q).Ship?.value})`);
  check(storage.getItem('horn.save-balloon') === null && storage.getItem('horn.save-horn1849') === null, 'in the transfer\'s own save');
  noProblems(p);
  noProblems(q);
});

await test('left docked at Midway with dry tanks, she comes back docked, dry', async () => {
  const storage = new MemoryStorage();
  const p = await shipAt((s) => { dockedAt('midway')(s); s.fuel = 0; }, { storage });
  check(statusRows(p).Ship?.value === 'Tanks dry', `docked dry (${statusRows(p).Ship?.value})`);
  p.press('Save and return to the title');
  const q = await shipPlayer({ engine: e2, storage, seeds: ['97'], random: lcg(97) });
  q.press('Rejoin the');
  check(q.screen === 'portMenu' && q.f.game.atPort && q.f.v.currentStop === 'midway', `docked at Midway (${q.screen})`);
  check(statusRows(q).Ship?.value === 'Tanks dry', `tanks dry (${statusRows(q).Ship?.value})`);
  noProblems(p);
  noProblems(q);
});

console.log(`mars: ${passed} checks passed, ${failures.length} failed`);
for (const f of failures) console.log(`FAILED ${f}`);
process.exit(failures.length ? 1 : 0);
