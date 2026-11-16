# Friendly Meditation for The Witcher 3 — 5.x port

Friendly Meditation is a gameplay mod for The Witcher 3 by Wasteland Ghost (wghost81), the author of Ghost Mode. It replaces the meditation menu with real-time meditation: Geralt sits down and time fast-forwards while buffs, toxicity and potions keep working, with a configurable camera, hotkeys (hold, switch or manual modes, a separate advance-time key) and campfire spawning. Everything is configurable from the options menu. Its last release, 2.3, targets the **legacy** game (patch 1.32); it does not work on current versions.

This repository ports it to **game version 5.x** (the 2026 remaster), the same way [TriangleGhostMode](https://github.com/TriangleAuthority/TriangleGhostMode) ports Ghost Mode and [TriangleGwentImprovements](https://github.com/TriangleAuthority/TriangleGwentImprovements) ports Gwent Improvements: re-expressed with 5.x's script annotations and DLC overrides instead of whole-file edits, one small slice at a time, each verified in game.

**First version: legacy behaviour, bugs fixed.** The port reproduces the legacy mod's behaviour and options. Bugs are fixed as they are found, and every difference from legacy is recorded in [docs/deviations.md](docs/deviations.md).

Preparations (same author) builds on Friendly Meditation: refilling while meditating, campfires spawned with timber, a "Friendly Meditation" preset. It is ported separately in [TrianglePreparations](https://github.com/TriangleAuthority/TrianglePreparations); the two ports must work together and apart.

**Compatible with Ghost Mode, merge possible later.** Like the Gwent port, this mod is developed separately from the Ghost Mode port but must work with it. See [docs/ghost-mode-compatibility.md](docs/ghost-mode-compatibility.md).

**Save-safe, as in legacy.** The legacy mod does not change saves and could be installed and removed at any point of a playthrough. The port keeps that.

## Status

All of the legacy mod's features are ported and tested by script in game, beside the Ghost Mode port and with Preparations: hotkey meditation in its three modes, the time fast-forward, refills, the camera, the campfire, the clock, Quen and places of power. Still to do before a release: a test of every key pressed by hand, and the witcher-house bed (Blood and Wine) in game. There is no packaged release yet.

## Installing

Needs The Witcher 3 game version 5.x (PC). Requirements of the legacy mod (Community Patch – Base, UPatch) do not apply: 5.x contains what it needed.

1. **Get the zip** `modFriendlyMeditation-<version>.zip`: from a release once there is one, or build it from this repository with `python tools/build_mod.py --ref master --out build/release --package` (needs Python 3 and REDkit, see [docs/tools.md](docs/tools.md)); the zip is then in `build/release/`.
2. **Extract it into the game folder** `<game>` (the folder that holds `bin` and `content`), keeping its folders: it puts the mod into `<game>\mods\modFriendlyMeditation\` and its options menu into `<game>\bin\config\r4game\user_config_matrix\pc\modFMeditationConfig.xml`. Nothing else in the game changes.
3. **Add the hotkeys:** with the game closed, open `Documents\The Witcher 3\input.settings` in a text editor and paste the lines from `input.settings.part.txt` (in `<game>\mods\modFriendlyMeditation\`, also [here](release/input.settings.part.txt)) at the top. They bind: hold N (or the right stick) to meditate, Space (or the left stick) to advance time in manual mode, End to switch the campfire on or off.
4. **Optional, to see the keys in Options → Key Bindings:** paste the lines from `input.xml.part.txt` (next to the other file, also [here](release/input.xml.part.txt)) into the game's `input.xml` as that file explains. The keys work without this step. A game update may replace `input.xml`; paste them again afterwards.
5. Start the game: the options are under **Options → Mods → Friendly Meditation**. They start at the legacy defaults; with Preparations installed, the campfire is on and the hotkey is in manual mode (legacy's "Preparations" preset).

The mod does not change saves: it can be installed or removed at any point of a playthrough. To remove it, delete the `modFriendlyMeditation` folder from `<game>\mods\`, the menu file `modFMeditationConfig.xml` from step 2, and the lines from step 3.

## Using it with other mods (Script Merger)

**With the Ghost Mode, Preparations and Gwent Improvements ports: nothing to merge.** They are built to run side by side as separate mods, in the default folder order (tested in game, with Ghost Mode's full regression run passing beside them).

**With other mods:** Script Merger merges *loose* scripts (`.ws` files) that two mods both edited. This port ships compiled scripts instead (`content\precompiled.rsblob`, built with 5.x's script annotations), which Script Merger cannot merge. Use it to find conflicts, not to fix this mod's:

1. Install all your mods first, this one included.
2. Run Script Merger Remastered (the 5.x version of Script Merger, on Nexus Mods) and refresh the conflict list.
3. Merge the conflicts it can merge between your *other* mods as usual.
4. Conflicts that involve this mod are listed as "not mergeable": leave them unmerged. The game resolves them itself:
   - Where two compiled mods replace the same function, the mod whose folder name sorts first wins. To change that, give the mod you want to win a lower `Priority` in `Documents\The Witcher 3\mods.settings` (a section `[modFriendlyMeditation]` with `Priority=50`, for example; the default is 100).
   - Where a mod only adds code around a function (most of this port's changes), both mods' additions run.
   - A loose-script mod that edits the same function as this mod loses to it, whatever its priority.
5. Do **not** let Script Merger Remastered 3.x merge this mod's compiled scripts into a merged mod: in tests of that feature, compiled mods lost some of their changes.

If two mods still clash in game, keep the one you prefer first in the load order, or do not combine them.

## Differences from the legacy mod

Every difference from the legacy mod, with the reason and who decided it, is listed in [docs/deviations.md](docs/deviations.md).

## How this repository is organised

The same layout as TriangleGhostMode and TriangleGwentImprovements: every branch starts from the same root commit, the legacy (1.32) game files, so every change is visible as a diff.

| Branch | Contents |
|---|---|
| `vanilla-1.32` | Unmodified legacy (1.32) game files at the mod's paths: the baseline every other branch starts from |
| `legacy-FM` | `vanilla-1.32` + Community Patch – Base (the mod's dependency) + Friendly Meditation 2.3 (two commits) |
| `vanilla-5.x` | `vanilla-1.32` + the same game files from the current 5.x release (Steam build 26238013, `witcher3.exe` 5.0.0.1090142) |
| `master` | `vanilla-5.x` + the port (work in progress), plus the README, tools and docs |

- What the mod changed: `git diff legacy-FM~1 legacy-FM` (add `-w`)
- What CDPR changed in 5.x: `git diff vanilla-1.32...vanilla-5.x`
- The port so far: `git diff vanilla-5.x...master -- modFriendlyMeditation`

`modFriendlyMeditation/` contains the full vanilla file set (every script, every gameplay XML/CSV) with the mod's changes applied on `legacy-FM` and `master`, so it is a reference tree, not a ready-to-install mod. See [docs/repository.md](docs/repository.md).

## Documentation

See [docs/](docs/README.md). Start with [docs/port-plan.md](docs/port-plan.md) for where the port stands and what's next.
