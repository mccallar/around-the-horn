# Ship checklist

What the code can't check for itself. Everything else in spec §12 is covered by the
three test schemes and `ScreenshotUITests` (see README).

## Ryan, on a device

- [ ] **Sound.** The synth is tested for volume and shape but has never been *heard*:
      the click, the message blip, the title tune on "Sail for California", the arrival
      fanfare, the death dirge, the win tune, the harpoon and the catch. Mute toggle
      silences all of it; your own music keeps playing underneath.
- [ ] **Haptics.** Light tap on every choice; success on arrival, the finale and a catch;
      warning on a death.
- [ ] **A real force-quit mid-voyage**, then Continue (the UI test terminates the app,
      which is close but not the app switcher).
- [ ] **Fishing by thumb.** The hit rate feels fair; 25 seconds feels right.
- [ ] **VoiceOver**: the scene reads as "Ship sailing in fair winds"; choices, bars and
      the status panel read sensibly; fishing's double-tap throws at the nearest fish.
- [ ] **A hardware keyboard on iPad**: 1–9 pick choices, Return picks a lone one.
- [ ] **Balance (docs/decisions.md D8):** the shipwright wins 93% for the rebuilt bot.
      Keep, or tighten? (Spec §0.5: no balance number changes without you.)

## Ryan, in Apple's tools (only if it should reach TestFlight)

- [ ] Create the GitHub repo and push: `gh repo create mccallar/around-the-horn --private --source . --push`
- [ ] Register the App ID `com.mccallatech.AroundTheHorn` (automatic signing will on first device build).
- [ ] App Store Connect record, then an Xcode Cloud workflow → TestFlight (internal group).
