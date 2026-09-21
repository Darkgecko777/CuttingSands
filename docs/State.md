# State — Caravans of the Cutting Sands

Handshake for Grok.com (creative) and Grok Build (implementation). Read this instead of scanning the repo.

Keep **two** shipped tasks only. After each completed task: new work becomes **Current**, old Current becomes **Prior**, drop anything older. Spec files stay at repo root (`TASK_<name>.md`); this file is the outcome, not a recap of the spec.

**HEAD:** `cd9f536` on `main` (15 Sep 2026) · weather, yard authority, game clock, string roster, doors, and rumour tickets are in the working tree, not committed  
**Play:** Godot 4.7 · `scenes/map/field_shell.tscn` after house select · start in Market.

---

## Current — `rumour_tickets`

**When:** 21 Sep 2026 · working tree · spec `TASK_rumour_tickets.md`  
**Vision:** Rumours as expedition tickets. Independent of markets. Placeholder cards only.

A rumour is a ticket. Socialize in the Outyard mints or bumps one. At the origin Outyard the player walks a short stub and takes loot. Tickets do not write prices.

**Shipped**

- Ticket fields: origin, stars 1–5, last valid day, verified (always false this pass). The Rumours tab lists them. No map pins. Dawn drops a ticket once the day has moved past its last day. Life is hop count along the path, plus one pad from the worst current term on that path (Clear +0, Heat or Wind +1, Sandstorm +2). A same-yard ticket holds through today.
- Socialize spends one watch, the same remainder as Wait 1 watch, then always succeeds. The card sits in the center of the window. Forks are New ticket and Improve existing. Improve is dead when every ticket is already five stars. One sit per day. New tickets prefer this dock or a neighbor and start at 2 or 3 stars; a farther dock starts at 1. Sarn is not a subject. Improve adds one star and does not move the last day.
- Expedition is live when a ticket names this dock. One card at 1 star, two at 2, three at 3–5. The wagon does not tween. The last card pays 8 scrubstone per star and that many rations; units that do not fit are deleted. `GameState.exp` gains the star count. The ticket burns, then the clock jumps one watch per card.
- Stall arrival notes still mint for the price tooltip. They are no longer the Rumours tab.

**Where:** `rumour_book.gd`, `placeholder_card.gd`, `word_desk.gd`, `field_shell.gd`, `game_state.gd`.

---

## Prior — `doors_and_commissions`

**When:** 21 Sep 2026 · working tree · spec `TASK_doors_and_commissions.md`  
**Vision:** House influence + standing + commissions. No intrigue, no apartment, no exp sheet.

Villages and posts have a door. Cities and Ghorath do not. Standing moves only when a commission is turned in.

**Shipped**

- Opening presence at each village and post is `100 / hops` to that house’s seat. The highest score holds the door. A tie keeps the previous door. With no previous door, a tie falls to the player’s home house. Kaleth opens as Kharûn. Ghûl and Moraq open as Ghorath. Neth, Sorel, and Southmark open as Zamath. Torven, Ashar, and Ridgewatch open as Thalor. The other fluid docks open as Kharûn.
- A sale stamps that seller’s house: units × pre-cut local price × 1 when the row is under half the cellar, otherwise × 0.5. Each Dawn, before strings act, every score × 0.9. The stall line shows house, standing, and cut. 12% at standing 0, one point per rung, 4% at 8. Cities and Ghorath take no cut. Outyard restock and string purses stay on the raw price.
- Standing starts at 1 with the home house and 0 elsewhere. Home cap 10. Rival cap 8. Turn-in deletes the lot, pays the wage, and adds 1 standing until the cap. A rival board hides at 8. The home board stays at 10 and still pays. Commission rows are still empty.

**Where:** `door_book.gd`, `field_shell.gd`, `game_state.gd`, `cargo_hold.gd`, `string_book.gd`, `world_book.gd`, `commissions.json`.

---

## Do not implement until Derek asks

Weather step on Wait; house rank / intrigue; personality traits; travel interrupts, salvage, ruins; stacked-in-cell cargo; player daily eat; skills, agents, save/options, other starting houses. Attribute checks on Socialize wait for the skill sheet.

Chrome and well layout are locked (see `AGENTS.md`). Play is one well. Do not revive `city_hub` / `world_map` / `main_game`.
