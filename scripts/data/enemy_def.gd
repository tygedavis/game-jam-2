class_name EnemyDef
extends Resource
## One enemy type. Add an enemy by creating an EnemyDef .tres and listing it on Main.

@export var display_name := "Enemy"
@export var max_hp := 20.0
## Movement speed in pixels per second.
@export var speed := 90.0
## Damage dealt to the player per contact hit.
@export var contact_damage := 10.0
## Damage per second dealt to dirt in its way (how fast it burrows).
@export var dig_dps := 40.0
## XP dropped on death.
@export var xp := 5.0
## Placeholder visuals.
@export var color := Color(0.8, 0.3, 0.35)
@export var size := 22.0
