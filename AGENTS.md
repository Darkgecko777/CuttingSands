# Caravans of the Cutting Sands — Grok Build rules

These rules apply when Grok Build is running **inside this Godot checkout**.

They are not the Grok.com workspace rules.

## Session start

- Source of truth for *code* is **this working tree**, not GitHub memory and not a prior chat.
- Source of truth for *design intent* is `TraderOfTheCuttingSands_Vision.md`. Read the **relevant section** when the task is a lock. Do not paste the vision into the prompt or into this file.
- If `docs/State.md` exists, read it first. It is the last **two** shipped tasks for Grok.com / Grok Build. Do not scan the repo to recover them.
- If `docs/worklog.md` exists, read the **latest entries** before exploring. Do not ingest the whole archive.
- One task cluster at a time. Do not recap the whole project at the start of a session.

## Identity

- Official title: **Caravans of the Cutting Sands**.
- Engine: **Godot 4.7**. Prefer typed GDScript, existing autoloads, existing scene trees.
- Owner: Derek. Local playtest is the Godot project on disk. Do not assume a `git pull` is required for him to see edits.
- This checkout **is the game**. Unbuilt systems are gated until Derek asks. Do not describe work as a demo, vertical slice, proof-of-concept, or down-payment on a different title.

## Live map (use these)

| Job | Where |
|---|---|
| Play shell | `scenes/map/field_shell.tscn`, `scripts/map/field_shell.gd` |
| Map / hop watch | `scripts/map/map_well.gd`, `scenes/map/map.tscn` |
| Market / cargo UI | `scripts/map/market_desk.gd`, `wagon_rack.gd`, `wagon_deal.gd`, `cargo_math.gd` |
| Travel / weather | `scripts/autoload/caravan_log.gd`, `scripts/map/road_pressure.gd` |
| Economy | `scripts/autoload/cargo_hold.gd`, `market_book.gd`, `game_state.gd` |
| World data | `scripts/autoload/world_book.gd` ← `data/world/*.json` |
| Knowledge / rumours | `scripts/sight/` (`SightBook`, `WordBook`, `GoodCopy`) — engine names until a rename pass |
| Rival tokens | `scripts/autoload/string_book.gd` ← `data/world/strings.json` |
| Title / house / pause | `scripts/ui/title_screen.gd`, `house_select.gd`, `pause_menu.gd` |
| Stand-in plates | `scripts/ui/instrument_style.gd`, `Assets/UI/instrument/` |

## Leftovers (do not revive)

- `scenes/main/city_hub.tscn` + `scripts/main/city_hub.gd`
- `scenes/map/world_map.tscn` + `scripts/map/world_map.gd`
- `scenes/main/main_game.tscn`

Play lives in **one well** after house select. No second full-screen city hub or map destination.

## Player-facing chrome (locked)

| Say | Do not put on chrome |
|---|---|
| Rumours (tab); one entry is a **rumour** | Word, assay, slip |
| Cargo (top tab) | Wagon as a chrome label |
| House, Market, Outyard (bottom yards) | generic “location buttons” |
| Outyard confirms hops | starting a hop from the Map tab |

Start and arrival land in **Market**, no top tab open. Engine identifiers may still say Word / wagon until a rename pass. Do not put *assay* or *slip* on chrome, in player copy, or in new identifiers.

## UI lock (keep; do not rebuild)

The working frame is `docs/UI_Layout.md`. The look, for outside pictures and for stand-in controls, is `docs/UI_Visuals.md`. Play uses the plates in `Assets/UI/instrument/` through `InstrumentStyle`. Generate no stand-in pictures. Do not restyle `field_shell` to preview outside art.

- One frame. Top paper banner, book with leather tags, borderless well, bottom paper banner.
- Feature tags, one open at a time, and each can close. Play draws **Cargo | Map | Rumours**. Character and Agents join when those systems exist.
- Bottom banner: **House | Market | Outyard**. House is drawn in cities and Ghorath. Villages and posts draw Market and Outyard only. All of them are dead on the road.
- Map tag shows the existing chart, letterboxed, inside the well. No fog of war on that chart.
- Each stop has its own full-bleed ground. The road has its own ground. Until those pictures are applied, a hop with no tab is still the zoomed chart. Opening a tab **pauses** the hop tween; close resumes.
- Game clock: time runs on the watch, Skip, or explicit Wait. Wait is Outyard only. Time does not run in House or Market.
- Title: Continue and Options stay visible but disabled until save / options exist. Title does not open PauseMenu for Options.

## UI contact

- Roles, and what the frame must tell the player: `docs/UI_Layout.md`.
- Finished pictures, and how stand-in controls are drawn: `docs/UI_Visuals.md`.
- The shell loads `Assets/UI/instrument/` until outside pictures are applied. Generate no art in this checkout. `Samples/` is mood, not a slot.
- The words on the controls are a string table. The chrome table above is what this build says today. Neither UI document renames those words or freezes them.

## Built vs gated

**In this checkout now:** one player wagon; JSON world; hop along adjacent roads; weather term at Outyard (Clear / Heat / Wind / Sandstorm; no Quiet / Watched / Active); region-pair term frozen at New Game (Heat/Wind +1 day, Sandstorm +2; arrival leak, no coin tithe); arrival rumours; live prices only at the stall you stand; per-node warehouses that produce/consume at Dawn; cities/villages mint rations + water (posts do not; Sarn is painted only — no mint, no dock); price bands; stall ledger (lowest buy / highest sale + town); emergency edible → rations; House in cities and Ghorath only; Outyard restock toward 2 water and 6 rations; Wait 1 watch / half day / full day in Outyard only; Market yard inactive on watches 6–8; 16 cells + 36 mass; 19 NPC tokens short-haul on the game clock (Map tab is the committed stamp; travel watch slides the current watch; hop zoom; no FoW).

**Locked in the vision — do not implement until Derek asks:**

- Socialize (spend a day, chance of a rumour, stars only). Market is the public street until another public yard exists.
- Weather step on Wait
- House rank, one-way intrigue, personality traits on tokens
- Interrupt travel events, salvage/lost-pool, ruin extraction
- Stacked-in-cell cargo (vision 16 slots with stack limits); rack is 16 cells now — do not silently retune
- Player daily eat of rations/water
- Skill webs, agent roster, save/options, other starting houses

When those land, follow the vision section for that lock. They are part of this game, not a later product. Short reminder: one wagon, no rumour shop, stars are P(true), Outyard is hop authority, never 0% road risk, bandits tithe (they do not murder the mark).

## How to work

- Open the target file and its direct callers. Do not ingest the whole tree.
- Smallest set of files that ships the ask. Match surrounding style; do not reformat untouched files.
- World facts go in `data/world/` JSON, not hard-coded in scripts.
- Leave `.uid` files to Godot; do not hand-edit them.
- Do not invent unique art, extra SKUs, a second wagon, a fleet screen, or a second economy unless asked.
- After each completed task, update `docs/State.md`: the new task becomes **Current**, the old Current becomes **Prior**, drop anything older. Keep the file to those two entries.
- Do not add README / extra scaffolding “for the agent.” `AGENTS.md`, `docs/State.md`, `docs/worklog.md`, `docs/UI_Layout.md`, and `docs/UI_Visuals.md` are the exceptions.
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