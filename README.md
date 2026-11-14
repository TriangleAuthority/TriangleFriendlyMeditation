# Friendly Meditation for The Witcher 3 — 5.x port

Friendly Meditation is a gameplay mod for The Witcher 3 by Wasteland Ghost (wghost81), the author of Ghost Mode. It replaces the meditation menu with real-time meditation: Geralt sits down and time fast-forwards while buffs, toxicity and potions keep working, with a configurable camera, hotkeys (hold, switch or manual modes, a separate advance-time key) and campfire spawning. Everything is configurable from the options menu. Its last release, 2.3, targets the **legacy** game (patch 1.32); it does not work on current versions.

This repository ports it to **game version 5.x** (the 2026 remaster), the same way [TriangleGhostMode](https://github.com/TriangleAuthority/TriangleGhostMode) ports Ghost Mode and [TriangleGwentImprovements](https://github.com/TriangleAuthority/TriangleGwentImprovements) ports Gwent Improvements: re-expressed with 5.x's script annotations and DLC overrides instead of whole-file edits, one small slice at a time, each verified in game.

**First version: legacy behaviour, bugs fixed.** The port reproduces the legacy mod's behaviour and options. Bugs are fixed as they are found, and every difference from legacy is recorded in [docs/deviations.md](docs/deviations.md).

Preparations (same author) builds on Friendly Meditation: refilling while meditating, campfires spawned with timber, a "Friendly Meditation" preset. It is ported separately in [TrianglePreparations](https://github.com/TriangleAuthority/TrianglePreparations); the two ports must work together and apart.

**Compatible with Ghost Mode, merge possible later.** Like the Gwent port, this mod is developed separately from the Ghost Mode port but must work with it. See [docs/ghost-mode-compatibility.md](docs/ghost-mode-compatibility.md).

**Save-safe, as in legacy.** The legacy mod does not change saves and could be installed and removed at any point of a playthrough. The port keeps that.

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
