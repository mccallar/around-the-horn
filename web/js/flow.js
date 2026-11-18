// The game's flow: which journey is on the table, the voyage in hand, which screen is
// showing, the queue of interrupts being presented, and the travel loop that takes one
// turn every 0.7 s. A line-for-line port of the app's GameController (and its menus and
// Persistence), driving the engine in horn.wasm through engine.js.
//
// No DOM: the screens are described by screens.js and drawn by ui.js, and a test can
// drive a whole voyage here in Node. Time comes from `timers` and chance from `random`
// and `seed`, so a test can hold all three.

import { newSeed } from '../engine.js';
import { offered } from './journeys/skins.js';
import { popText, reward, FishingModel } from './fishing.js';

/** One save and one top ten per journey, in the browser's localStorage (spec §11). */
export class Persistence {
  constructor(storage) {
    this.storage = storage;
  }

  saveKey(id) { return `horn.save-${id}`; }
  topTenKey(id) { return `horn.topten-${id}`; }

  get(key) {
    try {
      return this.storage.getItem(key);
    } catch {
      return null;
    }
  }

  set(key, value) {
    try {
      this.storage.setItem(key, value);
    } catch (e) {
      console.error('save failed:', e);
    }
  }

  remove(key) {
    try {
      this.storage.removeItem(key);
    } catch {
      // Nothing to remove.
    }
  }

  /** The save as the app writes it: the voyage's keys and, when anything is waiting, `pending`. */
  save(id, saveObject) {
    if (saveObject.over) return;
    this.set(this.saveKey(id), JSON.stringify(saveObject));
  }

  /** The save in the store, parsed, or null. Whether the engine will take it is `Flow.peek`'s. */
  raw(id) {
    const text = this.get(this.saveKey(id));
    if (!text) return null;
    try {
      const s = JSON.parse(text);
      return s && typeof s === 'object' && !Array.isArray(s) ? s : null;
    } catch {
      return null;
    }
  }

  deleteSave(id) {
    this.remove(this.saveKey(id));
  }

  topTen(J) {
    const text = this.get(this.topTenKey(J.id));
    if (text) {
      try {
        const t = JSON.parse(text);
        if (Array.isArray(t) && t.length && t.every((r) => typeof r?.name === 'string' && Number.isInteger(r?.score))) return t;
      } catch {
        // Unreadable: the journey's own table instead.
      }
    }
    return J.defaultTopTen;
  }

  saveTopTen(id, table) {
    this.set(this.topTenKey(id), JSON.stringify(table));
  }

  get muted() { return this.get('horn.muted') === '1'; }
  set muted(v) { this.set('horn.muted', v ? '1' : '0'); }

  get lastJourney() { return this.get('horn.lastJourney'); }
  set lastJourney(id) { this.set('horn.lastJourney', id); }
}

/** A store that forgets: for Node, and for a browser that won't keep anything. */
export class MemoryStorage {
  constructor() { this.m = new Map(); }
  getItem(k) { return this.m.has(k) ? this.m.get(k) : null; }
  setItem(k, v) { this.m.set(k, String(v)); }
  removeItem(k) { this.m.delete(k); }
}

/** Real time: `every(ms, fn)` calls `fn` every `ms` until cancelled. */
export const realTimers = {
  every(ms, fn) {
    const h = setInterval(fn, ms);
    return { cancel: () => clearInterval(h) };
  },
};

/** An interrupt's kind, as Swift's Codable writes it: `{"message":{"_0":…}}` → "message". */
export const kindOf = (i) => Object.keys(i)[0];

/** A shuffled draw from the journey's names (NameSuggestions). */
export function nameSuggestions(J, random) {
  const pick = (a) => a[Math.floor(random() * a.length)];
  const ship = J.vesselNames.length ? pick(J.vesselNames) : '';
  const names = [...J.firstNames];
  for (let i = names.length - 1; i > 0; i--) {
    const k = Math.floor(random() * (i + 1));
    [names[i], names[k]] = [names[k], names[i]];
  }
  return { ship, crew: [0, 1, 2, 3, 4].map((i) => (names.length ? names[i % names.length] : '')) };
}

