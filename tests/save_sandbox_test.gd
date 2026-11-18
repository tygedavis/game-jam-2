extends SceneTree
## Headless tests for the dev save sandbox in Save: nothing is written while it is on, and leaving
## it restores the real wallet, unlocks and levels.
## Run: godot --headless --path . --script tests/save_sandbox_test.gd

const TEST_PATH := "user://save_sandbox_test.json"

var _failed := false


func _check(test_name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + test_name)
	if not ok:
		_failed = true


func _item(item_name: String) -> UpgradeItemDef:
	var d := UpgradeItemDef.new()
	d.resource_path = "res://fake_items/%s.tres" % item_name
	d.unlock_cost = 30
	d.base_cost = 20
	d.cost_growth = 1.0
	d.max_shop_level = 3
	return d


func _cleanup() -> void:
	if FileAccess.file_exists(TEST_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))


## A Save with real state (money 50, unlocked a, a at level 2) already written to TEST_PATH.
func _real_save() -> Node:
	var s = load("res://scripts/save.gd").new()
	s.path = TEST_PATH
	s.money = 50
	s.unlocked = ["a"]
	s.item_levels = {"a": 2}
	s.save_game()
	return s


func _init() -> void:
	_cleanup()
	test_enter_gives_big_wallet_and_exit_restores()
	test_nothing_written_while_sandboxed()
	test_enter_twice_keeps_original_snapshot()
	test_exit_without_enter_is_harmless()
	_cleanup()
	quit(1 if _failed else 0)


func test_enter_gives_big_wallet_and_exit_restores() -> void:
	var s = _real_save()
	s.enter_sandbox()
	_check("enter: sandbox flag set", s.sandbox)
	_check("enter: wallet is the sandbox amount", s.money == s.SANDBOX_MONEY)
	s.exit_sandbox()
	_check("exit: flag cleared", not s.sandbox)
	_check("exit: money restored", s.money == 50)
	_check("exit: unlocked restored", s.unlocked == ["a"])
	_check("exit: item levels restored", s.item_levels == {"a": 2})
	s.free()


func test_nothing_written_while_sandboxed() -> void:
	var s = _real_save()
	var before := FileAccess.get_file_as_string(TEST_PATH)
	s.enter_sandbox()
	var thing := _item("b")
	_check("sandbox: can buy an unlock with the big wallet", s.unlock(thing))
	_check("sandbox: purchase took effect in memory", s.is_unlocked(thing))
	s.bank(10)
	_check("sandbox: file is byte-identical after buying and banking",
		FileAccess.get_file_as_string(TEST_PATH) == before)
	s.exit_sandbox()
	_check("exit: sandbox purchase is gone", not s.is_unlocked(thing))
	_check("exit: banked money is gone", s.money == 50)
	_check("exit: file still unchanged", FileAccess.get_file_as_string(TEST_PATH) == before)
	s.free()


func test_enter_twice_keeps_original_snapshot() -> void:
	var s = _real_save()
	s.enter_sandbox()
	s.money = 5 # a purchase inside the sandbox
	s.enter_sandbox() # must not snapshot the sandbox state
	s.exit_sandbox()
	_check("twice: still restores the real money", s.money == 50)
	_check("twice: still restores the real unlocks", s.unlocked == ["a"])
	s.free()


func test_exit_without_enter_is_harmless() -> void:
	var s = _real_save()
	s.exit_sandbox()
	_check("exit alone: state unchanged", s.money == 50 and s.unlocked == ["a"] and s.item_levels == {"a": 2})
	_check("exit alone: not sandboxed", not s.sandbox)
	s.free()
