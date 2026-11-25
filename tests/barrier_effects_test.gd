extends SceneTree
## Headless tests for BarrierEffects.
## Run: godot --headless --path . --script tests/barrier_effects_test.gd

var _failed := false


func _init() -> void:
	await test_flash_is_translucent_and_throttled()
	await test_pause_recentres_camera_and_particles_keep_running()
	await test_hit_stop_survives_free()
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


func _make_fx() -> Array:
	var terrain := Terrain.new()
	terrain.profile = TerrainProfile.new()
	root.add_child(terrain)
	var camera := Camera2D.new()
	root.add_child(camera)
	var fx := BarrierEffects.new()
	fx.setup(camera, terrain) # before entering the tree, so _process never sees a null camera
	root.add_child(fx)
	await process_frame
	return [fx, camera, terrain]


func test_pause_recentres_camera_and_particles_keep_running() -> void:
	var nodes := await _make_fx()
	var fx: BarrierEffects = nodes[0]
	var camera: Camera2D = nodes[1]
	fx.on_break(100, Vector2(0, 1280))
	fx._process(0.016)
	_check("pause: break shake moves the camera", camera.offset != Vector2.ZERO)
	paused = true # level-up menu opens mid-shake
	await process_frame
	_check("pause: camera recentred while paused", camera.offset == Vector2.ZERO)
	var particles := fx.find_children("*", "CPUParticles2D", false, false)
	_check("pause: break made particle bursts", particles.size() >= 2)
	var all_run := particles.all(func(p: Node) -> bool: return p.can_process())
	_check("pause: particles keep simulating while paused", all_run)
	paused = false
	fx._process(0.016)
	_check("pause: shake does not resume after unpausing", camera.offset == Vector2.ZERO)
	for n in nodes:
		n.queue_free()
	await create_timer(0.2, true, false, true).timeout # let the hit-stop finish
	Engine.time_scale = 1.0


func test_hit_stop_survives_free() -> void:
	var nodes := await _make_fx()
	var fx: BarrierEffects = nodes[0]
	fx.on_break(100, Vector2(0, 1280))
	_check("hit-stop: slows time on a break", Engine.time_scale < 1.0)
	fx.free() # scene change during the hit-stop window
	_check("hit-stop: freeing restores time scale", Engine.time_scale == 1.0)
	await create_timer(BarrierEffects.HIT_STOP_TIME + 0.1, true, false, true).timeout
	_check("hit-stop: timer firing after free leaves time scale alone", Engine.time_scale == 1.0)
	nodes[1].queue_free()
	nodes[2].queue_free()
