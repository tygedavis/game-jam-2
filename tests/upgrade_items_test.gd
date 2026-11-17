extends SceneTree
## Headless tests for map upgrade items (issue #13).
## Run: godot --headless --path . --script tests/upgrade_items_test.gd

var _failed := false


func check(test_name: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + test_name)
	if not ok:
		_failed = true


func _initialize() -> void:
	_test_def()
	_test_drill()
	_test_terrain()
	quit(1 if _failed else 0)


func _test_def() -> void:
	var d := UpgradeItemDef.new()
	d.buff_per_stack = 0.02
	d.buff_step_per_level = 0.02
	check("buff_at_level(0) is base", is_equal_approx(d.buff_at_level(0), 0.02))
	check("buff_at_level(1) doubles 2% to 4%", is_equal_approx(d.buff_at_level(1), 0.04))
	check("cost_for(0) is base_cost", d.cost_for(0) == d.base_cost)
	check("cost_for(2) grows", d.cost_for(2) == roundi(d.base_cost * pow(d.cost_growth, 2)))
	var loaded: UpgradeItemDef = load("res://data/items/sharp_tip.tres")
	check("id() is the file name", loaded != null and loaded.id() == "sharp_tip")


var _item_count := 0


func _item(prop: String, per_stack: float, step := 0.02) -> UpgradeItemDef:
	var d := UpgradeItemDef.new()
	# id() comes from the file name, so each test item needs its own path.
	_item_count += 1
	d.resource_path = "res://test_item_%d.tres" % _item_count
	d.property = prop
	d.buff_per_stack = per_stack
	d.buff_step_per_level = step
	return d


func _drill() -> Drill:
	var dr := Drill.new()
	dr.attack_damage = 10.0
	dr.attack_interval = 0.4
	return dr


func _test_drill() -> void:
	var item := _item("attack_damage", 0.02)
	var dr := _drill()
	dr.add_upgrade(item, 0)
	check("one stack adds 2%", is_equal_approx(dr.attack_damage, 10.2))
	for i in 4:
		dr.add_upgrade(item, 0)
	check("five stacks add up to 10% (not compounded)", is_equal_approx(dr.attack_damage, 11.0))

	var leveled := _drill()
	for i in 3:
		leveled.add_upgrade(item, 1)
	check("shop level 1 gives 4% per stack", is_equal_approx(leveled.attack_damage, 11.2))

	var two := _drill()
	var other := _item("attack_damage", 0.05)
	two.add_upgrade(item, 0)
	two.add_upgrade(item, 0)
	two.add_upgrade(other, 0)
	check("two items on one stat add into one sum", is_equal_approx(two.attack_damage, 10.0 * 1.09))

	# Review Focus 1: cap.
	check("sixth stack is refused", not dr.add_upgrade(item, 0))
	check("stacks stay at the cap", dr.stacks_of(item) == 5)
	check("stat stays at the cap value", is_equal_approx(dr.attack_damage, 11.0))

	# Review Focus 4: attack_interval gets faster, never zero or negative.
	var fast := _drill()
	var gears := _item("attack_interval", 0.5)
	for i in 5:
		fast.add_upgrade(gears, 0)
	check("interval is divided by 1 + buffs", is_equal_approx(fast.attack_interval, 0.4 / 3.5))
	check("interval stays positive and smaller", fast.attack_interval > 0.0 and fast.attack_interval < 0.4)

	# Stacks do not leak between runs.
	var fresh := _drill()
	check("a new drill has no stacks", fresh.stacks_of(item) == 0)
	check("a new drill has its original stats", is_equal_approx(fresh.attack_damage, 10.0))
	for node in [dr, leveled, two, fast, fresh]:
		node.free()


var _collected: Array = []


func _on_collected(def: UpgradeItemDef) -> void:
	_collected.append(def)


func _terrain(defs: Array[UpgradeItemDef]) -> Terrain:
	var t := Terrain.new()
	t.profile = load("res://data/terrain_profile.tres")
	t.upgrade_defs = defs
	t.upgrade_chance = 0.05
	root.add_child(t) # runs _ready, which seeds the terrain
	return t


func _scan(t: Terrain) -> Dictionary:
	var found := {} # Vector2i -> UpgradeItemDef
	for x in range(-100, 101):
		for y in range(0, 201):
			var d := t.upgrade_at(Vector2i(x, y))
			if d:
				found[Vector2i(x, y)] = d
	return found


func _test_terrain() -> void:
	var a := _item("attack_damage", 0.02)
	var b := _item("speed", 0.02)
	b.min_layer = 1
	var t := _terrain([a, b])
	var found := _scan(t)
	var layer_h: int = t.profile.layer_height
	var only_known := true
	var b_too_shallow := false
	var seen_a := false
	var seen_b := false
	for cell in found:
		var d: UpgradeItemDef = found[cell]
		only_known = only_known and (d == a or d == b)
		seen_a = seen_a or d == a
		seen_b = seen_b or d == b
		if d == b and cell.y < layer_h:
			b_too_shallow = true
	check("spawns only the listed items", only_known)
	check("both items appear", seen_a and seen_b)
	check("min_layer is respected", not b_too_shallow)
	var cell0: Vector2i = found.keys()[0]
	check("upgrade_at is deterministic", t.upgrade_at(cell0) == t.upgrade_at(cell0))
	check("sky has no upgrades", t.upgrade_at(Vector2i(0, -1)) == null)

	# Collection.
	_collected.clear()
	t.upgrade_collected.connect(_on_collected)
	t.damage(cell0, 1.0e30, false)
	check("breaking a tile without collect gives nothing", _collected.is_empty())
	var cell1: Vector2i = found.keys()[1]
	t.damage(cell1, 1.0e30, true)
	check("collecting emits once with the right def", _collected.size() == 1 and _collected[0] == found[cell1])

	# Review Focus 3: a capped item stops spawning without reshuffling the others.
	t.capped_upgrade_ids[a.id()] = true
	var after := _scan(t)
	var stable := true
	var a_gone := true
	for cell in found:
		var was: UpgradeItemDef = found[cell]
		if was == a:
			a_gone = a_gone and not after.has(cell)
		else:
			stable = stable and after.get(cell) == was
	check("capped item no longer spawns", a_gone)
	check("other tiles keep their items when one is capped", stable)

	# Review Focus 2: no unlocked items.
	var empty := _terrain([])
	check("empty pool spawns nothing", _scan(empty).is_empty())
	t.free()
	empty.free()
