extends SceneTree
## Headless tests for the flamethrower secondary (issue #53).
## Run: godot --headless --path . --script tests/flamethrower_test.gd

var _failed := false
var _gems := 0
var _items := 0


class FakeEnemy:
	extends Node2D
	var box := Rect2()
	var taken := 0.0

	func rect() -> Rect2:
		return box

	func take_damage(amount: float) -> void:
		taken += amount


func check(test_name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + test_name)
	if not ok:
		_failed = true


func _initialize() -> void:
	await process_frame
	_test_dirt_and_cone()
	_test_enemies()
	_test_gems_and_items_not_collected()
	_test_barrier()
	_test_edge_cases()
	_test_fuel()
	quit(1 if _failed else 0)


func _terrain() -> Terrain:
	var t := Terrain.new()
	t.profile = TerrainProfile.new()
	t.gem_chance = 0.0
	t.upgrade_chance = 0.0
	root.add_child(t)
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


## A flame hot enough to break any dirt tile in one step, with test-chosen reach.
func _weapon(range_px := 100.0, dirt := 1.0e6, enemy := 100.0) -> Weapon:
	var def: WeaponDef = load("res://data/weapons/flamethrower.tres").duplicate(true)
	var b := def.behavior as FlamethrowerBehavior
	b.range_px = range_px
	b.dirt_damage_per_second = dirt
	b.enemy_damage_per_second = enemy
	return Weapon.create(def)


func _test_dirt_and_cone() -> void:
	var t := _terrain()
	var d := _drill(t, Vector2(16, 208))
	var w := _weapon()
	w.update(d, 1.0, true, Vector2.RIGHT)
	check("flame burns dirt in range ahead", not t.is_dirt(Vector2i(1, 6)) and not t.is_dirt(Vector2i(2, 6)))
	check("flame goes through dirt (not only the first tile)", not t.is_dirt(Vector2i(2, 6)))
	check("dirt beyond range is untouched", t.is_dirt(Vector2i(5, 6)))
	check("dirt outside the cone is untouched", t.is_dirt(Vector2i(2, 9)) and t.is_dirt(Vector2i(2, 3)))
	check("dirt behind the drill is untouched", t.is_dirt(Vector2i(-2, 6)))


func _test_enemies() -> void:
	var t := _terrain()
	var d := _drill(t, Vector2(16, 208))
	var inside := FakeEnemy.new()
	inside.box = Rect2(Vector2(60, 200), Vector2(16, 16))
	var outside := FakeEnemy.new()
	outside.box = Rect2(Vector2(60, 300), Vector2(16, 16))
	for e in [inside, outside]:
		e.add_to_group("enemies")
		root.add_child(e)
	_weapon().update(d, 0.5, true, Vector2.RIGHT)
	check("flame hurts an enemy in the cone", is_equal_approx(inside.taken, 50.0))
	check("flame ignores an enemy outside the cone", outside.taken == 0.0)
	inside.queue_free()
	outside.queue_free()


func _test_gems_and_items_not_collected() -> void:
	var t := _terrain()
	t.gem_chance = 1.0
	t.gem_defs = [GemDef.new()] as Array[GemDef]
	t.gem_collected.connect(func(_def: GemDef) -> void: _gems += 1)
	var d := _drill(t, Vector2(16, 208))
	var w := _weapon()
	w.update(d, 1.0, true, Vector2.RIGHT) # breaks the dirt, exposing gems
	var cell := Vector2i(1, 6)
	check("flame breaks the dirt over a gem", not t.is_dirt(cell) and t.gem_exposed(cell))
	w.update(d, 1.0, true, Vector2.RIGHT)
	w.limiter.update(10.0, false)
	w.update(d, 1.0, true, Vector2.RIGHT)
	check("flame never damages or collects an exposed gem", _gems == 0 and is_equal_approx(t.gem_fraction(cell), 1.0))

	var t2 := _terrain()
	t2.upgrade_chance = 1.0
	var item := UpgradeItemDef.new()
	t2.upgrade_defs = [item] as Array[UpgradeItemDef]
	t2.upgrade_collected.connect(func(_def: UpgradeItemDef) -> void: _items += 1)
	var d2 := _drill(t2, Vector2(16, 208))
	_weapon().update(d2, 1.0, true, Vector2.RIGHT)
	check("flame leaves dirt holding an upgrade item alone", t2.is_dirt(Vector2i(1, 6)) and _items == 0)


func _test_barrier() -> void:
	var t := _terrain()
	for y in range(30, 39): # open air above the barrier; rows 41+ below it stay dirt
		for x in range(-3, 4):
			t.damage(Vector2i(x, y), 1.0e9)
	var d := _drill(t, Vector2(0, 1200))
	check("control: dirt below the barrier exists", t.is_dirt(Vector2i(0, 41)))
	var wall_hp := t.barrier_fraction(1)
	_weapon(200.0).update(d, 1.0, true, Vector2.DOWN)
	check("barrier is still alive after flame", t.barrier_alive(1))
	check("barrier health is unchanged", is_equal_approx(t.barrier_fraction(1), wall_hp))
	check("dirt past an unbroken barrier is untouched", t.is_dirt(Vector2i(0, 41)))


func _test_edge_cases() -> void:
	var t := _terrain()
	var up := _drill(t, Vector2(0, -12))
	_weapon().update(up, 1.0, true, Vector2.UP)
	check("flame aimed up from the surface does not error", true)
	var zero := _drill(t, Vector2(16, 208))
	zero.facing = Vector2i.RIGHT
	_weapon().update(zero, 1.0, true, Vector2.ZERO)
	check("zero aim falls back to the facing direction", not t.is_dirt(Vector2i(1, 6)))


func _test_fuel() -> void:
	var t := _terrain()
	var d := _drill(t, Vector2(16, 208))
	var w := Weapon.create(load("res://data/weapons/flamethrower.tres"))
	var steps := 0
	while w.limiter.update(0.1, true) and steps < 100:
		steps += 1
	check("flame stops after about 2 s of fuel", steps >= 18 and steps <= 22)
	check("fuel meter reads near empty", w.limiter.fraction() < 0.1)
	d.queue_free()
