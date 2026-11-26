extends SceneTree
## Headless tests for weapon limiters (issue #53).
## Run: godot --headless --path . --script tests/weapon_limiter_test.gd

var _failed := false


func check(test_name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + test_name)
	if not ok:
		_failed = true


## Test-local limiter: allows two shots, then never fires. Proves new limiters need only a subclass.
class ChargesStub extends WeaponLimiter:
	var shots_left := 2

	func update(_delta: float, wants_fire: bool) -> bool:
		if wants_fire and shots_left > 0:
			shots_left -= 1
			return true
		return false

	func fraction() -> float:
		return shots_left / 2.0


func _initialize() -> void:
	_test_cooldown()
	_test_fuel()
	_test_extensible()
	quit(1 if _failed else 0)


func _test_cooldown() -> void:
	var c := CooldownLimiter.new()
	check("cooldown: first update fires", c.update(0.016, true))
	check("cooldown: immediate second update does not fire", not c.update(0.0, true))
	c.update(0.5, false)
	check("cooldown: fires again after the interval", c.update(0.0, true))
	c.update(0.1, false)
	check("cooldown: fraction is between 0 and 1 while cooling", c.fraction() > 0.0 and c.fraction() < 1.0)
	c.update(1.0, false)
	check("cooldown: fraction is 1.0 when ready", is_equal_approx(c.fraction(), 1.0))
	var idle := CooldownLimiter.new()
	check("cooldown: never fires when not wanted", not idle.update(1.0, false))


func _test_fuel() -> void:
	var f := FuelLimiter.new()
	var fired_time := 0.0
	while f.update(0.1, true):
		fired_time += 0.1
		if fired_time > 5.0:
			break
	check("fuel: fires for about its capacity (2.0 s)", absf(fired_time - 2.0) < 0.15)
	check("fuel: fraction is near 0 when it runs dry", f.fraction() < 0.1)
	# Holding fire while empty must not flicker: off until fuel passes resume_fraction.
	var fraction_at_resume := -1.0
	var flickered := false
	var running := false
	for i in 20:
		var fired := f.update(0.1, true)
		if fired and not running:
			running = true
			if fraction_at_resume < 0.0:
				fraction_at_resume = f.fraction()
		elif not fired and running:
			if f.fraction() > 0.05:
				flickered = true # stopped while fuel remained
			running = false
	check("fuel: resumes only after recovering past resume_fraction", fraction_at_resume >= 0.2)
	check("fuel: does not flicker while fuel remains", not flickered)
	var r := FuelLimiter.new()
	for i in 30:
		r.update(0.1, true)
	r.update(100.0, false)
	check("fuel: idle recharge caps at 1.0", is_equal_approx(r.fraction(), 1.0))
	var steady := FuelLimiter.new()
	steady.update(1.0, true)
	steady.update(1.0, false) # recharge 0.5 s worth
	check("fuel: recharges at recharge_per_second", is_equal_approx(steady.fraction(), 0.75))


func _test_extensible() -> void:
	var stub := ChargesStub.new()
	check("extensible: custom limiter fires twice", stub.update(0.0, true) and stub.update(0.0, true))
	check("extensible: custom limiter then stops", not stub.update(0.0, true))
	check("extensible: custom fraction used", is_equal_approx(stub.fraction(), 0.0))
	check("extensible: is a WeaponLimiter", stub is WeaponLimiter)
