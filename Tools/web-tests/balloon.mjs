// The Jet Stream in the web game's flow (web/js/flow.js, web/js/screens.js and the balloon
// skin), played in Node through what the screens offer, as airship.mjs plays Over the Pole:
//
// - the picker offers it; its title card, learn pages, setup and top ten are its own, in
//   its own words (D11);
// - Marrakech won't launch her without propane for the climb, and a flight saved in its
//   supply hangar comes back to it (D16);
// - whole seeded flights: round the world to the finish line through every stop, on the
//   northern track and the southern, and every other ending: down in the sea, down on land,
//   grounded at a field, the pilot lost;
// - every kind of trouble (D14) and each way out of it: burners dead (a kit aloft, or
//   drifting to a field's burner man, or going up on the helium alone, D17), tanks dry (a
//   field's propane, or the ground team's on the sponsor's account), the last of the
//   propane, going down (ballast, a propane cylinder, a field's ground team, or nothing);
//   the relaunch refused for what the field can mend, and repairs, the yard and the
//   trouble's choices in the condition box's order (D15);
// - leaving mid-trouble and coming back to the same screen and the same plight on a fresh
//   engine; and on every screen of every flight no other journey's word, no "undefined"
//   and no "NaN".
//
//   node Tools/web-tests/balloon.mjs
import { Player, engine, lcg, describe, plain, balloonProblems, SAFE } from './player.mjs';
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
const saveOf = (storage, id = 'balloon') => JSON.parse(storage.getItem(`horn.save-${id}`) ?? 'null');
const screenWords = (f) => {
  const d = describe(f);
  return JSON.stringify(d.blocks.filter((b) => b.type !== 'scene')) + JSON.stringify(d.choices.map((c) => [c.label, c.enabled]));
};
const wordsOn = (d) => d.blocks.map((b) => plain(b.markup ?? b.text ?? b.label ?? '')).filter(Boolean).join(' ');

/** D11: the lines no journey may use. */
const D11 = /Many kinds of people|You may:|Find out the differences|\bBe an? [a-z]+ from\b|\bFilling\b|\bMeager\b|Bare bones|Attempt to trade/;

/** A balloon player whose every look is also checked for other journeys' words and the banner. */
async function airPlayer(o = {}) {
  const p = await Player.make({ journey: 'balloon', ...o });
  const look = p.look.bind(p);
  p.look = () => {
    const d = look();
    if (p.f.journey.id === 'balloon' && p.screen !== 'picker') {
      p.problems.push(...balloonProblems(d, p.screen));
      const all = wordsOn(d) + ' ' + d.choices.map((c) => plain(c.label)).join(' ');
      const m = all.match(D11);
      if (m) p.problems.push(`${p.screen}: D11's "${m[0]}"`);
      if (d.banner !== 'THE JET STREAM · 1999') p.problems.push(`${p.screen}: the banner reads ${d.banner}`);
    }
    return d;
  };
  return p;
}

const noProblems = (p, what = 'no word went wrong') => check(p.problems.length === 0, `${what}: ${p.problems.slice(0, 3).join(' | ')}`);

/** The status box's rows by label: { value, color }. */
const statusRows = (p) => Object.fromEntries((p.look().blocks.find((b) => b.type === 'status')?.rows ?? [])
  .map((r) => [plain(r.label), { value: r.value, color: r.color }]));

const J0 = (await airPlayer({ engine: e1 })).f.journey;
const stopIndex = (id) => J0.stops.findIndex((s) => s.id === id);
const mileOf = (id) => J0.stops[stopIndex(id)].mile;

/**
 * A balloon from the debug start, by day, short of Jodhpur over the Gulf of Oman (`mile`,
 * a watch's flying from anywhere), with `set` applied to it, on its menu.
 */
