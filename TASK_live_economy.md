# Grok Build task — Live produce / consume (no NPC movers)

**Date:** 14 September 2026  
**Repo:** `Darkgecko777/CuttingSands` `main`  
**Do not** invent SKUs, art, a second UI desk, or rival-string logistics.

Derek pulls `origin/main` as a whole. Commit the smallest set that ships this.

---

## Intent

Replace reset-on-leave stall stock with a **per-node warehouse** that ticks on Clock B days.

- Origins **produce** daily up to a cap, then stop.
- Every dockable node **consumes** daily (silent local drain), weighted by hidden market size.
- The **player wagon is the only mover** this pass. Rival strings do not buy, sell, or haul.
- Price at a node is structural (origin distance + intervening market gravity + local scarcity). Weather is a hook only.

Player fantasy: a Kethra origin good is cheap at Kethra, absorbed hard by Kharûn (and somewhat Ghorath) on the way, and expensive in Veythar if any of it still exists.

---

## Identity

Vision display names stay. Data **ids** may be placeholders.

| Node | Placeholder ids | Vision display names (keep / map) |
|---|---|---|
| Kharûn | `kharun_a` … `kharun_d` | Brineglass, Thirstcake, Spawn-lime, Mark-glaze |
| Zamath | `zamath_a` … `zamath_d` | Witching rods, Night-salt, Listening-sap, Razorreed |
| Thalor | `thalor_a` … `thalor_d` | Highweave, Molt-floss, Mindstain, Frost-vein |
| Veythar | `veythar_a` … `veythar_d` | Speargrain, Edge-oil, Lure-honey, Chaff-weave |
| Ghorath | `ghorath_a` … `ghorath_d` | Oath-wine, Spring-wax, Once-vellum, Exile-iron |
| Ghûl | `ghul_a` `ghul_b` | Deepgrease, Salt-plate |
| Rukh | `rukh_a` `rukh_b` | Spawn-cord, Drowned-eye |
| Neth | `neth_a` `neth_b` | Night-bile, Dusk-hide |
| Kethra | `kethra_a` `kethra_b` | Mute-stone, Thirst-weed |
| Sorel | `sorel_a` `sorel_b` | Day-crust, Reed-heart |
| Draven | `draven_a` `draven_b` | Molt-ash, Echo-block |
| Moraq | `moraq_a` `moraq_b` | Gritback-floss, Lake-tooth |
| Torven | `torven_a` `torven_b` | Hopper-mash, Nest-brick |
| Ashar | `ashar_a` `ashar_b` | Nerve-dust, Cairn-crystal |
| Sarn's Rest | `water` | Water |

If `goods.json` already uses vision-slug ids, **keep those ids** and add economy fields. Do not fork a second catalog. Placeholders are allowed only where a row has no id yet.

Trading posts (**Westmark, Kaleth, Highmark, Southmark, Brineford, Ridgewatch**): no origin SKUs. They hold warehouses and consume by gravity. Markup-only sourcing stays — they do not mint stock from nothing.

---

## Cargo grammar (locked)

- Wagon rack = 16 cells.
- `size` = cells per unit, **1–4**, independent of `mass`.
- `mass` stays on the existing field; do not drive price or produce rate from mass.
- Water `size` 3 / `mass` 4 (existing). Other sizes: copy the 10 Sep vision table (Echo-block is 3; most bulk 2; compact value 1).

Suggested value bands (base coin at origin when stock is healthy, ~50–70% of cap):

| Band | Typical size | Daily produce (origin) | Base origin price | Examples |
|---|---|---|---|---|
| Staple bulk | 2 | 3–6 | low | Speargrain, Thirst-weed, Day-crust, Hopper-mash |
| Industrial bulk | 2–3 | 2–4 | mid | Brineglass, Mute-stone, Exile-iron, Nest-brick, Echo-block |
| Craft / fuel | 1–2 | 1–3 | mid-high | Edge-oil, Spawn-cord, Molt-ash, Spring-wax |
| Compact prestige | 1 | 0–2 | high | Highweave, Night-bile, Mark-glaze, Drowned-eye, Nerve-dust, Oath-wine |

Exact integers live in data. Correlative rule: **higher base price ⇒ lower mean daily produce**. Do not invent quality grades.

---

## Market size (hidden; never print to the player)

| Tier | Rank | Nodes |
|---|---|---|
| Seat city | 10 | Kharûn, Zamath, Thalor, Veythar |
| Clearing city | 8 | Ghorath |
| Heavy village | 4 | Kethra, Torven |
| Village | 3 | Ghûl, Rukh, Neth, Sorel, Draven, Moraq, Ashar |
| Post | 2 | Westmark, Kaleth, Highmark, Southmark, Brineford, Ridgewatch |
| Tap | 0 | Sarn's Rest (no market). Water production only; other goods may sit in a warehouse if the player dumps them, consume rate 0. |

---

## Warehouses

Every dockable node has a warehouse map: `good_id → units` (int).

- Origins start at **60% of cap** for their own goods, **0** for foreign goods.
- Posts / non-origins start at **0** for everything.
- Cap is **per good per node**, not a shared cellar.

**Caps (defaults, tunable in data):**

`cap(node, good) = produce_mean(good) * 8 * max(1, market_size(node) / 4)` at origin.

At non-origin: `cap = produce_mean(good) * 4 * max(1, market_size(node) / 5)`.

Posts use the non-origin formula (small cellars). Sarn cap for water only; other caps 0 or a small dump slot if easier than special-casing sell rejection.

