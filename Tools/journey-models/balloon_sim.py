#!/usr/bin/env python3
"""Balance model of the `balloon` journey (docs/journeys/balloon.md).

A Python re-statement of the spec's rules (§5-§15) and its sensible bot (§18.2), used to
check that the tables put the roles in their bands. It is NOT the engine: Python's RNG is
not the engine's, so no flight here matches a seeded engine flight. The engine's own
BalanceSimulationTests are the authority once the journey is built; this file is evidence
that the numbers are in the right place, and the source of every number in §18.3-§18.4.

    python3 Tools/journey-models/balloon_sim.py report     # every table in §18.3-§18.4
    python3 Tools/journey-models/balloon_sim.py rates      # win rates only
    python3 Tools/journey-models/balloon_sim.py rates --builder 7000   # try a start purse

Section numbers in comments are the spec's. Where the engine's order of operations matters
(what is consumed before what, which region a rule reads), this follows the 1849 engine.
"""
import argparse
import datetime
import math
import random
import statistics
from collections import Counter, defaultdict

# ---------------------------------------------------------------- §2 roles
ROLES = {
    # money, score x, lift per ballast sack, burner points per kit, catch cap, bot hit rate
    'chocolatier': dict(money=15000, mult=1, ballast=20, spares=25, catch=40, hit=0.35),
    'builder': dict(money=6250, mult=2, ballast=30, spares=35, catch=40, hit=0.35),
    'pilot': dict(money=5000, mult=3, ballast=20, spares=25, catch=60, hit=0.55),
}
ROLE_ORDER = ('chocolatier', 'builder', 'pilot')

# ---------------------------------------------------------------- §5 supplies
ITEMS = dict(  # key: (Marrakech price per bought unit, step, per, max bought)
    food=(3.0, 10, 1, 500), water=(0.5, 10, 1, 250), scrub=(25, 1, 1, 30), meds=(100, 1, 1, 12),
    suits=(80, 1, 1, 10), ballast=(60, 1, 1, 20), spares=(140, 1, 1, 20), line=(30, 1, 20, 30),
    fuel=(0.45, 50, 1, 1200))
CAP = {k: v[2] * v[3] for k, v in ITEMS.items()}

# ---------------------------------------------------------------- §6 fields
PORTS = {  # mult, item mods, flu risk
    'mar': (1.0, {}, False),
    'lux': (1.3, dict(fuel=0.8, water=0.7, suits=1.4, spares=1.3), False),
    'jod': (1.35, dict(food=0.7, water=0.8, fuel=1.1, spares=1.4, ballast=0.4), False),
    'saga': (1.6, dict(spares=0.8, food=1.2, scrub=0.9), True),
    'abq': (1.25, dict(spares=0.6, ballast=0.7, fuel=0.9), False),
    'kh': (1.45, dict(fuel=1.1, suits=0.9), True),
}
# On the ground the field's own temperature is used, never the region's (§6, §11). None of
# the six is hot or cold, so on the ground there is no heat water and no heat illness.
FIELD_TEMP = dict(mar='warm', lux='warm', jod='warm', saga='cool', abq='cool', kh='cool')

# ---------------------------------------------------------------- §7 stops
STOPS = [('mar', 'port', 0), ('atlas', 'mark', 100), ('lux', 'port', 2200), ('jod', 'port', 4400),
         ('him', 'special', 5050), ('saga', 'port', 7650), ('pacific', 'fork', 7800),
         ('dateline', 'special', 10050), ('landfall', 'mark', 12600), ('abq', 'port', 13500),
         ('kh', 'port', 15000), ('azores', 'special', 17350), ('finish', 'end', 18300)]

# ---------------------------------------------------------------- §9 weather
W = dict(  # speed x, wear x, harsh hp
    steady=(1.0, .2, 0), jet=(1.45, .35, 0), light=(.55, .1, 0), stalled=(.1, .03, 0),
    sun=(.7, .05, 0), cloud=(.85, .15, 0), snow=(.8, .6, 0), shear=(1.15, 1.2, .6),
    storm=(.4, 2.5, 1.5), dust=(.85, .3, 0))
ROUGH = {'shear', 'storm'}