async function balloonAt(set, { mile = 3700, seed = '9', storage = new MemoryStorage(), role = 'merchant' } = {}) {
  const p = await airPlayer({ engine: e1, storage, seeds: ['31'], random: lcg(31) });
  e1.start({ journey: 'balloon', role, ship: 'Skylark', captain: 'Greta', crew: ['Hugo', 'Yuki', 'Conor', 'Rosa'],
    year: 1999, month: 0, seed });
  const s = e1.save([]);
  p.f.skin.debug.start(s, stopIndex('jod'));
  s.mile = mile;
  s.stopIndex = Math.max(0, J0.stops.findLastIndex((st) => st.mile < mile));
  set(s);
  p.f.loadForDebug(s);
  return p;
}
/** Over the field at `id`, its arrival told, not landed. */
const overField = (id) => (s) => Object.assign(s, { stopIndex: stopIndex(id), mile: mileOf(id) });
/** On the ground at the field at `id`. */
const onField = (id) => (s) => Object.assign(s, { stopIndex: stopIndex(id), mile: mileOf(id), atPort: true });
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
/** Flies watches, landing at fields and taking the first answer to anything else, until `done`. */
const flyUntil = (p, done, limit = 120) => {
  let watches = 0;
  for (let i = 0; i < limit && !done(p); i++) {
    if (p.screen === 'travel') {
      p.timers.fire();
      watches += 1;
    } else {
      p.look().choices.find((c) => c.enabled).act();
    }
  }
  return watches;
};

// MARK: - The picker, the title card, the setup

await test('the picker offers the Jet Stream, and its title card, pages, setup and top ten are its own', async () => {
  const storage = new MemoryStorage();
  const p = await airPlayer({ engine: e1, storage, journey: null, seeds: ['4'], random: lcg(4) });
  check(p.screen === 'picker' && p.labels().includes(J0.title), `the picker offers it (${p.labels()})`);
  p.press(J0.title);
  check(p.screen === 'title' && p.look().banner === 'THE JET STREAM · 1999', 'its title card');
  check(storage.getItem('horn.lastJourney') === 'balloon', 'and remembers the choice');
  const q = await airPlayer({ engine: e2, storage, journey: null });
  check(q.screen === 'title' && q.f.journey.id === 'balloon', 'a new visit opens on it');
  const r = await airPlayer({ engine: e2, journey: 'balloon' });
  check(r.screen === 'title' && r.f.journey.id === 'balloon', '?journey=balloon opens on it');

  p.press('Learn about the flight');
  const headings = [];
  while (p.screen === 'learn') {
    headings.push(p.look().blocks[0].text);
    p.press(p.labels()[0]);
  }
  check(headings.join('/') === 'The flight/Propane, lift and burners/Air, food and the cold/The Pacific', `four pages (${headings})`);
  p.press('See the top ten');
  const places = p.look().blocks.filter((b) => b.type === 'place');
  check(places.length === 10 && places[0].text === `1. ${J0.defaultTopTen[0].name}`,
    `the flight's own top ten (${places[0]?.text}, ${places[0]?.rank})`);
  p.press('Back');
  p.press('Fly round the world');
  check(p.labels().join('/') === `${J0.roles.map((x) => x.label).join('/')}/Compare the three/Back to the title`,
    `who are you? (${p.labels().join('/')})`);
  check(wordsOn(p.look()).includes('Balloonists came from every walk of life'), 'in its own words (D11)');
  p.press('Compare the three');
  check(wordsOn(p.look()).includes('Bush pilot — starts with $6,500.'), 'how they compare');
  p.press('Back');
  p.press(J0.roles[2].label);
  const fields = p.look().blocks.filter((b) => b.type === 'field');
  check(fields[0].label === "Balloon's name" && fields[1].label === "Pilot's name" && fields[2].label === 'Crew member 1',
    'the balloon, the pilot and the crew');
  p.press('Use these names', { ship: 'Skylark', captain: 'Greta' });
  check(p.labels().join('/') === 'November 1998/December 1998/January 1999/February 1999/March 1999/Ask for advice/Back to the title',
    `the months she can launch in (${p.labels().join('/')})`);
  p.press('Ask for advice');
  check(p.f.screen.text.startsWith('Your meteorologist taps the chart'), 'the meteorologist');
  p.press('Continue');
  p.press('March 1999');
  check(wordsOn(p.look()).startsWith('Outfitting You have $6,500 to fit out the Skylark.'), `fitting out the Skylark (${wordsOn(p.look()).slice(0, 60)})`);
  p.press('Back to the title');
  check(p.screen === 'title' && p.f.game === null, 'back to the title, nothing started');
  noProblems(p);
});

// MARK: - Marrakech

