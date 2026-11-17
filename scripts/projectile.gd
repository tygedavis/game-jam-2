class_name Projectile
extends Node2D
## A shot fired by the drill. Flies in a straight line, damages the first enemy it touches, and
## stops at solid dirt. It has no gameplay range; it is only cleaned up once far off screen.
## Call setup() before adding to the tree.

const RADIUS := 4.0
## Housekeeping only: free shots that have flown this far, so strays don't live forever.
const CLEANUP_DISTANCE := 4000.0

var terrain: Terrain
var velocity := Vector2.ZERO
var damage := 0.0
var _travelled := 0.0


func setup(ground: Terrain, from: Vector2, direction: Vector2, shot_speed: float, shot_damage: float) -> void:
	terrain = ground
	position = from
	velocity = direction.normalized() * shot_speed
	damage = shot_damage


func _physics_process(delta: float) -> void:
	# Sub-step so fast shots can't skip over thin enemies or single dirt tiles.
	var total := velocity.length() * delta
	var steps := maxi(ceili(total / (RADIUS * 2.0)), 1)
	var step := velocity * delta / float(steps)
	for i in steps:
		position += step
		_travelled += step.length()
		if _hit_something() or _travelled >= CLEANUP_DISTANCE:
			queue_free()
			return


func _hit_something() -> bool:
	var hit_box := Rect2(position - Vector2(RADIUS, RADIUS), Vector2(RADIUS, RADIUS) * 2.0)
	var barrier := terrain.barrier_layer_in_rect(hit_box)
	if barrier >= 1:
		terrain.damage_barrier(barrier, damage, position.x)
		return true
	if terrain.is_solid(terrain.world_to_cell(position)):
		return true
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy and enemy.rect().intersects(hit_box):
			enemy.take_damage(damage)
			return true
	return false


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, Color(1.0, 0.9, 0.4))
