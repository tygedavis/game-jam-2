class_name ReturnPrompt
extends CanvasLayer
## "Return to the surface?" confirmation. Pauses the game while open; the owner decides what
## happens next from the confirmed / declined signals (it does not unpause itself).

signal confirmed
signal declined


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
	var go := Button.new()
	go.text = "Return (Space)"
	go.pressed.connect(_confirm)
	col.add_child(go)
	var stay := Button.new()
	stay.text = "Keep digging (Esc)"
	stay.pressed.connect(_decline)
	col.add_child(stay)
	go.grab_focus.call_deferred()


func open() -> void:
	visible = true
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