await test('Marrakech won\'t launch her without propane for the climb, and a flight saved in its hangar comes back to it (D16)', async () => {
  const storage = new MemoryStorage();
  const a = await airPlayer({ engine: e1, storage, seeds: ['5'], random: lcg(5) });
  a.setUp();
  check(a.screen === 'shop' && a.f.game.fuel === 0, 'in the supply hangar with empty tanks');
  a.shop({ food: 10 });
  a.press('Pay');
  check(a.screen === 'message' && a.f.screen.text === J0.text.noProvisions
    && a.f.screen.text.includes('at least 25 gallons of propane'), `no launch without propane (${a.f.screen.text})`);
  a.press(1);
  check(a.screen === 'shop', 'and it is back to the hangar');
  check(saveOf(storage)?.atPort && saveOf(storage).day === 0 && saveOf(storage).food === 100, 'the rations bought, saved in the hangar');
  const b = await airPlayer({ engine: e2, storage, seeds: ['6'], random: lcg(6) });
  check(b.labels()[1] === `Continue the flight of the ${saveOf(storage).ship}`, `the title card offers the flight (${b.labels()[1]})`);
  b.press('Continue the flight');
  check(b.screen === 'shop', `back in the hangar at Marrakech (${b.screen})`);
  b.topUp(SAFE.balloon);
  const fuel = SAFE.balloon.fuel;
  b.press('Pay');
  check(b.screen === 'depart' && b.f.screen.text.includes('lifts off from the launch field outside Marrakech at 0800 GMT'),
    `and up through the launch (${b.f.screen.text?.slice(0, 90)})`);
  check(b.f.game.fuel === fuel - 25, `the climb burns 25 gallons (${fuel} to ${b.f.game.fuel})`);
  const f = sceneFrame(b.f.journey, b.f.v, false, 0);
  check(b.f.skin.scene.label(f).startsWith('Balloon climbing away from the launch field at Marrakech'), `climbing away (${b.f.skin.scene.label(f)})`);
  b.press('Climb away');
  check(b.screen === 'travel', 'under way');
  b.f.stopTravel();
  const box = b.look().blocks.find((x) => x.type === 'status');
  check(box.date === 'January 1, 1999, 0800 GMT' && statusRows(b).Propane.value === '1,175 gal' && statusRows(b)['Lift · Burners'].value === '100% · 100%'
    && statusRows(b)['Next: High Atlas'].value === '100 nm', `the status box keeps GMT, gallons and nautical miles (${box.date})`);
  noProblems(a);
  noProblems(b);
});

// MARK: - Whole flights

await test('careful flights cross the finish line, through every stop on the way, on both tracks', async () => {
  let landed = 0;
  const stopsSeen = new Set();
  const tracks = new Set();
  for (const [seed, role, month, track] of [['3', 0, 'January 1999', 0], ['11', 1, 'January 1999', 1], ['17', 2, 'December 1998', 0],
    ['23', 0, 'February 1999', 1]]) {
    const storage = new MemoryStorage();
    const p = await airPlayer({ engine: e1, storage, seeds: [seed], random: lcg(Number(seed)) });
    p.setUp({ role: J0.roles[role].label, month });
    const seen = new Set();
    let said = '';
    const end = p.voyage({
      onScreen: (q) => {
        if (q.f.game) seen.add(q.f.game.stopIndex);
        if (q.screen === 'message') said += `${q.f.screen.text}\n`;
        if (choiceKey(q) === 'fork') {
          q.press(track === 0 ? 'Ride the northern track' : 'Take the southern track');
          return null;
        }
        if (choiceKey(q) === 'forecast') q.press('Trust your own eyes');
        return null;
      },
    });
    if (end === 'finale') {
      landed += 1;
      for (const i of seen) stopsSeen.add(i);
      const words = wordsOn(p.look());
      check(words.includes('Finish line!') && words.includes('crosses eight degrees west') && words.includes('Children run out'),
        `the finish, as the engine tells it (${words.slice(0, 80)})`);
      check(saveOf(storage) === null, 'the save goes with the finish');
      check(JSON.parse(storage.getItem('horn.topten-balloon') ?? '[]').length === 10 && storage.getItem('horn.topten-airship') === null,
        'into the flight\'s own top ten');
      check(seen.size === J0.stops.length, `${J0.roles[role].title} from seed ${seed}: every stop (${[...seen].join(',')})`);
      const landfall = track === 0 ? 'The coast of California slides in under you' : 'San Diego slides in under you';
      check(said.includes(landfall), `the landfall on the ${track === 0 ? 'northern' : 'southern'} track`);
      if (said.includes(landfall)) tracks.add(track);
    }
    noProblems(p, `seed ${seed}`);
  }
  check(landed >= 3, `careful flights finish (${landed} of 4)`);
  check(stopsSeen.size === J0.stops.length && tracks.size === 2, `every stop seen (${stopsSeen.size} of ${J0.stops.length}), both tracks flown`);
});

