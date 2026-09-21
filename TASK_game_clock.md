# Grok Build task — Game clock + string travel

**Date:** 21 September 2026  
**Repo:** `Darkgecko777/CuttingSands` `main`  
**Vision:** Game Clock (21 Sep 2026) + One map, two modes (21 Sep 2026) + Rival strings (8 Sep)  
**State:** lifts “no road watch” for the 19 tokens. Rank / intrigue / events / fatigue stay off.

Derek pulls `origin/main` as a whole. Smallest commit set. No unique art. Read checkout `AGENTS.md` and `docs/State.md` first. Do not ingest the tree.

---

## Intent

Replace day-atom time with one **game clock**. A watch is 3 hours; eight watches are a day. The player and the 19 strings move on that stamp. Towns still mint and eat once per day, at Dawn.

When the player looks at **Map** in a yard, they see the world frozen at the last process stamp (arrival, or the watch they Waited to). On the road with no tab, they see live movement inside the current watch, line of sight of this hop. Same plate. Do not build a second map stack.

---

## Game clock

Store a single stamp. Hours-from-epoch is fine if `day`, `watch` (1–8), and `hour_into_watch` (0–3) can be derived.

| Watch | Name | Market |
|---|---|---|
| 1 | Dawn | open — **day pulse** |
| 2 | Morning | open |
| 3 | Heat | open |
| 4 | Afternoon | open |
| 5 | Dusk | open |
| 6 | First night | closed |
| 7 | Deep night | closed |
| 8 | Predawn | closed |

**Runs when:** travel watch with no top tab; Skip on the road; Wait in a yard.  
**Frozen when:** any yard except during Wait; Cargo / Map / Rumours open (including mid-hop).

**Arrival.** Write the exact stamp and stop. Do **not** flush the rest of the watch for the world.

**Wait** (House, Market, and Outyard — same three choices):

- **1 watch** — advance to the end of the *current* watch only. Arrive 1 hour in, pick 1 watch → 2 hours pass.
- **Half day** — remainder of current watch, then 4 watches.
- **Full day** — remainder, then 8 watches.

All three land on a watch boundary. While that time passes, every in-transit token (and the weather word already on the edge — do not build a moving storm this pass) advances.

**Skip** on the road: same as Wait 1 watch (remainder of current). Do not skip the whole hop.

**Market hours.** Stall + Market yard trade only on watches 1–5. Arrival on 6–8: land **parked**. Market chrome dead. House and Outyard live. Wait is how they reach Dawn. Same window on every `has_market` node. Sarn stays non-market; tokens still do not dock there to trade.

**Day pulse** — only when the stamp *crosses into watch 1*:

1. Produce (existing).
2. Each NPC token that is **docked** at a `has_market` node, stable id order: one stall act (existing buy-or-sell rules from `TASK_string_roster`). Then, if still docked and idle, they may **depart** (below).
3. Consume (existing).
4. Spoil / rumour age if those already tick on `tick_day`. Do not invent spoil.

Do not pulse produce/consume on watches 2–8.

Kill the names Clock A, Clock B, and “model B” in player copy and in new comments. Engine identifiers may stay until a rename is cheap.

---

## Hop length and ETA

Existing hop length is in days. One hop day = **8 watches** = 24 hours. Weather extra days already on the edge stay extra days → extra watches. Do not add pace, fatigue, night-closed flags, or event hour-taxes this pass.

Outyard road line and hop confirm show ETA as `day + watch name` (e.g. `Westmark · day 3 · Dusk`). If the player is already mid-hop, rewrite from current stamp + remaining hours. Frozen weather values are allowed; if weather later adds days, the label must be able to change.

Player wagon progress is hours on the current edge. Arrival stamp = now + remaining hours, snapped only for the *label* if you must; sim keeps the exact hour.

---

## String travel (this pass)

Lift “re-seat snap, no road watch.”

A token is either:

- **Docked** — `node_id`, chip under that town glyph; or
- **In transit** — `from_id`, `to_id`, `hours_done`, `hours_total`; chip on that edge at `hours_done / hours_total`.

