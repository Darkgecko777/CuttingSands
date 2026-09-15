# State — Caravans of the Cutting Sands

Handshake for Grok.com (creative) and Grok Build (implementation). Read this instead of scanning the repo.

Keep **two** shipped tasks only. After each completed task: new work becomes **Current**, old Current becomes **Prior**, drop anything older. Spec files stay at repo root (`TASK_<name>.md`); this file is the outcome, not a recap of the spec.

**HEAD:** `cd9f536` on `main` (15 Sep 2026)  
**Play:** Godot 4.7 · `scenes/map/field_shell.tscn` after house select · start in Market.

---

## Current — `economy_revise`

**When:** 15 Sep 2026 · `cd9f536` · spec `TASK_economy_revise.md`  
**Vision:** *Live Economy — Cellars, Rations, Bands*

Corrected the catalog and price shape on top of live warehouses. Do not re-spec this.

**Shipped**

- Cities mint **4** origin letters; villages **2**; posts **none**.
- Cities and villages mint **rations** and **water** (authored `local_mint` in `data/world/settlements.json`). Posts mint neither. **Sarn** mints **water only**.
- Price is still a cellar readout, then **clamped** to a per-node floor/ceiling (`0.70` / `1.45`). Origin letters use hops × gravity for the band mid; rations/water use authored per-node `base`.
- Buy and sell share the same stall number.
- Market tooltip ledger: **Lowest buy + town** / **Highest sale + town** (only goods the player has seen at a stall). Rumours do not write it.
- Emergency convert: one smash of an `edible` unit → `ration_yield` rations; refuses if the rack cannot hold them. Player daily eat is **not** wired.
- Warehouse tick, Clock B, and “player wagon is the only mover” stay as in Prior.

**Where:** `data/world/goods.json`, `data/world/settlements.json`, `scripts/autoload/market_book.gd`, `world_book.gd`, `game_state.gd`, `cargo_hold.gd`, `scripts/sight/good_copy.gd`, Market / Cargo in `field_shell.gd`.

---

## Prior — `live_economy`

**When:** 14 Sep 2026 · `024fec2` · spec `TASK_live_economy.md`

First live cellar. Superseded by Current where they disagree (water-only-at-Sarn as the player well; no rations row; no floor/ceiling; no tooltip ledger).

**Shipped (still true)**

- Per-node warehouse ticks on Clock B (hop day, Skip, Outyard **Wait** one day). No tick in a yard or while a top tab pauses a hop.
- Origins produce to cap; every market consumes what it holds. Leave does not reset stock.
- Price raw form: scarcity × hops-from-origin × corridor gravity. Weather is a hook only (`local` = 1).
- Player wagon is the only mover. Strings do not buy, sell, or haul.
- Rack **16 cells** / **36 mass**. Empty stall rows hide.

---

## Do not implement until Derek asks

Socialize; weather step / rival walk-in on Wait; 19 strings, house rank, intrigue; travel interrupts, salvage, ruins; stacked-in-cell cargo; player daily eat; skills, agents, save/options, other starting houses.

Chrome and well layout are locked (see `AGENTS.md`). Play is one well. Do not revive `city_hub` / `world_map` / `main_game`.
