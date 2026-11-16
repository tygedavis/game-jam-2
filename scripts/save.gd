extends Node
## Autoload "Save": the persistent wallet and purchased permanent upgrades (user://save.json).

const PATH := "user://save.json"

var money := 0
var levels := {} # MetaUpgradeDef.id() -> purchased level


func _ready() -> void:
	load_game()


func level_of(def: MetaUpgradeDef) -> int:
	return levels.get(def.id(), 0)


func next_cost(def: MetaUpgradeDef) -> int:
	return def.cost_for(level_of(def))


func is_maxed(def: MetaUpgradeDef) -> bool:
	return level_of(def) >= def.max_level


func can_buy(def: MetaUpgradeDef) -> bool:
	return not is_maxed(def) and money >= next_cost(def)


func buy(def: MetaUpgradeDef) -> bool:
	if not can_buy(def):
		return false
	money -= next_cost(def)
	levels[def.id()] = level_of(def) + 1
	save_game()
	return true


func bank(amount: int) -> void:
	money += amount
	save_game()


## Applies all purchased upgrades to a fresh drill.
func apply_to(drill: Drill, defs: Array[MetaUpgradeDef]) -> void:
	for def in defs:
		def.apply(drill, level_of(def))


func save_game() -> void:
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"money": money, "levels": levels}))


func load_game() -> void:
	if not FileAccess.file_exists(PATH):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if data is Dictionary:
		money = int(data.get("money", 0))
		levels = {}
		for k in data.get("levels", {}):
			levels[k] = int(data["levels"][k])
