extends SceneTree
## Headless tests for the DevMode autoload (toggle flags, availability, status text, money sandbox).
## Autoloads don't resolve by name in the test script itself (see run_end_test), so wait a frame
## and fetch them from the root.
## Run: godot --headless --path . --script tests/dev_mode_test.gd

var _failed := false


func _check(test_name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + test_name)
	if not ok:
		_failed = true


func _init() -> void:
	await process_frame
	var dev: Node = root.get_node_or_null("DevMode")
	_check("autoload: DevMode exists", dev != null)
	if dev == null:
		quit(1)
		return
	test_status_text(dev)
	test_changed_signal(dev)
	test_available(dev)
	test_money_sandbox(dev)
	quit(1 if _failed else 0)


func test_status_text(dev: Node) -> void:
	_check("status: empty by default", dev.status_text() == "")
	dev.set_flag(&"invincible", true)
	dev.set_flag(&"noclip", true)
	_check("status: lists active flags in order", dev.status_text() == "DEV: invincible, noclip")
	dev.set_flag(&"spawning_paused", true)
	_check("status: no-spawn comes last", dev.status_text() == "DEV: invincible, noclip, no-spawn")
	dev.set_flag(&"invincible", false)
	dev.set_flag(&"noclip", false)
	dev.set_flag(&"spawning_paused", false)
	_check("status: empty again when all off", dev.status_text() == "")


func test_changed_signal(dev: Node) -> void:
	var count := [0]
	var on_changed := func() -> void: count[0] += 1
	dev.changed.connect(on_changed)
	dev.set_flag(&"noclip", true)
	dev.set_flag(&"noclip", false)
	dev.changed.disconnect(on_changed)
	_check("changed: fires once per set_flag", count[0] == 2)


func test_available(dev: Node) -> void:
	_check("available: true in a debug (editor) run", dev.available())


func test_money_sandbox(dev: Node) -> void:
	var save: Node = root.get_node("Save")
	var real_money: int = save.money
	dev.set_infinite_money(true)
	_check("money on: DevMode flag set", dev.infinite_money)
	_check("money on: Save is sandboxed", save.sandbox)
	_check("money on: status shows money", dev.status_text() == "DEV: money")
	dev.set_infinite_money(false)
	_check("money off: flag cleared", not dev.infinite_money)
	_check("money off: Save sandbox left", not save.sandbox)
	_check("money off: real wallet restored", save.money == real_money)