export class Flow {
  /**
   * `engine`: from engine.js's `loadEngine`. `storage`: localStorage, or a MemoryStorage.
   * `journey`: an id to open on (the app's `-journey <id>`). `sound(cue)`: plays a cue.
   */
  constructor({ engine, storage = new MemoryStorage(), timers = realTimers, random = Math.random, seed = newSeed,
    journey = null, skins, sound = () => {}, tickInterval = 700 } = {}) {
    this.engine = engine;
    this.persistence = new Persistence(storage);
    this.timers = timers;
    this.random = random;
    this.newSeed = seed;
    this.sound = sound;
    this.tickInterval = tickInterval;
    this.listeners = [];

    const on = offered(engine.journeys(), skins);
    if (!on.length) throw new Error('no journey has a skin');
    this.offered = on;
    this.journeys = on.map((x) => x.journey);

    this.screen = { name: 'title' };
    this.screenID = 0;
    /** The bridge's view of the voyage in hand (`v.state` the GameState), or null. */
    this.v = null;
    this.traveling = false;
    this.muted = this.persistence.muted;
    this.draftRole = 'merchant';
    this.draftNames = { ship: '', captain: '', crew: [] };
    this.queue = [];
    /** The interrupt on screen: taken off the queue, not yet answered. */
    this.showing = null;
    this.after = 'travel';
    this.timer = null;
    this.inProgress = new Set();

    const offer = (id) => (id ? on.find((x) => x.journey.id === id) : undefined);
    const chosen = offer(journey) ?? (on.length > 1 ? offer(this.persistence.lastJourney) : undefined);
    const first = chosen ?? on[0];
    this.journey = first.journey;
    this.skin = first.skin;
    this.suggestions = nameSuggestions(this.journey, random);
    if (!chosen && on.length > 1) this.showPicker();
  }

  get game() { return this.v?.state ?? null; }
  get journeyID() { return this.journey.id; }
  /** With one journey there is nothing to pick, and no way back from its title card. */
  get hasPicker() { return this.journeys.length > 1; }

  /** `fn` is called after anything changes. Returns a way to stop. */
  subscribe(fn) {
    this.listeners.push(fn);
    return () => { this.listeners = this.listeners.filter((f) => f !== fn); };
  }

  changed() {
    for (const f of this.listeners) f(this);
  }

  play(cue) {
    if (!this.muted) this.sound(cue);
  }

  setMuted(m) {
    this.muted = m;
    this.persistence.muted = m;
    if (!m) this.sound('unmute');
    this.changed();
  }

  /** The one place the journey in hand changes. False for a journey not on offer. */
  select(id) {
    const x = this.offered.find((o) => o.journey.id === id);
    if (!x) return false;
    this.journey = x.journey;
    this.skin = x.skin;
    return true;
  }

  showPicker() {
    this.inProgress = new Set(this.journeys.map((j) => j.id).filter((id) => this.peek(id)));
    this.show({ name: 'picker' });
  }

  // MARK: - Navigation

  show(s) {
    this.screen = s;
    this.screenID += 1;
    this.changed();
  }

  message(text, then, label = 'Continue') {
    this.play('message');
    this.show({ name: 'message', text, label, then });
  }

  /** The menu you came from. Saves, as every menu does, with nothing waiting. */
  backToMenu() {
    const g = this.game;
    if (!g) return this.show({ name: 'title' });
    this.queue = [];
    this.showing = null;
    this.save();
    this.show({ name: g.atPort ? 'portMenu' : 'seaMenu' });
  }

  /** One engine call: the reply, with the voyage's view kept. */
  run(method, ...args) {
    const r = this.engine[method](...args);
    if (r && r.view) this.v = r.view;
    this.changed();
    return r;
  }

  /** The voyage, and with it whatever is still waiting to be shown (D10). */
  save() {
    const g = this.game;
    if (g && !g.over) this.persistence.save(this.journeyID, this.engine.save(this.pending));
  }

  /** What the last turn raised and the player has not yet dealt with, in order. */
  get pending() {
    return (this.showing ? [this.showing] : []).concat(this.queue);
  }

  // MARK: - Title and setup

  /**
   * A journey's saved voyage, if the engine will continue it: its state, or null. Only
   * asked with no voyage in hand (the title card, the picker), since the engine holds one
   * voyage at a time.
   */
  peek(id) {
    const save = this.persistence.raw(id);
    if (!save) return null;
    if (this.v) return save.journey === id && !save.over ? save : null;
    try {
      const r = this.engine.load(save, '0', id);
      return r.view.state;
    } catch {
      return null;
    } finally {
      this.engine.close();
    }
  }

  get savedVoyage() { return this.peek(this.journeyID); }

  goToTitle() {
    this.stopTravel();
    this.engine.close();
    this.v = null;
    this.queue = [];
    this.showing = null;
    this.show({ name: 'title' });
  }

