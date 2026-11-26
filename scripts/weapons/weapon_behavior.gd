class_name WeaponBehavior
extends Resource
## The mechanic of a weapon (what happens when it fires). Add a new mechanic by extending this
## with its own @export tuning values, then use it from a WeaponDef .tres.


## Called by Weapon.update on every frame the limiter allows firing. `aim` is a non-zero direction;
## `delta` is the physics step, for weapons that act continuously (a flamethrower).
func fire(_drill: Drill, _weapon: Weapon, _aim: Vector2, _delta: float) -> void:
	pass
