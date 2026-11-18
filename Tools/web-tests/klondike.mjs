// To the Klondike in the web game's flow (web/js/flow.js, web/js/screens.js and the klondike
// skin), played in Node through what the screens offer, as mars.mjs plays the Long Transfer:
//
// - the picker offers it; its title card, learn pages, setup and top ten are its own, in
//   its own words (D11);
// - Seattle: less grub than the police will want is a warning the player may heed or wave
//   off, none at all is the outfitter's refusal while the purse runs to a step of it, and a
//   purse that doesn't is a hungry departure, warned (D21); a trek saved in the outfitter's
//   comes back to it (D16);
// - whole seeded treks over both passes, through every stop, to Dawson, each set piece
//   answered both ways, the stops named for the pass taken; and every other ending: the
//   outfit ruined, the boat broken up, turned back at the summit, the leader lost;
// - Lake Bennett's hold: no floating to Dawson on a sled, the boat question from the yard's
//   row, and the ice;
// - every kind of trouble (D14) and each way out of it: sleds or oars given out (a coil, a
//   coil bought off the next party, making do, taking stock), no firewood, both at once; no
//   meter below 0%; the condition box, the repairs and the yard in its order (D15);
// - leaving mid-trouble and mid-hold and coming back to the same screen on a fresh engine;
//   and on every screen of every trek no other journey's word, no "undefined" and no "NaN".
//
//   node Tools/web-tests/klondike.mjs
import { Player, engine, lcg, describe, plain, klondikeProblems, SAFE } from './player.mjs';
import { MemoryStorage } from '../../web/js/flow.js';
import { sceneFrame } from '../../web/js/drawing.js';
import * as kSkin from '../../web/js/journeys/klondike-skin.js';

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
const saveOf = (storage, id = 'klondike') => JSON.parse(storage.getItem(`horn.save-${id}`) ?? 'null');
const screenWords = (f) => {
  const d = describe(f);
  return JSON.stringify(d.blocks.filter((b) => b.type !== 'scene')) + JSON.stringify(d.choices.map((c) => [c.label, c.enabled]));
};
const wordsOn = (d) => d.blocks.map((b) => plain(b.markup ?? b.text ?? b.label ?? '')).filter(Boolean).join(' ');

/** D11: the lines no journey may use. */
const D11 = /Many kinds of people|You may:|Find out the differences|\bBe an? [a-z]+ from\b|\bFilling\b|\bMeager\b|Bare bones|Attempt to trade/;
const BANNER = 'TO THE KLONDIKE · 1898';