  goToPicker() {
    this.goToTitle();
    if (this.hasPicker) this.showPicker();
  }

  chooseJourney(id) {
    if (!this.select(id)) return;
    this.persistence.lastJourney = id;
    this.goToTitle();
  }

  /** Out of a voyage under way to its title card, where it waits to be continued. */
  leaveVoyage() {
    this.stopTravel();
    this.save();
    this.goToTitle();
  }

  startNewGame() {
    this.play('title');
    this.suggestions = nameSuggestions(this.journey, this.random);
    this.show({ name: 'role' });
  }

  /** Starts from a given state on the menu under way (tests and debug starts). */
  loadForDebug(state) {
    if (!this.select(state.journey)) return;
    this.stopTravel();
    this.run('load', state, this.newSeed(), state.journey);
    this.backToMenu();
  }

  /**
   * Back to where the voyage was left: on a menu, or, if it was left with something on
   * screen, on that, with whatever was queued behind it still to come. After those, a
   * menu, not the loop.
   */
  continueSavedVoyage() {
    const save = this.persistence.raw(this.journeyID);
    let r;
    try {
      r = save && this.run('load', save, this.newSeed(), this.journeyID);
    } catch {
      r = null;
    }
    if (!r) return this.goToTitle();
    const s = this.game;
    const waiting = [...r.pending];
    // A voyage standing on its last stop has arrived and not yet been told so.
    const ends = waiting.some((i) => kindOf(i) === 'arrival' || kindOf(i) === 'finale');
    if (this.v.nextStop == null && !ends) waiting.push({ arrival: { stopID: this.v.currentStop } });
    // Saved in the first port's stores, or beside them, before it set out: back to them,
    // if the skin says so, so that it can only leave through `depart`.
    if (!waiting.length && Flow.notYetLeft(s) && this.skin.words(this.v).resumesInFirstShop) return this.enterFirstShop();
    if (!waiting.length) return this.backToMenu();
    this.present(waiting, s.atPort ? 'portMenu' : 'seaMenu');
  }

  /** Still at the first port with no turn taken: `depart` has not let it go. */
  static notYetLeft(s) { return s.atPort && s.stopIndex === 0 && s.day === 0; }

  chooseRole(r) {
    this.draftRole = r;
    this.suggestions = nameSuggestions(this.journey, this.random);
    this.show({ name: 'names' });
  }

  pickNewNames() {
    this.suggestions = nameSuggestions(this.journey, this.random);
    this.show({ name: 'names' });
  }

  /** Blank fields take their suggestion. */
  setNames(ship, captain, crew) {
    const pick = (typed, suggested, max) => this.engine.name(typed ?? '', suggested, max);
    const s = this.suggestions;
    this.draftNames = {
      ship: pick(ship, s.ship, 22),
      captain: pick(captain, s.crew[0], 16),
      crew: [0, 1, 2, 3].map((i) => pick(crew[i], s.crew[i + 1], 16)),
    };
    this.show({ name: 'month' });
  }

  chooseDeparture(year, month) {
    const d = this.draftNames;
    this.run('start', { journey: this.journeyID, role: this.draftRole, ship: d.ship, captain: d.captain, crew: d.crew,
      year, month, seed: this.newSeed() });
    this.show({ name: 'outfit' });
  }

  /** The shop at the first stop, which leads straight to the departure. */
  enterFirstShop() {
    this.showShop(() => this.depart());
  }

  /** `heeded`: the skin's warning (`words.departWarning`) has been shown and waved off. */
  depart(heeded = false) {
    const why = this.v ? this.skin.words(this.v).departRefusal : null;
    if (why != null) return this.message(why, () => this.enterFirstShop());
    const warn = !heeded && this.v ? this.skin.words(this.v).departWarning : null;
    if (warn) {
      this.play('message');
      return this.show({ name: 'ask', text: warn.text, answers: [
        { label: warn.back, then: () => this.enterFirstShop() },
        { label: warn.go, then: () => this.depart(true) },
      ] });
    }
    const text = this.run('depart').result;
    if (text == null) return this.message(this.journey.text.noProvisions, () => this.enterFirstShop());
    this.show({ name: 'depart', text });
  }

  // MARK: - Travel (spec §2: one turn every 0.7 s)

  /**
   * The port menu's way out: under way, unless the skin says why not yet
   * (`words.leaveRefusal`), and then back to the port menu.
   */
  leavePort() {
    const why = this.v ? this.skin.words(this.v).leaveRefusal : null;
    if (why != null) return this.message(why, () => this.backToMenu());
    this.startTravel();
  }