await test('every other ending: down in the sea, down on land, grounded at a field, the pilot lost', async () => {
  const downAt = async (mile, where) => {
    const p = await balloonAt((s) => Object.assign(s, { mile, stopIndex: Math.max(0, J0.stops.findLastIndex((st) => st.mile < mile)),
      hull: 0.3, timber: 0, fuel: 40 }));
    p.press('Continue the flight');
    p.timers.fire();
    check(p.screen === 'gameOver' && p.f.screen.title.startsWith('The [i]Skylark[/i] has come down'),
      `down over ${where} (${p.screen}: ${p.f.screen.title})`);
    check(p.look().blocks.some((b) => b.type === 'scene') && p.f.v.state.over, 'the scene shows where she came down');
    const label = p.f.skin.scene.label(sceneFrame(p.f.journey, p.f.v, false, 0));
    noProblems(p);
    return [p.f.screen.title, wordsOn(p.look()), label];
  };
  const [seaTitle, sea, seaLabel] = await downAt(9000, 'the North Pacific');
  const [landTitle, land, landLabel] = await downAt(4800, 'northern India');
  check(seaTitle === 'The [i]Skylark[/i] has come down in the sea.' && sea.includes('A freighter answers your mayday'), `in the sea (${seaTitle})`);
  check(landTitle === 'The [i]Skylark[/i] has come down.' && land.includes('a cloud of dust and torn fabric'), `on land (${landTitle})`);
  check(seaLabel.startsWith('The balloon down in the sea') && landLabel.startsWith('The balloon down on open ground'),
    `each drawn where it happened (${seaLabel} | ${landLabel})`);

  const p = await balloonAt((s) => { overField('lux')(s); Object.assign(s, { hull: 0.3, money: 5, timber: 0, fuel: 40 }); });
  p.press('Continue the flight');
  p.timers.fire();
  check(p.screen === 'gameOver' && p.f.screen.title === 'Grounded at Luxor.', `grounded at Luxor (${p.f.screen.title})`);
  check(wordsOn(p.look()).includes('comes down on the field at Luxor for the last time'), 'for the last time');
  check(p.f.skin.scene.label(sceneFrame(p.f.journey, p.f.v, false, 0)).startsWith('The balloon down for good on the field at Luxor'),
    'laid out flat on the field');
  noProblems(p);

  const c = await balloonAt((s) => {
    s.crew[0].hp = 1;
    s.crew[0].ailment = J0.ailments.reduce((a, b) => (b.damage > a.damage ? b : a));
    s.meds = 0;
  });
  c.press('Continue the flight');
  flyUntil(c, (q) => q.screen === 'gameOver', 60);
  check(c.screen === 'gameOver' && /^You, .*Greta, have died of /.test(c.f.screen.title), `the pilot lost (${c.f.screen.title})`);
  check(wordsOn(c.look()).includes('Your co-pilot brings the balloon down'), 'and the co-pilot brings her down');
  noProblems(c);
});

// MARK: - Trouble (D14) and the order of repairs (D15)

await test('worn to nothing with nothing to mend with: no meter below 0%, the box says so in red, and she comes down', async () => {
  const p = await balloonAt((s) => Object.assign(s, { sails: 3, hull: 6, fuel: 30, sailcloth: 0, timber: 0, money: 0 }));
  p.press('Continue the flight');
  const meters = [], troubles = [];
  for (let i = 0; i < 120 && p.screen !== 'gameOver'; i++) {
    if (p.screen !== 'travel') {
      p.look().choices.find((c) => c.enabled).act();
      continue;
    }
    const rows = statusRows(p);
    meters.push(rows['Lift · Burners'].value);
    if (rows.Balloon) troubles.push(`${rows.Balloon.value}/${rows.Balloon.color}`);
    p.timers.fire();
  }
  check(meters.length > 1 && !meters.some((m) => m.includes('-')), `no meter below 0 (${[...new Set(meters)].slice(-4).join(' | ')})`);
  check(troubles.every((t) => t.endsWith('/red')) && troubles.some((t) => /^(Burners dead|Tanks dry|Last of the propane)/.test(t)),
    `the box says what is wrong, in red (${[...new Set(troubles)]})`);
  check(p.screen === 'gameOver', `with nothing to throw over the side she comes down (${p.screen}: ${p.f.screen.title})`);
  noProblems(p);
});

