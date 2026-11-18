extends SceneTree
## Static check: nothing outside scripts/dev/ may reference the dev folder or its classes, so a
## production export that leaves scripts/dev/ out still starts. The one allowed link is the
## PANEL_PATH load() in scripts/dev_mode.gd.
## Run: godot --headless --path . --script tests/dev_isolation_test.gd

var _failed := false


func _check(test_name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + test_name)
	if not ok:
		_failed = true


func _init() -> void:
	var files: Array[String] = []
	_collect("res://scripts", files)
	_collect("res://scenes", files)
	files.append("res://project.godot")
	var scanned := 0
	for path in files:
		if path.begins_with("res://scripts/dev/"):
			continue
		var text := FileAccess.get_file_as_string(path)
		scanned += 1
		var offending := ""
		if path == "res://scripts/dev_mode.gd":
			if text.count("res://scripts/dev/") != 1:
				offending = "must name res://scripts/dev/ exactly once (PANEL_PATH)"
			elif text.contains("DevActions"):
				offending = "must not reference DevActions"
		else:
			for needle in ["scripts/dev/", "DevActions", "DevPanel"]:
				if text.contains(needle):
					offending = "references " + needle
					break
		if offending != "":
			_check("%s: %s" % [path, offending], false)
	_check("isolation: scanned %d files outside scripts/dev/ and found no stray references" % scanned,
		not _failed and scanned > 10)
	quit(1 if _failed else 0)


func _collect(dir_path: String, out: Array[String]) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	for sub in dir.get_directories():
		_collect(dir_path + "/" + sub, out)
	for f in dir.get_files():
		if f.ends_with(".gd") or f.ends_with(".tscn"):
			out.append(dir_path + "/" + f)
