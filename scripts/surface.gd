extends Node2D
## Minimal surface hub (placeholder shapes). Walk the dog to the drill and press Space to
## start a run. The owner and other hub contents come later (see docs/game-design.md).

const RUN_SCENE := "res://scenes/main.tscn"
const GROUND_Y := 500.0
const DRILL_X := 900.0
const USE_RANGE := 90.0

@export var walk_speed := 220.0

var _dog_x := 300.0
var _facing := 1
var _prompt: Label


func _ready() -> void:
	var layer := CanvasLayer.new()
	_prompt = Label.new()
	_prompt.text = "Press SPACE to start digging"
	_prompt.position = Vector2(DRILL_X - 130.0, GROUND_Y - 110.0)
	layer.add_child(_prompt)
	var help := Label.new()
	help.text = "A / D or arrows: walk"
	help.position = Vector2(12, 8)
	layer.add_child(help)
	add_child(layer)


func _process(delta: float) -> void:
	var dir := int(Input.is_physical_key_pressed(KEY_D) or Input.is_action_pressed("ui_right")) \
		- int(Input.is_physical_key_pressed(KEY_A) or Input.is_action_pressed("ui_left"))
	if dir != 0:
		_facing = dir
	_dog_x = clampf(_dog_x + dir * walk_speed * delta, 40.0, 1240.0)
	_prompt.visible = _near_drill()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo \
			and event.physical_keycode == KEY_SPACE and _near_drill():
		get_tree().change_scene_to_file(RUN_SCENE)


func _near_drill() -> bool:
	return absf(_dog_x - DRILL_X) <= USE_RANGE


func _draw() -> void:
	var size := get_viewport_rect().size
	draw_rect(Rect2(0, 0, size.x, GROUND_Y), Color(0.55, 0.75, 0.9)) # sky
	draw_rect(Rect2(0, GROUND_Y, size.x, size.y - GROUND_Y), Color(0.55, 0.36, 0.2)) # ground
	draw_rect(Rect2(0, GROUND_Y, size.x, 10), Color(0.3, 0.6, 0.3)) # grass
	# Drill vehicle (same colours as in-run).
	draw_rect(Rect2(DRILL_X - 24, GROUND_Y - 48, 48, 48), Color(0.95, 0.75, 0.2))
	draw_circle(Vector2(DRILL_X, GROUND_Y + 6), 12, Color(0.7, 0.7, 0.75))
	# Dog on foot: body, head and snout showing facing.
	draw_rect(Rect2(_dog_x - 14, GROUND_Y - 22, 28, 16), Color(0.7, 0.5, 0.3))
	draw_rect(Rect2(_dog_x + _facing * 12 - 7, GROUND_Y - 32, 14, 14), Color(0.7, 0.5, 0.3))
	draw_rect(Rect2(_dog_x + _facing * 20 - 4, GROUND_Y - 26, 8, 6), Color(0.3, 0.2, 0.1))
