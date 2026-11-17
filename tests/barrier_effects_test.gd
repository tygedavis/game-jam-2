extends SceneTree
## Headless tests for BarrierEffects.
## Run: godot --headless --path . --script tests/barrier_effects_test.gd

var _failed := false


func _init() -> void:
	await test_flash_is_translucent_and_throttled()
	quit(1 if _failed else 0)


func _check(name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + name)
	if not ok:
		_failed = true


func test_flash_is_translucent_and_throttled() -> void:
	var terrain := Terrain.new()
	terrain.profile = TerrainProfile.new()
	root.add_child(terrain)
	var camera := Camera2D.new()
	root.add_child(camera)
	var fx := BarrierEffects.new()
	root.add_child(fx)
	await process_frame
	fx.setup(camera, terrain)
	fx.on_hit(0.5, Vector2(0, 1280))
	_check("flash: never fully opaque, so the damage tint shows", fx.flash_alpha() > 0.0 and fx.flash_alpha() <= 0.4)
	fx._process(0.07) # flash expires; the spark throttle is still running
	fx.on_hit(0.5, Vector2(0, 1280)) # digging reports a hit every frame
	_check("flash: hits inside the throttle window do not re-flash", fx.flash_alpha() == 0.0)
	fx.queue_free()
	camera.queue_free()
	terrain.queue_free()
