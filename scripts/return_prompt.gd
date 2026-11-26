class_name ReturnPrompt
extends CanvasLayer
## "Return to the surface?" confirmation. Pauses the game while open; the owner decides what
## happens next from the confirmed / declined signals (it does not unpause itself).

signal confirmed
signal declined

var _return_button: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 20
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 20)
	center.add_child(col)
	var label := Label.new()
	label.text = "Return to the surface?"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(label)
	_return_button = Button.new()
	_return_button.text = "Return (Space)"
	_return_button.pressed.connect(_confirm)
	col.add_child(_return_button)
	var stay := Button.new()
	stay.text = "Keep digging (Esc)"
	stay.pressed.connect(_decline)
	col.add_child(stay)


func open() -> void:
	visible = true
	# Focus only once shown: a hidden control can't hold focus, so grabbing it in _ready() did nothing.
	_return_button.grab_focus()
	get_tree().paused = true


func _confirm() -> void:
	visible = false
	confirmed.emit()


func _decline() -> void:
	visible = false
	declined.emit()


func _input(event: InputEvent) -> void:
	if not visible or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if event.physical_keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
		get_viewport().set_input_as_handled()
		_confirm()
	elif event.physical_keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_decline()
