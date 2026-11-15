# Open questions

Things only the game, a probe or legacy can answer. Move answers into the doc they belong to and delete the entry.

- **Bindings:** does a new context section (`[MEDITATION_CLOCK_CONTEXT]`, legacy's stop key) work from `input.settings`? Does a real press of End reach `OnToggleSpawnCampFire` (slice 0 tested the binding and the handler separately)?
- **Camera:** when Geralt is in a state that defines `OnGameCameraPostTick`, does `CR4Player.OnGameCameraPostTick` run too?
- **Behaviour graph on 5.x:** do `MeditateWithIgnite` (Igni lighting the fire), `HasCampfire` (putting it out) and `MeditateAbort` still play, and does `PlayerStartAction(PEA_Meditation)` without 5.x's `InitState` still sit Geralt down and fire `OnPlayerActionStartFinished`?
- **5.x flow:** what does the hidden `NewMeditationGroup` option switch (no script reads it)? Does pressing N in 5.x always sit Geralt down before the menu, also in interiors and on boats?
- **Effects:** do multi-second `PerformUpdate` steps behave (potion expiry, regeneration, toxicity, Ghost Mode's per-tick effects)? Does 5.x still leave a Quen shield after the basic Quen buff is removed by an update (FM-QUEN's reason)?
- **To test in legacy FM:** why `W3Effect_BasicQuen.OnEffectRemoved` was added; whether the extra effect update made potions and regeneration run faster than normal time (the engine's tick plus `PerformUpdate`); how the Igni lighting and put-out looked; whether saving was really refused during meditation (`CreateNoSaveLock`).
