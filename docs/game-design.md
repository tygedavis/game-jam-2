# Game Design: Vision

Working title: TBD. Jam theme: **"Deeper and Deeper"**.

This is a self-imposed jam. Two people are learning game development: one is primarily the developer, the other primarily story and art (either can help in the other area). Favor simple, finishable, well-structured work over ambitious scope. Use placeholder shapes until the art arrives; code must not depend on final art.

## Pitch

A 2D side-view roguelite with upgrade items found buried in the ground. You play a dog piloting a drill vehicle down through the earth to find buried gems while enemies attack you. The deeper you go, the harder the ground gets and the better the loot, so you have to find upgrades to keep going.

## Core loop

1. **Dig** down and sideways through the ground, carving tunnels, by steering into dirt (digging is automatic on contact). Depth is the main axis of progress and risk.
2. **Fight** enemies by shooting them.
3. **Find upgrade items** buried in the ground. Breaking the tile collects the item and adds one stack of its buff for the rest of the run.
4. **Collect gems** (and money) buried in the ground.
5. **Choose when to return** to the surface. The player decides when to go back; going back is a risk and reward call.
6. **Visit the owner (shop)** and spend gems and money to unlock upgrade items and strengthen their buffs. Then dig again, able to go deeper.

## Systems

### Movement and digging
- The playable character is a **dog driving a drill vehicle**. The drill is what digs; the dog is the pilot. The vehicle is the player's on-screen avatar for the whole run.
- Side-view. The drill digs down and sideways (not freely in 8 directions).
- Terrain is destructible, and carved tunnels persist for the run.
- **There is no dig button.** Digging happens automatically whenever dirt (or an exposed gem) touches the drill's leading edge in the direction it faces, whether or not the player is moving. Digging is separate from attacking (see Combat). Gems are buried in dirt tiles and have their own **durability**: dig away the dirt to expose a gem, then keep digging to break it out and collect it. An exposed gem blocks the drill like dirt until collected. Enemies only dig dirt, so they never destroy or collect gems.

### Depth layers and hard ground
- The ground is divided into depth layers. Each deeper layer is harder to dig.
- Hardness is a **soft block**: a layer can be effectively impassable until the drill's dig power is upgraded enough. This is what pushes the player back to the owner to upgrade.
- Layers also drive enemy types, gem rarity, and visuals (to be defined).
- **Layer barriers:** a thin wall (about 12 px, tunable) sits on every boundary between layers. It has high HP and the player must break it, by digging or shooting, to reach the next layer. Enemies cannot damage it. Breaking it pays a large amount of money immediately and is the run's big reward moment, so it gets heavy feedback (hit-stop, shake, particles, coin shower, popup). Once broken it never returns during that run.
- **No spawn camping:** enemies never spawn on the far side of an unbroken barrier; they only spawn in the player's current layer and above.

