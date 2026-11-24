extends SceneTree
## Headless tests for the developer panel: opening and closing, pausing, toggles, status line,
## run-only controls, and cleanup. Uses the panel DevMode adds to itself on startup.
## Run: godot --headless --path . --script tests/dev_panel_test.gd

const PANEL := "res://scripts/dev/dev_panel.gd"

var _failed := false
var _dev: Node
var _panel: Node


func _check(test_name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + test_name)
	if not ok:
		_failed = true


func _key(code: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.pressed = true
	return e


func _init() -> void:
	await process_frame
	_dev = root.get_node("DevMode")
	_panel = _dev.get_node_or_null("DevPanel")
	_check("panel: DevMode added it on startup", _panel != null)
	if _panel == null:
		quit(1)
		return
	test_open_and_close()
	test_keys()
	test_toggles_and_status()
	test_money_toggle()
	test_run_only_controls_without_a_run()
	await test_run_controls_with_a_run()
	test_freed_while_open_unpauses()
	test_does_not_repause_after_the_other_pauser_let_go()
	await test_controls_disable_when_the_run_ends()
	await test_backtick_works_with_the_shop_open()
	await test_shop_money_refreshes_when_infinite_money_toggles()
	quit(1 if _failed else 0)


func test_open_and_close() -> void:
	paused = false
	_panel.set_open(true)
	_check("open: shows and pauses", _panel.is_open() and paused)
	_panel.set_open(false)
	_check("close: hides and unpauses", not _panel.is_open() and not paused)
	paused = true # something else (e.g. the results screen) already paused the game
	_panel.set_open(true)
	_panel.set_open(false)
	_check("close: leaves the game paused when it was already paused", paused)
	paused = false


func test_keys() -> void:
	_panel._input(_key(KEY_QUOTELEFT))
	_check("key: backtick opens", _panel.is_open())
	_panel._input(_key(KEY_QUOTELEFT))
	_check("key: backtick closes", not _panel.is_open())
	_panel.set_open(true)
	_panel._input(_key(KEY_ESCAPE))
	_check("key: Esc closes", not _panel.is_open())
	_panel._input(_key(KEY_ESCAPE))
	_check("key: Esc does nothing when closed", not _panel.is_open())
	paused = false


func test_toggles_and_status() -> void:
	_panel.controls["invincible"].button_pressed = true
	_check("toggle: invincible flips DevMode", _dev.invincible)
	_check("status: label shows it", _panel.controls["status"].text == "DEV: invincible"
		and _panel.controls["status"].visible)
	_panel.controls["invincible"].button_pressed = false
	_check("status: hidden again when nothing is on", not _panel.controls["status"].visible)
	_panel.controls["noclip"].button_pressed = true
	_panel.controls["spawning_paused"].button_pressed = true
	_check("toggle: noclip and spawn pause flip DevMode", _dev.noclip and _dev.spawning_paused)
	_panel.controls["noclip"].button_pressed = false
	_panel.controls["spawning_paused"].button_pressed = false


func test_money_toggle() -> void:
	var save: Node = root.get_node("Save")
	_panel.controls["infinite_money"].button_pressed = true
	_check("money: toggle starts the save sandbox", save.sandbox and _dev.infinite_money)
	_panel.controls["infinite_money"].button_pressed = false
	_check("money: toggle off leaves it", not save.sandbox)


func test_run_only_controls_without_a_run() -> void:
	_panel.set_open(true)
	_check("no run: skip, give and kill are disabled", _panel.controls["skip_down"].disabled
		and _panel.controls["skip_up"].disabled and _panel.controls["give"].disabled
		and _panel.controls["kill"].disabled)
	_panel.set_open(false)


func test_run_controls_with_a_run() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	_panel.set_open(true)
	_check("run: controls enabled", not _panel.controls["skip_down"].disabled
		and not _panel.controls["give"].disabled)
	_panel.controls["skip_down"].pressed.emit()
	_check("run: Skip layer down breaks barrier 1", not main.terrain.barrier_alive(1))
	var def: UpgradeItemDef = main.catalog.items[0]
	_check("run: item list is the catalog", _panel.controls["item_list"].item_count == main.catalog.items.size())
	_panel.controls["item_list"].select(0)
	_panel.controls["give"].pressed.emit()
	_check("run: Give adds a stack of the selected item", main.drill.stacks_of(def) == 1)
	var weapons: WeaponCatalog = load("res://data/weapon_catalog.tres")
	_check("run: weapon list is the weapon catalog", _panel.controls["weapon_list"].item_count == weapons.weapons.size())
	_panel.controls["weapon_list"].select(weapons.weapons.find(load("res://data/weapons/flamethrower.tres")))
	_panel.controls["equip"].pressed.emit()
	_check("run: Equip puts the selected weapon on the drill", main.drill.secondary != null and main.drill.secondary.def.id() == "flamethrower")
	_panel.set_open(false)
	main.queue_free()
	await process_frame


func test_freed_while_open_unpauses() -> void:
	paused = false
	var extra: Node = load(PANEL).new()
	root.add_child(extra)
	extra.set_open(true)
	_check("cleanup: second panel paused the tree", paused)
	extra.free()
	_check("cleanup: freeing an open panel unpauses the tree", not paused)


## Something else (the return prompt, the results screen) paused the game; the panel opens on top of
## it; that other thing unpauses (Esc on the prompt, Space or Return on the results screen); closing
## the panel must not pause the game again.
func test_does_not_repause_after_the_other_pauser_let_go() -> void:
	paused = true
	_panel.set_open(true)
	paused = false
	_panel.set_open(false)
	_check("pause: closing the panel does not re-pause after the other pauser let go", not paused)
	var extra: Node = load(PANEL).new()
	root.add_child(extra)
	paused = true
	extra.set_open(true)
	paused = false
	extra.free()
	_check("pause: freeing an open panel does not re-pause either", not paused)
	paused = false


## The run ends (scene change) while the panel is open: Skip/Kill/Give must switch off.
func test_controls_disable_when_the_run_ends() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	_panel.set_open(true)
	_check("run ends: controls enabled while the run exists", not _panel.controls["skip_down"].disabled)
	main.free()
	_check("run ends: controls disabled the moment the run goes away",
		_panel.controls["skip_down"].disabled and _panel.controls["give"].disabled
		and _panel.controls["kill"].disabled)
	_panel.set_open(false)
	paused = false


## (Loaded by path: naming ShopMenu would compile this test before the autoloads exist.)
func _shop() -> Node:
	var shop: Node = load("res://scripts/shop_menu.gd").new()
	root.add_child(shop)
	shop.open(load("res://data/item_catalog.tres"))
	return shop


## The shop swallows key presses, but the panel (infinite money is used in the shop) must still open.
func test_backtick_works_with_the_shop_open() -> void:
	var shop := _shop()
	root.push_input(_key(KEY_QUOTELEFT))
	_check("shop: backtick still opens the panel while the shop is open", _panel.is_open())
	_panel.set_open(false)
	root.push_input(_key(KEY_ESCAPE))
	_check("shop: Esc still closes the shop", not shop.visible)
	shop.free()
	paused = false


func test_shop_money_refreshes_when_infinite_money_toggles() -> void:
	var shop := _shop()
	_panel.controls["infinite_money"].button_pressed = true
	_check("shop: open shop shows the sandbox wallet", shop._title.text.contains(str(root.get_node("Save").SANDBOX_MONEY)))
	_panel.controls["infinite_money"].button_pressed = false
	_check("shop: and the real wallet again afterwards", not shop._title.text.contains(str(root.get_node("Save").SANDBOX_MONEY)))
	shop.free()
