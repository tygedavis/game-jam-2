class_name MetaUpgradeDef
extends Resource
## A permanent upgrade sold by the owner. Add one by creating a MetaUpgradeDef .tres and
## listing it on the Surface and Main scenes. Each purchased level multiplies one Drill stat.

@export var display_name := "Upgrade"
@export_multiline var description := ""
@export_enum("attack_damage", "attack_interval", "attack_reach", "speed", "max_hp") var property := "attack_damage"
## Applied once per purchased level (e.g. 1.15 = +15% each; 0.93 on attack_interval = faster).
@export var multiplier := 1.15
@export var max_level := 10
## Price of the first level; later levels cost base_cost * cost_growth ^ level.
@export var base_cost := 20
@export var cost_growth := 1.6


## Stable save key, taken from the file name.
func id() -> String:
	return resource_path.get_file().get_basename()


func cost_for(level: int) -> int:
	return roundi(base_cost * pow(cost_growth, level))


func apply(drill: Drill, level: int) -> void:
	if level > 0:
		drill.set(property, drill.get(property) * pow(multiplier, level))
