extends SceneTree
## Headless tests: barriers block and take damage from the drill and shots.
## Run: godot --headless --path . --script tests/barrier_collision_test.gd

const WALL_TOP := 1280.0 - 6.0

var _failed := false


func _init() -> void:
	await test_projectile_damages_and_stops()
	await test_projectile_breaks_barrier()
	await test_drill_blocked_and_digs()
	await test_drill_moves_through_after_break()
	await test_drill_overlapping_breaks_free()
	quit(1 if _failed else 0)


func _check(name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + name)
	if not ok:
		_failed = true


## A terrain with an open pocket (rows 30..42, columns -3..3) around the first boundary.
func _terrain() -> Terrain:
	var t := Terrain.new()
	t.profile = TerrainProfile.new()
	root.add_child(t)
	for y in range(30, 43):
		for x in range(-3, 4):
			t.damage(Vector2i(x, y), 1.0e9)
	return t


func _drill(t: Terrain, pos: Vector2) -> Drill:
	var d := Drill.new()
	var sprite := Node2D.new()
	sprite.name = "Sprite"
	d.add_child(sprite)
	d.terrain = t
	d.position = pos
	root.add_child(d)
	return d


func _shoot(t: Terrain, damage: float) -> Projectile:
	var p := Projectile.new()
	p.setup(t, Vector2(0, 1200), Vector2.DOWN, 6000.0, damage)
	root.add_child(p)
	return p


func test_projectile_damages_and_stops() -> void:
	var t := _terrain()
	var fractions := []
	t.barrier_hit.connect(func(_l: int, f: float, _a: Vector2) -> void: fractions.append(f))
	var p := _shoot(t, 20.0)
	for i in 5:
		await physics_frame
	_check("projectile: stopped at the wall", not is_instance_valid(p))
	_check("projectile: wall took damage", fractions.size() == 1 and fractions[0] < 1.0)
	t.queue_free()


func test_projectile_breaks_barrier() -> void:
	var t := _terrain()
	var broke := []
	t.barrier_broken.connect(func(l: int, _p: int, _a: Vector2) -> void: broke.append(l))
	_shoot(t, t.barrier_max_hp(1))
	for i in 5:
		await physics_frame
	_check("projectile: one big shot breaks the barrier", broke == [1])
	t.queue_free()


func test_drill_blocked_and_digs() -> void:
	var t := _terrain()
	var d := _drill(t, Vector2(0, 1250))
	d.facing = Vector2i.DOWN
	d._move_axis(Vector2(0, 50))
	_check("drill: stopped flush above the wall", d.position.y <= WALL_TOP - 12.0 + 0.01 and d.position.y > WALL_TOP - 14.0)
	for i in 10:
		await physics_frame
	_check("drill: digging damages the wall", t.barrier_fraction(1) < 1.0)
	d.queue_free()
	t.queue_free()


func test_drill_moves_through_after_break() -> void:
	var t := _terrain()
	var d := _drill(t, Vector2(0, 1250))
	d.facing = Vector2i.DOWN
	d._move_axis(Vector2(0, 50))
	t.damage_barrier(1, t.barrier_max_hp(1), 0.0)
	d._move_axis(Vector2(0, 30))
	_check("drill: passes the broken barrier", d.position.y > 1280.0)
	d.queue_free()
	t.queue_free()


func test_drill_overlapping_breaks_free() -> void:
	var t := _terrain()
	var d := _drill(t, Vector2(0, 1280))
	t.damage_barrier(1, t.barrier_max_hp(1), 0.0)
	var before := d.position.y
	d._move_axis(Vector2(0, 10))
	_check("drill: not stuck after the overlapped barrier breaks", d.position.y > before)
	d.queue_free()
	t.queue_free()
