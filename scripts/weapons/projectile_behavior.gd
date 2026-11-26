class_name ProjectileBehavior
extends WeaponBehavior
## Fires one projectile from the drill toward the aim direction.

## Projectile speed, in pixels per second.
@export var speed := 600.0


func fire(drill: Drill, weapon: Weapon, aim: Vector2, _delta: float) -> void:
	var shot := Projectile.new()
	shot.setup(drill.terrain, drill.position, aim, speed, weapon.damage(drill))
	drill.get_parent().add_child(shot)
