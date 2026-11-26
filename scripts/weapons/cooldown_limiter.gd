class_name CooldownLimiter
extends WeaponLimiter
## Fires at most once per `interval` seconds while the player holds fire.

## Seconds between shots.
@export var interval := 0.4

var _timer := 0.0


func update(delta: float, wants_fire: bool) -> bool:
	_timer = maxf(_timer - delta, 0.0)
	if wants_fire and _timer <= 0.0:
		_timer = interval
		return true
	return false


func fraction() -> float:
	if interval <= 0.0:
		return 1.0
	return clampf(1.0 - _timer / interval, 0.0, 1.0)
