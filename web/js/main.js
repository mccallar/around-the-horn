// Starts the game in the page: loads the engine (horn.wasm), then hands the page to the
// flow and the screens. `?journey=<id>` opens on that journey's title card, as the app's
// `-journey <id>` launch argument does.

import { loadEngine } from '../engine.js';
import { Flow, MemoryStorage } from './flow.js';
import { Synth } from './sound.js';
import { UI } from './ui.js';

/** localStorage, or a store that forgets if the browser keeps nothing. */
function storage() {
  try {
    const s = globalThis.localStorage;
    s.setItem('horn.probe', '1');
    s.removeItem('horn.probe');
    return s;
  } catch {
    return new MemoryStorage();
  }
}

async function main() {
  const root = document.getElementById('screen');
  try {
    const engine = await loadEngine(new URL('../horn.wasm', import.meta.url));
    await document.fonts?.ready;
    const synth = new Synth();
    const journey = new URLSearchParams(location.search).get('journey');
    const flow = new Flow({ engine, storage: storage(), journey, sound: (cue) => synth.play(cue) });
    const sound = document.getElementById('snd');
    sound.hidden = false;
    new UI(flow, { root, banner: document.getElementById('banner'), sound, synth });
  } catch (e) {
    console.error(e);
    root.innerHTML = '<p class="failed"></p>';
    root.firstChild.textContent = `The game could not start: ${e.message}`;
  }
}

main();
