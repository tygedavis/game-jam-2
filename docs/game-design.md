# Game Design: Vision

Working title: TBD. Jam theme: **"Deeper and Deeper"**.

This is a self-imposed jam. Two people are learning game development: one is primarily the developer, the other primarily story and art (either can help in the other area). Favor simple, finishable, well-structured work over ambitious scope. Use placeholder shapes until the art arrives; code must not depend on final art.

## Pitch

A 2D side-view, Vampire Survivors-style roguelite. You are a dog digging down through the earth to find buried trinkets while enemies attack you. The deeper you go, the harder the ground gets and the better the loot, so you have to upgrade to keep going.

## Core loop

1. **Dig** down and sideways through the ground, carving tunnels. Depth is the main axis of progress and risk.
2. **Fight** enemies automatically (auto-attack weapons, as in Vampire Survivors). Enemies drop XP.
3. **Level up in-run** from XP and pick one of several offered upgrades (a choice, not random assignment).
4. **Collect trinkets** (and money) buried in the ground.
5. **Choose when to return** to the surface. The player decides when to go back; going back is a risk and reward call.
6. **Visit the owner (shop)** and spend trinkets and money on permanent upgrades. Then dig again, able to go deeper.

## Systems

### Movement and digging
- Side-view. The dog digs down and sideways (not freely in 8 directions).
- Terrain is destructible, and carved tunnels persist for the run.

### Depth layers and hard ground
- The ground is divided into depth layers. Each deeper layer is harder to dig.
- Hardness is a **soft block**: a layer can be effectively impassable until the dog's dig power is upgraded enough. This is what pushes the player back to the owner to upgrade.
- Layers also drive enemy types, trinket rarity, and visuals (to be defined).

### Combat
- Weapons fire automatically; upgrades add or modify them.
- Enemies come from the dirt and tunnels. **How they move through a side-view dig (burrowing, roaming carved tunnels, surface spawns) is an open question.**
- Enemies drop XP.

### Progression (two tiers)
- **In-run:** XP from enemies leads to a level-up, which offers a choice of upgrades. This resets each run.
- **Permanent (meta):** trinkets and money are brought to the owner for upgrades that persist across runs.

### Run end and death
- A run ends when the player chooses to return to the surface, or when they die.
- Returning voluntarily keeps all loot.
- Dying has a **small penalty** (for example, losing a portion of unbanked trinkets or money). The exact penalty is TBD but must be mild, never a full wipe.

### The owner (shop)
- A character who accepts trinkets and money and provides permanent upgrades. Good spot for story and personality (the partner owns the narrative direction).

### Win condition
- None for now. Treat it as an open-ended dig. Do not build a final depth or boss yet.

## Art and tone
- Target: pixel art, being made by the art/story partner. **Use placeholder shapes (colored rects, circles) until assets arrive.** Keep sprites swappable by isolating visuals from logic.
- Tone is still to be decided with the art partner.

## Open questions
- Enemy behavior in a side-view dig (being taken to the art/story partner).
- Jam deadline and scope cutoff (not yet given).
- Exact death penalty.
- Weapon and upgrade list, trinket list, layer count, and names for each layer.
- Controls (keyboard/mouse/gamepad) and how digging is triggered.
- Story and owner characterization.

## Guidance for agents
- Check this doc before designing features, and keep it updated when decisions are made. Move resolved items out of "Open questions."
- Prefer data-driven content (layers, enemies, upgrades, trinkets as Godot Resources) so the art partner and developer can add content without engine surgery.
- Don't add scope that isn't listed here (win condition, bosses, etc.) without asking.