**Depart** (only at day pulse, only if docked, only if they chose a dest): pick dest with the existing 1–2 hop matrix. If dest is not adjacent, path the first edge toward it (shortest hop count, existing graph). `hours_total` = that edge’s days × 24. Leave the node immediately after the stall act so they are on the wire for the rest of Dawn if you step watches during Wait.

**In transit each time the clock advances H hours:** `hours_done += H`. On `hours_done >= hours_total`: dock at `to_id`. If the arrival stamp is watch 6–8, they are parked until watch 1; they do not trade until a Dawn pulse while docked.

Same base speed as the player. No kit, no traits. Mid-hop tokens skip the stall act.

Sarn: still not a trade dock. Do not path tokens onto Sarn this pass.

Player is not a 20th AI body. Player transit is the existing hop, now stamped in hours.

---

## Map (one plate, two modes)

Do not add a second map scene or fog system.

- **Map tab:** paused plate at current stamp. Town chips as now (HBox under glyph, cap 4, `+N`, player ring). Tokens in transit: same chip template on the edge at the stamp fraction. Letterbox stays.
- **Travel watch (hop, no tab):** same plate, existing zoom. Player wagon icon stays. Draw in-LOS tokens on the current edge (and the two nodes of this hop if you already show them). Live tween inside the watch. Opening Map/Cargo/Rumours freezes stamp + switches to paused plate; close resumes.

Clicking a chip still does nothing extra.

LOS this pass: the current hop’s edge + its two endpoints. Do not build a vision radius.

---

## Arrival chrome

Start of run and arrival on watches 1–5: **Market**, no top tab (existing).  
Arrival on watches 6–8: same well, Market yard **disabled** (no draft), House + Outyard live, no top tab. Copy can be a one-line “stalls closed until Dawn.” Do not invent a fourth yard.

---

## Do not implement

- Travel interrupts, salvage, ruins, tithe resolution, event table.
- Pace / crew fatigue.
- Moving weather center, Perlin mass, night-closed edges.
- House rank, intrigue, personality, wagon variants.
- Player daily eat, skills, agents, save/options, other starting houses.
- Socialize, weather step as a separate verb.
- A second map, a token inspector, FoW on the Map tab.
- Produce/consume eight times a day.
- Flushing the remainder of a watch on arrival (only Wait / Skip does that).

---

## Files

Likely: `game_state.gd` (stamp), `scripts/autoload/string_book.gd`, `market_book.gd` (`tick_day` → day pulse on Dawn only), `scripts/map/map_well.gd`, Outyard hop confirm + Wait, `field_shell` Market enable/disable, hop tween. Edge lengths already live on the graph / world book.

Open those and direct callers only.

---

## Playtest

1. New run in Market at Dawn. Map: chips under towns, none sitting on Sarn.
2. Outyard: pick a road. Line shows dest + weather + heat + **ETA watch name**. Confirm hop. Travel watch: wagon moves. Open Map mid-hop: everything frozen, including string chips; close: tween resumes.
3. Arrive mid-watch (force a hop whose remainder is not a boundary if you can). Stamp is not snapped. Other chips have not jumped to the end of that watch.
4. Arrive on First night: Market dead, Wait offered. **1 watch** three times should reach Predawn then Dawn — on Dawn, Market opens and stall numbers can change.
5. Wait **full day** in Outyard from Dawn: one day pulse; some tokens have left town chips and sit on edges or in other HBoxes.
6. Two tokens on the same edge as the player hop: visible on the travel watch; after arrival they are either in the dest HBox or still on the wire at the frozen fraction.
7. Wait **1 watch** after docking one hour into Heat: only two hours pass; next label is Afternoon, not Dusk.

---

## After this ships

Update `docs/State.md`: this task becomes **Current**, prior Current becomes **Prior**. Outcome only: game clock in watches; Wait 1 / 4 / 8 with remainder; market 1–5; strings in transit on edges; Map tab paused / watch live. Rank still off. Events still off.

Port this file to the repo root as `TASK_game_clock.md` when you start GB. Also port `TraderOfTheCuttingSands_Vision.md` (Game Clock + one-map section) and replace checkout `AGENTS.md` if this workspace copy is ahead.
