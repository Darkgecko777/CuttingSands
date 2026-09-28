# Caravans of the Cutting Sands — Project Vision

**Status:** Active direction (updated 21 September 2026 — session overwrite plus Face / Ken / Knack / Steel)  
**Engine:** Godot 4.x  
**Platform target:** Steam (using an existing paid slot)  
**Primary goal:** Ship *Caravans of the Cutting Sands* — a trading + intrigue game that delivers the marked-wagon fantasy. The project is the game. Systems arrive when they are built.

The official name is **Caravans of the Cutting Sands**. Repo and some engine strings may still say CuttingSands / Trader until a rename pass.

**This overwrite supersedes** the 18 Sep coin/cell/deeds lock, the 8 Sep node-rank + sabotage intrigue lock, the 2 Sep rumour-as-market-claim lock, the 2 Sep bandit-heat + lost-pool travel lock, and Sarn’s Rest as a playable/economic node. Clock (21 Sep), map modes (21 Sep), live economy cellars (14 Sep), catalog width, UI top tabs, and “this is the game” language stay except where this file says otherwise.

---

## One-Sentence Pitch

A desert trading and intrigue game in which you buy on knowledge your agents have gathered, risk the journey with one marked wagon, and convert that edge into profit — while rumours pull you off the stall into short expeditions that make the sand feel inhabited.

---

## Core Player Fantasy

The feeling first awakened by *Dune Trader* (Dark Sun, AD&D 2e):

- You possess (or believe you possess) non-obvious information about supply, demand, risk, or opportunity.
- That information comes from **skillful application of agents across the map** (parked eyes, live range, fog lifting on stalls and strings).
- You commit capital and reputation on the strength of that knowledge.
- You must survive the journey and the attention it attracts.
- Success feels earned because you outmaneuvered competition, read the situation correctly, or executed a clever edge.
- Failure carries real weight — lost cargo, wasted watches, a door tariff you refused to court.

**Knowledge game** = agents + fog + personal price memory.  
**Political-economic game** = village/post doors, standing, commissions.  
**Road / expedition game** = weather, abstract loss, event cards (placeholder until attributes exist).  
**Rumours** are not market intel. They are tickets into short treasure-hunt instances. That is extra surface for immersion, not a second price tooltip.

**Brand intent — immersion.** The player should feel like the person under the mark.

**Brand intent — Uncanny Mercantile (locked 1 September 2026).** Unique fantasy goods are how the player touches the setting. Water and staple grain may stay ordinary. A good is ready when it has an old-world rhyme and a local wound. Catalog width stays 4 letters per city, 2 per village; posts mint none; rations and water are separate stall rows.

---

## Setting Direction

Mirrored fantasy of Dark Sun / Athas: recognition without pastiche. Desperate, utilitarian, competing houses. Water, information, and safe passage are forms of power. The player is a marked agent inside one house, not the house.

### Scrubstone, Currency, and the Water Constraint (Locked)

Scrubstone is currency and desalination feedstock, produced only in Kharûn, exported as minted coin. Coins dissolve in concentrated salt water; merchants wear gloves and house-marked pouches.

Kharûn has no generous local water. It can plate a trickle so the street exists. Cheap bulk water is a trade problem, not a Kharûn deed on an oasis.

**Sarn’s Rest is out of play.** It may remain a painted landmark on the plate (a notable water supply the map can show). It is not a dock, not a stall, not a roster seat, not an origin, not a rumour subject. Do not mention it in systems, tasks, or player copy except as inert map art if the plate already draws it.

Populations stay fixed and invisible. No settlement-growth sim.

### Merchant Houses — Origin, Pact, and Membership (Locked)

Unchanged in fiction: five houses (Kharûn, Zamath, Thalor, Veythar, Ghorath), glove-and-pouch trust, limited safe-conduct for marked caravans, Ghorath as pressure-release. Houses are not city departments.

### Player Representation — Marked Agent, One Caravan (Locked 30 August 2026)

