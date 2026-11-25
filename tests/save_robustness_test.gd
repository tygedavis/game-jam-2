extends SceneTree
## Headless tests for a damaged or hand-edited save file (issue #28) and the atomic write (issue #29).
## Run: godot --headless --path . --script tests/save_robustness_test.gd

const TEST_PATH := "user://save_robustness_test.json"

var _failed := false


func check(test_name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + test_name)
	if not ok:
		_failed = true


func _item(item_id: String, max_level := 3) -> UpgradeItemDef:
	var d := UpgradeItemDef.new()
	d.item_id = item_id
	d.max_shop_level = max_level
	return d


func _save() -> Node:
	var s = load("res://scripts/save.gd").new()
	s.path = TEST_PATH
	return s


func _write(text: String) -> void:
	var f := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	f.store_string(text)
	f.close()


func _cleanup() -> void:
	for suffix in ["", ".tmp", ".bad"]:
		if FileAccess.file_exists(TEST_PATH + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH + suffix))


## Loads text as the save file and returns the resulting Save (caller frees it).
func _load_text(text: String) -> Node:
	_cleanup()
	_write(text)
	var s = _save()
	s.load_game()
	return s


func _initialize() -> void:
	_test_corrupt_file()
	_test_wrong_types()
	_test_clamping()
	_test_atomic_write()
	_cleanup()
	quit(1 if _failed else 0)


func _test_corrupt_file() -> void:
	var s = _load_text("{\"money\": 12")
	check("truncated: starts fresh", s.money == 0 and s.unlocked.is_empty())
	check("truncated: moved to .bad", FileAccess.file_exists(TEST_PATH + ".bad"))
	check("truncated: original no longer in place", not FileAccess.file_exists(TEST_PATH))
	check(".bad keeps the original bytes", FileAccess.get_file_as_string(TEST_PATH + ".bad") == "{\"money\": 12")
	s.bank(5)
	check("next save does not touch .bad", FileAccess.get_file_as_string(TEST_PATH + ".bad") == "{\"money\": 12")
	s.free()

	s = _load_text("[1, 2, 3]")
	check("non-object JSON: moved to .bad", FileAccess.file_exists(TEST_PATH + ".bad"))
	s.free()

	s = _load_text("")
	check("empty file: moved to .bad", FileAccess.file_exists(TEST_PATH + ".bad"))
	s.free()


func _test_wrong_types() -> void:
	var s = _load_text(JSON.stringify({"money": [1], "unlocked": 5, "item_levels": [1, 2]}))
	check("wrong types: money 0", s.money == 0)
	check("wrong types: unlocked empty", s.unlocked.is_empty())
	check("wrong types: item_levels empty", s.item_levels.is_empty())
	check("wrong types: valid object is not quarantined", not FileAccess.file_exists(TEST_PATH + ".bad"))
	s.free()

	s = _load_text(JSON.stringify({"money": "50", "unlocked": ["a", 3, null, "a"], "item_levels": {"a": "x", "b": 2}}))
	check("string money is 0", s.money == 0)
	check("unlocked keeps only unique strings", s.unlocked == ["a"])
	check("non-numeric level is 0", s.item_levels["a"] == 0)
	check("numeric level kept", s.item_levels["b"] == 2)
	s.free()


func _test_clamping() -> void:
	var s = _load_text(JSON.stringify({"money": -40, "item_levels": {"a": -3, "b": 99}}))
	check("negative money clamped to 0", s.money == 0)
	check("negative level clamped to 0", s.item_levels["a"] == 0)
	check("level above max reads as max", s.item_level_of(_item("b", 3)) == 3)
	check("level above max counts as maxed", s.is_item_maxed(_item("b", 3)))
	s.free()

	s = _load_text(JSON.stringify({"money": 1e300}))
	check("absurd money clamped", s.money == s.MAX_MONEY)
	s.free()


func _test_atomic_write() -> void:
	_cleanup()
	var s = _save()
	s.money = 42
	check("save_game reports success", s.save_game())
	check("save file written", FileAccess.file_exists(TEST_PATH))
	check("no .tmp left behind", not FileAccess.file_exists(TEST_PATH + ".tmp"))
	s.money = 43
	check("overwrite succeeds", s.save_game())
	var s2 = _save()
	s2.load_game()
	check("overwrite round-trips", s2.money == 43)
	s2.free()

	# A crash mid-write leaves only a partial .tmp: the real save must still load.
	_write(JSON.stringify({"money": 43}))
	var f := FileAccess.open(TEST_PATH + ".tmp", FileAccess.WRITE)
	f.store_string("{\"mon")
	f.close()
	var s3 = _save()
	s3.load_game()
	check("partial .tmp does not affect the save", s3.money == 43)
	s3.free()

	s.path = "user://no_such_dir/deeper/save.json"
	check("save_game reports failure for an unwritable path", not s.save_game())
	s.free()
