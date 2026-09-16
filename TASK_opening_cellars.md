# Grok Build task — Opening cellars (including posts)

**Date:** 16 September 2026  
**Repo:** `Darkgecko777/CuttingSands` `main`  
**Vision:** *Live Economy — Cellars, Rations, Bands*  
**Does not supersede** `TASK_economy_revise.md`. Additive seed only.

Derek pulls `origin/main` as a whole. Smallest commit set. Do not invent SKUs, art, strings buy/sell, or a second price formula.

---

## Intent

Every `has_market` node starts with stock **beyond what it mints**, so a first visit is not a blank stall. Posts stay markup-only: they still mint nothing. The player wagon is still the only mover after seed.

Seed is a frozen “the road already happened once.” After day 0, shelves only change by mint, consume, and player buy/sell.

---

## Do not change

- Mint rules from Current (`economy_revise`): cities 4 letters, villages 2, posts none. Cities/villages mint rations + water. Sarn water only. Posts mint 0.
- Price formula, bands 0.70 / 1.45, buy = sell.
- Consume formula and post weights already in `market_book.gd`.
- Clock B. Cap formulas.
- Player ledger, emergency convert, chrome, travel.

---

## Seed rule

Replace the current `seed_all()` behaviour that fills **only** `can_mint` rows at 60% of cap and leaves everything else at 0.

**Mintable rows** (unchanged idea):

- If `can_mint(node, good)`: start at **60% of cap**, floored.

**Imported sliver** (new), only when `has_market` and `market_size > 0` and the good is **not** mintable here:

- Origin letters only (not a second copy of water/rations logic).
- Include the letter if shortest hops from `origin_node_id` to this node is **1 or 2**.
- Quantity: `max(1, floor(cap(node, good) * sliver))` where  
  `sliver = 0.25` at 1 hop, `0.12` at 2 hops.
- Hops 0 is mintable and already handled. Hops ≥ 3 stay **0**.

**Water and rations at posts** (new cache, no mint):

- Posts do not mint these. Seed them anyway so a waystation has a sip.
- Quantity: `max(1, floor(cap(post, good) * 0.40))` for both `water` and `rations`.
- Cities and villages already get 60% from the mintable rule. Do not double-fill.
- Sarn: water only, 60% of its water cap. No rations. `market_size` 0 still means no consume.

**Do not** author a per-node crate list this pass. No `price_quirks`. No refill of imported slivers or post staple caches — consume burns them; only a player sell puts them back.

Empty stall rows still hide.

---

## Files

Likely: `scripts/autoload/market_book.gd` (`seed_all`), `world_book.gd` if hops helpers live there, `data/world/settlements.json` / `goods.json` only if a missing field blocks the rule (prefer no JSON schema change).

Do not touch string / map / hop code.

---

## Playtest

1. New run, start Market in Kharûn: own letters + water + rations present. At least some 1-hop village letters on the stall (Kethra corridor if that is 1 hop).
2. Walk to **Kaleth** or **Westmark** without selling anything: stall shows water, rations, and a thin mix of nearby origin letters. Wait a day: those rows tick down or hold; water/rations do **not** mint back up.
3. Wait a day in Kharûn: local mint still rises toward cap.
4. Sarn still has no market / no origin letters. Rukh still the cheap water well vs Westmark markup.

---

## Out of scope

NPC tokens. Rank / house influence. Player daily eat. Weather on price. Opening a second economy layer.