One rising agent, one caravan. The house is patronage and constraint.

**Agents** are tools on that stake:

- **Ride** the wagon: named modifiers on the event / Socialize checks they exist for (guard on threat rows, factor on Face, wrangler on sand).
- **Park** at a settlement: planted eyes. They lift knowledge fog — local stall freshness, strings in skill-scaled range. This is the trading-advantage layer.

Agents do not run their own trade loop and never hold the purse.

**Failsafes:** no permanent player death. Ruin extracts the agent to a house seat. Cargo on that wagon may simply be gone (abstract leak).

**Sabotage is out** of this game (sequel reserve). No player verbs to delay, spoil, or bump another token. Hostile pressure on the camera is the common event table and door tariffs, not a named dirty-tricks layer.

---

## Coin, Compound Cell, and House Standing (Session 21 September 2026)

Three ledgers. Do not mix them.

**Coin** spends on kit, reserve, travel restock, hop hires. Commissions pay a fixed wage in coin. Coin never buys a chair, civic status, or a furnishing SKU. No 0% road. No second wagon.

**Standing** is per house, ten rungs.

- Home house: cap **10**.
- Each rival house: cap **8**.
- Standing rises by completing that house’s **commissions**.
- Rival boards **turn off at 8**. Home board stays up (wage + exp after the bar is full).
- Standing 8 with a house hangs that house’s object for that rung and fires the Steam plaque. One save can earn all five house plaque lines (home 1–10 + four rivals 1–8 = **42 objects** in that save).

**Furnishings are standing objects. There is no separate deed shop.**

- Five generic apartment shells, one per house. Visual dressing follows the **home city** of that house. The player only *opens* the apartment at their **home seat** House tab. Objects earned from rival standing still appear there.
- **50 authored objects** in data: 5 houses × 10 rungs. A given save can land **42** (home ten + four eights).
- Rank 1 is a small curiosity (an exotic feather). Rank 10 is furniture (an armoire). Objects get more aesthetically present as the rung rises. They do not alter tariffs, stall access, or safe-conduct.
- Steam only mirrors objects that already exist in the cell. Hidden until the object lands. No “earn N coin” plaques.

**Capstone fantasy** can still colour *which* object a house hangs at high rungs. It is not a second furnish path and not a second save.

---

## Scope Boundaries

### What this game is

- Trading + intrigue on one desert map, one wagon.
- Live cellars. Strings share the stall.
- Agents as the knowledge / fog layer.
- Rumours as expedition tickets (immersion + loot/exp), independent of markets.
- Village and post **doors** (tariffs) as the house-influence layer. Cities do not flip.
- Commissions at house seats.
- Travel with visible weather mass, abstract cargo leak, and event cards.
- 5 major cities plus villages and posts.

### What this game is deliberately not

- Fleet / warehouse company sim.
- Auto-battler travel.
- Settlement growth or demographics.
- Sabotage / murder intrigue.
- A closed cargo-conservation sim (lost-pool, salvage-as-bookkeeping).

---

## Economic & Agency Model

### Settlements

**Cities** — clamp. Four origin letters (placeholder until full goods and lore pass) + local rations/water mint. House seats. House tab exists. Influence / door tariff **does not apply**. A city stall has no flipping owner. A small fixed home-house cut at the player’s own seat is allowed as patronage, not as a contest.

**Villages** — fluid doors. Two origin letters + local rations/water mint. Market + Outyard only.

**Trade posts** — fluid doors, identical to villages except: **no mint**, **lower consume**, smaller gravity (market rank 1–2). Cellars are what wagons and strings sold plus the opening sip already shipped. Market + Outyard only.

All three are dockable. Arrival lands in Market when the stall is open.

### Live Economy (Locked 14 September 2026, leaks added)

Static map, live shelves. Mint to cap, daily consume, price from fullness inside a distance band. Player buy shrinks the local warehouse; player sell writes the dest warehouse.

**Leaks (intentional, not conserved):**

