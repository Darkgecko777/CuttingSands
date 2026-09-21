# Caravans of the Cutting Sands — Project Vision

**Status:** Active direction (updated 21 September 2026; game clock in 3-hour watches; one map two modes; compound cell / house marks; one game, not a demo)  
**Engine:** Godot 4.x  
**Platform target:** Steam (using an existing paid slot)  
**Primary goal:** Ship *Caravans of the Cutting Sands* — a trading + intrigue game that delivers the marked-wagon fantasy. The project is the game. Systems arrive when they are built. There is no separate demo product, test slice, or “later real game” sitting behind this one.

The working title was previously *Trader of the Cutting Sands*. The official name is **Caravans of the Cutting Sands**. Repo and some engine strings may still say CuttingSands / Trader until a rename pass.

---

## One-Sentence Pitch

A desert trading and intrigue game in which you buy on knowledge, risk the journey with one marked wagon, and try to convert an information edge into profit before rival houses, bandits, or the desert itself close the gap.

---

## Core Player Fantasy

The feeling first awakened by *Dune Trader* (Dark Sun, AD&D 2nd Edition):

- You possess (or believe you possess) non-obvious information about supply, demand, risk, or opportunity.
- You commit capital and reputation on the strength of that knowledge.
- You must survive the journey and the attention it attracts.
- Success feels earned because you outmaneuvered competition, read the situation correctly, or executed a clever edge (“hack”).
- Failure carries real weight — lost cargo, damaged reputation, or worse.

Numbers going up only matter when they are attached to this specific kind of agency and risk.

Both the sharp knowledge-edge fantasy and the quieter satisfaction of building early structural advantage (reputation, preferred access, better information flow) are desired. Both must be delivered through merchant means: the player never conquers cities or rewrites the economic map by force.

**Brand intent — immersion.** The player should feel like the person under the mark: glove on the pouch, one load on the road, one rumour they chose to trust. Consequence concentrates on that stake. This is not a company-management comfort layer with an optional avatar.

**Brand intent — Uncanny Mercantile (locked 1 September 2026).**  
The load itself must feel like this world. Unique fantasy goods are not garnish, lore frosting, or a later art pass. They are how the player *touches* the setting. The brand loves the grain of old-world commodity trade — origin monopolies, fragile hauls, ugly extraction, ritual demand, long distance between the thing and the people who want it — flipped into fantastical production. Spice as basilisk bile, silk from horse-sized territorial insects, cane that cuts the harvester: that inversion *is* Uncanny Mercantile.

A desert with generic Iron / Spices / Cloth is a template economy wearing a costume. Water and staple grain may stay ordinary; they keep thirst and calories honest. The vast majority of what rides the wagon should be things that could only exist here. Names are interaction. The stall does not need icons before it needs true nouns.

---

## Setting Direction

A **mirrored fantasy** of Dark Sun / Athas:

- Enough structural and tonal similarity that veterans of the original material will feel a spark of recognition (harsh desert world, scarce resources, powerful merchant houses, dangerous travel, political and magical undercurrents).
- Distinct enough in names, history, cosmology, and specific details that it stands as its own setting rather than a direct adaptation or pastiche.

The world should feel desperate, utilitarian, and alive with competing interests. Beauty is harsh and hard-won. Water, information, and safe passage are forms of power.

The market is larger than any single house. Houses operate inside a system they can influence but cannot own or redraw through territorial control. The player is a marked agent inside one house, not the house as an institution. This constraint is intentional and sharpens the knowledge-edge fantasy.

### Trade Goods — Uncanny Mercantile North Star (Locked 1 September 2026)

Most traded goods are native to this setting. Ordinary bulk (water, staple grain) may remain ordinary. Signature goods invert familiar commodity roles through fantastical production, danger, or monopoly.

Goods exist to be believed, doubted, hauled, and lied about — not to decorate a generic market. A rumour and a house custom should be able to *name the thing* and still sound like the box.

**A good is ready when it has an old-world rhyme and a local wound.**

- **Rhyme:** what historical commodity is it *acting like*? (spice, silk, salt, indigo, incense, pitch, steel, tea, alum.)
- **Wound:** what does this world pay to get it? (territory, poison, night shores, a house monopoly, a craft that cannot leave Zamath, coins that dissolve.)

If a proposed good cannot support a 3-star rumour that would make the player reroute the only wagon, it is flavor text, not a trade good.

**Scope guardrails (so this does not become a catalog product):**

- Origin catalog is **4 unique goods per city** (Ghorath counts as city-tier) and **2 per village**. Trading posts mint none. Rations and water are separate stall rows, not those letters. Width is allowed to exceed the old 10–14 north star. *Truth of the names* still matters when a letter is named; ids may stay generic (`kharun_a`) until then.
- All goods that will exist in the region are available from the start. No unlocking new commodities as progression.
- Origins stay few and sticky (mint, forest, shore, hypersaline belt, a single craft seat) so knowledge can compound.
- One short paragraph plus producer, risk/spoil tag, and rumour shape is enough. The rest appears in house custom and rumours — not in a bestiary dump.
- Placeholder template goods (Iron, Spices, Cloth as generic SKUs) are a motivation tax. Replace them with setting nouns before investing in unique art.
- Do not add a second economy of crafting trees or quality grades to justify the fantasy. The production story lives in the name and the map role. Emergency smash of an edible letter into rations is a panic verb, not a craft tree.

Scrubstone coin remains currency and desalination feedstock; it is not “just another row on the stall.”

### Scrubstone, Currency, and the Water Constraint (Locked)

Scrubstone is the region’s currency and the key industrial material for efficient desalination. It is produced only in Kharûn and is exported almost exclusively as minted coin. Minting is the critical value-adding step; raw or bulk scrubstone does not leave Kharûn in meaningful quantities. This protects Kharûn’s interlocking monopolies on the material, the process, and the trusted form of the currency.

Coins are soluble in concentrated salt water (their primary industrial function). Ordinary sweat causes slow, long-term erosion, so merchants of every recognized house wear functional and ceremonial gloves and keep coinage in house-marked pouches. The recognizable glove-and-pouch combination is the visible guarantee that the coins are official mint product and have been properly handled. Independent traders can imitate the gear, but only house-marked equipment carries institutional trust and eliminates the need to test every coin by hand.

Kharûn has no generous local water. It can plate a trickle so the street exists, but cheap bulk water does not belong to the mint city. **Sarn’s Rest** is the oasis anomaly: only **Rukh** has true access. Rukh hauls water (and its own village goods) to **Westmark**. Kharûn is merely the nearest seat on that chain, not the owner of the tap. Survival still runs through trade. The hostage is geography and desalination feedstock, not a Kharûn deed on Sarn.

