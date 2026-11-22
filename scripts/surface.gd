@tool
extends Node2D
## Minimal surface hub. The scenery is drawn here; the characters are Sprite children (Drill, Owner, Dog)
## that artists can re-texture in the editor. (@tool so the sky and ground also show in the editor.)
## Walk the dog to the drill and press Space to start a run. The owner and other hub contents come later (see docs/game-design.md).

const RUN_SCENE := "res://scenes/main.tscn"
## Screen-centred so the hub lines up with the run, where the camera centres the drill (720px tall view, drill 24px).
const GROUND_Y := 372.0
const DRILL_X := 640.0
const USE_RANGE := 90.0
const OWNER_X := 160.0

@export var walk_speed := 220.0
## The upgrade items the owner sells (unlocks and upgrades). Edit the catalog .tres to stock the shop.
@export var catalog: ItemCatalog

var _dog_x := 300.0
var _facing := 1
var _prompt: Label
var _owner_prompt: Label
var _money: Label
var _shop: ShopMenu
var _ground_color: Color = load("res://data/terrain_profile.tres").color_for_layer(0)

@onready var _dog: Sprite2D = $Dog


func _ready() -> void:
	if Engine.is_editor_hint():
		queue_redraw()
		return
	var layer := CanvasLayer.new()
	_prompt = Label.new()
	_prompt.text = "Press SPACE to start digging"
	_prompt.position = Vector2(DRILL_X - 130.0, GROUND_Y - 80.0)
	layer.add_child(_prompt)
	_owner_prompt = Label.new()
	_owner_prompt.text = "Press SPACE to shop"
	_owner_prompt.position = Vector2(OWNER_X - 70.0, GROUND_Y - 100.0)
	layer.add_child(_owner_prompt)
	_money = Label.new()
	_money.position = Vector2(12, 32)
	layer.add_child(_money)
	var help := Label.new()
	help.text = "A / D or arrows: walk"
	help.position = Vector2(12, 8)
	layer.add_child(help)
	add_child(layer)
	_shop = ShopMenu.new()
	add_child(_shop)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_money.text = "Money: %d" % Save.money
	var dir := 0
	if not _shop.visible:
		dir = int(Input.is_physical_key_pressed(KEY_D) or Input.is_action_pressed("ui_right")) \
			- int(Input.is_physical_key_pressed(KEY_A) or Input.is_action_pressed("ui_left"))
	if dir != 0:
		_facing = dir
	_dog_x = clampf(_dog_x + dir * walk_speed * delta, 40.0, 1240.0)
	_dog.position.x = _dog_x
	_dog.flip_h = _facing < 0 # dog art faces right
	_prompt.visible = _near_drill() and not _shop.visible
	_owner_prompt.visible = _near_owner() and not _shop.visible
	queue_redraw()
	
	#Music player
	if $AudioStreamPlayer.playing == false:
		$AudioStreamPlayer.play()


func _unhandled_input(event: InputEvent) -> void:
	if _shop.visible or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if event.physical_keycode != KEY_SPACE:
		return
	# Space is always the interaction button.
	if _near_drill():
		get_tree().change_scene_to_file(RUN_SCENE)
	elif _near_owner():
		_shop.open(catalog)


func _near_owner() -> bool:
	return absf(_dog_x - OWNER_X) <= USE_RANGE


func _near_drill() -> bool:
	return absf(_dog_x - DRILL_X) <= USE_RANGE


func _draw() -> void:
	var size := get_viewport_rect().size
	if Engine.is_editor_hint():
		size = Vector2(ProjectSettings.get_setting("display/window/size/viewport_width"),
			ProjectSettings.get_setting("display/window/size/viewport_height"))
	draw_rect(Rect2(0, 0, size.x, GROUND_Y), Terrain.SKY_COLOR) # sky
	draw_rect(Rect2(0, GROUND_Y, size.x, size.y - GROUND_Y), _ground_color) # ground
	draw_rect(Rect2(0, GROUND_Y - Terrain.GRASS_HEIGHT, size.x, Terrain.GRASS_HEIGHT), Terrain.GRASS_COLOR) # grass