await test('the condition box, the repairs, the yard and the relaunch list the lift first (D15)', async () => {
  const p = await balloonAt((s) => Object.assign(s, { hull: 30, sails: 30 }));
  check(statusRows(p)['Lift · Burners']?.value === '30% · 30%', `lift, then the burners (${JSON.stringify(statusRows(p)['Lift · Burners'])})`);
  p.press('Make repairs');
  check(p.labels().join('/') === 'Drop a sack of ballast (have 4)/Service the burners — 1 kit (have 3)/Done', `repairs aloft (${p.labels().join('/')})`);
  p.press('Drop a sack of ballast');
  check(p.f.game.timber === 3 && p.f.game.hull > 30, `a sack of ballast lifts her (${p.f.game.hull})`);
  const y = await balloonAt((s) => { onField('jod')(s); Object.assign(s, { hull: 40, sails: 40 }); });
  check(y.screen === 'portMenu' && y.labels().includes('Visit the riggers'), `on the ground at Jodhpur (${y.labels().join('/')})`);
  y.say(y.words.yard);
  check(/^Top up the helium — \$[\d,]+\/Overhaul the burners — \$[\d,]+\/Back to the field$/.test(y.labels().join('/')),
    `the riggers (${y.labels().join('/')})`);
  // Both given out, on the ground with the price of everything: the lift's refusal first.
  const r = await balloonAt((s) => { onField('jod')(s); Object.assign(s, { hull: 0.3, sails: 0.3, timber: 0 }); });
  check(statusRows(r).Balloon?.value === 'No lift', `on the ground with no lift (${statusRows(r).Balloon?.value})`);
  r.say(r.words.leavePort);
  check(r.screen === 'message' && r.f.screen.text.startsWith("The launch director won't let you go up with no lift in her."),
    `the lift's refusal first (${r.f.screen.text})`);
  r.press(1);
  check(r.screen === 'portMenu', 'and back to the field');
  noProblems(p);
  noProblems(y);
  noProblems(r);
});

await test('burners dead: she sinks, the box says so, and a burner kit gets her heat back', async () => {
  const p = await balloonAt((s) => Object.assign(s, { sails: 0.4, sailcloth: 1 }));
  check(statusRows(p).Balloon?.value === 'Burners dead, sinking' && statusRows(p).Balloon.color === 'red', 'the box says so, in red');
  check(statusRows(p)['Lift · Burners'].value === '72% · 0%', `the burners at 0%, never below (${statusRows(p)['Lift · Burners'].value})`);
  p.say(p.words.supplies);
  check(wordsOn(p.look()).includes('the burners are dead'), 'the supplies note');
  p.f.backToMenu();
  p.say(p.words.changePace);
  check(wordsOn(p.look()).includes('With no heat for the cone, the height makes no difference to how far she drifts.'), 'the altitude screen');
  p.f.backToMenu();
  const { fuel, hull } = p.f.game;
  p.press('Continue the flight');
  p.timers.fire();
  const said = readOn(p);
  check(said.includes('The burners have given out.') && said.includes('there is no heat for the cone'), `told once (${said.slice(0, 120)})`);
  check(p.f.game.fuel === fuel && p.f.game.hull < hull, `no propane burnt, and sinking (lift ${hull} to ${p.f.game.hull})`);
  if (p.screen === 'travel') p.press(1);
  p.press('Make repairs');
  p.press('Service the burners');
  check(p.f.game.sails > 0.4 && p.f.game.sailcloth === 0, `the kit fitted (${p.f.game.sails})`);
  if (p.screen === 'message') readOn(p);
  if (p.screen === 'repairs') p.press('Done');
  check(p.screen === 'seaMenu' && !statusRows(p).Balloon, `and nothing wrong in the box (${p.screen}: ${JSON.stringify(statusRows(p).Balloon)})`);
  const f2 = p.f.game.fuel;
  p.press('Continue the flight');
  p.timers.fire();
  check(p.f.game.fuel < f2, `burning again (${f2 - p.f.game.fuel} gallons)`);
  noProblems(p);
});

