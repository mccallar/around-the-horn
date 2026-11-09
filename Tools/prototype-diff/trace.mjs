// Runs the web prototype's own game logic headless, with Math.random replaced by the
// engine's SplitMix64, and records the state before every sailing day. The Swift test
// `PrototypeParityTests` replays the same voyages through HornEngine and compares.
//
//   node Tools/prototype-diff/trace.mjs > HornEngineTests/Fixtures/prototype-traces.json
//
// Regenerate whenever docs/reference/horn1849.html changes. The prototype itself is
// never edited: its <script> is evaluated as-is in a vm context with the page stubbed.
import fs from 'node:fs';
import vm from 'node:vm';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

process.env.TZ = 'UTC';
const here = path.dirname(fileURLToPath(import.meta.url));
const html = fs.readFileSync(path.join(here, '../../docs/reference/horn1849.html'), 'utf8');
const script = html.match(/<script>([\s\S]*)<\/script>/)[1];
// What the driver buys at every port, in this order, up to these stored amounts: the
// same list PrototypeParityTests uses.
const SHOPPING = [['food', 1500], ['water', 600], ['limes', 10], ['clothes', 5], ['meds', 3], ['sailcloth', 3], ['timber', 3]];
const VOYAGES = JSON.parse(fs.readFileSync(path.join(here, 'voyages.json'), 'utf8'));

function splitmix(seed) {
  let s = BigInt.asUintN(64, BigInt(seed));
  return () => {
    s = BigInt.asUintN(64, s + 0x9E3779B97F4A7C15n);
    let z = s;
    z = BigInt.asUintN(64, (z ^ (z >> 30n)) * 0xBF58476D1CE4E5B9n);
    z = BigInt.asUintN(64, (z ^ (z >> 27n)) * 0x94D049BB133111EBn);
    z = z ^ (z >> 31n);
    return Number(z >> 11n) * 2 ** -53;
  };
}

const strip = s => String(s).replace(/<[^>]*>/g, '').trim();
// The first option of every screen that is a ChoiceEvent in the Swift engine.
const CHOICE_FIRSTS = ['Hail her', 'Let it be', 'Sign them on as cabin hand', 'Shorten sail and pick your way through',
  'Hold the ceremony (1 day)', 'Send a party ashore (2 days)', 'Round Cape Horn', 'Hire the pilot ($75)',
  'Drop anchor and go ashore', 'Accept the trade'];

