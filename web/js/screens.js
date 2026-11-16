// What each screen shows and offers: the app's SwiftUI views (AroundTheHorn/UI/Screens),
// as plain descriptions with no DOM. ui.js draws them; a test reads them, and presses
// their choices as a player would.
//
// `describe(flow)` gives `{ banner, blocks, choices, keys }`. A block is one piece of the
// screen (`{ type: 'para', markup }`, `{ type: 'status', … }`, …); a choice is a numbered
// button `{ label, detail, enabled, primary, act(input) }`, its label in markup; `input`
// holds what the screen's text fields say. `keys` is false where digits belong to a field.
//
// Which strings are markup follows the app: paragraphs, messages, choices and row labels
// are; headings, names and values are plain text.

import { escape, formatNumber, fixed2, jsRounded, monthNames } from './markup.js';
import * as Stores from './stores.js';
import { reward } from './fishing.js';

/** AppInfo.displayName: the banner while a journey is being picked. */
export const APP_NAME = 'Around the Horn';

const choice = (label, act, o = {}) => ({ label, act, detail: o.detail ?? null, enabled: o.enabled ?? true,
  primary: o.primary ?? false });
const heading = (text) => ({ type: 'heading', text });
const para = (markup, size = 22, color = null) => ({ type: 'para', markup, size, color });
const message = (markup) => ({ type: 'message', markup });
const scene = (moving = false) => ({ type: 'scene', moving });
const row = (label, value, color = null, pad = false) => ({ type: 'row', label, value, color, pad });
/** A row with room above and below, as the supplies list and the score have them. */
const spaced = (label, value) => row(label, value, null, true);
const bar = (value) => ({ type: 'bar', value });

const percent = (x) => `${jsRounded(x)}%`;

/** The way out of setting up a voyage, at the foot of each setup screen, when there is a picker. */
function wayBack(c) {
  return c.hasPicker ? [choice('Back to the title', () => c.goToTitle())] : [];
}

/** The way out of a voyage, at the foot of both menus, on the same terms. */
function wayOut(c) {
  return c.hasPicker ? [choice('Save and return to the title', () => c.leaveVoyage())] : [];
}

export function stopByID(J, id) {
  return id == null ? null : J.stops.find((s) => s.id === id) ?? null;
}

/** The weather that reads in red: the hardest on the crew the journey has (`Weather.harsh`). */
export function isWorst(w, J) {
  return w.harsh > 0 && w.harsh >= Math.max(0, ...J.weathers.map((x) => x.harsh));
}

/** The status box's store rows: food always, water if the journey stocks it, fuel if it burns any. */
export function storeRows(J, g, words) {
  const keys = ['food'];
  if (J.items.some((i) => i.key === 'water')) keys.push('water');
  if (J.burnsFuel) keys.push('fuel');
  return keys.map((key) => {
    const it = J.items.find((i) => i.key === key);
    return { label: words.statusNames[key] ?? it.name, value: Stores.amount(it, g, words) };
  });
}

/** StatusPanel: date and region, weather, health, stores, next stop, distance, meters, note. */
export function status(c) {
  const J = c.journey, v = c.v, g = v.state, words = c.skin.words(v);
  const next = stopByID(J, v.nextStop);
  const rows = [
    row('Weather', g.weather.name, isWorst(g.weather, J) ? 'red' : null),
    row('Health', v.healthLabel, v.healthColor),
    ...storeRows(J, g, words).map((r) => row(r.label, r.value)),
    row(`Next: ${next?.short ?? '—'}`, next ? `${words.distance(next.mile - g.mile)} ${words.distanceUnit}` : ''),
    row(words.travelled, `${words.distance(g.mile)} of ${words.distance(J.totalMiles)} ${words.distanceUnit}`),
    row(`${words.meters[0]} · ${words.meters[1]}`, `${percent(g.hull)} · ${percent(g.sails)}`),
  ];
  if (words.clock) rows.push(row(words.clock.label, words.clock.value));
  if (words.trouble) rows.push(row(words.trouble.label, words.trouble.value, 'red'));
  return { type: 'status', date: v.dateText, region: v.region.name, rows, note: g.note };
}

function conditionBox(g, meters) {
  return { type: 'box', blocks: [row(meters[0], percent(g.hull)), bar(g.hull), row(meters[1], percent(g.sails)), bar(g.sails)] };
}

