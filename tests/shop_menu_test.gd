extends SceneTree
## Headless tests for the item shop UI text and scene wiring.
## Run: godot --headless --path . --script tests/shop_menu_test.gd

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
	quit(1 if _failed else 0)


func _test_row_text() -> void:
	var d := UpgradeItemDef.new()
	d.display_name = "Sharp Tip"
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
	check("lv0 shows current percent", lv0.contains("5%"))
	check("lv0 shows next percent", lv0.contains("7.5%"))
	check("lv0 shows cost", lv0.contains("20"))
	var maxed: String = _shop_script.row_text(d, true, 2, 100)
	check("max row says MAX", maxed.contains("MAX"))
	check("max row has no cost number", not maxed.contains("Cost") and not maxed.contains("20"))


func _test_scene_wiring() -> void:
	for path in ["res://scenes/main.tscn", "res://scenes/surface.tscn"]:
		var node: Node = load(path).instantiate()
		var cat = node.get("catalog")
		check(path + " catalog has 3 items", cat is ItemCatalog and cat.items.size() == 3)
		node.free()


func _test_menu_open_close() -> void:
	var menu = _shop_script.new()
	root.add_child(menu)
	menu.open(ItemCatalog.new())
	check("opens with empty catalog", menu.visible)
	menu.open(null)
	check("opens with null catalog", menu.visible)
	menu.close()
	check("close hides", not menu.visible)
	menu.free()
