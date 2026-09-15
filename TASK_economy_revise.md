# Grok Build task — Revise live economy (rations, bands, player ledger)

**Date:** 14 September 2026  
**Repo:** `Darkgecko777/CuttingSands` `main`  
**Vision:** `TraderOfTheCuttingSands_Vision.md` section *Live Economy — Cellars, Rations, Bands*  
**Supersedes** `TASK_live_economy.md` where they disagree (water-only-at-Sarn as the *player* well; no rations row; no floor/ceiling; no tooltip ledger).

Derek pulls `origin/main` as a whole. Smallest commit set that ships this. Do not invent display nouns, art, a new desk, or rival-string buy/sell.

---

## Intent

Keep the warehouse tick. Correct the catalog and price shape to the 14 Sep lock.

- Cities mint **4** origin letters. Villages mint **2**. Posts mint **none**.
- Cities and villages also mint **rations** and **water** (authored rates). Posts do not mint those either; they only hold stock sold in.
- Every market **consumes** stock it actually holds. No teleport.
- Price stays a readout of the cellar, **clamped** to a per-node floor/ceiling.
- Player tooltip: **cheapest buy + town**, **highest sale + town**.
- Player wagon is still the only mover. Strings do not mutate warehouses.

---

## Goods

Do not fork a second catalog. Extend `goods.json` (or the real file on main).

**Origin letters.** Keep existing ids if present. Otherwise `kharun_a`…`kharun_d`, `zamath_a`…`d`, `thalor_a`…`d`, `veythar_a`…`d`, `ghorath_a`…`d`, and two letters per village (`ghul`, `rukh`, `neth`, `kethra`, `sorel`, `draven`, `moraq`, `torven`, `ashar`). Display names already in data stay. Do not author new flavour names.

Per origin letter:

```
id, display_name,
size, mass,
origin_node_id,
produce_min, produce_max,
base_origin_price,
consume_rate,
edible: bool          # default false; set true only if a row is already an obvious food or when data already says so
ration_yield: int     # units of rations per 1 unit smashed; 0 if not edible. Default 1 if edible.
```

**Shared rows** (not part of the 4+2):

| id | origin mint |
|---|---|
| `rations` | every city and village; **not** posts; **not** Sarn |
| `water` | every city and village, plus Sarn; **not** posts |

Rations and water use the same cellar rules as letters. They have no single origin for the distance band — use a **local** band (distance 0 at the node that minted this stock is wrong for pooled water). Practical rule:

- For `rations` and `water`, **floor/ceiling are authored per node** (see bands). Do not use hops-from-Kharûn.
- For origin letters, hops-from-`origin_node_id` sets the band.

Mark existing food-like rows `edible` only when the current display name is already a food (e.g. Speargrain). Do not guess the rest.

---

## Node mint rates (defaults, tunable in data)

Hidden `market_size` unchanged: seats 10, Ghorath 8, heavy villages 4, villages 3, posts 2, Sarn 0.

**Water produce per day** (ints, then cap):

| Node | produce_min–max | Note |
|---|---|---|
| Sarn's Rest | high (e.g. 6–10) | oasis; not a market |
| Rukh | high (e.g. 4–7) | first player-facing cheap well |
| Ghorath | mid-high | kinder local water |
| Other cities / villages | low–mid | street exists |
| Kharûn | trickle (e.g. 0–2) | dear unless imports sit on the shelf |
| Posts | 0 | no mint |

**Rations produce per day:**

| Node | produce_min–max |
|---|---|
| Cities / villages | mid (e.g. 2–5); farm-ish villages may sit at the top of that range if a village already has a grain letter |
| Kharûn | low–mid (city still plates itself; not a bread basket) |
| Posts / Sarn | 0 |

Origin-letter produce stays as in the current live-economy data / prior task bands (staple more units, prestige fewer). Cap formulas already on main may stay if they exist; otherwise:

- Origin letter at origin: `produce_mean * 8 * max(1, market_size/4)`
- Same letter elsewhere: `produce_mean * 4 * max(1, market_size/5)`
- Rations/water at a minting node: same local-origin style cap from that node’s produce_mean
- Posts: cap small; fill only from player sells