# ---------------------------------------------------------------- §8 regions
ARABIA_W = [('steady', 30), ('sun', 22), ('light', 16), ('dust', 14), ('jet', 10), ('stalled', 6), ('shear', 2)]
R = [  # to (exclusive), name, temp, flags, ordered weights
    (2200, 'The Sahara', 'warm', set(),
     [('steady', 32), ('jet', 18), ('light', 14), ('sun', 14), ('dust', 12), ('shear', 6), ('stalled', 4)]),
    (3500, 'Arabia', 'hot', set(), ARABIA_W),
    (3800, 'The Gulf of Oman', 'warm', {'sea'},
     [('steady', 34), ('light', 18), ('jet', 14), ('cloud', 12), ('sun', 10), ('stalled', 8), ('storm', 4)]),
    (4400, 'The Indus & the Thar', 'warm', set(), ARABIA_W),
    (5050, 'Northern India', 'cool', {'jet'},
     [('steady', 34), ('jet', 24), ('light', 14), ('cloud', 12), ('shear', 8), ('stalled', 6), ('dust', 2)]),
    (7350, 'The Himalaya & China', 'cold', {'jet', 'high'},
     [('jet', 30), ('steady', 20), ('shear', 18), ('snow', 12), ('cloud', 10), ('storm', 5), ('light', 5)]),
    (7800, 'The East China Sea', 'cool', {'sea', 'jet'},
     [('jet', 26), ('steady', 24), ('cloud', 16), ('shear', 12), ('snow', 8), ('light', 8), ('storm', 6)]),
    (10050, 'The North Pacific', 'cold', {'sea', 'jet', 'high', 'ice'},
     [('jet', 32), ('shear', 22), ('snow', 14), ('storm', 14), ('steady', 10), ('cloud', 8)]),
    (12600, 'The Northeast Pacific', 'cold', {'sea', 'jet'},
     [('jet', 26), ('steady', 20), ('shear', 16), ('cloud', 16), ('snow', 12), ('storm', 6), ('light', 4)]),
    (13500, 'The American Southwest', 'cool', {'jet'},
     [('steady', 30), ('jet', 22), ('light', 14), ('shear', 12), ('dust', 10), ('cloud', 8), ('stalled', 4)]),
    (15000, 'The Great Plains', 'cold', {'jet'},
     [('jet', 26), ('steady', 24), ('shear', 16), ('cloud', 12), ('snow', 10), ('storm', 6), ('light', 6)]),
    (17350, 'The North Atlantic', 'cool', {'sea', 'atlantic'},
     [('steady', 26), ('jet', 22), ('cloud', 16), ('shear', 16), ('storm', 8), ('snow', 6), ('light', 6)]),
    (10 ** 9, 'The Azores & home', 'warm', {'sea'},
     [('steady', 34), ('light', 18), ('jet', 14), ('cloud', 14), ('sun', 8), ('stalled', 8), ('shear', 4)]),
]
SOUTH = [
    (10050, 'The southern track', 'warm', {'sea', 'jet', 'storms'},
     [('steady', 32), ('jet', 20), ('light', 14), ('cloud', 12), ('storm', 10), ('sun', 6), ('stalled', 6)]),
    (12600, 'The subtropical Pacific', 'hot', {'sea', 'jet', 'storms'},
     [('steady', 32), ('jet', 18), ('light', 16), ('sun', 10), ('cloud', 10), ('storm', 8), ('stalled', 6)]),
]

# ---------------------------------------------------------------- §10 altitude & rations
PACE = dict(low=(110, .5, .6, 12), middle=(150, 0, 1, 14), high=(185, -1, 2, 16))  # nm, hp, wear x, gal
RAT = dict(hot=(0.5, 1), half=(0.3, -.3), crackers=(0.2, -2.2))  # lb/person/watch, hp
TEMPF = dict(hot=.85, warm=.95, cool=1.0, cold=1.1, freezing=1.2)

# ---------------------------------------------------------------- §11 ailments
AIL = {'stale air': (2.2, (999, 999)), 'altitude sickness': (3.0, (4, 8)), 'hypothermia': (4.5, (5, 9)),
       'frostbite': (2.5, (6, 12)), 'influenza': (4.5, (6, 11)), 'food poisoning': (4.5, (4, 8)),
       'a fever': (3.0, (4, 7)), 'a broken arm': (1.2, (14, 24)), 'exhaustion': (1.5, (3, 5))}
POOL = dict(
    flu_field=['influenza', 'a fever', 'food poisoning'],
    ground=['influenza', 'food poisoning', 'a fever', 'a broken arm', 'exhaustion'],
    hot=['a fever', 'food poisoning', 'exhaustion', 'influenza', 'altitude sickness'],
    cold=['hypothermia', 'frostbite', 'altitude sickness', 'influenza', 'a broken arm'],
    other=['influenza', 'food poisoning', 'a fever', 'a broken arm', 'exhaustion'])

FISH = [(1, 35), (2, 26), (5, 18), (12, 13), (24, 8)]  # §15: lb, weight

P = dict(onset=18, slope=0.006, loiter=10, relaunch=25, drift_nm=40, empty_lift=5, leak=0.08,
         freeze_warm=1.6, freeze_cold=4.5, cold_nowarm=2.2, event=0.11, strike=0.035, strike_fc=0.008,
         roof=0.02, scrub_use=0.02, water_use=0.2, forecasters=250, bot_hire_above=1500,
         camera_bot_min=50)
DEPARTURES = [(1998, 11), (1999, 0), (1999, 1)]  # the bot's: December, January, February


class Over(Exception):
    pass


