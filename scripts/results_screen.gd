class_name ResultsScreen
extends CanvasLayer
## End-of-run summary. Pauses the game; emits retry when the player continues.

signal retry

## Keys are ignored for this long after the screen opens, so a double-tap of Space (confirm the
## return prompt, then continue) can't skip the summary.
const KEY_DELAY_MSEC := 300

var _label: Label
var _opened_at_msec := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 20
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.75)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 20)
	center.add_child(col)
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_label)
	var button := Button.new()
	button.text = "Return to surface (Space)"
	button.pressed.connect(func() -> void: retry.emit())
	col.add_child(button)
	button.grab_focus.call_deferred()


func show_results(text: String) -> void:
	_label.text = text
	visible = true
	_opened_at_msec = Time.get_ticks_msec()
	get_tree().paused = true


func _input(event: InputEvent) -> void:
	if visible and Time.get_ticks_msec() - _opened_at_msec >= KEY_DELAY_MSEC and event is InputEventKey and event.pressed and not event.echo \
			and event.physical_keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
		get_viewport().set_input_as_handled()
		retry.emit()