Scrubstone is produced and consumed at a relatively fixed rate. This imposes a soft ceiling on regional population and prosperity that functions as internal consistency for the designer. Populations of cities and villages are treated as fixed and are never presented as numbers or systems to the player. There is no formal population control in the setting, no fluff about family size, and no player-facing demographic simulation. High baseline mortality and periodic water-pressure events are sufficient to keep the constraint felt without explicit modeling. Growing settlements through trade volume is interesting as a thought experiment and is not part of this game.

### Merchant Houses — Origin, Pact, and Membership (Locked)

Merchant houses exist because pure independent traders and pure city-controlled logistics both failed after the last major collapse of reliable overland routes. Houses are a third category: permanent, multi-generational organizations that can maintain reputation, credit, route knowledge, and enforcement capacity across political boundaries. Cities tolerate and in most cases prefer them because they solve a coordination problem that neither anarchy nor total city control could solve.

**Inter-house understandings (pragmatic custom, not a written constitution):**
- Mutual recognition of authenticated coinage and house marks. Systematic counterfeiting or debasing of another house’s mark is one of the few acts that can provoke coordinated retaliation.
- Limited safe-conduct for marked caravans on major arteries, provided the houses are not actively at war.
- A rough understanding that no single house will be permitted total monopoly over the movement of scrubstone coin or critical secondary goods. When one house approaches that line, the others quietly reopen alternative channels.
- House Ghorath functions as the pressure-release valve and neutral ground precisely because the other houses need a place none of them fully control.

**House–city relationship:**
- Each major house is “of” a city in the sense of home seat, core relationships, and primary political ties. The city receives reliable access to goods it cannot produce and a cut (tariffs, contracts, preferred pricing). The house receives legal standing, warehouse rights, and a degree of protection inside the walls.
- A house is not a department of its city. Its agents answer first to the house and are not ordinary citizens while acting under mark. This is why a Kharûn agent can operate in other cities without being treated as a foreign spy by default.
- Cities retain the right to close gates, raise tariffs, or expel local factors. Houses retain the right to redirect caravans and starve a city of critical goods. The balance is constantly renegotiated through leverage.

**Why an individual trader joins a house:**
- Access to the trusted glove-and-pouch system (without a recognized mark every transaction carries a steep distrust discount or requires testing the coin by hand).
- Credit and the ability to operate on float rather than pure hand-to-mouth cash.
- Route intelligence, preferred warehousing, and a degree of protection or retaliation if a marked caravan is hit.
- Legal and social standing inside cities.
- The long-term possibility of rising inside the house structure.

In exchange the house takes primary loyalty (house before personal citizenship or origin while under mark), a cut of profits, and the obligation to prioritize house interests. Most competent independents eventually join or are absorbed; those who remain truly free operate in the cracks and are never fully trusted.

The five existing houses fit this framework directly: Kharûn (material and minting monopoly, contracts and quiet leverage), Zamath (complementary scarce goods and pragmatic willingness to deal with the Shore Clans), Thalor (proud dependent), Veythar (deliberate isolationism, participates only as survival requires), and Ghorath (neutral clearing house for debts, exiles, information, and second chances).

### Player Representation — Marked Agent, One Caravan (Locked 30 August 2026)

The player is one rising agent under a house mark, travelling with **one caravan**. The house is patronage and constraint — credit, glove-and-pouch trust, standing, a cut of the take — not a company the player operates.

This supersedes the earlier “hybrid uber caravan master” lock (26 August 2026). That model preserved a Patrician / Port Royale fleet layer and treated the avatar as optional enhancement. It fought the immersion intent and the world fiction of an individual merchant improving capacity *inside* a house.

**What the player is:**
- The only person who buys, sells, and commits cargo.
- Present to the journey: when the wagon is on the road, that is the player’s stake.
- Able to rise in skill, credit, and house standing without becoming a dispatcher of other captains.

**What the player is not:**
- A house office running multiple independent caravans.
- A detached overseer whose body never has to take the road.
- An embodied overland RPG avatar walking town tiles.

**Agents are tools on that stake, never parallel caravan masters.** They do not run their own trade loop. They either:
- Ride with the wagon (road kit: weigh the load, custom, escort, capacity handling on *this* hop), or
- Sit in a city as planted eyes (fog, rumours, freshness of market knowledge).

Economy stays solely in the player’s purse. Intrigue is how the player changes what they are allowed to know.

**Failsafes against permanent death:**  
Mishaps, ambushes, and desert events still cost cargo, time, reputation, injury, or delay. The player character is protected by diegetic house extraction, safe-conduct, and institutional recovery so that permanent death is off the table. The wagon can be ruined; the run should not hard-end on a single ambush.

**Design guardrails:**
- Do not add a second player-owned caravan “just in case.”
- Quests and personal actions feed the core loop: reputation, better information, preferred rates, new agent attachments, or political leverage. Side content detached from trading and intrigue is out of scope.
- Travel stays abstracted (destination/route + watch phase with time, risk, and events). No full overland RPG movement mode.
- Combat, if it appears, is a rare tax on the road — not the reason the road exists. This is not *Tradesman: Deal to Dealer*.
- Camera follows the selected catalog item. There is one wagon pin that matters.

### Coin, Compound Cell, and Marks (Locked 18 September 2026)

Three ledgers. Do not mix them.

**Coin** spends on risk management only: wagon kit on the single pin (cells/mass in small steps, weather furniture, marked coffer, watch kit, a bunk that shortens a laid-up stay) and a banked reserve against tithe, delay, and ruin. Coin never buys house rank, a chair, civic status, or furnishings. Cosmetics and power do not share an SKU. No upgrade reads as 0% road risk. No second wagon.

**Deeds** furnish the house compound cell. The house *assigns* the cell at the home seat when the player takes a chair. It is not a purchased townhouse and not nobility. Each Steam achievement has one corresponding object in that cell. The object names the read; the house names the grain. Objects never alter tariffs, stall access, or safe-conduct.

**House rank** (the standing / experience track, not a shop) improves the *cell* — shelf, desk, light, a display rail other chairs may eventually see. Rank does not upgrade the souvenirs. A poor cell holding a real deed outranks a beautiful cell holding bought rugs.

**Steam** only mirrors objects that already exist in the cell. Hidden until the object lands. No “earn N coin” plaques. Numeric grind is the wrong lure.

**Five house capstones.** Each house is a different reason to keep a reserve and a different deed that hangs. All five belong to this game. Other starting houses remain gated as build order, not as a second product. Visitor objects (a deed earned while marked for another house) and chair capstones are different lists if both exist; the capstone is the house you serve.

