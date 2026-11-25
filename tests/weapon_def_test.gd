extends SceneTree
## Headless tests for weapon defs, the catalog and Weapon (issue #53).
## Run: godot --headless --path . --script tests/weapon_def_test.gd

var _failed := false


func check(test_name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + test_name)
	if not ok:
		_failed = true


## Test-local mechanic and limiter: prove a new weapon needs no changes to Weapon, Drill or HUD.
class CountBehavior extends WeaponBehavior:
	var fired := 0

	func fire(_drill: Drill, _weapon: Weapon, _aim: Vector2, _delta: float) -> void:
		fired += 1


class TwoShots extends WeaponLimiter:
	var left := 2

	func update(_delta: float, wants_fire: bool) -> bool:
		if wants_fire and left > 0:
			left -= 1
			return true
		return false


func _initialize() -> void:
	_test_basic_gun()
	_test_flamethrower()
	_test_catalog()
	_test_instances_do_not_share_state()
	_test_extensible()
	quit(1 if _failed else 0)


func _test_basic_gun() -> void:
	var d: WeaponDef = load("res://data/weapons/basic_gun.tres")
	check("basic_gun loads", d != null)
	check("basic_gun id is the file name", d.id() == "basic_gun")
	check("basic_gun is a primary", d.slot == WeaponDef.SLOT_PRIMARY)
	check("basic_gun scales with drill stats", d.scales_with_drill_stats)
	check("basic_gun behavior is a ProjectileBehavior", d.behavior is ProjectileBehavior)
	check("basic_gun limiter is a CooldownLimiter", d.limiter is CooldownLimiter)
	check("basic_gun matches the old drill defaults", is_equal_approx((d.limiter as CooldownLimiter).interval, 0.4) and is_equal_approx((d.behavior as ProjectileBehavior).speed, 600.0) and is_equal_approx(d.damage, 10.0))


func _test_flamethrower() -> void:
	var d: WeaponDef = load("res://data/weapons/flamethrower.tres")
	check("flamethrower loads and is a secondary", d != null and d.slot == WeaponDef.SLOT_SECONDARY)
	check("flamethrower id is the file name", d.id() == "flamethrower")
	check("flamethrower uses fuel and a flame behavior", d.limiter is FuelLimiter and d.behavior is FlamethrowerBehavior)
	check("flamethrower does not scale with the drill", not d.scales_with_drill_stats)


func _test_catalog() -> void:
	var defs := WeaponCatalog.all()
	var files := Array(ResourceLoader.list_directory(WeaponCatalog.WEAPON_DIR)).filter(func(f: String) -> bool: return f.ends_with(".tres"))
	check("catalog finds every weapon file in data/weapons/", defs.size() == files.size() and defs.size() >= 2)
	var ids := {}
	var sorted := true
	for i in defs.size():
		ids[defs[i].id()] = true
		if i > 0 and defs[i - 1].id() > defs[i].id():
			sorted = false
	check("catalog is sorted by id", sorted)
	check("catalog contains basic_gun", ids.has("basic_gun"))
	check("catalog contains flamethrower", ids.has("flamethrower"))
	check("catalog ids are unique", ids.size() == defs.size())


func _test_instances_do_not_share_state() -> void:
	var d: WeaponDef = load("res://data/weapons/basic_gun.tres")
	var a := Weapon.create(d)
	var b := Weapon.create(d)
	check("weapon limiter is a copy of the def's", a.limiter != d.limiter)
	check("two weapons have separate limiters", a.limiter != b.limiter)
	a.limiter.update(0.0, true) # a fires and starts cooling
	check("firing one weapon does not cool the other", b.limiter.update(0.0, true))


func _test_extensible() -> void:
	var d := WeaponDef.new()
	var behavior := CountBehavior.new()
	d.behavior = behavior
	d.limiter = TwoShots.new()
	var w := Weapon.create(d)
	var drill := Drill.new()
	for i in 5:
		w.update(drill, 0.016, true, Vector2.RIGHT)
	check("custom behavior and limiter fire through Weapon", behavior.fired == 2)
	drill.free()
