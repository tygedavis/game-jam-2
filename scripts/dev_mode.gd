extends Node
## Autoload "DevMode": the developer-mode toggle flags that game scripts read. Only available in
## debug builds that are not tagged "production". The panel and cheat actions live in scripts/dev/
## and are loaded by path from here, so excluding that folder from an export cannot break startup.
## Nothing outside scripts/dev/ may reference that folder (tests/dev_isolation_test.gd checks).

signal changed

const PANEL_PATH := "res://scripts/dev/dev_panel.gd"
## Status order and labels, for status_text().
const _LABELS := [[&"invincible", "invincible"], [&"noclip", "noclip"],
	[&"infinite_money", "money"], [&"spawning_paused", "no-spawn"]]

var invincible := false
var noclip := false
var spawning_paused := false
## Set through set_infinite_money(), which also starts or ends the save sandbox.
var infinite_money := false
## The active run (Main) while one is open, else null. Main sets and clears it.
var run: Node = null


func _ready() -> void:
	if available() and ResourceLoader.exists(PANEL_PATH):
		add_child(load(PANEL_PATH).new())


## Dev mode exists only in debug builds that are not tagged "production".
func available() -> bool:
	return OS.has_feature("debug") and not OS.has_feature("production")


func set_flag(flag: StringName, on: bool) -> void:
	if not available() and on:
		return
	set(flag, on)
	changed.emit()


func set_infinite_money(on: bool) -> void:
	if not available() and on:
		return
	infinite_money = on
	if on:
		Save.enter_sandbox()
	else:
		Save.exit_sandbox()
	changed.emit()


## "DEV: invincible, noclip" listing the active toggles, or "" when none is on.
func status_text() -> String:
	var active: Array[String] = []
	for entry in _LABELS:
		if get(entry[0]):
			active.append(entry[1])
	return "" if active.is_empty() else "DEV: " + ", ".join(active)
