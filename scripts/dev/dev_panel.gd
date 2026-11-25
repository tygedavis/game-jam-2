extends CanvasLayer
## The developer panel. Backtick opens and closes it, Esc closes it. While open the game is paused
## and everything is clickable (no function keys). Also shows a status line while any cheat is on.
## Lives in scripts/dev/, which production builds leave out; DevMode loads it by path.

## Controls by key, so tests can drive them: invincible, noclip, infinite_money, spawning_paused,
## skip_down, skip_up, kill, item_list, give, weapon_list, equip, status.
var controls := {}

## The weapons listed in weapon_list, in order.
var _weapons: Array[WeaponDef] = []

var _open := false
## True if opening the panel is what paused the game. Closing then unpauses it; if something else
## (the return prompt, the results screen) had paused it, that thing owns the unpausing.
var _paused_by_us := false
var _window: Control


func _init() -> void:
	name = "DevPanel"


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	DevMode.changed.connect(_refresh)
	set_open(false)


func is_open() -> bool:
	return _open


## Shows or hides the panel. Opening pauses the game (if it is not paused already); closing
## unpauses it only if the panel was what paused it.
func set_open(open: bool) -> void:
	if open == _open and _window != null and _window.visible == open:
		return
	if open and not _open:
		_paused_by_us = not get_tree().paused
		get_tree().paused = true
	elif not open and _open:
		_release_pause()
	_open = open
	_window.visible = open
	if open:
		_fill_items()
		_fill_weapons()
	_refresh()


func _release_pause() -> void:
	if _paused_by_us and get_tree() != null:
		get_tree().paused = false
	_paused_by_us = false


func _exit_tree() -> void:
	if _open:
		_release_pause()
		_open = false


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var key: int = event.physical_keycode
	if key == KEY_QUOTELEFT:
		set_open(not _open)
		get_viewport().set_input_as_handled()
	elif key == KEY_ESCAPE and _open:
		set_open(false)
		get_viewport().set_input_as_handled()


func _build() -> void:
	var status := Label.new()
	status.position = Vector2(12, 684)
	status.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))
	add_child(status)
	controls["status"] = status

	_window = PanelContainer.new()
	_window.position = Vector2(12, 40)
	add_child(_window)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	_window.add_child(col)
	var title := Label.new()
	title.text = "DEVELOPER MODE    ` or Esc to close"
	col.add_child(title)
	_add_toggle(col, "invincible", "Invincible", func(on: bool) -> void: DevMode.set_flag(&"invincible", on))
	_add_toggle(col, "noclip", "Noclip (through dirt and barriers)", func(on: bool) -> void: DevMode.set_flag(&"noclip", on))
	_add_toggle(col, "infinite_money", "Infinite money (session only, never saved)", DevMode.set_infinite_money)
	_add_toggle(col, "spawning_paused", "Pause enemy spawning", func(on: bool) -> void: DevMode.set_flag(&"spawning_paused", on))
	col.add_child(HSeparator.new())
	_add_button(col, "skip_down", "Skip layer down (breaks the barrier)", func() -> void: DevActions.skip_layer(DevMode.run, 1))
	_add_button(col, "skip_up", "Skip layer up", func() -> void: DevActions.skip_layer(DevMode.run, -1))
	_add_button(col, "kill", "Kill all enemies", func() -> void: DevActions.kill_enemies(DevMode.run))
	var row := HBoxContainer.new()
	col.add_child(row)
	var list := OptionButton.new()
	list.custom_minimum_size = Vector2(260, 0)
	row.add_child(list)
	controls["item_list"] = list
	_add_button(row, "give", "Give 1 stack", _give_selected)
	var weapon_row := HBoxContainer.new()
	col.add_child(weapon_row)
	var weapons := OptionButton.new()
	weapons.custom_minimum_size = Vector2(260, 0)
	weapon_row.add_child(weapons)
	controls["weapon_list"] = weapons
	_add_button(weapon_row, "equip", "Equip weapon", _equip_selected)


func _add_toggle(parent: Node, key: String, text: String, on_toggled: Callable) -> void:
	var b := CheckButton.new()
	b.text = text
	b.toggled.connect(on_toggled)
	parent.add_child(b)
	controls[key] = b


func _add_button(parent: Node, key: String, text: String, on_pressed: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.pressed.connect(on_pressed)
	parent.add_child(b)
	controls[key] = b


func _give_selected() -> void:
	var run: Node = DevMode.run
	var list: OptionButton = controls["item_list"]
	if run == null or list.selected < 0:
		return
	DevActions.give_item(run, run.catalog.items[list.selected])


func _equip_selected() -> void:
	var list: OptionButton = controls["weapon_list"]
	if list.selected < 0 or list.selected >= _weapons.size():
		return
	DevActions.equip_weapon(DevMode.run, _weapons[list.selected])


func _fill_weapons() -> void:
	var list: OptionButton = controls["weapon_list"]
	list.clear()
	_weapons.clear()
	for def in WeaponCatalog.all():
		_weapons.append(def)
		list.add_item("%s (%s)" % [def.display_name, "secondary" if def.slot == WeaponDef.SLOT_SECONDARY else "primary"])


func _fill_items() -> void:
	var list: OptionButton = controls["item_list"]
	list.clear()
	var run: Node = DevMode.run
	if run == null or run.catalog == null:
		return
	for def in run.catalog.items:
		list.add_item(def.display_name)


## Syncs the toggles with DevMode, enables the run-only controls only during a run, and shows or
## hides the status line.
func _refresh() -> void:
	for key in ["invincible", "noclip", "infinite_money", "spawning_paused"]:
		(controls[key] as CheckButton).set_pressed_no_signal(DevMode.get(key))
	var in_run := DevMode.run != null
	for key in ["skip_down", "skip_up", "kill", "give", "equip"]:
		(controls[key] as Button).disabled = not in_run
	(controls["item_list"] as OptionButton).disabled = not in_run
	(controls["weapon_list"] as OptionButton).disabled = not in_run
	var status: Label = controls["status"]
	status.text = DevMode.status_text()
	status.visible = status.text != ""