class Flight:
    def __init__(s, role, seed, year, month, policy=None):
        s.r = random.Random(seed)
        s.role, s.R, s.pol = role, ROLES[role], policy or {}
        s.start = datetime.datetime(year, month + 1, 1, 8, 0)
        s.money = float(s.R['money'])
        s.st = dict(food=0., water=0., scrub=0., meds=0, suits=0, ballast=0, spares=0, line=0, fuel=0.)
        s.crew = [dict(hp=100., ail=None, ad=0., tr=False, alive=True, cap=i == 0) for i in range(5)]
        s.lift = s.burn = 100.
        s.pace = 'middle'
        s.rat = 'hot' if role == 'chocolatier' else 'half'
        s.t = s.mile = s.si = 0
        s.passage, s.fc = 'north', False
        s.noScr = s.bad = s.ff = 0
        s.w = 'steady'
        s.starv = s.thirst = s.over = False
        s.end = None
        s.ground = True  # on a field
        s.mascot = False
        # instrumentation
        s.spend = Counter()
        s.fuel_burnt = 0.
        s.sponsor = 0
        s.legs = []  # (field id, watch, fuel burnt, lift lost) at each relaunch and arrival
        s.lift_lost = 0.
        s.cond = []  # speed condition factor on each sailing watch
        s.fish_outings = 0
        s.camera = Counter()

    # ------------------------------------------------------------ helpers
    def rnd(s, a, b): return s.r.uniform(a, b)
    def ri(s, a, b): return s.r.randint(a, b)
    def ch(s, p): return s.r.random() < p

    def month(s):
        return (s.start + datetime.timedelta(hours=4 * s.t)).month - 1

    def living(s): return [c for c in s.crew if c['alive']]

    def avg_hp(s):
        l = s.living()
        return sum(c['hp'] for c in l) / len(l)

    def region(s, m=None):
        m = s.mile if m is None else m
        if s.passage == 'south' and 7800 <= m < 12600:
            for r in SOUTH:
                if m < r[0]:
                    return r
        for r in R:
            if m < r[0]:
                return r

    def temp(s, reg):  # §8 effective temperature
        t, mo = reg[2], s.month()
        if 'high' in reg[3] and t == 'cold' and mo in (11, 0, 1):
            t = 'freezing'
        if 'atlantic' in reg[3] and mo in (10, 11, 0, 1, 2):
            t = 'cold'
        return t

    def here_temp(s, mode):
        return FIELD_TEMP[STOPS[s.si][0]] if mode == 'port' else s.temp(s.region())

    def weights(s, reg):  # §8 seasonal rules, in order
        w = list(reg[4])
        mo, fl = s.month(), reg[3]

        def bump(k, f):
            for i, (kk, v) in enumerate(w):
                if kk == k:
                    w[i] = (k, f(v))
                    return
            w.append((k, f(0)))
        if 'jet' in fl and mo == 10:
            bump('jet', lambda x: x * .6); bump('storm', lambda x: x + 6)
        if 'jet' in fl and mo in (2, 3):
            bump('jet', lambda x: x * .5); bump('light', lambda x: x + 12)
            bump('stalled', lambda x: x + 8); bump('storm', lambda x: x + 6)
        if 'atlantic' in fl and mo in (11, 0, 1):
            bump('shear', lambda x: x + 8); bump('storm', lambda x: x + 5)
        if s.bad > 0:
            bump('shear', lambda x: x + 20); bump('storm', lambda x: x + 15); bump('stalled', lambda x: x + 10)
        return w

    def roll(s, reg):
        if s.ff > 0:
            s.ff -= 1
            return 'steady'
        w = s.weights(reg)
        if s.bad > 0:
            s.bad -= 1
        x = s.r.random() * sum(v for _, v in w)
        for k, v in w:
            x -= v
            if x <= 0:
                return k
        return w[0][0]

    def burn_fuel(s, g):
        g = min(g, s.st['fuel'])
        s.st['fuel'] -= g
        s.fuel_burnt += g

    def lose_lift(s, x):
        x = min(x, s.lift)
        s.lift -= x
        s.lift_lost += x

    def check(s):
        if s.lift <= 0 and not s.over:
            s.lift = 0
            s.over = True
            s.end = 'down' + (' (no propane)' if s.st['fuel'] <= 0 else '')
            raise Over

    # ------------------------------------------------------------ §12.5 one watch flying
    def sail(s):
        ns = STOPS[s.si + 1]
        s.t += 1
        reg = s.region()
        s.w = s.roll(reg)
        w = W[s.w]
        n = len(s.living())
        base = PACE[s.pace][0] if s.st['fuel'] > 0 else P['drift_nm']
        cond = (0.45 + 0.55 * s.burn / 100) * (0.75 + 0.25 * s.lift / 100)
        s.cond.append(cond)
        sp = base * w[0] * cond * (1 if n >= 3 else .9 if n == 2 else .75) * s.rnd(.85, 1.15)
        d = max(0, math.floor(sp + 0.5))
        arrived = s.mile + d >= ns[2]
        if arrived:
            d = ns[2] - s.mile
        s.mile += d
        s.consume('sail')
        s.health('sail')
        s.wear(reg)
        if not arrived:
            if 'storms' in reg[3] and s.ch(P['strike_fc'] if s.fc else P['strike']):
                s.lose_lift(s.ri(15, 35))
                s.t += 1
                s.burn_fuel(PACE[s.pace][3] * TEMPF[s.temp(s.region())])
                s.w = 'storm'
                s.check()
            elif 'ice' in reg[3] and s.ch(P['roof']):
                s.roof()
            elif s.ch(P['event']):
                s.event(reg)
        if arrived:
            s.si += 1
            s.arrive(ns)

    # ------------------------------------------------------------ §12.2 consume
    def consume(s, mode):
        n = len(s.living())
        t = s.here_temp(mode)
        f = n * RAT[s.rat][0]
        if s.st['food'] >= f:
            s.st['food'] -= f; s.starv = False
        else:
            s.st['food'] = 0; s.starv = True
        wn = n * P['water_use'] * (1.5 if t == 'hot' else 1)
        if s.st['water'] >= wn:
            s.st['water'] -= wn; s.thirst = False
        else:
            s.st['water'] = 0; s.thirst = True
        if mode == 'port':
            s.noScr = 0
        elif s.st['scrub'] > 0:
            s.st['scrub'] = max(0, s.st['scrub'] - n * P['scrub_use']); s.noScr = 0
        else:
            s.noScr += 1
        if mode != 'port' and s.w == 'snow' and s.st['water'] < CAP['water']:
            s.st['water'] = min(CAP['water'], s.st['water'] + s.ri(2, 6))
        if mode != 'port':
            if s.st['fuel'] > 0:
                s.burn_fuel((PACE[s.pace][3] if mode == 'sail' else P['loiter']) * TEMPF[t])
            else:
                s.lose_lift(P['empty_lift'])
                s.check()  # the engine must check `over` before health (§20)

    # ------------------------------------------------------------ §12.3 health
    def health(s, mode):
        t = s.here_temp(mode)
        w = W[s.w]
        port = STOPS[s.si][0] if mode == 'port' else None
        flu = port is not None and PORTS[port][2]
        for i, c in enumerate(s.living()):
            d = RAT[s.rat][1]
            if mode == 'sail':
                d += PACE[s.pace][1] - w[2]
            if mode == 'sea':
                d += 3
            if mode == 'port':
                d += 6
            if s.starv:
                d -= 7
            if s.thirst:
                d -= 12
            warm = i < s.st['suits']
            if mode != 'port':
                if t == 'freezing':
                    d -= P['freeze_warm'] if warm else P['freeze_cold']
                elif t == 'cold':
                    d -= 0 if warm else P['cold_nowarm']
                elif t == 'hot':
                    d -= .4
            if c['ail']:
                d -= AIL[c['ail']][0] * (.5 if c['tr'] else 1)
                if c['ail'] == 'stale air':
                    if (s.st['scrub'] > 0 or mode == 'port') and s.ch(.6 if mode == 'port' else .35):
                        c['ail'] = None
                else:
                    c['ad'] -= 2 if mode == 'port' else 1.5 if mode == 'sea' else 1
                    if c['ad'] <= 0:
                        c['ail'] = None; c['tr'] = False
            else:
                d += 1
            c['hp'] = min(100, max(0, c['hp'] + d))
            if c['ail'] is None and c['hp'] > 0:
                p = .0035 + (100 - c['hp']) * .00035
                if s.rat == 'crackers': p += .005
                if s.starv: p += .03
                if s.thirst: p += .04
                if t == 'hot': p += .003
                if t in ('freezing', 'cold') and not warm and mode != 'port': p += .01
                if flu: p += .012
                if mode == 'port': p *= .7
                if s.ch(p):
                    s.sicken(c, t, mode, flu, None)
                elif mode != 'port' and s.noScr > P['onset'] and s.ch(min(.12, (s.noScr - P['onset']) * P['slope'])):
                    s.sicken(c, t, mode, False, 'stale air')
        for c in s.crew:
            if c['alive'] and c['hp'] <= 0:
                c['alive'] = False
                if c['cap']:
                    s.over = True
                    s.end = 'pilot died'
                    raise Over

    def sicken(s, c, t, mode, flu, force):
        if force:
            pool = [force]
        elif mode == 'port':
            pool = POOL['flu_field'] if flu else POOL['ground']
        else:
            pool = POOL['hot'] if t == 'hot' else POOL['cold'] if t in ('cold', 'freezing') else POOL['other']
        a = s.r.choice(pool)
        c['ail'], c['ad'], c['tr'] = a, s.ri(*AIL[a][1]), False
        if a != 'stale air' and s.st['meds'] > 0:
            s.st['meds'] -= 1; c['tr'] = True

    # ------------------------------------------------------------ §12.4 wear
    def wear(s, reg):
        w = W[s.w]
        s.burn = max(0, s.burn - PACE[s.pace][2] * w[1] * s.rnd(.6, 1.4))
        hd = P['leak']
        if s.w == 'storm':
            hd += s.rnd(1, 2.6) * (1.6 if s.pace == 'high' else .7 if s.pace == 'low' else 1) \
                * (1.5 if 'ice' in reg[3] else 1)
        if s.w == 'shear':
            hd += s.rnd(0, .8) * (1.5 if s.pace == 'high' else 1)
        if s.w == 'sun':
            hd += s.rnd(0, .4)
        if s.w == 'snow' and 'ice' in reg[3]:
            hd += s.rnd(.5, 1.5)
        s.lose_lift(hd)
        if s.lift < 35 and s.st['food'] > 20 and s.ch(.06):
            s.st['food'] -= s.ri(5, 15)
        s.check()

    def roof(s):  # §13 event 8
        c = [x for x in s.crew if x['alive'] and not x['cap']]
        if not c:
            return
        x = s.r.choice(c)
        if s.ch(.65):
            x['hp'] = max(1, x['hp'] - 25)
        else:
            x['hp'] -= 20
            if x['ail'] is None:
                x['ail'] = 'a broken arm'; x['ad'] = s.ri(14, 24)

    # ------------------------------------------------------------ §13 events (bot's choices)
    def event(s, reg):
        w, st = s.w, s.st
        rough = w in ROUGH
        t = s.temp(reg)
        sea = 'sea' in reg[3]
        E = [(6, st['food'] > 40, 'condensation'), (5, st['water'] > 30 and t != 'hot', 'jug'),
             (4, True, 'stash'), (3, True, 'find'), (6, rough or w == 'jet', 'burner'), (4, rough, 'cable'),
             (4, True, 'leak'), (3, rough or w == 'snow', 'roof'), (1.5, st['fuel'] > 100, 'valve'),
             (2, w == 'storm', 'lightning'), (2.5, sea and not rough, 'freighter'),
             (2, t in ('cold', 'freezing') and not s.mascot, 'mascot'),
             (5, t in ('warm', 'hot') or 'storms' in reg[3], 'thunderheads'),
             (4, t in ('cold', 'freezing') and w in ('snow', 'cloud'), 'ice'),
             (2, not sea and not rough, 'camera'), (2, not rough, 'quiet'), (1.5, rough, 'smooth')]
        el = [e for e in E if e[1]]
        x = s.r.random() * sum(e[0] for e in el)
        k = el[0][2]
        for e in el:
            x -= e[0]
            if x <= 0:
                k = e[2]
                break
        if k == 'condensation':
            st['food'] -= math.floor(st['food'] * s.rnd(.05, .14) + .5)
        elif k == 'jug':
            st['water'] = max(0, st['water'] - s.ri(6, 20))
        elif k == 'stash':
            st['food'] = min(CAP['food'], st['food'] + s.ri(3, 8))
        elif k == 'find':
            if s.ch(.5):
                st['spares'] = min(CAP['spares'], st['spares'] + 1)
            elif s.ch(.6):
                st['food'] = min(CAP['food'], st['food'] + s.ri(10, 25))
        elif k == 'burner':
            s.burn = max(0, s.burn - s.ri(12, 28))
        elif k == 'cable':
            s.burn = max(0, s.burn - 15); s.lose_lift(6)
            c = [x for x in s.crew if x['alive'] and x['ail'] is None]
            if c and s.ch(.5):
                x = s.r.choice(c); x['ail'] = 'a broken arm'; x['ad'] = s.ri(14, 24); x['hp'] -= 10
            s.check()
        elif k == 'leak':
            s.lose_lift(s.ri(8, 18)); s.check()
        elif k == 'roof':
            s.roof()
        elif k == 'valve':
            s.burn_fuel(math.floor(st['fuel'] * .08 + .5))
        elif k == 'lightning':
            s.burn = max(0, s.burn - 18)
        elif k == 'mascot':  # the bot keeps the bear
            s.mascot = True
        elif k == 'thunderheads':  # the bot goes around
            s.t += 1
            s.consume('sail'); s.health('sail')
            if s.ch(.1):
                s.lose_lift(s.ri(6, 12))
            s.check()
        elif k == 'ice':  # the bot climbs if it can
            if st['fuel'] >= 40:
                s.burn_fuel(40)
            else:
                s.lose_lift(s.ri(5, 15)); s.check()
        elif k == 'camera':
            take = (s.pol.get('camera', False) and s.role != 'chocolatier'
                    and s.lift >= P['camera_bot_min'] and s.burn >= P['camera_bot_min'])
            if take:
                if s.ch(.5):
                    g = 50 * s.ri(6, 16); s.money += g; s.camera['won'] += g
                else:
                    s.lose_lift(8); s.burn = max(0, s.burn - 12); s.camera['hurt'] += 1; s.check()
        elif k == 'smooth':
            s.ff = 2
        # freighter: the bot flies on; quiet: flavour only

    # ------------------------------------------------------------ §12.6 time without flying
    def pass_(s, n, mode):
        for _ in range(n):
            s.t += 1
            s.w = s.roll(s.region()) if mode != 'port' else 'steady'
            s.consume(mode)
            s.health(mode)

    # ------------------------------------------------------------ §6, §14 stops
    def arrive(s, stop):
        k, typ, m = stop
        if typ == 'port':
            s.legs.append((k, s.t, s.fuel_burnt, s.lift_lost))
            s.port(k)
        elif typ == 'special':
            if k == 'dateline':  # the bot holds the party
                s.t += 1
                s.burn_fuel(15)
                s.st['food'] = max(0, s.st['food'] - 3)
                for c in s.living():
                    c['hp'] = min(100, c['hp'] + 8)
            elif k == 'azores':  # the bot meets the boat
                s.st['water'] = min(CAP['water'], s.st['water'] + s.ri(20, 40))
                s.st['food'] = min(CAP['food'], s.st['food'] + s.ri(10, 25))
                s.noScr = 0
                for c in s.living():
                    if c['ail'] == 'stale air':
                        c['ail'] = None
                c = [x for x in s.crew if x['alive'] and x['ail'] is None and not x['cap']]
                if c and s.ch(.15):
                    x = s.r.choice(c); x['ail'] = 'a broken arm'; x['ad'] = s.ri(14, 22)
                for _ in range(2):  # two watches loitering, no weather roll; propane at the loiter rate
                    s.t += 1; s.consume('sea'); s.health('sea')
            # Himalaya: the bot stays south
        elif typ == 'fork':
            s.passage = s.pol.get('fork') or ('north' if s.ch(.5) else 'south')
            hire = s.pol.get('hire', 'bot')
            if s.passage == 'south' and s.money >= P['forecasters'] and (
                    hire is True or (hire == 'bot' and s.money > P['bot_hire_above'])):
                s.money -= P['forecasters']; s.spend['forecasters'] += P['forecasters']; s.fc = True
        elif typ == 'end':
            s.over = True; s.end = 'WIN'
            raise Over

    def port(s, k):
        s.ground = True
        if s.avg_hp() < 70:
            s.pass_(3, 'port')
        s.shop(k)
        mult = PORTS[k][0]
        hc = math.ceil((100 - s.lift) * 20 * mult)
        if s.lift < 70 and s.money >= hc:
            s.money -= hc; s.spend['riggers: helium'] += hc; s.lift = 100.; s.pass_(1, 'port')
        bc = math.ceil((100 - s.burn) * 15 * mult)
        if s.burn < 70 and s.money >= bc:
            s.money -= bc; s.spend['riggers: burners'] += bc; s.burn = 100.; s.pass_(1, 'port')
        s.relaunch(k)

    def relaunch(s, k):
        """§6: a relaunch burns 25 gal. Short of that, it is refused if a step of propane is
        affordable here (the bot would have bought it); otherwise the ground team tops the
        tank up to 25 on the sponsor's account."""
        if s.st['fuel'] < P['relaunch']:
            step_cost = s.price(k, 'fuel') * ITEMS['fuel'][1]
            if s.money >= step_cost:  # never happens after the bot's shopping, kept for completeness
                s.money -= step_cost; s.spend['fuel'] += step_cost; s.st['fuel'] += ITEMS['fuel'][1]
            else:
                s.sponsor += 1; s.st['fuel'] = P['relaunch']
        s.burn_fuel(P['relaunch'])
        s.legs.append((k + '>', s.t, s.fuel_burnt, s.lift_lost))
        s.ground = False

    def price(s, k, item):
        m, mods, _ = PORTS[k]
        return ITEMS[item][0] * m * mods.get(item, 1)

    def shop(s, k):  # §18.2
        nxt = [x for x in STOPS[s.si + 1:] if x[1] in ('port', 'end')][0]
        Wt = (nxt[2] - s.mile) / 90 + 12
        n = len(s.living())
        want = [('fuel', Wt * 15 + P['relaunch'] + 40), ('food', n * RAT[s.rat][0] * Wt),
                ('water', n * P['water_use'] * 1.3 * Wt), ('scrub', n * P['scrub_use'] * Wt), ('suits', n),
                ('meds', 2), ('spares', 2), ('ballast', 2), ('line', 0 if s.role == 'chocolatier' else 60)]
        total = 0.
        for item, target in want:
            pr, step, per, mx = ITEMS[item]
            units = math.ceil((target - s.st[item]) / per / step) * step
            room = int((mx * per - s.st[item]) // per)
            units = min(max(0, units), room)
            p = s.price(k, item)
            while units > 0 and total + units * p > s.money:
                units -= step
            units = max(0, units)
            total += units * p
            s.st[item] += units * per
            s.spend[item] += units * p
        s.money -= total

    # ------------------------------------------------------------ §15, §18.2 aloft
    def fishing(s):
        s.fish_outings += 1
        caught = 0
        for _ in range(15):
            if s.st['line'] <= 0:
                break
            s.st['line'] -= 1
            if s.ch(s.R['hit']):
                x = s.r.random() * 100
                for lb, wt in FISH:
                    x -= wt
                    if x <= 0:
                        caught += lb
                        break
        got = min(caught, s.R['catch'], int(CAP['food'] - s.st['food']))
        s.st['food'] += got
        s.noScr = 0  # the hatch has been open at the wave tops (§15)
        s.pass_(1, 'sea')

    def before_watch(s):
        while (s.lift < 40 and s.st['ballast'] >= 1) or (s.burn < 40 and s.st['spares'] >= 1):
            if s.lift < 40 and s.st['ballast'] >= 1:
                s.st['ballast'] -= 1; s.lift = min(100, s.lift + s.R['ballast'])
            else:
                s.st['spares'] -= 1; s.burn = min(100, s.burn + s.R['spares'])
            s.pass_(1, 'sea')
        n = len(s.living())
        if (s.role != 'chocolatier' and s.st['food'] < 12 * n * RAT[s.rat][0] and s.st['line'] > 0
                and 'sea' in s.region()[3] and s.w not in ROUGH):
            s.fishing()
        if s.role == 'chocolatier':
            s.pace = 'middle'
        else:
            s.pace = ('high' if s.avg_hp() >= 75 and s.temp(s.region()) != 'freezing' and s.st['fuel'] > 0
                      else 'middle')

    def score(s):  # §17
        alive = s.living()
        a = s.avg_hp()
        per = 500 if a >= 75 else 400 if a >= 50 else 300 if a >= 28 else 200
        st = s.st
        lines = [len(alive) * per, round(s.lift * 2 + s.burn),
                 int(st['fuel'] // 50) + int(st['food'] // 10) + int(st['water'] // 50),
                 int(st['scrub']) + st['meds'] * 5 + st['suits'] * 2 + st['spares'] * 4 + st['ballast'] * 3
                 + st['line'] // 20,
                 int(s.money // 50)]
        return lines, sum(lines) * s.R['mult']

    def play(s):
        try:
            s.shop('mar')
            s.relaunch('mar')
            while s.t < 600:
                s.before_watch()
                s.sail()
            s.end = 'day cap'
        except Over:
            pass
        return s


# ======================================================================== reports
SEED_SETS = (1999, 50000, 90000, 123456, 777777, 31337)


def flights(role, base, n=30, policy=None):
    out = []
    for i in range(n):
        seed = base + 1000 * ROLES[role]['mult'] + i
        y, m = DEPARTURES[seed % 3]
        out.append(Flight(role, seed, y, m, policy).play())
    return out


def pct(xs, q):
    xs = sorted(xs)
    return xs[min(len(xs) - 1, int(math.ceil(q * len(xs))) - 1)]


def rates(sets=SEED_SETS):
    print('Win rates, 30 flights per role per seed set (seeds base + 1000 x multiplier + i)')
    allw = []
    for role in ROLE_ORDER:
        row, tot = [], 0
        for b in sets:
            fl = flights(role, b)
            w = [f for f in fl if f.end == 'WIN']
            row.append(len(w)); tot += len(w)
            allw += [f.t for f in w]
        print(f'  {role:12s}', ' '.join(f'{x:2d}/30' for x in row),
              f'  total {tot}/{30 * len(sets)} = {100 * tot / (30 * len(sets)):.0f}%')
    print('  median winning flight', statistics.median(allw), 'watches')


def per_set_medians(sets=SEED_SETS):
    res = []
    for b in sets:
        ts = [f.t for role in ROLE_ORDER for f in flights(role, b) if f.end == 'WIN']
        res.append(statistics.median(ts))
    print('  median winning flight by seed set:', res)


def losses(sets=SEED_SETS):
    print('How flights end (all seed sets)')
    for role in ROLE_ORDER:
        c = Counter()
        sp = 0
        for b in sets:
            for f in flights(role, b):
                where = STOPS[f.si][0] if f.ground else f.region()[1]
                c[f.end if f.end == 'WIN' else f'{f.end} @ {where}'] += 1
                sp += f.sponsor
        print(f'  {role:12s}', dict(c.most_common(7)), 'sponsor top-ups', sp)


def months():
    print('By departure month, 60 flights per role, seeds 777 + i')
    labels = [('November', (1998, 10)), ('December', (1998, 11)), ('January', (1999, 0)),
              ('February', (1999, 1)), ('March', (1999, 2))]
    for role in ROLE_ORDER:
        row = []
        for name, (y, m) in labels:
            w = sum(Flight(role, 777 + i, y, m).play().end == 'WIN' for i in range(60))
            row.append(f'{name[:3]} {w}/60')
        print(f'  {role:12s}', '  '.join(row))


def tracks():
    print('By Pacific track, 120 flights per role (seeds 4242 + i, Dec/Jan/Feb in turn), track forced')
    pols = [('north', dict(fork='north')), ('south + forecasters', dict(fork='south', hire=True)),
            ('south, none', dict(fork='south', hire=False)), ('south, bot rule', dict(fork='south'))]
    for role in ROLE_ORDER:
        row = []
        for name, pol in pols:
            fl = [Flight(role, 4242 + i, *DEPARTURES[i % 3], pol).play() for i in range(120)]
            row.append(f'{name}: {sum(f.end == "WIN" for f in fl)}')
        print(f'  {role:12s}', ' | '.join(row))


def legs(roles=ROLE_ORDER, sets=SEED_SETS[:4]):
    """Per leg: aloft watches, propane and lift lost from a relaunch (its 25 gal included) to
    the next field or the finish, over every flight that got there."""
    print(f'Legs, {"/".join(roles)}, seed sets {sets} - from relaunch (included) to arrival')
    data = defaultdict(list)
    cond = []
    for role in roles:
        for b in sets:
            for f in flights(role, b):
                cond += f.cond
                lg = list(f.legs)
                if f.end == 'WIN':
                    lg.append(('finish', f.t, f.fuel_burnt, f.lift_lost))
                for a, z in zip(lg, lg[1:]):
                    if a[0].endswith('>') and not z[0].endswith('>'):
                        x = (z[1] - a[1], z[2] - a[2], z[3] - a[3])
                        data[(a[0][:-1], z[0], f.passage if a[0] == 'saga>' else '')].append(x)
                        if a[0] == 'saga>':
                            data[('saga', 'abq', 'both')].append(x)
    order = [s[0] for s in STOPS]
    for k in sorted(data, key=lambda k: (order.index(k[0]), k[2])):
        v = data[k]
        ws = [x[0] for x in v]; fu = [x[1] for x in v]; li = [x[2] for x in v]
        print(f'  {k[0]:>4s}->{k[1]:<6s} {k[2]:5s} n={len(v):3d} watches med {statistics.median(ws):4.0f}'
              f' p90 {pct(ws, .9):3d} | propane med {statistics.median(fu):4.0f} p90 {pct(fu, .9):5.0f}'
              f' max {max(fu):5.0f} | lift lost med {statistics.median(li):3.0f} p90 {pct(li, .9):3.0f}')
    print(f'  condition factor (burners x lift) mean while flying: {statistics.mean(cond):.3f}')


def money(sets=SEED_SETS):
    print(f'Money over the whole flight, means over {30 * len(sets)} flights per role (all flights)')
    keys = ['fuel', 'food', 'water', 'scrub', 'suits', 'meds', 'spares', 'ballast', 'line',
            'riggers: helium', 'riggers: burners', 'forecasters']
    rows = {}
    for role in ROLE_ORDER:
        fl = [f for b in sets for f in flights(role, b)]
        wins = [f for f in fl if f.end == 'WIN']
        rows[role] = ({k: statistics.mean([f.spend[k] for f in fl]) for k in keys},
                      statistics.mean([sum(f.spend.values()) for f in fl]),
                      statistics.mean([f.money for f in wins]) if wins else 0,
                      statistics.median([f.score()[1] for f in wins]) if wins else 0,
                      statistics.mean([f.camera['won'] for f in fl]),
                      statistics.mean([f.fish_outings for f in fl]))
    for k in keys:
        print(f'  {k:18s}', '  '.join(f'{rows[r][0][k]:7.0f}' for r in ROLE_ORDER))
    print('  spent             ', '  '.join(f'{rows[r][1]:7.0f}' for r in ROLE_ORDER))
    print('  left (winners)    ', '  '.join(f'{rows[r][2]:7.0f}' for r in ROLE_ORDER))
    print('  median score (win)', '  '.join(f'{rows[r][3]:7.0f}' for r in ROLE_ORDER))
    print('  camera bonus mean ', '  '.join(f'{rows[r][4]:7.0f}' for r in ROLE_ORDER))
    print('  fishing outings   ', '  '.join(f'{rows[r][5]:7.2f}' for r in ROLE_ORDER))


def pacific_fill(sets=SEED_SETS[:4]):
    """What happens to a chocolatier who fills only to F gallons at Saga."""
    print('Chocolatier filling only to F gal at Saga (120 flights): flights that come down before Albuquerque')
    for F in (700, 800, 900, 1000, 1200):
        orig = Flight.shop

        def shop(s, k, F=F):
            orig(s, k)
            if k == 'saga' and s.st['fuel'] > F:
                s.money += (s.st['fuel'] - F) * s.price(k, 'fuel'); s.st['fuel'] = F
        Flight.shop = shop
        down = 0
        for b in sets:
            for f in flights('chocolatier', b):
                if f.end and f.end.startswith('down') and f.si < 9 and f.si >= 5:
                    down += 1
        Flight.shop = orig
        print(f'  F = {F:4d}: {down}/120')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('what', nargs='?', default='report')
    ap.add_argument('--builder', type=float)
    ap.add_argument('--pilot', type=float)
    ap.add_argument('--forecasters', type=float)
    a = ap.parse_args()
    if a.builder: ROLES['builder']['money'] = a.builder
    if a.pilot: ROLES['pilot']['money'] = a.pilot
    if a.forecasters: P['forecasters'] = a.forecasters
    if a.what in ('rates', 'report'):
        rates(); per_set_medians()
    if a.what in ('losses', 'report'):
        losses()
    if a.what in ('months', 'report'):
        months()
    if a.what in ('tracks', 'report'):
        tracks()
    if a.what in ('legs', 'report'):
        legs(('chocolatier',)); legs()
    if a.what in ('money', 'report'):
        money()
    if a.what in ('fill', 'report'):
        pacific_fill()


if __name__ == '__main__':
    main()
