# Ghost Mode and Preparations compatibility

This mod is independent of the Ghost Mode port ([TriangleGhostMode](https://github.com/TriangleAuthority/TriangleGhostMode)) and of the Preparations port, but must work with both.

## Ghost Mode

State on 2026-11-13 (Ghost Mode's `master` at 229b8e1d), read from both repositories (**unverified** in game). Legacy Ghost Mode 4.1 did not touch the meditation states, the clock or common menu, the bed or places of power.

| File or system | Ghost Mode's port | FM | Conflict and plan |
|---|---|---|---|
| `W3PlayerWitcher.MeditationRestoring` | `@wrapMethod` (STAM-10, `stamina/exhaustion.ws`): clears the new tree's lowered max stamina | Legacy FM never calls it after a meditation | **Real:** with FM, meditation no longer clears exhaustion. Plan: Ghost Mode also clears on leaving `MeditationWaiting` (a wrapper of its `OnLeaveState`, which vanilla and FM both pass through), or FM calls a neutral hook; owner's call |
| Meditation state events | Not wrapped | Wrapped, skipping `wrappedMethod` for FM meditation | Any later Ghost Mode wrapper there would be skipped when it sits further in the chain than FM's; keep Ghost Mode off these events or make FM's wrappers call `wrappedMethod` |
| Toxicity (`W3Effect_Toxicity.OnUpdate`, MUT-09 replacement, `mutations/toxicity.ws`) | No toxicity damage while the state is `Meditation` or `MeditationWaiting` | Keeps the vanilla state names | Compatible as long as FM keeps the names; toxicity now decays in accelerated time instead of being drained |
| Effect updates | Many effect wrappers and replacements (`InternalAddEffect`, `CalculateDuration`, regeneration, decoctions, STAM-07/10 per-tick code) | `PerformUpdate` with multi-second steps every frame | **Risk:** per-tick code tuned for frame steps; test Ghost Mode's regen, toxicity, exhaustion and decoction effects during FM fast-forward |
| `W3Effect_BasicQuen` | `@replaceMethod GetStacks` (SKL-11); legacy GM also stopped caching the Quen entity on add/load | Adds `OnEffectRemoved` (uses the cached `quenEntity`) | No overlap in methods; FM's addition may find `quenEntity` unset. Check in slice 6 |
| `MeditationForceAbort` | Called from Ghost Mode's `OnTakeDamage` replacement (ENCH) and `OnCombatStart` wrapper (MUT) | Wrapped to end FM meditation | Compatible (FM wraps, does not replace) |
| `CR4Player` | 33 methods wrapped or replaced, not `OnGameCameraPostTick` or `DisallowedActionDontShowHack` | Wraps both | No overlap |
| `CPlayerInput` | Wraps casting, dodge, special attacks, bombs | `Initialize`, `OnCommPanelMeditation`, `OnMeditationAbort`, new events | No overlap |
| `CR4IngameMenu` | Wraps `OnOptionValueChanged`, `SaveChangedSettings`, `OnPresetApplied` | Wraps `GetKeybindGroupTag` | No overlap |
| Options menu, strings | `modGhostMode.xml`; ids 2110992xxx | `modFMeditationConfig.xml`; ids 2112067xxx (Gwent: 2113322xxx) | No overlap |
| Alchemy refill (`SingletonItemsRefillAmmo`, CRAFT-07's alcohol rule) | Vanilla 5.x code, Ghost Mode's items | Called after one game hour | Compatible |
| Script blobs | `modGhostMode` blob | `modFriendlyMeditation` blob | Fine while no method is replaced by both; prefix all FM additions |
| Game install, saves | Shared slot, `game.py` needs Ghost Mode installed | Same as Gwent | As Gwent's tools.md |

## Preparations interaction

Preparations 6.2 (TrianglePreparations, `legacy-PREP`) was written to merge with FM: its `playerWitcher.ws` carries FM's field block and FM's `IsMeditating`, `IsSkippingTime`, `UpdateEffectsAccelerated` verbatim, so each mod compiled alone and Script Merger joined them. What Preparations uses from FM (all **unverified** in game):

| FM hook | Preparations' use |
|---|---|
| `fmedCanSpawnCampfire` | Set by `IsMeditationAllowed` and `CanSpawnCampfire()` (option, interior, settlement, existing fire, `prepConfig.HasResourcesForCampfire()`), false in `SetupFMed()`; FM reads it before spawning |
| `fmedAutorefillAlchemy` | `SetupFMed()`: true only if one of Preparations' autorefill options (bombs, oils, mutagens, potions) is on; FM's hourly refill obeys it |
| `fmedRefillIntervalSeconds`, `fmedApplyWitcherHouseBuffs`, `fmedWitcherHouseBuffsHours` | Declared with FM's defaults; not changed |
| `spawnedCampFire` | `HasCampfire()` counts FM's fire as the open fire Preparations requires |
| Timers `CampFireResourcesTimer`, `CampFireErrorMessageTimer` | Defined by Preparations (`prepConfig.RemoveResourcesForCampfire()` takes the timber; the error notification); FM starts them by name |
| `CanMeditate`, `CanMeditateWait`, `CanMeditateHere` | Replaced by Preparations with `IsMeditationAllowed()` and its error message; FM's `ModCanMeditate` calls all three |
| `IsMeditating()`, `IsSkippingTime()` | Preparations' menu rules (alchemy, skills, mutagens, repair, upgrades "only while meditating") |
| `UpdateEffectsAccelerated` | Preparations' `AdvanceTimeSeconds` (time cost of crafting, skills, repairs) |
| Option `modFriendlyMeditation` / `fmedSpawnCampfire` | Read by `prepConfig.fmedSpawnCampFire()` |
| FM preset "Preparations" (`fmed_prep_def`) | Campfire on, manual hotkey mode |

On 5.x the two ports ship separate blobs, each compiled against vanilla only, so they **cannot share declarations**: a field or method both declare by `@addField`/`@addMethod` may clash when both load (untested), and neither can reference the other's. Name-based links survive separate compilation: timers started by name, option ids, facts, and vanilla functions one mod wraps and the other calls (`CanMeditate` & co.). Proposed contract (to agree with the Preparations port):

- FM keeps calling `CanMeditate`, `CanMeditateWait`, `CanMeditateHere` (Preparations wraps them) and starting `CampFireResourcesTimer` and `CampFireErrorMessageTimer` by name (Preparations adds them with `@addMethod(W3PlayerWitcher) timer function`).
- The flags Preparations sets (`fmedCanSpawnCampfire`, `fmedAutorefillAlchemy`) and what Preparations reads (`spawnedCampFire`, "is meditating") pass through name-based channels instead of shared fields: e.g. facts or a hidden config var, or Preparations reads the player state names (`Meditation`, `MeditationWaiting`) directly. Each mod keeps its own prefixed helpers (`FMIsMeditating`, a Preparations counterpart).
- Option and preset ids stay legacy.
- Or merge the two ports into one blob later (as Gwent may merge into Ghost Mode).
