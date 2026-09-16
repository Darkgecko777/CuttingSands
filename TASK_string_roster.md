# Grok Build task — String roster (19 tokens, chips, stall use)

**Date:** 16 September 2026  
**Repo:** `Darkgecko777/CuttingSands` `main`  
**Vision:** Rival strings (8 Sep 2026) + Live Economy (shared stalls)  
**State:** lifts “19 strings” off the do-not list for **presence and stall use**. Rank / intrigue stay off.

Derek pulls `origin/main` as a whole. Smallest commit set. No unique art. No rank.

---

## Intent

Twenty marked merchants exist. Each house is entitled to one active mark per rival house → four chairs per house. The player occupies one chair of the starting house. **19 NPC tokens** fill the rest.

They are carbon copies of the player wagon (same rack **16 cells / 36 mass**, no kit variants). They stand on the **same stall number** you do. They buy and sell into the same cellars.

They do not play a travel watch. They **re-seat** on Clock B, then act at the node they occupy. The Map atlas shows who is in a town without covering the town glyph.

House influence / rank does **not** change price this pass. When that comes later it is willingness or a personal courtesy, not a second cellar price.

---

## Roster

- Five houses. Four chairs each. Total **20** marks including the player.
- Player is chair 0 of the starting house (Kharûn if that is still the only start).
- Seed the other 19 on day 0 across dockable `has_market` nodes. Spread them. Do not stack all 19 on the start town. Cities may hold more than posts.
- A token has: `id`, `house_id`, `chair` (0–3), `node_id`, `purse`, cargo on the same cell/mass grammar as the player.
- Starting purse: one authored int for every token (e.g. same as a new player purse if that exists; otherwise `400`). Identical.
- Starting cargo: empty rack. They fill from stalls.
- One run, fixed roster. No trait randomizer.

Data: `data/world/strings.json` **or** generate deterministically from house list + node list with a fixed seed. Prefer data if houses are already listed.

---

## Clock B order

Same day pulse as now (hop day, Skip, Outyard Wait; not while a top tab pauses a hop). Do not split Clock B into 19 watches.

1. Produce (existing).
2. Each NPC token, stable id order:
   - **Trade** at `node_id` (below).
   - Then **re-seat** or stay.
3. Consume (existing).

Re-seat: 50% stay, else a random adjacent dockable `has_market` node (1 hop). Snap. No tween, event, tithe, or weather spend. Sarn is not a market; tokens do not sit there.

Player is not simulated as a 20th AI body. Player chip = player is in that settlement. On a hop with no tab, player is in no town HBox.

---

## Trade (shared stall)

Tokens read `MarketBook.local_price` at real cellars. They do **not** use the player ledger. They may see current prices at their node and at nodes **1–2 hops** away (extended knowledge, not full-map omniscience).

**One act per token per day.** Either buy or sell, not both.

**Sell** if the rack holds a good whose price here is at least **15% above** the best price they can see at a 1–2 hop node they would treat as “buy origin” *or* simply: sell if local price ≥ 1.15 × the lowest price among those visible nodes for that good, and they hold at least 1 unit. Prefer the good with the largest spread. Sell `min(held, 2)` units. Purse += price × units. Stock on this node += units then clamp to cap (same as player sell).

**Buy** else, if purse and rack allow: pick the good with the largest implied spread  
`best_visible_price_within_2_hops − local_price`, require spread ≥ 15% of local (or at least +2 coin). Buy `min(2, stock, rack room, purse/price)` units. Must fit cells and mass. Purse −=. Local stock −=.

Skip the act if no legal buy or sell. Do not short, do not mint, do not teleport cargo to another node.

Water and rations are legal rows. Origin letters are legal. Empty stall rows stay hidden. Two tokens in the same town resolve in id order against the live shelf (the second may find the row gone).

No house-colored price. No private warehouse.

---

## Map chrome

Kill the existing player sprite on the atlas.

One chip template, Godot defaults only: `ColorRect` + `Label`.

- Color by house (five authored colors; fix collisions in data, not with a sixth shape).
- Label: short house mark + chair index.
- Player chip: same template plus a 1px ring or extra pip.

**Layout:** town glyph and name stay the node. Merchants at that node sit in a **small HBox under the glyph**.

- Player chip first if present, then others.
- Visible cap **4**. Overflow as `+N`. Do not let the box eat the next town.
- Chip means present in that location. Do not draw chips on road edges.
- Clicking a chip does nothing extra this pass.

Map tab only. Do not spawn 19 chips on the hop watch.

---

## Do not implement

- House rank / influence on the stall number.
- Fog of war on tokens (seeing every chair on Map is the test).
- Travel interrupts, salvage, intrigue, agents, save.
- Personality traits, wagon variants, cargo UI for NPCs.
- New tab or inspector. No “what is this token holding” panel unless one already exists and is trivial to reuse — default **no**.

---

## Files

Likely: `string_book.gd` (or similar), `data/world/strings.json`, Map atlas / `field_shell.gd` Map pane, Clock B next to `MarketBook.tick_day`, `market_book.gd` buy/sell helpers reused not forked, cargo cell/mass helpers already used by the player rack.

Open those and direct callers only.

---

## Playtest

1. New run, **Map** in starting Market: player chip in the start HBox; other towns show a spread of house chips; glyphs readable.
2. **Wait** several days in Outyard: HBoxes change; stall quantities at towns you revisit are **not** frozen at seed — some rows moved without you.
3. Mid-hop Map: world paused; tokens do not trade or re-seat while the tab is open.
4. You and a token in the same Market: you see the same printed price. Buying the last units can empty a row they wanted; that is correct.
5. A post you left stocked can later show less water/letters after days pass even if you never returned.

---

## After this ships

Update `docs/State.md`: this task becomes **Current**, prior Current becomes **Prior**. Outcome: 19 tokens present, re-seat on Clock B, buy/sell on the shared stall (1 act/day, 1–2 hop spread). Rank still off.
