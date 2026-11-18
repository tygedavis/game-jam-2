extends SceneTree
## Headless tests: death loss maths and the earned-versus-kept summary text.
## Run: godot --headless --path . --script tests/run_summary_test.gd

var _failed := false


func _init() -> void:
	test_lost_amount()
	test_death_text()
	test_voluntary_text()
	test_sections_and_empty_lists()
	quit(1 if _failed else 0)


func _check(name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + name)
	if not ok:
		_failed = true


func _stats() -> Dictionary:
	return {"deepest": 12, "layer": "Clay", "kills": 5,
		"gems": {"Ruby": 2}, "upgrades": {"dmg": {"name": "Damage", "stacks": 3}},
		"barriers": 1, "barrier_money": 80}


func _empty_stats() -> Dictionary:
	return {"deepest": 0, "layer": "Topsoil", "kills": 0, "gems": {}, "upgrades": {},
		"barriers": 0, "barrier_money": 0}


func test_lost_amount() -> void:
	_check("lost_amount 400 at 25% is 100", RunSummary.lost_amount(400, 0.25) == 100)
	_check("lost_amount 0 is 0", RunSummary.lost_amount(0, 0.25) == 0)
	_check("lost_amount 3 rounds down to 0", RunSummary.lost_amount(3, 0.25) == 0)
	_check("lost_amount negative earned is 0", RunSummary.lost_amount(-5, 0.25) == 0)
	_check("lost_amount fraction clamps to 1", RunSummary.lost_amount(400, 2.0) == 400)


func _in_order(text: String, parts: Array) -> bool:
	var from := 0
	for part in parts:
		var at := text.find(part, from)
		if at < 0:
			return false
		from = at + part.length()
	return true


func test_death_text() -> void:
	var text := RunSummary.build_text("YOU WERE OVERRUN", _stats(), 400, 100, 1250, true)
	_check("death text has title", text.contains("YOU WERE OVERRUN"))
	_check("death text earned/lost/keep/banked in order", _in_order(text,
		["Earned 400", "Lost: 100", "You keep 300", "Banked 300  (money: 1250)"]))
	_check("death text has no percent sign", not text.contains("%"))


func test_voluntary_text() -> void:
	var text := RunSummary.build_text("BACK ON THE SURFACE", _stats(), 400, 0, 1250, false)
	_check("voluntary text has title", text.contains("BACK ON THE SURFACE"))
	_check("voluntary text earned/keep/banked in order", _in_order(text,
		["Earned 400", "You keep 400", "Banked 400  (money: 1250)"]))
	var has_lost_line := false
	for line in text.split("\n"):
		if line.begins_with("Lost"):
			has_lost_line = true
	_check("voluntary text has no Lost line", not has_lost_line)


func test_sections_and_empty_lists() -> void:
	var text := RunSummary.build_text("T", _stats(), 10, 0, 10, false)
	for section in ["Deepest:", "Enemies drilled:", "Gems found:", "Upgrades found:", "Barriers broken:"]:
		_check("text has section " + section, text.contains(section))
	_check("text lists gems and upgrades", text.contains("Ruby x2") and text.contains("Damage x3"))
	var empty := RunSummary.build_text("T", _empty_stats(), 0, 0, 0, true)
	_check("empty gems and upgrades show (none)", empty.count("(none)") == 2)
