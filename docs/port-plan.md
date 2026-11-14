# Port plan

## Where the port stands

**2026-11-13: slice 0 under way.** The baselines and the legacy mod are committed ([repository.md](repository.md)); the legacy mod is described in [legacy-mod.md](legacy-mod.md) and compared with 5.x in [meditation-5.x.md](meditation-5.x.md) (both read from the files, **unverified** in game). The build tools are in and the compile check works (**verified**: a ping test script compiles, [tools.md](tools.md)). Next: the owner's remaining [decisions](#decisions-to-make), then the rest of slice 0 in game.

## Approach

As in TriangleGhostMode and TriangleGwentImprovements: reproduce the legacy mod's behaviour in the least invasive 5.x form (script annotations, the options menu XML, whole files only where needed), one small slice at a time, each verified in game on the shared game slot. Bugs in the legacy mod are fixed as found and listed as deviations. Prefix for everything the mod adds: `FM`/`fm` (see [Preparations](ghost-mode-compatibility.md#preparations-interaction) for the legacy `fmed*` names). No DLC is needed: FM changes no XML and no binary resource.

## Decisions made

- **FM replaces 5.x's meditation, as legacy replaced 1.32's; the port stays as close to legacy as is reasonable** (owner, 2026-11-13, replacing two earlier same-day decisions that kept 5.x's flow). Every way into meditation (N, the radial menu and its key, the minimap clock, the panels' Meditation tab, the bed) ends in FM's real-time meditation, and FM's hotkeys work as in legacy (hold N, advance time, campfire, stop). Where 5.x's own meditation code gives the same result more cleanly, the port builds on it instead of copying legacy's states:
  - **Proposed form:** keep 5.x's entry (`Meditate()`: sit down in place, turn to open space, the clock over the world) and 5.x's clock menu (it already hides itself while time passes), and replace only what happens once an hour is chosen: 5.x's time-lapse in `MeditationWaiting` becomes FM's real-time fast-forward (hours per minute ramping up, effects updated in accelerated time, refill after a game hour, no `MeditationRestoring` at the end, stops at the chosen hour). The hold-N hotkey sits Geralt down the same way without opening the clock and fast-forwards as its mode says. Differences from legacy this leaves (5.x sits down before the clock opens; legacy closed the menu first) are deviations, recorded when built.
  - **Radial:** all radial entries (the slot, the meditation key while the radial menu is open, `CR4HudModuleRadialMenu.OnOpenMeditation`, and tapping the minimap's clock, `CR4HudModuleMinimap2.OnTapTime`) pass through `W3PlayerWitcher.OnRadialMenuItemChoose("Meditation")` → `Meditate()`, so they follow N's path. The two HUD callers show "not allowed here" unless Geralt is in state `Meditation` right after the call. Neither Ghost Mode nor Preparations touches this event (checked 2026-11-13).
- **No healing at the end of FM meditation** (owner, 2026-11-13: "as close to the original as is reasonable"). Legacy's rule: FM meditation never calls `MeditationRestoring`; health, toxicity and adrenaline change only through effects running in accelerated time; alchemy refills after one game hour of fast-forward. Ghost Mode's exhaustion comes back through regen during the fast-forward ([ghost-mode-compatibility.md](ghost-mode-compatibility.md)).
- **Hotkeys are kept** (owner, 2026-11-13). Legacy needed two manual steps: the actions added to `bin\config\r4game\user_config_matrix\pc\input.xml` (overwrite it, or merge the marked blocks) so they show in Key Bindings, and the default keys pasted into `Documents\The Witcher 3\input.settings` (`release/input.settings.part.txt`: hold N or the right stick to meditate, Space or the left stick to advance time, End for the campfire, C or Y to stop in the clock). Slice 0 finds the least manual 5.x way ([meditation-5.x.md](meditation-5.x.md#hotkeys-on-5x)).

## Decisions to make

1. **Hotkey install**, once slice 0 shows what works ([meditation-5.x.md](meditation-5.x.md#hotkeys-on-5x)): whether the install adds the `input.settings` lines itself, or players paste them as in legacy.
2. **Names shared with Preparations** ([below](ghost-mode-compatibility.md#preparations-interaction)).

## Features and port forms

| ID | Feature | Port form | Difficulty |
|---|---|---|---|
| FM-MENU | Options → Mods → Friendly Meditation (two groups, 14 options, 8 presets), `CModFMeditationConfig` | `menu/modFMeditationConfig.xml` (legacy ids, UTF-8 BOM); config class in a new file, defaults in script for unset values; strings 2112067000–045 from the five CSVs | Small |
| FM-KEYS | Hotkeys `HoldToMeditate`, `MeditationFastForward`, `ToggleSpawnCampFire`, `MeditationStop`; hold/toggle/manual modes; N shared with the clock | Bindings: input.settings lines plus `input.xml` entries or an own input XML (slice 0 decides); `@wrapMethod(CPlayerInput) Initialize` + `@addMethod` events; `@replaceMethod(CPlayerInput) OnCommPanelMeditation`; `@wrapMethod OnMeditationAbort`; `@wrapMethod(CR4IngameMenu) GetKeybindGroupTag` | **Hard** (no supported mod path for bindings) |
| FM-RT | Real-time meditation: states, HPM ramp, effects updated in accelerated time, optional time scale, refill after an hour, no save while meditating, blocks, notifications, vibration | Wrappers on `W3PlayerWitcherStateMeditation` and `...MeditationWaiting` events (`OnEnterState`, `OnLeaveState`, `OnPlayerTickTimer`, `StopRequested`) that run FM's code for FM meditation and skip `wrappedMethod`; FM's logic in `@addMethod(W3PlayerWitcher)` helpers and `@addField`s; `@wrapMethod` of `OnPlayerActionStartFinished`, `MeditationForceAbort`, `OnBlockingSceneStarted`, `CR4Player.DisallowedActionDontShowHack` | **Hard** |
| FM-CAM | Meditation camera, presets, camera return after meditation | `@wrapMethod(W3PlayerWitcherStateMeditationBase) OnGameCameraTick` (and the `Meditation` state's own camera events), `@wrapMethod(CR4Player) OnGameCameraPostTick` for FOV and the 1.5 s return | Medium |
| FM-FIRE | Campfire spawned with Igni, toggle key, kept or removed afterwards | `@addMethod(W3PlayerWitcher)` timers (`FMSpawnCampFireTimer`, `DeSpawnCampFireTimer`); `campfire_01.w2ent` and `W3Campfire` unchanged in 5.x; behaviour variables to check in game | Medium (animation check) |
| FM-CLOCK | Clock menu starts FM meditation to an hour, shows the target, "Stop meditation" button; common menu no longer stops it | On 5.x's clock ([Decisions made](#decisions-made)): `@wrapMethod` of `CR4MeditationClockMenu.OnMeditate` (and `OnStopMeditate`) so the chosen hour starts FM's fast-forward; the stop key (`MeditationStop`, C / Y) and the target-hour display as legacy | Medium |
| FM-BED | Witcher-house bed: meditation without the sitting animation, bonuses after an hour | 5.x already leaves meditation unblocked in bed; FM's bed branch in the state wrappers; `ApplyWitcherHouseBuffs` unchanged | Small |
| FM-POP | Places of power no longer cancel a meditation | 5.x fixed it itself (`StopMeditationAction`, `BlockMeditation`); only FM's behaviour-variable reset before channeling may be needed: `@wrapMethod(CMajorPlaceOfPowerEntityStatePlaceOfPower_Channeling) OnEnterState` | Small (likely nothing) |
| FM-QUEN | Basic Quen's shield expires with its buff | Scope-based override block `class W3Effect_BasicQuen extends CBaseGameplayEffect { event OnEffectRemoved() ... }` (inherited event); only if 5.x still shows the problem | Small |

## Slices

0. **Tooling and probes:** the tools from TriangleGwentImprovements (done 2026-11-13) (`paths.MOD = modFriendlyMeditation`), compile check, install on the shared slot with Ghost Mode installed (as Gwent's [tools.md](https://github.com/TriangleAuthority/TriangleGwentImprovements/blob/master/docs/tools.md#testing-in-game) does). Show FM-MENU in game (`autoconfig("modFriendlyMeditation")`), and **one hotkey**: `ToggleSpawnCampFire` on End through an own input XML, then the legacy `input.xml` edit, each with the `input.settings` line; read the result in Key Bindings and by the option flipping. Answer the blob probes in [Open questions](open-questions.md) (state `@addField`, duplicate `@addMethod` across two blobs).
1. **FM-RT core with FM-KEYS:** the hold hotkey starts and ends sitting and fast-forward; HPM ramp; `PerformUpdate`; ends on hit, scene, combat; no save while meditating. Test by script (scripted input actions, as TGM's input simulation) and one real key press with the owner's OK.
2. **FM-RT rest:** refill after a game hour, time-scale option, notifications, manual and toggle modes, `MeditationFastForward`.
3. **FM-CAM.**
4. **FM-FIRE** (spawn, Igni pose, removal, toggle key).
5. **FM-CLOCK** (the clock starts FM's fast-forward to the chosen hour; stop key), **FM-BED**.
6. **FM-POP**, **FM-QUEN** (only if 5.x needs them), Ghost Mode regression with FM installed.

## Compatibility

What Ghost Mode's port touches in the same places, and how this mod works with Preparations: [ghost-mode-compatibility.md](ghost-mode-compatibility.md).

## Deviations

Every difference from the legacy mod is listed in [deviations.md](deviations.md).
