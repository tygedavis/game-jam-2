extends Node
## Autoload "Save": the persistent wallet, unlocked shop items and their upgrade levels (user://save.json).

var path := "user://save.json"

var money := 0
var unlocked: Array = [] # UpgradeItemDef.id() of items unlocked at the shop (issue #38)
var item_levels := {} # UpgradeItemDef.id() -> shop upgrade level

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


func item_level_of(def: UpgradeItemDef) -> int:
	return item_levels.get(def.id(), 0)


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


func save_game() -> void:
	if sandbox:
		return
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"money": money, "unlocked": unlocked, "item_levels": item_levels}))


func load_game() -> void:
	if not FileAccess.file_exists(path):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if data is Dictionary:
		money = int(data.get("money", 0))
		unlocked = []
		for id in data.get("unlocked", []):
			unlocked.append(str(id))
		item_levels = {}
		for k in data.get("item_levels", {}):
			item_levels[k] = int(data["item_levels"][k])