function runVoyage(v) {
  const timers = [];
  let current = null;
  const elem = () => ({ innerHTML: '', textContent: '', value: '', placeholder: 'Fair winds, shipmate.',
    onclick: null, getContext: () => null, querySelector: () => elem(), querySelectorAll: () => [],
    addEventListener() {}, appendChild() {} });
  const ctx = {
    console, JSON, Math: Object.create(Math), Object, Array, String, Number, BigInt, Date, Set, Map,
    document: { getElementById: elem, createElement: elem, addEventListener() {}, body: { contains: () => false } },
    localStorage: { getItem: k => (k === 'horn_muted' ? '1' : null), setItem() {}, removeItem() {} },
    window: { scrollTo() {} },
    setTimeout: fn => { timers.push(fn); return timers.length; },
    clearTimeout: () => { timers.length = 0; },
    requestAnimationFrame: () => 0, cancelAnimationFrame() {}, performance: { now: () => 0 },
  };
  ctx.Math.random = splitmix(v.seed);
  vm.createContext(ctx);
  vm.runInContext(script, ctx);
  // Every screen goes through `view`; record it instead of drawing it.
  ctx.view = (h, choices = []) => { current = { html: h, choices }; };
  const run = code => vm.runInContext(code, ctx);

  run(`newGame()`);
  run(`G.role=${JSON.stringify(v.role)};G.money=ROLES[G.role].money;G.ship=${JSON.stringify(v.ship)};
       G.crew=${JSON.stringify(v.names)}.map((n,i)=>({name:n,hp:100,ail:null,ailDays:0,treated:false,alive:true,cap:i===0}));
       G.y0=${v.year};G.m0=${v.month};`);
  for (const [k, n] of Object.entries(v.supplies)) run(`G.${k}=${n}`);

  const snaps = [], picks = [];
  const snap = () => snaps.push(JSON.parse(run(`JSON.stringify({day:G.day,mile:G.mile,money:G.money,food:G.food,
    water:G.water,limes:G.limes,meds:G.meds,clothes:G.clothes,sailcloth:G.sailcloth,timber:G.timber,tackle:G.tackle,
    hull:G.hull,sails:G.sails,weather:G.weather,stopIdx:G.stopIdx,passage:G.passage,pilot:G.pilot,noCitrus:G.noCitrus,
    badLuck:G.badLuck,forceFair:G.forceFair,tradesLeft:G.tradesLeft,talkIdx:G.talkIdx,atPort:G.atPort,
    albatross:G.albatross,stowaway:G.stowaway,starving:G.starving,thirst:G.thirst,
    flags:['food','lowfood','water','lowwater','limes','hull','sails'].map(k=>!!G.flags[k]),
    crew:G.crew.map(p=>({name:p.name,hp:p.hp,ail:p.ail,ailDays:p.ailDays,treated:p.treated,alive:p.alive,leave:p.leave||null})),
    graves:G.graves.map(g=>g.name+'|'+g.cause+'|'+g.date+'|'+g.epitaph)})`)));
  const origSail = ctx.sailDay;
  ctx.sailDay = () => { snap(); return origSail(); };

  const G = () => run('G');
  const avgHp = () => run('avgHp()');
  const restedAtSea = new Set();
  let portStep = 0, askedMate = false;
  const needRepair = g => (g.sails < 45 && g.sailcloth > 0) || (g.hull < 45 && g.timber > 0);
  const wantSeaRest = g => avgHp() < 50 && !restedAtSea.has(g.stopIdx);

  run('startTravel()');
  let outcome = 'limit';
  for (let step = 0; step < 20000; step++) {
    const labels = current ? current.choices.map(c => strip(c.label)) : [];
    const click = label => {
      const i = labels.indexOf(label);
      if (i < 0) throw new Error(`no option "${label}" in [${labels.join(' | ')}] (voyage ${v.name})`);
      const c = current.choices[i];
      current = null;
      c.fn();
    };
    const firstEnabled = () => labels[current.choices.findIndex(c => !c.disabled)];
    const g = G();

    if (labels[0] === 'Heave to & take stock') {
      if (v.policy !== 'second' && (needRepair(g) || wantSeaRest(g))) { click(labels[0]); continue; }
      if (!timers.length) throw new Error('travel view with no tick pending');
      const t = timers.shift();
      t();
      continue;
    }
    if (labels[0] === 'Sail again') { outcome = 'finale'; break; }
    if (labels[0] === 'Try again') { outcome = 'gameover'; break; }
    if (labels[0] === 'Continue on your voyage') {
      if (needRepair(g)) click('Make repairs');
      else if (wantSeaRest(g)) { restedAtSea.add(g.stopIdx); click('Heave to and rest'); }
      else click('Continue on your voyage');
      continue;
    }
    if (labels[0] === '1 day') { click(g.atPort ? '2 days' : '3 days'); continue; }
    if (labels[0].startsWith('Mend sails')) {
      const en = l => !current.choices[labels.indexOf(l)].disabled;
      const mend = labels[0], patch = labels[1];
      if (g.sails < 45 && en(mend)) click(mend);
      else if (g.hull < 45 && en(patch)) click(patch);
      else click('Done');
      continue;
    }
    if (labels[0] === 'Weigh anchor and sail on') {
      const plan = ['Rest ashore', 'Attempt to trade', 'Talk to people', 'Visit the shipyard', 'Buy supplies'];
      click(portStep < plan.length ? plan[portStep++] : 'Weigh anchor and sail on');
      continue;
    }
    if (labels[0].startsWith('Haul out')) { click(firstEnabled()); continue; }
    if (labels[0] === 'Leave the shop' || labels[0].startsWith('Pay $') || labels[0].startsWith('You can')) {
      // The shop's +/− buttons are DOM; apply the same cart its Pay button would.
      run(`(()=>{const port=curStop().id,cart=${JSON.stringify(SHOPPING)},bought={};let total=0;
        for(const [k,target] of cart){const i=ITEMS.find(x=>x.k===k);
          const room=Math.max(0,Math.floor((cap(k)-G[k])/i.per));
          let n=Math.min(room,Math.max(0,Math.ceil((target-G[k])/i.per/i.step)*i.step));
          const pr=itemPrice(k,port);
          while(n>0&&total+n*pr>G.money)n-=i.step;
          n=Math.max(0,n);
          bought[k]=n;total+=n*pr}
        const t=ITEMS.reduce((s,i)=>s+(bought[i.k]||0)*itemPrice(i.k,port),0);
        G.money-=t;ITEMS.forEach(i=>add(i.k,(bought[i.k]||0)*i.per));})()`);
      current = null;
      run('portMenu()');
      continue;
    }
    if (CHOICE_FIRSTS.includes(labels[0])) {
      let pick;
      if (labels[0] === 'Round Cape Horn') {
        pick = v.fork;
        if (pick === "Ask the first mate's advice") { if (askedMate) pick = 'Round Cape Horn'; askedMate = true; }
      }
      else if (v.policy === 'second' && labels.length > 1 && !current.choices[1].disabled) pick = labels[1];
      else if (v.policy === 'rotate' && !current.choices[picks.length % labels.length].disabled) pick = labels[picks.length % labels.length];
      else pick = firstEnabled();
      if (labels[0] === 'Drop anchor and go ashore' && pick === labels[0]) portStep = 0;
      picks.push(`${labels[0]} -> ${pick}`);
      click(pick);
      continue;
    }
    if (labels.length === 1) { click(labels[0]); continue; }
    throw new Error(`unhandled screen [${labels.join(' | ')}] in voyage ${v.name}`);
  }
  snap();
  return { ...v, outcome, picks, snaps };
}

const out = VOYAGES.map(runVoyage);
process.stdout.write(JSON.stringify(out));
for (const v of out) process.stderr.write(`${v.name}: ${v.outcome}, ${v.snaps.length - 1} sailing days, ${v.picks.length} choices\n`);
