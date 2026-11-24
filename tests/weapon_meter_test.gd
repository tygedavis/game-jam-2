extends SceneTree
## Headless tests for the secondary weapon HUD meter (issue #53).
## Run: godot --headless --path . --script tests/weapon_meter_test.gd

var _failed := false


func check(test_name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + test_name)
	if not ok:
		_failed = true


func _initialize() -> void:
	await process_frame
	var t := Terrain.new()
	t.profile = TerrainProfile.new()
	root.add_child(t)
	var d := Drill.new()
	var sprite := Node2D.new()
	sprite.name = "Sprite"
	d.add_child(sprite)
	d.terrain = t
	d.position = Vector2(16, 208)
	root.add_child(d)
	var meter := WeaponMeter.new()
	root.add_child(meter)
	meter.setup(d)
	await process_frame
	check("meter is hidden with no secondary", not meter.visible)
	d.equip(load("res://data/weapons/flamethrower.tres"))
	await process_frame
	check("meter shows once a secondary is equipped", meter.visible)
	check("meter shows full at the start", is_equal_approx(meter.shown_value(), 100.0))
	for i in 10:
		d.secondary.update(d, 0.1, true, Vector2.RIGHT)
	await process_frame
	check("meter drops as the weapon fires", meter.shown_value() < 60.0)
	quit(1 if _failed else 0)