### Combat
- Attacking is player-issued and mouse-aimed (the cursor is a target reticle during a run). There are two weapon slots:
  - **Primary** (hold left click): reliable. You start with the basic gun, which fires projectiles. Upgrade items buff it. Basic primaries are meant to be bought on the surface (#12).
  - **Secondary** (hold right click): wacky, powerful and a little unreliable, found in the map (#12). Each weapon has its own limit: the flamethrower runs on a fuel timer that drains while firing and recharges when idle; a bomb would use a cooldown. A HUD meter shows the secondary's limit.
  - Weapons are data-driven: a `WeaponDef` (`data/weapons/*.tres`) holds a behavior (the mechanic) and a limiter (the firing rule). A variant is a new `.tres`; a new mechanic or limiter is one script in `scripts/weapons/`. `WeaponCatalog` finds weapons by scanning `data/weapons/`, so dropping a `.tres` there is enough.
  - Secondaries that clear dirt (flamethrower, later a bomb) use their own fixed dirt damage, not the primary's dig power or upgrades. They never collect gems or upgrade items; the player still has to mine those. They cannot damage layer barriers.
- **Dig and attack are separate.** Digging is automatic on dirt contact (dirt takes damage against its layer hardness and breaks). The attack is a ranged projectile aimed at the mouse cursor (hold left click); it hits the first enemy in its path and stops at solid dirt. For now dig power is derived from the primary's attack stats (damage / interval), so attack upgrades also speed up digging.
- Because of this, dig power and attack power are still tied together. A layer's hardness acts as a soft block when the drill's attack damage can't break it effectively. Keep this in mind when designing upgrades: some may affect only dirt or only enemies, but the base stats are shared.
- **Burrowers:** most enemies dig through the dirt toward the player. They tunnel through terrain themselves, so they can come from any direction, including through undisturbed ground.
- **Tunnel dwellers:** some enemies live in pre-dug tunnels that exist before the player arrives and do something unique with them (behavior TBD, e.g. patrolling, ambushing, using the tunnel network as cover or shortcuts). These give each layer places that feel inhabited.

### Progression (two tiers)
- **Baseline:** the drill's own stats (e.g. attack damage) are fixed and intentionally weak. This pushes the player to explore for upgrade items instead of buying their way down.
- **In-run (upgrade items):** found buried in the dirt. Each item is a percentage buff to one stat (e.g. +2% attack damage). Finding more of the same item adds a stack. Buffs add up (5 stacks at +2% is +10%, not compounded); for attack interval the buff means faster attacks. Each item has its own stack cap (5 for now). Stacks reset every run. Only unlocked items can appear.
- **Permanent (meta):** nothing starts unlocked, so the first runs are hard and find no items; the money they earn pays for the first unlock. The owner sells two things per item: Unlock (so it can spawn) and Upgrade (each shop level raises that item's per-stack buff, e.g. 2% to 4%, up to level 5 for now). Each item sets its own unlock and upgrade prices. The unlocked set and each item's shop level are saved.

### Run end and death
- A run ends when the player chooses to return to the surface, or when they die.
- **Voluntary return:** dig back up to the ground line (after having been underground) and a "Return to the surface?" prompt opens; Space confirms, Esc or the Keep digging button declines and the run continues. It reopens only after the drill goes underground again. There is no fee or delay: the cost is the trip back up while burrowers chase you. Returning keeps all loot.
- **Death:** the player loses 25% of the run's total value (gems and barrier payouts, rounded down; `death_loss_fraction` on `Main`) and banks the rest. Never a full wipe.
- Both endings show a run summary; the bottom of it shows what was earned versus what is kept (`Earned`, `Lost` on death only, `You keep`, `Banked`).

### The surface (hub)
- The area above ground works like a main menu you can walk around in. It is the game's home base, not a run.
- It contains the **drill vehicle**: the dog gets into it to start a run. Starting the descent is when the run actually begins. On the surface the dog is on foot; in a run the dog is in the drill.
- It contains the owner (below) and room for other things we add later (cosmetics, story beats, etc.).
- Returning from a run puts the player back here.

### The owner (shop)
- A character on the surface who accepts gems and money. The owner unlocks upgrade items (so they can appear in the ground) and strengthens their per-stack buffs permanently. Nothing is unlocked at the start. Good spot for story and personality (the partner owns the narrative direction).

### Win condition
- None for now. Treat it as an open-ended dig. Do not build a final depth or boss yet.

## Developer mode
A testing aid, not part of the game. In debug builds only, press the backtick key (`` ` ``) to open a panel (Esc or backtick closes it; it works on the surface and in a run, and never needs function keys). It offers: **Invincible**, **Noclip** (the drill passes through dirt and barriers without digging; enemies stay solid), **Infinite money** (a throwaway session: shop purchases work but nothing is written to the save, and turning it off restores the real wallet, unlocks and levels), **Pause enemy spawning**, **Skip layer** down (breaks that layer's barrier with no payout) or up, **Kill all enemies**, and **Give item** (one stack of any upgrade item).
- All dev code lives in `scripts/dev/`; the small `DevMode` autoload holds the toggles. Production builds (`tools/build.sh --production`) leave `scripts/dev/` out entirely, and dev mode refuses to run in release exports or when the `production` feature tag is set.
- Nothing outside `scripts/dev/` may reference that folder (`tests/dev_isolation_test.gd` checks this).

## Art and tone
- Target: pixel art, being made by the art/story partner. **Use placeholder shapes (colored rects, circles) until assets arrive.** Keep sprites swappable by isolating visuals from logic.
- Tone is still to be decided with the art partner.

## Open questions
- Enemy roster: which burrowers and tunnel dwellers exist, and what the tunnel dwellers do uniquely with pre-dug tunnels.
- Whether pre-dug tunnels are part of every layer's generated terrain and how they are generated.
- Other permanent upgrade types besides item unlocks and upgrades (e.g. HP).
- The final unlock and upgrade prices, buff steps and number of shop levels.
- Whether owner upgrades are framed as drill upgrades, dog upgrades, or both (affects naming and art).
- Other things the surface hub should contain.
- Jam deadline and scope cutoff (not yet given).
- Tuning the death loss (currently 25%) and whether other ways back up (rescue beacon, layer checkpoints) are added.
- An upgrade related to moving up layers (now unblocked: the return-to-surface mechanic exists).
- Barrier tuning: HP multiple, payout per layer, and whether broken barriers should ever persist across runs.
- The upgrade item list (stats, buff sizes, caps, prices), weapon list, gem list, layer count, and names for each layer.
- Gamepad support (aiming would need a stick). Digging has no trigger; attacks are aimed with the mouse.
- Weapon finding and unlocks (#12): chests with 2-3 secondaries to choose from, primary chests (permanent unlock or stronger for one run), modifier chests, surface purchase of primaries, per-weapon upgrades and special abilities, and the rest of the secondary list (bomb, chain lightning, ...).
- Story and owner characterization.

## Guidance for agents
- Check this doc before designing features, and keep it updated when decisions are made. Move resolved items out of "Open questions."
- Prefer data-driven content (layers, enemies, upgrades, gems as Godot Resources) so the art partner and developer can add content without engine surgery.
- Don't add scope that isn't listed here (win condition, bosses, etc.) without asking.
