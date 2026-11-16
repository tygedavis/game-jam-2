class_name Drill
extends Node2D
## Player drill vehicle. Moves in four directions; blocked by dirt.
## Milestone 1: pushing into dirt digs it. Milestone 2 replaces this with the auto-attack.

@export var speed := 180.0
@export var dig_interval := 0.18

var terrain: Terrain
var facing := Vector2i.DOWN
var _half := Vector2(12, 12)
var _dig_timer := 0.0


func _physics_process(delta: float) -> void:
	var input := _read_input()
	if input != Vector2i.ZERO:
		facing = input
	var step := Vector2(input) * speed * delta
	_move_axis(Vector2(step.x, 0))
	_move_axis(Vector2(0, step.y))

	_dig_timer -= delta
	if input != Vector2i.ZERO and _dig_timer <= 0.0 and _blocked(position + Vector2(input) * (speed * delta + 1.0)):
		_dig_front()
		_dig_timer = dig_interval
	queue_redraw()


func _read_input() -> Vector2i:
	var x := int(Input.is_physical_key_pressed(KEY_D) or Input.is_action_pressed("ui_right")) \
		- int(Input.is_physical_key_pressed(KEY_A) or Input.is_action_pressed("ui_left"))
	var y := int(Input.is_physical_key_pressed(KEY_S) or Input.is_action_pressed("ui_down")) \
		- int(Input.is_physical_key_pressed(KEY_W) or Input.is_action_pressed("ui_up"))
	# One axis at a time (no diagonals); horizontal wins.
	if x != 0:
		return Vector2i(x, 0)
	return Vector2i(0, y)


func _move_axis(offset: Vector2) -> void:
	if offset == Vector2.ZERO:
		return
	var target := position + offset
	if not _blocked(target):
		position = target


func _blocked(center: Vector2) -> bool:
	var a := terrain.world_to_cell(center - _half)
	var b := terrain.world_to_cell(center + _half - Vector2(0.01, 0.01))
	for y in range(a.y, b.y + 1):
		for x in range(a.x, b.x + 1):
			if terrain.is_solid(Vector2i(x, y)):
				return true
	return false


func _dig_front() -> void:
	var probe := position + Vector2(facing) * (_half.x + 4.0)
	terrain.dig(terrain.world_to_cell(probe))
	# Also clear the neighbors in the perpendicular direction so the tunnel fits the drill.
	var side := Vector2(facing.y, facing.x).abs() * 10.0
	terrain.dig(terrain.world_to_cell(probe + side))
	terrain.dig(terrain.world_to_cell(probe - side))


func _draw() -> void:
	# Placeholder visuals: body plus a drill nose showing the facing direction.
	draw_rect(Rect2(-_half, _half * 2.0), Color(0.95, 0.75, 0.2))
	var nose := Vector2(facing) * (_half.x + 6.0)
	draw_circle(nose, 6.0, Color(0.7, 0.7, 0.75))