await test('burners dead with no kit: she drifts on to a field, its director won\'t relaunch her, and its burner man overhauls them', async () => {
  const p = await balloonAt((s) => Object.assign(s, { sails: 0, sailcloth: 0, timber: 8, money: 5000, mile: mileOf('jod') - 150 }));
  p.press('Continue the flight');
  const watches = flyUntil(p, (q) => q.screen === 'portMenu');
  check(p.screen === 'portMenu' && p.f.v.currentStop === 'jod' && watches > 1, `drifted in to Jodhpur (${p.screen}, ${watches} watches)`);
  check(statusRows(p).Balloon?.value === 'Burners dead', `on the ground, the box says burners dead (${statusRows(p).Balloon?.value})`);
  check(p.labels().includes('Relaunch (on the helium alone)'), `no climb to burn propane on (${p.labels().join('/')})`);
  p.say(p.words.leavePort);
  check(p.screen === 'message' && p.f.screen.text === "The launch director won't let you go up on dead burners. The riggers' burner man can overhaul them first.",
    `refused (${p.f.screen.text})`);
  p.press(1);
  p.say(p.words.yard);
  p.press('Overhaul the burners');
  readOn(p);
  if (p.screen === 'shipyard') p.press('Back to the field');
  check(p.f.game.sails > 0 && !statusRows(p).Balloon && p.labels().includes('Relaunch (25 gallons)'), `overhauled (${p.f.game.sails})`);
  noProblems(p);
});

await test('burners dead on the ground with no money: she goes up on the helium alone, burning nothing, and the kit goes in aloft (D17)', async () => {
  const p = await balloonAt((s) => { onField('jod')(s); Object.assign(s, { sails: 0, sailcloth: 1, money: 0 }); });
  check(p.f.skin.words(p.f.v).leaveRefusal === null, 'no refusal without the overhaul\'s price');
  check(p.f.skin.words(p.f.v).paceNow.endsWith('[red]Not on dead burners: she can only go up on the helium, and drift.[/red]'), 'the altitude screen says so');
  const fuel = p.f.game.fuel;
  p.say(p.words.leavePort);
  check(p.screen === 'travel', `up she goes (${p.screen})`);
  p.timers.fire();
  const said = plain(readOn(p));
  check(said.startsWith('She goes up on dead burners.') && said.includes('The crew can fit a burner kit now that she is up.'), `told first (${said.slice(0, 100)})`);
  check(p.f.game.fuel === fuel, `burning nothing (${fuel} to ${p.f.game.fuel})`);
  if (p.screen === 'travel') p.press(1);
  p.press('Make repairs');
  p.press('Service the burners');
  check(p.f.game.sails > 0, 'the kit in aloft');
  noProblems(p);
});

await test('tanks dry: sinking, a field sells propane, and with an empty purse the ground team puts in the climb', async () => {
  const p = await balloonAt((s) => Object.assign(s, { fuel: 0 }));
  check(statusRows(p).Balloon?.value === 'Tanks dry, sinking' && statusRows(p).Propane.value === '0 gal', `the box says tanks dry (${JSON.stringify(statusRows(p).Propane)})`);
  check(p.f.skin.words(p.f.v).suppliesNote.includes('the tanks are dry'), 'and the supplies note');
  const hull = p.f.game.hull;
  p.press('Continue the flight');
  p.timers.fire();
  readOn(p);
  check(p.f.game.hull < hull, `sinking on the helium (lift ${hull} to ${p.f.game.hull})`);
  noProblems(p);

  const m = await balloonAt((s) => { onField('lux')(s); s.fuel = 0; });
  check(statusRows(m).Balloon?.value === 'Tanks dry', 'on the ground, the box says tanks dry');
  m.say(m.words.leavePort);
  check(m.screen === 'message' && m.f.screen.text === 'You need at least 25 gallons of propane to relaunch. The ground crew points at the fuel truck.',
    `refused (${m.f.screen.text})`);
  m.press(1);
  m.say(m.words.buy);
  m.topUp({ fuel: 500 });
  m.press('Pay');
  check(m.f.game.fuel === 500 && !statusRows(m).Balloon, `propane bought at Luxor (${m.f.game.fuel})`);
  noProblems(m);

  const b = await balloonAt((s) => { onField('lux')(s); Object.assign(s, { fuel: 0, money: 0 }); });
  check(b.f.skin.words(b.f.v).leaveRefusal === null, 'with an empty purse, no refusal');
  b.say(b.words.leavePort);
  b.timers.fire();
  const said = readOn(b);
  check(said.includes('On the sponsor\'s account') && said.includes('Relaunched.') && said.includes('The last propane tank sputters dry!'),
    `the ground team puts in the climb (${said.slice(0, 120)})`);
  check(b.f.game.fuel === 0, 'and she leaves with an empty tank');
  noProblems(b);
});

