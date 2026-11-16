# Game Design: Vision

Working title: TBD. Jam theme: **"Deeper and Deeper"**.

This is a self-imposed jam. Two people are learning game development: one is primarily the developer, the other primarily story and art (either can help in the other area). Favor simple, finishable, well-structured work over ambitious scope. Use placeholder shapes until the art arrives; code must not depend on final art.

## Pitch

A 2D side-view roguelite with automatic attacks and level-up upgrade choices. You play a dog piloting a drill vehicle down through the earth to find buried trinkets while enemies attack you. The deeper you go, the harder the ground gets and the better the loot, so you have to upgrade to keep going.

## Core loop

1. **Dig** down and sideways through the ground, carving tunnels, by steering into dirt (the auto-attack does the digging). Depth is the main axis of progress and risk.
2. **Fight** enemies automatically (the same auto-attack). Enemies drop XP.
3. **Level up in-run** from XP and pick one of several offered upgrades (a choice, not random assignment).
4. **Collect trinkets** (and money) buried in the ground.
5. **Choose when to return** to the surface. The player decides when to go back; going back is a risk and reward call.
6. **Visit the owner (shop)** and spend trinkets and money on permanent upgrades. Then dig again, able to go deeper.

## Systems

### Movement and digging
- The playable character is a **dog driving a drill vehicle**. The drill is what digs; the dog is the pilot. The vehicle is the player's on-screen avatar for the whole run.
- Side-view. The drill digs down and sideways (not freely in 8 directions).
- Terrain is destructible, and carved tunnels persist for the run.
- **There is no dig button.** Digging and attacking are the same mechanism (see Combat): the drill's automatic attack digs when it hits dirt and damages when it hits an enemy. The player only steers; the attack does the rest.

### Depth layers and hard ground
- The ground is divided into depth layers. Each deeper layer is harder to dig.
- Hardness is a **soft block**: a layer can be effectively impassable until the drill's dig power is upgraded enough. This is what pushes the player back to the owner to upgrade.
- Layers also drive enemy types, trinket rarity, and visuals (to be defined).

### Combat
- Attacks fire automatically; upgrades add or modify them.
- **Attack = dig.** The same attack hits whatever is in its path: dirt takes damage against its layer hardness (and breaks, digging the tunnel), and enemies take damage. One system, one set of upgrade stats (damage, speed, reach, area), so a single upgrade improves both digging and fighting.
- Because of this, dig power and attack power are tied together. A layer's hardness acts as a soft block when the drill's attack damage can't break it effectively. Keep this in mind when designing upgrades: some may affect only dirt or only enemies, but the base stats are shared.
- **Burrowers:** most enemies dig through the dirt toward the player. They tunnel through terrain themselves, so they can come from any direction, including through undisturbed ground.
- **Tunnel dwellers:** some enemies live in pre-dug tunnels that exist before the player arrives and do something unique with them (behavior TBD, e.g. patrolling, ambushing, using the tunnel network as cover or shortcuts). These give each layer places that feel inhabited.
- Enemies drop XP.

### Progression (two tiers)
- **In-run:** XP from enemies leads to a level-up, which offers a choice of upgrades. This resets each run.
- **Permanent (meta):** trinkets and money are brought to the owner for upgrades that persist across runs.

### Run end and death
- A run ends when the player chooses to return to the surface, or when they die.
- Returning voluntarily keeps all loot.
- Dying has a **small penalty** (for example, losing a portion of unbanked trinkets or money). The exact penalty is TBD but must be mild, never a full wipe.

### The surface (hub)
- The area above ground works like a main menu you can walk around in. It is the game's home base, not a run.
- It contains the **drill vehicle**: the dog gets into it to start a run. Starting the descent is when the run actually begins. On the surface the dog is on foot; in a run the dog is in the drill.
- It contains the owner (below) and room for other things we add later (cosmetics, story beats, etc.).
- Returning from a run puts the player back here.

### The owner (shop)
- A character on the surface who accepts trinkets and money and provides permanent upgrades. Good spot for story and personality (the partner owns the narrative direction).

### Win condition
- None for now. Treat it as an open-ended dig. Do not build a final depth or boss yet.

## Art and tone
- Target: pixel art, being made by the art/story partner. **Use placeholder shapes (colored rects, circles) until assets arrive.** Keep sprites swappable by isolating visuals from logic.
- Tone is still to be decided with the art partner.

## Open questions
- Enemy roster: which burrowers and tunnel dwellers exist, and what the tunnel dwellers do uniquely with pre-dug tunnels.
- Whether pre-dug tunnels are part of every layer's generated terrain and how they are generated.
- Whether owner upgrades are framed as drill upgrades, dog upgrades, or both (affects naming and art).
- How the player triggers a return to the surface mid-run (walk up, item, button).
- Other things the surface hub should contain.
- Jam deadline and scope cutoff (not yet given).
- Exact death penalty.
- Weapon and upgrade list, trinket list, layer count, and names for each layer.
- Controls (keyboard/mouse/gamepad). Digging has no trigger; open question is how attack direction is chosen: follows movement direction, follows the mouse/aim stick, or a mix (e.g. attacks the nearest thing in reach).
- Whether extra weapons (beyond the dig attack) exist, and if they auto-target enemies only or can also break dirt.
- Story and owner characterization.

## Guidance for agents
- Check this doc before designing features, and keep it updated when decisions are made. Move resolved items out of "Open questions."
- Prefer data-driven content (layers, enemies, upgrades, trinkets as Godot Resources) so the art partner and developer can add content without engine surgery.
- Don't add scope that isn't listed here (win condition, bosses, etc.) without asking.
