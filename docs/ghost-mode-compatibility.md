# Ghost Mode and Preparations compatibility

This mod is independent of the Ghost Mode port ([TriangleGhostMode](https://github.com/TriangleAuthority/TriangleGhostMode)) and of the Preparations port, but must work with both.

## Ghost Mode

State on 2026-11-13 (Ghost Mode's `master` at 229b8e1d), read from both repositories (**unverified** in game). Legacy Ghost Mode 4.1 did not touch the meditation states, the clock or common menu, the bed or places of power.

| File or system | Ghost Mode's port | FM | Conflict and plan |
|---|---|---|---|
| `W3PlayerWitcher.MeditationRestoring` | `@wrapMethod` (STAM-10, `stamina/exhaustion.ws`): clears the new tree's lowered max stamina at once | Legacy FM never calls it after a meditation | **Minor:** the lowered max still comes back with time. STAM-10's payback runs in `W3Effect_AutoStaminaRegen.OnUpdate(dt)` (`staminaRegen.ws`) while stamina is full, and FM's fast-forward feeds that effect large `dt` steps through `PerformUpdate`, so a few real seconds of fast-forward repay a full drain (at the defaults about 10 s of normal time for 60 points). What is lost is only the instant clear; whether stamina regen runs while sitting is a game check |
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

## Combining cleanly without a patch (analysis, 2026-11-13)

With the [proposed form](port-plan.md#decisions-made) (FM's fast-forward inside 5.x's idle `Meditation` state, never `MeditationWaiting`), Friendly Meditation combines with Ghost Mode and Preparations as separate blobs, in any folder order, with no patch. Read in code; nothing built or tested yet.

- **FM replaces or skips `wrappedMethod` in only two methods, which neither Ghost Mode nor Preparations touches:** `W3PlayerWitcherStateMeditation.MeditationWait` (always, for FM's fast-forward) and `W3PlayerWitcherStateMeditationBase.OpenUI` (only in the hold-N mode). Possibly a third, the entry function `InitState`, if the Igni pose needs it (also untouched by both).
- **Every method FM shares with them it wraps in calling form**, as they do: `OnSpawned`, `DisallowedActionDontShowHack` (Preparations' wrapper must call `wrappedMethod` too).
- **Methods they replace FM only calls**: `CanMeditate`, `CanMeditateWait`, `CanMeditateHere` (Preparations), `MeditationRestoring` (FM never calls it), `SingletonItemsRefillAmmo`, `ApplyWitcherHouseBuffs`, `OnTakeDamage`/`OnCombatStart` (Ghost Mode's replacements keep calling `MeditationForceAbort`, which reaches FM through `StopRequested`).
- **Ghost Mode's exhaustion:** its instant clear does not run after FM meditation (accepted: it comes back through regen).

## Compatibility patch (fallback)

**Decision** (owner, 2026-11-13): conflicts the mods cannot be written around go into **our own compatibility patch mod** in its own repository, not into Script Merger. None is left for Friendly Meditation with the design above. If one turns up:

- **Independent of the order of the mods below it.** The patch's folder sorts before all of them (e.g. `mod0TriangleCompat`; digits sort before letters), so it takes precedence whatever their names or `mods.settings` priorities say about each other. Its `@replaceMethod` of a method drops every other mod's change of that method, replacements and wrappers alike.
- **It covers every method that one mod replaces and another mod changes in any way**, not only the pairs that fail at the default order. A replacement in one mod and a wrapper in another combine only when the wrapping mod comes first, so any such pair depends on the order: the patch takes it over. For Friendly Meditation: any method it replaces (or skips `wrappedMethod` in) that Ghost Mode or Preparations also changes, found as the slices are built; for Preparations: its six wrappers on Ghost Mode's replacements and `MeditationRestoring`. Scope-based overrides count as replacements (how two blobs' overrides of one method combine is untested). Only methods that every mod merely wraps stay out of the patch: wrappers chain in any order.
- **For each such method, one `@replaceMethod` that contains every mod's change**: the replacing mod's body with the other mods' wrappers folded in (e.g. `ConsumeItem`: Ghost Mode's toxicity rule and Preparations' combat refusal). The fold-in fixes the order of the wrapped parts once, in the patch, instead of leaving it to the mod order.
- **Installed only together with every mod it merges** (owner, 2026-11-13); without one of them it is not installed. Its combined bodies need the mods' own fields and functions (Ghost Mode's option helpers, Preparations' settings). Each blob is compiled against vanilla only, so the patch must be compiled against the mods' sources as declarations (Script Merger's `Tools\WSCompiler\WSCompiler.exe --reference <mod scripts>` does that; `wcc_lite` has no such option). That works in game (**verified** 2026-11-13: a blob built this way called another blob's global function and `@addMethod`, read its `@addField` and created its class; TriangleGhostMode `docs/development.md`). The patch is therefore built with `WSCompiler`, referencing the mods' sources.
- **Enum members: not fixable by the patch** (each blob compiles them as numbers; TriangleGhostMode `docs/development.md`). Friendly Meditation adds none.
- **Upkeep:** the patch copies the mods' code of those methods, so a change to one of them in any mod needs a patch release; the patch's build should compare its copies with the mods' sources and fail when they drift. The patch is needed only when Ghost Mode and the other mod are both installed.
- **Where it lives:** its own repository next to the others (owner, 2026-11-13).

## Preparations interaction

**The interface as built** (PREP-FMED, **verified** 2026-11-15 with all three mods installed; each mod keeps its own prefixed names and neither declares a shared one, since two blobs must never declare the same name):

- **"Is meditating":** Preparations checks the state name `'Meditation'`; FM's fast-forward stays in that state.
- **"May FM make its campfire now":** FM sets the fact `fmed_campfire_query` and calls `CanMeditate()`; Preparations' wrapper writes `prep_fmed_campfire_ok` (2 yes, 1 no) from its campfire check; FM reads it and removes both. Without Preparations the answer is 0 and FM uses its own rule (no FM fire within 3 m).
- **Timber and the message:** Preparations adds `PrepCampFireResourcesTimer` and `PrepCampFireErrorMessageTimer`; FM starts them by name only after Preparations answered (the first when its fire is made, the second when the meditation starts with the fire refused).
- **FM's campfire counts as a fire:** tagged `fmed_campfire`; Preparations finds it by tag.
- **Refill:** FM always calls `SingletonItemsRefillAmmo`, which Preparations filters by type (legacy's `fmedAutorefillAlchemy` switch goes).
- **Options:** Preparations reads FM's legacy ids (`modFriendlyMeditation` / `fmedSpawnCampfire`) and detects FM by its options menu; with FM installed its own options default to legacy's "Friendly Meditation" preset.

**Legacy, for reference:**

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
