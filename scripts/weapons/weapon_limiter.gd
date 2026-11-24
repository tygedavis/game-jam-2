class_name WeaponLimiter
extends Resource
## Decides when a weapon may fire and reports a 0-1 value for the HUD. This is the extension
## point for new firing rules: add a subclass (one script, its own @export tuning values) and use
## it in any WeaponDef .tres. Nothing else needs to change. A Weapon duplicates its limiter, so
## runtime state kept in subclass vars is per weapon instance.


## Call every physics frame, even when the player is not firing (limiters recharge and cool down
## in that time). Returns true if the weapon fires this frame.
func update(_delta: float, _wants_fire: bool) -> bool:
	return false


## 1.0 when fully ready or full, 0.0 when empty or cooling. Drives the HUD meter.
func fraction() -> float:
	return 1.0
