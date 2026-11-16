class_name LevelUpMenu
extends CanvasLayer
## Pause-and-pick screen. Call offer() with the choices; emits chosen() when one is picked.

signal chosen(def: UpgradeDef)

var _choices: Array[UpgradeDef] = []
var _box: HBoxContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 10
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 16)
	center.add_child(col)
	var title := Label.new()
	title.text = "LEVEL UP - choose an upgrade (1/2/3)"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)
	_box = HBoxContainer.new()
	_box.add_theme_constant_override("separation", 16)
	col.add_child(_box)


func offer(choices: Array[UpgradeDef]) -> void:
	_choices = choices
	for child in _box.get_children():
		child.queue_free()
	for i in choices.size():
		var b := Button.new()
		b.text = "%d. %s\n%s" % [i + 1, choices[i].display_name, choices[i].description]
		b.custom_minimum_size = Vector2(200, 110)
		b.pressed.connect(choose.bind(i))
		_box.add_child(b)
		if i == 0:
			b.grab_focus.call_deferred()
	visible = true
	get_tree().paused = true


func choose(index: int) -> void:
	if not visible or index >= _choices.size():
		return
	visible = false
	get_tree().paused = false
	chosen.emit(_choices[index])


func _input(event: InputEvent) -> void:
	if not visible or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	match event.physical_keycode:
		KEY_1: choose(0)
		KEY_2: choose(1)
		KEY_3: choose(2)
