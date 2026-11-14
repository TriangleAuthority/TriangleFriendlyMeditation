# Open questions

Things only the game, a probe or legacy can answer. Move answers into the doc they belong to and delete the entry.

- **Bindings:** does an own XML in `user_config_matrix\pc\` with a `builder="Input"` group show in Key Bindings, merged into `PCInput` or as its own group? Does an action work from an `input.settings` line alone? Does 5.x keep lines it does not know when it rewrites `input.settings` (version 60), and does a new context section (`[MEDITATION_CLOCK_CONTEXT]`) work?
- **Blobs:** two mods' blobs `@addField`/`@addMethod` the same name on one class: compile error at start, or which wins? Do `@addField`/`@addMethod` work on a state class (`W3PlayerWitcherStateMeditation`)? Does a `timer function` declared in a state run when started with `thePlayer.AddTimer` (legacy FM's `SpawnCampFireTimer`)?
- **Camera:** when Geralt is in a state that defines `OnGameCameraPostTick`, does `CR4Player.OnGameCameraPostTick` run too?
- **Behaviour graph on 5.x:** do `MeditateWithIgnite` (Igni lighting the fire), `HasCampfire` (putting it out) and `MeditateAbort` still play, and does `PlayerStartAction(PEA_Meditation)` without 5.x's `InitState` still sit Geralt down and fire `OnPlayerActionStartFinished`?
- **5.x flow:** what does the hidden `NewMeditationGroup` option switch (no script reads it)? Does pressing N in 5.x always sit Geralt down before the menu, also in interiors and on boats?
- **Effects:** do multi-second `PerformUpdate` steps behave (potion expiry, regeneration, toxicity, Ghost Mode's per-tick effects)? Does 5.x still leave a Quen shield after the basic Quen buff is removed by an update (FM-QUEN's reason)?
- **To test in legacy FM:** why `W3Effect_BasicQuen.OnEffectRemoved` was added; whether the extra effect update made potions and regeneration run faster than normal time (the engine's tick plus `PerformUpdate`); how the Igni lighting and put-out looked; whether saving was really refused during meditation (`CreateNoSaveLock`).
