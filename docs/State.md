# State — Caravans of the Cutting Sands

Handshake for Grok.com (creative) and Grok Build (implementation). Read this instead of scanning the repo.

Keep **two** shipped tasks only. After each completed task: new work becomes **Current**, old Current becomes **Prior**, drop anything older. Spec files stay at repo root (`TASK_<name>.md`); this file is the outcome, not a recap of the spec.

**HEAD:** `cd9f536` on `main` (15 Sep 2026) · weather, yard authority, game clock, string roster, doors, and rumour tickets are in the working tree, not committed  
**Play:** Godot 4.7 · `scenes/map/field_shell.tscn` after house select · start in Market.

---

## Current — `visuals_handoff`

**When:** 28 Sep 2026 · working tree · no spec file  
**Vision:** Pictures are drawn outside this checkout. The sample scenes and the neon study are gone. Stand-in controls stay on `InstrumentStyle`.

**Shipped**

- `docs/UI_Visuals.md` is the brief for outside pictures and the rule for prototype controls.
- `docs/UI_Layout.md` stays the frame. It no longer points at a review stage.
- Removed the block, the sample, the gallery, the neon study, `docs/UI_Review.md`, `Assets/UI/stage/`, and `Assets/UI/neon_sepia/`.
- The shell was not restyled.

**Where:** `docs/UI_Layout.md`, `docs/UI_Visuals.md`, `AGENTS.md`.

**Playtest:** play from house select. The shell looks as it did. The F6 sample scenes are gone.

---

## Prior — `painted_sample_set`

**When:** 24 Sep 2026 · working tree · no spec file  
**Vision:** The sample screen wore one painted set: gouache ground, paper banners, ledger, leather tags, wax and pewter seals, ink marks.

**Where:** was `Assets/UI/stage/` and `scenes/ui/screen_sample.tscn`. Removed in `visuals_handoff`. The shell was not restyled.

---

## Do not implement until Derek asks

Weather step on Wait; house rank / intrigue; personality traits; travel interrupts, salvage, ruins; stacked-in-cell cargo; player daily eat; skills, agents, save/options, other starting houses. Attribute checks on Socialize wait for the skill sheet.

Shell roles are in `docs/UI_Layout.md`. Picture brief and stand-in controls are in `docs/UI_Visuals.md`. Today's strings stay in `AGENTS.md` until a rename. Play is one well. Do not revive `city_hub` / `world_map` / `main_game`. Generate no stand-in pictures. Do not restyle `field_shell` to preview outside art.