- Weather and failed road / expedition checks may **delete** cargo or coin. Nothing enters a zone pool.
- Commission deliveries **leave the world** (fed to the house machine). They do not restock the stall.
- Expedition leftover that will not fit the rack is gone, not stored in the sand.

Mint, consume, and gravity are the rate knobs that absorb those leaks.

**Player knowledge (stall).** Tooltip: cheapest buy seen + where, highest sale seen + where. Personal only.

**Trading advantage (map).** Planted agents and fog. Parked eyes make a location’s stall and nearby strings readable without the wagon sitting there. That is how you know to reroute. Rumours do not write this.

**Rations.** Player eats rations (hook reserved). Outyard restock fills travel water/rations against the local cellar at local price. Origin letters stay Market. Emergency smash edible letter → rations at a bad rate stays.

**Strings.** 19 NPC tokens, four chairs per house, player is home chair 0. Short-haul 1–2 hop lots, one act per day pulse, shared stall. **Village and post sales stamp door influence. City sales do not.**

### House influence and tariffs (villages and posts only)

Houses gain a **current** presence score at fluid docks when their marks (player or string) sell. Stamp uses the hybrid: cells sold × local value, boosted when that row is short of a simple band, halved when the cellar is fat. Dawn decay. No lifetime ledger of tariff income (sequel reserve).

The **highest** house at that dock is the **door**. The stall prints one line: house, your standing with them, cut %. Tariff applies to **buy and sell**. Standing lowers the cut. Skills may poke specific circumventions later. Rival doors never reach 0%.

NPCs path to profit, not to rank. Doors emerge.

### Commissions

Posted on the **House tab at that house’s city**. Fetch: buy specified goods, deliver to the house, goods deleted, fixed wage + standing (and exp). Own-house board pays a better rate and stays available at standing 10. Rival board dies at 8.

Simple jobs only: one SKU, one qty, one payday.

---

## Information, Fog, Agents

Default sight: the docked town is known. The rest is fog unless a planted eye’s range covers it (skill-scaled live vision: stall freshness, strings in/out). Map tab remains the no-FoW atlas. Live knowledge lives on eyes, travel watch, and pins — not on rumours.

`where` = settlement id, player wagon, or (later) a string id. Eye on a string can wait; eye on a place is the knowledge game. No courier delay on LoS.

NPC strings do not get rumours and do not grow smarter because you parked an eye.

---

## Rumours and Expeditions (Session 21 September 2026)

A rumour is a **ticket**: origin node, stars 1–5, expiry, optional verified flag. Rumours tab is inventory. No pins on the plate for tickets. Independent of cellars and doors.

**Spend:** at the origin node’s **Outyard**, start an expedition instance — a short chain of placeholder event cards. No wagon tween. Clock jumps by spent watches when the instance ends. Payoff is loot + exp scaled to stars. Ticket burns. Loot that will not fit the rack vanishes.

Length scales with stars (short: on the order of 1 card at 1★, a few at 5★). Fail-forward. Weather at that country may mask which placeholder rows are legal.

**Mint / improve — Socialize (Outyard).**

- Once per Dawn–Dawn.
- Costs **one watch**.
- Face / charisma family when attributes exist; until then, a placeholder card with two labelled forks.
- Success fork, player-chosen, odds modified by player + factor agent: **new ticket** or **+1 star** on an existing ticket (cap 5). Miss = wasted watch.
- Improve does not refresh expiry.
- New tickets: subject may be any dockable node. Local/adjacent may start with more stars. **Expiry floor** = hops(here → origin) + a small weather pad from the *current* worst term on that path (+0 Clear, +1 Heat/Wind, +2 Sandstorm). Never emit a ticket that dies on a clean run plus one delay.

Rescue or other road flavour may still mint a ticket. Stars are **payoff mass**, not P(true) about a stall.

---

## Skills, Attributes, Events (Locked 21 September 2026 — names and shape; numbers and table later)

Four checks. Setting nouns. No PHB sheet and no second skill list.