| House | Unique play | Capstone deed | Object in the cell |
|---|---|---|---|
| **Kharûn** | Coin, contracts, quiet leverage. Win by float and by not needing the tap. | Clear a loop while holding a reserve large enough that a tithe cannot empty you | A sealed pouch on a glove-peg, stamped but unopened |
| **Zamath** | Scarce complementary goods, Shore pragmatism. Win by touching what other houses will not. | Profit a Shore-touched letter without dumping it to panic rations | A stoppered vial / wrapped length that still smells wrong |
| **Thalor** | Proud dependent. Win by making the dependency look like dignity. | Sell a Thalor origin two hops out at a personal high, then bring a gift-good home | A folded cloth hung as if it were a banner, slightly too fine for the cell |
| **Veythar** | Isolation until survival requires otherwise. Win by leaving late and leaving clean. | Complete a necessary foreign hop and return with the mark unstained (no dumped marked load) | A closed shutter-box; opened only after that return |
| **Ghorath** | Debts, exiles, second chances, information. Win by being the place others have to stop. | Take a rescue rumour on the road and sell the story at Ghorath, not the cargo | A blank token on the desk — someone else’s mark, paid through you |

Under the capstones sit smaller deed-objects any chair can earn (first two-hop origin sale, first extraction, first time a string takes the obvious stall). Those fill shelves. The capstone changes the character of the room.

The cell lives in the existing House yard pane (desk stub). It is not a fourth top tab and not a decorating mode.

---

## Scope Boundaries

### What this game is
- A focused trading + intrigue experience on a single desert-focused map.
- A small closed catalog of setting-native goods (uncanny commodities plus honest bulk water/grain).
- One player caravan. Agents and rumours as the information layer around it.
- 8–9 major cities plus supporting villages/outposts.
- Persistent rival houses that act as real competitors (sabotage, violence, political maneuvering) against *this* wagon and *this* mark.
- Information as a resource: rumours with a reliability rating, not free perfect knowledge.
- Meaningful constraints in the form of laws, tariffs, and local political realities that feel somewhat arbitrary or self-interested.
- Primarily UI-driven systems with a supporting visual map layer for spatial intuition, route choice, fog, and event placement.
- Travel abstracted enough to stay manageable (destination/route selection + travel phase with time, risk, and events).

### What this game is deliberately not
- A Patrician / Port Royale fleet-and-warehouse company sim.
- A trade game whose travel layer is an auto-battler.
- A large multi-scale, multi-biome world simulation.
- A Crusader Kings-style dynasty or realm-management game.
- A project that requires extensive procedural map generation or complex pathfinding as core pillars.
- An unbounded kitchen-sink scope. Constraints below are the game’s identity, not a temporary demo fence.
- A game in which the player conquers cities or forcibly rewrites the economic geography.
- A demographic or settlement-growth simulation. Populations are fixed and invisible; the soft desalination ceiling exists only for internal consistency.
- A generic commodity list wearing desert labels, or a 60-SKU encyclopedia with crafting graphs. Neither is this brand.

---

## Economic & Agency Model (Locked Direction)

### Settlements (Cities & Villages)
- All goods that will exist in the region are available from the start. There is no growth, expansion, or unlocking of new production.
- Settlements have consistent economic roles (signature goods, scarce goods, base production/regeneration).
- Their output and local conditions fluctuate primarily through an event/pressure layer rather than through independent AI decisions.
- Settlements are the relatively stable board. They do not expand or actively optimize. Populations are treated as fixed and are never presented to the player.

### Merchant Houses
- Houses are the primary *institutional* agents in the setting. Rival houses send their own caravans, take losses, and pursue edges under incomplete information.
- The player is not a house. The player is one marked merchant whose success feeds house standing and who is constrained by house custom.
- Long-term structural advantage is possible only through merchant means (reputation, repeated successful risk-taking, better intelligence coverage, preferred access, soft leverage).

### Rival Strings, House Rank, and One-Way Intrigue (Locked 8 September 2026)

The market is hollow if stalls only move when the player touches them. Rival houses therefore run **living merchant tokens** on the shared stall and the shared road. They do not run the player loop and they do not wage targeted intrigue against the camera.

**Roster.** Each of the five houses fields **four marked merchants**. The player is one of the four under their chosen mark. That is **19 NPC strings** plus the player wagon — twenty tokens on the board, not a hidden fleet.

A string is a pin: house, current node, bound-for, a blunt hold (one or two goods and units, not a 16-cell rack), and a house credit tap. No purse UI. No stars. No Socialize. No Disruption web. Ruined NPC strings dump into the same zone lost-pool as the player; the house respawns a fresh string from a seat after a delay. Houses persist. Strings are mortal. The player persists because they are the camera (extraction / safe-conduct already locked).

**Near-sighted profit matrix.** When a string is idle and the game clock ticks a **day pulse**, it scores buy-here / sell-within-**1–2 hops** using this stall as it is now and structural or last-unloaded prices at candidate dests. Expected take minus road tax (days, weather, heat tithe). Pick the best score above a floor, load, leave, sell on arrival, think again. They chase the commodity rhyme the map already encodes. They miss rumour edges, 3-hop chains, spite dumps, and clever Waits. That gap is the player fantasy.

NPC knowledge is wheels and house memory, not Rumours. They do not get rumours. They do not become smarter because the player planted an eye on them.

**Shared stall, frozen desk.** NPC buy/sell resolves only on world-clock ticks. A Market draft in front of the player is frozen: strings do not print into that stall while the player is mid-deal. Wait is therefore an economic verb — sit a day and other marks can walk in.

**House rank on every tradeable node.** All five houses have a running presence score at every city and village the wagon can dock. Delivering goods the seat actually wants scores the delivering house (player deliveries count the same as NPC deliveries). Dumping unloved goods scores little or cuts. Rank is a scoreboard of who fed the place. It is not ownership, levy, or production change.

- **Cities:** presence shifts, but **no house usurps dominance**. Clamp or soft floor/ceiling so a seat stays a contested house town. First place is never “this city is now only Kharûn.”
- **Villages:** ranks move like the sands. A few deliveries can reorder the board. That is where a single string (including the player) can matter politically in one season.

NPCs do **not** path to maximize rank. They path to profit. Rank emerges. A later light bias (“home-seat gravity”) is allowed; a war AI is not.

**Intrigue is one-way.** Murder is out. Permitted sabotage only, and only as player verbs on **tokens**: plant an eye, ride an eye on a string, delay a hop, spoil or cut a load, feed a string one stale dest price, bump heat on *their* edge. Costs are days, purse, standing, and that house’s stance toward the player.

NPCs never run those verbs at the player. Hostile pressure on the camera is **location weather**: city/village rank of houses that are cold to you weights the **common event deck** (customs, planted lie, house-backed tithe, colder stall, a letter). Same cards, different odds. You may obsess over one named string with an eye; the world answers as houses and places.

**Agents, vision, and tokens.**

