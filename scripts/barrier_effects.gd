class_name BarrierEffects
extends Node2D
## All the feedback for hitting and breaking layer barriers: flash, sparks, screen shake, hit-stop,
## particle bursts, coin shower and the "+money" popup. Logic never depends on this node, so the
## visuals can be swapped or tuned freely. Call setup() once, then on_hit() / on_break().

## Tuning (start values, adjust by feel).
const HIT_FLASH_TIME := 0.06
const HIT_SHAKE_MIN := 1.0
const HIT_SHAKE_MAX := 6.0
const HIT_SHAKE_TIME := 0.15
const BREAK_SHAKE := 14.0
const BREAK_SHAKE_TIME := 0.5
const HIT_STOP_SCALE := 0.05
const HIT_STOP_TIME := 0.12 # real seconds
const BREAK_PARTICLES := 80
const COIN_PARTICLES := 30
const POPUP_TIME := 1.0
## Digging reports a hit every frame; sparks fire at most this often (seconds).
const SPARK_INTERVAL := 0.1

var _camera: Camera2D
var _terrain: Terrain
var _shake := 0.0
var _shake_time := 0.0
var _shake_total := 0.01
var _flash := 0.0
var _flash_y := 0.0
var _spark_cooldown := 0.0
var _popup_layer := CanvasLayer.new()


func setup(camera: Camera2D, terrain: Terrain) -> void:
	_camera = camera
	_terrain = terrain
	add_child(_popup_layer)


func _exit_tree() -> void:
	Engine.time_scale = 1.0 # never leave the game in slow motion


func _process(delta: float) -> void:
	_flash = maxf(_flash - delta, 0.0)
	_spark_cooldown = maxf(_spark_cooldown - delta, 0.0)
	_shake_time = maxf(_shake_time - delta, 0.0)
	var strength := _shake * (_shake_time / _shake_total)
	_camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * strength
	queue_redraw()


func _draw() -> void:
	if _flash <= 0.0 or _camera == null:
		return
	var half_width := get_viewport_rect().size.x
	var half := _terrain.barrier_thickness * 0.5
	draw_rect(Rect2(_camera.position.x - half_width, _flash_y - half, half_width * 2.0, half * 2.0),
		Color(1, 1, 1, _flash / HIT_FLASH_TIME))


## The wall took a hit. `fraction` is its remaining HP (1 = untouched); shaking grows as it weakens.
func on_hit(fraction: float, at: Vector2) -> void:
	_flash = HIT_FLASH_TIME
	_flash_y = at.y
	_add_shake(lerpf(HIT_SHAKE_MIN, HIT_SHAKE_MAX, 1.0 - fraction), HIT_SHAKE_TIME)
	if _spark_cooldown <= 0.0:
		_spark_cooldown = SPARK_INTERVAL
		_burst(at, 5, Color(1.0, 0.9, 0.5), 140.0, 0.3, Vector2(0, 300), 0.0)


## The wall broke: the big moment.
func on_break(payout: int, at: Vector2) -> void:
	_add_shake(BREAK_SHAKE, BREAK_SHAKE_TIME)
	_hit_stop()
	var width := get_viewport_rect().size.x
	_burst(at, BREAK_PARTICLES, Color(0.85, 0.85, 0.95), 420.0, 0.9, Vector2(0, 500), width * 0.5)
	_burst(at, COIN_PARTICLES, Color(1.0, 0.82, 0.2), 320.0, 1.4, Vector2(0, 900), width * 0.3)
	_popup(payout)


func _add_shake(amount: float, time: float) -> void:
	if amount >= _shake * (_shake_time / _shake_total):
		_shake = amount
		_shake_total = time
		_shake_time = time


func _hit_stop() -> void:
	Engine.time_scale = HIT_STOP_SCALE
	# process_always, process_in_physics, ignore_time_scale: counts real seconds.
	await get_tree().create_timer(HIT_STOP_TIME, true, false, true).timeout
	Engine.time_scale = 1.0


func _burst(at: Vector2, count: int, color: Color, speed: float, life: float, gravity: Vector2, spread_x: float) -> void:
	var p := CPUParticles2D.new()
	p.position = at
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = count
	p.lifetime = life
	p.color = color
	p.direction = Vector2.UP
	p.spread = 180.0
	p.initial_velocity_min = speed * 0.4
	p.initial_velocity_max = speed
	p.gravity = gravity
	p.scale_amount_min = 2.0
	p.scale_amount_max = 5.0
	if spread_x > 0.0:
		p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		p.emission_rect_extents = Vector2(spread_x, 4.0)
	add_child(p)
	p.emitting = true
	get_tree().create_timer(life + 0.5, true, false, true).timeout.connect(p.queue_free)


func _popup(payout: int) -> void:
	var label := Label.new()
	label.text = "+%d" % payout
	label.add_theme_font_size_override("font_size", 72)
	label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	label.add_theme_color_override("font_outline_color", Color(0.25, 0.1, 0.0))
	label.add_theme_constant_override("outline_size", 12)
	_popup_layer.add_child(label)
	var size := get_viewport_rect().size
	label.size = label.get_minimum_size()
	label.pivot_offset = label.size * 0.5
	label.position = Vector2(size.x * 0.5, size.y * 0.35) - label.pivot_offset
	label.scale = Vector2(0.3, 0.3)
	var tween := create_tween().set_ignore_time_scale(true)
	tween.tween_property(label, "scale", Vector2(1.3, 1.3), POPUP_TIME * 0.25) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "position:y", label.position.y - 60.0, POPUP_TIME * 0.75)
	tween.parallel().tween_property(label, "modulate:a", 0.0, POPUP_TIME * 0.75).set_delay(POPUP_TIME * 0.1)
	tween.tween_callback(label.queue_free)
