# Layer barriers (issue #9): short design

## Intent
A thin, high-HP wall sits between depth layers. Breaking it is the reward moment of a run: an immediate large money payout with big, flashy feedback. The goal is a dopamine hit that feels tangible and earned.

## Goals
- A barrier at every layer boundary (not at the surface), spanning the full width of the ground.
- The player breaks it by digging and by projectiles. It has high HP.
- Once broken it never reappears (within a run; terrain regenerates each run).
- No spawn camping: enemies never spawn on the far side of an unbroken barrier. Spawns are limited to the player's current layer and above, until the barrier below is broken (`Main._try_spawn`).
- Money is awarded the instant it breaks, added to the run's gem value (banked at run end like gems).
- Juice: crack/flash while damaged, screen shake rising as it nears breaking, then on break a hit-stop, particle burst, stronger shake, coin shower, and a large "+money" popup.

## Non-goals
- The "move up layers" upgrade. It depends on a return-to-surface mechanic that doesn't exist; track it as a separate issue.
- Persisting broken barriers across runs.
- Per-layer authored barrier art (placeholder visuals only).

## Anti-goals
- A barrier that looks thick or chunky like a floor tile.
- Enemies being able to break it, or leaving a gap that lets them through while it stands.
- Visual or collision mismatch (invisible blocking, or walking through something drawn solid).

## Constraints
- Terrain is a 32px tile grid with only damaged tiles stored (`scripts/terrain.gd`); layers are `TerrainProfile.layer_height` (40) rows. The barrier is its own thing, not a tile.
- Collision readers that must know about it: `Drill._blocked` / `_dig`, `Projectile`, and enemy movement.
- Content stays data-driven: tunables are `@export`s on `Terrain`/`TerrainProfile`.

## Approaches considered
- **A. Full tile row.** Cheapest, but 32px thick; reads as a floor.
- **B. Tile row drawn thin.** Invisible collision around the plate; rejected.
- **C. True wall on the layer boundary line.** Chosen. The user asked for it to be thicker than "a few pixels" (about 12px) to see how it looks, so thickness is a tunable.

## Design (decided with the user)
- Approach C. Thickness `@export barrier_thickness := 12.0` px, easy to change.
- Enemies are stopped by the barrier but can never damage it.
- Spawn rule: `_try_spawn` rejects (or clamps) any candidate position whose y is at or below the first unbroken barrier under the player. `Terrain` exposes a query for that barrier's y. Enemies already alive stay where they are; since they can't pass the wall, nothing reaches the player from below.

## Builder's calls (mine, adjust freely)
- The wall is centred on the boundary line between layer k-1 and k (k >= 1). It overlaps 6px into each neighbouring row's space; that is fine since the neighbours are dirt until dug.
- HP: `barrier_hp_multiplier` (default ~15) times the tile HP of the layer above, tuned by playtest.
- Payout: `barrier_payout_base` scaled by layer index; tune against gem values.
- Broken barriers are tracked in a set per run (like `_gems_done`).
- Drill digging damages the wall when the leading-edge contact rect overlaps it, using the same `dig_power()`.
- On a rejected spawn position, clamp it upward into the allowed area rather than skipping, so spawn pressure stays steady near a barrier.
- Juice is isolated in a small effect node so visuals stay swappable (see `docs/art-guide.md`).

## Left to the builder
- Exact feel values: shake curve, hit-stop length, particle counts, popup style.
- Whether to show the barrier in the editor preview.
- Update `docs/game-design.md` (Depth layers section) and `docs/prototype-plan.md` when it lands.