  /**
   * Under way. A port that holds the party ashore (`Journey.holdInPort`, Lake Bennett
   * before a boat or the ice) says why instead, and the queue decides where it goes next.
   */
  startTravel() {
    const held = this.run('setSail').interrupts ?? [];
    if (held.length) return this.present(held, 'leaving');
    this.traveling = true;
    this.show({ name: 'travel' });
    this.timer?.cancel();
    this.timer = this.timers.every(this.tickInterval, () => {
      if (this.traveling) this.tick();
    });
  }

  stopTravel() {
    this.traveling = false;
    this.timer?.cancel();
    this.timer = null;
  }

  tick() {
    const q = this.run('sailDay').interrupts;
    if (!q.length) return this.save();
    this.stopTravel();
    this.present(q, 'travel');
  }

  heaveTo() {
    this.stopTravel();
    this.backToMenu();
  }

  // MARK: - Interrupts

  /** Shows `q` in order, then goes where `then` says. The save follows the queue. */
  present(q, then) {
    this.queue = [...q];
    this.after = then;
    this.advance();
  }

  advance() {
    this.showing = null;
    if (!this.queue.length) {
      this.save();
      return this.finishQueue();
    }
    const next = this.queue.shift();
    const kind = kindOf(next);
    const x = next[kind] ?? {};
    switch (kind) {
      case 'message':
        this.hold(next);
        return this.message(x._0, () => this.advance());
      case 'choice': {
        this.hold(next);
        const c = x._0;
        this.play(kindOf(c.kind) === 'stranger' ? 'stranger' : 'message');
        return this.show({ name: 'choice', event: c });
      }
      case 'burial':
        this.hold(next);
        this.play('death');
        return this.show({ name: 'burial', crewID: x.crewID, cause: x.cause });
      case 'arrival':
        this.play('arrive');
        this.queue = this.run('beginArrival', x.stopID).interrupts.concat(this.queue);
        return this.advance();
      case 'enterPort':
        this.queue = [];
        return this.backToMenu();
      case 'gameOver':
        this.queue = [];
        this.stopTravel();
        this.persistence.deleteSave(this.journeyID);
        this.play('death');
        return this.show({ name: 'gameOver', title: x.title, body: x.body });
      case 'finale':
        this.queue = [];
        return this.finish();
      default:
        throw new Error(`no such interrupt: ${kind}`);
    }
  }

  /** `i` is on screen until it is answered. Saved with it there. */
  hold(i) {
    this.showing = i;
    this.save();
  }

  choose(c, option) {
    const r = this.run('resolve', c, option).interrupts;
    this.queue = r.concat(this.queue);
    this.advance();
  }

  bury(crewID, cause, epitaph) {
    this.run('commitBurial', crewID, cause, epitaph);
    this.advance();
  }

  finishQueue() {
    const g = this.game;
    if (!g || g.over) return;
    switch (this.after) {
      case 'travel': return this.startTravel();
      case 'seaMenu':
      case 'portMenu': return this.backToMenu();
      case 'repairs': return this.show({ name: 'repairs' });
      case 'shipyard': return this.show({ name: 'shipyard' });
      // Setting out from a port that held the party ashore: under way if the answer let
      // it go, otherwise back to the port menu.
      case 'leaving': return g.atPort ? this.backToMenu() : this.startTravel();
      default: throw new Error(`nowhere to go after the queue: ${this.after}`);
    }
  }

  finish() {
    this.stopTravel();
    const r = this.run('finish');
    this.persistence.deleteSave(this.journeyID);
    const { table, place } = this.engine.topTen(this.journeyID, this.game.crew[0].name, r.score.total,
      this.persistence.topTen(this.journey));
    if (place != null) this.persistence.saveTopTen(this.journeyID, table);
    this.play('win');
    this.show({ name: 'finale', finale: { score: r.score, rank: r.rank, place: place ?? null } });
  }

  // MARK: - Menu actions (each takes time, so each may raise interrupts)

  get menu() { return this.game?.atPort ? 'portMenu' : 'seaMenu'; }

  act(q, then) {
    this.present(q, then);
  }

  setPace(p) {
    this.run('setPace', p);
    this.backToMenu();
  }

  setRations(r) {
    this.run('setRations', r);
    this.backToMenu();
  }

  rest(days) {
    const q = this.run('rest', days).interrupts;
    this.act(q, this.menu);
  }

