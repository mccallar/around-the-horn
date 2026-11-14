# Around the Horn: 1849 on the web

The web version runs the game's own engine: the Swift rules in `HornEngine/`, compiled
to WebAssembly (`horn.wasm`). There is no second copy of the rules in JavaScript. The page
is plain HTML, CSS and JavaScript modules, with no build step and nothing to install.

## Play

From the repository's root:

    python3 -m http.server -d web 8000

then open <http://localhost:8000>. Any static file server will do; opening the files
straight from disk will not, since browsers won't load WebAssembly from `file://`.

## Rebuild horn.wasm

Only needed after changing the engine (`HornEngine/`) or the bridge (`HornWeb/`). It needs
Swift 6.4.2 and its WebAssembly SDK from swift.org; `Tools/build_web.sh` says where to get
them. Then:

    SWIFT_WASM_TOOLCHAIN=<toolchain>/usr/bin SWIFT_WASM_SDKS=<sdk directory> sh Tools/build_web.sh

It writes `web/horn.wasm` and prints its size (about 13 MB). Commit the new file with the
change that needed it, and run the tests below.

## Test

With Node 20 or later, from the repository's root:

    node Tools/web-tests/imports.mjs   # the WASI shim answers exactly what horn.wasm imports
    node Tools/web-tests/golden.mjs    # the 300 golden 1849 voyages hash as the Mac recorded them (~1 min)
    node Tools/web-tests/parity.mjs    # horn.wasm and the Mac build give identical replies (~1 min)

`parity.mjs` builds the bridge for the Mac with `swift build` (Xcode's Swift); set
`HORN_NATIVE` to an already built `HornWeb` to skip that, and `VOYAGES` to play more than
20 voyages per background and journey. The engine's own tests are unchanged:
`swift test --disable-sandbox`.

## How it fits together

- `HornWeb/Bridge.swift` takes one JSON request and gives one JSON reply. Each request is
  `{"op": …}` with that call's fields; each reply is `{"ok": true, …}` or
  `{"ok": false, "error": …}`. `HornWeb/Exports.swift` exports it to JavaScript
  (`horn_alloc`, `horn_free`, `horn_call`, `horn_reply_len`); `HornWeb/main.swift` serves
  the same requests on stdin on the Mac, for the parity test.
- `engine.js` loads `horn.wasm` with a small WASI shim of its own (no files; a clock, the
  console and random bytes) and wraps the bridge in one method per call:

  | Method | What it is |
  |---|---|
  | `journeys()` | every journey's tables: items, stops, regions, ports and prices, weathers, ailments, roles, paces, rations, departures, names, the default top ten, the foraging quarry, the rules the screens show, a few sentences |
  | `start({journey, role, ship, captain, crew, year, month, seed})` | `GameController.chooseDeparture`: a voyage at its first stop |
  | `save(pending)` / `load(save, seed)` | the save file exactly as the app writes it (the GameState's keys, `pending` beside them) |
  | `buy`, `depart`, `setSail`, `sailDay`, `rest`, `mendSails`, `patchHull`, `repairHullAtYard`, `recutSailsAtYard`, `tradeAtPort`, `talk`, `throwHarpoon`, `landCatch`, `beginArrival`, `resolve`, `commitBurial`, `finish`, `setPace`, `setRations` | `GameEngine`'s calls of the same names, as GameController makes them |
  | `rank`, `topTen`, `bill`, `formatNumber`, `escape`, `name` | the engine's helpers the screens use |

  Every voyage call replies with `view`: `state` (the GameState) and what the screens
  read off it (the date as written, the region, health, the next stop, prices and room in
  the shop, what repairs cost and whether they can be done, why foraging is refused, the
  generator's position). Calls that take time also reply with `interrupts`, in the order
  the app shows them; `readInterrupt` reads one into `{type, …}`. Hand the interrupt
  itself back to the engine (`resolve`, `save`), never the reading of it.
- Randomness: `newSeed()` draws 64 bits with `crypto.getRandomValues` for each voyage, and
  the engine plays it with its own `SeededRNG`, so a seed replays a voyage exactly.
  Loading a save takes a seed too (`view.rng` continues where the voyage left off).
