class_name UpgradeItemDef
extends Resource
## An upgrade found buried in the map. Add one by creating an UpgradeItemDef .tres and listing it
## in the item catalog (data/item_catalog.tres). It must be its own .tres file: the file name is
## its id. Each pickup adds one stack for the current run; every stack adds a percentage buff to
## one Drill stat. The owner can later strengthen the per-stack buff (shop level).

@export var display_name := "Upgrade Item"
@export_multiline var description := ""
## Which Drill property it buffs. A positive buff on attack_interval makes attacks faster.
@export_enum("attack_damage", "attack_interval", "speed") var property := "attack_damage"
## Buff added per stack at shop level 0, as a fraction (0.05 = +5%).
@export var buff_per_stack := 0.05
## Added to the per-stack buff for each shop upgrade level.
@export var buff_step_per_level := 0.025
## Most stacks the player can hold in one run.
@export var max_stacks := 5
## Price to unlock the item in the shop (issue #38).
@export var unlock_cost := 30
## Shop price of the first upgrade level.
@export var base_cost := 20
## Each further shop level costs this many times the previous one.
@export var cost_growth := 1.6
## Highest shop upgrade level the owner can buy.
@export var max_shop_level := 5
## Spawn odds among the items available at a depth, and the shallowest layer it can appear in.
@export var weight := 1.0
@export var min_layer := 0
## Placeholder visuals.
@export var color := Color(0.9, 0.9, 0.9)


## Stable save key, taken from the file name.
func id() -> String:
	return resource_path.get_file().get_basename()


func buff_at_level(shop_level: int) -> float:
	return buff_per_stack + shop_level * buff_step_per_level


func cost_for(level: int) -> int:
	return roundi(base_cost * pow(cost_growth, level))