Overflow clamps. Player sell that overflows still pays; then clamp.

Sarn: warehouse for `water` only. Other caps 0 (or a dump slot if sell-reject is harder). `market_size` 0 ⇒ consume 0.

---

## Daily tick (Clock B)

Same clock as now: hop day, Skip, Wait. Not while paused in a yard or a top tab mid-hop.

Order, all nodes:

1. Produce origin letters at their origin.
2. Produce rations / water at nodes allowed to mint them.
3. Consume each good that has stock, using existing want × consume_rate × jitter, `min(stock, eaten)`.
4. Refresh cached prices for the current node (others on demand).

Target wash: region mint a bit above region eat for each letter so origins can refill. Tune consume_rate rather than adding new systems.

---

## Price bands

Keep the existing raw readout if it is already on main (scarcity from stock/cap, distance, gravity). Then **clamp**:

```
raw = existing price function
price = clamp(raw, floor(node, good), ceiling(node, good))
```

**Origin letters:**

```
mid    = base_origin_price * (1 + 0.22 * hops(origin, node)) * (1 + 0.04 * path_gravity)
floor  = round(mid * 0.70 * quirk)
ceiling = round(mid * 1.45 * quirk)
```

`quirk` defaults **1.0**. Reserve a per-node-per-good field. Do not fill lore quirks this pass.

**Rations and water:**

Author `base` per node (Kharûn water high, Rukh water low, Ghorath water lower than Kharûn). Floor = `0.70 * base`, ceiling = `1.45 * base`. Live scarcity still walks inside the band.

Buy and sell use the same stall number at that node (current desk habit).

---

## Player ledger

When the player can see a stall line for a good (Market), record:

- `lowest_buy_price`, `lowest_buy_node_id`
- `highest_sell_price`, `highest_sell_node_id`

Update if this node’s current price is a new low (treat as purchase price) or new high (treat as sale price). Same number for buy and sell is fine.

Tooltip on that good (stall and cargo if a tooltip already exists): two lines, no extra chrome.

```
Lowest buy  12  Kharûn
Highest sale  31  Veythar
```

Empty if the player has never seen that good. Do not show world-best. Do not write these fields from rumours.

---

## Emergency convert

Cargo (or Market if that is the only place units can leave the rack): if a unit is `edible` and `ration_yield > 0`, allow **one** convert action.

- Remove 1 unit of the letter.
- Add `ration_yield` rations if cells allow; if the rack cannot fit the rations, refuse the convert.
- Rate must read as a loss versus buying rations in a normal town (yield of 1 from a 2-cell food is already a loss). Do not add a recipe book.

---

## Player eat

**Do not** wire daily ration/water drain this pass. Rows exist; consume hook later.

---

## Player stall

Unchanged draft. Buy subtracts local warehouse. Sell adds then clamps. Leave does not reset. Empty line stays empty. Strings still must not buy, sell, or haul.

---

## Files

Find real names on main. Likely: goods / node data, Market desk, cargo tooltip, Clock B tick, any reset-on-leave. Open those and direct callers only.

---

## Acceptance

1. City has four origin letters minting; village two; post zero origin letters.
2. Wait at a city: local rations and water rise unless at cap. Wait at a post: those two do not mint.
3. Kharûn water price band sits above Rukh’s when both cellars are similarly full.
4. Buy at origin, leave, return: stock did not reset.
5. Sell a letter in a far city: cellar rises; price stays inside that node’s band.
6. Tooltip records a new low/high with the town name when the stall is seen.
7. One edible convert produces rations at `ration_yield` and refuses if the rack cannot hold them.
8. Strings do not change warehouses.
9. No new screen. No *assay* / *slip* / Word chrome. No new display nouns.
10. After push: tell Derek the hash.

---

## Out of scope

NPC logistics, player daily eat, lore quirks filled in, weather-in-price, spoil sim, population, unique art, Rumours writing the ledger, Sarn as a full Market, access rules that hide Sarn from the player beyond `market_size` 0.