| Check | Family | Rolls |
|---|---|---|
| **Face** | custom / Socialize | Socialize (mint or +1★), talk rows, custom/tithe talk, later door-talk pokes |
| **Ken** | find / knowledge | Informed forks, identify a find, later quality of what a planted eye reports |
| **Knack** | sand / salvage flavour | Wagon adaptation, restock knack, jury-rig, making a wreck useful |
| **Steel** | threat | Bandit / beast / armed standoff options on a card. No combat screen. No HP track. |

Cards (when the table exists): 2–3 keyed options, d20 + modifiers, visible odds. Riding agents add on the family they exist for (factor → Face, guard → Steel, wrangler → Knack). Find/Ken may sit on the player until a scout seat exists.

**Ken vs Knack:** Ken is what you already understand. Knack is what you invent from what is in front of the wagon. Salvage remains flavour copy on find/expedition rows; Knack is the check those rows use. Weather stays time + leak; Knack only appears when a card offers a workaround.

**Exp** is generic. Sources in direction: commissions, expedition stars, later road cards. On level-up the player places potential into the four checks. Do not auto-distribute. Unique character effects are separate unlocks (named gifts), not extra attributes.

**Starting house** is the racial-pattern choice: a written **+/- package on the four checks** plus **one unique gameplay gift**. Houses are patronage, not species — the gift is house method (how that mark works a wagon), not a bloodline. Other starting houses stay gated in State until Derek asks; Kharûn remains the shipped door. Do not stub the five gifts until they are authored.

Disruption / sabotage gifts are sequel. Do not stub them.

**Until the attribute pass ships:** any feature that would roll a check (road interrupt, Socialize, expedition cards, tariff poke, restock knack) is a **placeholder card** — title, short copy, Continue, optional stub deltas. Do not balance DCs. Do not invent a 12-node web to unblock travel, Outyard, or rumours.

---

## UI Shell — Play Frame

One well. Top tabs unchanged: **Cargo | Map | Rumours**, single-select and close.

```
TOP        House · place or bound-for · Day · Scrubstone · cells/mass · weather pip · Cargo | Map | Rumours · gear
WELL       two content panes  or  atlas plate  or  travel watch
BOTTOM     large place name  ·  banner  ·  House (cities only) | Market | Outyard
```

**Market** — every dock. Buy and sell only. 50/50 hold / stall. **Greyed during watches 6–8.** Player cannot Wait here, so the stall cannot be “open because time slipped.” Arrival after close lands the wagon in the settlement with Market disabled until Dawn; Outyard still works.

**Outyard** — every dock. The only grounded time-and-leave desk:

- Wait (1 watch / half day / full day, remainder rules unchanged)
- Restock travel water/rations
- Socialize (once per day)
- Expedition (if a live ticket names this node)
- Take the road

**House** — **cities only**. Commissions, standing roster, and at the **home seat** an Apartment button that opens the cell. No House chrome on villages or posts. No Wait here.

Road: bottom yards dead. Opening Cargo / Map / Rumours mid-hop pauses the stamp.

**One map, two modes (21 Sep):** Map tab = paused stamp, no FoW. Travel watch = live LOS + weather mass. Same plate.

---

## Game Clock (Locked 21 September 2026)

Unchanged wire: watch = 3h, 8/day, Dawn pulse produce → string act → consume, rumour age on Dawn, arrival freezes remainder, ETA in watch names, pace/fatigue unbuilt.

**Wait is Outyard only.**

Market open watches 1–5; 6–8 Market grey. Outyard verbs still legal at night (Wait the stall open, Socialize if the daily charge remains, restock if the cellar allows, hop).

---

## Travel, Weather, and Road Events

Travel is still the tax on the bet. No overland RPG mode. No combat screen. No bandit sim. No lost-pool.

### Weather (distinct system)

A visible mass on the plate (country-scoped blobs; Perlin or similar for local scud and drift). Edges that cross the same country read the same term.