/** A crew member's state, under their name on the supplies screen. */
export function condition(p) {
  if (p.ailment) return p.ailment.rawValue + (p.treated ? ' · treated' : '');
  return p.hp > 70 ? 'healthy' : p.hp > 40 ? 'weary' : 'very weak';
}

function graves(list, headingText) {
  if (!list.length) return [];
  return [heading(headingText), ...list.map((gr) => ({ type: 'grave', name: gr.name, rest: ` — ${gr.cause}, ${gr.date}`,
    epitaph: `“${gr.epitaph}”` }))];
}

const memo = new WeakMap();
/** Something worth working out once per screen shown, not on every redraw. */
function once(c, key, f) {
  let m = memo.get(c.screen);
  if (!m) memo.set(c.screen, (m = {}));
  if (!(key in m)) m[key] = f();
  return m[key];
}

export function describe(c) {
  const s = c.screen;
  const J = c.journey, skin = c.skin, card = skin.card;
  const v = c.v, g = c.game;
  const words = v ? skin.words(v) : null;
  const banner = s.name === 'picker' ? APP_NAME.toUpperCase() : card.banner;
  let blocks = [];
  let choices = [];
  let keys = true;

  switch (s.name) {
    case 'picker':
      blocks = [heading('Choose a journey')];
      choices = c.journeys.map((j) => choice(j.title + (c.inProgress.has(j.id) ? ' [amber]· in progress[/amber]' : ''),
        () => c.chooseJourney(j.id), { detail: j.subtitle }));
      break;

    case 'title': {
      const saved = once(c, 'saved', () => c.savedVoyage);
      blocks = [
        scene(),
        { type: 'title', text: card.title, label: J.title },
        { type: 'center', text: card.year, color: 'amber' },
        { type: 'center', text: card.tagline, color: 'dim' },
      ];
      choices = [
        choice(card.start, () => c.startNewGame()),
        ...(saved ? [choice(card.resume(escape(saved.ship)), () => c.continueSavedVoyage())] : []),
        choice(card.learn, () => c.show({ name: 'learn', page: 0 })),
        choice('See the top ten', () => c.show({ name: 'topTen', highlight: null, back: () => c.goToTitle() })),
        ...(c.hasPicker ? [choice('Choose another journey', () => c.goToPicker())] : []),
      ];
      break;
    }

    case 'learn': {
      const pages = card.learnPages;
      const page = Math.min(s.page, pages.length - 1);
      const p = pages[page];
      blocks = [heading(p.heading), ...p.paragraphs.map((x) => para(x))];
      choices = [page < pages.length - 1
        ? choice('Next', () => c.show({ name: 'learn', page: page + 1 }))
        : choice('Back to the start', () => c.goToTitle())];
      break;
    }

    case 'role':
      blocks = [heading(card.roleHeading), para(card.roleIntro)];
      choices = [...J.roles.map((r) => choice(r.label, () => c.chooseRole(r.role))),
        choice(card.differencesAction, () => c.show({ name: 'roleDifferences' })), ...wayBack(c)];
      break;

    case 'roleDifferences':
      blocks = [heading(card.differencesHeading), ...card.differences.map((x) => para(x))];
      choices = [choice('Back', () => c.show({ name: 'role' }))];
      break;

    case 'names': {
      const sg = c.suggestions;
      const field = (id, placeholder, maxLength, label) => ({ type: 'field', id, placeholder, maxLength, label });
      blocks = [
        heading(card.namesHeading),
        { type: 'fieldLabel', text: card.vesselPrompt },
        field('ship', sg.ship, 22, card.vesselLabel),
        { type: 'fieldLabel', text: card.leaderPrompt },
        field('captain', sg.crew[0], 16, card.leaderLabel),
        { type: 'fieldLabel', text: card.crewPrompt },
        ...[0, 1, 2, 3].map((i) => field(`crew${i}`, sg.crew[i + 1], 16, `${card.crewLabel} ${i + 1}`)),
      ];
      choices = [
        choice('Use these names', (input = {}) => c.setNames(input.ship ?? '', input.captain ?? '',
          [0, 1, 2, 3].map((i) => input[`crew${i}`] ?? ''))),
        choice('Pick new names for me', () => c.pickNewNames()),
        ...wayBack(c),
      ];
      keys = false;
      break;
    }

    case 'month':
      blocks = [heading(card.monthHeading), para(card.monthIntro)];
      choices = [
        ...J.departures.map((d) => choice(`${monthNames[d.month]} ${d.year}`, () => c.chooseDeparture(d.year, d.month))),
        choice('Ask for advice', () => c.message(card.monthAdvice, () => c.show({ name: 'month' }))),
        ...wayBack(c),
      ];
      break;

    case 'outfit':
      blocks = [heading(card.outfitHeading), para(card.outfitIntro(v)),
        { type: 'box', blocks: card.outfitBullets.map((x) => para(x, 18)) }];
      choices = [choice(card.enterShop, () => c.enterFirstShop()), ...wayBack(c)];
      break;

    case 'message':
      blocks = [scene(), message(s.text)];
      choices = [choice(s.label, () => s.then(), { primary: true })];
      break;

    case 'topTen': {
      const table = once(c, 'table', () => c.persistence.topTen(J));
      blocks = [
        heading('The top ten'),
        ...table.map((r, i) => ({ type: 'place', text: `${i + 1}. ${r.name}`, rank: c.engine.rank(J.id, r.score),
          score: formatNumber(r.score), highlight: s.highlight === i })),
        para(card.rankLegend, 18, 'dim'),
      ];
      choices = [choice('Back', () => s.back())];
      break;
    }

    case 'shop': {
      const sign = words.currency;
      const home = (J.stops.length && J.ports.find((p) => p.id === J.stops[0].id)) || J.ports[0];
      const port = c.shopPort;
      const bill = c.bill;
      const over = bill > g.money;
      blocks = [heading(port.shop)];
      if (port.id !== home.id) blocks.push(para(words.priceNote(jsRounded((port.mult - 1) * 100)), 18, 'dim'));
      blocks.push({ type: 'cash', cash: `${words.cash} ${sign}${formatNumber(g.money)}`, bill: `${sign}${fixed2(bill)}`, over });
      for (const it of J.items) {
        const how = Stores.counting(it, words);
        const have = Stores.have(g[it.key], it, how), qty = s.cart[it.key] ?? 0;
        blocks.push({
          type: 'item', key: it.key, name: it.name,
          price: Stores.priceLabel(it, port.prices[it.key], sign, words.lots.includes(it.key)),
          have: `Have ${have} ${Stores.unit(it, have, how)}. ${it.desc}`,
          // SwiftUI writes an Int in a Text with the thousands grouped: "1,200".
          qty, count: formatNumber(qty), qtyUnit: Stores.unit(it, String(qty), how),
          less: () => c.shopStep(it.key, -1), more: () => c.shopStep(it.key, 1),
        });
      }
      choices = [
        choice(over ? "[red]You can't afford all that[/red]" : bill > 0 ? `Pay ${sign}${fixed2(bill)} and leave` : 'Leave the shop',
          () => c.shopPay(), { enabled: !over, primary: true }),
        ...(bill > 0 ? [choice('Leave without buying', () => c.shopLeave())] : []),
      ];
      break;
    }

    case 'depart':
      blocks = [scene(), message(s.text)];
      choices = [choice(words?.setOut ?? 'Continue', () => c.startTravel(), { primary: true })];
      break;

    case 'travel':
      blocks = [scene(true), ...(g ? [status(c)] : [])];
      choices = [choice(words?.halt ?? 'Continue', () => c.heaveTo(), { primary: true })];
      break;

    case 'seaMenu': {
      const pace = J.paces.find((p) => p.pace === g.pace), rations = J.rations.find((r) => r.rations === g.rations);
      blocks = [scene(), status(c)];
      choices = [
        choice(words.carryOn, () => c.startTravel(), { primary: true }),
        choice(words.supplies, () => c.show({ name: 'supplies' })),
        choice(words.chart, () => c.show({ name: 'chart' })),
        choice(`${words.changePace} [dim](${pace.name})[/dim]`, () => c.show({ name: 'pace' })),
        choice(`${words.changeRations} [dim](${rations.name})[/dim]`, () => c.show({ name: 'rations' })),
        choice(words.rest, () => c.show({ name: 'rest' })),
        choice(words.repairs, () => c.show({ name: 'repairs' })),
        choice(words.forage, () => c.goFishing()),
        ...wayOut(c),
      ];
      break;
    }

    case 'portMenu': {
      const pace = J.paces.find((p) => p.pace === g.pace), rations = J.rations.find((r) => r.rations === g.rations);
      const stop = stopByID(J, v.currentStop);
      blocks = [scene(), status(c), heading(J.ports.find((p) => p.id === v.currentStop)?.name ?? stop.name)];
      choices = [
        choice(words.leavePort, () => c.startTravel(), { primary: true }),
        choice(words.supplies, () => c.show({ name: 'supplies' })),
        choice(words.chart, () => c.show({ name: 'chart' })),
        choice(`${words.changePace} [dim](${pace.name})[/dim]`, () => c.show({ name: 'pace' })),
        choice(`${words.changeRations} [dim](${rations.name})[/dim]`, () => c.show({ name: 'rations' })),
        choice(words.restInPort, () => c.show({ name: 'rest' })),
        choice(words.trade, () => c.trade()),
        choice(words.talk, () => c.talk()),
        choice(words.buy, () => c.buySupplies()),
        choice(words.yard, () => c.show({ name: 'shipyard' })),
        ...wayOut(c),
      ];
      break;
    }

    case 'choice': {
      const e = s.event;
      blocks = [scene(), message(e.prompt), ...(e.detail != null ? e.detail.split('\n\n').map((x) => para(x)) : [])];
      choices = e.options.map((o, i) => choice(o.label, () => c.choose(e, i), { enabled: o.enabled }));
      break;
    }

    case 'burial': {
      const name = escape(g?.crew.find((p) => p.id === s.crewID)?.name ?? '');
      blocks = [scene(), message(`[red]${name} has died of ${s.cause}.[/red]`),
        ...(words ? [para(words.burial(name))] : []),
        { type: 'field', id: 'epitaph', placeholder: J.text.defaultEpitaph, maxLength: 70, label: 'Epitaph', sentences: true }];
      choices = [choice(words?.commit ?? 'Continue', (input = {}) => c.bury(s.crewID, s.cause, input.epitaph ?? ''),
        { primary: true })];
      keys = false;
      break;
    }

    case 'supplies': {
      const living = g.crew.filter((p) => p.alive);
      blocks = [
        heading('Supplies'),
        spaced(words.cash, `${words.currency}${formatNumber(g.money)}`),
        ...J.items.map((it) => spaced(words.storeNames[it.key] ?? it.name, Stores.amount(it, g, words))),
        heading(words.vesselHeading),
        row(words.meters[0], percent(g.hull)), bar(g.hull),
        row(words.meters[1], percent(g.sails)), bar(g.sails),
        para(words.suppliesNote, 18, 'dim'),
        heading(words.crewHeading),
        ...living.map((p) => ({ type: 'crew', name: p.name, tag: p.isCaptain ? ` (${words.leaderTag})` : '',
          condition: condition(p), ailing: !!p.ailment, hp: p.hp })),
        ...(words.clothesWarning ? [para(words.clothesWarning, 18)] : []),
        ...(g.graves.length ? [heading('Lost'), ...g.graves.map((gr) => ({ type: 'small', text: `${gr.name} — ${gr.cause}, ${gr.date}` }))] : []),
      ];
      choices = [choice('Back', () => c.backToMenu())];
      break;
    }

    case 'chart': {
      const chart = skin.chart;
      blocks = [
        heading(chart.title),
        { type: 'chart', label: chart.label(v) },
        { type: 'legend', items: J.stops.map((st, i) => {
          const passed = i <= g.stopIndex, next = i === g.stopIndex + 1;
          return { text: `${passed ? '✓' : next ? '►' : '·'} ${st.short}`, color: passed ? 'amber' : next ? null : 'dim',
            label: `${st.short}, ${passed ? 'passed' : next ? 'next' : 'ahead'}` };
        }) },
        para(chart.footer(v), 18, 'dim'),
      ];
      choices = [choice('Back', () => c.backToMenu())];
      break;
    }

    case 'pace':
      blocks = [heading(words.paceHeading), para(words.paceNow)];
      choices = J.paces.map((p) => choice(p.name, () => c.setPace(p.pace), { detail: p.desc }));
      break;

    case 'rations':
      blocks = [heading(words.rationsHeading), para(words.rationsNow)];
      choices = J.rations.map((r) => choice(r.name, () => c.setRations(r.rations), { detail: r.desc }));
      break;

    case 'rest':
      blocks = [scene(), para(words.restPrompt)];
      choices = [...J.rules.restChoices.map((n) => choice(words.restChoice(n), () => c.rest(n))),
        choice('Never mind', () => c.backToMenu())];
      break;

    case 'repairs':
      blocks = [scene(), heading(words.repairsHeading), conditionBox(g, words.meters), para(words.repairsNote, 18, 'dim')];
      choices = [
        choice(words.mend, () => c.mendSails(), { enabled: v.canMendSails }),
        choice(words.patch, () => c.patchHull(), { enabled: v.canPatchHull }),
        choice('Done', () => c.backToMenu()),
      ];
      break;

    case 'shipyard':
      blocks = [scene(), heading(words.yardHeading), conditionBox(g, words.meters), para(words.yardIntro)];
      choices = [
        choice(words.yardHull(v.shipyardHullCost), () => c.repairHullAtYard(), { enabled: v.canRepairHullAtYard }),
        choice(words.yardSails(v.shipyardSailsCost), () => c.recutSailsAtYard(), { enabled: v.canRecutSailsAtYard }),
        choice(words.leaveYard, () => c.backToMenu()),
      ];
      break;

    case 'fishing': {
      const forage = skin.forage, m = s.model;
      const rw = reward(J, words);
      const role = J.roles.find((r) => r.role === g.role);
      blocks = [
        heading(forage.heading),
        { type: 'tally', items: [`${forage.throwsLabel}: ${g.tackle}`, `${forage.caughtLabel}: ${rw.measure(m.caught)}`,
          `${forage.timeLabel}: ${Math.ceil(Math.max(0, m.time))}`] },
        { type: 'fishing', label: forage.label(m.fish.length), hint: forage.actionHint },
        para(forage.hint(rw.measure(role.catchLimit)), 18, 'dim'),
      ];
      choices = [choice(forage.leave, () => c.fishingFinish())];
      break;
    }

    case 'finale': {
      const f = s.finale, sc = f.score;
      blocks = [
        scene(), message(words.arrival), para(words.arrivalBody), heading('Your score'),
        ...sc.lines.map((l) => spaced(l.label, formatNumber(l.points))),
        spaced('Subtotal', formatNumber(sc.subtotal)),
        spaced(words.bonus, `×${sc.multiplier}`),
        { type: 'rule' },
        { ...row('Final score', formatNumber(sc.total)), total: true },
        { type: 'center', text: `Rank: ${f.rank}${f.place != null ? ` · #${f.place + 1} in the top ten!` : ''}`, color: 'amber' },
        ...graves(g.graves, words.lostHeading),
      ];
      choices = [
        choice(words.again, () => c.goToTitle(), { primary: true }),
        choice('See the top ten', () => c.show({ name: 'topTen', highlight: f.place,
          back: () => c.message(words.thanks, () => c.goToTitle(), words.again) })),
      ];
      break;
    }

    case 'gameOver':
      blocks = [scene(), message(`[red]${s.title}[/red]`), para(s.body),
        ...(g ? [para(words.gameOverLine, 22, 'dim'), ...graves(g.graves, words.lostHeading)] : [])];
      choices = [choice('Try again', () => c.goToTitle(), { primary: true })];
      break;

    default:
      throw new Error(`no such screen: ${s.name}`);
  }
  return { banner, blocks, choices, keys };
}

/** Every string a player reads on a description, with whether it is markup. */
export function texts(d) {
  const out = [{ text: d.banner, markup: false }];
  const walk = (b) => {
    for (const [k, val] of Object.entries(b)) {
      if (k === 'type' || k === 'id' || k === 'color' || k === 'key') continue;
      if (typeof val === 'string') out.push({ text: val, markup: k === 'markup' || (b.type === 'row' && k === 'label') });
      else if (Array.isArray(val)) val.forEach((x) => (typeof x === 'string' ? out.push({ text: x, markup: false }) : walk(x)));
      else if (val && typeof val === 'object') walk(val);
    }
  };
  d.blocks.forEach(walk);
  for (const ch of d.choices) {
    out.push({ text: ch.label, markup: true });
    if (ch.detail != null) out.push({ text: ch.detail, markup: true });
  }
  return out;
}