await test('the last of the propane heats its share of a watch', async () => {
  const fair = J0.weathers.find((w) => w.rawValue === 'steady');
  const p = await balloonAt((s) => Object.assign(s, { fuel: 4, weather: fair }));
  check(statusRows(p).Balloon?.value === 'Last of the propane', `the box says so (${statusRows(p).Balloon?.value})`);
  const hull = p.f.game.hull;
  p.press('Continue the flight');
  p.timers.fire();
  const part = hull - p.f.game.hull;
  check(p.f.game.fuel === 0, 'it is all burnt');
  const q = await balloonAt((s) => Object.assign(s, { fuel: 0, weather: fair }));
  const from = q.f.game.hull;
  q.press('Continue the flight');
  q.timers.fire();
  check(part > 0 && part < from - q.f.game.hull, `and she sinks less than in a watch with none (${part}, ${from - q.f.game.hull})`);
  readOn(p);
  readOn(q);
  noProblems(p);
  noProblems(q);
});

await test('going down: ballast, a propane cylinder, or a field\'s ground team, in that order', async () => {
  const p = await balloonAt((s) => Object.assign(s, { hull: 0.3 }));
  check(statusRows(p).Balloon?.value === 'Going down' && statusRows(p).Balloon.color === 'red', 'the box says going down');
  const mile = p.f.game.mile;
  p.press('Continue the flight');
  p.timers.fire();
  check(choiceKey(p) === 'sinking' && p.f.game.mile === mile, `asked before another watch is flown (${p.screen})`);
  check(p.labels().join('/') === 'Cut away a sack of ballast (have 4)/Cut away a propane cylinder: 50 gallons (have 900 gallons)',
    `ballast first, then propane (${p.labels().join('/')})`);
  check(wordsOn(p.look()).startsWith('She is going down.') && p.look().blocks.some((b) => b.markup?.startsWith('[red]She is going down.[/red]'))
    && wordsOn(p.look()).includes('sinking toward the sea'), 'in red, over the sea');
  p.press('Cut away a sack of ballast');
  check(p.f.game.timber === 3 && Math.round(p.f.game.hull) > 0, `ballast over the side (${p.f.game.hull})`);
  noProblems(p);

  const d = await balloonAt((s) => Object.assign(s, { hull: 0.3 }));
  d.press('Continue the flight');
  d.timers.fire();
  d.press('Cut away a propane cylinder');
  const said = readOn(d);
  check(d.f.game.fuel <= 850 && said.includes('cuts a propane cylinder loose, fifty gallons and all'), `a cylinder over the side (${d.f.game.fuel})`);
  noProblems(d);

  const m = await balloonAt((s) => { overField('jod')(s); Object.assign(s, { hull: 0.3, timber: 0, money: 5000 }); });
  m.press('Continue the flight');
  m.timers.fire();
  check(choiceKey(m) === 'sinking' && m.labels()[2] === 'Come down on the field at Jodhpur', `the field's third answer (${m.labels().join('/')})`);
  check(m.look().choices.map((c) => c.enabled).join() === 'false,true,true', 'no ballast to cut away');
  check(wordsOn(m.look()).includes('settling toward the field at Jodhpur'), 'over the field at Jodhpur');
  m.press('Come down on the field');
  readOn(m);
  check(m.screen === 'portMenu' && m.f.game.atPort, `down to the ground team (${m.screen})`);
  check(statusRows(m).Balloon?.value === 'No lift', `still with no lift (${statusRows(m).Balloon?.value})`);
  m.say(m.words.leavePort);
  check(m.screen === 'message' && m.f.screen.text.startsWith("The launch director won't let you go up with no lift in her."), 'not up again with no lift');
  m.press(1);
  m.say(m.words.yard);
  m.press('Top up the helium');
  readOn(m);
  if (m.screen === 'shipyard') m.press('Back to the field');
  check(m.f.game.hull > 50 && !statusRows(m).Balloon, `the helium topped up (${m.f.game.hull})`);
  noProblems(m);

  const n = await balloonAt((s) => Object.assign(s, { hull: 0.3, timber: 0 }));
  n.press('Continue the flight');
  n.timers.fire();
  check(n.look().choices.map((c) => c.enabled).join() === 'false,true', 'with no ballast, only propane');
  noProblems(n);
});

