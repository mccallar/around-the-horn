# Ship checklist

What the code can't check for itself. Everything else is covered by the test schemes, the
Node tests of the web version and the screenshot walks (see README).

## On a device

- [ ] **Sound.** The synth is tested for volume and shape but has never been *heard*:
      the click, the message blip, each journey's title tune, the arrival fanfare, the
      death dirge, the win tune, each journey's mini-game (the harpoon and the catch in
      1849). Mute toggle silences all of it; your own music keeps playing
      underneath.
- [ ] **Haptics.** Light tap on every choice; success on arrival, the finale and a catch;
      warning on a death.
- [ ] **A real force-quit mid-voyage**, then Continue (the UI test terminates the app,
      which is close but not the app switcher). Once in 1849 and once in another journey,
      and once on the first stores before leaving (D16).
- [ ] **The mini-game by thumb**, in each journey: the hit rate feels fair; the time feels
      right.
- [ ] **VoiceOver**, in each journey: the scene reads as what it shows (1849: "Ship sailing
      in fair winds"); choices, bars and the status panel read sensibly; the mini-game's
      double-tap throws at the nearest quarry.
- [ ] **A hardware keyboard on iPad**: 1–9 pick choices, Return picks a lone one.
- [ ] **The picker**: all six journeys listed; the one last chosen opens on relaunch.
- [ ] **Each new journey played once to its end** (rail, the airship, the balloon, the
      transfer, the Klondike): its words read right on the narrow phone and the large text
      size, and its endings feel fair.
- [ ] **Balance (docs/decisions.md D8):** the shipwright wins 93% for the rebuilt bot.
      Keep, or tighten? (Spec §0.5: no balance number changes without asking.)

## In a real browser

- [ ] **The web version** (`web/README.md`, "Play"), in Safari and one other browser, on a
      computer and a phone: the picker, each journey's title card, a few turns of each, its
      scene, chart and mini-game drawn, sound on and off, a reload mid-voyage coming back
      to the same screen, and keys and taps both working.

## In Apple's tools (only if it should reach TestFlight)

- [ ] Register the App ID `com.mccallatech.AroundTheHorn` (automatic signing will on first device build).
- [ ] App Store Connect record, then an Xcode Cloud workflow → TestFlight (internal group).
