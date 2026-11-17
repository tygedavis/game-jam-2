# Layer Barriers Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a thin, breakable, high-HP barrier at every layer boundary that pays out money the instant it breaks, with big juicy break feedback, and stop enemies spawning below an unbroken barrier.

**Architecture:** `Terrain` owns the barrier model (geometry, HP, broken set, payout) and emits signals; it is not a tile. Drill, Projectile and Enemy ask `Terrain` whether a rect overlaps an unbroken barrier (all three are blocked; drill and projectile also damage it, enemies never do). `Main` wires payout, spawn limiting and a separate `BarrierEffects` node that owns all juice so visuals stay swappable.

**Tech Stack:** Godot 4.7, GDScript. No test framework exists; logic is tested with headless SceneTree scripts in `tests/`, run with `godot --headless --path . --script tests/<name>.gd`.

**Spec:** `docs/superpowers/specs/2026-11-17-layer-barriers-design.md`

## Global Constraints

- Godot 4.7, GDScript, 2D, Compatibility renderer. Godot binary: `/home/tygedavis/.local/bin/godot`.
- Barrier thickness is `@export var barrier_thickness := 12.0` px, wall centred on the layer boundary line.
- A barrier sits between layer k-1 and k for k >= 1 (none at the surface). Boundary y = `k * TerrainProfile.layer_height * Terrain.TILE`.
- Enemies can never damage a barrier. Once broken it never returns (within a run).
- Payout is added to the run's gem value the instant it breaks.
- Enemies never spawn on the far side of an unbroken barrier; rejected spawn positions are clamped upward, not skipped.
- Git: never commit to `develop` or `main`. Branch off `origin/develop`, PR against `develop`.
- Content tunables stay `@export`s. Keep visuals separate from logic. Do not add scope beyond the spec (no move-up-layers upgrade).

## Review Focus

- Drill standing exactly on the boundary when it breaks, or a barrier that breaks while the drill overlaps it: must not leave the drill stuck or inside a phantom collider (covered in Task 2 tests).
- Fast projectile or large dig step crossing the 12px wall in one frame: must not tunnel through (Task 2 projectile test uses a high speed).
- Several barriers broken in quick succession, or one broken while a level-up menu is open: payout counts once, no double emit (Task 1 test).
- Enemy alive on the far side when the player breaks the barrier: it just resumes; nothing special (no test, noted only).
- Spawn clamp when the drill is inside the first layer (barrier 1 only): spawns stay above y of barrier 1 and below the existing floor of 2 tiles (Task 3 test).

---

### Task 0: Branch

- [ ] **Step 1: Create the branch off develop**

Run: `git fetch origin && git switch -c feat/layer-barriers origin/develop`
Expected: on `feat/layer-barriers`. The untracked spec and plan files carry over.

- [ ] **Step 2: Commit the spec and plan**

```bash
git add docs/superpowers
git commit -m "Add layer barriers design and plan"
```

---

### Task 1: Terrain barrier model

**Files:**
- Modify: `scripts/terrain.gd`
- Create: `tests/barrier_test.gd`

