class_name DevActions
extends RefCounted
## Developer-mode cheat actions on a run (a Main node). Lives in scripts/dev/, which production
## builds leave out, so nothing outside that folder may reference this class.

## Rows to land below (or above) a layer boundary.
const LAND_OFFSET_TILES := 2


## Jumps the drill one layer down (direction +1) or up (-1). Going down breaks that layer's
## barrier without payout; both ways carve a small pocket at the landing spot. Returns false when
## it did nothing (already at the surface going up, or another direction).
static func skip_layer(run: Node, direction: int) -> bool:
	if not is_instance_valid(run) or (direction != 1 and direction != -1):
		return false
	var terrain: Terrain = run.terrain
	var drill: Drill = run.drill
	var current := terrain.profile.layer_of(terrain.world_to_cell(drill.position).y)
	if direction < 0 and current <= 0:
		return false
	var landing_y: float
	if direction > 0:
		terrain.mark_barrier_broken(current + 1)
		landing_y = terrain.barrier_y(current + 1) + LAND_OFFSET_TILES * Terrain.TILE
	else:
		landing_y = terrain.barrier_y(current) - LAND_OFFSET_TILES * Terrain.TILE
	drill.position = Vector2(drill.position.x, landing_y)
	var cell := terrain.world_to_cell(drill.position)
	terrain.carve(Rect2i(cell.x - 1, cell.y - 1, 3, 3))
	return true


## Gives one stack of an upgrade item, the same way picking it up from the ground does (so the
## run's HUD and caps stay right). Returns false at the stack cap.
static func give_item(run: Node, def: UpgradeItemDef) -> bool:
	if not is_instance_valid(run):
		return false
	var before: int = run.drill.stacks_of(def)
	run.terrain.upgrade_collected.emit(def)
	return run.drill.stacks_of(def) > before


## Equips a weapon on the run's drill, in the slot its def names. Returns false if there is no run.
static func equip_weapon(run: Node, def: WeaponDef) -> bool:
	if not is_instance_valid(run):
		return false
	run.drill.equip(def)
	return true


## Removes every enemy (not counted as kills). Returns how many.
static func kill_enemies(run: Node) -> int:
	if not is_instance_valid(run):
		return 0
	var enemies := run.get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		e.queue_free()
	return enemies.size()
