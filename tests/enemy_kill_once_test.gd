extends SceneTree
## Headless tests that an enemy dies exactly once, even if hit again before it is freed.
## Run: godot --headless --path . --script tests/enemy_kill_once_test.gd

var _failed := false


func _init() -> void:
	await process_frame
	test_killed_emits_once()
	test_projectile_skips_dying_enemy()
	quit(1 if _failed else 0)


func _check(name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + name)
	if not ok:
		_failed = true


func _enemy() -> Enemy:
	var e := Enemy.new()
	var d := EnemyDef.new()
	d.max_hp = 10.0
	e.setup(d, null, null)
	return e


func test_killed_emits_once() -> void:
	var e := _enemy()
	var kills := []
	e.killed.connect(func(_def: EnemyDef, at: Vector2) -> void: kills.append(at))
	e.take_damage(4.0)
	_check("kill: partial damage does not kill", kills.is_empty())
	e.take_damage(10.0)
	_check("kill: lethal damage emits killed", kills.size() == 1)
	_check("kill: enemy is queued for deletion", e.is_queued_for_deletion())
	e.take_damage(10.0)
	_check("kill: a second hit before free does not emit again", kills.size() == 1)


func test_projectile_skips_dying_enemy() -> void:
	var t := Terrain.new()
	t.profile = TerrainProfile.new()
	# Up in the sky so the shot can't hit dirt instead.
	var at := Vector2(100, -100)
	var e := _enemy()
	e.terrain = t
	e.position = at
	var sprite := AutoSprite.new()
	sprite.name = "Sprite"
	e.add_child(sprite)
	e.set_physics_process(false)
	root.add_child(e)
	var kills := []
	e.killed.connect(func(_def: EnemyDef, pos: Vector2) -> void: kills.append(pos))
	var p := Projectile.new()
	p.setup(t, at, Vector2.RIGHT, 0.0, 1.0)
	root.add_child(p)
	_check("projectile: hits a live enemy", p._hit_something() and is_equal_approx(e.hp, 9.0))
	e.take_damage(10.0)
	_check("projectile: does not hit an enemy queued for deletion", not p._hit_something())
	_check("projectile: killed still emitted only once", kills.size() == 1)
	p.free()
	e.free()
	t.free()