- An agent’s `where` is a **settlement id**, the **player wagon**, or **any string id**.
- Planted in a place: they grant a **range of live vision** scaled by skill — incoming and outgoing strings, and the local stall, inside that range. This is knowledge fog and pin visibility, not a second paint job on the atlas. The Map tab remains the no-FoW reference chart; live tokens and freshness live in Rumours, travel watch, and pins.
- Stuck on a string: detailed cargo class, bound-for, and timing on *that* token.
- **No courier delay on line-of-sight.** In range is in view. This is a video game. Stars and days-old still apply when the output is a *rumour* (Socialize, rescue, house talk). Live token sight does not wait on a rider.

Do not add rival skill webs, per-NPC plot queues, or assassination. The matrix plus rank plus the shared deck is the rival game.

### Pricing Foundations
- Base prices are derived from durable map characteristics: distance from primary production source, typical route danger, and standing political/tariff friction.
- Prices fluctuate through two main drivers:
  1. Actual scarcity or glut created by trade volume (caravans arriving or failing to arrive).
  2. Discrete events that temporarily alter production, consumption, or willingness to pay.
- Long-term production and consumption are kept roughly in balance so the regional economy tends to wash out rather than permanently inflate or deflate. The continuous consumption of scrubstone coin for desalination provides a natural monetary and material sink.

### Live Economy — Cellars, Rations, Bands (Locked 14 September 2026)

This is a **static map with live shelves**. Towns do not grow, found workshops, or change what they mint because the player fed them. Stock moves. Demand geography does not.

**Mint.**  
Each city origin writes four letters. Each village origin writes two. Those letters mint only at that origin, daily, up to a cap, then stop. Trading posts mint no origin letters.

Every **city and village** also mints **rations** and **water** into local cellars so the place can plate itself. Mint rate and cap are authored per node (Ghorath water can sit easy; Kharûn water is a trickle; Rukh water is the first generous stall on the Sarn chain). Posts do not mint rations or water; they only hold what a wagon sold there.

Sarn’s Rest mints water only and is not a market. The player-facing cheap well is Rukh.

**Burn.**  
Every market tries to eat some of every good that is on its own shelf, every day, scaled by hidden market size. A town cannot eat a crate that is not there. No silent teleport of stock. The player wagon is the only mover until strings are allowed to buy and sell.

**Price.**  
Live price is how full that cellar is, inside a **floor and ceiling** for that good at that node. Distance from origin sets the band. A later authored quirk may shift one node’s band for one good (Ghûl pays more for a Thalor letter). Quirks are data, not a town sim.

**Player knowledge.**  
Tooltip on a good: cheapest purchase this merchant has seen and **where**, highest sale this merchant has seen and **where**. Personal standing only. Those numbers inherit the cycle the stall was in that day. Rumours may point at a market the player has not verified; they do not write the tooltip.

**Rations.**  
The player eats rations, not origin letters. Rations and water are stall goods everywhere a settlement sells them. Some origin letters will be edible in lore. An edible unit may be smashed into rations at a **bad rate**, emergency only.

**Strings later.**  
Rival tokens read the same cellars and bands. They do not need different physics. They are not required to haul for this lock to be valid.

**Do not add** a quote layer, a hunger meter as chrome, house trickle, or demand-mask machinery on top of mint / burn / band.

### Information, Fog, and Rumours (Locked 30 August 2026; sources 2 September 2026)
- Detailed knowledge of what a city currently holds is not free.
- Default sight: the town the wagon is docked in is known. Adjacent towns may be dim. The rest is fog unless a planted agent or a fresh rumour covers it.
- **Stars are the only quality pip on a rumour.** They *are* the chance the claim is true (1 star ≈ 20%, 5 stars ≈ as close as seeing it yourself). There is no grade / value pip. The wagon is the multiplier: a true market claim pays in whatever you can actually haul; a true stash claim fills against free capacity at the moment you claim it.
- Stars are minted by source quality, proximity, and the listener. Agent skillups raise the ceiling of stars that agent can produce. House rumours and street talk start low on *distant* claims; a claim about the town you are standing in can still come in hot.
- A rumour is a bet you can take because you only have one wagon to send. Truth is resolved when you arrive or when the relevant day comes — not when you hear it.
- Tracking rival movements and cargoes is a high-value use of planted eyes (example: learning a metal-laden rival wagon is en route and choosing to crash the local market before it arrives).
- Where rumours are pulled from, and the Socialize verb, are locked below. Skill-web content stays deferred; stub the hooks.

### Rumours — Where They Come From (Direction Lock — 2 September 2026; terms 14 September 2026)

The player does not buy a rumour menu. They spend a day in a place that talks.

**Desks that listen**

- **House yard** (own compound / factor in the seat you are standing in). House-coloured talk. Standing matters here.
- **Public meeting yard** of that settlement. Market is the street until a well, gate, or hall exists as the same slot. Not a new rail tab. Not a unique tavern scene.

Planted agents still mint rumours from their `where` without the player sitting the desk. Arrival rumours and road rescue remain. Socialize is the verb for the merchant’s own body.

**Verb: Socialize**

- Context action while idle in House or the public yard.
- Spends a day (game clock, one day pulse). Time-paused mash is not a source.
- Returns a *chance* of a rumour, not a rumour. Failure is a wasted afternoon and is legal.
- One attempt per yard per day is enough.

**Subject can be anywhere**

When a rumour is generated, its *subject* (settlement, good, rival wagon, zone) may be any live node on the map. That is how fog lifts on a city you have not docked in.

Generation site is where you heard it. If the subject is this settlement or an adjacent one, **stars tick up**. Local street talk can still be 5-star early (“the stall here is short Speargrain”). A far claim from the same well stays dim unless the source is better.

**Who mints stars**

| Knob | Pushes |
|---|---|
| Source type (street / house / agent / rescue) | Star floor and ceiling |
| Subject next to the generation site | Extra stars |
| Player Socialize / Intelligence rank | Chance a rumour appears, and how close the star roll sits to the source ceiling |
| Agent rank at their seat | That agent’s own star ceiling |

House standing can still change *which room you are in*. It does not print a second quality number on the rumour.

**Payout is the wagon**

Do not pre-roll a treasure size onto the rumour. If the claim is a stash, holdout, or salvage, the amount is computed **when it is claimed**, against free slots on this wagon (capacity minus what you actually rolled in with). An early wagon makes a true find small. A later wagon makes the same kind of find a real load. The player may empty the rack and gamble the hop; if the stars were a lie, they arrive with air.

Market claims work the same way without a special rule: guarantee of sale or a shortage is only worth what this caravan can move.

Geography luck — a true holdout sitting next to the best stall for what is in it — is not advertised as a rating. The subject is on the plate. Whether that is a kind map is the player’s read.

**Scaffold**

Socialize spends the day, rolls chance, writes a rumour with subject / stars / days-old = 0, parks it in the Rumours tab. No grade field. Plate camera on the subject can wait. Agent minting can wait. Stash resolution against free capacity waits on the first salvage/holdout verb.

**Guardrails**

