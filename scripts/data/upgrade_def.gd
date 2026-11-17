class_name UpgradeDef
extends Resource
## An in-run level-up choice. Add one by creating an UpgradeDef .tres and listing it on Main.
## It multiplies one Drill stat, so attack stats improve digging and fighting together.

@export var display_name := "Upgrade"
@export_multiline var description := ""
## Which Drill property to change.
@export_enum("attack_damage", "attack_interval", "speed") var property := "attack_damage"
## The property is multiplied by this (e.g. 1.3 = +30%; 0.85 on attack_interval = faster attacks).
@export var multiplier := 1.25


func apply(drill: Drill) -> void:
	drill.set(property, drill.get(property) * multiplier)
