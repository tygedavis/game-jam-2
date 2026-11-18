extends SceneTree
## Headless tests for the dev invincible and noclip flags on the Drill.
## Run: godot --headless --path . --script tests/dev_drill_test.gd

const WALL_TOP := 1280.0 - 6.0

var _failed := false
var _dev: Node


## Stands in for an enemy: just a solid rect in the "enemies" group.
class FakeEnemy:
	extends Node2D
	var box := Rect2()

	func rect() -> Rect2:
		return box


func _check(test_name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + test_name)
	if not ok:
		_failed = true


func _init() -> void:
	await process_frame
	_dev = root.get_node("DevMode")
	test_invincible()
	await test_noclip_passes_dirt_without_digging()
	await test_noclip_passes_barrier()
	test_noclip_still_blocked_by_enemies()
	test_normal_blocking_returns_when_noclip_off()
	_dev.set_flag(&"invincible", false)
	_dev.set_flag(&"noclip", false)
	quit(1 if _failed else 0)


## Plain dirt everywhere.
func _dirt_terrain() -> Terrain:
	var t := Terrain.new()
	t.profile = TerrainProfile.new()
	root.add_child(t)
	return t


## Dirt with an open pocket (rows 30..42, columns -3..3) around the first boundary.
func _pocket_terrain() -> Terrain:
	var t := _dirt_terrain()
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


func test_invincible() -> void:
	var t := _dirt_terrain()
	var d := _drill(t, Vector2(0, 100))
	var deaths := [0]
	d.died.connect(func() -> void: deaths[0] += 1)
	_dev.set_flag(&"invincible", true)
	d.take_damage(1000.0)
	_check("invincible: hp untouched", d.hp == d.max_hp)
	_check("invincible: no death", deaths[0] == 0)
	_dev.set_flag(&"invincible", false)
	d.take_damage(1000.0)
	_check("control: without invincible the same hit kills", deaths[0] == 1)
	d.queue_free()
	t.queue_free()


func test_noclip_passes_dirt_without_digging() -> void:
	var t := _dirt_terrain()
	var d := _drill(t, Vector2(16, 100))
	d.facing = Vector2i.DOWN
	_dev.set_flag(&"noclip", true)
	d._move_axis(Vector2(0, 50))
	_check("noclip: moved straight through dirt", is_equal_approx(d.position.y, 150.0))
	var cell := t.world_to_cell(d.position + Vector2(0, 24))
	for i in 5:
		await physics_frame
	_check("noclip: dirt ahead is not dug", t._hp_at(cell) == t.max_hp(cell.y))
	_dev.set_flag(&"noclip", false)
	d.queue_free()
	t.queue_free()


func test_noclip_passes_barrier() -> void:
	var t := _pocket_terrain()
	var d := _drill(t, Vector2(0, 1250))
	_dev.set_flag(&"noclip", true)
	d._move_axis(Vector2(0, 50))
	_check("noclip: crossed the barrier", d.position.y > WALL_TOP + 12.0)
	_check("noclip: barrier left intact", t.barrier_alive(1) and t.barrier_fraction(1) == 1.0)
	_dev.set_flag(&"noclip", false)
	d.queue_free()
	t.queue_free()


func test_noclip_still_blocked_by_enemies() -> void:
	var t := _dirt_terrain()
	var d := _drill(t, Vector2(16, 100))
	var e := FakeEnemy.new()
	e.box = Rect2(0, 130, 32, 32)
	root.add_child(e)
	e.add_to_group("enemies")
	_dev.set_flag(&"noclip", true)
	d._move_axis(Vector2(0, 50))
	_check("noclip: enemies stay solid", d.position.y < 130.0)
	_dev.set_flag(&"noclip", false)
	e.queue_free()
	d.queue_free()
	t.queue_free()


func test_normal_blocking_returns_when_noclip_off() -> void:
	var t := _pocket_terrain()
	var d := _drill(t, Vector2(0, 1250))
	_dev.set_flag(&"noclip", true)
	_dev.set_flag(&"noclip", false)
	d._move_axis(Vector2(0, 50))
	_check("noclip off: wall blocks again", d.position.y <= WALL_TOP - 12.0 + 0.01)
	d.queue_free()
	t.queue_free()
