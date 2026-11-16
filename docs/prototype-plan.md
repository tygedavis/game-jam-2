# First Playable Prototype Plan

See `docs/game-design.md` for the vision. This plan covers only the first playable prototype.

## Goal
Answer one question: **is steering a drill that auto-digs and auto-fights, while burrowing enemies chase you, fun for about 5 minutes?**

- Placeholder shapes only (colored rects/circles). No dependence on final art.
- The game boots to a minimal surface scene; walk the dog to the drill and press Space to start a run. The shop and meta-progression come after the prototype.

## Decisions
- Attack direction follows the drill's movement direction (single input, easy to change later).
- Movement is four-directional (one axis at a time). Controls: WASD or arrows; Space on the surface.
- Terrain is endless in depth. Tile HP comes from a formula (`TerrainProfile`: `base_hp * hp_growth ^ layer`), with optional hand-authored `LayerDef` overrides (name, colour, HP) for layers that need personality. Only damaged or dug tiles are stored.
- Terrain is a script-drawn grid (not a `TileMapLayer`), so no tileset is needed; swap to tiles when art arrives.
- Only the player's attacks collect trinkets. A trinket in a tile broken by an enemy is lost.
- Dying shows a results screen, then returns to the surface.

## Milestones
Each was playable and committed on its own.

1. **Drill and terrain** (done). Destructible dirt grid; drill that moves and steers in side view.
2. **Auto-attack is dig** (done). Timer-based attack in the facing direction shared by digging and fighting (damage, interval, reach, area). Tile HP by depth layer, so deeper ground soft-blocks the drill.
3. **Burrowing enemy** (done). `EnemyDef`-driven burrower spawns off screen, tunnels toward the drill, deals contact damage, takes damage from the auto-attack, drops XP. Player has HP.
4. **Level-up choice** (done). XP bar; each level pauses and offers three random `UpgradeDef`s (attack damage, attack speed, reach, move speed).
5. **Trinkets and depth** (done). Buried `TrinketDef`s (rarer and more valuable deeper), depth and trinket HUD, results screen on death.
6. **Stretch**
   - Minimal surface scene with a start prompt (done).
   - Tunnel-dweller enemy (not started).

## Not yet built (vision items beyond the prototype)
- Owner, shop, and permanent upgrades; carrying trinkets/money between runs.
- Voluntary return to the surface mid-run, and a death penalty.
- Tunnel-dweller enemies and pre-dug tunnels; enemy scaling with depth.

## Structure
- Content as Godot `Resource` files so it can be added without code changes: `scripts/data/` for the definitions (`LayerDef`, `TerrainProfile`, `EnemyDef`, `UpgradeDef`, `TrinketDef`), `data/` for the `.tres` instances.
- `scenes/` for entities and screens (`surface.tscn` is the main scene; `main.tscn` is a run), `scripts/` for systems.
- Keep visuals separate from logic so placeholder shapes can be swapped for sprites.
