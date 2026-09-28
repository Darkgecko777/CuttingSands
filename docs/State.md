# State — Caravans of the Cutting Sands

Handshake for Grok.com (creative) and Grok Build (implementation). Read this instead of scanning the repo.

Keep **two** shipped tasks only. After each completed task: new work becomes **Current**, old Current becomes **Prior**, drop anything older. Spec files stay at repo root (`TASK_<name>.md`); this file is the outcome, not a recap of the spec.

**HEAD:** `cd9f536` on `main` (15 Sep 2026) · weather, yard authority, game clock, string roster, doors, and rumour tickets are in the working tree, not committed  
**Play:** Godot 4.7 · `scenes/map/field_shell.tscn` after house select · start in Market.

---

## Current — `painted_sample_set`

**When:** 24 Sep 2026 · working tree · no spec file  
**Vision:** The sample screen wears one painted set: gouache ground, paper banners, ledger, leather tags, wax and pewter seals, ink marks.

**Shipped**

- The test ground and the road are a finished plate of one caravanserai. That finish is the lock for later grounds.
- The top banner is 56 pixels, half the first block. Both banners are worn paper: a rough outer edge and a black ink pattern inside it.
- Banners, seals, and marks are the painted set. The block stage is still primitives. The shell is not restyled.

**Where:** `Assets/UI/stage/`, `docs/UI_Visuals.md`.

**Playtest:** open `scenes/ui/screen_sample.tscn` and press F6. `R` shows the road. `1`–`5` show the marks on the tags.

---

## Prior — `test_ground_and_book`

**When:** 24 Sep 2026 · working tree · no spec file  
**Vision:** A photographic yard and a cropped ledger, used to test the sample screen.

**Where:** `Assets/UI/stage/`. Replaced by the painted set. The shell was not restyled.

---

## Do not implement until Derek asks

Weather step on Wait; house rank / intrigue; personality traits; travel interrupts, salvage, ruins; stacked-in-cell cargo; player daily eat; skills, agents, save/options, other starting houses. Attribute checks on Socialize wait for the skill sheet.

Shell roles are in `docs/UI_Layout.md`. Component look is in `docs/UI_Visuals.md`. The stage is `docs/UI_Review.md`. Today's strings stay in `AGENTS.md` until a rename. Play is one well. Do not revive `city_hub` / `world_map` / `main_game`. Do not restyle `field_shell` until the staged screen is accepted.