- The Rumours tab stays the rumour list. House desk Socialize does not swallow standing letters or credit.
- Do not add a rumour shop or a third economy of buying tips.
- Do not require unique meeting-yard art.
- Stars remain P(true). Do not reintroduce value-as-a-stat on the rumour.
- Do not roll stash units at mint time and then ignore the wagon.

---

### Lost Goods & Salvage Loop
- The player wagon (and rival wagons, when tracked) move through discrete zones.
- When a caravan is lost, its goods enter a temporary “lost” state associated with that zone (bandits, scavengers, the desert).
- Goods are not permanently deleted from the regional total. A passive re-introduction system eventually returns a portion of lost goods into nearby settlements or black-market channels.
- Sufficient intelligence may let the player attempt to recover lost cargo before it fully recirculates. A holdout / salvage rumour does not carry a unit count. On a successful claim, fill from that zone’s lost-pool (or a local good if the pool is thin) up to **free capacity on the wagon that arrived**.

### Espionage & Agents
- Espionage is not a side mode; it is how the player generates non-obvious information.
- Agents have roles, traits, and textual personality without unique portraits. Visuals stay generic (shared icons by role or house) to protect scope.
- An agent record needs `where` (settlement id, player wagon, or any rival string id), `role`, and skill rank. No cargo hold. No independent market actions.
- Planted eyes lift knowledge fog and show strings in range by skill. An eye on a string reads that token in detail. Live sight has no courier delay. Rival houses do not get a matching verb set aimed at the player; their “agents” are flavour and deck weight, not a second intrigue sim.
- Catalog Agents / Reports list these attachments and rumours. They are not a fleet roster.

---

## Skills & Progression (Direction Locked, Implementation Deferred)

Both the player merchant and agents will have skill webs. Full trees are later; architectural space must be left now.

**Primary axis:** Economy ↔ Intrigue, with meaningful variety inside each side.

**Player web** — the merchant’s own capacity. Skills change *how this wagon and this purse* work, not how a house office dispatches captains. Example clusters:
- Economy – Logistics (survival, capacity, recovery)
- Economy – Markets (scarcity reading, timing, local influence)
- Economy – Capital (credit, terms, float)
- Intrigue – Intelligence (rumour filtering, rival tracking)
- Intrigue – Influence (reputation, reception, soft pressure)
- Intrigue – Disruption (sabotage, misinformation)
- Small hybrid set (house standing, negotiation, personal resilience)

**Agent web** — narrower, tactical, role-focused. Specialized tools, not second player characters. Example clusters:
- Scout / Tracker
- Listener / Analyst (stars on rumours, freshness)
- Fixer / Negotiator
- Shadow / Disruptor
- Guardian / Escort

An agent should not be able to do everything the player can, and must never take the purse. Both Economy and Intrigue paths remain viable routes to converting an edge into profit.

**Implementation stance:** Stub data fields (skill ranks, rumour stars, agent `where`) and query hooks in market and intelligence code when those systems are touched. Defer node lists, costs, balancing, and visual webs until the core trading + travel + basic rumour loop is proven fun.

---

## Key Systems (High-Level)

1. **Trade Goods & Markets**  
   Cities mint four letters, villages two, plus rations and water as local rows. Signature letters carry an old-world commodity rhyme and a local wound when named; ids may stay generic until then. Many letters may be foods. Base bands grounded in geography; live movement is cellar fullness. Scrubstone coin is currency and desalination feedstock. Only the player wagon trades until strings are unlocked.

2. **Information & Espionage**  
   Agents and 1–5 star rumours generate the specialized knowledge the fantasy depends on. Information is partial, timed, and often contested.

3. **Travel & Risk**  
   Choose routes or destinations for the one wagon. Pressures (weather, bandit heat) sit on the plate before departure. Resolve the hop as a watch phase: days elapse, at most one interrupt event fires, lost cargo feeds the salvage loop. See *Travel, Pressures, and Road Events*.

4. **Rival Houses & Intrigue**  
   Competing houses with their own goals and incomplete information. The player can be targeted and can act against them through economic, informational, and limited direct means. House–city leverage is political texture, not a realm to annex.

5. **Constraints & Friction**  
   Laws, tariffs, local rules, house marks, glove-and-pouch trust, and the scrubstone monopoly.

6. **Skills (later)**  
   Player and agent webs on an Economy ↔ Intrigue axis. Architectural space reserved; content deferred.

---

## UI Shell — Play Frame (Locked 5 September 2026)

One play scene after house select. Title and house select stay outside it. There is no separate full-screen city hub and no separate full-screen map destination. The game lives in one **well**. Top bar and bottom bar are fixed. What occupies the well is whatever the player is actively doing.

```
TOP        House · place or bound-for · Day · Scrubstone · cells/mass · weather pip · Cargo | Map | Rumours · gear
WELL       two content panes  or  atlas plate  or  travel watch
BOTTOM     large place name  ·  location banner (vibe)  ·  House | Market | Outyard
```

This supersedes the 31 August strip (left rail + right context column). That column is gone. Copy and verbs live inside the well panes.

**Top bar:** house mark, current stop or “bound for X”, day, purse, cargo fill, weather pip only while a pressure touches this hop, then the closeable tabs, then gear. Gear lives here. Esc still opens pause.

**Top tabs — Cargo | Map | Rumours (locked 5 September 2026).** Single-select and close. They occupy the well the same way a yard does. Closing the active tab returns to the current location; the player never left. They may change the bottom yard while a tab is open; the new yard is current but not interactive until the tab closes. No city list. No fleet list. Market and House are not top tabs.

**Player-facing chrome (locked 2–5 September 2026).**
- Third tab is **Rumours**. One entry is a **rumour**. Stars are how true it sounds. Do not use *Word*, *assay*, or *slip* on chrome or in player copy.
- Hold tab is **Cargo**, not Wagon. The stake is one marked string; engine may still say wagon / Word until a rename pass.
- Embark / roads location is **Outyard**. Do not put *Embark* on chrome.

**Bottom bar — the place.** Large settlement (or bound-for) name at left. Banner band is the only “place painting”: market cloth, house mark, outyard road, travel weather. Well stays lists and icons. Location actions are the big buttons: **House | Market | Outyard**. Disabled on the road.

**Yards (locked):** a settlement is rooms, not one screen.
- **Market** (if the stop has one): start yard after house select and after a hop. Well split **50/50** — player hold left (trade clicks), stall right.
- **House:** desk stub left, standing / letters copy right.
- **Outyard:** roads left; selected hop (days, weather, heat, **Take the road**) right. This desk is the authority for leaving. The atlas may hint; it does not confirm the hop.
- Place name with no yard selected: settlement copy only.

**Well splits (locked 5 September 2026).** The well is full width. Two panes, ratios change with the job. Banner keeps the vibe; well does not.

