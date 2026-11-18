extends SceneTree
## Headless tests for the Terrain barrier model.
## Run: godot --headless --path . --script tests/barrier_test.gd

var _failed := false


func _init() -> void:
	test_geometry()
	test_hp_and_payout()
	test_damage_then_break_once()
	test_next_barrier_y()
	test_spawn_clamp()
	test_spawn_position_stays_off_screen()
	quit(1 if _failed else 0)


func _check(name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + name)
	if not ok:
		_failed = true


func _terrain() -> Terrain:
	var t := Terrain.new()
	t.profile = TerrainProfile.new()
	return t


func test_geometry() -> void:
	var t := _terrain()
	_check("geometry: barrier_y(1) is 40 rows down", t.barrier_y(1) == 40.0 * 32.0)
	_check("geometry: rect on the wall hits layer 1", t.barrier_layer_in_rect(Rect2(0, 1280 - 6, 10, 12)) == 1)
	_check("geometry: rect just below the wall misses", t.barrier_layer_in_rect(Rect2(0, 1280 + 7, 10, 10)) == -1)
	_check("geometry: no barrier at the surface", t.barrier_layer_in_rect(Rect2(0, 0, 10, 10)) == -1)
	t.free()


func test_hp_and_payout() -> void:
	var t := _terrain()
	_check("hp: 15x the tile HP of the layer above", is_equal_approx(t.barrier_max_hp(1), 15.0 * t.max_hp(39)))
	_check("payout: base * layer", t.barrier_payout(2) == 200)
	t.free()


func test_damage_then_break_once() -> void:
	var t := _terrain()
	var hits := []
	var breaks := []
	t.barrier_hit.connect(func(layer: int, fraction: float, _at: Vector2) -> void: hits.append([layer, fraction]))
	t.barrier_broken.connect(func(layer: int, payout: int, _at: Vector2) -> void: breaks.append([layer, payout]))
	var broke := t.damage_barrier(1, t.barrier_max_hp(1) - 1.0, 0.0)
	_check("damage: partial damage does not break", not broke and breaks.is_empty())
	_check("damage: hit emitted with fraction in (0,1)", hits.size() == 1 and hits[0][1] > 0.0 and hits[0][1] < 1.0)
	broke = t.damage_barrier(1, 5.0, 0.0)
	_check("damage: finishing blow breaks it", broke)
	_check("damage: broken emitted once with payout", breaks == [[1, 100]])
	_check("damage: further damage does nothing", not t.damage_barrier(1, 999.0, 0.0) and breaks.size() == 1)
	_check("damage: no longer alive", not t.barrier_alive(1))
	_check("damage: no longer collides", t.barrier_layer_in_rect(Rect2(0, 1280 - 6, 10, 12)) == -1)
	t.free()


func test_next_barrier_y() -> void:
	var t := _terrain()
	_check("next: first barrier below the surface", t.next_barrier_y(100.0) == 1280.0)
	_check("next: strictly below", t.next_barrier_y(1280.0) == 2560.0)
	t.damage_barrier(1, t.barrier_max_hp(1), 0.0)
	_check("next: skips a broken barrier", t.next_barrier_y(100.0) == 2560.0)
	t.free()


func test_spawn_clamp() -> void:
	var t := _terrain()
	_check("spawn: kept above the first unbroken barrier", t.clamp_spawn_y(5000.0, 100.0) == 1280.0 - 32.0)
	_check("spawn: still at least two tiles down", t.clamp_spawn_y(0.0, 100.0) == 64.0)
	t.damage_barrier(1, t.barrier_max_hp(1), 0.0)
	_check("spawn: limit moves down once the barrier breaks", t.clamp_spawn_y(5000.0, 100.0) == 2560.0 - 32.0)
	t.free()


func test_spawn_position_stays_off_screen() -> void:
	var t := _terrain()
	var player := Vector2(0.0, 1250.0) # digging just above barrier 1
	for angle in [PI * 0.5, PI * 0.45, PI * 0.2, 0.0]:
		var pos := t.spawn_position(player, angle, 700.0)
		_check("spawn pos: above the barrier (angle %.2f)" % angle, pos.y <= 1280.0 - 32.0)
		_check("spawn pos: far from the player (angle %.2f)" % angle, pos.distance_to(player) >= 600.0)
	t.free()
