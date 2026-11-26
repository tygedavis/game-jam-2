extends SceneTree
## Headless tests for the dev actions (skip layer, give item, kill enemies, pause spawning) and the
## two Terrain helpers they use.
## Run: godot --headless --path . --script tests/dev_actions_test.gd

var _failed := false
var _dev: Node


## Stands in for an enemy: just a node in the "enemies" group.
class FakeEnemy:
	extends Node2D

	func rect() -> Rect2:
		return Rect2(position, Vector2(8, 8))


func _check(test_name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + test_name)
	if not ok:
		_failed = true


func _init() -> void:
	await process_frame
	_dev = root.get_node("DevMode")
	test_terrain_helpers()
	await test_run_registers_with_devmode()
	await test_skip_down()
	await test_skip_down_over_broken_barrier()
	await test_skip_down_from_layer_one()
	await test_skip_up()
	await test_skip_up_at_surface()
	await test_give_item()
	await test_equip_weapon()
	await test_kill_enemies()
	await test_spawning_paused()
	_dev.set_flag(&"spawning_paused", false)
	quit(1 if _failed else 0)


func _main() -> Node:
	get_root().get_tree().paused = false
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	return main


func _finish(main: Node) -> void:
	main.queue_free()
	await process_frame


func test_terrain_helpers() -> void:
	var t := Terrain.new()
	t.profile = TerrainProfile.new()
	var gem := GemDef.new()
	t.gem_defs = [gem]
	t.gem_chance = 1.0
	root.add_child(t)
	var broken := []
	var collected := []
	t.barrier_broken.connect(func(l: int, p: int, _a: Vector2) -> void: broken.append([l, p]))
	t.gem_collected.connect(func(g: GemDef) -> void: collected.append(g))
	t.mark_barrier_broken(1)
	t.mark_barrier_broken(1)
	_check("mark_barrier_broken: barrier gone", not t.barrier_alive(1))
	_check("mark_barrier_broken: no signal, no payout (and safe twice)", broken.is_empty())
	_check("carve: setup has a gem and dirt", t.gem_at(Vector2i(1, 50)) != null and t.is_dirt(Vector2i(1, 50)))
	t.carve(Rect2i(0, 50, 3, 3))
	_check("carve: dirt and gems in the rect no longer block",
		not t.is_blocked(Vector2i(0, 50)) and not t.is_blocked(Vector2i(2, 52)))
	_check("carve: cells outside the rect are untouched", t.is_blocked(Vector2i(3, 50)))
	_check("carve: collecting the gems is not announced", collected.is_empty())
	t.queue_free()


func test_run_registers_with_devmode() -> void:
	var main := await _main()
	_check("run: DevMode.run is the open run", _dev.run == main)
	await _finish(main)
	_check("run: DevMode.run cleared when the run closes", _dev.run == null)


func _free_to_stand(main: Node) -> bool:
	return not main.drill._blocked(main.drill.position) \
		and main.terrain.barrier_layer_in_rect(main.drill.rect()) == -1


func test_skip_down() -> void:
	var main := await _main()
	var x: float = main.drill.position.x
	var ok := DevActions.skip_layer(main, 1)
	var t: Terrain = main.terrain
	_check("skip down: reports it moved", ok)
	_check("skip down: barrier 1 is broken", not t.barrier_alive(1))
	_check("skip down: x unchanged, two tiles below the boundary",
		main.drill.position.x == x and is_equal_approx(main.drill.position.y, t.barrier_y(1) + 2.0 * Terrain.TILE))
	_check("skip down: not embedded in dirt or a barrier", _free_to_stand(main))
	_check("skip down: no money paid", main._barrier_money == 0 and main._gem_value == 0)
	await _finish(main)


func test_skip_down_over_broken_barrier() -> void:
	var main := await _main()
	main.terrain.mark_barrier_broken(1)
	_check("skip over a broken barrier still moves", DevActions.skip_layer(main, 1))
	_check("skip over a broken barrier: lands below it",
		is_equal_approx(main.drill.position.y, main.terrain.barrier_y(1) + 2.0 * Terrain.TILE))
	await _finish(main)


func test_skip_down_from_layer_one() -> void:
	var main := await _main()
	main.drill.position = Vector2(0, main.terrain.barrier_y(1) + 100.0)
	_check("skip from layer 1 moves", DevActions.skip_layer(main, 1))
	_check("skip from layer 1: breaks barrier 2", not main.terrain.barrier_alive(2))
	_check("skip from layer 1: lands below barrier 2",
		is_equal_approx(main.drill.position.y, main.terrain.barrier_y(2) + 2.0 * Terrain.TILE))
	await _finish(main)


func test_skip_up() -> void:
	var main := await _main()
	main.drill.position = Vector2(0, main.terrain.barrier_y(1) + 100.0)
	_check("skip up: reports it moved", DevActions.skip_layer(main, -1))
	_check("skip up: lands two tiles above the boundary",
		is_equal_approx(main.drill.position.y, main.terrain.barrier_y(1) - 2.0 * Terrain.TILE))
	_check("skip up: barrier below is left alone", main.terrain.barrier_alive(1))
	_check("skip up: not embedded in dirt", _free_to_stand(main))
	await _finish(main)


func test_skip_up_at_surface() -> void:
	var main := await _main()
	var before: Vector2 = main.drill.position
	_check("skip up at the surface does nothing", not DevActions.skip_layer(main, -1))
	_check("skip up at the surface: drill stays put", main.drill.position == before)
	await _finish(main)


func test_give_item() -> void:
	var main := await _main()
	var def: UpgradeItemDef = main.catalog.items[0]
	_check("give: first stack accepted", DevActions.give_item(main, def))
	_check("give: drill holds one stack", main.drill.stacks_of(def) == 1)
	_check("give: the run's own bookkeeping saw it", main._upgrades.has(def.id()))
	for i in def.max_stacks - 1:
		DevActions.give_item(main, def)
	_check("give: stops at the stack cap", not DevActions.give_item(main, def) \
		and main.drill.stacks_of(def) == def.max_stacks)
	await _finish(main)


func test_equip_weapon() -> void:
	var main := await _main()
	var flame: WeaponDef = load("res://data/weapons/flamethrower.tres")
	_check("equip: accepted during a run", DevActions.equip_weapon(main, flame))
	_check("equip: secondary slot holds the flamethrower", main.drill.secondary != null and main.drill.secondary.def == flame)
	_check("equip: primary untouched", main.drill.primary.def.id() == "basic_gun")
	await _finish(main)
	_check("equip: no run is refused", not DevActions.equip_weapon(null, flame))


func test_kill_enemies() -> void:
	var main := await _main()
	for i in 3:
		var e := FakeEnemy.new()
		main.add_child(e)
		e.add_to_group("enemies")
	_check("kill: returns how many it removed", DevActions.kill_enemies(main) == 3)
	await process_frame
	_check("kill: none left", get_nodes_in_group("enemies").is_empty())
	await _finish(main)


func test_spawning_paused() -> void:
	var main := await _main()
	main.drill.position = Vector2(0, 200) # underground, past spawn_min_row
	_dev.set_flag(&"spawning_paused", true)
	main._try_spawn()
	_check("paused: no enemy spawns", get_nodes_in_group("enemies").is_empty())
	_dev.set_flag(&"spawning_paused", false)
	main._try_spawn()
	_check("control: an enemy spawns once unpaused", get_nodes_in_group("enemies").size() == 1)
	await _finish(main)
