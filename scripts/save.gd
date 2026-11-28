extends Node
## Autoload "Save": the persistent wallet, unlocked shop items and their upgrade levels (user://save.json).

var path := "user://save.json"

var money := 0
var unlocked: Array = [] # UpgradeItemDef.id() of items unlocked at the shop (issue #38)
var item_levels := {} # UpgradeItemDef.id() -> shop upgrade level

## Loaded money is clamped to 0..MAX_MONEY so a hand-edited or corrupt file can't break the wallet.
const MAX_MONEY := 1_000_000_000_000

## Dev mode "infinite money": a throwaway session. While on, nothing is written to disk, and
## leaving restores the real wallet, unlocks and levels.
const SANDBOX_MONEY := 999999999
var sandbox := false
var _real := {}


func _ready() -> void:
	load_game()


func is_unlocked(def: UpgradeItemDef) -> bool:
	return unlocked.has(def.id())


func can_unlock(def: UpgradeItemDef) -> bool:
	return not is_unlocked(def) and money >= def.unlock_cost


func unlock(def: UpgradeItemDef) -> bool:
	if not can_unlock(def):
		return false
	money -= def.unlock_cost
	unlocked.append(def.id())
	save_game()
	return true


## Clamped to 0..max_shop_level, so a bad save (or a lowered max) can't apply extra levels (#28).
func item_level_of(def: UpgradeItemDef) -> int:
	return clampi(item_levels.get(def.id(), 0), 0, def.max_shop_level)


func is_item_maxed(def: UpgradeItemDef) -> bool:
	return item_level_of(def) >= def.max_shop_level


func next_upgrade_cost(def: UpgradeItemDef) -> int:
	return def.cost_for(item_level_of(def))


func can_upgrade_item(def: UpgradeItemDef) -> bool:
	return is_unlocked(def) and not is_item_maxed(def) and money >= next_upgrade_cost(def)


func upgrade_item(def: UpgradeItemDef) -> bool:
	if not can_upgrade_item(def):
		return false
	money -= next_upgrade_cost(def)
	item_levels[def.id()] = item_level_of(def) + 1
	save_game()
	return true


func bank(amount: int) -> void:
	money += amount
	save_game()


## Starts the sandbox: remembers the real state and gives a huge wallet. Does nothing if already on.
func enter_sandbox() -> void:
	if sandbox:
		return
	_real = {"money": money, "unlocked": unlocked.duplicate(), "item_levels": item_levels.duplicate()}
	sandbox = true
	money = SANDBOX_MONEY


## Ends the sandbox and puts the real state back. Does nothing if it is not on.
func exit_sandbox() -> void:
	if not sandbox:
		return
	money = _real["money"]
	unlocked = _real["unlocked"]
	item_levels = _real["item_levels"]
	_real = {}
	sandbox = false


## Writes the save atomically: the data goes to <path>.tmp, which is then renamed over <path>, so a
## crash mid-write leaves the old save intact (issue #29). Returns false and logs an error if the
## write fails. In the sandbox nothing is written and it returns true.
func save_game() -> bool:
	if sandbox:
		return true
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		push_error("Save: could not open %s for writing (error %d)" % [tmp, FileAccess.get_open_error()])
		return false
	f.store_string(JSON.stringify({"money": money, "unlocked": unlocked, "item_levels": item_levels}))
	f.flush()
	var write_err := f.get_error()
	f.close()
	if write_err != OK:
		push_error("Save: writing %s failed (error %d)" % [tmp, write_err])
		DirAccess.remove_absolute(_abs(tmp))
		return false
	var err := DirAccess.rename_absolute(_abs(tmp), _abs(path))
	if err != OK:
		push_error("Save: could not move %s over %s (error %d)" % [tmp, path, err])
		return false
	return true


## Loads the save, validating every field (issue #28). A file that isn't a JSON object is moved to
## <path>.bad with a warning, so the next save can't overwrite whatever is recoverable in it.
## Fields with the wrong type fall back to empty; numbers are clamped to sane ranges.
func load_game() -> void:
	if not FileAccess.file_exists(path):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary:
		_quarantine()
		return
	money = clampi(_num(data.get("money", 0)), 0, MAX_MONEY)
	unlocked = []
	var raw_unlocked = data.get("unlocked", [])
	if raw_unlocked is Array:
		for id in raw_unlocked:
			if id is String and not unlocked.has(id):
				unlocked.append(id)
	item_levels = {}
	var raw_levels = data.get("item_levels", {})
	if raw_levels is Dictionary:
		for k in raw_levels:
			item_levels[str(k)] = maxi(_num(raw_levels[k]), 0)


## A JSON number as an int; anything else (string, array, null...) is 0.
static func _num(v) -> int:
	if v is float or v is int:
		return int(clampf(v, -MAX_MONEY, MAX_MONEY))
	return 0


func _abs(p: String) -> String:
	return ProjectSettings.globalize_path(p)


func _quarantine() -> void:
	var bad := path + ".bad"
	push_warning("Save: %s is not valid save data; moved it to %s and starting fresh" % [path, bad])
	var err := DirAccess.rename_absolute(_abs(path), _abs(bad))
	if err != OK:
		push_error("Save: could not move %s to %s (error %d)" % [path, bad, err])
