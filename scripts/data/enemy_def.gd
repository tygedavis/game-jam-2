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
## Art. Drag a PNG here (static image or sprite sheet). Draw it facing RIGHT; the game flips it.
## If empty, a coloured square is drawn instead.
@export var sprite: Texture2D
## Sprite sheet layout: columns and rows (1 and 1 for a single static image).
@export var sprite_hframes := 1
@export var sprite_vframes := 1
## Sprite sheet animation speed, frames per second.
@export var sprite_fps := 8.0
## Placeholder visuals, used only when no sprite is set. size is also the hitbox (pixels),
## whatever size the art is.
@export var color := Color(0.8, 0.3, 0.35)
@export var size := 22.0