When stock would exceed cap, **clamp**. Production that would overflow is wasted (the well is full). Player sell that would overflow: allow the sale but clamp; pay as if the dest accepted the units (do not strand the player). Log a one-line debug if useful; no player modal.

---

## Daily tick (Clock B)

Tick once per world day: hop day resolved, Skip, or Wait. **Do not** tick while paused in a yard or while a top tab is open mid-hop.

Order per day, all nodes:

1. **Produce** at origins only.  
   `delta = clamp(round(rand_range(produce_min, produce_max)), 0, cap - stock)`  
   Inclusive ints. A prestige good may roll 0.
2. **Consume** at every node with `market_size > 0`.  
   Structural want for `good` at `node`:

   `want = market_size(node) * consume_weight(good, node)`

   `consume_weight` defaults:
   - Origin node of that good: **0.15** (they keep some, they do not eat the whole mint).
   - Other cities: **1.0** for staples, **0.55** for industrial, **0.35** for prestige.
   - Villages: **0.7** staples, **0.25** industrial, **0.1** prestige.
   - Posts: **0.4** staples, **0.15** industrial, **0.05** prestige.

   Daily consume units:

   `units = min(stock, max(0, round(want * consume_rate(good) * rand_range(0.7, 1.3))))`

   `consume_rate(good)` is a small fraction of `produce_mean` so the **region as a whole** does not instantly eat all production. Target: with no player, origin warehouses sit near cap and foreign warehouses stay near empty. Tune `consume_rate` so sum of expected consume across the map ≈ **0.6–0.9 × total produce** for that SKU. Leftover is the slack the player (later strings) can move.

3. Recompute cached prices for nodes the player can see this session (current node is enough; others on demand).

Do **not** simulate intervening absorption as stock movement. Absorption is a **price** term only this pass. Physical units move only when the player buys/sells.

---

## Price (Dune Trader rhyme, our map)

Athas tables used availability × city. We use **scarcity × distance × gravity**.

Let `hops(origin, node)` = shortest hop count on the **existing road graph** (legal Outyard edges). Same node = 0.

Let `path_gravity(origin, node)` = sum of `market_size` of every node **strictly between** origin and node on one shortest path (if several, pick the path with **largest** sum — the absorbing corridor).

```
scarcity = lerp(1.35, 0.70, stock / cap)     # empty dear, full cheap; clamp stock/cap to 0..1
distance = 1.0 + 0.22 * hops
absorb   = 1.0 + 0.04 * path_gravity         # Kharûn 10 on the Kethra→Veythar path hurts Veythar supply price
local    = 1.0                               # hook: later weather / heat
price    = max(1, round(base_origin_price * scarcity * distance * absorb * local))
```

At the origin, `hops = 0`, `path_gravity = 0`, so price is just `base * scarcity`.

Posts use the same formula (they did not produce; hops from origin still count).

Water: special. Produce only at Sarn. `base` low. Other nodes consume water at staple weights if you already treat Water as a stall row; if Water is still a tap with no market, leave that path alone and only warehouse-tick Water at Sarn.

Hook `local` as a named multiplier defaulting to 1. Do not read weather into it this pass.

---

## Player stall

Existing Market draft stays.

- **Buy** commits: subtract units from **current node** warehouse; add to wagon; pay `price` at commit time (snapshot the line, do not live-renumber mid-draft unless the old desk already does).
- **Sell** commits: subtract from wagon; add to **current node** warehouse (then clamp to cap); pay `price`.
- Stall list is live stock, not a reset template. If stock is 0, the line is 0 / hidden / “none” — match existing empty-row habit; do not spawn free origin goods.
- Leaving the node does **not** reset the warehouse.
- NPC strings: **no buy, no sell, no haul** this pass. Their profit matrix may still *read* prices if already wired; they must not mutate warehouses.

---

## Data shape (prefer extending `data/world/goods.json` + node data)

Per good:

```
id, display_name,
size, mass,
origin_node_id,
band: staple | industrial | prestige,
produce_min, produce_max,          # ints / day at origin
base_origin_price,
consume_rate
```

Per node (existing settlement records):

```
market_size,
warehouse: { good_id: units }      # runtime; seed from caps as specified
```

Caps may be derived at load rather than authored twice.

Do not add player-facing market-size or cap chrome.

---

## Files to touch (find the real names on main; do not ingest the tree)

Likely: `goods.json` / world node JSON, Market desk script, Clock B / Wait / hop-day resolver, any `reset stock on leave` call (delete or gate it).

Open only those files and direct callers.

---

## Acceptance

1. Wait one day at Kethra: Kethra origin stocks rise (unless at cap); a foreign good already in that warehouse falls or stays 0.
2. Fill an origin warehouse to cap, Wait: stock does not grow.
3. Buy 2, leave, return later without selling: those 2 are still gone (no reset).
4. Sell Mute-stone in Veythar: Veythar warehouse gains units; Veythar price for that id is higher than Kethra’s at similar scarcity because hops + Kharûn gravity.
5. Trading post never gains origin mint; it only holds what the player sold there, then consumes.
6. Rival strings do not change any warehouse.
7. No new screen. No Word/Wagon chrome regressions.
8. After push: tell Derek the hash.

---

## Out of scope

NPC logistics, weather-in-price, spoil/aging, population, house rank from deliveries (already exists — do not retune unless a compile forces it), unique art, collapsing the catalog, Sarn market, Rumours about prices.
