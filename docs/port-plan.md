# Port plan

## Where the port stands

**2026-11-13: slice 0 under way.** The baselines and the legacy mod are committed ([repository.md](repository.md)); the legacy mod is described in [legacy-mod.md](legacy-mod.md) and compared with 5.x in [meditation-5.x.md](meditation-5.x.md) (both read from the files, **unverified** in game). The build tools are in and the compile check works (**verified**: a ping test script compiles, [tools.md](tools.md)). Next: the owner's remaining [decisions](#decisions-to-make), then the rest of slice 0 in game.

## Approach

As in TriangleGhostMode and TriangleGwentImprovements: reproduce the legacy mod's behaviour in the least invasive 5.x form (script annotations, the options menu XML, whole files only where needed), one small slice at a time, each verified in game on the shared game slot. Bugs in the legacy mod are fixed as found and listed as deviations. Prefix for everything the mod adds: `FM`/`fm` (see [Preparations](ghost-mode-compatibility.md#preparations-interaction) for the legacy `fmed*` names). No DLC is needed: FM changes no XML and no binary resource.

## Decisions made

- **5.x's own meditation stays on N and the Meditation tab; the radial menu and FM's hotkey start FM's meditation** (owner, 2026-11-13; the radial menu changed the same day). N and the panels' Meditation tab keep 5.x's flow (sit down, clock, time-lapse, `MeditationRestoring` at the end). The radial menu's Meditation choice starts FM's real-time meditation, as does FM's hotkey; FM's meditation shares the two states through a flag on the player. 5.x's flow is not real-time meditation (it is 1.32's model shown in the world, [meditation-5.x.md](meditation-5.x.md#summary)), so the game has two meditations that play differently. Legacy FM replaced vanilla's flow everywhere, so this is a deviation ([deviations.md](deviations.md)). FM-CLOCK is dropped, except possibly a stop button.
  - **Radial port form:** `@wrapMethod(W3PlayerWitcher) OnRadialMenuItemChoose`: for `"Meditation"` start FM's meditation and return, otherwise `wrappedMethod`. All three ways to it pass there: choosing the radial slot, the meditation key while the radial menu is open (`CR4HudModuleRadialMenu.OnOpenMeditation`) and tapping the minimap's clock (`CR4HudModuleMinimap2.OnTapTime`). The two HUD callers show "not allowed here" unless Geralt is in state `Meditation` right after the call, so FM must enter it at once (not after a delay). Neither Ghost Mode nor Preparations touches this event (checked 2026-11-13).

## Decisions to make

1. **Healing:** legacy FM meditation never calls `MeditationRestoring` (no full heal on the easy modes, no toxicity or adrenaline reset, refill only after one game hour of fast-forward). Keep for FM meditation? (Ghost Mode's exhaustion still comes back with time without it: [ghost-mode-compatibility.md](ghost-mode-compatibility.md).)
2. **Hotkey path** once slice 0 shows what works ([meditation-5.x.md](meditation-5.x.md#hotkeys-on-5x)).
3. **Names shared with Preparations** ([below](ghost-mode-compatibility.md#preparations-interaction)).

## Features and port forms

| ID | Feature | Port form | Difficulty |
|---|---|---|---|
| FM-MENU | Options → Mods → Friendly Meditation (two groups, 14 options, 8 presets), `CModFMeditationConfig` | `menu/modFMeditationConfig.xml` (legacy ids, UTF-8 BOM); config class in a new file, defaults in script for unset values; strings 2112067000–045 from the five CSVs | Small |
| FM-KEYS | Hotkeys `HoldToMeditate`, `MeditationFastForward`, `ToggleSpawnCampFire`, `MeditationStop`; hold/toggle/manual modes; N shared with the clock | Bindings: input.settings lines plus `input.xml` entries or an own input XML (slice 0 decides); `@wrapMethod(CPlayerInput) Initialize` + `@addMethod` events; `@replaceMethod(CPlayerInput) OnCommPanelMeditation`; `@wrapMethod OnMeditationAbort`; `@wrapMethod(CR4IngameMenu) GetKeybindGroupTag` | **Hard** (no supported mod path for bindings) |
| FM-RT | Real-time meditation: states, HPM ramp, effects updated in accelerated time, optional time scale, refill after an hour, no save while meditating, blocks, notifications, vibration | Wrappers on `W3PlayerWitcherStateMeditation` and `...MeditationWaiting` events (`OnEnterState`, `OnLeaveState`, `OnPlayerTickTimer`, `StopRequested`) that run FM's code for FM meditation and skip `wrappedMethod`; FM's logic in `@addMethod(W3PlayerWitcher)` helpers and `@addField`s; `@wrapMethod` of `OnPlayerActionStartFinished`, `MeditationForceAbort`, `OnBlockingSceneStarted`, `CR4Player.DisallowedActionDontShowHack` | **Hard** |
| FM-CAM | Meditation camera, presets, camera return after meditation | `@wrapMethod(W3PlayerWitcherStateMeditationBase) OnGameCameraTick` (and the `Meditation` state's own camera events), `@wrapMethod(CR4Player) OnGameCameraPostTick` for FOV and the 1.5 s return | Medium |
| FM-FIRE | Campfire spawned with Igni, toggle key, kept or removed afterwards | `@addMethod(W3PlayerWitcher)` timers (`FMSpawnCampFireTimer`, `DeSpawnCampFireTimer`); `campfire_01.w2ent` and `W3Campfire` unchanged in 5.x; behaviour variables to check in game | Medium (animation check) |
| FM-CLOCK | Clock menu starts FM meditation to an hour, shows the target, "Stop meditation" button; common menu no longer stops it | Dropped: 5.x's clock flow stays ([Decisions made](#decisions-made)); at most a stop button for FM meditation | None |
| FM-BED | Witcher-house bed: meditation without the sitting animation, bonuses after an hour | 5.x already leaves meditation unblocked in bed; FM's bed branch in the state wrappers; `ApplyWitcherHouseBuffs` unchanged | Small |
| FM-POP | Places of power no longer cancel a meditation | 5.x fixed it itself (`StopMeditationAction`, `BlockMeditation`); only FM's behaviour-variable reset before channeling may be needed: `@wrapMethod(CMajorPlaceOfPowerEntityStatePlaceOfPower_Channeling) OnEnterState` | Small (likely nothing) |
| FM-QUEN | Basic Quen's shield expires with its buff | Scope-based override block `class W3Effect_BasicQuen extends CBaseGameplayEffect { event OnEffectRemoved() ... }` (inherited event); only if 5.x still shows the problem | Small |

## Slices

0. **Tooling and probes:** the tools from TriangleGwentImprovements (done 2026-11-13) (`paths.MOD = modFriendlyMeditation`), compile check, install on the shared slot with Ghost Mode installed (as Gwent's [tools.md](https://github.com/TriangleAuthority/TriangleGwentImprovements/blob/master/docs/tools.md#testing-in-game) does). Show FM-MENU in game (`autoconfig("modFriendlyMeditation")`), and **one hotkey**: `ToggleSpawnCampFire` on End through an own input XML, then the legacy `input.xml` edit, each with the `input.settings` line; read the result in Key Bindings and by the option flipping. Answer the blob probes in [Open questions](open-questions.md) (state `@addField`, duplicate `@addMethod` across two blobs).
1. **FM-RT core with FM-KEYS:** the hold hotkey starts and ends sitting and fast-forward; HPM ramp; `PerformUpdate`; ends on hit, scene, combat; no save while meditating. Test by script (scripted input actions, as TGM's input simulation) and one real key press with the owner's OK.
2. **FM-RT rest:** refill after a game hour, time-scale option, notifications, manual and toggle modes, `MeditationFastForward`.
3. **FM-CAM.**
4. **FM-FIRE** (spawn, Igni pose, removal, toggle key).
5. **FM-BED** (and FM-CLOCK's stop button, if wanted).
6. **FM-POP**, **FM-QUEN** (only if 5.x needs them), Ghost Mode regression with FM installed.

## Compatibility

What Ghost Mode's port touches in the same places, and how this mod works with Preparations: [ghost-mode-compatibility.md](ghost-mode-compatibility.md).

## Deviations

Every difference from the legacy mod is listed in [deviations.md](deviations.md).
