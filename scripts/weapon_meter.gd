class_name WeaponMeter
extends Control
## HUD meter for the secondary weapon: its name and a bar driven by the limiter's 0-1 fraction.
## Hidden while no secondary is equipped. Works for any limiter, so new weapons need no HUD changes.

var _drill: Drill
var _bar := ProgressBar.new()
var _label := Label.new()
var _equipped: WeaponDef


func setup(drill: Drill) -> void:
	_drill = drill
	custom_minimum_size = Vector2(180, 36)
	_label.position = Vector2.ZERO
	add_child(_label)
	_bar.position = Vector2(0, 20)
	_bar.custom_minimum_size = Vector2(180, 12)
	_bar.max_value = 100.0
	_bar.show_percentage = false
	add_child(_bar)
	visible = false


func shown_value() -> float:
	return _bar.value


func _process(_delta: float) -> void:
	if _drill == null or _drill.secondary == null:
		visible = false
		return
	visible = true
	var weapon := _drill.secondary
	if weapon.def != _equipped:
		_equipped = weapon.def
		_label.text = weapon.def.display_name
		_bar.modulate = weapon.def.color
	_bar.value = weapon.limiter.fraction() * 100.0
