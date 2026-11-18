extends SceneTree
## Headless tests on the real run scene: both run endings bank the right amount, a run ends once,
## and the return prompt only opens after the drill has gone underground and come back up.
## Run: godot --headless --path . --script tests/run_end_test.gd

const SAVE_PATH := "user://save.json"

var _failed := false
var _save: Node
var _saved_text := ""
var _had_file := false


func _check(name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + name)
	if not ok:
		_failed = true


func _init() -> void:
	await process_frame
	_save = root.get_node("Save")
	_had_file = FileAccess.file_exists(SAVE_PATH)
	if _had_file:
		_saved_text = FileAccess.get_file_as_string(SAVE_PATH)
	await test_death_banks_75_percent()
	await test_death_with_nothing_earned()
	await test_death_with_tiny_haul_keeps_everything()
	await test_voluntary_return_banks_everything()
	await test_run_ends_once()
	await test_prompt_not_open_at_run_start()
	await test_prompt_opens_after_returning_from_depth()
	_restore_save()
	quit(1 if _failed else 0)


func _restore_save() -> void:
	if _had_file:
		var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
		f.store_string(_saved_text)
	elif FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


## A fresh run scene with a known wallet; the caller frees it with _finish.
func _run() -> Node:
	_save.money = 1000
	get_root().get_tree().paused = false
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	return main


func _finish(main: Node) -> void:
	paused = false
	main.queue_free()
	await process_frame


func test_death_banks_75_percent() -> void:
	var main := await _run()
	main._gem_value = 400
	main._on_player_died()
	_check("death: wallet rises by 300 of 400 earned", _save.money == 1300)
	_check("death: results screen visible", main._results.visible)
	_check("death: shows Lost line", main._results._label.text.contains("Lost: 100"))
	await _finish(main)


func test_death_with_nothing_earned() -> void:
	var main := await _run()
	main._gem_value = 0
	main._on_player_died()
	_check("death with 0 earned: wallet unchanged", _save.money == 1000)
	await _finish(main)


func test_death_with_tiny_haul_keeps_everything() -> void:
	var main := await _run()
	main._gem_value = 3
	main._on_player_died()
	_check("death with 3 earned: loss rounds to 0, wallet rises by 3", _save.money == 1003)
	await _finish(main)


func test_voluntary_return_banks_everything() -> void:
	var main := await _run()
	main._gem_value = 400
	main._on_return_confirmed()
	_check("voluntary return: wallet rises by 400", _save.money == 1400)
	_check("voluntary return: titled BACK ON THE SURFACE", main._results._label.text.contains("BACK ON THE SURFACE"))
	_check("voluntary return: no Lost line", not main._results._label.text.contains("Lost"))
	await _finish(main)


func test_run_ends_once() -> void:
	var main := await _run()
	main._gem_value = 400
	main._on_player_died()
	main._on_return_confirmed()
	main._on_player_died()
	_check("run ends once: only the first ending banks (300)", _save.money == 1300)
	await _finish(main)


func test_prompt_not_open_at_run_start() -> void:
	var main := await _run()
	for i in 5:
		await physics_frame
	_check("prompt is not visible at run start", not main._return_prompt.visible)
	await _finish(main)


func test_prompt_opens_after_returning_from_depth() -> void:
	var main := await _run()
	var start: Vector2 = main.drill.position
	main.drill.position = Vector2(start.x, 200.0) # underground, row 6
	await process_frame
	main.drill.position = start
	await process_frame
	_check("prompt opens after going underground and coming back", main._return_prompt.visible)
	_check("prompt pauses the game", paused)
	main._return_prompt._decline() # what Esc or the Keep digging button does
	_check("declining unpauses the game", not paused)
	await process_frame
	_check("declined prompt does not reopen above ground", not main._return_prompt.visible)
	await _finish(main)
