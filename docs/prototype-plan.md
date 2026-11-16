# First Playable Prototype Plan

See `docs/game-design.md` for the vision. This plan covers only the first playable prototype.

## Goal
Answer one question: **is steering a drill that auto-digs and auto-fights, while burrowing enemies chase you, fun for about 5 minutes?**

- Placeholder shapes only (colored rects/circles). No dependence on final art.
- `main.tscn` boots straight into a run. The surface hub, shop, and meta-progression come after the prototype.

## Decisions
- Attack direction follows the drill's movement direction (single input, easy to change later).
- The prototype starts directly in a run; no surface scene yet.

## Milestones
Each is playable and committed on its own.

1. **Drill and terrain**
   - Grid-based destructible dirt world (likely `TileMapLayer`).
   - Drill that moves and steers in side view; digs into dirt.
2. **Auto-attack is dig**
   - Attack fires on a timer in the movement direction.
   - Dirt tiles have HP and break when hit. Layer 1 soft, layer 2 harder, so the soft-block is felt.
3. **Burrowing enemy**
   - One enemy type tunnels through dirt toward the player.
   - Damages the player on contact, takes damage from the auto-attack, drops XP.
4. **Level-up choice**
   - XP bar fills, then a pick-one-of-three upgrade screen.
   - Upgrades: attack damage, attack speed, attack reach, move speed (data-defined).
5. **Trinkets and depth**
   - Trinkets buried in dirt; depth counter and HUD.
   - Death ends the run and shows a results screen listing what was collected.
6. **Stretch (only if time allows)**
   - Tunnel-dweller enemy.
   - Minimal surface scene with a start button.

## Structure
- Content as Godot `Resource` files so content can be added without code changes: `scripts/data/` for `LayerDef`, `EnemyDef`, `UpgradeDef`.
- `scenes/` for entities, `scripts/` for systems.
- Keep visuals separate from logic so placeholder shapes can be swapped for sprites.