| State | Left | Right | Ratio |
|---|---|---|---|
| Market | Hold (trade) | Stall | 50 / 50 |
| Cargo tab | Hold (inspect; trade only if Market is still the yard) | Selected-item copy | 60 / 40 |
| Outyard | Road list | Hop detail + confirm | 50 / 50 |
| House | Desk stub | Standing / letters | 50 / 50 |
| Rumours | Rumour list | Selected rumour | 50 / 50 |
| Map tab | Whole plate, zoomed out, letterboxed in the well | — | one surface |
| On a hop, no tab | Zoomed travel watch | — | one surface |

Market hold and Cargo-tab hold are two loadouts of the same rack, not two inventories.

**One map, two modes (locked 21 September 2026; replaces “two maps, one texture”).**
Same plate, same renderer, same tokens. Not two map systems. Scale and chrome change; the world does not.

- **Map tab (paused).** The plate at the last process stamp: arrival, or the watch just Waited to. Nothing moves. No FoW. Rumour pins and mark positions are the stamp. In a yard this is the only map. On the road, opening Map (or Cargo / Rumours) freezes the game clock *and* switches to this paused plate. Letterboxed in the well until a fuller asset exists.
- **Travel watch (live).** Hop, no top tab. Same plate, larger scale (full well, less chrome). Line of sight of this hop. Tokens and the weather mass move inside the current watch. Close the tab, resume from the stamp.

Inventory / planning map is always the paused mode. Live movement exists only on the travel watch. Do not build a second map stack, a second fog system, or a second pin list.

**Travel as a location (locked 5 September 2026).** The road owns the well like a yard. Opening Cargo, Map, or Rumours **pauses the hop clock** (the watch tween). Closing the tab resumes on current progress. Time does not run in town except explicit Wait / rest. Time runs on the watch, on Skip, or on Wait. House / Market / Outyard stay dead until arrival. Arrival lands in **Market** with no top tab open.

**Always-on vs place-bound**
- Always on: Cargo, Map, Rumours, status, gear, Skip while the watch is up.
- Place-bound (idle in a settlement): House, Market, Outyard.

**Arrival (reserved):** a one-shot rumour after time away can still land in Rumours. Playtest may stay quiet. Do not open a top tab for the player on arrival.

**Map events / route read:** weather and bandit heat are learned at the **Outyard**, as words on the selected road, and as a status pip only while that pressure is touching this hop. The atlas may show a hint. Never as a market row. Wait is a yard verb that advances the game clock (1 watch / half day / full day). No fourth full-screen for the briefing.

### Cargo and market staging (locked direction, visual pass later)

Capacity is **N slots** (16 for the first wagon), not hidden weight. Each good has a stack limit per cell. Water stack is 1. Other stack sizes are still open; a temporary “everything else stacks to 4” is acceptable until icons exist.

Two motions, never mixed:

- Rearrange inside the wagon is free and instant.
- Stall ↔ wagon is a **draft**. Left click stages +1 unit, right click peels 1 off the draft. Buy and Sell buttons commit. Clear dumps the draft. The draft dies when the wagon leaves the desk.

Stall and hold will both be icon racks. That UI is unbuilt. Scaffold the rack cells and keep a temporary numeric stall list in the Market right pane so buy, travel, and sell work. Goods icons are a later art pass.

**Game clock (locked 21 September 2026).** One clock. No “Clock A / Clock B.” See **Game Clock** below. Time does not run in a yard except explicit Wait. Time does not run while a top tab is open mid-hop. Time runs on the travel watch with no tab, on Skip, or on Wait. The tween is interpolation inside a watch; pausing a tab pauses the hop.

Layout chrome and hex palette remain open. Existing in-engine cues: title-screen sand, parchment map, hub brown `Color(0.12, 0.08, 0.05)`, gold labels around `Color(0.92, 0.78, 0.45)`.

---

## Game Clock (Locked 21 September 2026)

One game clock. Do not say Clock A, Clock B, or “model B.”

**Wire.** A **watch** is 3 hours. Eight watches make a calendar day. The sim stores a stamp (`day + watch index + hours into watch`, or hours-from-epoch). Caravans, the weather center, and event rolls step on watches. Visuals interpolate inside the watch (wagon on the path; weather mass as Perlin or similar around a moving center). Edges still read as discrete words (Clear / Heat / Wind / Sandstorm).

Watch indices, player copy:

| # | Name |
|---|---|
| 1 | Dawn |
| 2 | Morning |
| 3 | Heat |
| 4 | Afternoon |
| 5 | Dusk |
| 6 | First night |
| 7 | Deep night |
| 8 | Predawn |

Market open = Dawn through Dusk. Closed = the three night watches. Day pulse fires at Dawn (watch 1).

**Day pulse.** Every 8 watches, at dawn: produce → string stall-act → consume. Spoil and rumour age ride the day pulse. Do not fire the cellar eight times a day.

**Road vs yard.** Time runs on the travel watch with no top tab, on Skip, and on Wait. Yards freeze the stamp. Opening Cargo / Map / Rumours mid-hop freezes the stamp.

**Arrival.** Dock writes the exact stamp and stops. Other tokens stay where that stamp left them. The remainder of the current watch is **not** flushed on arrival.

**Wait (yard).** Player picks **1 watch**, **half day** (4 watches), or **full day** (8 watches). Options land on watch boundaries.

- **1 watch** = advance only to the end of the current watch. Arrive one hour into a watch, choose 1 watch → two hours pass. That remainder is when other caravans and the weather center finish *this* watch.
- **Half day / full day** = that many watches after the current boundary (remainder first, then 4 or 8).

Wait is the only way a parked player lets the world catch up.

**Market hours.** Stalls are open **watches 1–5** of each day (five of eight — more than half the day, 15 hours). Watches 6–8 are closed. Outside that window a caravan **parks** until watch 1 — player included. Arrival after close does not open Market; the wagon sits, then the open-watch flush runs as forced Wait. Same window on every dockable node unless a later quirk says otherwise.

**ETA.** Outyard and the road line show estimated arrival as a stamp in watch names. Weather and events add hours; the label rewrites while the hop runs.

**Pace and fatigue (direction, unbuilt).** Crew fatigue is why the player sometimes stays. Pace on a hop is a choice (crawl / march / push) that trades hours against fatigue. Push spends; crawl and parked watches recover. Night and Heat watches spend more on the wrong edge. Fatigue is not player-eat and is not this build’s task.

**Events.** Same watch beat. Weights scaled so expected cards per hop stay ~one, not eight. Night / Heat are watch indices plus the existing edge flags, not a second deck.

---

## Travel, Pressures, and Road Events (Direction Lock — 2 September 2026)

Travel is the tax on the knowledge-edge bet. The player already committed the only wagon. The road exists to make that commitment take time and take hits — not to become a second game.

**What the player feels:** look at the plate, read the weather and the heat on the road, choose to leave or Wait, then sit the watch. The play beat on the hop is an event that names what happened. Most hops are quiet. Some cost days. Some take a cut. A few give something back.