  mendSails() { this.act(this.run('mendSails').interrupts, 'repairs'); }
  patchHull() { this.act(this.run('patchHull').interrupts, 'repairs'); }
  repairHullAtYard() { this.act(this.run('repairHullAtYard').interrupts, 'shipyard'); }
  recutSailsAtYard() { this.act(this.run('recutSailsAtYard').interrupts, 'shipyard'); }
  trade() { this.act(this.run('tradeAtPort').interrupts, 'portMenu'); }

  talk() {
    const t = this.run('talk').result;
    this.message(t, () => this.backToMenu());
  }

  // MARK: - The shop

  /** A port's shop: a cart per item, which the screen fills; `done` is where paying leads. */
  showShop(done) {
    this.show({ name: 'shop', done, cart: {} });
  }

  /**
   * The port menu's yard row: the yard, unless the skin has a question to ask there
   * instead (`words.yardQuestion`, the engine call that asks it).
   */
  openYard() {
    const ask = this.v ? this.skin.words(this.v).yardQuestion : null;
    if (!ask) return this.show({ name: 'shipyard' });
    this.act(this.run(ask).interrupts, 'portMenu');
  }

  buySupplies() {
    this.showShop(() => this.backToMenu());
  }

  /**
   * The shop's port: the one you are at, as the engine finds it for the way taken
   * (`Journey.port(_:at:)`, the view's `port`), or the first stop's.
   */
  get shopPort() {
    const J = this.journey;
    const home = (J.stops.length && J.ports.find((p) => p.id === J.stops[0].id)) || J.ports[0];
    return this.v.port ?? home;
  }

  /** How many more of an item fit aboard, in the units the shop sells. */
  room(it) {
    return Math.max(0, Math.floor((it.cap - this.game[it.key]) / it.per));
  }

  get bill() {
    return this.engine.bill(this.journeyID, this.shopPort.id, this.screen.cart);
  }

  /** One press of − (`dir` −1) or + (1). False when it can't go further. */
  shopStep(key, dir) {
    const it = this.journey.items.find((i) => i.key === key);
    const cart = this.screen.cart;
    const qty = cart[key] ?? 0;
    if (dir < 0) {
      if (qty <= 0) return false;
      cart[key] = Math.max(0, qty - it.step);
      this.play('shopDown');
    } else {
      const next = Math.min(this.room(it), qty + it.step);
      if (next === qty) return false;
      cart[key] = next;
      this.play('shopUp');
    }
    this.changed();
    return true;
  }

  /** "Pay and leave", or "Leave the shop" with an empty cart. */
  shopPay() {
    const { cart, done } = this.screen;
    if (this.bill > 0) this.run('buy', cart);
    this.save();
    done();
  }

  shopLeave() {
    this.screen.done();
  }

  // MARK: - Fishing

  goFishing() {
    const refusal = this.v.fishingRefusal;
    if (refusal != null) return this.message(refusal, () => this.backToMenu());
    const J = this.journey, forage = this.skin.forage;
    const rw = reward(J, this.skin.words(this.v), forage.grouped);
    const role = J.roles.find((r) => r.role === this.game.role);
    const model = new FishingModel({
      field: forage.field, quarry: J.quarry, seconds: J.forageSeconds, padding: role.aim, pop: popText(forage, rw),
      random: this.random,
      useTackle: () => {
        const ok = this.throwHarpoon();
        if (ok) this.play('harpoon');
        return ok;
      },
      tackleLeft: () => this.game?.tackle ?? 0,
    });
    model.onCatch = () => this.play('fishHit');
    this.show({ name: 'fishing', model, landed: false, now: 0 });
  }

  /** One throw in the mini-game. False when the tackle is gone. */
  throwHarpoon() {
    return this.run('throwHarpoon').result;
  }

  /** The mini-game's clock: `dt` seconds have passed. It lands the catch when it ends. */
  fishingStep(dt) {
    const s = this.screen;
    if (s.name !== 'fishing' || s.landed) return;
    s.model.step(dt);
    s.now += dt;
    if (s.model.ended) this.fishingFinish();
    else this.changed();
  }

  fishingFinish() {
    const s = this.screen;
    if (s.name !== 'fishing' || s.landed) return;
    s.landed = true;
    s.model.stop();
    this.endFishing(s.model.caught);
  }

  endFishing(caught) {
    this.act(this.run('landCatch', caught).interrupts, 'seaMenu');
  }

  // MARK: - Lifecycle

  /** Spec §2: on leaving the page, stop the clock and save; on return, a menu, not the loop. */
  background() {
    const was = this.traveling;
    this.stopTravel();
    this.save();
    if (was) this.backToMenu();
  }
}
