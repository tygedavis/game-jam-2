class_name Weapon
extends RefCounted
## A weapon in use: a WeaponDef plus its own copy of the limiter, so cooldowns and fuel are never
## shared between drills or runs.

var def: WeaponDef
var limiter: WeaponLimiter


static func create(weapon_def: WeaponDef) -> Weapon:
	var w := Weapon.new()
	w.def = weapon_def
	w.limiter = weapon_def.limiter.duplicate() as WeaponLimiter
	return w


## Damage for one shot (or one second): the drill's buffed attack damage for the primary.
func damage(drill: Drill) -> float:
	return drill.attack_damage if def.scales_with_drill_stats else def.damage


## Call every physics frame. `aim` must be non-zero.
func update(drill: Drill, delta: float, wants_fire: bool, aim: Vector2) -> void:
	if def.scales_with_drill_stats and limiter is CooldownLimiter:
		(limiter as CooldownLimiter).interval = drill.attack_interval
	if limiter.update(delta, wants_fire):
		def.behavior.fire(drill, self, aim, delta)