Closed set: **Clear / Heat / Wind / Sandstorm** (hood 0–3). No Quiet / Watched / Active. No bandit heat pip.

Sample at hop commit (and again if a card fires, later):

- **Time:** Heat/Wind extra watches; Sandstorm more.
- **Leak:** chance or small flat % of rack deleted. Faceless.
- **Gate:** event-row weather masks. A sandstorm deck has no tithe-conversation. Uneventful through a storm is legal — the storm already charged time + leak.

Wait in Outyard lets the mass step. Sandstorm is the Wait test.

Do not write weather into stall rows.

### Events (distinct system)

At most **one interrupt per hop**. Uneventful majority. When a card fires: placeholder (this pass) or 2–3 keyed options (attribute pass). Currencies: watches, cargo %, purse %, rare wagon state. Hits are abstract deletion.

Bandits, beasts, salvage, finds, rescue, custom talk are **flavours of rows**, not systems. Salvage is copy on a find/expedition row.

Do not double-bill: weather took faceless leak; a card should spend a different or smaller named hit.

**Floor:** after modifiers, some chance remains. No 0% road.

Ruin (rare): extract agent, hop aborts to a house seat, cargo may be gone.

Mitigation later: player skill, riding agent, hop hire — as visible modifiers on the card, not a hidden knock-down table. Stub only.

---

## Rival Strings (8 Sep roster, influence retargeted)

Roster and short-haul matrix stay. Shared stall, frozen draft while the player is mid-deal.

**Drop:** house rank on cities as a contest; lost-pool on ruined strings; player sabotage verbs; heat on the profit matrix.

**Keep / retarget:** presence scores on villages and posts from sales; doors emerge; city sales ignored for doors; house respawns a ruined string from a seat after a delay without recycling cargo into the region.

---

## Key Systems (High-Level)

1. Trade goods and live cellars.  
2. Agents and fog (trading knowledge).  
3. Doors and standing (village/post politics).  
4. Commissions (wage, standing, exp, cell objects).  
5. Rumours as expeditions (immersion, loot, exp).  
6. Weather mass + abstract leak + event cards.  
7. Face / Ken / Knack / Steel + authored table — names locked; numbers, gifts, and live table are a future pass. Placeholders until then.

---

## Production Philosophy

Unchanged: core loop first; true nouns; Moody Blocks; map as support; identity is the constraint; gating is build order. Placeholder event cards are allowed so Outyard and travel can exist before the sheet exists.

---

## This is the game

*Caravans of the Cutting Sands* is the project. Unbuilt is unbuilt. Do not frame this as a demo.

---

## Success Criteria

- Knowledge from parked agents changes a buy or a route.
- A village door and a standing shave are readable on the stall.
- A rumour ticket becomes a short instance that feels like the setting, not a market hint.
- Weather on the watch is why you Wait.
- One save can hang all 42 standing objects and fire the matching plaques.
- The well stays one scene. Market is the stall. Outyard owns time.

---

## Open Items

- Live DCs, house gift list, and authored event table (future pass; placeholders until then). Four check names are locked.
- Exact tariff percents, decay, hybrid shortfall band.
- Commission table and exp curve.
- Expedition length and loot bands per star.
- Socialize odds and star-start bands.
- Weather leak rates and mask lists.
- Eye range formula and what “stall freshness” prints.
- Apartment art: 5 shells + 50 objects (scope for a later asset pass; data can stub).
- Exact city/village/post count and plate.
- Catalog names (ids may stay generic).
- Pace / fatigue.
- Player daily eat hook.
- Save / options / other starting houses (still gated in State).
- Engine string rename.

---

## GB note (copy into every task that touches these verbs)

Four checks are named. Do not implement DCs, a live event table, or house gifts until Derek asks. Road interrupts, Socialize, expeditions, and similar beats stay **placeholder cards** (title, paragraph, Continue). Weather labels, Wait, Market-closed chrome, House-city-only, ticket inventory, and commission fetch can ship without a sheet.
