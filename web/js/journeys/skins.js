// Every skin the web build has (AroundTheHorn/Journeys/JourneySkin.swift, `Skins.all`).
// Adding a journey's skin is a line here and its files beside this one. A journey the
// engine has without a skin here is not offered, rather than shown wearing another's.
//
// With one skin there is no picker: the game opens on its title card. With more than one
// the flow opens on the picker (flow.js, `hasPicker`), as the app does.

import * as horn1849 from './horn1849-skin.js';
import * as rail from './rail-skin.js';
import * as airship from './airship-skin.js';
import * as balloon from './balloon-skin.js';
import * as mars from './mars-skin.js';

export const all = [horn1849, rail, airship, balloon, mars];

/** The skins for the journeys the engine has, in the engine's order: `[{ journey, skin }]`. */
export function offered(journeys, skins = all) {
  return journeys
    .map((J) => ({ J, maker: skins.find((s) => s.id === J.id) }))
    .filter((x) => x.maker)
    .map(({ J, maker }) => ({ journey: J, skin: maker.skin(J) }));
}
