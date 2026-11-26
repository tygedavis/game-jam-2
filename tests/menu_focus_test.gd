extends SceneTree
## Headless tests: the return prompt and results screen give a button keyboard focus when shown
## (issue #42), and Tab moves focus between the prompt's buttons.
## Run: godot --headless --path . --script tests/menu_focus_test.gd

var _failed := false


func _check(name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + name)
	if not ok:
		_failed = true


func _init() -> void:
	await process_frame
	await test_return_prompt_focuses_return_button()
	await test_results_screen_focuses_its_button()
	paused = false
	quit(1 if _failed else 0)


func _focused() -> Control:
	return root.gui_get_focus_owner()


func test_return_prompt_focuses_return_button() -> void:
	var prompt := ReturnPrompt.new()
	root.add_child(prompt)
	await process_frame
	await process_frame
	_check("hidden prompt holds no focus", _focused() == null)
	prompt.open()
	await process_frame
	var focus := _focused()
	_check("open prompt focuses the Return button", focus == prompt._return_button)
	var tab := InputEventKey.new()
	tab.pressed = true
	tab.keycode = KEY_TAB
	tab.physical_keycode = KEY_TAB
	root.push_input(tab)
	await process_frame
	focus = _focused()
	_check("Tab moves focus to the other prompt button",
			focus is Button and focus != prompt._return_button and prompt.is_ancestor_of(focus))
	prompt._decline()
	paused = false
	prompt.queue_free()
	await process_frame


func test_results_screen_focuses_its_button() -> void:
	var results := ResultsScreen.new()
	root.add_child(results)
	await process_frame
	await process_frame
	results.show_results("summary")
	await process_frame
	_check("results screen focuses its button", _focused() == results._button)
	paused = false
	results.queue_free()
	await process_frame
