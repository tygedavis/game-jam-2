# Game Design: Vision

Working title: TBD. Jam theme: **"Deeper and Deeper"**.

This is a self-imposed jam. Two people are learning game development: one is primarily the developer, the other primarily story and art (either can help in the other area). Favor simple, finishable, well-structured work over ambitious scope. Use placeholder shapes until the art arrives; code must not depend on final art.

## Pitch

A 2D side-view roguelite with automatic attacks and level-up upgrade choices. You play a dog piloting a drill vehicle down through the earth to find buried gems while enemies attack you. The deeper you go, the harder the ground gets and the better the loot, so you have to upgrade to keep going.

## Core loop

1. **Dig** down and sideways through the ground, carving tunnels, by steering into dirt (digging is automatic on contact). Depth is the main axis of progress and risk.
2. **Fight** enemies automatically (the same auto-attack). Enemies drop XP.
3. **Level up in-run** from XP and pick one of several offered upgrades (a choice, not random assignment).
4. **Collect gems** (and money) buried in the ground.
5. **Choose when to return** to the surface. The player decides when to go back; going back is a risk and reward call.
6. **Visit the owner (shop)** and spend gems and money on permanent upgrades. Then dig again, able to go deeper.

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

### Combat
- Attacks fire automatically; upgrades add or modify them.
- **Dig and attack are separate.** Digging is automatic on dirt contact (dirt takes damage against its layer hardness and breaks). The attack only hits enemies and is being moved to a mouse-aimed ranged attack; until then it still fires automatically. For now dig power is derived from the attack stats (damage / interval), so attack upgrades also speed up digging.
- Because of this, dig power and attack power are still tied together. A layer's hardness acts as a soft block when the drill's attack damage can't break it effectively. Keep this in mind when designing upgrades: some may affect only dirt or only enemies, but the base stats are shared.
- **Burrowers:** most enemies dig through the dirt toward the player. They tunnel through terrain themselves, so they can come from any direction, including through undisturbed ground.
- **Tunnel dwellers:** some enemies live in pre-dug tunnels that exist before the player arrives and do something unique with them (behavior TBD, e.g. patrolling, ambushing, using the tunnel network as cover or shortcuts). These give each layer places that feel inhabited.
- Enemies drop XP.

### Progression (two tiers)
- **In-run:** XP from enemies leads to a level-up, which offers a choice of upgrades. This resets each run.
- **Permanent (meta):** gems and money are brought to the owner for upgrades that persist across runs.

### Run end and death
- A run ends when the player chooses to return to the surface, or when they die.
- Returning voluntarily keeps all loot.
- Dying has a **small penalty** (for example, losing a portion of unbanked gems or money). The exact penalty is TBD but must be mild, never a full wipe.

### The surface (hub)
- The area above ground works like a main menu you can walk around in. It is the game's home base, not a run.
- It contains the **drill vehicle**: the dog gets into it to start a run. Starting the descent is when the run actually begins. On the surface the dog is on foot; in a run the dog is in the drill.
- It contains the owner (below) and room for other things we add later (cosmetics, story beats, etc.).
- Returning from a run puts the player back here.

### The owner (shop)
- A character on the surface who accepts gems and money and provides permanent upgrades. Good spot for story and personality (the partner owns the narrative direction).

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
- Weapon and upgrade list, gem list, layer count, and names for each layer.
- Controls beyond keyboard (mouse/gamepad). Digging has no trigger. For the prototype, attack direction follows the movement direction; revisit if it feels wrong.
- Whether extra weapons (beyond the dig attack) exist, and if they auto-target enemies only or can also break dirt.
- Story and owner characterization.

## Guidance for agents
- Check this doc before designing features, and keep it updated when decisions are made. Move resolved items out of "Open questions."
- Prefer data-driven content (layers, enemies, upgrades, gems as Godot Resources) so the art partner and developer can add content without engine surgery.
- Don't add scope that isn't listed here (win condition, bosses, etc.) without asking.
