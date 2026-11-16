class_name Drill
extends Node2D
## Player drill vehicle. Moves in four directions; blocked by dirt.
## The auto-attack fires on a timer in the facing direction and damages dirt
## (digging) and, later, enemies. Stats here are shared by both.

@export var speed := 180.0
## Seconds between attacks.
@export var attack_interval := 0.4
## Damage per attack.
@export var attack_damage := 10.0
## How far past the drill's edge the attack reaches, in pixels.
@export var attack_reach := 20.0
## Half-width of the attack, in pixels.
@export var attack_area := 15.0

var terrain: Terrain
var facing := Vector2i.DOWN
var _half := Vector2(12, 12)
var _attack_timer := 0.0
var _flash := 0.0


func _physics_process(delta: float) -> void:
	var input := _read_input()
	if input != Vector2i.ZERO:
		facing = input
	var step := Vector2(input) * speed * delta
	_move_axis(Vector2(step.x, 0))
	_move_axis(Vector2(0, step.y))

	_attack_timer -= delta
	if _attack_timer <= 0.0:
		_attack_timer = attack_interval
		_attack()
	_flash = maxf(_flash - delta, 0.0)
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


## The attack area in local space: from the drill's center out past its edge by `attack_reach`.
func attack_rect() -> Rect2:
	var reach := _half.x + attack_reach
	if facing.x != 0:
		return Rect2(0.0 if facing.x > 0 else -reach, -attack_area, reach, attack_area * 2.0)
	return Rect2(-attack_area, 0.0 if facing.y > 0 else -reach, attack_area * 2.0, reach)


func _attack() -> void:
	_flash = 0.08
	var r := attack_rect()
	r.position += position
	var a := terrain.world_to_cell(r.position)
	var b := terrain.world_to_cell(r.end - Vector2(0.01, 0.01))
	for y in range(a.y, b.y + 1):
		for x in range(a.x, b.x + 1):
			terrain.damage(Vector2i(x, y), attack_damage)
	# Enemies take damage from the same attack in milestone 3.


func _draw() -> void:
	# Placeholder visuals: body plus a drill nose showing the facing direction.
	draw_rect(Rect2(-_half, _half * 2.0), Color(0.95, 0.75, 0.2))
	var nose := Vector2(facing) * (_half.x + 6.0)
	draw_circle(nose, 6.0, Color(0.7, 0.7, 0.75))
	if _flash > 0.0:
		draw_rect(attack_rect(), Color(1, 1, 1, 0.35))