### Scaffold now, visibility next

- **Now:** each road out carries two discrete labels. Under the hood those are ints that feed the hop table. Resolve, show the event, apply the delta. Uneventful is the common result.
- **Next:** the same labels get glyphs on the plate, then visible odds once mitigation hooks exist. RNG still picks which beat fires inside a known pressure.

No new scene. The briefing is the **Outyard**. The atlas may hint; it does not authorize the hop. A long journey is a chain of hops. New weather and heat are learned at the next Outyard — there is no global forecast.

### Route read (first implementation)

Idle in a settlement, **Outyard** lists roads out in the well. Each road is one destination and two words, for example:

`Veythar · Heat · Watched`

Selecting that road fills the right pane (days, terms, confirm). Leave only on **Take the road**. Status-bar weather pip only while the string is on a hop that has a pressure.

**Player-facing terms — closed sets.** Never show the int.

| Pressure | Terms (best → worst) | Hood | Lives on |
|---|---|---|---|
| Weather | Clear, Heat, Wind, Sandstorm | `0–3` | The hop / the country that hop crosses |
| Bandit heat | Quiet, Watched, Active | `0–2` | The road (artery), not the city |

Sandstorm is the Wait test. Active is the long-quiet-vs-short-hot test. Do not add Fair, Haze, Held, or percents until those labels are asked for.

**What the ints do (defaults, tunable):**

- Weather `0` Clear: base hop days. `1` Heat / `2` Wind: +1 day. `3` Sandstorm: +2 days and a heavier mishap weight.
- Heat `0` Quiet: tithe rare. `1` Watched: tithe uncommon. `2` Active: tithe likely. Tithe size stays the flat percent of stake; heat changes *whether* it fires, not the rule.

**Where the numbers live.** Per-edge fields on the existing road list. Four or five cities do not need a climate sim or a heat map layer. Weather may be shared by edges that cross the same country so two roads out are not rolling different storms for the same sand.

**How they move.** Wait (and each road day) may step weather by one term. Heat steps slower — on Wait in larger chunks, or after a tithe / a quiet crossing. Do not retune every watch into noise. Scaffold may even freeze both until the labels read; stepping is the second beat.

Rival interference stays a later pressure.

### Pressures (visible risks)

Two first-class pressures. Weather is country/hop-scoped. Bandit heat is artery-scoped. The route read above is how the player sees them before they leave.

### What a hit is allowed to take

The merchant is under mark. The wagon is the stake. Permanent death is already off the table (house extraction, safe-conduct, institutional recovery). Hits spend the currencies that make the *next* market decision worse.

| Currency | Who uses it | Typical magnitude |
|---|---|---|
| **Days** | Weather, camp, rescue, ruin recovery | +1–3 on a hop |
| **Cargo** | Bandit tithe, rare bury/scatter | A **flat percent** of units on the rack, into the zone lost-pool |
| **Purse** | Tithe, bribe, “road custom” | The same **flat percent** of current coin |
| **Wagon state** | Rare mishap or heavy hit | A slot locked or the wagon laid up N days — not deletion of the run |
| **Standing** | Cowardice, dumped marked load, unpaid custom | Soft, later; do not wire it for the first table |

**Flat percent, whole loop.** Tithe size does not shrink into “one crate” as the wagon grows, and it does not balloon into a wipe. Early and late, a hit is the same share of what is actually on this wagon and in this pouch. Scaffold may pick one of cargo-percent or coin-percent per tithe so the result line stays readable. Exact rate is balance; the rule is percent-of-stake, not a fixed unit count.

Time is the weather weapon. Extra days are how grain sours and rumours go stale. Do not invent a separate “spoil event” when delay already does that job.

**Not a hit:** player death, a combat screen, a full wipe presented as the normal bandit result, deletion of goods from the regional total (lost units enter the zone salvage pool).

Water and rations are traded goods and the player’s consumables. Daily eat from the rack is a reserved hook — wire the rows and the emergency convert first. Do not add a second hidden meter that bypasses the stall.

### Why bandits steal instead of erase the mark

House custom already says marked caravans carry limited safe-conduct, and a house answers if its mark is broken in blood. Road people know the difference.

- Theft of coin and a few units is the expected tax. Houses grumble; they do not raise a coordinated hunt for a tithe.
- Killing a marked agent, or taking the whole house wagon as if it were unowned, is the line. That is what brings retaliation.
- Independents without a glove-and-pouch pay worse terms. The player is marked, so the common event is a cut, not a massacre.

Diegetic cover for the failsafe: if a wagon is actually ruined, the agent is pulled to the nearest house compound and the cargo dumps into that zone’s lost pool. The run continues. The load may be recoverable through the salvage loop if the player spends a salvage rumour on it.

### Mitigation — skills, agents, guards (never zero)

The point of Logistics, a Guardian / escort on this wagon, and a hired road guard is to **knock the cut down or make the tithe miss more often**. It is not to turn the desert off.

- Player ranks in Economy – Logistics (survival, recovery) and the small resilience hybrid.
- An agent riding the wagon in Guardian / Escort (or equivalent) applies their rank to this hop only. Planted city eyes do not escort.
- A hired guard is a paid hop attachment, not a second caravan and not a combat mode. Coin out at departure; the hire dies when the wagon docks.

**Floor.** After every modifier there is still a visible chance the pressure fires, and a visible floor on the percent if it does. No combination of skill, agent, and hire reads as 0%. When plate visibility is in, the road out shows those chances (heat, weather delay, tithe odds / expected cut). Hidden scaffold may omit the numbers; the rule still applies under the table.

Do not build the skill web or a guard market to prove travel. Stub a modifier hook on the hop (player rank, riding escort rank, hire flag) so the table can listen later.

### Road events (the actual play beat)

On the road, context stays Skip. An event interrupts Skip with one card:

- Title in setting voice
- One short paragraph
- A result line the player can trust (what changed)
- Continue

At most **one interrupt per hop**. Quiet roads can resolve with no event, or with a one-line “the road was kind” so silence still feels like the world.

Branching choices (pay the tithe / risk a heavier hand; press the storm / make camp +1 day) are allowed later. Scaffold may auto-resolve so the table can be felt before verbs are built.

### First event table (scaffold weights, not final copy)

Uneventful should dominate. The road is dangerous in the *possibility*, not in a popup every watch.

| Kind | Role | Example result |
|---|---|---|
| Uneventful | Majority | Nothing, or a flavour line |
| Weather delay | Time tax | +1–3 days; spoil and rumour clocks tick |
| Tithe | Bandit heat | Flat % of purse **or** flat % of rack units, into the zone lost-pool |
| Mishap | Rare | +days and a locked slot / laid-up wagon |
| Ruin | Very rare | Cargo to lost-pool, agent extracted, hop aborted to nearest house seat |
| Tailwind | Positive time | −1 day |
| Abandoned goods | Positive cargo | Units from that zone’s lost-pool (or a cheap local good if the pool is empty) |
| Rescue | Positive rumour | Spend a day (or not) pulling someone off the road; they pay with a rumour |

