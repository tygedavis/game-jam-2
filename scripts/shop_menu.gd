class_name ShopMenu
extends CanvasLayer
## The owner's permanent-upgrade shop. Call open(); keys 1-9 buy, Space/Esc close.

signal closed

var _defs: Array[MetaUpgradeDef] = []
var _title: Label
var _box: VBoxContainer


func _ready() -> void:
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
	col.add_theme_constant_override("separation", 10)
	center.add_child(col)
	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_title)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 8)
	col.add_child(_box)
	var hint := Label.new()
	hint.text = "1-9 or click to buy    Space / Esc to leave"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(hint)


func open(defs: Array[MetaUpgradeDef]) -> void:
	_defs = defs
	visible = true
	_refresh()


func close() -> void:
	visible = false
	closed.emit()


func _refresh() -> void:
	_title.text = "THE OWNER'S SHOP    Money: %d" % Save.money
	for child in _box.get_children():
		child.queue_free()
	for i in _defs.size():
		var d := _defs[i]
		var b := Button.new()
		var status := "MAX" if Save.is_maxed(d) else "Cost %d" % Save.next_cost(d)
		b.text = "%d. %s   Lv %d/%d   %s   (%s)" % [i + 1, d.display_name,
			Save.level_of(d), d.max_level, d.description, status]
		b.custom_minimum_size = Vector2(560, 40)
		b.disabled = not Save.can_buy(d)
		b.pressed.connect(_buy.bind(i))
		_box.add_child(b)


func _buy(i: int) -> void:
	if i < _defs.size() and Save.buy(_defs[i]):
		_refresh()


func _input(event: InputEvent) -> void:
	if not visible or not (event is InputEventKey) or not event.pressed or event.echo:
		return
	get_viewport().set_input_as_handled()
	var key: int = event.physical_keycode
	if key == KEY_ESCAPE or key == KEY_SPACE:
		close()
	elif key >= KEY_1 and key <= KEY_9:
		_buy(key - KEY_1)
