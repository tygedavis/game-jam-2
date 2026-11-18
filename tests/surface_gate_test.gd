extends SceneTree
## Headless tests: when the return-to-surface prompt may open.
## Run: godot --headless --path . --script tests/surface_gate_test.gd

var _failed := false


func _init() -> void:
	test_no_prompt_at_run_start()
	test_prompts_once_after_underground()
	test_decline_rearms_only_after_underground()
	quit(1 if _failed else 0)


func _check(name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + name)
	if not ok:
		_failed = true


func test_no_prompt_at_run_start() -> void:
	var gate := SurfaceGate.new()
	_check("no prompt at row -1 at run start", not gate.update(-1))
	_check("no prompt at row -2 at run start", not gate.update(-2))


func test_prompts_once_after_underground() -> void:
	var gate := SurfaceGate.new()
	_check("row 1 underground does not prompt", not gate.update(1))
	_check("row 0 does not prompt", not gate.update(0))
	_check("row -1 after underground prompts", gate.update(-1))
	_check("second frame at row -1 does not prompt again", not gate.update(-1))


func test_decline_rearms_only_after_underground() -> void:
	var gate := SurfaceGate.new()
	gate.update(5)
	_check("prompts after going deep", gate.update(-1))
	gate.decline()
	_check("no prompt after decline while still above ground", not gate.update(-1))
	gate.update(1)
	_check("prompts again after going underground again", gate.update(-1))
