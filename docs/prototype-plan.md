# First Playable Prototype Plan

See `docs/game-design.md` for the vision. This plan covers only the first playable prototype.

## Goal
Answer one question: **is steering a drill that auto-digs and fires at the mouse, while burrowing enemies chase you, fun for about 5 minutes?**

- Placeholder shapes only (colored rects/circles). No dependence on final art.
- The game boots to a minimal surface scene; walk the dog to the drill and press Space to start a run. The shop and meta-progression come after the prototype.

## Decisions
- Attack is a mouse-aimed projectile fired while left click is held (`Projectile`); it has no range limit (add one if it proves necessary). Digging is automatic and separate.
- Movement is four-directional (one axis at a time). Controls: WASD or arrows; Space is always the interaction button.
- Terrain is endless in depth. Tile HP comes from a formula (`TerrainProfile`: `base_hp * hp_growth ^ layer`), with optional hand-authored `LayerDef` overrides (name, colour, HP) for layers that need personality. Only damaged or dug tiles are stored.
- Terrain is a script-drawn grid (not a `TileMapLayer`), so no tileset is needed. Tiles use textures from `TerrainProfile`/`LayerDef` (flat colour fallback); `terrain.gd` is `@tool` and draws a layer preview in the editor.
- Only the player's digging collects gems. A gem has its own durability and is exposed once the dirt around it is gone; enemies dig dirt only and never affect gems.
- Dying shows a results screen, then returns to the surface.

## Milestones
Each was playable and committed on its own.

1. **Drill and terrain** (done). Destructible dirt grid; drill that moves and steers in side view.
2. **Auto-attack is dig** (done). Timer-based attack in the facing direction shared by digging and fighting (damage, interval). Tile HP by depth layer, so deeper ground soft-blocks the drill.
3. **Burrowing enemy** (done). `EnemyDef`-driven burrower spawns off screen, tunnels toward the drill, deals contact damage, takes damage from the player's shots. Player has HP.
4. **Map upgrade items** (done; replaced the XP level-up choice). `UpgradeItemDef`s are buried in the dirt; breaking the tile adds a stack of a percentage buff for the run (attack damage, attack speed, move speed).
5. **Gems and depth** (done). Buried `GemDef`s (rarer and more valuable deeper), depth and gem HUD, results screen on death.
6. **Stretch**
   - Minimal surface scene with a start prompt (done).
   - Persistent wallet, owner and shop with permanent upgrades (done, see below).
   - Tunnel-dweller enemy (not started).

## Meta-progression (done)
- `Save` autoload (`scripts/save.gd`) holds money, unlocked items and item shop levels in `user://save.json`.
- Gem value is banked as money when a run ends, either by dying (75% is kept) or by returning to the surface voluntarily (all of it is kept).
- The owner stands on the surface (walk up, press Space). The shop sells Unlock and Upgrade for each `UpgradeItemDef` listed in the item catalog (`data/item_catalog.tres`); nothing starts unlocked. Each upgrade level raises the item's per-stack buff (cap 5 levels); prices are set on each item.

## Layer barriers (done)
- `Terrain` owns a barrier at each layer boundary (`barrier_thickness`, `barrier_hp_multiplier`, `barrier_payout_base`); broken ones are remembered for the run. The drill, shots and enemies are blocked by it; only the drill's digging and shots damage it.
- Breaking one adds its payout to the run's gem value and triggers `BarrierEffects` (`scripts/barrier_effects.gd`). Spawns are clamped above the first unbroken barrier (`Terrain.clamp_spawn_y`).
- Headless tests live in `tests/`. Run them all with `tests/run_all.sh` (CI's `tests` job runs the same script), or one with `godot --headless --path . --script tests/<name>_test.gd`.
- Test contract: `tests/**/*_test.gd`, `extends SceneTree`, print `PASS`/`FAIL` lines, `quit(1)` on failure. A test fails on a non-zero exit, a timeout (`TEST_TIMEOUT`, default 120s), any `FAIL` line, or no `PASS` line. New files are picked up automatically.

## Not yet built (vision items beyond the prototype)
- Tunnel-dweller enemies and pre-dug tunnels; enemy scaling with depth.

## Structure
- Content as Godot `Resource` files so it can be added without code changes: `scripts/data/` for the definitions (`LayerDef`, `TerrainProfile`, `EnemyDef`, `UpgradeItemDef`, `GemDef`), `data/` for the `.tres` instances.
- `scenes/` for entities and screens (`surface.tscn` is the main scene; `main.tscn` is a run), `scripts/` for systems.
- Keep visuals separate from logic so placeholder shapes can be swapped for sprites. Characters are `AutoSprite` nodes (`scripts/auto_sprite.gd`) in the scenes; see `docs/art-guide.md`.
