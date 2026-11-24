class_name FuelLimiter
extends WeaponLimiter
## Fires every frame while the player holds fire and there is fuel. Fuel drains while firing and
## recharges otherwise. Once empty it stays off until fuel recovers past `resume_fraction`, so
## holding fire at empty does not flicker.

## Seconds of continuous fire from a full tank.
@export var capacity := 2.0
## Fuel spent per second of firing.
@export var drain_per_second := 1.0
## Fuel regained per second while not firing.
@export var recharge_per_second := 0.5
## Fraction of the tank that must be recovered after running dry before firing resumes.
@export_range(0.0, 1.0) var resume_fraction := 0.25

var _fuel := -1.0 # set to capacity on first use, after exported values are applied
var _locked := false


func update(delta: float, wants_fire: bool) -> bool:
	if _fuel < 0.0:
		_fuel = capacity
	if wants_fire and not _locked and _fuel > 0.0:
		_fuel = maxf(_fuel - drain_per_second * delta, 0.0)
		if _fuel <= 0.0:
			_locked = true
		return true
	_fuel = minf(_fuel + recharge_per_second * delta, capacity)
	if _locked and _fuel >= resume_fraction * capacity:
		_locked = false
	return false


func fraction() -> float:
	if capacity <= 0.0:
		return 0.0
	return 1.0 if _fuel < 0.0 else clampf(_fuel / capacity, 0.0, 1.0)