**Interfaces:**
- Produces on `Terrain`:
  - `@export var barrier_thickness := 12.0`, `@export var barrier_hp_multiplier := 15.0`, `@export var barrier_payout_base := 100`
  - `signal barrier_hit(layer: int, fraction: float, at: Vector2)` fraction = remaining HP 0..1, `at` = world point of the wall nearest the damage (use the boundary line's y, x supplied by caller, see `damage_barrier`)
  - `signal barrier_broken(layer: int, payout: int, at: Vector2)`
  - `func barrier_y(layer: int) -> float`: boundary y for layer k (k >= 1)
  - `func barrier_max_hp(layer: int) -> float`: `barrier_hp_multiplier * max_hp(layer * profile.layer_height - 1)`
  - `func barrier_payout(layer: int) -> int`: `barrier_payout_base * layer`
  - `func barrier_alive(layer: int) -> bool`: false for layer < 1 or once broken
  - `func barrier_layer_in_rect(rect: Rect2) -> int`: layer of an unbroken barrier overlapping `rect`, else -1
  - `func damage_barrier(layer: int, amount: float, at_x: float) -> bool`: no-op if not alive; emits `barrier_hit`; on 0 HP marks broken, emits `barrier_broken`, returns true
  - `func next_barrier_y(from_y: float) -> float`: y of the first unbroken barrier whose boundary is strictly below `from_y`
- Consumes: `TerrainProfile.layer_height`, `Terrain.max_hp(row)`, `Terrain.TILE`.

- [ ] **Step 1: Write the failing test** in `tests/barrier_test.gd` (`extends SceneTree`, builds `Terrain.new()` with `profile = TerrainProfile.new()`, no gems). Test names and assertions:
  - `test_geometry`: `barrier_y(1) == 40 * 32`; `barrier_layer_in_rect(Rect2(0, 1280 - 6, 10, 12)) == 1`; `barrier_layer_in_rect(Rect2(0, 1280 + 7, 10, 10)) == -1`; `barrier_layer_in_rect(Rect2(0, 0, 10, 10)) == -1` (no barrier at the surface).
  - `test_hp_and_payout`: `barrier_max_hp(1) == 15.0 * terrain.max_hp(39)`; `barrier_payout(2) == 200`.
  - `test_damage_then_break_once`: damaging by `barrier_max_hp(1) - 1` emits `barrier_hit` with fraction in (0,1) and returns false; damaging by 5 more returns true, emits `barrier_broken(1, 100, ...)` exactly once; a further `damage_barrier(1, 999.0, 0.0)` returns false and emits nothing; `barrier_alive(1) == false`; `barrier_layer_in_rect` for the old position returns -1.
  - `test_next_barrier_y`: `next_barrier_y(100.0) == 1280.0`; after breaking barrier 1, `next_barrier_y(100.0) == 2560.0`; `next_barrier_y(1280.0)` returns 2560.0 when barrier 1 is intact (strictly below).
  - Prints `PASS`/`FAIL name` per test and calls `quit(1)` on any failure, `quit(0)` otherwise.

- [ ] **Step 2: Run it to see it fail**

Run: `godot --headless --path . --script tests/barrier_test.gd`
Expected: FAIL / script error (functions not defined).

- [ ] **Step 3: Implement the interface above in `scripts/terrain.gd`**

State: `var _barriers_hp := {}` (layer -> remaining HP, created lazily at `barrier_max_hp`) and `var _barriers_done := {}` (layer -> true). The overlap check derives candidate layers from `rect.position.y - barrier_thickness/2` and `rect.end.y + barrier_thickness/2` divided by `layer_height * TILE`, intersects `Rect2(rect.position.x, barrier_y(k) - thickness/2, rect.size.x, thickness)` against the rect, and skips k < 1 and broken layers. `damage_barrier` calls `queue_redraw()`.

- [ ] **Step 4: Run the test to verify it passes**

Run: `godot --headless --path . --script tests/barrier_test.gd`
Expected: all `PASS`, exit 0.

- [ ] **Step 5: Commit**

```bash
git add scripts/terrain.gd tests/barrier_test.gd
git commit -m "Add layer barrier model to Terrain"
```

---

### Task 2: Collision and damage from drill, projectile, enemy

**Files:**
- Modify: `scripts/drill.gd` (`_blocked`, `_dig`), `scripts/projectile.gd` (`_hit_something`), `scripts/enemy.gd` (`_move_axis`)
- Create: `tests/barrier_collision_test.gd`

**Interfaces:**
- Consumes: `Terrain.barrier_layer_in_rect(rect: Rect2) -> int`, `Terrain.damage_barrier(layer: int, amount: float, at_x: float) -> bool`.
- Produces: no new public API.

- [ ] **Step 1: Write the failing test** in `tests/barrier_collision_test.gd` (`extends SceneTree`, adds a `Terrain` to the root, awaits frames). Assertions:
  - `test_projectile_damages_and_stops`: a `Projectile` fired straight down from y=1200 at speed 6000 (far more than 12px per frame) ends up freed and `barrier_max_hp(1)` has been reduced by its damage (assert via `barrier_hit` emission with fraction < 1). It must not pass y=1290.
  - `test_projectile_breaks_barrier`: with a damage of `barrier_max_hp(1)`, one shot emits `barrier_broken`.
  - `test_drill_blocked_and_digs`: a `Drill` (use `preload` of the drill scene if one exists in `scenes/`; otherwise instantiate the node used in `main.tscn`) set `facing = Vector2i(0, 1)`, placed just above the boundary, terrain tiles around it already dug via `terrain.damage(cell, 1.0e9)`: after 120 physics frames pressing down it has not crossed y = 1280 - 6 and the barrier's HP fraction has dropped; after it is broken (`damage_barrier` with max HP) the drill can move through within 60 frames.
  - `test_drill_not_stuck_when_overlapping_breaks`: break the barrier while the drill rect overlaps it; the drill moves freely afterwards.
  - Enemy: assert via a manual call of the same overlap query that an enemy-sized rect straddling the boundary returns layer 1 and that nothing in `enemy.gd` calls `damage_barrier` (a `grep` step, below).

- [ ] **Step 2: Run it to see it fail**

Run: `godot --headless --path . --script tests/barrier_collision_test.gd`
Expected: FAIL (drill and projectile ignore barriers).

- [ ] **Step 3: Implement**
  - `Drill._blocked(center)`: also return true when `terrain.barrier_layer_in_rect(Rect2(center - _half, _half * 2.0)) >= 1`.
  - `Drill._dig(delta)`: after the tile loop, `var layer := terrain.barrier_layer_in_rect(contact_rect)`; if `layer >= 1`, `terrain.damage_barrier(layer, damage_this_frame, contact_rect.get_center().x)`.
  - `Projectile._hit_something()`: before the tile check, build the projectile's hit rect; if `terrain.barrier_layer_in_rect(hit_box) >= 1`, call `damage_barrier(layer, damage, position.x)` and return true. The existing sub-stepping (step <= 8px) is already smaller than the 12px wall, so no tunnelling; keep that invariant.
  - `Enemy._move_axis`: treat `terrain.barrier_layer_in_rect(next) >= 1` as `blocked = true` without damaging it.

- [ ] **Step 4: Run both tests and the load check**

Run: `godot --headless --path . --script tests/barrier_collision_test.gd; godot --headless --path . --script tests/barrier_test.gd; godot --headless --path . --quit 2>&1 | grep -E "SCRIPT ERROR|Parse Error"`
Expected: all `PASS`; the grep prints nothing.

- [ ] **Step 5: Confirm enemies never damage barriers**

Run: `grep -n "damage_barrier" scripts/*.gd`
Expected: only `terrain.gd`, `drill.gd`, `projectile.gd`.

- [ ] **Step 6: Commit**

```bash
git add scripts/drill.gd scripts/projectile.gd scripts/enemy.gd tests/barrier_collision_test.gd
git commit -m "Barriers block drill, shots and enemies; drill and shots damage them"
```

---

### Task 3: Payout and spawn limiting in Main

**Files:**
- Modify: `scripts/main.gd` (`_ready`, `_try_spawn`, results text)
- Modify: `tests/barrier_test.gd` (add the spawn-limit helper test)

**Interfaces:**
- Consumes: `Terrain.barrier_broken(layer: int, payout: int, at: Vector2)`, `Terrain.next_barrier_y(from_y: float) -> float`.
- Produces: `func Main.clamp_spawn_y(y: float, player_y: float) -> float` returning `clampf(y, Terrain.TILE * 2.0, terrain.next_barrier_y(player_y) - Terrain.TILE)`; used by `_try_spawn` in place of the existing `maxf(pos.y, Terrain.TILE * 2.0)`.

- [ ] **Step 1: Write the failing test** in `tests/barrier_test.gd`: `test_spawn_clamp` with a bare `Main`-free approach (put the clamp in a pure static helper on `Terrain`, `Terrain.clamp_spawn_row_y`, or test `clamp_spawn_y` on an instantiated `Main` scene, whichever the implementer finds simpler; assertions: player at y=100, intact barrier 1: `clamp_spawn_y(5000.0, 100.0) == 1280.0 - 32.0`; `clamp_spawn_y(0.0, 100.0) == 64.0`; after breaking barrier 1, `clamp_spawn_y(5000.0, 100.0) == 2560.0 - 32.0`.

- [ ] **Step 2: Run it to see it fail**

Run: `godot --headless --path . --script tests/barrier_test.gd`
Expected: FAIL on `test_spawn_clamp`.

- [ ] **Step 3: Implement**
  - Connect `terrain.barrier_broken` in `_ready` to `_on_barrier_broken(layer, payout, at)`: `_gem_value += payout`, `_barrier_money += payout`, `_barriers_broken += 1`.
  - Add the `clamp_spawn_y` function above and use it in `_try_spawn`.
  - Add a `Barriers broken: n (+money)` line to the death results text in `_on_player_died`, between the gems list and the total, so total value (which includes barrier money) matches the banked amount.

- [ ] **Step 4: Run tests and load check**

Run: `godot --headless --path . --script tests/barrier_test.gd; godot --headless --path . --quit 2>&1 | grep -E "SCRIPT ERROR|Parse Error"`
Expected: `PASS`, grep prints nothing.

- [ ] **Step 5: Manual check** with the `run` skill or Godot MCP: dig to the first barrier, confirm no enemy appears below it, break it, confirm the HUD gem value jumps by 100 and enemies begin spawning below.

- [ ] **Step 6: Commit**

```bash
git add scripts/main.gd tests/barrier_test.gd
git commit -m "Pay out barrier money and keep spawns above unbroken barriers"
```

---

### Task 4: Drawing and juice

**Files:**
- Modify: `scripts/terrain.gd` (`_draw`)
- Create: `scripts/barrier_effects.gd` (`class_name BarrierEffects`, `extends Node2D`)
- Modify: `scripts/main.gd` (add the node, connect `barrier_hit` and `barrier_broken`)

**Interfaces:**
- Consumes: `Terrain.barrier_hit(layer, fraction, at)`, `Terrain.barrier_broken(layer, payout, at)`, `Terrain.barrier_alive(layer)`, `Terrain.barrier_y(layer)`, `Terrain.barrier_max_hp(layer)`.
- Produces: `BarrierEffects.setup(camera: Camera2D) -> void`, `on_hit(fraction: float, at: Vector2) -> void`, `on_break(payout: int, at: Vector2) -> void`. Shake uses `camera.offset` (Main already sets `camera.position` each frame, so offset does not fight it).

- [ ] **Step 1: Draw the wall in `Terrain._draw`.** For each unbroken barrier whose y is within the view, draw a full-view-width rect `barrier_thickness` tall centred on `barrier_y(k)` in a bright placeholder colour (metal grey with a lighter 2px top highlight). Darken/crack toward red as remaining HP fraction falls (add `func barrier_fraction(layer: int) -> float` if needed). Skip broken layers.

- [ ] **Step 2: Implement `BarrierEffects`.** Values to start with (tune by feel, all `const` at the top):
  - `on_hit`: short white flash on the wall (an overlay rect drawn for ~0.06s), a few spark `CPUParticles2D` at `at`, camera shake with amplitude `lerp(1.0, 6.0, 1.0 - fraction)` px decaying over 0.15s.
  - `on_break`: hit-stop (`Engine.time_scale = 0.05` for 0.12s real time, restored using a timer created with `ignore_time_scale = true`), a one-shot `CPUParticles2D` burst of ~80 particles spread along the wall, a coin shower of ~30 gold particles falling, camera shake 14px over 0.5s, and a large centred "+N" `Label` that scales up and fades over ~1s via a `Tween`.
  - Ensure `Engine.time_scale` is restored if the scene is freed mid hit-stop (reset it in `_exit_tree`).

- [ ] **Step 3: Wire in `Main._ready`:** `var fx := BarrierEffects.new(); add_child(fx); fx.setup(camera)`; connect `terrain.barrier_hit` to `fx.on_hit` (passing fraction and at) and `terrain.barrier_broken` to a small lambda calling `fx.on_break(payout, at)`.

- [ ] **Step 4: Load check**

Run: `godot --headless --path . --quit 2>&1 | grep -E "SCRIPT ERROR|Parse Error"`
Expected: prints nothing.

- [ ] **Step 5: Manual feel check** using the `run` skill or Godot MCP: reach barrier 1 and break it. Confirm the wall is visible and 12px, cracks as damaged, shake rises, and break shows hit-stop, particles, coins, popup, and money in the HUD. Try `barrier_thickness` at 6 and 20 in the editor to confirm it is tunable. Confirm time scale returns to 1 after the break and after dying mid-effect.

- [ ] **Step 6: Commit**

```bash
git add scripts/terrain.gd scripts/barrier_effects.gd scripts/main.gd
git commit -m "Draw layer barriers and add break juice"
```

---

### Task 5: Docs, CI check, PR

**Files:**
- Modify: `docs/game-design.md` (Depth layers section: barriers, payout, no spawn camping; add the move-up-layers upgrade to Open questions as deferred), `docs/prototype-plan.md` (decisions and "Not yet built")

- [ ] **Step 1: Update the two docs** as described above, no issue links in docs.
- [ ] **Step 2: Run all tests and the load check** (commands from Tasks 1-4). Expected: all `PASS`, grep empty.
- [ ] **Step 3: Commit**, then push and open a PR against `develop`:

```bash
git add docs
git commit -m "Document layer barriers"
git push -u origin feat/layer-barriers
gh pr create --base develop --title "Layer barriers: breakable wall between layers" --body "Implements #9 (barrier, payout, spawn limiting, break juice). The move-up-layers upgrade is deferred to a separate issue."
```

Expected: PR opened against `develop`; CI (`ci.yml`) passes. Note the PR body must end with the attribution line from the session.

- [ ] **Step 4: Open a follow-up issue** for the "move up layers" upgrade (depends on a voluntary return mechanic): `gh issue create --title "Upgrade for moving up layers" --body "Deferred from #9: depends on a return-to-surface mechanic."`
