# State — Caravans of the Cutting Sands

Handshake for Grok.com (creative) and Grok Build (implementation). Read this instead of scanning the repo.

Keep **two** shipped tasks only. After each completed task: new work becomes **Current**, old Current becomes **Prior**, drop anything older. Spec files stay at repo root (`TASK_<name>.md`); this file is the outcome, not a recap of the spec.

**HEAD:** `cd9f536` on `main` (15 Sep 2026) · opening cellars + string roster + game clock are in the working tree, not committed  
**Play:** Godot 4.7 · `scenes/map/field_shell.tscn` after house select · start in Market.

---

## Current — `game_clock`

**When:** 21 Sep 2026 · working tree · spec `TASK_game_clock.md`  
**Vision:** Game Clock + One map, two modes. Rank / intrigue / events stay off.

One stamp (hours from epoch). A watch is 3 hours; eight watches a day. Day pulse at Dawn only. Arrival writes the exact stamp and stops.

**Shipped**

- Header is `Day N · watch name`. Wait in House, Market, and Outyard: **1 watch** (remainder), **half day**, **full day**. Skip on the road is remainder of this watch, not the whole hop.
- Stall + Market yard live on watches 1–5. Arrival on 6–8 lands parked; Market chrome dead; copy “Stalls closed until Dawn.”
- Strings dock or sit on an edge (`hours_done / hours_total`). Dawn: produce → docked stall act → maybe depart first edge → consume. In-transit tokens skip the stall.
- Map tab: paused plate, town chips as before, same chips on edges. Travel watch: hop zoom locked on the launch/destination midpoint (not the wagon); player wagon; enlarged road chips; every token drawn (no FoW). Open a tab: freeze + atlas; close: resume. Day-1 Dawn act puts idle strings on their first edge so the roads are already moving.

**Where:** `game_state.gd` (stamp), `string_book.gd`, `caravan_log.gd`, `cargo_hold.gd`, `market_desk.gd`, `map_well.gd`, `field_shell.gd`.

---

## Prior — `string_roster`

**When:** 16 Sep 2026 · working tree · spec `TASK_string_roster.md`  
**Vision:** Rival strings (presence / stall use only). Rank and intrigue stay off.

19 NPC tokens share the stall. Uniform **short-haul**: one good, lot of 2, 1–2 hops, coin-per-hop, sell the morning after arrival. Personality later.

**Shipped**

- Five houses × four chairs. Player is Kharûn chair 0. The other 19 are authored in `data/world/strings.json` (cities thicker than posts; none on Sarn; start town is player only).
- Purse **500**, empty rack, 16 cells / 36 mass. Same `local_price` as the player. No ledger, no rank.
- Produce → each token (stable id) one act → consume. At dest with the trip good: sell and stay. Empty: buy 2 of the best trip and step. Mid-trip: step only. Idle: stay.
- Map tab: `ColorRect` + `Label` chips under the glyph (house color, mark+chair). Player chip has a 1px ring. Cap 4, overflow `+N`. No chips on the hop watch in that pass; wagon icon stayed on the watch only.

**Where:** `scripts/autoload/string_book.gd`, `data/world/strings.json`, `data/world/houses.json` (colors), `world_book.gd`, `game_state.gd`, `market_book.gd`, `scripts/map/map_well.gd`.

---

## Do not implement until Derek asks

Socialize; weather step on Wait; house rank / intrigue; personality traits; travel interrupts, salvage, ruins; stacked-in-cell cargo; player daily eat; skills, agents, save/options, other starting houses.

Chrome and well layout are locked (see `AGENTS.md`). Play is one well. Do not revive `city_hub` / `world_map` / `main_game`.
