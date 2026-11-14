# The legacy mod: Friendly Meditation 2.3

What the legacy mod is, how it was packaged, and what it changes. Everything here was read from the files on `legacy-FM` (`git diff -w legacy-FM~1 legacy-FM`), **unverified** in game.

## The release

- **Friendly Meditation 2.3** by wghost81 (Wasteland Ghost, also the author of Ghost Mode), Nexus mod 2067, file `modFriendlyMeditation-2067-2-3`. Readmes: `release/README.txt`, `release/README_RUS.txt`.
- **Dependency:** the readme asks for UPatch "or Community Patch – Base". The scripts were written on top of Community Patch – Base v1.0, which `legacy-FM` carries as its own commit (`legacy-FM~1`). FM calls nothing that only the patch provides; its only patch-based file is `ingameMenu.ws`. 5.x contains most of Community Patch – Base (see TriangleGhostMode's `docs/legacy-ghost-mode.md#dependencies`), and FM needs none of the rest.
- **Save impact (readme):** "doesn't change your save files": no `saved` field is added; installing or removing it mid-game is safe.

| Shipped | Installed to | In the repository (`legacy-FM`) |
|---|---|---|
| `content/scripts/*.ws` (13 vanilla scripts edited, 1 new) | `<game>\Mods\modFriendlyMeditation\` | `modFriendlyMeditation/scripts/` (UTF-8) |
| `content/<lang>.w3strings` (en, de, es, jp, ru) | same | Sources only: `modFriendlyMeditation/localization/<lang>.csv` (the `.w3strings` are not kept) |
| `modFMeditationConfig.xml` (options menu) | `<game>\bin\config\r4game\user_config_matrix\pc\` by hand or by TW3MM | `modFriendlyMeditation/menu/modFMeditationConfig.xml` |
| `input.xml` (vanilla's, with the hotkeys added) | same folder; overwrite, or copy the marked blocks by hand | `modFriendlyMeditation/bin/config/r4game/user_config_matrix/pc/input.xml` |
| `user.settings.part.txt` (option defaults) | pasted at the top of `Documents\The Witcher 3\user.settings` | `release/user.settings.part.txt` |
| `input.settings.part.txt` (default keys) | pasted at the top of `Documents\The Witcher 3\input.settings` | `release/input.settings.part.txt` |

Packaging notes:

- **Strings:** ids **2112067000–2112067045** (the community encoder's id space 2067, the Nexus id; `readme-localization.txt`: `w3strings.exe --encode en.csv --id-space 2067`). 42 rows; 002–007, 009 and 033 unused. `es` is translated, `de` and `ru` mostly, `jp` partly. Keys follow the legacy menu convention (`panel_*`, `option_*`, `preset_value_*`, `preset_Mods_friendly_meditation_*`), plus the action names (`HoldToMeditate`, `MeditationFastForward`, `ToggleSpawnCampFire`) as key-binding labels and `panel_Mods` ("Mods"), which 5.x has as its own `panel_mods`.
- **`user.settings.part.txt` has no `fmedBeSilent`** (preset 0 sets it). The readme warns that without the pasted defaults "most of the mod's options will be off".
- **Hotkeys need two edits** (readme): the `input.xml` entries make the actions appear in Key Bindings; the `input.settings` lines bind the keys ("if you miss this step, you will see hotkeys in game menu, but you will be unable to assign them properly").

## What it changes

Code is marked `//---=== modFriendlyMeditation ===---` or `//modFriendlyMeditation begin/end`. FM replaces the vanilla meditation flow rather than adding to it: three state files are rewritten, and the clock menu, common menu and input code are cut over to FM's entry points.

### FM-RT: real-time meditation (states)

Files: `player/states/meditation/meditation.ws`, `meditationWaiting.ws`, `meditationBase.ws` (all "reworked"), `player/playerWitcher.ws`.

- **Entry and exit:** `W3PlayerWitcher.ModStartMeditation(optional isPlayerMeditatingInBed, optional isFromClock, optional endTime)` checks `ModCanMeditate`, closes any menu, stores the three arguments in new fields (`medIsPlayerMeditatingInBed`, `medIsFromClock`, `medEndTime`), clears the behaviour variable `MeditateAbort` and `PushState('Meditation')`; when already meditating it updates them and, from the clock, starts fast-forward. `ModEndMeditation()` sets `MeditateAbort` = 1, `PopState()`, resets the fields and closes any menu. State stack: Exploration → Meditation → MeditationWaiting (fast-forward), each pushed and popped.
- **`ModCanMeditate(optional inBed)`:** true in bed; otherwise vanilla `CanMeditate()`, `CanMeditateWait(true)`, `CanMeditateHere()` ("checking everything for Preparations compatibility": Preparations replaces these three), and `ModCanMeditateHereExt()` (no vehicle, swimming, diving or negative submerge depth).
- **`Meditation` state** (sitting, time normal): `OnEnterState` ends at once if `MeditateAbort` > 0; otherwise sets `MeditateWithIgnite`/`HasCampfire` = 0, `BlockGameplayActions(true)` (`BlockAllActions('Meditation')` except meditation, fast menu, inventory, alchemy, character, journal, map, glossary, radial menu), **`CreateNoSaveLock("Meditation")` (no saving while meditating)**, `HideItemsInHands()` (sword sheathed, held item hidden, crossbow holstered), `InternalBeginMeditation()` (campfire, then `PlayerStartAction(PEA_Meditation)`; in bed it skips the animation), and timers `MeditationModulesOnTimer`/`OffTimer` "FHUD compatibility" (Friendly HUD; FM does not define them). Idle is reached on the behaviour notification `OnPlayerActionStartFinished` (state event `OnBehaviorGraphNotification`) → `SetMeditationIdle()`, which starts fast-forward unless the hotkey mode is manual and the meditation was not started from the clock. `OnPlayerTickTimer` ends meditation when the player action is no longer `PEA_Meditation`/`PEA_GoToSleep`. `OnLeaveState` (not to Waiting) unblocks, releases the save lock, `InternalEndMeditation()` (bed: `ManageSleeping()`, `SetWasUsed(false)`; ends fast-forward; despawns the campfire; `PlayerStopAction(PEA_Meditation)`) and sets the fact `MeditationWaitFinished`. Vanilla's latent `InitState`/`Loop`/`StopMeditation`, the clock-menu opening on anim event `OpenUI` and `MeditationWait` are gone. `StartFastforward()`/`EndFastforward()` push/pop `MeditationWaiting`.
- **`MeditationWaiting` state** (fast-forward), per tick (`OnPlayerTickTimer` → `MeditationUpdate()`), no latent loop:
  - **Time:** hours per minute ramp from the stored value by `fmedHoursPerMinutePerSecond` × real seconds since start, capped at `fmedMaxHoursPerMinute` (`theGame.SetHoursPerMinute`; option labels: game minutes per real second). `GetFastForwardSystem().BeginFastForward()` on enter, `AllowFastForwardSelfCompletion()` on leave, HPM restored.
  - **Buffs:** `W3PlayerWitcher.UpdateEffectsAccelerated(realTimeSecs, hpm / storedHpm)` → `effectManager.PerformUpdate(realTimeSecs × acceleration)` each tick, so potions, toxicity, regeneration (Sun and Stars) and every timed effect run in accelerated time. `realTimeSecs` = `ConvertGameSecondsToRealTimeSeconds(game seconds since last tick)`, which divides by the current HPM. The engine's own effect tick runs as well.
  - **Animation speed (option "Speed up animations", off by default):** once HPM reaches the max, HPM goes back to normal and `theGame.SetTimeScale(hpm / storedHpm, 'FriendlyMeditation', 100)` speeds up the whole game instead; the extra effect update stops (the engine ticks faster).
  - **Refill:** `MeditationCheckRefill()` → `W3PlayerWitcher.MeditationRefill(gameSecs)`: once per fast-forward session, after `fmedRefillIntervalSeconds` (3600, one game hour) and if `fmedAutorefillAlchemy`, `inv.SingletonItemsRefillAmmo()`. The game time counts from entering `MeditationWaiting`, so stopping fast-forward resets it.
  - **Witcher house (Blood and Wine):** on leave, `CheckWitcherHouseBuffs(gameSecs)`: in bed and at least `fmedWitcherHouseBuffsHours` (1) passed → vanilla `ApplyWitcherHouseBuffs()`.
  - **From the clock:** ends when the game hour equals `medEndTime` (`ModEndMeditation`).
  - **Feedback:** light controller vibration when health is full and on each change of day part; HUD notifications "Waiting is started/stopped" unless `fmedBeSilent`.
  - Facts as vanilla: `MeditationWaitStartDay`, `MeditationWaitStartHour`, `MeditationStarted` (1 on enter, 0 on leave).
  - Its own `BlockAllActions('MeditationWaiting')` except meditation.
- **Not done any more:** vanilla's end of waiting, `MeditationRestoring(simulatedTime)` (full heal below Blood and Broken Bones, toxicity and adrenaline drained, refill, `SimulateBuffTimePassing`). FM calls it only from the clock menu when game time is paused by a quest (`GamePausedNotByUI`), as vanilla did. So FM meditation **does not heal, clear toxicity or clear adrenaline** by itself; regeneration and decay happen in accelerated time.
- **`MeditationBase.StopRequested`** now calls `ModEndMeditation()`, so vanilla callers (`OnReactToBeingHit`, `MeditationForceAbort`) end FM meditation.
- **`W3PlayerWitcher`:** `IsMeditating()` (state `Meditation`), `IsSkippingTime()` (state `MeditationWaiting`), `GetIsPlayerMeditatingInBed()`, `GetMeditationTargetTime()`, `GetMeditationStartedByClock()`, `MeditationStartFastforward()`/`MeditationEndFastforward()`; `Meditate()` now only opens the clock menu (`RequestMenuWithBackground('MeditationClockMenu', 'CommonMenu')`) after `ModCanMeditate`; `MeditationForceAbort(forceCloseUI)` → `ModEndMeditation()` then closes menus; `OnBlockingSceneStarted` → `ModEndMeditation()`.
- **`CR4Player.DisallowedActionDontShowHack`** returns true while meditating: no "action not allowed" HUD messages from the blocks.

### FM-CAM: meditation camera

Files: `meditationBase.ws`, `r4Player.ws`.

- `MeditationBase.OnEnterState` reads the camera options once. `OnGameCameraTick` (not in bed, camera on): face Geralt (yaw + 180) if `fmedCamFacePlayer`, pitch `fmedCamPitch`, distance `fmedCamDistance` (0 = leave), pivot Z offset `fmedCamZOffset`, local X offset `fmedCamXOffset` (damped spring). `OnGameCameraPostTick`: FOV damped to `fmedCamFOV`. A value of 0 leaves that part alone.
- Leaving meditation with the face-Geralt camera calls `CR4Player.fmedRequestCameraHeading()`; `CR4Player.OnGameCameraPostTick` then turns the camera back behind Geralt for 1.5 s (new field `fmedCameraRequestTimeStamp`, `fmedResetCameraRequest()`).
- Vanilla's fixed meditation camera (in `meditation.ws`) is removed. Presets: see [Options](#fm-menu-options-menu).

### FM-KEYS: hotkeys and modes

Files: `player/playerInput.ws`, `gui/main_menu/ingameMenu.ws`, `input.xml`, `input.settings.part.txt`.

| Action | Default keys (context) | Handler |
|---|---|---|
| `HoldToMeditate` | hold N 0.4 s, hold pad right stick (`State=Duration,IdleTime=0.4`, `[Exploration]`) | `CPlayerInput.OnHoldToMeditate` |
| `MeditationFastForward` | Space, pad left stick (`[Exploration]`) | `CPlayerInput.OnMeditationFastForward` |
| `ToggleSpawnCampFire` | End (`[Exploration]`) | `CPlayerInput.OnToggleSpawnCampFire` |
| `MeditationStop` | C, pad Y (`[MEDITATION_CLOCK_CONTEXT]`, a new context) | `CR4MeditationClockMenu.OnMeditationStop` |

- Listeners added in `CPlayerInput.Initialize`. `input.xml` adds the first three to the `PCInput` group (`MeditationFastForward` tagged `input_overlap2`) and `MeditationStop` to a new `Hidden` group (not shown).
- **Hotkey modes** (`Virtual_fmedHotkeyBehavior`): 0 **hold** (press starts, release ends), 1 **toggle** (press starts, press again ends), 2 **manual** (press toggles the meditation pose; time advances only while `MeditationFastForward` is held, or from the clock). In every mode a press while meditating ends it.
- **`MeditationFastForward`:** while meditating (not in bed), press starts fast-forward, release or a second press ends it, so in effect "hold Space".
- **N shared with the clock menu:** `OnCommPanelMeditation` now opens the menu on release only if the hold did not fire (`inFriendlyMeditation`; vanilla: on release). `CR4IngameMenu.GetKeybindGroupTag` puts `HoldToMeditate` and `PanelMeditation` (and any var tagged `input_overlap_fmed1`) in one overlap group, so Key Bindings accepts both on one key.
- **`OnMeditationAbort`** (vanilla abort action) → `ModEndMeditation()`.
- **`OnToggleSpawnCampFire`:** flips `fmedSpawnCampfire` and saves the settings (`CModFMeditationConfig.SetSpawnCampFire`), with a notification unless silent.

### FM-FIRE: campfire spawning

Files: `meditation.ws`, `playerWitcher.ws`.

- On entering meditation (not in bed) with `fmedSpawnCampfire` on: if `fmedCanSpawnCampfire` (a Preparations hook, default true) and no FM fire within 3 m, behaviour variable `MeditateWithIgnite` = 1 (Geralt lights it with Igni) and `SpawnCampFireTimer` after 4.5 s: loads `environment\decorations\light_sources\campfire\campfire_01.w2ent` (exists in 5.x, `blob.bundle` and world bundles; read from the TOCs), places it 0.8 m in front of Geralt (Z from navmesh, then physics), `W3Campfire.ToggleFire(true)`, stores it in `W3PlayerWitcher.spawnedCampFire`, and starts the timer `CampFireResourcesTimer` (0.1 s, "Preparations compatibility"; FM does not define it). If `fmedCanSpawnCampfire` is false: timer `CampFireErrorMessageTimer` ("spawning was turned off by Preparations"; also not defined in FM).
- **FM itself needs no timber**; Preparations' `CampFireResourcesTimer` takes the resources.
- On leaving, unless `fmedDoNotDespawnCampfire`: behaviour variable `HasCampfire` = 1 and `DeSpawnCampFireTimer` (1.5 s) puts the fire out and destroys it.
- `SpawnCampFireTimer` is a `timer function` of the `Meditation` state but started with `thePlayer.AddTimer`.

### FM-CLOCK: meditation clock menu and common menu

Files: `gui/menus/meditationClockMenu.ws`, `gui/menus/commonMenu.ws`.

- **`CR4MeditationClockMenu`:** no more `MeditationClockStart/Stop`, `StartWaiting`/`StopWaiting`/`MeditatingEnd` or `isGameTimePaused`. `OnConfigUI`: if a clock meditation is running, shows the current and target hour; bonus time = `fmedWitcherHouseBuffsHours`; in the witcher house with the bed used → `isPlayerMeditatingInBed`, `SetMeditationBonuses()`; `canMeditateWait` = `ModCanMeditate(inBed)` (game unpaused for the check), or false with `MeditationRestoring(0)` when time is paused by a quest; `RegisterActions()` stores input context `MEDITATION_CLOCK_CONTEXT` and listens to `MeditationStop`. `OnMeditate(dayTime)` → `ModStartMeditation(inBed, true, CeilF(dayTime))` (the menu closes; time passes in the world, not behind the menu). `OnStopMeditate` and `OnMeditationStop` → `ModEndMeditation()`. `SetButtons` adds "Stop meditation" (C / pad Y) while meditating. `OnCloseMenu` in bed without a meditation → `ManageSleeping()`.
- **`CR4CommonMenu`:** meditation mode removed (`m_mode_meditation`, `m_had_meditation`, `SetMeditationMode`, `StopMeditation`, `GetIsPlayerMeditatingInBed` commented out); `OnClosingMenu` no longer stops waiting or meditation or shuts down fast-forward; the meditation tab's enabling ignores the bed.

### FM-BED: witcher bed (Corvo Bianco)

Files: `gameplay/interactive/witcherBed.ws`, `playerWitcher.ws`, clock menu, states.

- `witcherBed.ws`: only a commented-out `BlockGameplayActions` (no effect).
- `W3PlayerWitcher.OnPlayerActionStartFinished`: on `PEA_GoToSleep`, `UnblockAction(EIAB_OpenMeditation / EIAB_MeditationWaiting, 'WitcherBed')` before the clock menu opens, so sleeping can use FM's flow. In bed, meditation skips the sitting animation and the camera, and fast-forward starts at once.

### FM-POP: places of power

File: `gameplay/interactive/placeOfPowerEntity.ws`. `PlaceOfPower_Idle.OnEnterState` and `PlaceOfPower_Activated.OnEnterState` stop the meditation action only when coming from `PlaceOfPower_Channeling` (vanilla stopped it always, which broke a meditation started near a place of power). `PlaceOfPower_Channeling`'s latent loop resets `MeditateWithIgnite`/`HasCampfire` before `PlayerStartAction(PEA_Meditation)`.

### FM-QUEN: basic Quen

File: `gameplay/effects/effects/other/basicQuen.ws`. New `W3Effect_BasicQuen.OnEffectRemoved`: restarts the Quen entity's `Expire` timer at 0.1 s, so the shield goes when the buff is removed (for example when an accelerated update expires it; the reason is not stated).

### FM-MENU: options menu

Files: `menu/modFMeditationConfig.xml`, `scripts/fmedconfig/modFMeditationConfig.ws`.

`CModFMeditationConfig` (created in `W3PlayerWitcher.OnSpawned` as `fMeditationConfig`; global `GetFMeditationConfig()`) reads each value live through `GetInGameConfigWrapper().GetVarValue`. Options → Mods → Friendly Meditation:

**Meditation** (group `modFriendlyMeditation`):

| Var | Type | Default (preset 0) |
|---|---|---|
| `fmedMaxHoursPerMinute` | slider 0–300 | 60 |
| `fmedHoursPerMinutePerSecond` | slider 0–50 | 10 |
| `fmedUseTimescale` (speed up animations) | toggle | false |
| `fmedSpawnCampfire` | toggle | false |
| `fmedDoNotDespawnCampfire` | toggle | false |
| `Virtual_fmedHotkeyBehavior` → `fmedHotkeyBehavior` | options: hold / toggle / manual | 0 |
| `fmedBeSilent` (no text messages) | toggle | 0 |

Presets: Default; Acceleration (20/s, timescale on); No acceleration; **Preparations** (campfire on, manual hotkey mode).

**Camera** (group `modFriendlyMeditationCamera`):

| Var | Type | Default (preset 0) |
|---|---|---|
| `fmedUseMeditationCam` | toggle | true |
| `fmedCamFacePlayer` | toggle | true |
| `fmedCamFOV` | slider 30–90 | 40 |
| `fmedCamDistance` | slider 0–20 | 3.8 |
| `fmedCamPitch` | slider −90–90 | −15 |
| `fmedCamXOffset` | slider −2–2 | 0.5 |
| `fmedCamZOffset` | slider −2–2 | 0.5 |

Presets: Default (face Geralt); Sightseeing (from behind, FOV 50, distance 2, pitch 0); FOV only (exploration camera, FOV 80); Off.

### Hooks for other mods

Fields on `W3PlayerWitcher`, not set by FM itself, for Preparations to change: `fmedCanSpawnCampfire` (true), `fmedAutorefillAlchemy` (true), `fmedRefillIntervalSeconds` (3600), `fmedApplyWitcherHouseBuffs` (true), `fmedWitcherHouseBuffsHours` (1); `spawnedCampFire`. Timers started by name and defined elsewhere: `CampFireResourcesTimer`, `CampFireErrorMessageTimer` (Preparations), `MeditationModulesOnTimer`, `MeditationModulesOffTimer` (Friendly HUD). See [port-plan.md](ghost-mode-compatibility.md#preparations-interaction).
