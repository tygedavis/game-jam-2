class_name FlamethrowerBehavior
extends WeaponBehavior
## A short-range cone of fire. Burns dirt (through any thickness, up to range) and hurts enemies
## continuously while held. It never collects: gems and cells holding an upgrade item are left for
## the player to mine, and it cannot burn through an unbroken barrier.
## TODO(#54): once upgrade items become pickups after their dirt breaks, remove the upgrade-item skip
## in fire() and its test in tests/flamethrower_test.gd.

## How far the flame reaches, in pixels.
@export var range_px := 96.0
## Half the width of the cone, in degrees.
@export var cone_half_angle_degrees := 25.0
## Damage per second to dirt tiles in the cone. Fixed here, not buffed by primary upgrades.
@export var dirt_damage_per_second := 60.0
## Damage per second to enemies in the cone.
@export var enemy_damage_per_second := 30.0

## Cells closer than this to the drill are always in the flame, whatever the aim.
const NEAR := 16.0


func fire(drill: Drill, _weapon: Weapon, aim: Vector2, delta: float) -> void:
	var direction := aim.normalized() if not aim.is_zero_approx() else Vector2(drill.facing)
	var terrain := drill.terrain
	var half_angle := deg_to_rad(cone_half_angle_degrees)
	var origin := drill.position
	# Only cells inside the square around the drill that the flame can reach are worth checking.
	var min_cell := terrain.world_to_cell(origin - Vector2(range_px, range_px))
	var max_cell := terrain.world_to_cell(origin + Vector2(range_px, range_px))
	for y in range(min_cell.y, max_cell.y + 1):
		for x in range(min_cell.x, max_cell.x + 1):
			var cell := Vector2i(x, y)
			if not terrain.is_dirt(cell) or terrain.upgrade_at(cell) != null:
				continue
			var center := (Vector2(cell) + Vector2(0.5, 0.5)) * Terrain.TILE
			if not _in_flame(origin, center, direction, half_angle):
				continue
			if terrain.barrier_layer_in_rect(Rect2(origin, Vector2.ZERO).expand(center)) >= 1:
				continue # an unbroken barrier is in the way
			terrain.damage(cell, dirt_damage_per_second * delta, false)
	for node in drill.get_tree().get_nodes_in_group("enemies"):
		var box: Rect2 = node.rect()
		if _in_flame(origin, box.get_center(), direction, half_angle):
			node.take_damage(enemy_damage_per_second * delta)


func _in_flame(origin: Vector2, point: Vector2, direction: Vector2, half_angle: float) -> bool:
	var offset := point - origin
	var dist := offset.length()
	if dist > range_px:
		return false
	return dist <= NEAR or absf(direction.angle_to(offset)) <= half_angle