Abandoned goods and a rescue are first-class goods results, not flavour on Uneventful. Rescue is how a person becomes a rumour without a planted agent. Stars stay honest to source — a stranger on the sand is not a 5-star claim.

Positive entries exist so mitigation is not the only skill. A good-weather window, a wreck in the zone, or a voice that owes you a story are as much a reason to leave today as a storm is a reason to Wait.

Copy names the goods that are actually on the rack when it can. “They took a crate” is weaker than taking Speargrain the player was racing.

### Resolution order on a hop

1. Read plate pressures (or, in scaffold, roll as if they were hidden).
2. Apply weather day-modifier to the hop length.
3. Run watches to the arrival stamp. Day pulse (produce / string stall-act / consume, spoil, rumour age) fires when the stamp crosses a dawn boundary.
4. Roll at most one interrupt from the weighted table, biased by those pressures.
5. Show the event. Apply cargo/coin/wagon deltas. Lost units go to the zone pool.
6. Arrive, or extract to the recovery seat if ruined.

### Guardrails

- No overland RPG movement. No auto-battler.
- Combat, if it ever appears, is a rare tax — not a reason to open the map.
- Do not add unique road art, extra SKUs, or a second wagon to “absorb” risk.
- Do not let events write into the stall as if weather were a market row.
- Spoil is a property of goods + elapsed days. Wire tags when the catalog is touched; do not block travel on a full perishability sim.

---

## Production Philosophy

- **Core loop first.** The decision-and-risk fantasy has to feel good or nothing else will. Build in that order. Unbuilt systems are unbuilt; they are not “cut from the demo.”
- **True nouns before pretty icons.** Placeholder template goods drain the will to play. A short canonical list with setting names is part of the loop, not a content dessert. Unique art can wait; Iron/Spices/Cloth as the stall language cannot.
- **Moody Blocks approach.** Prioritize a small set of high-feeling, reusable assets (goods icons *after* the names are right, caravan states, UI frames, city sigils, basic feedback) so the game carries atmosphere while it is still incomplete.
- **Asset confidence.** Lean into generated icons and supporting visuals where quality and consistency are now reliable.
- **Map as support, not master.** A single visual map with nodes is useful; it stays in service of the trading/intrigue loop rather than becoming the primary time sink.
- **Identity is the constraint.** One wagon, merchant means only, no settlement-growth sim, no fleet layer. Those are what the game is. They are not a slice fence around a larger unwritten title.
- **Settlements low-agency, player-and-rivals high-agency.** Complexity sits on the wagon, the rumours, and rival pressure — not on a fleet roster.
- **Leave space, don’t build early.** Skill webs, full agent simulation, save/options, other starting houses, and the rest of State’s gated list stay gated until Derek asks. Gating is build order, not a second product.

---

## This is the game

*Caravans of the Cutting Sands* is the project. Do not describe play, scope, or success as a vertical slice, demo, prototype-for-proof, or down-payment on a different title.

What is unbuilt is simply unbuilt. House rank, travel interrupts, Socialize, player eat, skills, agents, save/options, other starting houses, room furnishings, Steam plaques — these wait on a build order. They are part of the same game when they land.

The merchant-limited economic model (no conquest of the market, information as primary edge, one personal stake on the road) is a deliberate feature of this game, not a temporary simplification. Fleets, settlement growth, and demographic simulation are not this game.

---

## Success Criteria

- The core loop (knowledge → commitment → risk the journey → convert or lose the edge) creates real tension and satisfaction on a single wagon.
- The stall and the rumours speak setting-native goods. A rumour about a load should sound like Uncanny Mercantile, not a template market.
- Fog, rumours, and planted agents make information feel scarce and worth paying for.
- Enough polish on feedback and atmosphere that the fantasy of being under the mark registers.
- The game can reach Steam without renaming itself into a different genre or a second, larger title.
- Rival houses and the intelligence layer feel active enough that the market is contested rather than a solitary puzzle.

---

## Open Items for Project Workspace

- Exact city count and layout (recommended starting point: 4–5 major cities + limited outposts; scope list above still allows 8–9 majors plus support).
- Catalog shape locked 14 Sep 2026: 4 letters per city, 2 per village, generic ids until named; rations + water as separate local rows. Sarn water via Rukh → Westmark. Player tooltip: cheapest buy + where, highest sale + where. Emergency edible → rations. Daily player eat reserved. First named samples (1 Sep) still valid as display names where they already exist.
- First rumour verb and how stars are shown in Reports — **verb locked 2 Sep 2026:** Socialize in House yard or public meeting yard, spends a day, chance of a rumour. Stars only (no grade). Subject may be any node; local subject boosts stars. Stash/holdout amounts resolve at claim against free wagon capacity. Remaining: pip UI, exact chances, first salvage-claim verb.
- Agent data stubs (`where`, role, rank) and catalog listing.
- How rival houses prioritize goals and how visible their actions are through fog — **locked 8 Sep 2026:** 4 marks per house (player is one); 19 NPC strings on a 1–2 hop profit matrix; rank on every dockable node (cities clamped, villages volatile); player-only token sabotage; location-weighted common deck the other way; agent `where` = place / player wagon / string; live LoS instant. **21 Sep:** strings travel on the game clock (GB `TASK_game_clock.md`). Remaining: rank formula, matrix weights, personality.
- Game clock — **locked 21 Sep 2026:** one clock, watch = 3 hours, 8 watches/day (Dawn … Predawn), day pulse at Dawn, Wait 1 watch / half day / full day with remainder, market watches 1–5, arrival freezes the stamp, ETA in watch names. Pace / fatigue / events / moving weather mass unbuilt.
- Map — **locked 21 Sep 2026:** one plate, two modes. Map tab = paused stamp, no FoW. Travel watch = live LOS, same plate, larger scale. Replaces 5 Sep “two maps, one texture.”
- Degree of map/node/zone complexity needed for travel, loss tracking, and salvage.
- Visual identity pass (logo, UI color/type spec; play-frame shell locked 5 Sep 2026 — top tabs + well panes + bottom yards; hex palette and chrome still open).
- Audio direction (Reason is already planned for sound design).
- Event table and pressure types — **framework locked 2 Sep 2026**; **route read locked 2 Sep 2026** (no new screen; road line in context shows discrete weather + heat; hood ints 0–3 / 0–2; per-edge fields). Remaining: exact rates, table weights, spoil tags, weather step-on-Wait, plate glyphs.
- Starter skill nodes and experience sources (content deferred; data hooks to be reserved).
- Engine/repo string rename from Trader → Caravans, Word → Rumours, and purge of *assay* / *slip* from player copy, when convenient.
