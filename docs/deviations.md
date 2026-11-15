# Deviations from the legacy mod

Every place where the port behaves differently from Friendly Meditation 2.3, with the reason, who decided and when, and a question for the original author (wghost81) where their intent is unclear. Add an entry whenever the port deviates, in the same commit.

"Owner" is this project's owner; "porter's call" means not yet confirmed by the owner.

| # | Feature | Legacy | Port | Why | Decided | Question for the author |
|---|---|---|---|---|---|---|
| 1 | FM-MENU | The defaults come from `user.settings` lines the player pastes by hand (`release/user.settings.part.txt`); without them every option reads empty (0 or off) | Every option has its default in script (`FMOptionDefault`, legacy's "Default" presets, the same values); options never set get it when a save loads, and the reads fall back to it while an option is empty | No manual step for the options; same values as legacy's install. The hotkey steps stay manual (owner, 2026-11-14) | Porter's call, as in Preparations' port, not confirmed by the owner | None |

(An entry keeping 5.x's meditation beside FM's was withdrawn on 2026-11-13: FM replaces it, as in legacy.)
