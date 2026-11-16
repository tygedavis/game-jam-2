extends Node2D
## Minimal surface hub (placeholder shapes). Walk the dog to the drill and press Space to
## start a run. The owner and other hub contents come later (see docs/game-design.md).

const RUN_SCENE := "res://scenes/main.tscn"
## Screen-centred so the hub lines up with the run, where the camera centres the drill (720px tall view, drill 24px).
const GROUND_Y := 372.0
const DRILL_X := 640.0
const USE_RANGE := 90.0

@export var walk_speed := 220.0

var _dog_x := 300.0
var _facing := 1
var _prompt: Label
var _ground_color: Color = load("res://data/terrain_profile.tres").color_for_layer(0)


func _ready() -> void:
	var layer := CanvasLayer.new()
	_prompt = Label.new()
	_prompt.text = "Press SPACE to start digging"
	_prompt.position = Vector2(DRILL_X - 130.0, GROUND_Y - 80.0)
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
	draw_rect(Rect2(0, 0, size.x, GROUND_Y), Terrain.SKY_COLOR) # sky
	draw_rect(Rect2(0, GROUND_Y, size.x, size.y - GROUND_Y), _ground_color) # ground
	draw_rect(Rect2(0, GROUND_Y - Terrain.GRASS_HEIGHT, size.x, Terrain.GRASS_HEIGHT), Terrain.GRASS_COLOR) # grass (above the line, as in the run)
	# Drill vehicle (same colours as in-run).
	# Matches the in-run drill (24px body, nose pointing down) so the run starts right here.
	draw_rect(Rect2(DRILL_X - 12, GROUND_Y - 24, 24, 24), Color(0.95, 0.75, 0.2))
	draw_circle(Vector2(DRILL_X, GROUND_Y + 6), 6, Color(0.7, 0.7, 0.75))
	# Dog on foot: body, head and snout showing facing.
	draw_rect(Rect2(_dog_x - 14, GROUND_Y - 22, 28, 16), Color(0.7, 0.5, 0.3))
	draw_rect(Rect2(_dog_x + _facing * 12 - 7, GROUND_Y - 32, 14, 14), Color(0.7, 0.5, 0.3))
	draw_rect(Rect2(_dog_x + _facing * 20 - 4, GROUND_Y - 26, 8, 6), Color(0.3, 0.2, 0.1))
