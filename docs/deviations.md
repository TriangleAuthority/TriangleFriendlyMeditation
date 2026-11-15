# Deviations from the legacy mod

Every place where the port behaves differently from Friendly Meditation 2.3, with the reason, who decided and when, and a question for the original author (wghost81) where their intent is unclear. Add an entry whenever the port deviates, in the same commit.

"Owner" is this project's owner; "porter's call" means not yet confirmed by the owner.

| # | Feature | Legacy | Port | Why | Decided | Question for the author |
|---|---|---|---|---|---|---|
| 1 | FM-MENU | The defaults come from `user.settings` lines the player pastes by hand (`release/user.settings.part.txt`); without them every option reads empty (0 or off) | Every option has its default in script (`FMOptionDefault`, legacy's "Default" presets, the same values); options never set get it when a save loads, and the reads fall back to it while an option is empty | No manual step for the options; same values as legacy's install. The hotkey steps stay manual (owner, 2026-11-14) | Porter's call, as in Preparations' port, not confirmed by the owner | None |
| 2 | FM-RT | The hotkey pushes FM's own `Meditation` state (Geralt sits facing where he stands) and the fast-forward pushes `MeditationWaiting` | The hotkey sits Geralt down through 5.x's `Meditate()` (5.x turns him toward open space first, about 2 s to sit); the fast-forward runs inside 5.x's `Meditation` state, which only idles | Builds on 5.x's meditation instead of replacing its states, so Ghost Mode's and Preparations' hooks on it keep working; the player sees the same thing apart from the turn | Owner, 2026-11-13 (the proposed form in [port-plan.md](port-plan.md#decisions-made)) | None |
| 3 | FM-RT | No input context change while sitting | 5.x switches to an input context `Meditation`, which has no key bindings; in hotkey mode FM switches back to the previous context on the first tick, so the hotkey's release and the other FM keys reach the game | Without it, releasing the hotkey would do nothing while seated (unverified with a real key) | Porter's call, not confirmed by the owner | None |
| 4 | FM-RT | "Waiting is started" / "Waiting is stopped" notifications | Not shown yet | Temporary, until slice 2 (notifications) | Porter's call | None |

(An entry keeping 5.x's meditation beside FM's was withdrawn on 2026-11-13: FM replaces it, as in legacy.)
