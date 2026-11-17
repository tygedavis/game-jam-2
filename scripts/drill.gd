class_name Drill
extends Node2D
## Player drill vehicle. Moves in four directions; blocked by dirt.
## Digging is automatic: whenever dirt or a gem touches the drill's leading edge, it damages that
## dirt continuously. The auto-attack (until the mouse attack replaces it) only hits enemies.
## Dig power is derived from the attack stats, so attack upgrades also speed up digging.

@export var speed := 180.0
## Seconds between attacks.
@export var attack_interval := 0.4
## Damage per attack.
@export var attack_damage := 10.0
## Projectile speed, in pixels per second.
@export var projectile_speed := 600.0
## How close (px) the drill must be to dirt, in the steering direction, to dig it.
@export var dig_contact := 4.0

signal died
signal xp_changed
signal leveled_up

@export var max_hp := 100.0
## Seconds of invulnerability after taking a hit.
@export var hit_cooldown := 0.6

var terrain: Terrain
var hp := 0.0
## XP progress toward the next level (resets on level-up).
var xp := 0.0
var level := 1
var _invuln := 0.0
var facing := Vector2i.DOWN
var _half := Vector2(12, 12)
var _attack_timer := 0.0

## The drill art (an AutoSprite child named Sprite). Artists swap its texture in the editor.
## The art should point DOWN; it is rotated to match the facing direction.
@onready var _sprite: Node2D = $Sprite


func _ready() -> void:
	hp = max_hp


func rect() -> Rect2:
	return Rect2(position - _half, _half * 2.0)


func take_damage(amount: float) -> void:
	if _invuln > 0.0 or hp <= 0.0:
		return
	hp -= amount
	_invuln = hit_cooldown
	if hp <= 0.0:
		died.emit()


func xp_to_next() -> float:
	return 10.0 + 6.0 * (level - 1)


func gain_xp(amount: float) -> void:
	xp += amount
	while xp >= xp_to_next():
		xp -= xp_to_next()
		level += 1
		leveled_up.emit()
	xp_changed.emit()


func _physics_process(delta: float) -> void:
	_invuln = maxf(_invuln - delta, 0.0)
	var input := _read_input()
	if input != Vector2i.ZERO:
		facing = input
	var step := Vector2(input) * speed * delta
	_move_axis(Vector2(step.x, 0))
	_move_axis(Vector2(0, step.y))

	_dig(delta) # digs whatever the leading edge touches, even when standing still

	_attack_timer = maxf(_attack_timer - delta, 0.0)
	if _attack_timer <= 0.0 and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_attack_timer = attack_interval
		_attack()
	_update_visuals()
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
	if not _blocked(target) and not _hits_enemy(target):
		position = target
		return
	# Blocked: creep up to the obstacle so we end flush against it. Otherwise a big step (speed
	# upgrades, frame hitches) can stop us further away than `dig_contact`, and nothing gets dug.
	var direction := offset.normalized()
	var remaining := offset.length()
	while remaining > 0.0:
		var creep := minf(1.0, remaining)
		var next := position + direction * creep
		if _blocked(next) or _hits_enemy(next):
			return
		position = next
		remaining -= creep


## True if moving to `center` would newly overlap an enemy (enemies are solid).
func _hits_enemy(center: Vector2) -> bool:
	var next := Rect2(center - _half, _half * 2.0)
	var now := rect()
	for e in get_tree().get_nodes_in_group("enemies"):
		var er: Rect2 = e.rect()
		if next.intersects(er) and not now.intersects(er):
			return true
	return false


func _blocked(center: Vector2) -> bool:
	var a := terrain.world_to_cell(center - _half)
	var b := terrain.world_to_cell(center + _half - Vector2(0.01, 0.01))
	for y in range(a.y, b.y + 1):
		for x in range(a.x, b.x + 1):
			if terrain.is_blocked(Vector2i(x, y)):
				return true
	return false


## Dirt damage per second while digging (same output as the old attack timer).
func dig_power() -> float:
	return attack_damage / attack_interval


## Damages the dirt (and exposed gems) touching the drill's leading edge.
## Breaking a gem out collects it.
func _dig(delta: float) -> void:
	var body_rect := Rect2(position - _half, _half * 2.0)
	var contact_rect: Rect2
	if facing.x > 0:
		contact_rect = Rect2(body_rect.end.x, body_rect.position.y, dig_contact, body_rect.size.y)
	elif facing.x < 0:
		contact_rect = Rect2(body_rect.position.x - dig_contact, body_rect.position.y, dig_contact, body_rect.size.y)
	elif facing.y > 0:
		contact_rect = Rect2(body_rect.position.x, body_rect.end.y, body_rect.size.x, dig_contact)
	else:
		contact_rect = Rect2(body_rect.position.x, body_rect.position.y - dig_contact, body_rect.size.x, dig_contact)
	var first_cell := terrain.world_to_cell(contact_rect.position)
	var last_cell := terrain.world_to_cell(contact_rect.end - Vector2(0.01, 0.01))
	var damage_this_frame := dig_power() * delta
	for cell_y in range(first_cell.y, last_cell.y + 1):
		for cell_x in range(first_cell.x, last_cell.x + 1):
			terrain.damage(Vector2i(cell_x, cell_y), damage_this_frame, true)


## Fires one projectile from the drill's center toward the mouse cursor.
func _attack() -> void:
	var direction := get_global_mouse_position() - global_position
	if direction.is_zero_approx():
		direction = Vector2(facing)
	var shot := Projectile.new()
	shot.setup(terrain, position, direction, projectile_speed, attack_damage)
	get_parent().add_child(shot)


func _update_visuals() -> void:
	# Art points down; rotate it to the facing direction. Blink while invulnerable.
	_sprite.rotation = Vector2.DOWN.angle_to(Vector2(facing))
	var blink := _invuln > 0.0 and int(_invuln * 20.0) % 2 == 0
	_sprite.modulate.a = 0.5 if blink else 1.0
