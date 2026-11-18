// How much of an item there is, as the shop, the lists and the mini-game write it
// (`Stores` in AroundTheHorn/UI/Components/StatusPanel.swift). The engine counts in stored
// units, `Item.per` of them to the unit the shop sells; nothing here shows a stored count
// as if it were units.

import { formatNumber, fixed2 } from './markup.js';

/**
 * How one item is counted: `{ loose, looseOne, tenths, singular }`. `loose` is what one
 * stored unit is called when the item is counted loose aboard, and `looseOne` exactly one
 * of them, if that is not `loose` ("1 balloon").
 */
export function counting(it, words) {
  const loose = words.looseUnits[it.key] ?? null;
  return {
    loose,
    looseOne: words.looseOne[it.key] ?? null,
    tenths: words.fractional.includes(it.key) || (it.per > 1 && loose === null),
    singular: words.singular,
  };
}

/** `stored` in the item's own unit, rounded down to a tenth: "9.5", "1.4", "2". */
function tenths(stored, it) {
  const x = Math.floor(stored * 10 / Math.max(1, it.per)) / 10;
  return String(x);
}

function whole(stored, it) {
  return Math.floor(stored / Math.max(1, it.per));
}

/** The unit to write after `count` of an item. */
export function unit(it, count, how) {
  return how.singular && count === '1' ? it.one : it.unit;
}

/** The shop's "Have N": units of the item as it is sold, whole or to a tenth. */
export function have(stored, it, how) {
  return how.tenths ? tenths(stored, it) : String(whole(stored, it));
}

/** The bare number of `stored`, in whatever the item is counted in. */
export function count(stored, it, how, grouped = false) {
  if (how.loose !== null) return String(Math.floor(stored));
  if (how.tenths) return tenths(stored, it);
  return grouped ? formatNumber(whole(stored, it)) : String(whole(stored, it));
}

/**
 * `stored` with what it is counted in: "1,500 lbs", "9.5 crates", "1.4 cords", and what is
 * loose aboard counted singly and written plain, "60 throws", "1 balloon".
 */
export function measure(stored, it, how, grouped = false) {
  const n = count(stored, it, how, grouped);
  const loose = n === '1' ? how.looseOne ?? how.loose : how.loose;
  return `${n} ${loose ?? unit(it, n, how)}`;
}

/** With its unit, for the supplies list and the status box. */
export function amount(it, g, words) {
  return measure(g[it.key], it, counting(it, words), true);
}

/** The prototype's price label: "$0.13", "$4", "$5.20". */
export function priceText(p, sign) {
  return sign + (p < 1 || p % 1 !== 0 ? fixed2(p) : String(Math.trunc(p)));
}

/** What an item costs, as its shop row writes it: "$4/cord", or by the lot, "$2/100 gallons". */
export function priceLabel(it, price, sign, lot) {
  if (!lot || it.step <= 1) return `${priceText(price, sign)}/${it.one}`;
  return `${priceText(Math.round(price * it.step * 100) / 100, sign)}/${it.step} ${it.unit}`;
}
