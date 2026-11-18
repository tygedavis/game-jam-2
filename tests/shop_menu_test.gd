extends SceneTree
## Headless tests for the item shop UI text and scene wiring.
## Run: godot --headless --path . --script tests/shop_menu_test.gd

const SAVE_PATH := "user://save.json"

var _failed := false
# Loaded at runtime: shop_menu.gd names the Save autoload, which does not exist yet when this script compiles.
var _shop_script: GDScript


func check(test_name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + test_name)
	if not ok:
		_failed = true


func _init() -> void:
	await process_frame # autoloads are registered by now
	_shop_script = load("res://scripts/shop_menu.gd")
	_test_row_text()
	_test_scene_wiring()
	_test_menu_open_close()
	await _test_unlocked_pool()
	quit(1 if _failed else 0)


func _test_row_text() -> void:
	var d := UpgradeItemDef.new()
	d.display_name = "Sharp Tip"
	d.description = "+attack damage per stack"
	d.buff_per_stack = 0.05
	d.buff_step_per_level = 0.025
	d.base_cost = 20
	d.cost_growth = 1.0
	d.unlock_cost = 30
	d.max_shop_level = 2
	var locked: String = _shop_script.row_text(d, false, 0, 100)
	check("locked row has name", locked.contains("Sharp Tip"))
	check("locked row says Unlock", locked.contains("Unlock"))
	check("locked row shows unlock cost", locked.contains("30"))
	var lv0: String = _shop_script.row_text(d, true, 0, 100)
	check("lv0 shows level", lv0.contains("Lv 0/2"))
	check("lv0 shows current percent", lv0.contains("+5% ->"))
	check("lv0 shows next percent", lv0.contains("7.5%"))
	check("lv0 shows cost", lv0.contains("20"))
	var maxed: String = _shop_script.row_text(d, true, 2, 100)
	check("max row says MAX", maxed.contains("MAX"))
	check("max row has no cost number", not maxed.contains("Cost") and not maxed.contains("20"))
	check("max row has no arrow", not maxed.contains("->"))
	check("max row shows current buff", maxed.contains("+10% per pickup"))
	check("locked row has description", locked.contains("Sharp Tip (+attack damage per stack)"))
	check("unlocked row has description", lv0.contains("Sharp Tip (+attack damage per stack)"))
	d.description = ""
	var bare: String = _shop_script.row_text(d, false, 0, 100)
	check("empty description adds no parens", not bare.contains("("))


func _test_scene_wiring() -> void:
	for path in ["res://scenes/main.tscn", "res://scenes/surface.tscn"]:
		var node: Node = load(path).instantiate()
		var cat = node.get("catalog")
		check(path + " catalog has 3 items", cat is ItemCatalog and cat.items.size() == 3)
		node.free()


func _nothing_label(menu) -> bool:
	for c in menu._box.get_children():
		if c is Label and c.text.contains("Nothing for sale yet"):
			return true
	return false


func _space_event() -> InputEventKey:
	var ev := InputEventKey.new()
	ev.physical_keycode = KEY_SPACE
	ev.pressed = true
	ev.echo = false
	return ev


func _test_menu_open_close() -> void:
	var menu = _shop_script.new()
	root.add_child(menu)
	var closed_count := [0]
	menu.closed.connect(func(): closed_count[0] += 1)
	menu.open(ItemCatalog.new())
	check("opens with empty catalog", menu.visible)
	check("empty catalog shows Nothing for sale", _nothing_label(menu))
	menu.open(null)
	check("opens with null catalog", menu.visible)
	check("null catalog shows Nothing for sale", _nothing_label(menu))
	menu._input(_space_event())
	check("Space hides the menu", not menu.visible)
	check("Space emits closed", closed_count[0] == 1)
	menu.open(null)
	menu.close()
	check("close hides", not menu.visible)
	menu.free()


## Locked items must never spawn: the run's pool is only the unlocked catalog items.
func _test_unlocked_pool() -> void:
	var save = root.get_node("Save")
	var had_file := FileAccess.file_exists(SAVE_PATH)
	var saved_text := FileAccess.get_file_as_string(SAVE_PATH) if had_file else ""
	var old_unlocked: Array = save.unlocked
	var old_money: int = save.money
	save.unlocked = []
	var scene: PackedScene = load("res://scenes/main.tscn")
	var run = scene.instantiate()
	root.add_child(run)
	check("no unlocked items: empty spawn pool", run.terrain.upgrade_defs.is_empty())
	var catalog: ItemCatalog = run.catalog
	run.free()
	save.unlocked = [catalog.items[1].id()]
	run = scene.instantiate()
	root.add_child(run)
	check("one unlocked item: pool is exactly it",
		run.terrain.upgrade_defs.size() == 1 and run.terrain.upgrade_defs[0] == catalog.items[1])
	run.free()
	save.unlocked = old_unlocked
	save.money = old_money
	if had_file:
		var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
		f.store_string(saved_text)
	elif FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