// MARK: - Leaving mid-trouble

await test('left on the question going down, the question and the plight come back', async () => {
  const storage = new MemoryStorage();
  const p = await balloonAt((s) => Object.assign(s, { hull: 0.3 }), { storage });
  p.press('Continue the flight');
  p.timers.fire();
  check(choiceKey(p) === 'sinking', 'going down');
  const save = saveOf(storage);
  check(save && Array.isArray(save.pending) && JSON.stringify(save.pending[0]) === JSON.stringify(p.f.showing), 'saved with the question on screen');
  const q = await airPlayer({ engine: e2, storage, seeds: ['99'], random: lcg(99) });
  q.press('Continue the flight of the');
  check(screenWords(q.f) === screenWords(p.f), 'the question comes back as it was');
  q.press('Cut away a propane cylinder');
  p.press('Cut away a propane cylinder');
  check(screenWords(q.f) === screenWords(p.f), 'the same answer after coming back');
  noProblems(p);
  noProblems(q);
});

await test('left with the burners dead and the tanks dry, the plight comes back with the flight', async () => {
  const storage = new MemoryStorage();
  const p = await balloonAt((s) => Object.assign(s, { sails: 0, fuel: 0, timber: 8 }), { storage });
  check(statusRows(p).Balloon?.value === 'Burners dead, tanks dry', 'both');
  p.press('Continue the flight');
  p.timers.fire();
  readOn(p);
  if (p.screen === 'travel') p.press(1);
  const { mile, day } = p.f.game;
  p.press('Save and return to the title');
  const q = await airPlayer({ engine: e2, storage, seeds: ['98'], random: lcg(98) });
  q.press('Continue the flight of the');
  check(q.screen === 'seaMenu' && q.f.game.mile === mile && q.f.game.day === day, 'where she was');
  check(statusRows(q).Balloon?.value === 'Burners dead, tanks dry', `and as she was (${statusRows(q).Balloon?.value})`);
  check(storage.getItem('horn.save-airship') === null && storage.getItem('horn.save-horn1849') === null, 'in the flight\'s own save');
  noProblems(p);
  noProblems(q);
});

await test('left on the ground with dead burners, she comes back on the field, refused as before', async () => {
  const storage = new MemoryStorage();
  const p = await balloonAt((s) => { onField('saga')(s); Object.assign(s, { sails: 0, money: 5000 }); }, { storage });
  p.say(p.words.leavePort);
  const refusal = p.f.screen.text;
  p.press(1);
  p.press('Save and return to the title');
  const q = await airPlayer({ engine: e2, storage, seeds: ['97'], random: lcg(97) });
  q.press('Continue the flight of the');
  check(q.screen === 'portMenu' && q.f.game.atPort && q.f.v.currentStop === 'saga', `on the field at Saga (${q.screen})`);
  check(statusRows(q).Balloon?.value === 'Burners dead' && q.look().blocks.some((b) => plain(b.markup ?? b.text ?? '').includes('Saga')),
    `burners dead, at Saga (${statusRows(q).Balloon?.value})`);
  q.say(q.words.leavePort);
  check(q.screen === 'message' && q.f.screen.text === refusal && refusal.includes('dead burners'), `refused as before (${q.f.screen.text})`);
  noProblems(p);
  noProblems(q);
});

console.log(`balloon: ${passed} checks passed, ${failures.length} failed`);
for (const f of failures) console.log(`FAILED ${f}`);
process.exit(failures.length ? 1 : 0);
