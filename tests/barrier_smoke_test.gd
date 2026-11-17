extends SceneTree
## Smoke test on the real run scene: hit and break the first barrier, check payout, and that
## hit-stop restores the time scale. Needs the project's autoloads, so run it with the scene:
## godot --headless --path . --script tests/barrier_smoke_test.gd

var _failed := false


func _check(name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + name)
	if not ok:
		_failed = true


func _init() -> void:
	await process_frame
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var terrain: Terrain = main.get_node("Terrain")
	var before: int = main._gem_value
	terrain.damage_barrier(1, terrain.barrier_max_hp(1) * 0.5, 0.0)
	await process_frame
	terrain.damage_barrier(1, terrain.barrier_max_hp(1), 0.0)
	await process_frame
	_check("smoke: payout added to gem value", main._gem_value == before + terrain.barrier_payout(1))
	_check("smoke: hit-stop slows time", Engine.time_scale < 1.0)
	await create_timer(0.5, true, false, true).timeout
	_check("smoke: time scale restored", Engine.time_scale == 1.0)
	quit(1 if _failed else 0)
