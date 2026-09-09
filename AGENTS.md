# Caravans of the Cutting Sands — Grok Build rules

These rules apply when Grok Build is running **inside this Godot checkout**.

## Session start

- Source of truth for *code* is **this working tree**, not GitHub memory and not a prior chat.
- Source of truth for *design intent* is `TraderOfTheCuttingSands_Vision.md`. Read the **relevant section** when the task is a lock. Do not paste the vision into the prompt or into this file.
- If `docs/worklog.md` exists, read the **latest entries** before exploring. Do not ingest the whole archive.
- One task cluster at a time. Do not recap the whole project at the start of a session.

## Identity

- Official title: **Caravans of the Cutting Sands**.
- Engine: **Godot 4.7**. Prefer typed GDScript, existing autoloads, existing scene trees.
- Owner: Derek. Local playtest is the Godot project on disk. Do not assume a `git pull` is required for him to see edits.

## Live map (use these)

| Job | Where |
|---|---|
| Play shell | `scenes/map/field_shell.tscn`, `scripts/map/field_shell.gd` |
| Map / hop watch | `scripts/map/map_well.gd`, `scenes/map/map.tscn` |
| Market / cargo UI | `scripts/map/market_desk.gd`, `wagon_rack.gd`, `wagon_deal.gd`, `cargo_math.gd` |
| Travel / tithe | `scripts/autoload/caravan_log.gd`, `scripts/map/road_pressure.gd` |
| Economy | `scripts/autoload/cargo_hold.gd`, `market_book.gd`, `game_state.gd` |
| World data | `scripts/autoload/world_book.gd` ← `data/world/*.json` |
| Knowledge / slips | `scripts/sight/` (`SightBook`, `WordBook`, `GoodCopy`) — engine names until a rename pass |
| Title / house / pause | `scripts/ui/title_screen.gd`, `house_select.gd`, `pause_menu.gd` |

## Leftovers (do not revive)

- `scenes/main/city_hub.tscn` + `scripts/main/city_hub.gd`
- `scenes/map/world_map.tscn` + `scripts/map/world_map.gd`
- `scenes/main/main_game.tscn`

Play lives in **one well** after house select. No second full-screen city hub or map destination.

## Player-facing chrome (locked)

| Say | Do not put on chrome |
|---|---|
| Rumours (tab); one entry is a **slip** | Word, assay |
| Cargo (top tab) | Wagon as a chrome label |
| House, Market, Outyard (bottom yards) | generic “location buttons” |
| Outyard confirms hops | starting a hop from the Map tab |

Start and arrival land in **Market**, no top tab open. Engine identifiers may still say Word / wagon / assay until a rename pass.

## UI lock (keep; do not rebuild)

- Well: two panes, or one map surface. No side context column.
- Top tabs: **Cargo | Map | Rumours**. Single-select and close.
- Bottom yards: **House | Market | Outyard**. Dead on the road.
- Map tab = letterboxed atlas (no fog of war on that chart).
- Hop with no tab = zoomed travel watch. Opening a tab **pauses** the hop tween; close resumes.
- Clock B: time runs on the watch, Skip, or explicit Wait. Time does not run in a yard.
- Title: Continue and Options stay visible but disabled this slice.

## Slice now vs locked later

**Shipped in this checkout:** one player wagon; JSON world; hop along adjacent roads; weather + heat *labels* at Outyard; auto tithe; arrival slips; live prices only at the stall you stand; 24 cells + 36 mass.

**Locked in the vision — do not implement until Derek asks:**

- Socialize (spend a day, chance of a slip, stars only)
- Wait as a Clock B / economic verb
- 19 rival strings, house rank, one-way intrigue
- Interrupt travel slips, salvage/lost-pool, ruin extraction
- 16-slot stacked cargo (vision); do not silently change capacity
- Skill webs, agent roster, save/options, other starting houses

When those land, follow the vision section for that lock. Short reminder: one wagon, no rumour shop, stars are P(true), Outyard is hop authority, never 0% road risk, bandits tithe (they do not murder the mark).

## How to work

- Open the target file and its direct callers. Do not ingest the whole tree.
- Smallest set of files that ships the ask. Match surrounding style; do not reformat untouched files.
- World facts go in `data/world/` JSON, not hard-coded in scripts.
- Leave `.uid` files to Godot; do not hand-edit them.
- Do not invent unique art, extra SKUs, a second wagon, a fleet screen, or a second economy unless asked.
- Do not add README / extra scaffolding “for the agent.” `AGENTS.md` and `docs/worklog.md` are the exceptions.
- Do not read bulk media unless the task is art/audio: `.godot/`, `*.import`, `Assets/map/`, `Assets/audio/`, large title/menu frames. See `.grokignore`. Honor that list even if a tool still lists the files.

## Git

- Default branch is `main`. Do not force-push.
- Do not commit or push unless Derek asked. Do not commit secrets, `.godot/`, or local session files.
- If you do commit: small, complete; message says what the player or compiler can now do.

## Plan

For anything that touches more than one script + its scene, plan first:

1. Files you will open.
2. Files you will edit.
3. What will not change.
4. How Derek playtests it in Godot on this disk.
