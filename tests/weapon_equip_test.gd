extends SceneTree
## Headless tests for the drill's primary and secondary weapon slots (issue #53).
## Run: godot --headless --path . --script tests/weapon_equip_test.gd

var _failed := false


func check(test_name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + test_name)
	if not ok:
		_failed = true


func _initialize() -> void:
	await process_frame
	_test_slots()
	_test_primary_fires_projectile()
	_test_buffs_apply_to_primary()
	_test_secondary_does_not_change_dig_power()
	_test_aim_fallback()
	quit(1 if _failed else 0)


func _drill() -> Drill:
	var t := Terrain.new()
	t.profile = TerrainProfile.new()
	root.add_child(t)
	var d := Drill.new()
	var sprite := Node2D.new()
	sprite.name = "Sprite"
	d.add_child(sprite)
	d.terrain = t
	d.position = Vector2(0, -12)
	root.add_child(d)
	return d


func _secondary_def() -> WeaponDef:
	var d := WeaponDef.new()
	d.slot = WeaponDef.SLOT_SECONDARY
	d.behavior = WeaponBehavior.new()
	d.limiter = CooldownLimiter.new()
	return d


func _test_slots() -> void:
	var drill := _drill()
	check("default primary is basic_gun", drill.primary != null and drill.primary.def.id() == "basic_gun")
	check("no secondary by default", drill.secondary == null)
	var sec := _secondary_def()
	drill.equip(sec)
	check("equip fills the secondary slot", drill.secondary != null and drill.secondary.def == sec)
	check("equipping a secondary keeps the primary", drill.primary.def.id() == "basic_gun")
	var other_primary := WeaponDef.new()
	other_primary.slot = WeaponDef.SLOT_PRIMARY
	other_primary.behavior = WeaponBehavior.new()
	other_primary.limiter = CooldownLimiter.new()
	drill.equip(other_primary)
	check("equipping a primary replaces the primary", drill.primary.def == other_primary)
	var drill2 := _drill()
	drill2.equip(sec)
	check("same def in two drills has separate limiters", drill.secondary.limiter != drill2.secondary.limiter)


func _test_primary_fires_projectile() -> void:
	var drill := _drill()
	var before := root.get_children().filter(func(n: Node) -> bool: return n is Projectile).size()
	drill.primary.update(drill, 0.0, true, Vector2.RIGHT)
	var shots := root.get_children().filter(func(n: Node) -> bool: return n is Projectile)
	check("primary fires one projectile", shots.size() == before + 1)
	check("projectile damage is the drill's attack damage", is_equal_approx((shots[-1] as Projectile).damage, drill.attack_damage))
	var idle := _drill()
	idle.primary.update(idle, 0.0, false, Vector2.RIGHT)
	check("no projectile when fire is not held", root.get_children().filter(func(n: Node) -> bool: return n is Projectile).size() == before + 1)


func _test_buffs_apply_to_primary() -> void:
	var drill := _drill()
	var item := UpgradeItemDef.new()
	item.property = "attack_interval"
	item.buff_per_stack = 0.5
	item.resource_path = "res://data/items/test_interval_item.tres"
	drill.capture_baseline()
	drill.add_upgrade(item, 0)
	drill.primary.update(drill, 0.0, false, Vector2.RIGHT)
	var cd := drill.primary.limiter as CooldownLimiter
	check("primary cooldown follows the buffed attack interval", is_equal_approx(cd.interval, drill.attack_interval) and drill.attack_interval < 0.4)


func _test_secondary_does_not_change_dig_power() -> void:
	var drill := _drill()
	var power := drill.dig_power()
	var damage := drill.attack_damage
	drill.equip(_secondary_def())
	drill.secondary.update(drill, 0.0, true, Vector2.RIGHT)
	check("secondary leaves dig power alone", is_equal_approx(drill.dig_power(), power))
	check("secondary leaves attack damage alone", is_equal_approx(drill.attack_damage, damage))


func _test_aim_fallback() -> void:
	var drill := _drill()
	drill.facing = Vector2i.LEFT
	var aim := drill.aim_from(drill.global_position)
	check("aiming at the drill's own position falls back to facing", aim == Vector2(-1, 0))
	check("aim is finite and normalized", is_equal_approx(drill.aim_from(drill.global_position + Vector2(30, 40)).length(), 1.0))
