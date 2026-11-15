// The square-wave synth (AroundTheHorn/Services/Audio.swift, spec §10): every cue is
// rendered once into a buffer the way the prototype's `beep` shapes a note — a square (or
// sawtooth) wave starting at a low gain and decaying exponentially to near silence.

const RATE = 44100;

/** The prototype's `tune`: notes back to back, each 95% of its slot. */
function tune(seq) {
  let t = 0;
  return seq.map(([hz, d]) => {
    const n = { hz, seconds: d * 0.95, saw: false, volume: 0.03, at: t };
    t += d;
    return n;
  });
}

const note = (hz, seconds, o = {}) => [{ hz, seconds, saw: o.saw ?? false, volume: o.volume ?? 0.035, at: 0 }];

/** The cue table: beeps from the buttons, messages, the shop and the harpoon, and the tunes. */
export function notes(cue) {
  switch (cue) {
    case 'click': return note(520, 0.03);
    case 'message': return note(240, 0.07);
    case 'shopUp': return note(880, 0.025);
    case 'shopDown': return note(440, 0.025);
    case 'harpoon': return note(320, 0.06, { saw: true });
    case 'stranger': return note(200, 0.15);
    case 'unmute': return note(660, 0.05);
    case 'title': return tune([[392, 0.15], [523, 0.15], [659, 0.15], [784, 0.3], [659, 0.15], [698, 0.15],
      [784, 0.15], [880, 0.45], [784, 0.15], [659, 0.15], [523, 0.4]]);
    case 'arrive': return tune([[523, 0.1], [659, 0.1], [784, 0.1], [1047, 0.25]]);
    case 'death': return tune([[392, 0.3], [349, 0.3], [311, 0.3], [262, 0.7]]);
    case 'win': return tune([[523, 0.12], [523, 0.12], [659, 0.12], [784, 0.24], [659, 0.12], [784, 0.12], [1047, 0.5]]);
    case 'fishHit': return tune([[660, 0.06], [880, 0.1]]);
    default: return [];
  }
}

/** Mono samples for a cue. */
export function render(ns) {
  const end = Math.max(0, ...ns.map((n) => n.at + n.seconds + 0.03));
  const out = new Float32Array(Math.floor(end * RATE));
  for (const n of ns) {
    const start = Math.floor(n.at * RATE);
    const count = Math.floor((n.seconds + 0.03) * RATE);
    for (let i = 0; i < count && start + i < out.length; i++) {
      const tau = i / RATE;
      const gain = n.volume * Math.pow(0.0001 / n.volume, Math.min(tau, n.seconds) / n.seconds);
      const phase = (tau * n.hz) % 1;
      const wave = n.saw ? 2 * phase - 1 : (phase < 0.5 ? 1 : -1);
      out[start + i] += gain * wave;
    }
  }
  return out;
}

/** Plays cues in the browser. Silent until the page has been touched, as browsers require. */
export class Synth {
  constructor() {
    this.ctx = null;
    this.buffers = new Map();
  }

  play(cue) {
    const AC = globalThis.AudioContext ?? globalThis.webkitAudioContext;
    if (!AC) return;
    try {
      this.ctx ??= new AC();
      if (this.ctx.state === 'suspended') this.ctx.resume();
      let b = this.buffers.get(cue);
      if (!b) {
        const samples = render(notes(cue));
        if (!samples.length) return;
        b = this.ctx.createBuffer(1, samples.length, RATE);
        b.copyToChannel(samples, 0);
        this.buffers.set(cue, b);
      }
      const src = this.ctx.createBufferSource();
      src.buffer = b;
      src.connect(this.ctx.destination);
      src.start();
    } catch {
      // No sound to be had: the game plays on without it.
    }
  }
}
