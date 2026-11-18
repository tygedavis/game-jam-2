class_name ShopMenu
extends CanvasLayer
## The owner's permanent-upgrade shop. Call open(); keys 1-9 buy, Space/Esc close.

signal closed

var _catalog: ItemCatalog
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


func open(catalog: ItemCatalog) -> void:
	_catalog = catalog
	visible = true
	_refresh()


func close() -> void:
	visible = false
	closed.emit()


## The text of one shop row. Locked items show their unlock price; unlocked ones show the level,
## the buff now and after the next upgrade, and the next upgrade price (or MAX).
static func row_text(def: UpgradeItemDef, unlocked: bool, level: int, _money: int) -> String:
	if not unlocked:
		return "%s   Unlock   Cost %d" % [def.display_name, def.unlock_cost]
	var status := "MAX" if level >= def.max_shop_level else "Cost %d" % def.cost_for(level)
	return "%s   Lv %d/%d   +%s -> +%s per pickup   %s" % [def.display_name, level,
		def.max_shop_level, _percent(def.buff_at_level(level)), _percent(def.buff_at_level(level + 1)), status]


static func _percent(fraction: float) -> String:
	var text := "%.1f" % (fraction * 100.0)
	if text.ends_with(".0"):
		text = text.trim_suffix(".0")
	return text + "%"


func _refresh() -> void:
	for child in _box.get_children():
		child.queue_free()
	if _catalog == null or _catalog.items.is_empty():
		_title.text = "THE OWNER'S SHOP"
		var empty := Label.new()
		empty.text = "Nothing for sale yet"
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_box.add_child(empty)
		return
	_title.text = "THE OWNER'S SHOP    Money: %d" % Save.money
	for i in _catalog.items.size():
		var d := _catalog.items[i]
		var unlocked := Save.is_unlocked(d)
		var b := Button.new()
		b.text = "%d. %s" % [i + 1, row_text(d, unlocked, Save.item_level_of(d), Save.money)]
		b.custom_minimum_size = Vector2(560, 40)
		b.disabled = not (Save.can_upgrade_item(d) if unlocked else Save.can_unlock(d))
		b.pressed.connect(_buy.bind(i))
		_box.add_child(b)


func _buy(i: int) -> void:
	if _catalog == null or i >= _catalog.items.size():
		return
	var d := _catalog.items[i]
	var ok := Save.upgrade_item(d) if Save.is_unlocked(d) else Save.unlock(d)
	if ok:
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