/** A trek player whose every look is also checked for other journeys' words and the banner. */
async function trekPlayer(o = {}) {
  const p = await Player.make({ journey: 'klondike', ...o });
  const look = p.look.bind(p);
  p.look = () => {
    const d = look();
    if (p.f.journey.id === 'klondike' && p.screen !== 'picker') {
      p.problems.push(...klondikeProblems(d, p.screen));
      const all = wordsOn(d) + ' ' + d.choices.map((c) => plain(c.label)).join(' ');
      const m = all.match(D11);
      if (m) p.problems.push(`${p.screen}: D11's "${m[0]}"`);
      if (/undefined|NaN|\[object|-0%/.test(all)) p.problems.push(`${p.screen}: ${all.match(/.{0,40}(undefined|NaN|\[object|-0%).{0,20}/)[0]}`);
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

const J0 = (await trekPlayer({ engine: e1 })).f.journey;
const stopIndex = (id) => J0.stops.findIndex((s) => s.id === id);
const mileOf = (id) => J0.stops[stopIndex(id)].mile;
const FOOT = 'Outfit · Sleds', BOAT = 'Boat · Oars & sail';

/**
 * A party from the skin's debug start, short of the stop `stop`, with `set` applied to it,
 * on its menu (or in town, if `set` puts it there).
 */
async function trekAt(set = () => {}, { stop = 'lakes', seed = '9', storage = new MemoryStorage(), role = 'merchant', engine: e = e1 } = {}) {
  const p = await trekPlayer({ engine: e, storage, seeds: ['31'], random: lcg(31) });
  e.start({ journey: 'klondike', role, ship: 'Puget Belle', captain: 'Gus', crew: ['Martha', 'Lars', 'Ida', 'Homer'],
    year: 1898, month: 2, seed });
  const s = e.save([]);
  p.f.skin.debug.start(s, stopIndex(stop), 2);
  set(s);
  p.f.loadForDebug(s);
  return p;
}
/** In the town `id`, its arrival told, as the skin's gallery puts a party there. */
const inTown = (id, white = false) => (s) => kSkin.at(J0, s, id, true, white);

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
/** Goes on a day at a time, taking the first answer to anything, until `done`. */
const goUntil = (p, done, limit = 200) => {
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
/** The shop's way out: "Pay" with something in the cart, "Leave the shop" with nothing. */
const leaveShop = (p) => p.press(p.labels().find((l) => l === 'Pay' || l === 'Leave the shop'));
const sceneLabel = (p) => p.f.skin.scene.label(sceneFrame(p.f.journey, p.f.v, p.screen === 'travel', 0));

// MARK: - The picker, the title card, the setup

await test('the picker offers the Klondike, and its title card, pages, setup and top ten are its own', async () => {
  const storage = new MemoryStorage();
  const p = await trekPlayer({ engine: e1, storage, journey: null, seeds: ['4'], random: lcg(4) });
  check(p.screen === 'picker' && p.labels().includes(J0.title), `the picker offers it (${p.labels()})`);
  p.press(J0.title);
  check(p.screen === 'title' && p.look().banner === BANNER, 'its title card');
  check(storage.getItem('horn.lastJourney') === 'klondike', 'and remembers the choice');
  const q = await trekPlayer({ engine: e2, storage, journey: null });
  check(q.screen === 'title' && q.f.journey.id === 'klondike', 'a new visit opens on it');

  p.press('Learn about the trail');
  const headings = [];
  while (p.screen === 'learn') {
    headings.push(p.look().blocks[0].text);
    p.press(p.labels()[0]);
  }
  check(headings.join('/') === 'The rush/The outfit/Pass, lakes, river', `three pages (${headings})`);
  p.press('See the top ten');
  const places = p.look().blocks.filter((b) => b.type === 'place');
  check(places.length === 10 && places[0].text === `1. ${J0.defaultTopTen[0].name}`, `the trail's own top ten (${places[0]?.text})`);
  p.press('Back');
  p.press('Head for the Klondike');
  check(p.labels().join('/') === `${J0.roles.map((x) => x.label).join('/')}/What does each one bring north?/Back to the title`,
    `who are you? (${p.labels().join('/')})`);
  check(wordsOn(p.look()).includes('In 1898 the fever took clerks and cooks, preachers and prospectors.'), 'in its own words (D11)');
  p.press('What does each one bring north?');
  check(wordsOn(p.look()).startsWith('What each one brings north') && wordsOn(p.look()).includes('Miner — starts with $720.'), 'what each one brings');
  p.press('Back');
  p.press(J0.roles[0].label);
  const fields = p.look().blocks.filter((b) => b.type === 'field');
  check(fields[0].label === "Boat's name" && fields[1].label === 'Your name' && fields[2].label === 'Partner 1',
    `the boat, you and your partners (${fields.map((f) => f.label)})`);
  p.press('Use these names', { ship: 'Puget Belle', captain: 'Gus' });
  check(p.labels().join('/') === 'January 1898/February 1898/March 1898/April 1898/May 1898/Ask for advice/Back to the title',
    `the months a party can leave in (${p.labels().join('/')})`);
  p.press('Ask for advice');
  check(p.f.screen.text.startsWith('An old sourdough taps his pipe on the stove'), 'the old sourdough');
  p.press('Continue');
  p.press('March 1898');
  check(wordsOn(p.look()).startsWith('Outfitting You have $1,700 to outfit your party.'), `outfitting (${wordsOn(p.look()).slice(0, 60)})`);
  p.press('Back to the title');
  check(p.screen === 'title' && p.f.game === null, 'back to the title, nothing started');
  noProblems(p);
});

// MARK: - Seattle

await test('Seattle: short of grub is a warning heeded or waved off, none is the outfitter\'s refusal, and the shop comes back (D16)', async () => {
  const storage = new MemoryStorage();
  const a = await trekPlayer({ engine: e1, storage, seeds: ['5'], random: lcg(5) });
  a.setUp();
  check(a.screen === 'shop' && a.f.game.food === 0 && a.f.game.money === 1700, 'in the outfitter\'s with nothing');
  leaveShop(a);
  check(a.screen === 'message' && a.f.screen.text === "You can't go north with no provisions! The outfitter laughs and points you back inside.",
    `no grub, and the purse runs to some: the outfitter's refusal (${a.screen}: ${a.f.screen.text})`);
  a.press(1);
  check(a.screen === 'shop', 'back in the shop');
  a.shop({ food: 16 });
  a.press('Pay');
  check(a.screen === 'ask' && a.f.screen.text === 'You have [amber]4,000 lbs[/amber] of provisions. The police at the summit will want [amber]5,475[/amber] — a year\'s worth for every one of you.',
    `the warning (${a.screen}: ${a.f.screen.text})`);
  check(a.labels().join('/') === 'Back to the shop/Leave anyway', `heed it or wave it off (${a.labels().join('/')})`);
  a.press('Back to the shop');
  check(a.screen === 'shop', 'heeded: back to the shop');
  check(saveOf(storage)?.atPort && saveOf(storage).day === 0 && saveOf(storage).food === 4000, `the grub bought, saved in the shop (${saveOf(storage)?.food})`);

  const b = await trekPlayer({ engine: e2, storage, seeds: ['6'], random: lcg(6) });
  check(b.labels()[1] === `Continue the journey of the ${saveOf(storage).ship}`, `the title card offers the trek (${b.labels()[1]})`);
  b.press('Continue the journey of the');
  check(b.screen === 'shop', `back in the outfitter's at Seattle (${b.screen})`);
  leaveShop(b);
  check(b.screen === 'ask', 'still short: warned again');
  b.press('Leave anyway');
  check(b.screen === 'depart' && !b.f.screen.text.includes("There isn't a pound of grub"), `waved off: away north (${b.screen})`);
  check(sceneLabel(b) === 'A crowded steamer lying to in fair weather' || sceneLabel(b).startsWith('The steamer tied up at Seattle'),
    `the steamer at Seattle (${sceneLabel(b)})`);
  b.press('Steam north');
  check(b.screen === 'travel', 'under way');
  b.f.stopTravel();
  const box = b.look().blocks.find((x) => x.type === 'status');
  const rows = statusRows(b);
  check(box.date === 'March 1, 1898' && rows[FOOT]?.value === '100% · 100%' && rows.Provisions?.value === '4,000 lbs',
    `the status box: the date, the outfit and sleds, the grub (${box.date} ${JSON.stringify(rows)})`);
  check(Object.entries(rows).some(([k, r]) => k === 'Next: Juneau' && /^[\d,]+\.\d mi$/.test(r.value)), `the next stop in miles and tenths (${Object.keys(rows)})`);
  check(!rows.Party, 'nothing wrong with the party');
  noProblems(a);
  noProblems(b);
});

await test('a purse too thin for a step of grub, and none aboard: the party leaves hungry, warned, and the police turn it back (D21)', async () => {
  const p = await trekPlayer({ engine: e1, seeds: ['7'], random: lcg(7) });
  p.setUp({ role: J0.roles[2].label });
  check(p.f.game.money === 720, `a miner's purse (${p.f.game.money})`);
  p.shop({ limes: 40, meds: 12, clothes: 12, sailcloth: 20, timber: 10, water: 5 });
  check(p.f.game.money - p.f.bill < 25 && p.f.game.money - p.f.bill >= 0, `less than a step of grub's price left (${p.f.game.money - p.f.bill})`);
  p.press('Pay');
  check(p.f.v.hooks.departsUnfed === true && p.f.game.food === 0, 'the engine lets the party go hungry');
  check(p.screen === 'ask' && p.f.screen.text.includes('You have [amber]0 lbs[/amber] of provisions.'), `warned (${p.screen}: ${p.f.screen.text})`);
  p.press('Back to the shop');
  leaveShop(p);
  p.press('Leave anyway');
  check(p.screen === 'depart' && p.f.screen.text.endsWith("There isn't a pound of grub in your outfit, and too little in your purse to buy any, so you will go hungry until somebody sells you some. The police at the summit will turn back a party without its year's grub."),
    `away north, hungry (${p.screen}: ${p.f.screen.text?.slice(-120)})`);
  p.press('Steam north');
  goUntil(p, (q) => q.screen === 'gameOver' || q.screen === 'finale', 400);
  check(p.screen === 'gameOver', `and it ends, never a loop (${p.screen}: ${p.f.screen.title})`);
  noProblems(p);
});

// MARK: - Whole treks

await test('careful treks reach Dawson over both passes through every stop, each set piece answered both ways', async () => {
  let arrived = 0;
  const stopsSeen = new Set(), answers = new Set(), ends = [];
  const PICKS = {
    fork: ['Land at Dyea for the Chilkoot', 'Land at Skagway for the White Pass'],
    canyon: ['Hire a pilot to run her through', 'Portage the outfit and line her down'],
    fivefinger: ['Run the right-hand channel', 'Line her down along the bank'],
    packers: ['Hire the packers', 'Pack it all yourselves'],
  };
  // Which answer each set piece gets, by run.
  for (const [seed, role, month, way] of [['3', 0, 'March 1898', 0], ['11', 1, 'March 1898', 1], ['21', 0, 'February 1898', 1],
    ['29', 1, 'April 1898', 0]]) {
    const storage = new MemoryStorage();
    const p = await trekPlayer({ engine: e1, storage, seeds: [seed], random: lcg(Number(seed)) });
    p.setUp({ role: J0.roles[role].label, month });
    const seen = new Set(), next = new Set();
    const end = p.voyage({
      onScreen: (q) => {
        if (q.f.game) seen.add(q.f.game.stopIndex);
        if (q.screen === 'travel' || q.screen === 'seaMenu' || q.screen === 'portMenu') {
          for (const k of Object.keys(statusRows(q))) if (k.startsWith('Next: ')) next.add(k.slice(6));
        }
        const key = choiceKey(q);
        const pick = PICKS[key];
        if (pick) {
          const c = q.look().choices.find((x) => plain(x.label).startsWith(pick[way]));
          if (c?.enabled) {
            answers.add(`${key}:${pick[way]}`);
            c.act();
          } else {
            q.look().choices.find((x) => x.enabled).act();
          }
        }
        return null;
      },
    });
    const white = way === 1;
    if (end === 'finale') {
      arrived += 1;
      for (const i of seen) stopsSeen.add(i);
      const words = wordsOn(p.look());
      check(/The .* noses into the mud below Dawson City on .*, \d+ days after you left Seattle\./.test(words), `Dawson (${words.slice(0, 140)})`);
      check(saveOf(storage) === null, 'the save goes with the arrival');
      check(JSON.parse(storage.getItem('horn.topten-klondike') ?? '[]').length === 10, 'into the trail\'s own top ten');
      check(seen.size === J0.stops.length, `${J0.roles[role].title} from seed ${seed}: every stop (${[...seen].join(',')})`);
      const named = [...next].join('/');
      check(white ? next.has('Skagway') && next.has('White Pass City') && next.has('White Pass summit') && next.has('Log Cabin') && !next.has('Sheep Camp')
        : next.has('Dyea') && next.has('Sheep Camp') && next.has('Chilkoot summit') && next.has('Lindeman') && !next.has('Skagway'),
      `seed ${seed}: the stops named for the ${white ? 'White Pass' : 'Chilkoot'} (${named})`);
    } else {
      ends.push(`seed ${seed}: ${end} on day ${p.f.game?.day} (${plain(p.f.screen.title ?? '')})`);
    }
    noProblems(p, `seed ${seed}`);
  }
  check(arrived >= 3, `careful treks reach Dawson (${arrived} of 4; ${ends.join('; ')})`);
  check(stopsSeen.size === J0.stops.length, `every stop seen (${stopsSeen.size} of ${J0.stops.length})`);
  check(['fork', 'canyon', 'fivefinger'].every((k) => PICKS[k].every((a) => answers.has(`${k}:${a}`))),
    `each set piece answered both ways (${[...answers]})`);
});

// MARK: - Lake Bennett

await test('Lake Bennett holds the party: no floating to Dawson on a sled, the boat question from the yard\'s row, and the ice', async () => {
  const storage = new MemoryStorage();
  const p = await trekAt(inTown('bennett'), { stop: 'bennett', storage });
  check(p.screen === 'portMenu' && p.labels().includes('See about a boat') && p.labels().includes('Push off and float on'),
    `in camp at Bennett (${p.labels().join('/')})`);
  check(p.look().blocks.find((b) => b.type === 'status').region === 'Lake Bennett', 'Lake Bennett, in the status box');
  check(sceneLabel(p) === 'Your party in camp at Lake Bennett, in fair weather' || /^Your party in camp at Lake Bennett, /.test(sceneLabel(p)), `the scene (${sceneLabel(p)})`);
  p.say('Push off and float on');
  check(p.screen === 'message' && p.f.screen.text === "You can't float to Dawson on a sled. See about a boat first.", `no floating on a sled (${p.f.screen.text})`);
  p.press(1);
  check(choiceKey(p) === 'boat' && p.labels().length === 5 && p.labels()[4] === 'Not yet', `the boat question (${p.labels().join('/')})`);
  // Left mid-hold, the question comes back on a fresh engine.
  const asked = screenWords(p.f);
  const q = await trekPlayer({ engine: e2, storage, seeds: ['8'], random: lcg(8) });
  q.press('Continue the journey of the');
  check(q.screen === 'choice' && screenWords(q.f) === asked, `left mid-hold, the boat question comes back (${q.screen})`);
  p.press('Not yet');
  check(p.screen === 'portMenu' && p.f.game.atPort, 'not yet: still in camp');
  p.say('See about a boat');
  check(choiceKey(p) === 'boat', `the yard's row asks it (${p.screen})`);
  p.press('Whipsaw lumber and build her properly');
  readOn(p);
  check(p.f.v.hooks.klondike.hasBoat && p.screen === 'portMenu' && p.labels().includes('Visit the boatwrights'), `a boat built (${p.screen}: ${p.labels().join('/')})`);
  check(statusRows(p)[BOAT]?.value === '100% · 100%', `the meters are the boat's (${JSON.stringify(statusRows(p))})`);
  check(sceneLabel(p) === 'Your boat tied up at Lake Bennett, in fair weather' || /^Your boat tied up at Lake Bennett, /.test(sceneLabel(p)), `her at the bank (${sceneLabel(p)})`);
  const iceIn = !kSkin.iceOut(p.f.game, p.f.v.date);
  if (iceIn) {
    p.say('Push off and float on');
    check(choiceKey(p) === 'ice' && p.labels().join('/') === 'Wait in camp for the ice to go out/Not yet', `the ice (${p.screen}: ${p.labels().join('/')})`);
    check(p.look().blocks.some((b) => plain(b.markup ?? b.text ?? '').startsWith('Lake Bennett is still white from shore to shore.')), 'still white');
    const held = screenWords(p.f);
    const r = await trekPlayer({ engine: e2, storage, seeds: ['8'], random: lcg(8) });
    r.press('Continue the journey of the');
    check(r.screen === 'choice' && screenWords(r.f) === held, 'left waiting for the ice, it comes back');
    p.press('Not yet');
    check(p.screen === 'portMenu', 'not yet: still in camp');
    p.say('Push off and float on');
    p.press('Wait in camp for the ice to go out');
    readOn(p);
    check(kSkin.iceOut(p.f.game, p.f.v.date), `the ice out (${p.f.v.dateText})`);
    goUntil(p, (x) => x.screen === 'travel' || x.f.game.mile > mileOf('bennett'), 10);
    check(p.f.game.mile > mileOf('bennett') || p.screen === 'travel', `and away down the lakes (${p.screen}, ${p.f.game.mile})`);
  }
  check(iceIn, 'the ice was in on the day the gallery puts a party at Bennett');
  noProblems(p);
});

// MARK: - Trouble (D14) and the order of repairs (D15)

await test('the sleds given out: the box says so in red, and a coil, a coil bought, making do or taking stock', async () => {
  const given = (more = {}) => (s) => { kSkin.go(J0, s, 11400); Object.assign(s, { sails: 0, sailcloth: 1 }, more); };
  const storage = new MemoryStorage();
  const a = await trekAt(given(), { stop: 'lakes', storage });
  check(statusRows(a).Party?.value === 'Sleds given out' && statusRows(a).Party.color === 'red', `the box says so, in red (${JSON.stringify(statusRows(a).Party)})`);
  check(/^\d+% · 0%$/.test(statusRows(a)[FOOT].value), `the sleds at 0%, never below (${statusRows(a)[FOOT].value})`);
  a.say(a.words.supplies);
  check(wordsOn(a.look()).includes('the sleds have given out'), 'the supplies note');
  a.f.backToMenu();
  a.say(a.words.changePace);
  check(wordsOn(a.look()).includes('The sleds have given out: nobody moves until they are mended.'), 'the pace screen');
  a.f.backToMenu();
  const mile = a.f.game.mile;
  a.say(a.words.carryOn);
  a.timers.fire();
  check(choiceKey(a) === 'givenout' && a.f.game.mile === mile, `asked before another step (${a.screen})`);
  check(a.labels().join('/') === 'Mend the sleds: 1 coil of rope & rawhide (have 1)/Lash up pack boards from empty crates and sacking (2 days)/Take stock first',
    `a coil, making do, taking stock (${a.labels().join('/')})`);
  check(a.look().blocks.some((b) => (b.markup ?? '').startsWith('[red]Your sleds have given out.[/red]')), 'in red');
  check(sceneLabel(a) === 'Your party beside sleds that have given out, in fair weather' || sceneLabel(a).startsWith('Your party beside sleds that have given out'),
    `drawn (${sceneLabel(a)})`);
  // Left mid-trouble, the question comes back on a fresh engine.
  const asked = screenWords(a.f);
  const back = await trekPlayer({ engine: e2, storage, seeds: ['8'], random: lcg(8) });
  back.press('Continue the journey of the');
  check(back.screen === 'choice' && screenWords(back.f) === asked, `left mid-trouble, it comes back (${back.screen})`);
  check(back.f.v.hooks.klondike.givenOut && back.f.game.sails === 0 && back.f.skin.words(back.f.v).trouble?.value === 'Sleds given out',
    'in the same plight');
  a.press('Mend the sleds');
  readOn(a);
  check(a.f.game.sails > 0 && a.f.game.sailcloth === 0, `mended (${a.f.game.sails})`);
  check(!statusRows(a).Party, 'and nothing wrong in the box');

  const b = await trekAt(given({ sailcloth: 0 }), { stop: 'lakes' });
  b.say(b.words.carryOn);
  b.timers.fire();
  check(b.labels().join('/') === 'Mend the sleds: 1 coil of rope & rawhide (have 0)/Buy a coil off the next party along ($24)/Lash up pack boards from empty crates and sacking (2 days)/Take stock first',
    `no coil: buy one (${b.labels().join('/')})`);
  const money = b.f.game.money;
  b.press('Buy a coil off the next party along');
  readOn(b);
  check(b.f.game.money === money - 24 && b.f.game.sails > 0, `bought and mended (${b.f.game.money}, ${b.f.game.sails})`);

  const c = await trekAt(given({ sailcloth: 0, money: 0 }), { stop: 'lakes' });
  c.say(c.words.carryOn);
  c.timers.fire();
  check(c.look().choices.map((x) => x.enabled).join() === 'false,false,true,true', 'no coil and no money: making do');
  const day = c.f.game.day;
  c.press('Take stock first');
  check(c.screen === 'seaMenu' && statusRows(c).Party?.value === 'Sleds given out', `taking stock, still given out (${c.screen})`);
  c.say(c.words.carryOn);
  c.timers.fire();
  c.press('Lash up pack boards');
  readOn(c);
  check(c.f.game.day === day + 2 && c.f.game.sails > 0, `two days' work (${c.f.game.day - day}, ${c.f.game.sails})`);
  noProblems(a);
  noProblems(back);
  noProblems(b);
  noProblems(c);
});

await test('no firewood, and both at once: the box says so; the oars given out on the river', async () => {
  const a = await trekAt((s) => { kSkin.go(J0, s, 11400); s.water = 0; }, { stop: 'lakes' });
  check(statusRows(a).Party?.value === 'No firewood' && statusRows(a).Party.color === 'red', `no firewood (${JSON.stringify(statusRows(a).Party)})`);
  a.say(a.words.supplies);
  check(wordsOn(a.look()).includes('no firewood'), 'the supplies note');
  a.f.backToMenu();
  const b = await trekAt((s) => { kSkin.go(J0, s, 11400); s.water = 0; s.sails = 0; }, { stop: 'lakes' });
  check(statusRows(b).Party?.value === 'Sleds given out, no firewood', `both (${JSON.stringify(statusRows(b).Party)})`);
  const c = await trekAt((s) => { kSkin.go(J0, s, 14000); s.sails = 0; s.sailcloth = 1; }, { stop: 'fivefinger' });
  check(statusRows(c).Party?.value === 'Oars & sail given out' && /^\d+% · 0%$/.test(statusRows(c)[BOAT]?.value ?? ''),
    `the oars (${JSON.stringify(statusRows(c))})`);
  check(sceneLabel(c).startsWith('Your boat tied to the bank with no oars or sail'), `tied to the bank (${sceneLabel(c)})`);
  c.say(c.words.changePace);
  check(wordsOn(c.look()).includes('The oars & sail have given out: she stays tied to the bank until they are re-rigged.'), 'the pace screen');
  c.f.backToMenu();
  c.say(c.words.carryOn);
  c.timers.fire();
  check(choiceKey(c) === 'givenout' && c.labels().join('/') === 'Re-rig the oars & sail: 1 coil of rope & rawhide (have 1)/Cut a sweep and oars from a spruce on the bank (2 days)/Take stock first',
    `re-rig, cut a sweep, take stock (${c.labels().join('/')})`);
  c.press('Re-rig the oars & sail');
  readOn(c);
  check(c.f.game.sails > 0 && !statusRows(c).Party, `re-rigged (${c.f.game.sails})`);
  const d = await trekAt((s) => { kSkin.go(J0, s, 14000); s.sails = 0; s.water = 0; }, { stop: 'fivefinger' });
  check(statusRows(d).Party?.value === 'Oars given out, no firewood', `both on the river (${JSON.stringify(statusRows(d).Party)})`);
  for (const p of [a, b, c, d]) noProblems(p);
});

await test('worn to nothing with nothing to mend with: no meter below 0%, the box in red, and the outfit ruined', async () => {
  const p = await trekAt((s) => Object.assign(s, { sails: 2, hull: 3, sailcloth: 0, timber: 0, money: 0 }), { stop: 'lakes' });
  p.say(p.words.carryOn);
  const meters = [], troubles = [];
  for (let i = 0; i < 200 && p.screen !== 'gameOver'; i++) {
    if (p.screen !== 'travel') {
      p.look().choices.find((c) => c.enabled).act();
      continue;
    }
    const rows = statusRows(p);
    meters.push(rows[FOOT]?.value ?? rows[BOAT]?.value);
    if (rows.Party) troubles.push(`${rows.Party.value}/${rows.Party.color}`);
    p.timers.fire();
  }
  check(meters.length > 1 && !meters.some((m) => m.includes('-')), `no meter below 0 (${[...new Set(meters)].slice(-4).join(' | ')})`);
  check(troubles.every((t) => t.endsWith('/red')), `the box in red (${[...new Set(troubles)]})`);
  check(p.screen === 'gameOver', `in the end the outfit is ruined (${p.screen}: ${p.f.screen.title})`);
  if (p.screen === 'gameOver' && p.f.game.hull <= 0) check(sceneLabel(p).startsWith('Your outfit lies ruined in the snow'), `ruined in the snow (${sceneLabel(p)})`);
  noProblems(p);
});

await test('the condition box, the repairs and the yard list the outfit or the boat first (D15)', async () => {
  const p = await trekAt((s) => Object.assign(s, { hull: 30, sails: 30 }), { stop: 'lakes' });
  check(statusRows(p)[FOOT]?.value === '30% · 30%', `the outfit, then the sleds (${JSON.stringify(statusRows(p))})`);
  p.say(p.words.repairs);
  check(p.labels().join('/') === 'Patch the outfit — 1 bundle of canvas & pitch (have 4)/Mend sleds & straps — 1 coil of rope & rawhide (have 3)/Done',
    `repairs (${p.labels().join('/')})`);
  p.press('Patch the outfit');
  check(p.f.game.timber === 3 && p.f.game.hull > 30, `a bundle patches the outfit (${p.f.game.hull})`);
  const r = await trekAt((s) => { kSkin.go(J0, s, 14000); Object.assign(s, { hull: 30, sails: 30 }); }, { stop: 'fivefinger' });
  check(statusRows(r)[BOAT]?.value === '30% · 30%', `the boat, then the oars & sail (${JSON.stringify(statusRows(r))})`);
  r.say(r.words.repairs);
  check(r.labels().join('/') === 'Patch the hull — 1 bundle of canvas & pitch (have 4)/Re-rig oars & sail — 1 coil of rope & rawhide (have 3)/Done',
    `the boat's repairs (${r.labels().join('/')})`);
  const y = await trekAt((s) => { inTown('camp')(s); Object.assign(s, { hull: 40, sails: 40, money: 2000 }); }, { stop: 'camp' });
  check(y.screen === 'portMenu' && y.labels().includes("Visit the outfitters' yard"), `in Sheep Camp (${y.labels().join('/')})`);
  y.say(y.words.yard);
  check(/^Have the outfit re-sacked and re-tarped — \$[\d,]+\/Have the sleds and harness made good — \$[\d,]+\/Leave the yard$/.test(y.labels().join('/')),
    `the outfitters' yard (${y.labels().join('/')})`);
  const w = await trekAt((s) => { inTown('camp', true)(s); }, { stop: 'camp' });
  check(w.look().blocks.find((b) => b.type === 'status').region === 'White Pass City', 'White Pass City, on the White Pass');
  for (const x of [p, r, y, w]) noProblems(x);
});

// MARK: - Endings

await test('every other ending: turned back at the summit, the boat broken up, the leader lost', async () => {
  const a = await trekAt((s) => Object.assign(s, { food: 500 }), { stop: 'summit' });
  a.say(a.words.carryOn);
  goUntil(a, (q) => choiceKey(q) === 'police' || q.screen === 'gameOver', 40);
  check(choiceKey(a) === 'police' && a.labels().at(-1) === 'Turn back for home', `the police at the summit (${a.screen}: ${a.labels().join('/')})`);
  a.press('Turn back for home');
  readOn(a);
  check(a.screen === 'gameOver' && a.f.screen.title === 'The police have turned you back.', `turned back (${a.screen}: ${a.f.screen.title})`);
  check(sceneLabel(a).startsWith('Your party turning back from the summit'), `facing home (${sceneLabel(a)})`);

  const b = await trekAt((s) => { kSkin.go(J0, s, 14000); Object.assign(s, { hull: 1, timber: 0, money: 0 }); }, { stop: 'fivefinger' });
  b.say(b.words.carryOn);
  goUntil(b, (q) => q.screen === 'gameOver' || q.screen === 'finale', 60);
  check(b.screen === 'gameOver' && b.f.game.hull === 0, `the boat broken up (${b.screen}: ${b.f.screen.title})`);
  check(sceneLabel(b).startsWith('The wreck of your boat going down the river'), `the wreck (${sceneLabel(b)})`);

  const c = await trekAt((s) => {
    s.crew[0].hp = 1;
    s.crew[0].ailment = J0.ailments.reduce((x, y) => (y.damage > x.damage ? y : x));
    s.meds = 0;
  }, { stop: 'lakes' });
  c.say(c.words.carryOn);
  goUntil(c, (q) => q.screen === 'gameOver', 60);
  check(c.screen === 'gameOver' && /^You, .*Gus, have died of /.test(c.f.screen.title), `the leader lost (${c.f.screen.title})`);
  for (const p of [a, b, c]) noProblems(p);
});

if (failures.length) {
  console.log(failures.slice(0, 30).join('\n'));
  console.log(`klondike: ${passed} checks passed, ${failures.length} failed`);
  process.exit(1);
}
console.log(`klondike: ${passed} checks passed, 0 failed`);
