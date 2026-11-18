extends SceneTree
## Headless tests for item unlock and upgrade purchases in Save (issue #38).
## Run: godot --headless --path . --script tests/shop_save_test.gd

const TEST_PATH := "user://shop_save_test.json"

var _failed := false
var _n := 0


func check(test_name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + test_name)
	if not ok:
		_failed = true


func _item(item_name: String) -> UpgradeItemDef:
	var d := UpgradeItemDef.new()
	d.resource_path = "res://fake_items/%s.tres" % item_name
	d.unlock_cost = 30
	d.base_cost = 20
	d.cost_growth = 1.0
	d.max_shop_level = 2
	return d


func _save() -> Node:
	var s = load("res://scripts/save.gd").new()
	s.path = TEST_PATH
	return s


func _cleanup() -> void:
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))


func _initialize() -> void:
	_cleanup()
	_test_unlock()
	_test_upgrade()
	_test_persistence()
	_cleanup()
	quit(1 if _failed else 0)


func _test_unlock() -> void:
	var s = _save()
	var a := _item("item_a")
	check("fresh: not unlocked", not s.is_unlocked(a))
	check("can_unlock false at money 0", not s.can_unlock(a))
	s.money = 30
	check("can_unlock true at money 30", s.can_unlock(a))
	check("unlock at exact cost succeeds", s.unlock(a))
	check("unlock leaves money 0", s.money == 0)
	check("is_unlocked after unlock", s.is_unlocked(a))
	s.money = 50
	check("second unlock fails", not s.unlock(a))
	check("second unlock keeps money", s.money == 50)
	s.free()


func _test_upgrade() -> void:
	var s = _save()
	var a := _item("item_b")
	s.money = 100
	check("upgrade locked item fails", not s.upgrade_item(a))
	check("locked upgrade keeps money", s.money == 100)
	check("locked upgrade keeps level", s.item_level_of(a) == 0)
	s.money = 130
	check("unlock ok", s.unlock(a))
	check("next_upgrade_cost matches cost_for", s.next_upgrade_cost(a) == a.cost_for(s.item_level_of(a)))
	check("first upgrade succeeds", s.upgrade_item(a))
	check("second upgrade succeeds", s.upgrade_item(a))
	check("level is 2", s.item_level_of(a) == 2)
	check("money is 60", s.money == 60)
	check("third upgrade fails", not s.upgrade_item(a))
	check("is_item_maxed", s.is_item_maxed(a))
	check("can_upgrade_item false when maxed", not s.can_upgrade_item(a))
	s.free()


func _test_persistence() -> void:
	var s = _save()
	var a := _item("item_c")
	s.money = 100
	s.unlock(a)
	s.upgrade_item(a)
	var s2 = _save()
	s2.load_game()
	check("round-trip money", s2.money == s.money)
	check("round-trip unlocked", s2.unlocked == s.unlocked)
	check("round-trip item_levels", s2.item_levels == s.item_levels)
	s.free()
	s2.free()

	var f := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify({"money": 7, "levels": {"hard_bit": 3}}))
	f.close()
	var s3 = _save()
	s3.load_game()
	check("old format: money", s3.money == 7)
	check("old format: unlocked empty", s3.unlocked.is_empty())
	check("old format: item_levels empty", s3.item_levels.is_empty())
	s3.free()

	var s4 = _save()
	s4.unlocked = ["ghost_item"]
	check("unknown unlocked id does not unlock others", not s4.is_unlocked(_item("item_d")))
	s4.free()
