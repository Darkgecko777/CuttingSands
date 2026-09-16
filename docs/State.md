# State — Caravans of the Cutting Sands

Handshake for Grok.com (creative) and Grok Build (implementation). Read this instead of scanning the repo.

Keep **two** shipped tasks only. After each completed task: new work becomes **Current**, old Current becomes **Prior**, drop anything older. Spec files stay at repo root (`TASK_<name>.md`); this file is the outcome, not a recap of the spec.

**HEAD:** `cd9f536` on `main` (15 Sep 2026) · opening cellars + string roster are in the working tree, not committed  
**Play:** Godot 4.7 · `scenes/map/field_shell.tscn` after house select · start in Market.

---

## Current — `string_roster`

**When:** 16 Sep 2026 · working tree · spec `TASK_string_roster.md`  
**Vision:** Rival strings (presence / stall use only). Rank and intrigue stay off.

19 NPC tokens share the stall. Uniform **short-haul**: one good, lot of 2, 1–2 hops, coin-per-hop, sell the morning after arrival. Personality later.

**Shipped**

- Five houses × four chairs. Player is Kharûn chair 0. The other 19 are authored in `data/world/strings.json` (cities thicker than posts; none on Sarn; start town is player only).
- Purse **500**, empty rack, 16 cells / 36 mass. Same `local_price` as the player. No ledger, no rank.
- Clock B: produce → each token (stable id) one act → consume. At dest with the trip good: sell and stay. Empty: buy 2 of the best trip and step. Mid-trip: step only. Idle: stay.
- Map tab: `ColorRect` + `Label` chips under the glyph (house color, mark+chair). Player chip has a 1px ring. Cap 4, overflow `+N`. No chips on the hop watch; wagon icon stays on the watch only.

**Where:** `scripts/autoload/string_book.gd`, `data/world/strings.json`, `data/world/houses.json` (colors), `world_book.gd`, `game_state.gd`, `market_book.gd` (`tick_day`), `scripts/map/map_well.gd`.

---

## Prior — `opening_cellars`

**When:** 16 Sep 2026 · working tree · spec `TASK_opening_cellars.md`

Day-0 cellars are a frozen “the road already happened once.” Mint, bands, consume, and Clock B pulse are unchanged.

**Shipped (still true)**

- Mintable rows open at **60% of cap**. Origin letters at **1 hop** seed **25%**, **2 hops** **12%** (cities included; posts count as hops).
- Posts get those leftovers plus a **40%** water/rations sip. Sarn water only, no stall.

---

## Do not implement until Derek asks

Socialize; weather step on Wait; house rank / intrigue; personality traits; travel interrupts, salvage, ruins; stacked-in-cell cargo; player daily eat; skills, agents, save/options, other starting houses.

Chrome and well layout are locked (see `AGENTS.md`). Play is one well. Do not revive `city_hub` / `world_map` / `main_game`.
